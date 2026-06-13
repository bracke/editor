Pass1075 adds Editor.Ada_Diagnostic_Action_Router.

Scope:
- consume Editor.Ada_Diagnostic_Quick_Fix_Skeleton
- consume Editor.Ada_Diagnostic_Navigation
- consume Editor.Ada_Diagnostic_Panel_Projection
- consume Editor.Ada_Diagnostic_Provenance
- consume Editor.Ada_Diagnostic_Status_Line
- route projection-only diagnostic actions to available IDE-facing targets
- preserve diagnostic identity, source span, severity, source family, token kind, syntax node, labels/details, target ids, route status, and fingerprints
- expose rejected/stale models as zero active routes with rejected-route totals

No edits are produced or applied. The router performs no parsing, file IO, buffer mutation, command registration, workspace mutation, or rendering-side semantic work.

Regression:
- Test_Ada_Diagnostic_Action_Router_Pass1075
