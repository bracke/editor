Pass1076 adds Editor.Ada_Diagnostic_Command_Projection.

Scope:
- Consume Editor.Ada_Diagnostic_Action_Router.
- Project diagnostic action routes into stable command-facing descriptors.
- Preserve diagnostic identity, route identity, source span, severity, source family, token kind, syntax node, labels/details, availability, and fingerprints.
- Provide command kinds for navigation, explanation, expression review, overload-ranking review, generic review, cross-unit review, and representation review.
- Keep the layer projection-only: no command registration, invocation, edits, parsing, buffer mutation, file IO, workspace mutation, or rendering-side semantic work.
- Preserve rejected/stale route withholding by exposing zero active descriptors and rejected-command totals.

Regression:
- Test_Ada_Diagnostic_Command_Projection_Pass1076
