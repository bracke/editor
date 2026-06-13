# Pass1143 - Accessibility / lifetime scope graph legality

Pass1143 adds `Editor.Ada_Accessibility_Scope_Graph_Legality`, a compiler-grade building block that deepens accessibility/lifetime precision into an explicit master/scope graph.

The pass connects nested master hierarchy facts with anonymous access parameter levels, allocator masters, return-object and return-access masters, access discriminants, access conversions, generic body replay substitutions, discriminant-dependent aggregate legality, finalization masters, and coverage-gate enforcement. It preserves source nodes, object/scope names, source spans, linked legality statuses, blocker counts, deterministic lookups, and stable fingerprints.

The package remains snapshot-owned and projection-free: it performs no parser mutation, file IO, command/palette/render integration, compiler invocation, or editor dirty-state mutation.

Added regression coverage:

* `Test_Ada_Accessibility_Scope_Graph_Legality_Pass1143`

This pass reduces false legal accessibility conclusions by requiring a usable master/scope graph before access values, allocators, returns, discriminants, generic actuals, and finalization effects are treated as lifetime-safe.
