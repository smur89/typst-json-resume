// Typst can't catch panics, so source-level substring assertions are
// the closest available proxy for "this message survives refactors".
// Same approach as tests/lens_panic_messages.typ.
//
// **Coverage rule:** every `assert(...)` site in `internal/schema.typ`
// is pinned below. A new assert added in an MR that touches that
// file should land its pin in the same MR.
//
// Note: the `_override-fold` assert IS exercised behaviorally by
// `tests/schema_strict.typ` (the strict variant constructs the
// schema at module load time, tripping this assert on any upstream
// drift). The pin guards the message wording too — a refactor that
// reworded the diagnostic for clarity wouldn't fail the behavior
// test (which only triggers on drift), but would fail this pin.

#let src = read("../internal/schema.typ")

// `_override-fold` is the safety net for the strict variant's
// content / date overrides: each override has an expected source
// kind, and if upstream drift produces something different at the
// target path, the fold panics at module load time rather than
// silently dropping the override. The message names the offending
// path and the kind change so an upstream-bump audit is targeted.
#assert(src.contains("must target"))
#assert(src.contains("leaves only"))
#assert(src.contains("Audit upstream schema bump"))
