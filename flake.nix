{
  description = "gen-differential — the comparison machinery for a differential test: a parameterized subject, a seam-routed identity control, and the oracles that keep a green from being vacuous";

  # ★★ THE INPUT SET IS EMPTY, AND THAT ABSENCE IS THIS REPOSITORY'S POINT — the harness argument
  # applied one layer up. An instrument must not drag a substrate into the lock of the thing it
  # measures: a comparison library that pinned a module-system utility set would be pinning
  # something a CANDIDATE might be, and a consumer would then build it twice in one evaluation, once
  # as the instrument's dependency and once as the design under test.
  #
  # It costs nothing, because both arms are arguments. The reference evaluator, the design under
  # test, the substitution seam, the corpus and the observables all arrive at the call site — so
  # there is no substrate left for this flake to declare.
  #
  # The test plane declares what it needs (`./ci`), which no consumer pins.
  inputs = { };

  outputs = _: {
    lib = import ./lib;
  };
}
