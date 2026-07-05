Pass1314: Numeric/static expression vertical slice

This pass adds Editor.Ada_Numeric_Static_Expression_Vertical_Slice_Legality.

It is a concrete Ada semantic vertical slice, not another closure/provenance/recheck layer.  It models static expression legality and universal numeric resolution used by overload resolution, subtype/range predicates, representation clauses, aggregates, and Ada 2022 expression consumers.

Covered semantics include named numbers, static constants, integer/real literals, unary and binary static operators, qualified expressions, static attributes, static range bounds, modular expressions, fixed-point expressions, universal integer/real resolution, expected type compatibility, static divide-by-zero, exponent naturalness, fixed delta compatibility, out-of-base range bounds, modular modulus bounds, source/AST/type fingerprint freshness, and runtime-check versus static-context distinction.

The AUnit regression uses source-shaped expression rows such as named-number declarations, static constants, numeric operators, qualified expressions, attributes, range bounds, modular conversions, fixed-point expressions, and stale evidence cases.
