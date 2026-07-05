Pass 625 - Separator-spaced Base-qualified discrete constants

- Added Normalize_Static_Attribute_Spacing to canonicalize Ada separator whitespace after an attribute apostrophe before static prefix suffix checks.
- Bounded qualified discrete constant retention now accepts Color' Base'(Blue) and Primary_Color' Base'(Blue) as Base-qualified operands.
- Declared object subtype checking still rejects constrained objects initialized from out-of-range Base-qualified values.
- Extended the qualified discrete constant regression with accepted spaced Base-qualified constants and a rejected constrained-object case.
