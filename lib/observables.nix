# OBSERVABLES — the function from an evaluation result to the compared value.
#
# ★★ THE OBSERVABLE AXIS IS OPEN, AND THAT IS A MEASURED FACT RATHER THAN A GUESS. The apparatus
# this library is extracted from offered two surfaces (the config tree, and a NixOS toplevel
# derivation path). A completed probe in the same project compared at FIVE — delivery structure,
# aspect closure, settings provenance, class producers, corpus ingest — and explicitly demoted the
# derivation path, recording that it is terminal rather than the bar. So a contract fixed at two
# observables would already be narrower than a differential this project has run. The fixture
# therefore carries an observable SET, and every claim names which member it was measured at.
#
# ★ NOTHING HERE IS A DEFAULT. These are named, exported values a caller reaches for by name. The
# NixOS toplevel accessor in particular is a domain coordinate, not a general one — it was the one
# place the source apparatus's domain leaked into its otherwise domain-free half, and exporting it
# as a named value rather than burying it in the comparison is what stops that leak recurring.
#
# Dependency-free.
let
  refuse = what: why: throw "gen-differential: ${what} — ${why}";

  # An attribute-path accessor. Refuses at the first missing component and names it, because an
  # observable that quietly yields `null` for a coordinate that is not there compares two absences
  # and reports agreement.
  at =
    path: result:
    builtins.foldl' (
      acc: k:
      if builtins.isAttrs acc && acc ? ${k} then
        acc.${k}
      else
        refuse "observable `at'" "no attribute `${k}' at ${builtins.concatStringsSep "." path}"
    ) result path;

  # The evaluated configuration tree. The ordinary structural surface.
  config = at [ "config" ];

  # The NixOS system derivation. Paired with the `drvPath` comparison kind, which reads `.drvPath`
  # off whatever the observable yields.
  nixosToplevel = at [
    "config"
    "system"
    "build"
    "toplevel"
  ];

  # The declared OPTION SURFACE rather than the values — the shape of what was declared, which a
  # value comparison cannot see.
  #
  # ★★ THE `_module` FILTER IS PART OF THIS OBSERVABLE'S DECLARED MEANING, NOT A TIDY-UP, AND IT IS
  # A REAL NARROWING. `_module` is the reference module system's own synthetic pseudo-option; an
  # implementation that does not publish it is not thereby divergent, so comparing it would redden a
  # cell for a difference no claim here covers. Filtering is the right default — and it means
  # **a candidate that wrongly emitted a `_module`-shaped option is invisible at this observable.**
  # That is exactly the kind of buried assumption the observable layer exists to surface, so the
  # unfiltered surface is exported beside it: a caller who needs to see the pseudo-option reaches
  # for `rawOptionNames` BY NAME, and nobody has to defeat a filter they cannot see.
  dropModule = builtins.filter (n: n != "_module");

  rawOptionNames = result: builtins.attrNames result.options;

  optionNames = result: dropModule (rawOptionNames result);

  # Augment a base observable with option-shape data, so one comparison can assert values AND the
  # declared surface they came from. `subOptionPaths` maps an option name to the location list its
  # type's sub-options are read at.
  withOptionShape =
    {
      base,
      options ? null,
      subOptionPaths ? { },
    }:
    result:
    (base result)
    // {
      __optionNames = if options != null then options else optionNames result;
      __subOptions = builtins.mapAttrs (
        opt: loc: dropModule (builtins.attrNames (result.options.${opt}.type.getSubOptions loc))
      ) subOptionPaths;
    };
in
{
  inherit
    at
    config
    nixosToplevel
    optionNames
    rawOptionNames
    withOptionShape
    ;
}
