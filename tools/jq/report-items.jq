# Report schemas whose scalar `items` (true/false/null/string) is normalized
# to `{}` by prune.jq. Output format (TSV):
#   <JSON pointer path>.items\t<original value>

include "bad";

paths(objects) as $p
| getpath($p)
| select(.items? != null and (.items | type) != "object" and (.items | type) != "array")
| [(($p + ["items"]) | map(tostring) | join(".")), (.items | tojson)]
| @tsv
