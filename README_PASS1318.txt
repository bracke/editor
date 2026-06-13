Pass1318 - Body/spec conformance vertical slice

Adds Editor.Ada_Body_Spec_Conformance_Vertical_Slice_Legality.

This is a real vertical semantic pass, not diagnostic/provenance/recheck scaffolding.
It models Ada body/spec completion and conformance directly for subprograms,
packages, task/protected units, generic bodies, separate bodies, private/full-view
completions, deferred constants, and incomplete types.

The pass checks:
- required body presence and optional body acceptance
- duplicate body rejection
- body/spec unit-kind conformance
- completion region/placement legality
- profile mode/type/default/null-exclusion/convention/result conformance
- generic formal and generic body availability checks
- separate-body stub and parent matching
- private type full-view completion
- deferred constant completion matching
- incomplete type completion
- visibility, private-view, limited-view, elaboration, overload, and representation blockers
- source/spec/body/profile fingerprint freshness

AUnit coverage is added in
Test_Ada_Body_Spec_Conformance_Vertical_Slice_Legality_Pass1318.
