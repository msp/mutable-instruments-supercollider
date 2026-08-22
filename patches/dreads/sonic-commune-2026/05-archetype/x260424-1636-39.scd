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
			(cloudsSend: 0.9, decay: 0.47, decayMod: 0.3, delaySend: 0.01, distAmount: 0.0, distDrive: 0.0, droneMode: 0.0, dur: 0.5, engine: 2.0, fmMod: -0.02, harm: 0.33, legato: 4.0, lpgColour: 0.5, morph: 0.66, morphMod: 0.0, mul: 0.5, mute: 0.0, phaseOffset: 0.0, pitch: 48.0, revDamp: 0.68, revDrywet: 0.0, revFreeze: 0.0, revHp: 0.41, revTime: 0.82, reverbSend: 0.0, sendToPhones: 0.0, speed: 1.0, stereoMode: 1.0, tempo: 178.0, timbMod: 0.5, timbre: 0.31, volume: 0.94),
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
			(cloudsSend: 0.73, decay: 0.05, decayMod: 0.0, delaySend: 0.27, distAmount: 0.0, distDrive: 0.0, droneMode: 1.0, dur: 1.0, engine: 20.0, fmMod: -0.02, harm: 0.11, legato: 15.0, lpgColour: 0.5, morph: 0.39, morphMod: 0.39, mul: 0.5, mute: 0.0, phaseOffset: -0.5, pitch: 60.0, revDamp: 0.17, revDrywet: 0.32, revFreeze: 0.0, revHp: 0.79, revTime: 0.98, reverbSend: 0.7, sendToPhones: 0.0, speed: 0.5, stereoMode: 1.0, tempo: 178.0, timbMod: 0.71, timbre: 0.32, volume: 0.1),
			// $PRESET_SCALARS_END
			// $PRESET_SEQUENCES_START
			(
				div: \unit,
				duration: \sync_1,
				pitch: \rndm_walk_slow,
			),
			// $PRESET_SEQUENCES_END
			// $PRESET_LFO_START
			()
			// $PRESET_LFO_END
		),

		// $PLAITS3
		~plaitsFactory.(
			// $PRESET_SCALARS_START
			(cloudsSend: 0.84, decay: 0.22, decayMod: 0.0, delaySend: 0.0, distAmount: 0.0, distDrive: 0.0, droneMode: 1.0, dur: Rest(1.0), engine: 16.0, fmMod: 0.0, harm: 0.38, legato: 9.0, lpgColour: 0.5, morph: 0.66, morphMod: 0.06, mul: 0.5, mute: 1.0, phaseOffset: 0.0, pitch: 64.0, revDamp: 0.42, revDrywet: 0.66, revFreeze: 0.0, revHp: 0.45, revTime: 0.88, reverbSend: 0.0, sendToPhones: 0.0, speed: 0.5, stereoMode: 1.0, tempo: 178.0, timbMod: 0.0, timbre: 0.34, volume: 0.31),
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
			(atk: 0.5, bankName: 'halfmastv6', cloudsSend: 1.0, decay: 0.5, delaySend: 0.0, distAmount: 0.0, distDrive: 0.0, dur: 1.0, legato: 0.7, mul: 1.0, mute: 0.0, panDur: 0.5, phaseOffset: 0.0, rate: 0.99, revDamp: 0.8, revDrywet: 0.45, revFreeze: 0.0, revHp: 0.49, revTime: 0.92, reverbSend: 0.0, speed: 1.0, startPos: 0.13, tempo: 178.0, variant: 3.0, volume: 0.25),
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
			(atk: 0.0, bankName: 'default', cloudsSend: 0.0, decay: 0.14, delaySend: 0.0, distAmount: 0.49, distDrive: 0.0, dur: 2.0, legato: 0.7, mul: 1.0, mute: 1.0, panDur: 0.5, phaseOffset: 0.0, rate: 0.18, revDamp: 0.8, revDrywet: 0.0, revFreeze: 0.0, revHp: 0.7, revTime: 0.3, reverbSend: 0.0, speed: 0.5, startPos: 0.0, tempo: 178.0, variant: 0.0, volume: 1.1),
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
			(atk: 0.5, bankName: 'default', cloudsSend: 0.0, decay: 0.5, delaySend: 0.0, distAmount: 0.0, distDrive: 0.0, dur: 1.0, legato: 0.7, mul: 1.0, mute: 1.0, panDur: 0.5, phaseOffset: 0.0, rate: 1.0, revDamp: 0.8, revDrywet: 0.25, revFreeze: 0.0, revHp: 0.7, revTime: 0.3, reverbSend: 0.0, speed: 1.0, startPos: 0.0, tempo: 178.0, variant: 0.0, volume: 0.0),
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
	clouds: (
		blend: 0.5,
		density: 0.58,
		feedback: 0.49,
		freeze: 0.0,
		inGain: 1.0,
		lofi: 0.0,
		mix: 1.0,
		mode: 3.0,
		pitch: 0.5,
		position: 0.36,
		reverb: 0.0,
		size: 0.74,
		spread: 0.5,
		texture: 0.4,
		volume: 0.41
	),
	delay: (
		feedback: 0.36,
		filterFreq: 6560.91,
		spread: 1.5,
		time: 0.67
	),
	reverb: (
		damp: 0.6,
		diffuse: 0.63,
		freeze: 0.0,
		hp: 0.23,
		time: 0.43
	)
),
	// $PRESET_FX_END
);

~states = Pseq([\a, \b, \c, \d], inf).asStream;
~state = ~states.next;
~playCount = 0;
~tempoClock.tempo = ~dreads.synths[0].tempo/60;


// $LFO_SOURCES_START
~dreads.lfoSources = (
	lfo1: (freq: 3, shape: 5),
	lfo2: (freq: 2.2, shape: 1),
	lfo3: (freq: 8.1, shape: 2),
	lfo6: (freq: 3, shape: 4),
	lfo7: (freq: 2.2, shape: 1),
	lfo8: (freq: 8.1, shape: 1),
	lfo11: (freq: 3, shape: 4),
	lfo12: (freq: 2.2, shape: 1),
	lfo13: (freq: 8.1, shape: 1)
);
// $LFO_SOURCES_END

~applyPatch.();
)

