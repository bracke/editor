Pass1127 — Record / variant / discriminant aggregate legality

This pass adds Editor.Ada_Record_Variant_Aggregate_Legality, a deterministic snapshot-owned semantic closure layer for record aggregates, extension aggregates, variant aggregates, discriminant constraints, component associations, and representation-layout aggregate use sites.

The new layer connects existing aggregate structural legality, predicate/invariant use-site legality, and representation/layout/stream integration legality. It classifies complete legal record aggregates, legal extension aggregates, legal variant aggregates, legal discriminant constraints, defaulted-discriminant legality, and representation-layout-compatible aggregate uses.

It also diagnoses missing components, duplicate components, component type mismatch, positional associations after named associations, missing/duplicate/type-mismatched discriminants, unconstrained aggregates without discriminants, duplicate/overlapping/unreachable/incomplete variant choices, variant layout holes/overlaps, discriminant layout errors, linked aggregate legality failures, linked predicate/invariant failures, linked representation/layout failures, private/limited-view barriers, cross-unit unresolved views, and indeterminate aggregate closure.

The package provides deterministic counters, status/kind/type/node lookups, row identity, source fingerprints, linked semantic statuses, and model fingerprints. It performs no parsing, file IO, save/reload, dirty-state mutation, command/keybinding/workspace/render mutation, compiler invocation, LSP integration, external parser generation, Python integration, or shell-script integration.

AUnit regression added:
- Test_Ada_Record_Variant_Aggregate_Legality_Pass1127

This pass adds one compiler-grade building block for record, variant, discriminant, aggregate, and representation-layout semantic closure. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, and cross-unit semantic closure layers are fully integrated.
