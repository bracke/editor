# Editor Pass 651

Focused grammar coverage increment: exception-handler statement-sequence structure.

## Changes

- Added `Production_Exception_Handler_Statement_Sequence` to the token-cursor grammar.
- Exception handlers now retain an explicit statement-sequence position after `=>` while preserving the existing generic `Production_Statement_Sequence` marker.
- Parameterized handlers such as `when Error : Constraint_Error | Program_Error =>` continue to retain the choice parameter and exception choice list.
- Unparameterized exception handlers such as `when others =>` are classified as exception handlers when parsed in an exception part.
- AUnit coverage was extended for parameterized and unparameterized handlers, nested raise-message statements, and block exception-part integration.

## Scope

This improves structural grammar coverage for Ada exception-handler statement sequences. It is not compiler-grade legality checking for exception choice legality, handler reachability, exception resolution, or control-flow semantics.
