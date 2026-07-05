Pass876 adds `Production_Enumeration_Representation_Empty_List_Recovery_Boundary`, `Production_Enumeration_Representation_Trailing_Separator_Recovery_Boundary`, and `Production_Enumeration_Representation_Missing_Value_Recovery_Boundary` so malformed enumeration representation clauses such as `for T use ();`, `for T use (A => 0,);`, and `for T use (A =>);` expose representation-specific recovery metadata. The parser preserves existing `Production_Recovery_Point` metadata, delimiter metadata, and continues into following declarations. AUnit coverage is provided by `Test_Language_Model_Token_Cursor_Enumeration_Representation_Recovery_Pass876`.

Pass875 adds `Production_Use_Clause_Missing_Name_Recovery_Boundary`, `Production_Use_Clause_Trailing_Separator_Recovery_Boundary`, and `Production_Use_Clause_Missing_Terminator_Recovery_Boundary` so malformed `use`, `use type`, and `use all type` clauses expose use-clause-specific recovery metadata. The parser preserves existing `Production_Recovery_Point` metadata and continues into following declarations. AUnit coverage is provided by `Test_Language_Model_Token_Cursor_Use_Clause_Specific_Recovery_Pass875`.

Pass874 adds `Production_Exception_Handler_Missing_Statement_Recovery_Boundary` and `Production_Exception_Handler_End_Statement_Recovery_Boundary` so exception handlers distinguish `when X =>` recovery at a following handler or at the enclosing `end`. The parser preserves handler statement-sequence metadata, following handlers, and enclosing body terminators. AUnit coverage is provided by `Test_Language_Model_Token_Cursor_Exception_Handler_Statement_Recovery_Pass874`.

Pass873 adds `Production_Formal_Package_Actual_Empty_Recovery_Boundary` so formal package declarations distinguish malformed empty actual parts such as `with package P is new G ();` from omitted/defaulted actual parts and valid whole-part `(<>)` box defaults. The parser preserves actual-part metadata, the close delimiter, and following generic formal declarations. AUnit coverage is provided by `Test_Language_Model_Token_Cursor_Formal_Package_Empty_Actual_Recovery_Pass873`.

Pass872 adds `Production_Case_Alternative_End_Case_Statement_Recovery_Boundary` so terminal case alternatives distinguish `when X => end case;` recovery from alternatives that recover at a following `when` or semicolon. The parser preserves the enclosing `end case` terminator and later statements. AUnit coverage is provided by `Test_Language_Model_Token_Cursor_Case_Alternative_End_Case_Statement_Recovery_Pass872`.

Pass868 adds `Production_Case_Alternative_Missing_Statement_Recovery_Boundary` so case statement alternatives distinguish a present-but-empty/malformed statement sequence from ordinary nested statement scanning. The parser keeps the following `when` alternative, `end case`, and later statements visible. AUnit coverage is provided by `Test_Language_Model_Token_Cursor_Case_Alternative_Statement_Recovery_Pass868`.

Pass867 adds `Production_Case_Choice_Missing_Choice_Recovery_Boundary` so case statement choice lists distinguish a normal `|` separator from bounded recovery when the next choice is absent. The parser keeps the following `=>`, alternative statement sequence, `end case`, and later statements visible. AUnit coverage is provided by `Test_Language_Model_Token_Cursor_Case_Choice_Missing_Choice_Recovery_Pass867`.

### Pass866 - Case statement missing-is recovery depth

Pass866 adds `Production_Case_Statement_Missing_Is_Recovery_Boundary` so case statements distinguish a present `is` keyword from bounded recovery at malformed/in-progress forms such as `case Kind` followed directly by `when` alternatives. The parser preserves selector metadata, alternatives, end-case metadata, and following statements so downstream consumers continue to degrade gracefully. AUnit coverage is provided by `Test_Language_Model_Token_Cursor_Case_Statement_Is_Recovery_Pass866`.

This improves structural grammar coverage only. It does not add compiler-grade case-choice coverage checking, discrete-choice legality checking, expression type checking, overload resolution, compiler invocation, LSP integration, rendering-side parsing, or dirty-state mutation.

### Pass865 - Extended return missing-do recovery depth

Pass865 adds `Production_Extended_Return_Missing_Do_Recovery_Boundary` so extended return statements distinguish a present `do` boundary from bounded recovery at malformed/in-progress forms such as `return Result : Integer := 1;`. The parser preserves return-object declaration, initializer, and the broader `Production_Return_Recovery_Boundary` marker so downstream consumers continue to degrade gracefully. AUnit coverage is provided by `Test_Language_Model_Token_Cursor_Extended_Return_Do_Recovery_Pass865`.

This improves structural grammar coverage only. It does not add compiler-grade return-object legality checking, subtype conformance validation, expression type checking, overload resolution, compiler invocation, LSP integration, rendering-side parsing, or dirty-state mutation.

### Pass864 - Requeue statement missing-target recovery depth

Pass864 adds `Production_Requeue_Missing_Target_Recovery_Boundary` so requeue statements distinguish a present target from bounded recovery at malformed/in-progress forms such as `requeue ;`. The parser also preserves the older broader `Production_Requeue_Target_Recovery_Boundary` marker so downstream structural consumers continue to degrade gracefully. AUnit coverage is provided by `Test_Language_Model_Token_Cursor_Requeue_Target_Recovery_Pass864`.

This improves structural grammar coverage only. It does not add compiler-grade requeue legality checking, entry-family validation, select/accept context validation, overload resolution, compiler invocation, LSP integration, rendering-side parsing, or dirty-state mutation.

### Pass863 - Accept statement missing-entry-name recovery depth

Pass863 adds `Production_Accept_Missing_Entry_Name_Recovery_Boundary` so accept statements distinguish a present entry name from bounded recovery at malformed/in-progress forms such as `accept ;`. AUnit coverage is provided by `Test_Language_Model_Token_Cursor_Accept_Entry_Name_Recovery_Pass863`. This improves structural completion metadata only and does not add compiler-grade tasking legality checks.

### Pass854 - Select guard missing-condition recovery depth

Pass854 adds `Production_Select_Guard_Missing_Condition_Recovery_Boundary` so guarded select alternatives distinguish a present guard condition from bounded recovery at malformed/in-progress forms such as `when =>`. AUnit coverage is provided by `Test_Language_Model_Token_Cursor_Select_Guard_Condition_Recovery_Pass854`. This improves structural completion metadata only and does not add compiler-grade select/tasking legality checks.

### Pass853 - Accept statement missing-terminator recovery depth

Pass853 adds `Production_Accept_Missing_Terminator_Recovery_Boundary` so accept statement do-parts distinguish a present `end Name;` terminator from a bounded missing-terminator recovery at `end Name` before following statements. AUnit coverage is provided by `Test_Language_Model_Token_Cursor_Accept_Terminator_Recovery_Pass853`. This improves structural completion metadata only and does not add compiler-grade tasking legality checks.

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

Pass830 improves qualified-expression grammar coverage in the token cursor.
Qualified-expression operands now expose productions for the operand open
delimiter, close delimiter, and bounded missing-close recovery boundary while
preserving the existing subtype-mark, selected subtype-mark, apostrophe,
operand, allocator-qualified-expression, aggregate, and association-list
metadata.

Covered examples include `Count'(1)`, `Math.Count'(1)`, nested aggregate
operands such as `Vector'(1 => Count'(2))`, allocator qualified expressions
such as `new Count'(4)`, and malformed/in-progress operands that reach a
declaration terminator before `)`. This remains parser metadata only and does
not disambiguate conversions or validate qualified-expression legality.

### Pass829 - Aggregate delimiter and recovery depth

Pass829 improves aggregate grammar coverage in the token cursor. Aggregate
primaries and association lists now expose productions for open delimiters,
close delimiters, top-level component separators, and bounded missing-close
recovery. This complements the existing aggregate productions for positional
components, named component associations, choice lists, arrows, box components,
`others`, null-record extension aggregates, extension aggregates, and delta
aggregates.

Covered examples include positional aggregates such as `(1, 2, 3)`, named
component associations such as `(X => 1, Y => 2)`, box/default components, and
malformed/in-progress aggregate expressions that reach a declaration terminator
before `)`. This remains structural metadata only and does not validate aggregate
legality or component-choice coverage.

Pass827 - Discriminant part delimiter and recovery depth

Pass827 deepens Ada discriminant-part grammar metadata. Shared discriminant-part parsing now records opening and closing delimiters, semicolon separators between discriminant specifications, and a bounded missing-close recovery boundary for malformed or in-progress discriminant parts.

Coverage added:
- `Production_Discriminant_Part_Open_Delimiter`
- `Production_Discriminant_Part_Close_Delimiter`
- `Production_Discriminant_Specification_Separator`
- `Production_Discriminant_Part_Missing_Close_Recovery_Boundary`
- AUnit regression `Test_Language_Model_Token_Cursor_Discriminant_Part_Delimiters_Pass827`

The pass preserves existing known/unknown discriminant-part metadata, discriminant specification metadata, default-expression metadata, access-definition metadata, and bounded parser recovery. This is structural grammar coverage only; it is not compiler-grade discriminant legality or conformance checking.

### Pass828 - Index/discriminant constraint delimiter and recovery depth

Pass828 improves subtype constraint grammar coverage in the token cursor. Index
constraints now expose structural productions for the opening delimiter, closing
delimiter, top-level item separators, and bounded missing-close recovery.
Discriminant constraints now expose equivalent productions for opening/closing
delimiters, top-level association separators, and bounded missing-close recovery.

Covered examples include `Vector (1 .. 10, 1 .. 20)`, `Rec (Low => 1, High =>
10)`, and malformed/in-progress constraint actual parts that reach a declaration
terminator before `)`. This remains parser metadata only; legality of the
constraint, subtype conformance, static evaluation, and discriminant-vs-index
semantic disambiguation remain outside this pass.

### Pass831 - Parenthesized-expression delimiter and recovery depth

Pass831 adds parenthesized-expression-specific delimiter and missing-close
recovery metadata to the token cursor:

- `Production_Parenthesized_Expression_Open_Delimiter`
- `Production_Parenthesized_Expression_Close_Delimiter`
- `Production_Parenthesized_Expression_Missing_Close_Recovery_Boundary`
- AUnit regression `Test_Language_Model_Token_Cursor_Parenthesized_Expression_Delimiters_Pass831`

This improves structural grammar coverage for ordinary and nested parenthesized
expressions, including parenthesized conditional expressions and malformed
in-progress parenthesized expressions. It does not perform compiler-grade
expression legality checking or aggregate-vs-parenthesized semantic
disambiguation.

### Pass832 - Discrete choice-list separator and recovery depth

Pass832 adds choice-list separator and missing-choice recovery metadata:

- `Production_Discrete_Choice_Separator`
- `Production_Discrete_Choice_Missing_Choice_Recovery_Boundary`
- AUnit regression `Test_Language_Model_Token_Cursor_Discrete_Choice_List_Separators_Pass832`

This improves structural grammar coverage for case/variant-style discrete choice
lists. Recovery is bounded so a malformed choice after `|` leaves the enclosing
`=>` arrow available to the surrounding alternative parser. This remains parser
metadata only and does not validate choice legality, duplicate choices, static
ranges, or variant coverage.

### Pass833 - Enumeration type delimiter and recovery depth

Pass833 adds enumeration type delimiter, separator, and missing-close recovery
metadata:

- `Production_Enumeration_Type_Open_Delimiter`
- `Production_Enumeration_Type_Close_Delimiter`
- `Production_Enumeration_Literal_Separator`
- `Production_Enumeration_Type_Missing_Close_Recovery_Boundary`
- AUnit regression `Test_Language_Model_Token_Cursor_Enumeration_Type_Delimiters_Pass833`

This improves structural grammar coverage for Ada enumeration type definitions.
Recovery is bounded so malformed declarations such as `type T is (A, B;` leave
following declarations visible. This remains parser metadata only and does not
validate duplicate literals, literal legality, or visibility.

### Pass835 - Range constraint bound and separator recovery depth

Pass835 adds range-constraint separator and missing-bound recovery metadata:

- `Production_Range_Constraint_Range_Separator`
- `Production_Range_Constraint_Missing_Lower_Bound_Recovery_Boundary`
- `Production_Range_Constraint_Missing_Upper_Bound_Recovery_Boundary`
- AUnit regression `Test_Language_Model_Token_Cursor_Range_Constraint_Bounds_Pass835`

This improves structural grammar coverage for Ada range constraints. Recovery is
bounded so malformed constraints such as `range ;` and `range 1 .. ;` leave
following declarations visible. This remains parser metadata only and does not
perform static range validation, subtype legality checking, or overload
resolution.

### Pass836 - Attribute argument delimiter and recovery depth

Pass836 adds attribute argument-list delimiter, separator, and missing-close
recovery metadata:

- `Production_Attribute_Argument_List_Open_Delimiter`
- `Production_Attribute_Argument_List_Close_Delimiter`
- `Production_Attribute_Argument_Association_Separator`
- `Production_Attribute_Argument_List_Missing_Close_Recovery_Boundary`
- AUnit regression `Test_Language_Model_Token_Cursor_Attribute_Argument_Delimiters_Pass836`

This improves structural grammar coverage for Ada attribute argument parts,
including ordinary indexed attribute arguments and Ada 2022 reduction attribute
arguments. Recovery is bounded so malformed forms such as `T'First (1;` leave
following declarations visible. This remains parser metadata only and does not
perform attribute legality checking, reduction profile conformance, or overload
resolution.

### Pass837 - Membership choice-list separator and recovery depth

Pass837 adds membership choice-list separator and missing-choice recovery
metadata:

- `Production_Membership_Choice_Separator`
- `Production_Membership_Choice_Missing_Choice_Recovery_Boundary`
- AUnit regression `Test_Language_Model_Token_Cursor_Membership_Choice_List_Separators_Pass837`

This improves structural grammar coverage for Ada membership choice lists in
`in` and `not in` relations. Recovery is bounded so malformed forms such as
`A in B | ;` leave following declarations visible. This remains parser metadata
only and does not perform membership legality checking, duplicate-choice
validation, static range evaluation, or overload resolution.


### Pass838 - Case-expression alternative separator and recovery depth

Pass838 adds `Production_Case_Expression_Alternative_Separator` for comma
separators between case-expression alternatives and reuses bounded
`Production_Case_Expression_Missing_Alternative_Recovery_Boundary` metadata for
trailing-comma/in-progress alternatives.

Regression coverage:
- AUnit regression `Test_Language_Model_Token_Cursor_Case_Expression_Alternative_Separators_Pass838`

This is structural grammar coverage only; it is not compiler-grade legality
checking.

### Pass839 - Declare-expression begin keyword and recovery depth

Pass839 adds declare-expression begin-boundary and missing-begin recovery
metadata:

- `Production_Declare_Expression_Begin_Keyword`
- `Production_Declare_Expression_Missing_Begin_Recovery_Boundary`
- AUnit regression `Test_Language_Model_Token_Cursor_Declare_Expression_Begin_Recovery_Pass839`

This improves structural grammar coverage for Ada 2022 declare expressions.
Recovery is bounded so malformed forms such as `(declare X : constant Integer :=
1; X + 1)` do not consume following declarations. This remains parser metadata
only and does not perform declare-expression legality checking, declarative-item
legality checking, expression type resolution, or overload resolution.

### Pass840 - Quantified-expression missing-quantifier recovery depth

Pass840 adds quantified-expression missing-quantifier recovery metadata:

- `Production_Quantified_Missing_Quantifier_Recovery_Boundary`
- AUnit regression `Test_Language_Model_Token_Cursor_Quantified_Missing_Quantifier_Pass840`

This improves structural grammar coverage for malformed or in-progress Ada
quantified expressions where `for` is not followed by the required `all` or
`some` quantifier. Recovery is bounded so forms such as `(for I in 1 .. 10 =>
I > 0)` still expose the quantified domain and arrow while leaving following
declarations visible. This remains parser metadata only and does not perform
quantified-expression legality checking, loop-scheme legality checking,
predicate type checking, or overload resolution.


### Pass841 - If-expression missing-then recovery depth

Pass841 adds if/elsif expression missing-`then` recovery metadata:

- `Production_If_Expression_Missing_Then_Recovery_Boundary`
- `Production_Elsif_Expression_Missing_Then_Recovery_Boundary`
- AUnit regression `Test_Language_Model_Token_Cursor_If_Expression_Then_Recovery_Pass841`

This improves structural grammar coverage for malformed or in-progress Ada
conditional expressions where an `if` or `elsif` condition is not followed by
the required `then`. Recovery is bounded and keeps following declarations
visible. This remains parser metadata only and does not perform conditional
expression legality checking, branch type checking, or overload resolution.


### Pass842 — Selected-name missing-selector recovery depth

- `Production_Selected_Name_Missing_Selector_Recovery_Boundary` records bounded recovery for dangling selected-name dots.
- Existing selected-name prefix, separator, chain-component, literal-selector, operator-selector, and character-selector metadata remains intact.
- Scope: structural grammar recovery only, not compiler-grade name resolution or selector legality checking.

### Pass843 — Delta aggregate keyword and recovery depth

Improves structural grammar metadata for Ada 2022 delta aggregates. The token cursor records the top-level `with` keyword, `delta` keyword, comma separators between delta aggregate associations, and bounded missing-association recovery for incomplete `with delta` aggregate forms.

This is not compiler-grade aggregate legality checking, component-choice validation, type resolution, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass844 — Extension aggregate keyword and recovery depth

Improves structural grammar metadata for Ada extension aggregates. The token cursor records the top-level `with` keyword, comma separators between extension aggregate component associations, and bounded missing-association recovery for incomplete non-`delta` extension aggregate forms. `with null record` remains structurally distinct.

This is not compiler-grade aggregate legality checking, component-choice validation, type resolution, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass845 — Null-record aggregate keyword and recovery depth

- `with null record` extension aggregates retain explicit `null` / `record` keyword metadata.
- malformed `with null` forms retain null-record-aggregate-specific missing-`record` recovery metadata.
- recovery remains bounded and leaves following declarations visible.

### Pass847 — Iterated component domain recovery depth

- `Production_Iterated_Component_Missing_Domain_Recovery_Boundary` records bounded recovery when an aggregate iterated component association reaches `when` or `=>` before its domain.
- Existing iterated component association, domain, filter, arrow, component-expression, and missing-arrow metadata remains intact.
- Recovery is bounded and leaves following declarations visible for Outline, diagnostics, and semantic-colouring consumers.

### Pass846 — Iterated component association arrow recovery depth

- `Production_Iterated_Component_Association_Arrow` records the explicit `=>` boundary in aggregate iterated component associations.
- `Production_Iterated_Component_Missing_Arrow_Recovery_Boundary` records bounded recovery for malformed/in-progress iterated component associations with no arrow.
- Existing iterated component domain, iterator filter, and component-expression metadata remains intact.
- Scope: structural grammar metadata only, not compiler-grade aggregate or iterator legality checking.

### Pass848 — Loop iteration domain recovery depth

- `Production_For_Loop_Missing_Domain_Recovery_Boundary` records bounded recovery when a `for I in ... loop` iteration scheme reaches `when`, `loop`, or `;` before a discrete range/domain.
- `Production_Iterator_Loop_Missing_Domain_Recovery_Boundary` records bounded recovery when a `for E of ... loop` iterator scheme reaches `when`, `loop`, or `;` before an iterable domain.
- Existing loop filter, loop-begin, statement-sequence, and following statement metadata remain visible after recovery.
- This improves structural grammar coverage only; it is not compiler-grade iterator or loop legality checking.

### Pass849 — Iterator-filter condition recovery depth

- Adds `Production_Loop_Iterator_Filter_Missing_Condition_Recovery_Boundary` for malformed loop filters that reach `loop`, `;`, or another boundary before a condition.
- Adds `Production_Quantified_Iterator_Filter_Missing_Condition_Recovery_Boundary` for quantified-expression filters that reach `=>` before a condition.
- Adds `Production_Iterated_Component_Iterator_Filter_Missing_Condition_Recovery_Boundary` for aggregate iterated component filters that reach `=>` before a condition.
- Scope: structural recovery metadata only; no iterator legality checking, predicate type checking, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass850 — Exit-when condition recovery depth

- Adds `Production_Exit_When_Missing_Condition_Recovery_Boundary` for malformed/in-progress `exit when` statements that reach a terminator or synchronization boundary before a condition expression.
- Preserves existing `Production_Exit_When_Keyword`, `Production_Exit_When_Condition`, and `Production_Exit_Terminator` metadata for well-formed and recovered statements.
- Keeps recovery bounded so following statements remain visible to language-model consumers.
- This is structural parser/token-cursor coverage only, not compiler-grade loop legality checking or condition type checking.


### Pass851 — Delay statement missing-expression recovery depth

- Adds `Production_Delay_Until_Missing_Expression_Recovery_Boundary` for malformed/in-progress `delay until` statements that reach a terminator or synchronization boundary before a time expression.
- Adds `Production_Delay_Relative_Missing_Expression_Recovery_Boundary` for malformed/in-progress relative `delay` statements that reach a terminator or synchronization boundary before a duration expression.
- Preserves existing delay mode, expression, selected/qualified time-expression, statement terminator, and select-alternative metadata.
- This improves structural parser recovery only; it is not compiler-grade delay legality checking or time-expression type checking.

### Pass852 — Requeue statement missing-terminator recovery depth

- Adds `Production_Requeue_Missing_Terminator_Recovery_Boundary` for malformed/in-progress `requeue` statements that reach `end`, `or`, `else`, `exception`, or end-of-input before a semicolon.
- Preserves existing requeue target, selected/indexed target, entry-name, entry-index, `with abort`, and terminator metadata for well-formed and recovered forms.
- Keeps recovery bounded so enclosing accept/block end markers and following statements remain visible.
- This improves structural parser recovery only; it is not compiler-grade requeue legality checking, entry-family validation, select/accept context validation, or overload resolution.

### Pass855 — Abort target recovery depth

- `Production_Abort_Missing_Target_Recovery_Boundary` records bounded recovery when an Ada `abort` statement reaches `;` or end-of-input before a required task-name target.
- Trailing-comma/in-progress target lists such as `abort Worker, ;` retain abort target-list and separator metadata before recovery.
- Scope: structural parser/token-cursor metadata only; no compiler-grade abort legality checking, task-name resolution, tasking legality checking, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass856 — Return statement missing-terminator recovery depth

- `Production_Return_Missing_Terminator_Recovery_Boundary` records bounded recovery when a simple Ada `return` statement reaches a synchronization boundary before its required semicolon.
- `Test_Language_Model_Token_Cursor_Return_Terminator_Recovery_Pass856` covers malformed/in-progress `return 1` before `else` while preserving ordinary return terminator metadata on a later well-formed return statement.
- This improves structural parser recovery only; it is not compiler-grade return legality checking, return type conformance, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass857 — raise-expression message recovery depth

Improves structural grammar coverage for Ada raise expressions by recording an
expression-specific recovery boundary when a `with` message clause has no
message expression, for example `(if Ready then raise Constraint_Error with else
False)`.  This keeps the following expression/declaration structure visible to
outline, diagnostics, and semantic-colouring consumers.  This is not
compiler-grade raise-expression legality checking, exception visibility
analysis, message type checking, or overload resolution.

### Pass858 — Raise-statement message recovery depth

Raise statements now expose statement-specific bounded recovery metadata when a
`with` message clause is missing its expression. This improves structural
coverage for malformed/in-progress forms such as `raise Constraint_Error with;`
while preserving well-formed message-expression metadata and following-statement
visibility. This is not compiler-grade raise legality checking or exception
message type analysis.

### Pass859 — Label missing-close recovery depth

Improves structural label parsing by adding
`Production_Label_Missing_Close_Recovery_Boundary` for malformed labels with a
missing `>>` delimiter before the line boundary. Recovery remains bounded and
leaves following statements visible. This is parser/token-cursor metadata only,
not compiler-grade label legality checking, goto-target resolution, or
duplicate-label validation.

### Pass860 — Assignment expression recovery depth

Improves structural statement recovery for Ada assignment statements by adding
`Production_Assignment_Missing_Expression_Recovery_Boundary` when a `:=` token
is followed immediately by a statement/declaration synchronization boundary or
semicolon. This keeps malformed/in-progress forms such as `X :=;` localized
while preserving well-formed assignment-expression metadata and following
statement visibility. This is not compiler-grade assignment legality checking,
left-hand-side legality checking, expression type checking, or overload
resolution.

### Pass861 — Goto target recovery depth

Improves structural statement recovery for Ada `goto` statements by adding
`Production_Goto_Missing_Target_Recovery_Boundary` when a `goto` keyword is
followed immediately by a statement synchronization boundary or semicolon. This
keeps malformed/in-progress forms such as `goto;` localized while preserving
well-formed goto target metadata and following label/statement visibility. This
is not compiler-grade goto legality checking, label resolution, duplicate-label
validation, visibility analysis, or overload resolution.

### Pass862 — Raise-statement missing exception-name recovery

Raise statements now record `Production_Raise_Statement_Missing_Exception_Name_Recovery_Boundary`
when the parser sees a `with` message introducer before an exception name, for example
`raise with "message";`. The parser keeps the message keyword/expression visible and avoids
misclassifying `with` as an exception name. This is structural recovery metadata, not
compiler-grade raise legality checking.

### Pass 869 — If statement branch recovery

Improves structural coverage for Ada if statements with empty branch bodies. The token cursor now records dedicated missing-statement recovery boundaries for `then`, `elsif`, and `else` branches when the next token is already a branch/end boundary. This keeps `elsif`, `else`, `end if`, and following statements visible after recovery.

### Pass870 - loop body statement recovery

* Added `Production_Loop_Missing_Statement_Recovery_Boundary`.
* Empty loop bodies immediately followed by `end loop` now retain
  loop-specific recovery metadata while preserving the enclosing loop end and
  following statements.
* Scope: structural token-cursor recovery only, not compiler-grade loop or
  statement legality checking.

### Pass871 - block statement-sequence recovery

* Added `Production_Block_Missing_Statement_Recovery_Boundary`.
* Empty block statement sequences immediately followed by `end` or `exception`
  now retain block-specific recovery metadata while preserving block end,
  exception-part, and following-statement visibility.
* Scope: structural token-cursor recovery only, not compiler-grade block,
  exception-handler, or statement legality checking.

### Pass877 — Subprogram contract/aspect placement on specs and bodies

Pass877 improves structural grammar coverage for subprogram aspect placement by
retaining subprogram-specific metadata for aspect specifications attached to
subprogram declarations and to subprogram bodies before `is`.  Contract-bearing
aspect lists such as `Pre`, `Post`, `Global`, and `Depends` also receive a
subprogram contract placement marker so Outline and semantic-colouring consumers
can distinguish contract placement without reparsing source text.

This remains structural parser metadata only.  It is not compiler-grade contract
legality checking, Global/Depends validation, profile conformance, overload
resolution, compiler invocation, LSP integration, render-side parsing, or
analysis-side dirty-state mutation.

### Pass878 — Package declarative item boundary recovery

Pass878 improves structural grammar coverage for package declaration and package
body declarative-item recovery.  Malformed nested declarative items now expose a
package-specific nested-declarative recovery production and preserve whether the
synchronization point was `private`, `begin`, or `end`.

This is structural editor metadata only.  It is not package legality checking,
nested declaration legality checking, visibility checking, compiler invocation,
LSP integration, render-side parsing, or dirty-state mutation.

### Pass879 — Anonymous access-to-subprogram refined recovery

Pass879 improves structural grammar coverage for anonymous access-to-subprogram
edge forms.  The token cursor now distinguishes three recovery boundaries: a
protected access definition missing `procedure`/`function`, an access-to-function
profile missing `return`, and an access-to-function `return` clause missing its
result subtype.  Existing access-definition, protected-profile, parameter
profile, result-profile, and generic recovery metadata is preserved.

This remains structural parser metadata only.  It is not callable-profile
legality checking, result subtype legality checking, overload resolution,
compiler invocation, LSP integration, render-side parsing, or dirty-state
mutation.

### Pass880 — Conditional expression operand recovery

Pass880 improves structural grammar coverage for malformed Ada conditional
expressions.  The token cursor now exposes specific recovery productions for an
`if` expression missing its condition, for a `then` branch missing its dependent
expression, and for an `else` branch missing its dependent expression.  Existing
conditional-expression metadata and following declaration visibility are
preserved.

This remains structural parser metadata only.  It is not expression type
checking, Boolean legality checking, overload resolution, compiler invocation,
LSP integration, render-side parsing, or dirty-state mutation.

### Pass881 — Selected literal name refinement

Pass881 improves structural name-grammar coverage for selected names whose
selector is an operator-symbol string literal or a character literal.  Literal
selectors now also expose the generic selected-selector production, and selected
literal subtype-mark metadata is retained separately for qualified-expression
and allocator contexts.

This remains structural parser metadata only.  It is not subtype legality
checking, operator legality checking, overload resolution, compiler invocation,
LSP integration, render-side parsing, or dirty-state mutation.

### Pass882 — Select alternative statement-sequence recovery

Pass882 improves structural grammar coverage for Ada select statements whose
alternative bodies are empty or malformed immediately before a select boundary.
The token cursor now distinguishes missing statement sequences before `or`,
`else`, `then abort`, `terminate`, and `end select` boundaries with
`Production_Select_Alternative_Missing_Statement_Recovery_Boundary`,
`Production_Select_Else_Missing_Statement_Recovery_Boundary`, and
`Production_Select_Abortable_Missing_Statement_Recovery_Boundary` while retaining
existing select-alternative, else-part, abortable-part, end-select terminator,
and generic recovery metadata.

This is structural editor grammar coverage only. It is not tasking legality
checking, selective-accept legality checking, statement legality checking,
compiler invocation, LSP integration, render-side parsing, or dirty-state
mutation.

### Pass883 — accept-statement body statement-sequence recovery

Pass883 adds `Production_Accept_Body_Missing_Statement_Recovery_Boundary` and
`Production_Accept_Body_End_Statement_Recovery_Boundary` so empty or malformed
`accept ... do` bodies retain accept-specific recovery metadata rather than only
using generic accept-end recovery. AUnit coverage is provided by
`Test_Language_Model_Token_Cursor_Accept_Body_Statement_Recovery_Pass883`.

Covered recovery shapes include empty accept bodies before `end Name;`, malformed
accept bodies before select-alternative boundaries such as `or`, and preservation
of malformed accept terminator metadata before following declarations.

This improves structural parser coverage only; it is not compiler-grade tasking
legality checking, accept-body legality checking, entry-family validation,
overload resolution, compiler invocation, LSP integration, rendering-side
parsing, or dirty-state mutation.

### Pass884 — generic formal incomplete type declarations

Pass884 adds `Production_Formal_Incomplete_Type_Declaration`,
`Production_Formal_Incomplete_Tagged_Type_Definition`, and
`Production_Formal_Incomplete_Type_Recovery_Boundary` so generic formal
incomplete type declarations such as `type T;`, `type T (<>);`, and
`type T is tagged;` are retained as formal-type grammar rather than reported as
missing-`is` failures.  The regression
`Test_Language_Model_Token_Cursor_Generic_Formal_Incomplete_Type_Pass884`
ensures malformed `type T is;` recovery remains bounded and does not consume
following generic formal declarations or the generic package declaration.

### Pass885 — pragma recovery depth

Pass885 adds pragma-specific recovery metadata for missing pragma identifiers,
empty pragma argument lists, trailing argument separators, missing argument
expressions, and missing pragma terminators.  This improves structural pragma
coverage while preserving generic recovery metadata and following declaration
visibility.  It is not compiler-grade pragma legality checking.


### Pass886 — address and attribute-definition representation-clause recovery

Pass886 adds structural recovery metadata for malformed address and
attribute-definition representation clauses.  The token cursor now distinguishes
attribute-definition clauses missing `use`, attribute-definition clauses missing
the expression after `use`, and address clauses missing the address expression
after either `for X'Address use` or `for X use at`.

The productions
`Production_Attribute_Definition_Missing_Use_Recovery_Boundary`,
`Production_Attribute_Definition_Missing_Value_Recovery_Boundary`, and
`Production_Address_Clause_Missing_Value_Recovery_Boundary` preserve specific
recovery causes while retaining the existing representation-clause,
attribute-definition-clause, address-clause, and generic recovery metadata.

This improves structural parser coverage only. It is not compiler-grade
representation legality checking, address expression legality checking, static
expression validation, overload resolution, compiler invocation, LSP
integration, render-side parsing, or dirty-state mutation.

### Pass887 — broader aspect-placement family metadata

Pass887 adds structural aspect-placement metadata for package declarations,
package bodies, task declarations, task bodies, protected declarations,
protected bodies, private type declarations, and generic declarations. The
metadata is intentionally placement-oriented: the ordinary aspect association,
aspect mark, contract aspect, and value-expression productions remain the
source of detailed aspect payload structure.

This improves structural grammar coverage for broader Ada aspect placement. It
is not compiler-grade aspect legality checking, representation aspect
validation, contract legality checking, compiler invocation, LSP integration,
render-side parsing, background whole-project scanning, or dirty-state
mutation.

### Pass888 — case-expression dependent-expression recovery

Pass888 records `Production_Case_Expression_Missing_Dependent_Expression_Recovery_Boundary`
when a case-expression alternative has `=>` but no dependent expression before
`,`, `)`, `;`, or another reserved recovery boundary. Existing case-expression,
choice-list, arrow, dependent-expression, and generic recovery metadata remains
available.

Regression: `Test_Language_Model_Token_Cursor_Case_Expression_Dependent_Recovery_Pass888`.
This improves structural expression grammar coverage and is not compiler-grade
case-choice legality or type checking.

### Pass889 — name/attribute prefix and incomplete selected-name refinement

Pass889 adds parser-owned metadata for selected-name attribute prefixes and
complex attribute prefixes. It also records qualified-expression-specific and
allocator-specific recovery when a selected subtype mark is left dangling before
a qualification apostrophe or allocator terminator. The productions
`Production_Attribute_Selected_Prefix`, `Production_Attribute_Complex_Prefix`,
`Production_Qualified_Expression_Incomplete_Selected_Subtype_Mark`, and
`Production_Allocator_Incomplete_Selected_Subtype_Mark` preserve these contexts
without replacing the existing generic selected-name recovery markers.

Regression: `Test_Language_Model_Token_Cursor_Name_Attribute_Refinement_Pass889`.
This is structural grammar coverage only, not attribute legality checking,
subtype legality checking, overload resolution, compiler invocation, LSP
integration, render-side parsing, or dirty-state mutation.

### Pass890 — task/protected body declarative-item recovery

Pass890 improves structural recovery for declarative items inside task bodies and
protected operation bodies. Malformed declarations before `begin` now expose
body-family-specific recovery metadata instead of only broad package-style or
generic recovery points.

New productions:

* `Production_Task_Body_Declarative_Item_Recovery_Boundary`
* `Production_Task_Body_Declarative_Begin_Boundary`
* `Production_Task_Body_Declarative_End_Boundary`
* `Production_Protected_Body_Declarative_Item_Start`
* `Production_Protected_Body_Declarative_Item_Recovery_Boundary`
* `Production_Protected_Body_Declarative_Begin_Boundary`
* `Production_Protected_Body_Declarative_End_Boundary`

Regression: `Test_Language_Model_Token_Cursor_Task_Protected_Body_Declarative_Recovery_Pass890`.

This is structural editor grammar coverage only. It does not validate tasking
legality, protected operation profile legality, declaration legality, or
compiler-grade semantic rules.

### Pass891 — semantic-colouring suppression for recovered partial metadata

Pass891 follows through on the recent name/recovery grammar passes by tightening
semantic-colouring metadata consumption. Metadata-only names that are visibly
partial recovery products, such as dangling selected names (`Broken.`) or
unresolved bindings whose source expression contains an incomplete selected
qualification (`Broken.'(1)`) or allocator subtype mark (`new Broken.;`), no
longer seed the bounded semantic map as complete package/type/value names.

Resolved bindings are unchanged: when the language model has a concrete target
symbol, semantic colouring still uses the target symbol kind. This improves
false-positive suppression for recovered partial names only. It is not
compiler-grade name binding, overload resolution, compiler invocation, LSP
integration, render-side parsing, background whole-project scanning, or
dirty-state mutation.

Regression: `Test_Syntax_Semantics_Recovered_Metadata_Suppressed_Pass891`.

### Pass892 — reduction attribute argument recovery depth

Pass892 refines Ada 2022 reduction attribute argument parsing for malformed
argument parts. `Production_Reduction_Missing_Reducer_Recovery_Boundary`,
`Production_Reduction_Missing_Initial_Value_Recovery_Boundary`, and
`Production_Reduction_Trailing_Separator_Recovery_Boundary` distinguish recovery
for empty reducer slots, empty initial-value slots, and trailing separators
inside `Reduce`, `Parallel_Reduce`, and `Map_Reduce` argument lists.

Regression: `Test_Language_Model_Token_Cursor_Reduction_Argument_Recovery_Pass892`.

This is structural expression grammar coverage only. It does not validate
reducer callable conformance, initial-value type compatibility, parallel
execution legality, overload resolution, compiler invocation, LSP integration,
render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass893 — quantified-expression predicate recovery

Pass893 refines Ada quantified-expression recovery when the quantified arrow is
present but the predicate expression is missing. The token cursor now records
`Production_Quantified_Missing_Predicate_Recovery_Boundary` for malformed forms
where `=>` is followed immediately by a delimiter, separator, semicolon, or
reserved expression boundary.

Regression: `Test_Language_Model_Token_Cursor_Quantified_Predicate_Recovery_Pass893`.

This is structural expression grammar coverage only. It does not validate
Boolean predicate legality, iterator legality, overload resolution, compiler
invocation, LSP integration, render-side parsing, background whole-project
scanning, or dirty-state mutation.

### Pass894 — declare-expression body recovery

Declare expressions now expose
`Production_Declare_Expression_Missing_Body_Recovery_Boundary` when the `begin`
keyword is followed immediately by a close delimiter, separator, semicolon, or
reserved expression boundary. This preserves the enclosing declare-expression
structure and following declarations without treating boundary tokens as body
expressions.

Regression: `Test_Language_Model_Token_Cursor_Declare_Expression_Body_Recovery_Pass894`.

This is structural expression grammar coverage only. It does not validate the
declarative part, body expression type, overload resolution, compiler
invocation, LSP integration, render-side parsing, background whole-project
scanning, or dirty-state mutation.

### Pass895 — iterated component association missing-expression recovery

Iterated component associations now expose
`Production_Iterated_Component_Missing_Expression_Recovery_Boundary` when the
association arrow is followed immediately by a close delimiter, separator,
semicolon, or reserved expression boundary. This keeps malformed aggregate
component associations structurally visible without treating boundary tokens as
component expressions.

Regression: `Test_Language_Model_Token_Cursor_Iterated_Component_Expression_Recovery_Pass895`.

This is structural parser coverage only. It does not validate aggregate legality,
iterator legality, component expression type compatibility, or compiler-grade
semantic rules.

### Pass896 — generic actual association list recovery

Pass896 improves structural grammar coverage for malformed generic actual parts.
`Production_Generic_Actual_Empty_List_Recovery_Boundary` records `()` actual
lists, `Production_Generic_Actual_Missing_Actual_Recovery_Boundary` records
named/positional actual associations whose value is missing, and
`Production_Generic_Actual_Trailing_Separator_Recovery_Boundary` records a
separator immediately followed by `)` or `;`. The parser keeps the broader
generic actual part, association, separator, close-delimiter, and generic
recovery metadata visible for language-model, resolver, and semantic-colouring
consumers.

### Pass897 — renaming target recovery

Pass897 improves structural grammar coverage for malformed renaming declarations.
Renaming tails now distinguish declarations where `renames` is present but the
renamed entity is omitted, including aspect-only recovery such as
`package P renames with Preelaborate;`.  The parser preserves renaming
metadata, renaming aspect placement, valid following renamed targets, generic
recovery metadata, and following declarations.  This is not compiler-grade
renamed-entity legality checking or visibility checking.

### Pass898 — entry-body statement-sequence recovery

Pass898 improves structural grammar coverage for Ada entry bodies whose `begin`
keyword is followed immediately by `end`, select-alternative boundaries, or a
terminator instead of a statement sequence.  The token cursor now emits
`Production_Entry_Body_Statement_Sequence` for non-empty entry bodies and
`Production_Entry_Body_Missing_Statement_Recovery_Boundary` for empty or
boundary-only entry body statement sequences, while preserving existing entry
body begin/end metadata and generic recovery points.

This is structural recovery metadata for editor outline and semantic-colouring
consumers; it is not compiler-grade tasking legality checking, entry barrier
legality checking, statement legality checking, overload resolution, compiler
invocation, LSP integration, render-side parsing, background whole-project
scanning, or dirty-state mutation.

### Pass899 — Entry barrier missing-condition recovery

Pass899 adds `Production_Entry_Barrier_Missing_Condition_Recovery_Boundary`
and `Production_Protected_Entry_Barrier_Missing_Condition_Recovery_Boundary`
so malformed entry barriers such as `entry E when is` retain a barrier-specific
recovery boundary instead of allowing `is`, `with`, `begin`, `end`, or `;` to be
classified as a condition expression. This improves structural recovery for
entry declarations/bodies and protected entry-body scans only; it is not
compiler-grade tasking or barrier-condition legality checking.

### Pass900 — entry-family empty-definition recovery

Pass900 improves structural grammar coverage for malformed entry-family
specifications. Empty entry-family definitions such as `entry E ();` now expose
`Production_Entry_Family_Empty_Definition_Recovery_Boundary` while preserving
entry declaration metadata, broader entry-family metadata, valid following
entry-family index subtype metadata, parameter-profile metadata, and generic
recovery points.

This is parser-owned structural recovery metadata only. It is not entry-family
legality checking, discrete subtype validation, tasking legality checking,
overload resolution, compiler invocation, LSP integration, render-side parsing,
background whole-project scanning, or dirty-state mutation.


### Pass901 - abort target-list reserved-boundary recovery

Pass901 adds `Production_Abort_Target_Reserved_Boundary_Recovery_Boundary` so malformed abort target lists with a comma followed by a reserved statement-sequence boundary retain abort-specific recovery metadata without treating the boundary as a task-name target.


### Pass902 - requeue target reserved-boundary recovery

Pass902 adds `Production_Requeue_Target_Reserved_Boundary_Recovery_Boundary` so malformed requeue statements followed directly by reserved statement-sequence boundaries, such as `requeue else;`, retain requeue-specific missing-target recovery metadata without treating the boundary as an entry-name target. Valid following requeue targets remain visible.

### Pass903 - delay expression reserved-boundary recovery

Pass903 adds `Production_Delay_Reserved_Boundary_Recovery_Boundary` so malformed delay statements followed directly by reserved statement-sequence boundaries, such as `delay then;` or `delay until when;`, retain delay-specific missing-expression recovery metadata without treating the boundary token as a delay expression. Valid following delay statements and terminators remain visible.

### Pass904 - goto target reserved-boundary recovery

Pass904 adds `Production_Goto_Target_Reserved_Boundary_Recovery_Boundary` so malformed goto statements followed directly by reserved statement-sequence boundaries, such as `goto else;`, retain goto-specific missing-target recovery metadata without treating the boundary token as a label name. Valid following goto statements, label names, and terminators remain visible.

### Pass905 — return expression reserved-boundary recovery

Pass905 adds `Production_Return_Reserved_Boundary_Recovery_Boundary` so malformed return statements followed directly by reserved statement-sequence boundaries, such as `return else;`, retain return-specific recovery metadata without treating the boundary token as a return expression. Valid following return expressions and terminators remain visible.

### Pass906 — raise target reserved-boundary recovery

Pass906 adds `Production_Raise_Target_Reserved_Boundary_Recovery_Boundary` so malformed raise statements followed directly by reserved statement-sequence boundaries, such as `raise else;`, retain raise-specific recovery metadata without treating the boundary token as an exception name. Valid following raise exception names and terminators remain visible.

### Pass907 — exit target reserved-boundary recovery

Pass907 adds `Production_Exit_Target_Reserved_Boundary_Recovery_Boundary` so malformed exit statements followed directly by reserved statement-sequence boundaries, such as `exit else;`, retain exit-specific recovery metadata without treating the boundary token as a loop name. Valid following exit loop names, `when` conditions, and terminators remain visible.

### Pass908 — assignment expression reserved-boundary recovery

Pass908 adds `Production_Assignment_Reserved_Boundary_Recovery_Boundary` so malformed assignment statements followed directly by reserved statement-sequence boundaries, such as `Value := else;`, retain assignment-specific recovery metadata without treating the boundary token as an expression. Valid following assignment expressions and terminators remain visible.

### Pass909 — call actual association-list recovery

Pass909 adds `Production_Call_Actual_Missing_Actual_Recovery_Boundary`, `Production_Call_Actual_Trailing_Separator_Recovery_Boundary`, and `Production_Call_Actual_Empty_List_Recovery_Boundary` so malformed call actual lists such as `Call ();`, `Call (Item =>, Other => 1);`, and `Call (1,);` retain call-specific recovery metadata. Entry-call actual-list metadata receives the same structural recovery markers. Valid following actual associations, call terminators, and statement visibility remain preserved.

### Pass910 — if/elsif missing-condition recovery

Pass910 adds `Production_If_Statement_Missing_Condition_Recovery_Boundary` and `Production_Elsif_Statement_Missing_Condition_Recovery_Boundary` so malformed statement forms such as `if then` and `elsif then` retain condition-specific recovery metadata. The token cursor avoids fabricating reserved boundaries as ordinary condition expressions and preserves `then` keyword, valid following condition, and `end if` terminator metadata.

### Pass911 — while-loop missing-condition recovery

Pass911 adds `Production_While_Loop_Missing_Condition_Recovery_Boundary` so malformed statement forms such as `while loop` retain while-condition-specific recovery metadata. The token cursor avoids fabricating the `loop` keyword or other statement-sequence boundaries as ordinary condition expressions and preserves `while` keyword, `loop` keyword, valid following condition, and loop terminator metadata.

This improves structural grammar coverage for malformed Ada while-loop conditions. It is not Boolean condition legality checking, expression type checking, loop-statement legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass912 — for/iterator loop domain reserved-boundary recovery

Pass912 adds `Production_For_Loop_Domain_Reserved_Boundary_Recovery_Boundary` and `Production_Iterator_Loop_Domain_Reserved_Boundary_Recovery_Boundary` so malformed iteration schemes such as `for I in else loop` and `for C of else loop` do not fabricate reserved statement-sequence boundary tokens as iteration domains. The parser preserves the broader missing-domain recovery markers, valid following discrete/iterator domains, loop begin keywords, and loop end terminators.

### Pass913 — case selector reserved-boundary recovery

Pass913 adds `Production_Case_Statement_Selector_Reserved_Boundary_Recovery_Boundary` so malformed case statements such as `case is` do not fabricate reserved statement-sequence boundary tokens as selector expressions. The parser preserves `case` statement metadata, the `is` keyword, valid following selector metadata from later case statements, case terminators, and generic recovery points.

This improves structural grammar coverage for malformed Ada case-statement selectors. It is not selector expression legality checking, discrete-choice legality checking, case coverage checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass914 — Extended return initializer reserved-boundary recovery

Pass914 improves structural recovery for malformed extended return object
initializers where `:=` is followed immediately by a reserved do-part or
statement-sequence boundary.  The token cursor now records
`Production_Extended_Return_Initializer_Reserved_Boundary_Recovery_Boundary`
without consuming `do`, `end`, `else`, `elsif`, `exception`, `then`, `when`, or
`;` as an initializer expression, while preserving extended-return `do` and
`end return` metadata for later outline and colouring consumers.

### Pass915 — raise message reserved-boundary recovery

Pass915 adds `Production_Raise_Message_Reserved_Boundary_Recovery_Boundary` so malformed raise statements where `with` is followed directly by a reserved statement-sequence boundary, such as `raise Program_Error with else;`, retain raise-message-specific recovery metadata without treating the boundary token as a message expression. Valid following raise message expressions remain visible.

This improves structural grammar coverage for malformed Ada raise-with-message expressions. It is not message-expression legality checking, exception-name legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass916 — exit-when condition reserved-boundary recovery

Pass916 adds `Production_Exit_When_Reserved_Boundary_Recovery_Boundary` so malformed exit statements where `when` is followed directly by a reserved statement-sequence boundary, such as `exit when else;`, retain exit-when-condition-specific recovery metadata without treating the boundary token as a Boolean condition expression. Valid following exit-when conditions and terminators remain visible.

This improves structural grammar coverage for malformed Ada exit-when conditions. It is not Boolean condition legality checking, loop-name legality checking, exit-statement legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

Pass917 adds `Production_Null_Reserved_Boundary_Recovery_Boundary` so malformed null statements followed directly by reserved statement-sequence boundaries, such as `null else`, retain null-statement-specific recovery metadata in addition to the existing missing-terminator metadata. Valid following null-statement terminators remain visible after recovery.

### Pass918 — aggregate component expression reserved-boundary recovery

Pass918 adds `Production_Aggregate_Component_Expression_Reserved_Boundary_Recovery_Boundary` so malformed aggregate named component associations where `=>` is followed directly by a reserved boundary, such as `(1 => else, 2 => 10)`, retain aggregate-component-specific recovery metadata without treating the boundary token as a component expression. Aggregate arrows, aggregate recovery metadata, and following valid associations remain visible.

This improves structural grammar coverage for malformed Ada aggregate component expressions. It is not aggregate legality checking, component type checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass919 — object initialization expression reserved-boundary recovery

Pass919 adds `Production_Object_Initialization_Reserved_Boundary_Recovery_Boundary` so malformed object declarations where `:=` is followed directly by an aspect/declaration/statement boundary, such as `Broken : Integer := with Volatile;`, retain object-initializer-specific recovery metadata without treating the boundary token as an initialization expression. Object declaration metadata, initialization-expression metadata, broader object-declaration recovery metadata, and following valid declarations remain visible.

This improves structural grammar coverage for malformed Ada object initialization expressions. It is not object declaration legality checking, initializer type checking, aspect legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass920 — Range constraint reserved-boundary recovery

Pass920 adds `Production_Range_Constraint_Reserved_Boundary_Recovery_Boundary` so malformed range constraints where `range` or `..` is followed directly by a reserved statement/declaration boundary, such as `subtype Missing_Lower is Integer range else;` or `subtype Missing_Upper is Integer range 1 .. else;`, retain range-constraint-specific recovery metadata without treating the boundary token as a lower or upper bound expression. Existing missing-lower, missing-upper, constraint-recovery, valid upper-bound, and following declaration metadata remain visible.

### Pass921 — Digits/delta constraint reserved-boundary recovery

Pass921 adds `Production_Digits_Constraint_Reserved_Boundary_Recovery_Boundary` and `Production_Delta_Constraint_Reserved_Boundary_Recovery_Boundary` so malformed digits/delta constraints where `digits` or `delta` is followed directly by a reserved statement/declaration boundary, such as `subtype Missing_Digits is Float digits else;` or `subtype Missing_Delta is Fixed delta else;`, retain constraint-specific recovery metadata without treating the boundary token as a digits/delta expression. Existing missing-expression recovery and valid following constraint-expression metadata remain visible.

### Pass922 — Index/discriminant constraint reserved-boundary recovery

Pass922 adds `Production_Index_Constraint_Missing_Item_Recovery_Boundary`, `Production_Index_Constraint_Reserved_Boundary_Recovery_Boundary`, `Production_Discriminant_Association_Missing_Expression_Recovery_Boundary`, and `Production_Discriminant_Constraint_Reserved_Boundary_Recovery_Boundary` so malformed index and discriminant constraints such as `Vector (else)`, `Vector (1 .. else)`, and `Rec (D => else)` retain constraint-specific recovery metadata without treating reserved boundary tokens as item, bound, or discriminant expressions. Valid following index bounds and discriminant expressions remain visible.

### Pass923 — Profile default reserved-boundary recovery

Pass923 adds `Production_Profile_Default_Reserved_Boundary_Recovery_Boundary` so malformed parameter/profile defaults such as `Item : Integer := )`, `Item : Integer := ;`, and `Item : Integer := with Inline` retain profile-default-specific recovery metadata instead of treating reserved or delimiter boundary tokens as default expressions. Valid following profile/declaration terminator metadata remains visible.

### Pass924 — Object subtype reserved-boundary recovery

Pass924 adds `Production_Object_Subtype_Reserved_Boundary_Recovery_Boundary` so malformed object declarations where the subtype/access definition is missing after the colon, such as `Missing_With : with Volatile;` or `Missing_Then : then;`, retain object-subtype-specific recovery metadata instead of treating reserved/aspect boundary tokens as subtype marks. Object declaration metadata, broader declaration recovery metadata, generic recovery metadata, and valid following object initializers remain visible.

This improves structural grammar coverage for malformed Ada object subtype indications. It is not object declaration legality checking, subtype legality checking, aspect legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass925 — Number initialization reserved-boundary recovery

Pass925 adds `Production_Number_Initialization_Reserved_Boundary_Recovery_Boundary` so malformed named-number declarations where `:=` is followed by a reserved/aspect boundary, such as `Missing_With : constant := with Volatile;` or `Missing_Then : constant := then;`, retain number-initializer-specific recovery metadata instead of treating boundary tokens as initialization expressions. Number declaration metadata, broader declaration recovery metadata, generic recovery metadata, and valid following number initializers remain visible.

This improves structural grammar coverage for malformed Ada named-number initialization expressions. It is not named-number legality checking, static-expression validation, universal type resolution, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass926 — Component default reserved-boundary recovery

Pass926 adds `Production_Component_Default_Reserved_Boundary_Recovery_Boundary` so malformed record component declarations where `:=` is followed by a reserved/aspect boundary, such as `Missing_With : Integer := with Volatile;` or `Missing_Then : Integer := then;`, retain component-default-specific recovery metadata instead of treating boundary tokens as default expressions. Component declaration metadata, generic recovery metadata, and valid following component default expressions remain visible.

Pass927 adds `Production_Discriminant_Default_Reserved_Boundary_Recovery_Boundary` so malformed discriminant specifications where `:=` is followed by a reserved/aspect boundary, such as `D : Integer := with Volatile` or `D : Integer := then`, retain discriminant-default-specific recovery metadata instead of treating boundary tokens as default expressions. Discriminant specification metadata, shared profile-default recovery metadata, generic recovery metadata, and valid following discriminant default expressions remain visible.

Pass928 adds `Production_Array_Index_Reserved_Boundary_Recovery_Boundary` so malformed array index parts where a reserved/declaration boundary appears where an index item or upper bound is required, such as `array (else) of Integer` or `array (1 .. else) of Integer`, retain array-index-specific recovery metadata instead of treating boundary tokens as index expressions. Array type definition metadata, generic constraint recovery metadata, and valid following array index bounds remain visible.

Pass929 adds `Production_Access_Object_Missing_Subtype_Recovery_Boundary` so malformed access-to-object definitions where a reserved/declaration boundary appears where the designated subtype is required, such as `access with Volatile`, `access private`, or `access)`, retain access-object-specific recovery metadata instead of treating boundary tokens as subtype marks. Generic access-type recovery metadata and valid following declarations remain visible.

### Pass930 — Access-definition recovery depth

Pass930 deepens structural recovery for malformed access definitions adjacent to pass929. The token cursor now distinguishes `access all` / `access constant` declarations whose designated subtype is missing via `Production_Access_Mode_Missing_Subtype_Recovery_Boundary`, records `Production_Access_Mode_Subprogram_Conflict_Recovery_Boundary` when a general-access object mode is followed by a subprogram-profile head, retains the actual boundary token after malformed `access protected` through `Production_Access_Protected_Missing_Subprogram_Boundary_Token`, and records `Production_Access_Result_Missing_Subtype_Recovery_Boundary` when an access-to-function `return` reaches an aspect/declaration boundary before a result subtype. This improves structural grammar coverage for malformed access definitions; it is not compiler-grade access-type legality checking, designated-subtype legality checking, profile conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass931 — Generic formal subprogram default recovery

Pass931 improves structural grammar coverage for generic formal subprogram declarations.  The token cursor now distinguishes `is abstract Name` defaults with `Production_Formal_Subprogram_Default_Abstract_Name` and retains `Production_Formal_Subprogram_Default_Missing_Target_Recovery_Boundary` when a formal subprogram default introducer reaches `;`, `with`, or EOF before any default target.  This keeps recovery bounded and lets later generic formal declarations remain visible to Outline and semantic-colouring consumers.  This is parser-owned structural coverage only; it is not compiler-grade generic contract checking, default conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass932 — Formal package declaration header recovery

Pass932 improves structural grammar coverage for formal package declarations. The token cursor now distinguishes missing `is` and missing `new` in `with package P is new G (...)` style declarations with `Production_Formal_Package_Missing_Is_Recovery_Boundary` and `Production_Formal_Package_Missing_New_Recovery_Boundary`, preserves formal package actual parts such as `(<>)` after header recovery, and records `Production_Formal_Package_Named_To_Positional_Order_Recovery_Boundary` when a positional actual appears after a named actual. This keeps malformed formal package declarations bounded so later generic formal declarations remain visible to Outline and semantic-colouring consumers. This is parser-owned structural coverage only; it is not compiler-grade generic contract checking, generic actual conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass933 — Use-clause recovery depth

Pass933 improves structural Ada grammar recovery for malformed use clauses. The token cursor now records `Production_Use_All_Missing_Type_Recovery_Boundary` for `use all ...;` clauses that omit the required `type` keyword, and `Production_Use_Clause_Reserved_Name_Recovery_Boundary` when a use-clause name list reaches a reserved declaration/package boundary where a package name or subtype mark was expected. The new AUnit regression is `Test_Language_Model_Token_Cursor_Use_Clause_Recovery_Depth_Pass933`. This improves structural grammar coverage for use-clause recovery, but it is not compiler-grade visibility legality checking, subtype-mark legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass934 — Representation / operational item recovery depth

Pass934 deepens structural recovery for representation and operational items. The token cursor now records specific productions for representation targets stopped at declaration boundaries, ordinary representation clauses missing `use`, attribute-definition clauses missing the attribute designator after an apostrophe, address clauses whose value is replaced by a reserved boundary, and enumeration representation association lists interrupted by declaration/private boundaries. This improves bounded parser recovery only; it is not compiler-grade representation legality, freezing, layout, or static-expression checking.

### Pass935 — Subprogram contract/aspect placement depth

Pass935 improves structural grammar coverage for subprogram contract/aspect placement. The token cursor now records specific productions for contract aspects attached to subprogram bodies before `is`, null procedure completions after `is null`, abstract subprogram completions after `is abstract`, and expression-function completions after the expression. It also records `Production_Contract_Aspect_Missing_Value_Recovery_Boundary` when a contract aspect association reaches a delimiter before a value expression. This remains parser-owned structural recovery; it is not compiler-grade aspect legality checking, contract conformance checking, static-expression validation, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass936 — Subprogram contract/aspect value-family depth

Pass936 extends the pass935 subprogram contract/aspect work with more precise structural metadata for contract value families. The token cursor now records `Production_Classwide_Contract_Aspect_Mark` for `Pre'Class` and `Post'Class`, and records value-family productions for `Contract_Cases`, `Exceptional_Cases`/`Exit_Cases`, `Always_Terminates`, `Nonblocking`, and `Initializes`/`Depends`-style dataflow aspects. This improves grammar coverage for subprogram contract/aspect structure while remaining parser-owned metadata only; it is not compiler-grade aspect legality checking, static-expression validation, contract conformance checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass937 — Package declarative section recovery depth

Pass937 deepens structural recovery for package specification/body declarative sections. The token cursor now records `Production_Package_Duplicate_Private_Boundary` for a second `private` marker inside a package specification, `Production_Package_Private_Begin_Recovery_Boundary` for `begin` reached from a package private part, and `Production_Package_Body_Private_Declarative_Recovery_Boundary` for an illegal `private` marker inside a package body declarative part. This improves grammar coverage for malformed visible/private/body transitions and helps Outline/semantic-colouring consumers recover without reparsing or consuming the next valid declaration. It remains structural parser metadata only; it is not compiler-grade package legality checking, declarative-part legality checking, visibility checking, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass938 — Anonymous access-to-subprogram recovery refinement

Pass938 deepens anonymous access-to-subprogram structural recovery. The token cursor now exposes `Production_Access_Subprogram_Parameter_Profile_Missing_Close_Recovery_Boundary` for protected/ordinary access-to-subprogram parameter profiles that reach a declaration/aspect boundary before their closing delimiter, and `Production_Access_Result_Null_Exclusion_Missing_Subtype_Recovery_Boundary` for access-to-function result profiles where `return not null` is followed by a boundary instead of a result subtype. This preserves protected procedure/function profile metadata and following declarations for Outline and semantic colouring. It remains parser-owned structural metadata only; it is not compiler-grade access-type legality checking, profile conformance checking, result subtype legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass939 — Expression recovery refinement

Pass939 deepens expression grammar recovery. Conditional expressions now expose an explicit reserved-boundary marker for missing `if`/`elsif` conditions. Case expressions now distinguish missing selectors from missing `is` before alternatives, and parallel reductions now expose reduction-specific recovery when their argument list is malformed. This keeps nested expression recovery local and prevents a malformed expression branch from consuming following declarations. It remains parser-owned structural metadata only; it is not compiler-grade expression legality checking, expected-type resolution, static-expression validation, overload resolution, reduction profile conformance checking, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass940 — Name grammar recovery depth

Pass940 improves structural name grammar recovery for selected names, allocators, and qualified expressions. The token cursor now records `Production_Selected_Name_Reserved_Selector_Recovery_Boundary` when a selected-name dot is followed by a reserved/declaration boundary, `Production_Allocator_Missing_Subtype_Recovery_Boundary` when `new` reaches a boundary before a subtype indication, and `Production_Qualified_Expression_Missing_Operand_Recovery_Boundary` when a qualified-expression operand list is empty or begins at a boundary. Valid selected operator-symbol and character-literal selector metadata remains visible.

This improves structural grammar coverage for name grammar recovery. It is not compiler-grade selected-name legality checking, allocator subtype legality checking, qualified-expression operand legality checking, overload resolution, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass941 — Protected entry-body barrier recovery depth

Pass941 deepens tasking/protected structural recovery for entry bodies. The token cursor now records `Production_Entry_Body_Missing_Barrier_Recovery_Boundary` when an entry body reaches `is` without the required `when` barrier, and records `Production_Protected_Entry_Body_Missing_Barrier_Recovery_Boundary` for the protected-body scanner path. Valid following entry barriers and entry body begin/end metadata remain visible so Outline and semantic-colouring consumers do not need to reparse malformed protected operations. This improves structural grammar coverage only; it is not compiler-grade tasking legality checking, barrier expression legality checking, protected-operation conformance checking, compiler invocation, LSP integration, render-side parsing, background scanning, or dirty-state mutation.

### Pass942 - Ada 2022 expression syntax-tree grammar nodes

Pass942 moves part of the remaining compiler-grade grammar work from token-cursor-only metadata into parser-owned syntax-tree nodes. Ada 2022 declare expressions, delta aggregates, container aggregates with iterator specifications, reduction expressions, iterator specifications, and target-name `@` expressions now have stable node kinds: `Node_Declare_Expression`, `Node_Delta_Aggregate`, `Node_Container_Aggregate`, `Node_Reduction_Expression`, `Node_Iterator_Specification`, and `Node_Target_Name`. Declaration defaults now attach expression children so these forms are visible under object and constant declarations. This improves the grammar model needed by later compiler-grade semantic passes; it does not by itself complete name resolution, overload resolution, type checking, static evaluation, generic contracts, freezing, representation legality, or cross-unit analysis.

### Pass943 - declarative-region model foundation

Pass943 adds `Editor.Ada_Declarative_Regions`, a parser-owned declarative-region model built from `Editor.Ada_Syntax_Tree.Tree_Type`. The model records stable region IDs, owner syntax-tree nodes, parent region IDs, depth, labels, and deterministic fingerprints for compilation units, generic formal parts, package specs/bodies, subprogram specs/bodies, task/protected specs and bodies, entry bodies, record definitions, and block regions. This is the first compiler-grade semantic infrastructure layer needed before direct visibility, use-clause visibility, overload resolution, generic contracts, and legality diagnostics can be integrated. It does not yet perform name lookup or legality checking by itself.

### Pass944 — Direct visibility foundation over declarative regions

Pass944 adds `Editor.Ada_Direct_Visibility`, a compiler-grade semantic building block layered on `Editor.Ada_Declarative_Regions`. The model extracts defining declarations from the parser-owned syntax tree, assigns each declaration to its directly enclosing declarative region, records declaration kind/name/node/range/fingerprint metadata, and provides deterministic case-insensitive lookup in a single region plus enclosing-region lookup. Declarations that open their own region, such as packages, subprogram bodies/specs, type declarations, task/protected bodies, and entry bodies, are recorded in their parent region while still retaining their own nested region for later semantic analysis. This enables upcoming direct-name resolution and diagnostic passes; it does not yet implement use-clause visibility, overload resolution, expected-type filtering, type checking, freezing, representation legality, or cross-unit semantic closure.

## Pass945 — use-clause visibility semantic foundation

Pass945 adds a semantic layer rather than another syntax-only recovery marker:
`Editor.Ada_Use_Visibility` extracts `use`, `use type`, and `use all type`
clauses from the parser-owned syntax tree, binds them to declarative regions,
resolves ordinary package-use targets through direct visibility, and layers
package-use member lookup over direct lookup. Ambiguous package-use exposure is
reported deterministically. `use type` and `use all type` are recorded as stable
metadata for later operator-visibility and type-legality passes.

### Pass 946 - selected-name semantic resolution foundation

Pass946 adds `Editor.Ada_Selected_Name_Resolution`, a compiler-grade semantic
building block for selected names. It resolves package-prefix selected names
through declarative regions, direct visibility, and use visibility, then performs
direct selector lookup in the resolved prefix region. The pass records stable
prefix/selector declarations and deterministic status metadata for later type and
overload layers.

### pass947 — use-type primitive visibility foundation

Pass947 adds `Editor.Ada_Use_Type_Operators`, a semantic model that consumes the syntax tree, declarative-region table, direct-visibility table, and use-visibility clauses.  It resolves `use type` / `use all type` targets, including selected type names such as `P.T`, and records primitive operator/subprogram candidates exposed by those clauses.  This is a compiler-grade semantic foundation; it intentionally does not yet perform profile-aware primitive filtering, expected-type propagation, or overload resolution.

### pass948 — call-candidate overload foundation

Pass948 adds `Editor.Ada_Call_Candidates`, the first overload-resolution foundation layer.  It scans parser-owned call-shaped syntax nodes (`Node_Function_Call` and `Node_Call_Statement`), extracts a normalized callable designator, and records deterministic candidate metadata before expected-type or profile filtering.  Lookup combines direct/enclosing visibility, package-use visibility, and primitive operator visibility from `use type` / `use all type`, preserving unresolved and ambiguous statuses for later diagnostics.  This is a compiler-grade semantic building block; full overload resolution, type checking, expected-type propagation, implicit conversion legality, and profile conformance remain later work.

## pass949 — call-profile shape foundation

Pass949 adds `Editor.Ada_Call_Profile_Shapes`, a semantic model that extracts callable declaration profile shapes and call actual-argument shapes from the parser-owned Ada syntax tree.  Callable records include owning declarative region, normalized declaration name, formal-parameter count, result presence/subtype text, status, source range, and fingerprint.  Actual records include owning region, normalized call designator, positional actual count, named actual count, total actual count, status, source range, and fingerprint.  The AUnit regression `Test_Ada_Call_Profile_Shape_Foundation_Pass949` covers callable arity extraction, null procedure profile shape, positional/named actual counting, nullary call syntax, and deterministic fingerprints.  This is an overload-resolution foundation; it does not yet perform expected-type propagation, full profile conformance, type checking, implicit conversion legality, generic contract checking, freezing, or representation legality.

## pass950 — call-profile filter foundation

Pass950 adds `Editor.Ada_Call_Profile_Filters`, a semantic model that applies deterministic arity and named-actual shape filtering to pre-filter call candidates.  Filter records include the call candidate, call node, declaration ID, callable/actual profile IDs, formal count, positional/named/total actual counts, status, source range, and deterministic fingerprint.  The AUnit regression `Test_Ada_Call_Profile_Filter_Foundation_Pass950` covers compatible positional calls, too-many-actual rejection, named-actual classification, and model fingerprinting.  This is an overload-resolution foundation; later passes still need formal-name matching, defaulted-formal legality, expected-type propagation, full profile conformance, type checking, implicit conversions, generic contracts, freezing, representation legality, and cross-unit semantic closure.

## Pass951 — Formal-name/default overload-filter metadata

Pass951 adds semantic metadata rather than new syntax productions. Callable profile shapes now retain normalized formal-name lists and defaulted-formal counts/names. Actual profile shapes retain normalized named-actual names. The call-profile filter classifies matched named actuals, unknown named actuals, and missing required non-defaulted formals. AUnit coverage: `Test_Ada_Call_Profile_Formal_Name_Filter_Pass951`.

### Pass952 — Call-resolution result classification

Pass952 adds `Editor.Ada_Call_Resolution`, a compiler-grade overload-resolution staging layer above call candidates and profile filters. The model records one deterministic resolution result per call-shaped syntax node, including candidate count, filter count, viable profile-filter count, rejected count, status, source range, and fingerprint. It classifies missing call names, unresolved names, pre-profile ambiguity, absent filters, no viable profile, unique profile matches, and ambiguous viable profile sets.

This improves the compiler-grade overload-resolution foundation by turning candidate/filter metadata into diagnostic-facing call-resolution states. It does not yet complete expected-type propagation, full profile conformance, type checking, implicit conversion legality, generic contract matching, freezing/representation legality, or cross-unit semantic closure.


### Pass953 expected-type context foundation

Added `Editor.Ada_Expected_Type_Contexts` to attach deterministic expected-subtype context metadata to call-shaped expression nodes in declaration defaults, return contexts, simple assignment targets, and nested positional/named parameter actuals. This is a compiler-grade semantic staging layer for expected-type overload filtering and type checking; type compatibility, implicit-conversion legality, generic contracts, freezing/representation legality, and cross-unit semantic closure remain in downstream semantic consumers.

### Pass954 — Expected-call result-subtype filtering

Pass954 adds `Editor.Ada_Expected_Call_Filters`, connecting expected-subtype contexts from declaration defaults/return contexts to unique call-resolution results. The model classifies callable result subtype text as matching or mismatching the expected subtype context while preserving unresolved/context-free states for later diagnostics. AUnit coverage: `Test_Ada_Expected_Call_Filter_Foundation_Pass954`.

### Pass955 — Subtype compatibility foundation for expected-call filtering

Pass955 adds `Editor.Ada_Subtype_Compatibility`, a conservative compatibility model used by expected-call filtering. It classifies normalized subtype names into predefined integer/real and universal numeric families, records exact matches, universal-numeric compatibility, known numeric incompatibility, and indeterminate user-defined relationships. `Editor.Ada_Expected_Call_Filters` now stores compatibility status and separates exact result-subtype matches from compatible universal-numeric cases and unresolved user-defined cases. AUnit coverage: `Test_Ada_Subtype_Compatibility_Foundation_Pass955`.

### Pass956 — Declaration-derived type graph foundation

Pass956 adds `Editor.Ada_Type_Graph`, a compiler-grade type-system foundation built from parser-owned syntax-tree declarations, declarative regions, and direct visibility. The model records stable type IDs, declaration IDs, owning regions, normalized names, type categories, parent subtype text, resolved parent declarations/types where available, unresolved/ambiguous base status, and deterministic fingerprints. It classifies type/subtype/formal type declarations and exposes ancestry/compatibility queries for exact, subtype-of, and derived-from relationships. AUnit coverage: `Test_Ada_Type_Graph_Foundation_Pass956`.

### Pass957 — Type-graph-aware expected-call compatibility

Pass957 connects the declaration-derived type graph to expected-call filtering. `Editor.Ada_Subtype_Compatibility` gains graph-aware exact/subtype/derived compatibility statuses, and `Editor.Ada_Expected_Call_Filters.Build_With_Type_Graph` records both subtype-compatibility and raw type-graph compatibility metadata. Calls returning a subtype can satisfy an expected ancestor subtype when the relationship is present in `Editor.Ada_Type_Graph`; derived-type ancestry remains explicit-conversion evidence and is not treated as an implicit overload selection. Known different roots remain mismatch metadata for later diagnostics. AUnit coverage: `Test_Ada_Expected_Call_Filter_Type_Graph_Compatibility_Pass957`.

### Pass958 - private views, interfaces, and class-wide compatibility

Pass958 extends the semantic type graph beyond declaration-derived subtype ancestry. Private partial views are linked to same-name full views in compatible declarative regions, interface type declarations are classified explicitly, and expected-call filtering can mark `Root'Class` contexts compatible with declaration-derived descendant results. This is a compiler-grade type-system building block, not yet full private-view visibility, interface conformance, or complete overload legality.

### Pass959 - implicit conversion metadata for expected-call filtering

Pass959 adds a dedicated implicit-conversion staging layer for compiler-grade expected-type analysis. It classifies existing subtype/type-graph compatibility results into implicit same-type/subtype compatibility, universal numeric compatibility, class-wide compatibility, explicit-conversion-required derived-type ancestry, known different-root rejection, or indeterminate cases. Expected-call filters now retain this metadata, allowing later diagnostics and overload resolution to distinguish "type graph related" from "implicitly usable in this context".

### Pass960 - static expression model foundation

Pass960 introduces `Editor.Ada_Static_Expressions` as the first compiler-grade static-expression staging model. The model records named-number and static-constant bindings per declarative region and evaluates a conservative integer subset: literals, references to earlier static bindings, parentheses, unary signs, and integer `+`, `-`, `*`, `/`, `mod`, and `rem`. Unresolved names, malformed expressions, non-static constructs, division by zero, and cycle-like cases are retained as explicit statuses for later legality diagnostics.

This improves compiler-grade semantic foundations for range checks, representation clauses, freezing diagnostics, and generic matching. It is not yet complete Ada static expression evaluation.


### Pass961 - static attribute expression foundation

Pass961 extends `Editor.Ada_Static_Expressions` with scalar subtype-bound staging and bounded static attribute evaluation. The model now records range-constrained type/subtype bounds as deterministic metadata, resolves `T'First` and `T'Last` when both bounds are static integers, and stages `T'Pos (...)` / `T'Val (...)` integer arguments conservatively. Unsupported attributes such as `Image` are retained as explicit unsupported-attribute statuses rather than being misclassified as unresolved names. Regression coverage is in `Test_Ada_Static_Attribute_Expression_Foundation_Pass961`. This is a compiler-grade static-expression building block; complete Ada static evaluation still requires real/universal arithmetic, enumeration literal positions, static string/character handling, modular overflow rules, static attribute completeness, generic contracts, freezing/representation legality, and cross-unit semantic closure.

### Pass962 - enumeration-position static-expression foundation

Pass962 extends `Editor.Ada_Static_Expressions` with deterministic enumeration literal position metadata. Enumeration literal declarations under parser-owned enumeration type declarations are staged with type name, literal name, source range, declaration region, zero-based position, and fingerprint. Static evaluation now uses that metadata for enumeration `T'Pos (Literal)` and `T'Val (Position)` cases while preserving unresolved literal operands for later diagnostics. This is a compiler-grade static-expression building block; full Ada static legality still requires complete discrete type handling, character/string static values, real/universal arithmetic, modular overflow rules, generic contracts, freezing/representation legality, and cross-unit semantic closure.

### Pass963 - modular-integer static-expression foundation

Pass963 extends `Editor.Ada_Static_Expressions` with deterministic modular type metadata. Modular type declarations are staged with the declared type name, owning region, modulus expression text, evaluated static modulus value where available, source range, and fingerprint. The model also adds `Reduce_Modular_Integer`, which reduces a resolved static integer expression by the known modular type modulus while preserving unresolved type names and malformed/non-static modulus information for later diagnostics. Regression coverage is in `Test_Ada_Static_Modular_Integer_Foundation_Pass963`. This is a compiler-grade static-expression building block; full Ada static legality still requires complete discrete-type semantics, universal/real arithmetic, complete modular overflow/range legality, generic contracts, freezing/representation legality, and cross-unit semantic closure.

### Pass964 - real/universal numeric static-expression foundation

Pass964 extends `Editor.Ada_Static_Expressions` with real static-value metadata and deterministic numeric expression evaluation. The model now stages `Static_Value_Real` values with `Real_Value`, evaluates decimal/exponent literals, named real constants, unary signs, and `+`, `-`, `*`, `/` arithmetic, while retaining explicit division-by-zero metadata. `Evaluate_Integer_Expression` remains integer-only by classifying real-valued expressions as non-static in integer-only contexts. Regression coverage is in `Test_Ada_Static_Real_Numeric_Foundation_Pass964`. This is a compiler-grade static-expression building block; full Ada static legality still requires fixed-point arithmetic, full universal numeric resolution, complete real-type legality, generic contracts, freezing/representation legality, and cross-unit semantic closure.

### Pass965 - fixed-point static-expression foundation

Pass965 extends `Editor.Ada_Static_Expressions` with deterministic fixed-point type metadata. The model stages fixed-point declarations with type name, owning region, delta expression, optional digits expression, optional range bounds, evaluated static values where available, and fingerprints. The new `Lookup_Fixed_Type`, `Static_Fixed_Type`, and `Quantize_Fixed_Value` APIs allow later legality passes to classify fixed-point static values as representable, delta-mismatched, out-of-range, unresolved, or malformed while preserving snapshot ownership. Regression coverage is in `Test_Ada_Static_Fixed_Point_Foundation_Pass965`. This is a compiler-grade static-expression/type-system building block; full Ada fixed-point legality, universal numeric resolution across all contexts, generic contracts, freezing/representation legality, and cross-unit semantic closure remain future work.

### Pass966 - generic contract model foundation

Pass966 introduces `Editor.Ada_Generic_Contracts` as the first compiler-grade generic contract staging layer. The model records formal type, object, subprogram, and package declarations from direct visibility metadata, preserves default/default-box markers where the parser exposes them, and stages generic instantiation actual shape with positional/named actual counts and named-actual names. Regression coverage is in `Test_Ada_Generic_Contract_Foundation_Pass966`. This is a compiler-grade generic-analysis building block; full formal/actual conformance, generic body contract visibility, overload matching, private view rules, freezing/representation legality, and cross-unit semantic closure remain future work.

### Pass967 - generic formal/actual matching foundation

- `Editor.Ada_Generic_Contracts` now records deterministic match entries for generic instantiations.
- The model resolves the target generic declaration through direct visibility, locates the generic formal region, and classifies positional/named actual shape against required/defaulted formals.
- New regression: `Test_Ada_Generic_Actual_Matching_Foundation_Pass967`.
- This is compiler-grade generic-contract staging, not complete type conformance, formal subprogram profile conformance, formal package contract matching, generic body visibility, freezing/representation legality, or cross-unit closure.

### Pass968 - generic formal/actual kind conformance foundation

Pass968 extends `Editor.Ada_Generic_Contracts` with deterministic actual-kind metadata for generic instantiations. Actuals are classified conservatively as type, object, subprogram, package, unknown, or malformed using staged syntax/direct-shape cues such as predefined type names, literals, attribute subprogram references, and `new ...` package actuals. Formal/actual matching now records compatible, mismatched, and unknown kind counts and can classify a generic instantiation as `Generic_Actual_Match_Formal_Kind_Mismatch` when the actual shape is incompatible with the formal kind. Regression coverage is in `Test_Ada_Generic_Formal_Actual_Kind_Conformance_Pass968`. This is a compiler-grade generic-contract building block; complete Ada generic conformance still requires resolved actual declarations in all contexts, formal subprogram profile conformance, formal package contract matching, overload resolution, private-view rules, freezing/representation legality, and cross-unit semantic closure.


### Pass969 - generic formal subprogram profile conformance

Pass969 extends `Editor.Ada_Generic_Contracts` with formal subprogram profile conformance metadata. Generic formal subprograms now retain parameter-count, normalized parameter-subtype shape, result presence, and result-subtype metadata. Generic instantiation actuals retain positional/named actual designator text, allowing declaration-shaped subprogram actuals to be resolved through direct visibility and compared against the formal profile. The match model now distinguishes formal-kind mismatches from formal subprogram profile mismatches and records deterministic compatible/mismatched/unknown profile counts. Regression coverage is in `Test_Ada_Generic_Formal_Subprogram_Profile_Conformance_Pass969`. This is a compiler-grade generic-contract building block; full Ada generic conformance still requires overload-aware subprogram actual selection, formal package contract matching, generic body contract visibility, private-view rules, freezing/representation legality, and cross-unit semantic closure.


### Pass970 - generic formal package contract conformance

Pass970 extends `Editor.Ada_Generic_Contracts` with formal package contract conformance metadata. Generic formal package records now retain their expected target generic name, normalized target, and box actual-state marker. Generic instantiation matching resolves package actuals through direct visibility, recognizes inline `new Generic (...)` package actuals, verifies that declaration-shaped package actuals are package instantiations, and compares the actual package instance target generic against the formal package contract. The match model now distinguishes formal package contract mismatches and unknown formal package contract cases, including unresolved actuals, ambiguous actuals, non-instance package actuals, wrong-generic package instances, unknown formal contracts, and malformed package actuals, with deterministic compatible/mismatched/unknown counters exposed through `Formal_Package_Compatible_Count_For_Instance`, `Formal_Package_Mismatch_Count_For_Instance`, and `Formal_Package_Unknown_Count_For_Instance`. Regression coverage is in `Test_Ada_Generic_Formal_Package_Contract_Conformance_Pass970`. This pass adds one compiler-grade generic-contract building block. Full compiler-grade Ada analysis remains incomplete until remaining layers such as overload-aware actual selection, generic body contract visibility, private-view rules, default-expression legality, freezing/representation legality, and cross-unit semantic closure are fully integrated.

## pass971 — Generic body contract visibility

- Added generic body contract-visibility metadata in `Editor.Ada_Generic_Contracts`.
- Generic declarations now retain deterministic links from their formal region to the matching body region when a package/subprogram body is present in the snapshot.
- Generic formal type/object/subprogram/package declarations are queryable from the matching body region via body-contract APIs.
- Body-not-found and missing-formal-region states are explicit coverage states rather than silent absence.
- Regression: `Test_Ada_Generic_Body_Contract_Visibility_Pass971`.

## pass972 — Overload-aware generic subprogram actual selection

- `Editor.Ada_Generic_Contracts` now enumerates overloaded subprogram actual candidates for generic formal subprograms instead of collapsing ambiguous names to unknown.
- Selection is profile-driven and applies existing simple formal type substitution before comparing the actual subprogram profile to the formal profile.
- The model records overload candidate counts, selected conforming actuals, ambiguous conforming actuals, unresolved sets, and a dedicated ambiguous-profile status.
- Regression: `Test_Ada_Generic_Formal_Subprogram_Overload_Selection_Pass972`.

## pass973 — Generic default-expression legality foundation

- Generic-contract semantic layer now has a static-aware build path, `Build_With_Static`, for object-formal default and actual expression legality.
- Formal-object defaults and explicit object actual expressions are classified as static, illegal, or unknown/unresolved using `Editor.Ada_Static_Expressions`.
- The match model records checked/static/illegal/unknown counters plus non-static, malformed, unresolved, and division-by-zero detail counters.
- Regression: `Test_Ada_Generic_Default_Expression_Legality_Pass973`.
\nPass974: Generic-contract analysis now retains formal subprogram parameter mode vectors and classifies declaration-shaped subprogram actuals with same arity/subtypes but nonconforming modes as deterministic mode mismatches. Regression coverage: Test_Ada_Generic_Formal_Subprogram_Mode_Conformance_Pass974.

### pass975 — type-graph-aware generic profile conformance

- `Editor.Ada_Generic_Contracts` can now build with `Editor.Ada_Type_Graph` for generic formal subprogram profile checks.
- Text-only profile matching remains conservative; type-graph builds accept known subtype relationships after simple formal type substitution.
- Regression: `Test_Ada_Generic_Formal_Subprogram_Type_Graph_Conformance_Pass975`.


Pass976 adds a compiler-grade generic profile-conformance building block for formal subprogram null-exclusion and anonymous access-to-subprogram profile matching. Generic actual matching now records and reports null-exclusion mismatches and access-profile mismatches separately from generic profile mismatches, with deterministic counters and regression coverage in Test_Ada_Generic_Formal_Subprogram_Null_Access_Conformance_Pass976. Full compiler-grade Ada analysis remains incomplete until private-view rules, freezing, representation legality, cross-unit closure, and full expression type inference are fully integrated.

### pass976 — formal subprogram null/access profile conformance

- `Editor.Ada_Generic_Contracts` now distinguishes formal subprogram null-exclusion mismatches from generic profile mismatches.
- Anonymous access-to-subprogram profile mismatches are counted and reported separately.
- Public counters expose null-exclusion and access-profile mismatch totals per instantiation.
- Regression: `Test_Ada_Generic_Formal_Subprogram_Null_Access_Conformance_Pass976`.


Pass977 coverage note: generic-contract matching now includes calling-convention conformance for formal subprogram actuals. Explicit Convention aspects are normalized, default Ada convention is staged conservatively, and mismatched conventions are reported as a distinct generic actual-match category.

### pass978 — generic formal subprogram defaulted-parameter profile conformance

- `Editor.Ada_Generic_Contracts` now records required/defaulted parameter vectors for formal subprogram profiles.
- Generic subprogram actual matching now classifies defaulted-parameter contract mismatches separately from broad profile, mode, null-exclusion, access-profile, convention, overload, and type-graph mismatches.
- New public counter: `Subprogram_Profile_Default_Mismatch_Count_For_Instance`.
- Regression: `Test_Ada_Generic_Formal_Subprogram_Default_Conformance_Pass978`.

This is a compiler-grade profile-conformance building block; remaining Ada semantic closure still requires private-view visibility, freezing, representation legality, and cross-unit completion.

### Pass979 generic formal subprogram class-wide profile conformance

- `Editor.Ada_Generic_Contracts` now records class-wide profile mismatches for generic formal subprogram actuals.
- New match status: `Generic_Actual_Match_Formal_Subprogram_Class_Wide_Mismatch`.
- New public counter: `Subprogram_Profile_Class_Wide_Mismatch_Count_For_Instance`.
- Regression: `Test_Ada_Generic_Formal_Subprogram_Class_Wide_Conformance_Pass979`.
- This is a compiler-grade building block; full Ada legality still depends on the remaining semantic layers.

### Pass980 generic formal subprogram parameter-name profile conformance

- `Editor.Ada_Generic_Contracts` now records normalized parameter-name vectors for formal subprogram profiles.
- Generic subprogram actual matching now classifies parameter-name contract mismatches separately from broad profile, mode, null-exclusion, access-profile, convention, defaulted-parameter, class-wide, overload, and type-graph mismatches.
- New match status: `Generic_Actual_Match_Formal_Subprogram_Name_Mismatch`.
- New public counter: `Subprogram_Profile_Name_Mismatch_Count_For_Instance`.
- Regression: `Test_Ada_Generic_Formal_Subprogram_Name_Conformance_Pass980`.
- This is a compiler-grade building block; full Ada legality still depends on the remaining semantic layers.

### Pass981 — generic formal subprogram result-subtype conformance

- Extended `Editor.Ada_Generic_Contracts` result-profile checking for formal subprogram actuals.
- Function result subtypes are now checked after simple generic formal type substitution.
- `Build_With_Type_Graph` and `Build_With_Static_And_Type_Graph` can accept subtype-compatible and class-wide-compatible function results through `Editor.Ada_Type_Graph`.
- New match status: `Generic_Actual_Match_Formal_Subprogram_Result_Mismatch`.
- New public counters: `Subprogram_Profile_Result_Compatible_Count_For_Instance`, `Subprogram_Profile_Result_Mismatch_Count_For_Instance`, and `Subprogram_Profile_Result_Unknown_Count_For_Instance`.
- Regression: `Test_Ada_Generic_Formal_Subprogram_Result_Conformance_Pass981`.

### Pass982 — private-view visibility foundation

- Added `Editor.Ada_Private_View_Visibility`.
- Links type-graph private partial/full views to package spec/private-part/body context metadata.
- Adds deterministic context queries for partial-only versus full-view visibility at a source line.
- Regression: `Test_Ada_Private_View_Visibility_Foundation_Pass982`.

### Pass983 — private-view-aware subtype compatibility

- Extended `Editor.Ada_Private_View_Visibility` with full-view lookup and effective type-view queries.
- Extended `Editor.Ada_Subtype_Compatibility` with `Check_With_Private_View`.
- Added private-view compatibility statuses for partial-view, full-view, and hidden full-view cases.
- Regression: `Test_Ada_Private_View_Subtype_Compatibility_Pass983`.

### Pass984 — freezing-point model foundation

- Added `Editor.Ada_Freezing_Points`.
- Records freezable declarations with first conservative freeze line, cause node, and cause kind.
- Classifies representation clauses as before, at, or after the target freeze point when the target can be resolved.
- Regression: `Test_Ada_Freezing_Point_Foundation_Pass984`.
Pass986: added record representation component-clause legality coverage, including component resolution, duplicate detection, static storage/bit-range evaluation, and reversed/negative position classification.

### Pass987 — enumeration representation legality

Adds compiler-grade representation-legality staging for enumeration representation clauses. The model validates enumeration targets, named/positional literal associations, literal coverage, duplicate literal associations, duplicate static values, non-static values, and representation-value ordering while keeping parser analysis deterministic and snapshot-owned.

### Pass988 — address clause legality
- Representation legality now stages Address clause target/value checks in the parser-owned representation model.
- Address targets are checked against freezable object/subprogram targets while type targets are classified separately.
- Address values are classified as static address expressions, null literals, raw literals, non-static names, or malformed expressions.

### Pass989 — Size/Alignment/Storage_Size representation legality

- `Editor.Ada_Representation_Legality` now classifies Size-family, Alignment, and Storage_Size clause target compatibility.
- Integer-valued representation clauses distinguish non-static/malformed values, real static values, non-positive integer values, and valid positive integer values.
- Regression: `Test_Ada_Size_Alignment_Storage_Legality_Pass989`.

### Pass990 — interfacing representation legality

- `Editor.Ada_Representation_Legality` now classifies Convention, Import, Export, External_Name, and Link_Name clauses.
- Interfacing values are staged as convention identifiers, static Booleans, static strings, malformed values, or unknown identifiers.
- Import/Export conflicts and Link_Name/External_Name dependency on enabled Import/Export are represented as deterministic model statuses and counters.
- Regression: `Test_Ada_Interfacing_Representation_Legality_Pass990`.


### Pass991 — stream attribute representation legality

- `Editor.Ada_Representation_Legality` now recognizes Read, Write, Input, Output, and Put_Image representation clauses.
- Stream clauses stage subprogram-designator metadata, classify malformed values, and reject incompatible non-type/subtype targets.
- Profile-unknown stream designators are preserved explicitly for later callable-profile conformance.
- Regression: `Test_Ada_Stream_Attribute_Representation_Legality_Pass991`.

### Pass992 — stream attribute profile conformance

- `Editor.Ada_Representation_Legality.Build_With_Stream_Profiles` layers direct-visibility and callable-profile metadata over stream attribute clauses.
- Read/Write/Output/Put_Image stream designators are checked as two-parameter procedures.
- Input stream designators are checked as one-parameter functions.
- Resolved compatible and mismatched stream profiles are separated from profile-unknown designators.
- Regression: `Test_Ada_Stream_Attribute_Profile_Conformance_Pass992`.


Pass 993: operational attribute legality now covers Boolean-valued operational attributes and storage-order attributes with target-shape and value classification.


## Pass994 representation/aspect legality unification

Representation-property aspects are now treated as first-class inputs to the representation-legality model. Attribute-definition clauses and aspects share clause-kind classification, target checks, value checks, freezing integration where available, source-form metadata, deterministic counters, and AUnit coverage.

### Pass995 cross-unit semantic closure foundation

Pass995 adds `Editor.Ada_Cross_Unit_Closure`, a deterministic model over the project index for Ada unit-family relationships. The model stages spec/body, body/spec, child/parent, parent/child, and separate-body parent links with explicit resolved/missing/ambiguous/overflow status metadata. This gives later compiler-grade semantic passes a stable cross-file closure boundary without invoking a compiler, file reloads, LSP, or rendering-side parsing.

### Pass996 note

Cross-unit semantic closure now includes context dependency links for ordinary `with`, `limited with`, `private with`, and context `use` package clauses. The dependency model is snapshot-owned, project-index-backed, deterministic, and preserves missing/ambiguous/overflow states for later semantic consumers.

## Pass997 cross-unit spec/body consistency

Pass997 extends the cross-unit semantic-closure model with deterministic spec/body consistency metadata. The model now records confirmed package/subprogram spec/body pairs and missing, ambiguous, overflow, role-mismatch, and name-mismatch conditions with stable fingerprints. This is parser/index-owned semantic data and does not require rendering-side parsing, file reloads, dirty-state mutation, or compiler invocation.

Pass998: cross-unit closure now includes deterministic child-unit and private-child legality metadata. Child library units are classified as resolved public children, resolved private children, missing-parent children, ambiguous-parent children, overflowed children, or parent-role mismatches, with stable query APIs and AUnit coverage in `Test_Ada_Cross_Unit_Child_Private_Legality_Pass998`.

Pass999: cross-unit closure now includes deterministic separate-body legality metadata. Separate bodies are classified separately from raw separate-parent links as resolved parent bodies, missing parents, ambiguous parents, overflow, parent-role mismatches, or missing parent-name text, with stable query APIs and AUnit coverage in `Test_Ada_Cross_Unit_Separate_Body_Legality_Pass999`.

Pass1000: expression type inference now has a parser-owned foundation model. Literals, names, selected names, calls, operators, qualified expressions, aggregates, and attributes are classified into deterministic type-status metadata with unresolved and ambiguous cases preserved for later compiler-grade propagation.

Pass1001 note: expression type inference now has an opt-in expected-type propagation layer. Declaration-default contexts and existing expected-context metadata are staged into deterministic expression records with compatible/propagated/mismatch/unknown statuses for later diagnostics and overload/type checking.

Pass1002 note: expression type inference now records operator operand/result metadata for predefined numeric, Boolean, short-circuit, relational, and membership-shaped operators. Unknown and mismatched operands are preserved explicitly for diagnostics and later overload-aware passes.

Pass1003: expression aggregate context inference adds context-sensitive aggregate/container-aggregate metadata, component-shape counters, and deterministic unknown/mismatch preservation to the Ada expression-type model.

Pass1004 update: expression type inference now includes conversion and qualified-expression target/operand metadata. The model exposes deterministic counters for resolved conversion targets, compatible operands, explicit-conversion operands, mismatches, and unknown conversion cases, with regression coverage in `Test_Ada_Expression_Conversion_Qualified_Inference_Pass1004`.

Pass1005 update: expression type inference now includes attribute-reference result metadata for scalar bounds, range/length/pos, image/value, address, size/alignment/storage-size, callable/terminated, and access-valued attributes. Unknown attributes and unresolved prefixes are preserved explicitly, with regression coverage in `Test_Ada_Expression_Attribute_Reference_Inference_Pass1005`.

Pass1006: Added conditional/declare/reduction expression type inference metadata in Editor.Ada_Expression_Types. The model now tracks compatible/mismatched/unknown conditional branches, Boolean quantified results, declare-expression result staging, reduction-expression result staging, deterministic counters, and fingerprint contribution. Regression coverage: Test_Ada_Expression_Conditional_Declare_Reduction_Inference_Pass1006.


Pass1007: Added expression membership/range inference metadata. Membership expressions now retain Boolean result plus operand/choice compatibility state; range expressions retain bound subtype compatibility state; deterministic counters and fingerprints cover resolved, mismatch, and unknown cases.

Pass1008: Added expression target-name/update inference metadata. Ada 2022 target-name @ expressions now preserve context-required versus context-propagated status, delta/update aggregates retain expected/source subtype compatibility metadata, and deterministic counters/fingerprints expose compatible, mismatch, and unknown update-expression cases.


Pass1009: expression type inference now stages indexed component and slice metadata, including prefix subtype, index subtype, result element/slice subtype, and deterministic counters for compatible/unknown index checks.

Pass1010: expression type inference now stages explicit dereference and access-designator metadata, including access-prefix subtype, designated subtype, Access-family attribute target/result subtype, and deterministic counters for resolved, target-error, and unknown cases.
Pass1011: expression type inference now stages allocator expression metadata for new-subtype constructs, expected access contexts, designated subtype matching, allocator result subtype inference, and deterministic resolved/error/unknown counters.

Pass1012: expression type inference now stages parameter-association expected-type propagation for call actuals, including positional/named formal mapping, formal subtype context, actual/formal compatibility and mismatch classification, unresolved/ambiguous formal-context preservation, deterministic counters, and AUnit coverage.

Pass1013: expression type inference now stages call actual type-resolution metadata, comparing positional/named actual expression subtype shapes against selected callable formal subtype context and preserving compatible, mismatched, unknown, unresolved, and ambiguous call classifications with deterministic counters and AUnit coverage.

Pass1014: expression type inference now stages overload-aware operator metadata. Primitive operators exposed through use type / use all type can be combined with operand subtype shapes, preserving resolved, ambiguous, mismatch, and unknown operator-overload states for later compiler-grade resolution and diagnostics.

Pass1015: expression type inference now stages universal numeric final-resolution metadata. Universal integer and universal real expressions are resolved against expected subtype contexts, including integer/modular/real/fixed families and static integer subtype range checks, while mismatch and unknown cases remain explicit for later diagnostics.

Pass1016: expression type inference now stages type-graph-aware aggregate validation metadata. Record aggregate associations retain compatible/missing/duplicate component counts when component declarations are available; array aggregates retain element-compatible/mismatch/unknown counts from expected element subtype context.

Pass1017: Expression type inference now includes raise-expression/no-return metadata with exception target, message shape, expected result context, deterministic counters, and AUnit coverage.

### Pass1018 — Boolean-context expression inference

Boolean-context expression analysis now stages expected-Boolean metadata for short-circuit and condition-shaped constructs. The model records compatible, mismatched, and unknown Boolean operands without rendering-side parsing, file IO, dirty-state mutation, or compiler invocation.

### Pass1019 — string and array concatenation inference

Expression analysis now stages concatenation-specific metadata for `&`, including string-family, character/string, expected-context, and array-family result inference. Mismatched and unknown operands remain explicit model metadata without rendering-side parsing, file IO, dirty-state mutation, or compiler invocation.

### Pass1020
Pass1020 adds dispatching-call inference metadata to `Editor.Ada_Expression_Types`, including primitive target, static binding, dynamic dispatch candidate, controlling-result, ambiguous, unresolved, and unknown classifications with deterministic counters and fingerprints.
### Pass1021
Pass1021 adds expression diagnostics projection for type-inference metadata, covering expected-type mismatches, operator/call/aggregate/conversion/membership/range/dereference/allocator/Boolean-context/numeric/concatenation failures, unresolved expressions, and unknown expressions with deterministic counters and fingerprints.
Pass1022: cross-unit visibility integration now projects context dependencies from closure into lookup-facing metadata for ordinary with, limited with, private with, and context use package clauses.

Pass1023: limited-with incomplete-view rules now project limited-with dependencies into lookup-facing metadata that distinguishes incomplete-view visibility from hidden full-view visibility.

### Pass1024 - private-with visibility constraints

Added `Editor.Ada_Private_With_Rules`, a deterministic lookup-facing projection
for private-with dependencies.  The model consumes cross-unit visibility
metadata, distinguishes visible-part/private-part/body lookup contexts, hides
private-with dependencies from ordinary visible-part lookup, exposes them in
private-part and body contexts, and retains missing/ambiguous/overflow cases as
explicit diagnostic metadata.  The regression
`Test_Ada_Private_With_Visibility_Constraints_Pass1024` covers the new counters,
context-sensitive lookup API, and fingerprinting behavior.

### Pass1025 - body/spec declaration conformance

Pass1025 adds `Editor.Ada_Body_Spec_Conformance`, a snapshot-owned semantic
closure projection over the project index and cross-unit spec/body consistency
model.  It confirms package body/spec pairs, confirms subprogram body/spec pairs
when retained profile summaries match, and preserves profile mismatches,
missing counterparts, ambiguous counterparts, overflow, role mismatches, and
name mismatches as deterministic metadata.

`Test_Ada_Body_Spec_Declaration_Conformance_Pass1025` covers the conformance
counters, profile mismatch preservation, missing counterpart preservation, and
deterministic fingerprints.

### Pass1026 - child-unit visibility from parent/private-child contexts

Pass1026 adds `Editor.Ada_Child_Unit_Visibility`, projecting child-unit legality metadata into context-sensitive lookup metadata for public children, private children, parent private parts, parent bodies, and external clients. Missing, ambiguous, overflow, and role-mismatch parent cases remain explicit diagnostic inputs, and the model remains deterministic, bounded, snapshot-owned, and free of render-side parsing or editor-state mutation.

- pass1027: added separate-body/body-stub placement legality metadata via Editor.Ada_Separate_Body_Stub_Rules, including matched/missing/ambiguous stub checks and parent-resolution preservation.

### Pass1028 - freezing interactions

Added `Editor.Ada_Freezing_Interactions` to stage generic-instantiation freezing, private partial/full-view freezing visibility, and body-context freezing metadata from parser-owned semantic models.

### Pass1029 - cross-unit representation target resolution

Added `Editor.Ada_Cross_Unit_Representation_Targets`, which allows representation-legality consumers to preserve cross-unit target-prefix resolution metadata for representation clauses whose targets are not found in the local declarative region. The model consumes existing cross-unit visibility and keeps limited/private/missing/ambiguous/overflow states explicit.

Pass1030 note: added Editor.Ada_Record_Layout_Validation as a compiler-grade record-layout validation building block. It derives deterministic bit-span metadata from record representation component clauses, detects overlapping component spans, preserves staged static/component errors, and exposes counters/fingerprints for diagnostics and future semantic-colouring projection. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as deeper alignment/size proof, overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.
Pass1031 note: added Editor.Ada_Record_Storage_Order_Rules as a compiler-grade record representation building block. It projects Bit_Order and Scalar_Storage_Order clauses onto record component layout spans, classifies explicit order application, conflicts, operational errors, layout errors, and exposes deterministic counters/fingerprints for diagnostics and future semantic-colouring projection. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

Pass1032 note: added Editor.Ada_Operational_Attribute_Rules as a compiler-grade operational representation building block. It consumes unified representation legality metadata after aspect/attribute-definition normalization, classifies duplicate operational properties, contradictory Boolean values, propagated target/value errors, and exposes deterministic counters/fingerprints for diagnostics and future semantic-colouring projection. Full compiler-grade Ada analysis remains incomplete until the remaining layers such as overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

Pass1033: added aspect inheritance/overriding metadata through `Editor.Ada_Aspect_Inheritance_Rules`. The projection consumes unified representation/aspect legality and type-graph inheritance data to retain inherited properties, explicit overrides, contradictory override metadata, private-view override state, deterministic counters, and stable fingerprints without rendering-side parsing or mutation.

Pass1034: added generic formal type conformance metadata through `Editor.Ada_Generic_Formal_Type_Conformance`. The projection consumes parser-owned generic-contract and type-graph snapshots to classify private, derived, interface, access, scalar/discrete, array, and record formal type actuals, while preserving unresolved/mismatched/unknown states and deterministic counters/fingerprints without rendering-side parsing or mutation.

### Pass1035 - generic formal package nested actual conformance

`Editor.Ada_Generic_Formal_Package_Nested_Conformance` now stages nested actual comparisons for formal package declarations. Formal package contracts with explicit nested actuals and box actuals are checked against named or inline package-instance actuals without rendering-side parsing or file IO. The model records compatible, boxed-compatible, mismatch, missing, wrong-generic, unresolved, malformed, and unknown states for later diagnostics.

### Pass1036 - generic renaming and nested generic instantiation visibility

`Editor.Ada_Generic_Renaming_Visibility` stages generic renaming declarations and nested generic instantiations as parser-owned semantic metadata. Renaming targets are classified as resolved, unresolved, ambiguous, non-generic, malformed, or unknown. Instantiations through renamed generics are resolved back to the original generic declaration/formal region when available, while direct nested instantiations remain separately visible for later contract matching.

### Pass1037 - generic object default-expression type conformance

- Added deterministic metadata for formal-object default and explicit object actual type compatibility.
- Uses static-expression values plus type-graph subtype/bound metadata to classify compatible object expressions, type mismatches, range errors, unknown static values, missing actuals/defaults, and unknown formal subtypes.
- Keeps generic contract analysis snapshot-owned and bounded; no rendering, workspace, command, keybinding, file-save, or reload paths are involved.

### Pass1038 generic contract diagnostics projection

Pass1038 adds `Editor.Ada_Generic_Contract_Diagnostics`, which projects generic formal-type conformance, formal-package nested conformance, generic renaming/nested-instantiation visibility, and formal-object default/actual type conformance into deterministic diagnostics with stable spans and fingerprints.

Pass1039 update:
- Added Editor.Ada_Cross_Unit_Diagnostics to project cross-unit visibility and closure metadata into deterministic diagnostics.
- Covers missing/ambiguous dependencies, limited-view full-view restrictions, private-with visible-part restrictions, body/spec conformance failures, private-child visibility restrictions, child-parent errors, and separate-body stub/parent errors.
- Added Test_Ada_Cross_Unit_Diagnostics_Projection_Pass1039.

Pass1040: Added representation/freezing diagnostics projection through Editor.Ada_Representation_Diagnostics, covering representation legality, record layout, storage order, operational attributes, aspect inheritance, and freezing interaction metadata with deterministic spans/severities/fingerprints.

Pass1041: Added semantic-colouring diagnostics projection through Editor.Ada_Semantic_Colour_Projection, converting expression, generic-contract, cross-unit, and representation/freezing diagnostics into deterministic render-safe diagnostic overlays.

Pass1042: Added semantic diagnostic snapshot guards through Editor.Ada_Semantic_Diagnostic_Snapshot_Guards. Semantic diagnostic and colouring overlays now carry path, buffer token, buffer revision, lifecycle generation, request token, and analysis fingerprint metadata and are rejected before projection when stale.

Pass1043: Added semantic diagnostics feed through Editor.Ada_Semantic_Diagnostic_Feed. The feed unifies expression, generic-contract, cross-unit, and representation/freezing semantic diagnostic overlays after snapshot-guard validation and exposes one deterministic IDE-facing API without parsing, file IO, mutation, or rendering-side semantic work.

Pass1044: Added semantic diagnostic indexing/search through Editor.Ada_Semantic_Diagnostic_Index. The index consumes the unified, snapshot-guarded semantic diagnostic feed and exposes deterministic lookup by line range, position, severity, source family, token kind, and syntax node without parsing, file IO, mutation, or rendering-side semantic work.

## Pass1045 diagnostic navigation coverage

Pass1045 adds `Editor.Ada_Diagnostic_Navigation` as an IDE-facing navigation projection over the snapshot-guarded semantic diagnostic index. The model covers deterministic first/last diagnostic lookup, next/previous navigation from source line/column positions, and severity-filtered navigation for error, warning, and informational diagnostics. Rejected stale indexes expose no navigation targets. This is diagnostic-navigation integration only; it does not expand parsing, mutate buffers, save or reload files, or perform rendering-side analysis.

## Pass1046 diagnostic panel projection coverage

Pass1046 adds `Editor.Ada_Diagnostic_Panel_Projection` as an IDE-facing panel model over the snapshot-guarded semantic diagnostic index. The model covers deterministic panel rows, stable row identity, severity grouping, source-family grouping, optional file/unit grouping metadata, selected-row state, nearest-row selection, rejected stale index withholding, and deterministic fingerprints. This is diagnostic presentation integration only; it does not expand parsing, mutate buffers, save or reload files, or perform rendering-side analysis.

## Pass1047 diagnostic status-line summary coverage

Pass1047 adds `Editor.Ada_Diagnostic_Status_Line` as an IDE-facing status summary over the snapshot-guarded semantic diagnostic index. The model covers deterministic diagnostic totals, highest-severity state, compact summary text, current-line/current-position counters, nearest diagnostic metadata, source-family counters, stale-index withholding, and fingerprints. This is diagnostic presentation integration only; it does not expand parsing, mutate buffers, save or reload files, or perform rendering-side analysis.


## Pass1048 diagnostic quick-fix skeleton coverage

Pass1048 adds `Editor.Ada_Diagnostic_Quick_Fix_Skeleton` as a projection-only quick-fix candidate layer over the snapshot-guarded semantic diagnostic index. Coverage includes deterministic candidate identity, navigation/explanation/source-family review skeletons, severity/action/source counters, diagnostic-identity queries, stale-index withholding, explicit producer-owned edit-hint metadata, and fingerprints. No source edits are synthesized or applied by this layer.

## Pass1049 diagnostic provenance coverage

Pass1049 adds `Editor.Ada_Diagnostic_Provenance` as an IDE-facing explain model over guarded semantic diagnostic indexes. Coverage includes stable provenance identity, source-family explanation labels, source/diagnostic fingerprint preservation, source-chain stage counters, diagnostic-identity queries, stale-index withholding, and deterministic fingerprints.

## Pass1050 diagnostic suppression / baseline coverage

Pass1050 adds `Editor.Ada_Diagnostic_Suppression_Baseline` as an IDE-facing metadata model over guarded semantic diagnostic indexes. Coverage includes deterministic rule identity, suppression and baseline classifications, rule reasons, diagnostic identity preservation, source/severity/status counters, diagnostic/status queries, stale-index withholding, rejected-entry totals, and fingerprints. The layer does not apply source edits and does not mutate buffers or workspace state.

Pass1051 note:
- Added overload ambiguity diagnostics over expression-type metadata. The model explains call/operator/universal-numeric ambiguity, mismatch, and unknown causes without adding rendering-side parsing, source mutation, file IO, command registration, workspace mutation, or compiler invocation.

Pass1052 update:
- Integrated overload ambiguity/candidate-rejection cause records into the expression diagnostics projection via `Editor.Ada_Expression_Diagnostics.Build_With_Overload_Causes`.
- Preserves deterministic overload cause detail, candidate counters, source spans, severity, and fingerprints for downstream semantic-colouring and diagnostic-feed consumers.
- Keeps the path projection-only and snapshot-owned; no render-side parsing, file IO, buffer mutation, command registration, workspace mutation, or edit application is introduced.

Pass1053 update:
- Added `Editor.Ada_Cross_Unit_Lookup_Integration`, routing cross-unit context visibility into deterministic lookup-facing metadata for ordinary with, use-package, limited, private, missing, ambiguous, and overflow cases.
- The pass preserves local-first lookup integration through `Resolve_With_Local` and keeps the model snapshot-owned, bounded, projection-only, and free of rendering-side parsing or editor-state mutation.

Pass1054 update:
- Added selected-name cross-unit lookup consumer integration through `Editor.Ada_Selected_Name_Resolution.Build_With_Cross_Unit` and `Resolve_Selected_With_Cross_Unit`.
- Cross-unit prefixes are now represented in selected-name metadata after local/direct/use lookup misses, preserving cross-unit status, target unit/path, lookup identity, and fingerprints.
- Coverage remains conservative for unsupported imported-unit shapes, but project cross-unit selected-name typing now resolves imported selector subtype metadata through the project index for live expression, assignment, return, and diagnostic consumers.

Pass1055: cross-unit selected-name expression inference added; expression metadata now preserves cross-unit selected-name target/selector identity and deterministic counters while maintaining snapshot-owned analysis invariants.

#### Pass1056 — view-aware compatibility integration

Adds `Editor.Ada_View_Aware_Compatibility` as a deterministic consumer-facing bridge for private-view and limited-view compatibility effects. The pass classifies existing subtype-compatibility and cross-unit selected-name expression metadata into compatible, private-view, limited-view, unresolved, incompatible, and indeterminate buckets while preserving stable identities, spans, labels, and fingerprints. It remains projection/analysis-only and does not add rendering-side parsing, file IO, dirty-state mutation, command registration, or workspace mutation.| Pass1057 | Expression diagnostics view-compatibility projection | Projects private/limited/cross-unit view compatibility barriers into deterministic expression diagnostics while keeping compatible views non-diagnostic. | Test_Ada_Expression_Diagnostics_View_Compatibility_Pass1057 |
| Pass1058 | Generic view-aware compatibility | Classifies generic actual/default checks with private/limited/cross-unit view compatibility metadata so generic contract consumers can distinguish view barriers from ordinary mismatches. | Test_Ada_Generic_View_Compatibility_Pass1058 |

| Pass1059 | Generic contract diagnostics view-compatibility projection | Projects generic actual/default private-view, limited-view, and cross-unit unresolved barriers into generic contract diagnostics while preserving view identity and fingerprints. | Test_Ada_Generic_Contract_Diagnostics_View_Compatibility_Pass1059 |

Pass1060: Generic instantiated body analysis
- Adds `Editor.Ada_Generic_Instantiated_Body_Analysis`.
- Projects generic actual/default substitutions into matching generic body contract contexts.
- Preserves body contract identity, formal/instance identity, view-barrier metadata, cross-unit selector metadata, counters, and fingerprints.
- Regression: `Test_Ada_Generic_Instantiated_Body_Analysis_Pass1060`.

| Pass1061 | Generic instantiated-body diagnostics projection | Projects generic instantiated-body substitution statuses into generic contract diagnostics with substitution/body-contract identity, view metadata, counters, and deterministic fingerprints. | Test_Ada_Generic_Contract_Diagnostics_Instantiated_Body_Pass1061 |


### Pass1063 — Nested body/spec diagnostics projection

Pass1063 extends `Editor.Ada_Cross_Unit_Diagnostics` with `Build_With_Nested`, projecting `Editor.Ada_Nested_Body_Spec_Conformance` results into the cross-unit diagnostics model. Diagnostics now cover nested missing body declarations, extra body declarations, ambiguous body declarations, kind/profile mismatches, profile-unknown cases, and nonconforming enclosing unit pairs while preserving nested conformance identity/status, declaration names, spans, severity, messages, counters, and deterministic fingerprints. The existing `Build` path remains unchanged for first-order cross-unit diagnostics. Regression coverage is in `Test_Ada_Cross_Unit_Diagnostics_Nested_Body_Spec_Pass1063`.

This pass adds one compiler-grade building block for nested body/spec diagnostic projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1064 — Selected-name representation target resolution

Pass1064 adds `Editor.Ada_Selected_Representation_Targets`, a deterministic representation-target consumer that combines `Editor.Ada_Cross_Unit_Representation_Targets` with `Editor.Ada_Selected_Name_Resolution`. Representation clauses whose targets are selected names now preserve selected-name identity/status, prefix/selector text, visible cross-unit target unit/path, candidate counts, classification counters, and deterministic fingerprints. The layer distinguishes local selected targets, cross-unit visible selected targets, use-visible selected targets, limited/private-view barriers, missing/ambiguous/overflow prefixes, selector errors, and non-selected targets without parsing, file IO, buffer mutation, command registration, workspace mutation, or rendering-side semantic work. Regression coverage is in `Test_Ada_Selected_Representation_Targets_Pass1064`.

## Pass1065 selected representation diagnostics projection

Pass1065 extends representation/freezing diagnostics so selected-name representation target resolution failures from `Editor.Ada_Selected_Representation_Targets` are visible to the ordinary diagnostic pipeline. Covered cases include limited/private selected prefixes, missing/ambiguous/overflow prefixes, missing/ambiguous selectors, and unresolved selected representation targets. This is a diagnostic projection layer only; it does not add parser forms or renderer-side semantic work.


### Pass1066

Added exact record layout size/alignment validation via `Editor.Ada_Record_Layout_Exact_Validation`, including exact/padded/exceeded Size clause classification, Alignment power-of-two validation, component-error propagation, target lookup, counters, fingerprints, and AUnit coverage in `Test_Ada_Record_Layout_Exact_Size_Alignment_Pass1066`.

### Pass1067 — Exact record layout diagnostics projection

Pass1067 projects exact record-layout validation results into `Editor.Ada_Representation_Diagnostics`. Size clauses smaller than occupied bits, padded Size clauses, invalid Alignment clauses, and propagated component-layout errors are now represented as deterministic representation diagnostics with stable spans, severity, counters, and fingerprints. The projection is metadata-only and does not introduce rendering-side parsing, file IO, buffer mutation, command registration, or workspace mutation.

Pass1068: Added Editor.Ada_Stream_Attribute_Profile_Conformance for deterministic stream attribute target-type profile conformance and representation diagnostic projection. The pass checks stream handler presence, ambiguity, procedure/function mode, arity, Input result subtype, target errors, and unknown profile cases while preserving snapshot-owned metadata and stale-safe diagnostic invariants.
Pass1069: Added Editor.Ada_Generic_Formal_Package_Substitutions for deterministic per-nested-actual formal package substitution metadata and generic diagnostic projection. The pass expands formal package nested conformance checks into substituted, boxed, mismatch, missing, wrong-generic, unresolved, malformed, and unknown entries while preserving formal/instance identity, nested position, source spans, fingerprints, and projection-only editor invariants.

### Pass1070 — Dispatching-call legality diagnostics

Added `Editor.Ada_Dispatching_Call_Legality` and expression-diagnostic integration for dispatching-call legality barriers. The pass consumes existing expression inference metadata only, preserves deterministic identities/spans/fingerprints, and projects unresolved, ambiguous, or unknown dispatching legality cases into the expression diagnostic model without rendering-side parsing, file IO, dirty-state mutation, command registration, workspace mutation, or edit application.

### Pass1071 — Overload ranking metadata

Pass1071 adds `Editor.Ada_Overload_Ranking`, a deterministic overload-ranking staging layer over expression type metadata and overload ambiguity causes. It classifies exact matches, implicit-conversion-ranked choices, universal-numeric tie-breaks, ambiguous-after-ranking cases, rejected candidate sets, and unknown ranking states while preserving expression identity, syntax node, candidate/rejection counts, source spans, source/cause fingerprints, and deterministic result fingerprints. `Editor.Ada_Expression_Diagnostics` now accepts ranking metadata through `Build_With_Overload_Ranking` and `Build_With_All_Semantic_Causes_And_Ranking`, projecting only rejected, ambiguous, or unknown ranking states as diagnostics while keeping successful ranking as non-mutating provenance metadata. Regression coverage is in `Test_Ada_Overload_Ranking_Pass1071`.

### Pass1072 — Overload ranking provenance/explain metadata

Adds `Editor.Ada_Overload_Ranking_Provenance`, linking ranked overload metadata to expression diagnostics. The coverage matrix now includes provenance for exact matches, implicit-conversion ranking, universal-numeric tie-breaks, ambiguous ranked outcomes, rejected candidate sets, unknown ranking evidence, and unlinked diagnostic/ranking metadata.

Pass1073 note: unified diagnostic provenance now accepts overload-ranking provenance through Editor.Ada_Diagnostic_Provenance.Build_With_Overload_Ranking.  The layer is projection-only, snapshot-guarded, and keeps overload-ranking explanation metadata out of rendering, command, workspace, and buffer mutation paths.

Pass1074 note: diagnostic quick-fix skeletons now accept overload-ranking provenance through Editor.Ada_Diagnostic_Quick_Fix_Skeleton.Build_With_Overload_Ranking.  The layer is projection-only, preserves ranked overload evidence for IDE explanation actions, and does not parse, apply edits, mutate buffers, touch workspace state, or perform rendering-side semantic work.

Pass1075 note: diagnostic action routing now joins quick-fix skeletons with diagnostic navigation, panel rows, provenance/explain items, status-line nearest-target metadata, and explicit feed edit hints through `Editor.Ada_Diagnostic_Action_Router`. The layer is projection-only and preserves stale-result rejection; it does not parse, mutate buffers, save/reload files, register commands, touch workspace state, or perform rendering-side semantic work.

Pass1076 note: diagnostic command projection now turns diagnostic action routes into deterministic command-facing descriptors through `Editor.Ada_Diagnostic_Command_Projection`, preserving explicit feed edit hints as descriptor metadata for executor-owned application. The layer is projection-only and does not register commands, invoke commands, apply edits, parse, mutate buffers, save/reload files, touch workspace state, or perform rendering-side semantic work. Rejected/stale action-route models expose no active command descriptors while preserving rejected-command totals.

Pass1077 note: diagnostic command palette projection now turns diagnostic command descriptors into deterministic command-palette-facing entries through `Editor.Ada_Diagnostic_Command_Palette_Projection`. The layer is projection-only and does not register command aliases, mutate keybindings, invoke commands, apply edits, parse, mutate buffers, save/reload files, touch workspace state, or perform rendering-side semantic work. Rejected/stale command projection models expose no active palette entries while preserving rejected-entry totals.

- Pass1078: added diagnostic keybinding hint projection over diagnostic command-palette entries, preserving command/action identity and stale-result withholding without mutating keybindings or command registration.

### Pass1079 diagnostic workspace/session projection

Pass1079 adds a projection-only diagnostic workspace/session model over diagnostic keybinding hints. The layer produces stable persistable diagnostic/action keys, selection/restore-candidate metadata, counters, and fingerprints without mutating workspace/session state, registering commands, changing keybindings, invoking commands, parsing, saving/reloading files, mutating buffers, or adding rendering-side semantic work. Rejected/stale inputs expose no active workspace entries and retain rejected totals.

### Pass 1080

Adds diagnostic render projection coverage through `Editor.Ada_Diagnostic_Render_Projection`.  The pass keeps diagnostic rendering data immutable and projection-only: accepted workspace/session diagnostic state is converted into stable draw-facing rows and badges, while stale/rejected models expose no active rows and retain rejected-row counts.  No parser, renderer, command, keybinding, workspace, buffer, edit, save, or reload mutation path is introduced.

### Pass1082 diagnostic recovery status projection

- Added `Editor.Ada_Diagnostic_Recovery_Status` as a consumer of diagnostic
  lifecycle recovery.
- Provides compact retained/changed/missing/rejected-stale status rows and
  headline summaries for IDE diagnostics recovery surfaces.
- Preserves stable source spans, severity, semantic source family, token kind,
  syntax node, persistent keys, lifecycle/render/index identities, and
  deterministic fingerprints.

### Pass1083

Added deterministic diagnostic recovery action projection.  Recovery/status rows for retained, changed, missing, and stale diagnostic UI state can now be surfaced as non-mutating IDE action metadata with stable identities and fingerprints.  The layer remains projection-only and preserves the parser, rendering, command, keybinding, workspace, buffer, and file lifecycle invariants.

- Pass1084: added projection-only diagnostic recovery command descriptors for lifecycle/recovery actions while preserving stale-result rejection and no mutation boundaries.

### Pass1085 diagnostic recovery command palette projection

Pass1085 adds a command-palette-facing projection for diagnostic lifecycle/recovery command descriptors. It preserves stable diagnostic identities, source spans, command kinds, availability states, recovery headlines, persistent keys, display/search/sort text, and fingerprints while exposing deterministic lookup and count helpers.

| Pass1086 | Diagnostic recovery keybinding hint projection | Adds `Editor.Ada_Diagnostic_Recovery_Keybinding_Hint_Projection` for deterministic recovery command keybinding/invocation hint metadata. | Projection-only; no command/keybinding/workspace/render mutation. |

Pass1087: Added Editor.Ada_Diagnostic_Recovery_Workspace_Projection for deterministic workspace/session-facing diagnostic recovery UI state descriptors. The projection consumes recovery keybinding hints, derives stable persistable keys without buffer-internal identifiers, preserves recovery/action/status/lifecycle/render/index identities and fingerprints, and remains projection-only with no workspace mutation, command registration, keybinding changes, edits, parsing, save/reload, or rendering-side semantic work.

Pass1088: Added Editor.Ada_Diagnostic_Recovery_Render_Projection. Diagnostic recovery workspace/session state can now be projected into immutable render-safe rows and recovery badges without rendering-side parsing, rendering-side semantic work, command registration, keybinding/workspace mutation, edits, buffer mutation, or file save/reload.

Pass1089: Added Editor.Ada_Diagnostic_Recovery_Render_Lifecycle. Diagnostic recovery render rows can now be validated against fresh guarded semantic diagnostic indexes and classified as retained, changed, missing, or rejected stale without rendering-side parsing, rendering-side semantic work, command registration, keybinding/workspace mutation, edits, buffer mutation, or file save/reload.

Pass1090: Added Editor.Ada_Diagnostic_Recovery_Render_Status. Diagnostic recovery render lifecycle rows now have a compact IDE-facing status surface with retained/changed/missing/rejected-stale summaries, badge/headline preservation, persistent-key metadata, and deterministic fingerprints without rendering-side parsing, rendering-side semantic work, command registration, keybinding/workspace/session mutation, edits, buffer mutation, or file save/reload.

### Pass1091 diagnostic recovery render action projection

Added `Editor.Ada_Diagnostic_Recovery_Render_Action_Projection` as a deterministic projection-only consumer of diagnostic recovery render status.  It exposes retained/changed/missing/stale/restore-candidate recovery-render actions for IDE consumers while preserving stable diagnostic identities, source spans, severity/source metadata, persistent keys, and fingerprints.  No parsing, command registration, command aliases, command invocation, keybinding mutation, workspace/session mutation, edits, buffer mutation, file save/reload, or rendering-side semantic work is introduced.

Pass1092: Added Editor.Ada_Diagnostic_Recovery_Render_Command_Projection as a projection-only command-facing layer for diagnostic recovery-render actions. It preserves stable recovery render/action/diagnostic identities and availability metadata while avoiding command registration, aliases, keybinding/workspace mutation, edits, parsing, file save/reload, and rendering-side semantic work. Regression: Test_Ada_Diagnostic_Recovery_Render_Command_Projection_Pass1092.

Pass1093: Added `Editor.Ada_Diagnostic_Recovery_Render_Command_Palette_Projection` for deterministic command-palette-facing diagnostic recovery-render command entries. This is an IDE projection layer only and introduces no parser, grammar, command registration, keybinding mutation, workspace mutation, buffer mutation, file save/reload, or rendering-side semantic work.

Pass1094 note: added `Editor.Ada_Diagnostic_Recovery_Render_Keybinding_Hint_Projection` as a projection-only bridge from recovery-render command-palette entries to deterministic keybinding/invocation hint metadata. The layer preserves stable diagnostic/recovery-render identities, source spans, severities, lifecycle/recovery headline metadata, persistent keys, previous/current diagnostic fingerprints, and hint fingerprints while avoiding command registration, aliases, keybinding mutation, command invocation, edits, parsing, buffer mutation, file save/reload, workspace/session mutation, rendering, or rendering-side semantic work.

Pass1095 note: added `Editor.Ada_Diagnostic_Recovery_Render_Workspace_Projection` as a projection-only bridge from recovery-render keybinding hints to deterministic workspace/session-facing UI state descriptors. The layer preserves stable diagnostic/recovery-render identities, source spans, severities, lifecycle/recovery headline metadata, persistent diagnostic/action/command keys, previous/current diagnostic fingerprints, selected/restore-candidate metadata, and workspace fingerprints while avoiding workspace/session mutation, command registration, aliases, keybinding mutation, command invocation, edits, parsing, buffer mutation, file save/reload, rendering, or rendering-side semantic work.

Pass1096: added final render-safe diagnostic recovery-render projection over recovery-render workspace/session state, preserving stable keys and rejected-state accounting without rendering-side semantic work.

Pass1098: Added Editor.Ada_Diagnostic_Recovery_Render_Final_Status. Final recovery-render lifecycle rows now have a compact IDE-facing status surface with clean/retained/changed/missing/rejected-stale classification, deterministic summaries, diagnostic/status/headline/final-row-kind/source-lifecycle lookup helpers, stale-input withholding, rejected-row totals, and stable status fingerprints. This is a projection-only consumer and does not expand parsing, mutate buffers, save/reload files, register commands, mutate workspace/keybinding/render state, or perform rendering-side semantic analysis.

Pass1099 note: Added `Editor.Ada_Assignment_Legality` as a semantic rule-completion pass for assignment and object-initialization legality.  The pass is snapshot-owned and projection-free: it consumes existing expression, subtype, static, type/view metadata and classifies target/source compatibility, constant/in-formal target errors, null-exclusion violations, static range violations, private/limited view barriers, unresolved universal numeric cases, and indeterminate cases without render-side parsing or editor mutation.

Pass1100 note: added `Editor.Ada_Return_Legality`, a snapshot-owned semantic legality layer for Ada return statements. It consumes assignment/object-initialization legality results and classifies legal procedure/function/extended returns plus illegal expression shape, incompatible result subtype, private/limited view barriers, unresolved result metadata, static range violations, unresolved universal numeric returns, and No_Return subprogram return statements. No diagnostic UI projection chain layer, rendering-side parsing, file save/reload, or mutable IDE-surface side effect is introduced.

Pass1101 note: widened the semantic pass scope by adding `Editor.Ada_Conversion_Access_Aggregate_Legality`, a snapshot-owned semantic legality layer covering conversion and qualified-expression legality, numeric/static range conversion checks, tagged/class-wide conversion classification, access/null-exclusion/accessibility foundations, allocator designated-subtype compatibility, aggregate structural legality, and container aggregate missing-aspect classification. Added `Test_Ada_Conversion_Access_Aggregate_Legality_Pass1101` and registered it in `Core_Suite`. No diagnostic UI projection chain layer, rendering-side parsing, file save/reload, dirty-state mutation, command/keybinding/workspace mutation, or render mutation is introduced.

Pass1102: Added `Editor.Ada_Control_Flow_Legality`, a wide snapshot-owned semantic legality layer for Ada control-flow and statement rules.  The pass classifies Boolean condition legality, case choice staticness/coverage/duplicates, exit/goto/label target legality, exception handler choices, raise targets, select/accept/requeue target checks, and return-path completeness without render-side parsing or editor mutation.

Pass1103 update: added `Editor.Ada_Tasking_Protected_Legality`, a snapshot-owned semantic legality layer for Ada task/protected type and body matching, entry declarations/bodies/families, protected barriers, accept/requeue legality, protected operation restrictions, select integration, and linked control-flow legality propagation. Added and registered `Test_Ada_Tasking_Protected_Legality_Pass1103`. No diagnostic projection chain, rendering-side parsing, file save/reload, dirty-state mutation, or command/keybinding/workspace/render mutation is introduced.

### Pass1104 - Tagged/derived/private/interface legality layer

Pass1104 adds `Editor.Ada_Tagged_Derived_Legality`, a snapshot-owned semantic legality layer for tagged derivation, private extensions, interface derivation, inherited primitive operation conflicts, overriding declarations, abstract-operation requirements, dispatching-call legality propagation, and class-wide conversion classification. Regression coverage is in `Test_Ada_Tagged_Derived_Legality_Pass1104`.

This is semantic legality coverage, not a parser-production expansion. It performs no rendering-side parsing, file save/reload, dirty-state mutation, command/keybinding/workspace mutation, render mutation, compiler invocation, LSP integration, external parser generation, Python integration, or shell-script integration.

Pass1105: Added `Editor.Ada_Generic_Instance_Freezing_Representation_Legality` as semantic coverage for generic instance closure across instantiated-body substitutions, formal-package substitutions, generic-induced freezing, representation items after instance freezing, and linked assignment/return/conversion/tagged semantic legality failures. This is semantic legality integration rather than parser-production expansion.

Pass1106: Added `Editor.Ada_Cross_Unit_Semantic_Closure` as semantic coverage that connects cross-unit dependency/lookup state into the widened legality layers for assignment, return, expression/conversion/access/aggregate, control-flow, tasking/protected, tagged/derived, generic-instance, and representation contexts. This is cross-unit semantic closure integration rather than parser-production expansion.

Pass1107: wide semantic legality diagnostics bridge added for Pass1099-Pass1106 compiler-grade legality layers, preserving snapshot ownership and deterministic fingerprints.

Pass1108 update:
- Integrated the Pass1107 wide semantic legality diagnostics into the unified snapshot-guarded semantic diagnostic feed via Build_With_Wide_Legality.
- Wide assignment, return, conversion/access/aggregate, control-flow, tasking/protected, tagged/derived, generic-instance, and cross-unit legality failures now participate in the normal diagnostic feed and index.
- Stale wide legality inputs and rejected base semantic guards expose zero active feed rows while preserving rejected-entry accounting.
- Added AUnit coverage in Test_Ada_Wide_Semantic_Diagnostic_Feed_Integration_Pass1108 and registered it in Ada_Language_Suite.

Pass1109 update: added Editor.Ada_Overload_Resolution_Legality as a compiler-grade overload/operator legality building block. It classifies exact and preference-based selections, expected-type and universal numeric preferences, primitive operator preference, implicit/class-wide/access conversion evidence, named/defaulted profile evidence, visibility failures, view barriers, cross-unit unresolved states, linked semantic errors, ambiguity, unknown, and indeterminate states. The layer is snapshot-owned and deterministic, with AUnit coverage in Test_Ada_Overload_Resolution_Legality_Pass1109.

Pass1110: added Editor.Ada_Staticness_Range_Predicate_Legality, a snapshot-owned semantic legality layer for Ada staticness requirements, range/choice legality, predicate metadata, linked assignment/return/conversion/access/aggregate/overload legality, deterministic lookup helpers, counters, and fingerprints. No diagnostic UI projection chain, rendering-side parser, file save/reload, dirty-state mutation, command/keybinding/workspace mutation, render mutation, compiler invocation, LSP bridge, external parser generator, Python integration, or shell-script integration is introduced.

Pass1111 update: added `Editor.Ada_Accessibility_Lifetime_Legality`, a widened snapshot-owned Ada accessibility/lifetime/aliasing legality layer covering accessibility levels, dynamic checks, null exclusion, access kind mismatches, aliased-object requirements, allocator/access-conversion/return-accessibility checks, anonymous access parameter escapes, access discriminant lifetime checks, dangling renaming risk metadata, and linked assignment/return/conversion/staticness failures. Added and registered `Test_Ada_Accessibility_Lifetime_Legality_Pass1111`.


Pass1112: Added contract/aspect legality coverage for pre/postconditions, invariants, predicates, assertions, contract cases, Global/Depends/refined flow aspects, placement/duplicate errors, view barriers, and linked widened semantic legality failures.


## Pass1113 elaboration/dependence legality

Adds snapshot-owned semantic classification for `Elaborate`, `Elaborate_All`, `Elaborate_Body`, `Preelaborate`, `Pure`, `Remote_Types`, `Shared_Passive`, call/access-before-elaboration, body-before-use, circular elaboration dependence, and linked cross-unit/contract/overload blockers.


Pass1114: Added Editor.Ada_Unit_Completion_Order_Legality for compiler-grade unit/body completion and declaration-order legality, including package/subprogram/task/protected/generic body completion, private/deferred/incomplete completion, body-stub/separate-body completion, declaration-before-use, private-part ordering, frozen-before-completion, view barriers, and linked semantic blockers. Added AUnit coverage and deterministic counters/lookups/fingerprints.

Pass1115 update: added Editor.Ada_Renaming_Alias_Visibility_Legality as a widened semantic legality layer for Ada renaming declarations, alias views, direct/use/use-type visibility, selected-name targets, homograph hiding, private/limited-view barriers, aliased-target requirements, self/circular renames, dangling rename risks, invalid/duplicate use clauses, and linked accessibility/overload/cross-unit/completion blockers. Added and registered Test_Ada_Renaming_Alias_Visibility_Legality_Pass1115. The pass remains snapshot-owned, deterministic, bounded, and non-mutating.

Pass1116 update: added Editor.Ada_Exception_Finalization_Legality as a widened semantic legality layer for Ada exception, raise, handler, propagation, cleanup/finalization, task termination, controlled primitive, and No_Return contexts. It consumes control-flow, accessibility/lifetime, contract/aspect, elaboration/dependence, renaming/visibility, and unit completion/order legality metadata; classifies legal raise/reraise/handler/renaming/propagation/finalization/No_Return cases; and reports unresolved/ambiguous/non-exception raise targets, reraise outside handlers, handler choice errors, raise-expression result issues, invalid exception renaming targets, controlled finalization primitive/profile/order/propagation/abort/master errors, No_Return violations, private/limited view barriers, and linked semantic blockers. Added and registered Test_Ada_Exception_Finalization_Legality_Pass1116. The pass remains snapshot-owned, deterministic, bounded, and non-mutating.

Pass1117 update: added Editor.Ada_Representation_Layout_Stream_Integration_Legality. The pass integrates representation legality, exact record layout, stream attribute profile conformance, generic-instance freezing/representation effects, accessibility/lifetime, staticness/range/predicate, completion/order, contract/aspect, and exception/finalization legality into one deterministic snapshot-owned semantic model. It adds Test_Ada_Representation_Layout_Stream_Integration_Legality_Pass1117 and keeps the analysis non-mutating, bounded, and independent of rendering, command, keybinding, workspace, save/reload, file IO, compiler invocation, LSP, and external parser generators.

Pass1118 update: added Editor.Ada_Integrated_Semantic_Closure as a widened semantic closure layer. It folds wide semantic legality diagnostics with overload, staticness/range/predicate, accessibility/lifetime, contract/aspect, elaboration/dependence, unit completion/order, renaming/alias/visibility, exception/finalization, and representation/layout/stream integration blockers into one deterministic snapshot-owned closure model. It classifies local/cross-unit/with-use legal closure, limited/private-view barriers, missing/ambiguous/overflow/stale/rejected dependencies, individual legality blockers, multiple blockers, and indeterminate closure. Added and registered Test_Ada_Integrated_Semantic_Closure_Pass1118 with counters, lookups, and fingerprints. The pass remains non-mutating and introduces no rendering-side parser, save/reload path, dirty-state mutation, command/keybinding/workspace/render mutation, compiler invocation, LSP bridge, external parser generator, Python integration, or shell-script integration.

Pass1119 update:
- Integrated semantic closure diagnostics now flow into the unified snapshot-guarded semantic diagnostic feed through Build_With_Integrated_Closure.
- Non-legal integrated closure rows become indexed semantic diagnostics; legal closure rows remain non-diagnostic.
- Stale integrated closure inputs and rejected base diagnostic guards expose zero active rows while preserving rejected-entry totals.
- This is a semantic integration pass, not a UI projection-chain extension.

Pass1120: Added integrated semantic closure provenance in `Editor.Ada_Diagnostic_Provenance`. Indexed diagnostics from `Editor.Ada_Integrated_Semantic_Closure` now retain explainable links to closure status, blocker family, dependency state, fingerprints, and diagnostic/index identity. The pass is deterministic, bounded, snapshot-owned, and non-mutating.

Pass1121 update: added `Editor.Ada_Definite_Initialization_Flow_Legality` with snapshot-owned definite-initialization and flow-sensitive object-state legality for read-before-write, component coverage, out-parameter obligations, return-object initialization, branch/loop merge failures, exception/finalization initialization effects, and linked semantic blockers. Regression: `Test_Ada_Definite_Initialization_Flow_Legality_Pass1121`.

### Pass1122 semantic closure update

Definite-initialization and flow-sensitive object-state legality from Pass1121 is now consumed by integrated semantic closure through `Editor.Ada_Integrated_Semantic_Closure.Definite_Initialization`. Read-before-write, partial component initialization, missing out-parameter assignment, return-object initialization gaps, branch/loop merge proof failures, exception/finalization path losses, use-after-finalization, and linked initialization blockers are represented as `Integrated_Closure_Definite_Initialization_Blocker` rows.

### Pass1123 semantic dataflow update

Pass1123 adds `Editor.Ada_Dataflow_Global_Depends_Legality` and integrates it with `Editor.Ada_Integrated_Semantic_Closure.Dataflow`. Global/Depends contract-aspect facts now consume definite-initialization object-state facts so read/write effects, null Global restrictions, Depends source/target consistency, linked contract failures, and initialization-before-read failures are classified together and can enter unified diagnostics as integrated semantic closure blockers. Regression: `Test_Ada_Dataflow_Global_Depends_Legality_Pass1123`.

### Pass1124 predicate/invariant use-site legality

Pass1124 adds `Editor.Ada_Predicate_Invariant_Use_Site_Legality`, a semantic use-site legality layer that consumes predicate/staticness metadata plus assignment, return, conversion/access/aggregate, overload, and generic-instance legality. It covers assignments, object initializations, returns, conversions, qualified expressions, record/array aggregates, call actuals, default expressions, generic actuals, discriminant defaults, and component defaults. The pass enforces static predicate failure, unresolved predicates, dynamic-check preservation, invariant violation/private-view barriers, cross-unit unresolved view blockers, missing checks per use-site family, and linked semantic blockers without adding parser-side or renderer-side behavior.

### Pass1125 generic instance body semantic expansion

Pass1125 adds `Editor.Ada_Generic_Instance_Body_Semantic_Expansion`, a semantic integration layer that projects instantiated generic body actual/formal substitutions into overload, accessibility/lifetime, contract/aspect, Global/Depends dataflow, definite-initialization, predicate/invariant use-site, and representation/layout/stream legality.  The pass preserves substitution identity, formal/actual names, source spans, fingerprints, and multiple-blocker rows so generic-body failures are not hidden behind the first matching classifier.

Pass1126: Added Ada overload preference legality. The semantic model now refines broad overload legality with direct/use visibility tiers, expected-type/profile evidence, primitive and dispatching primitive preferences, universal numeric preferences, conversion preferences, named/defaulted formal profile evidence, and distinct ambiguity classes. This is semantic legality integration only; it adds no rendering-side parsing or UI projection chain.

Pass1127 note: added Editor.Ada_Record_Variant_Aggregate_Legality to connect aggregate structural legality, discriminant constraints, variant coverage, predicate/invariant use-site checks, and representation/layout integration into deterministic record/variant aggregate semantic closure.
Pass1128 note: added Editor.Ada_Accessibility_Precision_Legality to deepen accessibility/lifetime precision across nested access levels, anonymous access parameters, allocator masters, access discriminants, return accessibility, generic actual lifetime substitution, and aggregate discriminant contexts.

## Pass1129 elaboration precision legality

Pass1129 adds a semantic consumer for elaboration-order precision. It does not add syntax, but it records that existing parsing of pragmas/aspects, generic instantiations, bodies, calls, access uses, and library-unit dependencies now feeds a deeper elaboration/dependence legality model.

## Pass1130 tasking/protected precision legality

Pass1130 adds semantic coverage for task activation, protected functions/procedures/entries, entry barriers, entry-family indexes, accept/requeue/select alternatives, queued entry-call accessibility, and protected-object state effects. The pass consumes existing tasking/protected legality, Global/Depends dataflow, elaboration precision, and accessibility precision facts; it does not add render-side parsing or parser-generator dependencies.

Pass1131 update: representation/freezing precision now connects explicit representation items, implicit semantic-use freezing, private/full-view timing, generic-instance freezing effects, representation/layout/stream integration, elaboration precision, and tasking/protected precision through `Editor.Ada_Representation_Freezing_Precision_Legality` with AUnit coverage.

## Pass1132 parser/AST semantic coverage audit

Pass1132 introduces `Editor.Ada_AST_Semantic_Coverage_Audit` to make grammar coverage consumable by semantic legality packages. The audit tracks coverage for aspects, representation clauses, operational attribute clauses, pragmas, generic formals, generic instantiations and renamings, task/protected/entry/accept/requeue/select constructs, separate bodies and stubs, renamings, access definitions, allocators, returns, assignments, calls, conversions, qualified expressions, record/extension/array/container/delta aggregates, reductions, quantified expressions, membership/case/if/declare expressions, target-name, discriminants, variants, exception handlers, and raise expressions.

A construct is not considered compiler-grade covered until it has a parser node, structural AST shape, source span, binding/type/staticness/contract/flow/representation/cross-unit metadata where applicable, and an integrated semantic legality consumer.

Pass1133 note: parser/AST semantic coverage audit gaps now feed integrated semantic closure through `Editor.Ada_Integrated_Semantic_Closure.AST_Coverage`. Uncovered Ada 2022 constructs are actionable semantic blockers rather than passive audit findings.

Pass1134 update: semantic coverage gates consume parser/AST coverage audit rows and prevent downstream Ada legality layers from treating incomplete parser structure, missing semantic metadata, missing cross-unit metadata, or non-integrated semantic consumers as confident legal conclusions.


Pass1135: Integrated semantic closure coverage gates wire Pass1134 semantic coverage gates into integrated closure. Unsafe confident conclusions caused by parser/AST, metadata, consumer-integration, graceful-degradation, or cross-unit coverage gaps now become closure blockers, dependency failures, or indeterminate closure rows.


Pass1136: Added coverage-gated semantic result integration so semantic coverage gates preserve the original widened legality conclusion family, consumer, source row, gate reason, and fingerprint through integrated closure.

Pass1141: Added RM-grade overload edge legality for universal numeric/fixed/root preference, inherited primitive hiding, dispatching/nondispatching ambiguity, access-to-subprogram profiles, generic formal subprograms, nested generic overload ambiguity, and preservation of generic replay / coverage-gate blockers.

Pass1142: Added discriminant-dependent legality for constraints/defaults, variant presence, constrained-object checks, and assignment/conversion/return/allocator/generic actual use sites.

## Pass1144 - Elaboration graph closure legality

Pass1144 records elaboration graph closure as a semantic consumer of Ada library-unit dependencies, calls during elaboration, access-before-elaboration edges, generic instantiations, default expressions, aspect expressions, representation items, and policy-bearing units.  Parser/AST coverage for these constructs is now consumed by `Editor.Ada_Elaboration_Graph_Closure_Legality`, with coverage-gated blockers preventing confident closure when grammar or metadata coverage is incomplete.

Pass1146 note: added Editor.Ada_Representation_Freezing_Exact_Propagation_Legality, which propagates implicit freezing from semantic uses and ties representation timing to generic body replay, discriminant/variant representation, operational/stream/finalization effects, flow-effect graphs, predicate/invariant propagation, accessibility scope graphs, elaboration graph closure, tasking/protected effects, and coverage-gated semantic blockers.

## Pass1147 parser/AST coverage repair legality

Pass1147 adds a repair-side model for coverage rows that were previously only
audited or gated.  Concrete repairs are tracked for parser-node coverage,
structural AST shape, source spans, name/type/staticness/contract/flow/
representation/cross-unit metadata, semantic consumers, consumer integration,
token-only parse replacement, and graceful-degradation replacement.  A repaired
row can clear a gate; incomplete or partial repair remains a blocker.

## Pass1152 repaired coverage semantic feedback

`Editor.Ada_Repaired_Coverage_Semantic_Feedback` feeds repaired parser/AST coverage back into semantic consumers instead of stopping at diagnostics/provenance. A repaired construct now produces a row stating whether its parser/AST shape, semantic metadata, consumer integration, or cross-unit metadata restoration makes it eligible for a specific widened legality engine. Missing, partial, mismatched, indeterminate, stale, cross-unit-required, and original-error cases remain explicit blockers. This lets repaired coverage for aspects, representation clauses, operational clauses, generic formals/instantiations, renamings, access definitions, task/protected constructs, entry/accept/requeue/select constructs, separate bodies/body stubs, record/variant aggregates, discriminants, allocators, raise constructs, reduction/quantified/container/delta expressions, and related Ada 2022 syntax feed legality checks only when the repair is safe for that consumer.

Pass1153 update: Refined_Global / Refined_Depends conformance now consumes flow-effect graph rows and repaired coverage feedback before accepting body/spec flow-contract conclusions. Body reads/writes, refined Global coverage, refined Depends edges, call propagation, linked flow errors, and repaired coverage blockers are represented as deterministic semantic legality rows.

Pass1154 update: Refined_Global / Refined_Depends body-spec conformance now feeds integrated semantic closure as a first-class blocker family. Legal refined conformance remains confident local closure; missing Global coverage, invalid Refined_Depends edges, unpropagated call effects, linked flow-effect errors, and repaired coverage blockers are exposed through integrated closure.

Pass1156 semantic consumer note: Global, Depends, Refined_Global, and Refined_Depends coverage is now consumed by contract/aspect legality through refined-flow consumer evidence. Parser/AST coverage that is repaired but not accepted by the flow-refinement consumer remains a semantic blocker instead of becoming a confident legal contract result.

### Pass1173 task/protected/select AST repair legality

Pass1173 adds a concrete repair legality layer for task/protected/select constructs. Repaired coverage for task types, task bodies, protected types, protected bodies, entry declarations, entry bodies, accept statements, requeue statements, and select statements is now aggregated by construct node. These constructs are treated as restored only when parser-node coverage, structural AST shape, source spans, token-only replacement, graceful-degradation replacement, flow metadata, required contract metadata, required representation metadata, cross-unit metadata, and integrated tasking/protected consumer evidence are all available.
Pass1173 adds a concrete repair legality layer for task/protected/select constructs. Repaired coverage for task types, task bodies, protected types, protected bodies, entry declarations, entry bodies, accept statements, requeue statements, and select statements is now aggregated by construct node. These constructs are treated as restored only when parser-node coverage, structural AST shape, source spans, token-only replacement, graceful-degradation replacement, flow metadata, required contract metadata, required representation metadata, cross-unit metadata, and integrated tasking/protected consumer evidence are all available.

Pass1174: Generic formal declaration AST repair legality now has a concrete repair consumer.  Generic formal object/type/subprogram/package constructs require repaired parser-node coverage, structural AST shape, source spans, name and type metadata, required staticness or contract metadata, cross-unit metadata, and integrated generic semantic consumers before coverage gates are cleared.

Pass1175: access-definition AST repair legality now records concrete repair acceptance/blocker rows for object access definitions, anonymous access parameters, access-to-subprogram definitions, and access discriminants. Access definitions remain blocked when parser nodes, AST shape, spans, name/type/staticness/contract/flow/representation/cross-unit metadata, token-only/degradation replacement, or integrated access consumers are missing.

Pass1176: representation/operational AST repair legality now requires complete parser node, structural AST, source span, token/degradation replacement, metadata, cross-unit, and integrated consumer evidence for representation clauses, operational attribute clauses, aspect specifications, and pragmas before clearing semantic coverage gates.
Pass1177: discriminant/variant AST repair legality now records concrete repair acceptance/blocker rows for discriminant specifications, variant parts, discriminant-dependent aggregate contexts, and private/full-view discriminant view contexts. Discriminant and variant coverage gates remain blocked until parser nodes, AST shape, spans, metadata, cross-unit evidence, and integrated discriminant/aggregate/accessibility/representation consumers are all repaired.

Pass1178 expression construct AST repair legality: container aggregates, delta aggregates, reduction expressions, and quantified expressions now have concrete repaired-coverage rows that can clear expression coverage gates only when parser node, structural AST, span, token/degradation replacement, metadata, cross-unit, and integrated consumer evidence are complete.

Pass1179: Added Editor.Ada_Overload_Type_Edge_Precision_Legality. The overload/type precision layer now preserves remaining Ada RM edge blockers for access-to-subprogram profiles, universal fixed/root numeric choices, inherited primitive hiding, dispatching/nondispatching ambiguity, generic formal subprograms, nested generic named/defaulted actual ties, and class-wide controlling contexts while requiring repaired expression AST and generic replay representation contract-predicate/dataflow evidence before accepting confident legality.


Pass1180: generic replay source/instance backmapping legality preserves two-sided generic body source and instantiation/formal/actual context for replayed semantic rows. Missing source/instance/formal/actual/body nodes, missing maps, fingerprint mismatches, replay CPD blockers, and overload/type edge ambiguity are explicit semantic blockers.

Pass1181: Integrated semantic closure now consumes generic replay source/instance backmapping rows directly. Generic body source, instantiation, formal, actual, substituted body, replay CPD, and overload/type-edge evidence are preserved as closure-visible semantic blocker families.

Pass1182: Added discriminant/variant consumer integration legality so record layout, aggregate, freezing/representation, access-discriminant, generic replay, and private/full-view consumers require accepted discriminant/variant, repaired AST, representation CPD, and generic backmapping evidence before reporting confident semantic legality.

Pass1183: Added Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality, a final accessibility master/scope consumer layer that requires exact scope, object-flow, discriminant/variant, and generic replay backmapping evidence before accepting anonymous access results, access discriminants, allocators, aggregate access components, generic access escapes, renamings, and controlled finalization lifetime paths as confidently legal.

Pass1184: added Editor.Ada_Elaboration_Graph_Final_Consumer_Legality. The pass feeds elaboration graph closure into final call/default/aspect/representation/tasking/generic/policy consumers and preserves predicate/dataflow, overload/type, representation/freezing, tasking, generic backmapping, accessibility, missing-evidence, duplicate-evidence, and indeterminate blockers as deterministic semantic legality rows.

Pass1185: Added Editor.Ada_Tasking_Protected_Final_Effects_Legality, preserving final tasking/protected effect blockers for protected reentrancy, visible-state mutation, barrier side effects, requeue-with-abort safety, terminate alternatives, finalization hazards, and dependent elaboration/representation/accessibility/discriminant evidence.

Pass1186 update:
- Added Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality.
- Final cross-unit semantic closure now preserves blocker families from integrated closure, overload/type-edge precision, generic replay backmapping, discriminant/variant consumers, final accessibility master/scope evidence, final elaboration evidence, final tasking/protected effects, representation/freezing CPD evidence, contract/predicate/dataflow evidence, Refined_Global/Depends conformance, unit completion/order, renaming/alias/visibility, and exception/finalization legality.
- Added Test_Ada_Cross_Unit_Final_Semantic_Closure_Legality_Pass1186 and registered it in the core AUnit suite.

Pass1187 note: Added Editor.Ada_Renaming_Separate_Exception_AST_Repair_Legality. Renaming declarations, separate bodies, body stubs, exception handlers, and raise expressions now have construct-specific parser/AST repair legality rows. These rows require parser nodes, structural AST shape, source spans, token-only/degradation replacement, name/type/staticness/contract/flow/representation metadata, cross-unit metadata, and integrated semantic consumers before repaired coverage can restore confident semantic conclusions.

Pass1188: Added expression control/target AST repair legality for membership tests, case expressions, if expressions, declare expressions, and target-name/update-expression contexts. Repaired coverage for these constructs only restores confident semantic conclusions when parser node, structural AST, source span, token/degradation replacement, required metadata, cross-unit metadata, and integrated semantic consumer evidence are present.

Pass1189: Added Editor.Ada_Overload_Type_Final_RM_Consumer_Legality. The overload/type final RM consumer now requires repaired access-definition AST evidence, overload/type edge precision evidence, and generic source/instance backmapping evidence before accepting prefixed-call primitive visibility, access-to-subprogram profile/null-exclusion/convention matching, class-wide controlling-result interactions, inherited/private-extension primitive hiding, universal fixed/root numeric mixed-mode ties, dispatching inherited operations, generic formal subprogram instances, and nested generic prefixed calls as confidently legal.

Pass1190: Added Editor.Ada_Generic_Replay_Nested_Cycle_Closure_Legality. Nested generic replay closure now requires source/instance backmapping, final overload/type RM consumer evidence, cross-unit final semantic closure evidence, generic body availability, bounded dependency/cycle state, view/child visibility state, and source/substitution fingerprints before local, cross-unit, child/private-child, formal-package, nested-instance, body/subprogram, representation, and task/protected generic replay conclusions can remain confidently legal. It preserves nested dependency cycles, recursive instantiation cycles, cycle-depth overflow, dependency overflow, stale dependencies, missing evidence, view barriers, generic body availability failures, mapping/fingerprint mismatches, and multiple blockers as first-class semantic statuses.


Pass1191: final representation/freezing hard-case coverage is tracked for private/full-view freezing, generic formal freezing, inherited operational attributes, stream attributes on limited/private views, variant/discriminant/finalization layout interactions, and implicit freezing order.
Pass1192: final flow/contract proof legality now preserves transitive Depends, dispatching Global refinement, abstract/refined state, volatile/atomic, independent-component, cross-unit, contract/dataflow, representation, and initialization blockers.

Pass1193 update:
- Added final deep tasking/protected edge legality for protected reentrancy, entry-family queue semantics, terminate graphs, and abort/deferred-finalization ordering.

### Pass1194 final semantic diagnostic integration

Pass1194 adds blocker-preserving final semantic diagnostic integration. It consumes final semantic closure and consumer evidence, withholds legal rows as non-diagnostics, and keeps stale, AST repair, coverage-gate, view-barrier, indeterminate, and multiple-blocker states distinct. It does not add UI projection, render parsing, command routing, keybinding routing, workspace mutation, or file lifecycle mutation.

## Pass1195 final semantic diagnostic feed integration

Pass1195 connects final semantic diagnostic rows to the snapshot-guarded semantic feed/index path while preserving blocker-family identity and stale-input rejection.  It adds no parser grammar or UI projection layer.


Pass1196 records final semantic diagnostic provenance for final blocker families so coverage-gated parser/AST repair, cross-unit closure, overload/type, generic replay, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility, and discriminant/variant blockers remain traceable after feed/index integration.

Pass1197 adds blocker-family-aware search indexing for final semantic diagnostics, preserving final semantic provenance across blocker family, status, stage, node, span, fingerprint, feed-link, and diagnostic-index-link queries.

Pass1198 update: added final semantic blocker trace closure.  Final semantic diagnostics can now be traced through blocker-family-preserving chains from final semantic closure and diagnostic integration through feed/index/provenance/search rows, including cross-unit, overload/type, generic replay, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility/lifetime, discriminant/variant, AST repair, coverage-gate, view-barrier, stale, indeterminate, and multiple-blocker roots.

Pass1201: Final remediation gate results are now represented as semantic closure rows. Unresolved prerequisite gates become first-class closure blockers while legal, preserved-error, and indeterminate rows retain their semantic identity.


Pass1202: final remediation-closure diagnostic integration now preserves AST/coverage, cross-unit, view, generic replay, overload/type, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility/lifetime, discriminant/variant, stale, multiple, and indeterminate blocker families in diagnostic/feed evidence.

Pass1203 adds final semantic remediation diagnostic provenance/search, preserving prerequisite blocker-family identity from remediation diagnostics through closure/gate/trace/feed/index/base-provenance links.

Pass1204: Added final semantic remediation worklist legality. The new worklist consumes remediation diagnostic provenance/search evidence and orders prerequisite semantic repair/re-analysis work by real blocker family while preserving deterministic node/span/fingerprint identity.

Pass1205 adds final semantic recheck eligibility legality.  It consumes remediation worklist ordering and emits bounded eligibility rows that preserve prerequisite blocker-family identity before semantic re-analysis is allowed.

Pass1206 adds Editor.Ada_Final_Semantic_Recheck_Application_Legality. It applies final semantic recheck eligibility back into the closure/feed boundary so only rows whose prerequisite chain is eligible now can become current, while stale, AST/coverage, cross-unit, view, generic, overload/type, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility, discriminant/variant, preserved-error, multiple-prerequisite, and indeterminate blockers remain explicit withheld-current semantic rows.

Pass1207 adds Editor.Ada_Final_Semantic_Recheck_Convergence_Legality. It consumes final semantic recheck application rows and marks results as converged, stably withheld, preserved-error, indeterminate, or changed relative to a prior application fingerprint, so the closure/feed boundary can stop cycling on unchanged prerequisite evidence while still rechecking stale, AST/coverage, cross-unit, view, generic, overload/type, representation/freezing, flow/contract, tasking/protected, elaboration, accessibility, discriminant/variant, multiple-prerequisite, and indeterminate blocker families when their fingerprints change.

Pass1208 note: Added final semantic stabilization gate legality. Converged recheck rows may be promoted across the final closure/feed boundary; prerequisite-blocked rows remain withheld with their original blocker family and stable fingerprints.

Pass1209 note: final semantic stabilization now feeds a stabilized closure model,
so stable accepted rows and stable withheld prerequisite blockers are represented
before diagnostic/feed exposure.

Pass1210: Added Editor.Ada_Final_Semantic_Stabilized_Diagnostic_Integration. Stable accepted closure rows from Pass1209 are withheld as current non-diagnostic semantic evidence, while stabilized blockers are emitted with their original blocker-family identity. Recheck-required and indeterminate rows remain warnings instead of being promoted as confident legal conclusions.

Pass1210 feed integration: `Editor.Ada_Semantic_Diagnostic_Feed.Build_With_Final_Stabilized_Diagnostics` consumes stabilized diagnostic rows, emits only stabilized blockers/recheck/indeterminate rows, withholds stable accepted closure rows, and preserves source-family mapping for cross-unit, generic, representation/freezing, and expression-family blockers.

Pass1211 adds Editor.Ada_Abstract_State_Refined_State_Legality, a compiler-grade abstract/refined state legality layer for abstract state declarations, Refined_State aspects, constituent mappings, abstract-state Global/Depends use, cross-unit state visibility, task/protected shared-state effects, and volatile/atomic state effects. It consumes final flow/contract proof, deep tasking/protected evidence, and stabilized final semantic closure evidence while preserving real blocker families.

Pass1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Pass1213: Added final overload/shared-state RM edge legality.  Final overload/type decisions now consume abstract/refined-state and volatile/atomic/shared-state evidence and preserve effect blockers by family.

Pass1214: representation/shared-state final legality now consumes final representation, abstract/refined state, volatile/atomic/shared-state, and overload shared-state evidence for representation and freezing contexts.

Pass1215 adds Editor.Ada_Tasking_Shared_State_Final_Legality, connecting deep tasking/protected RM edge evidence with abstract/refined state, volatile/atomic/shared-variable legality, overload shared-state RM evidence, and representation/freezing shared-state evidence. It preserves blocker-family identity for protected reads/writes, entry barriers, entry-family queues, accept/requeue/select effects, task activation/termination, abortable finalization, abstract-state access, and representation-sensitive tasking effects.

Pass1216: Added Editor.Ada_Cross_Unit_Shared_State_Final_Closure_Legality. The final shared-state semantic chain now has cross-unit closure across abstract/refined state, volatile/atomic/shared-variable effects, overload/type shared-state evidence, representation/freezing shared-state evidence, and tasking/protected shared-state evidence. Dependency, view, state-visibility, generic body/backmapping, volatile/atomic ordering, shared-variable, representation-effect, tasking-effect, fingerprint, multiple-blocker, and indeterminate states remain distinct blocker families.

Pass1217: shared-state stabilized diagnostic integration preserves cross-unit shared-state blocker families at the stabilized diagnostic boundary without adding UI projection behavior.

Pass1218: Shared-state remediation worklist legality now orders prerequisite semantic re-analysis for stabilized shared-state blockers without flattening blocker-family identity.

Pass1219 update: shared-state remediation worklist rows now feed bounded recheck eligibility while preserving prerequisite blocker-family identity for abstract/refined-state, volatile/atomic, overload/type, representation/freezing, tasking/protected, cross-unit, view, generic, state-visibility, fingerprint, multiple, and indeterminate blockers.

Pass1220 note: Editor.Ada_Shared_State_Recheck_Application_Legality applies shared-state recheck eligibility back into the final closure / stabilized diagnostic boundary.  Current shared-state conclusions are exposed only when prerequisite recheck evidence is eligible or already accepted as non-diagnostic current evidence; unresolved cross-unit, view, generic, state-visibility, abstract/refined-state, volatile/atomic, overload/type, representation/freezing, tasking/protected, fingerprint, multiple, and indeterminate blockers remain withheld with their blocker-family identity preserved.

Pass1221 note: added Editor.Ada_Shared_State_Recheck_Convergence_Legality.  The pass consumes shared-state recheck application rows and records whether shared-state semantic evidence converged as current/not-required, stayed stably withheld by its original blocker family, remained indeterminate, or changed relative to a previous application fingerprint.  It preserves shared-state blocker-family identity across abstract/refined state, volatile/atomic/shared-variable, overload/type, representation/freezing, tasking/protected, cross-unit, state-visibility, generic-backmapping, source-fingerprint, stale-eligibility, multiple-prerequisite, and indeterminate evidence.

Pass1222 update: added shared-state stabilization gating for Pass1221 convergence rows, preserving prerequisite blocker families while promoting only stable current shared-state evidence.

Pass1223 update: shared-state stabilization-gate rows now feed Editor.Ada_Shared_State_Stabilized_Closure_Legality. Stable accepted shared-state rows become first-class closure evidence; stable blockers remain explicit closure blockers with blocker-family identity preserved.

Pass1224: Added abstract/refined state consumer integration legality. The new package Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality requires abstract/refined-state evidence before Global/Depends, dispatching, generic replay, representation/freezing, tasking/protected, volatile/atomic/shared-variable, cross-unit shared-state, and stabilized shared-state closure consumers may remain confidently accepted. Blocker-family identity is preserved for abstract state, shared state, overload/dispatching, representation/freezing, tasking/protected, cross-unit, stabilized-closure, source-fingerprint, multiple-blocker, and indeterminate cases.

### Pass1226 - Dispatching Global/Depends refinement legality

Pass1226 adds `Editor.Ada_Dispatching_Global_Refinement_Legality`. It connects dispatching-call Global/Depends proof to abstract/refined-state legality, abstract-state consumer integration, overload shared-state evidence, volatile/atomic representation consumer evidence, final flow/contract proof, and shared-state stabilized closure. It preserves blocker-family identity for flow/contract proof, abstract state, abstract-state consumers, overload shared-state evidence, volatile/atomic representation evidence, stabilized shared-state closure, Global/Depends mismatches, dynamic effect joins, inherited/renamed/generic dispatching effects, fingerprint mismatches, multiple blockers, and indeterminate states. Regression coverage is in `Test_Ada_Dispatching_Global_Refinement_Legality_Pass1226`.

Pass1227: Added Editor.Ada_Generic_Abstract_State_Replay_Legality, replaying abstract/refined-state, volatile/atomic, shared-state, and dispatching Global/Depends effects through generic bodies and nested instantiations while preserving source/instance backmapping, formal/actual substitution, shared-state closure, and blocker-family fingerprints.

Pass1228 adds Editor.Ada_Overload_Generic_Shared_State_Final_Legality. It connects final overload shared-state RM evidence with generic abstract-state replay, dispatching Global/Depends refinement, volatile/atomic representation consumers, abstract-state consumers, and stabilized shared-state closure. The pass keeps final overload/type conclusions withheld until matching prerequisite evidence and fingerprints agree.


Pass1229: Representation/generic/shared-state final legality

Adds Editor.Ada_Representation_Generic_Shared_State_Final_Legality. The pass consumes final representation/freezing hard-case evidence, representation/shared-state evidence, generic abstract-state replay, overload/generic shared-state final evidence, volatile/atomic representation consumers, and stabilized shared-state closure before accepting representation/freezing conclusions. It preserves blocker-family identity for final representation, representation/shared-state, generic replay, overload/generic shared state, volatile/atomic representation, stabilized closure, private/full-view freezing, generic formal freezing, stream/operational attributes, variant layout, independent components, task/protected representation, fingerprint mismatches, multiple blockers, and indeterminate states.
Pass1230: Added Editor.Ada_Tasking_Generic_Shared_State_Final_Legality, a tasking/protected generic shared-state final legality layer that consumes deep tasking, tasking shared-state, generic abstract replay, overload/generic shared-state, representation/generic shared-state, abstract-state consumer, and stabilized shared-state closure evidence while preserving blocker-family identity.

Pass1232 adds elaboration/generic shared-state final legality. The semantic model now withholds elaboration conclusions for dispatching calls, generic instances, generic body replay, representation items, task activation/termination, and partition policy contexts until final elaboration, cross-unit generic/shared-state closure, dispatching Global/Depends, generic abstract-state replay, representation/generic shared-state, and tasking/generic shared-state evidence agree. Blocker-family identity is preserved for downstream semantic consumers.

Pass1233: Added accessibility/generic shared-state final legality, preserving blocker-family identity for accessibility/lifetime conclusions that depend on generic/shared-state closure evidence.

Pass1234: Added Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality to connect discriminant/variant consumer evidence into the generic/shared-state final chain. The pass preserves blocker-family identity for discriminant consumers, cross-unit generic/shared-state closure, elaboration, generic replay, overload, representation/freezing, tasking/protected, accessibility, stabilized shared-state closure, discriminant constraints, variant coverage, aggregate associations, private/full-view mismatches, generic substitution, representation layout, task/protected effects, access-discriminant lifetime, cross-unit consistency, fingerprint mismatches, multiple blockers, and indeterminate states.


Pass1235 records exception/finalization generic shared-state final legality as a semantic consumer, not a parser expansion. Parser/AST repair remains gated to coverage-proven gaps only.


Pass1236: renaming/generic/shared-state final legality now consumes base renaming/alias visibility evidence with cross-unit, generic replay, overload, representation, tasking, accessibility, discriminant, and stabilized shared-state evidence.


Pass1237 adds Editor.Ada_Predicate_Generic_Shared_State_Final_Legality. It connects predicate/invariant use-site and propagation evidence to the generic/shared-state final semantic chain, preserving blocker-family identity across generic replay, representation/freezing, tasking/protected, accessibility, discriminant/variant, exception/finalization, renaming/alias, dispatching Global/Depends, cross-unit closure, stabilized shared-state closure, source-fingerprint, substitution-fingerprint, multiple-blocker, and indeterminate states.


Pass1238 adds Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality. It integrates definite-initialization/dataflow legality with the generic/shared-state final chain, preserving blocker families for initialization, dataflow, predicates, generic replay, shared-state closure, representation/freezing, tasking/protected, accessibility, discriminants, exception/finalization, renaming, volatile/atomic representation, access escape, variant components, finalization, and fingerprint mismatches.

Pass1239: Added generic/shared-state final diagnostic integration and feed support. The integration exposes only blocking rows while preserving original semantic blocker-family identity and withholds accepted rows as current semantic evidence.
Pass1240: Added Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality. It consumes generic/shared-state final diagnostic rows and turns blocker-preserving evidence into a deterministic semantic remediation worklist. Accepted rows remain current semantic evidence; blockers become prerequisite work items ordered across stale/fingerprint evidence, definite initialization, dataflow, predicates, generic replay, stabilized shared-state closure, volatile/atomic representation, representation/freezing, tasking/protected, accessibility, discriminants/variants, exception/finalization, renaming/aliasing, multiple blockers, and indeterminate state before downstream re-analysis may trust generic/shared-state conclusions.


### Pass1241 generic/shared-state recheck eligibility

Generic/shared-state final recheck eligibility consumes remediation worklist evidence and preserves blocker families without introducing parser speculation or rendering-side analysis.

### Pass1242 generic/shared-state final recheck application

No grammar production is added. The pass preserves parser/AST and semantic blocker identity when generic/shared-state final recheck eligibility is applied.

Pass1243 adds Editor.Ada_Generic_Shared_State_Final_Recheck_Convergence_Legality and Test_Ada_Generic_Shared_State_Final_Recheck_Convergence_Legality_Pass1243. It detects convergence, stable withholding, indeterminate state, and changed application fingerprints for the generic/shared-state final chain while preserving prerequisite blocker-family identity.

Pass1244 adds Editor.Ada_Generic_Shared_State_Final_Stabilization_Gate_Legality and Test_Ada_Generic_Shared_State_Final_Stabilization_Gate_Legality_Pass1244. It promotes only stable generic/shared-state final convergence rows, withholds prerequisite blockers with their original family identity, and forces another bounded recheck when convergence fingerprints change.

Pass1245: Generic/shared-state final stabilized closure now promotes only stable accepted generic/shared-state final conclusions into first-class semantic closure evidence. Stable blockers remain explicit closure blockers with blocker-family identity preserved, and recheck-required rows remain non-confident.

Pass1246: overload/generic/shared-state RM edge completion adds semantic coverage for renamed primitive visibility, inherited/private-extension primitive hiding, dispatching abstract-state effects, prefixed-call side-effect contracts, access-to-subprogram effect profiles, generic formal subprogram effects, universal numeric expected-context state ambiguity, and class-wide controlling-result state joins. The pass consumes stabilized generic/shared-state final closure and prior overload/generic shared-state evidence, and preserves blocker-family identity for unresolved prerequisites and fingerprints.

Pass1247: added representation/generic/shared-state RM hard-case completion legality. Volatile/atomic representation clauses, independent component layout, limited/private stream attributes, inherited operational attributes, generic formal/instance freezing, discriminant-dependent layout, controlled/finalized components, and protected/task representation effects are now gated by previous representation evidence, overload RM edge evidence, stabilized generic/shared-state closure evidence, and stable fingerprints before downstream consumers may trust the result.


Pass1248 adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality, closing tasking/protected RM hard cases over the stabilized generic/shared-state semantic chain while preserving blocker-family identity for protected action reentrancy, callbacks, entry queues, requeue/select paths, abort/finalization, task termination, protected shared-state access, abstract-state-backed task effects, and generic task/protected bodies.

Pass1249: Added Editor.Ada_Coverage_Proven_Generic_Shared_State_AST_Repair_Legality. The pass accepts parser/AST repair only when semantic coverage gates prove that a real generic/shared-state final consumer is blocked, and it preserves blocker-family identity across coverage gates, stabilized closure, overload/type, representation/freezing, tasking/protected, parser-node, structural-AST, token-only, source-span, metadata, consumer-integration, fingerprint, multiple-blocker, and indeterminate cases.


Pass1250 adds cross-unit generic/shared-state RM completion closure legality, consuming prior cross-unit closure plus completed overload, representation/freezing, tasking/protected, and coverage-proven AST repair evidence before accepting dependency-spanning generic/shared-state RM conclusions.


Pass1251: elaboration RM completion now consumes coverage-proven AST repair evidence before accepting generic/shared-state elaboration conclusions.

## Pass1252

Pass1252 adds accessibility generic/shared-state RM completion legality. It preserves blocker-family identity for access-level, lifetime, completed RM-chain, and coverage-proven AST repair blockers.


Pass1253: exception/finalization generic/shared-state RM completion legality consumes completed RM prerequisites and preserves blocker-family identity.

Pass1254: Predicate/invariant RM completion now consumes the completed generic/shared-state RM chain and keeps prerequisite blocker families distinct for downstream semantic closure.

Pass1255 adds Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality. It completes dataflow/initialization legality over the completed generic/shared-state RM chain by requiring prior dataflow, cross-unit RM completion, elaboration, accessibility, exception/finalization, predicate/invariant, overload, representation, tasking, and coverage-proven AST repair evidence to agree before dataflow conclusions are accepted.


Pass1256: RM-completed generic/shared-state diagnostic integration now exposes completed-chain blockers while withholding accepted rows as current semantic evidence.

Pass1257: added RM-completed generic/shared-state remediation worklist legality. The pass is semantic-only and orders prerequisite blockers for the completed RM chain before recheck eligibility may trust downstream conclusions.


Pass1258 — Coverage-proven RM-completion AST repair legality
Adds coverage-proven AST repair over the RM-completed generic/shared-state chain while preserving blocker-family identity.

Pass1259: RM-completion generic/shared-state recheck eligibility now preserves blocker-family identity through the bounded recheck boundary.

Pass1260: Added generic/shared-state RM-completion recheck application legality, preserving RM-completion blocker-family identity while applying eligibility back into the semantic closure/feed boundary.
Pass1261 adds Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Convergence_Legality, which consumes Pass1260 RM-completion recheck application rows and classifies current, not-required, stably withheld, indeterminate, and changed generic/shared-state RM-completion conclusions while preserving blocker-family identity.


Pass1262 adds Editor.Ada_Generic_Shared_State_RM_Completion_Stabilization_Gate_Legality. It consumes RM-completion recheck convergence rows and promotes only stable generic/shared-state RM-completion conclusions while preserving prerequisite blocker-family identity for withheld rows.

Pass1263 adds Editor.Ada_Generic_Shared_State_RM_Completion_Stabilized_Closure_Legality. Stable RM-completion rows from the generic/shared-state stabilization gate now become first-class closure evidence, while blocked rows remain closure blockers with the original blocker-family identity preserved.

Pass1264: Added overload RM-completion closure consumer legality. The pass consumes stabilized generic/shared-state RM-completion closure rows before overload/type RM edge conclusions may be trusted, while preserving blocker-family identity for closure, overload, cross-unit, representation, tasking, elaboration, accessibility, dataflow, and fingerprint blockers.
\nPass1265: Added representation RM-completion closure consumer legality. The pass consumes stabilized generic/shared-state RM-completion closure rows before representation/freezing RM hard-case conclusions may be trusted, while preserving blocker-family identity for closure, representation, cross-unit, overload/type, tasking, elaboration, accessibility, dataflow, and fingerprint blockers.

Pass1266: Tasking/protected RM-completion closure consumer legality now consumes stabilized RM-completion closure evidence and preserves tasking/protected blocker-family identity.

Pass1267: Dataflow RM-completion closure consumer legality now requires stabilized generic/shared-state RM-completion closure evidence before dataflow/initialization RM-completion conclusions are considered current. Blocker-family identity is preserved for closure, dataflow, cross-unit, generic substitution, overload/type, representation/freezing, tasking/protected, elaboration, accessibility, predicates/invariants, multiple prerequisites, and indeterminate states.
# Historical Ada Parser Coverage Matrix

This file is retained as historical pass evidence. Current testing workflow is
in `docs/testing.md`; current release workflow is in
`docs/release/RELEASE_CHECKLIST.md`.
