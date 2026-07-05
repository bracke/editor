IDE-grade Outline/Semantic Language Model Pass 135

Focus:
- Propagate bounded Ada language-model analysis overflow through project-index resolution.

Changed:
- src/core/editor-ada_project_index.adb
  * Resolve now marks Result.Overflow when an indexed file's Analysis_Result overflowed.
  * Resolve_Current now does the same for current-stamped path/token/revision/lifecycle lookups.
  * Deterministic in-budget matches are still returned.

- tests/src/editor-syntax_semantics-tests.adb
  * Added Test_Project_Index_Propagates_Analysis_Overflow.
  * The test constructs a bounded overflowed Analysis_Result, indexes it, and verifies both ordinary and current-stamped resolution report overflow while retaining the in-budget match.

- docs/outline.md
- docs/syntax_colouring.md
  * Documented pass 135 overflow propagation semantics.

- tools/release_check.adb
  * Added static guards for the pass 135 source, test, and documentation updates.

Validation:
- No Python or shell scripts were added.
- GNAT/gprbuild is not available in this execution environment, so the Ada build and AUnit suite were not run here.
