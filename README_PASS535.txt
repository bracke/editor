Pass 535 - syntax-tree pragma literal retention parity

Implemented a focused hardening pass adjacent to the unified pragma/aspect/attribute representation path.

Changes:
- Added syntax-tree pragma retention code that strips comments while preserving Ada string and character literals.
- Rewired retained pragma syntax-tree labels and pragma argument children to use the literal-preserving text for pragma lines.
- Kept ordinary non-pragma syntax classification on the generic sanitized line path.
- Added regression coverage proving the syntax tree retains the quoted operator argument in `pragma Import (C, "+");` as a `Node_Pragma_Argument`.
- Preserved the existing language-model metadata regression for the same operator import target.

Rationale:
- Pass 534 fixed language-model target extraction for quoted operator pragmas, but syntax-tree retention still received sanitized pragma lines.  That could leave semantic-colouring/outline detail consumers with blanked literal pragma arguments even though the representation metadata path had retained them correctly.

Scope:
- This improves bounded structural grammar/literal retention for pragma syntax-tree nodes. It is not compiler-grade pragma legality checking.
