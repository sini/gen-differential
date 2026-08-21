# THE CORPUS — the registry shape, and the pure fixtures this library ships.
#
# ★★ WHAT SHIPS HERE IS SYNTHETIC AND PURE, BY RULING, AND THE CONTRACT IS WIDER THAN WHAT SHIPS.
# A domain corpus — real hosts, real templates, a real fleet — is deferred to the instantiation that
# has one, and arrives there as an argument like every other. That distinction is the entire reason
# the comparison is parameterized: deferring the corpus costs no redesign, because the corpus was
# never inside the library to begin with.
#
# ★ AND THE DEFERRAL IS NOT COSMETIC. A library shipping exactly one domain arm would be
# parameterized in the letter and singular in the fact — the very defect this library was
# commissioned to remove, reproduced one level up. Pure fixtures are what keep the parameterization
# honest rather than decorative.
#
# EVERY FIXTURE'S `modules` IS A FUNCTION OF THE ARM'S VOCABULARY. The arm supplies `mkOption`,
# `types`, `mkMerge` and the priority combinators; the fixture is the same source read through
# whichever implementation is being asked. A fixture that closed over one implementation's
# vocabulary would be two programs compared and called one.
{ contract, observables }:
let
  genAttrs =
    names: f:
    builtins.listToAttrs (
      map (n: {
        name = n;
        value = f n;
      }) names
    );
  upto = n: builtins.genList (i: i + 1) n;

  # ── TIERS ────────────────────────────────────────────────────────────────────────────────────
  # The tier names the VOCABULARY an entry needs, and it is read rather than decorative: a
  # candidate that implements the core surface but not the ordering combinators can draw the `core`
  # tier and say so, instead of aborting on a missing attribute halfway through a suite.
  #
  # `core`    — mkOption · types.{str,int,attrsOf,listOf,submodule} · mkMerge · mkOverride ·
  #             mkIf · mkForce · mkDefault
  # `ordered` — core, plus mkOrder · mkBefore · mkAfter
  tiers = [
    "core"
    "ordered"
  ];

  # ── SYNTHETIC ────────────────────────────────────────────────────────────────────────────────
  # A width-and-depth knob over the merge fold: `n` elements of a submodule declaring `ndecls`
  # options, where one option is an mkMerge of `layers` priority contributions — so the fixture
  # exercises the override filter and the definition fold rather than just attribute plumbing.
  synthetic = {
    mk =
      {
        n,
        ndecls,
        layers,
      }:
      contract.mkFixture {
        comparison = "value";
        observables = {
          things = observables.at [
            "config"
            "things"
          ];
          # A second observable over the SAME fixture, because the axis is open and a claim names
          # which member it was measured at. This one sees the declared surface a value comparison
          # cannot: a candidate that computes every value correctly while declaring a different
          # option set agrees at `things` and diverges here.
          shape = observables.withOptionShape {
            base = _: { };
            subOptionPaths.things = [ "things" ];
          };
        };
        modules =
          v:
          let
            optNames = map (i: "o${builtins.toString i}") (upto ndecls);
            sub = v.types.submodule {
              options = genAttrs optNames (
                _:
                v.mkOption {
                  type = v.types.str;
                  default = "";
                }
              );
            };
            elemVal = v.mkMerge (
              map (l: { o1 = v.mkOverride (100 - l) "v${builtins.toString l}"; }) (upto layers)
            );
          in
          [
            {
              options.things = v.mkOption {
                type = v.types.attrsOf sub;
                default = { };
              };
            }
            { config.things = genAttrs (map (e: "e${builtins.toString e}") (upto n)) (_: elemVal); }
          ];
      };
    defaultParams = {
      n = 50;
      ndecls = 20;
      layers = 2;
    };
    comparison = "value";
    tier = "core";
  };

  # ── ARTIFACT ─────────────────────────────────────────────────────────────────────────────────
  # ★ THE `drvPath` KIND IS DEMONSTRABLE WITHOUT A BUILD SYSTEM, and it has to be, because this
  # library ships no package set. The kind reads `.drvPath` off whatever the observable yields; a
  # fixture whose config carries that attribute exercises the kind's whole mechanism — including
  # its refusal branch — over an ordinary string. The domain accessor that yields a real system
  # derivation is exported as a NAMED observable, so a caller with a package set reaches for it by
  # name rather than finding it assumed.
  artifact = {
    mk =
      { tag }:
      contract.mkFixture {
        comparison = "drvPath";
        observables.out = observables.at [
          "config"
          "out"
        ];
        modules = v: [
          {
            options.out = v.mkOption {
              type = v.types.attrsOf v.types.str;
              default = { };
            };
          }
          { config.out.drvPath = "/nix/store/${tag}-fixture.drv"; }
        ];
      };
    defaultParams.tag = "0000000000000000000000000000000";
    comparison = "drvPath";
    tier = "core";
  };

  # ── LANDMINES ────────────────────────────────────────────────────────────────────────────────
  # The merge behaviours a reimplementation is most likely to get subtly wrong, each isolated to one
  # option so a red names the rule rather than a region.
  mkList =
    {
      elemTypeOf,
      defsOf,
    }:
    contract.mkFixture {
      comparison = "value";
      observables.thing = observables.at [
        "config"
        "thing"
      ];
      modules =
        v:
        [
          {
            options.thing = v.mkOption {
              type = v.types.listOf (elemTypeOf v);
              default = [ ];
            };
          }
        ]
        ++ defsOf v;
    };

  landmines = {
    # The priority fold: the winning class takes the option outright, and every lower class is
    # discarded rather than merged. `mkIf false` contributes nothing at all.
    priorityFold = {
      mk =
        _:
        mkList {
          elemTypeOf = v: v.types.str;
          defsOf = v: [
            { config.thing = [ "n" ]; }
            { config.thing = v.mkForce [ "c" ]; }
            { config.thing = v.mkDefault [ "z" ]; }
            { config.thing = v.mkIf false [ "gone" ]; }
            { config.thing = v.mkOrder 10 [ "ord" ]; }
          ];
        };
      defaultParams = { };
      comparison = "value";
      tier = "ordered";
    };

    # Ordering within one priority class: before, then unmarked, then after.
    order = {
      mk =
        _:
        mkList {
          elemTypeOf = v: v.types.str;
          defsOf = v: [
            { config.thing = v.mkAfter [ "last" ]; }
            { config.thing = [ "mid" ]; }
            { config.thing = v.mkBefore [ "first" ]; }
          ];
        };
      defaultParams = { };
      comparison = "value";
      tier = "ordered";
    };

    # ★ THE NON-OBVIOUS ONE, AND THE REASON THE SET EXISTS. Two definitions of a list option at the
    # same priority AND the same order merge in REVERSE declaration order — `[1]` then `[2]` yields
    # `[2 1]`, not `[1 2]`. It was verified empirically across three separate module-system
    # checkouts in the apparatus this fixture comes from. A reimplementation that folds definitions
    # in the order it reads them passes every other cell here and fails this one.
    valueMeta = {
      mk =
        _:
        mkList {
          elemTypeOf = v: v.types.int;
          defsOf = _: [
            { config.thing = [ 1 ]; }
            { config.thing = [ 2 ]; }
          ];
        };
      defaultParams = { };
      comparison = "value";
      tier = "core";
    };

    # Two same-priority overrides of a scalar are a conflict, and a conflict is an ANSWER: both arms
    # must refuse. An implementation that silently picks one is not a stricter reference, it is a
    # different language.
    latticeThrows = {
      mk =
        _:
        contract.mkFixture {
          comparison = "throws";
          observables.n = observables.at [
            "config"
            "n"
          ];
          modules = v: [
            { options.n = v.mkOption { type = v.types.int; }; }
            { config.n = v.mkForce 1; }
            { config.n = v.mkForce 2; }
          ];
        };
      defaultParams = { };
      comparison = "throws";
      tier = "core";
    };
  };

  entries = {
    inherit synthetic artifact;
  }
  // landmines;

  # Every entry, validated through the registry constructor. Reaching the corpus through this
  # attribute rather than the raw literals above is what makes the shape a contract instead of a
  # convention.
  registry = builtins.mapAttrs (_: contract.mkCorpusEntry) entries;

  # Entries a caller's vocabulary can actually run. `core` is a subset of `ordered`, so an arm
  # declaring `ordered` draws everything.
  ofTier =
    tier:
    let
      admits = if tier == "ordered" then tiers else [ "core" ];
    in
    builtins.listToAttrs (
      builtins.concatMap (
        name:
        let
          e = registry.${name};
        in
        if builtins.elem e.tier admits then
          [
            {
              inherit name;
              value = e;
            }
          ]
        else
          [ ]
      ) (builtins.attrNames registry)
    );
in
{
  inherit
    tiers
    registry
    ofTier
    ;
}
