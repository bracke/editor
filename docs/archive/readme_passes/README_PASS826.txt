Pass826 - Parameter profile delimiter and recovery depth

Pass826 deepens Ada parameter-profile grammar metadata. Shared parameter-profile parsing now records opening and closing delimiters, semicolon separators between parameter specifications, and a bounded missing-close recovery boundary for malformed or in-progress profiles.

Implemented:
- Added token-cursor productions `Production_Parameter_Profile_Open_Delimiter`, `Production_Parameter_Profile_Close_Delimiter`, `Production_Parameter_Profile_Separator`, and `Production_Parameter_Profile_Missing_Close_Recovery_Boundary`.
- Updated `Parse_Parameter_Profile` so well-formed profiles retain delimiter/separator metadata while malformed profiles record profile-specific missing-close recovery before the surrounding declaration continues.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Parameter_Profile_Delimiters_Pass826`.
- Updated parser coverage, syntax-colouring notes, release guards, and validation markers.

This improves structural grammar coverage for Ada parameter-profile delimiters, separators, and missing-close recovery. It is not compiler-grade parameter-mode legality checking, subtype conformance, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
