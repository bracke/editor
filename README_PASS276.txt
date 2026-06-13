Phase 579 pass 276

This pass extends parser-owned Ada statement-awareness metadata for compact same-line case statements. The parser now records compact case alternative actions in forms such as:

   case Mode is when A => Worker.Deliver (Name => Item); when others => null; end case;

The new Statement_Case_Alternative_Action metadata is emitted together with executable when-alternative metadata and the existing bounded alternative-action shape metadata for calls, named associations, assignments, return expressions, and null alternatives. Record variant alternatives remain excluded from executable statement metadata.

No Outline rows, semantic declaration symbols, scopes, declarations, navigation targets, render-side parsing, or expression AST are introduced by this pass.
