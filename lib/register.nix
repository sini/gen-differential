# THE DIVERGENCE REGISTER — a ruled difference is a NAMED DIVERGENCE, not a red.
#
# McKeeman names this problem as differential testing's second issue: "The results of two tested
# programs may differ and yet still be correct, depending on the requirements" (1998, DTJ 10(1),
# printed 101). His example is a C compiler's freedom among implementation-defined constructs; the
# case here is a deliberate, ruled change to the grammar the two arms share.
#
# ★★ AN ENTRY IS AN ASSERTION, NOT A MUTE, AND THAT IS THE WHOLE DESIGN. An entry states that a
# named divergence OCCURS. If it stops occurring, or occurs differently, the entry goes RED — so the
# register cannot decay into a suppression list, which is the shape a parity harness reaches for
# when it is tired. Three outcomes come back from every application and all three are assertable:
# divergences no entry covers (the ordinary red), entries no divergence satisfied (the register has
# gone stale), and the matched pairs.
#
# ★ EVERY ENTRY CARRIES ITS RULING. A divergence without an authorization is a bug someone has
# grown used to; requiring the field is what keeps the two apart.
#
# Dependency-free.
let
  refuse = what: why: throw "gen-differential: ${what} — ${why}";
  isNonEmptyString = v: builtins.isString v && v != "";

  # The DIVERGENCE side of the vocabulary is the value machinery's (`a`/`b`, which know nothing
  # about which side is which); the REGISTER side is the contract's (`reference`/`candidate`). The
  # mapping is fixed here and stated once: a ↦ reference, b ↦ candidate. Every comparison in this
  # library builds its diff with the reference as `a`, so the mapping holds by construction rather
  # than by each caller remembering it.
  matches =
    entry: divergence:
    divergence.path == entry.path
    && (
      entry.values == null
      || (divergence.aValue == entry.values.reference && divergence.bValue == entry.values.candidate)
    );

  # A fully pinned entry: the coordinate AND both expected values.
  mkEntry =
    {
      path,
      values,
      ruling,
    }:
    if !(builtins.isList path) then
      refuse "register.path" "a divergence coordinate is a list of attribute names and list indices"
    else if !(builtins.isAttrs values) || !(values ? reference) || !(values ? candidate) then
      refuse "register.values" "a pinned entry states both sides; use `mkCoordinateEntry` when a side is genuinely unpinnable"
    else if !(isNonEmptyString ruling) then
      refuse "register.ruling" "an entry authorizes a divergence, so it carries the ruling that authorized it"
    else
      {
        inherit path values ruling;
        valuesUnpinned = null;
      };

  # ★ THE DECLARED WEAKENING, AND IT IS DECLARED PER ENTRY RATHER THAN AVAILABLE BY DEFAULT. A
  # coordinate-only entry registers any divergence at ONE path. It keeps both teeth — it still goes
  # red if the divergence stops occurring, and it still covers exactly one coordinate, so it cannot
  # suppress a class — but it does not pin what the two sides produce. The reason has to be written
  # down at the entry, because a weakening nobody has to justify is one everybody takes.
  mkCoordinateEntry =
    {
      path,
      ruling,
      valuesUnpinned,
    }:
    if !(builtins.isList path) then
      refuse "register.path" "a divergence coordinate is a list of attribute names and list indices"
    else if !(isNonEmptyString ruling) then
      refuse "register.ruling" "an entry authorizes a divergence, so it carries the ruling that authorized it"
    else if !(isNonEmptyString valuesUnpinned) then
      refuse "register.valuesUnpinned" "a coordinate-only entry states why its values are not pinned; an unexplained weakening is a mute"
    else
      {
        inherit path ruling valuesUnpinned;
        values = null;
      };

  # A ruled RENAME is one ruling and two coordinates. The reference's tree carries the old key and
  # not the new; the candidate's carries the new and not the old — so the structural walk reports a
  # presence change at each of the two paths, never a single value divergence. The moved value
  # itself belongs to the grammar rather than to the register, which is why these two come back
  # coordinate-only with that as their stated ground.
  mkRename =
    {
      from,
      to,
      ruling,
    }:
    let
      ground =
        p:
        "a ruled rename diverges by PRESENCE at ${p}; the moved value is the grammar's to state, not this entry's";
    in
    [
      (mkCoordinateEntry {
        path = from;
        inherit ruling;
        valuesUnpinned = ground "the retired coordinate";
      })
      (mkCoordinateEntry {
        path = to;
        inherit ruling;
        valuesUnpinned = ground "the adopted coordinate";
      })
    ];

  # Apply a register to a divergence set. Total: every divergence lands in exactly one of
  # `registered` / `unregistered`, and every entry is either satisfied or `missing`.
  apply =
    { register, divergences }:
    let
      covered = d: builtins.any (e: matches e d) register;
      satisfied = e: builtins.any (d: matches e d) divergences;
    in
    rec {
      registered = builtins.filter covered divergences;
      unregistered = builtins.filter (d: !(covered d)) divergences;
      missing = builtins.filter (e: !(satisfied e)) register;
      # The register's verdict, and it takes BOTH halves. An empty `unregistered` alone is the
      # suppression-list reading.
      discharged = unregistered == [ ] && missing == [ ];
    };

  # ── THE SEEDED ENTRIES ───────────────────────────────────────────────────────────────────────
  # The two ruled divergences the retirement diagnosis supplies, carried as DATA with their
  # rulings. They are the register's first content and the shape every later entry is written
  # against.
  #
  # ★ THEY ARE NOT ASSERTED BY THIS LIBRARY'S OWN SUITE, AND SAYING SO IS THE POINT. Both name
  # coordinates in a grammar that does not ship here — this library's fixtures are synthetic and
  # pure — so there is no subject to assert them against yet. They travel to the instantiation that
  # has one. Asserting them here would require inventing the grammar they diverge in, which is the
  # opposite of a register entry.
  retirement =
    mkRename {
      from = [
        "cnf"
        "classes"
      ];
      to = [
        "cnf"
        "keySemantics"
      ];
      ruling = "gen-aspects 9a855c9, 2026-07-15 — the key-semantics rename; the retirement diagnosis records it as a deliberate grammar change, not a defect";
    }
    ++ [
      (mkCoordinateEntry {
        path = [
          "flat"
          "web/nested"
          "key"
        ];
        ruling = "owner ruling 2026-07-13 — A-IDENT's container-relative path identity (d699c4b → c019c15); the diagnosis isolates the residue to this single cell";
        valuesUnpinned = "the specification of record isolates the residue to this coordinate but does not carry the two identities; pinning invented strings here would assert something no primary states";
      })
    ];
in
{
  inherit
    matches
    mkEntry
    mkCoordinateEntry
    mkRename
    apply
    retirement
    ;
}
