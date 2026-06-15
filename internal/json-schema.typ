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

// Resolve an internal $ref like "#/definitions/iso8601" against the
// document root. `seen` is the chain of refs traversed so far; a
// repeat indicates a cycle (e.g. definitions.alias → alias) and we
// panic at the first repeat rather than letting Typst's recursion
// limit fire deep in the stack.
#let _resolve-ref(ref, root, seen) = {
  if not ref.starts-with("#/") {
    panic(
      "json-resume: schema-from-json-schema only supports internal $ref " +
        "(starting with \"#/\"), got: " + repr(ref) + ".",
    )
  }
  if ref in seen {
    panic(
      "json-resume: schema-from-json-schema — cyclic $ref detected: " +
        seen.map(repr).join(" → ") + " → " + repr(ref) + ".",
    )
  }
  if ref == "#/" {
    panic(
      "json-resume: schema-from-json-schema — $ref \"#/\" cannot " +
        "reference the document root.",
    )
  }
  let parts = ref.slice(2).split("/").filter(p => p != "")
  parts.fold(root, (acc, key) => {
    if type(acc) != dictionary or key not in acc {
      panic(
        "json-resume: schema-from-json-schema — $ref " + repr(ref) +
          " could not be resolved (segment " + repr(key) + " missing).",
      )
    }
    acc.at(key)
  })
}

// Composition / advanced keywords that aren't in the v0.2 scope.
// Listed explicitly so a schema using one fails loudly instead of
// silently dropping the constraint.
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
      panic(
        "json-resume: schema-from-json-schema — unsupported JSON Schema " +
          "keyword: " + repr(keyword) + ". Composition keywords (allOf/anyOf/" +
          "oneOf), enum, and conditional schemas are out of scope.",
      )
    }
  }
  let t = js.at("type", default: none)
  if t == "string" {
    // TODO(#10): once feat/format-validation lands, dispatch on format
    // to date-string / uri-string / email-string. For now everything
    // is str-type — strictly looser than the upstream spec.
    let fmt = js.at("format", default: none)
    if fmt != none and fmt not in ("uri", "email", "date", "date-time") {
      panic(
        "json-resume: schema-from-json-schema — unsupported string format: " +
          repr(fmt) + ".",
      )
    }
    return str-type
  }
  if t == "number" or t == "integer" { return number-type }
  if t == "array" {
    let items = js.at("items", default: none)
    if items == none {
      panic("json-resume: schema-from-json-schema — array schema missing \"items\".")
    }
    return array-of(_from-json-schema(items, root, seen))
  }
  if t == "object" {
    // JSON Schema `{ "type": "object" }` without `properties` means
    // "any object" (open). The validator engine is strict by design —
    // it can't represent open objects — so refuse to translate
    // rather than silently produce a validator that rejects every
    // key. Schema authors needing pass-through fields should declare
    // them in `properties`.
    if "properties" not in js {
      panic(
        "json-resume: schema-from-json-schema — open object schemas " +
          "(`type: \"object\"` with no `properties`) are out of scope; " +
          "every field must be declared.",
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
    panic(
      "json-resume: schema-from-json-schema — unsupported JSON Schema type: " +
        repr(t) + ".",
    )
  }
  panic(
    "json-resume: schema-from-json-schema — unrecognised JSON Schema " +
      "fragment (no \"type\" or \"$ref\"); keys: " + repr(js.keys()) + ".",
  )
}

#let schema-from-json-schema(js) = _from-json-schema(js, js, ())
