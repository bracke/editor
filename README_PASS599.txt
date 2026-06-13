Pass 599 - Spaced String bound attribute designators
===================================================

Scope
-----
This pass continues the bounded Ada static-evaluation work around direct
static String expressions used inside representation expressions.  Pass 598
made the scanner understand spaced String qualifications such as
`String' (Expr)'Length`; this pass closes the adjacent separator case after
the final bound-attribute apostrophe.

Changes
-------
- The static String bound primary scanner now skips Ada separator characters
  after the final attribute apostrophe before reading `First`, `Last`, or
  `Length`.
- Forms such as `String' ("Gr" & "een")' Length` are retained as static
  representation-expression operands.
- The qualification-apostrophe disambiguation remains unchanged: spaced
  `T' (Expr)` is still recognized as a qualified prefix before looking for the
  real bound attribute.
- Existing compact forms, character-literal skipping, nested parentheses, and
  constrained-qualification length diagnostics remain unchanged.
- Added regression coverage in the static String Length representation test.

Representative covered form
---------------------------

```ada
for V'Size use String' ("Gr" & "een")' Length * 8;
```

Expected retained static value: `40`.
