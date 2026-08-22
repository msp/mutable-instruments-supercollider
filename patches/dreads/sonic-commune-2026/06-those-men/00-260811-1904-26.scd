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
			(amDepth: 0.0, amFixedHz: 0.0, amRatio: 1.0, amRing: 0.0, amWave: 0.0, cloudsSend: 0.0, decay: 0.3, decayMod: 0.0, delaySend: 0.0, distAmount: 0.0, distDrive: 0.0, droneMode: 0.0, dur: 0.5, engine: 13.0, fmMod: 0.8, harm: 0.35, harmMod: 0.0, legato: 8.0, lpgColour: 0.5, morph: 0.81, morphMod: 0.3, mul: 0.5, mute: 0.0, phaseOffset: 0.75, pitch: 30.0, pitchMod: 0.0, releaseTime: 1.0, revDamp: 0.88, revDrywet: 0.0, revFreeze: 0.0, revHp: 0.0, revTime: 0.76, reverbSend: 0.0, sendToPhones: 0.0, speed: 1.0, stereoMode: 1.0, tempo: 140.0, timbMod: 0.2, timbre: 0.45, volume: 1.75, volumeMod: 0.0),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				duration: Pseq([
					Pwrand([0.5, Rest(0.5)], [0.9, 0.1].normalizeSum),
					Pwrand([0.5, Rest(0.5)], [0.2, 0.8].normalizeSum),
					Pwrand([0.5, Rest(0.5)], [0.6, 0.4].normalizeSum),
					Pwrand([0.5, Rest(0.5)], [0.1, 0.9].normalizeSum)
				], inf).asStream,
				// duration: \hold,
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
			(amDepth: 0.0, amFixedHz: 0.0, amRatio: 1.0, amRing: 0.0, amWave: 0.0, cloudsSend: 0.0, decay: 0.65, decayMod: 0.0, delaySend: 0.0, distAmount: 0.0, distDrive: 0.0, droneMode: 0.0, dur: Rest(0.25), engine: 19.0, fmMod: -0.02, harm: 0.63, harmMod: 0.0, legato: 15.0, lpgColour: 0.5, morph: 0.13, morphMod: 0.68, mul: 0.5, mute: 1.0, phaseOffset: -0.25, pitch: 42.0, pitchMod: 0.0, releaseTime: 1.0, revDamp: 0.04, revDrywet: 0.25, revFreeze: 0.0, revHp: 0.47, revTime: 0.84, reverbSend: 0.49, sendToPhones: 0.0, speed: 1.0, stereoMode: 1.0, tempo: 140.0, timbMod: 0.6, timbre: 0.3, volume: 0.51, volumeMod: 0.5),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				div: \unit,
				// duration: \eucl_5_16,
				// [0.25, Rest(0.25), Rest(0.25), 0.25, Rest(0.25), Rest(0.25), 0.25, Rest(0.25)]
				duration: Pseq([
					0.25,       Rest(0.25), Rest(0.25), 0.25,       Rest(0.25), Rest(0.25), 0.25,       Rest(0.25),
					Rest(0.25), Rest(0.25), Rest(0.25), Rest(0.25), 0.25,       Rest(0.25), Rest(0.25), Rest(0.25),
					// Rest(0.25), Rest(0.25), Rest(0.25), Rest(0.25), 0.25,       Rest(0.25),
 				], inf).asStream,
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
			(amDepth: 0.0, amFixedHz: 0.0, amRatio: 1.0, amRing: 0.0, amWave: 0.0, cloudsSend: 0.02, decay: 0.68, decayMod: 0.0, delaySend: 0.57, distAmount: 0.0, distDrive: 0.0, droneMode: 0.0, dur: Rest(0.5), engine: 18.0, fmMod: 0.01, harm: 0.2, harmMod: 0.0, legato: 9.0, lpgColour: 0.5, morph: 0.28, morphMod: 0.58, mul: 0.5, mute: 0.0, phaseOffset: -0.25, pitch: 42.0, pitchMod: 0.0, releaseTime: 1.0, revDamp: 0.76, revDrywet: 0.11, revFreeze: 0.0, revHp: 0.72, revTime: 0.88, reverbSend: 0.15, sendToPhones: 0.0, speed: 1.0, stereoMode: 1.0, tempo: 140.0, timbMod: 0.06, timbre: 0.28, volume: 1.11, volumeMod: 0.0),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				div: \unit,
				// duration: \eucl_3_8,
				// [0.5, Rest(0.5), Rest(0.5), 0.5, Rest(0.5), Rest(0.5), 0.5, Rest(0.5)]
				duration: Pseq([
					0.5,       Rest(0.5), Rest(0.5), 0.5,       Rest(0.5), Rest(0.5), 0.5,       Rest(0.5),
					Rest(0.5), Rest(0.5), Rest(0.5), Rest(0.5), Rest(0.5), Rest(0.5), Rest(0.5), Rest(0.5),
					Rest(0.5), Rest(0.5), Rest(0.5), Rest(0.5), Rest(0.5)
					// Rest(0.5), Rest(0.5), Rest(0.5), Rest(0.5), Rest(0.5), Rest(0.5), Rest(0.5), Rest(0.5),
				], inf).asStream,

				pitch: \hold,
				delaySend: \gate_every8,
				revDrywet: \sine_slow,
				decay: \gate_every8,
				distAmount: \gate_every5,
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
			(atk: 0.43, bankName: 'HATS', cloudsSend: 0.4, decay: 0.55, delaySend: 0.53, distAmount: 0.19, distDrive: 0.0, dur: 1.0, legato: 0.7, mul: 1.0, mute: 1.0, panDur: 0.24, phaseOffset: -0.25, rate: 3.39, rateMod: 0.3, revDamp: 0.8, revDrywet: 0.47, revFreeze: 0.0, revHp: 0.0, revTime: 0.92, reverbSend: 0.14, speed: 1.0, startPos: 0.15, tempo: 140.0, variant: 1.0, volume: 1.48, volumeMod: 1.0),
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
			(atk: 0.18, bankName: 'msp-summer2026', cloudsSend: 0.0, decay: 0.13, delaySend: 0.0, distAmount: 0.05, distDrive: 0.06, dur: Rest(2.0), legato: 0.7, mul: 1.0, mute: 0.0, panDur: 0.06, phaseOffset: 0.75, rate: 3.95, rateMod: 0.0, revDamp: 0.44, revDrywet: 0.74, revFreeze: 0.0, revHp: 0.8, revTime: 0.64, reverbSend: 0.29, speed: 0.25, startPos: 0.1, tempo: 140.0, variant: 0.0, volume: 1.31, volumeMod: 0.0),
			// $PRESET_SAMPLE_SCALARS_END
			// $PRESET_SAMPLE_SEQUENCES_START
			(
				div: \unit,
				// div: Pseq([1/8], inf).asStream,
				rate: \hold,
				mul: \unit,
				// duration: \offbeat,
				duration: Pseq([
					Rest(0.5),
					Pwrand([0.5, Rest(0.5)], [0.9, 0.1].normalizeSum),
					Rest(0.5),
					Pwrand([0.5, Rest(0.5)], [0.8, 0.2].normalizeSum),
				], inf).asStream,
				decay: \hold,
				distAmount: \hold,
				delaySend: \hold,
				revDrywet: \hold,
				startPos: Pseq([0.8, 0.32, 0.24, 0.01, 0.26, 0.99, 0.12, 0.18, 0.03, 0.98], inf).asStream,
				panDur: Pseq([0.4, 0.69, 0.89, 0.35, 0.11, 0.41, 0.7, 0.28, 0.17, 0.99, 0.67, 0.05, 0.2, 0.64], inf).asStream,
			),
			// $PRESET_SAMPLE_SEQUENCES_END
			// $PRESET_SAMPLE_LFO_START
			()
			// $PRESET_SAMPLE_LFO_END
		),

		// $SAMPLE3
		~sampleFactory.(
			// $PRESET_SAMPLE_SCALARS_START
			(atk: 0.22, bankName: 'HATS', cloudsSend: 0.1, decay: 0.87, delaySend: 0.63, distAmount: 0.21, distDrive: 0.0, dur: Rest(0.5), legato: 0.7, mul: 1.0, mute: 0.0, panDur: 0.5, phaseOffset: 0.25, rate: 1.0, rateMod: 0.05, revDamp: 0.8, revDrywet: 0.47, revFreeze: 0.0, revHp: 0.81, revTime: 0.3, reverbSend: 0.0, speed: 0.5, startPos: 0.19, tempo: 140.0, variant: 2.0, volume: 1.05, volumeMod: 0.0),
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
	clouds: (blend: 0.26, density: 0.93, feedback: 0.53, freeze: 0.0, inGain: 1.0, lofi: 0.0, mix: 1.0, mode: 3.0, pitch: 1.92, position: 0.69, reverb: 0.55, size: 0.27, spread: 0.5, texture: 0.59, volume: 0.2),
	delay: (feedback: 0.74, filterFreq: 3251.58, spread: 1.5, time: 0.43),
	reverb: (damp: 0.0, diffuse: 0.28, freeze: 1.0, hp: 0.15, time: 0.31)
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
	lfo7: (freq: 1.1474184989929, shape: 1), // plaits 1 timbre
	lfo8: (freq: 1.0, shape: 4), // plaits 1 morph
	lfo11: (freq: 0.2), // plaits 1 volume
	lfo13: (freq: 0.93332344293594, shape: 1, base: true), // plaits 2 timbre
	lfo14: (freq: 1, base: true), // plaits 2 morph
	lfo15: (freq: 6), // plaits 2 decay
	lfo16: (freq: 0.33333333333333, shape: 4), // plaits 2 pitch
	lfo17: (freq: 1), // plaits 2 volume
	lfo19: (freq: 0.083333333333333), // sample 0 rate
	lfo20: (freq: 0.85935586690903), // sample 0 volume
	lfo21: (freq: 0.72644079327583, shape: 2), // sample 1 rate
);
~base = 2.1;
// $LFO_SOURCES_END

// ~base = 0.5;
// ~dreads.lfoSources[\lfo1].freq = ~base + 0.04;
// ~dreads.lfoSources[\lfo4].freq = ~base + 0.03;
// ~dreads.lfoSources[\lfo5].freq = ~base;
// ~dreads.lfoSources[\lfo5].freq = ~base/5;

~applyPatch.();
)

