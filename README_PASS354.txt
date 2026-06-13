Phase 579 pass354 - use-type operator visibility completeness pass

Focus:
- Tighten the pass353 visibility resolver so use-type clauses model Ada visibility more conservatively and usefully.

Changes:
- Resolve_In_Scope no longer treats use type / use all type like a package-child export.
- use type now exposes only primitive operator-function declarations associated with the selected type when the type and operator are present in the retained analysis.
- Selected type names such as Shared.Count are resolved through the selected-prefix path even when the type symbol itself is retained as Count under the Shared package scope.
- Record components owned by the type are not exposed as ordinary directly visible names through use type.
- Added regression coverage: Test_Resolver_Use_Type_Clause_Exposes_Primitive_Operators_Only.

Conservative boundaries:
- This is not full GNAT-equivalent use-type legality or inherited primitive operation resolution.
- Non-operator primitives, inherited operations, operators whose profiles cannot be linked to the retained type, and cross-file-only types/operators still degrade to no match.
- No Python, shell scripts, parser generators, or generated caches were added.
