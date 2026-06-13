# Editor Phase 579 - Pass719 derived/tagged type extension grammar depth

Pass719 deepens structural Ada parsing for derived, tagged, private-extension,
and record-extension type definitions in the internal token cursor.

Implemented scope:

- explicit abstract/tagged/limited type modifier productions
- derived parent subtype retention
- derived interface parent-list retention
- derived private-extension markers for `with private`
- derived record-extension markers for `with record ... end record`
- derived null-record-extension markers for `with null record`
- bounded recovery when a derived type has `with` without a private or record extension

This pass preserves the existing architecture: parsing remains snapshot-owned,
bounded, deterministic, and analysis-only. It does not introduce rendering-side
parsing, LSP, compiler invocation, external parser generators, scripts, or dirty
state mutation.

This improves structural grammar coverage for Ada derived/tagged type extensions.
It is not compiler-grade legality checking for tagged-type derivation, interface
implementation legality, private-extension completion, record-extension legality,
abstract operation inheritance, dispatching, visibility, freezing, or conformance
rules.
