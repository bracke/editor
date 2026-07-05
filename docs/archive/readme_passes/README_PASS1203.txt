Pass1203 — Final Semantic Remediation Diagnostic Provenance/Search

This pass adds Editor.Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search.

The new package consumes Pass1202 final remediation diagnostic rows and links each row back to the semantic evidence that produced it: remediation closure rows, remediation gate rows, blocker trace closure rows, final semantic blocker family, unified diagnostic feed rows, diagnostic index rows, and base diagnostic provenance rows.

This is not a UI projection or status layer. It preserves the prerequisite blocker family that prevented a downstream legality result from remaining confident, including stale snapshot evidence, AST/coverage repair, cross-unit closure, view barriers, generic replay/backmapping, overload/type evidence, representation/freezing, flow/contract proof, tasking/protected effects, elaboration, accessibility/lifetime, discriminant/variant evidence, preserved semantic errors, multiple blockers, and indeterminate states.

The package provides deterministic bounded lookup by provenance status, provenance stage, blocker family, syntax node, source position, feed link, and diagnostic-index link. It also exposes counters for withheld legal rows, errors, warnings, stale rejections, preserved semantic errors, indeterminate rows, multiple blockers, feed/index/base provenance links, closure links, gate links, trace links, and a stable model fingerprint.

Added AUnit regression:

Test_Ada_Final_Semantic_Remediation_Diagnostic_Provenance_Search_Pass1203

The regression verifies that remediation diagnostics preserve blocker-family provenance, link back to closure/gate/trace/feed/index/base-provenance evidence, support node/position/feed/index queries, and keep stable fingerprints.
