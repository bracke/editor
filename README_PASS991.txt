Editor Phase 579 pass991

Implemented stream attribute representation legality staging in Editor.Ada_Representation_Legality.

Highlights:
- Added stream attribute recognition for Read, Write, Input, Output, and Put_Image representation clauses.
- Added stream subprogram designator metadata and deterministic stream legality statuses.
- Added target-shape checks requiring stream attributes to apply to type/subtype targets, conservatively preserving unknown targets.
- Rejects malformed stream representation items such as numeric, null, Boolean, string, or call-shaped values where a subprogram designator is required.
- Preserves profile-unknown stream designators as explicit metadata for later profile-aware stream conformance instead of treating them as silently valid.
- Added deterministic counters for stream errors, target errors, profile errors, and profile-unknown cases.
- Added AUnit regression Test_Ada_Stream_Attribute_Representation_Legality_Pass991.

This pass adds one compiler-grade building block for operational stream-attribute representation legality. Full compiler-grade Ada analysis remains incomplete until stream profile conformance is connected to callable-profile metadata, private-view-aware representation checks, cross-unit semantic closure, deeper freezing interactions, and full expression type inference are fully integrated.
