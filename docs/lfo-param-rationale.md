# Which params should be LFO-able — rationale & parked work

Design notes on the question "should samples expose more LFO-modulatable params
(`startPos`, `decay`, `atk`, …), and if so how?" The short answer landed on **not
yet** — the current set (`rate`, `volume`) is the principled minimum — but the
reasoning matters, and there's a real architecture blocker to clear first. Captured
here so we don't re-derive it.

See also: [`lfo-setup.md`](lfo-setup.md) (how the LFO system works),
[`osc-shared-modals.md`](osc-shared-modals.md) (the modal/cache UI).

## The framework: what an LFO actually buys

An LFO is a continuous control signal. Whether you *hear* it on a param depends on
**two axes**:

1. **How the param is read**
   - *Continuously* during the note — `rate`, `volume` are mapped to the LFO control
     **bus** (`sequencer.scd`, `…lfo.rate.bus.asMap`), so they track the bus every
     control block.
   - *Latched once at trigger* — `startPos` is read once by `PlayBuf` at note start;
     `atk`/`decay` bake the `Env.perc` shape at note start. Later bus movement is ignored.

2. **Voice lifetime**
   - *Long / sustained* → the LFO sweeps **within** the note (vibrato, tremolo, filter
     open).
   - *Short hit* → the LFO barely moves within the note.

### within-note vs across-note

- **within-note** — the value moves *while a single note sounds*; you hear the sweep
  during that note. Requires a continuously-read param **and** a long-enough note.
- **across-note** — each note is ~constant in itself, but *successive* notes land on
  different values (each note samples the LFO at its current phase). The modulation is
  heard as drift *between* hits, not during them.

|  | continuously-read | trigger-latched |
|---|---|---|
| **long / sustained note** | within-note sweep (classic LFO) | across-note (latched per trigger) |
| **short hit** | ≈ across-note drift | across-note wander |

## Applying it to samples

- **Samples span the whole spectrum.** A sample voice's length is `Env.perc(atk, decay)`
  (decay scales ~×2 the step) plus buffer length — so dense fast hits are short (across-
  note only) while sparse/slow steps, long decay, slow rate or long buffers give long
  voices where within-note sweep is fully audible. (Earlier claim that samples are
  "always short" was wrong.)

- **The real divider is *continuous vs latched*, not within/across-note.**
  - `rate`, `volume` (continuous) → an LFO can move them **within** a sustained note.
    **Seq patterns cannot do this** — a seq gives one value per step. This is the genuine,
    structural case for an LFO, and it's exactly why `rate`/`volume` are the current
    `~sampleLFOParams`. Not an accident — the right boundary.
  - `startPos`, `atk`, `decay`, `panDur` (latched) → **one value per note** = a stepped
    sequence of values = **seq territory**. An LFO here samples itself once per note, so
    its "smoothness" is invisible; a seq pattern reproduces the same result.

- **`startPos` is *not* special vs `atk`/`decay`.** All three are latched → across-note →
  seq-reproducible. An earlier pitch ("smooth un-seq-able scrub") was wrong on two counts:
  (a) sampled once per note, the LFO is effectively stepped, and (b) `PlayBuf` latches
  `startPos` at trigger and plays *forward* — it does **not** slide the playhead during the
  note. So a `startPos` LFO = each hit *enters the buffer at a wandering point* (across-
  note), **not** within-note scrubbing. True scrub/granular ("drag the read head during the
  note") needs a different engine — `BufRd`+`Phasor` or `GrainBuf` — see Future fork.

## The two arguments that *do* survive for broadening

Neither makes it a must, but together they're a legitimate "yes, if you value them":

1. **Conceptual consistency / parity.** Plaits can LFO `decay` (`decayMod`); samples can't.
   Someone reaching for "modulate the sample's decay" reasonably expects parity. A
   least-surprise / mental-model argument, independent of audio drama.

2. **Tempo-decoupling (the strong one).** A seq pattern is welded to the step grid — a
   length-N pattern repeats every N steps, bar-aligned. An LFO source runs in real Hz (or
   ×base, independent of the clock), so sampling it once per note gives values that
   **precess against the tempo** — non-repeating, unquantised, floating free of the beat.
   For a drone/evolving aesthetic that "unquantised drift" is a distinct *feel* a grid-
   locked seq can't naturally give. (You can approximate with `Pwhite`/`Pbrown`/
   incommensurate lengths, so not strictly unique — but the LFO is the ergonomic way.)
   This argument applies equally to `startPos`/`atk`/`decay`, so it doesn't single any out.

**Plus — visuals decouple the audio question entirely.** `~lfoReporter` reads the LFO
source **buses continuously** and streams to VDMX, independent of whether any note is
playing or how audio consumes the value. So *any* LFO-bound param is a full, always-live
visual source. If visuals are a first-class driver, that's a standalone reason to LFO more
params — audio audibility becomes a bonus, not the gate. (Though for pure visual sources,
free/unbound LFO sources may be cleaner than bolting them onto audio params.)

## Conclusion: the set

- **Keep `rate`, `volume`** — the only sample params where an LFO does something a seq
  can't (within-note movement). The principled minimum, already shipped.
- **If broadening, add `startPos` + `decay` + `atk` together** — that makes the four big
  sample knobs (`atk`/`decay`/`rate`/`startPos`) all LFO-able plus `volume`, a coherent
  set rather than a grab-bag. Justified by consistency + tempo-decoupling + visual sources,
  **not** by any within-note payoff.
- **Skip `panDur`** (already a pan-sweep param) and **`variant`** (stepped integer, not
  smooth-LFO material; a sample-and-hold "pick a variant" is a different feature).

## The architecture blocker: the source pool is sized to the param count

Adding latched params is only painful because of *how the pool is provisioned*, not
because routing is missing.

- **Routing already decouples source ↔ param.** `instance.lfo` maps param → source symbol,
  default 1:1 (`~defaultPlaitsLFOMap`/`~defaultSampleLFOMap`), patch overrides applied via
  `putAll`, resolved to live sources in `~applyLFOState` (`lfo.scd`). Re-mapping a param to
  a different source in the patch config works today (no UI for it).

- **"Stamp over each other" = shared-source behaviour, not a bug.** Route two params to the
  *same* source and they read the same bus → they modulate in lockstep. And because the
  modal edits *the source the param routes to*, tweaking one param's LFO rewrites the shared
  source → the other param's LFO changes too (and the reflect shows the bleed). So sharing
  couples params; the 1:1 default is what keeps each param independent and the UI coherent.

- **The renumber pain's real cause:** the source *pool* is sized exactly to the 1:1 map
  (pool size now *derives* as `~numLFOSources = ~numPlaits*~plaitsLFOParams.size + ~numSamples*~sampleLFOParams.size`),
  and the **reporter uses hardcoded offsets** into that numbering. New params grow the pool; to
  avoid *renumbering* (which would break existing patches) the AM params were **appended**
  (`amRing/amDepth/amRatio` = `lfo25-33`), so the numbering is non-contiguous — the map, the
  reporter wiring, and `shuffle_modules.py` (now map-driven) are the spots that must know it. Routing can't dodge it — sharing a source onto a new param gives it
  *coupled* modulation (stamping); independent modulation still needs its own source.

- **The pragmatic fix (first slice of the N-source idea):** *stop sizing the pool to the
  param count.* Make `~defaultLFOSources` a fixed generous size (e.g. 48), independent of
  wiring, and make the **reporter iterate the map instead of hardcoded offsets**. Then
  `startPos`/`decay`/`atk` — and any future param — get a spare source number via a one-line
  map entry, **no renumber**, and the existing re-mapping finally has spare sources to route
  *to*. This is the pragmatic precursor to a full routing-matrix UX; see
  [[project_lfo_nsource_bluesky]].

## Decision / status — PARKED

Not building now. When picked up, the order is:
1. **Decouple the source pool** from the param count + make the reporter map-driven (the
   blocker above). Do this first; it de-risks the add and makes it — and everything after —
   cheap.
2. **Then add `startPos` + `decay` + `atk`** as destinations: synthdef `*LFO`/`*Mod` args +
   `final*` lines, sequencer `.map`s, default-map entries, LFO-tab visibility list, and swap
   the three base knobs to `large_knob_lfo`.

## Future fork: a granular voice

True within-note scrubbing (drag the read head *during* the note) is a **different engine** —
`PlayBuf` → `BufRd`+`Phasor` or `GrainBuf`, as a separate sample voice type. It's a real
project and a classic rabbit hole; deferred deliberately. The current `PlayBuf` rig gets
"granular enough" for many textures via fast retrigger + `startPos` jitter + short `decay` +
`rate` spread + overlap. `GrainBuf` is a fairly cheap drop-in *if/when* the real thing is
wanted — a clean future fork, nothing to pre-empt.
