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
//
// First pin includes the `gairm-import:` prefix so a regression to
// an old prefix (e.g. the `json-resume:` form this commit fixed)
// fails loud. The second pin can't take the prefix without spanning
// a source-line break (the message is split across `"gairm-import:
// paths-of-kind ..."` + `"is not a recognised leaf kind..."`), but
// the first pin guards the prefix path on its own.
#assert(src.contains("gairm-import: paths-of-kind kind-name"))
#assert(src.contains("not a recognised leaf kind"))
