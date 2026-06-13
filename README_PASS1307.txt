Pass1307 adds Editor.Ada_Object_Initialization_Default_Vertical_Slice_Legality.

This is a vertical semantic pass, not another closure/provenance/recheck wrapper. It models concrete Ada object initialization and default-expression legality over source-shaped rows.

It checks object declarations, default expressions, deferred constants, record/array aggregates, controlled/finalized objects, access-object initialization, and out-parameter definite-assignment cases. It consumes type compatibility, subtype/range/predicate legality, accessibility/lifetime legality, controlled/finalization evidence, and stable source/AST fingerprints.

The pass rejects missing required initializers, type-incompatible initializers, illegal default expressions, deferred constants without completions, deferred constant type mismatches, missing aggregate components, duplicate aggregate components, component type mismatches, limited objects without available default initialization, blocked controlled/finalized initialization, access values that fail accessibility checks, and definite-assignment blockers. Runtime predicate checks remain legal-with-runtime-check evidence.

Added AUnit coverage in Test_Ada_Object_Initialization_Default_Vertical_Slice_Legality_Pass1307.
