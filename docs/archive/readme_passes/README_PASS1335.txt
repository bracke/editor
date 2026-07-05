Pass1335 starts the integration/audit phase after the ten planned semantic vertical slices.

Added package:

  Editor.Ada_Semantic_Integration_Audit_Pass1335

Purpose:

  This pass is not another diagnostic/projection/status layer and it does not
  add rendering, command, keybinding, workspace, or palette plumbing.  It adds
  a source-shaped semantic integration audit model that checks whether the
  completed vertical slices can compose through shared evidence rather than
  merely passing isolated slice-local tests.

The audit models:

  * aggregate, assignment/conversion, iterator/parallel, contract/aspect,
    context/with/use, library/subunit, interface/synchronized,
    interfacing/import/export, flow-refinement, and callable-profile slices
  * source-shaped whole-Ada scenarios spanning several slice families
  * required source, AST, type, profile, view, overload, freezing, generic
    substitution, cross-unit, flow/effect, representation, and runtime-check
    evidence roles
  * semantic consumer readiness, so a slice result is not considered complete
    merely because it exists
  * canonical model agreement, so slices cannot silently disagree on entity,
    type, view, profile, substitution, or effect interpretation
  * source/AST/type/profile/substitution/effect fingerprint freshness

Added tests:

  Test_Ada_Semantic_Integration_Audit_Pass1335

The AUnit tests cover:

  * a composition-ready suite of five source-shaped integration scenarios
  * missing vertical-slice blockers
  * unconsumed semantic-result blockers
  * required cross-unit evidence for context/subunit scenarios
  * canonical model disagreement and fingerprint mismatch blockers
  * rejection of synthetic non-source-shaped scenarios

Registered the new test in Core_Suite.

This pass begins the post-slice phase requested after Pass1334: integration,
composition readiness, RM-family audit mechanics, and end-to-end source-shaped
semantic closure checks.
