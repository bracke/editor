Pass 334 — token-cursor Ada grammar layer

This pass adds Editor.Ada_Token_Cursor as the parser-facing grammar substrate for
Ada analysis.  The new package tokenizes sanitized Ada source, exposes explicit
cursor operations, records grammar production events, and parses declarations,
statements, association lists, and expression-precedence productions from tokens.

Editor.Ada_Syntax_Tree now consumes this grammar pass by attaching a bounded
Node_Token_Cursor_Grammar subtree with Node_Grammar_Production children before
running the legacy compatibility line-to-tree ownership path.  This keeps the
existing Outline/semantic-colouring projections stable while adding a real
cursor-based grammar layer that later passes can project into richer semantic
symbols and navigation rows.

New coverage:
- Test_Language_Model_Token_Cursor_Ada_Grammar
- phase579_language_validation_check guards for Editor.Ada_Token_Cursor,
  token-cursor expression grammar, and syntax-tree grammar production ownership.
