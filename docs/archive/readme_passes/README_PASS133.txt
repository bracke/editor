IDE-grade outline/semantic language-model pass 133

Focused change:
- Added deterministic parent-to-child symbol accessors to Editor.Ada_Language_Model:
  - Child_Count (Analysis, Parent)
  - Child_At (Analysis, Parent, Index)
- The accessors expose parser-owned ownership relationships without making Outline,
  semantic colouring, or future navigation code reconstruct child lists by scanning
  and filtering symbols independently.
- Invalid parent symbols and out-of-range child indexes degrade to No_Symbol / zero
  count and do not synthesize children.

Tests/docs/static guards:
- Added AUnit coverage for package/type/nested package/procedure/component child ownership.
- Updated docs/outline.md and docs/syntax_colouring.md with pass 133 notes.
- Extended tools/release_check.adb guards for the new API, test coverage, and docs.

Validation note:
- This environment does not provide GNAT/gprbuild, so the Ada build and AUnit suite
  were not executed here. The change is source-level and keeps the project free of
  Python and shell scripts.
