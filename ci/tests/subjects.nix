# TWO OR MORE DISTINCT SUBJECTS.
#
# ★★ THE DEFECT THIS GUARDS IS THE ONE THIS LIBRARY EXISTS TO REMOVE, REPRODUCED ONE LEVEL DOWN. A
# harness parameterized against exactly one substrate is indistinguishable from one hard-coded to
# it. So is a suite carrying exactly one subject — and so is a suite carrying two whose seams are
# the same value, because that is one instantiation counted twice.
#
# What a failing run looks like, stated before the run: one subject in the roster, or two sharing a
# seam name.
{
  nixpkgsLib,
  nixpkgsSrc,
  genMerge,
  genDifferential,
  ...
}:
let
  gd = genDifferential;
  arms = import ./_arms.nix { inherit nixpkgsLib nixpkgsSrc genDifferential; };
  consumer = import ./_consumer.nix { inherit nixpkgsLib genMerge genDifferential; };

  # THE ROSTER. Two genuinely different instantiations, not one subject and a filler: a re-host of
  # the reference's own module body through a fixpoint extension, and a from-scratch merge engine
  # behind a surface adapter. Different candidates, different seams, different claims.
  roster = [
    arms.subject
    consumer.subject
  ];

  verdict = gd.oracles.distinctSubjects roster;
in
{
  flake.tests.subjects = {
    test-roster-carries-two-or-more-distinct-subjects = {
      expr = verdict.ok;
      expected = true;
    };

    # The seams are named, and the names are what the guard reads — so a reader can see the two
    # instantiations are different without re-deriving it from the candidates.
    test-the-two-seams-are-named-and-different = {
      expr = verdict.seams;
      expected = [
        "lib-extend-module-body"
        "module-system-surface"
      ];
    };

    test-each-subject-names-its-own-claim = {
      expr = builtins.length (
        builtins.attrNames (
          builtins.listToAttrs (
            map (p: {
              name = p;
              value = true;
            }) verdict.claims
          )
        )
      );
      expected = 2;
    };

    # ── THE SEEDED FAILURES ──────────────────────────────────────────────────────────────────
    # ★ A ONE-SUBJECT ROSTER IS THE DEFECT ITSELF, and the guard refuses it.
    test-control-a-single-subject-roster-fails-the-guard = {
      expr = (gd.oracles.distinctSubjects [ arms.subject ]).ok;
      expected = false;
    };

    # ★★ AND SO IS A TWO-SUBJECT ROSTER WITH ONE SEAM. This is the harder half: the roster LOOKS
    # plural — two subjects, two claims, two candidates — and is singular in the fact, which
    # is exactly the shape of the defect being guarded. Counting subjects would pass it.
    test-control-two-subjects-sharing-a-seam-fail-the-guard = {
      expr =
        (gd.oracles.distinctSubjects [
          arms.subject
          (gd.mkSubject {
            inherit (arms.subject) reference seam;
            candidate = consumer.subject.candidate;
            claim = "a different claim over the same substitution point";
          })
        ]).ok;
      expected = false;
    };

    # LIVE CONTROL, same instrument and same run: the counter itself is not stuck. Without it the
    # two cells above are satisfied by a guard that refuses every roster.
    test-control-the-guard-counts-what-it-is-given = {
      expr = verdict.count;
      expected = 2;
    };
  };
}
