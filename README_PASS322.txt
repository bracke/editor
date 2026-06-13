Editor Phase 579 Pass 322

This pass extends grammar-aware recovery with named end-target validation.

Changes:
- Added syntax-tree detail nodes for named endings:
  - Node_End_Target
  - Node_Expected_End_Target
- End nodes now retain explicit target metadata for named Ada endings such as `end Run;`.
- Grammar recovery now detects compatible end boundaries that close the wrong source-level declaration/body name.
- Mismatched named endings emit Node_Mismatched_End diagnostics with both actual and expected target children.
- Added AUnit coverage for named end-target recovery.
- Extended release validation guards and documentation.

The recovery nodes remain parser-owned diagnostics/structure only. They are not Outline declaration rows and do not create semantic-colouring symbols.
