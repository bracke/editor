# Editor Pass 686

This pass deepens the token-cursor grammar for Ada pragma syntax.

## Implemented

- Added `Production_Nullary_Pragma` so pragmas such as `pragma Pure;` and `pragma Elaborate_Body;` are classified separately from argument-bearing pragmas.
- Added `Production_Pragma_Argument_List` for pragma-specific argument-list retention while keeping the existing generic `Production_Association_List` marker for compatibility.
- Added `Production_Pragma_Argument_Expression` before parsing the expression/name value of each positional or named pragma argument.
- Kept `Production_Pragma_Argument_Identifier` for selectors before `=>` in named pragma argument associations.
- Added bounded recovery for missing pragma argument expressions such as `pragma Suppress (Check => );`.

## Tests

AUnit coverage was extended for:

- nullary pragmas;
- positional pragma arguments;
- named pragma argument associations;
- declaration-part pragmas;
- statement-sequence pragmas;
- malformed pragma argument recovery into following declarations.

## Scope

This improves structural grammar coverage for Ada pragma syntax. It is not compiler-grade legality checking for pragma placement, implementation-defined pragmas, staticness, entity resolution, convention legality, or argument-profile validation.
