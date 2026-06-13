Editor Phase 579 pass987

This pass adds one compiler-grade building block for representation-clause legality: enumeration representation clause completeness.

Implemented:
- Extended Editor.Ada_Representation_Legality with Enumeration_Representation_Legality_Info.
- Classifies enumeration representation literal associations independently from the parent representation clause.
- Validates enumeration targets using parser-owned type/literal shape.
- Checks named and positional literal coverage.
- Detects unresolved literals, duplicate literal associations, duplicate static representation values, non-static/malformed values, incomplete literal coverage, non-enumeration targets, and value-order violations.
- Added deterministic counters for enumeration representation errors, duplicate literals, duplicate values, static errors, and incomplete coverage.
- Added AUnit regression Test_Ada_Enumeration_Representation_Legality_Pass987.

Full compiler-grade Ada analysis remains incomplete until the remaining layers such as cross-unit semantic closure, deeper expression type inference, full freezing interactions, and complete operational/representation item legality are fully integrated.
