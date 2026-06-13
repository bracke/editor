Phase 579 pass 355 — selected nested package use-clause visibility

This pass tightens the conservative Ada visibility resolver added in passes 353-354.

Implemented changes:

* Editor.Ada_Symbol_Resolver.Package_Target now resolves selected use-clause targets through the same prefix/leaf ownership path used by scoped selected-name lookup.
* A use clause such as `use Parent.Child;` can now expose direct children of a nested package retained as `Child` under package `Parent`.
* The selected target fallback requires both synchronized Enclosing_Scope and Parent_Symbol ownership, so missing prefixes still degrade to no match instead of leaf-only guessing.
* Ordinary lexical declarations continue to win before use-clause visibility is considered.

Regression coverage:

* Test_Resolver_Use_Selected_Nested_Package_Clause

Still conservative:

* No GNAT-equivalent with/use legality checking.
* No automatic cross-file source discovery.
* No inherited primitive visibility or complete overload selection.
* Ambiguous, unresolved, or stale targets still degrade rather than guessing.
