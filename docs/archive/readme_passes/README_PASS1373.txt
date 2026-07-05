Pass1373 — Remaining Gap Remediation Pass 7

Selected Pass1366 inventory gap:

Remaining_Body_Stub_Elaboration_Private_View_Edge

This pass remediates a concrete cross-unit edge where a body stub, separate body, private/full view evidence, and elaboration availability must agree before semantic consumers may surface a final result.

The remediation requires agreement across:

* body-stub and separate-body identity
* parent unit and completion evidence
* private/full/limited-view visibility barriers
* elaboration availability and call-before-body evidence
* renamed/selected target evidence when a separate body is reached through an alias
* callable profile preservation for the completed body
* runtime accessibility-check preservation
* semantic consumer surfacing
* final readiness gap removal
* source, AST, entity, unit, view, profile, alias, visibility, elaboration, and consumer fingerprint freshness

The AUnit suite covers legal, illegal, runtime-check, indeterminate, inventory-gate, final-gate, corpus-balance, consumer, and fingerprint cases.
