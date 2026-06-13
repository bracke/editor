Pass 490 - Stream operational attribute kind unification

Implemented the next representation/operational property unification pass.

Changes:
- Promoted stream operational attributes out of Representation_Other_Clause into explicit retained representation kinds:
  - Representation_Read_Clause
  - Representation_Write_Clause
  - Representation_Input_Clause
  - Representation_Output_Clause
- Updated attribute-definition clause lowering so for T'Read/Write/Input/Output use ... resolves to the explicit stream kind.
- Updated aspect lowering so with Read/Write/Input/Output => ... resolves to the same explicit stream kind.
- Kept stream target compatibility, handler lookup, profile conformance, mode conformance, and duplicate detection on the same shared legality path for both forms.
- Expanded the representation/operational property regression to prove Read aspects and Read attribute-definition clauses produce the same explicit stream representation kind.

This completes another source-form unification layer: stream operational attributes are no longer retained as generic/other representation clauses while aspects already participate in stream legality.
