# A RED NAMES ITS CONJUNCT.
#
# ★★★ THIS IS THE DEFECT THAT KILLED THE PREDECESSOR APPARATUS, DISCHARGED STRUCTURALLY. That
# instrument silently asserted a CONJUNCTION — that the re-host computes what the reference
# computes, AND that the published grammar had not moved — with its reference side frozen so it
# could never follow. It went red on every deliberate grammar change and could not say which
# conjunct a red belonged to, so every red had to be adjudicated by hand and eventually none were.
#
# The discharge test: seed a divergence attributable to the REFERENCE side and one attributable to
# the CANDIDATE side, and show the two reds are distinguishable FROM THE FAILURE OUTPUT ALONE — not
# by an operator who already knows which was seeded.
#
# ★★ AND THE STRUCTURAL ANSWER IS SHARPER THAN THE OUTPUT STRINGS: THE IDENTITY CELL'S STATE NAMES
# THE CONJUNCT. A candidate-side divergence leaves the identity cell GREEN, because the reference
# and its own body through the seam still agree. A reference-side divergence reddens the identity
# cell too, because the reference itself moved. One bit, read off a cell that is already in the
# suite, tells a reader which side to look at before they read a single value.
{
  nixpkgsLib,
  nixpkgsSrc,
  genDifferential,
  ...
}:
let
  gd = genDifferential;
  arms = import ./_arms.nix { inherit nixpkgsLib nixpkgsSrc genDifferential; };

  # An arm that evaluates the fixture with one extra definition appended. Whichever side it is
  # installed on is the side that moved.
  armWith =
    name: extra:
    gd.mkArm {
      inherit name;
      vocab = arms.vocabOf nixpkgsLib;
      eval = request: nixpkgsLib.evalModules (request // { modules = request.modules ++ extra; });
    };

  drifted = armWith "drifted" [ { config.thing = [ 9 ]; } ];

  fixtures.valueMeta = arms.entry "valueMeta" { };

  # P1 — the CANDIDATE moved. The reference is untouched.
  candidateSeeded = gd.mkSuite {
    subject = gd.mkSubject {
      inherit (arms) reference seam;
      candidate = drifted;
      proposition = "P1 · the design under test computes what the reference computes";
    };
    inherit fixtures;
  };

  # P2 — the REFERENCE moved. The candidate is the one the unseeded suite uses.
  referenceSeeded = gd.mkSuite {
    subject = gd.mkSubject {
      inherit (arms) seam;
      reference = drifted;
      inherit (arms.subject) candidate;
      proposition = "P2 · the published grammar is unchanged since the claim was last measured";
    };
    inherit fixtures;
  };

  cell = suite: which: suite.cells.valueMeta.thing.${which};

  # ── THE ONE-SIDED-KEY CLASS, WITNESSED AT A COMPARISON CELL ─────────────────────────────────
  #
  # ★★ THE VALUE WALK TAKES ITS KEY UNION FROM BOTH SIDES, AND UNTIL NOW ONLY THE PRIMITIVE SAID SO.
  # A walk that enumerated the reference's keys alone would be blind to anything the CANDIDATE
  # declares and the reference does not — a divergence class that reads as AGREEMENT, which is the
  # worst shape a comparison can have. `machinery` asserts that reading at `diffAt`; nothing asserted
  # it end-to-end, because no shipped fixture can: fixtures are symmetric by construction, both arms
  # running the same source. The asymmetry has to come from an ARM.
  #
  # Both directions ship, because they are different readings of the record: a candidate-only key
  # puts `__absent` on the reference side, a reference-only key puts it on the other.
  keyFixture = gd.mkFixture {
    comparison = "value";
    projections.set = gd.projections.at [
      "config"
      "set"
    ];
    modules = v: [
      {
        options.set = v.mkOption {
          type = v.types.attrsOf v.types.str;
          default = { };
        };
      }
      { config.set.shared = "s"; }
    ];
  };

  armAdding =
    name:
    gd.mkArm {
      inherit name;
      vocab = arms.vocabOf nixpkgsLib;
      eval =
        request:
        nixpkgsLib.evalModules (
          request // { modules = request.modules ++ [ { config.set.extra = "x"; } ]; }
        );
    };

  keyCell =
    subject:
    (gd.mkSuite {
      inherit subject;
      fixtures.keyFixture = keyFixture;
    }).cells.keyFixture.set.candidate;

  candidateOnlyKey = keyCell (
    gd.mkSubject {
      inherit (arms) reference seam;
      candidate = armAdding "candidate-declares-extra";
      proposition = "P1 · the design under test computes what the reference computes";
    }
  );

  referenceOnlyKey = keyCell (
    gd.mkSubject {
      inherit (arms) seam;
      reference = armAdding "reference-declares-extra";
      inherit (arms.subject) candidate;
      proposition = "P2 · the published grammar is unchanged since the claim was last measured";
    }
  );
in
{
  flake.tests.conjunct = {
    # Both seeds produce a red. Without this the distinguishability below would be a comparison of
    # two greens.
    test-a-candidate-side-divergence-is-red = {
      expr = (cell candidateSeeded "candidate").green;
      expected = false;
    };

    test-a-reference-side-divergence-is-red = {
      expr = (cell referenceSeeded "candidate").green;
      expected = false;
    };

    # ★★ THE ONE BIT THAT NAMES THE CONJUNCT. Candidate-side: the identity cell is GREEN — the
    # reference and its own body through the seam still agree, so the movement is the candidate's.
    test-a-candidate-side-divergence-leaves-the-identity-cell-green = {
      expr = (cell candidateSeeded "identity").green;
      expected = true;
    };

    # Reference-side: the identity cell is RED, because the thing the identity arm is compared
    # against is the very thing that moved.
    test-a-reference-side-divergence-reddens-the-identity-cell = {
      expr = (cell referenceSeeded "identity").green;
      expected = false;
    };

    # ── THE FAILURE OUTPUT ALONE ─────────────────────────────────────────────────────────────
    # Each red carries the proposition it belongs to, so the two conjuncts are never one red.
    test-each-red-carries-its-own-proposition = {
      expr = [
        (cell candidateSeeded "candidate").proposition
        (cell referenceSeeded "candidate").proposition
      ];
      expected = [
        "P1 · the design under test computes what the reference computes"
        "P2 · the published grammar is unchanged since the claim was last measured"
      ];
    };

    # And each names the arms it compared, so "which side is `drifted`" is answerable without
    # knowing how the suite was assembled.
    test-each-red-names-the-arms-it-compared = {
      expr = [
        [
          (cell candidateSeeded "candidate").referenceArm
          (cell candidateSeeded "candidate").candidateArm
        ]
        [
          (cell referenceSeeded "candidate").referenceArm
          (cell referenceSeeded "candidate").candidateArm
        ]
      ];
      expected = [
        [
          "nixpkgs"
          "drifted"
        ]
        [
          "drifted"
          "rehosted-module-body@seam"
        ]
      ];
    };

    # ★ THE DIVERGENCE VALUES ARE MIRRORED, which is the reading an operator actually makes: the
    # extra definition is on the candidate side in P1 and on the reference side in P2, and the
    # first-divergence record says so without any outside knowledge.
    #
    # ★★ AND THE COORDINATE IS RELATIVE TO THE PROJECTION, NOT TO THE EVALUATION RESULT. The path is
    # `[ "length" ]` rather than `[ "thing" "length" ]` because the projection already selected the
    # list, and the walk starts where the projection ended. That is the only coherent reading — the
    # claim names its projection, so the coordinate has to be inside it — but it is stated here
    # because the other reading is the one someone will assume.
    test-the-two-reds-mirror-each-other-at-the-first-divergence = {
      expr = [
        (cell candidateSeeded "candidate").firstDivergence
        (cell referenceSeeded "candidate").firstDivergence
      ];
      expected = [
        {
          path = [ "length" ];
          aValue = 2;
          bValue = 3;
        }
        {
          path = [ "length" ];
          aValue = 3;
          bValue = 2;
        }
      ];
    };

    # The rendered explanation differs between the two, which is the property the discharge test
    # actually asks for: an operator reading only the output can tell them apart.
    test-control-the-two-explanations-are-not-the-same-text = {
      expr =
        gd.oracles.explain (cell candidateSeeded "candidate")
        != gd.oracles.explain (cell referenceSeeded "candidate");
      expected = true;
    };

    # ── THE ONE-SIDED-KEY WITNESS ────────────────────────────────────────────────────────────
    # ★★ A KEY THE CANDIDATE DECLARES AND THE REFERENCE DOES NOT IS A DIVERGENCE AT A COMPARISON
    # CELL, not only at the value walk. A walk taking its keys from the reference alone would report
    # this pairing IDENTICAL — agreement where there is none — and no other cell in this repository
    # would move.
    test-a-candidate-only-key-is-a-divergence-at-a-comparison-cell = {
      expr = candidateOnlyKey.green;
      expected = false;
    };

    test-the-candidate-only-key-is-located-with-the-reference-side-absent = {
      expr = candidateOnlyKey.firstDivergence;
      expected = {
        path = [ "extra" ];
        aValue = "__absent";
        bValue = "x";
      };
    };

    # ★ THE MIRROR, because the two are different readings and only one of them would survive a
    # one-sided walk in each direction.
    test-a-reference-only-key-mirrors-it = {
      expr = referenceOnlyKey.firstDivergence;
      expected = {
        path = [ "extra" ];
        aValue = "x";
        bValue = "__absent";
      };
    };

    # LIVE CONTROL, same instrument and same run: with NEITHER arm adding the key the same fixture
    # is green — so the two reds above are the extra key and not the fixture being broken.
    test-control-the-key-fixture-agrees-when-neither-arm-adds-the-key = {
      expr =
        (gd.mkSuite {
          inherit (arms) subject;
          fixtures.keyFixture = keyFixture;
        }).cells.keyFixture.set.candidate.green;
      expected = true;
    };

    # LIVE CONTROL, same instrument and same run: the unseeded suite's cell is green and its
    # explanation says so. Without it every cell above is satisfied by a comparison stuck at red.
    test-control-the-unseeded-cell-is-green = {
      expr = arms.suite.cells.valueMeta.thing.candidate.green;
      expected = true;
    };
  };
}
