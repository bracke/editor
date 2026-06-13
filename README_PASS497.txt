Pass 497 - literal/storage operational property unification

Implemented another representation/operational completeness pass focused on properties that can be written through either aspect specifications or attribute-definition clauses.

Changes:
- Added explicit retained operational representation kinds for Integer_Literal, Real_Literal, String_Literal, Max_Size_In_Storage_Elements, Storage_Model_Type, and Designated_Storage_Model.
- Extended attribute-definition clause lowering so for T'Integer_Literal use ..., for T'Max_Size_In_Storage_Elements use ..., and related clauses no longer remain generic/opaque representation items.
- Extended aspect lowering so with Integer_Literal => ..., with Real_Literal => ..., with String_Literal => ..., with Max_Size_In_Storage_Elements => ..., with Storage_Model_Type => ..., and with Designated_Storage_Model => ... use the same representation metadata path as attribute-definition clauses.
- Reused mixed aspect/attribute duplicate detection for the newly explicit properties.
- Reused static natural and positive-value legality for Max_Size_In_Storage_Elements.
- Added target compatibility checks for literal handler properties and storage-model operational properties.
- Added regression coverage proving aspect and attribute-definition forms lower to the same explicit kinds and share duplicate/target diagnostics.
