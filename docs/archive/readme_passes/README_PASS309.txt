Editor  IDE-grade outline/semantic language-model pass309

This pass completes another statement-syntax-tree gap after pass308.

Changes:
- Added Node_Select_Alternative to Editor.Ada_Syntax_Tree.
- Classifies line-level select `or` alternatives as first-class alternative nodes.
- Classifies compact embedded `or ...` action segments as Node_Select_Alternative instead of generic action text.
- Keeps the body of a select alternative as structured child statement/action-sequence nodes.
- Added AUnit coverage for line-level and compact select or/else alternatives.
- Extended language_validation_check guards.
- Updated README and docs.

Constraints preserved:
- Executable statement nodes remain parser-owned metadata, not Outline declaration rows.
- No rendering-side parsing.
- No Python or shell scripts were added.
- Same-line compact `select ... end select;` statements no longer leave a stale select scope on the ownership stack.
