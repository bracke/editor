Pass 536 - Ada representation/freezing interaction

Implemented bounded freezing-rule interaction for representation and operational
items in the Ada language model.

Changes:
- Added retained freezing-point metadata to Editor.Ada_Language_Model:
  Freezing_Point_Kind, Freezing_Point_Info, Add_Freezing_Point,
  Freezing_Point_Count, and Freezing_Point_At.
- Added Legality_Representation_After_Freezing diagnostics.
- Added representation-clause freezing checks before duplicate/value legality:
  * first declaration/profile use of the target before a representation item,
  * body/spec completion or body-stub style freezing before a later item,
  * generic instantiation and generic actual association freezing before a
    later item.
- Kept the pass bounded and model-backed: diagnostics are emitted only when the
  parser retained enough target and trigger metadata to avoid source-text-only
  guesses.
- Added an AUnit regression covering a type frozen by object declaration before
  a late Size clause and a generic actual/instance before a late Size clause.

Scope:
This is an IDE-grade freezing interaction pass. It tracks and reports retained
freezing triggers for representation legality; it is not a full Ada front-end
elaboration/freezing implementation.
