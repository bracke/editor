# Performance and Boundedness Validation Case 1434

Case 1434 is the project-scale validation gate for performance, cancellation,
budgeting, deterministic replay, stale-result rejection, and multi-buffer
cross-unit boundedness.

The gate is intentionally not a new Ada RM semantic edge.  It verifies that the
closed semantic model remains safe to consume in the editor under realistic
large-file and project-index workloads.

Accepted scenarios include:

- large-file semantic analysis within a deterministic work budget;
- multi-buffer project closure within a bounded traversal;
- cross-unit project-index traversal within a declared bound;
- cancellation acknowledgement before semantic consumers publish results;
- stale-result rejection by snapshot/fingerprint evidence;
- deterministic replay of schedule and consumer fingerprints;
- deterministic budget-exhaustion degradation.

Rejected states include unbounded work, ignored cancellation, stale-result
acceptance, nondeterministic replay, unbounded index traversal, semantic
consumer disagreement, reopened Remaining_* gaps after case 1428, stale evidence,
and missing evidence.
