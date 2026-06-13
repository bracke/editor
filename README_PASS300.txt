Editor Phase 579 IDE-grade Outline/Semantic language model pass 300

Completeness pass for the parser-owned Ada syntax-tree foundation.

Implemented changes:
- Editor.Ada_Syntax_Tree.Parse now uses a bounded source-shape scope stack.
- Declaration/body/statement container nodes now own nested child nodes instead of every node being attached to the compilation-unit root.
- Package bodies own nested subprogram bodies.
- Subprogram bodies own begin, statement, and end nodes.
- End nodes are retained in the tree and pop the parser-owned tree stack.
- Removed a duplicate unreachable return from Has_Nodes.
- Strengthened AUnit coverage for syntax-tree parent/child ownership.
- Extended phase579_language_validation_check to guard the syntax-tree stack/ownership implementation.
- Updated README, Outline docs, semantic-colouring docs, and release checklist.

This remains a conservative syntax-tree foundation, not a complete Ada grammar AST.
