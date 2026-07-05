# Pass 679 - Renaming declaration internal grammar

This pass improves structural grammar coverage for Ada renaming declarations.

Implemented:

- Added `Production_Renaming_Defining_Name` for package, subprogram, object,
  exception, and generic renaming declaration defining names.
- Added `Production_Renaming_Subtype_Indication` for object renaming subtype
  indications before `renames`.
- Added `Production_Renaming_Parameter_Profile` for subprogram renaming
  parameter profiles.
- Added `Production_Renaming_Result_Subtype` for function renaming result
  subtype positions.
- Preserved existing renaming declaration classifications and renamed-entity
  parsing.
- Extended AUnit coverage for package, subprogram, object, exception, and
  generic renaming internals.

This remains structural grammar coverage only. It is not compiler-grade legality
checking for renamed-entity resolution, subtype/profile conformance, overload
resolution, visibility, or renaming legality.
