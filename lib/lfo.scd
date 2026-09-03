////////////////////////////////////////////////////////////////////////////////
// LFO infrastructure — named sources, buses, reporter, VDMX relay
// Requires: ~lfoGroup (Group), \lfo and \lfoReporter SynthDefs, ~defaultLFOSources
////////////////////////////////////////////////////////////////////////////////

// Clean up previous if re-running
if (~lfo.notNil) {
	if (~lfo.sources.notNil) {
		~lfo.sources.do { |src|
			if (src.synth.notNil) { src.synth.free };
			if (src.bus.notNil) { src.bus.free };
		};
	};
	if (~lfo.reporter.notNil) { ~lfo.reporter.free };
	if (~lfo.reporterFunc.notNil) { ~lfo.reporterFunc.free };
};

// Initialize ~lfo namespace with named sources (\lfo1–\lfo21)
~lfo = (sources: ());

~defaultLFOSources.keysValuesDo { |key, defaults|
	var bus = Bus.control(s, 1);
	~lfo.sources[key] = (
		name: key,
		synth: Synth(\lfo, [\out, bus, \freq, defaults[\freq], \shape, defaults[\shape], \width, defaults[\width]], ~lfoGroup),
		bus: bus,
		freq: defaults[\freq],
		shape: defaults[\shape],
		width: defaults[\width],
		base: defaults[\base] ? false
	);
};

// Reporter relays all bus values to sclang for VDMX forwarding.
// The lfoN indices below MUST match ~defaultPlaitsLFOMap / ~defaultSampleLFOMap in
// globals.scd, and the SendReply order in the \lfoReporter synthdef defines the msg
// offsets read in ~lfo.reporterFunc — keep all three in sync when adding a param.
// Bus args follow reporter order: plaits 0-2 classic (timbre,morph,decay,pitch,volume,harm) = lfo1-18,
// samples 0-2 (rate,volume) = lfo19-24, then AM per voice (amRing,amDepth,amRatio) appended = lfo25-33.
~lfo.reporter = Synth(\lfoReporter, [
	\timbreBus0, ~lfo.sources[\lfo1].bus, \morphBus0, ~lfo.sources[\lfo2].bus,
	\decayBus0, ~lfo.sources[\lfo3].bus, \pitchBus0, ~lfo.sources[\lfo4].bus, \volumeBus0, ~lfo.sources[\lfo5].bus, \harmBus0, ~lfo.sources[\lfo6].bus,
	\timbreBus1, ~lfo.sources[\lfo7].bus, \morphBus1, ~lfo.sources[\lfo8].bus,
	\decayBus1, ~lfo.sources[\lfo9].bus, \pitchBus1, ~lfo.sources[\lfo10].bus, \volumeBus1, ~lfo.sources[\lfo11].bus, \harmBus1, ~lfo.sources[\lfo12].bus,
	\timbreBus2, ~lfo.sources[\lfo13].bus, \morphBus2, ~lfo.sources[\lfo14].bus,
	\decayBus2, ~lfo.sources[\lfo15].bus, \pitchBus2, ~lfo.sources[\lfo16].bus, \volumeBus2, ~lfo.sources[\lfo17].bus, \harmBus2, ~lfo.sources[\lfo18].bus,
	\sRateBus0, ~lfo.sources[\lfo19].bus, \sVolumeBus0, ~lfo.sources[\lfo20].bus,
	\sRateBus1, ~lfo.sources[\lfo21].bus, \sVolumeBus1, ~lfo.sources[\lfo22].bus,
	\sRateBus2, ~lfo.sources[\lfo23].bus, \sVolumeBus2, ~lfo.sources[\lfo24].bus,
	\amRingBus0, ~lfo.sources[\lfo25].bus, \amRingBus1, ~lfo.sources[\lfo26].bus, \amRingBus2, ~lfo.sources[\lfo27].bus,
	\amDepthBus0, ~lfo.sources[\lfo28].bus, \amDepthBus1, ~lfo.sources[\lfo29].bus, \amDepthBus2, ~lfo.sources[\lfo30].bus,
	\amRatioBus0, ~lfo.sources[\lfo31].bus, \amRatioBus1, ~lfo.sources[\lfo32].bus, \amRatioBus2, ~lfo.sources[\lfo33].bus,
], ~lfoGroup);

// Resolve a source's authored freq to Hz (× ~base when base-locked)
~resolveLFOFreq = { |src|
	var f;
	f = src[\freq] ? 0.125;
	if (src[\base] == true) { f * ~base } { f };
};

// Set global LFO base and re-resolve every base-locked source
~setLFOBase = { |v|
	~base = v;
	~lfo.sources.do { |src|
		if (src[\base] == true) { src[\synth].set(\freq, ~resolveLFOFreq.(src)) };
	};
};

// Apply one LFO param to a source (handles shape symbols, freq resolution, base flag)
~setLFOParam = { |src, synth, param, v|
	var val;
	val = v;
	if ((param == \shape) and: { val.isKindOf(Symbol) }) { val = ~lfoShapeMap[val] ? val };
	if (param == \base) {
		src.put(\base, val);
		synth.set(\freq, ~resolveLFOFreq.(src));
	} {
		if (param == \freq) {
			src.put(\freq, val);
			synth.set(\freq, ~resolveLFOFreq.(src));
		} {
			synth.set(param, val);
			src.put(param, val);
		};
	};
};

// Apply LFO state from patch data to runtime sources and synth mappings
// Called from ~applyPatch after patch load/re-evaluate
~applyLFOState = {
	// 1. Reset all sources to defaults, then apply overrides
	var overrides = ~dreads.lfoSources ?? ();
	~defaultLFOSources.keysValuesDo { |key, defaults|
		var src, synth;
		src = ~lfo.sources[key];
		if (src.notNil) {
			synth = src[\synth];
			~lfoSourceParams.do { |param| src.put(param, defaults[param]) };
			synth.set(\freq, ~resolveLFOFreq.(src), \shape, src[\shape], \width, src[\width]);
		};
	};
	overrides.keysValuesDo { |key, cfg|
		var src, synth;
		src = ~lfo.sources[key];
		if (src.notNil) {
			synth = src[\synth];
			~lfoSourceParams.do { |param|
				if (cfg[param].notNil) { src.put(param, cfg[param]) };
			};
			synth.set(\freq, ~resolveLFOFreq.(src), \shape, src[\shape], \width, src[\width]);
		} {
			("WARNING: LFO source " ++ key ++ " not found").warn;
		};
	};

	// 2. Hydrate plaits LFO mappings — resolve symbols to source Events on each instance
	~dreads.synths.do { |inst, i|
		var hydratedMap = ~defaultPlaitsLFOMap[i].copy;
		// Apply per-instance overrides (symbols from patch file)
		if (inst.lfo.notNil) { hydratedMap.putAll(inst.lfo) };
		// Replace each symbol with the actual source Event
		~plaitsLFOParams.do { |param|
			var key = hydratedMap[param];
			if (key.isKindOf(Symbol)) {
				hydratedMap[param] = ~lfo.sources[key];
			};
			// Map LFO bus to drone synth if running
			if (~drones.notNil && ~drones[i].notNil) {
				~drones[i].map((param ++ "LFO").asSymbol, hydratedMap[param].bus);
			};
		};
		inst.lfo = hydratedMap;
		// Push mod depth scalars to running drone
		if (~drones.notNil && ~drones[i].notNil) {
			~drones[i].set(
				\timbMod, inst[\timbMod], \morphMod, inst[\morphMod],
				\decayMod, inst[\decayMod], \pitchMod, inst[\pitchMod],
				\volumeMod, inst[\volumeMod], \harmMod, inst[\harmMod],
				\amRingMod, inst[\amRingMod], \amDepthMod, inst[\amDepthMod], \amRatioMod, inst[\amRatioMod]
			);
		};
	};

	// 3. Hydrate sample LFO mappings
	~dreads.samples.do { |inst, i|
		var hydratedMap = ~defaultSampleLFOMap[i].copy;
		if (inst.lfo.notNil) { hydratedMap.putAll(inst.lfo) };
		~sampleLFOParams.do { |param|
			var key = hydratedMap[param];
			if (key.isKindOf(Symbol)) {
				hydratedMap[param] = ~lfo.sources[key];
			};
		};
		inst.lfo = hydratedMap;
	};

	"LFO state applied".postln;
};

// Hydrate current patch's LFO mappings now that sources exist
~applyLFOState.();

// Livecoding helper: tweak LFO params by instance type/index/param name
// Single param: ~lfoTweak.(\plaits, 0, \pitch, \freq, 0.3)
// Multi param:  ~lfoTweak.(\plaits, 0, \pitch, (freq: 3, shape: \square))
// Shape names:  \sine, \tri, \saw, \square, \noise, \gaussian (or integers 0-5)
~lfoShapeMap = (sine: 0, tri: 1, saw: 2, square: 3, noise: 4, gaussian: 5);
~lfoShapeNames = [\sine, \tri, \saw, \square, \noise, \gaussian];
~lfoTweak = { |instType, instIndex, paramName, lfoParamOrEvent, val|
	var src, srcKey, synth, modKey, resolved, inst;
	srcKey = if (instType == \plaits) {
		~dreads.synths[instIndex].lfo[paramName].name;
	} {
		~dreads.samples[instIndex].lfo[paramName].name;
	};
	src = ~lfo.sources[srcKey];
	synth = src[\synth];
	modKey = if (paramName == \timbre) { \timbMod } { (paramName ++ "Mod").asSymbol };
	inst = if (instType == \plaits) { ~dreads.synths[instIndex] } { ~dreads.samples[instIndex] };
	if (lfoParamOrEvent.isKindOf(Event)) {
		lfoParamOrEvent.keysValuesDo { |param, v|
			if (param == \mod) {
				inst.put(modKey, v);
				if (instType == \plaits && ~drones.notNil && ~drones[instIndex].notNil) {
					~drones[instIndex].set(modKey, v);
				};
			} {
				~setLFOParam.(src, synth, param, v);
			};
		};
	} {
		if (lfoParamOrEvent == \mod) {
			inst.put(modKey, val);
			if (instType == \plaits && ~drones.notNil && ~drones[instIndex].notNil) {
				~drones[instIndex].set(modKey, val);
			};
		} {
			~setLFOParam.(src, synth, lfoParamOrEvent, val);
		};
	};
	// NB: deliberately NOT calling ~pushStateToUI here. It rebuilds the entire
	// seq-modal picker (~124 items) and re-pushes all state on every LFO change —
	// heavy, and it fired inconsistently (freq/shape/base went through here, mod
	// and ~base did not). The LFO UI reflects on modal-open instead (lfoReflect).
	// Trade-off: a *livecoded* ~lfoTweak won't auto-refresh an already-open modal.
};

// Relay LFO values from server to VDMX via OSC, scaled by per-instance mod depth
// Persistent one-pole state for the visual depth-slew (Dictionary: string keys need
// value-equality, an Event/IdentityDictionary would never match "p"++i++param).
~lfoSmooth = ~lfoSmooth ? Dictionary.new;

~lfo.reporterFunc = OSCFunc({ |msg|
	var bundle = Array.new(~numLFOSources);
	// Slew each depth so introducing/adjusting LFO depth eases the visual in, instead
	// of snapping to the free-running LFO's current phase. Mirrors the audio depth
	// slew (synthdef Lag.kr(~modGlide)); ~modGlide is the shared glide time.
	var a = exp(-1 / (60 * (~modGlide ? 0.15)));   // one-pole coeff for ~modGlide-second glide at 60Hz
	var sm = { |key, target|
		var cur = (~lfoSmooth[key] ? target);
		cur = target + ((cur - target) * a);
		~lfoSmooth[key] = cur;
		cur
	};
	~numPlaits.do { |i|
		var inst = ~dreads.synths[i];
		var offset = 3 + (i * 6);
		if ((inst.mute ? 0) != 1) {   // muted -> skip: visual freezes at last value, no jump
			bundle = bundle.add(["/plaits/" ++ i ++ "/lfo/timbre", msg[offset]     * sm.("p"++i++"timb",   inst.timbMod ? 0)]);
			bundle = bundle.add(["/plaits/" ++ i ++ "/lfo/morph",  msg[offset + 1] * sm.("p"++i++"morph",  inst.morphMod ? 0)]);
			bundle = bundle.add(["/plaits/" ++ i ++ "/lfo/decay",  msg[offset + 2] * sm.("p"++i++"decay",  inst.decayMod ? 0)]);
			bundle = bundle.add(["/plaits/" ++ i ++ "/lfo/pitch",  msg[offset + 3] * sm.("p"++i++"pitch",  inst.pitchMod ? 0)]);
			bundle = bundle.add(["/plaits/" ++ i ++ "/lfo/volume", msg[offset + 4] * sm.("p"++i++"volume", inst.volumeMod ? 0)]);
			bundle = bundle.add(["/plaits/" ++ i ++ "/lfo/harm",   msg[offset + 5] * sm.("p"++i++"harm",   inst.harmMod ? 0)]);
		};
	};
	~numSamples.do { |i|
		var samp = ~dreads.samples[i];
		var offset = 21 + (i * 2);
		if ((samp.mute ? 0) != 1) {
			bundle = bundle.add(["/samples/" ++ i ++ "/lfo/rate",   msg[offset]     * sm.("s"++i++"rate",   samp.rateMod ? 0)]);
			bundle = bundle.add(["/samples/" ++ i ++ "/lfo/volume", msg[offset + 1] * sm.("s"++i++"volume", samp.volumeMod ? 0)]);
		};
	};
	~numPlaits.do { |i|
		var inst = ~dreads.synths[i];
		if ((inst.mute ? 0) != 1) {
			bundle = bundle.add(["/plaits/" ++ i ++ "/lfo/amRing",  msg[27 + i] * sm.("p"++i++"amRing",  inst.amRingMod ? 0)]);
			bundle = bundle.add(["/plaits/" ++ i ++ "/lfo/amDepth", msg[30 + i] * sm.("p"++i++"amDepth", inst.amDepthMod ? 0)]);
			bundle = bundle.add(["/plaits/" ++ i ++ "/lfo/amRatio", msg[33 + i] * sm.("p"++i++"amRatio", inst.amRatioMod ? 0)]);
		};
	};
	// don't fire an empty bundle if every voice is muted
	if (bundle.size > 0) { ~vis.().sendBundle(nil, *bundle) };
}, '/lfoValues');
