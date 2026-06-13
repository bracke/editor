Pass 600 - Dimensioned String bound attributes in later constraints
================================================================

Scope
-----
This pass continues the bounded Ada static-evaluation work around retained
constrained `String` subtype and object bounds.  Earlier passes exposed
`First`, `Last`, and `Length` for later index constraints; this pass accepts
the Ada one-dimensional array attribute argument on those operands.

Changes
-------
- The signed static integer evaluator now consumes optional `(1)` arguments
  after retained constrained `String` subtype bound attributes.
- The same handling is applied to retained constrained `String` object bound
  attributes.
- Later constrained `String` subtypes can inherit bounds from both
  subtype-derived and object-derived dimensioned attributes.
- Dimension values other than `1` are rejected for this bounded one-dimensional
  String path.
- Added regression coverage in the static String qualification/bounds test.

Representative covered forms
----------------------------

```ada
subtype Offset_Name is String (2 .. 6);
Offset_Object : constant Offset_Name := Offset_Name'("Green");

subtype Dim_Derived_Name is
  String (Offset_Name'First (1) .. Offset_Name'Last (1));

subtype Object_Dim_Derived_Name is
  String (Offset_Object'First (1) .. Offset_Object'Last (1));
```

Expected retained metadata for both derived subtypes: `First = 2`, `Last = 6`,
`Length = 5`.
