Pass1198 - Final semantic blocker trace closure

This pass adds Editor.Ada_Final_Semantic_Blocker_Trace_Closure.

The pass consumes the Pass1196/1197 final semantic provenance and search-index rows and groups them into deterministic end-to-end trace chains.  It is not a UI projection layer.  It preserves the actual semantic blocker family, provenance status, source node and span, source fingerprint, feed/index links, stale/withheld decisions, and a stable trace fingerprint so one final semantic failure can be followed from semantic closure through diagnostic integration, feed insertion, diagnostic indexing, provenance, and search.

Covered blocker roots include local legal traces, cross-unit final closure, generic replay, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility/lifetime, discriminant/variant, AST repair, coverage gates, view barriers, multiple blockers, stale inputs, and unknown/indeterminate states.

Added regression:

  Test_Ada_Final_Semantic_Blocker_Trace_Closure_Pass1198

The regression checks blocker-family/root preservation, node/span/source-fingerprint lookup, feed/index link preservation, stale trace preservation, multiple-blocker preservation, and deterministic fingerprints.
