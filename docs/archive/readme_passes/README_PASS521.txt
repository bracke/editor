Pass 521 - Named entity-list pragma lowering

Implemented one more representation/operational property unification pass.

Changes:
- Extended multi-entity Boolean pragma lowering to accept named associations.
- `pragma Inline (Entity => J);` now strips the association label and lowers the unified `Inline` representation/operational item for `J`.
- The same named-association path applies to the existing Boolean entity-list pragma set handled by the multi-target pragma path:
  - Inline
  - Inline_Always
  - No_Inline
  - No_Return
  - Unreferenced
  - Unmodified
  - Weak_External
  - Volatile
  - Atomic
  - Independent
  - Discard_Names
- Preserved value-bearing pragma handling on the dedicated single-target/value extraction path.
- Expanded regression coverage in `Test_Language_Model_Representation_Pragma_Unification_Pass` for named Boolean entity pragmas.
