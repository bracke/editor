Pass1147 - Parser / AST coverage repair legality

This pass adds Editor.Ada_AST_Coverage_Repair_Legality, a snapshot-owned
semantic repair model for parser/AST coverage gaps found and gated by the
Pass1132-Pass1136 audit/gate layers.

The package records concrete repairs for parser nodes, structural AST shape,
source spans, name/type/staticness/contract/flow/representation/cross-unit
metadata, semantic consumers, consumer integration, token-only parse
replacement, and graceful-degradation replacement.  Repaired constructs become
explicit legal repair rows; unrepaired or partially repaired constructs remain
first-class blockers so widened legality engines cannot treat incomplete Ada
2022 grammar coverage as confident semantic truth.

This is not a projection/status pass.  It turns previously passive coverage
gaps into actionable repair facts that can clear semantic gates for constructs
whose parser/AST/metadata/consumer coverage has been made complete.

AUnit coverage added:
- Test_Ada_AST_Coverage_Repair_Legality_Pass1147
