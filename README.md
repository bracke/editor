Pass876 improves structural grammar coverage for Ada enumeration representation clauses by adding dedicated recovery metadata for empty lists, trailing separators, and missing value expressions. Regression coverage is in `Test_Language_Model_Token_Cursor_Enumeration_Representation_Recovery_Pass876`. This remains parser/token-cursor metadata only; it is not compiler-grade representation legality checking, static expression validation, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

Pass868 improves structural grammar coverage for Ada case statement alternatives by adding dedicated missing-statement recovery metadata after a choice arrow. Malformed or in-progress alternatives such as `when 1 =>` followed immediately by another `when` now retain `Production_Case_Alternative_Missing_Statement_Recovery_Boundary` while preserving the following alternative, `end case`, and later statements.

Pass867 improves structural grammar coverage for Ada case statement choice lists by adding dedicated missing-choice recovery metadata after a `|` separator. Malformed or in-progress alternatives such as `when 1 | =>` now retain `Production_Case_Choice_Missing_Choice_Recovery_Boundary` while preserving the following choice arrow, case alternative metadata, end-case markers, and following statements.

### Pass866 - Case statement missing-is recovery depth

Pass866 improves structural grammar coverage for Ada case statements by adding dedicated missing-`is` recovery metadata. Malformed or in-progress forms such as `case Kind` followed directly by `when` alternatives now retain `Production_Case_Statement_Missing_Is_Recovery_Boundary` after the selector, while preserving case alternatives and following statements for outline, diagnostics, and semantic-colouring consumers.

Regression coverage is in `Test_Language_Model_Token_Cursor_Case_Statement_Is_Recovery_Pass866`. This remains structural parser/token-cursor metadata only; it is not compiler-grade case-choice coverage checking, discrete-choice legality checking, expression type checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass865 - Extended return missing-do recovery depth

Pass865 improves structural grammar coverage for Ada extended return statements by adding dedicated missing-`do` recovery metadata. Malformed or in-progress forms such as `return Result : Integer := 1;` now retain `Production_Extended_Return_Missing_Do_Recovery_Boundary` after the return-object declaration and optional initializer, while preserving the broader return recovery marker for existing consumers.

Regression coverage is in `Test_Language_Model_Token_Cursor_Extended_Return_Do_Recovery_Pass865`. This remains structural parser/token-cursor metadata only; it is not compiler-grade return-object legality checking, subtype conformance validation, expression type checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass864 - Requeue statement missing-target recovery depth

Pass864 improves structural grammar coverage for Ada `requeue` statements by adding dedicated missing-target recovery metadata. Malformed or in-progress forms such as `requeue ;` now retain `Production_Requeue_Missing_Target_Recovery_Boundary` without borrowing a following token as the target, while preserving the existing broader requeue target recovery marker for compatibility with current consumers.

Regression coverage is in `Test_Language_Model_Token_Cursor_Requeue_Target_Recovery_Pass864`. This remains structural parser/token-cursor metadata only; it is not compiler-grade requeue legality checking, entry-family validation, select/accept context validation, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass863 - Accept statement missing-entry-name recovery depth

Pass863 improves structural grammar coverage for Ada accept statements by adding dedicated missing-entry-name recovery metadata. Malformed or in-progress forms such as `accept ;` now retain accept-specific bounded recovery metadata without borrowing a following token as the entry name, while preserving well-formed accept entry-name, terminator, do-part, end-name, and following statement metadata.

Regression coverage is in `Test_Language_Model_Token_Cursor_Accept_Entry_Name_Recovery_Pass863`. This remains structural parser/token-cursor metadata only; it is not compiler-grade accept statement legality checking, entry profile conformance, tasking legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass854 - Select guard missing-condition recovery depth

Pass854 adds token-cursor metadata for Ada select guards whose condition is missing before the guard arrow. This keeps malformed/in-progress guarded alternatives structurally bounded while preserving the following arrow, enclosing `end select`, and later statements for Outline, diagnostics, and semantic colouring consumers.

### Pass853 - Accept statement missing-terminator recovery depth

Pass853 improves structural grammar coverage for Ada accept statements by adding dedicated missing-terminator recovery metadata after parsed accept do-part end markers. Malformed or in-progress forms such as `end Broken` before a following statement now retain accept-specific bounded terminator recovery metadata while preserving the accept statement, end keyword, end name, and following statement metadata.

Regression coverage is in `Test_Language_Model_Token_Cursor_Accept_Terminator_Recovery_Pass853`. This remains structural parser/token-cursor metadata only; it is not compiler-grade accept statement legality checking, entry profile conformance, tasking legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass852 - Requeue statement missing-terminator recovery depth

Pass852 improves structural grammar coverage for Ada `requeue` statements by adding
dedicated missing-terminator recovery metadata. Malformed/in-progress statements
such as `requeue Step with abort` before an enclosing `end` now retain
requeue-specific bounded terminator recovery metadata while preserving the
requeue target, `with abort` clause, enclosing accept/block end markers, and
following statements.

Regression coverage is in
`Test_Language_Model_Token_Cursor_Requeue_Terminator_Recovery_Pass852`.
This remains structural parser/token-cursor metadata only; it is not
compiler-grade requeue legality checking, entry-family validation, select/accept
context validation, overload resolution, compiler invocation, LSP integration,
render-side parsing, or dirty-state mutation.

### Pass851 - Delay statement missing-expression recovery depth

Pass851 improves structural grammar coverage for Ada delay statements by adding
dedicated missing-expression recovery metadata for both `delay until` and
relative `delay` forms. Malformed/in-progress statements such as `delay until;`
and `delay;` now retain delay-specific bounded expression recovery metadata
while leaving statement terminators and following statements visible.

Regression coverage is in
`Test_Language_Model_Token_Cursor_Delay_Expression_Recovery_Pass851`.
This remains structural parser/token-cursor metadata only; it is not
compiler-grade delay legality checking, time-expression type checking, overload
resolution, compiler invocation, LSP integration, render-side parsing, or
dirty-state mutation.

### Pass834 - Digits/delta constraint expression recovery depth

Pass834 improves structural grammar coverage for Ada `digits` and `delta`
constraints by recording operand-expression metadata and bounded
missing-expression recovery metadata. This helps the token cursor distinguish
well-formed subtype constraints such as `digits 6 range ...` and `delta 0.1
 digits 4` from malformed or in-progress constraints such as `digits ;` or
`delta ;` without consuming following declarations.

Regression coverage is in
`Test_Language_Model_Token_Cursor_Digits_Delta_Constraint_Expressions_Pass834`.
This remains structural parser metadata only; it is not compiler-grade
fixed/floating-point legality checking, static expression validation, subtype
conformance validation, overload resolution, compiler invocation, LSP
integration, render-side parsing, or dirty-state mutation.

### Pass830 - Qualified-expression operand delimiter and recovery depth

Pass830 improves structural grammar coverage for Ada qualified expressions by
recording operand opening delimiters, closing delimiters, and bounded
missing-close recovery metadata after the qualification apostrophe. This covers
ordinary qualified expressions such as `Count'(1)`, nested aggregate operands
such as `Vector'(1 => Count'(2))`, allocator qualified expressions such as
`new Count'(4)`, and malformed/in-progress operands that reach a declaration
terminator before `)`.

Regression coverage is in
`Test_Language_Model_Token_Cursor_Qualified_Expression_Delimiters_Pass830`.
This is structural parser metadata only; it is not compiler-grade type
conversion disambiguation, qualified-expression legality checking, overload
resolution, compiler invocation, LSP integration, render-side parsing, or
dirty-state mutation.

### Pass829 - Aggregate delimiter and recovery depth

Pass829 improves structural grammar coverage for Ada aggregates by recording
aggregate/association-list opening delimiters, closing delimiters, comma
separators between top-level aggregate components, and bounded missing-close
recovery metadata. The new productions are:

- `Production_Aggregate_Open_Delimiter`
- `Production_Aggregate_Close_Delimiter`
- `Production_Aggregate_Component_Separator`
- `Production_Aggregate_Missing_Close_Recovery_Boundary`

Regression coverage is in
`Test_Language_Model_Token_Cursor_Aggregate_Delimiters_Pass829`. This is
structural parser metadata only; it is not compiler-grade aggregate legality
checking, component-choice validation, overload resolution, compiler invocation,
LSP integration, render-side parsing, or dirty-state mutation.

Pass827 - Discriminant part delimiter and recovery depth

Pass827 deepens Ada discriminant-part grammar metadata. Shared discriminant-part parsing now records opening and closing delimiters, semicolon separators between discriminant specifications, and a bounded missing-close recovery boundary for malformed or in-progress discriminant parts.

Highlights:
- Added token-cursor productions for discriminant-part open/close delimiters, discriminant-specification separators, and missing-close recovery.
- Preserved unknown discriminant part handling for `(<>)` while adding delimiter metadata around it.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Discriminant_Part_Delimiters_Pass827`.
- Updated validation guards, parser coverage documentation, syntax-colouring notes, and the release checklist.

This improves structural grammar coverage for Ada discriminant parts. It is not compiler-grade discriminant legality checking, discriminant-conformance validation, subtype legality checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass828 - Index/discriminant constraint delimiter and recovery depth

Pass828 improves structural grammar coverage for Ada subtype constraints by
recording delimiter, separator, and bounded missing-close recovery metadata for
index constraints and discriminant constraints. It adds productions for
index-constraint open/close delimiters, index item separators, index missing-close
recovery, discriminant-constraint open/close delimiters, discriminant association
separators, and discriminant missing-close recovery. Regression coverage is in
`Test_Language_Model_Token_Cursor_Constraint_Delimiters_Pass828`.

This is structural grammar metadata only; it is not compiler-grade subtype
constraint legality checking, discriminant/index disambiguation, static range
validation, subtype conformance validation, overload resolution, compiler
invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass831 - Parenthesized-expression delimiter and recovery depth

Pass831 improves parenthesized-expression grammar coverage in the token cursor.
Parenthesized expression primaries now expose parenthesized-expression-specific
open delimiter, close delimiter, and bounded missing-close recovery productions.
This complements the existing aggregate/association-list metadata used for the
shared `(` primary path while giving outline, diagnostics, and semantic-colouring
consumers a more precise structural hook for ordinary parenthesized expressions.

Regression coverage is in
`Test_Language_Model_Token_Cursor_Parenthesized_Expression_Delimiters_Pass831`.
This is structural parser metadata only; it is not compiler-grade expression
legality checking, aggregate-vs-parenthesized semantic disambiguation, overload
resolution, compiler invocation, LSP integration, render-side parsing, or
dirty-state mutation.

### Pass832 - Discrete choice-list separator and recovery depth

Pass832 improves discrete choice-list grammar coverage in the token cursor.
Choice lists now expose structural metadata for `|` separators and bounded
missing-choice recovery, so malformed/in-progress alternatives such as
`when A | =>` can be represented without consuming the following arrow or later
statements.

Regression coverage is in
`Test_Language_Model_Token_Cursor_Discrete_Choice_List_Separators_Pass832`.
This is structural parser metadata only; it is not compiler-grade
discrete-choice legality checking, duplicate-choice validation, static range
evaluation, variant legality checking, compiler invocation, LSP integration,
render-side parsing, or dirty-state mutation.

### Pass833 - Enumeration type delimiter and recovery depth

Pass833 improves enumeration type grammar coverage in the token cursor.
Enumeration type definitions now expose opening delimiter, closing delimiter,
comma separator, and bounded missing-close recovery metadata. This gives
outline, diagnostics, and semantic-colouring consumers more precise structural
hooks for literal lists without treating malformed/in-progress declarations as
compiler-grade legality errors.

Regression coverage is in
`Test_Language_Model_Token_Cursor_Enumeration_Type_Delimiters_Pass833`.
This is structural parser metadata only; it is not compiler-grade enumeration
legality checking, duplicate literal validation, character literal legality
checking, visibility analysis, overload resolution, compiler invocation, LSP
integration, render-side parsing, or dirty-state mutation.

### Pass835 - Range constraint bound and separator recovery depth

Pass835 improves range-constraint grammar coverage in the token cursor. Range
constraints now expose explicit metadata for the `..` separator and
range-specific missing lower/upper bound recovery boundaries. This gives
outline, diagnostics, and semantic-colouring consumers precise structural hooks
for `range` constraints without promoting malformed in-progress code to
compiler-grade legality diagnostics.

Regression coverage is in
`Test_Language_Model_Token_Cursor_Range_Constraint_Bounds_Pass835`.
This is structural parser metadata only; it is not compiler-grade static range
validation, subtype legality checking, overload resolution, compiler invocation,
LSP integration, render-side parsing, or dirty-state mutation.

### Pass836 - Attribute argument delimiter and recovery depth

Pass836 improves attribute argument-list grammar coverage in the token cursor.
Attribute argument parts now expose opening delimiter, closing delimiter, comma
separator, and bounded missing-close recovery metadata. Ordinary attribute
arguments such as `Vector'First (1)` and Ada 2022 reduction arguments such as
`Values'Reduce ("+", 0)` retain this structural delimiter metadata while
preserving existing argument-expression, reducer, and initial-value productions.

Regression coverage is in
`Test_Language_Model_Token_Cursor_Attribute_Argument_Delimiters_Pass836`.
This is structural parser metadata only; it is not compiler-grade attribute
legality checking, reduction profile conformance, overload resolution, compiler
invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass837 - Membership choice-list separator and recovery depth

Pass837 improves membership choice-list grammar coverage in the token cursor.
Membership tests now expose explicit `|` separator metadata and bounded
missing-choice recovery metadata. This covers `A in B | C`, `A not in B | C`,
and malformed/in-progress forms such as `A in B | ;` without consuming the
following declaration terminator.

Regression coverage is in
`Test_Language_Model_Token_Cursor_Membership_Choice_List_Separators_Pass837`.
This is structural parser metadata only; it is not compiler-grade membership
legality checking, duplicate-choice validation, static range evaluation,
overload resolution, compiler invocation, LSP integration, render-side parsing,
or dirty-state mutation.


### Pass838 - Case-expression alternative separator and recovery depth

Pass838 improves case-expression grammar coverage in the token cursor. Case
expression alternatives now expose explicit comma separator metadata, and
malformed/in-progress forms such as `(case A is when A => 1, )` retain bounded
missing-alternative recovery metadata without consuming following declarations.

Regression coverage is in
`Test_Language_Model_Token_Cursor_Case_Expression_Alternative_Separators_Pass838`.
This is structural parser metadata only; it is not compiler-grade case-expression
legality checking, discrete-choice validation, static expression evaluation,
overload resolution, compiler invocation, LSP integration, render-side parsing,
or dirty-state mutation.

### Pass839 - Declare-expression begin keyword and recovery depth

Pass839 improves Ada 2022 declare-expression grammar coverage in the token
cursor. Declare expressions now expose explicit `begin` keyword metadata and
bounded missing-begin recovery metadata, allowing malformed/in-progress forms to
recover without consuming following declarations.

Regression coverage is in
`Test_Language_Model_Token_Cursor_Declare_Expression_Begin_Recovery_Pass839`.
This is structural parser metadata only; it is not compiler-grade
declare-expression legality checking, declarative-item legality checking,
expression type resolution, overload resolution, compiler invocation, LSP
integration, render-side parsing, or dirty-state mutation.

### Pass840 - Quantified-expression missing-quantifier recovery depth

Pass840 improves Ada quantified-expression grammar coverage in the token cursor.
Malformed or in-progress forms such as `(for I in 1 .. 10 => I > 0)` now retain
bounded missing-quantifier recovery metadata instead of silently treating the
parameter as if the required `all`/`some` quantifier were optional. Well-formed
forms such as `(for all I in 1 .. 10 => I > 0)` continue to expose normal
quantifier, domain, arrow, and predicate metadata.

Regression coverage is in
`Test_Language_Model_Token_Cursor_Quantified_Missing_Quantifier_Pass840`.
This is structural parser metadata only; it is not compiler-grade
quantified-expression legality checking, loop-scheme legality checking,
predicate type checking, overload resolution, compiler invocation, LSP
integration, render-side parsing, or dirty-state mutation.


### Pass841 - If-expression missing-then recovery depth

Pass841 improves Ada if-expression grammar coverage in the token cursor.
Malformed or in-progress forms such as `(if Ready else False)` and
`(if Ready then True elsif Enabled else False)` now retain bounded
missing-`then` recovery metadata while preserving surrounding else-branch
structure.

Regression coverage is in
`Test_Language_Model_Token_Cursor_If_Expression_Then_Recovery_Pass841`.
This is structural parser metadata only; it is not compiler-grade conditional
expression legality checking, branch type checking, overload resolution,
compiler invocation, LSP integration, render-side parsing, or dirty-state
mutation.


## Pass842 — Selected-name missing-selector recovery depth

Pass842 adds `Production_Selected_Name_Missing_Selector_Recovery_Boundary` so dangling selected-name dots such as `Root.Child.` retain bounded recovery metadata while preserving existing selected-name prefix, separator, selector, literal-selector, operator-selector, and character-selector metadata. This improves structural grammar coverage for Ada selected-name recovery; it is not compiler-grade name resolution or selector legality checking.

### Phase 579 Pass843 — Delta aggregate keyword and recovery depth

Pass843 improves structural grammar coverage for Ada 2022 delta aggregates by tagging the top-level `with` keyword, the `delta` keyword, association separators, and bounded missing-association recovery for incomplete `with delta` aggregates. This remains parser/token-cursor metadata only, not compiler-grade aggregate legality checking.

### Phase 579 Pass844 — Extension aggregate keyword and recovery depth

Pass844 improves structural grammar coverage for Ada extension aggregates by tagging the top-level `with` keyword, extension-component separators, and bounded missing-association recovery for incomplete non-`delta` extension aggregates. `with null record` remains on its dedicated null-record extension path. This remains parser/token-cursor metadata only, not compiler-grade aggregate legality checking.

### Phase 579 Pass845 — Null-record aggregate keyword and recovery depth

Pass845 improves structural grammar coverage for Ada extension aggregates using `with null record` by tagging the `null` and `record` keywords separately and by recording bounded missing-`record` recovery for malformed/in-progress `with null` forms. This remains parser/token-cursor metadata only, not compiler-grade aggregate legality checking.

### Phase 579 Pass847 — Iterated component domain recovery depth

Pass847 improves structural grammar coverage for Ada aggregate iterated component associations by adding `Production_Iterated_Component_Missing_Domain_Recovery_Boundary`. Malformed/in-progress forms such as `(for I in => I)` and `(for I in when I > 0 => I)` now retain bounded missing-domain recovery metadata while preserving the existing association, filter, arrow, and expression markers. This remains parser/token-cursor metadata only, not compiler-grade iterator or aggregate legality checking.

### Phase 579 Pass846 — Iterated component association arrow recovery depth

Pass846 improves structural grammar coverage for Ada aggregate iterated component associations by tagging the association arrow and by recording bounded missing-arrow recovery for malformed/in-progress forms such as `(for I in 1 .. 3)`. Iterator domains and optional `when` filters remain structurally visible. This remains parser/token-cursor metadata only, not compiler-grade aggregate legality checking.

### Phase 579 Pass848 — Loop iteration domain recovery depth

Pass848 improves structural grammar coverage for Ada loop iteration schemes by adding `Production_For_Loop_Missing_Domain_Recovery_Boundary` and `Production_Iterator_Loop_Missing_Domain_Recovery_Boundary`. Malformed/in-progress forms such as `for I in when I > 0 loop` and `for E of when Ready loop` now retain bounded missing-domain recovery metadata while preserving existing loop filter, loop-begin, statement-sequence, and following-statement markers. This remains parser/token-cursor metadata only, not compiler-grade loop or iterator legality checking.

### Phase 579 Pass849 — Iterator-filter condition recovery depth

Pass849 improves structural grammar coverage for Ada iterator filters by adding bounded missing-condition recovery metadata for loop iterator filters, quantified-expression filters, and aggregate iterated component filters. Malformed/in-progress forms such as `for I in 1 .. 3 when loop`, `(for all I in 1 .. 3 when => I > 0)`, and `(for I in 1 .. 3 when => I)` now retain filter-specific recovery metadata while preserving loop keywords, arrows, following statements, and following declarations. This remains parser/token-cursor metadata only, not compiler-grade iterator filter legality checking.

### Phase 579 Pass850 — Exit-when condition recovery depth

Pass850 improves structural grammar coverage for Ada `exit when` statements by adding `Production_Exit_When_Missing_Condition_Recovery_Boundary`. Malformed/in-progress forms such as `exit when;` now retain bounded missing-condition recovery metadata while preserving the statement terminator and following statements. This remains parser/token-cursor metadata only, not compiler-grade loop legality checking or condition type checking.

### Phase 579 Pass855 — Abort target recovery depth

Pass855 improves structural grammar coverage for Ada `abort` statements by adding `Production_Abort_Missing_Target_Recovery_Boundary`. Malformed/in-progress forms such as `abort;` and `abort Worker, ;` now retain target-specific bounded recovery metadata while preserving abort target-list, separator, broader recovery, terminator, and following-statement metadata. This remains parser/token-cursor metadata only, not compiler-grade tasking legality checking.

### Phase 579 Pass856 — Return statement missing-terminator recovery depth

Pass856 improves structural grammar coverage for Ada `return` statements by adding `Production_Return_Missing_Terminator_Recovery_Boundary`. Malformed/in-progress forms such as `return 1` before a following `else`/`end` now retain return-specific bounded recovery metadata while preserving return statement, return expression, well-formed return terminator, and following statement metadata. This remains parser/token-cursor metadata only, not compiler-grade return legality checking or return type conformance.

### Phase 579 pass857 — raise-expression message recovery depth

Pass857 adds expression-specific token-cursor metadata for malformed Ada raise
expressions where the `with` message keyword is present but the message
expression is missing.  The parser now records
`Production_Raise_Expression_Message_Recovery_Boundary` while preserving the
existing generic raise-message and raise-expression recovery markers.  The pass
adds `Test_Language_Model_Token_Cursor_Raise_Expression_Message_Recovery_Pass857`
and keeps the work structural only: no legality checking, exception visibility
analysis, overload resolution, compiler invocation, LSP integration,
render-side parsing, or dirty-state mutation.

### Phase 579 pass858 — raise-statement message recovery depth

Pass858 adds statement-specific token-cursor metadata for malformed Ada raise
statements where the `with` message keyword is present but the message
expression is missing. The parser now records
`Production_Raise_Statement_Message_Recovery_Boundary` while preserving the
existing shared raise-message and raise-statement recovery markers. The pass
adds `Test_Language_Model_Token_Cursor_Raise_Statement_Message_Recovery_Pass858`
and keeps the work structural only: no legality checking, exception visibility
analysis, overload resolution, compiler invocation, LSP integration,
render-side parsing, or dirty-state mutation.

### Phase 579 pass859 — label missing-close recovery depth

Pass859 adds label-specific token-cursor metadata for malformed Ada labels where
`<<` is present but the closing `>>` delimiter is missing before the line
boundary. The parser now records
`Production_Label_Missing_Close_Recovery_Boundary` and keeps the recovery
bounded so following statements remain visible to outline, diagnostics, and
semantic-colouring consumers. The pass adds
`Test_Language_Model_Token_Cursor_Label_Missing_Close_Recovery_Pass859` and
keeps the work structural only: no label legality checking, goto-target
resolution, duplicate-label validation, compiler invocation, LSP integration,
render-side parsing, or dirty-state mutation.

### Phase 579 pass860 — assignment expression recovery depth

Pass860 adds assignment-statement-specific token-cursor metadata for malformed
Ada assignments where `:=` is present but the right-hand expression is missing.
The parser now records
`Production_Assignment_Missing_Expression_Recovery_Boundary` for forms such as
`X :=;` while preserving ordinary `Production_Assignment_Expression` metadata
on later well-formed assignments. Recovery remains bounded and keeps following
statements visible to outline, diagnostics, and semantic-colouring consumers.
This is parser/token-cursor metadata only: no assignment legality checking,
left-hand-side legality checking, expression type checking, overload
resolution, compiler invocation, LSP integration, render-side parsing, or
dirty-state mutation.

### Phase 579 pass861 — goto target recovery depth

Pass861 adds goto-statement-specific token-cursor metadata for malformed Ada
`goto` statements where the required label name is missing. The parser now
records `Production_Goto_Missing_Target_Recovery_Boundary` for forms such as
`goto;` while preserving generic goto recovery metadata, semicolon terminator
metadata, and following label/statement visibility. This is parser/token-cursor
metadata only: no goto legality checking, label resolution, duplicate-label
validation, compiler invocation, LSP integration, render-side parsing, or
dirty-state mutation.

### Pass862 — Raise-statement missing exception-name recovery depth

Pass862 adds `Production_Raise_Statement_Missing_Exception_Name_Recovery_Boundary`.
Malformed/in-progress raise statements such as `raise with "message";` now retain a
raise-statement-specific missing exception-name recovery marker while preserving the
`with` message keyword, message expression, terminator, and following statements. This
improves structural parser recovery only; it is not compiler-grade raise-statement
legality checking.

### Phase 579 Pass 869 — If statement branch recovery

Pass 869 adds token-cursor metadata for empty `then`, `elsif`, and `else` statement sequences. The parser records branch-specific missing-statement recovery boundaries while preserving `elsif`, `else`, `end if`, and following statements for outline, diagnostics, and semantic-colouring consumers. This remains structural grammar coverage, not compiler-grade statement legality checking.

### Phase 579 Pass870

Pass870 improves structural Ada parser/token-cursor coverage for empty loop
body recovery by adding loop-specific missing-statement metadata for loop,
while-loop, discrete for-loop, and iterator-loop bodies that reach `end loop`
without an intervening statement. This remains parser metadata only and is not
compiler-grade legality checking.

### Phase 579 Pass871

Pass871 improves structural Ada parser/token-cursor coverage for empty block
statement sequences by adding block-specific missing-statement metadata when a
`begin` part immediately reaches `end` or `exception`. This keeps block end
markers, exception parts, and following statements visible to language-model,
outline, diagnostics, and semantic-colouring consumers. This is parser metadata
only and is not compiler-grade statement legality checking.

### Phase 579 Pass872

Pass872 improves structural Ada parser/token-cursor coverage for terminal empty case alternatives. When a case alternative reaches `end case` immediately after `=>`, the parser now records `Production_Case_Alternative_End_Case_Statement_Recovery_Boundary` in addition to the broader missing-statement recovery marker. This keeps the enclosing `end case` terminator and following statements visible to language-model, outline, diagnostics, and semantic-colouring consumers. This is parser metadata only and is not compiler-grade case legality or coverage checking.

### Phase 579 Pass873

Pass873 improves structural Ada parser/token-cursor coverage for formal package declarations with malformed empty actual lists. When `with package P is new G ();` is encountered, the parser now records `Production_Formal_Package_Actual_Empty_Recovery_Boundary`, keeps the formal-package actual part and close delimiter visible, and resumes at following generic formal declarations. This distinguishes malformed empty lists from omitted/defaulted actual parts and valid `(<>)` box defaults. This is parser metadata only and is not compiler-grade generic contract legality, actual/default legality, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.


### Phase 579 pass875

Pass875 improves structural Ada parser/token-cursor recovery for malformed `use`, `use type`, and `use all type` clauses. The parser now records use-clause-specific missing-name, trailing-comma, and missing-terminator recovery boundaries while preserving the existing generic recovery-point metadata for older consumers. This keeps following declarations visible to Outline, diagnostics, resolver, and semantic-colouring consumers without render-side parsing or compiler legality checks.

### Phase 579 pass874

Pass874 improves structural Ada parser/token-cursor coverage for empty or malformed exception-handler statement sequences. When an exception handler reaches another `when` handler or the enclosing `end` immediately after `=>`, the parser now records handler-specific missing-statement recovery metadata, including a terminal-end marker for `when X => end ...`. This keeps following handlers, enclosing body terminators, outline data, diagnostics, and semantic-colouring consumers bounded to the snapshot-owned language model. This is parser metadata only and is not compiler-grade exception-handler legality checking.

### Editor Phase 579 Pass877

Pass1109: added Editor.Ada_Overload_Resolution_Legality, a widened overload/operator resolution legality layer for expected-type, universal numeric, primitive operator, implicit conversion, view, visibility, cross-unit, and linked semantic-error classifications.

Pass877 improves structural Ada grammar coverage for subprogram contract/aspect
placement.  The token cursor now distinguishes aspect specifications on
subprogram declarations from aspect specifications on subprogram bodies before
`is`, and marks contract-bearing subprogram aspect placements for downstream
Outline/semantic-colouring consumers.

This is not compiler-grade contract legality checking, Global/Depends
validation, profile conformance, overload resolution, compiler invocation, LSP
integration, render-side parsing, or dirty-state mutation.

### Editor Phase 579 Pass878

Pass878 improves structural Ada grammar coverage for package/spec/body
declarative-item recovery.  Malformed nested declarative items now record a
package-specific nested recovery boundary and preserve whether recovery reached
`private`, `begin`, or `end`, while retaining the existing visible/private/body
item metadata and generic recovery productions.

This remains parser-owned structural metadata only.  It is not package legality
checking, nested declaration legality checking, visibility checking, compiler
invocation, LSP integration, render-side parsing, background project scanning, or
dirty-state mutation.

### Editor Phase 579 Pass879

Pass879 improves structural Ada grammar coverage for anonymous
access-to-subprogram recovery.  Malformed `access protected`, access-to-function
profiles without `return`, and access-to-function `return` clauses without a
result subtype now expose specific recovery productions while preserving existing
anonymous access profile metadata and following declaration visibility.

This remains parser-owned structural metadata only.  It is not callable-profile
legality checking, result subtype legality checking, overload resolution,
compiler invocation, LSP integration, render-side parsing, background project
scanning, or dirty-state mutation.

### Editor Phase 579 Pass880

Pass880 improves structural Ada grammar coverage for conditional-expression
operand recovery.  The token cursor now distinguishes missing conditions,
missing then-dependent expressions, and missing else-dependent expressions in
Ada conditional expressions while preserving the enclosing conditional-expression
metadata and following declaration visibility.

This remains parser-owned structural metadata only.  It is not expression type
checking, Boolean legality checking, overload resolution, compiler invocation,
LSP integration, render-side parsing, background project scanning, or dirty-state
mutation.

### Editor Phase 579 Pass881

Pass881 improves structural Ada name-grammar coverage for selected names with
operator-symbol and character-literal selectors. Literal selectors now also
surface through the generic selected-selector production, and selected literal
subtype-mark metadata is retained for qualified-expression and allocator
contexts. This helps Outline and semantic-colouring consumers preserve selected
literal names without flattening them into ordinary expression literals.

This remains parser-owned structural metadata only. It is not subtype legality
checking, operator legality checking, overload resolution, compiler invocation,
LSP integration, render-side parsing, background project scanning, or dirty-state
mutation.

### Editor Phase 579 Pass882

Pass882 improves structural Ada grammar coverage for select-statement
alternative statement-sequence recovery. Empty or malformed select alternatives,
conditional-select `else` parts, and asynchronous-select `then abort` parts now
emit select-specific missing-statement recovery metadata while preserving
existing select alternative, `or`, `else`, `then abort`, `terminate`, `end select`,
and following-declaration visibility.

This improves parser/token-cursor structure only. It is not compiler-grade
tasking legality checking, selective-accept legality checking, overload
resolution, compiler invocation, LSP integration, render-side parsing, background
whole-project scanning, or dirty-state mutation.

### Editor Phase 579 Pass883

Pass883 improves structural Ada grammar coverage for accept-statement do-part
statement-sequence recovery. Empty or malformed `accept ... do` bodies now emit
accept-specific missing-statement recovery metadata, including a distinct
end-boundary marker when the empty body is immediately followed by `end Name;`.
The existing accept statement-sequence, accept end, accept terminator, select
alternative, and following-declaration metadata remain visible.

This improves parser/token-cursor structure only. It is not compiler-grade
tasking legality checking, accept-body legality checking, entry-family
validation, overload resolution, compiler invocation, LSP integration,
render-side parsing, background whole-project scanning, or dirty-state mutation.

### Editor Phase 579 Pass884

Pass884 improves structural Ada grammar coverage for generic formal incomplete
type declarations.  The token cursor now distinguishes `type T;`,
`type T (<>);`, and `type T is tagged;` from malformed formal type definitions,
and records a formal-type-specific recovery boundary for `type T is;`.

This remains editor-owned structural parsing.  It is not compiler-grade generic
contract legality checking, incomplete-type completion checking, visibility
checking, overload resolution, compiler invocation, LSP integration,
render-side parsing, or dirty-state mutation.

### Editor Phase 579 pass885

Pass885 improves structural Ada pragma grammar recovery.  The token cursor now
records pragma-specific recovery boundaries for missing pragma identifiers,
empty argument lists, trailing argument separators, missing argument
expressions, and missing pragma terminators while preserving generic recovery
metadata and following declaration visibility.  This is parser-owned structural
coverage only; it is not compiler-grade pragma legality checking.


### Editor Phase 579 pass886

Pass886 improves structural Ada parser coverage for malformed address and
attribute-definition representation clauses.  The token cursor now emits
specific recovery metadata when an attribute-definition clause is missing
`use`, when an attribute-definition clause is missing the value expression after
`use`, and when an address clause is missing its address expression after either
`for X'Address use` or `for X use at`.

This remains parser-owned structural metadata only. It is not compiler-grade
representation legality checking, address expression legality checking, static
expression validation, overload resolution, compiler invocation, LSP
integration, render-side parsing, background whole-project scanning, or
dirty-state mutation.

Pass887 improves structural Ada parser coverage for broader aspect placement.
The token cursor now records package declaration/body, task declaration/body,
protected declaration/body, private type, and generic declaration aspect
placement metadata while preserving ordinary aspect association payload
metadata. This is structural grammar coverage only; it is not compiler-grade
aspect legality checking, representation aspect validation, LSP integration,
render-side parsing, background whole-project scanning, or dirty-state
mutation.

### Pass888 — case-expression dependent-expression recovery

Pass888 adds case-expression-specific recovery metadata for alternatives that
contain `=>` but omit the dependent expression before a comma, close delimiter,
semicolon, or reserved recovery boundary. This keeps malformed expression code
visible to semantic-colouring and resolver consumers without treating separator
or boundary tokens as ordinary expression primaries.

This improves structural grammar coverage only. It is not expression type
checking, discrete-choice legality checking, case coverage checking, overload
resolution, compiler invocation, LSP integration, render-side parsing,
background whole-project scanning, or dirty-state mutation.

### Pass889 — name/attribute prefix and incomplete selected-name refinement

Pass889 improves structural Ada name grammar coverage for attribute references
whose prefixes are selected names, and for incomplete selected subtype marks in
qualified-expression and allocator contexts. The token cursor now records
selected/complex attribute-prefix metadata and context-specific dangling
selected subtype-mark recovery for forms such as `Broken.'(1)` and
`new Broken.;` while preserving generic selected-name missing-selector recovery
and following declaration visibility.

This improves structural grammar coverage only. It is not attribute legality
checking, subtype legality checking, overload resolution, compiler invocation,
LSP integration, render-side parsing, background whole-project scanning, or
dirty-state mutation.

### Pass890 — task/protected body declarative-item recovery

Pass890 improves structural Ada grammar coverage for malformed declarative items
inside task bodies and protected operation bodies. It adds task/protected-specific
recovery productions for declarative items that synchronize at `begin` or `end`,
while preserving body begin/end metadata and enclosing package completion.

This improves editor-owned grammar recovery only. It is not compiler-grade
tasking legality checking, protected operation legality checking, declaration
legality checking, overload resolution, compiler invocation, LSP integration,
render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass891 — semantic-colouring recovery follow-through

Pass891 improves semantic-colouring precision after the recent parser recovery
passes. The bounded semantic map now suppresses unresolved metadata-only names
that are clearly recovered partial selected-name fragments, including dangling
selected subtype marks in qualified-expression and allocator contexts. This
keeps recovered fragments from being coloured as complete declarations while
preserving normal colouring for bindings that have concrete target symbols.

This improves false-positive suppression for editor-owned semantic colouring. It
is not compiler-grade name binding, overload resolution, compiler invocation,
LSP integration, render-side parsing, background whole-project scanning, or
dirty-state mutation.

### Pass892 — reduction attribute argument recovery

Pass892 improves structural Ada expression grammar coverage for malformed Ada
2022 reduction attribute argument parts. The token cursor now records specific
recovery metadata for missing reducers, missing initial values, and trailing
argument separators in `Reduce`, `Parallel_Reduce`, and `Map_Reduce` forms while
preserving the existing reduction-expression, attribute-argument delimiter,
missing-close, generic recovery, and following-declaration metadata.

This improves editor-owned structural grammar recovery only. It is not callable
profile checking, parallel-reduction legality checking, expression type checking,
overload resolution, compiler invocation, LSP integration, render-side parsing,
background whole-project scanning, or dirty-state mutation.

### Pass893 — quantified-expression missing-predicate recovery

Pass893 improves structural Ada expression grammar coverage for malformed
quantified expressions whose `=>` arrow is present but whose predicate expression
is missing. The token cursor now emits
`Production_Quantified_Missing_Predicate_Recovery_Boundary` while preserving
quantified-expression, arrow, generic recovery, and following-declaration
metadata.

This improves editor-owned structural grammar recovery only. It is not Boolean
predicate legality checking, iterator legality checking, overload resolution,
compiler invocation, LSP integration, render-side parsing, background
whole-project scanning, or dirty-state mutation.

### Pass894 — declare-expression missing-body recovery

Pass894 improves structural Ada expression grammar coverage for malformed Ada
2022 declare expressions whose `begin` keyword is present but whose body
expression is missing. The token cursor now emits
`Production_Declare_Expression_Missing_Body_Recovery_Boundary` while preserving
declare-expression, begin-keyword, generic recovery, and following-declaration
metadata.

This improves editor-owned structural grammar recovery only. It is not
expression type checking, declarative-part legality checking, overload
resolution, compiler invocation, LSP integration, render-side parsing,
background whole-project scanning, or dirty-state mutation.

### Pass895 — iterated component association expression recovery

Pass895 improves structural Ada expression grammar coverage for malformed
aggregate iterated component associations whose `=>` arrow is present but whose
component expression is missing. The token cursor now emits
`Production_Iterated_Component_Missing_Expression_Recovery_Boundary` while
preserving iterated-component association metadata, arrow metadata, generic
recovery metadata, and following declaration visibility.

This improves editor-owned structural grammar recovery only. It is not aggregate
legality checking, iterator legality checking, expression type checking,
overload resolution, compiler invocation, LSP integration, render-side parsing,
background whole-project scanning, or dirty-state mutation.

### Pass896 — generic actual association recovery

Pass896 improves structural Ada grammar coverage for malformed generic actual
parts. Empty actual lists such as `new G ()`, missing actual values such as
`new G (T =>, Default => 1)`, and trailing separators such as `new G (Integer,)`
now retain generic-actual-specific recovery metadata while preserving generic
actual part, association, separator, close-delimiter, generic recovery, and
following declaration visibility. This remains parser/token-cursor metadata
only; it is not compiler-grade generic contract legality checking, overload
resolution, compiler invocation, LSP integration, render-side parsing,
background whole-project scanning, or dirty-state mutation.

### Pass897 — renaming target recovery

Pass897 improves structural Ada grammar coverage for malformed renaming tails.
The token cursor now emits `Production_Renaming_Missing_Target_Recovery_Boundary`
when `renames` is followed by a terminator or an attached aspect instead of a
renamed entity, while preserving renaming aspect metadata, valid following
renamed targets, generic recovery metadata, and following declarations.  This
is not compiler-grade renamed-entity legality checking, visibility checking,
overload resolution, compiler invocation, LSP integration, render-side parsing,
background whole-project scanning, or dirty-state mutation.

### Pass898 — entry-body statement-sequence recovery

Pass898 improves structural Ada grammar coverage for malformed entry bodies.
The token cursor now emits `Production_Entry_Body_Statement_Sequence` for
non-empty entry bodies and
`Production_Entry_Body_Missing_Statement_Recovery_Boundary` when an entry body
`begin` is followed immediately by `end`, `or`, `else`, `then abort`, or a
terminator.  Existing entry-body begin/end metadata and generic recovery points
remain visible to outline and semantic-colouring consumers.

This remains editor-owned structural parsing.  It is not compiler-grade tasking
legality checking, entry barrier legality checking, statement legality checking,
overload resolution, compiler invocation, LSP integration, render-side parsing,
background whole-project scanning, or dirty-state mutation.

### Editor Phase 579 — Pass899

Pass899 improves structural grammar recovery for Ada entry barriers with missing
conditions. The token cursor now emits
`Production_Entry_Barrier_Missing_Condition_Recovery_Boundary` and
`Production_Protected_Entry_Barrier_Missing_Condition_Recovery_Boundary` for
forms such as `entry E when is`, preserving entry body metadata and following
valid barriers without treating boundary tokens as ordinary condition names.
This is parser-owned recovery metadata only, not compiler-grade tasking legality
checking.

### Editor Phase 579 — Pass900

Pass900 improves structural grammar recovery for Ada entry-family declarations
with empty family definitions. The token cursor now emits
`Production_Entry_Family_Empty_Definition_Recovery_Boundary` for forms such as
`entry Empty ();`, while preserving ordinary entry declaration metadata, valid
following entry-family index subtype metadata, parameter-profile metadata, and
generic recovery points. This is parser-owned recovery metadata only, not
compiler-grade entry-family legality checking or tasking legality checking.


### Editor Phase 579 Pass901

Pass901 improves structural Ada grammar recovery for malformed abort target lists where a comma is followed by a reserved statement-sequence boundary, such as `abort Worker, else;`. The token cursor now records `Production_Abort_Target_Reserved_Boundary_Recovery_Boundary` instead of fabricating the boundary token as an abort target. This remains editor-grade structural parsing, not compiler-grade tasking legality checking.


### Editor Phase 579 Pass902

Pass902 improves structural Ada grammar recovery for malformed requeue statements where a reserved statement-sequence boundary appears where an entry-name target is required, such as `requeue else;`. The token cursor now records `Production_Requeue_Target_Reserved_Boundary_Recovery_Boundary` instead of fabricating the boundary token as a requeue target. This remains editor-grade structural parsing, not compiler-grade tasking legality checking.

### Editor Phase 579 Pass903

Pass903 improves structural Ada grammar recovery for malformed delay statements where a reserved statement-sequence boundary appears where a delay expression is required, such as `delay then;` or `delay until when;`. The token cursor now records `Production_Delay_Reserved_Boundary_Recovery_Boundary` instead of fabricating the boundary token as a delay expression. This remains editor-grade structural parsing, not compiler-grade delay-expression legality checking.

Pass904 improves structural Ada grammar recovery for malformed goto statements where a reserved statement-sequence boundary appears where a label name is required, such as `goto else;`. The token cursor now records `Production_Goto_Target_Reserved_Boundary_Recovery_Boundary` instead of fabricating the boundary token as a goto label name. This remains editor-grade structural parsing, not compiler-grade label legality checking.

Pass905 improves structural Ada grammar recovery for malformed return statements where a reserved statement-sequence boundary appears where a return expression would otherwise be parsed, such as `return else;`. The token cursor now records `Production_Return_Reserved_Boundary_Recovery_Boundary` instead of fabricating the boundary token as a return expression. This remains editor-grade structural parsing, not compiler-grade return legality checking.

Pass906 improves structural Ada grammar recovery for malformed raise statements where a reserved statement-sequence boundary appears where an exception name would otherwise be parsed, such as `raise else;`. The token cursor now records `Production_Raise_Target_Reserved_Boundary_Recovery_Boundary` instead of fabricating the boundary token as a raise exception name. This remains editor-grade structural parsing, not compiler-grade raise legality checking.

Pass907 improves structural Ada grammar recovery for malformed exit statements where a reserved statement-sequence boundary appears where a loop name would otherwise be parsed, such as `exit else;`. The token cursor now records `Production_Exit_Target_Reserved_Boundary_Recovery_Boundary` instead of fabricating the boundary token as an exit loop name. This remains editor-grade structural parsing, not compiler-grade loop-name or exit-statement legality checking.

Pass908 improves structural Ada grammar recovery for malformed assignment statements where a reserved statement-sequence boundary appears where an expression would otherwise be parsed, such as `Value := else;`. The token cursor now records `Production_Assignment_Reserved_Boundary_Recovery_Boundary` instead of fabricating the boundary token as an assignment expression. This remains editor-grade structural parsing, not compiler-grade assignment-expression legality checking.

Pass909 improves structural Ada grammar recovery for malformed call actual association lists, including empty actual lists (`Call ();`), missing named actual expressions (`Call (Item =>, Other => 1);`), and trailing separators (`Call (1,);`). The token cursor now records call-actual-specific recovery metadata instead of treating separators or close delimiters as ordinary actual expressions. This remains editor-grade structural parsing, not compiler-grade callable profile checking or overload resolution.

Pass910 improves structural Ada grammar recovery for malformed `if` and `elsif` statement conditions where `then` or another statement-sequence boundary appears immediately after the keyword. The token cursor now records if/elsif-condition-specific recovery metadata instead of treating boundary tokens as condition expressions, while preserving `then` keywords, following valid conditions, and `end if` terminator visibility. This remains editor-grade structural parsing, not compiler-grade Boolean legality checking or overload resolution.

Pass911 improves structural Ada grammar recovery for malformed `while` loop conditions where `loop` or another statement-sequence boundary appears immediately after `while`. The token cursor now records while-condition-specific recovery metadata instead of treating boundary tokens as condition expressions, while preserving `while` keyword, `loop` keyword, valid following conditions, and loop terminator visibility. This remains editor-grade structural parsing, not compiler-grade Boolean legality checking, loop legality checking, or overload resolution.

Pass912 improves structural Ada grammar recovery for malformed `for ... in` and `for ... of` loop domains where a reserved statement-sequence boundary appears where an iteration domain is required. The token cursor now records for-loop and iterator-loop domain reserved-boundary recovery metadata instead of treating boundary tokens as domain expressions, while preserving valid following loop domains and loop terminator visibility. This remains editor-grade structural parsing, not compiler-grade discrete range legality checking, iterator legality checking, expression type checking, or overload resolution.

Pass913 improves structural Ada grammar recovery for malformed case statements where a reserved statement-sequence boundary appears where a selector expression would otherwise be parsed, such as `case is`. The token cursor now records `Production_Case_Statement_Selector_Reserved_Boundary_Recovery_Boundary` instead of fabricating the boundary token as a case selector. This remains editor-grade structural parsing, not compiler-grade selector legality checking, discrete-choice legality checking, case coverage checking, or overload resolution.

### Editor Phase 579 pass914

Pass914 improves structural grammar recovery for malformed Ada extended return
object initializers when `:=` is followed by a reserved boundary such as `do`,
`end`, `else`, `elsif`, `exception`, `then`, `when`, or `;`.  The parser records
extended-return-initializer-specific recovery while preserving the surrounding
extended return structure for outline and semantic-colouring consumers.

### Editor Phase 579 pass915

Pass915 improves structural Ada grammar recovery for malformed raise-with-message statements where a reserved statement-sequence boundary appears where a message expression would otherwise be parsed, such as `raise Program_Error with else;`. The token cursor now records `Production_Raise_Message_Reserved_Boundary_Recovery_Boundary` instead of fabricating the boundary token as a message expression. This remains editor-grade structural parsing, not compiler-grade raise-message legality checking or overload resolution.

### Editor Phase 579 pass916

Pass916 improves structural Ada grammar recovery for malformed `exit when` statements where a reserved statement-sequence boundary appears where a condition expression would otherwise be parsed, such as `exit when else;`. The token cursor now records `Production_Exit_When_Reserved_Boundary_Recovery_Boundary` instead of fabricating the boundary token as a condition expression. This remains editor-grade structural parsing, not compiler-grade Boolean condition legality checking, exit-statement legality checking, or overload resolution.

Pass917 improves structural Ada grammar recovery for malformed `null` statements where a reserved statement-sequence boundary appears where a semicolon is expected, such as `null else`. The token cursor now records `Production_Null_Reserved_Boundary_Recovery_Boundary` alongside the existing missing-terminator recovery metadata. This remains editor-grade structural parsing, not compiler-grade statement legality checking or control-flow validation.

### Editor Phase 579 pass918

Pass918 improves structural Ada grammar recovery for malformed aggregate named component associations where a reserved statement-sequence or expression boundary appears where the component expression would otherwise be parsed, such as `(1 => else, 2 => 10)`. The token cursor now records `Production_Aggregate_Component_Expression_Reserved_Boundary_Recovery_Boundary` instead of fabricating the boundary token as an aggregate component expression. This remains editor-grade structural parsing, not compiler-grade aggregate legality checking, component type checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Editor Phase 579 pass919

Pass919 improves structural Ada grammar recovery for malformed object declarations where a reserved or aspect/declaration boundary appears where an initialization expression would otherwise be parsed, such as `Broken : Integer := with Volatile;`. The token cursor now records `Production_Object_Initialization_Reserved_Boundary_Recovery_Boundary` instead of fabricating the boundary token as an initializer expression. This remains editor-grade structural parsing, not compiler-grade object declaration legality checking, initializer type checking, aspect legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass920 — Range constraint reserved-boundary recovery

Pass920 improves structural Ada grammar recovery for malformed range constraints where reserved statement/declaration boundary keywords appear where lower or upper bound expressions would otherwise be parsed, such as `subtype Missing_Lower is Integer range else;` and `subtype Missing_Upper is Integer range 1 .. else;`. The token cursor now records `Production_Range_Constraint_Reserved_Boundary_Recovery_Boundary` while preserving existing missing-bound, constraint-recovery, and valid following range metadata. This remains editor-grade structural parsing, not compiler-grade range-expression legality checking, subtype legality checking, static expression validation, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass921 — Digits/delta constraint reserved-boundary recovery

Pass921 improves structural Ada grammar recovery for malformed digits and delta constraints where reserved statement/declaration boundary keywords appear where constraint expressions would otherwise be parsed, such as `subtype Missing_Digits is Float digits else;` and `subtype Missing_Delta is Fixed delta else;`. The token cursor now records `Production_Digits_Constraint_Reserved_Boundary_Recovery_Boundary` and `Production_Delta_Constraint_Reserved_Boundary_Recovery_Boundary` while preserving existing missing-expression and valid following constraint-expression metadata. This remains editor-grade structural parsing, not compiler-grade floating/fixed-point subtype legality checking, static expression validation, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass922 — Index/discriminant constraint reserved-boundary recovery

Pass922 improves structural Ada grammar recovery for malformed index and discriminant constraints where reserved statement/declaration boundary keywords appear where an index item, upper bound, or discriminant actual expression would otherwise be parsed. The token cursor now records `Production_Index_Constraint_Reserved_Boundary_Recovery_Boundary` and `Production_Discriminant_Constraint_Reserved_Boundary_Recovery_Boundary`, while preserving valid following bounds, discriminant expressions, and broader constraint recovery metadata. This remains editor-grade structural parsing, not compiler-grade constraint legality checking, subtype compatibility checking, static expression validation, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass923 — Profile default reserved-boundary recovery

Pass923 improves structural Ada grammar recovery for malformed parameter/profile defaults where `:=` is followed by a delimiter, separator, aspect/declaration boundary, or reserved statement boundary. The token cursor now records `Production_Profile_Default_Reserved_Boundary_Recovery_Boundary` while preserving profile, default-expression, declaration terminator, and generic recovery metadata. This remains editor-grade structural parsing, not compiler-grade default-expression legality checking, profile conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass924 — Object subtype reserved-boundary recovery

Pass924 improves structural Ada grammar recovery for malformed object declarations where a subtype/access definition is missing after the colon and the next token is a reserved/aspect boundary. The token cursor now records `Production_Object_Subtype_Reserved_Boundary_Recovery_Boundary` while preserving object declaration, broader declaration recovery, generic recovery, and valid following initializer metadata. This remains editor-grade structural parsing, not compiler-grade object declaration legality checking, subtype legality checking, aspect legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass925 — Number initialization reserved-boundary recovery

Pass925 improves structural Ada grammar recovery for malformed named-number declarations where `:=` is followed by a reserved/aspect boundary. The token cursor now records `Production_Number_Initialization_Reserved_Boundary_Recovery_Boundary` while preserving number declaration, broader declaration recovery, generic recovery, and valid following initializer metadata. This remains editor-grade structural parsing, not compiler-grade named-number legality checking, static-expression validation, universal type resolution, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass926 — Component default reserved-boundary recovery

Pass926 improves structural Ada grammar recovery for malformed record component declarations where `:=` is followed by a reserved/aspect boundary. The token cursor now records `Production_Component_Default_Reserved_Boundary_Recovery_Boundary` while preserving component declaration metadata, generic recovery metadata, and valid following component default-expression metadata. This remains editor-grade structural parsing, not compiler-grade component declaration legality checking, default-expression type checking, aspect legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

Pass927 improves structural Ada grammar recovery for malformed discriminant specifications where `:=` is followed by a reserved/aspect boundary. The token cursor now records `Production_Discriminant_Default_Reserved_Boundary_Recovery_Boundary` while preserving discriminant specification metadata, shared profile-default recovery metadata, generic recovery metadata, and valid following discriminant default-expression metadata. This remains editor-grade structural parsing, not compiler-grade discriminant legality checking, default-expression type checking, aspect legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

Pass928 improves structural Ada grammar recovery for malformed array index parts where an index item or upper bound is replaced by a reserved/declaration boundary. The token cursor now records `Production_Array_Index_Reserved_Boundary_Recovery_Boundary` while preserving array type definition metadata, generic constraint recovery metadata, and valid following array index bound metadata. This remains editor-grade structural parsing, not compiler-grade array index subtype legality checking, range expression type checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass929 — Access-object missing subtype recovery

Pass929 improves structural Ada grammar recovery for malformed access-to-object definitions where the designated subtype is missing and the next token is a reserved/declaration boundary, such as `access with Volatile`, `access private`, or `access)`. The token cursor now records `Production_Access_Object_Missing_Subtype_Recovery_Boundary` while preserving shared access-type recovery metadata and valid following declaration metadata. This remains editor-grade structural parsing, not compiler-grade access-type legality checking, designated-subtype legality checking, subtype resolution, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass930 — Access-definition recovery depth

Pass930 improves structural Ada grammar recovery for malformed access definitions. The token cursor now records mode-specific missing-subtype recovery for `access all` and `access constant`, conflict recovery when a general-access mode is followed by an access-to-subprogram head, boundary-token metadata after `access protected` without `procedure` or `function`, and result-subtype recovery when an access-to-function `return` reaches an aspect/declaration boundary. The new AUnit regression is `Test_Language_Model_Token_Cursor_Access_Definition_Recovery_Depth_Pass930`. This improves structural grammar coverage for access-definition edge cases, but it is not compiler-grade access-type legality checking, designated-subtype legality checking, profile conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass931 — Generic formal subprogram default recovery

Pass931 improves structural Ada grammar recovery for generic formal subprogram declarations. The token cursor now records `is abstract Name` defaults through `Production_Formal_Subprogram_Default_Abstract_Name` and records `Production_Formal_Subprogram_Default_Missing_Target_Recovery_Boundary` when `is` is followed immediately by a declaration/aspect boundary instead of a default target. The new AUnit regression is `Test_Language_Model_Token_Cursor_Generic_Formal_Subprogram_Default_Recovery_Pass931`. This improves structural grammar coverage for generic formal declarations, but it is not compiler-grade generic contract checking, default conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass932 — Formal package declaration header recovery

Pass932 improves structural Ada grammar recovery for generic formal package declarations. The token cursor now records `Production_Formal_Package_Missing_Is_Recovery_Boundary` and `Production_Formal_Package_Missing_New_Recovery_Boundary` for malformed `with package P ...` headers, keeps missing generic-package-name recovery bounded, and records `Production_Formal_Package_Named_To_Positional_Order_Recovery_Boundary` when a positional actual follows a named formal package actual. The new AUnit regression is `Test_Language_Model_Token_Cursor_Formal_Package_Header_Recovery_Pass932`. This improves structural grammar coverage for formal package declarations, but it is not compiler-grade generic contract checking, generic actual conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass933 — Use-clause recovery depth

Pass933 improves structural grammar coverage for malformed Ada use clauses by distinguishing omitted `type` after `use all` and reserved declaration/package boundaries where use-clause names were expected. This is parser metadata only; it is not compiler-grade visibility legality checking.

### Pass934 — Representation item recovery depth

Pass934 improves structural grammar coverage for malformed Ada representation and operational items by distinguishing target-boundary recovery, missing `use`, missing attribute designators, reserved-boundary address values, and enumeration representation association lists that hit declaration/private boundaries. This is parser metadata only; it is not compiler-grade representation legality checking, freezing-rule checking, layout validation, or static-expression validation.

### Pass935 — Subprogram contract/aspect placement depth

Pass935 improves structural grammar coverage for subprogram contracts and attached aspects. The token cursor now distinguishes contract placement on subprogram bodies, null procedure completions, abstract completions, and expression functions, and records contract-specific missing-value recovery for malformed `Pre`, `Post`, `Global`, and `Depends` style associations. The new AUnit regression is `Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Placement_Depth_Pass935`. This improves structural grammar coverage for subprogram contract/aspect placement, but it is not compiler-grade aspect legality checking, contract conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass936 — Subprogram contract/aspect value-family depth

Pass936 improves structural grammar coverage for subprogram contract/aspect value families. The token cursor now records `Production_Classwide_Contract_Aspect_Mark` for `Pre'Class` and `Post'Class`, and adds dedicated value-family metadata for `Contract_Cases`, `Exceptional_Cases`/`Exit_Cases`, `Always_Terminates`, `Nonblocking`, and `Initializes`/`Depends`-style aspects. The new AUnit regression is `Test_Language_Model_Token_Cursor_Subprogram_Contract_Aspect_Value_Families_Pass936`. This improves structural grammar coverage for subprogram contract/aspect placement and values, but it is not compiler-grade aspect legality checking, contract conformance checking, static-expression validation, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

Pass937 improves structural grammar coverage for package specification/body declarative section recovery. The token cursor now records dedicated metadata for duplicate package `private` markers, `begin` reached from a package private part, and illegal `private` markers in package body declarative parts. The new AUnit regression is `Test_Language_Model_Token_Cursor_Package_Declarative_Section_Recovery_Depth_Pass937`. This improves package declarative-section recovery for Outline and semantic-colouring stability, but it is not compiler-grade package legality checking, declarative-part legality checking, visibility checking, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass938 — Anonymous access-to-subprogram recovery refinement

Pass938 improves structural grammar recovery for anonymous access-to-subprogram definitions. The token cursor now records `Production_Access_Subprogram_Parameter_Profile_Missing_Close_Recovery_Boundary` when an access-to-procedure/function parameter profile reaches a declaration/aspect boundary before `)`, and records `Production_Access_Result_Null_Exclusion_Missing_Subtype_Recovery_Boundary` when an access-to-function `return not null` is followed by a boundary instead of a result subtype. The new AUnit regression is `Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Refinement_Depth_Pass938`. This improves structural grammar coverage for protected and ordinary anonymous access-to-subprogram profiles, but it is not compiler-grade access-type legality checking, profile conformance checking, result subtype legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass939 — Expression recovery refinement

Pass939 improves structural grammar recovery for expression families used by Outline and semantic colouring. The token cursor now records `Production_If_Expression_Condition_Reserved_Boundary` when `if` or `elsif` expression conditions reach a reserved branch boundary, `Production_Case_Expression_Missing_Selector_Recovery_Boundary` when a case expression reaches `is`/`when` before its selector, `Production_Case_Expression_Missing_Is_Recovery_Boundary` when the selector is followed by alternatives without `is`, and `Production_Parallel_Reduction_Argument_Recovery_Boundary` when malformed `Parallel_Reduce` argument parts recover at a boundary. The new AUnit regression is `Test_Language_Model_Token_Cursor_Expression_Recovery_Refinement_Depth_Pass939`. This improves structural grammar coverage for conditional expressions, case expressions, and parallel-reduction argument recovery, but it is not compiler-grade expression legality checking, expected-type resolution, static-expression validation, overload resolution, reduction profile conformance checking, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass940 — Name grammar recovery depth

Pass940 improves structural grammar recovery for Ada name grammar edge cases. The token cursor now distinguishes selected names whose selector is replaced by a reserved boundary, allocators missing a subtype indication after `new`, and qualified expressions or allocator-qualified expressions whose operand list is empty or starts at a boundary. The new AUnit regression is `Test_Language_Model_Token_Cursor_Name_Grammar_Recovery_Depth_Pass940`. This improves structural grammar coverage for selected-name, allocator, and qualified-expression recovery, but it is not compiler-grade selected-name legality checking, allocator subtype legality checking, qualified-expression operand legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass941 — Protected entry-body barrier recovery depth

Pass941 improves structural grammar recovery for protected entry bodies missing their `when` barrier before `is`. The token cursor now exposes `Production_Entry_Body_Missing_Barrier_Recovery_Boundary` and `Production_Protected_Entry_Body_Missing_Barrier_Recovery_Boundary`, with regression coverage in `Test_Language_Model_Token_Cursor_Entry_Body_Missing_Barrier_Recovery_Pass941`. This helps Outline and semantic-colouring consumers keep malformed protected operations local and recover into following valid entry bodies, but it is not compiler-grade tasking legality checking, protected-operation conformance checking, barrier expression legality checking, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

Pass942 starts the compiler-grade grammar pivot by retaining additional Ada 2022 expression families in the parser-owned syntax tree, not just in token-cursor production metadata. The syntax tree now exposes `Node_Declare_Expression`, `Node_Delta_Aggregate`, `Node_Container_Aggregate`, `Node_Reduction_Expression`, `Node_Iterator_Specification`, and `Node_Target_Name`, and declaration defaults now attach expression children so object/constant declarations can preserve nested Ada 2022 expression grammar. Regression coverage is in `Test_Ada_Syntax_Tree_Ada2022_Expression_Node_Coverage_Pass942`. This is a compiler-grade grammar-model building block; complete compiler-grade Ada analysis still depends on integrating name resolution, overload resolution, type checking, static evaluation, generic contracts, freezing/representation legality, and cross-unit semantics.

Pass943 starts the compiler-grade semantic pivot by adding `Editor.Ada_Declarative_Regions`. The new model is built from `Editor.Ada_Syntax_Tree.Tree_Type` and retains stable declarative-region identity, owner syntax-tree nodes, parent region IDs, nesting depth, labels, and fingerprints for compilation units, generic formal parts, package specs/bodies, subprogram specs/bodies, task/protected specs and bodies, entry bodies, record definitions, and blocks. Regression coverage is in `Test_Ada_Declarative_Region_Model_Foundation_Pass943`. This is a compiler-grade foundation for direct visibility and name-resolution passes; complete Ada analysis still requires lookup, overload resolution, type checking, static evaluation, generic contracts, freezing/representation legality, and cross-unit consistency.

### Pass944 — Direct visibility foundation

Pass944 adds `Editor.Ada_Direct_Visibility`, the first lookup layer over the pass943 declarative-region model. It extracts defining declarations from `Editor.Ada_Syntax_Tree`, assigns declarations to their directly enclosing region, records deterministic declaration metadata, and supports case-insensitive direct plus enclosing-region lookup. This is a compiler-grade semantic foundation for direct-name resolution, but full Ada compiler-grade analysis still requires use-clause visibility, overload resolution, expected-type propagation, type checking, static evaluation, generic contracts, freezing, representation legality, and cross-unit closure.

### Phase 579 pass945 — use-clause visibility foundation

Pass945 adds `Editor.Ada_Use_Visibility`, a parser-owned use-clause visibility
model layered over declarative regions and direct visibility. It records
ordinary `use`, `use type`, and `use all type` clauses with stable owner-region,
target-declaration, target-region, and fingerprint metadata, and it performs the
first package-use lookup with deterministic ambiguity reporting. This is a
compiler-grade semantic building block; complete Ada legality still requires the
later type, overload, generic, static-evaluation, and representation/freezing
layers.

### Phase 579 pass946

Pass946 adds `Editor.Ada_Selected_Name_Resolution`, the next compiler-grade
semantic foundation after use visibility. It resolves selected names with package
prefixes through direct/use visibility and records deterministic prefix/selector
metadata for later type, overload, and legality layers.

### Phase 579 pass947

Pass947 adds `Editor.Ada_Use_Type_Operators`, a compiler-grade semantic foundation for `use type` and `use all type` primitive visibility.  It records target type declarations, primitive regions, primitive operator/subprogram declarations, deterministic fingerprints, and operator lookup metadata for later overload and type-checking passes.

### Phase 579 pass948

Pass948 adds `Editor.Ada_Call_Candidates`, a compiler-grade semantic foundation for overload resolution.  It records call-shaped syntax nodes and their pre-filter callable candidates using direct visibility, use-clause package visibility, and use-type primitive visibility.  The pass provides deterministic found/ambiguous/unresolved candidate metadata for later expected-type, profile-conformance, and full overload-resolution passes.

### Phase 579 pass949 — call-profile shape foundation

Pass949 adds `Editor.Ada_Call_Profile_Shapes`, a compiler-grade overload-resolution building block layered on the parser-owned syntax tree and declarative-region model.  It records callable declaration profile shapes and actual-argument shapes with stable IDs, owning regions, normalized names, arity/named-actual counts, source ranges, statuses, and deterministic fingerprints.  Regression coverage is in `Test_Ada_Call_Profile_Shape_Foundation_Pass949`.  This enables later overload filtering by arity and named-actual shape; complete compiler-grade overload resolution still requires expected-type propagation, full profile conformance, type checking, implicit conversion legality, generic contracts, freezing/representation legality, and cross-unit semantic closure.

### Phase 579 pass950 — call-profile filter foundation

Pass950 adds `Editor.Ada_Call_Profile_Filters`, a compiler-grade overload-resolution building block layered on call candidates and call-profile shapes.  It records per-candidate filter entries with the call node, candidate declaration, callable/actual profile IDs, formal and actual counts, named-actual counts, status, source range, and deterministic fingerprint.  The pass applies deterministic arity and named-actual shape filtering: too many actuals are rejected, compatible positional calls are retained, and named-actual calls are classified for later formal-name/defaulted-formal checking.  Regression coverage is in `Test_Ada_Call_Profile_Filter_Foundation_Pass950`.  Full compiler-grade overload resolution still requires formal-name matching, defaulted-formal legality, expected-type propagation, profile conformance, type checking, implicit conversion legality, generic contracts, freezing/representation legality, and cross-unit semantic closure.

### Pass951 — Formal-name/default call-profile filtering

Pass951 extends the compiler-grade overload-resolution foundation. `Editor.Ada_Call_Profile_Shapes` now records normalized formal names, defaulted-formal names/counts, and named-actual names. `Editor.Ada_Call_Profile_Filters` now distinguishes formal-name-compatible named actuals, unknown named actuals, and calls that omit required non-defaulted formals. Regression coverage is in `Test_Ada_Call_Profile_Formal_Name_Filter_Pass951`. This is a compiler-grade building block for formal-name/default filtering; remaining work includes expected-type propagation, full profile conformance, type checking, implicit conversions, generic contracts, freezing/representation legality, and cross-unit semantic closure.

### Phase 579 pass952 — call-resolution result classification

Pass952 adds `Editor.Ada_Call_Resolution`, a compiler-grade overload-resolution staging model layered on `Editor.Ada_Call_Candidates` and `Editor.Ada_Call_Profile_Filters`. It records deterministic call-resolution states for call-shaped syntax nodes: unresolved call designators, pre-profile ambiguity, no actual filter, no viable profile, unique profile match, and ambiguous profile match. Regression coverage is in `Test_Ada_Call_Resolution_Profile_Result_Pass952`. This is a compiler-grade building block for diagnostics and later overload resolution; remaining work includes expected-type propagation, full profile conformance, type checking, implicit conversions, generic contracts, freezing/representation legality, and cross-unit semantic closure.


### Pass953 expected-type context foundation

Added `Editor.Ada_Expected_Type_Contexts` to attach deterministic expected-subtype context metadata to call-shaped expression nodes in declaration defaults and return contexts. This is a compiler-grade semantic staging layer for later expected-type overload filtering and type checking; it does not yet complete full type compatibility, implicit conversion legality, generic contracts, freezing/representation legality, or cross-unit semantic closure.

### Phase 579 pass954 — expected-call result-subtype filtering

Pass954 adds `Editor.Ada_Expected_Call_Filters`, a compiler-grade overload-resolution building block layered on expected-type contexts, call-resolution results, profile filters, and callable-profile shapes. It records deterministic per-call metadata connecting expected subtype text to the callable result subtype and classifies unique-profile calls as result-subtype matches or mismatches. Regression coverage is in `Test_Ada_Expected_Call_Filter_Foundation_Pass954`. This applies expected-type context information to call-result filtering, but full compiler-grade analysis still requires derived/class-wide compatibility, implicit conversions, universal numeric resolution, generic contracts, freezing/representation legality, and cross-unit semantic closure.

Pass955 adds `Editor.Ada_Subtype_Compatibility`, the first conservative subtype-compatibility foundation for expected-type filtering. It normalizes subtype-name text, classifies predefined integer/real and universal numeric families, and reports exact matches, universal-integer-to-integer, universal-real-to-real, universal-integer-to-real, known numeric incompatibility, or indeterminate user-defined relationships. `Editor.Ada_Expected_Call_Filters` now records the compatibility status and can distinguish exact result-subtype matches, compatible universal-numeric cases, known mismatches, and indeterminate relationships. Regression coverage is in `Test_Ada_Subtype_Compatibility_Foundation_Pass955`. This is a compiler-grade type-checking building block; full compiler-grade analysis still requires a complete type graph, derivation/class-wide compatibility, implicit conversions, static expression evaluation, generic contracts, freezing/representation legality, and cross-unit semantic closure.

Pass956 adds `Editor.Ada_Type_Graph`, the first declaration-derived type graph foundation. It builds stable type nodes from type, subtype, and formal type declarations, classifies range/modular/floating/fixed/array/record/access/private/derived/subtype/formal shapes, resolves subtype and derived-type parent declarations through direct visibility, records unresolved or ambiguous bases for diagnostics, and provides ancestry/compatibility queries for exact, subtype-of, and derived-from relationships. Regression coverage is in `Test_Ada_Type_Graph_Foundation_Pass956`. This is a compiler-grade type-system building block; full compiler-grade analysis still requires private-view completion, class-wide and interface compatibility, implicit conversions, static expression evaluation, generic contracts, freezing/representation legality, and cross-unit semantic closure.

Pass957 adds declaration-derived type-graph compatibility integration to expected-call filtering. `Editor.Ada_Subtype_Compatibility` now exposes type-graph-aware statuses for exact, subtype-of, and derived-from relationships, and `Editor.Ada_Expected_Call_Filters` records `Type_Compatibility` metadata through `Build_With_Type_Graph`. Expected-call filtering can now classify user-defined result subtypes using the declaration-derived type graph rather than relying only on normalized subtype text or predefined universal numeric families. Regression coverage is in `Test_Ada_Expected_Call_Filter_Type_Graph_Compatibility_Pass957`. This is a compiler-grade type-checking and overload-resolution building block; full compiler-grade Ada analysis still requires private-view completion, class-wide/interface compatibility, implicit conversions, static expression evaluation, generic contracts, freezing/representation legality, and cross-unit semantic closure.

### Phase 579 pass958

Pass958 extends the compiler-grade Ada type-system foundation with private/full-view links in `Editor.Ada_Type_Graph`, explicit interface type classification, and class-wide expected-type compatibility for type-graph-aware expected-call filtering. It adds `Test_Ada_Type_Graph_Private_Classwide_Interface_Pass958` and keeps the work staged for later full visibility, overload, generic, static-evaluation, and freezing legality layers.

### Phase 579 pass959

Pass959 adds `Editor.Ada_Implicit_Conversions`, a compiler-grade staging layer that classifies whether an already-known subtype/type-graph compatibility result is usable by Ada implicit-conversion rules in an expected-type context. It intentionally separates subtype compatibility from implicit assignment compatibility: subtype results and class-wide descendants are allowed, universal numeric results remain allowed, and distinct derived-type ancestry is retained as requiring an explicit conversion. `Editor.Ada_Expected_Call_Filters` now records implicit-conversion metadata for expected-call results. The pass adds `Test_Ada_Implicit_Conversion_Filter_Foundation_Pass959` and keeps overload/type checking staged for full profile conformance, implicit conversion coverage beyond calls, generic contracts, static evaluation, and freezing/representation legality.

### Pass960 - static-expression model foundation

Pass960 adds `Editor.Ada_Static_Expressions`, a compiler-grade static-expression staging layer. It evaluates a bounded, deterministic subset of Ada static integer expressions from snapshot-owned syntax-tree data: integer literals, named-number/static-constant references, parentheses, unary signs, and `+`, `-`, `*`, `/`, `mod`, and `rem`. Unsupported or unresolved expressions are preserved as explicit status values for later diagnostics rather than guessed. The pass adds `Test_Ada_Static_Expression_Foundation_Pass960` and keeps full Ada static evaluation, universal real arithmetic, static attributes, modular overflow, enumeration positions, generic matching, freezing, and representation legality for later passes.


### Pass961 - static attribute expression foundation

Pass961 extends `Editor.Ada_Static_Expressions` with scalar subtype-bound staging and bounded static attribute evaluation. The model now records range-constrained type/subtype bounds as deterministic metadata, resolves `T'First` and `T'Last` when both bounds are static integers, and stages `T'Pos (...)` / `T'Val (...)` integer arguments conservatively. Unsupported attributes such as `Image` are retained as explicit unsupported-attribute statuses rather than being misclassified as unresolved names. Regression coverage is in `Test_Ada_Static_Attribute_Expression_Foundation_Pass961`. This is a compiler-grade static-expression building block; complete Ada static evaluation still requires real/universal arithmetic, enumeration literal positions, static string/character handling, modular overflow rules, static attribute completeness, generic contracts, freezing/representation legality, and cross-unit semantic closure.

### Pass962 - static enumeration-position foundation

Pass962 extends `Editor.Ada_Static_Expressions` with deterministic enumeration literal position metadata. Enumeration literal declarations under enumeration type declarations are staged with type/literal names, source region, zero-based position, and fingerprints. Static evaluation now resolves enumeration `T'Pos (Literal)` to integer positions and `T'Val (Position)` to enumeration-literal metadata when the literal table is known, while unresolved operands remain explicit diagnostic metadata. Regression coverage is in `Test_Ada_Static_Enumeration_Position_Foundation_Pass962`. This is a compiler-grade static-expression building block; complete Ada static evaluation still requires full discrete-type semantics, character/string static handling, real/universal arithmetic, modular overflow rules, generic contracts, freezing/representation legality, and cross-unit semantic closure.

Pass963 extends `Editor.Ada_Static_Expressions` with deterministic modular integer metadata. Modular type declarations are staged with type name, owning region, modulus expression text, evaluated static modulus value where available, source range, and fingerprint. The new `Reduce_Modular_Integer` API reduces static integer expressions by a known modular type modulus and preserves unresolved type names or malformed/non-static modulus cases for later diagnostics. Regression coverage is in `Test_Ada_Static_Modular_Integer_Foundation_Pass963`. This is a compiler-grade static-expression building block; complete Ada analysis still requires complete modular legality, full discrete-type semantics, universal/real arithmetic, generic contracts, freezing/representation legality, and cross-unit semantic closure.

Pass964 extends `Editor.Ada_Static_Expressions` with real/universal numeric static-expression metadata. Static values now include `Static_Value_Real` and `Real_Value`, and the new `Evaluate_Numeric_Expression` API evaluates decimal/exponent literals, named real constants, unary signs, and `+`, `-`, `*`, `/` arithmetic while preserving division-by-zero as explicit metadata. `Evaluate_Integer_Expression` remains integer-only and rejects real-valued expressions as non-static for integer-only legality clients. Regression coverage is in `Test_Ada_Static_Real_Numeric_Foundation_Pass964`. This is a compiler-grade static-expression building block; complete Ada analysis still requires fixed-point static evaluation, full universal numeric resolution, complete real-type legality, generic contracts, freezing/representation legality, and cross-unit semantic closure.

Pass965 extends `Editor.Ada_Static_Expressions` with fixed-point static metadata. Fixed-point type declarations are now staged with delta, optional digits, range bound expressions, evaluated static numeric values where available, source range, and deterministic fingerprints. The new fixed-type lookup and `Quantize_Fixed_Value` API classify static fixed-point values as representable, delta-mismatched, range-invalid, unresolved, or malformed without guessing. Regression coverage is in `Test_Ada_Static_Fixed_Point_Foundation_Pass965`. This is a compiler-grade static-expression/type-system building block; complete Ada analysis still requires complete fixed-point legality, universal numeric resolution in every expression context, generic contracts, freezing/representation legality, and cross-unit semantic closure.

### Pass966 - generic contract model foundation

Pass966 adds `Editor.Ada_Generic_Contracts`, a compiler-grade generic-analysis foundation. The model stages generic formal type, object, subprogram, and package declarations from the parser-owned syntax tree and direct-visibility table, records formal defaults/default boxes where structurally available, and records generic instantiation actual shape with positional/named counts and named-actual names. Regression coverage is in `Test_Ada_Generic_Contract_Foundation_Pass966`. Complete compiler-grade Ada analysis still requires full formal/actual conformance, generic body contract visibility, overload matching, type checking, private-view rules, static-expression legality, freezing/representation legality, and cross-unit semantic closure.

### Pass967 - generic formal/actual matching foundation

Pass967 extends `Editor.Ada_Generic_Contracts` with deterministic formal/actual matching metadata for generic instantiations. The model now resolves an instantiation target generic through direct visibility, locates the generic formal region, counts required and defaulted formals, matches positional and named actuals by normalized formal name, and classifies malformed instances, unresolved/ambiguous generic names, non-generic targets, missing formal regions, too many positional actuals, unknown or duplicate named actuals, and missing non-defaulted formals. Regression coverage is in `Test_Ada_Generic_Actual_Matching_Foundation_Pass967`. This is a compiler-grade generic-contract staging layer; complete Ada analysis still requires type/formal conformance, subprogram profile matching, formal package contract matching, generic body contract visibility, overload resolution, private-view rules, freezing/representation legality, and cross-unit semantic closure.

### Pass968 - generic formal/actual kind conformance foundation

Pass968 extends `Editor.Ada_Generic_Contracts` with conservative actual-kind staging for generic instantiations. The model now records positional and named actual kind metadata, distinguishes type/object/subprogram/package actual shapes where the parser-owned syntax makes that deterministic, and classifies formal-kind mismatches separately from missing, unknown, duplicate, or malformed actuals. Regression coverage is in `Test_Ada_Generic_Formal_Actual_Kind_Conformance_Pass968`. This is a compiler-grade generic-contract building block; full Ada generic conformance still needs declaration-resolved actual classification in all contexts, formal subprogram profile matching, formal package contract matching, overload resolution, private-view rules, freezing/representation legality, and cross-unit semantic closure.


### Pass969 - generic formal subprogram profile conformance

Pass969 extends `Editor.Ada_Generic_Contracts` with formal subprogram profile conformance metadata. Generic formal subprograms now retain parameter-count, normalized parameter-subtype shape, result presence, and result-subtype metadata. Generic instantiation actuals retain positional/named actual designator text, allowing declaration-shaped subprogram actuals to be resolved through direct visibility and compared against the formal profile. The match model now distinguishes formal-kind mismatches from formal subprogram profile mismatches and records deterministic compatible/mismatched/unknown profile counts. Regression coverage is in `Test_Ada_Generic_Formal_Subprogram_Profile_Conformance_Pass969`. This is a compiler-grade generic-contract building block; full Ada generic conformance still requires overload-aware subprogram actual selection, formal package contract matching, generic body contract visibility, private-view rules, freezing/representation legality, and cross-unit semantic closure.


### Pass970 - generic formal package contract conformance

Pass970 extends `Editor.Ada_Generic_Contracts` with formal package contract conformance metadata. Generic formal package records now retain their expected target generic name, normalized target, and box actual-state marker. Generic instantiation matching resolves package actuals through direct visibility, recognizes inline `new Generic (...)` package actuals, verifies that declaration-shaped package actuals are package instantiations, and compares the actual package instance target generic against the formal package contract. The match model now distinguishes formal package contract mismatches and unknown formal package contract cases, including unresolved actuals, ambiguous actuals, non-instance package actuals, wrong-generic package instances, unknown formal contracts, and malformed package actuals, with deterministic compatible/mismatched/unknown counters exposed through `Formal_Package_Compatible_Count_For_Instance`, `Formal_Package_Mismatch_Count_For_Instance`, and `Formal_Package_Unknown_Count_For_Instance`. Regression coverage is in `Test_Ada_Generic_Formal_Package_Contract_Conformance_Pass970`. This pass adds one compiler-grade generic-contract building block. Full compiler-grade Ada analysis remains incomplete until remaining layers such as overload-aware actual selection, generic body contract visibility, private-view rules, default-expression legality, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Phase 579 pass971 — Generic body contract visibility

Pass971 extends `Editor.Ada_Generic_Contracts` with a deterministic body-contract visibility model.  The model maps a generic declaration's formal region to the matching package/subprogram body region, records visible/shadowed generic formals, exposes body-region formal lookup APIs, and preserves body-not-found/missing-formal-region states explicitly.  The new AUnit regression is `Test_Ada_Generic_Body_Contract_Visibility_Pass971`.

This pass adds one compiler-grade building block for generic body contract visibility.  Full compiler-grade Ada analysis remains incomplete until the remaining layers such as overload resolution, type checking, generic default legality, private-view visibility, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Phase 579 pass972 — Overload-aware generic subprogram actual selection

Pass972 extends `Editor.Ada_Generic_Contracts` with profile-driven overload selection for generic formal subprogram actuals.  Ambiguous visible subprogram names are now enumerated in Ada hiding order and filtered against the expected formal profile after simple formal type substitution.  The model records selected, ambiguous, and unresolved overload metadata through deterministic counters and the new `Generic_Actual_Match_Formal_Subprogram_Profile_Ambiguous` status.  The new AUnit regression is `Test_Ada_Generic_Formal_Subprogram_Overload_Selection_Pass972`.

### Phase 579 pass973 — Generic default-expression legality foundation

Pass973 extends `Editor.Ada_Generic_Contracts` with `Build_With_Static`, allowing the generic-contract layer to consume `Editor.Ada_Static_Expressions.Static_Model` and classify generic formal-object defaults and explicit object actual expressions as static, illegal, or unresolved/unknown.  The model now records deterministic counters for checked/static/illegal/unknown object expressions, including non-static, malformed, unresolved, and division-by-zero detail metadata.  New statuses distinguish illegal and unknown formal-object default/actual expression cases, and the AUnit regression is `Test_Ada_Generic_Default_Expression_Legality_Pass973`.

### Phase 579 pass974 — Generic formal subprogram parameter-mode conformance

Pass974 extends `Editor.Ada_Generic_Contracts` with parameter-mode retention and mode-aware formal subprogram profile conformance. Generic formal subprogram profiles now record normalized parameter mode vectors (`in`, `out`, `in out`) alongside parameter-count and subtype-shape metadata. Generic actual matching rejects same-arity/same-subtype subprogram actuals whose parameter modes do not conform to the formal profile, records deterministic mode-mismatch counters, and exposes `Subprogram_Profile_Mode_Mismatch_Count_For_Instance`. The new AUnit regression is `Test_Ada_Generic_Formal_Subprogram_Mode_Conformance_Pass974`.

This pass adds one compiler-grade building block for complete profile conformance. Full compiler-grade Ada analysis remains incomplete until remaining layers such as access-to-subprogram profile conformance, null-exclusion/profile subtype conformance, private-view rules, freezing/representation legality, cross-unit semantic closure, and full expression type inference are fully integrated.

### Phase 579 pass975 — Type-graph-aware generic subprogram profile conformance

Pass975 extends `Editor.Ada_Generic_Contracts` with `Build_With_Type_Graph` and `Build_With_Static_And_Type_Graph`, allowing generic formal subprogram profile conformance to use `Editor.Ada_Type_Graph` relationships after formal type substitution. Profile matching can now accept known subtype relationships such as a formal profile substituted to `Root` matching an actual subprogram parameter of subtype `Small`, while the default text-only build path continues to preserve conservative raw-subtype-name rejection. The match model records deterministic type-compatible, type-mismatched, and type-unknown counters exposed through `Subprogram_Profile_Type_Compatible_Count_For_Instance`, `Subprogram_Profile_Type_Mismatch_Count_For_Instance`, and `Subprogram_Profile_Type_Unknown_Count_For_Instance`. The new AUnit regression is `Test_Ada_Generic_Formal_Subprogram_Type_Graph_Conformance_Pass975`.

This pass adds one compiler-grade building block for complete profile conformance. Full compiler-grade Ada analysis remains incomplete until remaining layers such as access-to-subprogram profile conformance, null-exclusion and convention conformance, private-view rules, freezing/representation legality, cross-unit semantic closure, and full expression type inference are fully integrated.


Pass976 adds a compiler-grade generic profile-conformance building block for formal subprogram null-exclusion and anonymous access-to-subprogram profile matching. Generic actual matching now records and reports null-exclusion mismatches and access-profile mismatches separately from generic profile mismatches, with deterministic counters and regression coverage in Test_Ada_Generic_Formal_Subprogram_Null_Access_Conformance_Pass976. Full compiler-grade Ada analysis remains incomplete until private-view rules, freezing, representation legality, cross-unit closure, and full expression type inference are fully integrated.

### Phase 579 pass976 — Null/access generic subprogram profile conformance

Pass976 extends `Editor.Ada_Generic_Contracts` with a compiler-grade profile-conformance building block for formal subprogram actuals. Generic actual matching now classifies null-exclusion mismatches and anonymous access-to-subprogram profile mismatches separately from broad profile mismatches, exposes deterministic counters for both cases, and covers the behavior with `Test_Ada_Generic_Formal_Subprogram_Null_Access_Conformance_Pass976`.


Pass977 adds one compiler-grade building block for generic formal subprogram profile conformance: calling-convention conformance. Generic formal subprograms now retain a normalized convention, actual subprogram candidates are checked against the expected convention, and convention mismatches are classified separately from broad profile mismatches. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as private-view visibility rules, freezing and representation legality, cross-unit semantic closure, and full expression type inference are fully integrated.

### Phase 579 pass978 — Generic formal subprogram defaulted-parameter conformance

Pass978 extends `Editor.Ada_Generic_Contracts` with defaulted-parameter profile metadata for generic formal subprogram conformance. Formal subprogram profiles now retain a deterministic required/defaulted parameter vector alongside count, subtype, mode, convention, and result metadata. Generic actual matching now rejects a subprogram actual whose corresponding parameter is required when the formal subprogram contract exposes that parameter as defaulted, while still accepting a defaulted actual for a required formal parameter. The new status is `Generic_Actual_Match_Formal_Subprogram_Default_Mismatch`, the public counter is `Subprogram_Profile_Default_Mismatch_Count_For_Instance`, and regression coverage is in `Test_Ada_Generic_Formal_Subprogram_Default_Conformance_Pass978`.

This pass adds one compiler-grade building block for complete profile conformance. Full compiler-grade Ada analysis remains incomplete until remaining layers such as private-view rules, freezing/representation legality, cross-unit semantic closure, and full expression type inference are fully integrated.

### Pass979 generic formal subprogram class-wide profile conformance

Pass979 extends `Editor.Ada_Generic_Contracts` with class-wide/controlling-profile conformance metadata for generic formal subprogram actuals. Formal subprogram actual selection now separates profile mismatches caused by `T` versus `T'Class` parameter/result subtype marks from broad profile mismatches. The new status is `Generic_Actual_Match_Formal_Subprogram_Class_Wide_Mismatch`, the public counter is `Subprogram_Profile_Class_Wide_Mismatch_Count_For_Instance`, and regression coverage is in `Test_Ada_Generic_Formal_Subprogram_Class_Wide_Conformance_Pass979`.

This pass adds one compiler-grade building block for profile conformance. Full compiler-grade Ada analysis remains incomplete until private-view visibility rules, freezing, representation legality, cross-unit semantic closure, full expression type inference, and deeper generic body/instance legality are fully integrated.

### Pass980 generic formal subprogram parameter-name conformance

Pass980 extends `Editor.Ada_Generic_Contracts` with parameter-name retention and name-aware formal subprogram profile conformance. Formal subprogram profiles now retain normalized parameter-name vectors alongside count, subtype, mode, default, convention, class-wide, and result metadata. Generic actual matching now rejects same-shape subprogram actuals whose parameter names do not conform to the formal subprogram contract, reports the new `Generic_Actual_Match_Formal_Subprogram_Name_Mismatch` status, exposes `Subprogram_Profile_Name_Mismatch_Count_For_Instance`, and covers the behavior with `Test_Ada_Generic_Formal_Subprogram_Name_Conformance_Pass980`.

This pass adds one compiler-grade building block for profile conformance. Full compiler-grade Ada analysis remains incomplete until private-view visibility rules, freezing, representation legality, cross-unit semantic closure, full expression type inference, and deeper generic body/instance legality are fully integrated.

### Pass981 generic formal subprogram result-subtype conformance

Pass981 extends `Editor.Ada_Generic_Contracts` with result-subtype conformance metadata for generic formal subprogram actuals. Profile matching now substitutes simple formal type actuals into function result subtypes, applies type-graph relationships when the stricter build path is used, accepts subtype-compatible and class-wide-compatible results, and separates result-subtype mismatches from broad profile mismatches. The new status is `Generic_Actual_Match_Formal_Subprogram_Result_Mismatch`, the public counters are `Subprogram_Profile_Result_Compatible_Count_For_Instance`, `Subprogram_Profile_Result_Mismatch_Count_For_Instance`, and `Subprogram_Profile_Result_Unknown_Count_For_Instance`, and regression coverage is in `Test_Ada_Generic_Formal_Subprogram_Result_Conformance_Pass981`.

This pass adds one compiler-grade building block for complete profile conformance. Full compiler-grade Ada analysis remains incomplete until private-view visibility rules, freezing, representation legality, cross-unit semantic closure, full expression type inference, and deeper generic body/instance legality are fully integrated.

### Pass982 private-view visibility foundation

Pass982 adds `Editor.Ada_Private_View_Visibility`, a compiler-grade building block for Ada private-view visibility rules. The model is derived from parser-owned syntax-tree regions and the existing type graph, links private partial/full views to their package spec, private-part boundary, and matching package body region, and exposes deterministic `View_Status_At_Line` / `Full_View_Visible_At_Line` queries. The regression is `Test_Ada_Private_View_Visibility_Foundation_Pass982`.

This pass adds one compiler-grade building block for private-view rules. Full compiler-grade Ada analysis remains incomplete until semantic consumers use this visibility model throughout overload resolution, expression typing, generic contracts, representation legality, freezing, and cross-unit semantic closure.

### Pass983 private-view-aware subtype compatibility

Pass983 extends the private-view foundation into `Editor.Ada_Subtype_Compatibility`. `Editor.Ada_Private_View_Visibility` now exposes `Private_View_For_Full` and `Effective_Type_At_Line`, allowing semantic consumers to collapse hidden full views to partial views in visible-part/client contexts while exposing full views in private parts and matching package bodies. `Check_With_Private_View` applies those effective views before type-graph compatibility and records partial-view versus full-view compatibility through `Subtype_Compatibility_Private_View_Partial_View` and `Subtype_Compatibility_Private_View_Full_View`, with hidden full-view metadata preserved as `Subtype_Compatibility_Private_View_Hidden_Full_View`. Regression coverage is in `Test_Ada_Private_View_Subtype_Compatibility_Pass983`.

This pass adds one compiler-grade building block for private-view rules. Full compiler-grade Ada analysis remains incomplete until private-view-aware checks are threaded through overload resolution, expression typing, generic contracts, representation legality, freezing, and cross-unit semantic closure.

### Pass984 freezing-point model foundation

Pass984 adds `Editor.Ada_Freezing_Points`, a snapshot-owned freezing-point foundation derived from the Ada syntax tree, declarative regions, direct visibility, and type graph. The model records freezable declarations, first conservative freezing causes such as object declarations and subprogram bodies, and representation-clause ordering metadata so consumers can distinguish representation clauses that appear before a target is frozen from clauses that appear after the first freeze point. Regression coverage is in `Test_Ada_Freezing_Point_Foundation_Pass984`.

This pass adds one compiler-grade building block for freezing and later representation legality. Full compiler-grade Ada analysis remains incomplete until representation clauses, operational attributes, private-view rules, generic bodies, overload resolution, and cross-unit semantic closure all consume the freezing model.


Pass985: added Editor.Ada_Representation_Legality as a compiler-grade representation-legality foundation. It combines parser-owned representation clauses with freezing-order checks, static-expression metadata, and type-graph target-kind checks, with AUnit coverage for static values, late clauses, and incompatible target kinds.
Pass986: extended Editor.Ada_Representation_Legality with record representation component-clause legality metadata. The pass stages each component clause, resolves it against the represented record type's components, evaluates static storage-unit and bit-range expressions, rejects duplicate component clauses, unresolved components, non-static/malformed locations, negative positions, and reversed bit ranges, and adds deterministic counters plus AUnit coverage.

Pass987 update:
- Added enumeration representation clause legality checks in Editor.Ada_Representation_Legality.
- Literal associations are now staged separately with deterministic metadata for target validation, coverage, duplicate literals, duplicate values, static value validity, and ordering.
- Added Test_Ada_Enumeration_Representation_Legality_Pass987 and README_PASS987.txt.

Pass988 update:
- Extended Editor.Ada_Representation_Legality with Address-clause legality metadata for target compatibility and address value shape classification.
- Added static address expression recognition for X'Address and To_Address-style values, and separate rejection for null, arbitrary non-static names, and raw integer literals.
- Added deterministic counters for Address target errors, Address value errors, and accepted static Address values.
- Added Test_Ada_Address_Clause_Legality_Pass988 and README_PASS988.txt.

### Pass989 — Size, Alignment, and Storage_Size legality

Pass989 extends `Editor.Ada_Representation_Legality` with Size/Alignment/Storage_Size representation-legality checks. The model now separates incompatible targets for Size-family, Alignment, and Storage_Size clauses, requires integer-valued static expressions for integer representation values, classifies real-valued static expressions through `Representation_Legality_Static_Value_Not_Integer`, and exposes deterministic Size/Alignment/Storage target/static error counters. Regression coverage is in `Test_Ada_Size_Alignment_Storage_Legality_Pass989`.

This pass adds one compiler-grade building block for representation clause legality. Full compiler-grade Ada analysis remains incomplete until remaining operational attributes, private-view-aware representation checks, cross-unit semantic closure, freezing interactions, and full expression type inference are fully integrated.

### Pass990 — Convention, Import, Export, External_Name, and Link_Name legality

Pass990 extends `Editor.Ada_Representation_Legality` with a compiler-grade interfacing representation-legality layer. The model now stages Convention, Import, Export, External_Name, and Link_Name clauses alongside the existing freezing/static/type checks, records normalized convention/value metadata, validates target shape, validates convention identifiers, requires static Boolean Import/Export values, requires static string External_Name/Link_Name values, rejects enabled Import and Export on the same target, and flags standalone link-name clauses that do not accompany an enabled Import or Export. Regression coverage is in `Test_Ada_Interfacing_Representation_Legality_Pass990`.

Pass991 extends `Editor.Ada_Representation_Legality` with a compiler-grade stream-attribute representation-legality layer. The model recognizes Read, Write, Input, Output, and Put_Image clauses, stages stream subprogram designator metadata, checks type/subtype target shape, rejects malformed stream values, preserves profile-unknown designators for later callable-profile conformance, and exposes deterministic stream counters. Regression coverage is in `Test_Ada_Stream_Attribute_Representation_Legality_Pass991`.

This pass adds one compiler-grade building block for operational and interfacing representation legality. Full compiler-grade Ada analysis remains incomplete until remaining operational attributes, private-view-aware representation checks, cross-unit semantic closure, deeper freezing interactions, and full expression type inference are fully integrated.

### Pass992 — stream attribute profile conformance

Pass992 extends `Editor.Ada_Representation_Legality` with `Build_With_Stream_Profiles`, a stricter stream-attribute legality build path that combines direct visibility and callable-profile shape metadata with the existing freezing/static/type representation model. Stream designators for `Read`, `Write`, `Input`, `Output`, and `Put_Image` can now be resolved from the clause context and classified as profile-known-compatible or profile-known-mismatch instead of remaining profile-unknown. Regression coverage is in `Test_Ada_Stream_Attribute_Profile_Conformance_Pass992`.

This pass adds one compiler-grade building block for operational attribute legality. Full compiler-grade Ada analysis remains incomplete until stream subtype/mode conformance, Root_Stream_Type/Root_Buffer_Type class-wide checks, private-view-aware representation checks, cross-unit semantic closure, deeper freezing interactions, and full expression type inference are fully integrated.


Pass 993 adds operational attribute legality checks for Pack, Atomic, Volatile, component-level operational attributes, Bit_Order, and Scalar_Storage_Order. The legality model now records operational target/value statuses and deterministic counters.


### Pass994 — Representation/aspect legality unification

Pass994 routes representation-property aspects through `Editor.Ada_Representation_Legality` alongside attribute-definition clauses. The model now records source form metadata, counts aspect-sourced and attribute-definition-sourced properties deterministically, normalizes Boolean aspect defaults, and adds `Test_Ada_Representation_Aspect_Unification_Pass994`.

### Pass995 — cross-unit semantic closure foundation

Pass995 adds `Editor.Ada_Cross_Unit_Closure`, a deterministic project-wide Ada unit closure model built from `Editor.Ada_Project_Index`. The model records first-class links for spec/body pairs, body/spec pairs, child-to-parent units, parent-to-child units, and separate-body parent relationships. Each link retains source and target unit names, roles, paths, status, candidate count, and a deterministic fingerprint. Missing, ambiguous, and overflow relationships are preserved explicitly for future semantic consumers instead of being collapsed to a generic unavailable result. Regression coverage is in `Test_Ada_Cross_Unit_Semantic_Closure_Foundation_Pass995`.

This pass adds one compiler-grade building block for cross-unit semantic closure. Full compiler-grade Ada analysis remains incomplete until with/use dependency closure, private/limited views across units, body/spec semantic completion, subunit body-stub closure, and cross-unit expression/type/generic legality are fully integrated.

### Pass996 — with/use dependency semantic closure

Pass996 extends `Editor.Ada_Cross_Unit_Closure` with deterministic context-clause dependency links. The closure model now stages ordinary `with`, `limited with`, `private with`, and context `use` package dependencies from parser-owned visibility metadata, resolves their target library units through the project index, preserves missing/ambiguous/overflow statuses, and records clause names plus limited/private flags in each link. Regression coverage is in `Test_Ada_Cross_Unit_Context_Dependency_Closure_Pass996`.

This pass adds one compiler-grade building block for cross-unit semantic closure. Full compiler-grade Ada analysis remains incomplete until private/limited cross-unit view rules, body/spec semantic completion, subunit body-stub closure, and cross-unit expression/type/generic legality are fully integrated.

### Pass997 — cross-unit spec/body consistency

Pass997 adds deterministic spec/body consistency records to `Editor.Ada_Cross_Unit_Closure`. The closure model now exposes queryable consistency metadata for package/subprogram specs and bodies, including confirmed matches, missing counterparts, ambiguous counterparts, overflow, role mismatch, and name mismatch. The pass adds `Test_Ada_Cross_Unit_Spec_Body_Consistency_Pass997` and documents the new counters and metadata in `README_PASS997.txt`.

### Pass998 — child-unit and private-child legality

Pass998 extends `Editor.Ada_Cross_Unit_Closure` with deterministic child-unit legality records. The closure model now stages each child library unit separately from raw child-to-parent links, preserves child/parent unit names, roles, paths, private-child classification, candidate counts, and fingerprints, and distinguishes resolved public children, resolved private children, missing parents, ambiguous parents, overflow, and parent-role mismatches. Regression coverage is in `Test_Ada_Cross_Unit_Child_Private_Legality_Pass998`.

This pass adds one compiler-grade building block for cross-unit semantic closure. Full compiler-grade Ada analysis remains incomplete until private/limited cross-unit view rules, body/spec semantic completion, subunit body-stub closure, overload/type resolution across units, and complete cross-unit generic legality are fully integrated.

Pass999: cross-unit closure now includes deterministic separate-body legality metadata. Separate bodies are classified separately from raw separate-parent links as resolved parent bodies, missing parents, ambiguous parents, overflow, parent-role mismatches, or missing parent-name text, with stable query APIs and AUnit coverage in `Test_Ada_Cross_Unit_Separate_Body_Legality_Pass999`.

Pass1000 adds `Editor.Ada_Expression_Types`, a deterministic expression-type inference foundation over parser-owned Ada syntax trees. The model stages literal, name, selected-name, call, operator, qualified-expression, aggregate, and attribute-reference type metadata, preserving unresolved/ambiguous cases with stable counters and fingerprints for later expected-type propagation and diagnostics. Regression coverage is in `Test_Ada_Expression_Type_Inference_Foundation_Pass1000`.

### Pass1001 — Expected-type propagation beyond calls

Pass1001 extends `Editor.Ada_Expression_Types` with expected-type propagation metadata and opt-in build paths for consumers that have expected-context data. It also adds syntax-local expected-context discovery for declaration defaults so non-call expressions such as literals, aggregates, qualified expressions, conversions, numeric operators, and null literals can be classified against an expected subtype without mutating editor state or invoking an external compiler.

### Pass1002 — expression operator operand/result inference

Pass1002 extends `Editor.Ada_Expression_Types` with deterministic operator operand/result metadata. Operator-shaped expressions now retain normalized operator symbols, operand subtype shapes, result subtype shapes, operator-resolution status, operand-compatible/mismatch/unknown counters, and fingerprint integration. The first predefined layer covers numeric, Boolean, short-circuit, relational, and membership-shaped operators while preserving unknown or mismatched operands explicitly. Regression coverage is in `Test_Ada_Expression_Operator_Operand_Inference_Pass1002`.

This pass adds one compiler-grade building block for expression type inference. Full compiler-grade Ada analysis remains incomplete until user-defined operator overload resolution, aggregate component inference, conversion legality, attribute result typing, private-view-aware expression typing, and cross-unit semantic visibility are fully integrated.

### Pass1003 — expression aggregate context inference

Pass1003 extends `Editor.Ada_Expression_Types` with aggregate and container-aggregate context inference. Aggregate expressions now retain expected subtype, element/index subtype shapes where derivable, component counts, named/positional association counts, explicit context-required/unknown/mismatch metadata, deterministic counters, and fingerprint integration. Regression coverage is in `Test_Ada_Expression_Aggregate_Context_Inference_Pass1003`.

### Pass1004 — conversion and qualified-expression inference

Pass1004 extends `Editor.Ada_Expression_Types` with deterministic conversion/qualified-expression metadata. Function-call-shaped type conversions and qualified expressions now retain target subtype, operand subtype, target-resolution status, compatible/explicit/mismatch/unknown operand counters, and fingerprint integration. Regression coverage is in `Test_Ada_Expression_Conversion_Qualified_Inference_Pass1004`.

This pass adds one compiler-grade building block for expression type inference. Full compiler-grade Ada analysis remains incomplete until overload-aware call/conversion disambiguation, attribute result typing, private-view-aware expression typing, and cross-unit semantic visibility are fully integrated.

### Pass1005 — attribute-reference expression type inference

Pass1005 extends `Editor.Ada_Expression_Types` with deterministic attribute-reference inference metadata. Attribute references now retain normalized attribute names, prefix text, prefix type metadata, inferred result subtype, per-attribute status, and counters for resolved/static/string/unknown/prefix-unresolved results. Covered families include scalar bounds, range/length/pos, value/image, address/size/alignment/storage-size, callable/terminated, and access-valued attributes. Regression coverage is in `Test_Ada_Expression_Attribute_Reference_Inference_Pass1005`.

Pass1006: Added conditional/declare/reduction expression type inference metadata in Editor.Ada_Expression_Types. The model now tracks compatible/mismatched/unknown conditional branches, Boolean quantified results, declare-expression result staging, reduction-expression result staging, deterministic counters, and fingerprint contribution. Regression coverage: Test_Ada_Expression_Conditional_Declare_Reduction_Inference_Pass1006.


Pass1007: Added expression membership/range inference metadata. Membership expressions now retain Boolean result plus operand/choice compatibility state; range expressions retain bound subtype compatibility state; deterministic counters and fingerprints cover resolved, mismatch, and unknown cases.

Pass1008: Added expression target-name/update inference metadata. Ada 2022 target-name @ expressions now preserve context-required versus context-propagated status, delta/update aggregates retain expected/source subtype compatibility metadata, and deterministic counters/fingerprints expose compatible, mismatch, and unknown update-expression cases.


Pass1009 adds indexed component and slice expression type inference metadata in Editor.Ada_Expression_Types, including prefix subtype, index subtype, element/slice result subtype, deterministic counters, and AUnit coverage.

Pass1010 adds dereference and access-designator expression type inference metadata in Editor.Ada_Expression_Types, including explicit dereference prefix/designated subtype tracking, Access-family attribute target/result subtype tracking, deterministic counters, and AUnit coverage.
Pass1011 adds allocator expression type inference metadata in Editor.Ada_Expression_Types, including allocator target subtype extraction, expected access-type propagation, designated-subtype matching through the type graph, deterministic counters, and AUnit coverage.

Pass1012 adds parameter-association expected-type propagation metadata in Editor.Ada_Expression_Types. Positional and named call actuals now retain mapped formal subtype context, propagated expected subtype metadata, actual/formal compatibility or mismatch classification, deterministic counters, fingerprint contribution, and AUnit coverage.

Pass1013 adds call actual type-resolution metadata in Editor.Ada_Expression_Types. Call-shaped nodes now retain selected callable declaration metadata, actual/formal subtype compatibility counts, mismatch and unknown classifications, deterministic counters, fingerprint contribution, and AUnit coverage.

Pass1014 adds overload-aware operator expression inference metadata in Editor.Ada_Expression_Types. Operator-shaped expressions can now consume use-type primitive operator candidates, compare candidate operators against operand subtype shapes, preserve resolved/ambiguous/mismatch/unknown overload states, expose deterministic counters, and contribute this metadata to fingerprints. Regression coverage is in Test_Ada_Expression_Operator_Overload_Resolution_Pass1014.

Pass1015 adds universal integer/real final-resolution metadata in Editor.Ada_Expression_Types. Universal numeric expressions are resolved against expected integer, modular, real, and fixed contexts where possible, with static range-error metadata and deterministic counters preserved for later diagnostics.

Pass1016 adds type-graph-aware aggregate validation metadata in Editor.Ada_Expression_Types. Record aggregates now retain compatible, missing, and duplicate component counters where record component declarations are available; array aggregates retain element-compatible, mismatch, and unknown counters derived from expected element subtype context. The metadata contributes to deterministic fingerprints and is covered by Test_Ada_Expression_Aggregate_Type_Graph_Validation_Pass1016.

Pass1017 adds raise-expression and no-return inference metadata in Editor.Ada_Expression_Types. Raise statements and expression-shaped raise constructs now retain exception-target, message-shape, result-context, and no-return classification metadata with deterministic counters and fingerprint contribution. Regression coverage is in Test_Ada_Expression_Raise_No_Return_Inference_Pass1017.

### Pass1018 — Boolean-context expression inference

Pass1018 extends `Editor.Ada_Expression_Types` with Boolean-context inference metadata. Short-circuit expressions and condition-shaped contexts now retain expected-Boolean propagation, compatible/mismatched/unknown operand classification, deterministic counters, and fingerprint contribution. Regression coverage is in `Test_Ada_Expression_Boolean_Context_Inference_Pass1018`.

### Pass1019 — string and array concatenation inference

Pass1019 extends `Editor.Ada_Expression_Types` with concatenation-specific result inference for the `&` operator. String/string, string/character, character/string, expected-context character/character, and array-family concatenations now retain resolved/mismatch/unknown metadata, deterministic counters, and fingerprint contribution. Regression coverage is in `Test_Ada_Expression_Concatenation_Inference_Pass1019`.

### Pass1020 — dispatching-call inference metadata

Pass1020 extends `Editor.Ada_Expression_Types` with dispatching-call metadata for call-shaped nodes. The model now classifies primitive callable targets, static binding, class-wide dynamic dispatch candidates, controlling-result cases, ambiguous targets, unresolved targets, and controlling-unknown cases. Deterministic counters and fingerprint contribution were added, with regression coverage in `Test_Ada_Expression_Dispatching_Call_Inference_Pass1020`.
### Pass1021 — expression diagnostics projection

Pass1021 adds `Editor.Ada_Expression_Diagnostics`, a projection-only diagnostics layer over `Editor.Ada_Expression_Types`. It converts staged expression inference failures into deterministic diagnostics with stable node identity, source-line spans, severity, kind, message text, counters, and fingerprints. Coverage was added in `Test_Ada_Expression_Diagnostics_Projection_Pass1021`.
Pass1022 adds `Editor.Ada_Cross_Unit_Visibility`, a project-wide visibility projection over existing cross-unit closure metadata. It turns ordinary `with`, `limited with`, `private with`, and context `use` dependencies into deterministic lookup-facing records with status, target path, view kind, candidate count, and fingerprint metadata. Coverage was added in `Test_Ada_Cross_Unit_Visibility_Integration_Pass1022`.

Pass1023 adds `Editor.Ada_Limited_View_Rules`, a deterministic cross-unit visibility layer for `limited with` incomplete-view semantics. It consumes `Editor.Ada_Cross_Unit_Visibility`, marks limited dependencies as incomplete-view-visible/full-view-hidden, keeps ordinary dependencies full-view-visible, and preserves missing/ambiguous/overflow states for diagnostics. Coverage was added in `Test_Ada_Limited_With_Incomplete_View_Rules_Pass1023`.

### Pass1024 - private-with visibility constraints

Added `Editor.Ada_Private_With_Rules`, a deterministic lookup-facing projection
for private-with dependencies.  The model consumes cross-unit visibility
metadata, distinguishes visible-part/private-part/body lookup contexts, hides
private-with dependencies from ordinary visible-part lookup, exposes them in
private-part and body contexts, and retains missing/ambiguous/overflow cases as
explicit diagnostic metadata.  The regression
`Test_Ada_Private_With_Visibility_Constraints_Pass1024` covers the new counters,
context-sensitive lookup API, and fingerprinting behavior.

### Pass1026 - child-unit visibility from parent/private-child contexts

Pass1026 adds `Editor.Ada_Child_Unit_Visibility`, a deterministic cross-unit semantic projection over existing child-unit legality metadata. The model classifies public child visibility, private child hiding from external and parent visible-part lookup, private child visibility from parent private-part and body contexts, and missing/ambiguous/overflow/role-mismatch parent errors. It records parent and child unit names, paths, private-child classification, context visibility flags, candidate counts, and deterministic fingerprints for later lookup and diagnostics consumers.

This pass adds one compiler-grade building block for cross-unit child-unit visibility. Full compiler-grade Ada analysis remains incomplete until complete with/use visibility integration, private/limited view semantics, body/spec semantic conformance, separate-body/stub closure, overload/type resolution across units, and generic legality across unit boundaries are fully integrated.

Pass1027 adds Editor.Ada_Separate_Body_Stub_Rules, a cross-unit semantic projection that checks separate bodies against matching body stubs in resolved parent bodies and records deterministic placement metadata for matched, missing, ambiguous, mismatched, and parent-error cases.

### Pass1028 - freezing interactions for generics, private views, and bodies

Pass1028 adds `Editor.Ada_Freezing_Interactions`, a deterministic semantic projection over existing freezing-point, generic-contract, type-graph, and private-view models. The model records generic-instantiation freezing interactions, private partial/full-view freezing visibility, and body-context freezing metadata with stable counters and fingerprints for later representation-legality diagnostics.

This pass adds one compiler-grade building block for freezing and representation legality. Full compiler-grade Ada analysis remains incomplete until generic instance freezing, private/full-view representation legality, cross-unit representation target resolution, record layout validation, and aspect inheritance/overriding rules are fully integrated.

Pass1030 note: added Editor.Ada_Record_Layout_Validation as a compiler-grade record-layout validation building block. It derives deterministic bit-span metadata from record representation component clauses, detects overlapping component spans, preserves staged static/component errors, and exposes counters/fingerprints for diagnostics and future semantic-colouring projection. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as deeper alignment/size proof, overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

Pass1032 note: added Editor.Ada_Operational_Attribute_Rules as a compiler-grade operational representation building block. It consumes unified representation legality metadata after aspect/attribute-definition normalization, classifies duplicate operational properties, contradictory Boolean values, propagated target/value errors, and exposes deterministic counters/fingerprints for diagnostics and future semantic-colouring projection. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1033 - aspect inheritance and overriding rules

Pass1033 adds `Editor.Ada_Aspect_Inheritance_Rules`, a deterministic representation/aspect inheritance projection over unified representation-legality metadata and the Ada type graph. The model stages inherited representation and operational properties for derived types, distinguishes explicit overrides from contradictory explicit values, preserves private partial/full-view override metadata where the type graph exposes it, and exposes stable counters/fingerprints for diagnostics and semantic-colouring consumers. Regression coverage is in `Test_Ada_Aspect_Inheritance_Override_Rules_Pass1033`.

This pass adds one compiler-grade building block for aspect and representation legality. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1034 - Generic formal type conformance

Pass1034 adds `Editor.Ada_Generic_Formal_Type_Conformance`, a deterministic projection that checks generic formal type actuals against the existing generic-contract and type-graph models. The pass stages formal private, derived, interface, access, scalar/discrete, array, and record type-conformance metadata; preserves missing/unresolved actuals, category/base mismatches, private-view unknowns, and access designated-subtype unknowns; and exposes stable counters/fingerprints for diagnostics and semantic-colouring consumers. Regression coverage is in `Test_Ada_Generic_Formal_Type_Conformance_Pass1034`.

### Pass1035 - Generic formal package nested actual conformance

Pass1035 adds `Editor.Ada_Generic_Formal_Package_Nested_Conformance`, a deterministic projection over existing generic-contract metadata. The pass compares the nested actuals required by formal package declarations such as `with package P is new G (T, <>)` against the actual package instance supplied at an enclosing generic instantiation, preserving boxed actual compatibility, nested actual mismatches, missing nested actuals, wrong generic targets, unresolved actual package names, and unknown/malformed cases. Stable counters/fingerprints are exposed for diagnostics and semantic-colouring consumers. Regression coverage is in `Test_Ada_Generic_Formal_Package_Nested_Conformance_Pass1035`.

This pass adds one compiler-grade building block for generic formal package conformance. Full compiler-grade Ada analysis remains incomplete until generic renaming, nested generic instantiation visibility, formal object/default type compatibility, overload resolution, type checking, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1036 - Generic renaming and nested generic instantiation visibility

Pass1036 adds `Editor.Ada_Generic_Renaming_Visibility`, a deterministic projection over syntax-tree, declarative-region, direct-visibility, and generic-contract metadata. The model stages generic renaming declarations, resolves renamed generic targets where possible, preserves unresolved/ambiguous/non-generic/malformed target cases, and exposes generic instantiations that target renamed generics or appear in nested generic/body/block regions. Renamed instantiations are linked back to the original generic declaration and formal region when available, while direct nested instantiations are retained as separate contract users. Regression coverage is in `Test_Ada_Generic_Renaming_Nested_Visibility_Pass1036`.

### Pass1037 - Generic object default-expression type conformance

Pass1037 adds `Editor.Ada_Generic_Object_Default_Type_Conformance`, a deterministic semantic projection over generic-contract, static-expression, and type-graph metadata. The model checks formal-object defaults and explicit object actuals against the formal object's expected subtype instead of only classifying expressions as static or non-static. It records compatible defaults, compatible explicit actuals, type mismatches, static range errors, unknown static values, missing actual/default cases, unknown formal subtype cases, stable spans, counters, and fingerprints. Regression coverage is in `Test_Ada_Generic_Object_Default_Type_Conformance_Pass1037`.

Pass1039 update:
- Added Editor.Ada_Cross_Unit_Diagnostics to project cross-unit visibility and closure metadata into deterministic diagnostics.
- Covers missing/ambiguous dependencies, limited-view full-view restrictions, private-with visible-part restrictions, body/spec conformance failures, private-child visibility restrictions, child-parent errors, and separate-body stub/parent errors.
- Added Test_Ada_Cross_Unit_Diagnostics_Projection_Pass1039.

### Pass1040 - representation/freezing diagnostics projection

Pass1040 adds `Editor.Ada_Representation_Diagnostics`, a deterministic projection-only diagnostics layer over representation legality, record-layout validation, storage-order interaction rules, operational-attribute duplicate/conflict rules, aspect-inheritance rules, and freezing-interaction metadata. The model records stable diagnostic kind, severity, syntax node, related node, target/property names, source-line span, message, and fingerprint without parsing, file IO, buffer mutation, command registration, workspace mutation, or rendering work. Regression coverage is in `Test_Ada_Representation_Diagnostics_Projection_Pass1040`.

This pass adds one compiler-grade building block for representation/freezing diagnostics. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1041 - semantic-colouring diagnostics projection

Pass1041 adds `Editor.Ada_Semantic_Colour_Projection`, a projection-only bridge from parser-owned semantic diagnostics into render-safe semantic-colouring overlay entries. It consumes expression, generic-contract, cross-unit, and representation/freezing diagnostic models and preserves source family, severity, syntax node where available, stable source span, message, and deterministic fingerprint. Severity is mapped only to existing syntax buckets (`Diagnostic_Error`, `Diagnostic_Warning`, and informational `Identifier`), so rendering remains projection-only with no parsing, file IO, buffer mutation, command registration, workspace mutation, or render-side semantic work. Regression coverage is in `Test_Ada_Semantic_Colour_Diagnostics_Projection_Pass1041`.

### Pass1042 - semantic diagnostic snapshot guards

Pass1042 adds `Editor.Ada_Semantic_Diagnostic_Snapshot_Guards`, a deterministic projection gate for semantic diagnostics and semantic-colouring overlays. The guard attaches path, buffer token, buffer revision, lifecycle generation, request token, and analysis fingerprint metadata to parser-owned diagnostic projections and rejects stale overlays before they can be exposed to editor consumers. Rejected snapshots retain the rejection reason and withheld-entry count but expose no stale entries. Regression coverage is in `Test_Ada_Semantic_Diagnostic_Snapshot_Guards_Pass1042`.

This pass adds one compiler-grade building block for stale-analysis rejection in diagnostics and semantic colouring. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1043 - semantic diagnostics feed

Pass1043 adds `Editor.Ada_Semantic_Diagnostic_Feed`, a unified, snapshot-guarded feed for IDE-facing Ada semantic diagnostics. It consumes accepted output from `Editor.Ada_Semantic_Diagnostic_Snapshot_Guards` and preserves diagnostic source family, severity, token kind, stable span, message, and deterministic fingerprints behind one projection-only API. Rejected stale snapshots expose no entries while retaining withheld-entry counts. Regression coverage is in `Test_Ada_Semantic_Diagnostic_Feed_Pass1043`.

## Pass1044 — semantic diagnostic index/search API

Pass1044 adds `Editor.Ada_Semantic_Diagnostic_Index`, a deterministic IDE-facing index over the unified semantic diagnostic feed. The index consumes only `Editor.Ada_Semantic_Diagnostic_Feed` output and exposes bounded lookup by source-line range, source position, severity, semantic source family, token kind, and syntax node. Stale rejected feeds expose zero indexed entries while preserving rejected-entry totals and deterministic fingerprints. Regression coverage is in `Test_Ada_Semantic_Diagnostic_Index_Pass1044`.

### Pass1045 - Ada diagnostic navigation model

Pass1045 adds `Editor.Ada_Diagnostic_Navigation`, an IDE-facing navigation layer over `Editor.Ada_Semantic_Diagnostic_Index`. It provides deterministic first/last and next/previous diagnostic targets from source positions, including severity-filtered navigation for errors, warnings, and infos. Stale or rejected diagnostic indexes expose no navigation targets and preserve rejected-target counts. The pass keeps the diagnostic-navigation path projection-only: no parsing, file IO, dirty-state mutation, command registration, workspace mutation, or rendering-side semantic work is introduced.

This pass adds one compiler-grade building block for IDE-facing diagnostic navigation. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1046 - Ada diagnostic panel projection model

Pass1046 adds `Editor.Ada_Diagnostic_Panel_Projection`, an IDE-facing projection layer over `Editor.Ada_Semantic_Diagnostic_Index`. It converts snapshot-guarded semantic diagnostics into deterministic panel rows with stable row identity, source spans, severity, source family, token kind, syntax node, message payload, optional file/unit labels, grouping metadata, selected-row state, counters, and fingerprints. Rejected stale diagnostic indexes expose no panel rows while preserving rejected-row totals. The pass remains projection-only: no parsing, file IO, dirty-state mutation, command registration, workspace mutation, or rendering-side semantic work is introduced.

### Pass1047 - Ada diagnostic status-line summary model

Pass1047 adds `Editor.Ada_Diagnostic_Status_Line`, an IDE-facing status-line summary over `Editor.Ada_Semantic_Diagnostic_Index`. It summarizes snapshot-guarded semantic diagnostics into deterministic totals, highest-severity state, compact summary text, current-line/current-position counts, nearest diagnostic metadata, source-family counters, rejected-stale withholding, and fingerprints. The pass remains projection-only: no parsing, file IO, dirty-state mutation, command registration, workspace mutation, or rendering-side semantic work is introduced.


### Pass1048 - Ada diagnostic quick-fix skeleton model

Pass1048 adds `Editor.Ada_Diagnostic_Quick_Fix_Skeleton`, a projection-only quick-fix candidate model over `Editor.Ada_Semantic_Diagnostic_Index`. It exposes deterministic non-mutating action skeletons for each accepted guarded semantic diagnostic: navigation, explanation, and source-family review candidates. The model preserves diagnostic identity, spans, severity, source family, token kind, syntax node, message payload, rejected-stale withholding, candidate counters, and fingerprints. It does not apply edits, build text changes, parse, save, reload, mutate buffers, register commands, touch workspace state, or perform rendering-side semantic work.

### Pass1049 - Ada diagnostic provenance / explain model

Pass1049 adds `Editor.Ada_Diagnostic_Provenance`, a projection-only explain/provenance layer over `Editor.Ada_Semantic_Diagnostic_Index`. It preserves indexed diagnostic identity, source span, severity, source family, token kind, syntax node, message payload, source fingerprint, diagnostic fingerprint, and a deterministic source chain from semantic source through diagnostic projection, semantic-colour projection, snapshot guard, unified feed, and diagnostic index. Rejected stale indexes expose no provenance items while preserving rejected-item totals.

### Pass1050 - Ada diagnostic suppression / baseline metadata model

Pass1050 adds `Editor.Ada_Diagnostic_Suppression_Baseline`, a projection-only suppression and baseline metadata layer over `Editor.Ada_Semantic_Diagnostic_Index`. It records deterministic suppression/baseline rules, classifies accepted guarded diagnostics as active, suppressed, or baselined, preserves diagnostic identity, spans, severity, source family, token kind, syntax node, source/diagnostic fingerprints, rule reasons, rejected-stale withholding, counters, and fingerprints. It does not hide stale-result failures, mutate source buffers, apply edits, parse, save, reload, register commands, touch workspace state, or perform rendering-side semantic work.

### Pass1051 - Ada overload ambiguity diagnostics

Pass1051 adds `Editor.Ada_Overload_Ambiguity_Diagnostics`, a deterministic explanation layer over `Editor.Ada_Expression_Types` overload metadata. It classifies call, operator, and universal-numeric ambiguity causes into stable diagnostic-cause records with node identity, expression identity, severity, candidate counts, selected counts, compatible/mismatch/unknown counters, source spans, explanatory messages, and fingerprints. The pass does not perform new overload resolution and does not parse, touch files, mutate buffers, register commands, touch workspace state, or perform rendering-side semantic work. Regression coverage is in `Test_Ada_Overload_Ambiguity_Diagnostics_Pass1051`.

This pass adds one compiler-grade building block for overload ambiguity explanation. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1052 - Ada expression diagnostics overload-cause integration

Pass1052 extends `Editor.Ada_Expression_Diagnostics` with `Build_With_Overload_Causes`, allowing the richer overload ambiguity/candidate-rejection records from `Editor.Ada_Overload_Ambiguity_Diagnostics` to flow into the ordinary expression diagnostics projection. The integrated diagnostics preserve overload detail text, candidate/selected/compatible/mismatch/unknown counts, cause fingerprints, node identity, severity, source spans, and deterministic fingerprints while leaving the existing `Build` path unchanged for first-order expression diagnostics. Regression coverage is in `Test_Ada_Expression_Diagnostics_Overload_Cause_Integration_Pass1052`.

This pass adds one compiler-grade building block for overload diagnostics integration. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1053 - Ada cross-unit lookup integration

Pass1053 adds `Editor.Ada_Cross_Unit_Lookup_Integration`, a lookup-facing bridge from `Editor.Ada_Cross_Unit_Visibility` into deterministic name-resolution metadata. It records per-source-unit lookup entries for ordinary with visibility, context use-package visibility, limited incomplete views, private views, missing dependencies, ambiguous dependencies, and overflow conditions. It preserves source unit, lookup name, normalized name, target unit/path, with/use/limited/private flags, candidate counts, source fingerprints, and deterministic fingerprints. `Lookup_Name` and `Resolve_With_Local` give later direct/use/selected-name/type-expression consumers a stable local-first then cross-unit lookup path without file IO, buffer mutation, rendering-side parsing, or workspace/command mutation. Regression coverage is in `Test_Ada_Cross_Unit_Lookup_Integration_Pass1053`.

### Pass1054 - Ada selected-name cross-unit lookup consumer

Pass1054 extends `Editor.Ada_Selected_Name_Resolution` with cross-unit lookup consumer entry points. `Build_With_Cross_Unit` and `Resolve_Selected_With_Cross_Unit` preserve the existing local/direct/use selected-name resolution path, then consult `Editor.Ada_Cross_Unit_Lookup_Integration` only when the selected-name prefix is not locally visible. The selected-name metadata now records cross-unit lookup identity, status, target unit/path, and deterministic fingerprints for ordinary with-visible prefixes, context use-visible prefixes, limited incomplete views, private views, missing dependencies, ambiguity, and overflow cases. This keeps cross-unit visibility snapshot-owned and lookup-facing without rendering-side parsing, file IO, dirty-state mutation, command registration, workspace mutation, or renderer work. Regression coverage is in `Test_Ada_Selected_Name_Cross_Unit_Lookup_Consumer_Pass1054`.

### Pass1055 — Cross-unit selected-name expression inference

Pass1055 extends `Editor.Ada_Expression_Types` so expression inference can consume cross-unit selected-name metadata produced by `Editor.Ada_Selected_Name_Resolution.Build_With_Cross_Unit`.  The pass adds cross-unit selected-name statuses, target/selector/path metadata, deterministic counters, and expression-diagnostic integration for limited/private/unresolved cross-unit selected names.

This pass adds one compiler-grade building block for routing cross-unit visibility into expression/type consumers. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1056 — Ada view-aware compatibility integration

Pass1056 adds `Editor.Ada_View_Aware_Compatibility`, a deterministic semantic bridge that classifies private-view and limited-view compatibility barriers from already snapshot-owned expression and subtype-compatibility metadata. It consumes `Editor.Ada_Expression_Types` and `Editor.Ada_Subtype_Compatibility`, preserving expression identity, syntax node, selected-name identity/status, expected/actual subtype labels, cross-unit target/selector metadata, source span, and fingerprints. The model exposes compatible/private/limited/unresolved/incompatible/indeterminate counters plus lookup by expression, allowing later overload, expression, generic-contract, and diagnostic consumers to reason about private and limited view effects without parsing, file IO, buffer mutation, rendering-side semantic work, workspace mutation, or command registration. Regression coverage is in `Test_Ada_View_Aware_Compatibility_Pass1056`.
### Pass1057 — Ada expression diagnostics view-compatibility projection

Pass1057 extends `Editor.Ada_Expression_Diagnostics` with view-aware compatibility projection. It adds `Build_With_View_Compatibility` and `Build_With_Overload_Causes_And_View_Compatibility`, consuming `Editor.Ada_View_Aware_Compatibility` metadata and converting private-view, limited-view, cross-unit-private, cross-unit-unresolved, known-incompatible, and indeterminate compatibility barriers into deterministic expression diagnostics. Compatible view metadata remains non-diagnostic. The projection preserves expression/node identity, spans, expected/actual subtype labels, cross-unit target/selector detail, view status, source fingerprint, diagnostic fingerprint, and exposes counters for total view-aware diagnostics plus private, limited, and unresolved view diagnostics. Regression coverage is in `Test_Ada_Expression_Diagnostics_View_Compatibility_Pass1057`.


### Pass1058 — Ada generic view-aware compatibility

Pass1058 adds `Editor.Ada_Generic_View_Compatibility`, a deterministic bridge between generic object/default conformance and private/limited-view compatibility. Generic actual/default checks can now be classified as compatible, private-view barrier, limited-view barrier, cross-unit unresolved, ordinary object mismatch, object unknown, or no-view-metadata while preserving generic instance/formal identity, spans, expression text, view identity, cross-unit target/selector metadata, counters, and fingerprints. Regression coverage is in `Test_Ada_Generic_View_Compatibility_Pass1058`.

### Pass1059 — Generic contract diagnostics view-compatibility projection

Pass1059 extends `Editor.Ada_Generic_Contract_Diagnostics` with `Build_With_View_Compatibility`, projecting `Editor.Ada_Generic_View_Compatibility` private/limited/cross-unit generic actual/default barriers into the normal generic contract diagnostics model. Diagnostics now retain generic-view identity, status, fingerprint, detail text, stable spans, severity, source node, and deterministic counters for generic-view/private/limited/unresolved cases. Regression coverage is in `Test_Ada_Generic_Contract_Diagnostics_View_Compatibility_Pass1059`.

Pass1060 adds `Editor.Ada_Generic_Instantiated_Body_Analysis`, a deterministic instantiated-body analysis foundation that consumes generic contract metadata and generic view-compatibility results. Generic object actual/default substitutions are now projected into matching generic body contract contexts while preserving instance/formal identity, body-region identity, actual text, view-barrier status, cross-unit target/selector metadata, counters, and fingerprints. Regression coverage is in `Test_Ada_Generic_Instantiated_Body_Analysis_Pass1060`.

### Pass1061 — Generic instantiated-body diagnostics projection

Pass1061 extends `Editor.Ada_Generic_Contract_Diagnostics` with `Build_With_View_Compatibility_And_Body_Analysis`, projecting `Editor.Ada_Generic_Instantiated_Body_Analysis` substitution statuses into the normal generic contract diagnostics model. Diagnostics now cover instantiated-body private-view barriers, limited-view barriers, cross-unit unresolved substitutions, object mismatches, unknown substitutions, missing body contracts, and contract mismatches while preserving substitution identity, body contract identity, generic-view metadata, stable spans, detail text, severity, counters, and deterministic fingerprints. Regression coverage is in `Test_Ada_Generic_Contract_Diagnostics_Instantiated_Body_Pass1061`.

This pass adds one compiler-grade building block for generic instantiated-body diagnostic projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1062 — Nested body/spec declaration conformance

Pass1062 adds `Editor.Ada_Nested_Body_Spec_Conformance`, a deterministic semantic layer that compares direct nested declarations inside already-confirmed body/spec unit pairs. It consumes `Editor.Ada_Project_Index` and `Editor.Ada_Body_Spec_Conformance`, preserving unit identity, spec/body paths, symbol ids, declaration names, symbol kinds, profiles, spans, candidate counts, and fingerprints while classifying confirmed, missing, extra, ambiguous, kind-mismatch, profile-mismatch, profile-unknown, and nonconforming-unit-pair cases. Regression coverage is in `Test_Ada_Nested_Body_Spec_Conformance_Pass1062`.

This pass adds one compiler-grade building block for nested body/spec semantic conformance. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.


### Pass1063 — Nested body/spec diagnostics projection

Pass1063 extends `Editor.Ada_Cross_Unit_Diagnostics` with `Build_With_Nested`, projecting `Editor.Ada_Nested_Body_Spec_Conformance` results into the cross-unit diagnostics model. Diagnostics now cover nested missing body declarations, extra body declarations, ambiguous body declarations, kind/profile mismatches, profile-unknown cases, and nonconforming enclosing unit pairs while preserving nested conformance identity/status, declaration names, spans, severity, messages, counters, and deterministic fingerprints. The existing `Build` path remains unchanged for first-order cross-unit diagnostics. Regression coverage is in `Test_Ada_Cross_Unit_Diagnostics_Nested_Body_Spec_Pass1063`.

This pass adds one compiler-grade building block for nested body/spec diagnostic projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1064 — Selected-name representation target resolution

Pass1064 adds `Editor.Ada_Selected_Representation_Targets`, a deterministic representation-target consumer that combines `Editor.Ada_Cross_Unit_Representation_Targets` with `Editor.Ada_Selected_Name_Resolution`. Representation clauses whose targets are selected names now preserve selected-name identity/status, prefix/selector text, visible cross-unit target unit/path, candidate counts, classification counters, and deterministic fingerprints. The layer distinguishes local selected targets, cross-unit visible selected targets, use-visible selected targets, limited/private-view barriers, missing/ambiguous/overflow prefixes, selector errors, and non-selected targets without parsing, file IO, buffer mutation, command registration, workspace mutation, or rendering-side semantic work. Regression coverage is in `Test_Ada_Selected_Representation_Targets_Pass1064`.

### Pass1065 — Selected representation target diagnostics projection

Pass1065 extends `Editor.Ada_Representation_Diagnostics` with `Build_With_Selected_Targets`, projecting `Editor.Ada_Selected_Representation_Targets` results into the representation/freezing diagnostic model. Diagnostics now cover selected-name representation target limited/private-view barriers, missing/ambiguous/overflow prefixes, selector missing/ambiguous cases, and unresolved selected representation targets while preserving target text, selector text, source span, severity, message payload, selected-target fingerprint, and deterministic representation diagnostic fingerprints. The existing `Build` path remains unchanged for first-order representation diagnostics. Regression coverage is in `Test_Ada_Representation_Diagnostics_Selected_Targets_Pass1065`.

This pass adds one compiler-grade building block for selected-name-aware representation diagnostics. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1066 — Exact record layout size/alignment validation

Pass1066 adds `Editor.Ada_Record_Layout_Exact_Validation`, a deterministic record-layout validation layer that folds record component bit spans together with `Size` and `Alignment` representation clauses. It stages target summaries, exact-size checks, padded-size checks, size-exceeded errors, alignment compatibility, non-power-of-two alignment errors, target/static errors, component-error propagation, counters, lookup by target, and fingerprints. Regression coverage is in `Test_Ada_Record_Layout_Exact_Size_Alignment_Pass1066`.

This pass adds one compiler-grade building block for exact record representation layout validation. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1067 — Exact record layout diagnostics projection

Pass1067 extends `Editor.Ada_Representation_Diagnostics` with exact record-layout diagnostic projection. `Build_With_Exact_Layout` and `Build_With_Selected_Targets_And_Exact_Layout` consume `Editor.Ada_Record_Layout_Exact_Validation` and convert Size-clause exceeded cases, padded Size clauses, Alignment errors, and propagated component-layout errors into deterministic representation diagnostics while preserving target text, source spans, severity, messages, counters, and fingerprints. Regression coverage is in `Test_Ada_Representation_Diagnostics_Exact_Record_Layout_Pass1067`.

This pass adds one compiler-grade building block for exact record layout diagnostic projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

Pass1068: Added Editor.Ada_Stream_Attribute_Profile_Conformance for deterministic stream attribute target-type profile conformance and representation diagnostic projection. The pass checks stream handler presence, ambiguity, procedure/function mode, arity, Input result subtype, target errors, and unknown profile cases while preserving snapshot-owned metadata and stale-safe diagnostic invariants.
Pass1069: Added Editor.Ada_Generic_Formal_Package_Substitutions for deterministic per-nested-actual formal package substitution metadata and generic diagnostic projection. The pass expands formal package nested conformance checks into substituted, boxed, mismatch, missing, wrong-generic, unresolved, malformed, and unknown entries while preserving formal/instance identity, nested position, source spans, fingerprints, and projection-only editor invariants.

### Pass1070 — Dispatching-call legality diagnostics

Pass1070 adds `Editor.Ada_Dispatching_Call_Legality`, a deterministic legality layer over existing dispatching-call expression inference metadata. It classifies static binding, dynamic dispatch, primitive targets, controlling-result cases, unresolved targets, ambiguous targets, and unknown controlling operands/results while preserving expression identity, syntax node, controlling/result subtype metadata, source spans, counters, and fingerprints. `Editor.Ada_Expression_Diagnostics` now accepts dispatching legality metadata through `Build_With_Dispatching_Legality` and `Build_With_All_Semantic_Causes`, projecting unresolved/ambiguous/unknown dispatching legality barriers into the normal expression diagnostic model while keeping resolved cases as non-diagnostic metadata. Regression coverage is in `Test_Ada_Dispatching_Call_Legality_Pass1070`.

This pass adds one compiler-grade building block for dispatching-call legality diagnostics. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1071 — Overload ranking metadata

Pass1071 adds `Editor.Ada_Overload_Ranking`, a deterministic overload-ranking staging layer over expression type metadata and overload ambiguity causes. It classifies exact matches, implicit-conversion-ranked choices, universal-numeric tie-breaks, ambiguous-after-ranking cases, rejected candidate sets, and unknown ranking states while preserving expression identity, syntax node, candidate/rejection counts, source spans, source/cause fingerprints, and deterministic result fingerprints. `Editor.Ada_Expression_Diagnostics` now accepts ranking metadata through `Build_With_Overload_Ranking` and `Build_With_All_Semantic_Causes_And_Ranking`, projecting only rejected, ambiguous, or unknown ranking states as diagnostics while keeping successful ranking as non-mutating provenance metadata. Regression coverage is in `Test_Ada_Overload_Ranking_Pass1071`.

### Pass1072 — Overload ranking provenance/explain metadata

Pass1072 adds `Editor.Ada_Overload_Ranking_Provenance`, a deterministic projection-only provenance model that links overload-ranking decisions from `Editor.Ada_Overload_Ranking` to ranking diagnostics in `Editor.Ada_Expression_Diagnostics`. IDE explain/provenance consumers can now distinguish exact overload choices, implicit-conversion-ranked choices, universal numeric tie-breaks, ambiguous-after-ranking cases, no-ranked-candidate states, unknown ranking states, and unlinked ranking/diagnostic metadata while preserving syntax nodes, source spans, severity, candidate counters, ranking/diagnostic fingerprints, stage counters, and stable result fingerprints. The layer performs no parsing, file IO, buffer mutation, command registration, workspace mutation, rendering-side semantic work, or edit application.

This pass adds one compiler-grade building block for overload-ranking provenance and IDE explanation. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1073 — Unified diagnostic provenance with overload-ranking explanation

Pass1073 extends `Editor.Ada_Diagnostic_Provenance` with `Build_With_Overload_Ranking`, allowing the general IDE diagnostic explain/provenance model to consume `Editor.Ada_Overload_Ranking_Provenance`.  Matched expression diagnostics now gain overload-ranking explanation entries that preserve ranking provenance identity, outcome, candidate/selected/rejected/unknown counts, ranking fingerprint, diagnostic/index/feed identity, stable spans, source family, token kind, syntax node, source fingerprint, diagnostic fingerprint, chain summaries, and deterministic fingerprints.  Rejected/stale diagnostic indexes continue to expose no active provenance entries.

This pass adds one compiler-grade building block for unified IDE diagnostic provenance and overload-ranking explanation. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1074 — Quick-fix skeleton integration for overload-ranking explanation

Pass1074 extends `Editor.Ada_Diagnostic_Quick_Fix_Skeleton` with `Build_With_Overload_Ranking`, allowing projection-only quick-fix candidates to include structured overload-ranking explanation actions when `Editor.Ada_Overload_Ranking_Provenance` can be matched to an accepted semantic diagnostic.  The new action kind preserves overload-ranking provenance identity, ranking outcome, candidate/selected/rejected/unknown counts, ranking fingerprint, diagnostic identity, source span, severity, source family, token kind, syntax node, message payload, and deterministic fingerprints.  Successful exact/implicit/universal ranking and ambiguous/rejected/unknown ranking evidence remain non-mutating action skeletons only; no edits are produced or applied.

Regression coverage: `Test_Ada_Diagnostic_Quick_Fix_Overload_Ranking_Pass1074`.

### Pass1075 — Diagnostic action routing model

Pass1075 adds `Editor.Ada_Diagnostic_Action_Router`, a deterministic projection-only bridge across the quick-fix skeleton, diagnostic navigation, diagnostic panel projection, diagnostic provenance, and diagnostic status-line summary models.  It routes each non-mutating diagnostic action skeleton to available navigation targets, panel rows, provenance/explain items, and status-line nearest-target metadata while preserving diagnostic identity, source span, severity, source family, token kind, syntax node, labels/details, quick-fix fingerprints, target fingerprints, and deterministic route fingerprints.  Stale/rejected input models produce no active routes while preserving rejected-route totals.

Regression coverage: `Test_Ada_Diagnostic_Action_Router_Pass1075`.

This pass adds one compiler-grade building block for IDE-facing diagnostic action routing. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1076 — Diagnostic command projection model

Pass1076 adds `Editor.Ada_Diagnostic_Command_Projection`, a deterministic projection-only bridge from diagnostic action routes to command-facing descriptors.  The model consumes `Editor.Ada_Diagnostic_Action_Router` output and exposes stable command names, display labels, detail payloads, availability state, diagnostic identity, source span, severity, source family, token kind, syntax node, route fingerprints, and descriptor fingerprints.  It does not register commands, invoke commands, apply edits, parse, mutate buffers, save/reload files, touch workspace state, or perform rendering-side semantic work.  Stale/rejected action-route models produce no active command descriptors while preserving rejected-command totals.

Regression coverage: `Test_Ada_Diagnostic_Command_Projection_Pass1076`.

### Pass1077 — Diagnostic command palette projection model

Pass1077 adds `Editor.Ada_Diagnostic_Command_Palette_Projection`, a deterministic projection-only bridge from diagnostic command descriptors to command-palette-facing entries.  The model consumes `Editor.Ada_Diagnostic_Command_Projection` output and exposes stable palette entry identity, descriptor identity, diagnostic/feed/index identity, command kind, command name, title, subtitle, search text, sort key, availability state, source span, severity, source family, token kind, syntax node, descriptor fingerprints, and palette fingerprints.  It does not register command aliases, mutate keybindings, invoke commands, apply edits, parse, mutate buffers, save/reload files, touch workspace state, or perform rendering-side semantic work.  Stale/rejected command projections produce no active palette entries while preserving rejected-entry totals.

Regression coverage: `Test_Ada_Diagnostic_Command_Palette_Projection_Pass1077`.

### Pass1078 diagnostic keybinding hint projection

Pass1078 adds `Editor.Ada_Diagnostic_Keybinding_Hint_Projection`, consuming diagnostic command-palette projections and producing deterministic keybinding/invocation hint metadata. The layer is projection-only: it does not register commands, add aliases, mutate keybindings, invoke commands, apply edits, parse, save/reload files, mutate buffers, touch workspace state, or do rendering-side semantic work. Rejected/stale command-palette inputs expose zero active hints while retaining rejected-hint totals.

### Pass 1080 - Diagnostic render projection

Pass1080 adds `Editor.Ada_Diagnostic_Render_Projection`, a render-safe projection over diagnostic workspace/session metadata.  The model turns diagnostic UI state into immutable rows and badges for later rendering while preserving stable diagnostic identities, spans, severities, command kinds, selection state, display text, sort keys, and deterministic fingerprints.  It performs no rendering-side parsing, no command registration, no keybinding/workspace mutation, no edits, and no file save/reload.

### Pass1082 diagnostic recovery status projection

Pass1082 adds `Editor.Ada_Diagnostic_Recovery_Status`, a compact IDE-facing
status surface over diagnostic lifecycle recovery.  It classifies retained,
changed, missing, and rejected-stale diagnostic UI rows into headline/status
metadata, preserves stable diagnostic and projection identities, exposes summary
text and deterministic counters, and remains projection-only with no parsing,
rendering-side semantic work, command/keybinding/workspace mutation, edits, or
file save/reload.

### Pass1083 diagnostic recovery action projection

Pass1083 adds `Editor.Ada_Diagnostic_Recovery_Action_Projection`, a projection-only layer over diagnostic recovery/status rows.  It maps retained, changed, missing, and rejected-stale diagnostic UI lifecycle states into deterministic IDE-facing recovery action descriptors while preserving stable diagnostic identity, source spans, severity/source/token metadata, persistent keys, lifecycle/render/index identities, and fingerprints.  The model is intentionally non-mutating: it does not register or invoke commands, add aliases, mutate keybindings, mutate workspace/session state, parse, render, edit buffers, or save/reload files.

Pass1085 adds Editor.Ada_Diagnostic_Recovery_Command_Palette_Projection. The new layer consumes diagnostic recovery command descriptors and produces deterministic command-palette-facing recovery entries for retained, changed, missing, rejected-stale, and restore-selection diagnostic recovery actions. It remains projection-only: no command registration, aliases, keybinding mutation, command invocation, edits, parsing, buffer mutation, file save/reload, workspace/session mutation, or rendering-side semantic work.

### Pass1086 diagnostic recovery keybinding hint projection

Pass1086 adds `Editor.Ada_Diagnostic_Recovery_Keybinding_Hint_Projection`, consuming diagnostic recovery command-palette entries and producing deterministic keybinding/invocation hint metadata for recovery actions.  It covers review-status, navigate-retained, review-changed, review-missing, review-rejected-stale, and restore-selection-candidate commands while preserving diagnostic identity, lifecycle/render/index identity, source span, severity, recovery headline, persistent keys, availability state, and deterministic fingerprints.  The model remains projection-only: it does not register commands, add aliases, mutate keybindings, invoke commands, apply edits, parse, mutate buffers, save/reload files, touch workspace/session state, or perform rendering-side semantic work.

This pass adds one compiler-grade building block for keybinding-facing diagnostic recovery projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1088 diagnostic recovery render projection

Pass1088 adds `Editor.Ada_Diagnostic_Recovery_Render_Projection`, consuming diagnostic recovery workspace/session metadata and producing immutable render-safe recovery rows and badges.  It preserves diagnostic identity, recovery workspace identity, source spans, severity/source/token metadata, command and binding state, selection state, recovery headline, lifecycle row status, persistent keys, display/sort payloads, previous/current diagnostic fingerprints, and deterministic model fingerprints.  The layer remains projection-only: it does not render, parse, perform rendering-side semantic work, register commands, add aliases, mutate keybindings, invoke commands, edit buffers, save/reload files, or mutate workspace/session state.

This pass adds one compiler-grade building block for render-safe diagnostic recovery projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1089 diagnostic recovery render lifecycle validation

Pass1089 adds `Editor.Ada_Diagnostic_Recovery_Render_Lifecycle`, consuming immutable diagnostic recovery render rows and a fresh snapshot-guarded semantic diagnostic index.  It validates recovery render UI state by classifying rows as retained, changed, missing, or rejected stale while preserving recovery row identity, source spans, severity/source/token metadata, recovery headline, source lifecycle status, badges, persistent keys, previous/current diagnostic fingerprints, and deterministic lifecycle fingerprints.  The layer remains projection-only and validation-only: it does not render, parse, perform rendering-side semantic work, register commands, add aliases, mutate keybindings, invoke commands, edit buffers, save/reload files, or mutate workspace/session state.

### Pass1091 diagnostic recovery render action projection

Pass1091 adds `Editor.Ada_Diagnostic_Recovery_Render_Action_Projection`, a projection-only layer that consumes compact recovery-render status rows and exposes deterministic non-mutating IDE action descriptors for retained, changed, missing, stale, and restore-candidate recovery-render UI states.  The model preserves recovery render lifecycle/render/status identities, diagnostic/feed/index identity, source spans, severity, source family, token kind, syntax node, recovery headline, lifecycle row status, render row kind, render badges, stable diagnostic/action keys, previous/current diagnostic fingerprints, and deterministic action fingerprints.

The pass adds `Test_Ada_Diagnostic_Recovery_Render_Action_Projection_Pass1091` and keeps the diagnostic recovery render action surface free of command registration, command aliases, command invocation, keybinding mutation, workspace/session mutation, edits, parsing, buffer mutation, file save/reload, and rendering-side semantic work.

### Pass1092 diagnostic recovery-render command projection

Pass1092 adds `Editor.Ada_Diagnostic_Recovery_Render_Command_Projection`, consuming recovery-render action descriptors and producing deterministic command-facing descriptors for retained, changed, missing, stale, and restore-candidate recovery-render UI states.  The model preserves diagnostic identity, recovery render status/lifecycle/render identities, feed/index identity, source spans, severity/source/token metadata, recovery headline/source headline, lifecycle status, render badges, persistent keys, command names, availability state, previous/current diagnostic fingerprints, recovery-render action fingerprints, and deterministic command descriptor fingerprints.

The layer remains projection-only: it does not register commands, add aliases, invoke commands, mutate keybindings, mutate workspace/session state, apply edits, parse, mutate buffers, save/reload files, render, or perform rendering-side semantic work.

Regression coverage: `Test_Ada_Diagnostic_Recovery_Render_Command_Projection_Pass1092`.

This pass adds one compiler-grade building block for command-facing diagnostic recovery-render projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1093 diagnostic recovery-render command palette projection

Pass1093 adds `Editor.Ada_Diagnostic_Recovery_Render_Command_Palette_Projection`, consuming recovery-render command descriptors and producing deterministic command-palette-facing entries for retained, changed, missing, stale, and restore-candidate recovery-render UI states. The projection preserves diagnostic identity, recovery-render command/action/status/lifecycle/render identities, source spans, severity/source/token metadata, recovery headline, lifecycle status, command kind, availability state, command name, title/subtitle/search/sort payloads, persistent diagnostic/action keys, previous/current diagnostic fingerprints, descriptor fingerprints, and deterministic palette-entry fingerprints.

The layer remains projection-only: it does not register commands, add aliases, invoke commands, mutate keybindings, mutate workspace/session state, apply edits, parse, mutate buffers, save/reload files, render, or perform rendering-side semantic work.

Regression coverage: `Test_Ada_Diagnostic_Recovery_Render_Command_Palette_Projection_Pass1093`.

This pass adds one compiler-grade building block for command-palette-facing diagnostic recovery-render projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1094 diagnostic recovery-render keybinding hint projection

Pass1094 adds `Editor.Ada_Diagnostic_Recovery_Render_Keybinding_Hint_Projection`, consuming recovery-render command-palette entries and producing deterministic keybinding/invocation hint metadata for retained, changed, missing, stale, and restore-candidate recovery-render UI actions. The projection preserves diagnostic identity, recovery-render command/action/status/lifecycle/render identities, source spans, severity/source/token metadata, recovery headline, lifecycle status, command kind, availability state, persistent diagnostic/action keys, previous/current diagnostic fingerprints, palette-entry fingerprints, binding-state metadata, and deterministic hint fingerprints.

The layer remains projection-only: it does not register commands, add aliases, invoke commands, mutate keybindings, mutate workspace/session state, apply edits, parse, mutate buffers, save/reload files, render, or perform rendering-side semantic work.

Regression coverage: `Test_Ada_Diagnostic_Recovery_Render_Keybinding_Hint_Projection_Pass1094`.

This pass adds one compiler-grade building block for keybinding-facing diagnostic recovery-render projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1095 diagnostic recovery-render workspace projection

Pass1095 adds `Editor.Ada_Diagnostic_Recovery_Render_Workspace_Projection`, consuming recovery-render keybinding hints and producing deterministic workspace/session-facing UI state descriptors for retained, changed, missing, stale, and restore-candidate recovery-render actions. The projection preserves diagnostic identity, recovery-render hint/palette/command/action/status/lifecycle/render identities, source spans, severity/source/token metadata, recovery headline, lifecycle status, command kind, binding state, persistent diagnostic/action/command keys, previous/current diagnostic fingerprints, hint fingerprints, selected/restore-candidate metadata, and deterministic workspace fingerprints.

The layer remains projection-only: it does not persist workspace state, mutate workspace/session records, register commands, create aliases, mutate keybindings, invoke commands, apply edits, parse, save/reload files, mutate buffers, render, or perform rendering-side semantic work. Persistable keys are derived from stable diagnostic recovery-render metadata and never expose buffer-internal identifiers.

Regression coverage: `Test_Ada_Diagnostic_Recovery_Render_Workspace_Projection_Pass1095`.

Pass1096 update:
- Added Editor.Ada_Diagnostic_Recovery_Render_Final_Projection.
- Consumes Editor.Ada_Diagnostic_Recovery_Render_Workspace_Projection.
- Projects recovery-render workspace/session state into immutable final draw-facing rows and badges.
- Preserves diagnostic/feed/index identity, stable spans, severity, semantic source family, token kind, syntax node, command kind, binding/selection state, recovery headline, lifecycle row status, persistable diagnostic/action keys, previous/current diagnostic fingerprints, and deterministic row/model fingerprints.
- Keeps the layer projection-only: no rendering, command registration, aliases, keybinding mutation, command invocation, edits, parsing, buffer mutation, file save/reload, workspace/session mutation, or rendering-side semantic work.
- Added Test_Ada_Diagnostic_Recovery_Render_Final_Projection_Pass1096.

Pass1097 adds Editor.Ada_Diagnostic_Recovery_Render_Final_Lifecycle, a projection-only lifecycle validator for final render-safe diagnostic recovery-render rows. It compares final UI rows against a fresh snapshot-guarded semantic diagnostic index, classifies rows as retained, changed, missing, or rejected stale, and preserves stable diagnostic identity, recovery headline, lifecycle metadata, badges, persistent keys, and deterministic fingerprints without parsing, rendering-side semantic work, command registration, keybinding/workspace mutation, edits, buffer mutation, or file save/reload.

### Pass1098 final diagnostic recovery-render lifecycle status projection

Pass1098 adds `Editor.Ada_Diagnostic_Recovery_Render_Final_Status`, consuming `Editor.Ada_Diagnostic_Recovery_Render_Final_Lifecycle` and projecting final render lifecycle rows into a compact IDE-facing final recovery-render status surface. It classifies final lifecycle state as clean, retained, changed, missing, or rejected stale; preserves diagnostic identity, final lifecycle identity, final render row identity, feed/index identity, source spans, severity, semantic source family, token kind, syntax node, final render row kind, recovery headline, source lifecycle status, source render row kind, badges, persistent diagnostic/action keys, previous/current diagnostic fingerprints, final lifecycle fingerprints, and deterministic status fingerprints; and exposes lookup/count helpers for diagnostics, status, headline, final row kind, and source lifecycle status.

Rejected/stale final lifecycle inputs expose zero active status rows while preserving rejected-row totals and deterministic fingerprints. The layer remains projection-only: no parsing, rendering-side semantic work, command registration, command aliases, command invocation, keybinding mutation, workspace/session mutation, edits, buffer mutation, dirty-state mutation, rendering, or file save/reload is introduced.

Regression coverage: `Test_Ada_Diagnostic_Recovery_Render_Final_Status_Pass1098`.

This pass adds one compiler-grade building block for final diagnostic recovery-render lifecycle status projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Phase 579 Pass1099

Pass1099 adds `Editor.Ada_Assignment_Legality`, a compiler-grade semantic building block for Ada assignment and object-initialization legality.  It classifies compatible assignments, class-wide assignments, static range checks, incompatible subtypes, unresolved target/source metadata, private/limited view barriers, assignment to constants, assignment to in-mode formals, null-exclusion violations, static range violations, unresolved universal numeric assignments, and indeterminate cases.  The pass includes `Test_Ada_Assignment_Legality_Pass1099` and deliberately avoids adding another diagnostic projection or render lifecycle layer.

### Phase 579 Pass1100

Pass1100 adds `Editor.Ada_Return_Legality`, a compiler-grade semantic building block for Ada return statement legality. It consumes `Editor.Ada_Assignment_Legality` and classifies procedure returns, function result returns, extended return objects, illegal procedure return expressions, missing function return expressions, result subtype incompatibility, class-wide result incompatibility, private/limited view barriers, cross-unit unresolved views, unresolved target/source result metadata, static range violations, unresolved universal numeric returns, No_Return subprogram return statements, and indeterminate cases.

The pass adds `Test_Ada_Return_Legality_Pass1100` and registers the Pass1099 and Pass1100 semantic regressions in `Core_Suite` where that suite is the AUnit entry point. It deliberately continues the semantic roadmap instead of adding another diagnostic projection or render lifecycle layer.

Pass1101 note: widened the semantic pass scope by adding `Editor.Ada_Conversion_Access_Aggregate_Legality`, a snapshot-owned semantic legality layer covering conversion and qualified-expression legality, numeric/static range conversion checks, tagged/class-wide conversion classification, access/null-exclusion/accessibility foundations, allocator designated-subtype compatibility, aggregate structural legality, and container aggregate missing-aspect classification. Added `Test_Ada_Conversion_Access_Aggregate_Legality_Pass1101` and registered it in `Core_Suite`. No diagnostic UI projection chain layer, rendering-side parsing, file save/reload, dirty-state mutation, command/keybinding/workspace mutation, or render mutation is introduced.

## Pass1102 - Ada control-flow and statement legality

Pass1102 adds `Editor.Ada_Control_Flow_Legality`, a wider semantic-progress
pass that checks Ada statement/control-flow legality above expression,
assignment, conversion/access/aggregate, and return legality.  It covers
Boolean-only conditions, case expression/choice staticness and coverage,
exit/goto/label target legality, exception handler choices, raise targets,
select/accept/requeue target checks, and subprogram return-path completeness.
The package is deterministic, bounded, fixture-friendly, and snapshot-owned.

## Pass1103 - Ada tasking/protected semantic legality

Pass1103 adds `Editor.Ada_Tasking_Protected_Legality`, a wider semantic-progress pass that checks Ada tasking and protected-object legality above the statement-flow layer. It covers task/protected type and body spec/body matching, duplicate and missing bodies, kind/profile conformance metadata, entry declaration/body resolution, entry family index resolution/compatibility/staticness, protected entry barrier presence and Boolean legality, accept statement placement/profile checks, requeue target legality, protected function/procedure restrictions, protected private-data resolution metadata, select alternative legality, and linked `Editor.Ada_Control_Flow_Legality` error propagation.

The pass adds `Test_Ada_Tasking_Protected_Legality_Pass1103` and registers it in `tests/src/core_suite.adb`. It deliberately avoids adding another projection/status/render lifecycle layer and instead adds a compiler-grade semantic building block while preserving deterministic, bounded, snapshot-owned analysis and the no-mutation editor invariants.

Pass1104 update: added `Editor.Ada_Tagged_Derived_Legality`, a snapshot-owned semantic legality layer for tagged derivation, private extensions, interface derivation, inherited primitive conflicts, overriding conformance, abstract-operation requirements, dispatching-call legality propagation, class-wide conversion compatibility, and linked assignment/return semantic error propagation. Added and registered `Test_Ada_Tagged_Derived_Legality_Pass1104`. No diagnostic projection chain, rendering-side parsing, file save/reload, dirty-state mutation, or command/keybinding/workspace/render mutation is introduced.

### Phase 579 Pass1105

Pass1105 adds `Editor.Ada_Generic_Instance_Freezing_Representation_Legality`, a widened snapshot-owned semantic legality layer that connects generic instantiated-body substitution metadata, formal-package substitution metadata, generic-instance freezing effects, representation-item legality, and linked assignment/return/conversion/tagged semantic failures. The package classifies legal body/default/formal-package substitutions, private/limited/cross-unit body barriers, object mismatches, missing body contracts, formal-package missing/mismatch/wrong-generic/unresolved/malformed cases, instance freezing effects, representation after instance freezing, representation target/static/profile/operational errors, and linked semantic legality errors from the wider pass1099-pass1104 legality layers.

The pass adds and registers `Test_Ada_Generic_Instance_Freezing_Representation_Legality_Pass1105`. It continues the semantic rule-completion roadmap and does not add another diagnostic UI projection chain, rendering-side parser, file save/reload path, dirty-state mutation, command/keybinding/workspace mutation, render mutation, compiler invocation, LSP bridge, external parser generator, Python integration, or shell-script integration.

### Phase 579 Pass1106

Pass1106 adds `Editor.Ada_Cross_Unit_Semantic_Closure`, a widened snapshot-owned semantic closure layer that connects cross-unit dependency and lookup state into the assignment, return, expression/conversion/access/aggregate, control-flow, tasking/protected, tagged/derived, generic-instance, and representation legality layers. The package classifies closed/local/with-visible/use-visible semantic contexts, limited/private view barriers, missing/ambiguous/overflow dependencies, missing/ambiguous/overflow lookups, and linked semantic errors from the widened pass1099-pass1105 legality layers.

The pass adds and registers `Test_Ada_Cross_Unit_Semantic_Closure_Pass1106`. It continues the semantic rule-completion roadmap and does not add another diagnostic UI projection chain, rendering-side parser, file save/reload path, dirty-state mutation, command/keybinding/workspace mutation, render mutation, compiler invocation, LSP bridge, external parser generator, Python integration, or shell-script integration.

Pass1107: added Editor.Ada_Wide_Semantic_Legality_Diagnostics, a wide semantic diagnostic bridge for assignment, return, conversion/access/aggregate, control-flow, tasking/protected, tagged/derived, generic-instance/freezing/representation, and cross-unit semantic closure legality results.

Pass1108 update:
- Integrated the Pass1107 wide semantic legality diagnostics into the unified snapshot-guarded semantic diagnostic feed via Build_With_Wide_Legality.
- Wide assignment, return, conversion/access/aggregate, control-flow, tasking/protected, tagged/derived, generic-instance, and cross-unit legality failures now participate in the normal diagnostic feed and index.
- Stale wide legality inputs and rejected base semantic guards expose zero active feed rows while preserving rejected-entry accounting.
- Added AUnit coverage in Test_Ada_Wide_Semantic_Diagnostic_Feed_Integration_Pass1108 and registered it in Core_Suite.

### Phase 579 Pass1110

Pass1110 adds `Editor.Ada_Staticness_Range_Predicate_Legality`, a widened snapshot-owned semantic legality layer for Ada staticness requirements, range/choice legality, subtype predicate metadata, and linked legality outcomes from assignment, return, conversion/access/aggregate, and overload resolution. It classifies static range compatibility, static discrete choice compatibility, static constraint compatibility, dynamic/static predicate cases, required-static-expression failures, non-static/unresolved/malformed static expressions, static division by zero, static binding cycles, unsupported static attributes, range violations, null ranges, out-of-range choices, duplicate static choices, choice coverage gaps, static predicate failures, unresolved predicates, non-static predicates where staticness is required, linked semantic errors, unresolved universal numeric cases, and indeterminate static legality.

The pass adds and registers `Test_Ada_Staticness_Range_Predicate_Legality_Pass1110`. It continues the semantic rule-completion roadmap and does not add another diagnostic UI projection chain, rendering-side parser, file save/reload path, dirty-state mutation, command/keybinding/workspace mutation, render mutation, compiler invocation, LSP bridge, external parser generator, Python integration, or shell-script integration.

### Phase 579 Pass1111

Pass1111 adds `Editor.Ada_Accessibility_Lifetime_Legality`, a widened snapshot-owned semantic legality layer for Ada accessibility, lifetime, null-exclusion, access-kind, aliased-object, allocator, access conversion, access discriminant, anonymous access parameter, return-accessibility, and dangling-renaming rules. It also links assignment, return, conversion/access/aggregate, and staticness/range/predicate failures into a single access-focused legality model.

The pass adds and registers `Test_Ada_Accessibility_Lifetime_Legality_Pass1111`. It continues the semantic rule-completion roadmap and does not add another diagnostic UI projection chain, rendering-side parser, file save/reload path, dirty-state mutation, command/keybinding/workspace mutation, render mutation, compiler invocation, LSP bridge, external parser generator, Python integration, or shell-script integration.


Pass1112 adds Editor.Ada_Contract_Aspect_Legality, a widened semantic legality layer for Ada contracts and aspects: pre/postconditions, invariants, predicates, assertions, contract cases, Global/Depends/refined flow aspects, aspect placement/duplicate checks, view barriers, cross-unit barriers, and linked assignment/return/staticness/accessibility/overload/cross-unit legality failures.


### Pass1113

Adds `Editor.Ada_Elaboration_Dependence_Legality`, a widened semantic layer for Ada elaboration-order and dependence legality. It covers elaboration pragmas/policies, body-before-use, call/access-before-elaboration, circular dependencies, generic instance elaboration effects, and linked cross-unit/contract/overload blockers.


Pass1114: Added Editor.Ada_Unit_Completion_Order_Legality for compiler-grade unit/body completion and declaration-order legality, including package/subprogram/task/protected/generic body completion, private/deferred/incomplete completion, body-stub/separate-body completion, declaration-before-use, private-part ordering, frozen-before-completion, view barriers, and linked semantic blockers. Added AUnit coverage and deterministic counters/lookups/fingerprints.

Pass1115: Added `Editor.Ada_Renaming_Alias_Visibility_Legality`, a widened semantic legality layer for Ada renaming declarations, alias views, direct/use/use-type visibility, selected-name alias targets, and related cross-unit/private/limited-view blockers. It covers object, exception, package, subprogram, generic package, generic subprogram, formal object, use package, use type, selected-name, and alias-view contexts; target presence/ambiguity/overflow; kind/profile/generic-profile/subtype mismatches; self/circular renaming; constant-as-variable renaming; aliased-target requirements; dangling rename risks; hidden homographs; duplicate/invalid use clauses; and linked accessibility, overload, cross-unit, and completion/order legality failures. Added AUnit coverage and deterministic counters/lookups/fingerprints.

Pass1116 update: added Editor.Ada_Exception_Finalization_Legality as a widened semantic legality layer for Ada exception, raise, handler, propagation, cleanup/finalization, task termination, controlled primitive, and No_Return contexts. It consumes control-flow, accessibility/lifetime, contract/aspect, elaboration/dependence, renaming/visibility, and unit completion/order legality metadata; classifies legal raise/reraise/handler/renaming/propagation/finalization/No_Return cases; and reports unresolved/ambiguous/non-exception raise targets, reraise outside handlers, handler choice errors, raise-expression result issues, invalid exception renaming targets, controlled finalization primitive/profile/order/propagation/abort/master errors, No_Return violations, private/limited view barriers, and linked semantic blockers. Added and registered Test_Ada_Exception_Finalization_Legality_Pass1116. The pass remains snapshot-owned, deterministic, bounded, and non-mutating.

Pass1117 update: added Editor.Ada_Representation_Layout_Stream_Integration_Legality. The pass integrates representation legality, exact record layout, stream attribute profile conformance, generic-instance freezing/representation effects, accessibility/lifetime, staticness/range/predicate, completion/order, contract/aspect, and exception/finalization legality into one deterministic snapshot-owned semantic model. It adds Test_Ada_Representation_Layout_Stream_Integration_Legality_Pass1117 and keeps the analysis non-mutating, bounded, and independent of rendering, command, keybinding, workspace, save/reload, file IO, compiler invocation, LSP, and external parser generators.

Pass1118 update: added Editor.Ada_Integrated_Semantic_Closure as a widened semantic closure layer. It folds wide semantic legality diagnostics with overload, staticness/range/predicate, accessibility/lifetime, contract/aspect, elaboration/dependence, unit completion/order, renaming/alias/visibility, exception/finalization, and representation/layout/stream integration blockers into one deterministic snapshot-owned closure model. It classifies local/cross-unit/with-use legal closure, limited/private-view barriers, missing/ambiguous/overflow/stale/rejected dependencies, individual legality blockers, multiple blockers, and indeterminate closure. Added and registered Test_Ada_Integrated_Semantic_Closure_Pass1118 with counters, lookups, and fingerprints. The pass remains non-mutating and introduces no rendering-side parser, save/reload path, dirty-state mutation, command/keybinding/workspace/render mutation, compiler invocation, LSP bridge, external parser generator, Python integration, or shell-script integration.

Pass1119 update:
- Integrated semantic closure diagnostics now flow into the unified snapshot-guarded semantic diagnostic feed through Build_With_Integrated_Closure.
- Non-legal integrated closure rows become indexed semantic diagnostics; legal closure rows remain non-diagnostic.
- Stale integrated closure inputs and rejected base diagnostic guards expose zero active rows while preserving rejected-entry totals.
- This is a semantic integration pass, not a UI projection-chain extension.

Pass1120 update: extended `Editor.Ada_Diagnostic_Provenance` with integrated semantic closure provenance. The pass adds `Diagnostic_Provenance_Integrated_Closure`, `Build_With_Integrated_Closure`, integrated closure status/blocker/dependency metadata on provenance items, deterministic stage counting, and AUnit coverage in `Test_Ada_Diagnostic_Provenance_Integrated_Closure_Pass1120`. Integrated semantic closure diagnostics produced by the unified feed/index can now be explained back to their consolidated closure rows without adding parsing, file IO, compiler invocation, or UI mutation.

### Pass1121 — Definite initialization / flow legality

Pass1121 adds `Editor.Ada_Definite_Initialization_Flow_Legality`, a widened semantic legality layer for definite initialization, read-before-write, component initialization, out-parameter assignment, return-object initialization, branch/loop merge proof failures, exception/finalization initialization effects, use-after-finalization metadata, and linked legality blockers from the assignment, return, control-flow, exception/finalization, and integrated-closure layers. The AUnit regression is `Test_Ada_Definite_Initialization_Flow_Legality_Pass1121`, registered in `tests/src/core_suite.adb`.

## Pass1122

Pass1122 integrates definite-initialization and flow-sensitive object-state legality into the integrated Ada semantic closure path. Initialization errors are now first-class closure blockers and therefore flow through the existing unified semantic diagnostic feed, diagnostic index, and diagnostic provenance path without adding another UI-only projection layer.

## Pass1123

Pass1123 adds `Editor.Ada_Dataflow_Global_Depends_Legality` for Global/Depends dataflow legality. The new layer connects contract-aspect flow facts with definite-initialization object-state facts, enforcing Global read/write modes, null Global restrictions, Depends source/target mode consistency, duplicate/cyclic/unresolved dependency metadata, and initialization-before-read / out-parameter / use-after-finalization effects.

The pass also adds dataflow as a first-class integrated semantic closure blocker through `Closure_Blocker_Dataflow`, `Integrated_Closure_Dataflow_Blocker`, and `Editor.Ada_Integrated_Semantic_Closure.Dataflow`. Dataflow failures now flow into the existing semantic diagnostic feed, diagnostic index, and provenance path without adding another UI-only projection layer. Regression: `Test_Ada_Dataflow_Global_Depends_Legality_Pass1123`.

### Pass1124

Pass1124 adds `Editor.Ada_Predicate_Invariant_Use_Site_Legality`, connecting predicate/staticness and invariant metadata to assignment, return, conversion, aggregate, call/default, and generic-actual use sites with deterministic counters, lookups, and fingerprints.

Pass1125 note: added Editor.Ada_Generic_Instance_Body_Semantic_Expansion, connecting instantiated generic body actual/formal substitutions to overload, accessibility/lifetime, contract/aspect, Global/Depends dataflow, definite-initialization, predicate/invariant, and representation/layout/stream legality.  This is a semantic integration pass, not a diagnostic or UI projection pass.

### Pass1125

Pass1125 adds `Editor.Ada_Generic_Instance_Body_Semantic_Expansion`, connecting instantiated generic body actual/formal substitutions to overload, accessibility/lifetime, contract/aspect, Global/Depends dataflow, definite-initialization, predicate/invariant use-site, and representation/layout/stream legality with deterministic blocker counts, lookups, and fingerprints.

### Pass1126

Pass1126 adds `Editor.Ada_Overload_Preference_Legality`, a widened semantic legality layer that deepens overload resolution with Ada-specific preference ordering. It consumes existing overload legality rows and preference contexts, then classifies direct/use visibility preferences, exact profile evidence, expected-type/profile preference, primitive and dispatching primitive preferences, universal integer/real preferences, implicit/class-wide/access conversion preferences, named actual/profile preference, defaulted-formal preference, and distinct ambiguity classes for homograph, visibility, profile, expected-type, universal numeric, conversion, and remaining RM-preference ties. Regression: `Test_Ada_Overload_Preference_Legality_Pass1126`.

Pass1127 note: added Editor.Ada_Record_Variant_Aggregate_Legality to connect aggregate structural legality, discriminant constraints, variant coverage, predicate/invariant use-site checks, and representation/layout integration into deterministic record/variant aggregate semantic closure.
Pass1128 note: added Editor.Ada_Accessibility_Precision_Legality to deepen accessibility/lifetime precision across nested access levels, anonymous access parameters, allocator masters, access discriminants, return accessibility, generic actual lifetime substitution, and aggregate discriminant contexts.

### Pass1129 - Elaboration precision legality

Pass1129 adds `Editor.Ada_Elaboration_Precision_Legality`, a widened semantic pass that connects elaboration-order graph closure, generic-instance elaboration, body-before-use, `Elaborate_All` / `Elaborate_Body`, preelaboration/purity restrictions, Global/Depends dataflow, overload preference, and accessibility precision into one deterministic elaboration legality model. It is snapshot-owned and projection-free.

### Pass1130 - Tasking/protected precision legality

Pass1130 adds `Editor.Ada_Tasking_Protected_Precision_Legality`, a widened semantic legality package that connects protected-state effects, entry barriers, accept/requeue/select flow, queued entry-call accessibility, and task activation/elaboration precision into deterministic tasking/protected legality rows. It includes `Test_Ada_Tasking_Protected_Precision_Legality_Pass1130`.

### Pass1131 - Representation/freezing precision legality

Pass1131 adds `Editor.Ada_Representation_Freezing_Precision_Legality`, a widened semantic legality layer that connects representation clauses/aspects, implicit semantic-use freezing, private/full-view timing, generic-instance freezing effects, representation/layout/stream integration, elaboration precision, and tasking/protected precision.  It adds deterministic legality rows, lookups, counters, and fingerprints, with AUnit regression coverage in `Test_Ada_Representation_Freezing_Precision_Legality_Pass1131`.

### Pass1132 parser/AST semantic coverage audit

Pass1132 adds `Editor.Ada_AST_Semantic_Coverage_Audit`, a deterministic snapshot-owned audit for Ada 2022 grammar-to-semantic coverage. It records whether constructs have parser nodes, structural AST shape, spans, binding/type/staticness/contract/flow/representation/cross-unit metadata, and integrated semantic consumers before widened legality layers rely on them.

### Pass1133 - AST coverage integrated closure blockers

Pass1133 adds `Editor.Ada_Integrated_Semantic_Closure.AST_Coverage`, which converts Pass1132 parser/AST semantic coverage audit rows into integrated semantic closure rows. Parser-node gaps, token-only parses, structural AST gaps, source-span gaps, binding/type/staticness/contract/flow/representation/cross-unit metadata gaps, missing consumers, non-integrated consumers, and graceful-degradation-only coverage now become first-class closure blockers through `Closure_Blocker_AST_Coverage` and `Integrated_Closure_AST_Coverage_Blocker`. Cross-unit metadata gaps are preserved as dependency failures. Regression: `Test_Ada_Integrated_Closure_AST_Coverage_Pass1133`.

### Pass1134 - Semantic coverage gates

Pass1134 adds `Editor.Ada_Semantic_Coverage_Gates`, a semantic safety layer that consumes parser/AST semantic coverage audit rows and decides whether downstream Ada legality conclusions are safe to treat as confident results. Complete grammar-to-semantic coverage opens the gate. Parser-node gaps, token-only parses, structural AST gaps, span gaps, missing binding/type/staticness/contract/flow/representation metadata, cross-unit metadata gaps, missing or non-integrated consumers, graceful-degradation-only coverage, and indeterminate coverage now produce explicit gating actions: degrade to indeterminate, suppress legal/derived results, require cross-unit closure, require parser/AST repair, require semantic metadata repair, require consumer integration, or block unsafe results. Regression: `Test_Ada_Semantic_Coverage_Gates_Pass1134`.


Pass1135: Integrated semantic closure coverage gates wire Pass1134 semantic coverage gates into integrated closure. Unsafe confident conclusions caused by parser/AST, metadata, consumer-integration, graceful-degradation, or cross-unit coverage gaps now become closure blockers, dependency failures, or indeterminate closure rows.


Pass1136: Added coverage-gated semantic result integration so semantic coverage gates preserve the original widened legality conclusion family, consumer, source row, gate reason, and fingerprint through integrated closure.

Pass1137 adds Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement. Coverage-gated semantic results from Pass1136 are now consumable by widened legality engines before preserving confident legality conclusions. The enforcement model maps gated rows to assignment, return, conversion/access/aggregate, overload, staticness, accessibility, contract, dataflow, generic, record/variant, elaboration, tasking/protected, representation/freezing, exception/finalization, and integrated-closure engines, and requires suppression, degradation, cross-unit closure, or repair blockers when parser/AST/metadata/consumer coverage is incomplete.

### Pass1138 - Flow-effect graph legality

Pass1138 adds `Editor.Ada_Flow_Effect_Graph_Legality`, a deterministic
snapshot-owned Global/Depends flow-effect graph layer. It turns object reads,
writes, Depends edges, call propagation, generic formal/actual substitutions,
protected-state effects, task activation effects, and refined Global/Depends
body/spec effects into first-class semantic graph rows. The layer consumes
Pass1123 dataflow legality and Pass1137 coverage-gate enforcement so incomplete
AST/metadata coverage or already illegal dataflow cannot be reported as a
confident legal flow result.

### Pass1139 - Predicate/invariant propagation legality

Pass1139 adds `Editor.Ada_Predicate_Invariant_Propagation_Legality`, a widened semantic layer that propagates predicate and invariant obligations beyond local use-site classification. It connects Pass1124 predicate/invariant use-site rows with call chains, generic formal/actual substitutions, derived/private views, visible state updates, Pass1138 flow-effect graph rows, and Pass1137 coverage-gate enforcement so dynamic checks and invariant rechecks are not silently lost across semantic edges. Regression: `Test_Ada_Predicate_Invariant_Propagation_Legality_Pass1139`.

### Pass1140 - Generic instance body semantic replay

Adds `Editor.Ada_Generic_Instance_Body_Semantic_Replay`, which replays
instantiated generic body semantic facts under actual/formal mappings and
preserves generic-source/instance diagnostic backmapping for declarations,
statements, expressions, calls, flow effects, predicates/invariants,
accessibility, representation/freezing, and nested generic instances.

### Pass1141 -- RM-grade overload edge legality

Pass1141 adds `Editor.Ada_Overload_RM_Edge_Legality`, which deepens overload resolution for Ada RM edge cases: universal fixed/root numeric preference, inherited primitive and homograph hiding, dispatching versus nondispatching ambiguity, access-to-subprogram profiles, generic formal subprograms, nested generic named/defaulted formal ambiguity, and linked generic replay / coverage-gate blockers. The pass is semantic-only and snapshot-owned.

Pass1142: Added Editor.Ada_Discriminant_Dependent_Legality. Discriminant constraints/defaults, variant presence, constrained/unconstrained record semantics, and discriminant-dependent checks now connect to assignment, conversion, return, allocator, aggregate, generic actual, private/full-view, and coverage-gated semantic contexts.


## Pass1143 - Accessibility / lifetime scope graph legality

Added `Editor.Ada_Accessibility_Scope_Graph_Legality` and AUnit coverage for master/scope hierarchy, anonymous access levels, allocator and return masters, access discriminants, generic substitutions, discriminant aggregates, finalization masters, and coverage-gated lifetime blockers.

## Pass1144 - Elaboration graph closure legality

Pass1144 adds `Editor.Ada_Elaboration_Graph_Closure_Legality`, an explicit library-unit elaboration graph closure model.  It tracks transitive `Elaborate_All`, body-before-use through direct/indirect/dispatching calls, generic instance elaboration, access-before-elaboration risks, default/aspect/representation elaboration edges, cycle paths, policy restrictions, flow-effect blockers, accessibility scope blockers, generic replay blockers, precision/base elaboration blockers, and coverage-gated blockers.

Added regression coverage: `Test_Ada_Elaboration_Graph_Closure_Legality_Pass1144`.


Pass1145: added tasking/protected effects legality connecting entry queues, accept/requeue/select effects, protected-state flow effects, elaboration graph closure, accessibility scope, finalization, and coverage-gated semantic blockers.

Pass1146 note: added Editor.Ada_Representation_Freezing_Exact_Propagation_Legality, which propagates implicit freezing from semantic uses and ties representation timing to generic body replay, discriminant/variant representation, operational/stream/finalization effects, flow-effect graphs, predicate/invariant propagation, accessibility scope graphs, elaboration graph closure, tasking/protected effects, and coverage-gated semantic blockers.

### Pass1147 - Parser / AST coverage repair legality

Pass1147 adds `Editor.Ada_AST_Coverage_Repair_Legality`.  It consumes the parser/AST
coverage audit and semantic coverage gates and records concrete repairs for Ada
2022 construct coverage: parser nodes, structural AST shape, spans, semantic
metadata, cross-unit metadata, semantic consumers, consumer integration,
token-only replacement, and graceful-degradation replacement.  Repaired rows can
clear coverage gates; unrepaired or partial rows remain explicit blockers.


Pass1148: AST coverage repair gate application
- Added Editor.Ada_AST_Coverage_Repair_Gate_Application so Pass1147 parser/AST coverage repairs are consumed by widened legality coverage-gate enforcement. Complete repairs clear matching parser/AST, metadata, consumer-integration, suppressed-result, and unsafe-result blockers; missing, partial, cross-unit, and original semantic-error cases remain explicit blockers.

Pass1149 adds integrated closure repair-gate application. Parser/AST/metadata/consumer coverage repairs from Pass1148 now feed back into integrated semantic closure so repaired constructs can regain confident semantic closure, while missing, partial, mismatched, cross-unit, and original-error cases remain explicit blockers or dependency failures.

### Pass1150 - Repair-gated diagnostic integration

Pass1150 adds `Editor.Ada_Repair_Gated_Diagnostic_Integration`, connecting repair-applied coverage-gate closure rows to a deterministic diagnostic-integration model. Repaired constructs can now regain confident non-diagnostic closure while unrepaired gates, original semantic errors, dependency failures, indeterminate repairs, and stale inputs remain explicit diagnostic or rejection states.

### Pass1151 — Repair-gated diagnostic provenance

Pass1151 adds `Editor.Ada_Repair_Gated_Diagnostic_Provenance`, which consumes repair-gated diagnostic integration rows and preserves whether each result was restored, withheld, emitted as an error or warning, preserved as an original semantic error, or rejected as stale.  This completes the repair-gate diagnostic trace from coverage repair through integrated closure and diagnostic integration into provenance.

### Pass1152 - Repaired coverage semantic feedback

Pass1152 adds `Editor.Ada_Repaired_Coverage_Semantic_Feedback`. It consumes repair-gate application rows and repair-gated diagnostic integration rows, then tells individual widened legality engines whether a repaired construct may be treated as a structurally complete semantic input. Parser/AST repairs, metadata repairs, consumer-integration repairs, already-confident rows, cross-unit requirements, missing/partial/mismatched repairs, indeterminate repairs, preserved original semantic errors, and stale rejected inputs are now separated before assignment, return, conversion/access/aggregate, overload, generic, flow/dataflow, tasking/protected, elaboration, representation/freezing, exception/finalization, and integrated-closure consumers accept the row.

Regression: `Test_Ada_Repaired_Coverage_Semantic_Feedback_Pass1152`.

### Pass1153 - Refined Global / Depends conformance legality

Pass1153 adds `Editor.Ada_Refined_Global_Depends_Conformance_Legality`. It consumes explicit flow-effect graph rows and repaired coverage semantic feedback, then checks body/spec conformance for `Global`, `Depends`, `Refined_Global`, and `Refined_Depends`. The new layer classifies legal global refinements, legal dependency refinements, null refinements, call-effect propagation, body reads/writes missing from spec Global, body reads/writes missing from Refined_Global, extra Refined_Global items, mode mismatches, missing/extra Refined_Depends edges, invalid dependency source/target modes, unpropagated call effects, linked flow-effect graph errors, repaired coverage blockers, and indeterminate cases.

Regression: `Test_Ada_Refined_Global_Depends_Conformance_Legality_Pass1153`.

### Pass1154 - Integrated closure for Refined Global / Depends conformance

Pass1154 adds `Editor.Ada_Integrated_Semantic_Closure.Refined_Global_Depends`. It consumes `Editor.Ada_Refined_Global_Depends_Conformance_Legality` rows and makes refined `Global`, `Depends`, `Refined_Global`, and `Refined_Depends` body/spec failures first-class integrated semantic closure blockers. Legal refined conformance rows remain confident local closure rows; missing Global coverage, invalid refined dependency edges, unpropagated call effects, linked flow-effect errors, and repaired coverage blockers now surface through `Closure_Blocker_Refined_Global_Depends` and `Integrated_Closure_Refined_Global_Depends_Blocker`.

Regression: `Test_Ada_Integrated_Closure_Refined_Global_Depends_Pass1154`.


Pass1155 adds Editor.Ada_Flow_Refinement_Consumer_Legality, feeding Refined_Global / Refined_Depends conformance back into flow-effect graph consumers so downstream semantic engines cannot accept flow facts that fail body/spec refinement.

### Pass1157 - Elaboration contract-flow consumer legality

Pass1157 adds `Editor.Ada_Elaboration_Contract_Flow_Consumer_Legality`, a semantic consumer that connects refined Global/Depends contract-flow results to elaboration graph closure. Legal elaboration-time calls, default expressions, aspect expressions, representation items, generic instances, and policy-sensitive elaboration edges now require matching accepted contract-flow refinement evidence. Missing Refined_Global reads/writes, Refined_Global mode mismatches, missing or invalid Refined_Depends edges, unpropagated call effects, repaired coverage blockers, linked flow graph errors, and indeterminate refined-flow rows prevent confident elaboration conclusions.


Pass1158 adds Editor.Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality, connecting tasking/protected effect legality with elaboration-time Global / Depends and Refined_Global / Refined_Depends contract-flow evidence. Task activation, protected operations, entry/accept/requeue/select constructs, abortable parts, delay alternatives, and terminate alternatives now preserve refined-flow and elaboration-contract blockers instead of remaining confidently legal from local tasking facts alone.

### Pass1159 — Representation/freezing tasking elaboration-flow consumer legality

Pass1159 adds `Editor.Ada_Representation_Tasking_Elaboration_Flow_Consumer_Legality`.
It feeds tasking/protected elaboration contract-flow evidence into
representation/freezing exact propagation so representation clauses, operational
attributes, stream attributes, record layouts, generic-instance representation
effects, private/full-view representation timing, and finalization/abortable
tasking effects cannot remain confidently legal when tasking elaboration-flow
facts are missing, blocked, or indeterminate.

### Pass1160 - Generic replay representation-flow consumer legality

Pass1160 adds `Editor.Ada_Generic_Replay_Representation_Flow_Consumer_Legality`. It feeds representation/freezing tasking/elaboration/contract-flow evidence back into generic instance body semantic replay so instantiated generic body representation clauses, operational attributes, stream attributes, record layouts, private/full-view representation timing, nested generic instances, and tasking representation effects cannot remain confidently legal when their replayed representation/freezing evidence is missing, blocked, or indeterminate.

Regression: `Test_Ada_Generic_Replay_Representation_Flow_Consumer_Legality_Pass1160`.


Pass1161 adds Editor.Ada_Discriminant_Generic_Representation_Consumer_Legality, feeding discriminant/variant legality into generic replay and representation/freezing consumers so invalid discriminant defaults, variant coverage, discriminant mismatches, and private/full-view discriminant blockers cannot remain confident through instantiated or represented contexts.


Pass1162 adds Editor.Ada_Accessibility_Scope_Consumer_Legality. Exact accessibility master/scope graph rows now gate assignment, return, conversion/access, allocator, access-discriminant, renaming, generic replay, representation/freezing, record-layout, and finalization consumers, preserving discriminant/generic/representation blockers where lifetime-sensitive consumers depend on them.


Pass1163 adds Editor.Ada_Object_Flow_Accessibility_Consumer_Legality, feeding exact accessibility scope consumer evidence into assignment, initialization, return, conversion, allocator, access-discriminant, aggregate, renaming, generic replay, and finalization object-flow legality. Missing, mismatched, blocked, or indeterminate lifetime evidence now prevents confident object-flow conclusions.

Pass1164 adds Editor.Ada_Definite_Initialization_Object_Flow_Consumer_Legality, feeding exact object-flow accessibility consumer evidence into definite-initialization and flow-sensitive object-state legality. Object/component initialization, assignment, return-object, aggregate, out-parameter, exception-path, and finalization conclusions now require matching accepted object-flow/lifetime evidence; missing, mismatched, blocked, or indeterminate object-flow rows prevent confident initialization conclusions while preserving original read-before-write and partial-initialization errors.

### Pass1165 - Dataflow definite-initialization consumer legality

Pass1165 adds `Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality`.  It feeds Pass1164 exact initialization/object-flow evidence into Global/Depends and flow-effect consumers, preventing dataflow conclusions from remaining confident when a read/write object is not definitely initialized, is conditionally initialized, is used after finalization, or is blocked by lifetime, discriminant, representation, or repaired-coverage evidence.


Pass1166 adds Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality, feeding dataflow plus definite-initialization consumer evidence into predicate/invariant propagation so predicate and invariant conclusions cannot remain confident when object-state, refined-flow, lifetime, discriminant, representation, or coverage evidence is blocked.

### Pass1167 - Contract predicate/dataflow consumer legality

Pass1167 adds `Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality`, connecting predicate/invariant propagation plus definite-initialization and refined dataflow evidence back into contract/aspect legality.  Contract rows for preconditions, postconditions, predicates, invariants, assertions, contract cases, `Global`, `Depends`, `Refined_Global`, and `Refined_Depends` are no longer treated as confidently legal when their predicate/dataflow evidence is missing, blocked, or indeterminate.


Pass1168 adds Editor.Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality, feeding contract predicate/dataflow evidence into elaboration graph consumers so elaboration-time calls, defaults, aspects, representation items, generic instances, task activation, and policy-sensitive units cannot remain confidently legal when predicate, initialization, refined-flow, lifetime, discriminant, representation, or coverage evidence is blocked.

### Pass1169 - Tasking contract predicate/dataflow consumer legality

Pass1169 adds `Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality`, feeding Pass1168 elaboration contract predicate/dataflow evidence into tasking/protected effect consumers. Task activation, termination, protected reads/writes/calls, entry queues/barriers, accept bodies, requeue, select alternatives, abortable parts, delay alternatives, and terminate alternatives now require matching predicate, initialization, refined-flow, lifetime, discriminant, representation, and coverage evidence before remaining confidently legal.

### Pass1170 - Representation tasking contract predicate/dataflow consumer legality

Pass1170 adds `Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality`, feeding the richer Pass1169 tasking/protected contract predicate/dataflow evidence into representation/freezing exact propagation. Representation clauses, operational attributes, stream attributes, record layouts, generic-instance representation effects, private/full-view timing, task activation/termination effects, protected operation effects, entry barriers, accept bodies, requeue/select effects, and abortable finalization effects now require matching predicate, initialization, refined-flow, lifetime, discriminant, representation, and coverage evidence before remaining confidently legal.

Regression: `Test_Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality_Pass1170`.

### Pass1171 - Generic replay representation contract predicate/dataflow consumer legality

Pass1171 adds `Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality`. It feeds the richer Pass1170 representation/freezing tasking contract predicate/dataflow evidence back into generic instance body semantic replay. Instantiated generic body declarations, statements, expressions, nested instances, representation clauses, operational attributes, stream attributes, record layouts, private/full-view timing, and tasking representation effects now require matching accepted representation CPD evidence before remaining confidently legal. Predicate/invariant, definite-initialization, refined-flow, lifetime/accessibility, discriminant/variant, representation/freezing, tasking/protected, and repaired-coverage blockers are preserved through generic replay instead of being flattened by substitution success.

Regression: `Test_Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality_Pass1171`.

### Pass1172 - Integrated semantic closure semantic consumer-chain bridge

Pass1172 adds `Editor.Ada_Integrated_Semantic_Closure.Consumer_Chain`. It feeds the repaired/gated semantic consumer chain from Pass1163 through Pass1171 into integrated semantic closure by consuming generic replay representation contract predicate/dataflow rows. Accepted rows remain confident local closure; non-legal rows preserve direct closure blocker families for overload, accessibility, contract, elaboration, representation/freezing, definite flow/dataflow, Refined_Global/Refined_Depends, coverage gates, indeterminate state, and tasking/replay legality blockers. This prevents generic replay representation CPD failures from being flattened before closure consumers can reason about them.

Regression: `Test_Ada_Integrated_Closure_Semantic_Consumer_Chain_Pass1172`.

Pass1173 adds Editor.Ada_Tasking_Protected_AST_Repair_Legality, a concrete parser/AST coverage repair legality model for task/protected/select constructs. It aggregates repaired coverage rows for task types/bodies, protected types/bodies, entry declarations/bodies, accept/requeue statements, and select statements, and only clears the construct as semantically usable when parser node, structural AST, source span, token-only/degradation replacement, flow metadata, required contract/representation metadata, cross-unit metadata, and integrated tasking/protected consumer evidence are all present.

Pass1174 adds Editor.Ada_Generic_Formal_AST_Repair_Legality.  It provides concrete parser/AST repair legality for generic formal objects, types, subprograms, and packages, requiring parser nodes, structural AST, spans, token/degradation replacement, name/type/staticness/contract/cross-unit metadata, and integrated generic consumer evidence before generic formal declarations are treated as semantically restored.

Pass1175 adds Editor.Ada_Access_Definition_AST_Repair_Legality. It turns repaired coverage facts into concrete access-definition parser/AST repair rows for object access definitions, anonymous access parameters, access-to-subprogram definitions, and access discriminants, requiring parser node, structural AST, span, token-only/degradation replacement, name/type/staticness/contract/flow/representation/cross-unit metadata, and integrated accessibility/access consumer evidence before clearing coverage gates.

Pass1176 adds Editor.Ada_Representation_Operational_AST_Repair_Legality. It provides concrete parser/AST repair legality for representation clauses, operational attribute clauses, aspect specifications, and pragmas, requiring parser nodes, structural AST, spans, token/degradation replacement, name/type/staticness/contract/flow/representation/cross-unit metadata, and integrated representation/contract/elaboration consumer evidence before representation/operational constructs are treated as semantically restored.

Pass1177 adds Editor.Ada_Discriminant_Variant_AST_Repair_Legality. It provides concrete parser/AST repair legality for discriminant specifications, variant parts, discriminant-dependent aggregate contexts, and private/full-view discriminant view contexts, requiring parser nodes, structural AST, spans, token/degradation replacement, name/type/staticness/contract/flow/representation/cross-unit metadata, and integrated discriminant/aggregate/accessibility/representation consumer evidence before discriminant/variant constructs are treated as semantically restored.

Pass1178 adds Editor.Ada_Expression_Construct_AST_Repair_Legality. It provides concrete parser/AST repair legality for Ada 2022 expression constructs: container aggregates, delta aggregates, reduction expressions, and quantified expressions. These constructs are only treated as semantically restored when parser nodes, structural AST, spans, token/degradation replacement, name/type/staticness/contract/flow/representation/cross-unit metadata, and integrated expression/overload/predicate/contract/flow/aggregate consumer evidence are all present.

Pass1179: Added Editor.Ada_Overload_Type_Edge_Precision_Legality. The overload/type precision layer now preserves remaining Ada RM edge blockers for access-to-subprogram profiles, universal fixed/root numeric choices, inherited primitive hiding, dispatching/nondispatching ambiguity, generic formal subprograms, nested generic named/defaulted actual ties, and class-wide controlling contexts while requiring repaired expression AST and generic replay representation contract-predicate/dataflow evidence before accepting confident legality.


Pass1180 adds generic replay source/instance backmapping legality. Instantiated generic-body semantic replay now preserves the generic source node and instantiation/formal/actual/substituted-body context, and rejects confident replay when source-instance maps, formal-actual maps, diagnostic backmaps, fingerprints, replay CPD evidence, or overload/type edge evidence are missing, blocked, ambiguous, or indeterminate.

Pass1181 adds Editor.Ada_Integrated_Semantic_Closure.Generic_Backmapping. It feeds generic replay source/instance backmapping rows into integrated semantic closure while preserving generic body source, instantiation, formal, actual, substituted-body, replay-CPD, and overload/type-edge context. Missing maps or fingerprint mismatches become coverage-gate blockers; replay flow, predicate, accessibility, representation, and overload/type-edge failures become direct dataflow, contract, accessibility, representation, and overload closure blockers instead of being flattened.

Pass1182 adds Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality. It feeds discriminant and variant legality into record layout, aggregate, assignment/conversion/return/allocator, access-discriminant, representation/freezing, generic replay, and private/full-view consumers. These consumers now require accepted discriminant/variant evidence, repaired discriminant/variant AST coverage, representation/freezing CPD evidence where required, and generic replay source/instance backmapping evidence where required before remaining confidently legal.

Pass1183: Added Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality, a final accessibility master/scope consumer layer that requires exact scope, object-flow, discriminant/variant, and generic replay backmapping evidence before accepting anonymous access results, access discriminants, allocators, aggregate access components, generic access escapes, renamings, and controlled finalization lifetime paths as confidently legal.

Pass1184: added Editor.Ada_Elaboration_Graph_Final_Consumer_Legality. The pass feeds elaboration graph closure into final call/default/aspect/representation/tasking/generic/policy consumers and preserves predicate/dataflow, overload/type, representation/freezing, tasking, generic backmapping, accessibility, missing-evidence, duplicate-evidence, and indeterminate blockers as deterministic semantic legality rows.

Pass1185: Added Editor.Ada_Tasking_Protected_Final_Effects_Legality, preserving final tasking/protected effect blockers for protected reentrancy, visible-state mutation, barrier side effects, requeue-with-abort safety, terminate alternatives, finalization hazards, and dependent elaboration/representation/accessibility/discriminant evidence.

Pass1186 update:
- Added Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality.
- Final cross-unit semantic closure now preserves blocker families from integrated closure, overload/type-edge precision, generic replay backmapping, discriminant/variant consumers, final accessibility master/scope evidence, final elaboration evidence, final tasking/protected effects, representation/freezing CPD evidence, contract/predicate/dataflow evidence, Refined_Global/Depends conformance, unit completion/order, renaming/alias/visibility, and exception/finalization legality.
- Added Test_Ada_Cross_Unit_Final_Semantic_Closure_Legality_Pass1186 and registered it in the core AUnit suite.

Pass1187 note: Added Editor.Ada_Renaming_Separate_Exception_AST_Repair_Legality. Renaming declarations, separate bodies, body stubs, exception handlers, and raise expressions now have construct-specific parser/AST repair legality rows. These rows require parser nodes, structural AST shape, source spans, token-only/degradation replacement, name/type/staticness/contract/flow/representation metadata, cross-unit metadata, and integrated semantic consumers before repaired coverage can restore confident semantic conclusions.

Pass1188 note: Added Editor.Ada_Expression_Control_Target_AST_Repair_Legality. Membership tests, case expressions, if expressions, declare expressions, and target-name/update-expression contexts now have construct-specific parser/AST repair legality rows. These rows require parser nodes, structural AST shape, source spans, token-only/degradation replacement, name/type/staticness/contract/flow/representation metadata, cross-unit metadata, and integrated semantic consumers before repaired coverage can restore confident semantic conclusions.

Pass1189: Added Editor.Ada_Overload_Type_Final_RM_Consumer_Legality. The overload/type final RM consumer now requires repaired access-definition AST evidence, overload/type edge precision evidence, and generic source/instance backmapping evidence before accepting prefixed-call primitive visibility, access-to-subprogram profile/null-exclusion/convention matching, class-wide controlling-result interactions, inherited/private-extension primitive hiding, universal fixed/root numeric mixed-mode ties, dispatching inherited operations, generic formal subprogram instances, and nested generic prefixed calls as confidently legal.

Pass1190: Added Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality. Nested generic replay closure now requires source/instance backmapping, final overload/type RM consumer evidence, cross-unit final semantic closure evidence, generic body availability, bounded dependency/cycle state, view/child visibility state, and source/substitution fingerprints before local, cross-unit, child/private-child, formal-package, nested-instance, body/subprogram, representation, and task/protected generic replay conclusions can remain confidently legal. It preserves nested dependency cycles, recursive instantiation cycles, cycle-depth overflow, dependency overflow, stale dependencies, missing evidence, view barriers, generic body availability failures, mapping/fingerprint mismatches, and multiple blockers as first-class semantic statuses.


Pass1191 adds Editor.Ada_Representation_Freezing_Final_Hard_Cases_Legality for final representation/freezing hard cases: private/full-view cross-unit freezing, generic formal freezing, inherited operational attributes, stream attributes on limited/private views, variant/discriminant/finalization layout interactions, and implicit freezing order.
Pass1192 adds Editor.Ada_Flow_Contract_Final_Proof_Legality, strengthening final Global/Depends/Refined_Global/Refined_Depends proof obligations with transitive Depends closure, dispatching-call Global refinement, abstract/refined state modelling, volatile/atomic effect semantics, independent-component effects, and blocker-preserving integration with refined conformance, flow/dataflow/init, contract CPD, cross-unit final closure, and representation/freezing final hard cases.

Pass1193 update:
- Added Editor.Ada_Tasking_Protected_Deep_Edge_Legality for protected indirect-call reentrancy, callback reentrancy, entry-family index/queue semantics, requeue/select entry-family paths, terminate alternative dependency graphs, task termination ordering, abort/deferred-finalization ordering, and abortable-select finalization safety.
- Added Test_Ada_Tasking_Protected_Deep_Edge_Legality_Pass1193 and registered it in the core AUnit suite.
- The layer consumes final tasking/protected effects, final flow/contract proof, and final cross-unit semantic closure evidence while preserving concrete blocker families.

### Pass1194 - Final semantic diagnostic integration

Pass1194 adds `Editor.Ada_Final_Semantic_Diagnostic_Integration`, a blocker-preserving integration layer for final semantic closure and final consumer results. It turns final cross-unit, overload/type, generic replay, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility/lifetime, and discriminant/variant evidence into diagnostic-ready rows while withholding legal rows as non-diagnostic evidence. Stale input, AST repair blockers, coverage-gate blockers, view barriers, indeterminate rows, and multiple blockers remain distinct.

### Pass1195 - Final semantic diagnostic feed integration

Pass1195 extends `Editor.Ada_Semantic_Diagnostic_Feed` with `Build_With_Final_Semantic_Diagnostics`.  The unified semantic feed now consumes Pass1194 final semantic diagnostic rows, withholds legal final rows, preserves final blocker-family source mapping, rejects stale final input with zero active entries, and allows the existing semantic diagnostic index to query final semantic blockers by node, source family, severity, and source span.


Pass1196 adds Editor.Ada_Final_Semantic_Diagnostic_Provenance, preserving final semantic blocker-family provenance across final diagnostic integration, unified feed/index insertion, optional base provenance links, stale rejection, and withheld confident rows.

Pass1197 adds Editor.Ada_Final_Semantic_Diagnostic_Search_Index, a blocker-family-aware final semantic diagnostic search index. It indexes Pass1196 final semantic provenance by blocker family, final status, provenance status/stage, syntax node, span/position, source fingerprint, feed link, and diagnostic-index link while preserving real semantic blocker families and stale/withheld/indeterminate rows.

Pass1198 update: added final semantic blocker trace closure.  Final semantic diagnostics can now be traced through blocker-family-preserving chains from final semantic closure and diagnostic integration through feed/index/provenance/search rows, including cross-unit, overload/type, generic replay, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility/lifetime, discriminant/variant, AST repair, coverage-gate, view-barrier, stale, indeterminate, and multiple-blocker roots.

Pass1199 update: added Editor.Ada_Final_Semantic_Blocker_Remediation_Order.  Final semantic blocker traces are now converted into deterministic remediation-order rows that preserve blocker-family identity and dependency order for stale snapshots, AST/coverage repairs, cross-unit closure, view barriers, generic replay, overload/type evidence, representation/freezing, flow/contract proof, tasking/protected effects, elaboration, accessibility/lifetime, discriminants/variants, multiple blockers, and indeterminate states.

Pass1200: Added Editor.Ada_Final_Semantic_Remediation_Gate_Legality. The pass consumes final semantic blocker remediation order and gates downstream semantic conclusions so stale evidence, AST/coverage gaps, cross-unit dependencies, view barriers, generic replay/backmapping, overload/type evidence, representation/freezing, flow/contract proof, tasking/protected effects, elaboration, accessibility/lifetime, discriminant/variant evidence, multiple blockers, and indeterminate states cannot be bypassed by later consumers.

Pass1201: Added Editor.Ada_Final_Semantic_Remediation_Closure_Legality. Final remediation gates now feed back into semantic closure as first-class blockers, preserving blocker family, source/span, dependency order, downstream blocked pressure, and fingerprints so unresolved prerequisite repairs cannot be bypassed by downstream legality consumers.


Pass1202 adds final semantic remediation diagnostic integration. It feeds Pass1201 remediation-closure blockers into diagnostic-ready rows and the semantic diagnostic feed while preserving prerequisite blocker families instead of flattening them.

Pass1203 adds final semantic remediation diagnostic provenance/search. Remediation diagnostics now retain prerequisite blocker-family identity and can be traced back through remediation closure, remediation gates, blocker traces, feed/index rows, and base diagnostic provenance without flattening stale evidence, AST/coverage repair, cross-unit closure, view barriers, generic replay/backmapping, overload/type, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility/lifetime, discriminant/variant, multiple, or indeterminate blockers.

Pass1204: Added final semantic remediation worklist legality. The new worklist consumes remediation diagnostic provenance/search evidence and orders prerequisite semantic repair/re-analysis work by real blocker family while preserving deterministic node/span/fingerprint identity.

Pass1205 adds Editor.Ada_Final_Semantic_Recheck_Eligibility_Legality.  Final remediation worklist rows now become bounded recheck eligibility rows, preserving prerequisite blocker families so stale, AST/coverage, cross-unit, view, generic replay, overload/type, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility/lifetime, and discriminant/variant blockers cannot be bypassed by downstream semantic consumers.

Pass1206 adds Editor.Ada_Final_Semantic_Recheck_Application_Legality. It applies final semantic recheck eligibility back into the closure/feed boundary so only rows whose prerequisite chain is eligible now can become current, while stale, AST/coverage, cross-unit, view, generic, overload/type, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility, discriminant/variant, preserved-error, multiple-prerequisite, and indeterminate blockers remain explicit withheld-current semantic rows.

Pass1207 adds Editor.Ada_Final_Semantic_Recheck_Convergence_Legality. It consumes final semantic recheck application rows and marks results as converged, stably withheld, preserved-error, indeterminate, or changed relative to a prior application fingerprint, so the closure/feed boundary can stop cycling on unchanged prerequisite evidence while still rechecking stale, AST/coverage, cross-unit, view, generic, overload/type, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility, discriminant/variant, multiple-prerequisite, and indeterminate blocker families when their fingerprints change.

Pass1208 note: Added Editor.Ada_Final_Semantic_Stabilization_Gate_Legality. The final semantic recheck convergence model now feeds a stabilization gate that promotes only converged/current semantic rows and preserves prerequisite blocker families for stale evidence, AST/coverage repair, cross-unit closure, view barriers, generic replay, overload/type evidence, representation/freezing, flow/contract proof, tasking/protected effects, elaboration, accessibility/lifetime, discriminant/variant evidence, multiple blockers, and indeterminate states.

Pass1209 adds final semantic stabilized closure legality.  It consumes the final
stabilization gate and promotes only stable accepted semantic rows into closure,
while preserving stable withheld prerequisite rows as first-class closure blockers
with their blocker-family identity intact.

Pass1210: Added Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration. Stable accepted closure rows from Pass1209 are withheld as current non-diagnostic semantic evidence, while stabilized blockers are emitted with their original blocker-family identity. Recheck-required and indeterminate rows remain warnings instead of being promoted as confident legal conclusions.

Pass1210 feed integration: `Editor.Ada_Semantic_Diagnostic_Feed.Build_With_Final_Stabilized_Diagnostics` consumes stabilized diagnostic rows, emits only stabilized blockers/recheck/indeterminate rows, withholds stable accepted closure rows, and preserves source-family mapping for cross-unit, generic, representation/freezing, and expression-family blockers.

Pass1211 adds Editor.Ada_Abstract_State_Refined_State_Legality, a compiler-grade abstract/refined state legality layer for abstract state declarations, Refined_State aspects, constituent mappings, abstract-state Global/Depends use, cross-unit state visibility, task/protected shared-state effects, and volatile/atomic state effects. It consumes final flow/contract proof, deep tasking/protected evidence, and stabilized final semantic closure evidence while preserving real blocker families.

Pass1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Pass1213: Added Editor.Ada_Overload_Shared_State_RM_Edge_Legality to connect final overload/type RM edge conclusions with abstract/refined-state and volatile/atomic/shared-state evidence.  Prefixed calls, dispatching calls, access-to-subprogram calls, controlling-result selections, inherited primitives, generic formal subprogram calls, renamed primitives, and universal numeric operators now preserve missing/blocking state-effect evidence as semantic blockers instead of remaining confidently legal.

Pass1214 adds representation/shared-state final legality, connecting final representation/freezing hard cases with abstract/refined state and volatile/atomic/shared-variable evidence.

Pass1215 adds Editor.Ada_Tasking_Shared_State_Final_Legality, connecting deep tasking/protected RM edge evidence with abstract/refined state, volatile/atomic/shared-variable legality, overload shared-state RM evidence, and representation/freezing shared-state evidence. It preserves blocker-family identity for protected reads/writes, entry barriers, entry-family queues, accept/requeue/select effects, task activation/termination, abortable finalization, abstract-state access, and representation-sensitive tasking effects.

Pass1216: Added Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality. The final shared-state semantic chain now has cross-unit closure across abstract/refined state, volatile/atomic/shared-variable effects, overload/type shared-state evidence, representation/freezing shared-state evidence, and tasking/protected shared-state evidence. Dependency, view, state-visibility, generic body/backmapping, volatile/atomic ordering, shared-variable, representation-effect, tasking-effect, fingerprint, multiple-blocker, and indeterminate states remain distinct blocker families.

Pass1217: added shared-state stabilized diagnostic integration.  Cross-unit shared-state closure rows now reach the stabilized diagnostic boundary with abstract-state, volatile/atomic, overload/type, representation/freezing, tasking/protected, dependency, view, generic-backmapping, state-visibility, fingerprint, multiple-blocker, and indeterminate families preserved.

Pass1218: Added Editor.Ada_Shared_State_Remediation_Worklist_Legality. The pass consumes stabilized shared-state diagnostics and creates a deterministic semantic remediation worklist while preserving abstract/refined state, volatile/atomic, overload/type, representation/freezing, tasking/protected, dependency, view, generic-backmapping, fingerprint, multiple-blocker, and indeterminate blocker families.

Pass1219 update: added Editor.Ada_Shared_State_Recheck_Eligibility_Legality.  Shared-state remediation worklist rows now become bounded recheck eligibility rows, preserving abstract/refined-state, volatile/atomic, overload/type, representation/freezing, tasking/protected, cross-unit, view, generic, state-visibility, fingerprint, multiple-prerequisite, and indeterminate blocker families before downstream semantic re-analysis may trust them.

Pass1220 note: Editor.Ada_Shared_State_Recheck_Application_Legality applies shared-state recheck eligibility back into the final closure / stabilized diagnostic boundary.  Current shared-state conclusions are exposed only when prerequisite recheck evidence is eligible or already accepted as non-diagnostic current evidence; unresolved cross-unit, view, generic, state-visibility, abstract/refined-state, volatile/atomic, overload/type, representation/freezing, tasking/protected, fingerprint, multiple, and indeterminate blockers remain withheld with their blocker-family identity preserved.

Pass1221 note: added Editor.Ada_Shared_State_Recheck_Convergence_Legality.  The pass consumes shared-state recheck application rows and records whether shared-state semantic evidence converged as current/not-required, stayed stably withheld by its original blocker family, remained indeterminate, or changed relative to a previous application fingerprint.  It preserves shared-state blocker-family identity across abstract/refined state, volatile/atomic/shared-variable, overload/type, representation/freezing, tasking/protected, cross-unit, state-visibility, generic-backmapping, source-fingerprint, stale-eligibility, multiple-prerequisite, and indeterminate evidence.

Pass1222 note: added Editor.Ada_Shared_State_Stabilization_Gate_Legality. The pass consumes shared-state recheck convergence rows and promotes only stable current/not-required shared-state evidence across the stabilization boundary. Stable prerequisite blockers remain withheld with their original family identity across cross-unit dependencies, view barriers, generic backmapping, state visibility, abstract/refined state, volatile/atomic/shared-variable effects, overload/type shared-state evidence, representation/freezing shared-state evidence, tasking/protected shared-state evidence, source-fingerprint mismatches, stale eligibility, multiple prerequisites, and indeterminate evidence.

Pass1223 note: added Editor.Ada_Shared_State_Stabilized_Closure_Legality. The pass consumes shared-state stabilization-gate rows and makes stable accepted shared-state evidence first-class closure evidence while preserving stable blockers as explicit closure blockers. It preserves blocker-family identity across cross-unit dependencies, view barriers, generic backmapping, state visibility, abstract/refined state, volatile/atomic/shared-variable effects, overload/type shared-state evidence, representation/freezing shared-state evidence, tasking/protected shared-state evidence, source-fingerprint mismatches, stale eligibility, multiple prerequisites, and indeterminate evidence.

Pass1224: Added abstract/refined state consumer integration legality. The new package Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality requires abstract/refined-state evidence before Global/Depends, dispatching, generic replay, representation/freezing, tasking/protected, volatile/atomic/shared-variable, cross-unit shared-state, and stabilized shared-state closure consumers may remain confidently accepted. Blocker-family identity is preserved for abstract state, shared state, overload/dispatching, representation/freezing, tasking/protected, cross-unit, stabilized-closure, source-fingerprint, multiple-blocker, and indeterminate cases.
### Pass1225 - Volatile/atomic representation consumer legality

Pass1225 adds `Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality`. It connects volatile/atomic/shared-state legality to representation consumers for volatile full-access objects, atomic components, independent components, representation clauses, record layout, stream and operational attributes, protected/task shared-object representation, and shared-passive layout. It preserves blocker-family identity for volatile/atomic evidence, representation/freezing evidence, abstract-state consumers, stabilized closure, local volatile/atomic representation errors, fingerprint mismatches, multiple blockers, and indeterminate states. Regression coverage is in `Test_Ada_Volatile_Atomic_Representation_Consumer_Legality_Pass1225`.


### Pass1226 - Dispatching Global/Depends refinement legality

Pass1226 adds `Editor.Ada_Dispatching_Global_Refinement_Legality`. It connects dispatching-call Global/Depends proof to abstract/refined-state legality, abstract-state consumer integration, overload shared-state evidence, volatile/atomic representation consumer evidence, final flow/contract proof, and shared-state stabilized closure. It preserves blocker-family identity for flow/contract proof, abstract state, abstract-state consumers, overload shared-state evidence, volatile/atomic representation evidence, stabilized shared-state closure, Global/Depends mismatches, dynamic effect joins, inherited/renamed/generic dispatching effects, fingerprint mismatches, multiple blockers, and indeterminate states. Regression coverage is in `Test_Ada_Dispatching_Global_Refinement_Legality_Pass1226`.

Pass1227: Added Editor.Ada_Generic_Abstract_State_Replay_Legality, replaying abstract/refined-state, volatile/atomic, shared-state, and dispatching Global/Depends effects through generic bodies and nested instantiations while preserving source/instance backmapping, formal/actual substitution, shared-state closure, and blocker-family fingerprints.

Pass1228 adds Editor.Ada_Overload_Generic_Shared_State_Final_Legality. It connects final overload shared-state RM evidence with generic abstract-state replay, dispatching Global/Depends refinement, volatile/atomic representation consumers, abstract-state consumers, and stabilized shared-state closure so final overload/type conclusions remain withheld when generic replay, shared-state, representation, dispatching, abstract-state, closure, or fingerprint prerequisites are unresolved.


Pass1229: Representation/generic/shared-state final legality

Adds Editor.Ada_Representation_Generic_Shared_State_Final_Legality. The pass consumes final representation/freezing hard-case evidence, representation/shared-state evidence, generic abstract-state replay, overload/generic shared-state final evidence, volatile/atomic representation consumers, and stabilized shared-state closure before accepting representation/freezing conclusions. It preserves blocker-family identity for final representation, representation/shared-state, generic replay, overload/generic shared state, volatile/atomic representation, stabilized closure, private/full-view freezing, generic formal freezing, stream/operational attributes, variant layout, independent components, task/protected representation, fingerprint mismatches, multiple blockers, and indeterminate states.
Pass1230: Added Editor.Ada_Tasking_Generic_Shared_State_Final_Legality, a tasking/protected generic shared-state final legality layer that consumes deep tasking, tasking shared-state, generic abstract replay, overload/generic shared-state, representation/generic shared-state, abstract-state consumer, and stabilized shared-state closure evidence while preserving blocker-family identity.

Pass1231: Added Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality, a cross-unit closure layer for the generic/shared-state final chain. It consumes cross-unit shared-state closure, generic abstract-state replay, overload/generic shared-state, representation/generic shared-state, tasking/generic shared-state, abstract-state consumer, and stabilized shared-state closure evidence while preserving dependency, view, generic-backmapping, state-visibility, dispatching, volatile/atomic, representation, tasking, fingerprint, multiple-blocker, and indeterminate families.

Pass1232: Added Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality, connecting final elaboration consumers with the generic/shared-state final chain. It requires final elaboration, cross-unit generic/shared-state closure, dispatching Global/Depends refinement, generic abstract-state replay, representation/generic shared-state evidence, and tasking/generic shared-state evidence before accepting elaboration conclusions for dispatching calls, generic instances, generic body replay, representation items, task activation/termination, and partition policy contexts. Blocker-family identity is preserved for elaboration, cross-unit/generic shared state, dispatching, generic replay, representation, tasking, policy, view, fingerprint, multiple-blocker, and indeterminate cases.

Pass1233: Added accessibility/generic shared-state final legality.  This is a compiler-grade semantic integration pass, not a UI/projection layer.  It prevents accessibility/lifetime conclusions from becoming current while generic/shared-state, cross-unit, elaboration, overload, representation, tasking, stabilized-closure, or fingerprint prerequisites remain unresolved.

Pass1234: Added Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality to connect discriminant/variant consumer evidence into the generic/shared-state final chain. The pass preserves blocker-family identity for discriminant consumers, cross-unit generic/shared-state closure, elaboration, generic replay, overload, representation/freezing, tasking/protected, accessibility, stabilized shared-state closure, discriminant constraints, variant coverage, aggregate associations, private/full-view mismatches, generic substitution, representation layout, task/protected effects, access-discriminant lifetime, cross-unit consistency, fingerprint mismatches, multiple blockers, and indeterminate states.


Pass1235 adds Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality, connecting exception propagation, controlled finalization, abort/deferred finalization, task termination, no-return paths, generic replay, cross-unit closure, accessibility, discriminants, representation, tasking/protected effects, and stabilized shared-state closure while preserving blocker-family identity.


Pass1236 adds `Editor.Ada_Renaming_Generic_Shared_State_Final_Legality`, connecting renaming, aliasing, use-clause, selected-name, and visibility legality to the generic/shared-state final semantic chain while preserving blocker-family identity.


Pass1237 adds Editor.Ada_Predicate_Generic_Shared_State_Final_Legality. It connects predicate/invariant use-site and propagation evidence to the generic/shared-state final semantic chain, preserving blocker-family identity across generic replay, representation/freezing, tasking/protected, accessibility, discriminant/variant, exception/finalization, renaming/alias, dispatching Global/Depends, cross-unit closure, stabilized shared-state closure, source-fingerprint, substitution-fingerprint, multiple-blocker, and indeterminate states.


Pass1238 adds Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality. It integrates definite-initialization/dataflow legality with the generic/shared-state final chain, preserving blocker families for initialization, dataflow, predicates, generic replay, shared-state closure, representation/freezing, tasking/protected, accessibility, discriminants, exception/finalization, renaming, volatile/atomic representation, access escape, variant components, finalization, and fingerprint mismatches.

Pass1239: Added Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration and semantic-feed integration for the completed generic/shared-state final chain. Accepted rows are withheld as current non-diagnostic evidence; blockers are emitted with their original definite-initialization, dataflow, predicate, generic replay, shared-state closure, representation/freezing, tasking/protected, accessibility, discriminant/variant, exception/finalization, renaming/alias, volatile/atomic, fingerprint, multiple-blocker, and indeterminate families preserved.
Pass1240: Added Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality. It consumes generic/shared-state final diagnostic rows and turns blocker-preserving evidence into a deterministic semantic remediation worklist. Accepted rows remain current semantic evidence; blockers become prerequisite work items ordered across stale/fingerprint evidence, definite initialization, dataflow, predicates, generic replay, stabilized shared-state closure, volatile/atomic representation, representation/freezing, tasking/protected, accessibility, discriminants/variants, exception/finalization, renaming/aliasing, multiple blockers, and indeterminate state before downstream re-analysis may trust generic/shared-state conclusions.


### Pass1241 — Generic/shared-state final recheck eligibility

Pass1241 adds `Editor.Ada_Generic_Shared_State_Final_Recheck_Eligibility_Legality`, consuming the Pass1240 remediation worklist and producing bounded recheck eligibility rows for the generic/shared-state final chain while preserving blocker-family identity for generic replay, stabilized shared-state closure, volatile/atomic representation, representation/freezing, tasking/protected, accessibility, discriminants/variants, exception/finalization, renaming, predicates, dataflow, fingerprint mismatches, multiple blockers, and indeterminate evidence.

### Pass1242 — Generic/shared-state final recheck application legality

Pass1242 adds `Editor.Ada_Generic_Shared_State_Final_Recheck_Application_Legality`, consuming Pass1241 generic/shared-state final recheck eligibility rows and applying them back into the generic/shared-state final diagnostic/closure boundary. It exposes current semantic conclusions only when prerequisite eligibility, source/substitution fingerprints, generic replay, stabilized shared-state closure, volatile/atomic, overload/type, representation/freezing, tasking/protected, elaboration, accessibility, discriminant/variant, exception/finalization, renaming/aliasing, predicate/invariant, and dataflow evidence agree while preserving blocker-family identity for later convergence and stabilization.

Pass1243 adds Editor.Ada_Generic_Shared_State_Final_Recheck_Convergence_Legality and Test_Ada_Generic_Shared_State_Final_Recheck_Convergence_Legality_Pass1243. It detects convergence, stable withholding, indeterminate state, and changed application fingerprints for the generic/shared-state final chain while preserving prerequisite blocker-family identity.

Pass1244 adds Editor.Ada_Generic_Shared_State_Final_Stabilization_Gate_Legality and Test_Ada_Generic_Shared_State_Final_Stabilization_Gate_Legality_Pass1244. It promotes only stable generic/shared-state final convergence rows, withholds prerequisite blockers with their original family identity, and forces another bounded recheck when convergence fingerprints change.

Pass1245 adds Editor.Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality and Test_Ada_Generic_Shared_State_Final_Stabilized_Closure_Legality_Pass1245. It consumes the generic/shared-state final stabilization gate and makes stable accepted rows first-class semantic closure evidence while preserving stable prerequisite blockers as explicit closure blockers with their original family identity.

Pass1246 adds Editor.Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality and Test_Ada_Overload_Generic_Shared_State_RM_Edge_Completion_Legality_Pass1246. It deepens remaining overload/type RM edge cases over the stabilized generic/shared-state final closure, preserving blocker-family identity for renamed primitives, inherited/private-extension primitive hiding, dispatching abstract-state effects, prefixed-call side-effect contracts, access-to-subprogram effect profiles, generic formal subprogram effects, universal numeric state ambiguity, class-wide controlling-result state joins, previous overload evidence, stabilized closure evidence, fingerprints, multiple blockers, and indeterminate state.

Pass1247 adds Editor.Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality and Test_Ada_Representation_Generic_Shared_State_RM_Hard_Case_Completion_Legality_Pass1247. It deepens remaining representation/freezing RM hard cases over the stabilized generic/shared-state final closure, preserving blocker-family identity for previous representation evidence, overload RM edge evidence, stabilized closure evidence, volatile/atomic representation clauses, independent components, limited/private stream attributes, inherited operational attributes, generic formal/instance freezing, discriminant-dependent layout, controlled/finalized components, protected/task representation effects, fingerprints, multiple blockers, and indeterminate state.


Pass1248 adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality, closing tasking/protected RM hard cases over the stabilized generic/shared-state semantic chain while preserving blocker-family identity for protected action reentrancy, callbacks, entry queues, requeue/select paths, abort/finalization, task termination, protected shared-state access, abstract-state-backed task effects, and generic task/protected bodies.

Pass1249: Added Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality. The pass accepts parser/AST repair only when semantic coverage gates prove that a real generic/shared-state final consumer is blocked, and it preserves blocker-family identity across coverage gates, stabilized closure, overload/type, representation/freezing, tasking/protected, parser-node, structural-AST, token-only, source-span, metadata, consumer-integration, fingerprint, multiple-blocker, and indeterminate cases.


Pass1250 adds cross-unit generic/shared-state RM completion closure legality, consuming prior cross-unit closure plus completed overload, representation/freezing, tasking/protected, and coverage-proven AST repair evidence before accepting dependency-spanning generic/shared-state RM conclusions.


Pass1251 adds elaboration generic/shared-state RM completion legality, requiring completed cross-unit RM, overload, representation, tasking, AST repair, exception/finalization, renaming, predicate, and dataflow evidence before accepting elaboration conclusions.

## Pass1252 - Accessibility Generic/Shared-State RM Completion Legality

Pass1252 adds `Editor.Ada_Accessibility_Generic_Shared_State_RM_Completion_Legality`. It connects accessibility and lifetime legality to the completed generic/shared-state RM chain, requiring completed cross-unit, prior accessibility, elaboration, overload/type, representation/freezing, tasking/protected, and coverage-proven AST repair evidence before accepting access-level, master, return-object, renaming, finalization, private/full-view, cross-unit, task/protected, representation-sensitive, dispatching, variant-component, and protected-access conclusions.


## Pass1253

Pass1253 adds `Editor.Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality`, completing exception/finalization consumption of the completed generic/shared-state RM chain while preserving blocker-family identity.

### Pass1254 — Predicate/invariant RM completion over generic shared-state evidence

Pass1254 adds `Editor.Ada_Predicate_Generic_Shared_State_RM_Completion_Legality`. It consumes the prior predicate/invariant generic/shared-state final layer together with completed cross-unit, elaboration, accessibility, exception/finalization, dataflow, overload, representation/freezing, tasking/protected, and coverage-proven AST repair evidence. Predicate and invariant conclusions are accepted only when those completed RM prerequisites agree and fingerprints still match.

Pass1255 adds Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality. It completes dataflow/initialization legality over the completed generic/shared-state RM chain by requiring prior dataflow, cross-unit RM completion, elaboration, accessibility, exception/finalization, predicate/invariant, overload, representation, tasking, and coverage-proven AST repair evidence to agree before dataflow conclusions are accepted.


Pass1256: added Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration and feed support for RM-completed generic/shared-state diagnostics, preserving blocker-family identity and stale-input rejection.

Pass1257 adds Editor.Ada_Generic_Shared_State_RM_Completion_Remediation_Worklist_Legality. It converts RM-completed generic/shared-state diagnostic blockers into deterministic semantic remediation work items while preserving blocker-family identity for cross-unit, elaboration, accessibility, exception/finalization, predicate, dataflow, overload/type, representation/freezing, tasking/protected, AST repair, fingerprint, multiple-blocker, and indeterminate prerequisites.


Pass1258 — Coverage-proven RM-completion AST repair legality
Adds Editor.Ada_Coverage_Proven_RM_Completion_AST_Repair_Legality and Test_Ada_Coverage_Proven_RM_Completion_AST_Repair_Legality_Pass1258. Parser/AST repair remains evidence-driven: only coverage-proven RM-completion blockers are repaired or carried as semantic blockers.

Pass1259 adds Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Eligibility_Legality. It consumes the RM-completion remediation worklist and produces bounded recheck eligibility rows while preserving blocker-family identity for cross-unit, elaboration, accessibility, exception/finalization, predicate/invariant, dataflow, overload/type, representation/freezing, tasking/protected, AST repair, generic substitution, volatile/atomic, fingerprint, multiple-blocker, and indeterminate prerequisites.

Pass1260 adds Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Application_Legality. It applies RM-completion recheck eligibility back into the generic/shared-state final boundary, exposing current conclusions only when eligibility and fingerprints still agree while preserving blocker-family identity for stale/fingerprint, AST/coverage, cross-unit, generic substitution, prior dataflow, volatile/atomic, overload/type, representation/freezing, tasking/protected, elaboration, accessibility, discriminants/variants, exception/finalization, renaming/aliasing, predicate/invariant, dataflow, multiple-prerequisite, and indeterminate states.
Pass1261 adds Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Convergence_Legality, which consumes Pass1260 RM-completion recheck application rows and classifies current, not-required, stably withheld, indeterminate, and changed generic/shared-state RM-completion conclusions while preserving blocker-family identity.


Pass1262 adds Editor.Ada_Generic_Shared_State_RM_Completion_Stabilization_Gate_Legality. It consumes RM-completion recheck convergence rows and promotes only stable generic/shared-state RM-completion conclusions while preserving prerequisite blocker-family identity for withheld rows.

Pass1263 adds Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality. Stable RM-completion rows from the generic/shared-state stabilization gate now become first-class closure evidence, while blocked rows remain closure blockers with the original blocker-family identity preserved.

### Pass1264 — Overload RM-completion closure consumer legality

Pass1264 adds `Editor.Ada_Overload_RM_Completion_Closure_Consumer_Legality`. It consumes the generic/shared-state RM-completion stabilized closure from Pass1263 as first-class evidence for overload/type RM edge consumers. Accepted overload conclusions are exposed only when prior overload RM evidence, stabilized closure evidence, source fingerprints, and substitution fingerprints agree. Blockers remain separated by semantic family instead of being flattened.
\nPass1265: Added representation RM-completion closure consumer legality. The pass consumes stabilized generic/shared-state RM-completion closure rows before representation/freezing RM hard-case conclusions may be trusted, while preserving blocker-family identity for closure, representation, cross-unit, overload/type, tasking, elaboration, accessibility, dataflow, and fingerprint blockers.

Pass1266: Added tasking/protected RM-completion closure consumer legality. The pass consumes stabilized generic/shared-state RM-completion closure rows before tasking/protected RM hard-case conclusions may be trusted, while preserving blocker-family identity for closure, tasking/protected, cross-unit, overload/type, representation/freezing, elaboration, accessibility, dataflow, and fingerprint blockers.

Pass1267: Added dataflow RM-completion closure consumer legality. The pass consumes stabilized generic/shared-state RM-completion closure rows before dataflow and definite-initialization RM-completion conclusions may be trusted, while preserving blocker-family identity for closure, dataflow, cross-unit, overload/type, representation/freezing, tasking/protected, elaboration, accessibility, predicates/invariants, and fingerprint blockers.

Pass1441 removes the obsolete diagnostic command/palette/keybinding/workspace/render projection tower and its matching pass1077-pass1095 tests from the active tree. It adds `Editor.Ada_Phase579_Legacy_Projection_Tower_Removal_Pass1441` and a matching AUnit gate to reject lingering active references, dangling dependent source, noncanonical replacements, reopened Remaining_* gaps, and stale removal evidence.
