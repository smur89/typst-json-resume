// Typst can't catch panics, so source-level substring assertions are
// the closest available proxy for "this message survives refactors".
// Same approach as tests/lens_panic_messages.typ.

#let src = read("../internal/introspect.typ")

// `paths-of-kind` leaf-kind guard. First pin includes the prefix so
// a regression to the pre-rename `json-resume:` form fails loud;
// the second can't take the prefix without spanning a source-line
// break (the message is split across two `+ "..."` chunks).
#assert(src.contains("gairm-import: paths-of-kind kind-name"))
#assert(src.contains("not a recognised leaf kind"))
