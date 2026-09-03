# Visualisation OSC Architecture

How Dreads pushes per-instance parameter values out to external visual engines (VDMX, TouchDesigner, browser via WebSockets). Captures the current architecture, known gaps, and the design space for improvements.

## Two tiers of modulation

Per-instance parameter values are produced by combining up to two modulation tiers before they reach the synth.

### Tier 1 — Client-side (sclang Pbind, beat-rate)

Runs at sequencer tick rate (typically 1–4 Hz depending on `dur` × `div`). Each FX-related and most tonal params go through a Pfunc in `lib/sequencer.scd` that computes:

```supercollider
~modulateBipolar.(
    seqValue,    // current step of the pattern (or \hold = 0.5 if no pattern set)
    knobValue    // ~dreads.synths[i].<paramKey> — the UI scalar
);
```

Knob acts as a wet/dry blend with the sequence:

- knob `0` → output `0`
- knob `0.5` → output `seqValue`
- knob `1.0` → clipped to max

So in `\hold` mode (default, seqValue = 0.5) the knob behaves as identity. In an active pattern, knob = "amount of pattern applied".

### Tier 2 — Server-side (scsynth SynthDef, audio-control rate ~690 Hz)

Inside the `\plaits` and `\plaitsDrone` synthdefs, certain params combine their scalar input with an LFO bus value:

```supercollider
finalTimbre = (timbre + timbreLFO * timbMod).clip(0, 1);
```

The `timbreLFO` is `.map`'d from a control bus driven by a `\lfo` synth and reported separately via `\lfoReporter` at 60 Hz.

### Which params use which tier

| Param | Tier 1 (client modulation) | Tier 2 (server LFO) | "Truthful" value source |
|-------|---------------------------|---------------------|------------------------|
| `timbre`, `morph`, `decay`, `pitch`, `volume` | yes | yes | scalar **+** LFO contribution |
| `cloudsSend`, `delaySend`, `reverbSend`, `distAmount`, `distDrive` | yes | no | client-modulated scalar only |
| `engine`, `harm`, `lpgColour`, `fmMod` | yes | no | client-modulated scalar only |
| `tempo`, `mute`, `droneMode`, etc. | no (direct UI set) | no | raw UI value |

## Current OSC outbound paths

### From the sequencer (`lib/sequencer.scd`, in Pcollect block, beat-rate)

Three destinations, all fire when `\dur` is not a `Rest` (note: this fires in **drone mode too**, because drone uses `\type, \rest` to skip synth creation but doesn't make `\dur` a Rest):

- `~td.()` — TouchDesigner — `/plaits/state <i> <key1> <val1> ...`
- `~vis.()` — VDMX — `/plaits/<i>/<paramKey>` per value
- `~ws.()` — browser WebSockets — only when `sendToPhones == 1`

Values sent: `pitch`, `engine`, `harm`, `timbre`, `decay`, `morph`, `dur`, `volume`, `cloudsSend`, `delaySend`, `reverbSend`, `distAmount`, plus `note` counter and `tempo`.

These values are **Tier 1 outputs** — the sequencer's Pfunc result, after `~modulateBipolar`.

### From the LFO reporter (`lib/synthdefs.scd`, server-side, 60 Hz)

- `\lfoReporter` SynthDef fires `SendReply.kr(Impulse.kr(60), '/lfoValues', [...])`
- `~lfo.reporterFunc` (`lib/lfo.scd`) relays all LFO source buses to VDMX paths (mute-gated):
  - `/plaits/<i>/lfo/<param>` for `timbre, morph, decay, pitch, volume, harm, amRing, amDepth, amRatio` (9 params × 3 = 27)
  - `/samples/<i>/lfo/<param>` for `rate, volume` (2 × 3 = 6)
  - Each value = `(bus_value * modDepth) + 0.5`, range **0.0 .. 1.0, with 0.5 = rest** (the `emit` helper in `~lfo.reporterFunc` is the one place this encoding lives)

These values are the **LFO contribution alone** (the wobble; *not* added to the scalar base) — they represent Tier 2 modulation. `0.5` = LFO at rest, `<0.5` pushing down, `>0.5` pushing up; the span narrows toward 0.5 as depth drops and never clips.

### Wire convention: offset, encoded 0–1 rest-0.5 (decided 2026-09)

> **What we send is the modulation *offset*, not the absolute parameter value.** It says
> "how far the LFO is pushing this instant", not "where timbre actually is". Encoded 0–1
> with 0.5 = rest (i.e. the bipolar offset `±0.5×depth` shifted by `+0.5`), on **one**
> address per param — no second `lfoU`-style address, no signed values on the wire.

**Why 0–1 rest-0.5, not signed −0.5..+0.5** (the older convention, now retired):
- **VDMX is natively 0–1.** Standard slider receivers won't accept a negative `MIN` (the field snaps to 0), so a signed wire needed a per-slider remap or a Control Surface adapter on *every* mapping — the manual tax. 0–1 rest-0.5 drops straight in, no slider config.
- **A shader recovers the signed offset trivially** with `input - 0.5` (see the migrated display shaders below), so nothing is lost. Bipolar is the more "honest" representation of an offset, but the consumer here is VDMX/visuals, where 0–1 rules.

**Offset vs absolute value — why we send the offset.** Absolute (`base + offset`, e.g. the
real current timbre) would let a visual track knob turns and sequenced steps too, not just
the LFO wobble. We deliberately *don't* send it from the reporter, because:
- the reporter (`\lfoReporter`) only reads the **LFO buses** — it has the offset but not the base;
- the base changes per note for sequenced voices and would need capturing + a per-param range map + clip;
- **you already send the base** on `/plaits/<i>/<param>` (the Tier-1 stream), so any shader that wants absolute can just add the two channels itself. A server-side sum is an optional future convenience (see `TODO.md`).

**Two shader families, one convention.** Shaders split by how they use the value:
- **Modulation displays** (`scope`, `scope_v2`, `pulses`, `pulses_v2`, `phasewheel`, `interference`, `wow`) visualise the *wobble* — they were built with `−0.5..0.5` inputs. **Migrated 2026-09** to `0–1 / DEFAULT 0.5` inputs, each recovering the signed offset internally with `x = input - 0.5` at the point it's first read (testMode branches already synthesised `0.5*sin(…)`, so both paths stay in the same bipolar domain and all downstream maths is unchanged). Geometry inputs like `centreOffset*` stay signed — they're coordinates, not modulation.
- **Value / parameter drivers** (`chromointerference`, `amrm`, `amrm_v2`) feed the value into a `0–1` input directly. Already `0–1 / DEFAULT 0.5`, so **no change** — the new wire is native to them.

Net: every shader now reads `/…/lfo/<param>` as a plain 0–1 input. No negative slider mins, no per-mapping remap, no `lfoU` ambiguity, and new shaders just declare a `0–1` input and subscribe.

## Known gaps and discussion

### Drone-mode UI responsiveness

**Symptom:** in drone mode, dragging an FX-send knob in the O-S-C UI results in a stepped visual response in VDMX (~beat rate, 1–4 Hz) rather than smooth.

**Why:** the only path emitting `/plaits/<i>/delaySend` to VDMX is the sequencer Pcollect block. In drone mode that still fires (events have `\type, \rest` but `\dur` isn't a Rest), but at beat rate. UI knob movements update `~dreads.synths[i].delaySend` immediately but don't push to `~vis`.

**Discussion of options:**

1. **True multicast at O-S-C** (configure UI to send to both SC and VDMX) — zero SC code, smooth, but sends raw knob position. Wrong in pattern mode (where knob is wet/dry blend, not the audible value).
2. **Plain echo in SC OSCdef handler** — same wrongness in pattern mode, slightly more latency than (1).
3. **Echo with recompute in SC** — cache the most recent seqValue per param from the sequencer Pfunc; on UI inbound, recompute `~modulateBipolar` using cached seqValue + new knob, forward to `~vis`. Correct in pattern mode; latency = O-S-C send rate + tiny SC handler overhead. Slight staleness of cached seqValue between sequencer ticks but unnoticeable for slowly-evolving patterns.
4. **Continuous reporter** — sclang `Routine` ticking at 60 Hz, snapshotting `~dreads.synths[i].<param>` values and sending. Smoothest, source-independent (catches sequencer ticks too), but more plumbing and another OSC stream to manage.

Option 3 is correct-by-construction for FX sends (since they only have Tier 1 modulation) but is a band-aid in the broader architecture sense — it spreads responsibility for "what to send to visuals" across both the sequencer and the OSC handler.

Option 4 is the architecturally clean solution: a single reporter responsible for "snapshot the current scalar state and send", decoupled from where the updates come from (UI, sequence, dice, etc.). Closest to the LFO reporter pattern that already exists.

### Final-value tap for tonal params

Today the visual stream for tonal params (`timbre` etc.) is split:
- Tier 1 (client) → sequencer-rate outbound
- Tier 2 (LFO contribution) → 60 Hz LFO reporter

The visual side has to add these together to recover "what the synth is actually playing". In practice this is fine — visualisers either use the LFO bus path (continuous modulation feel) or the sequencer beat path (rhythmic state), rarely both summed.

A unified reporter that taps the **combined final value** inside the SynthDef would centralise this, but only works cleanly for drones (sequencer-triggered synths live too briefly for SendReply to be useful). For mixed-mode patches you'd need a per-instance monitor synth that re-computes the combination from buses + scalars. See `docs/miplaits-modulation.md` for related discussion on the Tier 2 mechanics.

### Sequencer-tick vs continuous question

The fundamental architectural tension:
- **Sequencer-tick outbound** is "ground truth for that beat" — captures fully-modulated values including sequence position. Slow.
- **Continuous outbound** would be "current snapshot at the polling rate" — captures UI movements, but pattern-modulated values are only updated on the actual sequencer tick.

Both have merit. A future-clean design might have both running in parallel: sequencer tick events as "discrete musical state changes", and a continuous low-rate reporter for "live UI state".

## Status

- 2026-05-19: documented; no architectural change made. Drone-mode UI responsiveness improvement deferred (proposed "echo with recompute" patch sketched but not applied).
- The current sequencer-rate outbound is **sufficient for sequencer-mode patches**; the gap is specifically the drone-mode + live-UI-drag combination.

## Related

- `docs/miplaits-modulation.md` — Tier 2 mechanics (LFO bus modulation, why `timb_mod` etc. work the way they do)
- `lib/synthdefs.scd` — `\lfoReporter` SynthDef and per-instance synth args
- `lib/sequencer.scd` — Pbind/Pfunc resolution and per-tick outbound
- `lib/osc.scd` — generic per-instance OSC handler
- `lib/lfo.scd` — `~lfo.reporterFunc` relay logic
