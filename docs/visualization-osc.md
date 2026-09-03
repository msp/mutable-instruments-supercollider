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
  - Each value = `bus_value * modDepth`, range **−0.5 .. +0.5** (signed)

These values are the **LFO contribution alone** (not added to the scalar) — they represent Tier 2 modulation.

### Consuming the bipolar LFO stream in VDMX

VDMX standard slider receivers **will not accept a negative `MIN`** — the field silently snaps back to 0. Feeding `/plaits/<i>/lfo/<param>` directly into an FX slider therefore clips the negative half of the LFO to the slider's floor. Visible symptom: the value "hangs" at the minimum for roughly half each cycle.

Two ways to bridge the mismatch:

1. **Per-receiver "Do Math?" expression** — VDMX slider receivers support a math expression using `$VAL`, `$MIN`, `$MAX` (DDMathParser syntax). Example to remap −0.5..+0.5 into the slider's envelope: `$VAL + 0.5` with "Scale val to fit in envelope" enabled. Downside: needs remembering per mapping, spreads the translation across the project.

2. **Control Surface adapter (recommended)** — a one-time-setup pattern. Build a Control Surface plugin containing one **custom fader per LFO channel** (24 total). Each fader:
   - has `MIN: -0.5, MAX: 0.5` — custom faders *do* accept a negative min
   - has **Publish Normalised** enabled — republishes the fader position as `0.0..1.0` under the fader's name
   - receives its OSC path directly (e.g. fader "plaits0_volume" listens on `/plaits/0/lfo/volume`)

   Downstream FX subscribe to the Publish Normalised value from the adapter fader, not the raw OSC. Range translation lives in one place, the fader labels are self-documenting, and the fader UI (or the Comm Display plugin) gives a live debug view of every LFO channel. Save the Control Surface as a plugin preset for reuse across projects.

The bipolar range is deliberate on Dreads' side — shaders that add the LFO to a base value (`finalTimbre = timbre + LFO * mod`) need a signed input, matching the server-side SynthDef maths. The adapter pattern lets both audiences — shaders that want bipolar, VDMX FX that want unipolar — get what they need without changing the Dreads OSC taxonomy.

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
