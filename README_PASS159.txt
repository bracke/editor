Phase 579 IDE-grade outline/semantic language model pass 159

This pass hardens deterministic language-model cache stamps for parser-owned
ownership metadata.

Changes:
- Updated `Editor.Ada_Language_Model.Add_Symbol` so initial symbol and
  aggregate analysis fingerprints include `Enclosing_Scope` and
  `Parent_Symbol`.
- Added `Test_Language_Model_Fingerprint_Includes_Ownership_Metadata`.
- Updated Outline and semantic-colouring documentation with pass 159 notes.
- Extended release-check guards so the ownership-sensitive fingerprinting
  cannot be silently removed.

Rationale:
Outline hierarchy, scoped resolver lookup, child traversal, navigation target
validation, and scope-aware semantic colouring all consume ownership metadata.
Two otherwise identical declarations retained under different lexical scopes or
parents must not share the same deterministic analysis fingerprint.
