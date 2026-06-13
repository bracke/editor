Pass 601 - Dimensioned String range attributes in later constraints

- Extended copied String range-attribute constraint retention to accept the optional one-dimensional array attribute argument.
- Newly covered forms include `subtype Range_Dim_Derived_Name is String (Offset_Name'Range (1));` and the object equivalent `String (Offset_Object'Range (1));`.
- Dimension values other than `1` remain rejected in the bounded one-dimensional String model.
- Range-derived constrained String subtypes preserve First/Last/Length metadata and feed existing representation static-value paths.
- Added regression coverage for subtype-based and object-based dimensioned `Range` constraints feeding representation static values.
