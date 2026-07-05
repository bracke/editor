# Editor pass747

Pass747 adds a hostile-source recovery regression matrix for the Ada
language-intelligence parser.  The new AUnit test combines malformed generic
formal package actuals, malformed variant-record alternatives, broken aggregate
associations, unterminated pragma/aspect/representation-style clauses, malformed
select alternatives, and malformed exception handlers in one source text.

The regression asserts that recovery remains bounded, that recovery markers are
retained for the affected grammar families, and that parsing resumes into later
declarations and subprogram bodies instead of treating the rest of the buffer as
one opaque failed construct.

Updated validation guards now require the hostile-source regression and its
family-specific assertions.

This improves malformed-source regression coverage only. It is not compiler-grade
Ada legality checking, semantic validation, exhaustive recovery, tasking
analysis, generic contract checking, aggregate legality checking, or
representation/freezing-rule validation.
