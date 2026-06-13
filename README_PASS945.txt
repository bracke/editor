# Editor Phase 579 Pass 945

Pass945 continues the compiler-grade semantic-analysis pivot after the
parser-owned syntax-tree, declarative-region, and direct-visibility foundation
passes.

## Implemented

* Added `Editor.Ada_Use_Visibility`.
* Extracted ordinary `use`, `use type`, and `use all type` clauses from the
  parser-owned Ada syntax tree.
* Split comma-separated ordinary package use clauses into deterministic clause
  records.
* Recorded per-clause owner region, source node, source range, normalized name,
  target declaration, target region, resolution state, and fingerprint.
* Added package-use lookup layered over direct visibility.
* Added deterministic ambiguity reporting when multiple used package regions
  expose the same name.
* Kept direct declarations ahead of use-clause lookup in the current region.
* Adjusted syntax-tree ownership so declarative `use` clauses inside packages,
  bodies, and nested declarative regions are owned by the current declarative
  region instead of being projected as top-level context-only items.

## Regression coverage

* `Test_Ada_Use_Visibility_Foundation_Pass945`

The regression checks package-use extraction, use-type/use-all-type metadata,
package-use member lookup, deterministic ambiguity, and direct-declaration
precedence.

## Scope

This is a compiler-grade semantic foundation for use-clause visibility. Full
compiler-grade Ada analysis still requires operator visibility for `use type`
and `use all type`, selected-name package resolution, overload resolution,
expected-type propagation, type checking, static evaluation, generic contracts,
freezing/representation legality, and cross-unit semantic closure.
