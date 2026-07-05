# pass774 - allocator constraint metadata depth

Pass774 deepens allocator grammar metadata for constrained allocator subtype indications.  The token cursor now emits allocator-specific markers for null exclusions, index constraints, discriminant constraints, range constraints, digits constraints, and delta constraints while preserving the existing shared subtype-indication productions.

This keeps forms such as `new not null T`, `new Vector (1 .. 4)`, and `new Item (Size => 4)` distinguishable from initialized allocator aggregate/expression parts without requiring semantic consumers to reparse expression text.

This improves structural grammar coverage for Ada allocator subtype indications.  It is not compiler-grade allocator accessibility checking, subtype compatibility checking, discriminant legality checking, index constraint validation, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
