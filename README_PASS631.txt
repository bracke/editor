Editor Phase 579 - Pass 631

Focused area: pragma identifier grammar.

Changes:
- Added Production_Pragma_Identifier to the token-cursor grammar result stream.
- Introduced a bounded Parse_Pragma production for:
  - nullary pragmas such as pragma Elaborate_Body;
  - pragmas with positional or named argument associations;
  - declaration and statement-sequence pragma occurrences.
- Kept pragma argument associations structural and widened named-argument recognition to identifier-like keyword tokens before =>.
- Replaced the old generic semicolon-scan path for pragmas with the structural pragma parser.
- Added AUnit regression coverage for nullary declaration pragmas, named pragma arguments, and statement-sequence pragmas.

Scope:
This pass improves structural grammar coverage for Ada pragma syntax. It does not perform compiler-grade legality checking for pragma-specific placement rules, implementation-defined pragma names, or argument profile conformance.
