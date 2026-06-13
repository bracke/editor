Phase 579 pass188 - scoped semantic rendering bridge

This pass implements missing item nr 5 from the latest completeness analysis: semantic colouring now has a parser-owned token-position scope bridge instead of relying only on a bounded flat semantic map.

Changes:
- Added Editor.Ada_Language_Model.Scope_For_Position.
- Retained parser-owned Syntax_Analysis in Editor.State.State_Type.
- Normal visible-range render projection now computes a conservative lexical owner scope for identifier tokens and calls the resolver-backed Kind_For_Identifier_In_Scope path before falling back to the bounded flat semantic map.
- semantic.refresh-buffer and project-index refresh paths now retain Syntax_Analysis when updating active-buffer semantic maps.
- Syntax-analysis state is cleared alongside semantic maps on invalidation paths.
- Added regression coverage for parser-owned scope lookup preferring a local object over an enclosing type.
- Updated docs and release_check guards.

Build note:
GNAT/gprbuild/AUnit were not available in this environment, so the Ada build and tests were not executed here.
