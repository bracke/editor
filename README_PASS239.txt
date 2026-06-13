Editor Phase 579 pass 239

This pass tightens Ada language-model handling for split aspect clauses.

Highlights:
- Added Editor.Ada_Language_Model.Mark_Symbol_Aspect_Specification so parser-owned aspect metadata can be applied after symbol creation.
- Added bounded Pending_Aspect_Owner handling to Editor.Ada_Declaration_Parser for declarations followed by split `with ...` aspect clauses.
- Prevented split aspect continuations from being treated as context `with` clauses or as declarations for aspect names/expressions.
- Added Test_Language_Model_Split_Aspect_Clause_Metadata.
- Extended Phase 579 validation guards and documentation for split aspect metadata.
