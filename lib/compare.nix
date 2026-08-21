# THE COMPARISON — the kinds, the claim record, and the suite constructor.
#
# "If a single test is fed to several comparable programs (for example, several C compilers), and
# one program gives a different result, a bug may have been exposed" (McKeeman 1998, DTJ 10(1),
# printed 101). This file is that sentence made structural: one fixture, two arms, a named claim.
#
# ★★ THE CONSTRUCTOR EMITS BOTH ARMS. There is no entry point that yields the candidate comparison
# alone, because an identity control a consumer may decline to call is a control that will be
# declined. `mkSuite` derives the identity arm from the subject's seam and emits it beside every
# candidate cell.
{
  contract,
  diff,
  register,
}:
let
  refuse = what: why: throw "gen-differential: ${what} — ${why}";

  # Bound before the field of the same name shadows the module: `register` is a CONTRACT FIELD on a
  # suite and a claim, and it is also this concern's namespace. The alias keeps both spellings
  # honest instead of renaming the contract field to protect an import.
  applyRegister = register.apply;

  # Evaluate a fixture through an arm. The fixture's `modules` is a function of the arm's own
  # vocabulary, so BOTH ARMS RUN THE SAME SOURCE against their own `mkOption`/`types`/`mkMerge`.
  # A fixture that closed over one arm's vocabulary would be comparing two different programs and
  # calling the result parity.
  run =
    arm: fixture:
    arm.eval (
      {
        modules = fixture.modules arm.vocab;
        inherit (fixture) specialArgs;
      }
      // (if fixture.class == null then { } else { inherit (fixture) class; })
    );

  # ── THE KINDS ────────────────────────────────────────────────────────────────────────────────
  #
  # ★ THE THREE ARE NOT A CLOSED SET, for the reason the observable axis is open: a comparison kind
  # is a predicate over observables, and the surfaces worth comparing are not enumerable from here.
  #
  # ★★ `drvPath` IDENTITY IS SUFFICIENT, NEVER NECESSARY, and the kind says so rather than a
  # footnote saying it. Byte identity is asserted only where it is free; end-result EQUIVALENCE is
  # the bar. And the honest ceiling on the other side of the same coin, measured in the source
  # apparatus: drvPath-equality proves output SHAREABILITY, not that evaluation work was shared. So
  # the kind is a strong witness in one direction and mute in the other, and `assertion` carries
  # which one a given cell claimed.
  kinds = {
    value = {
      assertion = "equivalence";
      # Structural equality of the observable, with first-divergence location.
      compare =
        {
          a,
          b,
          observable,
        }:
        let
          d = diff.diff {
            a = observable a;
            b = observable b;
          };
        in
        {
          inherit (d) identical bothEvaluated divergences;
          bothRefused = null;
        };
    };

    drvPath = {
      assertion = "identity";
      # ★ THE ABSENCE IS CONVERTED TO A THROW BEFORE IT IS READ, AND THAT IS NOT DEFENSIVENESS.
      # `tryEval` catches thrown errors and failed assertions and NOT a missing-attribute error, so
      # selecting `.drvPath` off an observable that has none takes the whole gate down instead of
      # failing one cell — the exact class this ecosystem keeps a second test output for. Measured
      # here: a seeded run whose observable stopped yielding a derivation-shaped value crashed the
      # suite rather than reddening the cell. Testing presence first turns an uncatchable abort into
      # a catchable refusal, so the cell can carry its own failure.
      compare =
        {
          a,
          b,
          observable,
        }:
        let
          read =
            arm:
            builtins.tryEval (
              let
                v = observable arm;
              in
              if builtins.isAttrs v && v ? drvPath then
                v.drvPath
              else
                throw "gen-differential: the `drvPath' comparison's observable yielded no `drvPath' attribute"
            );
          ea = read a;
          eb = read b;
          ok = ea.success && eb.success;
          same = ok && ea.value == eb.value;
        in
        {
          identical = same;
          bothEvaluated = ok;
          bothRefused = null;
          divergences =
            if same then
              [ ]
            else
              [
                {
                  path = [ "drvPath" ];
                  aValue = if ea.success then ea.value else "<<throw>>";
                  bValue = if eb.success then eb.value else "<<throw>>";
                }
              ];
        };
    };

    throws = {
      # Neither equivalence nor identity: a mutual-refusal claim asserts that both arms DECLINE the
      # same input. It is recorded under its own name so a reader cannot take it for either.
      assertion = "refusal";
      # ★ ITS DOMAIN IS THE tryEval-CATCHABLE SUBCLASS, not refusal in general — `tryEval` catches
      # thrown errors and failed assertions and not every abort class (a rejected regex is the
      # worked counterexample in this ecosystem). A cell asserting this kind is asserting about that
      # subclass, and the scope belongs at the kind rather than in a note somewhere else.
      #
      # ★★ AND IT ASSERTS MUTUAL REFUSAL, NOT A SHARED CAUSE. A refusal reading yields a boolean and
      # nothing else, so two arms that decline for entirely unrelated reasons satisfy this kind.
      # Measured in this repository's own suite: an arm perturbed so that the observed attribute no
      # longer exists still refuses, and the cell stays green — correctly, because "both decline" is
      # the whole of what is claimed. Asserting that the two REFUSED THE SAME WAY needs a comparison
      # of the refusals, which this reading cannot supply.
      compare =
        {
          a,
          b,
          observable,
        }:
        let
          ra = diff.expectThrow (observable a);
          rb = diff.expectThrow (observable b);
          both = ra && rb;
        in
        {
          identical = both;
          bothEvaluated = null;
          bothRefused = both;
          divergences =
            if both then
              [ ]
            else
              [
                {
                  path = [ ];
                  aValue = if ra then "<<throw>>" else "<<answered>>";
                  bValue = if rb then "<<throw>>" else "<<answered>>";
                }
              ];
        };
    };
  };

  # ── THE CLAIM ────────────────────────────────────────────────────────────────────────────────
  #
  # Every field a red needs to be readable WITHOUT an operator who already knows what was seeded:
  # which claim, which pair of arms, which observable, what was asserted, and where the two first
  # parted company.
  #
  # The record is a claim and it CARRIES the claim it belongs to, so the field shadows this
  # constructor inside the body below — harmlessly, because nothing here is recursive. It is the
  # same shape as `applyRegister` above and is noted for the same reason: a reader who later reaches
  # for `claim` in this scope is reaching for the string, not the function.
  claim =
    {
      claim,
      arms,
      fixture,
      observableName,
      a,
      b,
      register ? [ ],
    }:
    let
      kind = kinds.${fixture.comparison};
      observable = fixture.observables.${observableName};
      raw = kind.compare {
        inherit observable;
        a = run a fixture;
        b = run b fixture;
      };
      reg = applyRegister {
        inherit register;
        inherit (raw) divergences;
      };
    in
    raw
    // {
      inherit claim arms observableName;
      inherit (fixture) comparison rung;
      inherit (kind) assertion;
      referenceArm = a.name;
      candidateArm = b.name;
      firstDivergence = if raw.divergences == [ ] then null else builtins.head raw.divergences;
      registered = reg.registered;
      unregistered = reg.unregistered;
      missing = reg.missing;
      # THE VERDICT, and it takes the anti-vacuity key with it. A comparison that reports only
      # agreement cannot tell agreement from two arms that produced nothing.
      green =
        reg.unregistered == [ ]
        && reg.missing == [ ]
        && (if fixture.comparison == "throws" then raw.bothRefused else raw.bothEvaluated);
    };
in
rec {
  inherit run kinds claim;

  # ── THE SUITE ────────────────────────────────────────────────────────────────────────────────
  #
  # ★ THE REGISTER APPLIES TO THE CANDIDATE ARM ONLY, and the asymmetry is load-bearing. A register
  # entry authorizes a difference between the REFERENCE and the DESIGN UNDER TEST. The identity arm
  # is the reference's own body travelling the candidate's seam, so it must agree with the reference
  # outright: applying the register there would leave every entry `missing` on every identity cell,
  # which is the register asserting against the wrong pair.
  mkSuite =
    {
      subject,
      fixtures,
      register ? [ ],
    }:
    if !(builtins.isAttrs fixtures) || fixtures == { } then
      refuse "suite.fixtures" "a suite with no fixtures asserts nothing and reads green"
    else
      let
        arms = contract.armsOf subject;
        cellsFor =
          fixture:
          builtins.mapAttrs (
            observableName: _:
            let
              common = {
                inherit (subject) claim;
                inherit fixture observableName;
                a = arms.reference;
              };
            in
            {
              # Both arms, always. The identity cell is not reachable for removal.
              identity = claim (
                common
                // {
                  arms = "reference↔identity";
                  b = arms.identity;
                }
              );
              candidate = claim (
                common
                // {
                  arms = "reference↔candidate";
                  b = arms.candidate;
                  inherit register;
                }
              );
            }
          ) fixture.observables;

        cells = builtins.mapAttrs (_: cellsFor) fixtures;

        allClaims = builtins.concatMap (
          fx: builtins.concatMap (p: builtins.attrValues p) (builtins.attrValues fx)
        ) (builtins.attrValues cells);
      in
      {
        inherit cells allClaims;
        inherit (subject) claim;
        seam = subject.seam.name;
        green = builtins.all (c: c.green) allClaims;
      };
}
