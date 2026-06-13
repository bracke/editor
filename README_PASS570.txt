Pass 570 - Static string bound attributes

Implemented another bounded static-evaluation pass in the Ada semantic language model.

Highlights:
- Added retained static String'First and String'Last evaluation for named static string constants.
- Reused the existing static string environment for constants initialized from literals, concatenation, scalar Image attributes, and String subtype aliases.
- Wired String'First/String'Last through Natural-valued representation expressions.
- Wired String'First/String'Last through signed static expressions used by named numbers/constants and scalar range metadata.
- Kept the implementation deliberately object-bound: only retained static string constants expose First/Last/Length; arbitrary array objects and array type metadata are not inferred.
- Extended regression coverage in the static string Length test to include First and Last arithmetic.
