The Ada token cursor now exposes enumeration-representation-specific recovery metadata through `Production_Enumeration_Representation_Empty_List_Recovery_Boundary`, `Production_Enumeration_Representation_Trailing_Separator_Recovery_Boundary`, and `Production_Enumeration_Representation_Missing_Value_Recovery_Boundary`. Semantic-colouring and outline consumers can keep malformed representation aggregate clauses bounded without rendering-side parsing or compiler legality checks.

The Ada token cursor now exposes `Production_Case_Alternative_Missing_Statement_Recovery_Boundary` for malformed case alternatives such as `when 1 =>` followed by another alternative. Semantic-colouring and outline consumers can keep the case structure bounded without rendering-side parsing or semantic legality checks.

The Ada token cursor now exposes `Production_Case_Choice_Missing_Choice_Recovery_Boundary` for malformed case statement alternatives such as `when 1 | =>`. Semantic-colouring and outline consumers can retain the separator and arrow structure without rendering-side parsing or semantic legality checks.

### Pass866 - Case statement missing-is recovery metadata

The Ada token cursor now exposes `Production_Case_Statement_Missing_Is_Recovery_Boundary` for malformed case statements that omit the `is` keyword after the selector. Semantic-colouring and outline consumers can keep the selector, later alternatives, and following statements visible without doing rendering-side parsing.

### Pass865 - Extended return missing-do recovery metadata

The Ada token cursor now exposes extended-return-specific missing-`do` recovery metadata through `Production_Extended_Return_Missing_Do_Recovery_Boundary`. Semantic-colouring and outline consumers can keep malformed extended return headers local to the return statement while preserving following statements. This is parser-owned metadata; rendering code must continue to consume language-model results only.

### Pass864 - Requeue statement missing-target recovery depth

The Ada token cursor now exposes requeue-specific missing-target recovery metadata through `Production_Requeue_Missing_Target_Recovery_Boundary`. Semantic-colouring and outline consumers can keep malformed `requeue ;` edits local to the requeue statement and avoid treating later statement tokens as target names. This is parser-owned metadata; rendering code must continue to consume language-model results only.

### Pass863 - Accept statement missing-entry-name recovery depth

The Ada token cursor now exposes accept-specific missing-entry-name recovery metadata through `Production_Accept_Missing_Entry_Name_Recovery_Boundary`. Semantic-colouring and outline consumers can degrade gracefully around in-progress accept statements without reparsing in rendering code or consuming following statement structure.

### Pass854 - Select guard condition recovery metadata

Select guard recovery now exposes `Production_Select_Guard_Missing_Condition_Recovery_Boundary` when a guarded select alternative reaches `=>` or another select synchronization point before a condition. Semantic colouring and diagnostics consumers can keep the guard arrow and following alternative visible without render-side parsing or dirty-state mutation.

### Pass853 - Accept statement terminator recovery metadata

The Ada token cursor now exposes accept-specific missing-terminator recovery metadata through `Production_Accept_Missing_Terminator_Recovery_Boundary`. Semantic-colouring and outline consumers can degrade gracefully around in-progress accept do-parts without reparsing in rendering code or consuming following statement structure.

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

### Pass830 - Qualified-expression operand delimiter metadata

The Ada token cursor now records qualified-expression operand delimiter and
missing-close recovery productions. Semantic-colouring consumers can distinguish
the operand parentheses in `Subtype_Mark'(...)` from ordinary aggregate or
parenthesized-expression punctuation without reparsing the buffer. Allocator
qualified expressions reuse the same metadata, while rendering remains
projection-only.

Analysis remains deterministic, bounded, snapshot-owned, stale-result guarded,
and free of dirty-state mutation.

### Pass829 - Aggregate delimiter metadata

The Ada token cursor now records aggregate delimiter and separator productions.
Semantic-colouring consumers can distinguish aggregate parentheses and top-level
component separators from ordinary expression punctuation without reparsing the
buffer. Missing-close recovery is also surfaced as bounded parser metadata so
colouring can degrade gracefully on in-progress aggregate expressions.

Rendering remains projection-only. Analysis remains deterministic, bounded,
snapshot-owned, stale-result guarded, and free of dirty-state mutation.

Pass827 - Discriminant part delimiter and recovery depth

Pass827 adds token-cursor metadata for discriminant-part delimiters, discriminant-specification separators, and bounded missing-close recovery. This gives semantic-colouring and outline consumers more precise structural spans around known and unknown discriminant parts without moving parsing into rendering.

New productions:
- `Production_Discriminant_Part_Open_Delimiter`
- `Production_Discriminant_Part_Close_Delimiter`
- `Production_Discriminant_Specification_Separator`
- `Production_Discriminant_Part_Missing_Close_Recovery_Boundary`

Rendering remains projection-only. The analysis remains deterministic, bounded, snapshot-owned, and stale-result guarded.

### Pass828 - Constraint delimiter metadata

The Ada token cursor now records structural delimiter and separator metadata for
index constraints and discriminant constraints. Semantic-colouring consumers can
use the new productions to distinguish constraint parentheses and top-level
constraint separators from ordinary expression punctuation without reparsing the
buffer.

The metadata is bounded and snapshot-owned. It does not perform compiler-grade
constraint legality checks and does not mutate dirty state, rendering state,
command routing, keybindings, workspace state, or files.

### Pass831 - Parenthesized-expression delimiter metadata

The Ada token cursor now records parenthesized-expression-specific open/close
delimiter metadata and bounded missing-close recovery. Semantic-colouring
consumers can distinguish ordinary parenthesized-expression punctuation from
other expression punctuation without reparsing the buffer.

Rendering remains projection-only. Analysis remains deterministic, bounded,
snapshot-owned, stale-result guarded, and free of dirty-state mutation.

### Pass832 - Discrete choice-list separator metadata

The Ada token cursor now records discrete choice-list `|` separators and
missing-choice recovery boundaries. Semantic-colouring and diagnostics consumers
can distinguish choice-list punctuation in case/variant-style alternatives from
ordinary expression operators without reparsing the buffer.

### Pass833 - Enumeration type delimiter metadata

Enumeration type definitions now expose structural open/close delimiter,
comma-separator, and missing-close recovery productions. Semantic-colouring and
outline consumers can use these productions as stable parser-owned syntax
boundaries for enumeration literal lists while preserving bounded recovery for
in-progress declarations.

### Pass835 - Range constraint separator metadata

Range constraints now expose structural metadata for the `..` separator and
range-specific missing-bound recovery boundaries. Semantic-colouring and
diagnostics consumers can distinguish range-constraint punctuation and recovery
from generic expression punctuation without reparsing the buffer.

Rendering remains projection-only. Analysis remains deterministic, bounded,
snapshot-owned, stale-result guarded, and free of dirty-state mutation.

### Pass836 - Attribute argument-list delimiter metadata

Attribute argument parts now expose structural open/close delimiter, separator,
and missing-close recovery productions. Semantic-colouring and diagnostics
consumers can distinguish attribute argument-list punctuation from ordinary call,
aggregate, or indexed-component punctuation without reparsing the buffer.
Reduction attributes retain the same delimiter metadata while preserving reducer
and initial-value structural productions.

### Pass837 - Membership choice-list separator metadata

The Ada token cursor now emits explicit membership choice-list separator and
missing-choice recovery productions. Semantic-colouring and outline consumers can
therefore distinguish `|` separators in `in` / `not in` membership tests from
ordinary expression operators without reparsing source text. The metadata is
structural only and does not imply membership-choice legality checking.


### Pass838 - Case-expression alternative separator metadata

Case-expression alternatives now expose explicit comma separator metadata. This
gives syntax-colouring and outline consumers a stable structural boundary for
forms such as `(case A is when A => 1, when B => 2)` and a bounded recovery
marker for in-progress trailing-comma alternatives.

### Pass839 declare-expression begin/recovery metadata

Semantic-colouring and outline consumers can now rely on token-cursor metadata
for declare-expression `begin` boundaries and missing-begin recovery:

- `Production_Declare_Expression_Begin_Keyword`
- `Production_Declare_Expression_Missing_Begin_Recovery_Boundary`

This is structural parser metadata for colouring/recovery only. It does not add
compiler-grade declare-expression legality checking or external semantic
analysis.

### Pass840 quantified-expression missing-quantifier recovery metadata

Semantic-colouring, diagnostics, and outline consumers can now rely on a
quantified-expression-specific recovery marker when the required `all` or
`some` quantifier is missing after `for`:

- `Production_Quantified_Missing_Quantifier_Recovery_Boundary`

This keeps malformed quantified expressions structurally visible without
requiring consumers to reparse the source text. It is structural parser metadata
only and does not add compiler-grade quantified-expression legality checking or
external semantic analysis.


### Pass841 if-expression missing-then recovery metadata

Semantic-colouring, diagnostics, and outline consumers can now rely on
if-expression-specific recovery markers when the required `then` keyword is
missing after an `if` or `elsif` expression condition:

- `Production_If_Expression_Missing_Then_Recovery_Boundary`
- `Production_Elsif_Expression_Missing_Then_Recovery_Boundary`

This keeps malformed conditional expressions structurally visible without
requiring consumers to reparse source text. It is structural parser metadata
only and does not add compiler-grade conditional-expression legality checking
or external semantic analysis.


### Pass842 selected-name recovery metadata

Semantic-colouring consumers may observe `Production_Selected_Name_Missing_Selector_Recovery_Boundary` when a selected name has a dangling dot. The marker is structural recovery metadata and should not be treated as a resolved selector.

### Pass843 delta aggregate metadata

Delta aggregate parsing now exposes structural productions for the top-level `with` keyword, `delta` keyword, association separators, and missing-association recovery. Semantic colouring consumers can use this metadata without reparsing source text and without mutating editor state.

### Pass844 extension aggregate metadata

Extension aggregate parsing now exposes structural productions for the top-level `with` keyword, extension component separators, and missing-association recovery. Semantic-colouring consumers can use this metadata without reparsing source text and without mutating editor state. `with null record` remains available through the existing null-record aggregate marker.

### Pass845 null-record aggregate metadata

Null-record extension aggregates now expose structural productions for the `null` and `record` keywords and for bounded missing-`record` recovery. Semantic-colouring consumers can use these markers without reparsing source text and without mutating editor state.

### Pass847 iterated component domain recovery metadata

Aggregate iterated component associations now expose a dedicated missing-domain recovery marker when a malformed association reaches `when` or `=>` before the iteration domain. Semantic-colouring consumers can use the marker to avoid reparsing text and to keep following declarations visible after recovery.

### Pass846 iterated component association metadata

Aggregate iterated component associations now expose structural productions for the `=>` association arrow and bounded missing-arrow recovery. Semantic-colouring consumers can use these markers without reparsing source text and without mutating editor state.

### Pass848 loop iteration domain recovery metadata

The Ada token cursor now emits loop-specific missing-domain recovery productions for malformed `for ... in` and `for ... of` iteration schemes. Semantic-colouring and outline consumers can distinguish a missing loop domain from a missing `loop` keyword while still receiving filter and loop-body structure when the surrounding syntax is recoverable.

### Pass849 — Iterator-filter condition recovery metadata

Iterator-filter `when` clauses now expose bounded missing-condition recovery metadata across loops, quantified expressions, and aggregate iterated component associations. Semantic-colouring consumers can keep the `when`, `loop`, and `=>` boundaries stable in malformed/in-progress buffers without performing semantic legality checks.

### Pass850 — Exit-when condition recovery metadata

Pass850 adds a dedicated token-cursor recovery marker for malformed/in-progress `exit when` statements with no condition expression. This lets semantic-colouring and diagnostics consumers distinguish a missing condition from a generic exit-statement recovery boundary without invoking compiler semantics or mutating editor state.


### Pass851 — Delay statement missing-expression recovery metadata

Delay statements now expose dedicated missing-expression recovery productions for `delay until` and relative `delay` forms. Semantic-colouring consumers can distinguish missing time/duration expressions from generic delay-statement recovery while preserving statement terminators and following statements without reparsing source text or invoking compiler semantics.

### Pass852 — Requeue statement missing-terminator recovery metadata

Requeue statements now expose a dedicated missing-terminator recovery production. Semantic-colouring consumers can distinguish a missing semicolon after `requeue ... [with abort]` from generic requeue target recovery while keeping enclosing `end` markers and following statements stable without reparsing source text or invoking compiler semantics.

### Pass855 abort target recovery metadata

Pass855 adds token-cursor metadata for malformed/in-progress Ada `abort` statements with missing task-name targets. Syntax-colouring consumers may use `Production_Abort_Missing_Target_Recovery_Boundary` as a structural recovery marker only; it must not be interpreted as task-name resolution or compiler-grade tasking legality checking.

### Pass856 return missing-terminator recovery metadata

Pass856 adds token-cursor metadata for malformed/in-progress Ada `return` statements whose required semicolon is missing before a structural boundary. Syntax-colouring consumers may use `Production_Return_Missing_Terminator_Recovery_Boundary` as a local recovery marker only; it must not be interpreted as return type analysis, legality checking, overload resolution, or compiler-derived semantic information.

### Pass857 raise-expression message recovery

The syntax/semantic colouring pipeline can now distinguish malformed raise
expressions with a missing `with` message payload using
`Production_Raise_Expression_Message_Recovery_Boundary`.  This is parser-owned
structural metadata only and does not perform exception/message legality
analysis.

### Pass858 raise-statement message recovery

The syntax/semantic colouring pipeline can now distinguish malformed raise
statements with a missing `with` message payload using
`Production_Raise_Statement_Message_Recovery_Boundary`. This is parser-owned
structural metadata only and does not perform exception/message legality
analysis.

### Pass859 label missing-close recovery

Malformed labels that contain `<<` but omit `>>` now expose
`Production_Label_Missing_Close_Recovery_Boundary`. Semantic-colouring and
outline consumers can keep the broken label localized without treating the
following statement sequence as part of the label.

### Pass860 assignment expression recovery

Malformed assignments that contain `:=` but omit the right-hand expression now
expose `Production_Assignment_Missing_Expression_Recovery_Boundary`. Syntax and
semantic-colouring consumers may use this as a local parser-owned recovery
marker only; it must not be treated as assignment legality, type checking,
left-hand-side validation, or compiler-derived semantic information.

### Pass861 goto target recovery

Malformed `goto` statements that omit the required label target now expose
`Production_Goto_Missing_Target_Recovery_Boundary`. Syntax and semantic-colouring
consumers may use this as a local parser-owned recovery marker only; it must not
be treated as label resolution, goto legality checking, duplicate-label
validation, or compiler-derived semantic information.

### Pass862 — Raise-statement missing-name recovery colouring support

The token cursor now exposes `Production_Raise_Statement_Missing_Exception_Name_Recovery_Boundary`
for in-progress raise statements such as `raise with "message";`. Semantic-colouring consumers
can keep the `raise` keyword, `with` message introducer, and message expression distinct without
requiring compiler legality information.

### Pass 869 — If branch recovery metadata

The Ada token cursor now emits branch-specific recovery metadata for empty `then`, `elsif`, and `else` statement sequences. Semantic-colouring consumers can use this structural metadata to avoid over-colouring branch boundary keywords as malformed branch body expressions.

### Pass870 loop body recovery metadata

The Ada token cursor now emits
`Production_Loop_Missing_Statement_Recovery_Boundary` for empty loop bodies
that recover at `end loop`. Semantic-colouring consumers can use this as a
structural recovery hint without performing render-side parsing or mutating
buffer state.

### Pass871 block statement-sequence recovery metadata

The Ada token cursor now emits
`Production_Block_Missing_Statement_Recovery_Boundary` for empty block
statement sequences that recover at `end` or `exception`. Semantic-colouring
consumers can use this structural recovery hint without performing render-side
parsing, compiler legality checking, or dirty-state mutation.

Pass872 exposes `Production_Case_Alternative_End_Case_Statement_Recovery_Boundary` for malformed or in-progress terminal case alternatives where `end case` follows the choice arrow directly. Semantic-colouring and outline consumers can keep the terminal alternative bounded without rendering-side parsing or compiler legality checks.

Pass873 exposes `Production_Formal_Package_Actual_Empty_Recovery_Boundary` for malformed formal package actual parts written as `()`. Semantic-colouring and outline consumers can avoid treating empty lists as valid omitted actual parts or `(<>)` box defaults, while still relying on parser-owned bounded recovery and snapshot-owned analysis.



### Pass874 exception-handler statement-sequence recovery

Pass874 exposes `Production_Exception_Handler_Missing_Statement_Recovery_Boundary` for malformed or in-progress exception handlers where a `when` choice arrow is followed immediately by another handler, `exception`, `end`, or a semicolon. It also exposes `Production_Exception_Handler_End_Statement_Recovery_Boundary` when the enclosing body end follows the arrow directly. Semantic-colouring and outline consumers can keep exception-handler colouring bounded without rendering-side parsing or compiler legality checks.


### Pass875 use-clause recovery boundaries

Pass875 exposes `Production_Use_Clause_Missing_Name_Recovery_Boundary`, `Production_Use_Clause_Trailing_Separator_Recovery_Boundary`, and `Production_Use_Clause_Missing_Terminator_Recovery_Boundary` for malformed ordinary `use`, `use type`, and `use all type` clauses. Semantic-colouring and resolver consumers can distinguish incomplete visibility clauses from unrelated declarations while retaining the older generic recovery-point metadata for conservative fallback handling.

### Pass877 — Subprogram contract/aspect placement metadata

The Ada token cursor now records subprogram-specific aspect placement for both
subprogram declarations and subprogram bodies.  Contract aspects on those
placements also expose dedicated contract-placement metadata while preserving the
existing contract aspect association, mark, and value productions.  Semantic
colouring can therefore avoid treating body contracts as entry aspects or as
plain generic aspect lists.

### Pass878 — Package declarative recovery boundary metadata

Pass878 adds package-specific metadata for malformed nested declarative items in
package specs and bodies.  Recovery boundaries at `private`, `begin`, and `end`
are now distinguishable so syntax colouring and outline consumers can avoid
attributing recovered partial declarations too aggressively while preserving the
following package structure.

### Pass879 — Anonymous access-to-subprogram recovery metadata

Pass879 adds narrower recovery productions for malformed anonymous
access-to-subprogram profiles.  Syntax colouring and Outline consumers can now
distinguish dangling `access protected`, missing access-function `return`, and
missing result subtype after `return` without reparsing source text or promoting
partial profile tokens into declarations.

### Pass880 — Conditional expression recovery metadata

Pass880 adds narrower metadata for malformed conditional expressions.  Syntax
colouring and Outline consumers can distinguish missing `if` conditions, missing
`then` branch expressions, and missing `else` branch expressions without treating
boundary tokens such as `then`, `else`, `elsif`, `when`, `end`, `)`, or `;` as
ordinary expression names.

### Pass881 — Selected literal name refinement metadata

Pass881 exposes selected literal selectors through the generic selected-selector
path and adds context metadata for selected literal subtype marks in qualified
expressions and allocators.  Syntax colouring and Outline consumers can preserve
operator-symbol and character-literal selected names without flattening them into
ordinary expression literals or reparsing source text.

### Pass882 — Select alternative recovery metadata

Pass882 exposes select-specific missing-statement recovery metadata for empty or
malformed select alternatives, select `else` parts, and asynchronous `then abort`
abortable parts. Semantic-colouring and resolver consumers can use these markers
to avoid treating the following `or`, `else`, `then abort`, `terminate`, or
`end select` boundary as a recovered statement name while still preserving the
surrounding select structure.

The metadata is parser-owned and snapshot-local. It does not perform tasking
legality checking, selective-accept legality checking, compiler invocation, LSP
integration, render-side parsing, or dirty-state mutation.

### Pass883 accept-body recovery metadata

Pass883 keeps semantic-colouring consumers from treating an empty or malformed
`accept ... do` body as an ordinary resolved statement sequence. The token cursor
now emits accept-specific missing-statement recovery metadata, including an
end-boundary marker when recovery lands on the accept `end` keyword. Colouring
and resolver consumers can therefore suppress false-positive bindings inside the
recovered accept body while preserving the accept entry name, following select
alternatives, and following declarations.

### Pass884 generic formal incomplete type metadata

Pass884 exposes formal incomplete type declarations and tagged incomplete formal
suffixes through token-cursor metadata.  Semantic-colouring consumers can use
these markers to colour incomplete generic formal types conservatively, avoid
binding `tagged` as an ordinary identifier, and avoid treating malformed
`type T is;` text as a complete private/interface formal type.

### Pass885 pragma recovery metadata

The syntax-colouring path may use the pass885 pragma recovery productions to
avoid treating malformed pragma identifiers or recovered argument fragments as
fully valid declarations or resolved names.  The metadata is structural and
snapshot-owned; it does not perform pragma legality checking.


### Pass886 — representation-clause recovery colouring safety

Malformed address and attribute-definition representation clauses now carry
clause-specific recovery metadata for missing `use` and missing value
expressions. Semantic colouring consumers can use these recovery boundaries to
avoid treating incomplete representation-clause fragments as fully resolved
attribute values or address expressions.

The metadata remains snapshot-owned and parser-owned; it does not add compiler
legality checking, background project scanning, rendering-side parsing, or dirty
state mutation.

### Pass887 note: broader aspect placement metadata

The Ada token cursor now records package-, task-, protected-, private-type-,
and generic-declaration-specific aspect placement productions. Semantic
colouring may use these productions to keep aspect payload colouring attached
to the correct declaration family, but must not infer aspect legality or
compiler semantics from them.

### Pass888 note: case-expression dependent-expression recovery

Malformed case-expression alternatives with an arrow but no dependent expression
now expose case-expression-specific recovery metadata. Semantic colouring may use
this marker to avoid colouring the following separator, delimiter, or reserved
boundary as a resolved expression name. The marker is parser-owned structural
metadata only and does not imply case-choice legality, expression type checking,
or compiler-grade case coverage.

### Pass889 note: name/attribute prefix recovery metadata

Selected-name attribute prefixes and dangling selected subtype marks now carry
more specific token-cursor metadata. Semantic colouring may use these markers to
avoid treating recovered selectors or incomplete subtype marks as fully resolved
names while still colouring the surrounding declaration structure. The metadata
is snapshot-owned and parser-owned; it does not imply attribute legality,
subtype legality, overload resolution, or compiler-grade name binding.

### Pass890 note: task/protected body declarative recovery metadata

Pass890 gives semantic-colouring and resolver consumers more precise recovery
context for malformed declarative items in task bodies and protected operation
bodies. The new task/protected boundary productions make it possible to avoid
treating a partial recovered declaration as a fully bound symbol when the parser
synchronizes at `begin` or `end`.

### Pass891 note: suppress recovered partial metadata names

Semantic colouring now rejects metadata-only names that come from recovered
partial selected-name contexts before they enter the bounded semantic map. This
prevents incomplete forms such as `Broken.'(1)`, `new Broken.;`, and dangling
visibility names ending in `.` from colouring `Broken` or the recovered leaf as
if they were complete resolved declarations. Concrete resolver targets still win
and keep their symbol-derived colouring.

This is a conservative semantic-colouring follow-through for parser recovery
metadata. It does not add compiler-grade name binding, overload resolution,
render-side parsing, background whole-project scanning, or dirty-state mutation.

### Pass892 note: reduction attribute argument recovery metadata

Malformed reduction attribute argument lists now carry reducer/initial-value
specific recovery markers. Semantic-colouring and resolver consumers may use
these markers to avoid treating commas, close delimiters, semicolons, or reserved
expression boundaries as valid reducer or initial-value names. The metadata is
parser-owned and snapshot-owned; it does not imply callable conformance,
parallel-reduction legality, overload resolution, or compiler-grade expression
checking.

### Pass893 note: quantified-expression predicate recovery metadata

Malformed quantified expressions with a present arrow and missing predicate now
carry a predicate-specific recovery marker. Semantic-colouring and resolver
consumers may use this marker to avoid treating delimiters, separators,
semicolons, or reserved expression boundaries as valid predicate names. The
metadata is parser-owned and snapshot-owned; it does not imply Boolean legality,
iterator legality, overload resolution, or compiler-grade expression checking.

### Pass894 note: declare-expression body recovery metadata

Malformed declare expressions with a present `begin` and missing body expression
now carry a body-specific recovery marker. Semantic-colouring and resolver
consumers may use this metadata to avoid treating delimiters, separators,
semicolons, or reserved expression boundaries as valid expression names. The
metadata is parser-owned and snapshot-owned; it does not imply declaration
legality, expression type checking, overload resolution, or compiler-grade
analysis.

### Pass895 — iterated component association expression recovery

The Ada token cursor now records
`Production_Iterated_Component_Missing_Expression_Recovery_Boundary` for malformed
aggregate iterated component associations where `=>` has no component expression.
Semantic-colouring consumers should treat this production as recovery metadata
and avoid inferring a complete expression from the following delimiter,
separator, or reserved boundary token.

### Pass896 — generic actual recovery colouring guard

Pass896 adds generic-actual-specific recovery productions for empty actual
lists, missing actual values, and trailing separators. Semantic-colouring
consumers should treat these productions as partial/recovered syntax hints, not
as resolved actual expressions or complete generic associations.

### Pass897 — renaming target recovery colouring guard

Pass897 adds renaming-specific missing-target recovery metadata.  Semantic
colouring consumers should treat recovered renaming targets conservatively and
avoid promoting missing or aspect-only targets into resolved renamed entities.
Valid following renamed targets remain visible for ordinary structural
colouring.  The change remains parser-owned and snapshot-owned.

### Pass898 — entry-body statement-sequence recovery colouring guard

Pass898 adds entry-body-specific statement-sequence and missing-statement
recovery metadata.  Semantic-colouring consumers can use this parser-owned
boundary information to avoid treating `end`, `or`, `else`, `then abort`, or
standalone terminators as ordinary executable names inside malformed entry
bodies.  Valid entry body statement sequences continue to expose normal
statement-sequence metadata.

### Pass899 entry-barrier recovery colouring note

Entry barriers with a missing condition now expose entry-specific recovery
metadata. Semantic colouring should continue to treat the recovered boundary as
partial syntax and must not colour the boundary token as a resolved condition
name merely because it follows `when`.

### Pass900 — entry-family empty-definition colouring guard

Empty entry-family definitions now carry entry-family-specific recovery metadata.
Semantic-colouring consumers should treat
`Production_Entry_Family_Empty_Definition_Recovery_Boundary` as partial syntax and
must not colour the empty parentheses as a complete discrete subtype definition.
Valid following entry-family index subtype and parameter-profile metadata remain
available for ordinary structural colouring.


### Pass901 abort target-list recovery

Abort target-list recovery now distinguishes reserved boundaries after separators. Semantic colouring consumers should continue to treat recovered abort target names conservatively and avoid colouring boundary tokens as resolved task names.


### Pass902 requeue target recovery

Requeue target recovery now distinguishes reserved boundaries after the `requeue` keyword. Semantic-colouring consumers should treat `Production_Requeue_Target_Reserved_Boundary_Recovery_Boundary` as recovered partial syntax and must not colour boundary tokens such as `else`, `or`, `when`, or `end` as resolved entry-name targets.

### Pass903 delay expression recovery

Delay expression recovery now distinguishes reserved boundaries after `delay` and `delay until`. Semantic-colouring consumers should treat `Production_Delay_Reserved_Boundary_Recovery_Boundary` as recovered partial syntax and must not colour boundary tokens such as `then`, `when`, `terminate`, or `abort` as resolved delay-expression names.

### Pass904 - goto target reserved-boundary recovery

Goto target recovery now distinguishes reserved boundaries after `goto`. Semantic-colouring consumers should treat `Production_Goto_Target_Reserved_Boundary_Recovery_Boundary` as recovered partial syntax and must not colour boundary tokens such as `else`, `or`, `end`, `exception`, `then`, or `when` as resolved label names.

### Pass905 return expression reserved-boundary recovery

Return expression recovery now distinguishes reserved boundaries after `return`. Semantic-colouring consumers should treat `Production_Return_Reserved_Boundary_Recovery_Boundary` as recovered partial syntax and must not colour boundary tokens such as `else`, `or`, `end`, `exception`, `then`, or `when` as resolved expression names.

### Pass906 raise target reserved-boundary recovery

Malformed raise statements at reserved statement-sequence boundaries now expose `Production_Raise_Target_Reserved_Boundary_Recovery_Boundary`. Semantic colouring and resolver consumers can use this metadata to avoid treating boundary keywords as recovered exception-name targets while preserving valid raise targets after recovery.

### Pass907 exit target reserved-boundary recovery

Malformed exit statements at reserved statement-sequence boundaries now expose `Production_Exit_Target_Reserved_Boundary_Recovery_Boundary`. Semantic colouring and resolver consumers can use this metadata to avoid treating boundary keywords as recovered loop-name targets while preserving valid exit targets and `when` conditions after recovery.

### Pass908 assignment expression reserved-boundary recovery

Malformed assignments at reserved statement-sequence boundaries now expose `Production_Assignment_Reserved_Boundary_Recovery_Boundary`. Semantic-colouring and resolver consumers can use this metadata to avoid treating boundary keywords as recovered assignment expressions while preserving valid assignment targets and following assignments.

### Pass909 call actual association-list recovery

Malformed call actual lists now expose call-actual-specific recovery metadata for empty lists, missing actual expressions, and trailing separators. Semantic-colouring and resolver consumers can treat these markers as recovered partial syntax and avoid colouring separators or close delimiters as resolved actual expressions, while preserving valid following call targets and actual associations.

### Pass910 if/elsif missing-condition recovery

Malformed `if` and `elsif` statement conditions now expose condition-specific recovery metadata when statement-sequence boundary tokens appear where a condition is expected. Semantic-colouring and resolver consumers can suppress false-positive expression colouring for recovered `then`/`else`/`end` boundaries while preserving normal colouring for later valid conditions.

### Pass911 while-loop missing-condition recovery

Pass911 gives malformed `while loop` constructs a dedicated `Production_While_Loop_Missing_Condition_Recovery_Boundary`. Semantic-colouring and outline consumers can treat that boundary as recovered syntax rather than as a resolved condition name, while still seeing valid later `while Ready loop` conditions and loop terminators.

### Pass912 for/iterator loop domain reserved-boundary recovery

Pass912 gives malformed `for ... in` and `for ... of` loop domains dedicated reserved-boundary recovery metadata. Semantic-colouring and outline consumers can treat boundary tokens such as `else`, `or`, `then`, `when`, `exception`, and `end` as recovered syntax rather than as resolved iteration-domain names, while still seeing valid later loop domains and loop terminators.

### Pass913 case selector reserved-boundary recovery

Pass913 gives malformed `case is` constructs a dedicated `Production_Case_Statement_Selector_Reserved_Boundary_Recovery_Boundary`. Semantic-colouring and outline consumers can treat boundary tokens such as `is`, `when`, `else`, `or`, `exception`, and `end` as recovered syntax rather than as resolved selector names, while still seeing valid later case selectors and terminators.

### Pass914 extended return initializer recovery

Malformed extended return object initializers at reserved boundaries now carry
specific recovery metadata.  Semantic-colouring consumers should treat this as a
partial recovered initializer, not as a resolved expression binding, while still
using the surrounding extended-return structure when available.

### Pass915 raise message reserved-boundary recovery

Malformed raise-with-message statements at reserved statement-sequence boundaries now expose `Production_Raise_Message_Reserved_Boundary_Recovery_Boundary`. Semantic-colouring and resolver consumers can use this metadata to avoid treating boundary keywords as recovered message expressions while preserving valid message-expression metadata after recovery.

### Pass916 exit-when condition reserved-boundary recovery

Malformed `exit when` statements at reserved statement-sequence boundaries now expose `Production_Exit_When_Reserved_Boundary_Recovery_Boundary`. Semantic-colouring and resolver consumers can use this metadata to avoid treating boundary keywords as recovered condition expressions while preserving valid condition-expression metadata after recovery.

Malformed null statements at reserved statement-sequence boundaries now expose `Production_Null_Reserved_Boundary_Recovery_Boundary`. Semantic-colouring and resolver consumers can use this marker to avoid interpreting a boundary keyword after `null` as part of a recovered executable construct while preserving valid following null statements.

### Pass918 aggregate component reserved-boundary recovery

Malformed aggregate named component associations at reserved boundaries now expose `Production_Aggregate_Component_Expression_Reserved_Boundary_Recovery_Boundary`. Semantic-colouring and resolver consumers can use this marker to avoid interpreting boundary keywords after `=>` as recovered component expressions while preserving valid following aggregate associations.

### Pass919 — object initialization reserved-boundary recovery

Malformed object declarations with `:=` followed immediately by reserved or aspect/declaration boundaries now expose `Production_Object_Initialization_Reserved_Boundary_Recovery_Boundary`. Semantic-colouring and resolver consumers can use this marker to avoid interpreting `with`, `end`, `else`, or related boundary keywords as recovered initializer expressions while preserving valid following declarations.

### Pass920 range constraint reserved-boundary recovery

Malformed range constraints with reserved boundaries after `range` or `..` now expose `Production_Range_Constraint_Reserved_Boundary_Recovery_Boundary`. Semantic-colouring and resolver consumers can use this marker to avoid interpreting `else`, `then`, `when`, `or`, `exception`, `do`, or similar boundary keywords as recovered range-bound expressions while preserving valid following subtype/declaration metadata.

### Pass921 digits/delta constraint reserved-boundary recovery

Malformed digits and delta constraints with reserved boundaries after `digits` or `delta` now expose `Production_Digits_Constraint_Reserved_Boundary_Recovery_Boundary` and `Production_Delta_Constraint_Reserved_Boundary_Recovery_Boundary`. Semantic-colouring and resolver consumers can use these markers to avoid interpreting `else`, `then`, `when`, `or`, `exception`, `do`, or similar boundary keywords as recovered digits/delta expressions while preserving valid following subtype/declaration metadata.

### Pass922 — Index/discriminant constraint reserved-boundary recovery

Pass922 keeps malformed index and discriminant constraint recovery explicit for semantic-colouring consumers. Reserved boundaries in forms such as `Vector (else)` and `Rec (D => else)` are no longer surfaced as ordinary constraint expressions, reducing false-positive expression/name colouring while preserving valid following constraint metadata.

### Pass923 — Profile default reserved-boundary recovery

Pass923 keeps malformed profile default recovery explicit for semantic-colouring consumers. Boundary tokens after `:=` in parameter defaults are no longer surfaced as ordinary expression/name material, reducing false-positive colouring while preserving surrounding profile and declaration structure.

### Pass924 — Object subtype reserved-boundary recovery

Pass924 keeps malformed object subtype/access-definition recovery explicit for semantic-colouring consumers. Boundary tokens after the declaration colon in forms such as `Missing_With : with Volatile;` are no longer surfaced as ordinary subtype/name material, reducing false-positive colouring while preserving surrounding object declaration and following initializer structure.

### Pass925 — Number initialization reserved-boundary recovery

Pass925 keeps malformed named-number initializer recovery explicit for semantic-colouring consumers. Boundary tokens after `:=` in forms such as `Missing_With : constant := with Volatile;` are no longer surfaced as ordinary expression/name material, reducing false-positive colouring while preserving surrounding number declaration and valid following initializer structure.

### Pass926 — Component default reserved-boundary recovery

Pass926 keeps malformed component default-expression recovery explicit for semantic-colouring consumers. Boundary tokens after `:=` in record component declarations are no longer surfaced as ordinary expression/name material, reducing false-positive colouring while preserving surrounding component declaration and valid following default-expression structure.

Pass927 keeps semantic colouring conservative for recovered discriminant default expressions by exposing discriminant-default-specific reserved-boundary metadata. This lets syntax/semantic consumers distinguish malformed discriminant defaults from valid default expressions without adding compiler-grade type or aspect legality checks.

Pass928 keeps syntax-colouring input conservative for malformed array index parts. Reserved/declaration boundary tokens inside `array (...)` index parts are now surfaced through `Production_Array_Index_Reserved_Boundary_Recovery_Boundary`, so downstream semantic-colouring code can avoid treating recovered boundary tokens as real index expressions or subtype/range names.

### Pass929 access-object missing subtype recovery

Pass929 improves structural Ada grammar recovery for malformed access-to-object definitions where a reserved, aspect, declaration, body, or delimiter boundary appears where the designated subtype would otherwise be parsed. The token cursor now records `Production_Access_Object_Missing_Subtype_Recovery_Boundary` alongside the shared access-type recovery metadata, so semantic-colouring consumers can avoid projecting boundary tokens such as `with`, `private`, `begin`, `end`, `is`, or `)` as subtype names. This remains editor-grade structural parsing, not compiler-grade access-type legality checking or subtype resolution.

### Pass930 access-definition recovery depth

Pass930 adds more discriminating parser metadata for malformed access definitions before semantic-colouring projection. `access all` / `access constant` forms that stop at a boundary now expose mode-specific missing-subtype recovery, general-access modes followed by `procedure`, `function`, or `protected` expose mode/profile conflict recovery, malformed `access protected` retains the boundary token that replaced the required subprogram keyword, and access-to-function `return` clauses at aspect/declaration boundaries expose access-result missing-subtype recovery. Colouring consumers can therefore avoid treating boundary keywords or malformed profile heads as valid designated subtype names. This remains structural editor parsing, not compiler-grade legality or subtype resolution.

### Pass931 generic formal subprogram default recovery

Pass931 adds token-cursor metadata for `is abstract Name` formal subprogram defaults and for missing default targets after `is`.  Semantic-colouring consumers can avoid colouring `with` or declaration terminators as default-name expressions while still preserving following formal declarations.  This remains structural editor parsing, not compiler-grade default conformance or overload resolution.

### Pass932 formal package declaration header recovery

Pass932 adds token-cursor metadata for malformed formal package headers and association ordering. Semantic-colouring consumers can distinguish missing `is`, missing `new`, missing generic package names, and positional actuals after named actuals without reparsing source text or borrowing tokens from following generic formals. This remains structural editor parsing, not compiler-grade generic contract or actual-conformance checking.

### Pass933 use-clause recovery depth

Pass933 adds token-cursor metadata for malformed use clauses before semantic-colouring projection. `use all ...;` without the required `type` keyword now exposes a missing-type recovery boundary, and reserved declaration/package boundaries where a package name or subtype mark was expected now expose use-clause-specific recovery metadata. Colouring consumers can avoid treating boundary keywords as real visibility names while preserving following declarations. This remains structural editor parsing, not compiler-grade visibility legality checking.

### Pass934 representation item recovery metadata

Malformed representation and operational items now expose more specific token-cursor productions for target-boundary, missing-use, missing-attribute-designator, address-value, and enumeration-association recovery. Semantic colouring should continue to consume this as conservative parser metadata and must not infer compiler-grade representation legality from it.

### Pass935 — Subprogram contract/aspect placement depth

Pass935 keeps semantic colouring conservative around richer subprogram contract placement. Contract aspects on ordinary specs, null procedure completions, abstract completions, expression functions, and bodies now retain specific placement metadata, and malformed contract aspect values expose a contract-specific recovery boundary. This helps consumers colour contract marks and values without treating malformed delimiters as ordinary expression names. It is structural parser metadata only, not legality or contract conformance checking.

### Pass936 — Subprogram contract/aspect value-family depth

Pass936 gives semantic-colouring consumers finer structural hooks for contract-related aspect marks and values. `Pre'Class`/`Post'Class` now expose a contract-specific class-wide mark, and contract value families such as `Contract_Cases`, `Exceptional_Cases`, `Always_Terminates`, `Nonblocking`, `Initializes`, and `Depends` retain dedicated parser metadata. Consumers can colour these as contract/dataflow markers without reparsing aspect lists. This is structural metadata only, not legality or conformance checking.

### Pass937 — Package declarative section recovery depth

Pass937 gives semantic-colouring consumers more precise recovery hooks for malformed package section transitions. Duplicate `private` markers, `begin` inside a package private part, and `private` inside a package body declarative part now have dedicated token-cursor productions. Consumers can keep section colouring and declaration recovery deterministic across malformed package specs/bodies without reparsing. This is structural metadata only, not package legality checking.

### Pass938 — Anonymous access-to-subprogram recovery refinement

Pass938 gives semantic-colouring consumers access-specific recovery hooks for malformed anonymous access-to-subprogram profiles. Missing closing delimiters in access-to-procedure/function parameter profiles and missing result subtypes after `return not null` now have dedicated token-cursor productions, so consumers can avoid colouring `with`, `is`, `private`, `begin`, or `end` boundaries as profile/result subtype names. This is structural parser metadata only, not access-type legality, profile conformance, or result-subtype checking.

### Pass939 — Expression recovery refinement

Pass939 adds semantic-colouring hooks for malformed expression branches. Consumers can now avoid colouring reserved boundaries such as `then`, `elsif`, `is`, `when`, `begin`, `private`, or `end` as conditional/case operands, and can distinguish malformed `Parallel_Reduce` argument recovery from ordinary reduction metadata. This is structural parser metadata only, not expression legality, overload resolution, static evaluation, or reduction profile checking.

### Pass940 — Name grammar recovery depth

Pass940 keeps selected-name, allocator, and qualified-expression recovery parser-owned for semantic-colouring consumers. Malformed `Root.with`, `new ;`, `T'(with)`, and `new T'()` forms now expose dedicated recovery metadata instead of letting boundary tokens masquerade as selectors, allocator subtype marks, or qualified-expression operands. Existing selected operator-symbol and character-literal selector metadata remains available for conservative colouring.

### Pass941 — Protected entry-body barrier recovery depth

Pass941 adds semantic-colouring hooks for protected entry bodies whose `when` barrier is missing before `is`. Consumers can observe `Production_Entry_Body_Missing_Barrier_Recovery_Boundary` and `Production_Protected_Entry_Body_Missing_Barrier_Recovery_Boundary` and avoid treating `is`, `begin`, or following operation keywords as barrier-condition names. This is parser-owned structural metadata only, not tasking legality or barrier expression checking.

### Pass942 Ada 2022 expression grammar nodes

Pass942 adds syntax-tree hooks for Ada 2022 expression families that semantic-colouring consumers previously had to infer from raw expression text or token-cursor production labels. Consumers can now observe `Node_Declare_Expression`, `Node_Delta_Aggregate`, `Node_Container_Aggregate`, `Node_Reduction_Expression`, `Node_Iterator_Specification`, and `Node_Target_Name` under expression/declaration-default nodes. This supports the compiler-grade grammar pivot by making later semantic passes parser-owned and deterministic, while full legality and type analysis remain separate follow-up work.

### Pass943 declarative-region foundation

Pass943 adds a parser-owned declarative-region model exposed by `Editor.Ada_Declarative_Regions`. Semantic-colouring and Outline consumers can now rely on stable region ownership and parentage derived from syntax-tree nodes instead of inferring nested declarative scope from raw text. This is a compiler-grade semantic foundation for later name-resolution and visibility passes; it does not yet colour references using full Ada visibility or overload legality.

### Pass944 direct-visibility semantic foundation

Pass944 adds `Editor.Ada_Direct_Visibility`, which builds a deterministic direct-visibility table from the Ada syntax tree and declarative-region model. Semantic-colouring consumers can now distinguish directly declared names in the current/enclosing region from purely lexical identifiers without reparsing source text. This is a compiler-grade foundation for later reference colouring and unresolved-name diagnostics, but it intentionally does not yet apply use-clause visibility, overload resolution, expected-type filtering, or type legality.

## Pass945 semantic-colouring note

The Ada language model now has stable use-clause metadata via
`Editor.Ada_Use_Visibility`. Semantic colouring can distinguish direct names
from names made visible through ordinary package `use` clauses once it consumes
this model. The pass deliberately records `use type` and `use all type` clauses
without pretending to complete operator-visibility legality; those semantics
belong to later type and overload passes.

### Pass 946 selected-name semantic metadata

The Ada language model now has parser-owned selected-name resolution metadata for
package-prefix forms such as `Library.Exported`. Semantic colouring can use the
prefix declaration, prefix region, selector declaration, and resolution status to
colour resolved selectors conservatively without reparsing in the renderer. This
is a semantic foundation only; type-dependent component selection and overload
filtering remain later passes.

### pass947 — use-type primitive operator metadata

The Ada semantic pipeline now exposes a parser-owned `Editor.Ada_Use_Type_Operators` model.  Semantic colouring may use the model to distinguish operator and primitive-subprogram candidates made visible by `use type` and `use all type` clauses without reparsing source text or consulting renderer state.  The metadata is deterministic and snapshot-owned; later passes will add expected-type and overload filtering before using it as a legality decision.

## pass948 — call-candidate semantic metadata

The Ada language-intelligence layer now exposes parser-owned call-candidate metadata through `Editor.Ada_Call_Candidates`.  Semantic-colouring consumers can distinguish call-shaped nodes that have visible callable candidates, unresolved call names, ambiguous candidates, and primitive candidates exposed through `use type`, without reparsing in rendering code.  The metadata is deterministic and snapshot-owned; colour consumers must still treat it as pre-overload filtering until later expected-type and profile-conformance passes are integrated.

## pass950 — call-profile filter foundation

Pass950 adds `Editor.Ada_Call_Profile_Filters` so semantic colouring and Outline-adjacent consumers can reuse parser-owned overload-filter metadata rather than reparsing call text.  The model classifies compatible positional calls, too-many-actual calls, and named-actual calls structurally for later compiler-grade overload-resolution passes.  It does not mutate buffers, dirty state, rendering state, command routing, keybindings, or workspace state.

## pass951 — formal-name/default call-profile filtering

Pass951 extends overload-filter metadata available to Outline and semantic-colouring-adjacent consumers. Callable profile shapes now retain formal names and defaulted-formal metadata, while actual profiles retain named-actual names. The filter distinguishes formal-name-compatible calls, unknown named actuals, and calls missing required non-defaulted formals. It remains snapshot-owned and does not mutate buffers, dirty state, rendering state, command routing, keybindings, or workspace state.

## pass952 — call-resolution result metadata

Pass952 exposes parser-owned call-resolution result metadata through `Editor.Ada_Call_Resolution`. Semantic-colouring and diagnostics-adjacent consumers can now distinguish unresolved call names, pre-profile ambiguous call designators, no-viable-profile calls, and uniquely profile-compatible calls without reparsing in rendering code. The model is deterministic and snapshot-owned and does not mutate buffers, dirty state, rendering state, command routing, keybindings, or workspace state.


### Pass953 expected-type context foundation

Added `Editor.Ada_Expected_Type_Contexts` to attach deterministic expected-subtype context metadata to call-shaped expression nodes and syntax-owned declaration defaults, simple assignments, and ordinary return statements. The model now feeds expected-type overload filtering, expression typing, assignment legality, return legality, and live semantic diagnostics while remaining snapshot-owned and free of renderer-side parsing or editor-state mutation.


### Pass953 expected-type context foundation

Added `Editor.Ada_Expected_Type_Contexts` to attach deterministic expected-subtype context metadata to call-shaped expression nodes and syntax-owned declaration defaults, simple assignments, and ordinary return statements. The model now feeds expected-type overload filtering, expression typing, assignment legality, return legality, and live semantic diagnostics while remaining snapshot-owned and free of renderer-side parsing or editor-state mutation.

### pass954 — expected-call result-subtype filtering

Pass954 adds semantic metadata that can later help diagnostics and semantic colouring distinguish calls whose result subtype matches the surrounding expected subtype from calls that mismatch that context. The model remains snapshot-owned and derived from parser/semantic tables only; no renderer-side parsing or dirty-state mutation is introduced.

### pass955 — subtype compatibility metadata

Pass955 adds conservative subtype-compatibility metadata for expected-call filtering. Future diagnostics and semantic-colouring refinements can distinguish exact result-subtype matches, universal numeric compatibility, known predefined numeric mismatches, and indeterminate user-defined subtype relationships. The model is snapshot-owned and derived from parser/semantic tables only; no renderer-side parsing, compiler invocation, file mutation, or dirty-state mutation is introduced.

### pass956 — declaration-derived type graph metadata

Pass956 adds type-graph metadata for semantic-colouring and future diagnostics. Type, subtype, and formal type declarations now have a stable semantic type node with declaration ownership, owning region, category, parent-subtype relationship, and deterministic fingerprint. This does not alter rendering: the renderer consumes existing semantic classifications and never reparses. The model is snapshot-owned and uses parser/semantic tables only; it performs no compiler invocation, LSP request, file mutation, background scan, or dirty-state mutation.

Pass957 adds type-graph-aware expected-call metadata for future semantic colouring and diagnostics. Call-shaped expression nodes with expected subtype contexts now retain declaration-derived compatibility status, including derived-from, subtype-of, and known-different-root classifications. Rendering behaviour is unchanged: no renderer-side parsing, compiler invocation, LSP request, background scan, file mutation, or dirty-state mutation is introduced.

Pass965 adds fixed-point static-expression metadata. Semantic-colouring consumers may use fixed-point type/delta/range statuses conservatively for diagnostics-facing overlays, but analysis remains snapshot-owned and must not move parsing into rendering or mutate buffer/workspace state.

Pass966 adds generic contract metadata for formal declarations and instantiation actual shapes. Semantic-colouring consumers may use this metadata only as snapshot-owned analysis data; it must not trigger render-side parsing, compiler invocation, LSP queries, file reload/save, background whole-project scans, or dirty-state mutation.

### Pass967 generic formal/actual matching metadata

Pass967 extends `Editor.Ada_Generic_Contracts` with snapshot-owned formal/actual match records for generic instantiations. Syntax-colouring and diagnostics consumers may use the match status conservatively to distinguish valid staged actual shape from unresolved generic names, non-generic targets, too many positional actuals, unknown or duplicate named actuals, and missing non-defaulted formals. Consumers must not perform renderer-side parsing, compiler invocation, LSP queries, file mutation, background whole-project scans, or dirty-state mutation.

### Pass968 - generic actual-kind metadata

Generic instantiation actuals now carry conservative type/object/subprogram/package shape metadata through `Editor.Ada_Generic_Contracts`. This supports later diagnostic-aware colouring for generic contract mismatches while preserving the invariant that rendering consumes analysed metadata only.


### Pass969 - generic formal subprogram profile conformance

Pass969 extends `Editor.Ada_Generic_Contracts` with formal subprogram profile conformance metadata. Generic formal subprograms now retain parameter-count, normalized parameter-subtype shape, result presence, and result-subtype metadata. Generic instantiation actuals retain positional/named actual designator text, allowing declaration-shaped subprogram actuals to be resolved through direct visibility and compared against the formal profile. The match model now distinguishes formal-kind mismatches from formal subprogram profile mismatches and records deterministic compatible/mismatched/unknown profile counts. Regression coverage is in `Test_Ada_Generic_Formal_Subprogram_Profile_Conformance_Pass969`. This is a compiler-grade generic-contract building block; full Ada generic conformance still requires overload-aware subprogram actual selection, formal package contract matching, generic body contract visibility, private-view rules, freezing/representation legality, and cross-unit semantic closure.


### Pass970 - generic formal package contract conformance

Pass970 extends `Editor.Ada_Generic_Contracts` with formal package contract conformance metadata. Generic formal package records now retain their expected target generic name, normalized target, and box actual-state marker. Generic instantiation matching resolves package actuals through direct visibility, recognizes inline `new Generic (...)` package actuals, verifies that declaration-shaped package actuals are package instantiations, and compares the actual package instance target generic against the formal package contract. The match model now distinguishes formal package contract mismatches and unknown formal package contract cases, including unresolved actuals, ambiguous actuals, non-instance package actuals, wrong-generic package instances, unknown formal contracts, and malformed package actuals, with deterministic compatible/mismatched/unknown counters exposed through `Formal_Package_Compatible_Count_For_Instance`, `Formal_Package_Mismatch_Count_For_Instance`, and `Formal_Package_Unknown_Count_For_Instance`. Regression coverage is in `Test_Ada_Generic_Formal_Package_Contract_Conformance_Pass970`. This pass adds one compiler-grade generic-contract building block. Full compiler-grade Ada analysis remains incomplete until remaining layers such as overload-aware actual selection, generic body contract visibility, private-view rules, default-expression legality, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### pass971

The generic-contract model now exposes formal type/object/subprogram/package declarations for matching generic body regions.  This is semantic metadata for later colouring/navigation integration; rendering-side parsing remains prohibited.

### pass972

Generic subprogram actuals now retain overload-selection metadata in the parser-owned semantic model.  This supports later diagnostics and semantic colouring without renderer-side parsing: ambiguous generic actual designators can be classified as selected, unresolved, or profile-ambiguous before any display projection consumes the result.
\nPass974: Generic-contract analysis now retains formal subprogram parameter mode vectors and classifies declaration-shaped subprogram actuals with same arity/subtypes but nonconforming modes as deterministic mode mismatches. Regression coverage: Test_Ada_Generic_Formal_Subprogram_Mode_Conformance_Pass974.

### pass975

The Ada semantic model now exposes type-graph-aware generic formal subprogram profile conformance. Syntax colouring remains a consumer of stable model metadata only; no parsing or semantic classification is performed from the renderer.


Pass976 adds a compiler-grade generic profile-conformance building block for formal subprogram null-exclusion and anonymous access-to-subprogram profile matching. Generic actual matching now records and reports null-exclusion mismatches and access-profile mismatches separately from generic profile mismatches, with deterministic counters and regression coverage in Test_Ada_Generic_Formal_Subprogram_Null_Access_Conformance_Pass976. Full compiler-grade Ada analysis remains incomplete until private-view rules, freezing, representation legality, cross-unit closure, and full expression type inference are fully integrated.


Pass977 note: semantic-colouring consumers may now distinguish generic formal subprogram convention mismatches from ordinary profile mismatches via the generic-contract model metadata.

### pass978

Generic subprogram actual conformance metadata now includes defaulted-parameter mismatch classification. The colouring layer remains projection-only and must consume the parser-owned semantic model without reparsing or mutating editor state.

### Pass983 private-view-aware subtype compatibility

Subtype-compatibility metadata now has a private-view-aware path. Semantic-colouring and diagnostics consumers may use `Subtype_Compatibility_Private_View_Partial_View`, `Subtype_Compatibility_Private_View_Full_View`, and `Subtype_Compatibility_Private_View_Hidden_Full_View` to classify private-type compatibility in visible, private, and body contexts without rendering-side parsing.

### Pass984 freezing-point model foundation

Freezing metadata is now available through `Editor.Ada_Freezing_Points`. Semantic-colouring and diagnostics consumers may use representation freeze-order statuses to mark representation clauses that appear after a target has already been frozen, while preserving snapshot ownership and avoiding rendering-side parsing.

### Pass987 enumeration representation legality

The semantic layer now provides deterministic metadata for enumeration representation literal associations. Colouring remains projection-only; diagnostics or hover surfaces can reuse the metadata to explain invalid literal mappings without reparsing in the renderer.

### Pass988 address clause legality
Address-clause semantic metadata is now available for diagnostic and colouring consumers without rendering-side parsing. Static address values, incompatible targets, null values, raw literals, and non-static names are represented as deterministic analysis metadata.


Pass 993 note: semantic-colouring consumers can now distinguish malformed operational representation attributes from valid Boolean/storage-order clauses through representation-legality metadata.


### Pass994 representation/aspect source metadata

Semantic-colouring consumers can distinguish representation properties sourced from aspect associations versus attribute-definition clauses through `Representation_Source_Form`, while retaining a unified legality classification for both source forms.

### Pass995 cross-unit closure

The Ada semantic layer now exposes a deterministic cross-unit closure model for spec/body, child/parent, parent/child, and separate-body parent relationships. Colouring remains snapshot-owned and must consume this metadata only through analysis-owned models.

### Pass996 note

Cross-unit semantic closure now includes context dependency links for ordinary `with`, `limited with`, `private with`, and context `use` package clauses. The dependency model is snapshot-owned, project-index-backed, deterministic, and preserves missing/ambiguous/overflow states for later semantic consumers.

## Pass997 cross-unit spec/body consistency

Pass997 extends the cross-unit semantic-closure model with deterministic spec/body consistency metadata. The model now records confirmed package/subprogram spec/body pairs and missing, ambiguous, overflow, role-mismatch, and name-mismatch conditions with stable fingerprints. This is parser/index-owned semantic data and does not require rendering-side parsing, file reloads, dirty-state mutation, or compiler invocation.

Pass998: cross-unit closure now includes deterministic child-unit and private-child legality metadata. Child library units are classified as resolved public children, resolved private children, missing-parent children, ambiguous-parent children, overflowed children, or parent-role mismatches, with stable query APIs and AUnit coverage in `Test_Ada_Cross_Unit_Child_Private_Legality_Pass998`.

Pass999: cross-unit closure now includes deterministic separate-body legality metadata. Separate bodies are classified separately from raw separate-parent links as resolved parent bodies, missing parents, ambiguous parents, overflow, parent-role mismatches, or missing parent-name text, with stable query APIs and AUnit coverage in `Test_Ada_Cross_Unit_Separate_Body_Legality_Pass999`.

Pass1000: semantic colouring can consume `Editor.Ada_Expression_Types` metadata to distinguish resolved names, unresolved names, ambiguous calls, static numeric literals, Boolean/string/null literals, operator families, qualified expressions, aggregate-context requirements, and attribute result families without renderer-side parsing.

Pass1001 note: expression type inference now has an opt-in expected-type propagation layer. Declaration-default contexts and existing expected-context metadata are staged into deterministic expression records with compatible/propagated/mismatch/unknown statuses for later diagnostics and overload/type checking.

Pass1002 note: expression type inference now records deterministic operator operand/result metadata for predefined numeric, Boolean, short-circuit, relational, and membership-shaped operators. Operand mismatch and unknown cases remain explicit for later diagnostics and overload-aware typing.

Pass1003: expression aggregate context inference adds context-sensitive aggregate/container-aggregate metadata, component-shape counters, and deterministic unknown/mismatch preservation to the Ada expression-type model.

Pass1004 update: expression type inference now includes conversion and qualified-expression target/operand metadata. The model exposes deterministic counters for resolved conversion targets, compatible operands, explicit-conversion operands, mismatches, and unknown conversion cases, with regression coverage in `Test_Ada_Expression_Conversion_Qualified_Inference_Pass1004`.

Pass1005 update: attribute-reference expression inference now preserves attribute names, prefixes, result subtype families, unresolved-prefix cases, and unknown-attribute cases for semantic consumers. Regression coverage is in `Test_Ada_Expression_Attribute_Reference_Inference_Pass1005`.

Pass1006: Added conditional/declare/reduction expression type inference metadata in Editor.Ada_Expression_Types. The model now tracks compatible/mismatched/unknown conditional branches, Boolean quantified results, declare-expression result staging, reduction-expression result staging, deterministic counters, and fingerprint contribution. Regression coverage: Test_Ada_Expression_Conditional_Declare_Reduction_Inference_Pass1006.


Pass1007: Added expression membership/range inference metadata. Membership expressions now retain Boolean result plus operand/choice compatibility state; range expressions retain bound subtype compatibility state; deterministic counters and fingerprints cover resolved, mismatch, and unknown cases.

Pass1008: Added expression target-name/update inference metadata. Ada 2022 target-name @ expressions now preserve context-required versus context-propagated status, delta/update aggregates retain expected/source subtype compatibility metadata, and deterministic counters/fingerprints expose compatible, mismatch, and unknown update-expression cases.


Pass1009 note: semantic-colouring consumers can now distinguish indexed component and slice expression metadata from the expression type model without performing rendering-side parsing.

Pass1010 note: semantic-expression metadata now distinguishes explicit dereference and Access-family attribute result shapes. Colouring remains projection-only and may consume the new metadata without parsing during rendering.

Pass1017: Expression type inference now includes raise-expression/no-return metadata with exception target, message shape, expected result context, deterministic counters, and AUnit coverage.

### Pass1018 — Boolean-context semantic metadata

`Editor.Ada_Expression_Types` now retains Boolean-context inference status for short-circuit and condition-shaped expressions. This is semantic metadata only; rendering remains projection-only and performs no parsing or mutation.

### Pass1019 — concatenation semantic metadata

`Editor.Ada_Expression_Types` now retains concatenation result metadata for string and array `&` expressions. This is semantic metadata only; rendering remains projection-only and performs no parsing or mutation.

### Pass1020
Pass1020 adds dispatching-call inference metadata to `Editor.Ada_Expression_Types`, including primitive target, static binding, dynamic dispatch candidate, controlling-result, ambiguous, unresolved, and unknown classifications with deterministic counters and fingerprints.
### Pass1021
Pass1021 adds projection-only expression diagnostics metadata. The layer is suitable for later semantic-colouring and diagnostics surfaces because it retains stable spans, severity, diagnostic kind, and deterministic fingerprints without rendering-side parsing or mutation.


### Pass1035 semantic metadata

Formal package nested actual conformance is available through `Editor.Ada_Generic_Formal_Package_Nested_Conformance`. Colouring and annotation consumers should treat it as semantic metadata only; they must not parse source or mutate buffers/rendering state.

### Pass1036 semantic metadata

Generic renaming and nested generic-instantiation metadata is now available through `Editor.Ada_Generic_Renaming_Visibility`. Semantic-colouring and navigation consumers can distinguish generic aliases, instantiations through aliases, direct nested instantiations, unresolved renamed targets, and malformed instantiation targets without reparsing source text or mutating renderer state.

### Pass1037 semantic metadata

Generic formal-object default and actual-expression type-conformance records are now available as parser-owned semantic metadata. Rendering remains projection-only; consumers should use the stored source spans and fingerprints rather than re-running analysis.

Pass1039 update:
- Added Editor.Ada_Cross_Unit_Diagnostics to project cross-unit visibility and closure metadata into deterministic diagnostics.
- Covers missing/ambiguous dependencies, limited-view full-view restrictions, private-with visible-part restrictions, body/spec conformance failures, private-child visibility restrictions, child-parent errors, and separate-body stub/parent errors.
- Added Test_Ada_Cross_Unit_Diagnostics_Projection_Pass1039.

Pass1041: Parser-owned semantic diagnostics can be projected into syntax-colouring overlays through Editor.Ada_Semantic_Colour_Projection. This remains a projection-only bridge: it maps already-built diagnostics to existing token buckets and does not parse or mutate from the render path.

Pass1042: Semantic-colouring diagnostic overlays are now protected by Editor.Ada_Semantic_Diagnostic_Snapshot_Guards. The guard is projection-only and rejects overlays whose path, buffer token, revision, lifecycle generation, request token, or analysis fingerprint no longer matches the current analysis request.

Pass1043: Semantic-colouring diagnostic overlays now have an IDE-facing feed layer through Editor.Ada_Semantic_Diagnostic_Feed. The feed consumes only snapshot-accepted overlays, preserves source/severity/token/span metadata, and withholds all stale entries when snapshot guards reject the analysis.

Pass1044: Semantic diagnostic overlays now have an IDE-facing index layer through Editor.Ada_Semantic_Diagnostic_Index. The index queries accepted unified feed entries by span, position, severity, diagnostic source family, token kind, and syntax node, while preserving stale-feed rejection semantics and keeping rendering projection-only.

## Pass1045 semantic diagnostic navigation

Semantic diagnostic overlays now have a deterministic navigation projection through `Editor.Ada_Diagnostic_Navigation`. The navigation model consumes the semantic diagnostic index and preserves stable spans, severity, semantic source family, token kind, syntax node, message payload, feed/index identity, and fingerprint for first/last and next/previous navigation targets. This keeps syntax and semantic colouring render-safe: rendering receives projection data only and performs no parsing or semantic lookup.

## Pass1046 semantic diagnostic panel projection

Semantic diagnostics now have a deterministic panel projection through `Editor.Ada_Diagnostic_Panel_Projection`. The projection consumes the guarded semantic diagnostic index and preserves row identity, source span, severity, semantic source family, token kind, syntax node, message payload, optional file/unit labels, grouping metadata, selected-row state, and fingerprints. Rendering remains projection-only and does not perform parsing or semantic lookup.

## Pass1047 semantic diagnostic status-line summary

The Ada semantic diagnostic pipeline now includes `Editor.Ada_Diagnostic_Status_Line`, a projection-only status-line model over `Editor.Ada_Semantic_Diagnostic_Index`. It keeps status presentation deterministic by using accepted guarded diagnostics only, summarizing severity totals and nearest diagnostic metadata without parsing or rendering-side semantic work.


## Pass1048 semantic diagnostic quick-fix skeleton

The Ada semantic diagnostic pipeline now includes `Editor.Ada_Diagnostic_Quick_Fix_Skeleton`, a projection-only action-candidate layer. It consumes accepted semantic diagnostic indexes and exposes non-mutating quick-fix skeletons while preserving existing snapshot guard boundaries and render-safe projection behavior.

## Pass1049 semantic diagnostic provenance

Semantic diagnostic consumers now have a projection-only provenance model for explain-diagnostic UI flows. The model consumes only the guarded diagnostic index and records the accepted chain from semantic source to diagnostic index without parsing, file IO, buffer mutation, command registration, workspace mutation, or rendering-side semantic work.

## Pass1050 semantic diagnostic suppression / baseline metadata

Pass1050 keeps semantic-colouring diagnostic overlays projection-only while adding a separate metadata consumer for suppression and baseline classification. `Editor.Ada_Diagnostic_Suppression_Baseline` consumes the guarded semantic diagnostic index and preserves stable diagnostic spans, severity, source family, token kind, syntax node, messages, and fingerprints while recording whether an IDE consumer should treat a diagnostic as active, suppressed, or baselined. Stale indexes continue to expose no active entries.

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
- Cross-unit selected-name prefix visibility is now part of the language-model metadata path. The selected-name resolver records whether a prefix came from ordinary with visibility, context use visibility, limited incomplete view, private view, missing dependency, ambiguity, or overflow.
- Rendering remains a projection-only consumer; cross-unit lookup resolution is performed before rendering in the snapshot-owned semantic model.

Pass1055: cross-unit selected-name expression inference added; expression metadata now preserves cross-unit selected-name target/selector identity and deterministic counters while maintaining snapshot-owned analysis invariants.
Pass1057 adds private/limited-view compatibility diagnostics to the expression diagnostic source consumed by semantic-colouring projection; compatible view metadata is not emitted as a diagnostic token.

Pass1058 adds no new syntax-colouring token class. It prepares generic contract diagnostics to distinguish private/limited view barriers from ordinary actual/default mismatches before those diagnostics are projected into the guarded semantic-colouring path.

Pass1059 adds no new syntax-colouring token class. It routes generic view-compatibility barriers into generic contract diagnostics, so existing guarded semantic-colouring diagnostic overlays can later surface private/limited generic barriers without rendering-side parsing.

Pass1061 adds instantiated-body substitution diagnostics to the generic contract diagnostic family before semantic-colouring projection. These diagnostics preserve stable source spans and severity without adding render-side analysis.


### Pass1063 — Nested body/spec diagnostics projection

Pass1063 extends `Editor.Ada_Cross_Unit_Diagnostics` with `Build_With_Nested`, projecting `Editor.Ada_Nested_Body_Spec_Conformance` results into the cross-unit diagnostics model. Diagnostics now cover nested missing body declarations, extra body declarations, ambiguous body declarations, kind/profile mismatches, profile-unknown cases, and nonconforming enclosing unit pairs while preserving nested conformance identity/status, declaration names, spans, severity, messages, counters, and deterministic fingerprints. The existing `Build` path remains unchanged for first-order cross-unit diagnostics. Regression coverage is in `Test_Ada_Cross_Unit_Diagnostics_Nested_Body_Spec_Pass1063`.

This pass adds one compiler-grade building block for nested body/spec diagnostic projection. Full compiler-grade Ada analysis remains incomplete until overload resolution, type checking, generic contracts, freezing/representation legality, and cross-unit semantic closure are fully integrated.

### Pass1064 — Selected-name representation target resolution

Pass1064 adds `Editor.Ada_Selected_Representation_Targets`, a deterministic representation-target consumer that combines `Editor.Ada_Cross_Unit_Representation_Targets` with `Editor.Ada_Selected_Name_Resolution`. Representation clauses whose targets are selected names now preserve selected-name identity/status, prefix/selector text, visible cross-unit target unit/path, candidate counts, classification counters, and deterministic fingerprints. The layer distinguishes local selected targets, cross-unit visible selected targets, use-visible selected targets, limited/private-view barriers, missing/ambiguous/overflow prefixes, selector errors, and non-selected targets without parsing, file IO, buffer mutation, command registration, workspace mutation, or rendering-side semantic work. Regression coverage is in `Test_Ada_Selected_Representation_Targets_Pass1064`.

## Pass1065 selected representation target diagnostics

Representation clauses that target selected names now contribute diagnostics for private/limited view barriers, missing or ambiguous prefixes, bounded lookup overflow, selector failures, and unresolved selected targets. The colouring path remains a projection consumer of guarded diagnostics.

Pass1075 note: diagnostic action routing now joins quick-fix skeletons with diagnostic navigation, panel rows, provenance/explain items, status-line nearest-target metadata, and explicit feed edit hints through `Editor.Ada_Diagnostic_Action_Router`. The layer is projection-only and preserves stale-result rejection; it does not parse, mutate buffers, save/reload files, register commands, touch workspace state, or perform rendering-side semantic work.

Pass1076 note: diagnostic command projection now turns diagnostic action routes into deterministic command-facing descriptors through `Editor.Ada_Diagnostic_Command_Projection`, preserving explicit feed edit hints as descriptor metadata for executor-owned application. The layer is projection-only and does not register commands, invoke commands, apply edits, parse, mutate buffers, save/reload files, touch workspace state, or perform rendering-side semantic work. Rejected/stale action-route models expose no active command descriptors while preserving rejected-command totals.

Pass1077 note: diagnostic command palette projection now turns diagnostic command descriptors into deterministic command-palette-facing entries through `Editor.Ada_Diagnostic_Command_Palette_Projection`. The layer is projection-only and does not register command aliases, mutate keybindings, invoke commands, apply edits, parse, mutate buffers, save/reload files, touch workspace state, or perform rendering-side semantic work. Rejected/stale command projection models expose no active palette entries while preserving rejected-entry totals.

### Pass1082 recovery status projection

Diagnostic recovery status rows may be used by UI layers to describe retained,
changed, missing, or stale diagnostic render rows.  The model is immutable and
projection-only; syntax colouring and rendering continue to consume prepared
metadata rather than parsing or analysing source text.

- Pass1084: added projection-only diagnostic recovery command descriptors for lifecycle/recovery actions while preserving stale-result rejection and no mutation boundaries.

Pass1093: Diagnostic recovery-render command palette projection is downstream of guarded diagnostic and render-recovery metadata. It adds no syntax-colouring buckets and does not perform lexical parsing, semantic parsing, or rendering-side semantic work.

Pass1096: added final render-safe diagnostic recovery-render projection over recovery-render workspace/session state, preserving stable keys and rejected-state accounting without rendering-side semantic work.

## Pass1098 final diagnostic recovery-render lifecycle status

`Editor.Ada_Diagnostic_Recovery_Render_Final_Status` summarizes final recovery-render lifecycle state for IDE consumers after guarded diagnostic projection. It preserves stable diagnostic metadata and fingerprints while exposing no active status rows for rejected stale final lifecycle inputs. Rendering remains projection-only and performs no parsing or semantic lookup.

Pass1099 note: Added `Editor.Ada_Assignment_Legality` as a semantic rule-completion pass for assignment and object-initialization legality.  The pass is snapshot-owned and projection-free: it consumes existing expression, subtype, static, type/view metadata and classifies target/source compatibility, constant/in-formal target errors, null-exclusion violations, static range violations, private/limited view barriers, unresolved universal numeric cases, and indeterminate cases without render-side parsing or editor mutation.

Pass1100 note: added `Editor.Ada_Return_Legality`, a snapshot-owned semantic legality layer for Ada return statements. It consumes assignment/object-initialization legality results and classifies legal procedure/function/extended returns plus illegal expression shape, incompatible result subtype, private/limited view barriers, unresolved result metadata, static range violations, unresolved universal numeric returns, and No_Return subprogram return statements. No diagnostic UI projection chain layer, rendering-side parsing, file save/reload, or mutable IDE-surface side effect is introduced.

Pass1101 note: widened the semantic pass scope by adding `Editor.Ada_Conversion_Access_Aggregate_Legality`, a snapshot-owned semantic legality layer covering conversion and qualified-expression legality, numeric/static range conversion checks, tagged/class-wide conversion classification, access/null-exclusion/accessibility foundations, allocator designated-subtype compatibility, aggregate structural legality, and container aggregate missing-aspect classification. Added `Test_Ada_Conversion_Access_Aggregate_Legality_Pass1101` and registered it in `Core_Suite`. No diagnostic UI projection chain layer, rendering-side parsing, file save/reload, dirty-state mutation, command/keybinding/workspace mutation, or render mutation is introduced.

Pass1102: Added `Editor.Ada_Control_Flow_Legality`, a wide snapshot-owned semantic legality layer for Ada control-flow and statement rules.  The pass classifies Boolean condition legality, case choice staticness/coverage/duplicates, exit/goto/label target legality, exception handler choices, raise targets, select/accept/requeue target checks, and return-path completeness without render-side parsing or editor mutation.

Pass1103 update: added `Editor.Ada_Tasking_Protected_Legality`, a snapshot-owned semantic legality layer for Ada task/protected type and body matching, entry declarations/bodies/families, protected barriers, accept/requeue legality, protected operation restrictions, select integration, and linked control-flow legality propagation. Added and registered `Test_Ada_Tasking_Protected_Legality_Pass1103`. No diagnostic projection chain, rendering-side parsing, file save/reload, dirty-state mutation, or command/keybinding/workspace/render mutation is introduced.

### Pass1104 tagged/derived legality note

Pass1104 adds `Editor.Ada_Tagged_Derived_Legality` as a semantic layer for tagged derivation, private extensions, interfaces, overriding, abstract-operation requirements, dispatching legality propagation, and class-wide conversion legality. Syntax colouring remains a consumer of stable semantic metadata only; no rendering-side parsing or colouring-side semantic mutation is introduced.

Pass1105 note: Generic instance/freezing/representation semantic closure is now available through `Editor.Ada_Generic_Instance_Freezing_Representation_Legality`. Semantic-colouring consumers should continue to consume stable language-model/diagnostic metadata only; the new layer introduces no rendering-side parsing or render mutation.

Pass1106 note: Cross-unit semantic closure status is now available through `Editor.Ada_Cross_Unit_Semantic_Closure`. Semantic-colouring consumers should continue to consume stable language-model/diagnostic metadata only; the new layer introduces no rendering-side parsing or render mutation.

Pass1107: wide semantic legality diagnostics bridge added for Pass1099-Pass1106 compiler-grade legality layers, preserving snapshot ownership and deterministic fingerprints.

Pass1108 update:
- Integrated the Pass1107 wide semantic legality diagnostics into the unified snapshot-guarded semantic diagnostic feed via Build_With_Wide_Legality.
- Wide assignment, return, conversion/access/aggregate, control-flow, tasking/protected, tagged/derived, generic-instance, and cross-unit legality failures now participate in the normal diagnostic feed and index.
- Stale wide legality inputs and rejected base semantic guards expose zero active feed rows while preserving rejected-entry accounting.
- Added AUnit coverage in Test_Ada_Wide_Semantic_Diagnostic_Feed_Integration_Pass1108 and registered it in Ada_Language_Suite.

Pass1109 update: added Editor.Ada_Overload_Resolution_Legality as a compiler-grade overload/operator legality building block. It classifies exact and preference-based selections, expected-type and universal numeric preferences, primitive operator preference, implicit/class-wide/access conversion evidence, named/defaulted profile evidence, visibility failures, view barriers, cross-unit unresolved states, linked semantic errors, ambiguity, unknown, and indeterminate states. The layer is snapshot-owned and deterministic, with AUnit coverage in Test_Ada_Overload_Resolution_Legality_Pass1109.

Pass1110: added Editor.Ada_Staticness_Range_Predicate_Legality, a snapshot-owned semantic legality layer for Ada staticness requirements, range/choice legality, predicate metadata, linked assignment/return/conversion/access/aggregate/overload legality, deterministic lookup helpers, counters, and fingerprints. No diagnostic UI projection chain, rendering-side parser, file save/reload, dirty-state mutation, command/keybinding/workspace mutation, render mutation, compiler invocation, LSP bridge, external parser generator, Python integration, or shell-script integration is introduced.

Pass1111 update: added `Editor.Ada_Accessibility_Lifetime_Legality`, a widened snapshot-owned Ada accessibility/lifetime/aliasing legality layer covering accessibility levels, dynamic checks, null exclusion, access kind mismatches, aliased-object requirements, allocator/access-conversion/return-accessibility checks, anonymous access parameter escapes, access discriminant lifetime checks, dangling renaming risk metadata, and linked assignment/return/conversion/staticness failures. Added and registered `Test_Ada_Accessibility_Lifetime_Legality_Pass1111`.


Pass1112 note: semantic colouring may now consume contract/aspect legality diagnostics derived from pre/postconditions, invariants, predicates, assertions, contract cases, and flow aspects without render-side parsing.


## Pass1113

Elaboration/dependence legality is now represented as semantic metadata that downstream colouring/diagnostic consumers can use without render-side parsing or mutation.


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

Pass1123 update: added Global/Depends dataflow legality integration. Dataflow blockers are semantic-closure inputs and can appear in unified diagnostics through the existing feed/index/provenance path without rendering-side parsing.

Pass1131 update: representation/freezing precision now connects explicit representation items, implicit semantic-use freezing, private/full-view timing, generic-instance freezing effects, representation/layout/stream integration, elaboration precision, and tasking/protected precision through `Editor.Ada_Representation_Freezing_Precision_Legality` with AUnit coverage.

Pass1141: Added RM-grade overload edge legality for universal numeric/fixed/root preference, inherited primitive hiding, dispatching/nondispatching ambiguity, access-to-subprogram profiles, generic formal subprograms, nested generic overload ambiguity, and preservation of generic replay / coverage-gate blockers.

## Pass1147 coverage repair note

Syntax and semantic colouring consumers must not rely on token-only Ada syntax
coverage when the repair model still reports parser/AST/metadata gaps.  Once a
repair row proves structural coverage and consumer integration, downstream
semantic classifications may use the repaired construct facts confidently.

Pass1152: repaired coverage semantic feedback is analysis-side only. Repaired parser/AST, metadata, and consumer-integration facts can now make specific Ada constructs eligible for specific legality engines before diagnostics or semantic-colouring overlays consume results. Stale, partial, mismatched, cross-unit-required, and original-error rows remain blocked from render-time assumptions.

Pass1153 update: Refined_Global / Refined_Depends conformance now consumes flow-effect graph rows and repaired coverage feedback before accepting body/spec flow-contract conclusions. Body reads/writes, refined Global coverage, refined Depends edges, call propagation, linked flow errors, and repaired coverage blockers are represented as deterministic semantic legality rows.

Pass1154 update: Refined_Global / Refined_Depends body-spec conformance now feeds integrated semantic closure as a first-class blocker family. Legal refined conformance remains confident local closure; missing Global coverage, invalid Refined_Depends edges, unpropagated call effects, linked flow-effect errors, and repaired coverage blockers are exposed through integrated closure.


Pass1191: representation/freezing final hard-case status is available only as semantic-model evidence; colouring must not parse representation constructs during rendering.

Pass1193 update:
- Added final deep tasking/protected edge legality for protected reentrancy, entry-family queue semantics, terminate graphs, and abort/deferred-finalization ordering.

Pass1201: Final remediation gate results are now represented as semantic closure rows. Unresolved prerequisite gates become first-class closure blockers while legal, preserved-error, and indeterminate rows retain their semantic identity.

Pass1203 adds final semantic remediation diagnostic provenance/search, preserving prerequisite blocker-family identity from remediation diagnostics through closure/gate/trace/feed/index/base-provenance links.

Pass1209 note: final semantic stabilization now feeds a stabilized closure model,
so stable accepted rows and stable withheld prerequisite blockers are represented
before diagnostic/feed exposure.

Pass1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Pass1218: Shared-state remediation worklist legality now orders prerequisite semantic re-analysis for stabilized shared-state blockers without flattening blocker-family identity.

Pass1219 update: shared-state remediation worklist rows now feed bounded recheck eligibility while preserving prerequisite blocker-family identity for abstract/refined-state, volatile/atomic, overload/type, representation/freezing, tasking/protected, cross-unit, view, generic, state-visibility, fingerprint, multiple, and indeterminate blockers.

Pass1220 note: shared-state recheck application now gates current shared-state conclusions on eligible prerequisite evidence or explicitly current non-diagnostic stabilized evidence.  Dependency, view, generic, state-visibility, abstract/refined-state, volatile/atomic, overload/type, representation/freezing, tasking/protected, fingerprint, multiple, and indeterminate blockers stay withheld with blocker-family identity preserved.

Pass1221 note: shared-state recheck convergence now records stable current, stable withheld, changed, and indeterminate shared-state evidence without introducing rendering-side parsing or UI projection semantics.

Pass1222 update: added shared-state stabilization gating for Pass1221 convergence rows, preserving prerequisite blocker families while promoting only stable current shared-state evidence.

Pass1223 update: shared-state stabilization-gate rows now feed Editor.Ada_Shared_State_Stabilized_Closure_Legality. Stable accepted shared-state rows become first-class closure evidence; stable blockers remain explicit closure blockers with blocker-family identity preserved.
### Pass1225 - Volatile/atomic representation consumer legality

Pass1225 adds `Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality`. It connects volatile/atomic/shared-state legality to representation consumers for volatile full-access objects, atomic components, independent components, representation clauses, record layout, stream and operational attributes, protected/task shared-object representation, and shared-passive layout. It preserves blocker-family identity for volatile/atomic evidence, representation/freezing evidence, abstract-state consumers, stabilized closure, local volatile/atomic representation errors, fingerprint mismatches, multiple blockers, and indeterminate states. Regression coverage is in `Test_Ada_Volatile_Atomic_Representation_Consumer_Legality_Pass1225`.


### Pass1226 - Dispatching Global/Depends refinement legality

Pass1226 adds `Editor.Ada_Dispatching_Global_Refinement_Legality`. It connects dispatching-call Global/Depends proof to abstract/refined-state legality, abstract-state consumer integration, overload shared-state evidence, volatile/atomic representation consumer evidence, final flow/contract proof, and shared-state stabilized closure. It preserves blocker-family identity for flow/contract proof, abstract state, abstract-state consumers, overload shared-state evidence, volatile/atomic representation evidence, stabilized shared-state closure, Global/Depends mismatches, dynamic effect joins, inherited/renamed/generic dispatching effects, fingerprint mismatches, multiple blockers, and indeterminate states. Regression coverage is in `Test_Ada_Dispatching_Global_Refinement_Legality_Pass1226`.

Pass1227: Added generic abstract/refined-state replay legality for generic bodies and nested instantiations, preserving source/instance backmapping, formal/actual substitution, shared-state closure, and blocker-family identity.

Pass1231: Syntax colouring remains a consumer of stabilized cross-unit generic/shared-state semantic evidence and must not perform rendering-side dependency or generic legality checks.


Pass1237 adds Editor.Ada_Predicate_Generic_Shared_State_Final_Legality. It connects predicate/invariant use-site and propagation evidence to the generic/shared-state final semantic chain, preserving blocker-family identity across generic replay, representation/freezing, tasking/protected, accessibility, discriminant/variant, exception/finalization, renaming/alias, dispatching Global/Depends, cross-unit closure, stabilized shared-state closure, source-fingerprint, substitution-fingerprint, multiple-blocker, and indeterminate states.


Pass1238 adds Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality. It integrates definite-initialization/dataflow legality with the generic/shared-state final chain, preserving blocker families for initialization, dataflow, predicates, generic replay, shared-state closure, representation/freezing, tasking/protected, accessibility, discriminants, exception/finalization, renaming, volatile/atomic representation, access escape, variant components, finalization, and fingerprint mismatches.

Pass1239: Added generic/shared-state final diagnostic integration and feed support. The integration exposes only blocking rows while preserving original semantic blocker-family identity and withholds accepted rows as current semantic evidence.
Pass1240: Added Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality. It consumes generic/shared-state final diagnostic rows and turns blocker-preserving evidence into a deterministic semantic remediation worklist. Accepted rows remain current semantic evidence; blockers become prerequisite work items ordered across stale/fingerprint evidence, definite initialization, dataflow, predicates, generic replay, stabilized shared-state closure, volatile/atomic representation, representation/freezing, tasking/protected, accessibility, discriminants/variants, exception/finalization, renaming/aliasing, multiple blockers, and indeterminate state before downstream re-analysis may trust generic/shared-state conclusions.


### Pass1241 semantic-colouring note

Generic/shared-state final recheck eligibility remains a semantic model layer; colouring consumers must use stabilized diagnostic evidence only.

Pass1245: Generic/shared-state final stabilized closure now promotes only stable accepted generic/shared-state final conclusions into first-class semantic closure evidence. Stable blockers remain explicit closure blockers with blocker-family identity preserved, and recheck-required rows remain non-confident.

Pass1246: overload/generic/shared-state RM edge completion adds semantic coverage for renamed primitive visibility, inherited/private-extension primitive hiding, dispatching abstract-state effects, prefixed-call side-effect contracts, access-to-subprogram effect profiles, generic formal subprogram effects, universal numeric expected-context state ambiguity, and class-wide controlling-result state joins. The pass consumes stabilized generic/shared-state final closure and prior overload/generic shared-state evidence, and preserves blocker-family identity for unresolved prerequisites and fingerprints.


Pass1248 adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality, closing tasking/protected RM hard cases over the stabilized generic/shared-state semantic chain while preserving blocker-family identity for protected action reentrancy, callbacks, entry queues, requeue/select paths, abort/finalization, task termination, protected shared-state access, abstract-state-backed task effects, and generic task/protected bodies.


Pass1250 adds cross-unit generic/shared-state RM completion closure legality, consuming prior cross-unit closure plus completed overload, representation/freezing, tasking/protected, and coverage-proven AST repair evidence before accepting dependency-spanning generic/shared-state RM conclusions.


Pass1253: exception/finalization generic/shared-state RM completion legality consumes completed RM prerequisites and preserves blocker-family identity.

Pass1254: Predicate/invariant RM completion now consumes the completed generic/shared-state RM chain and keeps prerequisite blocker families distinct for downstream semantic closure.


Pass1256: RM-completed generic/shared-state diagnostic integration now exposes completed-chain blockers while withholding accepted rows as current semantic evidence.


Pass1258 — Coverage-proven RM-completion AST repair legality
Adds coverage-proven AST repair over the RM-completed generic/shared-state chain while preserving blocker-family identity.

Pass1259: RM-completion generic/shared-state recheck eligibility now preserves blocker-family identity through the bounded recheck boundary.

Pass1260: Added generic/shared-state RM-completion recheck application legality, preserving RM-completion blocker-family identity while applying eligibility back into the semantic closure/feed boundary.


Pass1262 adds Editor.Ada_Generic_Shared_State_RM_Completion_Stabilization_Gate_Legality. It consumes RM-completion recheck convergence rows and promotes only stable generic/shared-state RM-completion conclusions while preserving prerequisite blocker-family identity for withheld rows.
\nPass1265: Added representation RM-completion closure consumer legality. The pass consumes stabilized generic/shared-state RM-completion closure rows before representation/freezing RM hard-case conclusions may be trusted, while preserving blocker-family identity for closure, representation, cross-unit, overload/type, tasking, elaboration, accessibility, dataflow, and fingerprint blockers.

Pass1266: Tasking/protected RM-completion closure consumer legality now consumes stabilized RM-completion closure evidence and preserves tasking/protected blocker-family identity.

Live semantic diagnostic update: expected-type contexts now include syntax-owned declaration defaults, simple assignments, and ordinary return statements as production inputs, and return action nodes participate in expression typing. The live diagnostic pipeline therefore reports non-call assignment/return subtype mismatches through the existing wide semantic diagnostic feed without renderer parsing, file mutation, or dirty-state mutation.
# Historical Syntax Colouring Notes

This file is retained as historical pass evidence. Current testing workflow is
in `docs/testing.md`; current release workflow is in
`docs/release/RELEASE_CHECKLIST.md`.
