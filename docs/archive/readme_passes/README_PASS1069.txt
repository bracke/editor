Pass1069 adds Editor.Ada_Generic_Formal_Package_Substitutions.

Scope:
- Consume Editor.Ada_Generic_Formal_Package_Nested_Conformance.
- Expand aggregate formal-package nested conformance into per-nested-actual substitution entries.
- Classify substitutions as substituted, boxed, mismatch, missing, wrong-generic, unresolved, malformed, or unknown.
- Preserve instance/formal/actual identities, syntax nodes, formal package name, expected generic, nested position, formal/actual text, source span, source fingerprint, and deterministic result fingerprint.
- Extend Editor.Ada_Generic_Contract_Diagnostics with Build_With_Formal_Package_Substitutions and diagnostic kinds/counters for formal-package substitution mismatch, missing, wrong-generic, unresolved, and unknown cases.
- Add Test_Ada_Generic_Formal_Package_Substitutions_Pass1069.

Invariant:
The pass is deterministic, bounded, snapshot-owned, and projection-only. It performs no rendering-side parsing, no file save/reload, no editor state mutation, no command/keybinding/workspace/render mutation, no compiler invocation, and no external parser-generator integration.

This pass adds one compiler-grade building block for formal package contract substitution analysis. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
