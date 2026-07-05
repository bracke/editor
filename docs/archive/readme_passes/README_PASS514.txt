Pass 514 - Resolver-driven representation/operational property unification

Implemented another completeness pass over the representation/operational property unification layer.

Changes:
- Replaced the manually duplicated aspect-name recognition list with resolver-driven recognition using the shared Representation_Kind_For mapping.
- Added a single Boolean-property classifier based on explicit Representation_Clause_Kind values.
- Rewired bare Boolean aspect defaulting through that classifier instead of another parallel string-name list.
- This makes future additions to the shared property resolver automatically visible to aspect recognition and Boolean defaulting.
- Added regression coverage proving bare Boolean aspects and attribute-definition clauses share resolver-derived kinds and True defaults for Suppress_Debug_Info, Simple_Storage_Pool_Type, and Atomic_Always_Lock_Free.

Primary files touched:
- src/core/editor-ada_declaration_parser.adb
- tests/src/editor-syntax_semantics-tests.adb
