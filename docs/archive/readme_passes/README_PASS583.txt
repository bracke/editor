Pass583: qualified static String expressions now participate in bounded static string evaluation.

Changes:
- Added bounded handling for String-compatible qualified expressions such as String'("Gr" & "een") in the retained static string evaluator.
- Constrained String subtypes now retain a root String alias so subtype-qualified string expressions such as Small_Name'("Green") can initialize static string constants.
- Qualified static string expressions can now feed scalar Value attributes and String'Length representation expressions through the existing retained image path.
- Added AUnit regression coverage for direct qualified Value operands, named qualified String constants, constrained String subtype qualification, and Length over retained qualified strings.
