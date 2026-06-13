Pass1184 - elaboration graph final consumer legality

This pass adds Editor.Ada_Elaboration_Graph_Final_Consumer_Legality.

The pass feeds elaboration graph closure evidence into the remaining semantic consumers that can otherwise accept legality too early:

- call and overload/type-edge contexts;
- default-expression and aspect-expression contexts;
- representation item and freezing contexts;
- task activation and task termination contexts;
- generic instance and instantiated generic replay contexts;
- preelaboration, Pure, Remote_Types, and Shared_Passive policy contexts;
- accessibility-sensitive elaboration consumers.

Rows remain confidently legal only when the required elaboration contract/predicate/dataflow evidence and the relevant dependent consumer evidence are present, unique, and accepted.  Missing, duplicate, blocked, or indeterminate dependent rows are preserved as deterministic final-elaboration statuses rather than being flattened into generic failures.

The AUnit regression Test_Ada_Elaboration_Graph_Final_Consumer_Legality_Pass1184 covers accepted calls, read-before-write elaboration blockers, representation/freezing blockers, tasking lifetime blockers, generic backmap blockers, overload/type ambiguity, missing elaboration evidence, duplicate dependent evidence, accessibility policy blockers, indeterminate elaboration evidence, missing tasking evidence, and missing representation evidence.

This pass adds one compiler-grade building block for final elaboration graph consumption. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, parser/AST coverage, and cross-unit semantic closure layers are fully integrated.
