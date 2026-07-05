Pass1053 - Ada cross-unit lookup integration

This pass adds Editor.Ada_Cross_Unit_Lookup_Integration, a deterministic lookup-facing bridge from Editor.Ada_Cross_Unit_Visibility into name-resolution consumer metadata.

The new model consumes snapshot-owned cross-unit visibility records for one source unit and exposes lookup entries for ordinary with visibility, use-package visibility, limited incomplete views, private views, missing dependencies, ambiguous dependencies, and overflow conditions. It preserves source unit name, lookup name, normalized lookup name, target unit, target path, with/use/limited/private flags, candidate counts, source fingerprints, and deterministic result fingerprints.

The package provides Lookup_Name and Resolve_With_Local so downstream direct/use/selected-name/type-expression consumers can prefer local declarations and then consult cross-unit context visibility without reparsing, reading files, mutating buffers, registering commands, or involving rendering.

Regression coverage is in Test_Ada_Cross_Unit_Lookup_Integration_Pass1053.
