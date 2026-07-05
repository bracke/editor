Pass1112 - Contract/aspect legality semantic closure

This pass adds Editor.Ada_Contract_Aspect_Legality as a widened compiler-grade semantic building block for Ada contract and semantic aspect legality.  The pass covers preconditions, postconditions, type invariants, default/initial conditions, static and dynamic predicates, assertions, contract cases, Global/Depends/refined flow aspects, placement errors, duplicate aspects, private/limited/cross-unit barriers, and linked failures from assignment, return, staticness, accessibility, overload, and cross-unit semantic legality.

The model is deterministic, bounded, and snapshot-owned.  It exposes context rows, legality rows, status/subject/placement/flow lookups, legal/error counters, boolean/static/flow/view/linked/indeterminate counters, and stable fingerprints.  It performs no rendering-side parsing, file saves/reloads, dirty-state mutation, command-palette/keybinding/workspace/render mutation, compiler invocation, external parser invocation, Python, or shell script integration.

Regression coverage was added in Test_Ada_Contract_Aspect_Legality_Pass1112 and registered in Core_Suite.
