////////////////////////////////////////////////////////////////////////////////
// Dreads Patch with global FX
////////////////////////////////////////////////////////////////////////////////
(
~dreads = ~patchFactory.(
	// Synth instances array
	[
		// $PLAITS1
		~plaitsFactory.(
			// $PRESET_SCALARS_START
			(amDepth: 0.0, amFixedHz: 0.0, amRatio: 1.0, amRing: 0.0, amWave: 0.0, cloudsSend: 0.0, decay: 0.5, decayMod: 0.3, delaySend: 0.99, distAmount: 0.18, distDrive: 0.0, droneMode: 1.0, dur: 1.0, engine: 2.0, fmMod: 0.07, harm: 0.46, harmMod: 0.0, legato: 0.05, lpgColour: 0.5, morph: 0.24, morphMod: 0.29, mul: 0.5, mute: 0.0, phaseOffset: 0.0, pitch: 45.32, pitchMod: 0.0, releaseTime: 1.0, revDamp: 0.8, revDrywet: 0.72, revFreeze: 0.0, revHp: 0.23, revTime: 0.73, reverbSend: 0.0, sendToPhones: 0.0, speed: 1.0, stereoMode: 1.0, tempo: 80.63, timbMod: 0.0, timbre: 0.04, volume: 0.66, volumeMod: 0.0),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				morph: \updown,
				// timbre: \hold,
				// distAmount: \gate_every16,
			div: \unit,
			duration: \unit,
			),
			// $PRESET_SEQUENCES_END
			// $PRESET_LFO_START
			()
			// $PRESET_LFO_END
		),

		// $PLAITS2
		~plaitsFactory.(
			// $PRESET_SCALARS_START
			(amDepth: 0.0, amFixedHz: 0.0, amRatio: 1.0, amRing: 0.0, amWave: 0.0, cloudsSend: 0.1, decay: 0.08, decayMod: 0.3, delaySend: 0.38, distAmount: 0.0, distDrive: 0.0, droneMode: 0.0, dur: 3.73, engine: 2.0, fmMod: -0.03, harm: 0.4, harmMod: 0.0, legato: 9.0, lpgColour: 0.5, morph: 0.53, morphMod: 0.73, mul: 0.5, mute: 1.0, phaseOffset: 0.5, pitch: 79.85, pitchMod: 0.0, releaseTime: 1.0, revDamp: 0.55, revDrywet: 0.0, revFreeze: 0.0, revHp: 0.61, revTime: 1.06, reverbSend: 0.63, sendToPhones: 0.0, speed: 0.25, stereoMode: 1.0, tempo: 80.63, timbMod: 0.8, timbre: 0.6, volume: 0.64, volumeMod: 0.0),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				// duration: \hold,
				duration: \sine,
				// duration: Pseq([Rest(1/4), 1/4], inf).asStream,
				div: \unit,
				pitch: \hold,
				timbre: \gate_every8,
			decay: \sine_slow,
				delaySend: \gate_prob20,
			),
			// $PRESET_SEQUENCES_END
			// $PRESET_LFO_START
			()
			// $PRESET_LFO_END
		),

		// $PLAITS3
		~plaitsFactory.(
			// $PRESET_SCALARS_START
			(amDepth: 0.0, amFixedHz: 0.0, amRatio: 1.0, amRing: 0.0, amWave: 0.0, cloudsSend: 0.0, decay: 0.35, decayMod: 0.3, delaySend: 0.0, distAmount: 0.02, distDrive: 0.0, droneMode: 1.0, dur: 0.25, engine: 12.0, fmMod: 0.01, harm: 0.32, harmMod: 0.0, legato: 4.0, lpgColour: 0.5, morph: 0.18, morphMod: 0.2, mul: 0.5, mute: 0.0, phaseOffset: 0.0, pitch: 50.08, pitchMod: 0.0, releaseTime: 1.0, revDamp: 0.35, revDrywet: 0.97, revFreeze: 0.0, revHp: 0.78, revTime: 0.86, reverbSend: 0.0, sendToPhones: 0.0, speed: 1.0, stereoMode: 1.0, tempo: 80.63, timbMod: 0.21, timbre: 0.67, volume: 0.09, volumeMod: 0.0),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				duration: \eucl_7_16,
				delaySend: \gate_every8,
				div: \unit,
				distAmount: \gate_every8,
				reverbSend: \gate_every8,
				revDrywet: \hold,
				pitch: \gauss,
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
			(atk: 0.0, bankName: 'CLAPS', cloudsSend: 0.0, decay: 0.19, delaySend: 0.43, distAmount: 0.0, distDrive: 0.0, dur: 1.5, legato: 0.7, mul: 1.0, mute: 1.0, panDur: 0.5, phaseOffset: 0.0, rate: 1.05, rateMod: 0.0, revDamp: 0.55, revDrywet: 0.4, revFreeze: 0.0, revHp: 0.33, revTime: 0.48, reverbSend: 0.2, speed: 0.5, startPos: 0.0, tempo: 80.63, variant: 2.0, volume: 0.69, volumeMod: 0.0),
			// $PRESET_SAMPLE_SCALARS_END
			// $PRESET_SAMPLE_SEQUENCES_START
			(
				duration: \sprs_dotted,

				// duration: Pseq([2], inf).asStream,
				reverbSend: \gate_every4,
				div: \unit,
				rate: \unit,
				mul: \unit,
				delaySend: \gate_every8,
			),
			// $PRESET_SAMPLE_SEQUENCES_END
			// $PRESET_SAMPLE_LFO_START
			()
			// $PRESET_SAMPLE_LFO_END
		),

		// $SAMPLE2
		~sampleFactory.(
			// $PRESET_SAMPLE_SCALARS_START
			(atk: 0.45, bankName: 'halfmastv6', cloudsSend: 0.65, decay: 0.59, delaySend: 0.21, distAmount: 0.0, distDrive: 0.0, dur: 1.0, legato: 0.7, mul: 1.0, mute: 0.0, panDur: 0.22, phaseOffset: 0.0, rate: 2.25, rateMod: 0.0, revDamp: 0.73, revDrywet: 0.35, revFreeze: 0.0, revHp: 0.36, revTime: 0.75, reverbSend: 0.51, speed: 1.0, startPos: 0.5, tempo: 80.63, variant: 4.0, volume: 0.24, volumeMod: 0.0),
			// $PRESET_SAMPLE_SCALARS_END
			// $PRESET_SAMPLE_SEQUENCES_START
			(
				div: \unit,
				rate: \gauss,
				mul: \unit,
				duration: \unit,
				atk: \sine_slow,
			startPos: \sine,
			),
			// $PRESET_SAMPLE_SEQUENCES_END
			// $PRESET_SAMPLE_LFO_START
			()
			// $PRESET_SAMPLE_LFO_END
		),

		// $SAMPLE3
		~sampleFactory.(
			// $PRESET_SAMPLE_SCALARS_START
			(atk: 0.5, bankName: 'default', cloudsSend: 0.0, decay: 0.5, delaySend: 0.0, distAmount: 0.0, distDrive: 0.0, dur: 1.0, legato: 0.7, mul: 1.0, mute: 1.0, panDur: 0.5, phaseOffset: 0.0, rate: 1.0, rateMod: 0.0, revDamp: 0.8, revDrywet: 0.25, revFreeze: 0.0, revHp: 0.7, revTime: 0.3, reverbSend: 0.0, speed: 1.0, startPos: 0.0, tempo: 80.63, variant: 0.0, volume: 0.06, volumeMod: 0.0),
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
	clouds: (blend: 0.25, density: 0.7, feedback: 0.73, freeze: 0.0, inGain: 1.0, lofi: 0.0, mix: 1.0, mode: 3.0, pitch: -16.14, position: 0.47, reverb: 0.95, size: 0.63, spread: 0.5, texture: 0.65, volume: 0.0),
	delay: (feedback: 0.48, filterFreq: 7029.8, spread: 1.5, time: 0.72),
	reverb: (damp: 0.19, diffuse: 0.41, freeze: 0.0, hp: 0.29, time: 0.83)
),
	// $PRESET_FX_END
);

~states = Pseq([\a, \b, \c, \d], inf).asStream;
~state = ~states.next;
~playCount = 0;

~tempoClock.tempo = ~dreads.synths[0].tempo/60;

// $LFO_SOURCES_START
~dreads.lfoSources = (
	lfo2: (freq: 0.5), // plaits 0 morph
	lfo3: (freq: 1), // plaits 0 decay
	lfo7: (freq: 0.5), // plaits 1 timbre
	lfo8: (freq: 1), // plaits 1 morph
	lfo12: (freq: 0.5), // plaits 1 harm
	lfo13: (freq: 1), // plaits 2 timbre
);
~base = 1.2;
// $LFO_SOURCES_END

~applyPatch.();
)
// 