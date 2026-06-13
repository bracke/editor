# Pass 681 - Scalar type definition operand grammar

- Added scalar-type operand productions for signed integer ranges, modular modulus expressions, floating digits expressions, fixed delta expressions, and decimal fixed digits expressions.
- Updated ordinary scalar type parsing so `range`, `mod`, `digits`, and `delta` operands remain structurally visible before existing expression/range parsing runs.
- Preserved existing scalar type-definition classifications and existing range-constraint parsing for current consumers.
- Added AUnit coverage for signed integer, modular, floating point, ordinary fixed point, and decimal fixed point type definitions with recovery into a following declaration.
- Scope remains structural grammar coverage only; no scalar staticness, range legality, digits/delta legality, model-number legality, or subtype compatibility checking is implied.
