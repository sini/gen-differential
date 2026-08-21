# THE IDENTITY CONTROL PASSES, AND IS DEMONSTRATED ABLE TO FAIL.
#
# ★★★ BOTH HALVES ARE THE ORACLE. A control that has never been shown to fail is indistinguishable
# from `true`, and a control specified as reference-against-reference CANNOT be shown to fail —
# it is `x == x`. That is why the seam is a contract field: the identity arm is the reference's own
# body routed through the CANDIDATE'S substitution mechanism, so perturbing that mechanism moves it.
#
# The seeded perturbations below are permanent suite content, not a one-off demonstration. A guard
# whose teeth are proven once and then removed is a guard whose teeth are a historical claim.
{
  nixpkgsLib,
  nixpkgsSrc,
  genDifferential,
  ...
}:
let
  gd = genDifferential;
  arms = import ./_arms.nix { inherit nixpkgsLib nixpkgsSrc genDifferential; };

  claimsOf =
    which: suite:
    builtins.concatMap (fx: map (p: p.${which}) (builtins.attrValues fx)) (
      builtins.attrValues suite.cells
    );

  # A flat `<fixture>.<projection>` → green reading, which is what makes a seeded partition
  # assertable as a VALUE rather than as a count. A count would hide which cell moved.
  greenMap =
    which: suite: builtins.mapAttrs (_: ps: builtins.mapAttrs (_: a: a.${which}.green) ps) suite.cells;

  # ── THE SEED ─────────────────────────────────────────────────────────────────────────────────
  # A substitution mechanism that DROPS ONE MODULE from every evaluation. It is installed at the
  # same seam, so it reaches the identity arm and nothing else — which is what makes the resulting
  # red attributable rather than merely present.
  #
  # `drop` selects which module goes, and it is a parameter because no single perturbation moves
  # every fixture (see the partition asserted below). A seed hard-coded to one index would have
  # produced a weaker claim and called it a stronger one.
  seededInstall =
    drop: body:
    let
      elib = nixpkgsLib.extend (
        final: prev:
        let
          base = body.overlay final prev;
        in
        {
          modules = base // {
            evalModules = a: base.evalModules (a // { modules = drop a.modules; });
          };
        }
      );
    in
    arms.armOf "SEEDED-${body.name}" elib;

  seededSuite =
    label: drop:
    gd.mkSuite {
      subject = gd.mkSubject {
        inherit (arms.subject) reference candidate claim;
        seam = gd.mkSeam {
          name = "lib-extend-module-body@SEEDED-${label}";
          install = seededInstall drop;
          inherit (arms) referenceBody;
        };
      };
      inherit (arms) fixtures;
    };

  dropLast = ms: nixpkgsLib.take (builtins.length ms - 1) ms;
  # The module at index 2 of a landmine fixture is its WINNING definition.
  dropThird =
    ms:
    if builtins.length ms > 2 then
      nixpkgsLib.take 2 ms ++ builtins.tail (builtins.tail (builtins.tail ms))
    else
      ms;

  lastSeed = seededSuite "drop-last" dropLast;
  thirdSeed = seededSuite "drop-third" dropThird;
in
{
  flake.tests.identity-control = {
    # The control passes: routing the reference's own body through the candidate's seam changes
    # nothing any fixture can see, at any projection.
    test-identity-arm-agrees-with-the-reference-on-every-fixture = {
      expr = builtins.all (c: c.green) (claimsOf "identity" arms.suite);
      expected = true;
    };

    # And it is genuinely evaluating: every identity cell forced both stacks rather than agreeing
    # through a shared refusal.
    test-identity-cells-carry-their-anti-vacuity-key = {
      expr = builtins.all (
        c: if c.comparison == "throws" then c.bothRefused == true else c.bothEvaluated == true
      ) (claimsOf "identity" arms.suite);
      expected = true;
    };

    # ★★ THE SEEDED FAILURE, ASSERTED AS AN EXACT PARTITION RATHER THAN AS "SOMETHING WENT RED".
    # Dropping the last module reddens six of the seven identity cells in the same run in which the
    # unperturbed arm above is green.
    #
    # ★ `priorityFold` SURVIVES IT, AND THAT IS THE FIXTURE BEING CORRECT RATHER THAN THE SEED
    # BEING WEAK. Its last module is a normal-priority ordered definition, and the option is taken
    # outright by a `mkForce` in a higher class — so the dropped definition was already discarded
    # and removing it is invisible at the value projection. A perturbation that a projection cannot
    # see is a real phenomenon, and asserting the partition is what makes it visible here instead
    # of being discovered as a weak guard later.
    test-control-seeded-drop-last-reddens-exactly-this-partition = {
      expr = greenMap "identity" lastSeed;
      expected = {
        artifact.out = false;
        latticeThrows.n = false;
        order.thing = false;
        priorityFold.thing = true;
        synthetic = {
          shape = false;
          things = false;
        };
        valueMeta.thing = false;
      };
    };

    # ★ AND THE ONE SURVIVOR IS REACHABLE, so no cell in this suite is left undemonstrated. Dropping
    # the WINNING definition instead moves it, which is the same fixture answering a perturbation
    # its projection can see.
    test-control-seeded-drop-third-reddens-the-surviving-cell = {
      expr = (greenMap "identity" thirdSeed).priorityFold.thing;
      expected = false;
    };

    # ★★ THE RED IS ATTRIBUTABLE. The same seeded run leaves every CANDIDATE cell green, because the
    # seed is in the seam and the candidate arm is not routed through the seeded one. A control that
    # reddens everything proves only that something broke.
    test-control-seeded-seam-leaves-candidate-cells-green = {
      expr = builtins.all (c: c.green) (claimsOf "candidate" lastSeed);
      expected = true;
    };

    # The suite's own rollup agrees with the cells, so a consumer reading only `green` reads the
    # same fact the cells carry.
    test-control-seeded-suite-is-not-green = {
      expr = lastSeed.green;
      expected = false;
    };

    # The identity arm is NOT the reference arm: it carries the seam's mark, so the two are
    # distinguishable in the output as well as in the construction.
    test-identity-arm-is-not-the-reference-arm = {
      expr = (gd.contract.identityArm arms.subject).name != arms.subject.reference.name;
      expected = true;
    };
  };
}
