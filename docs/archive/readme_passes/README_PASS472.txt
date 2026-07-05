Pass 472 - Interfacing attribute value legality

Focus:
- Extend the representation/operational legality layer beyond target-class checks for interfacing attributes.

Changes:
- Added Legality_Convention_Identifier_Required.
- Added Legality_Import_Export_Boolean_Value_Required.
- Convention attribute definition clauses now require a convention identifier-shaped value in the bounded model.
- Import and Export attribute definition clauses now require a static Boolean value (True/False or Standard.True/Standard.False).
- Preserved prior target-class checks for Convention, Import, Export, External_Name, and Link_Name.
- Preserved Link_Name / External_Name static string-literal validation.

Regression:
- Added Test_Language_Model_Legality_Interfacing_Attribute_Value_Pass.
