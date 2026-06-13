Pass1108 adds wide semantic legality diagnostics to the unified semantic diagnostic feed and index path.

Implemented:
- Extended Editor.Ada_Semantic_Diagnostic_Feed with Build_With_Wide_Legality.
- Integrated Editor.Ada_Wide_Semantic_Legality_Diagnostics into the existing snapshot-guarded feed model.
- Preserved deterministic severity, span, node, message, source fingerprint, and feed/index fingerprints.
- Mapped wide semantic families into existing semantic source families without adding command aliases, render parsing, or UI mutation.
- Withheld active feed rows for stale wide legality input while preserving rejected totals.
- Withheld wide rows when the base semantic diagnostic guard is rejected stale.
- Reused Editor.Ada_Semantic_Diagnostic_Index unchanged so wide legality diagnostics participate in range, position, severity, source, token, and node lookup through the normal index.

AUnit:
- Added Test_Ada_Wide_Semantic_Diagnostic_Feed_Integration_Pass1108.
- Registered the new regression in tests/src/core_suite.adb.

This pass is a compiler-grade integration step because the widened legality checks from Pass1099 through Pass1107 now flow into the existing guarded diagnostic feed/index consumed by IDE diagnostics. It is not another UI projection-chain pass.
