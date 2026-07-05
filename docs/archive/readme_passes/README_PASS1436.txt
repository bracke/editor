Pass1436: project-scale closure

Added package:
  Editor.Ada_Project_Scale_Closure_Pass1436

Added AUnit package:
  Test_Ada_Project_Scale_Closure_Pass1436

Selected project-scale item:
  Final closure after the seven post-remediation validation items.

Scope:
  Pass1436 freezes the project-scale validation campaign after:
    1. Release-readiness validation
    2. End-to-end editor integration validation
    3. Real Ada corpus validation
    4. Performance and boundedness validation
    5. Diagnostic quality validation
    6. Architecture cleanup
    7. Documentation and handoff

The pass rejects:
  - missing project-scale validation item evidence
  - unregistered AUnit test evidence
  - missing release documentation evidence
  - consumer disagreement
  - reopened Remaining_* gaps after pass1428
  - speculative new semantic work without a real failing corpus case,
    source-shaped regression, or concrete RM contradiction
  - stale source/test/documentation/closure fingerprints
  - missing closure evidence

This pass does not add a new Ada RM semantic edge.  It turns the current
project-scale validation set into an explicit finite closure gate.
