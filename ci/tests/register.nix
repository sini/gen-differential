# THE DIVERGENCE REGISTER ASSERTS, IT DOES NOT MUTE.
#
# ★★★ THE FAILURE MODE BEING GUARDED IS A REGISTER THAT DECAYS INTO A SUPPRESSION LIST. An entry
# states that a named divergence OCCURS; if it stops occurring, the entry goes RED. That second
# half is what keeps the register honest, and it is the half a tired harness drops.
{
  nixpkgsLib,
  nixpkgsSrc,
  genDifferential,
  ...
}:
let
  gd = genDifferential;
  arms = import ./_arms.nix { inherit nixpkgsLib nixpkgsSrc genDifferential; };

  # A candidate that diverges at a known coordinate: one extra list element, so the projected list
  # is three long where the reference's is two.
  drifted = gd.mkArm {
    name = "drifted";
    vocab = arms.vocabOf nixpkgsLib;
    eval =
      request:
      nixpkgsLib.evalModules (request // { modules = request.modules ++ [ { config.thing = [ 9 ]; } ]; });
  };

  fixtures.valueMeta = arms.entry "valueMeta" { };

  entry = gd.register.mkEntry {
    path = [ "length" ];
    values = {
      reference = 2;
      candidate = 3;
    };
    ruling = "test ruling 2026-01-01 — the extra element is authorized";
  };

  suiteWith =
    candidate: register:
    gd.mkSuite {
      subject = gd.mkSubject {
        inherit (arms) reference seam;
        inherit candidate;
        proposition = "P1 · the design under test computes what the reference computes, modulo ruled divergences";
      };
      inherit fixtures register;
    };

  cellOf = suite: suite.cells.valueMeta.thing.candidate;

  registered = cellOf (suiteWith drifted [ entry ]);
  unregisteredCase = cellOf (suiteWith drifted [ ]);
  # The divergence STOPS OCCURRING while the entry remains: the register has gone stale.
  staleCase = cellOf (suiteWith arms.subject.candidate [ entry ]);
in
{
  flake.tests.register = {
    # A ruled divergence is a NAMED DIVERGENCE, not a red.
    test-a-registered-divergence-is-green = {
      expr = registered.green;
      expected = true;
    };

    test-the-registered-divergence-is-recorded-as-registered = {
      expr = builtins.length registered.registered;
      expected = 1;
    };

    # ★ THE SAME DIVERGENCE WITHOUT AN ENTRY IS AN ORDINARY RED. Without this the cell above is
    # satisfied by a comparison that never noticed the divergence at all.
    test-control-the-same-divergence-without-an-entry-is-red = {
      expr = unregisteredCase.green;
      expected = false;
    };

    test-control-the-unregistered-divergence-is-reported-as-unregistered = {
      expr = builtins.length unregisteredCase.unregistered;
      expected = 1;
    };

    # ★★★ THE ASSERT-NOT-MUTE HALF. The entry is still in the register and the divergence is gone —
    # the two arms now agree. A suppression list would report green here, because nothing is being
    # suppressed. This register reports RED, and names the unsatisfied entry.
    test-an-entry-whose-divergence-stopped-occurring-goes-red = {
      expr = staleCase.green;
      expected = false;
    };

    test-the-stale-entry-is-named-as-missing = {
      expr = map (e: e.path) staleCase.missing;
      expected = [ [ "length" ] ];
    };

    # ★ AND THE STALE CASE IS RED FOR THE RIGHT REASON: there is no unregistered divergence to blame
    # it on. Without this the cell above would pass for a suite that simply diverged elsewhere.
    test-control-the-stale-case-has-no-unregistered-divergence = {
      expr = staleCase.unregistered;
      expected = [ ];
    };

    # A divergence that occurs DIFFERENTLY fires both teeth at once: the entry is unsatisfied and
    # the actual divergence is uncovered.
    test-a-divergence-with-the-wrong-values-fires-both-halves = {
      expr =
        let
          wrong = cellOf (
            suiteWith drifted [
              (gd.register.mkEntry {
                path = [ "length" ];
                values = {
                  reference = 2;
                  candidate = 99;
                };
                ruling = "test ruling — deliberately wrong candidate value";
              })
            ]
          );
        in
        [
          (builtins.length wrong.unregistered)
          (builtins.length wrong.missing)
        ];
      expected = [
        1
        1
      ];
    };

    # ── THE IDENTITY ARM IS NOT REGISTERED AGAINST ────────────────────────────────────────────
    # ★★ A register entry authorizes a difference between the REFERENCE and the DESIGN UNDER TEST.
    # The identity arm is the reference's own body travelling the candidate's seam, so it must agree
    # outright. Applying the register there would leave every entry unsatisfied on every identity
    # cell — the register asserting against the wrong pair.
    test-the-identity-cell-is-unaffected-by-the-register = {
      expr = (suiteWith drifted [ entry ]).cells.valueMeta.thing.identity.green;
      expected = true;
    };

    test-the-identity-cell-carries-no-register-entries = {
      expr = [
        (suiteWith drifted [ entry ]).cells.valueMeta.thing.identity.missing
        (suiteWith drifted [ entry ]).cells.valueMeta.thing.identity.registered
      ];
      expected = [
        [ ]
        [ ]
      ];
    };

    # ── THE SEEDED ENTRIES ───────────────────────────────────────────────────────────────────
    # The two ruled divergences the retirement diagnosis supplies, carried as data with their
    # rulings. A ruled RENAME is one ruling at two coordinates: the reference's tree carries the old
    # key and not the new, the candidate's the reverse, so the walk reports a PRESENCE change at
    # each — never a single value divergence.
    test-the-retirement-register-carries-three-entries = {
      expr = map (e: e.path) gd.register.retirement;
      expected = [
        [
          "cnf"
          "classes"
        ]
        [
          "cnf"
          "keySemantics"
        ]
        [
          "flat"
          "web/nested"
          "key"
        ]
      ];
    };

    test-every-seeded-entry-carries-a-ruling = {
      expr = builtins.all (e: builtins.isString e.ruling && e.ruling != "") gd.register.retirement;
      expected = true;
    };

    # ★ EVERY COORDINATE-ONLY ENTRY EXPLAINS ITS WEAKENING AT THE ENTRY. An unexplained one is the
    # door a register becomes a suppression list through, and the constructor refuses it — this
    # asserts the shipped entries went through that door rather than around it.
    test-every-unpinned-seeded-entry-states-why = {
      expr = builtins.all (
        e: e.values != null || (builtins.isString e.valuesUnpinned && e.valuesUnpinned != "")
      ) gd.register.retirement;
      expected = true;
    };

    # LIVE CONTROL, same run: the predicate above can distinguish the two shapes. A pinned entry
    # really does carry values, so the disjunction is not satisfied by its left half for everything.
    test-control-a-pinned-entry-has-values-and-no-unpinned-reason = {
      expr = [
        (entry.values != null)
        (entry.valuesUnpinned == null)
      ];
      expected = [
        true
        true
      ];
    };
  };
}
