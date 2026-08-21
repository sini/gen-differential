# THE COVERAGE FLOOR — three keys here, the fourth deferred with its corpus.
#
# The instrument this library replaces held its coverage as four gate keys, of which two were ruled
# REQUIRED: that both stacks genuinely evaluated, and that perturbing an input moves the compared
# observable. Without those two a parity harness reads green while asserting nothing; that is the
# standard failure, and these are the keys that refuse it.
#
# ★★ THREE OF FOUR, AND A GREEN HERE DOES NOT DISCHARGE THE FOURTH. The missing key is that a real,
# domain-shaped tree flattens identically through both grammars. It is a property of a domain
# corpus, and this library's fixtures are synthetic by ruling — so the key is not weakened, it is
# owed by the instantiation that has a corpus. Saying so here is the difference between a deferral
# and a shortfall nobody wrote down.
{
  nixpkgsLib,
  nixpkgsSrc,
  genDifferential,
  ...
}:
let
  gd = genDifferential;
  arms = import ./_arms.nix { inherit nixpkgsLib nixpkgsSrc genDifferential; };

  syntheticAt =
    n:
    arms.entry "synthetic" {
      inherit n;
      ndecls = 4;
      layers = 2;
    };

  # THE TEETH: perturb a declared construction parameter and require the compared observable to
  # move. Widening the element count adds an element, which the value observable must see.
  teeth = gd.oracles.mutationTeeth {
    arm = arms.reference;
    fixture = syntheticAt 6;
    observableName = "things";
    perturb = _: syntheticAt 7;
  };

  # ★ THE NEGATIVE CONTROL FOR THE TEETH THEMSELVES. A `moved` that is stuck at `true` would pass
  # the key above while measuring nothing — so the same instrument, in the same run, is asked a
  # question whose honest answer is `false`: an identity perturbation moves nothing.
  toothlessControl = gd.oracles.mutationTeeth {
    arm = arms.reference;
    fixture = syntheticAt 6;
    observableName = "things";
    perturb = fx: fx;
  };

  # ★★ AND A PERTURBATION THE OBSERVABLE CANNOT SEE, which is the subtler negative: the fixture
  # really did change, and this observable is still entitled to report no movement. It is the same
  # phenomenon the observable SET exists for.
  invisibleControl = gd.oracles.mutationTeeth {
    arm = arms.reference;
    fixture = syntheticAt 6;
    observableName = "shape";
    perturb = _: syntheticAt 7;
  };

  result = gd.oracles.floor {
    inherit (arms) suite;
    teeth = teeth.moved;
  };
in
{
  flake.tests.floor = {
    test-the-floor-is-met = {
      expr = result.met;
      expected = true;
    };

    # The keys are asserted individually as well as in the rollup, so a red names which one moved
    # rather than reporting that the floor is not met.
    test-key-all-identical = {
      expr = result."all-identical";
      expected = true;
    };

    test-key-both-evaluated = {
      expr = result."both-evaluated";
      expected = true;
    };

    test-key-teeth-mutation-diverges = {
      expr = result."teeth-mutation-diverges";
      expected = true;
    };

    # ★ THE FLOOR NAMES ITS OWN MEMBERSHIP, and the membership is three. A floor that silently grew
    # or shrank would still report `met`.
    test-the-floor-has-exactly-three-keys = {
      expr = gd.oracles.floorKeys;
      expected = [
        "all-identical"
        "both-evaluated"
        "teeth-mutation-diverges"
      ];
    };

    # ── CONTROLS ─────────────────────────────────────────────────────────────────────────────
    test-control-an-identity-perturbation-moves-nothing = {
      expr = toothlessControl.moved;
      expected = false;
    };

    test-control-a-perturbation-the-observable-cannot-see-moves-nothing = {
      expr = invisibleControl.moved;
      expected = false;
    };

    # ★★ THE ANTI-VACUITY KEY HAS TEETH OF ITS OWN. Two arms that agree by both REFUSING must fail
    # `both-evaluated` — that is the entire point of the key, and a floor that could not be shown to
    # fail it would be reporting a constant. The suite below compares an arm against itself on a
    # fixture whose observable does not exist, so both sides refuse and the values are equal.
    test-control-two-refusing-arms-fail-the-anti-vacuity-key = {
      expr =
        let
          missing = gd.mkFixture {
            comparison = "value";
            observables.absent = gd.observables.at [
              "config"
              "nothing-declares-this"
            ];
            modules = v: [
              {
                options.x = v.mkOption {
                  type = v.types.str;
                  default = "";
                };
              }
            ];
          };
          suite = gd.mkSuite {
            inherit (arms) subject;
            fixtures.missing = missing;
          };
        in
        (gd.oracles.floor {
          inherit suite;
          teeth = true;
        })."both-evaluated";
      expected = false;
    };

    # And the same construction is genuinely a mutual refusal rather than a crash — the arms did
    # decline, which is what makes the key's `false` the right answer instead of an accident.
    test-control-the-refusing-suite-is-not-green = {
      expr =
        let
          missing = gd.mkFixture {
            comparison = "value";
            observables.absent = gd.observables.at [
              "config"
              "nothing-declares-this"
            ];
            modules = v: [
              {
                options.x = v.mkOption {
                  type = v.types.str;
                  default = "";
                };
              }
            ];
          };
        in
        (gd.mkSuite {
          inherit (arms) subject;
          fixtures.missing = missing;
        }).green;
      expected = false;
    };
  };
}
