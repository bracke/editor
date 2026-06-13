Editor Phase 579 pass 277

This pass expands parser-owned Ada statement awareness for compact same-line exception handlers.

The new Statement_Exception_Handler_Action metadata is emitted for compact/generated handler forms such as:

   exception when Constraint_Error => null; when others => raise;

The parser also retains executable when metadata and reuses the existing bounded alternative-action classifiers for null handlers, calls with named associations, and reraises. Handler choices and actions are not learned as declarations, Outline rows, semantic symbols, scopes, or navigation targets.

Updated areas:
- src/core/editor-ada_language_model.ads
- src/core/editor-ada_declaration_parser.adb
- tests/src/editor-syntax_semantics-tests.adb
- tools/phase579_language_validation_check.adb
- README.md
- docs/outline.md
- docs/syntax_colouring.md
- docs/release/RELEASE_CHECKLIST.md
