# Editor Pass717 array type definition grammar depth

Pass717 deepens structural Ada array type parsing in the internal token cursor.

Implemented scope:

- constrained vs unconstrained array index-part markers
- explicit array index subtype-name markers
- explicit array index range-box markers for `range <>` / `<>`
- multidimensional constrained index item retention
- ordinary component subtype-indication markers
- anonymous access component markers
- aliased anonymous-access component retention
- malformed range / trailing index recovery coverage

This pass preserves the existing architecture: parsing remains snapshot-owned,
bounded, deterministic, and analysis-only. It does not introduce rendering-side
parsing, LSP, compiler invocation, external parser generators, scripts, or dirty
state mutation.

This improves structural grammar coverage for Ada array type definitions. It is
not compiler-grade legality checking for index subtype legality, discrete range
staticness, dimensional compatibility, component subtype legality, anonymous
access accessibility, aliased component legality, or expected-type resolution.
