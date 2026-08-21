# THE ORACLES — the anti-vacuity machinery, shipped as library surface rather than as this
# repository's private test helpers.
#
# ★★ A HARNESS THAT CANNOT BE SHOWN TO FAIL IS INDISTINGUISHABLE FROM `true`. Every function here
# exists because some green is reachable without asserting anything, and each names the specific
# way. They ship on the public surface because a CONSUMER's suite is where the vacuity will
# actually appear: a library that keeps its own teeth private hands out the harness and keeps the
# reason it is trustworthy.
{ compare, diff }:
let
  refuse = what: why: throw "gen-differential: ${what} — ${why}";

  # ── THE COVERAGE FLOOR ───────────────────────────────────────────────────────────────────────
  #
  # ★ THREE OF FOUR. The instrument this library replaces held its coverage as four gate keys. The
  # fourth — that a REAL, domain-shaped tree flattens identically through both grammars — is not
  # met here and is not weakened: it is a property of a domain suite, and this library's fixtures
  # are synthetic and pure by ruling. A green here does NOT discharge that fourth key; it is met
  # when an instantiation with a real suite supplies it. Naming the three rather than calling the
  # floor complete is the difference between a deferral and a silent shortfall.
  floorKeys = [
    "all-identical"
    "both-evaluated"
    "teeth-mutation-diverges"
  ];

  floor =
    { suite, teeth }:
    let
      anti = c: if c.comparison == "throws" then c.bothRefused == true else c.bothEvaluated == true;
      keys = {
        # Every cell's observable agrees with its reference, or diverges exactly as ruled.
        "all-identical" = builtins.all (c: c.unregistered == [ ] && c.missing == [ ]) suite.allClaims;
        # THE ANTI-VACUITY KEY: both stacks genuinely produced something. Two arms that agree
        # through a shared refusal have not been shown to agree about anything else.
        "both-evaluated" = suite.allClaims != [ ] && builtins.all anti suite.allClaims;
        # THE TEETH: perturbing an input moves the compared observable. Without it a comparison can
        # be measuring a constant.
        "teeth-mutation-diverges" = teeth;
      };
    in
    keys
    // {
      met = builtins.all (k: keys.${k} == true) floorKeys;
    };

  # ── THE TEETH ────────────────────────────────────────────────────────────────────────────────
  #
  # Perturb the fixture, evaluate through ONE arm, and require the compared observable to move. The
  # probe reading is used rather than the parity walk, because the question is "did this change?"
  # and two refusals are an unchanged answer to it — where for a parity question they are not an
  # answer at all.
  mutationTeeth =
    {
      arm,
      fixture,
      observableName,
      perturb,
    }:
    if !(builtins.isFunction perturb) then
      refuse "teeth.perturb" "the teeth perturb a fixture, so `perturb` maps a fixture to a fixture"
    else
      let
        observable = fixture.observables.${observableName};
        base = observable (compare.run arm fixture);
        mutated = observable (compare.run arm (perturb fixture));
      in
      {
        inherit observableName;
        arm = arm.name;
        moved = !(diff.probeEq base mutated);
        baseReading = diff.probe base;
        mutatedReading = diff.probe mutated;
      };

  # ── EVERY DECLARED INPUT HAS A CONSUMING CELL ────────────────────────────────────────────────
  #
  # ★ A DISTINCT VACUITY FROM THE FLOOR'S ANTI-VACUITY KEY, WHICH IS WHY THE FLOOR DOES NOT ALREADY
  # COVER IT. `both-evaluated` catches two arms agreeing through a shared refusal. This catches a
  # declared input NO CELL READS AT ALL — a suite can pass every anti-vacuity key while every
  # fixture ignores the corpus it declares. Measured in a frozen apparatus in this project: a
  # corpus was passed into `specialArgs` and zero tests consumed it, so a full green was a genuine
  # no-regression signal for the harness and said nothing whatever about the corpus.
  #
  # The demonstration is by PERTURBATION rather than by a reachability reading: an input is consumed
  # when moving it moves a cell. A syntactic "is it mentioned" check would pass for a mention that
  # nothing forces.
  inputConsumption =
    {
      inputs,
      perturb,
      cells,
    }:
    if !(builtins.isAttrs inputs) || inputs == { } then
      refuse "inputConsumption.inputs" "there is nothing to demonstrate consumption of"
    else
      let
        readings = c: builtins.mapAttrs (_: diff.probe) c;
        baseline = readings (cells inputs);
        check =
          name:
          let
            alt = readings (cells (inputs // { ${name} = perturb name inputs.${name}; }));
            names = builtins.attrNames (baseline // alt);
            movedCells = builtins.filter (
              k: !((baseline ? ${k}) && (alt ? ${k}) && baseline.${k} == alt.${k})
            ) names;
          in
          {
            inherit name;
            moved = movedCells;
            consumed = movedCells != [ ];
          };
        perInput = map check (builtins.attrNames inputs);
      in
      {
        inherit perInput;
        consumed = map (r: r.name) (builtins.filter (r: r.consumed) perInput);
        unconsumed = map (r: r.name) (builtins.filter (r: !r.consumed) perInput);
        total = builtins.all (r: r.consumed) perInput;
      };

  # ── TWO OR MORE DISTINCT SUBJECTS ────────────────────────────────────────────────────────────
  #
  # ★ THE DEFECT THIS GUARDS IS THE ONE THIS LIBRARY EXISTS TO FIX, ONE LEVEL DOWN. A harness
  # parameterized against exactly one substrate is indistinguishable from one hard-coded to it —
  # and so is a suite carrying exactly one subject, or two whose seams are the same. The seam is
  # the field that decides it, which is why it carries a name: two subjects sharing a seam name are
  # one instantiation counted twice.
  distinctSubjects =
    subjects:
    let
      seams = map (s: s.seam.name) subjects;
      unique = builtins.attrNames (
        builtins.listToAttrs (
          map (n: {
            name = n;
            value = true;
          }) seams
        )
      );
      count = builtins.length subjects;
    in
    {
      inherit count seams;
      distinctSeams = builtins.length unique;
      claims = map (s: s.claim) subjects;
      ok = count >= 2 && builtins.length unique == count;
    };

  # ── A RED NAMES ITS CONJUNCT ─────────────────────────────────────────────────────────────────
  #
  # The readable form of a claim, taken from the claim ALONE. The discharge test for the separability
  # obligation is that two reds seeded on opposite sides are distinguishable from this output — not
  # by an operator who already knows which was seeded.
  explain =
    c:
    "${
      if c.green then "green" else "RED"
    }: ${c.claim} | arms ${c.arms} (${c.referenceArm} vs ${c.candidateArm}) | ${c.comparison}/${c.assertion} at observable ${c.observableName}"
    + (if c.rung == null then "" else " | rung ${builtins.toString c.rung}")
    + (
      if c.firstDivergence == null then
        ""
      else
        " | first divergence at ${diff.showPath c.firstDivergence.path}: reference=${builtins.toJSON c.firstDivergence.aValue} candidate=${builtins.toJSON c.firstDivergence.bValue}"
    )
    + (
      if c.missing == [ ] then
        ""
      else
        " | ${builtins.toString (builtins.length c.missing)} register entries UNSATISFIED"
    );
in
{
  inherit
    floorKeys
    floor
    mutationTeeth
    inputConsumption
    distinctSubjects
    explain
    ;
}
