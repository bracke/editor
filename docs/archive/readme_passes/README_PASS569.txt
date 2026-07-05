Pass 569 - Static String'Length evaluation

Implemented another bounded static-evaluation pass in the Ada semantic language model.

Changes:
- Added retained static String'Length evaluation for named bounded static string constants.
- Static strings initialized from literals, concatenation, and scalar Image attributes now expose their decoded image length to representation expressions.
- Wired String'Length through Natural-valued representation expressions.
- Wired String'Length through signed static expressions so it can participate in named-number/static-constant bounds and scalar range metadata.
- Canonicalized Standard.String to String for the static subtype-alias root model.
- Static string constants declared through String subtype aliases now remain reusable static string sources.
- Unknown string names used with 'Length remain nonstatic and continue to produce the existing static-value diagnostic.

Regression coverage:
- Named concatenated string Length in Size arithmetic.
- Image-fed string constant Length in Size arithmetic.
- String'Length feeding signed range metadata and later representation arithmetic.
- String subtype-alias constants retaining static Length.
- Unknown String'Length source rejected as nonstatic with a diagnostic.
