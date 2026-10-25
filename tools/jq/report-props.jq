# Report object properties whose schemas are "bad" and will be removed.
#
# Output format (TSV):
#   <JSON pointer path to parent>.properties\t<property name>\t<original schema JSON>

include "bad";

paths(objects) as $p
| getpath($p)
| select((.properties? | type) == "object")
| .properties | to_entries[]
| select(.value | bad)
| [($p | map(tostring) | join(".")), .key, (.value | tojson)]
| @tsv
