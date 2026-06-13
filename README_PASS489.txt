Pass 489 - Representation / operational property aspect-clause unification

Implemented a broader unification pass for Ada representation and operational properties that can be written either as aspects or as attribute-definition clauses.

Changes:
- Extended the common representation/operational property catalog beyond the previously handled representation attributes.
- Added retained clause kinds for:
  - Stream_Size
  - External_Tag
  - Put_Image
- Lowered aspect forms into the same representation metadata stream used by attribute-definition clauses:
  - with Stream_Size => ...
  - with External_Tag => ...
  - with Put_Image => ...
- Attribute-definition clauses for the same properties continue to use the same path:
  - for T'Stream_Size use ...;
  - for T'External_Tag use ...;
  - for T'Put_Image use ...;
- Reused common duplicate detection across mixed aspect / attribute-definition forms.
- Reused common legality checking:
  - Stream_Size requires static positive natural value.
  - External_Tag requires a static string literal value.
  - Put_Image requires a retained callable handler and procedure-like handler kind.
  - operational/representation property targets are checked through the shared target-compatibility path.
- Added regression coverage in Test_Language_Model_Representation_Operational_Property_Unification_Pass.

This pass closes the immediate structural gap where only a subset of representation/operational property names were unified between aspect syntax and attribute-definition clause syntax.
