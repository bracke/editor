Editor Pass 946

This pass adds the next compiler-grade semantic building block after direct
visibility and use-clause visibility: selected-name resolution for package
prefixes and direct selectors.

Implemented:
- New package Editor.Ada_Selected_Name_Resolution.
- Parser-owned selected-name resolution model built from Ada syntax-tree nodes.
- Deterministic resolution of selected names such as Library.Exported using:
  - declarative-region ownership,
  - direct visibility,
  - use-visibility for the prefix,
  - direct lookup of the selector in the resolved prefix region.
- Stable selected-name metadata:
  - selected-name id,
  - source node,
  - owning region,
  - prefix and selector text,
  - normalized prefix and selector,
  - prefix declaration,
  - prefix region,
  - selector declaration,
  - resolution status,
  - source line range,
  - deterministic fingerprint.
- Distinct statuses for missing prefix, ambiguous prefix, prefix with no nested
  declarative region, missing selector, ambiguous selector, and found selector.
- AUnit coverage:
  - Test_Ada_Selected_Name_Resolution_Foundation_Pass946

Updated:
- README.md
- docs/ada_parser_coverage_matrix.md
- docs/syntax_colouring.md
- tools/language_validation_check.adb
- tools/release_candidate_check.adb
- tools/release_check.adb
- tools/strict_runtime_validation_record.adb

Scope:
This is a compiler-grade semantic foundation for selected-name package-prefix
resolution. Full compiler-grade Ada analysis still requires type-based selected
component resolution, overload resolution, expected-type propagation, use type
operator visibility, static evaluation, generic contracts, freezing and
representation legality, and cross-unit semantic closure.
