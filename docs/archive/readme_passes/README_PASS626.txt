Pass 626 - Static-expression operands for retained T'Val defaults

- Extended retained discrete constant evaluation for scalar T'Val defaults so the Val operand can be a bounded natural static expression, not only a single numeric literal.
- Constants such as `Val_Expr_Color : constant Color := Color'Val (1 + 0);` now enter the retained discrete static environment.
- The evaluated Val operand is still checked against the declared object subtype range before retention.
- Added regression coverage in the qualified discrete constant pass for a T'Val static-expression constant feeding later `Color'Pos` representation arithmetic.
