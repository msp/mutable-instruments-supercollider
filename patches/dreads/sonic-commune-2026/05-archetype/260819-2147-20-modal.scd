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
			(amDepth: 0.0, amFixedHz: 0.0, amRatio: 1.0, amRing: 0.0, amWave: 0.0, cloudsSend: 0.79, decay: 0.33, decayMod: 0.11, delaySend: 0.0, distAmount: 0.31, distDrive: 0.0, droneMode: 1.0, dur: 0.5, engine: 2.0, fmMod: -0.01, harm: 0.33, harmMod: 0.0, legato: 4.0, lpgColour: 0.5, morph: 0.15, morphMod: 0.46, mul: 0.5, mute: 0.0, phaseOffset: 0.0, pitch: 48.0, pitchMod: 0.39, releaseTime: 1.0, revDamp: 0.0, revDrywet: 0.69, revFreeze: 0.0, revHp: 0.43, revTime: 0.98, reverbSend: 0.0, sendToPhones: 0.0, speed: 1.0, stereoMode: 1.0, tempo: 165.0, timbMod: 0.31, timbre: 0.0, volume: 1.4, volumeMod: 0.18),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				duration: \hold,
				div: \unit,
			),
			// $PRESET_SEQUENCES_END
			// $PRESET_LFO_START
			()
			// $PRESET_LFO_END
		),

		// $PLAITS2
		~plaitsFactory.(
			// $PRESET_SCALARS_START
			(amDepth: 0.0, amFixedHz: 0.0, amRatio: 1.0, amRing: 0.0, amWave: 0.0, cloudsSend: 0.73, decay: 0.42, decayMod: 0.0, delaySend: 0.27, distAmount: 0.0, distDrive: 0.0, droneMode: 1.0, dur: 1.0, engine: 20.0, fmMod: -0.02, harm: 0.11, harmMod: 0.0, legato: 15.0, lpgColour: 0.5, morph: 0.73, morphMod: 0.39, mul: 0.5, mute: 1.0, phaseOffset: -0.5, pitch: 60.0, pitchMod: 0.0, releaseTime: 1.0, revDamp: 0.48, revDrywet: 0.75, revFreeze: 0.0, revHp: 0.64, revTime: 1.08, reverbSend: 0.7, sendToPhones: 0.0, speed: 0.5, stereoMode: 1.0, tempo: 165.0, timbMod: 0.68, timbre: 0.73, volume: 0.09, volumeMod: 0.0),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				div: \unit,
				duration: \sync_1,
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
			(amDepth: 0.0, amFixedHz: 0.0, amRatio: 1.0, amRing: 0.0, amWave: 0.0, cloudsSend: 0.52, decay: 0.2, decayMod: 0.0, delaySend: 0.0, distAmount: 0.0, distDrive: 0.0, droneMode: 1.0, dur: 1.0, engine: 16.0, fmMod: 0.0, harm: 0.19, harmMod: 0.0, legato: 9.0, lpgColour: 0.5, morph: 0.63, morphMod: 0.0, mul: 0.5, mute: 1.0, phaseOffset: 0.0, pitch: 64.0, pitchMod: 0.0, releaseTime: 1.0, revDamp: 0.27, revDrywet: 0.91, revFreeze: 0.0, revHp: 0.91, revTime: 0.88, reverbSend: 0.0, sendToPhones: 0.0, speed: 0.5, stereoMode: 1.0, tempo: 165.0, timbMod: 0.12, timbre: 0.34, volume: 0.16, volumeMod: 0.11),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				div: \unit,
				duration: \offbeat,
				pitch: \hold,
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
			(atk: 0.5, bankName: 'halfmastv6', cloudsSend: 1.0, decay: 0.5, delaySend: 0.0, distAmount: 0.0, distDrive: 0.0, dur: 1.0, legato: 0.7, mul: 1.0, mute: 1.0, panDur: 0.19, phaseOffset: 0.0, rate: 0.99, rateMod: 0.0, revDamp: 0.8, revDrywet: 0.45, revFreeze: 0.0, revHp: 0.49, revTime: 0.92, reverbSend: 0.0, speed: 1.0, startPos: 0.13, tempo: 165.0, variant: 3.0, volume: 0.09, volumeMod: 0.43),
			// $PRESET_SAMPLE_SCALARS_END
			// $PRESET_SAMPLE_SEQUENCES_START
			(
				div: \unit,
				rate: \rndm_narrow,
				mul: \unit,
				duration: \unit,
				startPos: \sine,
			),
			// $PRESET_SAMPLE_SEQUENCES_END
			// $PRESET_SAMPLE_LFO_START
			()
			// $PRESET_SAMPLE_LFO_END
		),

		// $SAMPLE2
		~sampleFactory.(
			// $PRESET_SAMPLE_SCALARS_START
			(atk: 0.3, bankName: 'default', cloudsSend: 0.06, decay: 0.07, delaySend: 0.79, distAmount: 0.0, distDrive: 0.0, dur: 2.43, legato: 0.7, mul: 1.0, mute: 0.0, panDur: 0.09, phaseOffset: 0.0, rate: 5.0, rateMod: 0.67, revDamp: 0.8, revDrywet: 0.12, revFreeze: 0.0, revHp: 0.7, revTime: 0.3, reverbSend: 0.0, speed: 0.25, startPos: 0.28, tempo: 165.0, variant: 0.0, volume: 0.43, volumeMod: 0.0),
			// $PRESET_SAMPLE_SCALARS_END
			// $PRESET_SAMPLE_SEQUENCES_START
			(
				div: \unit,
				rate: \unit,
				mul: \unit,
				duration: \gauss,
				delaySend: \gate_every5,
			),
			// $PRESET_SAMPLE_SEQUENCES_END
			// $PRESET_SAMPLE_LFO_START
			()
			// $PRESET_SAMPLE_LFO_END
		),

		// $SAMPLE3
		~sampleFactory.(
			// $PRESET_SAMPLE_SCALARS_START
			(atk: 0.5, bankName: 'default', cloudsSend: 0.0, decay: 0.5, delaySend: 0.0, distAmount: 0.0, distDrive: 0.0, dur: 1.0, legato: 0.7, mul: 1.0, mute: 1.0, panDur: 0.5, phaseOffset: 0.0, rate: 1.0, rateMod: 0.0, revDamp: 0.8, revDrywet: 0.25, revFreeze: 0.0, revHp: 0.7, revTime: 0.3, reverbSend: 0.0, speed: 1.0, startPos: 0.0, tempo: 165.0, variant: 0.0, volume: 0.0, volumeMod: 0.0),
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
	clouds: (blend: 0.5, density: 0.58, feedback: 0.49, freeze: 0.0, inGain: 1.0, lofi: 0.0, mix: 1.0, mode: 3.0, pitch: 0.5, position: 0.36, reverb: 0.0, size: 0.74, spread: 0.5, texture: 0.4, volume: 0.41),
	delay: (feedback: 0.38, filterFreq: 6742.75, spread: 1.5, time: 0.72),
	reverb: (damp: 0.6, diffuse: 0.63, freeze: 1.0, hp: 0.22, time: 0.51)
),
	// $PRESET_FX_END
);

~states = Pseq([\a, \b, \c, \d], inf).asStream;
~state = ~states.next;
~playCount = 0;
~tempoClock.tempo = ~dreads.synths[0].tempo/60;


// $LFO_SOURCES_START
~dreads.lfoSources = (
	lfo1: (freq: 0.70384871959686, shape: 2, base: true), // plaits 0 timbre
	lfo2: (freq: 1.8600000143051, base: true), // plaits 0 morph
	lfo3: (freq: 8.1), // plaits 0 decay
	lfo4: (freq: 1.8184776306152), // plaits 0 pitch
	lfo5: (freq: 2.2990045547485, base: true), // plaits 0 volume
	lfo6: (freq: 3), // plaits 0 harm
	lfo7: (freq: 2.2), // plaits 1 timbre
	lfo8: (freq: 8.1), // plaits 1 morph
	lfo11: (freq: 3), // plaits 1 volume
	lfo12: (freq: 2.2), // plaits 1 harm
	lfo13: (freq: 6.1953458786011, shape: 2, base: true), // plaits 2 timbre
	lfo17: (freq: 0.050000000745058), // plaits 2 volume
	lfo20: (base: true), // sample 0 volume
	lfo21: (freq: 12.35916519165, base: true), // sample 1 rate
);
~base = 0.5;
// $LFO_SOURCES_END

~applyPatch.();
)
