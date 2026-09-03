//////////////////////////////////////////////////////////////////////////////
// Global utility functions and shared state
//////////////////////////////////////////////////////////////////////////////
(
// Generate output bus rotation array
// Note: Plaits outputs stereo, so last speaker won't be used in rotation
// numSpeakers=4 → [0, 1, 2, 3] (but \out=3 writes to buses 3-4, which is out of range)
// that's fine for now :)
~outputBuses = (0..(~numSpeakers - 1)); 

// Recording mode: route each voice to its own stereo bus
// Plaits 0-2 → buses 0,2,4 | Samples 0-2 → buses 6,8,10
// Delay → 12 | Reverb → 14 | Clouds → 16
~voiceOutBus = { |type, index|
	if (~recordingMode) {
		if (type == \plaits) { index * 2 } { 6 + (index * 2) };
	} { 0 };
};

// Cycle sample variant within current bank
~cycleSampleVariant = { |instanceIndex, direction|
	var instance = ~dreads.samples[instanceIndex];
	var bankName, bankBuffers, numVariants, newVariant, bankPaths, filepath, instanceNum;

	if (instance.isNil) {
		("WARNING: Sample instance " ++ instanceIndex ++ " not found").postln;
	} {
		bankName = instance.bankName;
		bankBuffers = ~sampleLibrary.banks[bankName];

		if (bankBuffers.isNil) {
			("WARNING: Bank " ++ bankName ++ " not found").postln;
		} {
			numVariants = bankBuffers.size;
			newVariant = (instance.variant.asInteger + direction).wrap(0, numVariants - 1);
			instance.variant = newVariant;

			// Update UI with new file path
			instanceNum = instanceIndex + 1;
			bankPaths = ~sampleLibrary.paths[bankName];
			if (bankPaths.notNil && bankPaths[newVariant].notNil) {
				filepath = bankPaths[newVariant];
				~ui.().sendMsg("/samples/" ++ instanceNum ++ "/samplePath", filepath);
			};

			["Sample " ++ instanceIndex ++ ": variant " ++ newVariant ++ "/" ++ numVariants ++ " (" ++ bankName ++ ")"].postln;
		};
	};
};

// Default tempo, will be updated by patches
~tempoClock = TempoClock.new(120/60);
~sendToPhones = false;
~nudgeAmount = 0.25; // Per-module nudge step size in beats

~ui = {
	if (~uiAddr.isNil) {
		~uiAddr = NetAddr("127.0.0.1", 9000);
	};
	~uiAddr;
};

~td = {
	if (~tdAddr.isNil) {
		~tdAddr = NetAddr("127.0.0.1", 10000);
	};
	~tdAddr;
};

~vis = {
	if (~visAddr.isNil) {
		~visAddr = NetAddr("127.0.0.1", 1234);
	};
	~visAddr;
};

~ws = {
	if (~wsAddr.isNil) {
		~wsAddr = NetAddr("127.0.0.1", 3333);
	};
	~wsAddr;
};

~saveAllModified = {
	Document.allDocuments.do{ |doc, index|
		[index, doc.isEdited, doc.path].postln;
		if (doc.path.notNil && doc.isEdited) {
			var file = File(doc.path, "w");
			("Saving editor changes: " ++ doc.path.basename).postln;
			file.write(doc.string);
			file.close;
		};
	};
	nil; // Explicitly return nil to avoid any return value issues
};

// Default scalar values for all plaits instances
~defaultScalars = (
	amDepth: 0.0,      // AM/ring-mod amount (0 = bypass)
	amFixedHz: 0,      // 0 = modulator tracks carrier ratio, 1 = fixed Hz (inharmonic)
	amRing: 0.0,       // AM<->RM morph (0 = AM/carrier present, 1 = ring mod/carrier suppressed)
	amRingMod: 0.0,    // LFO depth for amRing (AM/RM balance)
	amDepthMod: 0.0,   // LFO depth for amDepth (AM amount)
	amRatioMod: 0.0,   // LFO depth for amRatio (modulator ratio)
	amRatio: 1.0,      // modulator freq as a ratio of the carrier pitch
	amWave: 0,         // modulator waveform: 0 sine, 1 tri, 2 saw, 3 square
	cloudsSend: 1.0,
	decay: 0.5,
	decayMod: 0.3,  // legacy default — was hardcoded in sequencer before bus-based LFOs
	delaySend: 0.0,
	distAmount: 0.0,
	distDrive: 0.0,
	droneMode: 0,
	dur: 0.25,
	engine: 1.0,
	fmMod: 0.0,
	harm: 0.5,
	harmMod: 0.0,
	legato: 0.7,
	lpgColour: 0.5,
	morphMod: 0.0,
	morph: 0.5,
	mul: 0.5,
	mute: 0,
	phaseOffset: 0.0,
	pitch: 49.0,
	pitchMod: 0.0,
	releaseTime: 1.0,          // note release/tail (Linen release, seconds); per-voice, overridable
	revDamp: 0.8,
	revDrywet: 0.0,
	revFreeze: 0.0,
	revHp: 0.7,
	revTime: 0.5,
	reverbSend: 0.0,
	sendToPhones: 0.0,
	speed: 1.0,
	stereoMode: 1.0,
	tempo: 165.0,
	timbMod: 0.0,
	timbre: 0.5,
	volume: 1.0,
	volumeMod: 0.0,
);

// Default global FX settings for all patches
~defaultFX = (
	clouds: (
		blend: 0.5,
		density: 0.7,
		inGain: 1.0,
		lofi: 0.0,
		feedback: 0.0,
		freeze: 0.0,
		mode: 3,
		mix: 1.0,
		pitch: 0.5,
		position: 0.5,
		reverb: 0.0,
		size: 0.5,
		spread: 0.5,
		texture: 0.5,
		volume: 1.0
	),
	delay: (
		feedback: 0.4,
		filterFreq: 6000,
		spread: 1.5,
		time: 0.25
	),
	reverb: (
		damp: 0.2,
		diffuse: 0.625,
		freeze: 0.0,
		hp: 0.3,
		time: 0.2
	)
);

// Shared default sequences for both plaits and sample instances
// Symbols reference ~sequenceLibrary entries: \hold=0.5 (modulation), \unit=1.0 (timing)
~baseSequences = (
	cloudsSend: \hold,
	decay: \hold,
	delaySend: \hold,
	distAmount: \hold,
	distDrive: \hold,
	div: \unit,
	duration: \unit,
	revDamp: \hold,
	revDrywet: \hold,
	revHp: \hold,
	revTime: \hold,
	reverbSend: \hold,
);

// Plaits-specific sequences (merged with ~baseSequences)
~defaultSequences = ~baseSequences ++ (
	amDepth: \hold,
	amRing: \hold,
	engine: Pseq(["e"], inf).asStream,
	fmMod: \hold,
	harm: \hold,
	lpgColour: \hold,
	morph: \hold,
	mul: \hold,
	pitch: Pseq([0], inf).asStream,  // additive semitone offset
	timbre: \hold,
	volume: \hold,
);

// Sample library storage (SuperDirt-style bank/variant structure)
~sampleLibrary = (
	banks: Dictionary.new,      // bankName (Symbol) -> Array of Buffers
	paths: Dictionary.new,      // bankName (Symbol) -> Array of file paths
	metadata: Dictionary.new    // bankName (Symbol) -> Array of metadata dicts
);

// Sequence pattern library loaded from separate file
// See lib/sequence_library.scd for pattern definitions and tags

// Sequence stream cache for lazy resolution
// Stores runtime state: (symbol: \sparse, stream: <stream>)
// Cache key format: "plaits_0_duration" or "samples_1_rate"
~sequenceStreamCache = Dictionary.new;

// Default scalar values for sample instances
~defaultSampleScalars = (
	atk: 0.5,               // Normalized 0-1 (scaled to duration/2 in sequencer)
	bankName: \default,     // Sample bank name (\default = built-in SC samples)
	cloudsSend: 0.0,
	decay: 0.5,             // Normalized 0-1 (scaled to duration*2 in sequencer)
	delaySend: 0.0,
	distAmount: 0.0,
	distDrive: 0.0,
	dur: 0.25,
	legato: 0.7,
	mul: 1.0,
	mute: 0,
	phaseOffset: 0.0,
	panDur: 0.5,            // Normalized 0-1 (scaled to duration*2 in sequencer)
	rate: 1.0,
	rateMod: 0.0,
	reverbSend: 0.0,
	revDamp: 0.8,
	revDrywet: 0.25,
	revFreeze: 0.0,
	revHp: 0.7,
	revTime: 0.3,
	speed: 1.0,
	startPos: 0,            // Normalized 0-1 (scaled to duration in sequencer)
	tempo: 165.0,
	variant: 0,             // Which variant of the bank to play (0-based index)
	volume: 0.0,
	volumeMod: 0.0,
);

// Sample-specific sequences (merged with ~baseSequences)
~defaultSampleSequences = ~baseSequences ++ (
	atk: \hold,
	mul: \unit,
	panDur: \hold,
	rate: \unit,
	startPos: \hold,
	variant: Pseq([0], inf).asStream,  // integer index, not a modulation param
);

// Global LFO base frequency (Hz). Sources in "×base" mode multiply this value.
~base = 0.125;

// Module counts (must match the UI, the LFO maps below, and the \lfoReporter synthdef)
~numPlaits = 3;
~numSamples = 3;

// Per-instance LFO-modulatable params (order matches the LFO maps below)
~plaitsLFOParams = [\timbre, \morph, \decay, \pitch, \volume, \harm, \amRing, \amDepth, \amRatio];
~sampleLFOParams = [\rate, \volume];
// Per-source LFO controls (mod is separate — a synth scalar, not a source param)
~lfoSourceParams = [\freq, \shape, \width, \base];

// One LFO source synth per (module x modulatable param), pooled as lfo1..N.
// N derives from the counts above, so adding a param grows the pool automatically.
// (The LFO maps + the \lfoReporter synthdef still assign/read specific numbers,
//  so extend those to match when you add a param.)
~numLFOSources = (~numPlaits * ~plaitsLFOParams.size) + (~numSamples * ~sampleLFOParams.size);
~defaultLFOSources = ();
(1..~numLFOSources).do { |n|
	~defaultLFOSources[("lfo" ++ n).asSymbol] = (freq: 0.125, shape: 0, width: 0.3, base: false);
};

// Default 1:1 LFO mappings per plaits instance (param -> LFO source).
// SOURCE OF TRUTH for which lfo index drives which (voice, param).
// The \lfoReporter bus wiring in lib/lfo.scd (~lfo.reporter Synth) must pass the
// SAME lfoN to each bus, and scripts/shuffle_modules.py parses this map — keep in sync.
~defaultPlaitsLFOMap = [
	(timbre: \lfo1, morph: \lfo2, decay: \lfo3, pitch: \lfo4, volume: \lfo5, harm: \lfo6, amRing: \lfo25, amDepth: \lfo28, amRatio: \lfo31),
	(timbre: \lfo7, morph: \lfo8, decay: \lfo9, pitch: \lfo10, volume: \lfo11, harm: \lfo12, amRing: \lfo26, amDepth: \lfo29, amRatio: \lfo32),
	(timbre: \lfo13, morph: \lfo14, decay: \lfo15, pitch: \lfo16, volume: \lfo17, harm: \lfo18, amRing: \lfo27, amDepth: \lfo30, amRatio: \lfo33),
];

// Default 1:1 LFO mappings per sample instance
~defaultSampleLFOMap = [
	(rate: \lfo19, volume: \lfo20),
	(rate: \lfo21, volume: \lfo22),
	(rate: \lfo23, volume: \lfo24),
];
)