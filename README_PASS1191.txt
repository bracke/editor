Pass1191 -- Representation/freezing final hard-case legality

This pass adds Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality.

The pass closes final representation/freezing hard cases that require evidence from the final semantic consumer chain instead of relying on a local representation legality row alone.  It covers private/full-view cross-unit freezing, generic formal freezing, inherited and derived operational attributes, stream attributes on limited/private views, record layout with discriminants, variants and finalization, generic-instance representation effects, and implicit freezing order across units.

The model consumes final representation/freezing CPD evidence, cross-unit final closure, nested generic replay cycle closure, representation/operational AST repair, discriminant/variant consumer integration, accessibility master/scope final evidence, elaboration graph final evidence, and tasking/protected final effect evidence.

Accepted rows remain confident only when all required evidence is present and legal. Missing, blocked, indeterminate, stale, view-barrier, fingerprint-mismatched, and hard freezing/order rows are preserved as distinct blocker families.

Added regression:

Test_Ada_Representation_Freezing_Final_Hard_Cases_Legality_Pass1191
