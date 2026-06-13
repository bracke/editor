Pass1282 implements Editor.Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Provenance.

This pass preserves provenance for stabilized direct RM-completion closure-consumer diagnostics.  It links Pass1281 diagnostic rows back through the stabilized closure, stabilization gate, convergence, recheck application, eligibility, remediation worklist, and original direct-consumer diagnostic row while preserving blocker-family identity.

The pass is deterministic, bounded, snapshot-owned, and side-effect-free.  It performs no rendering-side parsing, file save/reload, dirty-state mutation, command/keybinding/workspace/render mutation, LSP use, compiler invocation, external parser generation, or speculative parser repair.

Added tests:
- Test_Ada_RM_Completion_Closure_Consumer_Stabilized_Diagnostic_Provenance_Pass1282
