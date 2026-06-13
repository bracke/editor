Pass992 — stream attribute profile conformance

This pass extends Editor.Ada_Representation_Legality with a stricter stream-profile build path. Build_With_Stream_Profiles layers direct-visibility lookup and callable-profile shape metadata over the existing stream attribute representation checks, so stream subprogram designators can now move from profile-unknown staging to known-compatible or known-mismatch status.

Implemented:
- Added Build_With_Stream_Profiles to Editor.Ada_Representation_Legality.
- Resolves stream attribute designators through direct visibility from the representation clause context.
- Checks basic stream attribute profile shape:
  - Read/Write/Output/Put_Image require two-parameter procedures.
  - Input requires a one-parameter function.
- Preserves unknown designators as profile-unknown when visibility/profile metadata cannot prove conformance.
- Separates profile mismatches from malformed stream values and incompatible stream targets.
- Added AUnit regression Test_Ada_Stream_Attribute_Profile_Conformance_Pass992.

This pass adds one compiler-grade building block for operational attribute legality. Full compiler-grade Ada analysis remains incomplete until stream subtype/mode conformance, Root_Stream_Type/Root_Buffer_Type class-wide checks, private-view-aware representation checks, cross-unit semantic closure, deeper freezing interactions, and full expression type inference are fully integrated.
