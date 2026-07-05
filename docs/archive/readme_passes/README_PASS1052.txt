Pass1052 - Ada expression diagnostics overload-cause integration

Implemented package update:
- Editor.Ada_Expression_Diagnostics

Scope:
- Adds Build_With_Overload_Causes to merge Editor.Ada_Overload_Ambiguity_Diagnostics cause records into the existing expression diagnostics projection.
- Preserves overload cause detail, candidate counts, selected counts, compatible/mismatch/unknown counters, cause fingerprints, node identity, source spans, severity, and expression diagnostic kind.
- Adds projection counters for overload-cause diagnostics and candidate rejections.
- Keeps ordinary Build behavior unchanged for consumers that only want first-order expression diagnostics.

Regression:
- Test_Ada_Expression_Diagnostics_Overload_Cause_Integration_Pass1052

Invariant:
- No rendering-side parsing.
- No file saves/reloads during analysis.
- No dirty-state mutation.
- No command/keybinding/workspace/render mutation.
- No compiler invocation, LSP, parser generator, Python, or shell integration in the project code.
