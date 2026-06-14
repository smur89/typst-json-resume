// Assumes input has passed _validate. Unknown keys are dropped
// silently rather than panicking; top-of-branch type checks catch
// shape mismatches from direct callers who skipped validation.
// assert(false, ...) over panic(...) for newline-preserving
// diagnostics if these messages ever go multi-line.

#import "errors.typ": _type-name-of

#let _coerce(schema, value) = {
  let kind = schema.kind
  if kind == "content" { return [#value] }
  if kind in ("str", "number") { return value }
  if kind == "array" {
    assert(
      type(value) == array,
      message: "json-resume: coerce-resume expected an array, got " +
        _type-name-of(value) + ". Run validate-resume first.",
    )
    return value.map(elem => _coerce(schema.elem, elem))
  }
  if kind == "object" {
    assert(
      type(value) == dictionary,
      message: "json-resume: coerce-resume expected an object, got " +
        _type-name-of(value) + ". Run validate-resume first.",
    )
    return value.pairs()
      .filter(((key, _)) => key in schema.shape)
      .map(((key, sub-value)) => (key, _coerce(schema.shape.at(key), sub-value)))
      .to-dict()
  }
  panic("json-resume: internal — unknown schema kind " + repr(kind))
}
