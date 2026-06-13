# Editor Phase 579 Pass757

This pass deepens structural grammar coverage for Ada `separate` subunits and body stubs.

## Changed

* Added explicit token-cursor metadata for dotted separate parent-unit names.
* Added explicit metadata for subunit body kind keywords and local body unit names.
* Added conservative body-stub metadata that can be used as a subunit relation hint without resolving or loading other files.
* Added AUnit regression coverage for package, subprogram, task, and protected subunits plus body stubs.
* Updated validation guards and coverage documentation.

## Non-goals

This pass does not perform compiler-grade subunit legality checking, cross-file body-stub/subunit conformance, semantic name resolution of parent units, library-unit consistency checking, compiler invocation, LSP integration, rendering-side parsing, or dirty-state mutation.
