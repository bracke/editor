Pass 617 - Separator-spaced discrete attribute defaults

- Extended bounded discrete static-default retention so attribute designators tolerate Ada separator whitespace after the apostrophe.
- Newly covered retained constants include Character' Succ (X), Color' Pos (Y)-style attribute functions, and scalar bound attributes such as T' First / T' Last when used as typed discrete constant defaults.
- Spaced discrete attribute defaults now feed later Character'Pos / T'Pos representation-expression static values through the retained discrete static environment.
- Added regression coverage in the qualified discrete constant pass for spaced Character Succ and spaced subtype First defaults.
