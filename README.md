# hfhub-go

An unofficial, auto-generated Go client for the [Hugging Face Hub API](https://huggingface.co/docs/hub/api).

> ⚠️ **Status: experimental, minimally vetted**
>
> This library is **machine-generated code** derived from Hugging Face's
> published OpenAPI spec. It has **not been thoroughly tested** and **not been
> reviewed line by line**. Behavior may deviate from the real API wherever the
> upstream spec is inaccurate or has been transformed (see below). Pin your
> version, read the generated code you call, and verify against real payloads
> before relying on it for anything that matters. Expect breaking changes
> whenever the spec changes.
>
> This project is not affiliated with or endorsed by Hugging Face.

## What it is

The Hub publishes an OpenAPI 3.1 specification at
`https://huggingface.co/.well-known/openapi.json`. [ogen](https://github.com/ogen-go/ogen)
generates a typed Go client directly from that spec. Because the upstream spec
uses several constructs ogen (v1.24.0) cannot parse, a small jq-based pipeline
normalizes and prunes the spec first, recording every deviation it makes.

The result is a client that tracks the real API as published — regenerating
picks up new endpoints and schema changes — with known, documented gaps.

## Installation

Requires Go 1.25+.

```sh
go get github.com/Kardbord/hfhub-go
```

Usage follows standard ogen conventions:

```go
client, err := hfhub.NewClient("https://huggingface.co", security...
// see the ogen-generated ClientInterface for available methods
```

Refer to the generated `ClientInterface` and models — they are the source of
truth for what this library can do.

## Regenerating the client

The client is **never edited by hand**. To regenerate from the current
upstream spec:

```sh
./tools/generate-client.sh
```

The script:

1. Downloads the published spec.
2. Rewrites scalar `items` values (`true`/`false`/`null` → `{}`) — ogen
   requires a schema object there.
3. Rewrites OpenAPI 3.1 numeric `exclusiveMinimum`/`exclusiveMaximum` to the
   OpenAPI 3.0 boolean form (semantics-preserving).
4. Removes properties whose schemas use constructs ogen cannot represent
   (e.g. `type: [string, boolean]` unions).
5. Removes properties that collide after ogen's Go name mangling (e.g. `id`
   vs. `_id`), keeping the non-underscore-prefixed name.
6. Removes operations that lack a `responses` object (invalid OpenAPI —
   typically redirect/media endpoints such as avatars) or that still contain
   unsupported constructs.
7. Verifies nothing unsupported remains, failing loudly with locations if it
   does.
8. Runs ogen and rewrites `openapi.processed.json` and `SPEC_DEVIATIONS.md`.

Review the resulting diffs (`openapi.processed.json`, `SPEC_DEVIATIONS.md`,
and the generated `.go` files) before merging.

## Known deviations

**Every deviation is enumerated in [`SPEC_DEVIATIONS.md`](SPEC_DEVIATIONS.md) —
read it before using this library.** It is regenerated on every build, so it
always reflects the shipped code.

In practice this means:

- Some response fields do not exist on the generated structs. Decoding is
  unaffected (unknown JSON keys are ignored), but those values are simply
  unavailable through this client.
- Some array elements decode as generic values (`[]interface{}`) rather than
  typed structs, where the upstream spec declares `items: false`.
- A handful of endpoints (e.g. avatar redirects) are absent entirely.
- If a removed field belongs to a **request** body, the client cannot send it.

## Repository layout

```
tools/
  regenerate-client.sh # orchestrates download → transform → generate
  jq/                  # jq filters (module-based) driving the transform
openapi.processed.json # the exact spec ogen consumed (committed for review)
SPEC_DEVIATIONS.md     # machine-generated record of every deviation
*.go                   # ogen-generated client (do not edit by hand)
.ogen.yml              # ogen configuration
```

## Caveats

- **Generated, unreviewed.** The entire client surface is ogen output built
  from a spec known to contain inaccuracies. Bugs found in generated code
  should be fixed in the pipeline or upstream spec, then regenerated — not
  patched by hand.
- **Churn.** The upstream spec changes frequently; regeneration can produce
  large diffs, including removed and renamed types.
- **Unofficial.** Hugging Face offers no stability guarantee for the
  published spec, and neither does this project.

## Acknowledgments

- [ogen-go/ogen](https://github.com/ogen-go/ogen) — the code generator.
- [huggingface.js](https://github.com/huggingface/huggingface.js) — where the
  upstream OpenAPI spec is maintained
