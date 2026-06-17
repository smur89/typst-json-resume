// Typst can't catch panics, so source-level substring assertions are
// the closest available proxy for "this message survives refactors".
// Same approach as tests/lens_panic_messages.typ.
//
// **Coverage rule:** every `_bail(...)` / `panic(...)` site in
// `internal/json-schema.typ` is pinned below. A new bail site added in
// an MR that touches that file should land its pin in the same MR.
// Half-coverage gives false comfort (the unpinned sites can drift
// silently); this file exists to be exhaustive.
//
// **Substring rule:** each pin is a UNIQUE substring of its target
// message AND fits on a single source line — multi-line string
// concatenation (e.g. `"foo " + "bar"`) means the contiguous bytes
// don't include `"foo bar"`. Escaped quotes (`\"`) in source bytes
// don't round-trip through Typst's string-literal escape processing,
// so prefix-only matches sidestep that.

#let src = read("../internal/json-schema.typ")

// --- $ref resolution -------------------------------------------------

// External $refs would need a fetcher the engine deliberately doesn't have.
#assert(src.contains("only internal $ref (starting with"))

// `seen` cycle detection. A $ref chain that revisits a previously-seen
// reference panics before Typst's recursion limit fires deep in the
// stack — a refactor that stopped threading `seen` would silently
// break this guard.
#assert(src.contains("cyclic $ref detected"))

// `#/` (without a JSON Pointer) would self-resolve to the root and
// loop forever; rejected before the cycle check runs.
#assert(src.contains("cannot reference the document root"))

// Resolution failure midway through a $ref path — the dead-end
// segment is named in the message.
#assert(src.contains("could not be resolved"))

// $ref value is the wrong type (not a string). Source has escaped
// `\"$ref\"`; pin via the unambiguous suffix.
#assert(src.contains("$ref\\\" must be a string"))

// --- top-of-translator dispatch / entry guard ------------------------

// Composition / conditional keywords are deliberately out of scope.
// Message names allOf/anyOf/oneOf explicitly so a reader knows what
// *is* expected here on bumps to draft 2020-12.
#assert(src.contains("unsupported JSON Schema keyword"))
#assert(src.contains("Composition keywords (allOf/anyOf/oneOf)"))

// A non-dict, non-path input to schema-from-json-schema. The boundary
// rejection means the diagnostic carries the standard prefix instead
// of failing deep inside _from-json-schema.
#assert(src.contains("expected a parsed JSON Schema dict or path"))

// Fallthrough at the end of _from-json-schema: no recognised type or
// $ref. Names the keys present so the user can spot what's missing.
#assert(src.contains("unrecognised JSON Schema fragment"))

// --- per-type shape checks ------------------------------------------
//
// Source bytes contain escaped quotes (`\"enum\"`) which don't
// round-trip through Typst's literal-string escape processing; pin
// on the suffix instead.

#assert(src.contains("enum\\\" must be an array of values"))
#assert(src.contains("pattern\\\" must be a string"))
#assert(src.contains("unsupported string format"))
#assert(src.contains("array schema missing"))
#assert(src.contains("items\\\" must be a schema object"))
#assert(src.contains("properties\\\" must be an object"))
#assert(src.contains("required\\\" must be an array of field names"))
#assert(src.contains("additionalProperties\\\" must be a schema, true, or false"))

// Fully-open object schemas (`type: "object"` with neither
// `properties` nor `additionalProperties`) are rejected at translate
// time — the engine is strict by design and a silently-open object
// would invert the intent.
#assert(src.contains("open object schemas"))
#assert(src.contains("must be declared or covered"))

// --- type-union dispatch --------------------------------------------

// Only [X, "null"] nullable unions are supported. Multi-non-null
// unions would need discriminated-union machinery that's out of
// scope (#84 tracks the strict-null follow-up).
#assert(src.contains("only supported as nullable wraps"))

// --- constraint keywords (#76) --------------------------------------

// Bad-shape `minLength` / `maxLength` / `minItems` / `maxItems` values.
#assert(src.contains("must be a non-negative integer"))

// Bad-shape `minimum` / `maximum` / `exclusiveMinimum` /
// `exclusiveMaximum` / `multipleOf` values.
#assert(src.contains("must be a number"))

// `multipleOf` must be > 0 (zero or negative would never match).
#assert(src.contains("must be > 0"))

// `uniqueItems` must be a boolean.
#assert(src.contains("must be a boolean"))

// Inclusive-bound contradictions (minLength > maxLength, etc.).
#assert(src.contains("is unsatisfiable"))

// Exclusive-bound contradictions (exclusiveMinimum >= maximum, etc.).
#assert(src.contains("leave no satisfying value"))
