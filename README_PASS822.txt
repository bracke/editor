Pass822 - Generic instantiation actual delimiter and recovery depth

Pass822 deepens Ada generic instantiation actual-part metadata. Generic package, procedure, and function instantiations with actual parts now retain explicit actual-part open/close delimiter productions, comma separator productions between top-level generic actual associations, and a bounded missing-close recovery production when an in-progress actual part reaches a semicolon before its closing parenthesis. Existing generic instantiation, instantiated unit name, generic actual association, named selector, positional association, box-default, nested-actual, aspect, and terminator metadata remains intact.

This pass is intentionally structural. It improves editor-owned grammar coverage for outline, semantic colouring, and deterministic recovery without attempting compiler-grade generic contract conformance, overload resolution, formal/actual matching legality, visibility analysis, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

Implementation notes:
- Added generic actual-part delimiter/separator/missing-close productions in `Editor.Ada_Token_Cursor`.
- Updated generic instantiation actual parsing to record delimiter and separator metadata while preserving existing association and nested-actual recovery behaviour.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Generic_Instantiation_Actual_Delimiters_Pass822`.
- Updated validation/release guard markers so the metadata and regression remain visible to the phase guard.
