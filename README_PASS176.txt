Phase 579 pass 176 - generic subprogram navigation completeness

This pass completes a concrete gap left after ordinary subprogram body/spec navigation: model-projected generic callable rows use generic subprogram labels and retain Symbol_Generic_Subprogram kind, so the indexed Outline navigation path must treat that kind as a valid callable target when parser-owned Is_Body metadata identifies the opposite side.

Changes:
- Stripped generic subprogram / generic subprogram body Outline labels before project-index lookup.
- Accepted Symbol_Generic_Subprogram in Outline procedure-row indexed body/spec target matching.
- Added project-index regression coverage for generic subprogram spec/body target retention.
- Updated docs/outline.md, docs/syntax_colouring.md, docs/commands.md, and tools/release_check.adb.

The build/AUnit suite was not run in this environment because GNAT/gprbuild is unavailable.
