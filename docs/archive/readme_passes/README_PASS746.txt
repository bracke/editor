# Editor pass746

This pass adds conservative syntax-recovery legality diagnostics on top of
already-retained Ada syntax-tree recovery metadata.

Changes:

* Added legality diagnostic kinds for malformed pragma syntax, malformed aspect
  association delimiters, missing metadata/declaration terminators, and missing
  alternative arrows in case/variant/exception alternatives.
* Added `Check_Syntax_Recovery_Diagnostics` to project selected syntax-tree
  recovery markers into bounded language-model diagnostics.
* Kept diagnostics conservative: they are emitted only from explicit parser
  recovery nodes such as expected semicolons, expected delimiters, and expected
  `=>` markers.
* Added AUnit regression:
  * `Test_Language_Model_Conservative_Syntax_Recovery_Diagnostics`
* Updated validation guards and documentation.

This improves safe legality-adjacent editor diagnostics for clearly malformed
local syntax. It is not compiler-grade legality checking, semantic validation,
exhaustiveness checking, overload resolution, or control-flow analysis.
