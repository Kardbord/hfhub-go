# Report schemas whose numeric exclusiveMinimum/exclusiveMaximum (OpenAPI 3.1
# form) get rewritten to the OpenAPI 3.0 boolean form by prune.jq.
# Output format (TSV):
#   <JSON pointer path to schema>\t<exclusiveMinimum or null>\t<exclusiveMaximum or null>

include "bad";

paths(objects) as $p
| getpath($p)
| select(. | numeric_exclusive_bounds)
| [($p | map(tostring) | join(".")),
   (.exclusiveMinimum? // null | tojson),
   (.exclusiveMaximum? // null | tojson)]
| @tsv

