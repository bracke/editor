Editor Pass1105

Pass1105 adds Editor.Ada_Generic_Instance_Freezing_Representation_Legality.

Scope:
- Connect generic instantiated-body substitution metadata with generic instance semantic closure.
- Connect formal package substitution metadata with instance legality.
- Classify generic instance freezing effects and representation items after instance freezing.
- Fold representation target/static/profile/operational legality into generic instance closure.
- Fold linked assignment, return, conversion/access/aggregate, and tagged/derived legality failures into generic instance body semantic status.
- Preserve deterministic counters, status/kind/target lookups, and fingerprints.

Regression:
- Test_Ada_Generic_Instance_Freezing_Representation_Legality_Pass1105.
- Registered in Core_Suite.

Invariants:
- No rendering-side parsing.
- No file save/reload.
- No dirty-state mutation.
- No command, keybinding, workspace, or render mutation.
- No compiler invocation, LSP, external parser generator, Python, or shell-script integration.
