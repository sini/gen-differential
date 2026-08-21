# THE CONTRACT — the four records, each with a required-and-total field set.
#
# ★ EVERY CONSTRUCT NAME IN THIS FILE IS A PLACEHOLDER UNDER A STANDING QUARANTINE. `subject`,
# `reference`, `candidate`, `seam`, `proposition`, `projections`, `comparison` and the divergence
# register are named by the specification of record and NOT by a verified primary. McKeeman 1998
# grounds the MECHANISM (two comparable systems, one input, divergence as the signal) and the
# reference/candidate ASYMMETRY, but grounds none of these identifiers; they resolve at their own
# primaries or as ruled namings, and until then a rename is expected rather than surprising.
#
# ★★ WHY THE FIELDS ARE REQUIRED RATHER THAN DEFAULTED. A missing declaration is a design choice,
# and a defaulted one makes that choice silently. The predecessor apparatus this library replaces
# asserted a CONJUNCTION nobody had written down — that the re-host computes what the reference
# computes, AND that the published grammar had not moved — so it went red on every deliberate
# grammar change and could not say which conjunct a red belonged to. `proposition` is a required
# field for exactly that reason: a red that cannot name its claim reproduces the defect under a new
# name. `projections` is required and total for the same reason one level down — a comparison that
# defaults its compared surface has decided what it measures without saying so.
let
  isNonEmptyString = v: builtins.isString v && v != "";

  refuse = what: why: throw "gen-differential: ${what} — ${why}";

  # ── The comparison kinds, named ONCE ────────────────────────────────────────────────────────
  # compare.nix implements them; this is the membership fact, and a cell asserts the two agree.
  # Stating it here rather than deriving it from the implementation means adding a kind without
  # declaring it is a refusal rather than a silent widening of what a fixture may ask for.
  comparisonKinds = [
    "value"
    "drvPath"
    "throws"
  ];

  # ── (0) THE ARM — an evaluator, treated opaquely ────────────────────────────────────────────
  # Not one of the specification's four records: it is what `reference` and `candidate` ARE, given
  # a name so the two halves of a subject have a shape rather than a convention.
  #
  # `vocab` travels WITH the arm because a module-system implementation supplies its own
  # `mkOption`/`types`/`mkMerge`, and a fixture that closed over one implementation's vocabulary
  # would be running two different sources through two evaluators and calling the result parity.
  # A fixture's `modules` is therefore a function of the arm's vocabulary (see `mkFixture`), which
  # is the shape the ecosystem's own evalModules-equivalence oracle already uses.
  mkArm =
    {
      name,
      vocab,
      eval,
    }:
    if !(isNonEmptyString name) then
      refuse "arm.name" "an arm's name is what a red says moved; it cannot be empty"
    else if !(builtins.isFunction eval) then
      refuse "arm.eval (${name})" "an arm evaluates a request, so `eval` must be a function"
    else if !(builtins.isAttrs vocab) then
      refuse "arm.vocab (${name})" "the vocabulary a fixture's modules are written against must be an attribute set"
    else
      {
        inherit name vocab eval;
      };

  # ── (a) THE SUBJECT — the parameterization, made structural ─────────────────────────────────
  #
  # McKeeman's asymmetry, and it is the paper's own rather than this design's: the analyzer
  # distinguishes "the compiler under test" from "the comparison compilers", and discards a test
  # when a COMPARISON implementation misbehaves, "since reporting the bugs of a comparison compiler
  # is not a testing objective" (McKeeman 1998, DTJ 10(1), printed 105). `reference` and
  # `candidate` are that distinction; they are not symmetric peers.
  #
  # ★ THE SEAM IS A CONTRACT FIELD PRECISELY SO THE IDENTITY CONTROL CANNOT DEGRADE TO `x == x`.
  # A control specified as reference-against-reference is trivially true and cannot be shown to
  # fail, which makes it indistinguishable from `true`. The identity arm here is the REFERENCE'S
  # OWN BODY INSTALLED AT THE CANDIDATE'S SEAM: semantically it is the reference, structurally it
  # travels the candidate's path, so a perturbation of the substitution mechanism moves it.
  mkSubject =
    {
      reference,
      candidate,
      seam,
      proposition,
    }:
    if !(isNonEmptyString proposition) then
      refuse "subject.proposition" "every assertion names the claim it belongs to; an unnamed claim is the conjunction defect"
    else
      {
        inherit
          reference
          candidate
          seam
          proposition
          ;
      };

  # The substitution point. `install` is the consumer's own mechanism — a `lib.extend` re-fixpoint,
  # a vocabulary swap, an evaluator replacement — and the library holds it opaquely. What the
  # library requires is that it be APPLICABLE TO THE REFERENCE'S BODY, because that application is
  # the identity arm and there is no other way to obtain one that is genuinely seedable.
  mkSeam =
    {
      name,
      install,
      referenceBody,
    }:
    if !(isNonEmptyString name) then
      refuse "seam.name" "a seam's name is its identity; two subjects sharing a seam name is a suite with one seam"
    else if !(builtins.isFunction install) then
      refuse "seam.install (${name})" "the seam installs a body and yields an arm, so `install` must be a function"
    else
      {
        inherit name install referenceBody;
      };

  # THE IDENTITY ARM, derived and never supplied. A consumer cannot hand in an identity arm that
  # bypasses the seam, because there is no field to hand it in through.
  identityArm = subject: subject.seam.install subject.seam.referenceBody;

  # The three arms a subject denotes. `reference` is the bare reference — it does NOT travel the
  # seam; `identity` is the same body that does. The pair is what makes "routing through the seam
  # changes nothing" an assertable proposition rather than an assumption.
  armsOf = subject: {
    inherit (subject) reference candidate;
    identity = identityArm subject;
  };

  # ── (b) THE FIXTURE — what to evaluate, and what to compare it at ───────────────────────────
  mkFixture =
    {
      modules,
      projections,
      comparison,
      specialArgs ? { },
      class ? null,
      rung ? null,
    }:
    if !(builtins.isFunction modules) then
      refuse "fixture.modules" "a fixture's modules are a function of the arm's vocabulary, so both arms run the same source"
    else if !(builtins.isAttrs projections) || projections == { } then
      refuse "fixture.projections" "the projection set is required and total; an empty set compares nothing and reads green"
    else if !(builtins.elem comparison comparisonKinds) then
      refuse "fixture.comparison" "`${builtins.toString comparison}' is not one of ${builtins.concatStringsSep ", " comparisonKinds}"
    else
      {
        inherit
          modules
          projections
          comparison
          specialArgs
          class
          rung
          ;
      };

  # ── (c) THE CORPUS ENTRY — the registry shape, adopted rather than redesigned ────────────────
  #
  # `defaultParams` stays because CONSTRUCTION-TIME ARGUMENTS AND COMPARISON METADATA ARE DIFFERENT
  # AXES and a registry has to state both: an entry whose `mk` needs an argument the registry
  # cannot supply still has a comparison kind, and an entry that derives its kind from `mk {}` still
  # has construction parameters.
  #
  # ★ PRECEDENCE, STATED RATHER THAN LEFT TO BE RE-DERIVED: the kind appears on both the fixture and
  # the entry, and THE FIXTURE GOVERNS. The entry's `gate` is metadata for a caller assembling a
  # suite — it says what the entry will produce without constructing it — and the constructed
  # fixture's `comparison` is what a comparison actually reads. The field keeps the registry's own
  # name (`gate`) rather than the fixture's, so the two are never mistaken for one value in two
  # places.
  mkCorpusEntry =
    {
      mk,
      defaultParams,
      gate,
      tier,
    }:
    if !(builtins.isFunction mk) then
      refuse "corpusEntry.mk" "an entry constructs a fixture from parameters, so `mk` is a function"
    else if !(builtins.isAttrs defaultParams) then
      refuse "corpusEntry.defaultParams" "construction parameters are an attribute set, possibly empty"
    else if !(builtins.elem gate comparisonKinds) then
      refuse "corpusEntry.gate" "`${builtins.toString gate}' is not one of ${builtins.concatStringsSep ", " comparisonKinds}"
    else if !(isNonEmptyString tier) then
      refuse "corpusEntry.tier" "a tier names which suites may draw the entry; it cannot be empty"
    else
      {
        inherit
          mk
          defaultParams
          gate
          tier
          ;
      };

  # Construct an entry's fixture, entry defaults under caller overrides.
  instantiate = entry: params: entry.mk (entry.defaultParams // params);
in
{
  inherit
    comparisonKinds
    mkArm
    mkSubject
    mkSeam
    identityArm
    armsOf
    mkFixture
    mkCorpusEntry
    instantiate
    ;
}
