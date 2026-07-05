Editor pass374

Representation-clause interpretation completeness pass.

Changes:
- Extended bounded static representation-expression evaluation with prior named-number constants.
- Named-number declarations such as Word_Bits : constant := 8 * 4; are retained in a parser-local static table during syntax-tree projection.
- Enumeration representation associations, Size/Alignment-style attribute clauses, and record representation component storage/bit expressions can now resolve those prior named numbers.
- The evaluator still preserves unsupported expressions as source text and does not turn unresolved identifiers into guessed numeric values.
- Added regression coverage: Test_Language_Model_Representation_Named_Static_Numbers.

Still conservative:
- No GNAT-equivalent representation legality checking.
- No deferred/typed constant lookup.
- No attribute evaluation.
- No layout overlap/alignment validation.
- No arbitrary Ada static-expression evaluator beyond the bounded numeric grammar and prior named-number constants.
