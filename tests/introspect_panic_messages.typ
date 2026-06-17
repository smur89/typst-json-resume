// Typst can't catch panics, so source-level substring assertions are
// the closest available proxy for "this message survives refactors".
// Same approach as tests/lens_panic_messages.typ.
//
// **Coverage rule:** every `assert(...)` site in
// `internal/introspect.typ` is pinned below. A new assert added in
// an MR that touches that file should land its pin in the same MR.

#let src = read("../internal/introspect.typ")

// `paths-of-kind` rejects container-kind names (`"object"`, `"array"`)
// as the kind-name argument. The walker descends through containers,
// so accepting one would silently return () for every call and mask
// the typo. Also rejects misspellings (`"strring"`) — only declared
// leaf kinds pass.
#assert(src.contains("paths-of-kind kind-name"))
#assert(src.contains("not a recognised leaf kind"))
