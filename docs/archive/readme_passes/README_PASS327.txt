Pass 327 — malformed declaration recovery completeness pass

This pass extends grammar-aware Ada syntax-tree recovery from control headers and alternatives into declaration headers and terminators.

Highlights:
- Package, type, subtype, object, constant, deferred constant, named number, rename, instantiation, entry, and generic formal declaration lines now retain their structured declaration node kind when malformed but still recognizable.
- Missing declaration `is` tokens produce parser-owned Node_Recovery_Point diagnostics with Node_Expected_Token = is.
- Missing declaration semicolons produce parser-owned Node_Recovery_Point diagnostics with Node_Expected_Token = ;.
- Declaration-shaped lines containing both `:` and `:=` no longer degrade to Node_Assignment_Statement merely because their semicolon is missing.
- Added AUnit regression coverage and release validation guards for malformed declaration recovery.

No Python, shell scripts, parser generators, rendering-side parsing, or external language services were introduced.
