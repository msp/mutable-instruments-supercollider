//////////////////////////////////////////////////////////////////////////////
// Mutable Instruments Plaits (via MiPlaits UGen)
//
// TIMBRE/MORPH MODULATION — see docs/miplaits-modulation.md for full analysis
//
// The MiPlaits UGen conflates the hardware's TIMBRE knob and CV jack into a
// single input. When timbre is a SynthDef arg (.kr), the UGen sets
// modulations.timbre_patched = true, which disables timb_mod entirely
// (it scales modulations.timbre, which is always 0).
//
// Our workaround: apply LFO modulation externally before the engine:
//   timbre: (timbre + (timbreLFO * timbMod)).clip(0, 1)
//
// To use the internal decay envelope instead (per-trigger timbre sweep),
// timbre must be .ir (scalar rate) — works for patterns, not for drones.
//
// fm_mod is unaffected: frequency_patched is hardcoded false in the UGen.
//
/////////////////////////////////////////////////////////////////////////////
(
// Shared signal chain for Plaits variants
// Applies stereo mode, distortion, reverb, and bus routing to raw MiPlaits output
~plaitsSigChain = { |sig, env, out, stereoMode, distDrive, distAmount,
	revTime, revDrywet, revDamp, revHp, revFreeze, volume,
	cloudsSend, delaySend, reverbSend|

	var cleanSig, distSig;

	// Stereo mode selection: 0=mono (left only), 1=stereo
	sig = Select.ar(stereoMode.clip(0, 1), [
		sig[0] ! 2,
		sig
	]);

	// Crossover distortion with wet/dry mix
	cleanSig = sig;
	distSig = CrossoverDistortion.ar(sig, distDrive.clip(0.1, 2.0), 0.5);
	sig = (cleanSig * (1 - distAmount.clip(0, 1))) + (distSig * distAmount.clip(0, 1));

	// Sanitize to kill denormals, infs, and NaNs - crucial for engine switching!
	sig = sig.sanitize;

	sig = MiVerb.ar(
		(sig * env).tanh,
		time: revTime.clip(0, 1.25),
		drywet: revDrywet.clip(0, 1),
		damp: revDamp.clip(0, 1),
		hp: revHp.clip(0, 1),
		freeze: revFreeze.clip(0, 1),
		diff: 0.625,
		mul: volume.clip(0, 2.0),
		add: 0.0
	);

	Out.ar(~cloudsBus, sig * cloudsSend);
	Out.ar(~delayBus, sig * delaySend);
	Out.ar(~reverbBus, sig * reverbSend);

	Out.ar(out, LeakDC.ar(sig.tanh));
};

// Per-voice AM / ring-mod stage: an audio-rate modulator multiplies the signal.
// amRing morphs AM (0 = carrier present) <-> ring mod (1 = carrier suppressed);
// amDepth is the amount (0 = bypass). The modulator tracks the carrier at amRatio,
// or a fixed Hz when amFixedHz = 1. amWave: 0 sine, 1 tri, 2 saw, 3 square.
// A small makeup gain (a function of amRing only) offsets the carrier-energy lost as
// you morph toward ring mod, so an AM<->RM sweep stays roughly level-constant. It's
// bounded (no blow-up at the silent corner) and static (no pumping), and leaves
// amDepth as the level control.
~plaitsAMStage = { |sig, carrierFreq, amRatio, amWave, amDepth, amRing, amFixedHz|
	var modFreq, mod, ring, makeup;
	ring = amRing.clip(0, 1);
	modFreq = Select.kr(amFixedHz.clip(0, 1), [
		carrierFreq * amRatio,
		amRatio.linlin(0, 8, 20, 2000)   // fixed-Hz mapping (adjustable by ear)
	]);
	mod = Select.ar(amWave.clip(0, 3), [
		SinOsc.ar(modFreq),
		LFTri.ar(modFreq),
		Saw.ar(modFreq),
		Pulse.ar(modFreq)
	]);
	// makeup = 1 + (amRing * G). G is the boost reached at full RM (amRing = 1):
	// 0.4 -> x1.4 -> ~+3 dB, chosen to offset the ~3 dB RMS the carrier-suppressed
	// full-depth ring mod loses vs the dry carrier. Purely a function of amRing, so
	// it's bounded (no divide-by-zero at depth 0) and static (no pumping). Raise G
	// for more lift (hardware/VSTs often over-compensate so RM reads as present),
	// lower for less. Baked at synthdef-build time, so reload to change it.
	makeup = 1 + (ring * 0.4);
	sig * ((1 - ring) + (amDepth * mod)) * makeup;
};

SynthDef(\plaits, {
	arg out=0, pitch=40, engine=1, harm=0.5, timbre=0.5, morph=0.5, speed=6, level=1.0, decay=0.5, fmMod=0.0, lpgColour=0.5, mul=0.5, gate=1.0, revDrywet=0.25, revTime=0.3, revDamp=0.8, revHp=0.7, revFreeze=0, volume=0.7, cloudsSend=0.0, delaySend=0.0, reverbSend=0.0, distDrive=0.0, distAmount=0.0, stereoMode=1,
	timbreLFO=0, morphLFO=0, decayLFO=0, pitchLFO=0, volumeLFO=0, harmLFO=0,
	timbMod=0.0, morphMod=0.0, decayMod=0.0, pitchMod=0.0, volumeMod=0.0, harmMod=0.0,
	amRatio=1.0, amWave=0, amDepth=0.0, amRing=0.0, amFixedHz=0, releaseTime=1.0, amRingLFO=0, amRingMod=0, amDepthLFO=0, amDepthMod=0, amRatioLFO=0, amRatioMod=0;

	var sig, env, carrierFreq, amRingEff, amDepthEff, amRatioEff;

	sig = MiPlaits.ar(
		pitch: (pitch + (pitchLFO * pitchMod)).clip(0, 127),
		engine: engine.clip(0, 23),
		harm: (harm + (harmLFO * harmMod)).clip(0, 1),
		timbre: (timbre + (timbreLFO * timbMod)).clip(0, 1),
		morph: (morph + (morphLFO * morphMod)).clip(0, 1),
		trigger: gate,
		decay: (decay + (decayLFO * decayMod)).clip(0, 1),
		fm_mod: fmMod.clip(-1, 1),
		lpg_colour: lpgColour.clip(0, 1),
		mul: mul
	);

	// AM / ring-mod stage (modulator tracks the modulated carrier pitch)
	carrierFreq = (pitch + (pitchLFO * pitchMod)).clip(0, 127).midicps;
	amRingEff  = (amRing  + (amRingLFO  * amRingMod )).clip(0, 1);   // LFO-modulated AM/RM balance
	amDepthEff = (amDepth + (amDepthLFO * amDepthMod)).clip(0, 1);   // LFO-modulated AM amount
	amRatioEff = (amRatio + (amRatioLFO * amRatioMod)).clip(0, 8);   // LFO-modulated modulator ratio
	sig = ~plaitsAMStage.(sig, carrierFreq, amRatioEff, amWave, amDepthEff, amRingEff, amFixedHz);

	// releaseTime = note release/tail (was hardcoded 1.0). Attack/sustain kept as Linen
	// defaults (0.01 / 1.0). Frees the synth when the release completes.
	env = Linen.kr(gate, 0.01, 1.0, releaseTime.max(0.001), doneAction: Done.freeSelf);

	~plaitsSigChain.(sig, env, out, stereoMode, distDrive, distAmount,
		revTime, revDrywet, revDamp, revHp, revFreeze,
		(volume + (volumeLFO * volumeMod)).clip(0, 2),
		cloudsSend, delaySend, reverbSend);
}).add;

// Drone variant: continuous trigger, ASR envelope with release on gate=0
SynthDef(\plaitsDrone, {
	arg out=0, pitch=40, engine=1, harm=0.5, timbre=0.5, morph=0.5, speed=6, level=1.0, decay=0.5, fmMod=0.0, lpgColour=0.5, mul=0.5, gate=1.0, revDrywet=0.25, revTime=0.3, revDamp=0.8, revHp=0.7, revFreeze=0, volume=0.7, cloudsSend=0.0, delaySend=0.0, reverbSend=0.0, distDrive=0.0, distAmount=0.0, stereoMode=1,
	timbreLFO=0, morphLFO=0, decayLFO=0, pitchLFO=0, volumeLFO=0, harmLFO=0,
	timbMod=0.0, morphMod=0.0, decayMod=0.0, pitchMod=0.0, volumeMod=0.0, harmMod=0.0,
	amRatio=1.0, amWave=0, amDepth=0.0, amRing=0.0, amFixedHz=0, amRingLFO=0, amRingMod=0, amDepthLFO=0, amDepthMod=0, amRatioLFO=0, amRatioMod=0;

	var sig, env, carrierFreq, amRingEff, amDepthEff, amRatioEff;

	sig = MiPlaits.ar(
		pitch: (pitch + (pitchLFO * pitchMod)).clip(0, 127),
		engine: engine.clip(0, 23),
		harm: (harm + (harmLFO * harmMod)).clip(0, 1),
		timbre: (timbre + (timbreLFO * timbMod)).clip(0, 1),
		morph: (morph + (morphLFO * morphMod)).clip(0, 1),
		trigger: 1,
		decay: (decay + (decayLFO * decayMod)).clip(0, 1),
		fm_mod: fmMod.clip(-1, 1),
		lpg_colour: lpgColour.clip(0, 1),
		mul: mul
	);

	// AM / ring-mod stage (modulator tracks the modulated carrier pitch)
	carrierFreq = (pitch + (pitchLFO * pitchMod)).clip(0, 127).midicps;
	amRingEff  = (amRing  + (amRingLFO  * amRingMod )).clip(0, 1);   // LFO-modulated AM/RM balance
	amDepthEff = (amDepth + (amDepthLFO * amDepthMod)).clip(0, 1);   // LFO-modulated AM amount
	amRatioEff = (amRatio + (amRatioLFO * amRatioMod)).clip(0, 8);   // LFO-modulated modulator ratio
	sig = ~plaitsAMStage.(sig, carrierFreq, amRatioEff, amWave, amDepthEff, amRingEff, amFixedHz);

	env = EnvGen.kr(Env.asr(5, 1, 5), gate, doneAction: Done.freeSelf);

	~plaitsSigChain.(sig, env, out, stereoMode, distDrive, distAmount,
		revTime, revDrywet, revDamp, revHp, revFreeze,
		(volume + (volumeLFO * volumeMod)).clip(0, 2),
		cloudsSend, delaySend, reverbSend);
}).add;

// Server-side LFO — writes bipolar (-0.5 to +0.5) to a control bus
// shape: 0=sine, 1=tri, 2=saw, 3=square, 4=noise (smoothed random)
SynthDef(\lfo, {
	arg out=0, freq=0.125, shape=0, width=0.3;
	var sig = Select.kr(shape, [
		SinOsc.kr(freq),           // 0: sine
		LFTri.kr(freq),            // 1: triangle
		LFSaw.kr(freq),            // 2: saw
		LFPulse.kr(freq, 0, 0.5) - 0.5, // 3: square
		LFNoise1.kr(freq),         // 4: noise
		LFGauss.kr(freq.reciprocal, width, loop: 1) * 2 - 1 // 5: gaussian (width: 0.01-1)
	]);
	Out.kr(out, sig * 0.5);
}).add;

// Reporter — reads per-instance LFO buses and sends values to sclang at 60Hz for VDMX relay
// (matches typical VDMX shader frame rate; lower rates cause stepped/jagged visuals)
// Plaits: timbre/morph/decay/pitch/volume × 3 instances = 15
// Samples: rate/volume × 3 instances = 6
// Total: 21 floats in SendReply
SynthDef(\lfoReporter, {
	arg timbreBus0=0, morphBus0=0, decayBus0=0, pitchBus0=0, volumeBus0=0, harmBus0=0,
	    timbreBus1=0, morphBus1=0, decayBus1=0, pitchBus1=0, volumeBus1=0, harmBus1=0,
	    timbreBus2=0, morphBus2=0, decayBus2=0, pitchBus2=0, volumeBus2=0, harmBus2=0,
	    sRateBus0=0, sVolumeBus0=0,
	    sRateBus1=0, sVolumeBus1=0,
	    sRateBus2=0, sVolumeBus2=0,
	    amRingBus0=0, amRingBus1=0, amRingBus2=0,
	    amDepthBus0=0, amDepthBus1=0, amDepthBus2=0,
	    amRatioBus0=0, amRatioBus1=0, amRatioBus2=0;
	SendReply.kr(
		Impulse.kr(60),
		'/lfoValues',
		[
			In.kr(timbreBus0, 1), In.kr(morphBus0, 1), In.kr(decayBus0, 1), In.kr(pitchBus0, 1), In.kr(volumeBus0, 1), In.kr(harmBus0, 1),
			In.kr(timbreBus1, 1), In.kr(morphBus1, 1), In.kr(decayBus1, 1), In.kr(pitchBus1, 1), In.kr(volumeBus1, 1), In.kr(harmBus1, 1),
			In.kr(timbreBus2, 1), In.kr(morphBus2, 1), In.kr(decayBus2, 1), In.kr(pitchBus2, 1), In.kr(volumeBus2, 1), In.kr(harmBus2, 1),
			In.kr(sRateBus0, 1), In.kr(sVolumeBus0, 1),
			In.kr(sRateBus1, 1), In.kr(sVolumeBus1, 1),
			In.kr(sRateBus2, 1), In.kr(sVolumeBus2, 1),
			In.kr(amRingBus0, 1), In.kr(amRingBus1, 1), In.kr(amRingBus2, 1),
			In.kr(amDepthBus0, 1), In.kr(amDepthBus1, 1), In.kr(amDepthBus2, 1),
			In.kr(amRatioBus0, 1), In.kr(amRatioBus1, 1), In.kr(amRatioBus2, 1)
		]
	);
}).add;

// Filter Delay Send Effect
SynthDef(\globalFilterDelay, {
	arg out=0, time=0.25, feedback=0.3, filterFreq=2000,
	mix=1.0, gate=1, spread=1.5;

	var maxDelayTime = 4;
	var input = In.ar(~delayBus, 2);
	var delayedL, delayedR, filteredL, filteredR, output;
	var env = EnvGen.kr(Env.asr(0.01, 1, 1), gate, doneAction: 2);

	// Initialize filtered signals for ping-pong feedback loop
	#filteredL, filteredR = LocalIn.ar(2);

	// Ping-pong delay: L gets input + R feedback, R gets input + L feedback
	delayedL = DelayL.ar(input.sum + (filteredR * feedback), maxDelayTime, time);
	delayedR = DelayL.ar(input.sum + (filteredL * feedback), maxDelayTime, time * spread);

	// Filter the delayed signals (tape-style)
	filteredL = LPF.ar(delayedL, filterFreq);
	filteredR = LPF.ar(delayedR, filterFreq);
	LocalOut.ar([filteredL, filteredR]);

	// Output 100% wet (mix=1.0) since it's a send effect
	output = [filteredL, filteredR] * mix * env;

	// Distribute to all speaker pairs in multi-channel setups
	if (~numSpeakers > 2) {
		(~numSpeakers / 2).do { |i|
			Out.ar(i * 2, output);
		};
	} {
		Out.ar(out, output);
	};
}).add;

// Global MiVerb Send Effect
SynthDef(\globalReverb, {
	arg out=0, time=0.5, damp=0.5, hp=0.25, diffuse=0.625, freeze=0,
	mix=1.0, gate=1, unfreezeGlide=5.0;

	var input = In.ar(~reverbBus, 2);
	var env = EnvGen.kr(Env.asr(0.01, 1, 2), gate, doneAction: 2);
	var frz = freeze.clip(0, 1);
	var targetTime = time.clip(0, 1.25);

	// Unfreeze glide: while frozen MiVerb pins its internal reverb time to 1.0. On
	// unfreeze it slams set_time(time) in one block, so a lowered time makes the
	// feedback coefficient drop abruptly -> glitch/swell. Ramp the time we feed it
	// from 1.0 down to the target so the frozen swell eases into a decaying tail.
	// freezeHold is derived from the same freeze signal (LagUD: engages instantly on
	// freeze, eases to 0 over unfreezeGlide after unfreeze) — so at the unfreeze
	// block it's still ~1.0, avoiding the trigger/EnvGen latency race that let the
	// set_time jump through.
	var freezeHold = LagUD.kr(frz, 0, unfreezeGlide.max(0.001));
	var effTime = (targetTime * (1 - freezeHold)) + freezeHold;  // 1.0 frozen -> targetTime

	var reverb = MiVerb.ar(
		input,
		time: effTime,
		drywet: 1.0, // Always 100% wet for send effect
		damp: damp.clip(0, 1),
		hp: hp.clip(0, 1),
		freeze: frz,
		diff: diffuse.clip(0, 1),
		mul: mix.clip(0, 2.0)
	);

	var output = LeakDC.ar(reverb * env);

	// Distribute to all speaker pairs in multi-channel setups
	if (~numSpeakers > 2) {
		(~numSpeakers / 2).do { |i|
			Out.ar(i * 2, output);
		};
	} {
		Out.ar(out, output);
	};
}).add;

// Global MiClouds Send Effect
SynthDef(\globalClouds, {
	arg out=0, position=0.0, size=0.0, density=0.5, texture=0.5,
	pitch=0.0, blend=0.5, freeze=0, inGain = 1.0, spread=0.5, reverb=0.0, feedback=0.0, mix=1.0, gate=1, mode=3, lofi=0.0, volume=1.0;

	// var input = InFeedback.ar(~cloudsBus, 2);
	var input = In.ar(~cloudsBus, 2);
	var env = EnvGen.kr(Env.asr(0.01, 1, 2), gate, doneAction: 2);
	var dens = LFNoise1.kr(0.3).range(0.3, 0.45);

	var clouds = MiClouds.ar(
		input,
		pit: pitch.clip(-48, 48),
		pos: position.clip(0, 1),
		size: size.clip(0, 1),
		dens: density.clip(0, 1),
		tex: texture.clip(0, 1),
		drywet: 1,
		in_gain: inGain.clip(0.125, 8),
		spread: spread.clip(0, 1),
		rvb: reverb.clip(0, 1),
		fb: feedback.clip(0, 1),
		freeze: freeze.clip(0, 1),
		mode: mode.clip(0, 3),
		lofi: lofi.clip(0, 1),
		mul: volume.clip(0, 1)
	);

	// clouds = PitchShift.ar(input, 0.2, LFNoise1.kr(0.3).range(0.0, 2.00), 0.0, 0.5) * 0.8;

	// Ring modulation - very audible effect:
	// clouds = clouds * SinOsc.ar(200) * 0.5 + clouds;

	var output = LeakDC.ar(clouds * env * mix.clip(0, 2.0));

	// Distribute to all speaker pairs in multi-channel setups
	if (~numSpeakers > 2) {
		(~numSpeakers / 2).do { |i|
			Out.ar(i * 2, output);
		};
	} {
		Out.ar(out, output);
	};
}).add;

SynthDef(\panningSamplePlayer, {
	|out=0, bufnum=0, numChannels=1, mul=1, rate=1, startPos=0, panDur=5,
	atk=0.01, decay=0.1, gate=1, volume=0.7,
	cloudsSend=0.0, delaySend=0.0, reverbSend=0.0,
	distDrive=0.0, distAmount=0.0,
	revDrywet=0.25, revTime=0.3, revDamp=0.8, revHp=0.7, revFreeze=0,
	rateLFO=0, rateMod=0.0,
	volumeLFO=0, volumeMod=0.0|

	var sig, env, pan, monoPlay, cleanSig, distSig;
	var finalRate = rate + (rateLFO * rateMod);
	var finalVolume = (volume + (volumeLFO * volumeMod)).clip(0, 2);

	// Pan from -1 to 1 over panDur
	pan = Line.kr(-1, 1, panDur);
	env = EnvGen.kr(Env.perc(atk, decay), gate, doneAction: Done.freeSelf);

	// Always read as mono (works for both mono and stereo buffers)
	monoPlay = PlayBuf.ar(
		numChannels: 1,
		bufnum: bufnum,
		rate: finalRate * BufRateScale.kr(bufnum),
		startPos: startPos,
		doneAction: 0
	);

	// Pan and convert to stereo
	sig = Pan2.ar(monoPlay, pan);

	sig = sig * mul;

	// Distortion (same as plaits)
	cleanSig = sig;
	distSig = CrossoverDistortion.ar(sig, distDrive.clip(0.1, 2.0), 0.5);
	sig = (cleanSig * (1 - distAmount.clip(0, 1))) + (distSig * distAmount.clip(0, 1));

	// Sanitize to kill denormals, infs, and NaNs
	sig = sig.sanitize;

	// MiVerb insert effect (same as plaits - apply env at input)
	sig = MiVerb.ar(
		(sig * env).tanh,
		time: revTime.clip(0, 1.25),
		drywet: revDrywet.clip(0, 1),
		damp: revDamp.clip(0, 1),
		hp: revHp.clip(0, 1),
		freeze: revFreeze.clip(0, 1),
		diff: 0.625,
		mul: finalVolume,
		add: 0.0
	);

	// Send to FX buses
	Out.ar(~cloudsBus, sig * cloudsSend);
	Out.ar(~delayBus, sig * delaySend);
	Out.ar(~reverbBus, sig * reverbSend);

	Out.ar(out, LeakDC.ar(sig.tanh));
}).add;

SynthDef(\samplePlayer, {
    |out=0, bufnum=0, amp=1, rate=1, startPos=0, atk=0.01, rel=0.1, gate=1|

    var sig, env;

    env = EnvGen.kr(Env.asr(atk, 1, rel), gate, doneAction: 2);

    sig = PlayBuf.ar(
        numChannels: 1,
        bufnum: bufnum,
        rate: rate * BufRateScale.kr(bufnum),
		startPos: startPos,
        doneAction: 0
    );

    sig = sig * env * amp;
    Out.ar(out, sig);
}).add;

)
