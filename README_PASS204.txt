Editor Phase 579 IDE-grade Outline/Semantic Colouring - Pass 204

This pass expands parser completeness by retaining Ada declaration aspect specifications as bounded language-model metadata.

Changes:
- Added Has_Aspect_Specification to Editor.Ada_Language_Model.Declaration_Flags.
- Included aspect metadata in analysis fingerprints.
- Added bounded top-level aspect-specification detection to Editor.Ada_Declaration_Parser.
- Outline details can now show aspect metadata on parser-owned symbols.
- Extended aspect-clause tests to cover package, scalar type, procedure, and function declarations.
- Extended phase579_language_validation_check guards for aspect metadata, parser detection, and test coverage.
- Updated docs and release checklist.

Policy:
- Aspect clauses do not create standalone Outline rows.
- Aspect names/expressions are not inserted as symbols.
- Profile summaries continue to stop before aspect clauses.
- Detection remains bounded and conservative; this is still not a compiler frontend.
