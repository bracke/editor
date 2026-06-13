Pass 401 — executable exception occurrence bindings

This pass extends the parser-owned executable semantic binding layer with
exception occurrence identifiers from handlers such as:

   when Occ : Constraint_Error | Program_Error =>

The occurrence identifier is retained as Binding_Exception_Occurrence and is
kept distinct from Binding_Exception_Handler_Choice rows for the exception
choices.  Semantic colouring may treat the occurrence identifier as a local
value-like binding where safe.  Unresolved exception choices continue to degrade
conservatively without guessed targets.

No Python, shell scripts, parser generators, rendering-side parsing, external
compiler integration, or LSP integration were added.
