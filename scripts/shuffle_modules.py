#!/usr/bin/env python3
"""
Reorder the three PLAITS module slots in a Dreads patch file, keeping each
module's LFO settings with it.

A patch has three plaits slots (0,1,2). Each slot's scalars + sequences live in
its $PLAITS block; its LFO source freq/shape values live in $LFO_SOURCES, keyed
by lfo number. Which lfo index maps to which (slot, param) is read from
~defaultPlaitsLFOMap / ~defaultSampleLFOMap in lib/globals.scd (the single source
of truth), so any layout -- including the non-contiguous AM sources (lfo25+) -- is
handled without positional assumptions. Sample sources and sample blocks are
left untouched.

This moves each slot's scalars, sequences AND lfo values to a new slot together,
so a reorder in the UI/patch stays sonically identical, just re-slotted.

Usage:
    python3 scripts/shuffle_modules.py PATCH.scd [perm]

  perm = comma-separated 3 old-slot indices, one per new slot:
         new_slot_i receives old_slot[perm[i]].
  Default "2,0,1" = the rotation old-p3->p1, old-p1->p2, old-p2->p3.

Examples:
    python3 scripts/shuffle_modules.py patches/.../2a-mod.scd          # 2,0,1
    python3 scripts/shuffle_modules.py patches/.../2a-mod.scd 1,2,0    # other way
    python3 scripts/shuffle_modules.py patches/.../2a-mod.scd 1,0,2    # swap p1<->p2

Writes in place. Prints a summary; re-run is safe (idempotent only if perm is
identity — otherwise each run applies the permutation again, so run once).
"""
import os, re, sys

def rotate_blocks(txt, marker, perm):
    """Rotate the payloads between START/END markers (3 expected) per perm."""
    pat = re.compile(
        r'(// \$PRESET_%s_START\n)(.*?)(\n[ \t]*// \$PRESET_%s_END)' % (marker, marker),
        re.S)
    payloads = [m.group(2) for m in pat.finditer(txt)]
    if len(payloads) != 3:
        raise SystemExit("expected 3 %s blocks, found %d" % (marker, len(payloads)))
    new = [payloads[perm[i]] for i in range(3)]
    it = iter(new)
    return pat.sub(lambda m: m.group(1) + next(it) + m.group(3), txt)


def load_lfo_maps(globals_path):
    """Parse ~defaultPlaitsLFOMap / ~defaultSampleLFOMap from globals.scd — the single
    source of truth for which lfo index drives which (slot, param). Returns
    (plaits, samples): each a list (per slot) of {param: lfo_number}."""
    txt = open(globals_path).read()
    def parse(name):
        m = re.search(r'~%s\s*=\s*\[(.*?)\];' % name, txt, re.S)
        if not m:
            raise SystemExit("could not find ~%s in %s" % (name, globals_path))
        slots = []
        for entry in re.findall(r'\(([^)]*)\)', m.group(1)):
            slots.append({p: int(n) for p, n in re.findall(r'(\w+):\s*\\lfo(\d+)', entry)})
        return slots
    return parse('defaultPlaitsLFOMap'), parse('defaultSampleLFOMap')


def remap_lfo(txt, perm, plaits_map, sample_map):
    """Rewrite $LFO_SOURCES, moving each plaits slot's lfo configs to its new slot.
    Driven from plaits_map (parsed from globals.scd), so any index layout — including
    non-contiguous AM sources (lfo25+) — is handled without positional assumptions."""
    m = re.search(r'~dreads\.lfoSources = \((.*?)\n\);', txt, re.S)
    if not m:
        raise SystemExit("no ~dreads.lfoSources block found")
    entries = {}
    for em in re.finditer(r'lfo(\d+):\s*(\([^)]*\))', m.group(1)):
        entries[int(em.group(1))] = em.group(2)

    plaits_src = {n: (s, p) for s, d in enumerate(plaits_map) for p, n in d.items()}
    sample_src = {n: (s, p) for s, d in enumerate(sample_map) for p, n in d.items()}
    old_to_new = {perm[i]: i for i in range(len(plaits_map))}  # old_slot -> new_slot

    out = {}       # new plaits source number -> value
    others = {}    # samples / unknown, unchanged
    for n, val in entries.items():
        if n in plaits_src:
            old_slot, param = plaits_src[n]
            out[plaits_map[old_to_new[old_slot]][param]] = val
        else:
            others[n] = val

    lines = ["~dreads.lfoSources = ("]
    for slot in range(len(plaits_map)):
        lines.append("\t// plaits %d" % slot)
        for param, n in sorted(plaits_map[slot].items(), key=lambda kv: kv[1]):
            if n in out:
                lines.append("\tlfo%d: %s, // plaits %d %s" % (n, out[n], slot, param))
    if others:
        lines.append("\t// samples / other (unchanged)")
        for n in sorted(others):
            if n in sample_src:
                s, p = sample_src[n]
                lines.append("\tlfo%d: %s, // sample %d %s" % (n, others[n], s, p))
            else:
                lines.append("\tlfo%d: %s," % (n, others[n]))
    lines.append(")")
    return txt[:m.start()] + "\n".join(lines) + txt[m.end() - 1:]  # keep trailing ;


def check_balanced(txt):
    c = "\n".join((l[:l.find("//")] if "//" in l else l) for l in txt.split("\n"))
    c = re.sub(r'"(\\.|[^"\\])*"', " ", c)
    c = re.sub(r"'(\\.|[^'\\])*'", " ", c)
    pairs = {"(": ")", "[": "]", "{": "}"}
    st = []
    for ch in c:
        if ch in "([{":
            st.append(ch)
        elif ch in ")]}":
            if not st or pairs[st.pop()] != ch:
                return False
    return not st


def main():
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    path = sys.argv[1]
    perm = [int(x) for x in (sys.argv[2] if len(sys.argv) > 2 else "2,0,1").split(",")]
    if sorted(perm) != [0, 1, 2]:
        raise SystemExit("perm must be a permutation of 0,1,2 (got %r)" % perm)

    txt = open(path).read()
    txt = rotate_blocks(txt, "SCALARS", perm)
    txt = rotate_blocks(txt, "SEQUENCES", perm)
    globals_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib", "globals.scd")
    plaits_map, sample_map = load_lfo_maps(globals_path)
    txt = remap_lfo(txt, perm, plaits_map, sample_map)

    if not check_balanced(txt):
        raise SystemExit("ABORT: result is not bracket-balanced; not writing")
    # duplicate-key guard
    keys = re.findall(r'\n\s*(lfo\d+):', txt)
    dups = [k for k in set(keys) if keys.count(k) > 1]
    if dups:
        raise SystemExit("ABORT: duplicate lfo keys %r" % dups)

    open(path, "w").write(txt)
    print("shuffled %s with perm new<-old %r (balanced, no dup lfo keys)" % (path, perm))


if __name__ == "__main__":
    main()
