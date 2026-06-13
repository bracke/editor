Phase 579 IDE-grade Outline/Semantic Language Model — pass 167

This pass hardens same-scope overload enumeration in Editor.Ada_Language_Model.

Changes:
- Added private Is_Direct_Overload validation.
- Overload_Count and Overload_At now require direct overload rows to have synchronized ownership stamps:
  * root overload rows must remain root-owned;
  * non-root overload rows must have Enclosing_Scope = Scope and Parent_Symbol = Symbol_Id (Scope).
- Malformed overload rows whose lexical scope and parent symbol disagree no longer appear as Outline/navigation or semantic-colouring overload candidates.
- Added Test_Language_Model_Overload_Lookup_Requires_Matching_Parent.
- Updated docs/outline.md and docs/syntax_colouring.md.
- Extended tools/release_check.adb guards for the pass 167 source/test/doc markers.

No Python or shell scripts were added.
