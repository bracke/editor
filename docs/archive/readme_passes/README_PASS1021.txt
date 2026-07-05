Editor — Pass1021

Pass1021 adds one compiler-grade expression-analysis building block: diagnostics projection for expression-type metadata.

Implemented:

- Added `Editor.Ada_Expression_Diagnostics` as a snapshot-owned diagnostics projection layer.
- Converts already-staged expression metadata into deterministic diagnostic records.
- Records stable node identity, source-line span, severity, diagnostic kind, message text, and fingerprint.
- Classifies diagnostics for expected-type mismatches, operator mismatches/ambiguity, call actual mismatches/ambiguity, aggregate mismatches, conversion mismatches, membership/range mismatches, dereference target errors, allocator target errors, Boolean-context mismatches, universal numeric range errors, concatenation mismatches, unresolved expressions, and unknown expressions.
- Added deterministic counters for errors, warnings, infos, diagnostic kinds, and model fingerprint.
- AUnit coverage was added in `Test_Ada_Expression_Diagnostics_Projection_Pass1021`.

This pass remains projection-only: it performs no parsing, file IO, editor mutation, rendering work, command registration, compiler invocation, LSP interaction, or stale-state mutation.

Full compiler-grade Ada analysis remains incomplete until the remaining semantic layers such as cross-unit visibility integration, exact overload/type checking closure, freezing/representation legality interactions, generic contract completion, and diagnostic publication through stale-result-checked editor surfaces are fully integrated.
