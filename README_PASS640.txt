Pass 640 - Case-expression dependent-expression grammar

This pass improves token-cursor structural grammar coverage for Ada case expressions.

Changes:
- Added Production_Case_Expression_Dependent_Expression for the expression position after `=>` in a case expression alternative.
- Updated case-expression parsing so each `when ... => ...` alternative retains the dependent-expression position instead of only relying on generic expression nodes.
- Preserved existing selector and alternative productions.
- Added AUnit regression coverage for nested dependent-expression forms inside case alternatives, including conditional expressions, qualified expressions, and raise expressions.
- Verified recovery into a following declaration after the case expression.

This improves structural grammar coverage for Ada case-expression alternatives and their dependent expressions. It is not compiler-grade legality checking for discrete-choice coverage, choice overlap, expected type resolution, or dependent-expression type conformance.
