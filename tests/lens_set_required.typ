// Pins the set-required lens companion: replaces an object schema's
// required-keys via lens, drives validate's "missing required key"
// errors from the new list, preserves the immutability contract,
// surfaces typos as construction-time panics.

#import "../lib.typ": (
  lens, set-required, object, validate,
  str-type, number-type,
)

// ---- happy: empty → required ---------------------------------------

#let basics = object((name: str-type, email: str-type, summary: str-type))
#let schema = object((basics: basics))
#assert.eq(schema.shape.basics.required-keys, ())

#let identity = lens(())
#let basics-lens = lens(("basics",))

#let strict = set-required(schema, basics-lens, ("name", "email"))
#assert.eq(strict.shape.basics.required-keys, ("name", "email"))

// validate now emits missing-required errors for the new list.
#let errs = validate((basics: (summary: "hi")), schema: strict)
#assert.eq(errs.len(), 2)
#let paths = errs.map(e => e.path)
#assert(("basics", "name") in paths)
#assert(("basics", "email") in paths)
#assert(errs.at(0).message.contains("missing required key"))

// Satisfying both required keys clears the errors.
#assert.eq(
  validate(
    (basics: (name: "Alice", email: "alice@example.com", summary: "hi")),
    schema: strict,
  ),
  (),
)

// ---- replacing an existing required-keys list ----------------------

#let stricter = set-required(strict, basics-lens, ("name", "email", "summary"))
#assert.eq(stricter.shape.basics.required-keys, ("name", "email", "summary"))

// Replacement, not merge — passing the empty tuple drops every required key.
#let relaxed = set-required(stricter, basics-lens, ())
#assert.eq(relaxed.shape.basics.required-keys, ())

// ---- identity lens replaces the root's required-keys ---------------

#let root-strict = set-required(schema, identity, ("basics",))
#assert.eq(root-strict.required-keys, ("basics",))

// ---- immutability of the input -------------------------------------

#assert.eq(schema.shape.basics.required-keys, ())
#assert.eq(strict.shape.basics.required-keys, ("name", "email"))

// ---- source-level panic pins (Typst can't catch panics) ------------

#let src = read("../internal/lens.typ")
#assert(src.contains("set-required keys not in object shape"))
#assert(src.contains("_require-object(parent, \"set-required\")"))
