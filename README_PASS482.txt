Pass 482 - Enumeration representation clause completeness

Focus:
- Complete enumeration representation clause handling beyond named literal associations.
- Preserve the aggregate shape needed by IDE diagnostics and representation-clause legality checks.

Implemented:
- Retained positional enumeration representation aggregate components in the syntax tree.
- Updated token-cursor representation-clause grammar so enumeration representation clauses accept both:
  - named associations: `for T use (A => 0, B => 1);`
  - positional associations: `for T use (0, 1);`
- Mapped positional enumeration representation values to retained enumeration literals in declaration order.
- Preserved extra positional aggregate values as unresolved positional representation items, so they surface through existing literal-resolution diagnostics instead of disappearing.
- Added enumeration-target validation: an enumeration representation clause now requires a retained enumeration type target, not merely any type-like declaration.
- Added order-preservation legality diagnostics for static enumeration representation values: later literals must have strictly greater retained code values than earlier literals.

Regression coverage:
- Added `Test_Language_Model_Enumeration_Representation_Completeness`.
- Covers positional aggregate retention, ordinal literal mapping, non-enumeration targets, and order-mismatch legality diagnostics.

Scope:
- This pass keeps the same bounded static evaluator used by the representation metadata layer. It improves structural and legality coverage without introducing target-machine layout interpretation.
