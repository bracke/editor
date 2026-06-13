Pass 614 - String subtype range-dispatch guard

- Tightened declaration metadata registration so constrained String subtypes are dispatched to the String index-constraint path before generic scalar range handling.
- Prevents raw occurrences of `range` and `..` inside an inline static String prefix from causing a declaration such as `subtype S is String (String'("range ..")'Range);` to be treated as a scalar subtype range.
- The String-specific path still uses the top-level dots scanner and copied `Range` handling from passes 607-613.
- Added regression coverage for an inline copied String `Range` whose retained literal contains both the word `range` and the token text `..`.
