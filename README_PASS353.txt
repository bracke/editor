Phase 579 pass353 - conservative Ada visibility resolver pass

Implemented item 1 from the remaining-gap list: improve Ada visibility rules.

Changes:
- Added bounded visibility-clause data to Editor.Ada_Language_Model.
- Added Visibility_Clause_Info and Visibility_Clause_Kind.
- Added Add_Visibility_Clause, Visibility_Clause_Count, and Visibility_Clause_At.
- The parser now records concrete with/use/use type/use all type names with source range and lexical scope, not only awareness booleans.
- Resolve_In_Scope now consults retained visible use-package clauses after ordinary lexical lookup fails.
- use-package lookup binds only direct children whose Enclosing_Scope and Parent_Symbol both match the used package symbol.
- Added regression coverage: Test_Resolver_Use_Package_Clause_Exposes_Package_Children.

Conservative boundaries:
- Local lexical declarations still win before use-clause matches.
- Missing or unresolved use targets produce no match rather than guessing.
- The pass does not implement GNAT-equivalent use legality, full with/use visibility, inherited primitive operation visibility, use type operator expansion, or automatic cross-file source discovery.
- No Python, shell scripts, parser generators, or generated caches were added.
