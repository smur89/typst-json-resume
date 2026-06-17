// Typst can't catch panics, so source-level substring assertions are
// the closest available proxy for "this message survives refactors".
// Same approach as tests/lens_panic_messages.typ.
//
// `_validate` returns error records via `_type-error` / `_err` —
// those are exercised behaviorally throughout tests/validate_*.typ.
// This file covers the lone genuine `panic`.

#let src = read("../internal/validate.typ")

// Prefix included so a project-wide rename surfaces here.
#assert(src.contains("gairm-import: internal — unknown schema kind"))
