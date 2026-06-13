Pass 587 - Constrained String subtype attributes

- Reused retained constrained String subtype bound metadata for static attribute evaluation.
- Small_Name'First, Small_Name'Last, and Small_Name'Length now feed bounded static representation expressions directly.
- Non-1 lower bounds such as subtype Offset_Name is String (2 .. 6) preserve their retained First/Last values while Length remains component-count based.
- Added regression coverage for constrained String subtype First/Last/Length in representation-expression static values.
