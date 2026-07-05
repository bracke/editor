# Editor Pass758

This pass deepens language-model projection for Ada context clauses.

## Changed

* Added context-clause-specific accessors in `Editor.Ada_Language_Model`:
  * `Context_Clause_Count`
  * `Context_Clause_At`
* Extended retained visibility metadata with:
  * `Is_Context_Clause`
  * `Has_Limited_Modifier`
  * `Has_Private_Modifier`
* Context `with` and `use` clauses at the root context-clause region are now distinguishable from declarative-region use clauses.
* Comma-separated context names are retained as separate metadata rows.
* `limited with`, `private with`, and `limited private with` retain explicit modifier flags without introducing compiler-grade dependency semantics.
* Added AUnit regression coverage for context modifiers, multi-name context clauses, root context use clauses, and declarative use-clause separation.
* Updated validation guards and parser coverage documentation.

## Non-goals

This pass does not perform compiler-grade context-clause legality checking, library-unit dependency analysis, limited-view semantic validation, private-with visibility validation, elaboration-order analysis, compiler invocation, LSP integration, rendering-side parsing, or dirty-state mutation.
