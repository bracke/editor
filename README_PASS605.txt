Pass 605 - Unconstrained String constant bound attributes in later constraints

- Extended signed static integer evaluation so named unconstrained retained static String constants expose First/Last/Length when used in later String index constraints.
- Later constrained String subtypes can now derive bounds from forms such as `subtype Constant_Bounds_Name is String (Qualified_Name'First .. Qualified_Name'Last);` where `Qualified_Name` is a retained `constant String` without explicit constrained-object bounds.
- The evaluator now reuses the shared static String bound path after the explicit constrained-object lookup, preserving constrained-object behavior while admitting the ordinary String lower bound of 1 and image-length Last for unconstrained constants.
- Optional one-dimensional array attribute arguments remain supported on this fallback path, and non-1 dimensions remain rejected by the bounded String model.
- Added regression coverage for unconstrained static String constant First/Last constraints feeding representation static values.
