// Pure coercer. Assumes input has passed _validate against the same
// schema. Wraps content-type strings into Typst content blocks so
// renderers consume them positionally; everything else passes through
// unchanged.

#let _coerce(schema, value) = {
  let kind = schema.kind
  if kind == "content" {
    return [#value]
  }
  if kind == "array" {
    return value.map(elem => _coerce(schema.elem, elem))
  }
  if kind == "object" {
    let out = (:)
    for (key, sub-value) in value.pairs() {
      out.insert(key, _coerce(schema.shape.at(key), sub-value))
    }
    return out
  }
  // str / number: identity.
  return value
}
