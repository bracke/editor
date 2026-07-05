Pass 606 - Standard.String constrained subtype bounds

- Extended constrained String subtype recognition to include fully qualified Standard.String index constraints.
- Subtypes such as `subtype Standard_Name is Standard.String (2 .. 6);` now retain the same bounded First/Last/Length metadata as `String (2 .. 6)`.
- The retained metadata feeds existing representation-expression static evaluation, constrained qualification length checks, and qualified-prefix indexing/slicing paths.
- Added regression coverage in the static String qualification pass for Standard.String constrained subtype bounds feeding Size arithmetic.
