Phase 579 IDE-grade outline/semantic language model pass 149

This pass hardens deterministic language-model fingerprints so they account for
preserved Ada source spelling while lookup remains case-insensitive.

Changes:
- Editor.Ada_Language_Model.Add_Symbol now hashes source identifier spelling in
  addition to normalized Ada lookup spelling.
- Add_Symbol and Set_Symbol_Target now hash preserved target spelling in
  addition to normalized target names.
- Added Test_Language_Model_Fingerprint_Includes_Source_Spelling.
- Updated outline and semantic-colouring docs with pass 149 notes.
- Extended release_check guards for the new source/test/doc coverage.

Rationale:
Outline labels, navigation metadata, and semantic/index cache rows preserve
source spelling. Analyses that differ only by declaration or target casing must
not become fingerprint-equivalent, even though Ada name resolution remains
case-insensitive.

Validation:
GNAT/gprbuild are not available in this environment, so the Ada build and AUnit
suite were not executed here.
