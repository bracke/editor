Editor pass695 -- conservative profile-parameter legality pass

This pass implements the numbered item 12 follow-up as a deliberately bounded
legality-adjacent improvement, not as compiler-grade legality checking.

Changes:
- Added Legality_Duplicate_Profile_Parameter to the retained language model
  diagnostic kind set.
- Added a deterministic local profile scan over retained callable profile
  summaries.
- Diagnoses duplicate parameter identifiers inside procedure, function, entry,
  generic subprogram, and formal subprogram profiles when the model has a
  bounded retained profile summary.
- Leaves overload resolution, subtype conformance, overriding legality,
  visibility legality, dispatching rules, and full Ada legality to later work.
- Added AUnit regression coverage for duplicate profile parameter diagnostics
  while preserving a clean same-profile positive case.
- Updated the  validation guard so the new diagnostic kind, parser
  helper, and regression test are required.

Invariant notes:
- No rendering-side parsing.
- No dirty-state mutation.
- No file save/reload during analysis.
- No LSP, compiler invocation, external parser generator, Python, or shell
  script is introduced into the project.
- Diagnostics are snapshot/model-owned and bounded by the existing legality
  diagnostic cap.
