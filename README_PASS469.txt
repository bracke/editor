Pass 469 - operational attribute handler legality

Focus:
- Extend representation/operational legality beyond target/value checks into stream attribute handler validation.

Implemented:
- Added legality diagnostics for stream operational attribute handlers that cannot be resolved to a retained declaration.
- Added compatibility checks for stream attributes:
  - Read/Write/Output require a procedure-like retained handler.
  - Input requires a function-like retained handler.
- Kept the check bounded and syntax/model-backed: profile conformance, stream root types, access levels, and parameter/result subtype conformance remain deeper resolver/type-inference work.
- Added focused regression coverage:
  - Test_Language_Model_Legality_Operational_Attribute_Handler_Pass

Preserved:
- Existing duplicate representation clause checks.
- Enumeration representation completeness/staticness checks.
- Record representation component staticness, overlap, and target/member checks.
