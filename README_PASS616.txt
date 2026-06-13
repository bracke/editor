Pass 616 - Separator-spaced qualified discrete constants

- Extended bounded qualified discrete constant retention to tolerate Ada separator whitespace between the qualification apostrophe and the opening parenthesis.
- Newly covered forms include Character' ('B') and the same path also applies to enumeration/Boolean qualified constants such as Color' (Green).
- Spaced qualified discrete constants now feed later Character'Pos / T'Pos representation expressions through the existing retained discrete static environment.
- Added regression coverage in the qualified discrete constant pass.
