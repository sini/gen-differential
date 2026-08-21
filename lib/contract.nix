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

  # ── THE SHAPE PREDICATES — stated ONCE, applied at BOTH boundaries ──────────────────────────
  #
  # ★★★ THIS IS A CLASS, AND IT IS DISCHARGED AT THE CLASS RATHER THAN AT ONE INSTANCE.
  # `builtins.tryEval` catches thrown errors and failed assertions and NOT a type or missing-
  # attribute error, so a malformed record that reaches a selection or an application aborts the
  # WHOLE evaluation instead of reddening a cell. This library already met that class once, at the
  # `drvPath` comparison kind, and fixing it there left the identical hole at the contract's own
  # entry point: a subject built with `seam = null` was ACCEPTED, and the failure surfaced later as
  # `expected a set but found null` — propagating straight out of `tryEval`, taking the gate down.
  #
  # The fix is not another guard at another call site. It is ONE statement of what an arm and a seam
  # ARE, applied both where they are constructed and where they are accepted. A record that reaches
  # `identityArm` has been shape-checked whether the consumer used `mkArm`/`mkSeam` or hand-rolled
  # it — and a hand-rolled one is exactly what the README's quick start invites.
  #
  # ★ THE LIMIT, STATED SO IT IS NOT MISTAKEN FOR MORE: this checks SHAPE, never PROVENANCE. It
  # establishes that the fields exist and are the right kind of thing, so a downstream selection or
  # application cannot abort uncatchably. It cannot establish that `install` installs anything, and
  # nothing here pretends to.
  armProblem =
    v:
    if !(builtins.isAttrs v) then
      {
        field = "";
        why = "an arm is the record `mkArm' builds; a ${builtins.typeOf v} cannot be evaluated through";
      }
    else if !((v ? name) && isNonEmptyString v.name) then
      {
        field = ".name";
        why = "an arm's name is what a red says moved; it cannot be missing or empty";
      }
    else if !((v ? vocab) && builtins.isAttrs v.vocab) then
      {
        field = ".vocab";
        why = "the vocabulary a fixture's modules are written against must be an attribute set";
      }
    else if !((v ? eval) && builtins.isFunction v.eval) then
      {
        field = ".eval";
        why = "an arm evaluates a request, so `eval' must be a function";
      }
    else
      null;

  seamProblem =
    v:
    if !(builtins.isAttrs v) then
      {
        field = "";
        why = "a seam is the record `mkSeam' builds; a ${builtins.typeOf v} has no substitution point to install at";
      }
    else if !((v ? name) && isNonEmptyString v.name) then
      {
        field = ".name";
        why = "a seam's name is its identity; two subjects sharing a seam name is a suite with one seam";
      }
    else if !((v ? install) && builtins.isFunction v.install) then
      {
        field = ".install";
        why = "the seam installs a body and yields an arm, so `install' must be a function";
      }
    else if !(v ? referenceBody) then
      {
        field = ".referenceBody";
        why = "the identity arm IS `install referenceBody'; without the reference's body there is no control to derive";
      }
    else
      null;

  # `where` names the role the record is filling, so one predicate yields `arm.eval` at construction
  # and `subject.candidate.eval` at acceptance — the same defect, reported where the reader is.
  checkShape =
    problem: where: v:
    let
      p = problem v;
    in
    if p == null then v else refuse "${where}${p.field}" p.why;

  checkArm = checkShape armProblem;
  checkSeam = checkShape seamProblem;

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
    checkArm "arm" {
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
    let
      # ★ ACCEPTANCE IS A BOUNDARY, NOT A FORMALITY. The same predicates the constructors apply,
      # re-applied where records are ACCEPTED — because a subject can be assembled from records
      # this library never built, and a hand-rolled one is exactly what the quick start invites.
      #
      # ★★ AND THE REFUSAL IS EAGER, WHICH IS THE WHOLE POINT. Written as attribute values the
      # checks would fire only when the field is read, so `mkSubject` would return a record that
      # looks accepted and aborts later — the same "looks fine until touched" shape as the defect
      # being closed. Forcing the list in the condition below refuses at construction, like every
      # other constructor in this file.
      problems = builtins.filter (x: x.p != null) [
        {
          where = "subject.seam";
          p = seamProblem seam;
        }
        {
          where = "subject.reference";
          p = armProblem reference;
        }
        {
          where = "subject.candidate";
          p = armProblem candidate;
        }
      ];
    in
    if !(isNonEmptyString proposition) then
      refuse "subject.proposition" "every assertion names the claim it belongs to; an unnamed claim is the conjunction defect"
    else if problems != [ ] then
      let
        f = builtins.head problems;
      in
      refuse "${f.where}${f.p.field}" f.p.why
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
    checkSeam "seam" {
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
  # the entry under ONE name, and THE FIXTURE GOVERNS. The entry's `comparison` is the declared
  # default — it says what the entry will produce without constructing it — and the constructed
  # fixture's `comparison` is what a comparison actually reads.
  #
  # ★★ THE SHARED NAME IS SAFE BY CONSTRUCTION RATHER THAN BY CONVENTION, which is why the entry no
  # longer spells it differently to protect the precedence. Nothing on the comparison path reads the
  # entry's field at all: a claim selects `fixture.comparison`, and an entry reaches a comparison
  # only through `instantiate`, which yields a fixture. The entry's copy is therefore unreachable
  # from a cell, so the two could not be mistaken for one value in two places even by a reader who
  # wanted to — and a second name to guard a precedence the code already enforces earns nothing.
  mkCorpusEntry =
    {
      mk,
      defaultParams,
      comparison,
      tier,
    }:
    if !(builtins.isFunction mk) then
      refuse "corpusEntry.mk" "an entry constructs a fixture from parameters, so `mk` is a function"
    else if !(builtins.isAttrs defaultParams) then
      refuse "corpusEntry.defaultParams" "construction parameters are an attribute set, possibly empty"
    else if !(builtins.elem comparison comparisonKinds) then
      refuse "corpusEntry.comparison" "`${builtins.toString comparison}' is not one of ${builtins.concatStringsSep ", " comparisonKinds}"
    else if !(isNonEmptyString tier) then
      refuse "corpusEntry.tier" "a tier names which suites may draw the entry; it cannot be empty"
    else
      {
        inherit
          mk
          defaultParams
          comparison
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
