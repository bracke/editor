Pass 542 - typed static constant compatibility refinement

Implemented a further static-evaluation precision pass for the Ada semantic
language model.

Changes:
- Added retained range propagation for subtype aliases such as:
    subtype Octet is Byte;
- Added retained range propagation for derived integer/modular scalar types such as:
    type Derived_Byte is new Byte;
- Added typed static-constant compatibility gating before constants are inserted
  into the reusable static numeric environment.
- Out-of-range typed constants are no longer reused by later representation
  expressions, so clauses such as `for T'Size use Bad;` now correctly remain
  nonstatic when `Bad` was declared outside its subtype range.
- Tightened numeric-only qualified-expression recognition so known retained
  integer/modular prefixes range-check integer-qualified numeric expressions.
- Added regression coverage for valid subtype-alias constants, invalid typed
  constants, and derived-type range inheritance in later representation clauses.
