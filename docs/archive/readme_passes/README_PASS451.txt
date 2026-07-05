Pass 451 - Complete aspect placement coverage

This pass expands Ada token-cursor aspect parsing from individual declaration branches to shared attached-aspect placement helpers.  The parser now searches for and retains aspect specifications before either a declaration semicolon or a body keyword such as `is`, so aspect specifications remain structural on generic formals, package declarations and bodies, type/subtype declarations, object and exception declarations, generic instantiations, subprogram declarations/bodies, task/protected declarations, and entry declarations.

The pass is syntactic grammar retention only.  It does not attempt compiler-grade aspect legality, staticness, inheritance, freezing, SPARK/aspect-specific semantics, or representation conflict validation.
