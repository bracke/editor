Pass1114 adds Editor.Ada_Unit_Completion_Order_Legality, a widened compiler-grade semantic building block for Ada unit/body completion and declaration-order legality.

The pass consumes cross-unit semantic closure, contract/aspect legality, elaboration/dependence legality, generic-instance/freezing/representation legality, and accessibility/lifetime legality. It classifies package, subprogram, task, protected, and generic body completion; private type/private extension completion; deferred constant and incomplete type completion; body-stub/separate-body completion; declaration-before-use; private part ordering; body-before-spec; use-before-full-view/completion; frozen-before-completion; limited/private view barriers; and linked semantic blockers.

The layer is snapshot-owned, deterministic, bounded, parser-free, render-free, and mutation-free. It exposes deterministic counters, lookups, and fingerprints for completion status, unit kind, subject kind, relation state, declaration order, visibility state, and normalized names.

Added Test_Ada_Unit_Completion_Order_Legality_Pass1114 and registered it in Core_Suite.
