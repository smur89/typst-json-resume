// Subtrees under unknown keys are not walked — their expected shape
// is undefined.
//
// JSON `null` (Typst's `none`) at a value position is treated as if
// the key were absent: no type error, no recursion. Per-key null
// values in objects, null array elements, and entire-section nulls
// are all absorbed by the top-of-function early return — recursion
// handles them uniformly. The required-keys check below is the only
// place that still needs an explicit null check (a present-but-null
// required key must still count as missing). See README "Errors"
// section for the user-facing rationale.

#import "errors.typ": _type-name-of

#let _type-error(path, expected, value) = ((
  path: path,
  message: "expected " + expected + ", got " + _type-name-of(value) + ".",
),)

// Format-specialised string kinds use tightened patterns over the
// canonical JSON Resume regexes — the upstream forms accept impossible
// months (13-19) and days (32-39), case-mismatched URI schemes, and
// domains with empty labels. Patterns are anchored with ^…$ so
// `value.matches(re)` returns one match iff the whole string conforms.
//
//  - date-string: iso8601 — YYYY, YYYY-MM, or YYYY-MM-DD. Month and
//    day are constrained to real calendar ranges (01-12 / 01-31). Does
//    NOT cross-check month against day count (e.g. 2024-02-31 passes).
//  - uri-string:  scheme `[A-Za-z][A-Za-z0-9+.-]*` (RFC 3986 declares
//    schemes case-insensitive), then `://`, then one-or-more
//    non-whitespace chars. Permissive — does NOT enforce RFC 3986.
//  - email-string: non-empty local + `@` + domain whose labels each
//    contain at least one char and are separated by literal dots —
//    rejects empty labels (e.g. `foo@bar..com`, `foo@host.`). Still
//    permissive — does NOT enforce RFC 5322.
#let _format-patterns = (
  "date-string":  regex("^([1-2][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])|[1-2][0-9]{3}-(0[1-9]|1[0-2])|[1-2][0-9]{3})$"),
  "uri-string":   regex("^[A-Za-z][A-Za-z0-9+.\-]*://\S+$"),
  "email-string": regex("^[^@\s]+@[^@\s.]+(?:\.[^@\s.]+)+$"),
)

#let _format-descriptions = (
  "date-string":  "an ISO-8601 date (e.g. \"2024-01-15\")",
  "uri-string":   "a URI (e.g. \"https://example.com\")",
  "email-string": "an email (e.g. \"name@example.com\")",
)

#let _format-error(path, kind, value) = ((
  path: path,
  message: "expected " + _format-descriptions.at(kind) + ", got " + repr(value) + ".",
),)

#let _validate(schema, value, path) = {
  // Null at any value position is "key absent" — no error, no
  // recursion. Single early return handles every shape uniformly:
  // standalone scalars, array elements (via the per-element call),
  // and per-key sub-values inside objects (via the per-key call).
  if value == none { return () }
  let kind = schema.kind
  if kind in ("str", "content") {
    if type(value) != str { return _type-error(path, "string", value) }
    return ()
  }
  if kind in ("date-string", "uri-string", "email-string") {
    if type(value) != str { return _type-error(path, "string", value) }
    if value.matches(_format-patterns.at(kind)).len() == 0 {
      return _format-error(path, kind, value)
    }
    return ()
  }
  if kind == "number" {
    if type(value) not in (int, float) { return _type-error(path, "number", value) }
    return ()
  }
  if kind == "array" {
    if type(value) != array { return _type-error(path, "array", value) }
    return value.enumerate()
      .map(((i, elem)) => _validate(schema.elem, elem, path + (i,)))
      .flatten()
  }
  if kind == "object" {
    if type(value) != dictionary { return _type-error(path, "object", value) }
    let per-key-errs = value.pairs().map(((key, sub-value)) => {
      if key in schema.shape {
        _validate(schema.shape.at(key), sub-value, path + (key,))
      } else {
        // Valid-keys list only assembled on the unknown-key branch so
        // the happy path skips the join. An unknown key with a null
        // value is still flagged — silently swallowing typos would
        // defeat the point of strict validation.
        let valid-keys-str = schema.shape.keys().join(", ")
        ((
          path: path + (key,),
          message: "unknown key " + repr(key) + ". Valid keys: " + valid-keys-str + ".",
        ),)
      }
    }).flatten()
    // A required key whose value is explicit null counts as missing —
    // null-as-absent applies uniformly.
    let required = schema.at("required-keys", default: ())
    let missing-errs = required
      .filter(k => k not in value or value.at(k) == none)
      .map(k => (
        path: path + (k,),
        message: "missing required key " + repr(k) + ".",
      ))
    return per-key-errs + missing-errs
  }
  panic("json-resume: internal — unknown schema kind " + repr(kind))
}
