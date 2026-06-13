Editor Phase 579 pass398

This pass extends the parser-owned executable expression/name binding model with
explicit type-conversion targets.  The declaration parser now distinguishes
retained type/subtype/record/generic-formal-type prefixes in conversion-shaped
expressions such as Count_Type (Raw) and Small_Count (Count) from array indexing,
slices, and ordinary call targets.

The new Binding_Type_Conversion_Target metadata remains conservative: a prefix
must resolve to a retained type-like symbol in the current analysis before it is
classified as a conversion target.  Unresolved or callable-only prefixes are not
guessed.

Updated tests/docs/guards:
- Test_Language_Model_Executable_Type_Conversion_Bindings
- README.md
- docs/outline.md
- docs/syntax_colouring.md
- docs/release/RELEASE_CHECKLIST.md
- tools/release_check.adb

No Python, shell scripts, parser generators, rendering-side parsing, external
compiler integration, or LSP integration were added.
