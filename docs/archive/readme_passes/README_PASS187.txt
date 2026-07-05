Editor pass 187

Completeness pass after profile-aware Outline navigation.

Changes:
- Hardened indexed callable body/spec navigation.
- If the selected Outline callable row retained parser-owned profile metadata,
  the indexed target must also retain a matching profile.
- Unprofiled same-name callable targets no longer satisfy a profiled selected
  row, preventing overload ambiguity from reappearing through incomplete target
  metadata.
- Rows without retained profile metadata keep the previous conservative
  name/kind/body-side behavior.
- Updated docs and release_check guards.

Build note:
- GNAT/gprbuild/AUnit were not available in this environment, so this pass was
  not compiled here.
