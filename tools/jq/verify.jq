# Sanity-check: after pruning + normalization, there should be ZERO remaining
# bad schemas, ZERO scalar items, ZERO numeric exclusive bounds, and ZERO
# property-name collisions.
#
# Exits non-zero (jq -e semantics) if any remain, causing the bash script
# to fail fast and print diagnostic locations via leftovers.jq.

include "bad";

( [.. | objects | select(bad)] | length == 0 )
and ( [.. | objects | select(scalar_items)] | length == 0 )
and ( [.. | objects | select(numeric_exclusive_bounds)] | length == 0 )
and ( [.. | objects | select(has_collisions)] | length == 0 )
