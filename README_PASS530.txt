Pass 530 - syntax-tree parenthesis retention parity for pragma arguments

Implemented another focused completeness pass adjacent to the unified
representation / operational pragma lowering path.

Changes:
- Hardened the syntax tree's shared `Segment_Between_First_Parens` helper.
- The syntax tree now ignores parentheses inside Ada string literals while
  finding the balancing close parenthesis of pragma/generic argument lists.
- The syntax tree now ignores parentheses inside Ada character literals such as
  `')'`, matching the already-hardened declaration-parser pragma scanners.
- This prevents syntax-tree `Node_Pragma_Argument` retention from truncating
  values such as `Char_Delay (')')` even when the language-model metadata path
  already retained them correctly.
- Added regression coverage to the representation pragma unification test so
  syntax-tree pragma argument retention and language-model pragma lowering stay
  in sync for character-literal parenthesis cases.
