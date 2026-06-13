Pass 611 - Static dimension expressions in copied String Range constraints

Implemented a bounded static-evaluation refinement for copied String range attributes. The optional dimension argument on `X'Range (...)` is now evaluated with the signed static integer evaluator before enforcing the one-dimensional String requirement, instead of accepting only a bare natural literal.

Newly covered form:

   subtype Offset_Name is String (2 .. 6);
   subtype Range_Expr_Derived_Name is String (Offset_Name'Range (1 + 0));

The derived subtype now retains First = 2, Last = 6, and Length = 5, and those bounds feed existing representation-expression static evaluation. Dimension values other than 1 remain rejected in this bounded one-dimensional String model.

Regression coverage was added to the static String qualification pass.
