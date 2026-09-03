# Spec: LFO any param (list-driven targets, default 1:1, routing opt-in)

**Status: 2026-08-28 — PARTIALLY IMPLEMENTED.** `amRing`/`amDepth`/`amRatio` are now
LFO targets (wired the *dedicated* way, not the list-driven loop this spec describes),
the source pool derives as `~numLFOSources`, `harmLFO` is wired for notes, and the
patch-serialiser + `shuffle_modules.py` are map-driven. Still TODO for the *full*
generalisation below: the synthdef + reporter loop over `~modTargets` so a brand-new
param is truly one list entry (today it still costs synthdef/sequencer/reporter lines). Chosen over per-param dedicated wiring
(the "harmLFO treadmill") and over ripping routing out entirely. Companion to
[`control-api-and-conductor.md`](./control-api-and-conductor.md) (same
single-source-of-truth direction) and the memories `project_modulation_buses`,
`project_lfo_nsource_bluesky` (the full routing matrix — explicitly **deferred**).

Motivation: LFO-ing a param with no LFO input today (`amRing`, `amDepth`,
`amRatio`, later `fmMod`, FX sends…) is a 7-touch-point ritual repeated per param,
and the existing declarative remap (`$PRESET_LFO`) is half-built (only 6 targets;
`harmLFO` wired for drones but not notes). This finishes that feature properly.

## Principles (the decisions)
1. **One list is the source of truth.** `~modTargets` defines every LFO-able param.
   Adding a target = one list entry; synthdef, Pbind, OSC, reporter, and UI all
   derive from it.
2. **Default 1:1, unchanged.** The classic params (`timbre/morph/decay/pitch/volume/
   harm`, sample `rate/volume`) keep their current dedicated source — no routing
   thought day-to-day. Everyday UX is identical to today.
3. **Routing is opt-in.** New targets are *routable* but **default to OFF** (no
   source). You enable one by assigning a spare LFO lane — the opt-in step. Classic
   params never require it.
4. **Source pool stays 24. No growth.** No new `\lfo` synths, so the reporter's fixed
   bus layout, the `$LFO_SOURCES` format, and the shuffle script are untouched. The
   24 lanes are mostly idle in real patches, so there's ample spare to route.

## Current hardcoded spots to collapse onto `~modTargets` (verified refs)
- `~plaitsLFOParams` / `~sampleLFOParams` — `globals.scd:281` (already a list, but only 6).
- `~defaultPlaitsLFOMap` / `~defaultSampleLFOMap` — `globals.scd:287` (param→source).
- **Synthdef** `\plaits` + `\plaitsDrone` — `synthdefs.scd:95,104,131,140`: hardcoded
  `<param>LFO` / `<param>Mod` args + `param + (lfo*mod)` per param.
- **Pbind** — `sequencer.scd:145-149`: wires `timbreLFO..volumeLFO` — **`harmLFO` is
  missing** (the latent inconsistency this fixes for free).
- **Hydration** — `lfo.scd:112-137` (loops `~plaitsLFOParams`; already list-driven).
- **Reporter synth** — `lfo.scd:36-46` (24 fixed bus args) and **reporterFunc** —
  `lfo.scd:202+` (positional `msg` offsets, `bus * <param>Mod`, per-voice mute gate).
- **OSC** — `osc.scd:339` (loops `~plaitsLFOParams`), `osc.scd:711` (pushStateToUI).
- **UI** — LFO-tab visibility list `plaits.json:2916`
  (`['timbre','morph','decay','pitch','volume','harm']`); generic `lfoSend`/
  `lfoPopulate` already build addresses from the param name.

## Design

### `~modTargets` (the list, with metadata)
Per target: `name`, clip `min`/`max`, and how it injects (most feed a MiPlaits arg;
`amRing/amDepth` feed `~plaitsAMStage`; `amRatio` is 0–8). Example:
```
~plaitsModTargets = [
  (name: \timbre, min: 0, max: 1), (name: \morph, min: 0, max: 1),
  (name: \decay, min: 0, max: 1),  (name: \pitch, min: 0, max: 127),
  (name: \volume, min: 0, max: 2), (name: \harm, min: 0, max: 1),
  // new, off by default:
  (name: \amRing, min: 0, max: 1), (name: \amDepth, min: 0, max: 1),
  (name: \amRatio, min: 0, max: 8),
];
```
`~plaitsLFOParams` becomes `~plaitsModTargets.collect(_.name)`.

### Generate, don't hand-wire
- **Synthdef:** declare controls in the body with NamedControls — loop the list:
  `var lfo = (t++"LFO").asSymbol.kr(0); var mod = (t++"Mod").asSymbol.kr(0);`
  and compute `<t>_eff = (<t>_base + lfo*mod).clip(min,max)`. The existing body then
  uses `<t>_eff` at each param's injection point (MiPlaits arg / AM stage). No fixed
  arg list; both `\plaits` and `\plaitsDrone` build from the same loop.
- **Pbind:** generate `\<t>LFO`/`\<t>Mod` keys by looping the list (replaces the 5
  hardcoded lines; `harmLFO` now wired for notes too).
- **OSC / pushStateToUI:** already loop `~plaitsLFOParams` → pick up new targets free.
- **UI gate:** `plaits.json:2916` reads the list instead of a literal array (or we
  regenerate that array from `~plaitsModTargets`) → LFO tab shows for new targets.

### Default map & routing (opt-in)
- `~defaultPlaitsLFOMap`: classic params keep their 1:1 source; **new targets have no
  entry → off.** Hydration resolves "no source" to a null/zeroed LFO (no audio effect,
  `amRingMod` irrelevant until routed).
- **Enable a new target** by assigning a spare lane — two paths, both opt-in:
  - **UI:** a small **source selector** added to the modal LFO tab ("LFO source:
    lfo1–24 / off"). Classic params show their source prefilled (unchanged feel);
    new params show "off" until you pick a spare. This makes routing first-class and
    usable (today it's `$PRESET_LFO`-only, hidden).
  - **Patch:** the existing `$PRESET_LFO` block, now able to name any target
    (`(amRing: \lfo6)`).

### The reporter (the one genuinely fiddly piece — the visual)
`reporterFunc` must become **target-aware** instead of positional-by-classic-param:
for each target, resolve its assigned source (`inst.lfo[target].name` → number N),
read that lane's value from `msg[3 + (N-1)]`, and emit at the target's address scaled
by the target's own depth. Keeps the existing mute gate. Report **mode per target**:
- **swing** `lfo*mod` (≈ ±0.5×depth) — matches the existing LFO→shader convention
  (`project_isf_shaders`), or
- **absolute** `clip(base + lfo*mod, min, max)` — for "where the balance *is*" (amRing
  0=AM,1=RM).
> **Open question (pin per shader):** which mode does your VDMX patch want for amRing?
> Default to *swing* (consistent with existing LFO visuals) unless you need absolute.

## What stays out of scope (deferred)
- Growing the pool past 24 (true 1:1 for *every* param) — needs the reporter/format
  surgery; not required, new targets route into the idle pool instead.
- Full N-source routing matrix / phase-coherence UI (`project_lfo_nsource_bluesky`).
- The broader control-API refactor — related, but this is a self-contained slice.

## Phased build + test (each phase its own commit; studio-time bedding-in)
1. **Establish the list as SoT for the *classic* params.** Generate synthdef/Pbind/
   OSC/UI from `~plaitsModTargets` with the current 6 — **behaviour identical**, and
   `harmLFO` gets wired for notes as a bonus.
   *Test:* load O-SC UI, set an LFO on every classic param (note + drone), confirm
   audio + `/plaits/i/lfo/<param>` visuals unchanged; mute gate still holds.
2. **Add `amRing`/`amDepth`/`amRatio` as targets** (list entries + AM-stage injection).
   Off by default. Assign a spare lane, confirm smooth *audio* AM/RM sweep.
   *Test:* route a slow-sine lane to amRing; audio sweeps continuously (not stepped).
3. **Target-aware reporter + UI source selector.** Shader receives the smooth amRing
   value (mode per the open question); UI can assign/clear a source per param.
   *Test:* mute/unmute freezes correctly; shader movement matches the audio sweep;
   classic params still report as before.

## Payoff recap
Any param becomes LFO-able via a list entry (no treadmill); the half-built remap is
finished and consistent (`harmLFO` fixed); no pool growth / no reporter-format surgery
per param; everyday UX unchanged (1:1 default), routing there when you want it.
