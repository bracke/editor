Pass 539 - Precise type-compatible static evaluation
====================================================

Implemented a deeper static-expression pass for representation legality and
metadata extraction.

Highlights
----------
- Added a bounded static numeric environment for retained declarations.
- Static named numbers and static constants now participate in later
  representation expressions.
- Typed static constants such as `Last_Bit : constant Byte_Index :=
  Byte_Index'(Word_Bits - 1);` are evaluated when their initializer is a
  bounded static expression.
- Qualified static expressions are now interpreted and checked against retained
  integer/modular subtype ranges before being accepted as static natural values.
- Static attributes `T'First` and `T'Last` are resolved for retained integer and
  modular type ranges when their values are nonnegative.
- Modular type ranges from `type T is mod N` and integer/subtype ranges from
  `range L .. H` are retained for local static checks.
- Universal-real named constants are recognized for numeric-only clauses such as
  `Small`, while integer-valued representation fields continue to reject
  non-integer/out-of-range values.

Regression coverage
-------------------
- Static constants in attribute, enumeration, and record representation clauses.
- Qualified values such as `Natural'(Word_Bits)` and `Nibble'(2#1111#)`.
- `T'First`/`T'Last` static attributes.
- Out-of-range modular qualification rejected for an integer representation
  value and diagnosed as a missing compatible static value.
- Universal-real named constants accepted for `Small` static numeric legality.
