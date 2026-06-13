Pass 345 completeness pass

This pass extends the token-cursor Ada grammar with explicit defining-name productions.

Changes:
- Added Production_Defining_Name for ordinary declaration/subprogram/type/subtype/package formal names.
- Added Production_Defining_Operator_Symbol for quoted Ada operator-function names.
- Added Parse_Defining_Name and wired it into subprogram constructs, formal subprograms, formal packages, type declarations, subtype declarations, and entry declarations.
- Added regression coverage for ordinary defining names and quoted operator symbols in generic formal operators and package subprogram declarations.
- Extended phase579 language validation guards.

No Python, shell scripts, or parser-generator tooling were added.
