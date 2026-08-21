# gen-differential — the comparison MACHINERY for a differential test.
#
# "Differential testing requires that two or more comparable systems be available to the tester"
# (W. M. McKeeman, *Differential Testing for Software*, Digital Technical Journal 10(1), 1998,
# pp. 100–107). Two comparable systems, one input, divergence as the signal — and the paper's own
# asymmetry between the implementation under test and the comparison implementation, which is this
# library's `candidate` and `reference`.
#
# ★ THE CITATION'S NARROWING IS RECORDED RATHER THAN GLOSSED. McKeeman's genus clause binds the term
# to random testing over MECHANICALLY GENERATED inputs; this library's inputs are curated fixtures.
# The paper's own counterweight — it applies the term to "ad hoc differential testers" and to
# "testing systems that are less elaborate" — is why the narrowing is an interval rather than a
# mismatch. A generated-input arm, with test reduction as its natural companion, is recorded future
# work and is the condition under which the narrowing retires.
#
# ★★ WHAT THIS LIBRARY IS AND IS NOT. It is the machinery: the parameterized subject, the
# seam-routed identity control, the required claim, the observable set, the divergence
# register, and the oracles that keep a green from being vacuous. It is NOT an instantiation. A
# green here says the machinery works; it does not say any particular design agrees with any
# particular reference, because both arms arrive as arguments and this library ships neither.
#
# ── NO DEPENDENCIES, AND THE ABSENCE IS THE POINT ────────────────────────────────────────────────
# The whole library is written in `builtins`. A consumer pinning it gains exactly one node: an
# instrument must not drag a substrate into the lock of the thing it measures, and a library that
# pinned a module-system utility set would be pinning something a candidate might BE. Both arms
# arrive as arguments, so there is nothing left for a substrate to supply.
#
# Convention §8 (a file is a function IFF it has dependencies) therefore makes this file a bare
# value: `import ./lib`, never `import ./lib { }`.
let
  diff = import ./diff.nix;
  contract = import ./contract.nix;
  register = import ./register.nix;
  observables = import ./observables.nix;
  compare = import ./compare.nix { inherit contract diff register; };
  suite = import ./suite.nix { inherit contract observables; };
  oracles = import ./oracles.nix { inherit compare diff; };
in
{
  # The five concerns, reachable as namespaces.
  inherit
    diff
    contract
    compare
    register
    suite
    observables
    oracles
    ;

  # THE NEGATIVE RESULT THIS LIBRARY CARRIES. Not machinery — a finding, kept where the machinery
  # is, because this is what a future eval-sharing shortcut would be built against. Its four results
  # and the scope correction that bounds them are fields of one record and cannot be separated.
  sharingNoGo = import ./no-go.nix;

  # ── THE SURFACE MOST CONSUMERS REACH FOR ────────────────────────────────────────────────────
  # Promoted to the top level because they are the contract's entry points, and a constructor a
  # consumer has to go looking for is one they will hand-roll instead.
  inherit (contract)
    mkArm
    mkSeam
    mkSubject
    mkFixture
    mkSuiteEntry
    ;
  inherit (compare) mkRun;
}
