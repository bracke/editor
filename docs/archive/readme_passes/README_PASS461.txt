Pass 461: label/goto legality diagnostics

Implemented another bounded legality-completeness increment in the Ada language model.

Changes:
- Added Legality_Duplicate_Label.
- Added Legality_Goto_Missing_Target.
- Added same-scope duplicate statement-label checking over retained executable binding metadata.
- Added conservative goto-target checking so goto statements whose target has no retained label in the same executable scope produce a legality diagnostic.
- Kept the check intentionally bounded: it does not perform full Ada control-flow accessibility analysis or cross-subprogram transfer legality.
- Added AUnit regression coverage: Test_Language_Model_Legality_Label_Goto_Pass.

This extends the pass 456-460 legality layer from declarations, generic actuals, representation items, and renames into executable transfer-target metadata.
