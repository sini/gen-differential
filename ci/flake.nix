{
  inputs = {
    # The subject. `../lib` is dependency-free, so this is the only edge that carries it.
    root.url = "path:..";

    gen-harness.url = "github:sini/gen-harness";

    # nixpkgs enters HERE AND ONLY HERE — the test plane. It is the REFERENCE ARM of this
    # repository's own subjects and the runner's dependency (nix-unit, treefmt); the library itself
    # (../lib) has no inputs at all and `tests/purity.nix` is the oracle for that.
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";

    # THE FIRST CONSUMER, pinned on the test plane rather than by the library. The dependency points
    # SUBJECT → INSTRUMENT in production: a consumer pins the harness and runs the differential in
    # its own CI. Here the arrow is reversed once, deliberately, so this repository can demonstrate
    # the instantiation it specifies without waiting for the consumer to adopt it — and it is
    # reversed on the plane no consumer pins, so nothing downstream inherits the edge.
    gen-merge.url = "github:sini/gen-merge";
  };

  outputs =
    inputs@{
      root,
      gen-harness,
      gen-merge,
      ...
    }:
    gen-harness.lib.mkCi {
      inherit inputs;
      name = "gen-differential";
      testModules = ./tests;
      specialArgs = {
        genDifferential = root.lib;
        genMerge = gen-merge.lib;

        # ★ ONE BINDING FOR THE REFERENCE ARM, AND HERE THAT IS LOAD-BEARING RATHER THAN TIDY. The
        # seam re-imports the reference's own module SOURCE against a re-extended fixpoint, so it
        # needs the path AND the built value to come from the same tree. The `lib` a flake-parts
        # module receives is flake-parts' `nixpkgs-lib`, which is a DIFFERENT tree from this
        # flake's `nixpkgs` — installing one's module body into the other's fixpoint compares two
        # module systems while claiming to compare one with itself.
        nixpkgsSrc = inputs.nixpkgs;
        nixpkgsLib = inputs.nixpkgs.lib;
      };
      # Cells whose `expr` ABORTS by design — the contract's named refusals. The batch asserter
      # behind `checks.default` forces every `expr` under `flake.tests`, so a refusal asserted there
      # would crash the gate instead of failing a cell. A contract whose refusals cannot be tested
      # for their own firing is a contract that refuses on paper.
      extraModules = [ ./tests-error.nix ];
    };
}
