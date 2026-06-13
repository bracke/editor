Pass 479 - Stream operational attribute profile legality

Focus:
- Add bounded stream profile conformance checks for operational attributes Read, Write, Input, and Output.

Changes:
- Added Legality_Stream_Attribute_Profile_Incompatible.
- Added Legality_Stream_Attribute_Mode_Incompatible.
- Read/Write/Output handlers are now checked beyond procedure/function kind:
  - retained profiles must include a stream formal;
  - Read requires a second item formal with out mode;
  - Write and Output reject out/in out item modes;
  - Input requires a single stream formal and a return profile matching the represented target name in the bounded model.
- Kept full overload/profile conformance conservative: exact class-wide stream type and overload resolution remain deeper resolver work.

Tests:
- Test_Language_Model_Legality_Stream_Attribute_Profile_Pass
