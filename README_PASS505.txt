Pass 505 - Task/protected/storage operational property unification

Implemented the next aspect/attribute-definition unification pass for remaining
operational properties adjacent to the representation legality model.

Changes:
- Added explicit retained operational property kinds for:
  - No_Task_Parts
  - Exclusive_Functions
  - Simple_Storage_Pool_Type
- Lowered aspect forms and attribute-definition clauses into the same retained
  representation/operational metadata path.
- Added default True handling for bare Boolean aspect forms.
- Routed these properties through common duplicate detection and static Boolean
  legality checks.
- Added target compatibility routing:
  - No_Task_Parts: type-like targets
  - Simple_Storage_Pool_Type: type-like targets
  - Exclusive_Functions: protected targets
- Extended pragma lowering for matching property names so pragma, aspect, and
  attribute-definition forms share the same downstream legality model.
- Added regression coverage for mixed aspect/attribute retention and explicit
  kind mapping.
