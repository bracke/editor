Pass597: constrained String range attributes now feed later static String index constraints.

- Added bounded retention for String index constraints copied with `'Range`, such as `subtype Range_Derived_Name is String (Offset_Name'Range);`.
- The retained range metadata works for constrained String subtypes and constrained String constants/objects that already expose static `First`/`Last` bounds.
- Derived range-attribute subtypes preserve `First`, `Last`, and `Length` and feed existing constrained qualification, subtype attribute, and qualified-prefix indexing/slicing paths.
- Added regression coverage for both subtype-based and object-based `'Range` constraints feeding representation static values.
