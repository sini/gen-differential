# Standalone (non-flake) entry. Flake consumers should use the `.lib` output.
#
# gen-differential is a function of nothing — the whole library is `builtins`, and both arms of
# every comparison arrive at the call site — so this shim has no locked revisions to fetch and is a
# plain re-export rather than the usual `fetchTree` pinning. The two entry points therefore cannot
# drift: they are the same expression.
import ./lib
