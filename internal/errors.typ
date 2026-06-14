// Error-formatting helpers. `_format-path` turns a path tuple into a
// human-readable string; `_format-report` (added in the next commit)
// turns a list of errors into a panic-ready message.

// Path-tuple → readable string. Strings join with ".", integers
// render as "[i]". Empty path renders as "<root>" so a top-level
// type error reads `"<root>: expected object, got …"`.
#let _format-path(parts) = {
  if parts.len() == 0 { return "<root>" }
  let out = ""
  for part in parts {
    if type(part) == int {
      out += "[" + str(part) + "]"
    } else {
      if out.len() > 0 { out += "." }
      out += part
    }
  }
  out
}
