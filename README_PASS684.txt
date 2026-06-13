Pass 684 - Generic formal type modifier and parent grammar depth

This pass improves structural grammar coverage for Ada generic formal type
definitions.  The token cursor now retains formal-type modifiers, formal
interface parent subtypes, explicit formal private extensions, and aliased
formal array component definitions instead of exposing only the broader formal
type family node.

Implemented changes:

- Added `Production_Formal_Type_Modifier` for modifiers owned by generic formal
  private, derived, and interface type definitions.
- Added `Production_Formal_Interface_Subtype` for each subtype in a generic
  formal derived/interface `and` interface list.
- Added `Production_Formal_Private_Extension_Definition` for `with private` in
  formal derived type definitions.
- Updated formal array type parsing so `of aliased Element` retains the aliased
  component marker before parsing the component subtype indication.
- Preserved existing generic formal type family productions, subtype-mark,
  selected-name, attribute-reference, access-type, discriminant, aspect, and
  recovery behaviour.
- Added AUnit coverage for formal private modifiers, formal derived interface
  parents, formal interface parent subtypes with attribute suffixes, formal
  private extensions, aliased formal array components, and recovery into the
  generic unit body.

This is structural parser coverage for editor language intelligence.  It is not
compiler-grade legality checking for generic formal type contracts, interface
inheritance, private extension legality, array component legality, visibility,
staticness, freezing, or conformance rules.
