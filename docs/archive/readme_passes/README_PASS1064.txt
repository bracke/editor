Pass1064 — Selected-name representation target resolution

This pass adds Editor.Ada_Selected_Representation_Targets.

Highlights:
- Consumes Editor.Ada_Cross_Unit_Representation_Targets and Editor.Ada_Selected_Name_Resolution.
- Resolves representation targets that are selected names through local, with-visible, and use-visible selected-name metadata.
- Preserves selected-name identity/status, prefix/selector text, visible target unit/path, candidate counts, statuses, and deterministic fingerprints.
- Classifies limited/private-view barriers, missing/ambiguous/overflow prefixes, selector errors, non-selected targets, and unresolved targets.
- Adds counters for resolved/local/cross-unit/limited/private/missing/ambiguous/selector-error/non-selected cases.
- Adds Test_Ada_Selected_Representation_Targets_Pass1064.

Invariant: this is a projection-only semantic consumer. It performs no rendering-side parsing, file IO, buffer mutation, command registration, workspace mutation, or editor-state mutation.
