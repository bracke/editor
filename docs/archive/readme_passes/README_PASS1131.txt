Pass1131 - Representation/freezing precision legality

This pass adds Editor.Ada_Representation_Freezing_Precision_Legality.

The new package deepens representation/freezing legality by connecting explicit representation clauses and aspects with implicit semantic-use freezing, private/full-view timing, generic-instance freezing effects, representation/layout/stream integration, elaboration precision, and tasking/protected precision.

It classifies legal representation items, aspects, operational items, stream attributes, record layouts, generic-instance effects, private/full-view timing, and implicit freezing. It also classifies unresolved or ambiguous freezing targets, non-freezable targets, target-kind mismatch, representation after explicit/implicit/generic/private-full-view freezing, representation at the freezing point, private-view barriers, missing full-view completion, static/profile/operational/layout/stream errors, generic-instance freezing errors, elaboration freezing errors, tasking/protected freezing errors, and linked representation/integration errors.

The package exposes deterministic context/result models, node/context/status/kind/target lookups, family counters, legal/error counters, and stable fingerprints. It performs no parsing, file IO, dirty-state mutation, command/keybinding/workspace/render mutation, or compiler invocation.

AUnit coverage was added in Test_Ada_Representation_Freezing_Precision_Legality_Pass1131 and registered in tests/src/core_suite.adb.
