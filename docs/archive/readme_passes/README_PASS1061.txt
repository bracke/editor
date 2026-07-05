Pass1061 - Generic instantiated-body diagnostics projection

This pass extends Editor.Ada_Generic_Contract_Diagnostics so generic instantiated-body substitution analysis can be projected into the normal generic contract diagnostics model.

Implemented:
- Added Build_With_View_Compatibility_And_Body_Analysis.
- Projects Editor.Ada_Generic_Instantiated_Body_Analysis statuses into deterministic diagnostics.
- Adds diagnostic kinds for instantiated-body private-view barriers, limited-view barriers, cross-unit unresolved substitutions, object mismatches, unknown substitutions, missing body contracts, and contract mismatches.
- Preserves instantiated-body substitution identity, body contract identity, generic-view identity/status, source spans, detail text, severity, source fingerprints, and deterministic diagnostic fingerprints.
- Adds counters for total instantiated-body diagnostics, private barriers, limited barriers, unresolved substitutions, missing body contracts, and contract mismatches.
- Adds regression coverage in Test_Ada_Generic_Contract_Diagnostics_Instantiated_Body_Pass1061.
- Keeps the pass projection-only: no rendering-side parsing, file IO, dirty-state mutation, command registration, workspace mutation, or compiler invocation.

This pass adds one compiler-grade building block for generic instantiated-body diagnostic projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
