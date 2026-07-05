Pass 516 - resolver-driven pragma representation property lowering

Implemented another representation/operational property unification pass.

Changes:
- Replaced the remaining manual pragma property-to-representation-kind table in
  Add_Representation_Pragma_Representation with the shared Representation_Kind_For
  resolver used by aspects and attribute-definition clauses.
- Preserved stable source-facing attribute names for lowered pragmas while deriving
  the semantic kind from the canonical shared property catalog.
- Kept interfacing pragmas on their dedicated lowering path so Convention/Import/
  Export/Interface/External keep their pragma-specific argument positions instead
  of being duplicated as generic Boolean representation items.
- Extended regression coverage for pragma properties that were known to the shared
  resolver but could previously drift out of pragma lowering:
  - pragma Discard_Names (E)
  - pragma Volatile_Function (F)
- This makes future representation/operational property additions automatically
  available to aspect recognition, attribute-definition clauses, Boolean aspect
  defaulting, and entity pragma lowering where the pragma target shape is the
  standard first-entity-argument form.
