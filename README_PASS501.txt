Pass 501 - State/ownership operational property unification

Implemented another aspect/attribute-definition unification pass for the bounded Ada language model.

Changes:
- Added explicit retained operational property kinds for:
  * Abstract_State
  * Refined_State
  * Initializes
  * Part_Of
  * Ghost
  * Relaxed_Initialization
- Unified aspect and attribute-definition clause lowering for these properties.
- Added default True handling for Boolean aspect forms without explicit values:
  * Ghost
  * Relaxed_Initialization
- Routed the new properties through shared duplicate detection, required-expression diagnostics, and target compatibility checks.
- Added package/subprogram routing for state abstraction properties and type/object routing for ownership/initialization properties.
- Added regression coverage in Test_Language_Model_State_Ownership_Operational_Unification_Pass.
