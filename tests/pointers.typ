// RFC 6901 JSON Pointer interop. Encode / decode coverage plus the
// round-trip property for the segment types validator + lens paths
// actually produce.

#import "../lib.typ": path-to-pointer, pointer-to-path

// ---- encode ---------------------------------------------------------

#assert.eq(path-to-pointer(()), "")
#assert.eq(path-to-pointer(("basics", "email")), "/basics/email")

// Mixed str + int — the shape validator emits for array-element errors.
#assert.eq(
  path-to-pointer(("work", 0, "highlights", 1)),
  "/work/0/highlights/1",
)

// `/` in an object key gets escaped as `~1`.
#assert.eq(path-to-pointer(("a/b",)), "/a~1b")

// `~` escapes as `~0`. Encoding order ensures `~` → `~0` runs before
// `/` → `~1`, so a stray `/` in the original doesn't get double-hit.
#assert.eq(path-to-pointer(("~tilde",)), "/~0tilde")

// Both special chars in the same segment, in the order that would
// catch order-of-encoding bugs.
#assert.eq(path-to-pointer(("a~b/c",)), "/a~0b~1c")

// Single empty-string segment → "/" (root + empty key per RFC 6901).
#assert.eq(path-to-pointer(("",)), "/")

// ---- decode ---------------------------------------------------------

#assert.eq(pointer-to-path(""), ())
#assert.eq(pointer-to-path("/basics/email"), ("basics", "email"))

// Array-index ABNF: only `0` or `[1-9][0-9]*` decode to int.
#assert.eq(pointer-to-path("/work/0/highlights/1"), ("work", 0, "highlights", 1))

// Leading zeros aren't valid array indices, so "01" stays str.
#assert.eq(pointer-to-path("/work/01"), ("work", "01"))

// `~1` and `~0` reverse the escapes (in that order, to dodge the
// `~01` → `/0` mis-decode if processed left-to-right).
#assert.eq(pointer-to-path("/a~1b"), ("a/b",))
#assert.eq(pointer-to-path("/~0tilde"), ("~tilde",))
#assert.eq(pointer-to-path("/a~0b~1c"), ("a~b/c",))

// `~01` is "~" followed by "1" — must decode in the order
// `~1` → `/` first, `~0` → `~` second, so `~01` reads as `~` + `1`
// (string "~1"), NOT `/` + `0` (string "/0").
#assert.eq(pointer-to-path("/~01"), ("~1",))

// Single empty-string segment.
#assert.eq(pointer-to-path("/"), ("",))

// ---- round-trip -----------------------------------------------------
//
// pointer-to-path(path-to-pointer(p)) == p for any p whose segment
// types are unambiguous (str object keys + int array indices — the
// only shapes lens / validator code produces).

#let round-trip-cases = (
  (),
  ("basics", "email"),
  ("work", 0, "highlights", 1),
  ("a/b",),
  ("~tilde",),
  ("a~b/c",),
  ("",),
  ("nested", "items", 3, "sub", "deep"),
)
#for p in round-trip-cases {
  assert.eq(
    pointer-to-path(path-to-pointer(p)),
    p,
    message: "round-trip lost path " + repr(p),
  )
}

// ---- error cases ----------------------------------------------------
//
// Source-level message pins (Typst can't catch panics) — same
// approach as tests/lens_panic_messages.typ.

#let src = read("../internal/pointers.typ")
#assert(src.contains("path-to-pointer expected a str or int segment"))
// Escaped quotes (\") in the source bytes don't round-trip through
// Typst's string-literal escape processing — match the unescaped
// suffix instead.
#assert(src.contains("pointer-to-path expected"))
#assert(src.contains("or a pointer starting with"))
