// Pure coercer. Assumes input has passed _validate against the same
// schema. Wraps content-type strings into Typst content blocks so
// renderers consume them positionally; everything else passes through
// unchanged.

#let _coerce(schema, value) = {
  let kind = schema.kind
  if kind == "content" {
    return [#value]
  }
  // array + object handled in the next commit.
  // str / number: identity.
  return value
}
