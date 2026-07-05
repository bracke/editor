Pass 560 - Qualified discrete static constants

This pass extends the precise static-evaluation work for Ada representation
clauses by retaining typed discrete constants whose defaults are qualified static
expressions.

Implemented:
- Added Static_Discrete_Default_Position as the common discrete-constant default
  resolver.
- Retained discrete constants initialized from qualified forms such as:
  - Color'(Green)
  - Color'Base'(Blue)
  - Boolean'(True)
  - Character'('A')
- Reused the retained discrete constant positions in later scalar attribute
  evaluation for representation expressions, for example:
  - Color'Pos (Default_Color) * 8
  - Boolean'Pos (Truth) * 8
  - Character'Pos (Letter)
- Preserved existing range validation so out-of-range or unknown defaults do not
  enter the reusable static environment.

Regression coverage:
- Added tests for qualified enumeration constants.
- Added tests for Base-qualified enumeration constants.
- Added tests for qualified Boolean and Character constants flowing into static
  representation expressions.
