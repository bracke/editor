with Text_Backend;
with Text_Backend.Rope_Impl;

--  Public text storage facade.
--
--  keeps the editor-facing indexing conventions stable while moving
--  storage to UTF-8 text with Unicode scalar/code-point public indexing:
--
--  * Cursor/edit positions are zero-based scalar insertion points in
--    0 .. Length.
--  * Insert uses a zero-based scalar cursor position. Positions past Length
--    append.
--  * Delete uses a zero-based scalar character position. Positions past the
--    final character delete the final character, preserving the historical API.
--  * Element uses one-based scalar character indexes in 1 .. Length and
--    returns Character'Val (0) for 0 or indexes greater than Length.
--    Character byte access maps non-ASCII scalars to '?'.
--  * Unicode-aware callers should use Code_Point_At and
--    For_Each_Code_Point_Range.
--  * For_Each_Char_Range uses a half-open zero-based scalar range
--    [Start, Stop).
--
--  Editor state, undo records, selections, render code, and clipboard code
--  store stable absolute scalar indexes only; rope nodes and UTF-8 byte offsets
--  are private storage details.
package Text_Buffer renames Text_Backend.Rope_Impl;
