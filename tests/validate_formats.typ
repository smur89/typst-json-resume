// Format-specialised string combinators reject malformed values with
// path-qualified error messages that name the expected format and
// give an example. Coverage:
//
//  - date-string  → iso8601 (YYYY / YYYY-MM / YYYY-MM-DD)
//  - uri-string   → scheme://rest (permissive)
//  - email-string → local@domain.tld (permissive)
//
// Each format has positive cases (errors list empty), negative cases
// (one path-qualified error), and a spot-check that the message
// names the format and embeds the offending value via repr(...).

#import "../internal/validate.typ": _validate
#import "../internal/schema.typ": date-string, uri-string, email-string, object, array-of

// Combinator shapes are plain tagged records — the validator dispatches
// on `.kind` and the coercer treats them as pass-through strings.
#assert.eq(date-string,  (kind: "date-string"))
#assert.eq(uri-string,   (kind: "uri-string"))
#assert.eq(email-string, (kind: "email-string"))

// ---- date-string ----------------------------------------------------

// Year only, year-month, year-month-day — all three iso8601 shapes
// the canonical JSON Resume schema accepts.
#assert.eq(_validate(date-string, "2024",       ("d",)), ())
#assert.eq(_validate(date-string, "2024-01",    ("d",)), ())
#assert.eq(_validate(date-string, "2024-01-15", ("d",)), ())
#assert.eq(_validate(date-string, "1999-12-31", ("d",)), ())

#let date-fail(value, path) = {
  let errs = _validate(date-string, value, path)
  assert.eq(errs.len(), 1, message: "expected one error for " + repr(value))
  assert.eq(errs.at(0).path, path)
  errs.at(0).message
}

// Slash-separated, free-text, partial, three-digit year, four-digit
// non-iso forms — all rejected. The message names ISO-8601, gives an
// example, and embeds the offending value via repr.
#let m1 = date-fail("2024/01/15", ("basics", "startDate"))
#assert(m1.contains("ISO-8601"))
#assert(m1.contains("e.g. \"2024-01-15\""))
#assert(m1.contains("\"2024/01/15\""))

#assert(date-fail("jan 2024",   ("d",)).contains("ISO-8601"))
#assert(date-fail("2024-1-15",  ("d",)).contains("ISO-8601"))
#assert(date-fail("24-01-15",   ("d",)).contains("ISO-8601"))
#assert(date-fail("",           ("d",)).contains("ISO-8601"))
#assert(date-fail("2024-01-15T10:00", ("d",)).contains("ISO-8601"))

// Wrong type yields a type-error, not a format-error — the format gate
// only fires once we know we have a string.
#let date-type-err = _validate(date-string, 2024, ("d",))
#assert.eq(date-type-err.len(), 1)
#assert(date-type-err.at(0).message.contains("expected string"))
#assert(date-type-err.at(0).message.contains("got integer"))

// ---- uri-string -----------------------------------------------------

// uri-string is "scheme + `://` + rest" — the canonical `url` /
// `image` / `canonical` fields in JSON Resume are all http(s)-shaped,
// so opaque schemes like `mailto:` and `urn:` fall outside the gate
// by design. Promote later if a caller needs them.
#assert.eq(_validate(uri-string, "https://example.com",        ("u",)), ())
#assert.eq(_validate(uri-string, "http://example.com/path",    ("u",)), ())
#assert.eq(_validate(uri-string, "git+ssh://host/repo.git",    ("u",)), ())

#let uri-fail(value, path) = {
  let errs = _validate(uri-string, value, path)
  assert.eq(errs.len(), 1, message: "expected one error for " + repr(value))
  assert.eq(errs.at(0).path, path)
  errs.at(0).message
}

#let m2 = uri-fail("not-a-uri", ("basics", "url"))
#assert(m2.contains("URI"))
#assert(m2.contains("e.g. \"https://example.com\""))
#assert(m2.contains("\"not-a-uri\""))

#assert(uri-fail("example.com",     ("u",)).contains("URI"))
#assert(uri-fail("://example.com",  ("u",)).contains("URI"))
#assert(uri-fail("https://",        ("u",)).contains("URI"))
#assert(uri-fail("",                ("u",)).contains("URI"))

// ---- email-string ---------------------------------------------------

#assert.eq(_validate(email-string, "name@example.com",     ("e",)), ())
#assert.eq(_validate(email-string, "first.last@host.co.uk",("e",)), ())
#assert.eq(_validate(email-string, "user+tag@example.com", ("e",)), ())

#let email-fail(value, path) = {
  let errs = _validate(email-string, value, path)
  assert.eq(errs.len(), 1, message: "expected one error for " + repr(value))
  assert.eq(errs.at(0).path, path)
  errs.at(0).message
}

#let m3 = email-fail("name@", ("basics", "email"))
#assert(m3.contains("email"))
#assert(m3.contains("e.g. \"name@example.com\""))
#assert(m3.contains("\"name@\""))

#assert(email-fail("@example.com", ("e",)).contains("email"))
#assert(email-fail("name",         ("e",)).contains("email"))
#assert(email-fail("name@host",    ("e",)).contains("email"))  // no dot in domain
#assert(email-fail("a b@host.com", ("e",)).contains("email"))  // whitespace in local
#assert(email-fail("",             ("e",)).contains("email"))

// ---- Nested under array-of / object: paths stay correct -------------

#let _work = object((url: uri-string, startDate: date-string))
#let schema = object((work: array-of(_work), email: email-string))

#let nested-errs = _validate(
  schema,
  (
    work: (
      (url: "https://ok.example", startDate: "2024-01"),
      (url: "nope",                startDate: "2024/01/15"),
    ),
    email: "name@",
  ),
  (),
)
#assert.eq(nested-errs.len(), 3)

// Path-qualified errors are sorted by the validator's natural walk
// (per-key for the array element, then siblings). Spot-check each.
#let paths = nested-errs.map(e => e.path)
#assert(("work", 1, "url")       in paths)
#assert(("work", 1, "startDate") in paths)
#assert(("email",)               in paths)
