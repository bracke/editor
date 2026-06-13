Pass1297 — Call and operator overload resolution vertical slice

This pass intentionally pivots away from the repeated closure/provenance/recheck scaffolding pattern and adds a concrete Ada semantic vertical slice.

Added package:
  Editor.Ada_Call_And_Operator_Overload_Resolution_Legality

The package performs direct overload mechanics over concrete call/operator candidate rows:
  * designator matching
  * visibility filtering
  * arity and defaulted-formal range checks
  * actual/formal profile compatibility
  * expected result type selection
  * universal integer and universal real handling
  * implicit numeric compatibility
  * primitive/use-type operator preference
  * access-to-subprogram profile selection
  * generic formal subprogram selection
  * class-wide controlling-result selection
  * ambiguity detection
  * no-candidate/no-visible/arity/type/view/cross-unit blockers

Added test:
  Test_Ada_Call_And_Operator_Overload_Resolution_Legality_Pass1297

The test uses source-shaped overload contexts rather than row-state closure plumbing. It covers expected-result selection, universal numeric operator resolution, access-to-subprogram profile matching, generic formal subprogram actual matching, ambiguity, no-visible candidates, arity mismatch, type mismatch, private-view blockers, cross-unit blockers, and empty deterministic inputs.

This pass reduces the real overload-resolution gap by adding executable call/operator selection mechanics. It does not claim complete Ada overload resolution; remaining work includes integrating these mechanics with full parser AST expression nodes, full declaration/profile extraction, named association matching, full expected-type propagation, dispatching primitive sets, universal fixed-point resolution, generic contract substitution, and cross-unit private/full-view legality.
