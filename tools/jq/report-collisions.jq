# Report sibling properties that collide after ogen-style Go name mangling
# (e.g. `id` and `_id` both become `ID`). One row per collision group.
# Output format (TSV):
#   <JSON pointer path to schema>\t<kept property>\t<removed properties, comma-separated>
#
# Collision groups whose members are ALL "bad" schemas are skipped — their
# removal is already recorded by report-props.jq. Run against the RAW spec
# (before pruning), since the losers no longer exist in the processed one.

include "bad";

paths(objects) as $p
| getpath($p)
| select((.properties? | type) == "object")
| .properties | to_entries
| map({key: .key, norm: (.key | norm_key), value: .value})
| group_by(.norm)[]
| select(length > 1)
| select(all(.[]; (.value | bad | not)))
| sort_by([(if (.key | startswith("_")) then 1 else 0 end), .key]) as $sorted
| [($p | map(tostring) | join(".")),
   $sorted[0].key,
   ($sorted | .[1:] | map(.key) | join(", "))]
| @tsv
