Pass 1313: Discriminant / Variant / Record vertical slice legality

This pass adds Editor.Ada_Discriminant_Variant_Record_Vertical_Slice_Legality.
It is a concrete vertical semantic slice, not another diagnostic/provenance/recheck
wrapper.

The pass models source-shaped Ada record, discriminant, variant, aggregate, delta
aggregate, component-selection, record-extension, and representation-clause rows.
It checks discriminant presence and type compatibility, discriminant defaults,
discriminant constraints, discriminant-dependent component legality, variant
coverage, overlapping/non-static variant choices, inactive variant components,
record aggregate discriminant/component completeness, duplicate components,
component type mismatches, named/positional aggregate mixing, record delta-update
target/component compatibility, private/limited view barriers, tagged extension
blockers, representation layout conflicts, controlled/finalized component
blockers, accessibility, initialization, subtype/range, predicate, overload, and
source/AST/type/layout fingerprint freshness.

The AUnit test package is
Test_Ada_Discriminant_Variant_Record_Vertical_Slice_Legality_Pass1313 and is
registered in Core_Suite.  The tests use source-shaped discriminated record,
variant part, record aggregate, delta aggregate, component selection, layout,
private/limited view, controlled/finalization, accessibility, and stale-fingerprint
scenarios rather than synthetic closure-state transitions.
