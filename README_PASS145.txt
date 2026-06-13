Phase 579 IDE-grade outline/semantic language-model pass 145

Implemented a bounded fingerprint-correctness hardening pass in Editor.Ada_Language_Model.

Changes:
- Initial Add_Symbol fingerprints now include the full source range, declaration column, declaration flags, profile summary, and target metadata.
- Added regression coverage proving initial symbol fingerprints distinguish those metadata differences.
- Updated outline and syntax-colouring documentation with the pass 145 language-analysis note.
- Extended tools/release_check.adb guards for the source/test/doc coverage.

No Python or shell scripts were added to the project.
