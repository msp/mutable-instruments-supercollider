//////////////////////////////////////////////////////////////////////////////
// Plaits Sequence Definitions
//////////////////////////////////////////////////////////////////////////////

(
/*~tdKeys = [
\pitch, \engine, \harm, \timbre, \morph, \decay, \fmMod, \lpgColour,
\mul, \revDrywet, \revTime, \revDamp, \revHp, \revFreeze,
\delaySend, \reverbSend, \cloudsSend, \distDrive, \distAmount,
\stereoMode, \volume, \out, \dur, \legato
];*/
~tdKeys = [
	\pitch, \engine, \harm, \timbre
];

~sendEventToTD = { |idx, ev|
	var msg = ["/plaits/state", idx];
	~tdKeys.do { |k| var v = ev[k]; if(v.notNil) { msg = msg ++ [k.asString, v] } };
	["~sendEventToTD", msg].postln;
	~td.().sendMsg(*msg);
	~ws.().sendMsg(*msg);
};

~noteCounter = Array.fill(~dreads.synths.size, 0);



// Clear stream cache so all sequence patterns start at position 0 on reload
~sequenceStreamCache = Dictionary.new;
x = Pdef(\plaitsSequence,
	Ppar(
		~dreads.synths.collect { |instance, i|
			Pseq([
			Pfuncn({ Rest(~dreads.synths[i].phaseOffset ? 0) }, 1),
			Pcollect({ |ev|
				var d       = ev[\dur];
				var isRest  = d.isKindOf(Rest);
				var durVal  = isRest.if({ d.value }, { d });  // numeric seconds

				if (isRest.not) {
					// tick only on real notes
					~noteCounter[i] = (~noteCounter[i] ? 0) + 1;

					// ["event", ~noteCounter[i], durVal].postln;

					~td.().sendMsg("/plaits/state", i,
						"note",       ~noteCounter[i],
						"tempo",      ~dreads.synths[0].tempo,
						"pitch",      ev[\pitch],
						"engine",     ev[\engine],
						"harm",       ev[\harm],
						"timbre",     ev[\timbre],
						"decay",      ev[\decay],
						"morph",      ev[\morph],
						"dur",        durVal,
						"volume",     (ev[\volume] ?? ev[\mul] ?? 0.0),
						"cloudsSend", (ev[\cloudsSend] ?? 0.0),
						"delaySend",  (ev[\delaySend] ?? 0.0),
						"reverbSend", (ev[\reverbSend] ?? 0.0),
						"revDrywet",  (ev[\revDrywet] ?? 0.0),
						"distAmount", (ev[\distAmount] ?? 0.0),
						"amRatio", (ev[\amRatio] ?? 1.0),
						"amDepth", (ev[\amDepth] ?? 0.0),
						"amRing", (ev[\amRing] ?? 0.0)
					);

					~vis.().sendBundle(nil,
						["/plaits/" ++ i ++ "/note",       ~noteCounter[i]],
						["/plaits/" ++ i ++ "/tempo",      ~dreads.synths[0].tempo],
						["/plaits/" ++ i ++ "/pitch",      ev[\pitch] / 127.0],
						["/plaits/" ++ i ++ "/engine",     ev[\engine] / 23.0],
						["/plaits/" ++ i ++ "/harm",       ev[\harm]],
						["/plaits/" ++ i ++ "/timbre",     ev[\timbre]],
						["/plaits/" ++ i ++ "/decay",      ev[\decay]],
						["/plaits/" ++ i ++ "/morph",      ev[\morph]],
						["/plaits/" ++ i ++ "/dur",        durVal],
						["/plaits/" ++ i ++ "/volume",     (ev[\volume] ?? ev[\mul] ?? 0.0)],
						["/plaits/" ++ i ++ "/cloudsSend", (ev[\cloudsSend] ?? 0.0)],
						["/plaits/" ++ i ++ "/delaySend",  (ev[\delaySend] ?? 0.0)],
						["/plaits/" ++ i ++ "/reverbSend", (ev[\reverbSend] ?? 0.0)],
						["/plaits/" ++ i ++ "/revDrywet",  (ev[\revDrywet] ?? 0.0)],
						["/plaits/" ++ i ++ "/distAmount", (ev[\distAmount] ?? 0.0)],
						["/plaits/" ++ i ++ "/amRatio", (ev[\amRatio] ?? 1.0) / 8.0],
						["/plaits/" ++ i ++ "/amDepth", (ev[\amDepth] ?? 0.0)],
						["/plaits/" ++ i ++ "/amRing", (ev[\amRing] ?? 0.0)]
					);

					if (~dreads.synths[i].sendToPhones == 1.0) {
						~ws.().sendMsg("/plaits/state", i,
							"note",       ~noteCounter[i],
							"tempo",      ~dreads.synths[0].tempo,
							"pitch",      ev[\pitch],
							"engine",     ev[\engine],
							"harm",       ev[\harm],
							"timbre",     ev[\timbre],
							"decay",      ev[\decay],
							"morph",      ev[\morph],
							"dur",        durVal,
							"volume",     (ev[\volume] ?? ev[\mul] ?? 0.0),
							"cloudsSend", (ev[\cloudsSend] ?? 0.0),
							"delaySend",  (ev[\delaySend] ?? 0.0),
							"reverbSend", (ev[\reverbSend] ?? 0.0),
							"revDrywet",  (ev[\revDrywet] ?? 0.0),
							"distAmount", (ev[\distAmount] ?? 0.0),
							"amRatio", (ev[\amRatio] ?? 1.0),
							"amDepth", (ev[\amDepth] ?? 0.0),
							"amRing", (ev[\amRing] ?? 0.0)
						);
					}
				};

				// Forward sequencer modulation to drone synth.
				// SC's \type \set event only sends default keys (freq, amp, pan) so we
				// forward \plaitsDrone control names explicitly via .set here instead.
				if (~dreads.synths[i].droneMode == 1) {
					if (~drones[i].notNil) {
						~drones[i].set(
							\pitch, ev[\pitch], \engine, ev[\engine],
							\harm, ev[\harm], \timbre, ev[\timbre],
							\morph, ev[\morph], \decay, ev[\decay],
							\fmMod, ev[\fmMod], \lpgColour, ev[\lpgColour],
							\mul, ev[\mul], \volume, ev[\volume],
							\revDrywet, ev[\revDrywet], \revTime, ev[\revTime],
							\cloudsSend, ev[\cloudsSend], \delaySend, ev[\delaySend],
							\reverbSend, ev[\reverbSend],
							\distDrive, ev[\distDrive], \distAmount, ev[\distAmount],
							\amDepth, ev[\amDepth], \amRing, ev[\amRing]
						);
					};
				};

				ev
			},

			Pbind(
				\type, Pfunc {
					if (~dreads.synths[i].droneMode == 1) { \rest } {
						if (~dreads.synths[i].mute == 1) { \rest } { \note };
					};
				},
				\instrument, \plaits,
				\group, ~voiceGroup,
				\delayBus, ~delayBus,
				\reverbBus, ~reverbBus,
				\timbreLFO, Pfunc { ~dreads.synths[i].lfo.timbre.bus.asMap },
				\morphLFO, Pfunc { ~dreads.synths[i].lfo.morph.bus.asMap },
				\decayLFO, Pfunc { ~dreads.synths[i].lfo.decay.bus.asMap },
				\pitchLFO, Pfunc { ~dreads.synths[i].lfo.pitch.bus.asMap },
				\volumeLFO, Pfunc { ~dreads.synths[i].lfo.volume.bus.asMap },
				\harmLFO, Pfunc { ~dreads.synths[i].lfo.harm.bus.asMap },
				\amRingLFO, Pfunc { ~dreads.synths[i].lfo.amRing.bus.asMap },
				\amDepthLFO, Pfunc { ~dreads.synths[i].lfo.amDepth.bus.asMap },
				\amRatioLFO, Pfunc { ~dreads.synths[i].lfo.amRatio.bus.asMap },
				\timbMod, Pfunc { ~dreads.synths[i].timbMod },
				\morphMod, Pfunc { ~dreads.synths[i].morphMod },
				\decayMod, Pfunc { ~dreads.synths[i].decayMod },
				\pitchMod, Pfunc { ~dreads.synths[i].pitchMod },
				\volumeMod, Pfunc { ~dreads.synths[i].volumeMod },
				\harmMod, Pfunc { ~dreads.synths[i].harmMod },
				\amRingMod, Pfunc { ~dreads.synths[i].amRingMod },
				\amDepthMod, Pfunc { ~dreads.synths[i].amDepthMod },
				\amRatioMod, Pfunc { ~dreads.synths[i].amRatioMod },
				\pitch, Pfunc { |event|
					// ["--->", ~state, ~dreads.synths[i].engine, ~playCount].postln;
					if (i == 0) {
						~playCount = ~playCount + 1;
						if (~playCount % 16 == 0) {
							~state = ~states.next;
							// "Completed 16 steps".postln;
						};
					};

					~add.(~getSequenceValue.(~dreads.synths[i], i, \plaits, \pitch), ~dreads.synths[i].pitch);
				},
				\dur, Pfunc { |event|

					// var v = ~sineAtBeat.(~tempoClock.beats, 64, 0.15, 0.5);
					// ~dreads.synths[i].dur = ~setDuration.(v, ~dreads.synths[i].sequences.div.next);
					// ~dreads.synths[i].dur = v;
					// ~dreads.synths[i].dur;

					var baseDur = ~setDuration.(
						~getSequenceValue.(~dreads.synths[i], i, \plaits, \duration),
						~getSequenceValue.(~dreads.synths[i], i, \plaits, \div)
					);
					var speed = ~dreads.synths[i].speed.clip(0.01, 100);
					var nudge = ~dreads.synths[i].nudgeOffset ? 0;
					var finalDur;
					~dreads.synths[i].nudgeOffset = 0;
					finalDur = (baseDur / speed + nudge).max(0.001);
					~dreads.synths[i].dur = finalDur;
						// ["plaits", i, "event at", thisThread.beats, "dur =", finalDur].postln;
					finalDur;
				},
				\decay, Pfunc { |event|
					~modulateBipolar.(~getSequenceValue.(~dreads.synths[i], i, \plaits, \decay), ~dreads.synths[i].decay);
				},
				\harm, Pfunc { |event|
					var inst, seqVal;
					inst = ~dreads.synths[i];
					seqVal = ~getSequenceValue.(inst, i, \plaits, \harm);
					inst.seqCache ?? { inst.seqCache = () };
					inst.seqCache[\harm] = seqVal;
					~modulateBipolar.(seqVal, inst.harm)
				},
				\timbre, Pfunc { |event|
					~modulateBipolar.(~getSequenceValue.(~dreads.synths[i], i, \plaits, \timbre), ~dreads.synths[i].timbre);
				},
				\morph, Pfunc { |event|
					~modulateBipolar.(~getSequenceValue.(~dreads.synths[i], i, \plaits, \morph), ~dreads.synths[i].morph);
				},
				\fmMod, Pfunc { |event|
					~modulateBipolar.(~getSequenceValue.(~dreads.synths[i], i, \plaits, \fmMod), ~dreads.synths[i].fmMod);
				},
				\lpgColour, Pfunc { |event|
					~modulateBipolar.(~getSequenceValue.(~dreads.synths[i], i, \plaits, \lpgColour), ~dreads.synths[i].lpgColour);
				},
				\legato, Pfunc { |event|
					var eng = ~dreads.synths[i].engine.asInteger;
					var leg;
					leg = if (eng >= 18 and: { eng <= 20 }) {
						// FM engines bypass LPG/decay, so remap decay knob to legato
						// decay 0-1 → legato 0.01-15
						~dreads.synths[i].decay.linlin(0, 1, 0.01, 15);
					} {
						~dreads.synths[i].legato;
					};
					// Floor so a near-zero legato can't leave note synths un-freed
					// (short gate -> Linen release never completes -> node leak -> server death).
					leg.max(0.05);
				},
				// Note release/tail (Linen release, seconds) — per-voice scalar.
				\releaseTime, Pfunc { ~dreads.synths[i].releaseTime },
				\engine, Pfunc { |event|
					~setEngine.(~dreads.synths[i].sequences.engine.next, ~dreads.synths[i].engine);
				},
				\mul, Pfunc { |event|
					if (~dreads.synths[i].mute == 1) { 0 } {
						~modulateBipolar.(~getSequenceValue.(~dreads.synths[i], i, \plaits, \mul), ~dreads.synths[i].mul);
					};
				},
				\revDrywet, Pfunc { |event|
					var inst, seqVal;
					inst = ~dreads.synths[i];
					seqVal = ~getSequenceValue.(inst, i, \plaits, \revDrywet);
					inst.seqCache ?? { inst.seqCache = () };
					inst.seqCache[\revDrywet] = seqVal;
					~modulateBipolar.(seqVal, inst.revDrywet)
				},
				\revTime, Pfunc { |event|
					var out = ~modulateBipolar.(~getSequenceValue.(~dreads.synths[i], i, \plaits, \revTime), ~dreads.synths[i].revTime);
					// ["revTime", out].postln;

					out
				},
				\revDamp, Pfunc { |event| ~dreads.synths[i].revDamp },
				\revHp, Pfunc { |event| ~dreads.synths[i].revHp },
				\revFreeze, Pfunc { |event| ~dreads.synths[i].revFreeze },
				// AM / ring-mod — ratio/wave/fixedHz are static scalars; depth & am/rm
				// are sequenceable (modulateBipolar: the knob scales a 0-1 shape sequence).
				\amRatio, Pfunc { |event| ~dreads.synths[i].amRatio },
				\amWave, Pfunc { |event| ~dreads.synths[i].amWave },
				\amDepth, Pfunc { |event|
					var inst, seqVal;
					inst = ~dreads.synths[i];
					seqVal = ~getSequenceValue.(inst, i, \plaits, \amDepth);
					inst.seqCache ?? { inst.seqCache = () };
					inst.seqCache[\amDepth] = seqVal;      // cached for the vis live-drag echo
					~modulateBipolar.(seqVal, inst.amDepth)
				},
				\amRing, Pfunc { |event|
					var inst, seqVal;
					inst = ~dreads.synths[i];
					seqVal = ~getSequenceValue.(inst, i, \plaits, \amRing);
					inst.seqCache ?? { inst.seqCache = () };
					inst.seqCache[\amRing] = seqVal;
					~modulateBipolar.(seqVal, inst.amRing)
				},
				\amFixedHz, Pfunc { |event| ~dreads.synths[i].amFixedHz },
				\delaySend, Pfunc { |event|
					var inst, seqVal;
					inst = ~dreads.synths[i];
					seqVal = ~getSequenceValue.(inst, i, \plaits, \delaySend);
					inst.seqCache ?? { inst.seqCache = () };
					inst.seqCache[\delaySend] = seqVal;
					~modulateBipolar.(seqVal, inst.delaySend)
				},
				\reverbSend, Pfunc { |event|
					var inst, seqVal;
					inst = ~dreads.synths[i];
					seqVal = ~getSequenceValue.(inst, i, \plaits, \reverbSend);
					inst.seqCache ?? { inst.seqCache = () };
					inst.seqCache[\reverbSend] = seqVal;
					~modulateBipolar.(seqVal, inst.reverbSend)
				},
				\cloudsSend, Pfunc { |event|
					var inst, seqVal;
					inst = ~dreads.synths[i];
					seqVal = ~getSequenceValue.(inst, i, \plaits, \cloudsSend);
					inst.seqCache ?? { inst.seqCache = () };
					inst.seqCache[\cloudsSend] = seqVal;
					~modulateBipolar.(seqVal, inst.cloudsSend)
				},
				\distDrive, Pfunc { |event|
					~modulateBipolar.(~getSequenceValue.(~dreads.synths[i], i, \plaits, \distDrive), ~dreads.synths[i].distDrive);
				},
				\distAmount, Pfunc { |event|
					var inst, seqVal;
					inst = ~dreads.synths[i];
					seqVal = ~getSequenceValue.(inst, i, \plaits, \distAmount);
					inst.seqCache ?? { inst.seqCache = () };
					inst.seqCache[\distAmount] = seqVal;
					~modulateBipolar.(seqVal, inst.distAmount)
				},
				\stereoMode, Pfunc { |event| ~dreads.synths[i].stereoMode },
				\volume, Pfunc { |event|
					var inst, seqVal;
					inst = ~dreads.synths[i];
					seqVal = ~getSequenceValue.(inst, i, \plaits, \volume);
					inst.seqCache ?? { inst.seqCache = () };
					inst.seqCache[\volume] = seqVal;      // cached for the vis live-drag echo
					~modulateBipolar.(seqVal, inst.volume)
				},
				\out, Pfunc { ~voiceOutBus.(\plaits, i) },
			))
			])
		} ++
		// Sample instances (use lookups for live coding)
		~dreads.samples.collect { |instance, i|
			Pseq([
			Pfuncn({ Rest(~dreads.samples[i].phaseOffset ? 0) }, 1),
			Pbind(
				\type, Pfunc { if (~dreads.samples[i].mute == 1) { \rest } { \oneShotSample } },
				\instrument, \panningSamplePlayer,
				\group, ~voiceGroup,
				\rateLFO, Pfunc { ~dreads.samples[i].lfo.rate.bus.asMap },
				\rateMod, Pfunc { ~dreads.samples[i].rateMod },
				\volumeLFO, Pfunc { ~dreads.samples[i].lfo.volume.bus.asMap },
				\volumeMod, Pfunc { ~dreads.samples[i].volumeMod },
				// Variant selection: two modes, both relative to base scalar, wrapped to bank size
			// Numeric: additive offset from base — Pseq([0, 2, -3], inf) with base 6 → 6, 8, 3
			// String:  "v" expression syntax  — Pseq(["v", "v+2", "v-3"], inf) with base 6 → 6, 8, 3
				\sampleVariant, Pfunc {
					var variantSeq = ~getSequenceValue.(~dreads.samples[i], i, \samples, \variant);
					var variantBase = ~dreads.samples[i].variant;
					var bankName = ~dreads.samples[i].bankName;
					var numVariants = (~sampleLibrary.banks[bankName] ? []).size.max(1);
					if (variantSeq.isKindOf(String) || variantSeq.isKindOf(Symbol)) {
						~setVariant.(variantSeq, variantBase, numVariants);
					} {
						~add.(variantSeq, variantBase).asInteger.wrap(0, numVariants - 1);
					};
				},
				// Get sample duration for scaling normalized values
				\sampleDuration, Pfunc { |event|
					var bankName = ~dreads.samples[i].bankName;
					var variant = event[\sampleVariant];
					var metadata, duration;

					if (bankName.notNil) {
						metadata = ~sampleLibrary.metadata[bankName];
						if (metadata.notNil && metadata[variant].notNil) {
							duration = metadata[variant].duration;
						};
					};

					duration ?? 1.0;  // Fallback to 1.0 second if not found
				},
				\bufnum, Pfunc { |event|
					var bankName = ~dreads.samples[i].bankName;
					var buffer = ~getSampleBuffer.(bankName, event[\sampleVariant]);
					buffer ?? 0;
				},
				\numChannels, Pfunc { |event|
					var bankName = ~dreads.samples[i].bankName;
					var buffer = ~getSampleBuffer.(bankName, event[\sampleVariant]);
					if (buffer.notNil) { buffer.numChannels } { 1 };
				},
				\dur, Pfunc {
					var durSeq = ~getSequenceValue.(~dreads.samples[i], i, \samples, \duration);
					var divSeq = ~getSequenceValue.(~dreads.samples[i], i, \samples, \div);
					var baseDur = ~setDuration.(durSeq, divSeq);
					var speed = ~dreads.samples[i].speed.clip(0.01, 100);
					var nudge = ~dreads.samples[i].nudgeOffset ? 0;
					var finalDur;
					~dreads.samples[i].nudgeOffset = 0;
					finalDur = (baseDur / speed + nudge).max(0.001);
					~dreads.samples[i].dur = finalDur;
					// ["sample", i, "event at", thisThread.beats, "dur =", finalDur].postln;
					finalDur;
				},
				\legato, Pfunc { |event| ~dreads.samples[i].legato },
				\mul, Pfunc {
				var baseMul, result;
				if (~dreads.samples[i].mute == 1) { 0 } {
					baseMul = ~dreads.samples[i].mul;
					result = ~modulateBipolar.(~getSequenceValue.(~dreads.samples[i], i, \samples, \mul), baseMul);
					result;
				};
			},
				\rate, Pfunc {
					var rateSeq = ~getSequenceValue.(~dreads.samples[i], i, \samples, \rate);
					var baseRate = ~dreads.samples[i].rate;
					var result = ~multiply.(rateSeq, baseRate);
					// if (i == 0) { ["Sample", i, "rateSeq:", rateSeq, "baseRate:", baseRate, "->", result].postln; };
					result;
				},
				\startPos, Pfunc { |event|
					var bankName = ~dreads.samples[i].bankName;
					var buffer = ~getSampleBuffer.(bankName, event[\sampleVariant]);
					var duration = event[\sampleDuration];
					// UI and sequence are normalized 0-1, scale to sample duration
					var normalized = ~modulateBipolar.(
						~getSequenceValue.(~dreads.samples[i], i, \samples, \startPos),
						~dreads.samples[i].startPos
					);
					var seconds = normalized * duration;  // Scale to actual sample length
					var frames = ~secondsToFrames.(seconds, buffer);
					// if (i == 0) { ["Sample startPos - norm:", normalized, "seconds:", seconds, "frames:", frames].postln; };
					frames;
				},
				\atk, Pfunc { |event|
					var duration = event[\sampleDuration];
					// Normalized 0-1, scale to duration/2 (attack shouldn't exceed half the sample)
					var normalized = ~modulateBipolar.(
						~getSequenceValue.(~dreads.samples[i], i, \samples, \atk),
						~dreads.samples[i].atk
					);
					normalized * (duration / 2);
				},
				\decay, Pfunc { |event|
					var duration = event[\sampleDuration];
					// Normalized 0-1, scale to duration*2 (allow longer decay than sample)
					var normalized = ~modulateBipolar.(
						~getSequenceValue.(~dreads.samples[i], i, \samples, \decay),
						~dreads.samples[i].decay
					);
					normalized * (duration * 2);
				},
				\panDur, Pfunc { |event|
					var duration = event[\sampleDuration];
					// Normalized 0-1, scale to duration*2
					var normalized = ~modulateBipolar.(
						~getSequenceValue.(~dreads.samples[i], i, \samples, \panDur),
						~dreads.samples[i].panDur
					);
					// if (i == 0) { ["Sample panDur - norm:", normalized, "duration:", duration, "->", normalized * (duration * 2), "seconds"].postln; };
					normalized * (duration * 2);
				},
				\volume, Pfunc {
				var vol = ~dreads.samples[i].volume;
					// if (i == 0) { ["Sample", i, "volume:", vol].postln; };
				vol;
			},
				\cloudsSend, Pfunc { ~modulateBipolar.(~getSequenceValue.(~dreads.samples[i], i, \samples, \cloudsSend), ~dreads.samples[i].cloudsSend) },
				\delaySend, Pfunc { ~modulateBipolar.(~getSequenceValue.(~dreads.samples[i], i, \samples, \delaySend), ~dreads.samples[i].delaySend) },
				\reverbSend, Pfunc { ~modulateBipolar.(~getSequenceValue.(~dreads.samples[i], i, \samples, \reverbSend), ~dreads.samples[i].reverbSend) },
				\distDrive, Pfunc { |event| ~dreads.samples[i].distDrive },
				\distAmount, Pfunc { |event|
					~modulateBipolar.(~getSequenceValue.(~dreads.samples[i], i, \samples, \distAmount), ~dreads.samples[i].distAmount);
				},
				\revDrywet, Pfunc { |event|
					~modulateBipolar.(~getSequenceValue.(~dreads.samples[i], i, \samples, \revDrywet), ~dreads.samples[i].revDrywet);
				},
				\revTime, Pfunc { |event|
					~modulateBipolar.(~getSequenceValue.(~dreads.samples[i], i, \samples, \revTime), ~dreads.samples[i].revTime);
				},
				\revDamp, Pfunc { |event|
					~modulateBipolar.(~getSequenceValue.(~dreads.samples[i], i, \samples, \revDamp), ~dreads.samples[i].revDamp);
				},
				\revHp, Pfunc { |event|
					~modulateBipolar.(~getSequenceValue.(~dreads.samples[i], i, \samples, \revHp), ~dreads.samples[i].revHp);
				},
				\revFreeze, Pfunc { |event| ~dreads.samples[i].revFreeze },
				\out, Pfunc { ~voiceOutBus.(\samples, i) },
			)
			])
		}
	)
);
Pdef(\plaitsSequence).quant = 1;
)