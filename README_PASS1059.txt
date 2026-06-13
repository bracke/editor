Pass1059 — Generic contract diagnostics view-compatibility projection

This pass extends Editor.Ada_Generic_Contract_Diagnostics with a view-aware diagnostic projection entry point. It consumes Editor.Ada_Generic_View_Compatibility and emits generic contract diagnostics for private-view barriers, limited-view incomplete barriers, cross-unit unresolved view cases, and residual object mismatch/unknown cases.

The pass preserves generic instance/formal identity, syntax node, stable source span, severity, message/detail payload, generic view identity, generic view status, generic view fingerprint, and deterministic diagnostic fingerprints. Compatible generic-view entries remain non-diagnostic.

Added API:
- Build_With_View_Compatibility
- Generic_View_Diagnostic_Count
- Private_View_Diagnostic_Count
- Limited_View_Diagnostic_Count
- View_Unresolved_Diagnostic_Count

Added regression coverage:
- Test_Ada_Generic_Contract_Diagnostics_View_Compatibility_Pass1059

This pass performs no parsing, file IO, buffer mutation, command registration, workspace mutation, or rendering-side semantic work.
