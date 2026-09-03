# MiPlaits Modulation Investigation

## Conventions

- **Use UK (British) spelling everywhere** — identifiers, OSC addresses, comments, docs,
  and commit messages. Prefer `-ise`/`-isation` over `-ize`/`-ization`, and `colour`,
  `behaviour`, etc. E.g. `~randomise` (not `~randomize`), `/dreads/randomiseAll`,
  `serialised`, `~randomiseRanges`. Match this when extending existing code.

- **Derive, don't hardcode — avoid magic numbers and fixed lists where a value can be
  computed from a single source of truth.** Prefer `~numPlaits * ~plaitsLFOParams.size`
  over a literal `33`; iterate the actual data (`~plaitsLFOParams`, a map's keys,
  `sourceUsages`) over a fixed range like `(1..21)`; loop `~numPlaits.do`/`.size` over a
  bare `3`. When a count or list *is* the authority (e.g. `~defaultPlaitsLFOMap`), make
  everything else read/derive from it rather than re-encoding the same assumption — a
  duplicated literal is a bug waiting to drift (this is what stranded the AM LFO sources
  in the patch serialiser and shuffle script). If a value genuinely must be repeated in
  two places (e.g. the globals LFO map ↔ the `\lfoReporter` bus wiring), add a comment in
  both naming the counterpart so they stay in lockstep.

- **Don't hand-maintain a list that mirrors a definitive source — derive it, with
  explicit exclusions.** A parallel list drifts silently: `~startDrone` re-listed ~40
  synth args by hand, so new scalars (`amRingMod`/`amDepthMod`/`amRatioMod`) were
  forgotten and the drone ignored them until a knob was touched. The fix is to build the
  list from the authority — here, the synthdef's own controls: `SynthDescLib.global.at(
  \name).controls.collect(_.name)` intersected with the instance scalars, minus a small
  explicit exclusion set (specials like `mul`, bus-mapped `*LFO` controls). Introspection
  is self-maintaining (invalid keys can't leak, new valid ones flow in) and beats a
  hand-kept exclusion list, which is just another parallel list that drifts. When you
  catch yourself typing a second copy of a list that already exists somewhere, stop and
  derive from the original.

## SuperCollider Language Gotchas

When writing SC code, follow these rules strictly to avoid silent failures and interpreter crashes.

### `var` declarations
- `var` must appear at the **very top** of a function or block, before any other statements
- `var x = if(...) { } { }` can cause silent errors — declare `var x;` first, then assign `x = if(...) ...` on a separate line
- Inside `.do` / `.collect` closures, declare all `var`s first, then assign:
  ```supercollider
  // WRONG: var k = test[0], n = test[1];
  // RIGHT:
  var k, n;
  k = test[0]; n = test[1];
  ```

### Control structures
- `if(cond) { trueFunc } { falseFunc }` — both branches are **functions** (blocks), not expressions
- `while { testFunc } { bodyFunc }` — test is a **function** that gets re-evaluated each iteration
- `switch(value) { test1 } { body1 } { test2 } { body2 }` — alternating test/body pairs
- Never use `if` inline to initialise a `var` on the same line

### Arrays
- `Array.new(n)` creates capacity but size 0 — prefer `Array.fill(n, { |i| ... })`
- `.add()` may return a **new** array — always reassign: `z = z.add(obj)`
- Use `List` instead of `Array` if you need frequent add/remove
- Array slicing: `a[4..8]`, but reversed ranges `a[5..3]` return elements in reverse (probably not what you want)

### Common pitfalls
- `1 ! n` creates an Array of `n` ones — but `1 ! 1 ! k` has unpredictable precedence, use `Array.fill` instead
- Environment variables (`~myVar`) persist across blocks — a function that captures `~dreads.synths[i]` will see stale data if the object is replaced. Always re-read from the environment inside handlers.
- Trailing function args must be **literal blocks** `{ }`, not variables holding functions
- `min(a, b)` is a function call; `a.min(b)` is a method call — both work but be consistent
- SC is single-threaded with cooperative scheduling — no race conditions in pattern Pfuncs vs OSC handlers

## Project Context
- SuperCollider audio programming project focused on Mutable Instruments Plaits emulation
- Uses MiPlaits UGen with 16 synthesis engines
- Pattern-based sequencing with OSC control integration
- User moved plaits work to separate `../mutable-sc` project

## Key Issue Discovered
**Problem**: Timbre modulation (LFTri) audible when triggering synth manually with Impulse, but not audible when triggered via patterns.

**Root Cause**: Pattern-triggered synths get killed/recreated each note (due to `doneAction: Done.freeSelf` in Linen envelope at plaits.scd:191), so LFTri modulation doesn't have time to be audible.

## Solutions Discussed

### 1. Pmono (Monophonic Sequences)
- Use `Pmono` instead of `Pbind` to reuse same synth instance
- Examples found in `plaits_minimal.scd:59` and `engine/_10-sequences.scd:389`
- Keeps synth alive between notes, allowing modulation to be heard

### 2. Legato Overlap
- Use `\legato, 9.1` in patterns to overlap notes significantly
- Prevents synth from being killed between notes
- Example: `plaits_minimal.scd:59`

### 3. Global Modulation Bus (Most Elegant)
```supercollider
// Allocate buses
~timbreBus = Bus.control(s, 1);

// Persistent LFO synth
SynthDef(\globalTimbreLFO, {
    var lfo = LFTri.kr(freq: 0.2, mul: 0.3, add: 0.5);
    Out.kr(~timbreBus, lfo);
}).add;

// In main synthdef, read from bus
var globalTimbreMod = In.kr(~timbreBus, 1);
var finalTimbre = timbre + (timb_mod * (globalTimbreMod - 0.5));
```

## Hardware Reference: Mutable Instruments Plaits
**Timbre Modulation Signal Flow**:
Timbre Knob → Internal Decay Envelope → CV Input → Attenuverter → Final Timbre Value

**Key Insight**: The `- 0.5` converts unipolar (0-1) to bipolar (-0.5 to +0.5) for proper bidirectional modulation around the base parameter value.

**Hardware Examples**:
- Internal envelope only: Attenuverter controls decay envelope modulation depth
- External CV: Attenuverter acts as gain/polarity control for incoming CV
- When CV unplugged with trigger active, reset attenuverter to 12 o'clock to avoid internal envelope

## Current Limitation
MiPlaits UGen may not implement internal decay envelope modulation exactly like hardware. The `timb_mod` parameter might not be wired up the same way, requiring custom envelope implementation:

```supercollider
var trig = Impulse.kr(2);
var decay_env = EnvGen.kr(Env.perc(0.01, 0.5), trig);
var l_timbre = (timbre + (decay_env * timb_mod)).clip(0, 1);
```

## Plaits/Sample Timing Alignment

### Problem
Plaits synth instances and sample instances running in the same `Ppar` can sound out of sync despite firing at the same logical beats.

### Root Causes Found

#### 1. Different default `div` values (pattern-level)
Plaits default `div` is `\hold` (resolves to `0.5` via `~sequenceLibrary`), while samples default `div` is `Pseq([1.0], inf).asStream`. This means `~setDuration.(seqValue, divValue)` produces different step durations even with identical `duration` sequences.

**Fix**: Set an explicit `div` in sample sequences to match the plaits timing, or be aware that omitting `div` gives different defaults per module type.

- Plaits defaults: `lib/globals.scd:117` (`~defaultSequences`)
- Sample defaults: `lib/globals.scd:201` (`~defaultSampleSequences`)

#### 2. Server latency mismatch (audio-level)
The standard `\note` event type (used by plaits `Pbind`) wraps synth creation in `server.makeBundle(server.latency, ...)`, scheduling the OSC message slightly ahead for precise timing. The custom `\oneShotSample` event type was creating synths immediately without latency compensation, causing a ~0.2s offset.

**Fix**: Wrap the `Synth` call in `oneShotSample` with `server.makeBundle(server.latency, ...)` to match the standard event type behavior. See `lib/utils.scd:338`. Committed in `b07883a`.

#### 3. Stream phase offset (live coding)
Sequence streams (`.asStream`) maintain internal position state. Changing a sample's sequence via the UI while the sequencer is running creates a new stream starting at position 0, while other streams are mid-cycle. This causes phase misalignment between modules.

**Fix**: Reload the preset and sequencer together so all streams start from position 0 simultaneously.

### Debugging
Add logging to `\dur` Pfuncs to verify beat alignment:
```supercollider
// In sequencer.scd, plaits dur:
["plaits", i, "event at", thisThread.beats, "dur =", dur].postln;
// In sequencer.scd, sample dur:
["sample", i, "event at", thisThread.beats, "dur =", dur].postln;
// In utils.scd, oneShotSample event type:
["oneShotSample event at", thisThread.beats, "dur =", ~dur].postln;
```

## Sample Library: Nested Directory Support
- `lib/utils.scd:235` recursively loads subfolders as separate banks
- Bank names use `-` separator: `samples/msp/iris/` becomes bank `msp-iris`
- Folder names with hyphens are preserved (no munging)
- Bank names with special characters must use quoted symbol syntax in SC code: `'msp-iris-hits'` not `\msp-iris-hits`
- Preset serialization (`lib/patches.scd`) writes symbols as `'quoted'` to support this
- Existing flat folder banks are unaffected

## Drone Mode
Per-module toggle (`droneMode` scalar). When active, a persistent `\plaitsDrone` synth runs continuously instead of the sequencer creating short-lived synths.

- `\plaitsDrone` SynthDef: `trigger: 1`, `Env.asr` envelope, shares signal chain with `\plaits` via `~plaitsSigChain` builder in `lib/synthdefs.scd`
- `~startDrone.(i)` / `~stopDrone.(i)` in `lib/utils.scd` manage synth lifecycle
- OSC handler in `lib/osc.scd` forwards `.set` to live drone, handles droneMode/mute specially
- Sequencer emits `\type, \rest` for droned instances (Ppar indices preserved)
- Stepped modulation: Pcollect in `lib/sequencer.scd` forwards computed sequence/LFO values to drone each beat
- Play/stop in osc.scd creates/releases drones; preset load respects play state

**SC limitation discovered**: `\type, \set` event only sends default event keys (`freq`, `amp`, `pan`) — custom SynthDef control names are ignored. This is why drone modulation uses explicit `.set` in Pcollect.

## Next Steps
- Implement continuous modulation via control buses (see memory for design notes)
- Compare hardware vs software modulation behavior
