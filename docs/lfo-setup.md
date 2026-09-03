# LFO setup

How LFO modulation is wired, changed, and persisted. The key thing to hold onto:
**the livecoding API and the preset blocks act on the *same* runtime source
objects** — one mutates them now, the other saves/restores them.

> **Design rationale** for *which* params should be LFO-able (and the parked
> source-pool refactor needed before broadening the sample set) lives in
> [`lfo-param-rationale.md`](lfo-param-rationale.md).

## Runtime model

- **21 named sources** `\lfo1`–`\lfo21`, each a running `\lfo` synth writing to a
  control bus (`~lfo.sources`, built in `lib/lfo.scd`). A param's modulation = its
  source's bus value, scaled by the param's `*Mod` depth.
- **Source ownership** (`~defaultLFOSources`, `lib/globals.scd`) — all default to
  `(freq: 0.125, shape: 0, width: 0.3, base: false)`. Numbering:
  - `lfo1-5` plaits 0 (timbre, morph, decay, pitch, volume), `lfo6-10` plaits 1,
    `lfo11-15` plaits 2
  - `lfo16-17` samples 0 (rate, volume), `lfo18-19` samples 1, `lfo20-21` samples 2
- **Routing** — `instance.lfo` maps param → source symbol (e.g. `timbre: \lfo1`),
  **1:1 by default** (`~defaultPlaitsLFOMap` / `~defaultSampleLFOMap`,
  `lib/globals.scd`). Sources *can* be shared (routing matrix is future work).
- **Shapes** (`~lfoShapeMap`, `lib/lfo.scd:160`): `sine`=0, `tri`=1, `saw`=2,
  `square`=3, `noise`=4, `gaussian`=5.
  - `noise` = `LFNoise1` — *smoothed random* (linear interp), the Perlin-ish "random
    with an overall shape" one.
  - `gaussian` = `LFGauss` — **not** random. A periodic **bell-shaped swell**, one per
    cycle (period = `1/freq`). Its `width` control (only shown for this shape) sets the
    bell's narrowness: narrow = a brief spike with gaps, wide = a smooth sine-like swell.
    Musically it's only interesting **slow** — at higher freqs the bells blur into a
    buzzy pulse.
- **Mod depth** is *not* on the source — it's the per-instance `*Mod` scalar
  (`timbre`→`timbMod`, others `<param>Mod`), stored in `$PRESET_SCALARS` and already
  a UI knob. The reporter relays live LFO values to VDMX scaled by `*Mod`
  (`~lfo.reporterFunc`, `lib/lfo.scd:202`).

## Two ways to change an LFO

### 1. Livecoding API — imperative, transient
`~lfoTweak` (`lib/lfo.scd:162`) mutates the live source (freq/shape/width on the
synth) and, for `mod`, writes the `*Mod` scalar + forwards to any live drone:

```supercollider
~lfoTweak.(\plaits, 0, \pitch, \freq, 0.3);              // single param
~lfoTweak.(\plaits, 0, \volume, (freq: 0.2, shape: \sine, mod: 0.0));  // multi
```

These changes are **not persisted** — they live only in the source objects until
you save the patch. Livecode overrides whatever the preset loaded, and is lost on
reload.

### 2. Preset blocks — declarative, persisted
A patch stores LFO state in **two** places (they separate routing from values):

- **`$PRESET_LFO`** — inside each instance's factory call: the **routing** map
  (param → source), i.e. `lfoMapOverrides`.
- **`$LFO_SOURCES`** — once, globally: the **per-source values**:
  ```supercollider
  ~dreads.lfoSources = (
      lfo1: (freq: 0.2),      // plaits 0 timbre
      lfo2: (freq: 0.2667),   // plaits 0 morph
      ...
  );
  ```

  Entries may also carry `shape`, `width` and `base` (all diffed against default).
  The global `~base` is written here too (`~base = …;`) when non-default.

`mod` is **not** here — it rides along in `$PRESET_SCALARS` as the `*Mod` scalar.

## Save / load round-trip

- **Save** (`lib/patches.scd:739`): walk all 21 sources, **diff each against
  `~defaultLFOSources`**, and emit only the changed params to `$LFO_SOURCES` (with a
  `// usage` comment). So a patch only records LFOs that differ from default.
- **Load / re-eval** (`~applyLFOState`, `lib/lfo.scd:84`, called from
  `~applyPatch`): **reset every source to defaults**, then apply the
  `~dreads.lfoSources` overrides onto the live sources + synths. Routing is hydrated
  separately from `instance.lfo`.

That reset-then-apply is why the preset structure exists: livecode tweaks are
ephemeral mutations of the source objects; the preset is the serialised snapshot
that recreates them on load. Same objects, different lifecycle.

## Base frequency (×base mode)

A source's `freq` can be **absolute Hz** or a **multiple of a global `~base`**:

- **`~base`** (`lib/globals.scd`, default `0.125`) — global base frequency.
- Each source stores an authored `freq` + a `base` bool. `~resolveLFOFreq` (`lib/lfo.scd`)
  computes the actual synth freq: `base ? freq * ~base : freq`. The **authored** value
  is what's stored/serialised; the resolved Hz is what the synth runs at.
- `~setLFOBase.(v)` sets `~base` and re-resolves every base-locked source.
- **Toggling `base` off reinterprets the same number as Hz** (chosen behaviour): e.g.
  `freq 4` at `~base 0.5` runs at 2 Hz; flick base off → 4 Hz (the number stays, the
  speed jumps). It does *not* rewrite `freq` to keep the speed continuous.
- Persistence: `base` is diffed into each `$LFO_SOURCES` entry; `~base` is written
  globally when non-default.

## OSC API

`n` = **1-based** instance. Handlers registered in `~setupLFOOSC` (`lib/osc.scd`);
`~pushStateToUI` reflects the same addresses back to the UI.

| Address | Value | Effect |
|---|---|---|
| `/{plaits\|samples}/{n}/lfo/{param}/freq` | float | authored freq (Hz or ×base multiplier) |
| `/{plaits\|samples}/{n}/lfo/{param}/shape` | shape name | `sine`/`tri`/… |
| `/{plaits\|samples}/{n}/lfo/{param}/base` | `1`/`0` | ×base on/off (OSC has no bool) |
| `/{plaits\|samples}/{n}/{param}Mod` | float | mod depth — **existing scalar**, `timbre`→`timbMod` |
| `/dreads/lfoBase` | float | global `~base` |

`param` ∈ `timbre/morph/decay/pitch/volume` (plaits), `rate/volume` (samples). Note the
numbering split: OSC is 1-based, `~lfoTweak` is 0-based (the handlers convert).

## UI: LFO controls tab

The seq modal (`seqModalPanel`) has two tabs: **seq** and **lfo**. The LFO tab holds a
shape `switch`, freq `knob`, ×base `toggle`, mod `knob` — one shared set that retargets
based on `seqModal/context` (`{param, instance, stateId, type}`), the same way the seq
switch works.

### Client-side cache (why there's no server ping)

Reflecting the *current* values when the modal opens must be **synchronous**, or
switching params fast races: an async server reply can land after the context has moved
on, showing — and even writing — the wrong param's values.

So we mirror the seq pattern: a **client-side cache**. Each fragment-backed knob carries
**5 hidden widgets** (`freq`/`shape`/`base`/`mod`/`width`). The cache is updated at **two
moments** — a bare `send` does *not* touch local widgets: (1) SC's `~pushStateToUI` on load,
(2) `window.lfoSend` writing it on each edit. On open, `window.lfoPopulate` reads them with
`get()` and populates the tab **synchronously** under a `window._initializingLfo` guard
(checked inside `lfoSend`) so the populate doesn't echo out. Each widget's `onValue` is a
one-liner: `lfoSend(sub, value)`. Full detail in `docs/osc-shared-modals.md`.

- **Widget ids:** freq/shape/base/width use `lfoState_{module}_{param}_{sub}_{instance}`. The
  **mod** cache is different — its id *is* the `*Mod` scalar address (minus slash, e.g.
  `plaits/1/timbMod`), making it an **id-twin** of the dedicated mod knob so O-S-C keeps the
  two in sync for free (see Override 4 in `docs/osc-shared-modals.md`, commit `1a235f2`).
- **No ping, no race** — same lifecycle as the seq switch's hidden `…Label_seq_…` cache.
- **Coverage:** all plaits/sample knobs are fragments now, so reflect works across the board.

### Tab visibility

The **lfo tab's `visible`** is **module-aware**: it branches on `@{seqModal/context}.type` —
samples see `['rate','volume']`, plaits see `['timbre','morph','decay','pitch','volume','harm','amRing','amDepth','amRatio']`
(these must stay in sync with `~plaitsLFOParams`/`~sampleLFOParams`). It hides itself for
non-LFO params and for sample `decay`. `openSeqModal` also forces the seq tab active
(`set('seqModalPanel', 0)`) so you're never stranded on a hidden tab.

## Status

All shipped: base-frequency mode + OSC wiring (`1b6acc0`, `e51bcfe`), the UI tab +
client-side cache + `lfoSend`/`lfoPopulate`, `harm` in the LFO set, module-aware
tab visibility (`8876587`), and dedicated-mod-knob sync via id-twin caches (`1a235f2`).
AM params (`amRing`/`amDepth`/`amRatio`) added as LFO targets; source pool now derives
as `~numLFOSources` (currently 33), AM sources appended at `lfo25-33`, `harmLFO` wired
for sequenced notes, and patch-serialisation + shuffle-script made map-driven.
