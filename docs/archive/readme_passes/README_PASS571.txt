Pass 571 - Dimensioned static String attributes

Implemented another bounded static-evaluation pass:

- Added optional dimension-argument consumption for retained static String attributes:
  - S'Length (1)
  - S'First (1)
  - S'Last (1)
- Wired dimensioned static String attributes through Natural-valued representation expressions.
- Wired dimensioned static String attributes through signed static expressions so they can define named numbers/constants and scalar range bounds.
- Enforced String's one-dimensional shape: dimension arguments must statically evaluate to 1.
- Non-1 dimension arguments stay nonstatic and continue to produce the existing static-value diagnostic.

Regression coverage added to the static string-attribute test for:

- Green_Name'Length (1) feeding a Size clause.
- Blue_Image'Last (1) feeding signed range metadata and later representation arithmetic.
- Green_Name'Length (2) rejection with a static-value diagnostic.
