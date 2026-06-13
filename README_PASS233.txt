Editor Phase 579 IDE-grade Outline/Semantic Language Model Pass 233

This pass adds bounded Ada child library-unit metadata to the parser/language model.

Implemented:
- Declaration flag Has_Child_Unit_Metadata.
- Deterministic fingerprint participation for child-unit metadata.
- Parser detection for dotted package/procedure/function defining unit names, including private child packages.
- Outline detail projection using child-unit.
- Regression coverage: Test_Language_Model_Child_Unit_Metadata.
- Phase579 validation guard markers for the new model/parser/test coverage.

Conservative behavior:
- Parent-name segments are not learned as separate symbols.
- No child-unit legality or completion inference is attempted.
- No cross-file target is produced without normal project-index validation.
