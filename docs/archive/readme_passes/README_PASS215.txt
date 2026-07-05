pass 215

This pass adds bounded Ada variant-record metadata to the parser-owned language model.

Changes:
- Adds Has_Variant_Record_Metadata to Declaration_Flags.
- Adds Mark_Symbol_Variant_Record_Metadata for multi-line record variant parts.
- Marks same-line and multi-line record variant case parts as metadata on the owning record type.
- Surfaces variant-record metadata in Outline details.
- Adds Test_Language_Model_Variant_Record_Metadata.
- Extends language_validation_check for the new model/parser/test markers.

Variant choices and branch labels remain syntax/metadata only; they do not create standalone Outline rows or resolver symbols.
