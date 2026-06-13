Pass 488 - Unchecked_Union representation legality

Implemented another bounded Ada representation-completeness pass focused on
Unchecked_Union, the remaining representation pragma/aspect family member next
to Pack, Atomic, Volatile, Independent, and component representation pragmas.

Changes:
- Added Representation_Unchecked_Union_Clause to the retained language model.
- Lowered pragma Unchecked_Union (T) into the common representation metadata
  stream with Attribute_Name = "Unchecked_Union" and Item_Text = "True".
- Lowered the Unchecked_Union aspect into the same representation item path.
- Added target-specific legality: Unchecked_Union must target a record type.
- Added value legality: Unchecked_Union requires a static Boolean value when an
  explicit aspect/attribute-style value is present.
- Reused existing duplicate representation detection across mixed pragma,
  aspect, and attribute-definition-style forms.
- Added regression coverage for pragma lowering, aspect lowering, non-record
  target diagnostics, and non-Boolean value diagnostics.
