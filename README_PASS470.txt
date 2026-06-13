Pass 470 - storage-specific representation attribute legality

Focus
- Extend the representation/operational legality layer beyond duplicate and
  handler checks with storage-specific target-class validation.

Changes
- Added legality diagnostics:
  - Legality_Storage_Pool_Target_Not_Access
  - Legality_Storage_Size_Target_Incompatible
- Added model-backed target checks for storage representation attributes:
  - Storage_Pool now requires a retained access type target.
  - Storage_Size now requires a retained access type or task type target.
- Preserved existing representation/operational diagnostics for unresolved
  targets, incompatible representation classes, static values, Bit_Order,
  enumeration representation coverage, record component layout, and stream
  operational handlers.
- Added regression coverage:
  - Test_Language_Model_Legality_Storage_Attribute_Target_Pass

Notes
- This pass remains deliberately bounded to checks supported by retained
  language-model metadata. Full pool-object type conformance and task-storage
  representation details remain deeper resolver/type-inference work.
