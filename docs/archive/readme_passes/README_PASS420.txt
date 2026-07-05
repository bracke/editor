Editor  pass420

This pass extends the Ada token-cursor parser with structural delay-statement grammar coverage.

Implemented:
- Added Production_Delay_Until_Statement.
- Added Production_Delay_Relative_Statement.
- Parsed `delay until <expression>;` as the Ada delay-until alternative.
- Parsed `delay <expression>;` as the Ada relative-delay alternative.
- Kept the common Production_Delay_Statement wrapper for existing consumers.
- Added AUnit coverage for both alternatives.
- Updated release/static guards and documentation.

Still intentionally conservative:
- No compiler-grade time-expression legality checking.
- No duration/clock type validation.
- No tasking runtime semantic validation.
