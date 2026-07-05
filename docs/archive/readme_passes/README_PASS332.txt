Editor IDE-grade Ada language layer pass332

This pass extends grammar-aware EOF recovery.  Unterminated handled statement parts now close with Node_Implicit_End at end-of-file when their enclosing body/declaration remains open, after which the owning body receives the true Node_Missing_End diagnostic.  This avoids reporting a transient begin/exception statement part as a hard missing end when the real source error is an incomplete enclosing unit.

No Python, shell scripts, external parser generators, rendering-side parsing, or LSP integration were added.
