// Typst can't catch panics, so source-level substring assertions are
// the closest available proxy for "this message survives refactors".
// Same approach as tests/lens_panic_messages.typ.
//
// `_override-fold`'s assert is exercised behaviorally by
// tests/schema_strict.typ (loads the strict variant, would trip on
// upstream drift). These pins additionally catch reword refactors.

#let src = read("../internal/schema.typ")

// Source has `"gairm-import: " + list-name + " must target"`; pin
// the source expression so a rename or extraction surfaces here.
#assert(src.contains("\"gairm-import: \" + list-name"))
#assert(src.contains("must target"))
#assert(src.contains("leaves only"))
#assert(src.contains("Audit upstream schema bump"))
