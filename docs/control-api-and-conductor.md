# Dreads Control API & Conductor — design + refactor plan

**Status: 2026-08-20 — design agreed, no code written.** Runway: ~1 month to an
installation, with studio time to bed it in. Supersedes the working name
`osc-api-refactor.md` (never created).

Cousin docs: [`installation-playback.md`](./installation-playback.md) (deterministic
*playback of a captured* run — the opposite of this), [`network-show-control.md`](./network-show-control.md)
(the iPad↔SC rig), [`visualization-osc.md`](./visualization-osc.md) (outbound visual streams).

---

## Why this exists (the reframing)

The install needs a **conductor**: an SC-side timeline that shapes the broad strokes
of a 3-chapter installation (which scene/patch, tempo, chapter transitions, visual +
DMX cues) while Dreads' generative engine plays out, and the iPad stays in hand for
live mix/timbre.

Trying to build that surfaced the real issue: **Dreads has no defined control-API
layer.** Operations on the instrument were only ever written as OSC handlers, because
until now the iPad was the *only* client. The conductor is the **first non-UI client**,
and that's what exposes the gap.

So this is not "extract some functions." It's **"define the instrument's control API,"**
with the conductor as its second consumer. Held that way, the goal is: one core the
iPad, the conductor, and (later) QLab / capture-replay all drive identically.

---

## Part 1 — The control-API refactor

### The smell
Business logic lives inside `OSCdef` closures, so the `~` setters are only half an
API and the *complete* behaviour is trapped in the handler. Setting a param fans out
to model + live synth + UI + visuals — but only via the OSC path. A direct
`~dreads.synths[i].param = x` silently skips the fan-out.

### Audit — trapped vs already-clean (`lib/osc.scd`, line refs as of 2026-08-20, will drift)

**Trapped (logic inline → extract to a function):**

| Handler | Does inline | Proposed function |
|---|---|---|
| plaits per-param `:74-135` | scalar set + forward to live drone + `droneMode` start/stop + `mute`→drone mul + vis echo of FX/AM params | `~setPlaitsParam.(i, key, val)` (pull out `~setMute.(mod,i,on)`, `~setDroneMode.(i,on)`) |
| tempo `:483` (dup at `:84`) | `~tempoClock.tempo` + sync every voice's `.tempo` scalar | `~setTempo.(bpm)` |
| FX delay/reverb/clouds `:382-455` | `~dreads.fx.<u>[p]=v` + `~fx.<u>.set(p,v)`, copy-pasted ×3 | `~setFx.(unit, param, val)` (3 blocks → 1 fn) |
| start/stop `:12-40` | stream-cache clear + drone start/stop + `x.play/stop` + LFO reporter | `~sequencerPlay.()` / `~sequencerStop.()` |
| flushSynths `:550` | `~voiceGroup.freeAll` + clear `~drones` | `~flushSynths.()` |
| loadFolderPatch `:467` | build path from `~currentPatchTemplate.dirname` | `~loadFolderPatch.(name)` |
| samplePath `~:315` | `~lookupSampleByPath` + set bank/variant/duration | `~setSamplePath.(i, path)` |
| nudge (plaits `:179/192`, sample `:243+`) | accumulate `nudgeOffset`+`phaseOffset` | `~nudge.(module, i, dir)` |

**Already clean (adapter → real function, leave as-is):**
`loadPatch`→`~loadPatch` · `save`/`saveAs` · `prev`/`next`→`~loadAdjacentPatch` ·
`reloadPatch` · `fadeOutReverb` · `randomiseAll(+Samples)` · per-param `…/seq`→`~selectSequence` ·
`dice`→`~diceSeq` · `randomise`→`~randomise` · `prev`/`nextVariant`→`~cycleSampleVariant` ·
LFO→`~lfoTweak`/`~setLFOBase` · **sample per-param** (just a scalar set — no drone/vis
fan-out — already equivalent; wrap as `~setSampleParam` only for symmetry).

### Proposed structure
- New **`lib/api.scd`**, loaded at **`dreads.scd:55`** (after `synthdefs`, before `osc`).
  Holds the extracted functions — *these are the API.*
- Every `OSCdef` body collapses to: parse message → call the function. OSC becomes a
  thin adapter. Behaviour stays **byte-identical**.
- Load order is safe because `OSCdef` bodies are closures resolving `~`-names at
  message-time; functions need only exist by first call.
- Debug `postln`s move to the adapter (or a quiet flag) — transport noise, not core.

### Five design commitments (get these right *while* refactoring — cheap now, costly later)

1. **Single write-path per param.** `~setPlaitsParam` is *the* way a voice param
   changes, so all clients fan out identically. **Explicit exception:** `~loadPatch`
   is a *bulk reset* — it rebuilds the model wholesale then re-syncs FX/drones
   separately, and legitimately does **not** go through per-param setters. Document
   that so nobody later "fixes" it.
2. **Tempo is duplicated N+1×** (the clock + every voice's `.tempo` scalar, for
   self-contained patch serialization). `~setTempo` encapsulates the duplication;
   leave a comment flagging it's a smell, not clean.
3. **One visual-output channel.** Visuals currently come from two places — the
   sequencer's per-event bundle *and* the per-param "echo" hack (whose own comment
   calls it a stop-gap). The conductor adds a third author (scene/chapter cues).
   Define a single `~visSend` / `~cue` channel in `api.scd` and route all three
   through it. **This is the one to get right now** — cheap, and matches
   `visualization-osc.md` / `project_visualization_osc`.
4. **Declarative cue model.** A cue = *target state + how to reach it*, so a future
   `xfade`/morph transition type slots in without redesign. Don't bake "load = instant
   cut" into the cue-list's structure.
5. **0-based internal, 1-based only at the OSC edge.** Every handler does `+1`, and
   the vis echo already mixes conventions (flagged in a code comment). Standardise the
   function API on 0-based; the conductor authors cues 0-based; 1-based lives only in
   the OSC path strings.

### Proposed function set (`lib/api.scd`)
```
// --- per-voice control (the single write-path) ---
~setPlaitsParam.(i, key, value)      // state + drone forward + vis echo
~setMute.(module, i, on)             // module: \plaits | \samples
~setDroneMode.(i, on)
~setSampleParam.(i, key, value)      // scalar set (symmetry)
~setSamplePath.(i, path)
~nudge.(module, i, dir)              // dir: +1 / -1
~setLFOControl.(module, i, lfoParam, sub, value)  // optional; ~lfoTweak is core

// --- global ---
~setTempo.(bpm)                      // clock + per-voice scalar sync
~setFx.(unit, param, value)          // unit: \delay | \reverb | \clouds
~sequencerPlay.()  /  ~sequencerStop.()
~flushSynths.()
~loadFolderPatch.(name)              // name within current patch folder

// --- output (decision 3) ---
~visSend.(addr ...values)            // one visual-out channel
~cue.(sceneSymbol)                   // conductor/chapter visual+DMX cue -> ~vdmx
```

### Execution sequencing (one group per commit, UI-wiggle test each)
1. `~setTempo` — lowest risk, proves the pattern.
2. `~setFx` — satisfying 3→1 simplification.
3. transport (`~sequencerPlay/Stop`, `~flushSynths`).
4. `~setPlaitsParam` (+ `~setMute`, `~setDroneMode`) — the big fan-out.
5. sample bits (`~setSampleParam`, `~setSamplePath`, `~nudge`).
6. `~visSend`/`~cue` channel + retire the echo hack onto it.

**Regression test (each commit):** load the O-SC UI; exercise every control + drone
toggle + FX send + start/stop; confirm the iPad *and* visuals still update. Small
commits ⇒ any regression bisects trivially. This is the live control surface — treat
it with that care.

---

## Part 2 — The conductor (`lib/show.scd`)

### Purpose
A wall-clock timeline structuring 3 chapters and the patches within each. Drives
**broad strokes**; the iPad owns **mix/timbre within a scene**; the conductor can
override back on the next cue with **zero special logic** (it just re-sends).

### Decisions (locked in discussion)
- **Clock:** wall-clock *holds* per cue; load immediately (bar-quantised swaps
  *deferred* — bridge/transition patches cover cuts for pass 1).
- **Advance:** auto timer **and** manual advance / hold / jump from the iPad.
- **Transitions:** parked (hard cuts + bridge patches) for pass 1.
- **No auto-`~randomise`** — the conductor sets the scene; Dreads self-evolves.
- **Drives the instrument via the API functions** (post-refactor) — direct,
  synchronous, in-process. The OSC surface still exists for iPad/QLab/capture.
- **VDMX/DMX port: TBC** (whether shaders + DMX both live in VDMX; which OSC port).

### Cue-list schema (declarative — decision 4)
```
~show = [
  (chapter: \emergence, cues: [
     (hold: 240, patch: "00a-intro", tempo: 96,  vdmx: \sceneA),
     (hold: 300, patch: "01a-full",  tempo: 110, vdmx: \sceneA),
  ]),
  (chapter: \density,  cues: [ (hold: 360, patch: "03a-beat", tempo: 130, vdmx: \sceneB), ... ]),
  (chapter: \dissolve, cues: [ ... ]),
];
```
Each cue carries a *target* (patch/tempo/visual) so a future `xfade:` key can add a
transition type without touching the runner.

### Runner
A `Routine` (wall-clock; `SystemClock`, or `~tempoClock` if you want musical holds)
walking `~show`, firing each cue via the API: `~loadFolderPatch`, `~setTempo`,
`~cue.(vdmx)`. Controls, bindable to the iPad (fits the Perf-tab macro area from
`greedy-kindling-teapot.md`):
```
~show.play  /  .pause  /  .next  /  .prev  /  .jump(\density)
```
Installs drift — manual jump/hold is not optional.

### Visual / DMX cueing
A `~vdmx` `NetAddr` (same lazy-init pattern as `~vis`/`~td`/`~ws` in `globals.scd`).
`~cue.(\sceneB)` sends the scene message; DMX looks presumably live in VDMX so one
cue covers shaders + lights. Routed through the single `~visSend` channel (decision 3).

### Why this is a clean architecture demo
One control plane, many drivers — iPad (human), conductor (machine), QLab / capture
(future) — all indistinguishable to the instrument. That's *why* iPad-override /
conductor-override-back needs no logic, and why a whole run is capturable as the same
OSC stream the playback path in `installation-playback.md` would consume.

---

## Part 3 — Deferred architectural inconsistencies (real, but not blocking the install)

Acknowledged and consciously parked past the install; several already have design notes.

- **Three propagation models** — sequenced params *pulled* per-event, drone params
  *pushed* via `.set`, LFOs *bus-mapped* (`.asMap`). Every setter carries an "if
  droned, also push" fork. Unifying (everything through control buses) is the
  `project_modulation_buses` vision — a real rethink, not a month's job. The refactor
  should *encapsulate* the fork cleanly, not remove it.
- **`~dreads` god-object / `~`-namespace** — idiomatic live-coding SC; `api.scd` is a
  mild step toward modules. Leave it.
- **UI-sync logic is spread** across handler echoes + `~pushStateToUI` +
  `~updatePatchUI`. Consolidating into an observer / `ui.scd` is a nice-to-have.
- **A "scene" is a patch snapshot with no interpolation** — the reason transitions got
  parked. Declarative cues (decision 4) keep the door open for future morph/xfade.
- **Tempo stored per-voice** (also decision 2) — global state duplicated for patch
  self-containment.

---

## Open questions / next actions
1. **VDMX**: which OSC port, and does DMX live in VDMX (one cue = shaders + lights)?
2. Confirm **refactor-first** (agreed, given the 1-month runway) vs OSC-for-now fallback.
3. **First code step:** extract `~setTempo` + `~setFx` (lowest risk), each its own
   commit with the UI-wiggle test.
4. Then `~setPlaitsParam` fan-out, then the `~visSend`/`~cue` channel, then `lib/show.scd`.

## Related
- [`lfo-any-param-spec.md`](./lfo-any-param-spec.md) — list-driven LFO targets (any param LFO-able, default 1:1, routing opt-in); same single-source-of-truth direction.
