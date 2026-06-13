Pass1430 — Real Ada corpus validation

Project-scale item implemented: nr 3, Real Ada corpus validation.

This pass does not reopen the finite Remaining_* remediation campaign closed by pass1428 and guarded by pass1429.  It adds a corpus-validation gate for source-shaped Ada 2022 scenarios that records legal acceptance, illegal rejection, runtime-check preservation, warning-only preservation, cross-unit consumer agreement, diagnostic source-span precision, duplicate-diagnostic suppression, stale evidence rejection, and source/AST/semantic/consumer fingerprint freshness.

Added package:
Editor.Ada_Phase579_Real_Ada_Corpus_Validation_Pass1430

Added AUnit package:
Test_Ada_Phase579_Real_Ada_Corpus_Validation_Pass1430

Added release document:
docs/release/REAL_ADA_CORPUS_VALIDATION_PASS1430.md

The pass establishes that future project-scale validation must be driven by corpus-shaped legal/illegal examples and concrete false-positive/false-negative evidence, not by speculative new Remaining_* edge invention.
