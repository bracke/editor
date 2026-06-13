Phase 579 IDE-grade outline/semantic colouring pass 143

Focused change:
- Hardened Editor.Ada_Language_Model.Set_Symbol_Profile so profile updates are fingerprint-idempotent.
- Re-applying the same profile text now leaves both the symbol and analysis fingerprints unchanged.
- A different profile still updates the symbol fingerprint and aggregate analysis fingerprint.

Why:
- The language-model fingerprint is used by project-index, outline, and semantic-cache ownership checks.
- Unchanged profile refinement must not churn deterministic stamps or cause avoidable stale-result invalidation.

Coverage:
- Added Test_Language_Model_Profile_Update_Is_Idempotent.
- Updated docs/outline.md and docs/syntax_colouring.md.
- Extended tools/release_check.adb guards for source, test, and docs coverage.

Verification note:
- GNAT/gprbuild is not available in this execution environment, so the Ada build and AUnit suite were not run here.
- No Python or shell scripts were added to the project.
