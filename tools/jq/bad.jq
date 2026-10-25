# Module: shared predicates for detecting schema constructs ogen cannot parse.
#
# Included by the other filters via:
#     include "bad";
#
# Exported definitions:
#   - multi_type      — true if . is a type list naming >1 non-null type
#   - bad             — recursive predicate: subtree contains an unsupported construct
#   - contains_bad    — true if the input value contains bad schemas anywhere within
#   - scalar_items    — true if . has an `items` that is neither object nor array
#   - numeric_exclusive_bounds — true if . uses numeric exclusiveMinimum/Maximum
#   - norm_key        — approximate ogen Go-name normalization of a property name
#   - colliding_groups — property-name collision groups of this schema
#   - has_collisions  — true if this schema has colliding sibling properties
#   - http_methods    — list of OpenAPI operation keys
#   - is_http_method  — true if the input string is an HTTP method key
#
# ogen only supports single types or [T, "null"] (collapsed to nullable T).
# Any other multi-type union is "bad" and must be pruned.

def multi_type:
  ((.type? // []) | type) == "array"
  and (((.type? // []) | map(select(. != "null"))) | length) > 1;

# Recursively descend through a schema tree:
# - items
# - additionalProperties
# - properties (any child)
# - oneOf (any variant)
def bad:
  multi_type
  or (if (.items? | type) == "object" then (.items | bad) else false end)
  or (if (.additionalProperties? | type) == "object" then (.additionalProperties | bad) else false end)
  or (if ((.properties? | type) == "object") then (.properties | any(.[]; bad)) else false end)
  or (if ((.oneOf? | type) == "array") then (.oneOf | any(.[]; bad)) else false end);

# True if the input contains any bad schema anywhere in its subtree.
def contains_bad:
  [.. | objects | select(bad)] | length > 0;

# True if . is an object whose `items` is a scalar (true/false/null/string).
# JSON Schema permits `items: true` ("any value") and `items: false`; ogen's
# parser requires a schema object and fails with "unexpected YAML kind Scalar".
# Tuple-form `items: [a, b]` (an array) is NOT flagged here — it's a separate
# construct with distinct handling.
def scalar_items:
  (.items? != null)
  and ((.items? | type) != "object")
  and ((.items? | type) != "array");

# True if . uses the JSON Schema 2020-12 / OpenAPI 3.1 numeric form of
# exclusiveMinimum/exclusiveMaximum. ogen v1.24.0 only accepts the OpenAPI
# 3.0 boolean form (`minimum: N` + `exclusiveMinimum: true`), so numeric
# bounds must be rewritten before generation.
def numeric_exclusive_bounds:
  ((.exclusiveMinimum? | type) == "number")
  or ((.exclusiveMaximum? | type) == "number");

# Approximation of ogen's Go field-name mangling: lowercase, drop everything
# that is not alphanumeric. Two properties whose normalized names are equal
# (e.g. `id` and `_id`, or `myField` and `my_field`) map to the same Go
# struct field, which ogen rejects as a conflict. This is deliberately
# conservative: it may over-detect (dropping a property that would not
# actually collide), but under-detection simply resurfaces as an ogen error
# on the next run.
def norm_key:
  ascii_downcase | gsub("[^a-z0-9]"; "");

# Given a schema with .properties, return the groups of sibling property
# names that collide after normalization. Each group is an array of
# {key, norm} objects, sorted with the "winner" first (non-underscore-prefixed
# and lexicographically smallest keys win).
def colliding_groups:
  (.properties? // {})
  | to_entries
  | map({key: .key, norm: (.key | norm_key)})
  | group_by(.norm)
  | map(select(length > 1))
  | map(
      sort_by([(if (.key | startswith("_")) then 1 else 0 end), .key]));

# True if . is a schema with colliding sibling property names.
def has_collisions:
  (colliding_groups | length) > 0;

def http_methods:
  ["get", "put", "post", "delete", "options", "head", "patch", "trace"];

def is_http_method:
  . as $key
  | http_methods | index($key) != null;
