////////////////////////////////////////////////////////////////////////////////
// Radigue-style drone — two detuned VA drones (a fifth apart) with gentle AM that
// drifts AM<->RM over minutes. Slow tempo, deep pitch, long reverb wash. Play, then
// leave it. (amRatio LFO drift is phase 2; for now the drift is stepped via sweep_slow.)
////////////////////////////////////////////////////////////////////////////////
(
~dreads = ~patchFactory.(
	// Synth instances array
	[
		// $PLAITS1
		~plaitsFactory.(
			// $PRESET_SCALARS_START
			(amDepth: 0.11, amFixedHz: 0.0, amRatio: 5.14, amRing: 0.05, amWave: 1.0, cloudsSend: 0.0, decay: 0.57, decayMod: 0.0, delaySend: 0.0, distAmount: 0.0, distDrive: 0.0, droneMode: 1.0, dur: 0.5, engine: 22.0, fmMod: 0.01, harm: 0.29, harmMod: 0.0, legato: 4.0, lpgColour: 0.6, morph: 0.5, morphMod: 0.11, mul: 0.5, mute: 0.0, phaseOffset: 0.0, pitch: 36.0, pitchMod: 0.0, revDamp: 0.0, revDrywet: 0.67, revFreeze: 0.0, revHp: 0.65, revTime: 0.95, reverbSend: 0.0, sendToPhones: 0.0, speed: 1.0, stereoMode: 1.0, tempo: 81.22, timbMod: 0.06, timbre: 0.17, volume: 0.31, volumeMod: 0.77),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				duration: \hold,
				div: \unit,
				amRing: \sweep_slow,

				// amRing: \sweep_slow,       // slow AM<->RM drift (stepped)
				cloudsSend: \sine_slow,
				revDrywet: \hold,
				delaySend: \hold,
				pitch: \hold,
				timbre: \hold,
			),
			// $PRESET_SEQUENCES_END
			// $PRESET_LFO_START
			()
			// $PRESET_LFO_END
		),

		// $PLAITS2
		~plaitsFactory.(
			// $PRESET_SCALARS_START
			(amDepth: 0.0, amFixedHz: 0.0, amRatio: 1.92, amRing: 0.54, amWave: 0.0, cloudsSend: 0.0, decay: 0.85, decayMod: 0.0, delaySend: 0.0, distAmount: 0.0, distDrive: 0.0, droneMode: 1.0, dur: 1.0, engine: 20.0, fmMod: 0.0, harm: 0.21, harmMod: 0.0, legato: 15.0, lpgColour: 0.5, morph: 0.5, morphMod: 0.0, mul: 0.5, mute: 0.0, phaseOffset: 0.0, pitch: 43.05, pitchMod: 0.0, revDamp: 0.48, revDrywet: 0.0, revFreeze: 0.0, revHp: 0.63, revTime: 0.95, reverbSend: 0.0, sendToPhones: 0.0, speed: 0.5, stereoMode: 1.0, tempo: 81.22, timbMod: 0.49, timbre: 0.4, volume: 0.38, volumeMod: 0.39),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				div: \unit,
				duration: \hold,
				amRing: \sine_slow,

				// amRing: \sine_slow,        // slow AM<->RM drift (different shape to plaits1, so they diverge)
				pitch: \hold,
			),
			// $PRESET_SEQUENCES_END
			// $PRESET_LFO_START
			()
			// $PRESET_LFO_END
		),

		// $PLAITS3
		~plaitsFactory.(
			// $PRESET_SCALARS_START
			(amDepth: 0.09, amFixedHz: 0.0, amRatio: 1.81, amRing: 0.15, amWave: 0.0, cloudsSend: 0.65, decay: 0.75, decayMod: 0.0, delaySend: 0.66, distAmount: 0.0, distDrive: 0.0, droneMode: 1.0, dur: 1.0, engine: 20.0, fmMod: 0.0, harm: 0.2, harmMod: 0.0, legato: 9.0, lpgColour: 0.5, morph: 0.31, morphMod: 0.05, mul: 0.5, mute: 0.0, phaseOffset: 0.0, pitch: 52.0, pitchMod: 0.0, revDamp: 0.17, revDrywet: 0.77, revFreeze: 0.0, revHp: 1.0, revTime: 0.88, reverbSend: 0.25, sendToPhones: 0.0, speed: 0.5, stereoMode: 1.0, tempo: 81.22, timbMod: 0.0, timbre: 0.3, volume: 0.32, volumeMod: 0.37),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				div: \unit,
				duration: \hold,
				pitch: \hold,
				amDepth: \sweep_slow,
			),
			// $PRESET_SEQUENCES_END
			// $PRESET_LFO_START
			()
			// $PRESET_LFO_END
		)
	],
	// Samples array
	[
		// $SAMPLE1
		~sampleFactory.(
			// $PRESET_SAMPLE_SCALARS_START
			(atk: 0.22, bankName: 'halfmastv6', cloudsSend: 0.83, decay: 0.62, delaySend: 0.0, distAmount: 0.0, distDrive: 0.0, dur: 64.0, legato: 0.7, mul: 1.0, mute: 0.0, panDur: 0.76, phaseOffset: 0.0, rate: 2.0, rateMod: 0.04, revDamp: 0.2, revDrywet: 0.95, revFreeze: 0.0, revHp: 0.87, revTime: 0.92, reverbSend: 0.14, speed: 0.25, startPos: 0.19, tempo: 81.22, variant: 3.0, volume: 0.05, volumeMod: 0.0),
			// $PRESET_SAMPLE_SCALARS_END
			// $PRESET_SAMPLE_SEQUENCES_START
			(
				div: Pseq([1/32], inf).asStream,
				rate: \hold,
				mul: \unit,
				duration: \hold,
				startPos: \rndm_walk_slow,
				distAmount: \hold,
				decay: \sine_slow,
				atk: \sine_slow,
				revDrywet: \sweep_slow,
			),
			// $PRESET_SAMPLE_SEQUENCES_END
			// $PRESET_SAMPLE_LFO_START
			()
			// $PRESET_SAMPLE_LFO_END
		),

		// $SAMPLE2
		~sampleFactory.(
			// $PRESET_SAMPLE_SCALARS_START
			(atk: 0.0, bankName: 'KICKS', cloudsSend: 0.0, decay: 1.0, delaySend: 0.47, distAmount: 0.31, distDrive: 0.0, dur: 2.0, legato: 0.7, mul: 1.0, mute: 1.0, panDur: 0.5, phaseOffset: 0.0, rate: 0.5, rateMod: 0.0, revDamp: 0.8, revDrywet: 0.69, revFreeze: 0.0, revHp: 0.0, revTime: 0.64, reverbSend: 0.0, speed: 0.5, startPos: 0.0, tempo: 81.22, variant: 3.0, volume: 1.33, volumeMod: 0.0),
			// $PRESET_SAMPLE_SCALARS_END
			// $PRESET_SAMPLE_SEQUENCES_START
			(
				div: \unit,
				rate: \unit,
				mul: \unit,
				duration: \unit,
			),
			// $PRESET_SAMPLE_SEQUENCES_END
			// $PRESET_SAMPLE_LFO_START
			()
			// $PRESET_SAMPLE_LFO_END
		),

		// $SAMPLE3
		~sampleFactory.(
			// $PRESET_SAMPLE_SCALARS_START
			(atk: 0.0, bankName: 'default', cloudsSend: 0.0, decay: 0.5, delaySend: 0.0, distAmount: 0.0, distDrive: 0.0, dur: 1.0, legato: 0.7, mul: 1.0, mute: 1.0, panDur: 0.5, phaseOffset: 0.0, rate: 1.0, rateMod: 0.0, revDamp: 0.8, revDrywet: 0.6, revFreeze: 0.0, revHp: 0.09, revTime: 0.3, reverbSend: 0.0, speed: 1.0, startPos: 0.0, tempo: 81.22, variant: 0.0, volume: 0.82, volumeMod: 0.0),
			// $PRESET_SAMPLE_SCALARS_END
			// $PRESET_SAMPLE_SEQUENCES_START
			(
				div: \unit,
				rate: \unit,
				mul: \unit,
				duration: \unit,
			),
			// $PRESET_SAMPLE_SEQUENCES_END
			// $PRESET_SAMPLE_LFO_START
			()
			// $PRESET_SAMPLE_LFO_END
		)
	],
	// Global FX settings
	// $PRESET_FX_START
(
	clouds: (blend: 0.5, density: 0.58, feedback: 0.49, freeze: 0.0, inGain: 1.0, lofi: 0.0, mix: 1.0, mode: 3.0, pitch: 0.5, position: 0.36, reverb: 0.0, size: 0.74, spread: 0.5, texture: 0.4, volume: 0.84),
	delay: (feedback: 0.36, filterFreq: 7133.86, spread: 1.5, time: 0.72),
	reverb: (damp: 0.6, diffuse: 0.63, freeze: 0.0, hp: 0.26, time: 0.47)
),
	// $PRESET_FX_END
);

~states = Pseq([\a, \b, \c, \d], inf).asStream;
~state = ~states.next;
~playCount = 0;
~tempoClock.tempo = ~dreads.synths[0].tempo/60;


// ~drones[0].set(\volumeMod, 0.0);
// ~drones[0].set(\pitchMod, 0.6);


// ~dreads.samples[0].volume = 0.9;
// ~dreads.samples[0][\volumeMod] = 0.9;
// ~dreads.samples[0][\rateMod] = 0.9;
//
// ~dreads.synths[0][\volume] = 0.8;
// ~dreads.synths[0].volume = 0.3;


// $LFO_SOURCES_START
~dreads.lfoSources = (
	lfo1: (freq: 0.10000000149012, base: true), // plaits 0 timbre
	lfo2: (freq: 0.5, base: true), // plaits 0 morph
	lfo3: (freq: 0.16666666666667), // plaits 0 decay
	lfo4: (freq: 0.8305327296257, base: true), // plaits 0 pitch
	lfo5: (freq: 0.050000000745058, base: true), // plaits 0 volume
	lfo6: (freq: 4, base: true), // plaits 0 harm
	lfo8: (freq: 0.16666666666667), // plaits 1 morph
	lfo11: (freq: 0.2, base: true), // plaits 1 volume
	lfo13: (freq: 0.16666666666667), // plaits 2 timbre
	lfo14: (freq: 1), // plaits 2 morph
	lfo15: (freq: 6), // plaits 2 decay
	lfo16: (freq: 0.33333333333333, shape: 4), // plaits 2 pitch
	lfo17: (freq: 1.0, base: true), // plaits 2 volume
	lfo19: (freq: 0.083333333333333), // sample 0 rate
	lfo21: (freq: 0.083333333333333), // sample 1 rate
);
~base = 0.5;
// $LFO_SOURCES_END

// ~base = 0.5;
// ~dreads.lfoSources[\lfo1].freq = ~base + 0.04;
// ~dreads.lfoSources[\lfo4].freq = ~base + 0.03;
// ~dreads.lfoSources[\lfo5].freq = ~base;
// ~dreads.lfoSources[\lfo5].freq = ~base/5;

~applyPatch.();

// --- livecoding area ---5


// ~base = 0.3;
//
// ~lfoTweak.(\plaits, 0, \volume, (freq: ~base, shape: \sine, width: 0.3, mod: 0.0));
// ~lfoTweak.(\plaits, 0, \morph, (freq: ~base*2, shape: \noise, width: 0.3, mod: 0.0));
// ~lfoTweak.(\plaits, 0, \pitch, (freq: ~base/3, shape: \sine, mod: 0.0));
// ~lfoTweak.(\plaits, 0, \timbre, (freq: ~base*5, shape: \sine, mod: 0.0));
//
// ~setLFOBase.(0.3);
)
