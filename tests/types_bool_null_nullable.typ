// bool-type / null-type / nullable: type-coverage gaps closed by #75.
// JSON Schema type forms — bool, null, [X, "null"] union — now
// translate to first-class engine kinds instead of panicking out of
// `_from-json-schema`.

#import "../lib.typ": (
  validate, coerce,
  schema-from-json-schema,
  bool-type, null-type, nullable,
  str-type, number-type, object,
)

// --- bool-type --------------------------------------------------------

#assert.eq(validate(true, schema: bool-type), ())
#assert.eq(validate(false, schema: bool-type), ())
#assert.eq(coerce(true, schema: bool-type), true)
#assert.eq(coerce(false, schema: bool-type), false)

// Type errors carry the path-qualified "expected boolean" message.
#let bool-errs = validate("yes", schema: bool-type)
#assert.eq(bool-errs.len(), 1)
#assert(bool-errs.at(0).message.contains("expected boolean"))
#assert(bool-errs.at(0).message.contains("got string"))

// --- null-type --------------------------------------------------------
//
// `value == none` is "key absent" at every position — null-type
// success is therefore indistinguishable from the engine-wide policy.
// The kind is load-bearing only as a target for translator output
// and as the inner of `nullable`. Non-none input is a type error.

// (null root is rejected by the lib.typ wrapper, so test against the
// engine via a nested-in-object position.)
#let nested = object((flag: null-type))
#assert.eq(validate((flag: none), schema: nested), ())
#let null-errs = validate((flag: 1), schema: nested)
#assert.eq(null-errs.len(), 1)
#assert(null-errs.at(0).message.contains("expected null"))

// --- nullable wrap ----------------------------------------------------
//
// `nullable(inner)` accepts none OR delegates to inner.

#let nullable-str = nullable(str-type)
#assert.eq(validate("hi", schema: nullable-str), ())
// none at value position is already absorbed by the engine — the
// nullable wrap doesn't change that, just makes it explicit.
#assert.eq(coerce("hi", schema: nullable-str), "hi")

// Non-none + wrong-type errors carry the INNER schema's error, not
// a wrapper one — the wrapper is transparent on the failure path too.
#let nullable-errs = validate(42, schema: nullable-str)
#assert.eq(nullable-errs.len(), 1)
#assert(nullable-errs.at(0).message.contains("expected string"))

// --- translator: type: "boolean" -------------------------------------

#assert.eq(
  schema-from-json-schema((type: "boolean")),
  bool-type,
)
#assert.eq(
  schema-from-json-schema((type: "null")),
  null-type,
)

// --- translator: [X, "null"] nullable wrap ---------------------------

#assert.eq(
  schema-from-json-schema((type: ("string", "null"))),
  nullable(str-type),
)
// Order doesn't matter — `null` can come first.
#assert.eq(
  schema-from-json-schema((type: ("null", "integer"))),
  nullable(number-type),
)
// Sibling keywords on the union carry through to the inner.
#assert.eq(
  schema-from-json-schema((type: ("string", "null"), format: "email")),
  nullable(schema-from-json-schema((type: "string", format: "email"))),
)

// --- translator: multi-non-null union rejected -----------------------
//
// Source-level pin on the bail message — Typst can't catch panics so
// this is the closest available proxy. Same pattern as
// tests/json_schema_panic_messages.typ.
#let src = read("../internal/json-schema.typ")
#assert(src.contains("only supported as nullable wraps"))
