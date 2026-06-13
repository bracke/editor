Pass1336 starts integration/audit pass 2: canonical semantic model agreement.

New package:

  src/core/editor-ada_canonical_semantic_model_agreement_audit_pass1336.ads
  src/core/editor-ada_canonical_semantic_model_agreement_audit_pass1336.adb

New AUnit test:

  tests/src/test_ada_canonical_semantic_model_agreement_audit_pass1336.ads
  tests/src/test_ada_canonical_semantic_model_agreement_audit_pass1336.adb

Core suite registration:

  tests/src/core_suite.adb

Purpose:

  Pass1335 audited whether the completed vertical legality slices were present,
  source-shaped, consumed, and composition-ready.  Pass1336 audits the next
  failure mode: slices that exist but disagree about the same semantic object.

  The new audit models canonical agreement for:

    * entity identity
    * type identity
    * view class identity: full/private/limited/incomplete/generic-formal/class-wide
    * callable profile identity
    * generic formal-to-actual substitution identity
    * library unit and completion identity
    * representation/freezing identity
    * flow/effect identity
    * overload-set identity
    * runtime-check identity

  It preserves the vertical-slice direction: the tests are source-shaped
  multi-slice Ada scenarios rather than synthetic closure/provenance/status
  transitions.

Source-shaped audit scenarios covered by tests:

  1. Private type, full-view representation, aggregate initialization,
     assignment/conversion, and predicate/runtime-check agreement.

  2. Generic formal actual, body replay, callable profile, substitution, and
     flow-refinement agreement.

  3. Tagged extension implementing synchronized interface, dispatching,
     class-wide conversion, contract effect, and overload-set agreement.

  4. Private child context, separate body/library completion, imported/exported
     callable profile, and representation/freezing agreement.

  5. Protected/synchronized interface, parallel loop, volatile/atomic effect
     ordering, callable profile, and runtime-check agreement.

Blockers audited:

  * missing source or AST evidence
  * missing required canonical binding
  * missing canonical identity
  * slice-local identity mismatch
  * view-class mismatch
  * profile-model mismatch
  * generic-substitution mismatch
  * library-unit/completion mismatch
  * representation/freezing mismatch
  * flow/effect mismatch
  * overload-set mismatch
  * runtime-check mismatch
  * unconsumed semantic result
  * source, AST, and model fingerprint mismatch
  * non-source-shaped scenario rejection
  * multiple blocker preservation

This pass is intentionally not a final diagnostic/projection pass.  It is a
semantic audit gate that makes later end-to-end RM coverage and consumer
integration meaningful by requiring all slices to share one canonical model.
