Pass 541 - signed static range evaluation

This pass deepens the precise static evaluator used by representation legality.

Implemented:
- Added a signed integer static-expression evaluator alongside the existing
  Natural-valued representation evaluator.
- Retained signed static named-number/constant values without allowing negative
  values to satisfy Natural-valued representation clauses accidentally.
- Type and subtype range metadata can now be built from signed static
  expressions, including named constants such as Low_Bound and High_Bound.
- Qualified static expressions now use signed range metadata for compatibility
  checks before flowing into Natural-valued representation metadata.
- Static attributes over signed ranges, especially T'Last when nonnegative, can
  participate in later Natural representation arithmetic.
- Added regression coverage for signed range qualification, out-of-range
  qualification rejection, and signed range attributes feeding Size clauses.

Limitations:
- This remains a bounded editor semantic model, not a full Ada front-end.
- Universal real arithmetic is still shape-checked for numeric-only properties
  such as Small; exact rational/decimal value propagation is intentionally not
  exposed through the Natural representation metadata.
