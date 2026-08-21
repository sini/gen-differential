# THE SECOND TEST OUTPUT — the cells whose `expr` ABORTS BY DESIGN, and the runner that reads them.
#
# The contract's fields are required and total, and a required field is enforced by a REFUSAL. The
# batch asserter behind `checks.default` forces every `expr` under `flake.tests` unconditionally, so
# a cell asserting a refusal would crash that gate rather than fail — which means a contract whose
# refusals live only under `flake.tests` is a contract that refuses on paper and has never been
# shown to refuse.
#
#   nix-unit --flake ./ci#tests        # the suites
#   nix-unit --flake ./ci#testsError   # these cells
{
  lib,
  genDifferential,
  genInputs,
  ...
}:
let
  gd = genDifferential;
in
{
  options.flake.testsError = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.raw);
    default = { };
    description = "Test suites whose cells' `expr` CAN ABORT: { suite.test = { expr; expected | expectedError; }; }. Read by `nix-unit --flake ./ci#testsError`; deliberately outside `flake.tests`, which the batch asserter forces every `expr` of and would crash on rather than fail.";
  };

  config = {
    # ── THE CONTRACT'S REFUSALS ───────────────────────────────────────────────────────────────
    # Each cell drives one required-and-total field to its degenerate value and asserts the library
    # says so BY NAME. A field that is "required" because a missing attribute happens to abort has
    # a message about attribute lookup; these have messages about the design.
    flake.testsError.contract-refusals = {
      # An unnamed claim is the conjunction defect: a red that cannot say which claim it
      # belongs to is the failure that retired the predecessor apparatus.
      test-empty-claim-refuses = {
        expr = gd.mkSubject {
          reference = null;
          candidate = null;
          seam = null;
          claim = "";
        };
        expectedError.msg = "subject.claim";
      };

      # An empty observable set compares nothing and reads green — the exact vacuity an observable
      # that is "required and total" exists to refuse.
      test-empty-observable-set-refuses = {
        expr = gd.mkFixture {
          modules = _: [ ];
          observables = { };
          comparison = "value";
        };
        expectedError.msg = "fixture.observables";
      };

      # A comparison kind is a member of a declared set, not a free string.
      test-unknown-comparison-kind-refuses = {
        expr = gd.mkFixture {
          modules = _: [ ];
          observables.x = x: x;
          comparison = "byteish";
        };
        expectedError.msg = "fixture.comparison";
      };

      # A fixture's modules are a function of the arm's vocabulary. A plain list closed over ONE
      # arm's vocabulary would make a differential compare two different programs.
      test-non-function-modules-refuses = {
        expr = gd.mkFixture {
          modules = [ ];
          observables.x = x: x;
          comparison = "value";
        };
        expectedError.msg = "fixture.modules";
      };

      # A run with no fixtures asserts nothing and reads green — the 0/0 false pass, refused at
      # the constructor rather than left for a reader to notice in a count.
      test-empty-run-refuses = {
        expr = gd.mkRun {
          subject = null;
          fixtures = { };
        };
        expectedError.msg = "run.fixtures";
      };

      # The seam is what makes the identity control non-vacuous; an unnamed one cannot be told from
      # another subject's, which is how a run ends up with one instantiation counted twice.
      test-empty-seam-name-refuses = {
        expr = gd.mkSeam {
          name = "";
          install = x: x;
          referenceBody = null;
        };
        expectedError.msg = "seam.name";
      };

      # The seam INSTALLS a body and yields an arm. Without that, there is no way to obtain an
      # identity arm at all.
      test-non-function-seam-install-refuses = {
        expr = gd.mkSeam {
          name = "s";
          install = null;
          referenceBody = null;
        };
        expectedError.msg = "seam.install";
      };

      # ── THE SUBJECT'S OTHER THREE REQUIRED FIELDS ─────────────────────────────────────────
      # ★★★ THE CLASS, NOT THE INSTANCE. `tryEval` catches thrown errors and failed assertions and
      # NOT a type or missing-attribute error, so a malformed record reaching a selection aborts
      # the whole evaluation instead of reddening a cell. This library met that class once at the
      # `drvPath` kind and fixed it there; measured afterwards, `mkSubject` still ACCEPTED
      # `seam = null`, and the failure surfaced as `expected a set but found null` — propagating
      # straight out of `tryEval`. These three cells are the class discharged at the contract's own
      # entry point, so a consumer who hand-rolls a subject (which is what the quick start shows)
      # gets a named refusal about the design rather than an abort about attribute lookup.
      test-non-seam-subject-refuses = {
        expr = gd.mkSubject {
          reference = gd.mkArm {
            name = "r";
            vocab = { };
            eval = _: { };
          };
          candidate = gd.mkArm {
            name = "c";
            vocab = { };
            eval = _: { };
          };
          seam = null;
          claim = "p";
        };
        expectedError.msg = "subject.seam";
      };

      test-non-arm-reference-refuses = {
        expr = gd.mkSubject {
          reference = null;
          candidate = gd.mkArm {
            name = "c";
            vocab = { };
            eval = _: { };
          };
          seam = gd.mkSeam {
            name = "s";
            install = b: b;
            referenceBody = { };
          };
          claim = "p";
        };
        expectedError.msg = "subject.reference";
      };

      # ★ THE CANDIDATE HALF IS CHECKED AS WELL AS THE REFERENCE HALF, so the asymmetry the contract
      # draws between them is an asymmetry of MEANING and never of validation. This one is
      # field-shaped rather than null — an attrset missing `eval` — because that is the malformed
      # record a consumer actually produces, and it is the one a bare `isAttrs` check would admit.
      test-non-arm-candidate-refuses = {
        expr = gd.mkSubject {
          reference = gd.mkArm {
            name = "r";
            vocab = { };
            eval = _: { };
          };
          candidate = {
            name = "c";
            vocab = { };
          };
          seam = gd.mkSeam {
            name = "s";
            install = b: b;
            referenceBody = { };
          };
          claim = "p";
        };
        expectedError.msg = "subject.candidate.eval";
      };

      # A register entry authorizes a divergence. Without the authorization it is indistinguishable
      # from a bug someone grew used to.
      test-register-entry-without-ruling-refuses = {
        expr = gd.register.mkEntry {
          path = [ "a" ];
          values = {
            reference = 1;
            candidate = 2;
          };
          ruling = "";
        };
        expectedError.msg = "register.ruling";
      };

      # ★ THE WEAKENING MUST BE EXPLAINED AT THE ENTRY. A coordinate-only entry that did not have
      # to say why its values are unpinned is the door the register becomes a suppression list
      # through.
      test-coordinate-entry-without-reason-refuses = {
        expr = gd.register.mkCoordinateEntry {
          path = [ "a" ];
          ruling = "ruled somewhere";
          valuesUnpinned = "";
        };
        expectedError.msg = "register.valuesUnpinned";
      };

      # An input-consumption question with nothing declared has nothing to demonstrate, and
      # answering `true` to it is how a run reports coverage it does not have.
      test-empty-input-set-refuses = {
        expr = gd.oracles.inputConsumption {
          inputs = { };
          perturb = _: v: v;
          cells = _: { };
        };
        expectedError.msg = "inputConsumption.inputs";
      };

      # LIVE CONTROL, same run and same instrument: the same constructors ANSWER on well-formed
      # input. Without it every cell above is satisfied by a library that refuses everything, which
      # is a different defect wearing the same green.
      # ★ THE CONTROL FOR THE THREE CELLS ABOVE, and it is the one that matters most: a WELL-FORMED
      # subject still answers. Without it, all three are satisfied by a `mkSubject` that refuses
      # every subject it is handed — which would redden the whole run elsewhere, but would satisfy
      # these cells exactly as a correct implementation does.
      test-control-well-formed-subject-answers = {
        expr =
          (gd.mkSubject {
            reference = gd.mkArm {
              name = "r";
              vocab = { };
              eval = _: { };
            };
            candidate = gd.mkArm {
              name = "c";
              vocab = { };
              eval = _: { };
            };
            seam = gd.mkSeam {
              name = "s";
              install = b: b;
              referenceBody = "REF-BODY";
            };
            claim = "p";
          }).claim;
        expected = "p";
      };

      test-control-well-formed-fixture-answers = {
        expr =
          (gd.mkFixture {
            modules = _: [ ];
            observables.x = x: x;
            comparison = "value";
          }).comparison;
        expected = "value";
      };

      test-control-well-formed-register-entry-answers = {
        expr =
          (gd.register.mkEntry {
            path = [ "a" ];
            values = {
              reference = 1;
              candidate = 2;
            };
            ruling = "ruled 2026-01-01";
          }).ruling;
        expected = "ruled 2026-01-01";
      };
    };

    perSystem =
      { pkgs, system, ... }:
      {
        pre-commit.settings.hooks.ci-error = {
          enable = true;
          name = "ci-error";
          description = "Run nix-unit error-assertion tests";
          entry = "${
            pkgs.writeShellApplication {
              name = "gen-differential-ci-nix-unit-error";
              runtimeInputs = [ genInputs.nix-unit.packages.${system}.default ];
              text = ''
                exec nix-unit --flake ./ci#testsError "$@"
              '';
            }
          }/bin/gen-differential-ci-nix-unit-error";
          files = "\\.nix$";
          pass_filenames = false;
        };
      };
  };
}
