# THE CONSUMER DEMONSTRATION — the first consumer's differential, run here.
#
# The engine the apparatus was built to hold accountable, finally held by it: a from-scratch pure
# merge engine compared against the reference module system, over the corpus tier its vocabulary
# admits, at every projection each fixture declares.
#
# ★ WHAT A GREEN HERE DOES AND DOES NOT SAY. It says the candidate agrees with the reference on
# these fixtures at these projections, with the identity control green and seedable in the same run.
# It does NOT say the candidate agrees in general, and it does not close the standing interval about
# the shared grammar — that closes at an instantiation with a real corpus, which is deferred with
# its own criteria. A machinery library's green must never be readable as the cross-implementation
# bar being met.
{
  nixpkgsLib,
  genMerge,
  genDifferential,
  ...
}:
let
  gd = genDifferential;
  consumer = import ./_consumer.nix { inherit nixpkgsLib genMerge genDifferential; };

  claimsOf =
    which: suite:
    builtins.concatMap (fx: map (p: p.${which}) (builtins.attrValues fx)) (
      builtins.attrValues suite.cells
    );

  greenMap =
    which: suite: builtins.mapAttrs (_: ps: builtins.mapAttrs (_: a: a.${which}.green) ps) suite.cells;

  # ── THE SEED ─────────────────────────────────────────────────────────────────────────────────
  # An adapter that drops one declared option from the normalized result. It is installed at the
  # same seam, so it reaches the identity arm — and the claim it falsifies is the one this seam
  # exists to make: that the adapter does not change the answer.
  seededSubject = gd.mkSubject {
    inherit (consumer.subject) reference candidate proposition;
    seam = gd.mkSeam {
      name = "module-system-surface@SEEDED";
      inherit (consumer) referenceBody;
      install =
        impl:
        gd.mkArm {
          name = "SEEDED-${impl.name}@surface";
          vocab = consumer.coreVocab impl.vocab;
          eval =
            request:
            let
              r = impl.evalModules { inherit (request) modules; };
              stripped = builtins.removeAttrs r.config [ "_module" ];
              drop = builtins.head (builtins.attrNames stripped);
            in
            {
              config = builtins.removeAttrs stripped [ drop ];
              options = builtins.removeAttrs r.options [ "_module" ];
            };
        };
    };
  };

  seededSuite = gd.mkSuite {
    subject = seededSubject;
    inherit (consumer) fixtures;
  };
in
{
  flake.tests.consumer = {
    # ── THE DIFFERENTIAL ─────────────────────────────────────────────────────────────────────
    test-candidate-agrees-with-the-reference-on-every-core-fixture = {
      expr = builtins.all (c: c.green) (claimsOf "candidate" consumer.suite);
      expected = true;
    };

    # The identity control for THIS subject, green in the same run: the adapter is invisible.
    test-identity-control-is-green = {
      expr = builtins.all (c: c.green) (claimsOf "identity" consumer.suite);
      expected = true;
    };

    # Both arms genuinely evaluated. Two engines that agreed by both refusing would satisfy the
    # verdict above and assert nothing.
    test-every-cell-carries-its-anti-vacuity-key = {
      expr = builtins.all (
        c: if c.comparison == "throws" then c.bothRefused == true else c.bothEvaluated == true
      ) (claimsOf "candidate" consumer.suite);
      expected = true;
    };

    # ★ WHICH FIXTURES RAN, ASSERTED AS A SET RATHER THAN A COUNT. The candidate does not publish
    # the ordering combinators, so the two `ordered`-tier fixtures are absent BY DECLARATION. A
    # count would let a fixture disappear and the suite stay green.
    test-tier-selection-is-exactly-the-core-entries = {
      expr = builtins.attrNames consumer.fixtures;
      expected = [
        "artifact"
        "latticeThrows"
        "synthetic"
        "valueMeta"
      ];
    };

    # ★★ AND THE FIXTURES IT CANNOT RUN ARE NAMED, NOT MERELY MISSING. This is the other half of the
    # line above: a reader can see what was excluded and why, from the suite itself.
    test-ordered-tier-entries-are-excluded-by-declaration = {
      expr = builtins.attrNames (
        builtins.removeAttrs gd.corpus.registry (builtins.attrNames consumer.coreEntries)
      );
      expected = [
        "order"
        "priorityFold"
      ];
    };

    # Every projection each fixture declares was measured — the claim names its projection, so a
    # projection quietly dropped would be visible here rather than absorbed into a total.
    test-every-declared-projection-was-measured = {
      expr = greenMap "candidate" consumer.suite;
      expected = {
        artifact.out = true;
        latticeThrows.n = true;
        synthetic = {
          shape = true;
          things = true;
        };
        valueMeta.thing = true;
      };
    };

    # ── THE SEEDED FAILURE ───────────────────────────────────────────────────────────────────
    # Perturb the adapter and the identity arm goes red at every VALUE projection. Two cells survive
    # it, and both survivals are the design being correct rather than the seed being weak:
    #
    # ★ `synthetic.shape` survives because the seed drops a CONFIG attribute and that projection
    #   reads DECLARATIONS. A perturbation one projection cannot see is exactly why a fixture
    #   carries a projection SET, and asserting the partition is what makes it visible here rather
    #   than discovered later as a weak guard.
    #
    # ★★ `latticeThrows.n` survives because the `throws` kind asserts MUTUAL REFUSAL AND NOT A
    #   SHARED CAUSE. The unseeded arm refuses on the merge conflict the fixture is about; the
    #   seeded arm refuses because the adapter removed the attribute the projection reads. Both
    #   refuse, so the claim holds — and it should, because the kind's proposition is that both arms
    #   decline, which is all a `tryEval`-shaped refusal reading can ever establish. Measured here
    #   rather than assumed: this cell is the record that the kind's domain is that narrow.
    test-control-seeded-adapter-reddens-exactly-this-partition = {
      expr = greenMap "identity" seededSuite;
      expected = {
        artifact.out = false;
        latticeThrows.n = true;
        synthetic = {
          shape = true;
          things = false;
        };
        valueMeta.thing = false;
      };
    };

    # ★ AND THE RED IS ATTRIBUTABLE TO THE ADAPTER RATHER THAN TO THE ENGINE: the candidate arm is
    # routed through the seeded adapter too, so it moves as well — and the cell says which arms it
    # compared. A seed that reddened only one arm would leave the pair ambiguous.
    test-control-seeded-adapter-is-visible-in-the-suite-rollup = {
      expr = seededSuite.green;
      expected = false;
    };
  };
}
