pass 180 completeness

This pass aligns normal visible-range semantic-colouring preparation with the shared Ada language model.

Changes:
- Editor.State.Rebuild_Syntax_Symbols now parses the active immutable buffer text with Editor.Ada_Declaration_Parser.Parse.
- The semantic map is built from Editor.Syntax_Semantics.Build_Map_From_Analysis, matching semantic.refresh-buffer.
- The line-level semantic learner remains only as a fallback when parser-owned analysis retains no symbols.
- Added syntax-cache regression coverage for parser-owned record-component semantic classification during visible-range preparation.
- Updated docs and release_check guards.

No Python or shell scripts were added.
