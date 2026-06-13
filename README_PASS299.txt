Pass 299: parser-owned Ada syntax tree foundation

Implemented item nr 1 from the full-Ada-syntax roadmap: add a real syntax tree model.

Source changes:
- Added src/core/editor-ada_syntax_tree.ads
- Added src/core/editor-ada_syntax_tree.adb
- Extended Editor.Ada_Language_Model with syntax-tree ownership/query APIs:
  * Set_Syntax_Tree
  * Has_Syntax_Tree
  * Syntax_Tree_Node_Count
  * Syntax_Tree_Root_Kind
  * Syntax_Tree_Fingerprint
  * Syntax_Tree
- Editor.Ada_Declaration_Parser.Parse now attaches Editor.Ada_Syntax_Tree.Parse(Text) to each Analysis_Result before declaration/statement metadata is populated.

Scope:
- The tree has a compilation-unit root and bounded source-shape nodes for context clauses, declarations, block starts, statement forms, pragmas, and end nodes.
- It is parser-owned and snapshot-owned.
- It performs no rendering, command, workspace, file-save, or reload work.
- It does not create Outline rows, semantic symbols, scopes, declarations, or navigation targets from statements.

Tests/guards/docs:
- Added AUnit coverage for parser-owned syntax tree attachment, root kind, node count, root child ownership, and fingerprint.
- Extended phase579_language_validation_check for syntax-tree package/API/parser integration markers.
- Updated README, outline docs, semantic-colouring docs, and release checklist.

Remaining:
- This is the syntax-tree foundation, not a full Ada grammar AST yet.
- Next passes should replace line-level source-shape nodes with complete expression/name/statement/declaration production nodes.
