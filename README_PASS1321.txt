Pass1321: Representation/aspect operational vertical slice

This pass adds Editor.Ada_Representation_Aspect_Operational_Vertical_Slice_Legality.

It is a vertical Ada legality slice, not a diagnostic/provenance/recheck wrapper.  It
models representation and operational items through their real source spellings: aspect
specifications, attribute-definition clauses, and related pragmas.  The pass unifies
aspect and attribute-definition legality for Address, Size/Object_Size/Value_Size,
Alignment, Storage_Size, Component_Size, Bit_Order, Scalar_Storage_Order, Convention,
Import/Export, External_Name/Link_Name, stream attributes, Volatile/Atomic and component
variants, Independent and Independent_Components.

The rule engine tracks target identity and kind, private/limited/incomplete/generic-formal
view barriers, freezing order, duplicate/conflicting source spellings, static expression
requirements, address/size/alignment/storage-size validity, convention and import/export
profile checks, stream profile and view barriers, volatile/atomic compatibility, operational
attribute compatibility, and stale source/target/item fingerprints.

AUnit coverage is in Test_Ada_Representation_Aspect_Operational_Vertical_Slice_Legality_Pass1321.
The tests use source-shaped targets and representation/operational items instead of synthetic
closure-state transitions.
