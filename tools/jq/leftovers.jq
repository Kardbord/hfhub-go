# Diagnostic: list locations of any schema that failed verify.jq, tagged by
# failure class, so the operator knows exactly where to fix things manually.
#
# Classes (mirroring the checks in verify.jq):
#   bad           — multi-type unions ([string, boolean] etc.)
#   scalar-items  — `items` as true/false/null that somehow survived pruning
#   bounds        — numeric exclusiveMinimum/exclusiveMaximum (OpenAPI 3.1 form)
#   collisions    — sibling properties that collide after Go name mangling
#
# Each line of output:
#   <class>\t<JSON pointer path>

include "bad";

# Emit one row per (class, location).
[
  { cls: "bad",
    loc: (paths(objects) as $p
          | getpath($p)
          | select(bad)
          | ($p | map(tostring) | join("."))) },
  { cls: "scalar-items",
    loc: (paths(objects) as $p
          | getpath($p)
          | select(scalar_items)
          | ($p | map(tostring) | join("."))) },
  { cls: "bounds",
    loc: (paths(objects) as $p
          | getpath($p)
          | select(numeric_exclusive_bounds)
          | ($p | map(tostring) | join("."))) },
  { cls: "collisions",
    loc: (paths(objects) as $p
          | getpath($p)
          | select(has_collisions)
          | ($p | map(tostring) | join("."))) }
]
| .[]
| select(.loc != "")
| [.cls, .loc]
| @tsv
