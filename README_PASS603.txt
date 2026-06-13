Pass 603 - Inline qualified String Range copy

- Extended copied String range-attribute constraint retention so the range source can be a direct bounded static String expression prefix, not only a named subtype/object/constant.
- The range-attribute scanner now selects the apostrophe that introduces the final Range attribute, so String qualification apostrophes in forms such as String'(""Green"")'Range no longer mask the copied range.
- Later constrained String subtypes can now derive bounds from forms such as:

  subtype Inline_Range_Name is String (String'(""Green"")'Range);
  subtype Inline_Offset_Range_Name is String (Offset_Name'(""Green"")'Range);

- Unconstrained qualified prefixes derive First = 1 and Last = retained image length; constrained qualified prefixes preserve the retained subtype First/Last bounds.
- Added regression coverage for inline qualified and inline constrained-qualified String Range constraints feeding representation static values.
