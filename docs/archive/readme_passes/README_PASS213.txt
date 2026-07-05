IDE-grade Outline/Semantic Colouring — Pass 213

This parser-completeness pass adds bounded scalar numeric declaration-form metadata to the Ada language model.

Implemented:
- Added Has_Range_Metadata, Has_Modular_Metadata, Has_Digits_Metadata, and Has_Delta_Metadata to Declaration_Flags.
- Included the new flags in deterministic symbol fingerprints.
- Updated Editor.Ada_Declaration_Parser to retain scalar numeric form metadata for integer range types, modular types, floating-point digits types, fixed-point delta/digits types, range-constrained subtypes, and generic formal scalar types.
- Updated Outline detail projection so affected declarations can show range/mod/digits/delta metadata.
- Added Test_Language_Model_Scalar_Type_Metadata.
- Extended language_validation_check for the new model/test markers.
- Updated docs and release checklist.

The metadata remains bounded and parser-owned: range bounds and numeric expressions are not learned as child symbols, and the scalar-form keywords are not inserted into semantic lookup.
