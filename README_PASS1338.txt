Pass1338: Ada RM Coverage Matrix Audit

This pass starts the explicit Ada RM semantic coverage matrix after the vertical-slice and integration/audit passes.  It adds Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338 and Test_Ada_RM_Coverage_Matrix_Audit_Pass1338.

The audit is deliberately not a diagnostic projection/status layer.  It records concrete rule-family coverage claims and rejects any claim that is not backed by a present implementing semantic slice, source-shaped tests, consumed semantic results, concrete rule-family evidence, and fresh source/AST/type/profile/substitution/effect fingerprints.

Covered RM-family groups include declarations/completions, names/visibility/selected names/attributes, types/subtypes/constraints/predicates, expressions/expected-type resolution, aggregates, assignments/conversions, calls/overload/callable profiles, generics/substitution/body replay, tagged/interface dispatching, arrays/records/discriminants/variants, access/accessibility, tasking/protected/synchronized constructs, exceptions/finalization, representation/aspects/freezing, library/context/subunit/elaboration closure, contracts/Global/Depends/flow, interfacing/import/export, iterators/parallel/reductions, static expressions/choices, and semantic diagnostics/consumer readiness.

The new AUnit tests verify:

- all twenty RM-family groups can be marked covered only when backed by source-shaped semantic evidence;
- a covered family without a present implementing slice is rejected;
- an implemented slice with no RM-family coverage entry is rejected;
- duplicate and conflicting coverage claims are rejected;
- covered entries require source-shaped tests and consumed semantic results;
- stale source/AST/type/profile/substitution/effect fingerprints block coverage;
- generic "compiler-grade" claims without concrete rule-family evidence are rejected;
- partial coverage is visible but does not count as final readiness.

The test suite is registered in Core_Suite.
