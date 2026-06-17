// Schema-kind constants and constructors. Lives in its own module
// because schema.typ depends on json-schema.typ (for derivation) and
// json-schema.typ depends on these primitives — extracting them here
// breaks the cycle.

#let str-type     = (kind: "str")
#let content-type = (kind: "content")
#let number-type  = (kind: "number")
#let bool-type    = (kind: "bool")

// "Must be null or absent": `none` passes via the engine's global
// early return, non-none hits the kind branch and errors.
#let null-type    = (kind: "null")

// Format-specialised string kinds — regex-gated in _validate;
// deliberately permissive (reject obvious malformations, not full RFC).
#let date-string     = (kind: "date-string")
#let datetime-string = (kind: "datetime-string")
#let uri-string      = (kind: "uri-string")
#let email-string    = (kind: "email-string")

// Per-instance regex gate — a constructor, not a constant, because
// each schema node carries its own regex and hint.
#let pattern-string(re, expected: "matching pattern") = (
  kind: "pattern-string",
  pattern: regex(re),
  expected: expected,
)

#let array-of(elem) = (kind: "array", elem: elem)

// Mixed-type members allowed — the validator's `in` check gates on
// equality, not type. `const` is a singleton enum.
#let enum-of(values) = (kind: "enum", values: values)
#let const-of(value) = enum-of((value,))

// `additional` controls keys not in `shape`:
//   none (default) — reject as unknown ("Did you mean …?" fuzzy match)
//   true           — allow without validation
//   <schema dict>  — allow, validate every value against this schema
//
// Reject required-keys that don't appear in shape so a schema typo
// fails at construction time, not as a phantom validation error.
#let object(shape, required-keys: (), additional: none) = {
  let unknown = required-keys.filter(k => k not in shape)
  assert(
    unknown.len() == 0,
    message: "gairm-import: object() required-keys references keys not in shape: " +
      unknown.join(", ") + ".",
  )
  let base = (
    kind: "object",
    shape: shape,
    required-keys: required-keys,
  )
  // Omit the field on the default (strict) path — keeps dict shape
  // identical for schemas that don't use additionalProperties.
  if additional == none { base } else { (..base, additional: additional) }
}

// Convenience: a pure "any string → value-schema" map.
#let map(value-schema) = object((:), additional: value-schema)
