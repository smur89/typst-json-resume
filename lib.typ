// Strict loader for canonical JSON Resume data
// (https://jsonresume.org/schema). The engines under internal/ are
// pure functions of (schema, value); see
// tests/engine_schema_agnostic.typ for the BYO-schema contract.

#import "internal/schema.typ": resume-schema, str-type, content-type, number-type, array-of, object
#import "internal/validate.typ": _validate
#import "internal/coerce.typ": _coerce
#import "internal/errors.typ": _format-report
#import "internal/json-schema.typ": schema-from-json-schema

// Combined-report formatter, for callers handling errors themselves
// instead of letting `parse` / `parse-resume` abort.
#let format-errors(errors) = _format-report(errors)

#let validate(schema, data) = _validate(schema, data, ())

// Unknown keys are dropped silently rather than panicking, so direct
// callers who skip validation don't get a Typst dictionary-access
// panic.
#let coerce(schema, data) = _coerce(schema, data)

// Shared parse implementation. `caller` and `hint` are spliced into
// panic messages so `parse-resume("relative.json")` recommends
// `parse-resume(json(…))` rather than the BYO `parse(schema, json(…))`
// form. Kept private to avoid leaking those as keyword arguments on
// the public surface.
//
// String paths must start with "/" because Typst resolves relative
// paths against the file containing the call — here that's the
// @preview cache. For paths relative to the caller's own .typ, pass
// `json("…")` instead.
#let _parse-impl(schema, data, caller, hint) = {
  let dict-data = if type(data) == str {
    if not data.starts-with("/") {
      panic(
        "json-resume: " + caller + " with a string path requires the path " +
          "to start with \"/\" (resolved from the typst root). Got: " + repr(data) + ". " +
          "To use a path relative to your own .typ file, call json() " +
          "directly: " + hint + ".",
      )
    }
    json(data)
  } else if type(data) == dictionary {
    data
  } else {
    panic(
      "json-resume: " + caller + " expected a dict or a string path, got " +
        repr(type(data)) + ".",
    )
  }
  let errors = validate(schema, dict-data)
  // assert preserves newlines in the diagnostic; panic repr-escapes
  // them and collapses the bullet list onto one line.
  assert(errors.len() == 0, message: format-errors(errors))
  coerce(schema, dict-data)
}

#let parse(schema, data) = _parse-impl(
  schema, data, "parse", "parse(schema, json(" + repr(data) + "))",
)

// Canonical wrappers — pre-bound to resume-schema. The engines treat
// `none` at any value position as "key absent" (right for leaves in
// a document, wrong for the root); validate-resume / coerce-resume
// reject root-null explicitly. parse-resume hits the same panic via
// the dict-or-string type guard inside `_parse-impl`.

#let validate-resume(data) = {
  if data == none { panic("json-resume: input must be a dict, got null.") }
  validate(resume-schema, data)
}

#let coerce-resume(data) = {
  if data == none { panic("json-resume: input must be a dict, got null.") }
  coerce(resume-schema, data)
}

#let parse-resume(data) = _parse-impl(
  resume-schema, data, "parse-resume", "parse-resume(json(" + repr(data) + "))",
)
