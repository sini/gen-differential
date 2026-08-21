# THE CROSS-SCOPE SHARING NO-GO — a rigorous negative, carried WITH its scope correction.
#
# ★★★ THE RESULTS AND THE CORRECTION ARE FIELDS OF ONE RECORD, AND THAT IS THE DESIGN. This is the
# library any future eval-sharing shortcut would be built against, so the negative belongs here
# rather than in a document that can be read without it. Shipping the four results WITHOUT the
# correction would license a false inference — that a declared host-class boundary is unsound —
# which is the opposite of what was found. A reader cannot import the results and leave the
# correction behind, because there is nothing to import them out of.
#
# Provenance: hola (github:sini/hola), the parity apparatus this library's machinery is extracted
# from, §2.4 of its SUMMARY; refuted across two adversarial workflows on four load-bearing claims.
# The scope correction is the owner's, recorded with the results.
{
  subject = "pure-Nix cross-scope eval-result sharing, single-host and cross-host heterogeneous";

  verdict = "NO-GO";

  # ★ THE DELIVERABLE IS THE NEGATIVE, and it generalizes. Each result is a separate refutation, not
  # four readings of one.
  results = [
    {
      name = "no-sound-single-host-net-win";
      claim = "There is no sound single-host net win.";
      ground = "A per-element sentinel forces an invariant option N+1 times against vanilla's N. Nix memoizes nothing across separate module fixpoints, so the deep force re-pays exactly the laziness it skipped.";
    }
    {
      name = "union-sentinel-unsound";
      claim = "A union sentinel is unsound.";
      ground = "Throwing the union of element paths over-throws and flips tryEval branches — it over-ADMITS unsafe cases. The sound universal form needs one sentinel per element, so there is no amortization.";
    }
    {
      name = "presence-and-structure-unsound";
      claim = "Presence and structure queries are unsound even per-element.";
      ground = "A value-throw sentinel never perturbs key PRESENCE. (`or` is safe, because it forces the value.)";
    }
    {
      name = "syntactic-path-set-key-unsound";
      claim = "Memoizing by syntactic path-set is unsound.";
      ground = "The key is value-derived.";
    }
  ];

  # The boundary of the soundness that does survive.
  soundnessBoundary = "Soundness is intrinsic ONLY for the throws-observed subclass; the boundary is non-forcing channels.";

  # ★ THE HONEST CEILING ON THE WHOLE APPARATUS, and it is the other side of the coin the `drvPath`
  # comparison kind sits on: a strong witness in one direction, mute in the other.
  ceiling = "drvPath-equality proves output SHAREABILITY, not that evaluation work was shared — so a parity gate is a mandatory backstop rather than a formality.";

  # ★★ DO NOT CITE THE NO-GO AS A BLANKET CEILING. This is the field whose absence would make the
  # record worse than no record at all.
  scopeCorrection = ''
    The NO-GO is NOT a blanket ceiling. It applies to the apparatus AS ARCHITECTED: per-element
    sentinel DISCOVERY. The lever is DECLARING the host-class boundary, not discovering it, and at
    fleet scale the sign flips positive.

    The stable thesis is: declare the host-invariant boundary, do not discover it. Per-element
    discovery is O(N) and net-negative, while declaring a host CLASS — keyed by the sorted
    aspect-include set, NOT by the hostname — and validating O(K) per class is N-independent.

    Reading the four results as a ceiling on class-declared sharing inverts the finding.
  '';
}
