Pass1026 - child-unit visibility from parent/private-child contexts

Implemented package:
- Editor.Ada_Child_Unit_Visibility

Scope:
- Projects child-unit legality metadata from Editor.Ada_Cross_Unit_Closure into lookup-facing child visibility metadata.
- Classifies public child units as visible.
- Classifies private child units as hidden from external-client and parent-visible-part contexts.
- Classifies private child units as visible from parent private-part and parent body contexts.
- Preserves missing parent, ambiguous parent, overflow, and parent-role-mismatch states explicitly.
- Records parent/child unit names, paths, private-child flags, visibility booleans, candidate counts, and deterministic fingerprints.

New counters/APIs:
- Visibility_Count
- Visibility_At
- Lookup_Child
- Visible_In_Context
- Public_Child_Visible_Count
- Private_Child_Hidden_Count
- Private_Child_Private_Context_Visible_Count
- Private_Child_Body_Context_Visible_Count
- Parent_Error_Count
- Missing_Parent_Count
- Ambiguous_Parent_Count
- Overflow_Count
- Fingerprint

Regression:
- Test_Ada_Child_Unit_Visibility_Context_Pass1026

This pass adds one compiler-grade building block for cross-unit child-unit visibility. Full compiler-grade Ada analysis remains incomplete until complete with/use visibility integration, private/limited view semantics, body/spec semantic conformance, separate-body/stub closure, overload/type resolution across units, and generic legality across unit boundaries are fully integrated.
