// Pure validator. Returns a flat list of {path, message} records for
// every shape/type mismatch found. Empty list = valid. Path is a
// tuple of dict keys and array indices; rendering lives in errors.typ.

#let _validate(schema, value, path) = {
  let kind = schema.kind
  if kind == "str" or kind == "content" {
    if type(value) != str {
      return ((
        path: path,
        message: "expected string, got " + repr(type(value)) + ".",
      ),)
    }
    return ()
  }
  if kind == "number" {
    if type(value) != int and type(value) != float {
      return ((
        path: path,
        message: "expected number, got " + repr(type(value)) + ".",
      ),)
    }
    return ()
  }
  // array + object handled in later commits.
  return ()
}
