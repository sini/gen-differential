# THE NO-GO RECORD IS PRESENT WITH ITS SCOPE CORRECTION.
#
# ★★★ THE CORRECTION'S ABSENCE IS A FAILURE OF THIS ORACLE, NOT A STYLISTIC OMISSION. The four
# results are a rigorous negative about one architecture; read as a blanket ceiling they say the
# opposite of what was found, and would license the false inference that a declared host-class
# boundary is unsound. A copy of the results without the correction is worse than no copy.
#
# ★★ THE STRUCTURAL DISCHARGE IS THAT THEY ARE FIELDS OF ONE RECORD. A reader cannot import the
# results and leave the correction behind, because there is nothing to import them out of. The
# cells below assert that property rather than the presence of a paragraph somewhere.
{ genDifferential, ... }:
let
  noGo = genDifferential.sharingNoGo;
in
{
  flake.tests.no-go-record = {
    # All four, named. A count would let one be dropped and replaced.
    test-the-four-results-are-present-and-named = {
      expr = map (r: r.name) noGo.results;
      expected = [
        "no-sound-single-host-net-win"
        "union-sentinel-unsound"
        "presence-and-structure-unsound"
        "syntactic-path-set-key-unsound"
      ];
    };

    # Each carries its ground, not only its claim: a negative result whose reasoning is missing is
    # a rumour with a citation.
    test-every-result-carries-a-claim-and-a-ground = {
      expr = builtins.all (
        r: builtins.isString r.claim && r.claim != "" && builtins.isString r.ground && r.ground != ""
      ) noGo.results;
      expected = true;
    };

    # ★★★ THE SCOPE CORRECTION TRAVELS WITH THEM.
    test-the-scope-correction-is-present = {
      expr = builtins.isString noGo.scopeCorrection && builtins.stringLength noGo.scopeCorrection > 200;
      expected = true;
    };

    # ★ AND IT IS THE CORRECTION RATHER THAN A PLACEHOLDER: the three clauses that carry its content
    # are each present. The correction says the NO-GO is not a blanket ceiling, that it applies to
    # per-element DISCOVERY, and that DECLARING the boundary flips the sign at fleet scale.
    test-the-correction-carries-its-three-load-bearing-clauses = {
      expr =
        map
          (
            needle:
            builtins.match ".*${needle}.*" (builtins.replaceStrings [ "\n" ] [ " " ] noGo.scopeCorrection)
            != null
          )
          [
            "NOT a blanket ceiling"
            "discovering"
            "sign flips positive"
          ];
      expected = [
        true
        true
        true
      ];
    };

    # ★★ THE STRUCTURAL PROPERTY: results and correction are attributes of the SAME value, so the
    # separation the record exists to prevent is not expressible. This is the cell that would go red
    # if someone split the record into two files "for readability".
    test-the-results-and-the-correction-are-one-record = {
      expr = builtins.all (k: noGo ? ${k}) [
        "results"
        "scopeCorrection"
        "soundnessBoundary"
        "ceiling"
        "verdict"
        "subject"
      ];
      expected = true;
    };

    # The soundness boundary and the honest ceiling are the two qualifications that make the
    # negative usable rather than merely discouraging.
    test-the-soundness-boundary-names-the-throws-observed-subclass = {
      expr = builtins.match ".*throws-observed subclass.*" noGo.soundnessBoundary != null;
      expected = true;
    };

    # The ceiling is the other side of the `drvPath` kind's coin, and the kind's own label agrees
    # with it — identity is a strong witness in one direction and mute in the other.
    test-the-ceiling-and-the-drvPath-kind-agree = {
      expr = [
        (builtins.match ".*not that evaluation work was shared.*" noGo.ceiling != null)
        genDifferential.compare.kinds.drvPath.assertion
      ];
      expected = [
        true
        "identity"
      ];
    };

    # LIVE CONTROL, same instrument and same run: the matcher used above can return `null`, so the
    # three `true`s are readings rather than a predicate stuck open.
    test-control-a-clause-that-is-absent-does-not-match = {
      expr = builtins.match ".*zzqq-not-in-the-correction.*" noGo.scopeCorrection;
      expected = null;
    };
  };
}
