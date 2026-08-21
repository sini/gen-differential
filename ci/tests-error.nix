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
      # An unnamed claim is the conjunction defect: a red that cannot say which proposition it
      # belongs to is the failure that retired the predecessor apparatus.
      test-empty-proposition-refuses = {
        expr = gd.mkSubject {
          reference = null;
          candidate = null;
          seam = null;
          proposition = "";
        };
        expectedError.msg = "subject.proposition";
      };

      # An empty projection set compares nothing and reads green — the exact vacuity a projection
      # that is "required and total" exists to refuse.
      test-empty-projection-set-refuses = {
        expr = gd.mkFixture {
          modules = _: [ ];
          projections = { };
          comparison = "value";
        };
        expectedError.msg = "fixture.projections";
      };

      # A comparison kind is a member of a declared set, not a free string.
      test-unknown-comparison-kind-refuses = {
        expr = gd.mkFixture {
          modules = _: [ ];
          projections.x = x: x;
          comparison = "byteish";
        };
        expectedError.msg = "fixture.comparison";
      };

      # A fixture's modules are a function of the arm's vocabulary. A plain list closed over ONE
      # arm's vocabulary would make a differential compare two different programs.
      test-non-function-modules-refuses = {
        expr = gd.mkFixture {
          modules = [ ];
          projections.x = x: x;
          comparison = "value";
        };
        expectedError.msg = "fixture.modules";
      };

      # A suite with no fixtures asserts nothing and reads green — the 0/0 false pass, refused at
      # the constructor rather than left for a reader to notice in a count.
      test-empty-suite-refuses = {
        expr = gd.mkSuite {
          subject = null;
          fixtures = { };
        };
        expectedError.msg = "suite.fixtures";
      };

      # The seam is what makes the identity control non-vacuous; an unnamed one cannot be told from
      # another subject's, which is how a suite ends up with one instantiation counted twice.
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
      # answering `true` to it is how a suite reports coverage it does not have.
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
      test-control-well-formed-fixture-answers = {
        expr =
          (gd.mkFixture {
            modules = _: [ ];
            projections.x = x: x;
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
