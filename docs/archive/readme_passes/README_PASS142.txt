IDE-grade outline / semantic colouring pass 142

Focus:
- Harden Ada_Language_Model fingerprint ownership for bounded analysis overflow.

Implemented:
- Updated Editor.Ada_Language_Model.Add_Symbol so the first transition to Symbol_Overflow=True updates Result_Fingerprint even though no extra symbol can be appended.
- Kept repeated over-budget insertions stable so overflow does not churn the fingerprint after the conservative state is already visible.
- Added Test_Language_Model_Fingerprint_Includes_Overflow_State.
- Updated docs/outline.md and docs/syntax_colouring.md with pass 142 notes.
- Extended tools/release_check.adb guards.

Validation:
- No Python or shell scripts were added.
- GNAT/gprbuild is not available in this environment, so the Ada build/AUnit suite was not executed here.
