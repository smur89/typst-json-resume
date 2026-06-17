// Typst can't catch panics, so source-level substring assertions are
// the closest available proxy for "this message survives refactors".
// Same approach as tests/lens_panic_messages.typ.

#let src = read("../internal/kinds.typ")

// Both `object()` construction-time guards; prefix included so a
// project-wide rename surfaces here.
#assert(src.contains("gairm-import: object() additional must be none, false, true, or a schema dict"))
#assert(src.contains("gairm-import: object() required-keys references keys not in shape"))
