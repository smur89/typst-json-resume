// Error-formatting helpers. `_format-path` turns a path tuple into a
// human-readable string; `_format-report` renders a list of error
// records into one panic-ready message.

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

// Renders a list of {path, message} errors into a single
// human-readable string suitable for `panic(...)`.
#let _format-report(errors) = {
  let n = errors.len()
  let noun = if n == 1 { "problem" } else { "problems" }
  let lines = errors.map(e => "  - " + _format-path(e.path) + ": " + e.message)
  "json-resume: found " + str(n) + " " + noun + " in the input:\n" + lines.join("\n")
}
