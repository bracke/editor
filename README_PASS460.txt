Pass 460 - Renaming target legality completeness

This pass adds a bounded legality-checking increment on top of the structural
renaming declaration work from pass 448 and the first legality diagnostics from
passes 456-459.

Implemented:
- Added Legality_Renaming_Missing_Target.
- Added Legality_Renaming_Self_Target.
- Added legality diagnostics for retained renaming declarations whose renamed
  entity is missing after the renames keyword.
- Added legality diagnostics for direct self-renaming such as
  X : Integer renames X;
- Kept the check name-based and conservative; full visibility resolution of
  renamed entities remains the resolver/type-inference layer's responsibility.
- Added AUnit regression coverage:
  Test_Language_Model_Legality_Renaming_Target_Pass.

The pass intentionally does not attempt full Ada renaming conformance rules yet
(subtype conformance, callable profile conformance, object view legality, or
visibility-private-view legality). It exposes unambiguous structural legality
errors using data already retained by the language model.
