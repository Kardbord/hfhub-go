# Report operations (endpoints) that will be removed.
#
# Two removal reasons:
#   1. Missing `responses` — required by OpenAPI and enforced by ogen.
#      Synthesizing a fake response type would fabricate a contract the
#      upstream spec deliberately (or buggily) omits, so the operation is
#      dropped instead.
#   2. Still contains bad schemas *after* property pruning.
#
# Output format (TSV):
#   <path pattern>\t<HTTP method>

include "bad";

.paths | to_entries[]
| .key as $pk
| (.value | to_entries[])
| select(.key | is_http_method)
| select(
    (.value.responses? == null)
    or (.value | contains_bad)
  )
| [$pk, .key]
| @tsv
