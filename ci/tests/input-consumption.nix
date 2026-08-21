# EVERY DECLARED INPUT OF A RUN HAS AT LEAST ONE CONSUMING CELL.
#
# ★★★ THE MEASURED FAILURE THIS EXISTS FOR: in a frozen apparatus in this project, a corpus was
# passed into a suite's arguments and ZERO tests consumed it. Every cell passed. The full green was
# a genuine no-regression signal for the harness and said NOTHING WHATEVER about the corpus — the
# pin's only live consumer was the lock file.
#
# ★★ IT IS A DISTINCT VACUITY FROM THE FLOOR'S ANTI-VACUITY KEY, WHICH IS WHY THE FLOOR DOES NOT
# ALREADY COVER IT. `both-evaluated` catches two arms agreeing through a shared refusal. This
# catches a declared input no cell reads at all — a run can pass every anti-vacuity key while
# every fixture ignores the corpus it declares.
#
# The demonstration is by PERTURBATION, never by a syntactic reachability reading: an input is
# consumed when moving it moves a cell. "Is it mentioned" passes for a mention nothing forces.
{
  nixpkgsLib,
  nixpkgsSrc,
  genDifferential,
  ...
}:
let
  gd = genDifferential;
  arms = import ./_arms.nix { inherit nixpkgsLib nixpkgsSrc genDifferential; };

  # A run's declared inputs, as values.
  inputs = {
    elements = 6;
    tag = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
  };

  perturb = name: v: if name == "elements" then v + 1 else "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";

  # THE CELLS, as a function of the declared inputs. Both are read.
  #
  # ★ THE FIRST DRAFT OF THIS FILE FAILED ITS OWN ORACLE, AND THE FAILURE IS WORTH KEEPING IN VIEW:
  # the `things` cell read the comparison's `firstDivergence`, which is `null` whenever the two arms
  # agree. Widening the element count moved the fixture, moved the evaluation, and left the cell at
  # `null` both times — so the input really was unconsumed BY THAT CELL, and the oracle said so.
  # A cell that reads a field which is constant on the happy path is exactly the shape this guard
  # exists to catch, and it caught it here before it caught it anywhere else.
  cells = i: {
    things = gd.observables.at [ "config" "things" ] (
      gd.compare.run arms.reference (
        arms.entry "synthetic" {
          n = i.elements;
          ndecls = 2;
          layers = 2;
        }
      )
    );
    # A cell that genuinely depends on `tag`: the artifact fixture's observed derivation path.
    out = gd.observables.at [ "config" "out" ] (
      gd.compare.run arms.reference (arms.entry "artifact" { inherit (i) tag; })
    );
  };

  # ★ THE SAME RUN WITH ONE INPUT NOTHING READS — the exact silhouette the measured failure had.
  inputsWithDead = inputs // {
    corpus = "a value no cell forces";
  };

  honest = gd.oracles.inputConsumption { inherit inputs perturb cells; };
  vacuous = gd.oracles.inputConsumption {
    inputs = inputsWithDead;
    perturb = name: v: if name == "corpus" then "moved" else perturb name v;
    inherit cells;
  };
in
{
  flake.tests.input-consumption = {
    test-every-declared-input-is-consumed = {
      expr = honest.total;
      expected = true;
    };

    # Named rather than counted: a count cannot say which input went dark.
    test-the-consumed-inputs-are-named = {
      expr = honest.consumed;
      expected = [
        "elements"
        "tag"
      ];
    };

    test-nothing-is-unconsumed = {
      expr = honest.unconsumed;
      expected = [ ];
    };

    # ★★ THE SEEDED FAILURE — a declared input no cell reads. The run is otherwise identical and
    # every one of its cells still passes; only this oracle can see the difference.
    test-control-an-unread-declared-input-is-caught = {
      expr = vacuous.total;
      expected = false;
    };

    test-control-the-unread-input-is-named = {
      expr = vacuous.unconsumed;
      expected = [ "corpus" ];
    };

    # ★ AND THE OTHER TWO ARE STILL REPORTED CONSUMED IN THE SAME RUN. Without this, the cell above
    # is satisfied by an oracle that has stopped detecting consumption at all — which would report
    # exactly the same `false`.
    test-control-the-live-inputs-stay-consumed-in-the-seeded-run = {
      expr = vacuous.consumed;
      expected = [
        "elements"
        "tag"
      ];
    };

    # The per-input record names WHICH cell moved, so a partially-consumed input is readable rather
    # than just a boolean.
    test-each-consumed-input-names-the-cell-it-moved = {
      expr = map (r: {
        inherit (r) name moved;
      }) honest.perInput;
      expected = [
        {
          name = "elements";
          moved = [ "things" ];
        }
        {
          name = "tag";
          moved = [ "out" ];
        }
      ];
    };
  };
}
