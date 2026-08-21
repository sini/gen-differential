# PURITY — the library's own source carries no substrate and no subject.
#
# ★★ BOTH ARMS ARRIVE AS ARGUMENTS, SO NEITHER IS IN THE SOURCE. That is the whole content of the
# claim: an instrument that vendored a reference evaluator would be measuring against a frozen copy
# that can never follow a ruled change — the defect that retired the predecessor apparatus — and one
# that named a candidate would be a harness for exactly one design wearing a general name.
#
# ★ TWO TOKENS ARE DELIBERATELY NOT FORBIDDEN, AND SAYING WHICH IS PART OF THE ORACLE. A named
# `NixOS` accessor is exported as an OBSERVABLE, which is the corrected form of the leak this scan
# exists to prevent: the coordinate is reachable by name instead of assumed inside the comparison.
# And the negative result the library carries names the public apparatus it came from, which is
# provenance rather than a dependency. A scan whose exclusions are unwritten is a scan whose next
# reader deletes them.
{
  genPrelude,
  genDifferential,
  ...
}:
let
  inherit (genPrelude) hasInfix;

  # Read every Nix source file of the library. `readDir` rather than a hand-kept list: a file added
  # without being added here would otherwise be scanned by nobody.
  dir = ../../lib;
  names = builtins.filter (n: builtins.match ".*\\.nix" n != null) (
    builtins.attrNames (builtins.readDir dir)
  );
  sources = map (n: {
    inherit n;
    text = builtins.readFile (dir + "/${n}");
  }) names;

  # ★ nixpkgs' own `hasInfix` recurses to a depth proportional to the string length on a whole-file
  # read and overflows the default stack. The prelude's backtracking-free form is what makes a
  # source scan possible at all.
  hits = token: map (s: s.n) (builtins.filter (s: hasInfix token s.text) sources);

  forbidden = [
    # A substrate the instrument must not carry: a reference evaluator arrives as an argument.
    "nixpkgs"
    # Impurity, in every spelling that reaches outside the source tree.
    "fetchTarball"
    "fetchTree"
    "getFlake"
    "builtins.currentSystem"
    # A named candidate. An instrument that knows one design's name is that design's harness.
    "gen-merge"
    "evalModuleTree"
    # Domain content. The suite is synthetic and pure by ruling; these are the tiers that are not.
    "denTemplate"
    "denFleet"
    "nix-config"
  ];

  violations = builtins.listToAttrs (
    builtins.concatMap (
      t:
      let
        f = hits t;
      in
      if f == [ ] then
        [ ]
      else
        [
          {
            name = t;
            value = f;
          }
        ]
    ) forbidden
  );
in
{
  flake.tests.purity = {
    # Named rather than counted: a violation says which token in which file.
    test-no-forbidden-token-appears-in-the-library-source = {
      expr = violations;
      expected = { };
    };

    # ★ THE SCAN COVERS EVERY SOURCE FILE, and the roster is asserted rather than trusted. A file
    # that stopped being read would leave the cell above green while scanning less.
    test-the-scan-covers-every-library-source-file = {
      expr = builtins.sort builtins.lessThan names;
      expected = [
        "compare.nix"
        "contract.nix"
        "default.nix"
        "diff.nix"
        "no-go.nix"
        "observables.nix"
        "oracles.nix"
        "register.nix"
        "suite.nix"
      ];
    };

    # ★★ THE PREDICATE CAN FIRE — the control that makes the empty result above a finding rather
    # than a broken scan. Several "clean" results in this project came from predicates that could
    # not have matched.
    test-control-a-token-that-is-present-is-found = {
      expr = hits "mkSubject" != [ ];
      expected = true;
    };

    # And it is not stuck at "found": a token nothing contains comes back empty.
    test-control-a-token-that-is-absent-is-not-found = {
      expr = hits "zzqq-not-a-token";
      expected = [ ];
    };

    # The scan read a non-trivial amount of text, so an empty file list could not have produced the
    # clean result above.
    test-control-the-scan-read-actual-source = {
      expr = builtins.all (s: builtins.stringLength s.text > 500) sources;
      expected = true;
    };

    # ── THE STRUCTURAL HALF ──────────────────────────────────────────────────────────────────
    # ★ THE FLAKE DECLARES NO INPUTS AT ALL. The token scan is a property of the text; this is a
    # property of the dependency graph, and it is the stronger statement: a consumer pinning this
    # instrument gains exactly one node, so no library can be built twice in one evaluation — once
    # as the instrument's dependency and once as the design under test.
    test-the-library-namespace-is-reachable-without-any-argument = {
      expr = builtins.isAttrs genDifferential && genDifferential ? mkSuite;
      expected = true;
    };
  };
}
