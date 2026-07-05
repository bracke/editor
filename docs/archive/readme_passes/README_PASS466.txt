Pass 466 - duplicate aspect association legality

This pass extends the bounded Ada legality layer with aspect-specification
association checks.

Implemented:
- Added Legality_Duplicate_Aspect_Association.
- Scans retained syntax-tree aspect association nodes rather than raw lines, so
  attached aspects on declarations/bodies and standalone aspect clauses share
  the same legality path.
- Diagnoses duplicate aspect marks within a single aspect specification, such as:
    type Flag is new Boolean with Size => 8, Volatile, Size => 16;
- Leaves distinct aspect specifications independent, and does not attempt deeper
  aspect-specific semantic legality such as expression type, operational aspect
  legality, or entity-class applicability.
- Added AUnit regression coverage:
    Test_Language_Model_Legality_Aspect_Association_Pass
