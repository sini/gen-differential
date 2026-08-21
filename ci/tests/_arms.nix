# The arms, the seam, and the subject this repository's own suites are taken on.
#
# Underscore-prefixed, so `import-tree` does not read it as a flake-parts module: it is a shared
# definition the suites import, not a suite.
#
# ★ THE REFERENCE IS AN ARGUMENT HERE TOO. nixpkgs is this plane's reference because the plane
# chose it, not because the library knows about it — `../lib` has no inputs and no nixpkgs token.
# Swapping this file's reference for another module-system implementation re-instantiates every
# suite below it without touching the library.
#
# ★★ IT TAKES `nixpkgsLib` RATHER THAN THE MODULE ARGUMENT `lib`, AND THE DIFFERENCE IS THE WHOLE
# SUBJECT. A flake-parts module's `lib` comes from flake-parts' own `nixpkgs-lib` input — a
# DIFFERENT tree from this flake's `nixpkgs`. The seam re-imports the reference's module SOURCE
# into the reference's own fixpoint; sourcing the path from one tree and the fixpoint from another
# makes the identity arm a comparison of two module systems while its name claims it is one system
# with itself. Measured: that mismatch put the seeded arm into infinite recursion, which is the
# loud form of the failure — the quiet form would have been a green.
{
  nixpkgsLib,
  nixpkgsSrc,
  genDifferential,
}:
let
  gd = genDifferential;

  # The vocabulary a fixture's `modules` function is applied to. Both arms of a subject supply
  # their own, which is what lets one fixture source run through two implementations.
  vocabOf = l: {
    inherit (l)
      mkOption
      mkMerge
      mkOverride
      mkIf
      mkForce
      mkDefault
      mkOrder
      mkBefore
      mkAfter
      types
      ;
  };

  armOf =
    name: l:
    gd.mkArm {
      inherit name;
      vocab = vocabOf l;
      eval = l.evalModules;
    };

  # THE REFERENCE ARM — the bare implementation. It does NOT travel the seam, which is exactly what
  # makes the identity arm a claim about the seam rather than a tautology.
  reference = armOf "nixpkgs" nixpkgsLib;

  # ── THE SEAM ─────────────────────────────────────────────────────────────────────────────────
  #
  # A `lib.extend` re-fixpoint that replaces the module-system body. Overriding `modules` ALONE
  # suffices: the utility set re-exports its whole module surface from that attribute through the
  # fixpoint, so evalModules, the priority combinators and the type constructors all resolve to the
  # installed body. `types` is re-fixpointed against `final`, so submodule re-entry stays inside the
  # installed body too.
  #
  # This is real work, and that is the point — a seam that did nothing could not be seeded.
  install =
    body:
    let
      elib = nixpkgsLib.extend (final: prev: { modules = body.overlay final prev; });
    in
    armOf body.name elib;

  # THE REFERENCE'S OWN BODY. Installing it is the IDENTITY ARM: semantically the reference,
  # structurally the candidate's path.
  referenceBody = {
    name = "reference-body@seam";
    overlay = _final: prev: prev.modules // { evalModules = a: prev.modules.evalModules a; };
  };

  # THE CANDIDATE'S BODY — the reference's module source re-imported against the extended fixpoint.
  # A re-host rather than a rewrite, which is the smallest candidate that is genuinely a candidate:
  # it must produce the same values through a different fixpoint, and it would not if the extension
  # mechanism were wrong about how the module surface is reached.
  rehostBody = {
    name = "rehosted-module-body@seam";
    overlay = final: _prev: import "${nixpkgsSrc}/lib/modules.nix" { lib = final; };
  };

  seam = gd.mkSeam {
    name = "lib-extend-module-body";
    inherit install referenceBody;
  };

  subject = gd.mkSubject {
    inherit reference seam;
    candidate = install rehostBody;
    claim = "P1 · the module body re-imported against an extended utility fixpoint computes what the reference computes";
  };

  # ── FIXTURES ─────────────────────────────────────────────────────────────────────────────────
  # The registry's declared defaults are the apparatus's; the suite instantiates smaller so a full
  # run stays a test rather than a benchmark. That the two can differ is what `defaultParams` is
  # for — construction arguments and comparison metadata are different axes.
  entry = name: params: gd.contract.instantiate gd.corpus.registry.${name} params;

  fixtures = {
    synthetic = entry "synthetic" {
      n = 6;
      ndecls = 4;
      layers = 2;
    };
    artifact = entry "artifact" { };
    priorityFold = entry "priorityFold" { };
    order = entry "order" { };
    valueMeta = entry "valueMeta" { };
    latticeThrows = entry "latticeThrows" { };
  };

  suite = gd.mkSuite { inherit subject fixtures; };
in
{
  inherit
    vocabOf
    armOf
    reference
    install
    referenceBody
    rehostBody
    seam
    subject
    entry
    fixtures
    suite
    ;
}
