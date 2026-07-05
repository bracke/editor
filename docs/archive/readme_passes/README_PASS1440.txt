Pass1440 — Legacy Scaffold Inventory and Classification

This pass implements the project-scale cleanup item "complete legacy scaffold inventory" after the semantic and release-validation closure.

Added package:
  Editor.Ada_Legacy_Scaffold_Inventory_Pass1440

Added AUnit package:
  Test_Ada_Legacy_Scaffold_Inventory_Pass1440

Purpose:
  Build a finite ledger for remaining historical scaffolding before any more destructive removal passes.  The pass classifies surfaces as production, regression evidence, quarantine, or removal candidates.  It rejects unowned active legacy surfaces, references to already removed scaffolds, command-alias leakage, reopened Remaining_* gaps after pass1428, stale inventory fingerprints, and unclassified surfaces.

Finite cleanup result:
  Production surfaces are kept.
  RM/project closure evidence is retained as regression evidence.
  Diagnostic recovery/render legacy surfaces are quarantined before deletion.
  Command/keybinding, repair-gated, remediation-worklist, and stabilized-closure scaffolds are recorded as finite removal candidates for later destructive cleanup passes.
