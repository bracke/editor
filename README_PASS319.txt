Pass 319: declaration grammar completeness

This pass tightens Ada syntax-tree declaration classification for constant-family declarations.

Implemented:
- Added Node_Constant_Declaration for typed constants with explicit initializers.
- Added Node_Deferred_Constant_Declaration for deferred constants without initializers.
- Preserved Node_Number_Declaration for named numbers using `: constant :=`.
- Reordered declaration/assignment classification so typed constants are not parsed as assignment statements.
- Added declaration-mode metadata for constant, deferred constant, and named number nodes.
- Added AUnit regression coverage separating constants, deferred constants, named numbers, and executable assignments.
- Extended phase579_language_validation_check guards.

No Python, shell scripts, or external parser generators were added.
