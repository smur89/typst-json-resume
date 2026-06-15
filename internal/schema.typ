// Canonical JSON Resume schema (https://jsonresume.org/schema).
//
// Derived at module-load time from the vendored
// fixtures/jsonresume-schema.json (pinned to upstream
// jsonresume/resume-schema v1.0.0) so the JSON document is the single
// source of truth. The kind/primitive constants live in kinds.typ to
// keep this file's only job "produce resume-schema".
//
// `_content-paths` is the deliberate divergence from the source: the
// canonical schema types these free-text fields as `string`, but the
// package wraps them in Typst `content` during coercion for ergonomic
// inline rendering. See #32 — that override is an open question;
// either it earns its keep or it moves out into a config / disappears.
//
// To bump the vendored schema: replace fixtures/jsonresume-schema.json
// with the chosen upstream tag, run `make test`, and audit
// `_content-paths` against any newly added free-text fields.

#import "kinds.typ": str-type, content-type, number-type, array-of, object
#import "json-schema.typ": schema-from-json-schema
#import "lens.typ": lens, lens-put

#let _content-paths = (
  ("basics", "summary"),
  ("work", "items", "summary"),
  ("work", "items", "highlights", "items"),
  ("volunteer", "items", "summary"),
  ("volunteer", "items", "highlights", "items"),
  ("awards", "items", "summary"),
  ("publications", "items", "summary"),
  ("references", "items", "reference"),
  ("projects", "items", "description"),
  ("projects", "items", "highlights", "items"),
)

#let resume-schema = _content-paths.fold(
  schema-from-json-schema(json("fixtures/jsonresume-schema.json")),
  (s, p) => lens-put(lens(p), s, content-type),
)
