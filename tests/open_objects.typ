// `additionalProperties` translation + the `map(value-schema)`
// combinator — #77.

#import "../lib.typ": (
  validate, coerce,
  schema-from-json-schema,
  object, map, str-type, number-type,
)

// --- map() convenience ----------------------------------------------

#let str-map = map(str-type)
#assert.eq(str-map.kind, "object")
#assert.eq(str-map.shape, (:))
#assert.eq(str-map.additional, str-type)

// All-strings map: arbitrary keys, every value validated.
#assert.eq(validate((en: "English", fr: "Français"), schema: str-map), ())

#let map-errs = validate((en: "English", fr: 42), schema: str-map)
#assert.eq(map-errs.len(), 1)
#assert.eq(map-errs.at(0).path, ("fr",))
#assert(map-errs.at(0).message.contains("expected string"))

// Coerce passes through every key, dropping nulls.
#assert.eq(
  coerce((a: "x", b: "y", c: none), schema: str-map),
  (a: "x", b: "y"),
)

// --- object with both properties and additional ---------------------

#let mixed = object(
  (name: str-type),
  required-keys: ("name",),
  additional: number-type,
)

// Declared key validated per properties; extras per `additional`.
#assert.eq(validate((name: "Ada", year: 1815, age: 200), schema: mixed), ())

// Wrong type on a declared key still errors via the property schema.
#let mixed-err = validate((name: 1, year: 1815), schema: mixed)
#assert.eq(mixed-err.len(), 1)
#assert.eq(mixed-err.at(0).path, ("name",))

// Wrong type on an extra errors via `additional`.
#let extra-err = validate((name: "Ada", year: "1815"), schema: mixed)
#assert.eq(extra-err.len(), 1)
#assert.eq(extra-err.at(0).path, ("year",))
#assert(extra-err.at(0).message.contains("expected number"))

// --- additional: true (pass-through) --------------------------------

#let permissive = object((name: str-type), additional: true)
// Any extra accepted without validation.
#assert.eq(validate((name: "Ada", anything: ((nested: ("array",))), other: 42), schema: permissive), ())

// Coerce preserves extras verbatim — no recursion into them.
#assert.eq(
  coerce((name: "Ada", whatever: (a: 1, b: 2)), schema: permissive),
  (name: "Ada", whatever: (a: 1, b: 2)),
)

// --- strict path unchanged (no `additional`) ------------------------

#let strict = object((name: str-type))
#let strict-err = validate((name: "Ada", year: 1815), schema: strict)
#assert.eq(strict-err.len(), 1)
#assert(strict-err.at(0).message.contains("unknown key"))

// --- translator: each additionalProperties form ---------------------

// (a) properties, no additionalProperties → strict (default)
#let t-no-ap = schema-from-json-schema((
  type: "object",
  properties: (name: (type: "string")),
))
#assert.eq(t-no-ap.kind, "object")
#assert("additional" not in t-no-ap)

// (b) properties + additionalProperties: false → strict (same shape)
#let t-ap-false = schema-from-json-schema((
  type: "object",
  properties: (name: (type: "string")),
  additionalProperties: false,
))
#assert("additional" not in t-ap-false)

// (c) properties + additionalProperties: true → permissive
#let t-ap-true = schema-from-json-schema((
  type: "object",
  properties: (name: (type: "string")),
  additionalProperties: true,
))
#assert.eq(t-ap-true.additional, true)

// (d) properties + additionalProperties: <schema> → typed extras
#let t-ap-schema = schema-from-json-schema((
  type: "object",
  properties: (name: (type: "string")),
  additionalProperties: (type: "number"),
))
#assert.eq(t-ap-schema.additional, number-type)

// (e) no properties + additionalProperties: <schema> → pure map
#let t-pure-map = schema-from-json-schema((
  type: "object",
  additionalProperties: (type: "string"),
))
#assert.eq(t-pure-map, map(str-type))

// (f) no properties, no additionalProperties → still bails (unchanged)
#let bail-src = read("../internal/json-schema.typ")
#assert(bail-src.contains("open object schemas"))
#assert(bail-src.contains("must be a schema, true, or false"))

// --- constructor: `additional` validated up front -------------------
//
// `object()` rejects anything that isn't `none`, `true`, or a schema
// dict, so a hand-built schema with e.g. `additional: false` fails
// at construction instead of crashing inside _validate when `.kind`
// is read.
#let kinds-src = read("../internal/kinds.typ")
#assert(kinds-src.contains("additional must be none, true, or a schema dict"))

// `additional` + required-key-not-in-shape is now allowed — the
// extra key gets validated by `additional`, so the construction-time
// subset check is skipped when an additional schema is present.
#let open-required = object(
  (:),
  required-keys: ("id",),
  additional: str-type,
)
#assert.eq(open-required.required-keys, ("id",))
// And the runtime still flags it missing if absent…
#let missing = validate((:), schema: open-required)
#assert.eq(missing.len(), 1)
#assert(missing.at(0).message.contains("missing required key \"id\""))
// …and validates the value against `additional` when present.
#assert.eq(validate((id: "abc"), schema: open-required), ())
#let wrong-type = validate((id: 1), schema: open-required)
#assert.eq(wrong-type.len(), 1)
#assert(wrong-type.at(0).message.contains("expected string"))

// --- error path uses the actual key, not "items" --------------------
//
// A pure map of objects: error inside one entry surfaces the real key.
#let book-map = map(object((title: str-type), required-keys: ("title",)))
#let bad-books = validate(
  (
    one: (title: "Ulysses"),
    two: (title: 42),
  ),
  schema: book-map,
)
#assert.eq(bad-books.len(), 1)
#assert.eq(bad-books.at(0).path, ("two", "title"))
