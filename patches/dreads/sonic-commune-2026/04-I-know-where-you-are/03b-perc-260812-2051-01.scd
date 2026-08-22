////////////////////////////////////////////////////////////////////////////////
// FM Patch Preview Preset
// PLAITS1 configured for clean FM auditioning — load this, then run fm-patches.scd
////////////////////////////////////////////////////////////////////////////////
(
~dreads = ~patchFactory.(
	// Synth instances array
	[
		// $PLAITS1
		~plaitsFactory.(
			// $PRESET_SCALARS_START
			(amDepth: 0.0, amFixedHz: 0.0, amRatio: 1.0, amRing: 0.0, amWave: 0.0, cloudsSend: 0.0, decay: 0.73, decayMod: 0.0, delaySend: 0.0, distAmount: 0.0, distDrive: 0.0, droneMode: 0.0, dur: Rest(0.5), engine: 13.0, fmMod: 0.38, harm: 0.35, harmMod: 0.0, legato: 8.0, lpgColour: 0.5, morph: 0.79, morphMod: 0.13, mul: 0.5, mute: 0.0, phaseOffset: 0.75, pitch: 30.0, pitchMod: 0.0, releaseTime: 1.0, revDamp: 0.88, revDrywet: 0.0, revFreeze: 0.0, revHp: 0.0, revTime: 0.76, reverbSend: 0.0, sendToPhones: 0.0, speed: 1.0, stereoMode: 1.0, tempo: 130.0, timbMod: 0.2, timbre: 0.45, volume: 1.3, volumeMod: 0.0),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				duration: \eucl_3_8,
				div: \unit,
				delaySend: \gate_every8,
				cloudsSend: \gate_prob20,
				revDrywet: \hold,
				harm: \gate_every4,
				pitch: \hold,
				morph: \hold,
				timbre: \hold,
				distAmount: \gate_every4,
			),
			// $PRESET_SEQUENCES_END
			// $PRESET_LFO_START
			()
			// $PRESET_LFO_END
		),

		// $PLAITS2
		~plaitsFactory.(
			// $PRESET_SCALARS_START
			(amDepth: 0.0, amFixedHz: 0.0, amRatio: 1.0, amRing: 0.0, amWave: 0.0, cloudsSend: 0.0, decay: 0.59, decayMod: 0.0, delaySend: 0.29, distAmount: 0.0, distDrive: 0.0, droneMode: 1.0, dur: Rest(0.25), engine: 6.0, fmMod: -0.15, harm: 0.22, harmMod: 0.42, legato: 15.0, lpgColour: 0.83, morph: 0.64, morphMod: 0.0, mul: 0.5, mute: 0.0, phaseOffset: -0.25, pitch: 36.0, pitchMod: 0.0, releaseTime: 1.0, revDamp: 0.04, revDrywet: 0.24, revFreeze: 0.0, revHp: 0.47, revTime: 0.84, reverbSend: 0.16, sendToPhones: 0.0, speed: 1.0, stereoMode: 1.0, tempo: 130.0, timbMod: 0.35, timbre: 0.35, volume: 1.25, volumeMod: 0.88),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				div: \unit,
				duration: \eucl_5_16,
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
			(amDepth: 0.0, amFixedHz: 0.0, amRatio: 1.0, amRing: 0.8, amWave: 0.0, cloudsSend: 0.2, decay: 0.1, decayMod: 0.61, delaySend: 0.35, distAmount: 0.0, distDrive: 0.0, droneMode: 0.0, dur: Rest(0.25), engine: 18.0, fmMod: 1.0, harm: 0.2, harmMod: 0.0, legato: 0.1, lpgColour: 0.5, morph: 0.31, morphMod: 0.12, mul: 0.5, mute: 0.0, phaseOffset: 0.0, pitch: 42.0, pitchMod: 0.0, releaseTime: 0.05, revDamp: 0.76, revDrywet: 0.11, revFreeze: 0.0, revHp: 0.72, revTime: 0.88, reverbSend: 0.0, sendToPhones: 0.0, speed: 1.0, stereoMode: 1.0, tempo: 130.0, timbMod: 0.0, timbre: 0.82, volume: 1.3, volumeMod: 0.3),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				div: \unit,
				// duration: \eucl_7_16,
				duration: Pseq([
					0.25, Rest(0.25), Rest(0.25), 0.25, Rest(0.25), 0.25, Rest(0.25), 0.25, Rest(0.25), Rest(0.25), 0.25, Rest(0.25), 0.25, Rest(0.25), 0.25, Rest(0.25),
					0.25, Rest(0.25), Rest(0.25), 0.25, Rest(0.25), 0.25, Rest(0.25), 0.25, Rest(0.25), Rest(0.25), 0.25, Rest(0.25), 0.25
					// Pwrand([1/2, Rest(1/2)], [1.0, 0.0].normalizeSum, 1),
				], inf).asStream,
				pitch: \hold,
				delaySend: \gate_every32,
				revDrywet: \sine_slow,
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
			(atk: 0.43, bankName: 'HATS', cloudsSend: 0.0, decay: 0.83, delaySend: 0.65, distAmount: 0.29, distDrive: 0.0, dur: 1.0, legato: 0.7, mul: 1.0, mute: 0.0, panDur: 0.24, phaseOffset: -0.25, rate: 3.74, rateMod: 0.3, revDamp: 0.8, revDrywet: 0.47, revFreeze: 0.0, revHp: 0.0, revTime: 0.92, reverbSend: 0.14, speed: 1.0, startPos: 0.0, tempo: 130.0, variant: 1.0, volume: 0.75, volumeMod: 1.0),
			// $PRESET_SAMPLE_SCALARS_END
			// $PRESET_SAMPLE_SEQUENCES_START
			(
				div: \unit,
				rate: \hold,
				mul: \unit,
				duration: \unit,
				startPos: \hold,
				distAmount: \gate_every3,
				decay: \hold,
				atk: \sine_slow,
			),
			// $PRESET_SAMPLE_SEQUENCES_END
			// $PRESET_SAMPLE_LFO_START
			()
			// $PRESET_SAMPLE_LFO_END
		),

		// $SAMPLE2
		~sampleFactory.(
			// $PRESET_SAMPLE_SCALARS_START
			(atk: 0.0, bankName: 'CLAPS', cloudsSend: 0.09, decay: 0.83, delaySend: 0.0, distAmount: 0.5, distDrive: 0.0, dur: 2.0, legato: 0.7, mul: 1.0, mute: 1.0, panDur: 0.5, phaseOffset: 0.75, rate: 1.0, rateMod: 0.0, revDamp: 0.59, revDrywet: 0.39, revFreeze: 0.0, revHp: 0.14, revTime: 1.11, reverbSend: 0.0, speed: 0.25, startPos: 0.0, tempo: 130.0, variant: 2.0, volume: 0.99, volumeMod: 0.0),
			// $PRESET_SAMPLE_SCALARS_END
			// $PRESET_SAMPLE_SEQUENCES_START
			(
				div: \unit,
				rate: \unit,
				mul: \unit,
				duration: \offbeat,
				decay: \gate_every3,
				distAmount: \gate_every5,
				delaySend: \gate_every5,
				revDrywet: \gate_every4,
			),
			// $PRESET_SAMPLE_SEQUENCES_END
			// $PRESET_SAMPLE_LFO_START
			()
			// $PRESET_SAMPLE_LFO_END
		),

		// $SAMPLE3
		~sampleFactory.(
			// $PRESET_SAMPLE_SCALARS_START
			(atk: 0.22, bankName: 'HATS', cloudsSend: 0.25, decay: 0.87, delaySend: 0.58, distAmount: 0.21, distDrive: 0.0, dur: Rest(0.5), legato: 0.7, mul: 1.0, mute: 1.0, panDur: 0.5, phaseOffset: 0.25, rate: 1.0, rateMod: 0.0, revDamp: 0.8, revDrywet: 0.47, revFreeze: 0.0, revHp: 0.81, revTime: 0.3, reverbSend: 0.0, speed: 0.5, startPos: 0.19, tempo: 130.0, variant: 2.0, volume: 1.18, volumeMod: 0.0),
			// $PRESET_SAMPLE_SCALARS_END
			// $PRESET_SAMPLE_SEQUENCES_START
			(
				div: \unit,
				rate: \unit,
				mul: \unit,
				duration: \eucl_5_16,
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
	clouds: (blend: 0.26, density: 0.93, feedback: 0.55, freeze: 0.0, inGain: 1.0, lofi: 0.0, mix: 1.0, mode: 3.0, pitch: 1.92, position: 0.69, reverb: 0.55, size: 0.27, spread: 0.5, texture: 0.59, volume: 0.83),
	delay: (feedback: 0.68, filterFreq: 4046.17, spread: 1.5, time: 0.46),
	reverb: (damp: 0.07, diffuse: 0.28, freeze: 1.0, hp: 0.27, time: 0.27)
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
	lfo1: (freq: 1.2, shape: 2), // plaits 0 timbre
	lfo2: (freq: 1.56), // plaits 0 morph
	lfo3: (freq: 0.16666666666667), // plaits 0 decay
	lfo4: (freq: 1.2, shape: 3), // plaits 0 pitch
	lfo5: (freq: 1.2), // plaits 0 volume
	lfo6: (freq: 1.0), // plaits 0 harm
	lfo7: (freq: 1.0700000524521, shape: 1, base: true), // plaits 1 timbre
	lfo8: (freq: 0.070000000298023, shape: 4, base: true), // plaits 1 morph
	lfo11: (freq: 0.60000002384186), // plaits 1 volume
	lfo12: (freq: 1.0599999427795, shape: 4), // plaits 1 harm
	lfo13: (freq: 2.5888495445251), // plaits 2 timbre
	lfo14: (freq: 1), // plaits 2 morph
	lfo15: (freq: 0.5), // plaits 2 decay
	lfo16: (freq: 0.33333333333333, shape: 4), // plaits 2 pitch
	lfo17: (freq: 0.059999998658895), // plaits 2 volume
	lfo19: (freq: 0.083333333333333), // sample 0 rate
	lfo20: (freq: 0.85935586690903), // sample 0 volume
	lfo21: (freq: 0.083333333333333), // sample 1 rate
);
~base = 1.0;
// $LFO_SOURCES_END

// ~base = 0.5;
// ~dreads.lfoSources[\lfo1].freq = ~base + 0.04;
// ~dreads.lfoSources[\lfo4].freq = ~base + 0.03;
// ~dreads.lfoSources[\lfo5].freq = ~base;
// ~dreads.lfoSources[\lfo5].freq = ~base/5;

~applyPatch.();
)

