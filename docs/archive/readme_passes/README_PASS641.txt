# Editor Pass 641

## Extension aggregate grammar

This pass improves the Ada token-cursor grammar for extension aggregates.

Changes:

- Added dedicated token-cursor productions for:
  - `Production_Extension_Aggregate`
  - `Production_Extension_Aggregate_Ancestor`
- Updated parenthesized aggregate parsing so forms such as:
  - `(Default_Root with B => 2)`
  - `(Default_Root with null record)`
  - `(Root'(A => 3) with A => 4, B => 5)`
  are retained as extension aggregates instead of letting the top-level `with` fall through ordinary aggregate recovery.
- Preserved existing delta-aggregate handling for `(X with delta ...)` by keeping `with delta` on the delta-aggregate path.
- Added AUnit regression coverage for ordinary extension aggregates, null-record extension aggregates, qualified-expression ancestors, component associations after `with`, and recovery into a following object declaration.
- Updated release checklist and README notes.

This improves structural grammar coverage for Ada extension aggregates. It is not compiler-grade legality checking for tagged-type ancestry, ancestor subtype legality, record component legality, or aggregate completeness.
