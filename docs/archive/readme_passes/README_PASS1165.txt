Pass1165 - Dataflow definite-initialization consumer legality

This pass adds Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality.

The package feeds exact definite-initialization/object-flow evidence from Pass1164 back into Global/Depends and flow-effect consumers.  A Global read, write, read/write effect, Depends edge, Refined_Global/Refined_Depends effect, call propagation edge, generic effect, or tasking/protected flow effect no longer remains confidently legal when the corresponding object initialization proof is missing, mismatched, blocked, or indeterminate.

The pass classifies accepted reads, writes, read/write effects, null effects, Depends edges, refinements, call propagation, generic effects, and task/protected effects.  It also preserves base Global/Depends dataflow errors, missing flow graph rows, flow global/depends/propagation/generic/tasking/coverage blockers, missing initialization-object-flow rows, read-before-write, component read-before-write, partial component initialization, out-parameter obligations, conditional in out assignment, return-object initialization gaps, branch/loop merge failures, exception path losses, finalization using uninitialized objects, use-after-finalization, lifetime blockers, discriminant/representation blockers, coverage blockers, linked initialization blockers, multiple blockers, and indeterminate states.

Added AUnit regression:
  Test_Ada_Dataflow_Definite_Initialization_Consumer_Legality_Pass1165

This is a semantic consumer pass, not a diagnostic/projection/status pass.
