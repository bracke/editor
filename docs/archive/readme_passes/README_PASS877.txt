Editor — Pass877

This pass improves structural grammar coverage for subprogram contract/aspect
placement.

Implemented:
- Production_Subprogram_Declaration_Aspect_Specification.
- Production_Subprogram_Body_Aspect_Specification.
- Production_Subprogram_Contract_Aspect_Placement.
- Parser metadata for aspects attached to subprogram declarations.
- Parser metadata for aspects attached to subprogram bodies before `is`.
- Contract-placement metadata for Pre/Post/Global/Depends-style subprogram
  aspect lists.
- Regression coverage in
  Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Placement_Pass877.
- Validation and release guard updates.

Scope note:
This improves structural grammar coverage for subprogram contracts/aspects.  It
is not compiler-grade contract legality checking, Global/Depends validation,
profile conformance, overload resolution, compiler invocation, LSP integration,
render-side parsing, or dirty-state mutation.
