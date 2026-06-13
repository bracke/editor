Pass 326 — grammar-aware malformed alternative recovery completeness

This pass extends the grammar-aware syntax-tree recovery added in the previous passes.

Changes:
- Missing `=>` in case alternatives, record variant alternatives, and exception handlers now emits structured recovery metadata.
- `Node_When_Alternative`, `Node_Variant`, and `Node_Exception_Handler` retain their node kind even when malformed.
- Recovery diagnostics use `Node_Recovery_Point` with `Node_Expected_Token` label `=>`.
- Record variant parts now use `end case` as their grammar boundary rather than being treated like record declarations that close only at `end record`.
- Added AUnit coverage for malformed alternative recovery.
- Extended release guards and documentation.

No Python, shell scripts, or generated parser tooling were added.
