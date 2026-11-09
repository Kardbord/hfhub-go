# Report schemas whose volatile ISO-8601 date-time `default` is rewritten to
# the fixed epoch sentinel by prune.jq. Output format (TSV, one column):
#   <JSON pointer path>.default
#
# Deliberately does NOT record the original value: it is a spec-build-time
# "now" value that changes on every upstream rebuild, so recording it would
# re-introduce churn into SPEC_DEVIATIONS.md and defeat the determinism the
# normalization exists to provide. Locations alone are stable unless the
# upstream spec genuinely adds or removes these parameters.

include "bad";

paths(objects) as $p
| getpath($p)
| select(volatile_datetime_default)
| (($p + ["default"]) | map(tostring) | join("."))
