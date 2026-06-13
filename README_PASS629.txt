Pass 629 - Reduction attribute argument grammar

- Added token-cursor production kinds for reduction reducer and reduction initial-value argument positions.
- Routed `Reduce`, `Parallel_Reduce`, and `Map_Reduce` attribute calls through a reduction-specific bounded argument parser.
- Kept non-reduction attribute calls on the existing generic attribute argument path.
- Added AUnit coverage proving ordinary, parallel, and map-style reduction attributes retain reduction-expression, reducer, initial-value, selected-name, and attribute-argument-part productions.

This improves structural grammar coverage for reduction attribute expressions. It is not compiler-grade legality checking for reducer profile conformance or parallel execution legality.
