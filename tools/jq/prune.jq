# Transform: normalize scalar `items` and numeric exclusive bounds, prune
# unsupported properties and name collisions, then remove invalid or
# unsupported operations.
#
# Strategy:
#   1. JSON Schema allows `items: true/false/null`; ogen requires an object.
#      Rewrite scalar items to the equivalent empty schema `{}` ("any value").
#      For `items: false` this LOOSENS the strict contract — recorded by
#      report-items.jq. Tuple-form `items: [a, b]` is left alone.
#   2. OpenAPI 3.1 numeric exclusiveMinimum/Maximum → OpenAPI 3.0 form:
#      `exclusiveMinimum: N` becomes `minimum: N` + `exclusiveMinimum: true`.
#      Semantics-preserving translation, recorded by report-bounds.jq.
#      If a plain `minimum`/`maximum` already exists with a different value,
#      the exclusive bound is dropped instead (kept constraint wins; still
#      recorded).
#   3. Walk the spec tree, stripping .properties entries where the value is "bad"
#   4. Remove properties that collide with a sibling after ogen-style Go name
#      mangling (e.g. `id` vs `_id` both become `ID`). One property per
#      collision group is kept — the non-underscore-prefixed,
#      lexicographically-smallest name wins. Recorded by
#      report-collisions.jq.
#   5. For .paths, drop operations that:
#      - lack a `responses` object (invalid OpenAPI, rejected by ogen), or
#      - still contain bad schemas after property pruning.
#      Preserve non-method path-item keys like shared `parameters` or `summary`.
#      A path item left with no operations at all is removed entirely.

include "bad";

def normalize_scalar_items:
  walk(
    if type == "object" and (. | scalar_items) then
      .items = {}
    else . end
  );

def normalize_numeric_bounds:
  walk(
    if type == "object" then
      (if (.exclusiveMinimum? | type) == "number" then
         if (.minimum? | type) == "number" and .minimum != .exclusiveMinimum then
           del(.exclusiveMinimum)
         else
           .minimum = .exclusiveMinimum | .exclusiveMinimum = true
         end
       else . end)
      | (if (.exclusiveMaximum? | type) == "number" then
           if (.maximum? | type) == "number" and .maximum != .exclusiveMaximum then
             del(.exclusiveMaximum)
           else
             .maximum = .exclusiveMaximum | .exclusiveMaximum = true
           end
         else . end)
    else . end
  );

# Remove losing properties from every collision group in every schema.
# NOTE: colliding_groups must be called on the SCHEMA (it reads .properties),
# so $losers is computed before entering .properties |= (...), where the
# context would shift to the properties MAP instead.
def prune_collisions:
  walk(
    if type == "object" and ((.properties? | type) == "object") then
      (colliding_groups | map(.[1:] | map(.key)) | flatten) as $losers
      | .properties |= with_entries(select(.key as $k | ($losers | index($k)) | not))
    else . end
  );

normalize_scalar_items
| normalize_numeric_bounds
| walk(
    if type == "object" and ((.properties? | type) == "object") then
      .properties |= with_entries(select(.value | bad | not))
    else . end
  )
| prune_collisions
| (.paths // {}) |= with_entries(
    .value |= with_entries(
      select(
        (.key | is_http_method | not)
        or ((.value.responses? != null) and (.value | contains_bad | not))
      )
    )
  )
| (.paths // {}) |= with_entries(
    select((.value | to_entries | any(.key | is_http_method)))
  )
