# THE VALUE MACHINERY AND THE CONTRACT, asserted at the primitives.
#
# The suites elsewhere assert PROPERTIES OF COMPARISONS. These assert the pieces those properties
# rest on, so a red above can be told from a red here.
{ genDifferential, ... }:
let
  gd = genDifferential;
  inherit (gd) diff;
in
{
  flake.tests.machinery = {
    # ── THE WALK ─────────────────────────────────────────────────────────────────────────────
    test-identical-structures-have-no-divergences = {
      expr = diff.diff {
        a = {
          x = [
            1
            2
          ];
          y.z = "s";
        };
        b = {
          x = [
            1
            2
          ];
          y.z = "s";
        };
      };
      expected = {
        identical = true;
        bothEvaluated = true;
        divergences = [ ];
      };
    };

    # The coordinate is the deepest point of disagreement, not the top-level attribute that
    # contains it — which is what makes a red readable on a wide option tree.
    test-a-nested-divergence-is-located-at-its-own-coordinate = {
      expr = diff.locate {
        a.y.z = "s";
        b.y.z = "t";
      };
      expected = {
        path = [
          "y"
          "z"
        ];
        aValue = "s";
        bValue = "t";
      };
    };

    # A key present on one side only is a PRESENCE divergence, and the absent side says so rather
    # than reporting `null` — which would be indistinguishable from a declared null.
    test-a-missing-key-is-reported-as-absent-rather-than-null = {
      expr = diff.locate {
        a = { };
        b.k = null;
      };
      expected = {
        path = [ "k" ];
        aValue = "__absent";
        bValue = null;
      };
    };

    # Lists of different length diverge at their length, not element-wise: comparing element 3 of a
    # two-element list is a coordinate that does not exist.
    test-lists-of-different-length-diverge-at-length = {
      expr =
        (diff.locate {
          a = [
            1
            2
          ];
          b = [
            1
            2
            3
          ];
        }).path;
      expected = [ "length" ];
    };

    # ★★ A REFUSAL ON EITHER SIDE IS A DIVERGENCE, AND THE ANTI-VACUITY KEY SAYS WHY. Two arms that
    # both refuse have not been shown to agree about anything except that they refuse; reporting
    # `identical` for that is the vacuity the whole floor exists to refuse.
    test-two-refusals-are-not-identical = {
      expr = diff.diff {
        a = throw "left";
        b = throw "right";
      };
      expected = {
        identical = false;
        bothEvaluated = false;
        divergences = [
          {
            path = [ ];
            aValue = "<<throw>>";
            bValue = "<<throw>>";
          }
        ];
      };
    };

    # ★ THE PROBE READING IS THE OPPOSITE CONVENTION, ON PURPOSE. "Did this move?" is answered `no`
    # by two refusals; "are these the same?" is not answered at all. The oracles use the first, the
    # comparison kinds the second, and keeping them apart is why both are correct.
    test-control-the-probe-reading-calls-two-refusals-unchanged = {
      expr = diff.probeEq (throw "left") (throw "right");
      expected = true;
    };

    test-control-the-probe-reading-still-separates-a-refusal-from-a-value = {
      expr = diff.probeEq (throw "left") 1;
      expected = false;
    };

    # ── THE CONTRACT ─────────────────────────────────────────────────────────────────────────
    # ★★ THE COMPARISON KINDS ARE DECLARED IN ONE PLACE AND IMPLEMENTED IN ANOTHER, AND THE TWO ARE
    # ASSERTED TO AGREE. Deriving the declaration from the implementation would make adding a kind a
    # silent widening of what a fixture may ask for; deriving neither would let them drift.
    test-the-declared-kinds-and-the-implemented-kinds-agree = {
      expr = builtins.sort builtins.lessThan (builtins.attrNames gd.compare.kinds);
      expected = builtins.sort builtins.lessThan gd.contract.comparisonKinds;
    };

    # Every kind states what a green MEANS. A cell that asserts derivation-path identity and is read
    # as end-result equivalence has overstated its own result.
    test-every-kind-states-what-it-asserts = {
      expr = builtins.mapAttrs (_: k: k.assertion) gd.compare.kinds;
      expected = {
        value = "equivalence";
        drvPath = "identity";
        throws = "refusal";
      };
    };

    # ★★★ THE IDENTITY ARM IS DERIVED FROM THE SEAM AND CANNOT BE SUPPLIED. There is no field to
    # hand one in through, which is what stops a consumer from installing an identity arm that
    # bypasses the substitution point and reports a control it never ran.
    test-the-identity-arm-is-the-reference-body-through-the-seam = {
      expr =
        let
          # Minimal well-formed arms rather than bare strings: `mkSubject` shape-checks BOTH halves
          # at acceptance, so a placeholder that is not arm-shaped is now refused by name. That the
          # arms are stubs is fine — this cell is about where the IDENTITY arm comes from, and it
          # comes from the seam alone.
          stub =
            n:
            gd.mkArm {
              name = n;
              vocab = { };
              eval = _: { };
            };
          subject = gd.mkSubject {
            reference = stub "REF";
            candidate = stub "CAND";
            proposition = "p";
            seam = gd.mkSeam {
              name = "s";
              install = body: "installed:${body}";
              referenceBody = "REF-BODY";
            };
          };
        in
        (gd.contract.armsOf subject).identity;
      expected = "installed:REF-BODY";
    };

    # A corpus entry's construction parameters are overridable at the call site, defaults under
    # caller values — construction arguments and comparison metadata being different axes is the
    # whole reason the registry states both.
    test-entry-defaults-are-overridable-at-the-call-site = {
      expr = (gd.contract.instantiate gd.corpus.registry.artifact { tag = "zzz"; }).comparison;
      expected = "drvPath";
    };

    # The registry validates every entry through the constructor, so its shape is a contract rather
    # than a convention that happens to hold today.
    test-every-registry-entry-has-the-registry-shape = {
      expr = builtins.all (
        e:
        builtins.sort builtins.lessThan (builtins.attrNames e) == [
          "defaultParams"
          "gate"
          "mk"
          "tier"
        ]
      ) (builtins.attrValues gd.corpus.registry);
      expected = true;
    };

    # ★ THE TIER IS READ, NOT DECORATIVE. Every entry's declared tier is a member of the declared
    # set, and the two tiers partition the registry — so a tier nobody selects on would be visible
    # here as a set with one member.
    test-the-tiers-partition-the-registry = {
      expr = {
        core = builtins.attrNames (gd.corpus.ofTier "core");
        ordered = builtins.attrNames (gd.corpus.ofTier "ordered");
      };
      expected = {
        core = [
          "artifact"
          "latticeThrows"
          "synthetic"
          "valueMeta"
        ];
        ordered = [
          "artifact"
          "latticeThrows"
          "order"
          "priorityFold"
          "synthetic"
          "valueMeta"
        ];
      };
    };
  };
}
