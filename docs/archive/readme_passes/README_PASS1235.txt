Pass1235 — Exception/finalization generic shared-state final legality

This pass adds one compiler-grade building block for Ada exception propagation and controlled-object finalization across the generic/shared-state final semantic chain.

Implemented package:

  Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality

The package consumes the existing exception/finalization legality layer together with cross-unit generic/shared-state closure, elaboration generic/shared-state evidence, generic abstract-state replay, overload/type generic shared-state evidence, representation/freezing generic shared-state evidence, tasking/protected generic shared-state evidence, accessibility generic shared-state evidence, discriminant generic shared-state evidence, and stabilized shared-state closure.

It classifies and preserves blocker-family identity for:

  * missing or blocked exception/finalization evidence;
  * cross-unit generic/shared-state dependency blockers;
  * elaboration generic/shared-state blockers;
  * generic abstract-state replay blockers;
  * overload/type generic shared-state blockers;
  * representation/freezing generic shared-state blockers;
  * tasking/protected generic shared-state blockers;
  * accessibility generic shared-state blockers;
  * discriminant/variant generic shared-state blockers;
  * stabilized shared-state closure blockers;
  * exception propagation, handler coverage, finalization primitive, finalization order, abort/deferred-finalization, task termination, no-return, accessibility-master, discriminant-finalization, and representation-finalization blockers;
  * source/substitution fingerprint mismatches, multiple blockers, and indeterminate states.

The implementation exposes deterministic counts, blocker-family queries, node/source-fingerprint lookups, accepted/blocked/indeterminate counters, and stable fingerprints. It does not add UI, projection, keybinding, workspace, rendering, parser generator, compiler invocation, or file lifecycle behaviour.

Regression added:

  Test_Ada_Exception_Finalization_Generic_Shared_State_Final_Legality_Pass1235

This pass is intentionally semantic. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
