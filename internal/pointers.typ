// RFC 6901 JSON Pointer interop. Path tuples used by lenses
// (`("basics", "email")`) and validator error reports (`("work",
// 0, "highlights", 1)`) <-> the "/basics/email" / "/work/0/
// highlights/1" form external tooling (editor extensions, schema
// linters, JSON Schema doc generators) expects.
//
// Encoding accepts str (object key) or int (array index) segments;
// other types panic. Decoding parses tokens matching JSON Pointer's
// array-index ABNF (`0` | `[1-9][0-9]*`) back to int; everything
// else stays str. This means round-trip is only stable for paths
// whose segment types are unambiguous — a string segment that
// looks like an integer (`("work", "0")`) round-trips to `("work",
// 0)`. Realistic paths from validator / lens code never carry
// numeric strings, so this isn't a concern in practice.

// Order matters: `~1` → `/` first would let an `~1` token round-
// trip wrong (e.g. `~01` should decode to `~1`, not `/0`). Encode
// `~` first so subsequent `/` encodes don't see the new `~0` we
// just introduced. Decode mirrors: `~1` before `~0`.
#let _escape-token(s) = s.replace("~", "~0").replace("/", "~1")
#let _unescape-token(s) = s.replace("~1", "/").replace("~0", "~")

// RFC 6901 array-index ABNF: `0` | `[1-9][0-9]*` — leading zeros
// (other than "0" itself) aren't valid array indices, so e.g. "01"
// round-trips as the string "01" rather than becoming int 1.
#let _int-token-re = regex("^(0|[1-9][0-9]*)$")
#let _try-int(token) = if token.match(_int-token-re) != none { int(token) } else { token }

// Convert a path tuple to an RFC 6901 JSON Pointer string. Empty
// path → empty string (whole-document reference per spec).
#let path-to-pointer(path) = {
  if path.len() == 0 { return "" }
  let parts = path.map(seg => {
    if type(seg) == str { _escape-token(seg) }
    else if type(seg) == int { str(seg) }
    else {
      panic(
        "gairm-import: path-to-pointer expected a str or int segment, got: "
          + repr(seg) + " (" + repr(type(seg)) + ")."
      )
    }
  })
  "/" + parts.join("/")
}

// Inverse. Empty string → empty path. A bare "/" decodes to a
// single empty-string segment (RFC 6901: "/" means "the empty
// string key at root"). Otherwise the pointer must start with "/".
#let pointer-to-path(pointer) = {
  if pointer == "" { return () }
  if not pointer.starts-with("/") {
    panic(
      "gairm-import: pointer-to-path expected \"\" or a pointer starting with \"/\", got: "
        + repr(pointer) + "."
    )
  }
  pointer.slice(1).split("/").map(_unescape-token).map(_try-int)
}
