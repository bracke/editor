Pass 547 — modular subtype/derived static metadata preservation

This pass tightens precise type-compatible static evaluation for modular scalar
metadata.

Implemented:
- Preserved the modular scalar category when static range metadata is propagated
  through subtype aliases.
- Preserved the modular scalar category when static range metadata is propagated
  through derived scalar type declarations.
- Kept inherited modular metadata available to later static representation
  expressions using:
  - Alias'Modulus
  - Derived'Base'Modulus
- Added regression coverage proving that modular aliases and derived modular
  types remain valid static sources for Size expressions.

This closes a precision hole from the previous Modulus pass where aliases and
derived types inherited numeric bounds but lost the fact that the source type was
modular, causing later Modulus attributes to be treated as nonstatic.
