Editor IDE-grade outline/semantic colouring pass 208

This pass adds bounded Ada `aliased` declaration metadata to the shared language model and declaration parser.

Key changes:
- Added Has_Aliased_Metadata to declaration flags.
- Included aliased metadata in deterministic symbol fingerprints.
- Detected sanitized `aliased` syntax on parsed declarations.
- Preserved combined metadata such as `aliased not null` declarations.
- Projected aliased metadata in Outline details.
- Added regression coverage proving aliased metadata does not create resolver symbols.
- Extended the validation guard and documentation.

The change remains metadata-only: `aliased` does not create Outline rows, does not open scopes, and does not become a semantic identifier.
