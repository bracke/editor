Pass 473 - Full representation target resolution

Focus:
- Representation/operational clause target resolution now follows retained selected-name ownership and package/object/type renames instead of relying on flat local-name matching.

Implemented:
- Split representation target lookup into direct lookup plus recursive rename-aware lookup.
- Added selected-prefix matching for representation clauses whose prefix is a retained package rename.
- Representation clauses such as `for Public.T'Size use ...` now resolve when `Public` renames the package that owns `T`.
- Enumeration representation clauses and record representation component clauses reuse the same full target resolution path.
- Renamed metadata targets have trailing semicolon cleanup before recursive lookup.
- Bounded recursion guard prevents rename cycles from destabilizing analysis.

Regression coverage:
- Added `Test_Language_Model_Legality_Representation_Full_Target_Resolution_Pass`.
- Covers selected representation targets and record representation component clauses through a package rename prefix.

Remaining deeper work:
- Cross-file unit loading, private/limited view resolution, and generic-instance semantic expansion still require the broader resolver/type-inference layer.
