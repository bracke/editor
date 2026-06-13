Pass 568 - Static string concatenation feeding scalar Value

Implemented another bounded precise static-evaluation pass for representation clauses.

Highlights:
- Added static string-expression evaluation for top-level Ada string concatenation (`&`).
- Concatenation operands may be string literals, retained static string constants, or retained scalar Image expressions.
- Added whole-parenthesized string-expression unwrapping for static string constants.
- Routed scalar `T'Value(...)` through the shared static string evaluator so direct concatenated operands and named concatenated strings both resolve.
- Preserved subtype/range compatibility checks before typed discrete constants initialized through concatenated Value results enter the static environment.

Regression coverage:
- Named concatenated strings feeding `Color'Value` and then `Color'Pos`.
- Direct string concatenation inside `Color'Value`.
- Parenthesized concatenated string constants.
- Mixed literal-plus-named string concatenation.
- Out-of-range concatenation-fed constrained subtype constants staying nonstatic and producing the existing static-value diagnostic.
