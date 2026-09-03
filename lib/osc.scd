//////////////////////////////////////////////////////////////////////////////
// Plaits OSC Setup - Dynamic OSC listener creation for all instances
//////////////////////////////////////////////////////////////////////////////

OSCFunc.trace(true, hideStatusMsg: true); // Turn posting on
OSCFunc.trace(false); // Turn posting off

(
OSCdef.freeAll;
s.defaultGroup.freeAll;

OSCdef.new(
	\startStop,
	{
		arg msg, time, addr, port;
		var value = msg[1];
		msg.postln;
		if (value == 1.0,
			{
				// Clear stream cache so patterns like \offbeat start at position 0
				~sequenceStreamCache = Dictionary.new;
				// Start drone synths for any instances with droneMode enabled
				~dreads.synths.do { |instance, idx|
					if (instance.droneMode == 1) { ~startDrone.(idx) };
				};
				x.play(~tempoClock);
				~lfo.reporter.run(true);
			},
			{
				x.stop;
				~lfo.reporter.run(false);
				// Stop all drone synths
				~dreads.synths.do { |instance, idx|
					~stopDrone.(idx);
				};
			}
		);
	},
	"/dreads/start"
);

// Randomise all unmuted plaits instances with a profile
// OSC: /dreads/randomiseAll  profileName  (tonal/colour/mod/fx/lfo/full)
OSCdef.new(
	\randomiseAll,
	{
		arg msg, time, addr, port;
		var mode;
		mode = if (msg[1].notNil) { msg[1].asSymbol } { \default };
		~randomiseAll.(mode);
	},
	"/dreads/randomiseAll"
);

// Randomise all unmuted sample instances with a profile
OSCdef.new(
	\randomiseAllSamples,
	{
		arg msg, time, addr, port;
		var mode;
		mode = if (msg[1].notNil) { msg[1].asSymbol } { \default };
		~randomiseAll.(mode, \samples);
	},
	"/dreads/randomiseAllSamples"
);

// Create OSC listeners for all instances and parameters
~setupPlaitsOSC = {
	~dreads.synths.do { |instance, instanceIndex|
		var instanceNum = instanceIndex + 1; // Convert to 1-based for OSC paths

		// ["binding plaits ------------------->", instanceIndex].postln;
		// Generic parameter handling - OSC keys match data structure keys
		instance.keys.select({ |key| (key != \sequences) && (key != \lfo) }).do { |paramKey|
			// ["binding key", paramKey].postln;
			OSCdef.new(
				("plaits" ++ instanceNum ++ paramKey).asSymbol,
				{
					arg msg, time, addr, port;
					var value = msg[1];
					msg.round(0.001).postln;

					// Special handling for tempo (affects global tempo clock)
					if (paramKey == 'tempo') {
						~dreads.synths[instanceIndex][paramKey] = value;
						~tempoClock.tempo = (value.max(0.1))/60;
					} {
						if (paramKey == 'droneMode') {
							~dreads.synths[instanceIndex][paramKey] = value;
							if (value == 1) {
								~startDrone.(instanceIndex);
							} {
								~stopDrone.(instanceIndex);
							};
						} {
							if (paramKey == 'mute') {
								~dreads.synths[instanceIndex][paramKey] = value;
								// Forward mute to drone synth
								if (~drones.notNil && ~drones[instanceIndex].notNil) {
									if (value == 1) {
										~drones[instanceIndex].set(\mul, 0);
									} {
										~drones[instanceIndex].set(\mul, ~dreads.synths[instanceIndex].mul);
									};
								};
							} {
								// Generic parameter update
								var cache, modVal;
								~dreads.synths[instanceIndex][paramKey] = value;
								// Forward to drone synth if active
								if (~drones.notNil && ~drones[instanceIndex].notNil) {
									~drones[instanceIndex].set(paramKey, value);
								};
								// Drone-mode UI responsiveness stop-gap: for FX sends, echo the
								// modulated value to visuals so live knob drags update VDMX
								// smoothly (otherwise visuals are sequencer-tick rate).
								// See docs/visualization-osc.md for full architecture discussion.
								if ([\cloudsSend, \delaySend, \reverbSend, \revDrywet, \distAmount, \harm, \amDepth, \amRing, \volume].includes(paramKey)) {
									cache = ~dreads.synths[instanceIndex].seqCache;
									if (cache.notNil and: { cache[paramKey].notNil }) {
										modVal = ~modulateBipolar.(cache[paramKey], value);
										// Match sequencer's 0-based path convention (lib/sequencer.scd ~/vis bundle)
										~vis.().sendMsg("/plaits/" ++ instanceIndex ++ "/" ++ paramKey.asString, modVal);
									};
								};
								// amRatio is static (no sequence) — echo the normalised knob value
								if (paramKey == \amRatio) {
									~vis.().sendMsg("/plaits/" ++ instanceIndex ++ "/amRatio", value / 8.0);
								};
							};
						};
					};
				},
				"/plaits/" ++ instanceNum ++ "/" ++ paramKey.asString
			);
		};

		// Sequence selection OSC handlers for all sequenceable parameters
		~defaultSequences.keys.do { |paramKey|

			OSCdef.new(
				("plaits" ++ instanceNum ++ paramKey ++ "Seq").asSymbol,
				{
					arg msg, time, addr, port;
					var seqName = msg[1].asSymbol;
					msg.postln;
					~selectSequence.(\plaits, instanceIndex, paramKey, seqName);
				},
				"/plaits/" ++ instanceNum ++ "/" ++ paramKey.asString ++ "/seq"
			);
		};

		// Dice: generate random sequence for a param
		// OSC: /plaits/{n}/dice  paramName
		OSCdef.new(
			("plaits" ++ instanceNum ++ "dice").asSymbol,
			{
				arg msg, time, addr, port;
				var paramKey = msg[1].asSymbol;
				~diceSeq.(instanceIndex + 1, paramKey);
			},
			"/plaits/" ++ instanceNum ++ "/dice"
		);

		// Randomise: apply a randomisation profile to this instance
		// OSC: /plaits/{n}/randomise  profileName  (tonal/colour/mod/fx/lfo/full)
		OSCdef.new(
			("plaits" ++ instanceNum ++ "randomise").asSymbol,
			{
				arg msg, time, addr, port;
				var mode;
				mode = if (msg[1].notNil) { msg[1].asSymbol } { \default };
				~randomise.(instanceIndex + 1, mode);
			},
			"/plaits/" ++ instanceNum ++ "/randomise"
		);

		// Nudge forward: /plaits/{n}/nudgeForward
		OSCdef.new(
			("plaits" ++ instanceNum ++ "nudgeForward").asSymbol,
			{
				arg msg, time, addr, port;
				var delta = ~nudgeAmount;
				~dreads.synths[instanceIndex].nudgeOffset = (~dreads.synths[instanceIndex].nudgeOffset ? 0) + delta;
				~dreads.synths[instanceIndex].phaseOffset = (~dreads.synths[instanceIndex].phaseOffset ? 0) + delta;
				["plaits nudge fwd", instanceNum, "nudge:", ~dreads.synths[instanceIndex].nudgeOffset, "phase:", ~dreads.synths[instanceIndex].phaseOffset].postln;
			},
			"/plaits/" ++ instanceNum ++ "/nudgeForward"
		);

		// Nudge back: /plaits/{n}/nudgeBack
		OSCdef.new(
			("plaits" ++ instanceNum ++ "nudgeBack").asSymbol,
			{
				arg msg, time, addr, port;
				var delta = ~nudgeAmount.neg;
				~dreads.synths[instanceIndex].nudgeOffset = (~dreads.synths[instanceIndex].nudgeOffset ? 0) + delta;
				~dreads.synths[instanceIndex].phaseOffset = (~dreads.synths[instanceIndex].phaseOffset ? 0) + delta;
				["plaits nudge back", instanceNum, "nudge:", ~dreads.synths[instanceIndex].nudgeOffset, "phase:", ~dreads.synths[instanceIndex].phaseOffset].postln;
			},
			"/plaits/" ++ instanceNum ++ "/nudgeBack"
		);
	};
};

// Sample OSC Handlers
~setupSampleOSC = {
	~dreads.samples.do { |instance, instanceIndex|
		var instanceNum = instanceIndex + 1;

		// ["binding sample ------------------->", instanceIndex].postln;

		// Generic parameter handling - OSC keys match data structure keys
		instance.keys.select({ |key| (key != \sequences) && (key != \samplePath) && (key != \lfo) }).do { |paramKey|
			OSCdef.new(
				("sample" ++ instanceNum ++ paramKey).asSymbol,
				{
					arg msg, time, addr, port;
					var value = msg[1];
					msg.round(0.001).postln;
					~dreads.samples[instanceIndex][paramKey] = value;
				},
				"/samples/" ++ instanceNum ++ "/" ++ paramKey.asString
			);
		};

		// Sequence selection OSC handlers for all sequenceable parameters
		~defaultSampleSequences.keys.do { |paramKey|

			OSCdef.new(
				("sample" ++ instanceNum ++ paramKey ++ "Seq").asSymbol,
				{
					arg msg, time, addr, port;
					var seqName = msg[1].asSymbol;
					msg.postln;
					~selectSequence.(\samples, instanceIndex, paramKey, seqName);
				},
				"/samples/" ++ instanceNum ++ "/" ++ paramKey.asString ++ "/seq"
			);
		};

		// Nudge forward: /samples/{n}/nudgeForward
		OSCdef.new(
			("sample" ++ instanceNum ++ "nudgeForward").asSymbol,
			{
				arg msg, time, addr, port;
				var delta = ~nudgeAmount;
				~dreads.samples[instanceIndex].nudgeOffset = (~dreads.samples[instanceIndex].nudgeOffset ? 0) + delta;
				~dreads.samples[instanceIndex].phaseOffset = (~dreads.samples[instanceIndex].phaseOffset ? 0) + delta;
				["sample nudge fwd", instanceNum, "nudge:", ~dreads.samples[instanceIndex].nudgeOffset, "phase:", ~dreads.samples[instanceIndex].phaseOffset].postln;
			},
			"/samples/" ++ instanceNum ++ "/nudgeForward"
		);

		// Nudge back: /samples/{n}/nudgeBack
		OSCdef.new(
			("sample" ++ instanceNum ++ "nudgeBack").asSymbol,
			{
				arg msg, time, addr, port;
				var delta = ~nudgeAmount.neg;
				~dreads.samples[instanceIndex].nudgeOffset = (~dreads.samples[instanceIndex].nudgeOffset ? 0) + delta;
				~dreads.samples[instanceIndex].phaseOffset = (~dreads.samples[instanceIndex].phaseOffset ? 0) + delta;
				["sample nudge back", instanceNum, "nudge:", ~dreads.samples[instanceIndex].nudgeOffset, "phase:", ~dreads.samples[instanceIndex].phaseOffset].postln;
			},
			"/samples/" ++ instanceNum ++ "/nudgeBack"
		);

		// Randomise: apply a randomisation profile to this sample instance
		// OSC: /samples/{n}/randomise  profileName  (tonal/colour/mod/fx/modFx/lfo/seq/full)
		OSCdef.new(
			("sample" ++ instanceNum ++ "randomise").asSymbol,
			{
				arg msg, time, addr, port;
				var mode;
				mode = if (msg[1].notNil) { msg[1].asSymbol } { \default };
				~randomise.(instanceIndex + 1, mode, \samples);
			},
			"/samples/" ++ instanceNum ++ "/randomise"
		);

		// File browser handler for this instance
		OSCdef.new(
			("sample" ++ instanceNum ++ "FileSelected").asSymbol,
			{
				arg msg, time, addr, port;
				var filepath = msg[1].asString;
				var lookup, metadata, duration;

				["Sample file selected (instance " ++ instanceIndex ++ "):", filepath].postln;

				// Lookup bank and variant from filepath
				lookup = ~lookupSampleByPath.(filepath);

				if (lookup.notNil) {
					["  Resolved to bank:", lookup.bankName, "variant:", lookup.variant].postln;

					// Update bankName and variant for this instance
					~dreads.samples[instanceIndex].bankName = lookup.bankName;
					~dreads.samples[instanceIndex].variant = lookup.variant;

					// Log sample metadata
					metadata = ~sampleLibrary.metadata[lookup.bankName];
					if (metadata.notNil && metadata[lookup.variant].notNil) {
						duration = metadata[lookup.variant].duration;
						["  Sample duration:", duration, "seconds"].postln;
					};
				} {
					["  ERROR: Could not find sample in loaded library"].postln;
				};
			},
			"/samples/" ++ instanceNum ++ "/samplePath"
		);

		// Variant cycling handlers
		OSCdef.new(
			("sample" ++ instanceNum ++ "PrevVariant").asSymbol,
			{
				arg msg, time, addr, port;
				~cycleSampleVariant.(instanceIndex, -1);
			},
			"/samples/" ++ instanceNum ++ "/prevVariant"
		);

		OSCdef.new(
			("sample" ++ instanceNum ++ "NextVariant").asSymbol,
			{
				arg msg, time, addr, port;
				~cycleSampleVariant.(instanceIndex, 1);
			},
			"/samples/" ++ instanceNum ++ "/nextVariant"
		);
	};
};

// LFO control OSC handlers (freq / shape / base per LFO-able param + global base)
~setupLFOOSC = {
	~dreads.synths.do { |instance, instanceIndex|
		var instanceNum = instanceIndex + 1;
		~plaitsLFOParams.do { |lfoParam|
			~lfoSourceParams.do { |sub|
				OSCdef.new(
					("plaits" ++ instanceNum ++ "lfo" ++ lfoParam ++ sub).asSymbol,
					{ |msg|
						var value, v, e;
						value = msg[1];
						msg.postln;
						v = if (sub == \shape) { value.asSymbol } { if (sub == \base) { value == 1 } { value.asFloat } };
						e = ();
						e.put(sub, v);
						~lfoTweak.(\plaits, instanceIndex, lfoParam, e);
					},
					"/plaits/" ++ instanceNum ++ "/lfo/" ++ lfoParam.asString ++ "/" ++ sub.asString
				);
			};
		};
	};
	~dreads.samples.do { |instance, instanceIndex|
		var instanceNum = instanceIndex + 1;
		~sampleLFOParams.do { |lfoParam|
			~lfoSourceParams.do { |sub|
				OSCdef.new(
					("sample" ++ instanceNum ++ "lfo" ++ lfoParam ++ sub).asSymbol,
					{ |msg|
						var value, v, e;
						value = msg[1];
						msg.postln;
						v = if (sub == \shape) { value.asSymbol } { if (sub == \base) { value == 1 } { value.asFloat } };
						e = ();
						e.put(sub, v);
						~lfoTweak.(\samples, instanceIndex, lfoParam, e);
					},
					"/samples/" ++ instanceNum ++ "/lfo/" ++ lfoParam.asString ++ "/" ++ sub.asString
				);
			};
		};
	};
	OSCdef.new(\lfoBase, { |msg| msg.postln; ~setLFOBase.(msg[1]) }, "/dreads/lfoBase");
};


// Delay Effect OSC Handlers
[\time, \feedback, \filterFreq, \spread].do { |paramKey|
	// ['binding fx/delay->', paramKey].postln;
	OSCdef.new(
		("fx_delay_" ++ paramKey).asSymbol,
		{
			arg msg, time, addr, port;
			var value = msg[1];
			var synthParam = ("fx_delay_" ++ paramKey).asSymbol;
			["fx/delay", paramKey, value].postln;

			// Update patch FX settings (nested structure)
			~dreads.fx.delay[paramKey] = value;

			// Send to synth using clean parameter names
			if (~fx.delay.notNil) {
				~fx.delay.set(paramKey, value);
			} {
				"ERROR: ~fx.delay is nil!".postln;
			};
		},
		"/fx/delay/" ++ paramKey.asString
	);
};

// Global Reverb Effect OSC Handlers
[\time, \damp, \hp, \diffuse, \freeze].do { |paramKey|
	// ['binding fx/reverb->', paramKey].postln;
	OSCdef.new(
		("fx_reverb_" ++ paramKey).asSymbol,
		{
			arg msg, time, addr, port;
			var value = msg[1];
			var synthParam = ("fx_reverb_" ++ paramKey).asSymbol;
			["fx/reverb", paramKey, value].postln;

			// Update patch FX settings (nested structure)
			~dreads.fx.reverb[paramKey] = value;

			// Send to synth using clean parameter names
			if (~fx.reverb.notNil) {
				~fx.reverb.set(paramKey, value);
			} {
				"ERROR: ~fx.reverb is nil!".postln;
			};
		},
		"/fx/reverb/" ++ paramKey.asString
	);
};

// Global Clouds Effect OSC Handlers
[\blend, \density, \freeze, \pitch, \position, \size, \texture, \reverb, \feedback, \spread, \inGain, \mode, \lofi, \volume].do { |paramKey|
	// ['binding fx/clouds->', paramKey].postln;
	OSCdef.new(
		("fx_clouds_" ++ paramKey).asSymbol,
		{
			arg msg, time, addr, port;
			var value = msg[1];
			var synthParam = ("fx_clouds_" ++ paramKey).asSymbol;
			["fx/clouds", paramKey, value].postln;

			// Update patch FX settings (nested structure)
			~dreads.fx.clouds[paramKey] = value;

			// Send to synth using clean parameter names
			if (~fx.clouds.notNil) {
				~fx.clouds.set(paramKey, value);
			} {
				"ERROR: ~fx.clouds is nil!".postln;
			};
		},
		"/fx/clouds/" ++ paramKey.asString
	);
};

OSCdef.new(
	\loadPatch.asSymbol,
	{
		arg msg, time, addr, port;
		var value = msg[1];
		["loadPatch", value].postln;
		~loadPatch.(value.asString)
	},
	"/dreads/loadPatch"
);

// Perf grid: load a patch by filename within the current patch's folder.
OSCdef.new(
	\loadFolderPatch.asSymbol,
	{
		arg msg, time, addr, port;
		var name = msg[1].asString;
		var path;
		if (~currentPatchTemplate.notNil) {
			path = ~currentPatchTemplate.standardizePath.dirname +/+ (name ++ ".scd");
			["loadFolderPatch", name, "->", path].postln;
			~loadPatch.(path);
		};
	},
	"/dreads/loadFolderPatch"
);

OSCdef.new(
	\globalTempo.asSymbol,
	{
		arg msg, time, addr, port;
		var bpm = msg[1].max(1);
		["tempo", bpm].postln;
		~tempoClock.tempo = bpm / 60;
		// Update all instances so patches save the current tempo
		~dreads.synths.do { |inst| inst.tempo = bpm };
		~dreads.samples.do { |inst| inst.tempo = bpm };
	},
	"/dreads/tempo"
);

OSCdef.new(
	\savePatch.asSymbol,
	{
		arg msg, time, addr, port;
		var value = msg[1];
		["savePatch", value].postln;
		~savePatch.()
	},
	"/dreads/savePatch"
);

OSCdef.new(
	\savePatchAs.asSymbol,
	{
		arg msg, time, addr, port;
		var value = msg[1];
		["savePatchAs", value].postln;
		~savePatchAs.()
	},
	"/dreads/savePatchAs"
);

OSCdef.new(
	\prevPatch.asSymbol,
	{
		arg msg, time, addr, port;
		["prevPatch"].postln;
		~loadAdjacentPatch.(-1);
	},
	"/dreads/prevPatch"
);

OSCdef.new(
	\nextPatch.asSymbol,
	{
		arg msg, time, addr, port;
		["nextPatch"].postln;
		~loadAdjacentPatch.(1);
	},
	"/dreads/nextPatch"
);

OSCdef.new(
	\reloadPatch.asSymbol,
	{
		arg msg, time, addr, port;
		var value = ~currentPatchTemplate;
		["reloadPatch", value].postln;
		~loadPatch.(value);
	},
	"/dreads/reloadPatch"
);

OSCdef.new(
	\flushSynths.asSymbol,
	{
		arg msg, time, addr, port;
		var value = msg[1];
		["flushSynths", value].postln;
		~voiceGroup.freeAll;
		// Clear drone synth references (synths already freed by freeAll)
		if (~drones.notNil) {
			~drones.size.do { |i| ~drones[i] = nil };
		};
	},
	"/dreads/flushSynths"
);

OSCdef.new(
	\fadeOutReverb,
	{
		arg msg, time, addr, port;
		var value = msg[1];
		"fadeOutReverb".postln;
		~fadeOutReverb.()
	},
	"/dreads/fadeOutReverb"
);

// Push current state values to UI
~pushStateToUI = {
	var ui, plaitsArray, fxSettings, seqNames, knownTags, uncategorized;

	ui = ~ui.();

	// Get current synth and FX data with fallback for compatibility
	if (~dreads.isKindOf(Dictionary)) {
		plaitsArray = ~dreads.synths;
		fxSettings = ~dreads.fx ?? ();
	} {
		plaitsArray = ~dreads; // Old array format fallback
		fxSettings = ();
	};

	// Send synth instance parameters
	plaitsArray.do { |instance, instanceIndex|
		var instanceNum = instanceIndex + 1;

		// Send all parameter values to UI
		instance.keys.select({ |key| (key != \sequences) && (key != \lfo) }).do { |paramKey|
			var value = instance[paramKey];
			var path = "/plaits/" ++ instanceNum ++ "/" ++ paramKey;
			// ["Sending:", path, value].postln;
			ui.sendMsg(path, value);
		};

		// Send sequence state to UI
		if (instance.sequences.notNil) {
			instance.sequences.keysValuesDo { |paramKey, value|
				var seqState, path;
				path = "/plaits/" ++ instanceNum ++ "/" ++ paramKey ++ "/seq";
				seqState = if (value.isKindOf(Symbol)) {
					value.asString
				} {
					// Bare stream or Event with source — both are custom sequences
					"custom"
				};
				ui.sendMsg(path, seqState);
			};
		};
	};

	// Send sample instance parameters
	~dreads.samples.do { |instance, instanceIndex|
		var instanceNum = instanceIndex + 1;

		// Send all parameter values to UI
		instance.keys.select({ |key| (key != \sequences) && (key != \lfo) }).do { |paramKey|
			var value = instance[paramKey];
			var path = "/samples/" ++ instanceNum ++ "/" ++ paramKey;
			// ["Sending:", path, value].postln;
			ui.sendMsg(path, value);
		};

		// Send sequence state to UI
		if (instance.sequences.notNil) {
			instance.sequences.keysValuesDo { |paramKey, value|
				var seqState, path;
				path = "/samples/" ++ instanceNum ++ "/" ++ paramKey ++ "/seq";
				seqState = if (value.isKindOf(Symbol)) {
					value.asString
				} {
					"custom"
				};
				ui.sendMsg(path, seqState);
			};
		};

		// Resolve and send file path from bankName/variant
		if (instance.bankName.notNil) {
			var bankPaths = ~sampleLibrary.paths[instance.bankName];
			if (bankPaths.notNil) {
				var filepath = bankPaths[instance.variant.asInteger];
				if (filepath.notNil) {
					var path = "/samples/" ++ instanceNum ++ "/samplePath";
					// ["Sending resolved sample path:", path, filepath].postln;
					ui.sendMsg(path, filepath);
				} {
					["WARNING: Variant", instance.variant.asInteger, "not found in bank", instance.bankName].postln;
				};
			} {
				["WARNING: Bank", instance.bankName, "not found in sample library"].postln;
			};
		};
	};

	// Send global tempo
	ui.sendMsg("/dreads/tempo", ~dreads.synths[0].tempo);

	// Send global FX parameters (nested structure)
	fxSettings.keysValuesDo { |category, categoryParams|
		categoryParams.keysValuesDo { |param, value|
			var path = "/fx/" ++ category ++ "/" ++ param;
			// ["Sending:", path, value].postln;
			ui.sendMsg(path, value);
		};
	};

	// Populate sequence modal switch with categorized sequences from library
	seqNames = List[];
	[
		[\rhythm, "RHYTHM"],
		[\shape, "SHAPE"],
		[\accent, "ACCENT"],
		[\pitch, "PITCH"],
		[\timing, "TIMING"],
	].do { |pair|
		var tag, label, entries;
		tag = pair[0]; label = pair[1];
		entries = ~sequenceLibrary.keys.asArray.select { |k|
			~sequenceLibrary[k].tag == tag
		}.sort.collect(_.asString);
		if (entries.size > 0) {
			seqNames.add("── " ++ label ++ " ──");
			seqNames.addAll(entries);
		};
	};
	// Collect any entries with unrecognized tags (e.g. user sequences with custom tags)
	knownTags = [\all, \rhythm, \shape, \accent, \pitch, \timing];
	uncategorized = ~sequenceLibrary.keys.asArray.select { |k|
		knownTags.includes(~sequenceLibrary[k].tag).not
	}.sort.collect(_.asString);
	if (uncategorized.size > 0) {
		seqNames.add("── OTHER ──");
		seqNames.addAll(uncategorized);
	};
	// ["seqModal:", seqNames.size, "items"].postln;
	ui.sendMsg('/EDIT', 'seqModal/switch',
		"{\"values\":[" ++ seqNames.collect { |s| "\"" ++ s ++ "\"" }.join(",") ++ "]}"
	);

	// Push LFO state (freq / shape name / base) per param + global base
	~dreads.synths.do { |instance, instanceIndex|
		var instanceNum = instanceIndex + 1;
		~plaitsLFOParams.do { |lfoParam|
			var src;
			src = instance.lfo[lfoParam];
			if (src.isKindOf(Symbol)) { src = ~lfo.sources[src] };
			if (src.notNil) {
				ui.sendMsg("/plaits/" ++ instanceNum ++ "/lfo/" ++ lfoParam ++ "/freq", src[\freq]);
				ui.sendMsg("/plaits/" ++ instanceNum ++ "/lfo/" ++ lfoParam ++ "/shape", ~lfoShapeNames[src[\shape]].asString);
				ui.sendMsg("/plaits/" ++ instanceNum ++ "/lfo/" ++ lfoParam ++ "/base", if (src[\base] == true) { 1 } { 0 });
				ui.sendMsg("/plaits/" ++ instanceNum ++ "/lfo/" ++ lfoParam ++ "/width", src[\width]);
			};
		};
	};
	~dreads.samples.do { |instance, instanceIndex|
		var instanceNum = instanceIndex + 1;
		~sampleLFOParams.do { |lfoParam|
			var src;
			src = instance.lfo[lfoParam];
			if (src.isKindOf(Symbol)) { src = ~lfo.sources[src] };
			if (src.notNil) {
				ui.sendMsg("/samples/" ++ instanceNum ++ "/lfo/" ++ lfoParam ++ "/freq", src[\freq]);
				ui.sendMsg("/samples/" ++ instanceNum ++ "/lfo/" ++ lfoParam ++ "/shape", ~lfoShapeNames[src[\shape]].asString);
				ui.sendMsg("/samples/" ++ instanceNum ++ "/lfo/" ++ lfoParam ++ "/base", if (src[\base] == true) { 1 } { 0 });
				ui.sendMsg("/samples/" ++ instanceNum ++ "/lfo/" ++ lfoParam ++ "/width", src[\width]);
			};
		};
	};
	ui.sendMsg("/dreads/lfoBase", ~base);


	// Populate the Perf-tab patch grid (also refreshed on every load/save via
	// ~updatePatchUI; this covers boot / full state pushes). nil-safe no-op.
	~pushPerfGrid.();

	"Plaits state pushed to UI!".postln;
};

// OSC handler for refreshing sample library
OSCdef(\refreshSampleLibrary, {
	arg msg, time, addr, port;

	"Refreshing sample library...".postln;

	// Free old buffers first so repeated refreshes don't leak buffer numbers.
	// Buffers are resolved fresh per note (~getSampleBuffer), so the reload is
	// safe mid-play — worst case is one glitched note during the async read.
	~freeSampleLibrary.();
	~loadSampleLibrary.();

	"Sample library refreshed".postln;
}, '/dreads/refreshSampleLibrary');

// Debug OSCFunc for catching all sample-related messages
OSCFunc({ |msg, time, addr, port|
	var path = msg[0];
	// Show all sample-related messages for debugging
	if (path.asString.contains("/samples")) {
		["OSC received:", msg].postln;
	};
	// Show other possible typos
	if (path.asString.contains("/plaits") ||
	    path.asString.contains("/delay") ||
	    path.asString.contains("/reverb") ||
	    path.asString.contains("/clouds") ||
	    path.asString.contains("/patch")) {
		["POSSIBLE TYPO:", msg].postln;
	};
});

// Setup OSC for plaits instances (called after patch structure is loaded)
~setupPlaitsOSC.();
~setupSampleOSC.();
~setupLFOOSC.();

~pushStateToUI.value;
)