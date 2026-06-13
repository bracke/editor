Pass1029 - cross-unit representation target resolution

- Added Editor.Ada_Cross_Unit_Representation_Targets.
- Projects representation-legality target metadata through cross-unit with/use visibility.
- Classifies locally resolved targets, visible cross-unit prefixes, limited-view prefixes, private-view prefixes, missing prefixes, ambiguous prefixes, overflow prefixes, and no-prefix local failures.
- Retains source unit, target text, normalized target, prefix, selector, visible target unit/path, candidate count, status, and deterministic fingerprint metadata.
- Added deterministic counters for resolved, local, missing, ambiguous, limited-view, private-view, and no-cross-unit-prefix cases.
- Added AUnit regression Test_Ada_Cross_Unit_Representation_Target_Resolution_Pass1029.
