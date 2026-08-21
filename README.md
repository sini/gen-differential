# gen-differential — comparison machinery for a differential test

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![Sponsor](https://img.shields.io/badge/Sponsor-%E2%9D%A4-pink?logo=github)](https://github.com/sponsors/sini)

> "Differential testing requires that two or more comparable systems be available to the tester."
> — W. M. McKeeman, *Differential Testing for Software*, Digital Technical Journal **10**(1), 1998, pp. 100–107

`gen-differential` is the machinery for asserting that two implementations agree: a parameterized
**subject**, a **seam-routed identity control**, a required **proposition** on every claim, a
**projection set** per fixture, a **divergence register** that asserts rather than mutes, and the
**oracles** that keep a green from being vacuous.

It is *not* an instantiation. Both arms of every comparison arrive as arguments, so a green here says
the machinery works — never that any particular design agrees with any particular reference.

## Table of contents

- [Why an external reference at all](#why-an-external-reference-at-all)
- [The contract](#the-contract)
- [Quick start](#quick-start)
- [Comparison kinds](#comparison-kinds)
- [Projections](#projections)
- [The divergence register](#the-divergence-register)
- [The oracles](#the-oracles)
- [The corpus](#the-corpus)
- [The cross-scope sharing NO-GO](#the-cross-scope-sharing-no-go)
- [Dependencies](#dependencies)
- [Testing](#testing)
- [What a green does not discharge](#what-a-green-does-not-discharge)
- [Theoretical foundations](#theoretical-foundations)

## Why an external reference at all

This is the load-bearing asymmetry, and it is the reason the library exists.

A claim about an implementation's **internal correctness** is provable against that implementation's
own suites. A claim that it **agrees with an external interface** is not — because the external
interface is not yours to define. Every parity-shaped instrument that compares a system against
*itself* (an optimization against its own unoptimized path, a warm evaluation against a cold one)
answers a different question, however similar the shape. Same shape, different proposition.

McKeeman's framing is comparison-as-oracle: divergence between comparable implementations on the
same input is the bug signal, substituting for a priori knowledge of the right answer. The section
that introduces it is headed *Seeking an Oracle*.

## The contract

Four records, each with a required-and-total field set. **A missing declaration is a design choice**,
so nothing here is defaulted into existence.

### The subject

```nix
subject = {
  reference;    # REQUIRED — the arm the claim is measured against
  candidate;    # REQUIRED — the design under test
  seam;         # REQUIRED — the substitution point at which candidate replaces reference
  proposition;  # REQUIRED — the named claim this pairing asserts
}
```

`reference` and `candidate` are **not symmetric peers**. The asymmetry is McKeeman's own: his test
analyzer distinguishes the implementation under test from the *comparison* implementations, and
discards a test when a comparison implementation misbehaves, "since reporting the bugs of a
comparison compiler is not a testing objective".

**`proposition` is required because a red that cannot name its claim is the defect that retires
parity harnesses.** The predecessor of this library silently asserted a conjunction — that the
re-host computes what the reference computes, *and* that the published grammar had not moved — with
its reference side frozen so it could never follow. It went red on every deliberate grammar change
and could not say which conjunct a red belonged to.

### The seam, and why the identity control is not `x == x`

```nix
seam = {
  name;           # REQUIRED — the seam's identity; two subjects sharing one are one subject twice
  install;        # REQUIRED — body -> arm; the consumer's own substitution mechanism
  referenceBody;  # REQUIRED — the reference's own body, for the identity arm
}
```

The identity arm is **derived, never supplied**:

```nix
identityArm = subject: subject.seam.install subject.seam.referenceBody;
```

A control specified as reference-against-reference is `x == x`: trivially true, unseedable, and
indistinguishable from `true`. The identity arm here is *the reference's own body installed at the
candidate's seam* — semantically the reference, structurally travelling the candidate's path. That
is what makes a seeded perturbation of the substitution mechanism able to move it.

`mkSuite` emits **both arms** for every fixture. There is no entry point that yields the candidate
comparison alone, because an identity control a consumer may decline to call is one that will be
declined.

### The fixture

```nix
fixture = {
  modules;                    # REQUIRED — a FUNCTION of the arm's vocabulary
  projections;                # REQUIRED, total, a SET — never defaulted
  comparison;                 # REQUIRED — one of the comparison kinds
  specialArgs ? { };
  class ? null;
  rung ? null;                # the ladder coordinate — carried, unexercised here
}
```

**`modules` is a function of the arm's vocabulary**, so both arms run the *same source* against
their own `mkOption` / `types` / `mkMerge`. A fixture closed over one implementation's vocabulary
would be two programs compared and called one.

### The corpus entry

```nix
corpusEntry = { mk; defaultParams; gate; tier; }
```

Construction-time arguments and comparison metadata are **different axes**, and the registry states
both. The comparison kind appears on the fixture *and* on the entry; **the fixture governs**, and the
entry's copy is metadata for a caller assembling a suite. The field keeps the registry's own name
(`gate`) so the two are never mistaken for one value in two places.

## Quick start

```nix
let
  gd = inputs.gen-differential.lib;

  # An arm is an evaluator plus the vocabulary its fixtures are written against.
  mkArmFor = name: l: gd.mkArm {
    inherit name;
    vocab = { inherit (l) mkOption mkMerge mkOverride mkIf mkForce mkDefault types; };
    eval = l.evalModules;
  };

  subject = gd.mkSubject {
    proposition = "P1 · the engine computes what the reference computes on the shared grammar";
    reference   = mkArmFor "reference" referenceLib;
    candidate   = install candidateImpl;
    seam        = gd.mkSeam {
      name = "module-system-surface";
      inherit install;
      referenceBody = referenceImpl;
    };
  };

  suite = gd.mkSuite {
    inherit subject;
    fixtures = builtins.mapAttrs (_: e: gd.contract.instantiate e { }) (gd.corpus.ofTier "core");
  };
in
  suite.green            # the verdict
```

Every cell in `suite.cells.<fixture>.<projection>` carries both `identity` and `candidate` claims.

## Comparison kinds

| Kind      | Asserts         | Notes                                                                  |
| --------- | --------------- | ---------------------------------------------------------------------- |
| `value`   | **equivalence** | Structural equality of the projection, with first-divergence location. |
| `drvPath` | **identity**    | Derivation-path identity of the projection.                            |
| `throws`  | **refusal**     | Both arms must decline.                                                |

**`drvPath` identity is sufficient, never necessary.** Byte identity is asserted only where it is
free; end-result equivalence is the bar. And the honest ceiling on the other side of the same coin:
*derivation-path equality proves output shareability, not that evaluation work was shared* — a strong
witness in one direction and mute in the other. Every claim carries an `assertion` field so a cell
that asserted identity cannot be read as having asserted equivalence.

**Two scope limits are stated at the kinds rather than in a footnote.** `throws` reads the
`tryEval`-catchable subclass of refusal — thrown errors and failed assertions, not every abort class.
And it asserts **mutual refusal, not a shared cause**: two arms that decline for entirely unrelated
reasons satisfy it, because a refusal reading yields a boolean and nothing else.

**The three kinds are not a closed set**, for the same reason the projection axis is open.

## Projections

A projection is the function from an evaluation result to the compared value. It is **required and
total** — never defaulted to the configuration tree — and every claim names which projection it was
measured at.

The axis takes more than two members, and that is measured rather than assumed: a completed probe in
this project compared at five surfaces and explicitly demoted the derivation path as terminal rather
than the bar. So a fixture carries a projection **set**.

```nix
gd.projections.at [ "config" "things" ]   # an attribute-path accessor; refuses at a missing component
gd.projections.config                     # the configuration tree
gd.projections.nixosToplevel              # the NixOS system derivation — a NAMED export, never a default
gd.projections.withOptionShape { ... }    # the declared option surface, which a value comparison cannot see
```

`nixosToplevel` is exported by name precisely because it is a domain coordinate rather than a general
one — that accessor buried inside a comparison was the one place the source apparatus's domain leaked
into its otherwise domain-free half.

**The first-divergence coordinate is relative to the projection**, not to the evaluation result: the
walk starts where the projection ended.

## The divergence register

A deliberate, ruled change to the shared grammar is expressible as a **named divergence**, not a red.
McKeeman names the same problem as differential testing's second issue: results may differ and still
both be correct.

```nix
gd.register.mkEntry           { path; values = { reference; candidate; }; ruling; }
gd.register.mkCoordinateEntry { path; ruling; valuesUnpinned; }
gd.register.mkRename          { from; to; ruling; }
```

**An entry is an assertion, not a mute.** It states that a named divergence *occurs*; if it stops
occurring, or occurs differently, the entry goes **red**. Applying a register returns three things
and all three are assertable: divergences no entry covers, entries no divergence satisfied, and the
matched pairs. That second one is what stops a register decaying into a suppression list.

**Every entry carries its ruling.** A divergence without an authorization is a bug someone has grown
used to; requiring the field is what keeps the two apart.

A **coordinate-only** entry registers any divergence at one path. It keeps both teeth, but does not
pin what the two sides produce — so it must state *why*, at the entry. A weakening nobody has to
justify is one everybody takes.

**The register applies to the candidate arm only.** An entry authorizes a difference between the
reference and the design under test; the identity arm must agree with the reference outright.

## The oracles

Shipped as library surface, not as this repository's private test helpers — a consumer's suite is
where the vacuity will actually appear.

| Oracle                                                     | Refuses                                                               |
| ---------------------------------------------------------- | --------------------------------------------------------------------- |
| `floor { suite; teeth; }`                                  | The three coverage-floor keys, asserted individually and in a rollup. |
| `mutationTeeth { arm; fixture; projectionName; perturb; }` | A comparison that is measuring a constant.                            |
| `inputConsumption { inputs; perturb; cells; }`             | A declared input **no cell reads at all**.                            |
| `distinctSubjects [ … ]`                                   | One subject, or two sharing a seam.                                   |
| `explain claim`                                            | A red that cannot be attributed without inside knowledge.             |

**`both-evaluated` and `inputConsumption` catch different vacuities**, which is why the floor does not
subsume the second. The first catches two arms agreeing *through a shared refusal*. The second
catches a declared input nothing forces — a suite can pass every anti-vacuity key while every fixture
ignores the corpus it declares. That is not hypothetical: in a frozen apparatus in this project a
corpus was passed into a suite's arguments and zero cells consumed it, so a full green was a genuine
no-regression signal for the harness and said nothing whatever about the corpus.

Consumption is demonstrated **by perturbation**, never by a syntactic reachability reading: an input
is consumed when moving it moves a cell. "Is it mentioned" passes for a mention nothing forces.

## The corpus

Synthetic and pure. `synthetic` (a width-and-depth knob over the merge fold), `artifact` (a
derivation-shaped value, so the `drvPath` kind is demonstrable without a package set), and four
landmines — the merge behaviours a reimplementation is most likely to get subtly wrong, each isolated
to one option so a red names the rule rather than a region.

Every entry declares the vocabulary **tier** it needs (`core`, or `ordered` for the ordering
combinators). `gd.corpus.ofTier` is how a candidate with a smaller published surface takes the
fixtures it can actually run, instead of aborting on a missing attribute halfway through a suite.

**The contract takes every tier; what ships is narrower than what the API can express.** That
distinction is the whole point of parameterizing the comparison, and it is why a domain corpus costs
no redesign to add later.

## The cross-scope sharing NO-GO

`lib.sharingNoGo` carries a rigorous negative result about pure-Nix cross-scope evaluation-result
sharing, refuted across two adversarial workflows on four load-bearing claims. It lives here because
this is the library any future evaluation-sharing shortcut would be built against.

**The four results and the scope correction that bounds them are fields of one record, and that is
the design.** The NO-GO is *not* a blanket ceiling: it applies to per-element sentinel **discovery**,
and the lever is **declaring** the host-class boundary rather than discovering it — at fleet scale
the sign flips positive. Copying the results without that paragraph would license the false inference
that a class-declared boundary is unsound, which inverts the finding. A reader cannot import the
results and leave the correction behind, because there is nothing to import them out of.

## Dependencies

**None.** The flake declares no inputs and the whole library is written in `builtins`.

That absence is the point, and it is the test-harness argument applied one layer up: an instrument
must not drag a substrate into the lock of the thing it measures. A comparison library that pinned a
module-system utility set would be pinning something a **candidate might be**, and a consumer would
then build it twice in one evaluation — once as the instrument's dependency and once as the design
under test. It costs nothing, because both arms are arguments.

Consumers reach this library by direct input. It is deliberately **off-roster**: an instrument is not
pinned by what it measures.

The root `default.nix` and the flake's `lib` output are the same expression, so the two entry points
cannot drift.

## Testing

```bash
nix-unit --flake ./ci#tests        # the suites
nix-unit --flake ./ci#testsError   # the contract's refusals
```

The refusals live on a **second output** because the batch asserter behind `checks.default` forces
every `expr` under `flake.tests` unconditionally — a cell asserting a refusal there would crash the
gate rather than fail. A contract whose refusals cannot be tested for their own firing is a contract
that refuses on paper.

**Every guard in this repository carries a permanent seeded control**, not a demonstration that was
run once and removed. The identity control is perturbed and its exact red partition asserted; the
subject guard is handed a one-subject roster and a two-subject roster sharing a seam; the register is
handed a divergence that stopped occurring; the consumption oracle is handed a declared input nothing
reads; the purity scan is asked for a token that is present and one that is not. A guard whose teeth
are proven once and then deleted is a guard whose teeth are a historical claim.

## What a green does not discharge

Stated as obligations, so silence is not read as settlement.

- **The fourth coverage-floor key.** Three of four are met here. The fourth — that a real,
  domain-shaped tree flattens identically through both grammars — is a property of a domain corpus
  and is owed by the instantiation that has one.
- **Agreement with an external module system in general.** The machinery that makes that assertable
  lands here; the assertion is made at an instantiation with a real corpus.
- **The rung differential.** The `rung` coordinate ships in the contract and is deliberately
  **unexercised**: the coordinate must exist for a ladder to be instantiated without re-opening the
  contract, and there is no domain rung here to exercise it against. It is the one declared input
  this library does not consume, and it is declared rather than silent for exactly that reason.
- **The register's two ruled entries as live assertions.** The `cnf.classes` → `cnf.keySemantics`
  rename and A-IDENT's path identity ship as **data with their rulings**, not as assertions: no
  grammar carrying those coordinates ships here, and inventing one would assert what no primary
  states. The register **machinery** is fully gated on synthetic entries; the two entries travel to
  the instantiation that has a grammar.

## Theoretical foundations

**W. M. McKeeman, *Differential Testing for Software*, Digital Technical Journal 10(1), 1998,
pp. 100–107.** The term's locus classicus, and it defines the mechanism at issue: two or more
comparable systems, one input, divergence as the bug signal; a designated implementation under test
against comparison implementations; and the application this library is built for — retiring an old
implementation in favour of a new one requires the new one to duplicate old behaviour, so the
differential flags all new results, correct or not, that disagree with the old.

**The citation's narrowing is recorded rather than glossed.** McKeeman's genus clause binds the term
to random testing over *mechanically generated* inputs, and this library's inputs are curated
fixtures. The paper's own counterweight — it applies the term to "ad hoc differential testers" and to
"testing systems that are less elaborate" — is why this is an interval rather than a mismatch. A
generated-input arm, with test reduction as its natural companion, is recorded future work and is the
condition under which the narrowing retires.

**Construct names are placeholders under a standing quarantine.** `subject`, `seam`, `proposition`,
`projections` and the divergence register are named by specification and not by a verified primary;
McKeeman grounds the mechanism and the reference/candidate asymmetry, and grounds none of those
identifiers. They resolve at their own primaries or as ruled namings, and until then a rename is
expected rather than surprising.

## License

MIT
