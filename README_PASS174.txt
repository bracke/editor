Editor Phase 579 pass 174

Completeness pass after indexed package body/spec navigation.

Changes:
- `outline.goto-spec` now accepts `Symbol_Generic_Package` as a valid package-spec target.
- Ordinary package spec/body navigation remains unchanged.
- Added project-index regression coverage for generic package spec/body target retention.
- Updated outline and syntax-colouring documentation.
- Extended release_check guards for the generic package body/spec navigation path.

No Python or shell scripts were added to the project.
