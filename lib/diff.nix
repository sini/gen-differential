# The VALUE MACHINERY — structural comparison with first-divergence location.
#
# Dependency-free (convention §8: a file is a function IFF it has dependencies; this one has none).
# Everything here is expressed in `builtins` alone, so the library adds no node to a consumer's lock
# and the purity scan over `lib/` has nothing to admit.
#
# Domain-free by construction: this layer knows two operands, `a` and `b`, and nothing about which
# of them is the reference. That mapping is made one layer up (compare.nix), which is also the layer
# that knows a claim. Keeping the asymmetry out of here is what lets the same walk serve the
# identity arm and the candidate arm without a second implementation.
let
  # deepSeq to a fixpoint of itself: force the whole structure, yield the structure.
  force = x: builtins.deepSeq x x;

  # A probe is a TOTAL reading of a value: it either carries the forced value or records that
  # forcing refused. Two refusals compare EQUAL under a probe, which is exactly what a consumption
  # or teeth question wants ("did this move?") and exactly what a parity question does not
  # ("are these the same?" — see `diff`, where a refusal on either side is a divergence).
  probe =
    v:
    let
      e = builtins.tryEval (force v);
    in
    if e.success then { forced = e.value; } else { refused = true; };

  # Equality under the probe reading. Used by the oracles, never by the parity kinds.
  probeEq = x: y: (probe x) == (probe y);

  showPath =
    p: if p == [ ] then "<root>" else builtins.concatStringsSep "." (map builtins.toString p);

  # The structural walk. Returns every point at which the two operands disagree, deepest-first
  # within a branch and in attribute-name order across branches, so `locate`'s head is a stable
  # coordinate rather than whichever branch the evaluator reached first.
  #
  # The key union is `attrNames (a // b)`: `//` is lazy in its values, so this forces neither side's
  # contents, and `attrNames` already returns a sorted duplicate-free list. Deriving the union by
  # deduplicating a concatenation instead is quadratic in the attribute count, which on a wide
  # option tree is the difference the walk is most likely to be felt at.
  diffAt =
    path: a: b:
    if builtins.isAttrs a && builtins.isAttrs b then
      builtins.concatMap (
        k:
        if (a ? ${k}) && (b ? ${k}) then
          diffAt (path ++ [ k ]) a.${k} b.${k}
        else
          [
            {
              path = path ++ [ k ];
              aValue = if a ? ${k} then a.${k} else "__absent";
              bValue = if b ? ${k} then b.${k} else "__absent";
            }
          ]
      ) (builtins.attrNames (a // b))
    else if builtins.isList a && builtins.isList b then
      if builtins.length a != builtins.length b then
        [
          {
            path = path ++ [ "length" ];
            aValue = builtins.length a;
            bValue = builtins.length b;
          }
        ]
      else
        builtins.concatMap (i: diffAt (path ++ [ i ]) (builtins.elemAt a i) (builtins.elemAt b i)) (
          builtins.genList (i: i) (builtins.length a)
        )
    else if a == b then
      [ ]
    else
      [
        {
          inherit path;
          aValue = a;
          bValue = b;
        }
      ];

  # ★ `bothEvaluated` IS PART OF THE ANSWER, NOT A SEPARATE QUESTION. A comparison that reports only
  # a verdict cannot distinguish "the two agree" from "neither produced anything", and the second
  # reads green wherever the verdict is the only thing asserted. Reporting the two facts side by
  # side is what lets the coverage floor assert the anti-vacuity key structurally rather than by
  # a convention the next suite forgets.
  #
  # A refusal on EITHER side is a divergence here — deliberately not a probe-equality, because two
  # implementations that both refuse have not been shown to agree about anything except that they
  # refuse, and asserting THAT is the `throws` kind's job (compare.nix), stated as its own claim.
  diff =
    { a, b }:
    let
      ea = builtins.tryEval (force a);
      eb = builtins.tryEval (force b);
    in
    if ea.success && eb.success then
      let
        divs = diffAt [ ] ea.value eb.value;
      in
      {
        identical = divs == [ ];
        bothEvaluated = true;
        divergences = divs;
      }
    else
      {
        identical = false;
        bothEvaluated = false;
        divergences = [
          {
            path = [ ];
            aValue = if ea.success then ea.value else "<<throw>>";
            bValue = if eb.success then eb.value else "<<throw>>";
          }
        ];
      };

  # The first divergence, or null. The coordinate a red is read at.
  locate =
    { a, b }:
    let
      d = diff { inherit a b; };
    in
    if d.identical then null else builtins.head d.divergences;

  # `expectThrow` takes an ALREADY-PROJECTED value; the arm:fixture wrapper lives in compare.nix.
  #
  # ★ SCOPE, STATED AT THE PRIMITIVE RATHER THAN IN A FOOTNOTE: `tryEval` catches thrown errors and
  # failed assertions, NOT every abort class — a rejected regex is the ecosystem's worked
  # counterexample. So this predicate reads the tryEval-catchable subclass of refusal, and a
  # comparison built on it inherits exactly that domain.
  expectThrow = projection: !(builtins.tryEval (force projection)).success;
in
{
  inherit
    force
    probe
    probeEq
    showPath
    diffAt
    diff
    locate
    expectThrow
    ;
}
