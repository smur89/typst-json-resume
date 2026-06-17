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

// `additional` for keys not in `shape`: `none` → reject; `true` →
// pass-through; schema dict → validate every extra against it.
// Bad-shape `additional` and required-keys-not-covered both fail at
// construction, not as a phantom validation error.
#let object(shape, required-keys: (), additional: none) = {
  let additional-ok = (
    additional == none
      or additional == true
      or (type(additional) == dictionary and "kind" in additional)
  )
  assert(
    additional-ok,
    message: "gairm-import: object() additional must be none, true, or a schema dict (with a `kind` field); got: " +
      repr(additional) + ".",
  )
  // With `additional`, undeclared required keys are covered by the
  // additional schema, so the subset check only applies when strict.
  let unknown = if additional == none {
    required-keys.filter(k => k not in shape)
  } else {
    ()
  }
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
  // Omitted when `none` so existing strict dicts keep their shape.
  if additional == none { base } else { (..base, additional: additional) }
}

#let map(value-schema) = object((:), additional: value-schema)
