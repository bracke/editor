Editor pass 136 — scoped overload-set language-model API

This pass strengthens the shared Ada language model with deterministic same-scope overload-set queries.

Implemented changes:
- Added Editor.Ada_Language_Model.Overload_Count.
- Added Editor.Ada_Language_Model.Overload_At.
- Added AUnit coverage for two overloaded declarations in one package scope.
- Added AUnit coverage proving a nested same-name declaration is not counted as part of the parent overload set.
- Added No_Symbol/zero-count degradation checks for out-of-range and missing overload lookups.
- Updated docs/outline.md and docs/syntax_colouring.md.
- Extended tools/release_check.adb guards.

No Python or shell scripts were added to the project.
