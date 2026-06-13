# Pass 632 - Declarative use-clause grammar ownership

This pass splits use-clause parsing out of context-clause parsing so the token
cursor can represent Ada `use`, `use type`, and `use all type` clauses both in
context clauses and in declarative parts without assigning declarative use items
to `Production_Context_Clause`.

## Changes

- Added a shared bounded `Parse_Use_Clause` token-cursor routine.
- Kept context-item `use` clauses wrapped by `Production_Context_Clause`.
- Routed package/procedure declarative `use` clauses directly through
  `Parse_Use_Clause` so they retain use-clause productions without a spurious
  context-clause owner.
- Preserved comma-separated package-name and subtype-mark parsing for ordinary
  `use`, `use type`, and `use all type` clauses.
- Added AUnit regression coverage for declarative `use`, `use type`, and
  `use all type` clauses, including recovery into a following object
  declaration.

## Scope

This improves structural grammar coverage for Ada declarative use clauses. It is
not compiler-grade legality checking for visibility, duplicate visibility
clauses, or subtype-mark legality.
