Pass 525 - Current-scope value pragma positional retention

This pass fixes another convergence bug in the unified representation/operational pragma path.

Implemented:
- Corrected value extraction for current-scope value pragmas that do not name an entity argument.
- `pragma Priority (10)`, `pragma Interrupt_Priority (7)`, `pragma CPU (2)`, `pragma Dispatching_Domain (...)`, `pragma Relative_Deadline (...)`, and `pragma Max_Entry_Queue_Length (...)` now retain their first positional argument as the representation item value.
- Preserved `Value => ...` named-argument handling for the same pragmas.
- Kept these pragmas on the shared `Representation_Kind_For` resolver path used by aspects and attribute-definition clauses.
- Expanded representation pragma regression coverage for task/protected current-scope scheduling pragmas.

Why this matters:
- Pass 523 correctly attached value-only pragmas to the enclosing declaration/scope, but the generic value extractor still used positional fallback 2 for scheduling/queue pragmas. That dropped ordinary Ada spellings such as `pragma Priority (10)` and prevented their static-value legality from matching `with Priority => 10` and `for T'Priority use 10`.
