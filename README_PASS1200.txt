Pass1200 — Final semantic remediation gate legality

This pass adds Editor.Ada_Final_Semantic_Remediation_Gate_Legality.

The package consumes Pass1199 final semantic blocker remediation ordering and turns remediation actions into a semantic gate model.  It prevents downstream legality consumers from accepting confident legal conclusions when prerequisite semantic evidence is still stale, missing, blocked, or indeterminate.

The gate model preserves blocker-family identity for stale snapshot evidence, AST/coverage repair, cross-unit dependency closure, view barriers, generic replay/backmapping, overload/type evidence, representation/freezing, flow/contract proof, tasking/protected effects, elaboration, accessibility/lifetime, discriminant/variant evidence, multiple blockers, and indeterminate states.

This is not a command, palette, keybinding, workspace, render, or status projection layer.  It is a compiler-grade semantic safety gate: a downstream conclusion remains confident only when the remediation order says no prerequisite blocker must be repaired first.

Added AUnit regression:

  Test_Ada_Final_Semantic_Remediation_Gate_Legality_Pass1200

Updated documentation and release notes for the new semantic gate layer.
