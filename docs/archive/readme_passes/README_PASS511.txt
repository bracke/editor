Pass 511 - default scalar storage order and dimension property unification

Implemented the next representation/operational property unification pass.

Changes:
- Added explicit retained property kinds for Default_Scalar_Storage_Order,
  Dimension_System, and Dimension.
- Unified aspect forms and attribute-definition clause forms for these properties
  through the same representation metadata path.
- Routed Default_Scalar_Storage_Order through the package-level target legality
  path and scalar-storage-order value validation.
- Routed Dimension_System and Dimension through type-like target compatibility
  and required-expression diagnostics.
- Added regression coverage proving both source forms retain the same explicit
  property kinds.
