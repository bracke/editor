Pass 467: representation and operational clause legality beyond duplicates

Implemented a bounded legality expansion for representation and operational clauses using the retained Ada language model metadata.

New legality diagnostics:
- Legality_Representation_Target_Not_Found
- Legality_Representation_Target_Incompatible
- Legality_Representation_Static_Value_Required
- Legality_Bit_Order_Invalid_Value
- Legality_Enumeration_Representation_Missing_Literal
- Legality_Enumeration_Representation_Literal_Not_Found
- Legality_Record_Component_Target_Not_Record
- Legality_Record_Component_Not_Found

Checks added:
- representation clauses whose targets do not resolve to retained declarations
- representation clauses attached to incompatible retained target classes
- numeric representation attributes that do not retain a static natural value
- Bit_Order clauses whose values are not Low_Order_First or High_Order_First
- enumeration representation clauses that omit retained literals
- enumeration representation clauses that name unknown literals
- record representation component clauses against non-record targets
- record representation component clauses that name components not retained in the target record
- stream operational attributes Read/Write/Input/Output are treated as type-target operational clauses for target-class checking

Existing duplicate/value/overlap legality diagnostics remain intact.
