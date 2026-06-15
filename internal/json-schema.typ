// JSON Schema → Typst-schema translator. Mechanical mapping for the
// draft-7 subset the canonical JSON Resume document actually uses;
// unsupported keywords and shapes panic with an explicit message
// rather than silently dropping constraints.
//
// Format-aware string kinds (date-string / uri-string / email-string)
// land in #10 (feat/format-validation). Until they're on main this
// translator degrades all `format`s to `str-type` with a TODO note;
// a one-line follow-up swap will wire them up.

#import "schema.typ": str-type, content-type, number-type, array-of, object

// Single source of truth for the panic prefix — every error in this
// module is greppable by "schema-from-json-schema —".
#let _bail(msg) = panic("json-resume: schema-from-json-schema — " + msg)

// Resolve an internal $ref like "#/definitions/iso8601" against the
// document root. `seen` is the chain of refs traversed so far; a
// repeat indicates a cycle (e.g. definitions.alias → alias) and we
// panic at the first repeat rather than letting Typst's recursion
// limit fire deep in the stack.
#let _resolve-ref(ref, root, seen) = {
  if not ref.starts-with("#/") {
    _bail("only internal $ref (starting with \"#/\") is supported, got: " + repr(ref) + ".")
  }
  if ref in seen {
    _bail("cyclic $ref detected: " + seen.map(repr).join(" → ") + " → " + repr(ref) + ".")
  }
  if ref == "#/" {
    _bail("$ref \"#/\" cannot reference the document root.")
  }
  let parts = ref.slice(2).split("/").filter(p => p != "")
  parts.fold(root, (acc, key) => {
    if type(acc) != dictionary or key not in acc {
      _bail("$ref " + repr(ref) + " could not be resolved (segment " + repr(key) + " missing).")
    }
    acc.at(key)
  })
}

// Composition / advanced keywords that aren't in the v0.2 scope.
#let _unsupported-keywords = (
  "allOf", "anyOf", "oneOf", "not",
  "enum", "const",
  "if", "then", "else",
  "dependencies", "dependentRequired", "dependentSchemas",
)

#let _from-json-schema(js, root, seen) = {
  if "$ref" in js {
    let ref = js.at("$ref")
    return _from-json-schema(
      _resolve-ref(ref, root, seen),
      root,
      seen + (ref,),
    )
  }
  for keyword in _unsupported-keywords {
    if keyword in js {
      _bail(
        "unsupported JSON Schema keyword: " + repr(keyword) +
          ". Composition keywords (allOf/anyOf/oneOf), enum, and conditional schemas are out of scope.",
      )
    }
  }
  let t = js.at("type", default: none)
  if t == "string" {
    // TODO(#10): dispatch on format to date-string/uri-string/email-string
    // once feat/format-validation lands; for now `format` only gates the
    // allow-list so unknown formats still panic.
    let fmt = js.at("format", default: none)
    if fmt != none and fmt not in ("uri", "email", "date", "date-time") {
      _bail("unsupported string format: " + repr(fmt) + ".")
    }
    return str-type
  }
  if t == "number" or t == "integer" { return number-type }
  if t == "array" {
    let items = js.at("items", default: none)
    if items == none {
      _bail("array schema missing \"items\".")
    }
    return array-of(_from-json-schema(items, root, seen))
  }
  if t == "object" {
    // The validator engine is strict by design and can't represent open
    // objects, so refuse to translate `{ "type": "object" }` without
    // `properties` rather than silently producing a validator that
    // rejects every key.
    if "properties" not in js {
      _bail(
        "open object schemas (`type: \"object\"` with no `properties`) " +
          "are out of scope; every field must be declared.",
      )
    }
    let props = js.at("properties")
    let required = js.at("required", default: ())
    return object(
      props.pairs().map(((k, v)) => (k, _from-json-schema(v, root, seen))).to-dict(),
      required-keys: required,
    )
  }
  if t in ("boolean", "null") {
    _bail("unsupported JSON Schema type: " + repr(t) + ".")
  }
  if type(t) == array {
    // JSON Schema allows `type` as an array (e.g. `["string", "null"]`
    // for nullable). Union types are out of scope; the null-as-absent
    // policy already covers the nullable case at the validator level.
    _bail("union `type` arrays are unsupported, got: " + repr(t) + ".")
  }
  _bail("unrecognised JSON Schema fragment (no recognised \"type\" or \"$ref\"); keys: " + repr(js.keys()) + ".")
}

#let schema-from-json-schema(js) = _from-json-schema(js, js, ())
