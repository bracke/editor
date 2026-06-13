# Editor Phase 579 Pass849

Pass849 improves structural Ada grammar coverage for iterator-filter condition
recovery across the token cursor.

Implemented productions:

- `Production_Loop_Iterator_Filter_Missing_Condition_Recovery_Boundary`
- `Production_Quantified_Iterator_Filter_Missing_Condition_Recovery_Boundary`
- `Production_Iterated_Component_Iterator_Filter_Missing_Condition_Recovery_Boundary`

The parser now records bounded recovery when a `when` iterator filter in a loop,
quantified expression, or aggregate iterated component association is followed
immediately by a structural boundary such as `loop`, `=>`, `;`, `,`, or `)`.
Well-formed filter conditions continue to retain their existing metadata, and
recovery leaves loop keywords, association arrows, following statements, and
following declarations visible to Outline, diagnostics, and semantic-colouring
consumers.

Regression coverage:

- `Test_Language_Model_Token_Cursor_Iterator_Filter_Condition_Recovery_Pass849`

This is parser/token-cursor metadata only. It is not compiler-grade iterator
filter legality checking, predicate type checking, iterator legality checking,
overload resolution, compiler invocation, LSP integration, render-side parsing,
or dirty-state mutation.
