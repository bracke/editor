Phase 579 pass 177 — separate-body parent navigation completeness

This pass completes a concrete remaining Outline navigation gap after package and callable spec/body pairing: selected separate-body rows can now use retained parser-owned parent metadata for indexed goto-spec navigation.

Changes:
- Projected Symbol_Separate_Body as a callable Outline row instead of unknown.
- Added separate-body recognition to the Outline body-label helper.
- Extended outline.goto-spec to resolve the selected separate body, read Symbol.Target_Name, resolve that parent declaration in the transient Ada project index, and navigate to the non-body parent declaration.
- Added project-index regression coverage for separate-body parent target retention.
- Updated docs/outline.md, docs/syntax_colouring.md, docs/commands.md, and release_check guards.

No Python or shell scripts were added to the project source tree. Build/AUnit execution was not performed in this environment because GNAT/gprbuild is unavailable.
