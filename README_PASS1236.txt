Pass1236 adds Editor.Ada_Renaming_Generic_Shared_State_Final_Legality.

This pass adds one compiler-grade building block for renaming, aliasing, use-clause, selected-name, and visibility legality over the generic/shared-state final semantic chain. It consumes base renaming/alias visibility legality plus cross-unit generic/shared-state closure, elaboration, generic abstract-state replay, overload/type shared-state evidence, representation/freezing shared-state evidence, tasking/protected shared-state evidence, accessibility/lifetime evidence, discriminant/variant evidence, and stabilized shared-state closure.

The new layer accepts object, exception, package, subprogram, and generic renamings; selected aliases; use-package and use-type visibility; alias redirection; homograph visibility; accessibility-sensitive aliases; dispatching aliases; Global/Depends aliases; generic replay aliases; and cross-unit aliases only when prerequisite semantic evidence agrees. It preserves blockers for missing/blocked renaming evidence, cross-unit closure, elaboration, generic replay, overload/type evidence, representation/freezing, tasking/protected effects, accessibility/lifetime, discriminants/variants, stabilized shared-state closure, target resolution, visibility, alias lifetime, homograph hiding, profile conformance, generic renaming, use clauses, fingerprint mismatches, multiple blockers, and indeterminate state.

Added AUnit regression:
Test_Ada_Renaming_Generic_Shared_State_Final_Legality_Pass1236

Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, abstract/refined state, volatile/atomic/shared-state, and cross-unit semantic closure layers are fully integrated.
