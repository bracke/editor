Editor Phase 579 pass764 — formal package positional actual grammar

This pass deepens token-cursor grammar coverage for Ada generic formal package declarations by tagging positional actual associations inside formal_package_actual_part with a formal-package-specific production.

Implemented:
- Added Production_Formal_Package_Actual_Positional_Association.
- Formal package actual parts now retain positional actuals distinctly from named selectors while also preserving generic actual positional metadata for compatibility.
- Added AUnit regression coverage for mixed positional/named/operator/box formal package actual parts.
- Updated README, coverage matrix, and release guards.

This improves structural grammar coverage for formal package actual parts. It is not compiler-grade generic contract conformance, formal package matching, overload resolution, generic semantic expansion, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
