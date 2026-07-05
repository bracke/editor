Pass 452 - compiler-complete expression grammar structure

Focus:
- Deepen Ada expression parsing so the token-cursor grammar retains compiler-grade expression structure instead of collapsing expression internals into broad relation/simple-expression nodes.

Implemented:
- Added structural productions for expression operators, relational operators, membership operators, parenthesized expressions, null literals, if-expression conditions/dependent expressions, elsif/else expression parts, case-expression selectors and alternatives, quantifiers, and quantified loop schemes.
- Retained arithmetic, concatenation, exponentiation, logical, relational, and membership operators as explicit grammar nodes.
- Retained null as a distinct primary rather than as an ordinary keyword/name fallback.
- Retained parenthesized expressions separately from aggregate association lists while preserving aggregate compatibility.
- Made conditional expressions expose condition and dependent expression positions for later semantic/type passes.
- Made case expressions expose selector and per-alternative structure.
- Made quantified expressions expose quantifier and quantified loop-scheme structure.

Regression coverage:
- Added Test_Language_Model_Token_Cursor_Compiler_Complete_Expression_Grammar.

Notes:
- This pass is grammar-structural. Compiler legality such as expected-type resolution, overload resolution, static-expression evaluation, and aggregate kind resolution remains part of the semantic resolver/type-inference layer rather than the token-cursor parser.
