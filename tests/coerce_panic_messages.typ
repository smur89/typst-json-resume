// Typst can't catch panics, so source-level substring assertions are
// the closest available proxy for "this message survives refactors".
// Same approach as tests/lens_panic_messages.typ.

#let src = read("../internal/coerce.typ")

// `_expect(expected, value)` builds every assert message — pin
// prefix + suffix so a template-level rename surfaces.
#assert(src.contains("gairm-import: coerce expected"))
#assert(src.contains("Run validate(data) first"))

// Per-branch expected-type literals — pin each so dropping a
// dispatch branch fails loud.
#assert(src.contains("_expect(\"a string\""))
#assert(src.contains("_expect(\"a number\""))
#assert(src.contains("_expect(\"a boolean\""))
#assert(src.contains("_expect(\"null\""))
// `enum`'s expected is built dynamically; pin the literal prefix.
#assert(src.contains("\"one of \""))
#assert(src.contains("_expect(\"an array\""))
#assert(src.contains("_expect(\"an object\""))

// Terminal dispatch fallthrough (with prefix).
#assert(src.contains("gairm-import: internal — unknown schema kind"))
