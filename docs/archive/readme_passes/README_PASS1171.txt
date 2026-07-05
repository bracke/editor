Pass1171 - Generic replay representation contract predicate/dataflow consumer legality

This pass adds Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality.

Purpose:
Feed the richer Pass1170 representation/freezing tasking contract predicate/dataflow evidence back into generic instance body semantic replay. This replaces the older Pass1160 representation-flow bridge for the new consumer chain, so instantiated generic body replay cannot remain confidently legal merely because generic replay mapping succeeded when its replayed representation/freezing evidence is blocked by predicate/invariant propagation, definite initialization, refined dataflow, lifetime/accessibility, discriminant/variant, representation/freezing, tasking/protected, or repaired coverage facts.

Consumes:
- Editor.Ada_Generic_Instance_Body_Semantic_Replay
- Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality

Applies to:
- formal substitutions
- generic body declarations
- generic body statements
- generic body expressions
- generic instances
- nested generic instances
- freezing effects
- representation clauses
- operational attributes
- stream attributes
- record layouts
- private/full-view timing
- tasking representation effects

Classifies:
- accepted legal replay contexts with matching representation CPD evidence
- base replay errors
- source/instance replay mapping errors
- generic expansion, overload, flow, predicate, accessibility, representation, and coverage replay blockers
- missing representation CPD rows
- base representation/freezing blockers
- contract, elaboration, tasking, predicate, initialization, lifetime, discriminant, representation, Global/Depends, call propagation, generic flow, tasking/protected flow, and coverage blockers carried through Pass1170
- multiple matching representation CPD blockers
- indeterminate representation CPD state

Regression:
- Test_Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality_Pass1171

This pass adds one compiler-grade building block for generic instance replay consuming the current representation/freezing tasking contract predicate/dataflow chain. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.
