Pass1434: performance and boundedness validation.

This pass adds Editor.Ada_Performance_Boundedness_Validation_Pass1434
and Test_Ada_Performance_Boundedness_Validation_Pass1434.

It validates project-scale performance and boundedness evidence after the finite
Remaining_* remediation closure.  The pass covers large-file analysis,
multi-buffer project closure, cross-unit index traversal, cancellation,
stale-result rejection, deterministic replay, and budget-exhaustion behavior.

The validation rejects unbounded work, ignored cancellation, accepted stale
results, nondeterministic replay, unbounded index traversal, consumer
disagreement, reopened Remaining_* gaps after pass1428, stale evidence, and
missing evidence.  It preserves the rule that future semantic remediation must
be evidence-driven rather than speculative.
