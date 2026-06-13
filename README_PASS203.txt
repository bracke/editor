Phase 579 pass 203

Implemented command surface canonicalization for Outline.

Changes:
- Stable_Command_Name now returns canonical dotted names for:
  - outline.refresh
  - outline.clear
  - outline.show
  - outline.focus
  - outline.open-selected
- Command lookup continues to resolve only canonical dotted Outline command names.
- Added regression coverage rejecting legacy spellings:
  - refresh-outline
  - clear-outline
  - show-outline
  - focus-outline
  - open-selected-outline-item
- Expanded the Phase 579 IDE-grade command-surface test to include the base Outline commands, not only project-index/navigation commands.
- Updated docs to remove user-facing duplicate spellings.
- Extended phase579_language_validation_check to guard canonical command names and stale docs.

Static validation:
- No legacy dash-style Outline command spelling remains in user-facing docs.
- Legacy spellings remain only inside negative regression tests and validation markers.
- No Python or shell scripts were added.
