# Report schemas whose volatile ISO-8601 date-time `default` is rewritten to
# the fixed epoch sentinel by prune.jq. Output format (TSV):
#   <JSON pointer path>.default\t<original value>

include "bad";

paths(objects) as $p
| getpath($p)
| select(volatile_datetime_default)
| [(($p + ["default"]) | map(tostring) | join(".")), .default]
| @tsv
