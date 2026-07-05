Pass 504 - Distributed operational property unification

This pass continues the representation/operational property unification work.

Implemented:
- Added explicit retained representation/operational kinds for:
  - No_Tagged_Streams
  - Extensions_Visible
  - Remote_Access_Type
- Unified aspect and attribute-definition clause lowering for those properties:
  - with No_Tagged_Streams
  - for P'No_Tagged_Streams use ...;
  - with Extensions_Visible
  - for P'Extensions_Visible use ...;
  - with Remote_Access_Type
  - for P'Remote_Access_Type use ...;
- Added default True handling for bare Boolean aspect forms.
- Reused shared duplicate detection, static Boolean legality diagnostics, and package target compatibility routing.
- Extended pragma lowering so corresponding pragma forms feed the same representation metadata stream.
- Expanded synonym operational unification regression coverage to assert aspect/attribute-definition equivalence for these distributed/type-streaming properties.
