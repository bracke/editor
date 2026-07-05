# Editor Pass718 access type definition grammar depth

Pass718 deepens structural Ada access type parsing in the internal token cursor.

Implemented scope:

- pool-specific access-to-object markers for `access T`
- general access-to-object markers for `access all T` and `access constant T`
- explicit object designated subtype-mark markers
- explicit `all` and `constant` object-mode markers
- named access-to-subprogram definition markers
- retained access-to-procedure/function profile structure
- retained protected access-to-subprogram forms
- malformed access object recovery boundaries

This pass preserves the existing architecture: parsing remains snapshot-owned,
bounded, deterministic, and analysis-only. It does not introduce rendering-side
parsing, LSP, compiler invocation, external parser generators, scripts, or dirty
state mutation.

This improves structural grammar coverage for Ada access type definitions. It is
not compiler-grade legality checking for designated subtype legality, general vs
pool-specific accessibility rules, access-to-constant update rules, profile
conformance, protected-operation legality, null-exclusion legality, visibility,
overload resolution, storage-pool rules, or accessibility analysis.
