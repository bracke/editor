Pass1308: Control-flow statement vertical slice legality

This pass adds Editor.Ada_Control_Flow_Statement_Vertical_Slice_Legality.
It is a vertical Ada semantic pass, not a diagnostic/provenance/recheck wrapper.

The pass models concrete statement/expression control-flow legality for return,
extended return, raise, exit, goto, if statements/expressions, case statements/
expressions, loops, blocks, and no-return calls.

It checks:
- function/procedure return expression presence and absence
- return result type compatibility with universal numeric handling
- return accessibility and definite-assignment blockers
- raise exception entity presence and visibility
- exit target presence and loop-kind validity
- goto target presence, deeper-scope entry, and protected-action entry
- Boolean if-condition legality
- case alternative type compatibility, completeness, and overlap
- loop exit-path evidence
- no-return fall-through
- unreachable statement classification
- predicate/runtime-check interaction
- stale source/AST fingerprint rejection

AUnit coverage uses source-shaped control-flow scenarios rather than synthetic
closure-state transitions.
