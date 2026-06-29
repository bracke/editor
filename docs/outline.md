Pass719: derived/tagged type extension parsing now retains abstract/tagged/limited modifiers, interface parent lists, private extensions, record extensions, null-record extensions, and bounded malformed-extension recovery for parser-owned Outline and semantic-colouring consumers.

Pass373: representation-clause static evaluation now treats Ada based literal exponents using the literal base, while decimal exponents remain decimal; unsupported expressions remain conservative.

# Outline workflow

`Editor.Outline` is the transient, command-routed outline model used by the editor feature panel. The current product feature is backed by the shared in-process Ada language model and declaration parser. It remains conservative and Ada-native, but Outline no longer owns the primary Ada declaration recognizer.

The feature supports selected-row navigation to declarations and uses stale snapshot guards/freshness checks so rows from an edited, closed, or different active buffer cannot be activated as if they were current.

The user-facing refresh path is owned by `Editor.Executor`:

```text
outline.refresh
  -> snapshot active in-memory buffer text
  -> Editor.Outline_Extractor.Extract
  -> Editor.Outline_Extractor.Apply_To_Outline
  -> Editor.Feature_Panel.Set_Rows_From_Outline
  -> show Feature Panel
  -> emit one command result message
```

Extraction is explicit. It does not run from rendering, command-palette projection, availability checks, keybinding display, input routing, workspace persistence, project lifecycle reset, buffer switch, or passive feature-panel projection.

## Implemented extraction

`Editor.Outline_Extractor` inspects only the immutable text snapshot supplied by `Editor.Executor`. It does not read files, save buffers, inspect project files, mutate editor state, clear dirty state, change carets/selections, or emit messages.

The extractor supports two deterministic input styles:

1. Explicit outline markers using `@outline ` lines.
2. Ada declaration analysis through `Editor.Ada_Declaration_Parser.Parse`, which produces `Editor.Ada_Language_Model.Analysis_Result` rows consumed by Outline.

The Ada subset recognizes declaration-leading forms such as:

```text
package specs and bodies
nested and private child packages
package renames and instantiations
procedure declarations, bodies, renames, null procedures, and generic instantiations
function declarations, bodies, renames, operator functions, abstract functions, and simple expression functions
abstract procedure declarations and overriding/not-overriding subprogram declarations
separate subprogram bodies
type, private type, record type, and subtype declarations
task and protected declarations, types, and bodies
task/protected entry declarations
enumeration type literals, including multi-line enumeration lists
package-level constants, objects/object renames, and exceptions
generic formal type/object/subprogram/package declarations
record discriminants and component fields inside recognized record types, including variant alternatives
character enumeration literals
generic marker applied to the next package/procedure/function declaration
common multi-line profiles where the declaration name is on the leading line
best-effort local line ranges for closed package/subprogram/task/protected/record constructs
```

Variant-record component lines such as `when Choice => Field : Type;` are sliced after the choice arrow before component extraction, so choices and the Ada keyword `when` are not emitted as record components.

The parser consumes the shared `Editor.Ada_Syntax_Core` lightweight Ada lexical sanitation pass directly so comments, string literals, and simple character literals do not accidentally become outline declarations. It stores source spelling and normalized Ada names in `Editor.Ada_Language_Model`, including symbol kind, source range, lexical scope depth, parent symbol, enclosing scope id, flags, same-line and multi-line enumeration literals parented to their defining type, targets for renames/instantiations where recognized, separate-body parent metadata for `separate (...)` units, private-section flags, and a deterministic fingerprint. The parser now stamps nested declarations onto their nearest parser-known parent scope so Outline and the project index can distinguish inner rows from outer rows without owning duplicate declaration parsing; qualified index lookup uses those parent chains rather than broad leaf-only matching. It is deliberately conservative: false negatives are acceptable; false positives should be minimized. Ada parser/sanitizer ownership is neutral: syntax colouring, semantic colouring, Outline, audits, and tests import `Editor.Ada_Syntax_Core` or the language model directly rather than routing through `Editor.Outline_Extractor`.

## Known extraction limits

The in-process Ada parser is not a full compiler frontend. It provides scope-aware declaration rows and parser-owned language-model data, but it still does not provide:

```text
compiler-accurate legality checking
complete GNAT-equivalent visibility and overload resolution
automatic whole-project background scans on every keystroke
compiler-derived cross-file semantic facts
full separate-subunit cross-file resolution when the parent source is unavailable
full operator-profile equivalence beyond retained overload sets
full generic formal semantics beyond recognized formal declarations
compiler-accurate representation-clause layout legality checking beyond bounded record component layout metadata
conditional/generated-source handling beyond retained awareness markers
language-server integration
```

Complex declarations may be omitted or approximated. The feature is now suitable for richer current-buffer and explicitly indexed-buffer navigation plus bounded semantic rename consumers. Broader compiler-grade refactoring and GNAT-equivalent semantic navigation remain outside the Outline extractor's scope.

## Item model and invariants

`Editor.Outline` owns transient outline item data: kind, label, detail, depth, target kind, line, column, and snapshot identity metadata. Extracted rows carry validated `Buffer_Position_Target` metadata with one-based line and column values. The detail field carries best-effort source range text such as `line 12 declaration` or `lines 3-19 body` where the lightweight extractor can infer a closed local construct. Synthetic fixture rows used by tests may carry `No_Target`.

Accessors are side-effect-free and treat invalid indexes as programmer errors guarded by preconditions/assertions rather than silently clamping.

`Invariant_Holds`, `Summary`, `Debug_Summary`, and `Fingerprint` are audit helpers. They do not normalize, repair, project, render, parse, inspect editor buffers, inspect project files, or emit messages. The fingerprint includes item count, item kind, label, detail, depth, target kind, line, and column while excluding render state, time, focus/hover/cursor blink state, Textrender atlas state, settings, keybindings, dirty state, and backend state.

Synthetic rows are test-fixture-only. Tests that need deterministic synthetic outline rows use `Editor.Outline.Fixtures.Populate_Synthetic_Outline`. Production source must not expose placeholder-specific outline sources, target kinds, or refresh helpers.

## Projection into Feature Panel

`Editor.Feature_Panel` is the generic display host for outline rows. It owns visibility, focus, rows, selection, and render snapshots. It does not own outline semantics and does not generate outline items.

`Set_Rows_From_Outline` replaces current feature-panel rows with outline-derived rows, maps `Outline_Header` and `Outline_Section` to `Feature_Row_Header`, maps other outline kinds to `Feature_Row_Item`, preserves labels/details, mirrors outline selection into the visible projection, and marks target rows as selectable/activatable. Projection mutates only feature-panel rows/selection. It does not parse source text, emit messages, save buffers, or change project/workspace state.

`Feature_Row_Maps_To_Item` guards stale selection. A selected feature-panel row maps to an outline item only when the row index is live in both states and the row kind, label, and detail match the current outline projection.

## Clear Outline versus Clear Feature Panel

`outline.clear` is semantic: it clears `Editor.Outline` and clears displayed outline rows from `Editor.Feature_Panel`. It preserves feature-panel visibility/focus according to the existing panel policy and emits `Outline cleared`.

`clear-feature-panel` is generic: it clears displayed feature-panel rows and selection only. It does not clear `Editor.Outline`. A later `outline.refresh` replaces both outline state and displayed rows with extracted rows from the current explicit active-buffer snapshot.

## Commands, availability, and messages

| Stable name | Behavior | Status/message |
| --- | --- | --- |
| `outline.refresh` | Requires an active buffer, snapshots current in-memory text, extracts outline rows, replaces outline items on success, projects rows into the feature panel, shows the panel, and does not focus it. | executed, `Outline refreshed` |
| `outline.clear` | Clears outline items and feature-panel rows without changing feature-panel visibility policy. | executed, `Outline cleared` |
| `outline.show` | Shows the feature panel without refreshing outline data. | executed, `Outline shown` |
| `outline.focus` | Requires the feature panel to be visible and not already focused; focuses the feature panel. | executed, `Outline focused` |
| `outline.open-selected` | Requires a visible feature panel and a selected row that maps to the current outline projection and active buffer. Moves the caret and viewport to the selected declaration after validation. | executed on success; otherwise no-op, `Outline item has no target` |
| `outline.select-next` / `outline.filter.next-match` | Moves Outline selection to the next visible selectable row and requests reveal in the feature panel. | executed on movement; otherwise no-op at boundaries or when no visible selectable row exists. |
| `outline.select-previous` / `outline.filter.previous-match` | Moves Outline selection to the previous visible selectable row and requests reveal in the feature panel. | executed on movement; otherwise no-op at boundaries or when no visible selectable row exists. |

Canonical disabled reasons include `No active buffer`, `No outline items`, `No outline item selected`, `Feature panel hidden`, `Feature panel already shown`, and `Feature panel already focused`.

Availability checks are side-effect-free. They do not refresh outline state, project rows, show/focus panels, mutate selection, emit messages, inspect active buffer text, parse files, or repair stale rows.

## Refresh behavior and failure safety

A successful zero-item extraction is still a successful refresh. It clears previous outline items, clears displayed outline rows, clears stale feature-panel selection, shows the feature panel, and emits the canonical outline refreshed message. After a zero-item refresh, `outline.clear` and `outline.open-selected` are unavailable until new items and a live selection exist.

Failed or unavailable extraction is applied as an explicit unavailable/failure Outline state and does not project partial results. Late extraction results are rejected by snapshot identity, preserving accepted rows when appropriate and recording a stale-result diagnostic.

Refresh reads current in-memory buffer text only. It does not save files, reload files, clear file dirty state, alter dirty-line markers, or create/resolve pending lifecycle transitions. Successful reload/revert operations and buffer-close lifecycle cleanup invalidate the accepted Outline snapshot: rows are cleared or made unavailable, selected-row activation is blocked, and the user must run `outline.refresh` again before navigation can resume.

## Open Selected behavior

`outline.open-selected` navigates only after the selected feature-panel row maps back to a live Outline item, the Outline still belongs to the active buffer, and the one-based target line/column is valid. On success, the editor focus returns to the text surface, the caret moves to the declaration target, and the viewport is handed off to reveal that caret. On failure, state is preserved and one unavailable/no-target message is emitted.

Feature-panel Enter routes to `outline.open-selected` only when the selected row maps to the current outline projection; otherwise it uses the generic feature-panel open-selected command. The command is selected-row driven; users do not pass buffer ids, file paths, or raw line numbers.

## Persistence exclusion

Outline runtime items are not workspace/session state, global settings, keybinding configuration, or recent-project data. Persistence files must not serialize `Outline_State`, extraction results, snapshot identities, outline labels/details, line/column metadata, or synthetic fixture rows.

Keybinding files may contain outline command stable names when defaults are exported or when the user explicitly configures chords. Focused outline defaults include `outline.refresh` on `Ctrl+F12`, `outline.open-selected` on `Alt+Enter`, `outline.select-next` / `outline.select-previous` on `Alt+F3` / `Alt+Shift+F3`, and `outline.select-current-symbol` / `outline.reveal-current-symbol` on `Alt+F12` / `Alt+Shift+F12`. `outline.show`, `outline.clear`, and `outline.focus` stay palette/user-configured unless explicitly bound.

## Input and rendering

Command-like outline actions route through `Command_Id` and `Editor.Executor`. Feature-panel Up/Down selection movement remains local panel mechanics and mutates only feature-panel selection. Ordinary text input remains governed by the existing overlay/input-field priority model.

Rendering remains Feature_Panel-driven. `Editor.Outline` does not render directly. Render snapshot construction is side-effect-free and requires no C/Vulkan backend changes or new renderer primitives.

## Future work

The current outline feature is a parser-backed active-buffer outline using the shared Ada language model. Future work should be added deliberately and tested independently:

```text
filesystem-watcher-driven background outline/indexing beyond current lifecycle-owned bounded refresh paths
separate subunit and cross-file symbol support
more complete Ada grammar support
LSP-backed outline provider
richer automatic refresh policy beyond current stale snapshot guards, if explicitly designed
```

Any future provider must preserve the current ownership boundaries: explicit Executor-owned snapshots, no automatic extraction from render/availability/palette/input paths, all-or-nothing application before projection, no persistence leakage, selected-row-driven navigation, and narrow extractor dependencies that avoid editor state mutation.


Pass 3 hardening: the Ada declaration parser now distinguishes real scope-closing `end` statements from non-declaration constructs such as `end if`, `end loop`, `end case`, and `end select`; this prevents control-flow syntax inside bodies from invalidating lexical parent stamps used by Outline and semantic colouring. Same-line record discriminants are parented to the record type symbol, matching multi-line discriminants and components. `Editor.Ada_Symbol_Resolver.Resolve_In_Scope` resolves from an actual parent-symbol chain and returns the nearest lexical overload set before falling back to enclosing scopes.

## Phase 579 language-model pass 6 hardening

The Ada declaration parser now models generic formal object declarations directly and stores bounded profile summaries for subprogram declarations, generic formal subprograms, and operator functions. These summaries are metadata for Outline rows and future navigation/disambiguation; they are not a claim of compiler-equivalent overload legality checking.

Project-index lookup now returns bounded cross-file symbol matches with source path and ownership stamps, giving Outline/navigation code a concrete validation object instead of only aggregate index counts. Generic formal package declarations retain their `is new ...` target metadata for display and future navigation, while legality checking remains outside this phase.

Representation-clause hardening: `for T use record ... end record;` is skipped as metadata and its terminator does not close the current package or subprogram parser scope. Private child packages are normalized by stripping only the leading `private` marker, so displayed and indexed package names remain canonical while retaining `Is_Private`.

Pass 10 hardening: multi-line enumeration declarations keep their pending enum owner until the closing parenthesis, so literals split across lines remain children of the defining type and the closing line does not disturb the enclosing package scope.

Pass 11 hardening: same-line record discriminant extraction now uses a discriminant-specific slice of the parenthesized type header. This prevents the parser from learning the `type` keyword or the record type name itself as `Symbol_Discriminant` when parsing declarations such as `type Rec (Id : Natural) is record`; only the actual discriminant identifiers are added under the record type.


- Same-line record discriminant ranges preserve original source columns for outline navigation and semantic diagnostics.

Pass 13 hardening: the shared language model now exposes value-like Ada declarations to semantic colouring as first-class parser-owned symbols, including objects, constants, exceptions, record components, discriminants, and enumeration literals. Outline remains backed by the same symbols and does not reimplement a separate recognizer for these cases.

### Subprogram profile parameters

Same-line procedure, function, operator-function, generic-formal-subprogram, and entry profiles are now scanned for parameter names. The parser stores those names as object-like child symbols under the owning callable so resolver and semantic colouring can bind them by lexical scope. Outline still presents the callable profile summary as the primary navigation row; parameter symbols are parser metadata for local semantic binding, not compiler-grade type checking.

### Multi-line callable profile parameters

Callable profiles that continue across lines are now tracked with parser-owned pending-profile state. Parameter names discovered on continuation lines are stored as child symbols of the owning procedure/function/operator/entry declaration, with source ranges preserved for later navigation metadata. This remains bounded and conservative: malformed or unfinished profiles do not create compiler-grade legality claims.
- Split Ada type headers are retained by the parser: a `type Rec` line followed by discriminants and `is record` is represented as one record-type outline symbol, not as a flat ordinary type plus orphan fields.

Pass 17 hardening: semantic colouring now has a resolver-backed scoped classification API that can consume the same parent-symbol chains produced for Outline rows. This keeps Outline and semantic classification aligned: when a row or token has a validated lexical owner symbol, callers can resolve names from that owner rather than relying only on a flat name map.

### Multi-name generic formal objects

Generic formal object declarations with more than one identifier are now parsed through the shared Ada language model. Both ordinary generic formal object lines and `with`-prefixed formal object lines retain every declared identifier as `Symbol_Generic_Formal_Object` with generic metadata, instead of exposing only the first name to Outline-derived metadata.

### Split-profile body scopes

Callable profiles may be split so that the profile closes before a later `is` line opens the body. The shared Ada declaration parser now opens the callable scope from that pending-profile `is` continuation, so Outline and navigation metadata keep local body declarations under the owning callable instead of the enclosing package. This remains a bounded parser heuristic, not full Ada legality checking.

## Separate body rows

Separate subunit bodies parsed from `separate (...)` clauses are represented in
the shared Ada language model with `Symbol_Separate_Body`, not only as ordinary
procedure/package/task/protected declarations with a flag attached.  Outline rows
can therefore render them as separate-body navigation targets while retaining the
parent unit name in `Target_Name` for validated index linking.

Pass 21 hardening: `Editor.Ada_Project_Index` now exposes current-stamped symbol resolution (`Resolve_Current`, `First_Current_Match`, and `Has_Current_Match`) in addition to broad project lookup. Callers that already validated a buffer path/token/revision/lifecycle/fingerprint can ask the index to return only symbols from that exact current analysis, so navigation and semantic consumers do not need to broad-resolve first and filter stale targets afterwards.

Private type metadata hardening: `type T is private;`, `type T is limited private;`, and generic formal private type declarations remain type/formal-type symbols while carrying `Is_Private`, so Outline can distinguish private type declarations without re-parsing labels.

Derived type metadata hardening: derived ordinary types and record extensions that contain the Ada keyword `new` are still represented as type or record-type symbols, not generic instantiations. Outline can therefore display and navigate derived types without confusing them with package/subprogram instantiation rows.
- Split callable bodies keep parser-owned scope across profile, return-subtype/aspect continuation, and body-opening `is` lines, improving Outline parentage for locals in multi-line procedures/functions.

### Entry-family profile parameters

Entry-family declarations can contain an index/group before the ordinary parameter profile. The shared Ada declaration parser now scans multiple same-line callable profile groups, ignores unnamed family-index groups, and records named parameters from the later entry profile as child symbols of the entry declaration. Outline still exposes the entry as the navigation row; these child symbols improve scope-aware semantic binding without claiming full Ada legality checking.

- Generic formal type discriminants, including split formal type headers, are emitted as child symbols beneath the formal type.

### Entry body barriers

Entry bodies with barriers, such as `entry Serve (Item : T) when Ready is`, are now parsed so the `when` barrier remains body metadata instead of polluting the Outline profile summary. The entry still opens a callable body scope, so local declarations inside the entry body are associated with the entry symbol for navigation and semantic lookup.
- Task and protected type discriminants are retained as child symbols of the concurrent type, giving Outline the same parent/range metadata used for record/type discriminants.
  Multi-name discriminant groups are split before model insertion, so every discriminant in a same-line task/protected/type header can appear as a child navigation symbol.

Access-to-subprogram type declarations are retained as type symbols.  Their nested callable profile syntax is treated as metadata for the type declaration and does not emit outline child rows for profile names.

### Split concurrent type headers

Task and protected type headers may now be split across the type name, discriminant part, and later `is` line. The Ada declaration parser keeps a pending concurrent-type owner so discriminants, entries, and protected operations remain parented to the task/protected symbol for Outline navigation.

- Derived type and record-extension rows retain their parent type target name as conservative metadata, while staying ordinary type/record-type declarations rather than instantiations.

Subtype metadata hardening: subtype declarations retain their subtype mark as parser-owned target metadata, so Outline/index consumers can display or navigate the underlying type without re-parsing the subtype label. `not null` access subtypes skip the null-exclusion keywords when recording the target.

- Split record openers written as `type T is` followed by `record` are treated as one record declaration; components remain children of the record symbol.

Object, constant, and exception renaming declarations are retained as value-like symbols with rename flags and target metadata, so Outline/index consumers can show the declared alias without losing its value-like category.

### Generic formal derived type targets

Generic formal derived type declarations now retain the ancestor subtype mark in `Target_Name`. For example, `type Child is new Root with private;` remains a generic formal type symbol with generic/private flags and records `Root` as its target metadata. Outline consumers can display or navigate that relationship without treating the formal type as a generic instantiation.

### Composite type target metadata

Array type declarations now retain their component subtype mark as parser-owned target metadata. Access-to-object declarations likewise retain the designated subtype mark after access qualifiers such as `all` or `constant`. Access-to-subprogram types retain bounded callable profile summaries while names inside `access procedure` or `access function` profiles are not emitted as outline child symbols.

Class-wide subtype metadata is retained for subtype marks, array component subtype marks, and access-object designated subtype marks.  Targets such as `Root'Class` remain intact instead of being truncated to `Root`, so Outline and project-index navigation can present class-wide relationships without re-parsing declaration labels.

- Pass 39: Ada body stubs (`procedure P is separate;`, `package body P is separate;`) retain `Is_Separate` metadata without opening parser scopes that capture following declarations.


Phase 579 language-model pass 40 note: package/subprogram renames keep their package/callable semantic kinds while carrying `Is_Rename` and `Target_Name`; they no longer collapse to a generic rename-only bucket.

Phase 579 language-model pass 41 note: Outline profile/detail text strips subprogram aspect clauses from the parser-owned profile summary so overload labels show signatures rather than declaration aspects.

### Object and component target metadata

Object-like declarations now retain subtype target metadata in the shared Ada language model. This includes ordinary objects, constants, record components, discriminants, generic formal objects, and callable parameters parsed from profiles. The parser strips declaration-mode and access/null qualifiers before storing the subtype mark, and exception declarations intentionally keep an empty target because `exception` is a declaration category rather than a subtype mark.

### Interface type target metadata

The Ada declaration parser retains bounded parent-interface target metadata for interface type declarations that name a parent after `and`, such as `type Child is interface and Root;`. Root interface declarations remain ordinary type rows with no synthetic target. This metadata is available to Outline/index consumers without treating interfaces as generic instantiations or opening declaration scopes.

- Access-to-subprogram object declarations remain value declarations; their anonymous callable profile names are not emitted as outline children.
- Anonymous array object declarations retain their element subtype mark as target metadata for Outline detail/navigation consumers.

- Function declarations and generic formal functions retain result subtype marks in the shared language model as target metadata, while renames and separate bodies retain their navigation targets.

### Generic formal composite type targets

Pass 47 hardening: generic formal array, access-to-object, and interface-extension type declarations now retain bounded target metadata through the shared Ada language model. Formal access-to-subprogram types retain bounded callable profile summaries while anonymous profile parameters are not learned as child symbols or semantic identifiers.

Pass 48 hardening: function result metadata now distinguishes anonymous access-to-object results from anonymous access-to-subprogram results. Access-to-object results retain the designated subtype target, while `return access procedure (...)` and `return access function (...)` keep empty target metadata, retain bounded callable result-profile summaries, and do not expose result-profile names as outline children.


Phase 579 language-analysis pass 50 note: task/protected type headers such as `task type Worker (Id : Positive)` followed by a later `is` now keep their pending concurrent-type owner. Outline rows for later entries/protected operations remain under the task/protected symbol rather than falling back to the enclosing package.

Phase 579 language-analysis pass 49 note: the Ada declaration parser now retains designated subtype target metadata for split access-to-object type declarations, including generic formal access types such as `type Ref is access` followed by `all Element;`, by using parser-owned pending target state rather than opening a false type scope.
Phase 579 language-analysis pass 51 note: the Ada declaration parser now retains element subtype target metadata for split array type declarations, including generic formal arrays such as `type Element_Array is array` followed by `(Positive range <>) of Element;`, by using parser-owned pending array target state rather than opening a false type scope.

Implementation note: split function declarations whose result subtype appears on a following `return` line are retained in the shared language model as function target metadata. This includes split profile/function bodies where the return subtype appears before the later body-opening `is`, so Outline detail and navigation metadata do not lose the result subtype or capture subsequent local declarations under the wrong parent.

Phase 579 language-analysis pass 53 note: the Ada declaration parser now retains element subtype target metadata for split anonymous-array object and constant declarations such as `Values : array` followed by `(Positive range <>) of Element;`. Parser-owned pending object-array target state stamps the already-emitted object/constant symbols when the continuation supplies the `of <subtype>` clause, without opening a false scope. This pass also removed an accidental duplicate nested `Skip_Blanks` declaration in `Skip_Component_Qualifiers`.

Phase 579 language-analysis pass 54 note: the Ada declaration parser now also retains designated subtype target metadata for split anonymous access-to-object declarations, including constant access objects, such as `View : access` followed by `all Root'Class;`. Parser-owned pending object-access target state stamps the already-emitted object/constant symbols from the continuation line and consumes that continuation as declaration metadata so it cannot open a false scope or create bogus symbols.
Phase 579 language-analysis pass 55 note: the Ada declaration parser now also learns ordinary split object, constant, and record-component declarations from their subtype header line, even when initialization or aspect metadata is on later lines. This preserves subtype target metadata such as `Name : String` followed by `:= ...;` and `Child : Root'Class` followed by a default expression, while treating the continuation as metadata-only so it cannot create false symbols.
Phase 579 language-analysis pass 56 note: the Ada declaration parser now retains target metadata for split subtype declarations, including class-wide and range-constrained forms such as `subtype Root_View is` followed by `Root'Class;` and `subtype Index is` followed by `Positive range 1 .. 10;`. Parser-owned pending subtype target state updates the emitted subtype symbol from the continuation line and treats that continuation as metadata-only, avoiding false declarations or false scopes.
Phase 579 language-analysis pass 57 note: the Ada declaration parser now retains target metadata for split package instantiations and package/subprogram renames, such as `package Integer_IO is new` followed by `Ada.Text_IO.Integer_IO;` and `procedure Old_Put renames` followed by `Integer_IO.Put;`. Parser-owned pending declaration-target state updates the already-emitted rename/instantiation symbol from the continuation line and consumes that continuation as metadata-only, avoiding false declarations or false scopes.
- Split derived type declarations, including generic formal derived types and derived record extensions, retain parent subtype target metadata and only open a record scope when the continuation line really introduces `record`.

Phase 579 language-analysis pass 59 note: the Ada declaration parser now retains `Symbol_Generic_Formal_Object` kind, generic flags, and subtype target metadata for split generic formal object declarations such as `with Default : in` followed by `Root'Class;`. Continuation lines are consumed as formal-declaration metadata, so they cannot be learned as ordinary package-level objects.

Phase 579 language-analysis pass 60 note: split interface type declarations now retain the parent interface target when the declaration line ends after `and` and the parent interface appears on the following line. This applies to ordinary and generic formal interface declarations; Outline consumers receive bounded target metadata without treating the continuation as a separate declaration.

Phase 579 language-analysis pass 61 note: the Ada declaration parser now retains target metadata for split generic formal package declarations where either `is` or `new` is placed on a continuation line, such as `with package Maps is` followed by `new Ada.Containers.Ordered_Maps (<>);`. The continuation is consumed as generic-formal metadata, preserving `Symbol_Generic_Formal_Package`, generic flags, instantiation flags, and target name without creating false package symbols.


Phase 579 language-analysis pass 62 note: the Ada declaration parser now retains designated subtype target metadata for split anonymous access-to-object function results, such as `function Ref return access` followed by `all Root'Class;`. Parser-owned pending return-access target state stamps the already-emitted callable symbol from the continuation line and consumes those lines as result metadata so they cannot create bogus declarations or lose following symbols.

Phase 579 language-analysis pass 63 note: split access-to-subprogram type declarations now keep their callable profile summary on the owning type/formal-type symbol. Outline can display `access procedure` / `access function` signatures without treating anonymous profile parameters as navigable declarations.
Phase 579 language-analysis pass 64 note: Outline now receives callable profile metadata for anonymous access-to-subprogram object and constant declarations, including split `access` header/profile continuations, without treating anonymous profile parameters as child declarations.

Phase 579 language-analysis pass 65 note: split object and exception renamings now use the same parser-owned continuation target path as split package/subprogram renames while retaining their value-like symbol categories. This prevents Outline and the project index from showing an alias as an ordinary split object with only a subtype target.

Phase 579 language-analysis pass 66 note: Outline now receives callable profile metadata for functions returning anonymous access-to-subprogram values, including split result-profile continuations. These result-profile parameters remain metadata-only and are not exposed as navigable declarations.


The Ada language model also retains generic formal subprogram default-callable metadata for supported `with procedure ... is Default_Name`, `is <>`, and `is null` declarations, including split default continuations, without treating the formal as a body scope.
Phase 579 language-analysis pass 69 note: Outline receives protected access-to-subprogram profile metadata such as `access protected procedure (...)` on the owning type/object symbol, while anonymous protected-profile parameters remain non-navigable metadata.

Phase 579 language-analysis pass 70 note: Outline receives protected callable profile metadata for functions returning anonymous access-to-subprogram values. The parser suppresses bogus `protected` target names and keeps result-profile parameters non-navigable metadata.

Pass 71 further hardens generic formal object outline metadata: anonymous access-to-subprogram formal objects keep their formal-object kind and generic flag while storing the callable profile summary on the symbol. Split continuation profile lines are consumed as formal metadata and do not become outline rows.

Pass 72 hardening: Outline now receives callable profile metadata for parameters declared as anonymous access-to-subprogram values, including protected callback parameters. The owning parameter remains the navigable row; names inside the anonymous callback profile remain non-navigable metadata.

Pass 73 hardening: Outline now receives designated subtype target metadata for callable parameters declared as split anonymous access-to-object values, such as `Ref : access` followed by `all Root'Class);`. The parameter remains parented to the callable symbol, and the access continuation is consumed as parameter metadata rather than becoming a package-level declaration.

Phase 579 language-analysis pass 74 note: record component extraction now splits semicolon-separated component groups on the same physical source line. Components such as `A : Natural; B, C : Boolean;` all become record-component symbols with preserved source columns and subtype target metadata. Variant choices before `=>` remain metadata-only, so `when Small => Count : Natural; Ready : Boolean;` learns `Count` and `Ready` without inventing `when` or `Small` outline symbols.

Phase 579 language-analysis pass 75 note: ordinary object, constant, exception, and generic formal object extraction now splits semicolon-separated declaration groups on the same physical source line. Outline receives parser-owned rows for `A : Natural; B, C : constant Boolean := True;`, `E1 : exception; E2 : exception;`, and generic formals such as `X : in Natural; Y, Z : in Boolean;` without dropping declarations after the first semicolon.

Phase 579 language-analysis pass 76 note: same-line object, constant, and exception renaming declaration groups are now split by the Ada declaration parser. Outline receives each alias from declarations such as `Alias_A : Integer renames Source_A; Alias_B : constant Integer renames Source_B;` with value-like kind, `Is_Rename`, source columns, and per-segment renamed-target metadata preserved.

Phase 579 language-analysis pass 77 note: same-line subtype declaration groups are now split by the Ada declaration parser. Outline receives each subtype from declarations such as `subtype Count is Natural; subtype Index is Positive range 1 .. 10;` with subtype kind, source columns, subtype-target metadata, and private-section metadata preserved.

Phase 579 language-analysis pass 78 note: the Ada declaration parser now splits same-line type declaration groups, such as `type Color is (Red, Green); type Mode is ('A', Named);`. Each type keeps its own language-model symbol, derived/array/access target metadata, and enumeration literal children, so Outline rows no longer lose later type declarations on compact source lines.

Phase 579 language-analysis pass 79 note: the Ada declaration parser now retains parser-owned callable declarations from same-line callable groups. Procedure/function specs, operator functions, callable renames, callable instantiations, and generic formal subprogram declarations after an earlier top-level same-line semicolon are emitted as distinct language-model symbols, while semicolons inside parameter profiles remain profile metadata.

Phase 579 language-analysis pass 80 note: the Ada declaration parser now splits same-line concurrent declaration groups. Compact task, task type, protected object, protected type, and entry declarations after an earlier top-level semicolon are emitted as distinct language-model symbols; discriminants and entry profile parameters remain owned by the corresponding concurrent/entry symbol.

Phase 579 language-analysis pass 81 note: package declaration extraction now splits semicolon-separated package declaration groups on the same physical source line. Package renames, package instantiations, package bodies, private package declarations, and generic formal package declarations after an earlier semicolon are emitted as parser-owned language-model symbols with preserved source spelling, kind, flags, and target metadata instead of being hidden by the first package declaration on the line.

Phase 579 language-analysis pass 82 note: compact generic unit markers are now consumed by the Ada declaration parser when the `generic` marker and the following package/procedure/function declaration appear on the same physical line. The parser blanks the consumed prefix before reparsing the tail, so Outline receives `Symbol_Generic_Package` or `Symbol_Generic_Subprogram` rows with generic flags and preserved source columns instead of dropping the unit behind the standalone marker.

Phase 579 language-analysis pass 83 note: same-line generic formal type groups now remain parser-owned generic formal declarations. Compact formal blocks such as `type Element is private; type Index is range <>; type Ref is access Element;` retain `Symbol_Generic_Formal_Type`, generic/private flags, and target metadata instead of being downgraded to ordinary type rows before Outline conversion.

Phase 579 language-analysis pass 84 note: compact separate body markers are now consumed when the `separate (Parent)` marker and the following procedure/function body declaration appear on the same physical line. The parser blanks the consumed marker prefix before reparsing the tail, so Outline receives the real body symbol with `Is_Separate`, preserved declaration columns, and the separate parent target instead of dropping the body behind the marker.

Phase 579 language-analysis pass 85 note: compact one-line generic declarations now split the text after `generic;` into top-level declaration segments before parsing. This lets Outline retain same-line generic formal type/subprogram declarations and the following generic package/subprogram unit from forms such as `generic; type Element is private; with procedure Visit (...); package G is ...`, while preserving absolute source columns and generic flags.

Phase 579 language-analysis pass 86 note: compact private-section markers are now consumed when `private;` and the first private declaration appear on the same physical source line. The parser marks the current scope private, blanks the consumed marker prefix, and reparses the tail so Outline receives private object/type rows with preserved absolute source columns instead of dropping the declaration behind the marker.

Phase 579 language-analysis pass 87 note: compact one-line package and body scopes now parse declaration tails after the scope-opening `is` with the emitted scope symbol as parent. Forms such as `package P is A : Integer; B : Boolean; end P;` retain the package row and parser-owned child declaration rows with absolute source columns and subtype target metadata instead of treating the tail as package metadata.

Phase 579 language-analysis pass 88 note: compact one-line record type declarations now expose parser-owned component rows. Declarations after the same-line `record` opener, including later semicolon-separated groups and variant components after `=>`, are parented to the record type while the compact `end record` tail remains metadata-only.

Phase 579 language-analysis pass 89 note: compact one-line package private tails now split the scope tail after `is` into top-level declaration segments. Forms such as `package P is A : Integer; private; B : Boolean; end P;` keep `A` public while marking `B` and later declarations private, all parented to the package with absolute source columns preserved.

Phase 579 language-analysis pass 90 note: compact one-line package scopes now keep nested compact record declarations intact while splitting the package tail. Forms such as `package P is type R is record A : Integer; B : Boolean; end record; X : Integer; end P;` parent `A` and `B` to `R`, then resume package-scope parsing for `X` after `end record`.

Phase 579 language-analysis pass 91 note: compact one-line package scope parsing now keeps nested compact package declarations intact while splitting the enclosing package tail. Forms such as `package Outer is package Inner is A : Integer; B : Boolean; end Inner; X : Integer; end Outer;` parent `A` and `B` to `Inner`, then resume outer-package parsing for `X` after the nested package end.

Phase 579 language-analysis pass 92 note: compact one-line package scope parsing now keeps nested compact protected/task declarations intact while splitting the enclosing package tail. Forms such as `package P is protected Lock is procedure Enter; entry Leave; end Lock; X : Integer; end P;` parent protected operations and entries to `Lock`, then resume package-scope parsing for `X` after the concurrent scope end.

Phase 579 language-analysis pass 93 note: record component splitting now respects parenthesized metadata. Components such as `Callback : access procedure (A : Integer; B : Integer); Next : Integer;` keep the profile semicolon inside the callback component and only split at the top-level component separator, preventing callback-profile parameters from becoming bogus record components.

Phase 579 language-analysis pass 94 note: object and generic-formal object declaration splitting now respects parenthesized metadata. Declarations such as `Callback : access procedure (A : Integer; B : Integer); Next : Integer;` keep the profile semicolon inside the callback object and only split at the top-level declaration separator, preventing profile parameters from appearing as bogus Outline rows.

Phase 579 language-analysis pass 95 note: grouped generic-formal object declaration parsing now performs top-level semicolon splitting inside `Add_Object_Declaration_Groups` itself. Compact formals such as `Formal_Filter : access function (Left : Integer; Right : Integer) return Boolean; Formal_Next : in Integer;` keep profile semicolons inside the formal object declaration while still exposing the following formal object to Outline.

Phase 579 language-analysis pass 96 note: compact generic package units with one-line declaration tails now stay whole while parsing the text after `generic;`. Forms such as `generic; package G is A : Integer; B : Boolean; end G;` parent both `A` and `B` to the generic package instead of splitting later tail declarations into the enclosing scope.

Phase 579 language-analysis pass 97 note: compact one-line package tails now recognize nested profiled callable bodies whose parameter profiles contain semicolons. Forms such as `package body P is procedure Run (Left : Integer; Right : Integer) is Local : Integer; begin null; end Run; X : Integer; end P;` keep profile parameters and local declarations under `Run`, then resume package-body parsing for `X` after the callable end.

Phase 579 language-analysis pass 98 note: compact one-line package tails now recognize nested protected/task declarations whose discriminant parts contain semicolon-separated groups. Forms such as `package P is protected type Lock (Left : Integer; Right : Integer) is entry Take; end Lock; X : Integer; end P;` keep `Left`, `Right`, and protected operations under `Lock`, then resume package-scope parsing for `X` after the concurrent end.

Phase 579 language-analysis pass 99 note: same-line discriminant extraction now scans the discriminant part with nested-parenthesis awareness. Access-to-subprogram discriminants such as `Callback : access procedure (Left : T; Right : T); Next : T` keep the callback profile semicolon as metadata, retain `Callback` and `Next` as discriminants, and do not emit the profile parameter names as outline symbols.

Phase 579 language-analysis pass 100 note: compact one-line package tails now distinguish nested callable bodies from compact expression functions and null/body-stub declarations. Forms such as `package body P is function F return Integer is (1); X : Integer; end P;` let `X` resume in the package-body scope instead of being captured by a synthetic callable-body nesting region that has no matching `end`.

Phase 579 language-analysis pass 101 note: compact generic callable units declared after a same-line `generic;` marker now distinguish expression functions, null procedures, and body stubs from nested callable bodies. Forms such as `generic; function F return Integer is (1); X : Integer;` let `X` parse as the following declaration instead of being swallowed by generic-unit nesting that is waiting for a non-existent `end`.

Phase 579 language-analysis pass 102 note: same-line type declaration groups now split only at top-level semicolons. Access-to-subprogram type profiles such as `type Callback is access procedure (Left : Integer; Right : Integer); type Next is range 0 .. 10;` keep profile semicolons inside the access type metadata while still exposing the following top-level type declaration to Outline.

Phase 579 language-analysis pass 103 note: compact one-line record tails now stop only at the matching `end record`, not at an inner variant `end case`. Forms such as `type Rec is record case Kind is when Small => Count : Integer; end case; Ready : Boolean; end record;` retain both `Count` and the post-variant `Ready` component as record-local Outline rows.

Phase 579 language-analysis pass 104 note: compact one-line package tails now keep nested compact record declarations open across inner variant `end case` markers until the matching `end record`. Forms such as `package P is type Rec is record case Kind is when Small => Count : Integer; end case; Trailer : Boolean; end record; After_Record : Integer; end P;` keep `Count` and `Trailer` record-local, then resume package-scope Outline rows for `After_Record`.

Phase 579 language-analysis pass 105 note: compact one-line package tails now keep nested compact callable bodies open across local `end record` and `end case` markers. Forms such as `package body P is procedure Run is type R is record A : Integer; B : Boolean; end record; Local : Integer; begin null; end Run; After_Run : Integer; end P;` keep the record and post-record callable locals under `Run`, then resume package-body Outline rows after `end Run`.

Phase 579 language-analysis pass 106 note: compact one-line package tails now keep nested callable bodies open across inner compact control-statement terminators such as `end if`, `end loop`, and `end select`. This prevents statement-block text after an inner control statement from being split as enclosing package declarations before the callable body's own `end` marker is reached.

Phase 579 language-analysis pass 107 note: compact one-line package tails now keep nested callable bodies open across named statement terminators and extended-return terminators. A named block such as `end Block_Name;` or an extended return `end return;` inside `procedure Run` / `function Make` no longer looks like the callable body's own `end`, so enclosing package-scope Outline rows resume only after the matching callable end.

Phase 579 language-analysis pass 108 note: compact one-line package tails now keep nested protected/task bodies open across operation-body terminators and inner control-statement ends until the matching protected/task `end <name>;`. Forms such as `package body P is protected body Lock is procedure Enter is begin if Ready then null; end if; end Enter; entry Leave when True is begin null; end Leave; end Lock; After_Lock : Integer; end P;` keep `Enter` and `Leave` protected-body local, then resume package-body Outline rows for `After_Lock`.

Phase 579 language-analysis pass 109 note: compact one-line package tails now keep nested compact package bodies open across callable-body and named statement terminators until the nested package's own anonymous or matching named `end`. Forms such as `package Outer is package body Inner is procedure Run is Local : Integer; begin null; end Run; Inner_After : Integer; end Inner; Outer_After : Integer; end Outer;` keep `Run` and `Inner_After` under `Inner`, then resume outer-package Outline rows after `end Inner`.

Phase 579 language-analysis pass 110 note: compact one-line package-tail parsing now records full selected names for nested compact package declarations and package bodies. Forms such as `package body Parent.Child is ... end Parent.Child;` no longer close the nested package region at an inner same-prefix terminator like `end Parent;`; Outline resumes the enclosing scope only at the anonymous package end or the exact selected package end.

Phase 579 language-analysis pass 111 note: compact one-line package-tail parsing now records full selected names for nested compact callable bodies. Forms such as `procedure Parent.Child is ... end Parent.Child;` no longer close the callable region at an inner same-prefix terminator like `end Parent;`; Outline resumes the enclosing package/body scope only at the anonymous callable end or the exact selected callable end.

Phase 579 language-analysis pass 112 note: compact one-line package-tail parsing now records full selected names for nested compact protected/task bodies. Forms such as `protected body Parent.Lock is ... end Parent.Lock;` no longer close the concurrent region at an inner same-prefix terminator like `end Parent;`; Outline resumes the enclosing package/body scope only at the anonymous concurrent end or the exact selected protected/task end.

Phase 579 language-analysis pass 113 note: compact selected-name tracking now normalizes layout around dots while splitting one-line package tails. Child-unit bodies such as `procedure Parent . Child is ... end Parent . Child;` keep their full selected name for tail matching, so an inner same-prefix `end Parent;` no longer closes the compact child body early and declarations after the exact child terminator resume in the enclosing scope.

Phase 579 language-analysis pass 114 note: compact generic package units declared after a same-line `generic;` marker now stay open across nested callable-body control terminators. Forms such as `generic; package G is procedure Run is begin if Ready then null; end if; end Run; After_Run : Integer; end G; Outside : Integer;` keep `After_Run` package-local and resume enclosing-scope Outline rows only after the generic package's own end.

### pass 115 compact generic package tail exact-end handling

The Ada declaration parser now keeps the opener name for compact generic package/unit tails introduced after a same-line `generic;` marker. A nested callable terminator such as `end Run;` no longer closes the compact generic package segment early; the enclosing generic package tail is split only at an anonymous end or the matching package/unit end marker.

### pass 116 compact generic package concurrent-tail handling

Phase 579 language-analysis pass 116 note: compact generic package tails now keep nested compact protected/task declarations whole. Forms such as `generic; package G is protected type Lock is procedure Enter; entry Leave; end Lock; After_Lock : Integer; end G;` parent protected operations and entries to `Lock`, then resume generic-package Outline rows for `After_Lock` only after the concurrent scope ends.

### pass 117 compact anonymous block tail handling

Phase 579 language-analysis pass 117 note: compact one-line package and generic-package tail parsing now keeps anonymous `declare ... end;` blocks and `accept ... do ... end;` bodies inside their owning compact callable/concurrent/nested package region. Forms such as `package body P is procedure Run is begin declare Local : Integer; begin null; end; After_Block : Integer; end Run; After_Run : Integer; end P;` keep `After_Block` under `Run`, then resume package-body Outline rows only after `end Run`.

Phase 579 language-analysis pass 118 note: compact tail parsing now distinguishes `accept Entry;` from `accept Entry do ... end;` while a compact callable, protected/task body, nested package, or compact generic unit is being kept whole. Accept statements without `do` no longer create anonymous-block nesting, so the following callable or generic-package end marker still resumes Outline ownership at the correct enclosing scope.

Phase 579 language-analysis pass 119 note: compact tail parsing now keeps anonymous declare/accept-body nesting open across inner control or metadata terminators such as `end if;`. The enclosing package/callable/generic tail splitter only consumes the anonymous nesting level at the anonymous block/body terminator, so declarations after that block remain in the callable/generic package until the real callable or package end.

### pass 120 compact callable bare-block tail handling

Phase 579 language-analysis pass 120 note: compact one-line package-tail parsing now treats bare `begin ... end;` blocks inside a compact callable body as callable-local anonymous blocks after the callable body's own first `begin` has been seen. Forms such as `package body P is procedure Run is begin begin null; end; Local_After : Integer; end Run; After_Run : Integer; end P;` keep `Local_After` under `Run` and resume package-body Outline rows only after the callable's matching end.

### pass 121 compact generic bare-block tail handling

Phase 579 language-analysis pass 121 note: compact same-line `generic;` package/unit tail parsing now mirrors compact package-tail bare-block handling. After the compact unit's own first `begin`, later bare `begin ... end;` blocks inside nested generic-package callables are treated as anonymous callable-local blocks, so their `end;` markers do not close the compact generic package or unit early.

### pass 122 compact package/concurrent bare-block tail handling

Phase 579 language-analysis pass 122 note: compact one-line package-tail parsing now also tracks bare `begin ... end;` anonymous blocks while nested compact package bodies and protected/task bodies are being kept whole. Forms such as `package body P is protected body Lock is procedure Enter is begin begin null; end; Local_After : Integer; end Enter; end Lock; After_Lock : Integer; end P;` keep `Local_After` under `Enter`, then resume package-body Outline rows only after the protected/task body's matching end.

### pass 123 compact anonymous declare block local-callable tails

Phase 579 language-analysis pass 123 note: compact package-tail parsing now tracks anonymous `declare` / `accept ... do` block end names instead of treating every non-control `end` inside the anonymous region as the anonymous block terminator. A local compact callable such as `procedure Local_Run ... end Local_Run;` inside a same-line `declare` block no longer spends the surrounding block's own `end;`, so declarations after the local callable remain callable-local until the real enclosing callable end.

### pass 124 compact generic anonymous declare block local-callable tails

Phase 579 language-analysis pass 124 note: compact `generic;` package/unit tail parsing now mirrors the package-tail anonymous-block name tracking. A local compact callable such as `procedure Local_Run ... end Local_Run;` inside a named same-line `declare` block no longer spends the surrounding block's own `end Local_Block;`, so declarations after the local callable remain callable-local until the real enclosing generic callable or package end.

### pass 125 compact labelled bare begin-block tails

Phase 579 language-analysis pass 125 note: compact tail parsing now records labels on bare `Name : begin ... end Name;` blocks inside one-line callable/package and same-line `generic;` tails. The labelled block terminator no longer leaves anonymous block nesting open, so declarations after the labelled block remain in the callable and declarations after the callable or generic package resume in the correct enclosing scope.

### pass 126 compact callable local-package begin ownership

Phase 579 language-analysis pass 126 note: compact one-line package-tail parsing now treats `begin` markers as belonging to the innermost compact owner. When a compact callable contains a local compact package/protected/task body, that inner body's `begin ... end;` block no longer marks the outer callable as having reached its own body begin, so declarations after the local body remain callable-local and declarations after the callable end resume in the enclosing package/body scope.

### pass 127 compact end-filter consolidation

Phase 579 language-analysis pass 127 note: compact package-tail and same-line `generic;` tail parsing now share a centralized metadata/control `end` filter. Anonymous declare/accept blocks, compact callable bodies, protected/task bodies, nested package bodies, and compact generic units consistently ignore inner `end case`, `end if`, `end loop`, `end select`, `end record`, and `end return` markers, so declarations after those metadata/control regions remain in the correct owning scope until the real declaration/body end is reached.

### pass 128 compact malformed-owner tail rejection

Phase 579 language-analysis pass 128 note: compact package-tail parsing now rejects malformed/in-progress nested callable, package, protected, or task fragments that do not expose a real owner name before opening a synthetic compact tail region. This keeps partially typed one-line declarations such as `procedure is ...`, `package is ...`, or `protected is ...` bounded: Ada keywords are not emitted as declaration names, and following declarations remain attached to the nearest valid package/body scope instead of being swallowed by a nameless compact owner.

### pass 129 compact generic malformed-owner rejection

Phase 579 language-analysis pass 129 note: compact same-line `generic;` tail parsing now mirrors the malformed-owner guard used by ordinary compact package tails. In-progress generic unit fragments such as `generic; package is ...`, `generic; function return T is ...`, `generic; protected is ...`, or `generic; task is ...` no longer open synthetic generic-unit regions named after Ada keywords; following declarations remain bounded and visible rather than being swallowed by a bogus compact owner.

### pass 130 reserved-word compact owner rejection

Phase 579 language-analysis pass 130 note: compact package-tail and same-line `generic;` tail tracking now rejects any Ada reserved word used as a would-be compact owner name, including selected-name components, instead of checking only the previously observed malformed fragments such as `is`, `return`, `body`, or `type`. Malformed/in-progress compact text therefore cannot learn reserved words like `private` as package, callable, protected, or task symbols, and following declarations remain bounded to the nearest valid owner.

### pass 131 compact quoted-operator owner validation

Phase 579 language-analysis pass 131 note: compact tail owner validation now accepts quoted callable owner names only when they are Ada operator symbols or reserved operator words such as `"+"`, `"and"`, or `"abs"`. Malformed compact callable/generic tails using arbitrary quoted strings no longer create synthetic operator-function owners while still preserving valid operator functions.

### pass 132 compact owner identifier validation

Phase 579 language-analysis pass 132 note: compact tail owner validation now requires each selected-name component to be a valid Ada identifier component before it can open a synthetic compact scope. Malformed/in-progress owners such as `Bad__Name`, `Trailing_`, or empty selected-name components are ignored, while valid compact package/callable owners and quoted Ada operator functions remain supported.

### pass 133 parent-child symbol ownership

Phase 579 language-analysis pass 133 note: the shared Ada language model now exposes deterministic parent-to-child symbol lookup through `Child_Count` and `Child_At`. Outline and navigation code can consume parser-owned child relationships directly instead of rebuilding ownership by rescanning all symbols, while invalid or out-of-range child lookups degrade to `No_Symbol`.

### pass 134 selected-name resolver false-positive guard

Phase 579 language-analysis pass 134 note: global selected-name resolver queries now stay exact unless the parser preserved the selected declaration name itself. A query such as `Missing.Widget` no longer falls back to an unrelated leaf symbol named `Widget`; scoped prefix/leaf walking remains the responsibility of `Resolve_In_Scope`, where the caller supplies the current lexical scope. This keeps Outline/navigation target discovery conservative and avoids fabricating declaration targets from same-leaf names.

### pass 135 project-index overflow propagation

Phase 579 language-analysis pass 135 note: project-index lookup now propagates overflow from each indexed Ada language-model analysis, not only from the project index file table itself. Declaration/body/spec navigation can therefore reject or degrade ambiguous targets when a current indexed file was parsed only up to the bounded symbol budget.

### pass 136 scoped overload-set language-model API

Phase 579 language-analysis pass 136 note: the shared Ada language model now exposes deterministic same-scope overload-set lookup through `Overload_Count` and `Overload_At`. Outline/navigation code can distinguish overloaded declarations owned by one scope without flattening them into a single symbol, while nested scopes remain isolated and out-of-range lookups degrade to `No_Symbol`.

### pass 137 lifecycle-index invalidation hardening

Phase 579 language-analysis pass 137 note: project language-index lifecycle invalidation now deletes exactly the matching indexed file at the current cursor and then rechecks the same vector position. This prevents stale project-close/switch generations from leaving adjacent stale files behind or accidentally deleting a survivor from a different lifecycle generation.

### pass 138 aggregate project-index overflow status

Phase 579 language-analysis pass 138 note: `Editor.Ada_Project_Index.Overflowed` now reports aggregate overflow across both the project index file table and every indexed bounded Ada analysis result. Outline/status/navigation callers can detect a truncated current project language index without first issuing a symbol lookup, so declaration/body/spec target discovery can remain conservative whenever any indexed file exceeded the per-analysis symbol budget.

### pass 139 overlong semantic-name degradation

Phase 579 language-analysis pass 139 note: semantic-map ingestion now treats overlong Ada names as bounded overflow instead of inserting a truncated key. This keeps Outline-backed and language-model-backed semantic consumers conservative: a very long declaration name is not converted into a misleading prefix symbol, and unknown identifiers continue to degrade to ordinary identifiers.

### pass 140 project-index path fingerprints

Phase 579 language-analysis pass 140 note: project language-index fingerprints now include the indexed file path in addition to buffer token, revision, lifecycle generation, and analysis fingerprint. Outline/navigation consumers therefore get distinct aggregate stamps for two different project files even when their source text and ownership counters match.

### pass 141 project-index overflow-sensitive fingerprints

Phase 579 language-analysis pass 141 note: project language-index fingerprints now include the bounded file-table overflow state. If an explicit index refresh attempts to add more files than the project-index budget allows, the index remains bounded, reports overflow, and changes its aggregate fingerprint even though no extra file row is appended. Outline/navigation consumers can therefore detect the conservative stale-target state through the same stamp used for ordinary file additions, removals, and replacements.

### pass 142 analysis overflow fingerprints

Phase 579 language-analysis pass 142 note: Ada language-model fingerprints now include the bounded analysis overflow transition. When parsing or explicit symbol insertion reaches `Max_Analysis_Symbols` and rejects an additional declaration, the `Analysis_Result` remains bounded, reports overflow, and changes its fingerprint exactly once for the overflow state. Outline/project-index consumers can therefore distinguish a complete analysis from a truncated analysis even when both contain the same retained symbol rows.

### pass 143 profile fingerprint idempotence

Phase 579 language-analysis pass 143 note: Ada language-model profile refinement is now fingerprint-idempotent. Re-applying the same subprogram/profile summary to a symbol no longer changes the analysis fingerprint, while a genuinely different profile still updates the stamp. This keeps Outline/project-index ownership stable when parser refinement code revisits an already-learned declaration without changing its displayed profile metadata.

### pass 144 selected-scope direct-leaf resolver matching

Phase 579 language-analysis pass 144 note: selected-name resolution now requires the final selected component to be a direct declaration in the resolved prefix scope. After `Pkg` has been selected, `Pkg.Widget` no longer binds to a dotted child such as `Inner.Widget` merely because the child has the same leaf name. This keeps Outline declaration/body/spec navigation from manufacturing selected-name targets from nested dotted symbols that are not direct children of the selected prefix.

Phase 579 language-analysis pass 145 note: initial `Editor.Ada_Language_Model.Add_Symbol` fingerprints now include the full source range, declaration column, declaration flags, profile summary, and target metadata. Outline cache stamps can therefore distinguish parser-owned rows whose displayed/navigation metadata differs at creation time, not only after a later mutator refines the symbol.


Phase 579 language-analysis pass 146 note: `Editor.Ada_Symbol_Resolver.Resolve_In_Scope` now rejects invalid lexical scope ids instead of falling back to the root scope. Outline navigation rows that carry stale or impossible scope stamps therefore degrade to no target rather than accidentally binding to a root declaration.

### pass 147 invalid parent-child lookup guard

Phase 579 language-analysis pass 147 note: `Editor.Ada_Language_Model.Child_Count` and `Child_At` now validate that the requested parent id is a symbol actually owned by the current analysis result. Stale or malformed parent ids no longer expose orphaned rows that happen to carry the same invalid parent number, so Outline/navigation child traversal degrades to zero children or `No_Symbol` unless the parent symbol is current and in-budget.

### pass 148 invalid overload-scope lookup guard

Phase 579 language-analysis pass 148 note: `Editor.Ada_Language_Model.Overload_Count` and `Overload_At` now validate that overload-set enumeration is requested for the root scope or a symbol scope owned by the current analysis result. Malformed or stale scope ids no longer expose orphaned overload rows that happen to carry the same impossible `Enclosing_Scope`, so Outline overload details degrade to zero members or `No_Symbol` unless the scope stamp is current and in-budget.

### pass 149 source-spelling-sensitive language-model fingerprints

Phase 579 language-analysis pass 149 note: `Editor.Ada_Language_Model.Add_Symbol` now keeps Ada lookup case-insensitive while also hashing preserved source spelling into the deterministic analysis fingerprint. Outline labels and navigation metadata retain declaration spelling, so otherwise identical declarations or rename targets that differ only by case no longer look cache-equivalent to stale-row rejection and project-index consumers.

### pass 150 cyclic lexical parent-chain guard

Phase 579 language-analysis pass 150 note: `Editor.Ada_Symbol_Resolver.Resolve_In_Scope` now bounds lexical parent-chain walking by the number of retained symbols. If malformed or stale parser metadata creates a cyclic parent chain, Outline declaration/body/spec navigation degrades to no match instead of looping indefinitely while trying to walk enclosing scopes.

### pass 151 exact selected-name lexical visibility

Phase 579 language-analysis pass 151 note: `Editor.Ada_Symbol_Resolver.Resolve_In_Scope` now keeps its exact selected-name fast path constrained to root-owned units or declarations visible from the caller's lexical scope chain. A preserved dotted declaration from an unrelated nested scope no longer becomes an Outline declaration/body/spec target merely because its normalized selected spelling matches the requested name.

### pass 152 impossible parent-scope resolver guard

Phase 579 language-analysis pass 152 note: `Editor.Ada_Symbol_Resolver.Resolve_In_Scope` now validates each lexical parent scope before performing a lookup iteration. If corrupt parser metadata points a valid starting symbol at an impossible parent id, Outline declaration/body/spec navigation degrades to no target instead of exposing orphaned rows whose `Enclosing_Scope` happens to carry that same impossible number.

### pass 153 scoped unselected dotted-leaf resolver guard

Phase 579 language-analysis pass 153 note: `Editor.Ada_Symbol_Resolver.Resolve_In_Scope` now separates scoped unselected lookup from selected/dotted declaration leaves. A request for `Widget` in a lexical scope no longer binds to a retained declaration named `Inner.Widget` merely because the leaf component matches. Exact selected lookup for `Inner.Widget` remains supported when visible, but Outline declaration/body/spec navigation does not manufacture a direct unselected target from a dotted child declaration.

### pass 154 compatibility resolver dotted-leaf guard

Phase 579 language-analysis pass 154 note: the compatibility `Editor.Ada_Symbol_Resolver.Resolve` path now uses the same selected-name leaf boundary as scoped resolution. An unselected Outline/navigation request for `Widget` no longer binds to a retained declaration named `Inner.Widget`; exact selected lookup for `Inner.Widget` remains available, and a direct `Widget` declaration remains resolvable.

### pass 155 self-parent child traversal guard

Phase 579 language-analysis pass 155 note: `Editor.Ada_Language_Model.Child_Count` and `Child_At` now ignore malformed self-parent edges. If a parser or test fixture accidentally stamps a symbol as its own parent, Outline child traversal no longer exposes the parent as its own child; real nested children still appear in deterministic declaration order.

### pass 156 predicate classification alignment

Phase 579 language-analysis pass 156 note: `Editor.Ada_Language_Model.Is_Subprogram` now includes `Symbol_Separate_Body`, and `Is_Type_Like` now includes `Symbol_Generic_Formal_Type`. Outline/navigation consumers that use these model predicates are therefore aligned with the semantic token mapping: separate bodies are treated as callable body targets, while generic formal types remain dedicated generic-formal tokens but still participate in broader type-like filtering.

### pass 157 declaration-owning overload scope guard

Phase 579 language-analysis pass 157 note: `Editor.Ada_Language_Model.Overload_Count` and `Overload_At` now require non-root overload scopes to be declaration-owning symbols, not merely numerically valid symbol ids. Malformed rows attached to object/component/literal ids no longer appear as overload sets, so Outline overload details and navigation degrade to zero members or `No_Symbol` unless the scope id names an actual declaration-owning scope retained by the analysis.

### pass 158 generic-formal-package overload scope support

Phase 579 language-analysis pass 158 note: `Editor.Ada_Language_Model.Overload_Count` and `Overload_At` now treat `Symbol_Generic_Formal_Package` as a declaration-owning scope. This preserves the pass 157 non-owner guard while allowing retained nested declarations under generic formal packages to participate in deterministic overload enumeration for Outline metadata and navigation.

### pass 159 ownership-sensitive language-model fingerprints

Phase 579 language-analysis pass 159 note: `Editor.Ada_Language_Model.Add_Symbol` now hashes `Enclosing_Scope` and `Parent_Symbol` into the deterministic analysis fingerprint. Outline hierarchy, child traversal, scoped navigation, and stale-row rejection all depend on parser-owned ownership metadata, so otherwise identical declarations retained under different scopes or parents no longer look cache-equivalent.

### pass 160 bounded project-index qualified names

Phase 579 language-analysis pass 160 note: `Editor.Ada_Project_Index` now bounds parent-symbol walking while constructing qualified names for project-wide lookup. If malformed analysis data creates a cyclic or impossible `Parent_Symbol` chain, qualified Outline/navigation lookup degrades to local spelling and does not fabricate dotted declaration targets or recurse indefinitely.

### pass 161 project-index unselected selected-leaf guard

Phase 579 language-analysis pass 161 note: project-wide unselected lookup now mirrors the scoped resolver's selected-name boundary. A request for `Widget` no longer binds to a retained project-index declaration named `Inner.Widget` merely because the leaf spelling matches; exact selected lookup for `Inner.Widget` and direct unselected `Widget` declarations remain supported. Outline declaration/body/spec navigation therefore avoids manufacturing project-wide leaf targets from selected/dotted declarations.

### pass 162 project-index non-owner parent qualifier guard

Phase 579 language-analysis pass 162 note: project-index qualified-name construction now accepts only declaration-owning parent symbols as selected-name prefixes. Malformed analysis metadata that attaches a child declaration to a value-like parent such as an object no longer fabricates navigation targets like `Obj.Widget`; local lookup remains available and package-owned selected names such as `Pkg.Gadget` still resolve.

### pass 163 declaration-owner child traversal guard

Phase 579 language-analysis pass 163 note: `Editor.Ada_Language_Model.Child_Count` and `Child_At` now require the requested parent symbol to be declaration-owning, not only numerically valid. Malformed analysis rows attached beneath value-like symbols such as objects, constants, components, or literals no longer appear as Outline child rows; valid package/type/subprogram/task/protected/generic/formal-package parents still expose deterministic children.

### pass 164 declaration-owner predicate consolidation

Phase 579 pass 164 centralizes declaration-owner classification in `Editor.Ada_Language_Model.Is_Declaration_Owner`.  Outline child traversal now uses this shared predicate instead of maintaining a private owner-kind list, so package/type/subprogram/task/protected/generic ownership rules stay aligned with overload scopes and project-index selected-name construction.  Value-like rows such as objects, constants, record components, discriminants, literals, and exceptions remain non-owners and therefore cannot expose malformed nested Outline children.

### pass 165 child parent/scope consistency guard

Phase 579 pass 165 tightens `Editor.Ada_Language_Model.Child_Count` and `Child_At` so direct Outline children require both parser-owned ownership stamps to agree: `Parent_Symbol` must identify the parent row and `Enclosing_Scope` must name that same parent scope. Malformed rows that point at one parent but carry another lexical scope no longer appear as Outline children; valid direct children remain visible in deterministic declaration order.

### pass 166 non-owner resolver start-scope guard

Phase 579 pass 166 tightens `Editor.Ada_Symbol_Resolver.Resolve_In_Scope` so a numerically valid symbol id is accepted as a lexical starting scope only when it is a declaration-owning symbol. Value-like rows such as objects, constants, record components, discriminants, literals, and exceptions can no longer act as Outline declaration/body/spec lookup scopes or expose malformed child rows whose `Enclosing_Scope` happens to match that value symbol id.

Phase 579 pass 167 tightens overload-set enumeration in `Editor.Ada_Language_Model`. `Overload_Count` and `Overload_At` now require direct overload rows to have synchronized parser-owned ownership stamps: root overloads must remain root-owned, and non-root overloads must have both `Enclosing_Scope` and `Parent_Symbol` pointing at the same declaration-owning scope. Malformed rows that carry the requested lexical scope but point at a different parent no longer appear as same-scope Outline overload/navigation rows.

### pass 168 selected-name direct-parent resolver guard

Phase 579 pass 168 tightens selected-name Outline/navigation lookup in `Editor.Ada_Symbol_Resolver.Resolve_In_Scope`. After a selected prefix such as `A` resolves, `A.Widget` now binds only to declarations whose `Enclosing_Scope` and `Parent_Symbol` both identify that prefix symbol. Malformed rows that carry the selected scope but point at another parent are ignored, preserving valid direct selected children while preventing stale ownership metadata from fabricating navigation targets.

### pass 169 canonical language command surface

Phase 579 pass 169 adds the canonical IDE-grade language commands to the real command registry and executor path: `outline.refresh-project-index`, `outline.goto-declaration`, `outline.goto-body`, `outline.goto-spec`, `semantic.refresh-buffer`, `semantic.refresh-project-index`, `language.index.clear`, and `language.index.status`. `outline.goto-declaration` reuses the existing validated Outline row declaration navigation path, the refresh commands parse only the active immutable buffer snapshot, and the language-index commands operate on transient in-memory Ada project-index state without mutating files, dirty state, rendering-side parsing, or workspace persistence.

### pass 170 language-index lifecycle invalidation

Phase 579 pass 170 wires the transient Ada project language index into existing project/file lifecycle invalidation instead of relying only on explicit `language.index.clear`. Project close/clear/switch now clears `Editor.State.Language_Index`, and file lifecycle changes that stale Outline targets (`save as`, reload, revert, rename/delete/move style active-buffer lifecycle paths) invalidate the active buffer token and current source path in `Editor.Ada_Project_Index`. This keeps `outline.goto-declaration` and future body/spec target lookup from seeing stale parser-owned rows after a path, revision, or lifecycle transition.

### pass 171 explicit project-file index refresh

Phase 579 pass 171 changes `outline.refresh-project-index` from active-buffer-only indexing to project-file indexing. The command refreshes known project files, parses `.ads` and `.adb` files from disk without saving or reloading buffers, uses the active immutable buffer snapshot for the current file when paths match, clears the transient index before rebuilding it, and reports indexed/skipped/read-error counts. Project-wide Outline/navigation lookup state remains executor-owned instead of render-driven while preserving bounded `Editor.Ada_Project_Index` limits.

Phase 579 pass 172 fixes the command-surface regression coverage added for the IDE-grade language command set: the expected-command descriptor loop is now closed before the project-refresh descriptor assertions. This keeps `outline.refresh-project-index` and the other canonical language commands covered as individual stable ids while also preserving separate assertions for the project-file refresh wording.

### pass 173 indexed Outline body/spec navigation

Phase 579 pass 173 turns `outline.goto-body` and `outline.goto-spec` from registered unavailable commands into real indexed Outline navigation for package spec/body pairs. The commands validate the selected Outline projection row, resolve the preserved package name through the transient Ada project language index, filter the target by package-spec/package-body kind, open or focus the indexed file through the normal file-open path, and then navigate to the parser-owned source range. If the index is stale, absent, over-budget, or lacks a matching pair, the commands remain unavailable and do not fabricate targets.

### pass 174 generic package spec/body navigation completeness

Phase 579 pass 174 completes the package body/spec navigation path for generic packages. `outline.goto-spec` now accepts both ordinary `Symbol_Package` and `Symbol_Generic_Package` targets when the selected row is a package body, while `outline.goto-body` continues to target `Symbol_Package_Body`. This keeps generic package specs represented by the language model as generic declarations without making package-body navigation unavailable for `generic ... package G is` / `package body G is` pairs.

### pass 175 subprogram body/spec navigation completeness

Phase 579 pass 175 extends indexed Outline body/spec navigation beyond packages to ordinary procedure and function declarations. The Ada language model now retains a conservative `Is_Body` declaration flag for parser-owned callable bodies, Outline labels preserve `procedure body` / `function body` spelling for model-projected rows, and `outline.goto-body` / `outline.goto-spec` filter project-index matches by both callable kind and body/spec metadata. If a callable target is absent, stale, overloaded without a retained opposite declaration, or not represented by current project-index data, navigation remains unavailable rather than fabricating a cross-file target.

Phase 579 pass 176 completes the conservative generic subprogram side of indexed Outline body/spec navigation. Model-projected generic callable rows use `generic subprogram` labels, so `outline.goto-body` / `outline.goto-spec` now strip that label prefix and accept `Symbol_Generic_Subprogram` targets when the parser-owned `Is_Body` metadata selects the opposite side. Generic procedure/function profile-level disambiguation remains conservative, but retained generic subprogram spec/body pairs no longer degrade merely because their shared language-model kind is generic.

### pass 177 separate-body parent navigation completeness

Phase 579 pass 177 completes the first indexed separate-body parent navigation path. Model-projected `Symbol_Separate_Body` rows now keep a callable Outline kind instead of degrading to unknown, and `outline.goto-spec` uses the selected separate body's retained `Target_Name` metadata to resolve and navigate to the indexed parent declaration. If the selected subunit, parent target, or project index entry is stale or absent, navigation remains unavailable rather than fabricating a parent location.

### pass 178 separate-body parent target validation

Phase 579 pass 178 tightens the separate-body `outline.goto-spec` path added in pass 177. The selected separate body still uses parser-owned `Target_Name` metadata and the transient Ada project index, but the indexed parent candidate must now satisfy the shared language-model `Is_Separate_Body_Parent_Target` predicate. Objects, components, literals, body rows, and other value-like symbols that merely share the same retained name are rejected rather than used as navigation targets.

### Phase 579 pass 179 completeness: edit invalidation for indexed Outline targets

Phase 579 pass 179 closes an invalidation gap after the indexed `outline.goto-body` / `outline.goto-spec` work. Ordinary text edits now invalidate transient Ada project-index rows for the active source path and active buffer token, and clear parser-derived semantic maps. This gives text edits the same stale-analysis treatment as reload, revert, save-as, and other lifecycle operations: Outline navigation must refresh from the edited snapshot instead of reusing a pre-edit parser/index target.

### Phase 579 pass 180 semantic preparation alignment

Phase 579 pass 180 aligns render-time visible-range semantic preparation with the shared Ada language model used by Outline and indexed navigation. Semantic colouring no longer has to re-project through Outline rows before classification during normal syntax preparation; it consumes parser-owned `Analysis_Result` data directly and keeps the same revision/buffer ownership stamps used by the cache invalidation paths.

### Phase 579 pass 181 completeness: semantic lookup prefix safety

Phase 579 pass 181 keeps Outline-driven and language-model-driven semantic colouring conservative for fixed-width semantic maps. Overlong identifier lookups no longer match retained 64-column prefixes, so malformed or unusually long Ada identifiers cannot acquire an Outline/semantic classification by prefix collision.

### Phase 579 pass 182 completeness: file lifecycle index invalidation

Phase 579 pass 182 closes the remaining file-lifecycle integration gap for indexed Outline targets. Active-buffer rename, move, and delete operations now invalidate the previous backing path as well as the active token/new association. File Tree create/rename/delete invalidates exact and descendant language-index paths so directory-level mutations cannot leave cross-file Outline body/spec or separate-body targets pointing at removed or rebased Ada source files.

Phase 579 pass 183 completeness: exact Ada project-index path invalidation now uses the same separator and trailing-slash normalization as subtree invalidation. Active-buffer lifecycle operations such as reload, revert, save-as, rename, and move may hand the language index a platform-native path spelling while project refresh retained a normalized project path. Exact invalidation now removes the same indexed Outline/navigation row in either spelling, preventing stale declaration/body/spec targets from surviving only because `/` and `\` or a trailing separator differed.

### Phase 579 pass 184 project-index open-buffer overlay

`outline.refresh-project-index` now overlays every open file-backed Ada buffer
onto the project language index after the filesystem/project-file pass.
This means an inactive open buffer with unsaved text is indexed from its
immutable editor snapshot instead of leaving the project-wide Outline/navigation
index on the older disk contents.  The active buffer still uses the active-state
stamps, and the refresh remains bounded by `Editor.Ada_Project_Index.Max_Index_Files`.

### Phase 579 pass 185 completeness: open-buffer index priority

Phase 579 pass 185 makes project language-index refresh prefer editor-owned snapshots before filesystem snapshots. The active Ada buffer and other open file-backed Ada buffers are indexed before the project file scan, so unsaved open-buffer analyses cannot be starved when a large project reaches the bounded index budget. Disk rows whose normalized paths are already represented by an open-buffer snapshot are skipped rather than replacing the editor-owned parser analysis.

### Phase 579 pass 186 profile-aware callable navigation

Phase 579 pass 186 tightens indexed `outline.goto-body` / `outline.goto-spec` matching for overloaded callable declarations. Procedure and function navigation still uses conservative name/kind/body metadata, but when both the selected Outline row and an indexed candidate retain parser-owned profile summaries, the profiles must match before the candidate can be used as a target. This prevents a selected overload such as `Run (Count : Natural)` from navigating to an unrelated `Run (Name : String)` body merely because the base name and body/spec side match.

### Phase 579 pass 187 profiled callable navigation safety

`outline.goto-body` and `outline.goto-spec` now treat a selected callable row
with retained parser-owned profile metadata as profile-sensitive.  Such a row
will not navigate to an indexed callable target that lacks profile metadata;
this avoids reintroducing same-name overload ambiguity after the pass 186
profile-aware target filtering.  Rows without retained profile metadata remain
conservative and continue to use name/kind/body-side matching.


## Phase 579 pass 188 semantic scope bridge

Pass 188 retains the parser-owned Ada analysis in editor state so render-time semantic colouring can ask the language model for a conservative token-position lexical scope before falling back to the bounded flat semantic map. Outline navigation continues to use validated indexed targets; the shared scope bridge keeps render-time semantic lookup aligned with parser-owned declaration ownership.

### Phase 579 pass 189 completeness

The parser-owned semantic scope bridge now respects retained source ranges. A declaration-owning symbol that merely starts before a token is no longer considered the active lexical scope after its parser-retained range has ended, so stale body/package owners cannot colour later declarations or navigation candidates as though they were still nested.

### Phase 579 pass 190 completeness

Outline remains backed by parser-owned Ada language-model symbols. This pass tightens the semantic-colouring consumer of that model: overlong identifier tokens are no longer classified through scoped resolver lookup, preserving the same bounded no-truncation invariant used by the flat semantic map while leaving Outline labels and source-spelling retention unchanged.


### Phase 579 pass 191 completeness

Outline fallback handling is now marker-only. If `Editor.Ada_Declaration_Parser` produces parser-owned Ada symbols, Outline projects those symbols through the shared language model. If the parser produces no symbols, `Editor.Outline_Extractor` may still preserve explicit `@outline` manual rows, but it no longer runs the older declaration-leading Ada line scanner as a fallback recognizer.

### Phase 579 pass 192 completeness

Outline extraction now invokes `Editor.Ada_Declaration_Parser.Parse` for every non-empty immutable snapshot instead of first gating parser execution through the older Ada-like line detector. Extensionless buffers with real Ada declarations therefore use the same parser/language-model path as `.ads` and `.adb` files, while parser-empty snapshots still fall back only to explicit `@outline` manual markers.

### Phase 579 pass 193 unique body/spec target selection

Indexed Outline navigation now degrades on remaining ambiguity after name, symbol kind, body/spec side, and parser-owned profile filtering.  This keeps cross-file `outline.goto-body` and `outline.goto-spec` deterministic and conservative: the editor opens a target only when the project language index contains one matching declaration/body/spec candidate, while duplicate retained candidates require a future, more precise Ada visibility model rather than a guessed jump.


## Pass 194 completeness

The old declaration-leading Ada fallback procedure has been removed from `Editor.Outline_Extractor`. Normal Ada declarations are now projected only from `Editor.Ada_Declaration_Parser` / `Editor.Ada_Language_Model` analysis. If parser analysis yields no symbols, the extractor preserves only explicit manual `@outline` marker rows and does not keep a dormant duplicate Ada line recognizer in the Outline package body.


Phase 579 pass 195 representation-clause note: Ada representation clauses such as `for T use record ... end record;` and address/size clauses are retained as bounded declaration metadata on the referenced symbol when the declaration is present in the current analysis. They do not create standalone Outline rows, they do not open or close language-model scopes, and unresolved representation targets are ignored rather than guessed. Generated-source and conditional-source markers are retained as bounded awareness metadata; interpreting or expanding generated/conditional source remains a conservative non-goal.

### Phase 579 pass 196 overflow-safe indexed navigation

Indexed `outline.goto-body` / `outline.goto-spec` now reject apparent unique targets when the Ada project language index reports either file-table overflow or per-file analysis overflow. A truncated index cannot prove that omitted declarations would not create a duplicate or better body/spec target, so command availability degrades to unavailable rather than navigating to the only retained match. Separate-body `outline.goto-spec` now follows the same rule and also rejects duplicate retained parent candidates instead of selecting the first one.


### Pass 197 validation gate note

Pass 197 adds `tools/bin/phase579_language_validation_check`, an Ada-native validation gate for the IDE-grade Ada language-model work. The gate statically verifies the parser-backed Outline architecture, scoped semantic-colouring path, project-index/navigation regression coverage, representation-clause metadata coverage, and generated/conditional source-awareness tests. With `EDITOR_REQUIRE_PHASE579_LANGUAGE_VALIDATION=1`, missing `gprbuild`, a failed `tests/tests.gpr` build, or a failed `tests/bin/tests` run is a hard validation failure.

## Phase 579 pass 200 completeness: indexed navigation target-key revalidation

`outline.goto-body` and `outline.goto-spec` now carry the exact `Editor.Ada_Project_Index.Indexed_File_Key` resolved with the indexed target. Execution revalidates that key immediately before opening a target path or applying the caret handoff. Open-buffer targets must still match the current buffer token, revision, lifecycle generation, and analysis fingerprint; disk-indexed targets must still be present as the exact retained zero-token key. This closes the gap where command availability could observe a unique indexed target and a later clear, project switch, file lifecycle invalidation, or refresh could otherwise leave a stale executable target.

### Phase 579 pass 201 declaration target availability

Declaration navigation availability now validates the selected Outline row as an activation target, not merely as a selectable row. The retained buffer token, target kind, line, and column must still resolve to a live editor buffer and an in-range source position before `outline.goto-declaration` or `outline.open-selected` are exposed as available. This aligns declaration navigation with the stricter body/spec target-key revalidation used by the project index.

### Phase 579 pass 202 normalized indexed body/spec handoff

Indexed body/spec navigation now keeps the pass 200 exact target-key validation and additionally normalizes the active editor path during the execution handoff. This preserves stale-target rejection while avoiding false negatives when the retained project-index path and the active buffer path differ only by separator spelling or equivalent normalized root-path form.

Phase 579 pass 204 parser-completeness note: declaration aspect specifications are now retained as bounded parser-owned metadata on package, type, subprogram, and other parsed declaration symbols. Aspect text remains metadata rather than a standalone Outline row or semantic declaration; profile summaries continue to stop before aspect clauses, while Outline detail rows can show that a declaration carried aspect metadata.

Phase 579 pass 205 parser-completeness note: Outline details now surface parser-owned pragma metadata on the referenced declaration when an entity pragma can be resolved. Pragmas remain metadata only; they do not create Outline rows, open scopes, or affect manual `@outline` fallback handling.


Pass 206 parser-completeness update: Ada context `with` clauses and `use` / `use type` / `use all type` clauses are retained as bounded analysis metadata. They do not create Outline rows, do not create declaration symbols for imported package names, and do not change scope ownership; they only stamp the parser-owned analysis so caches, docs, and conservative language consumers can distinguish source that depends on context/use visibility clauses.

Phase 579 pass 207 parser-completeness note: Ada null exclusions (`not null`) on access types, subtypes, object declarations, and generic formal objects are retained as bounded declaration metadata (`Has_Null_Exclusion`). The null-exclusion keywords do not create Outline rows, do not become semantic symbols, and are stripped from subtype/designated-target metadata where target metadata is retained.

Phase 579 pass 208 parser-completeness note: Ada `aliased` declaration syntax is now retained as bounded declaration metadata (`Has_Aliased_Metadata`) on parser-owned symbols such as objects and generic formal objects. The `aliased` keyword does not create Outline rows, open scopes, or become a semantic declaration, and it can coexist with other metadata such as `not-null`.

Phase 579 pass 209 parser-completeness note: Ada type qualifiers are now retained as bounded declaration metadata. Parser-owned type and generic formal type symbols can expose `Has_Limited_Metadata`, `Has_Tagged_Metadata`, and `Has_Interface_Metadata` in Outline details without creating standalone rows or treating `limited`, `tagged`, or `interface` as declarations.

Phase 579 pass 210 parser-completeness note: Ada `synchronized` interface/type qualifier syntax is now retained as bounded declaration metadata (`Has_Synchronized_Metadata`) on parser-owned type and generic formal type symbols. The qualifier appears only in Outline detail metadata; it does not create standalone rows, open scopes, or become a semantic declaration.

Phase 579 language-analysis pass 211 note: access and array declaration forms are now retained as bounded declaration metadata. Access type/object/formal declarations carry `access` metadata and array type/object declarations carry `array` metadata on the owning language-model symbol; index ranges, designated subtype expressions, and anonymous profile internals remain target/profile metadata rather than standalone Outline rows.

Phase 579 language-analysis pass 212 note: derived type declarations are now retained as bounded declaration metadata. Declarations such as `type Child is new Root with null record;`, private extensions, and generic formal derived types carry `derived` metadata on the owning language-model symbol; parent subtype expressions remain target/profile text and do not become standalone Outline rows.

Phase 579 language-analysis pass 213 note: scalar numeric type forms are now retained as bounded declaration metadata. Signed integer ranges, modular types, floating-point `digits` clauses, fixed-point `delta`/`digits` clauses, range-constrained subtypes, and generic formal scalar types carry `range`, `mod`, `digits`, and `delta` metadata on the owning language-model symbol; bounds and numeric expressions remain metadata text and do not create Outline rows.


Pass 214 extends parser-owned Ada declaration metadata with bounded access-to-subprogram awareness. Access procedure/function and access protected procedure/function declarations retain `access-subprogram` metadata on the owning symbol without learning anonymous profile names as declarations.

Phase 579 language-analysis pass 215 note: variant record parts are now retained as bounded declaration metadata. Record types that contain a variant `case ... is` part carry `variant-record` metadata on the owning parser-owned type symbol; discriminant choices and variant branch labels remain syntax/metadata and do not create standalone Outline rows.

Phase 579 language-analysis pass 216 note: default expressions and initializers are now retained as bounded declaration metadata. Object/constant initializers, component defaults, discriminant defaults, and subprogram parameter defaults can mark the owning parser-owned symbol with `default-expression` detail; the expression itself does not create standalone Outline rows or declaration symbols.

Phase 579 language-analysis pass 217 note: entry-family declarations now retain bounded declaration metadata. Entries such as `entry E (Positive) (Item : T);` can mark the owning parser-owned entry symbol with `entry-family` detail; the family index subtype and choices do not create standalone Outline rows or declaration symbols.


Pass 218 parser-completeness note: incomplete type declarations (`type T;` and `type T is tagged;`) are retained as bounded language-model metadata (`incomplete-type`) on the owning type symbol. They do not open scopes, create completion targets, or learn syntax keywords as semantic identifiers.

### Pass 219 parser completeness note

The Ada declaration parser now retains explicit parameter-mode/profile-shape metadata on the owning callable declaration.  `in out`, `out`, and anonymous `access` parameter forms are surfaced as bounded Outline detail metadata and are not learned as declaration symbols.

Phase 579 language-analysis pass 220 note: entry bodies with `when` barrier conditions now retain bounded declaration metadata. The owning parser-backed entry symbol can show `entry-barrier` detail, while the barrier expression itself does not create Outline rows or declaration symbols.

### Pass 221: box syntax metadata

The parser-owned Outline model retains Ada box (`<>`) syntax as bounded declaration metadata.  Generic formal scalar boxes, generic formal package actual boxes, unconstrained array bounds, and boxed formal defaults can be shown as `box` detail metadata on the owning declaration.  The box marker does not create a separate Outline row and does not make generic actual expressions or bound syntax into symbols.

### Phase 579 pass 222: access-mode metadata

The parser-owned Outline model now distinguishes Ada access-to-object mode qualifiers as bounded declaration metadata.  Declarations containing `access all` can show `access-all`, and declarations containing `access constant` can show `access-constant`, on the owning type/object/formal symbol.  The mode keywords remain metadata only: they do not create Outline rows, do not affect scope ownership, and do not become semantic identifiers.


### Phase 579 pass 223: class-wide subtype-mark metadata

The parser-owned Outline model now retains Ada class-wide subtype marks (`T'Class`) as bounded declaration metadata. Affected type/object/callable declarations can show `class-wide` detail on the owning symbol. The attribute designator remains non-declarative: it does not create an Outline row, open a scope, or become a semantic identifier.


Pass 224 parser completeness note: Ada private extension forms such as `type T is new Parent with private;` are retained as bounded declaration metadata (`private-extension`) on the owning symbol. The parser does not infer completion legality or expose `with private` syntax as separate symbols.

Pass 225 parser completeness note: Ada named-number declarations such as `Limit : constant := 10;` are retained as bounded declaration metadata (`named-number`) on the owning constant symbol. Typed constants remain ordinary constant declarations and are not marked as named numbers; initializer expressions remain non-declarative and do not create Outline rows or semantic symbols.

### Pass 226: null subprogram and expression-function metadata

The Ada declaration parser retains bounded callable body-shape metadata for null procedures and expression functions. Outline details may show `null-subprogram` or `expression-function` on the owning callable row. The null body or expression body does not create additional rows and does not contribute declaration symbols.

### Pass 227: null-record metadata

The Ada declaration parser retains bounded null-record metadata on the owning type row. Outline details may show `null-record` for compact null records and null record extensions. The empty record body does not create synthetic component rows or additional scopes.

### Pass 228: discriminant part metadata

The Ada declaration parser retains bounded discriminant-part awareness on the owning type declaration. A declaration such as `type Node (Kind : Node_Kind := Leaf) is record ...` can show `discriminant-part` in Outline details. This is metadata only: discriminant expressions and constraints are not emitted as extra Outline rows, and callable/access profiles are not treated as discriminant parts.

## Pass 229 body-stub metadata

The Ada declaration parser now retains bounded body-stub awareness on the owning declaration. Forms such as `procedure Deferred is separate;` and `function Later return Boolean is separate;` can show `body-stub` in Outline details. This is metadata only: the body stub does not create a synthetic subunit row, does not open a normal body scope, and separate subunits beginning with `separate (...)` are still modeled separately rather than treated as body stubs.


Phase 579 pass 230: the parser-retained overriding indicators are projected into Outline detail metadata as `overriding` or `not-overriding` on callable declarations. They do not create standalone rows or alter scope ownership.

## Pass 231 deferred-constant metadata

The Ada declaration parser now retains bounded deferred-constant awareness on the owning constant declaration. Forms such as `Value : constant Element;` can show `deferred-constant` in Outline details. This is metadata only: the parser does not infer the completing declaration, does not evaluate visibility legality, and does not learn subtype or completion expressions as standalone Outline rows.


Pass 232: the Ada declaration parser retains bounded subtype/discriminant/index constraint metadata on owning declarations. Constraint expressions, bounds, and generic actual lists remain non-declarative and do not create Outline rows or semantic symbols.

## Pass 233 child-unit metadata

The Ada declaration parser now retains bounded child library-unit awareness on parser-owned package and subprogram declarations whose defining unit name is selected, such as `Parent.Child`, `Parent.Run`, or `package body Parent.Body_Child, or private package Parent.Private_Child`. This is Outline/detail metadata only: parent-name segments are not learned as separate declarations, no cross-file completion or legality inference is attempted, and scope/index validation remains conservative.

Pass 234: parser-owned abstract declaration metadata is projected into Outline detail text as `abstract`; it remains metadata on the owning declaration and does not create duplicate rows or perform legality analysis.

## Pass 235 access-protected metadata

Pass 235 separates protected access-to-subprogram awareness from general access-subprogram metadata. Declarations such as `access protected procedure` and `access protected function` now retain `access-protected` detail metadata on the owning type/object/profile symbol without creating rows for anonymous profile components or treating `protected` as a semantic identifier.

## Pass 236 task/protected interface metadata

Pass 236 adds bounded Ada interface-kind metadata for `task interface` and `protected interface` declarations. The parser retains these qualifiers as declaration metadata (`task-interface` and `protected-interface`) on the owning type or generic formal type symbol. They do not create standalone Outline rows, open scopes, or introduce `task`/`protected` keyword symbols.

Phase 579 pass 237 note: the Ada parser now retains bounded `task type` and `protected type` declaration-form metadata separately from single task/protected declarations. Outline details may show `task-type` or `protected-type`; the keywords remain non-symbol metadata and do not affect scope legality analysis.

### Pass 238: generic actual-part metadata

Pass 238 adds bounded Ada generic-instantiation actual-part metadata. Instantiations such as `package Int_Vectors is new Vectors (Integer);` can show `generic-actuals` on the owning instantiation row. Actual expressions and subtype marks remain non-declarative: they do not create Outline rows, semantic symbols, scope changes, or compiler-grade generic matching.

### Phase 579 pass 239 split aspect clauses

Split Ada aspect specifications are now retained as parser-owned declaration metadata. When a declaration header is followed by a `with ...` aspect continuation, the shared Ada declaration parser stamps `Has_Aspect_Specification` on the owning language-model symbol instead of treating the continuation as a context clause or learning aspect identifiers such as `Pre`/`Post` as declarations. This keeps Outline detail projection conservative for multi-line contracts while preserving the existing no-rendering-side-parsing and stale-analysis constraints.

Phase 579 pass 240 note: the Ada language model now retains bounded parser-owned statement awareness metadata for executable constructs encountered while parsing bodies.  The parser recognizes sanitized `if`, `case`, plain/while/for loops, `declare`/`begin` blocks, `return`, `raise`, `goto`, `exit`, `delay`, `select`, `accept`, `requeue`, `abort`, `null`, assignment, and conservative call statements without creating Outline rows for them.  Record variant parts remain declaration metadata and are not misclassified as executable `case` statements.  This improves parser completeness for body syntax while preserving Outline as a declaration/navigation projection rather than a statement tree viewer.

Phase 579 pass 241 note: statement awareness now retains additional control-flow alternatives and handled-sequence markers.  The parser records sanitized `elsif`, `else`, executable `when` alternatives, `exception` sections, and `terminate` select alternatives in addition to the pass 240 statement set.  Record variant choices remain excluded from executable `when` metadata, so record shape parsing does not pollute statement counts or Outline rows.

Phase 579 pass 242 note: the parser-owned statement awareness layer now recognizes leading Ada statement labels (`<<Label>>`).  Labels are counted as statement metadata and then stripped for same-line statement classification, so `<<Retry>> Work;` remains a labelled call statement rather than becoming an unknown declaration-like line.  Labels are not emitted as Outline rows.

Phase 579 pass 243 note: statement awareness now recognizes Ada named block and loop statement prefixes (`Name : declare`, `Name : begin`, `Name : loop`, and `Name : for/while ... loop`).  The parser records named-block/named-loop metadata, strips the statement identifier before classifying the underlying statement kind, and keeps the metadata out of Outline rows so object declarations containing colons are not misread as statements.

Phase 579 pass 244 note: statement awareness now records select-alternative separators more explicitly.  The parser keeps `or` alternatives and asynchronous-select `then abort` alternatives as bounded statement metadata, while still avoiding Outline rows or semantic declaration symbols for those tasking-control constructs.

Phase 579 pass 245 note: the parser-owned statement awareness layer now retains unambiguous structured statement terminators (`end if`, executable `end case`, `end loop`, and `end select`) as language-model metadata.  This improves body-syntax awareness for validation/fingerprinting while preserving Outline as a declaration/navigation projection; statement terminators are not shown as Outline rows.

Phase 579 pass 246 note: the Ada parser now records extended return statement awareness, including `end return` terminators, as language-model metadata.  This improves parser coverage and fingerprints for executable bodies while keeping Outline declaration rows restricted to declarations and validated navigation targets.

Phase 579 pass 247 note: the Ada parser now records accept statements with handled `do` parts plus relative `delay` and `delay until` forms as bounded statement metadata. These tasking statement forms do not create Outline declaration rows.

Phase 579 pass 248 note: the parser-owned statement-awareness layer now records conditional `exit ... when`, `raise ... with`, and `requeue ... with abort` forms as body-syntax metadata. These forms improve analysis fingerprints and parser coverage while remaining outside the Outline declaration/navigation row projection.

Phase 579 pass 249 note: the parser-owned statement-awareness layer now recognizes Ada code statements as statement metadata.  Code statements improve parser coverage and fingerprints but remain outside the declaration Outline projection and do not create navigation rows.

Phase 579 pass 250 note: parser-owned statement awareness now recognizes procedure-call statements with explicit argument lists, including named associations using `=>`.  This closes the previous conservative gap where call statements containing associations were skipped to avoid confusing them with code statements.  Qualified-expression code statements remain separately classified, and calls with arguments still do not create Outline rows.

Phase 579 pass 251 note: stacked Ada statement labels are now counted individually by parser-owned statement metadata.  The labels are stripped before underlying statement classification, but they remain outside the Outline declaration projection and never become navigation rows.

Phase 579 pass 252: statement-awareness metadata now preserves selected-name call shape.  Calls such as `Console.Flush;` and `Worker.Start (Priority => High);` remain ordinary call statements, but additionally carry `Statement_Call_Selected_Name` metadata so the parser fingerprint distinguishes selected calls from simple-name calls without creating Outline rows or semantic declaration symbols.

Phase 579 pass 253: parser-owned statement metadata now distinguishes executable null alternatives such as `when Choice => null;` from record variant alternatives.  This metadata is fingerprinted for analysis freshness but is not projected as Outline rows, scopes, symbols, or navigation targets.

Phase 579 pass 254: parser-backed statement awareness now records simple executable actions after alternative arrows as metadata only.  These alternative-action shapes improve parser fingerprints but do not produce Outline rows or navigation targets.

Phase 579 pass 255: parser-backed statement awareness now records additional simple control/tasking actions after alternative arrows (`exit`, `goto`, `delay`, `requeue`, and `abort`) as metadata only.  These action shapes improve analysis fingerprints while remaining invisible to Outline rows and navigation targets.

Phase 579 pass 256: executable alternative-action metadata now preserves the same bounded call/code shape used for ordinary statements.  Calls after `=>` can retain argument-list, named-association, and selected-name metadata, while qualified-expression code actions are counted as `Statement_Alternative_Code` plus `Statement_Code` and are deliberately not flattened into call metadata.

Phase 579 pass 257 note: parser-owned statement awareness now records compact same-line statement sequences, such as `if Ready then null; end if;`, `while Ready loop null; end loop;`, and compact `select ... else ... end select;` forms.  The parser stamps compact-sequence, inline-null-action, and inline terminator metadata while keeping Outline rows declaration-only and avoiding statement symbols.

Phase 579 pass 258: parser-owned statement awareness now distinguishes Ada `for` loop iteration schemes (`Statement_For_In_Loop`, `Statement_For_Of_Loop`, and `Statement_For_Reverse_Loop`).  This is analysis metadata for parser completeness and fingerprints only; it does not create Outline rows, scopes, declarations, or navigation targets.

Phase 579 pass 259: parser-owned statement awareness now distinguishes named loop terminators.  Forms such as `end loop Outer;` are retained as `Statement_End_Named_Loop` in addition to the base `Statement_End_Loop` metadata, but they remain parser/fingerprint metadata only and do not produce Outline rows or navigation targets.

Phase 579 pass 260: parser-owned statement awareness now distinguishes ordinary return-expression statements from bare and extended returns.  `return Value;` and executable alternative actions such as `when C => return Value;` update language-model statement metadata only; they do not create Outline rows or navigation targets.

Phase 579 pass 261: parser-owned statement awareness now preserves assignment target shape for selected-component, indexed-component, and slice assignment statements.  The metadata improves parser fingerprints and statement-syntax coverage, but assignments remain outside the declaration Outline projection and never create navigation rows.

## Pass 262 statement-awareness note

The Ada parser retains bounded abort-statement target-shape metadata for the shared language model.  Selected-name abort targets and comma-separated abort target lists affect parser fingerprints and statement counts only.  They do not create Outline rows, semantic declaration symbols, scopes, or navigation targets.

## Pass 263 statement-awareness note

The Ada parser now retains bounded requeue-statement target-shape metadata for the shared language model.  Selected requeue targets and entry-family/argument target forms affect parser fingerprints and statement counts only.  They do not create Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets.

## Pass 264 statement-awareness note

The Ada parser now retains bounded accept-statement shape metadata for parameter profiles and entry-family/index forms.  This improves parser fingerprints and tasking statement coverage, but accept profile names, parameter names, and entry-family indexes are not projected as Outline rows or navigation targets.

## Pass 265 statement-awareness note

The Ada parser now retains bounded explicit-access-dereference statement metadata.  Access-to-subprogram calls and access-object assignment targets using `.all` improve parser fingerprints and Ada statement-shape coverage, but they are not projected as Outline rows or navigation targets.

Pass 266 note: the Ada declaration parser also records entry-family shaped call statement metadata (`Statement_Call_Entry_Family_Index`) for forms such as `Server.Family (Index) (Item);`.  This supports parser completeness auditing only; Outline rows remain declaration/navigation rows and do not expose executable call statements.

Phase 579 pass 267 note: the Ada parser now records bounded raise-form metadata for bare reraises, named exception raises, and message raises.  These statement shapes improve parser completeness/fingerprints but are not projected as Outline rows or navigation targets.

Pass 268 note: the Ada declaration parser also records named-loop exit statement metadata (`Statement_Exit_Named_Loop`) for forms such as `exit Outer;` and `exit Outer when Done;`.  This is parser completeness metadata only; Outline rows remain declaration/navigation rows and do not expose executable exit statements or loop-name targets.

Pass 269 note: selective-accept delay alternatives are recognized by the Ada parser as bounded statement metadata (`Statement_Delay_Alternative`, with relative/until refinements).  This improves parser completeness and fingerprints only; Outline remains declaration/navigation oriented and does not expose delay alternatives as rows.

## Phase 579 pass 270

The Ada parser now records same-line selective-accept alternatives as bounded statement metadata.  `or accept ...` lines retain explicit accept-alternative metadata and preserve existing accept profile/body/entry-family shape metadata where visible.  This metadata remains outside Outline rows: accept alternatives do not become declarations, scopes, or navigation targets.

Phase 579 pass 271 note: parser-owned statement awareness now records same-line asynchronous-select `then abort` actions.  The parser keeps `then abort Cleanup (...);` as bounded metadata (`Statement_Then_Abort_Action` plus the embedded action shape) while Outline remains a declaration/navigation projection and does not display the action as a row.

Phase 579 pass 272 note: parser-owned statement awareness now records compact same-line `if ... then` action metadata.  The parser keeps visible then-actions such as `if Ready then Worker.Deliver (...); end if;` as bounded statement metadata (`Statement_Then_Action` plus embedded simple action shape), while Outline remains a declaration/navigation projection and does not display the action as a row.

Phase 579 pass 273 note: parser-owned statement awareness now records compact same-line `if ... else` action metadata.  The parser keeps visible else-actions such as `if Ready then null; else Worker.Deliver (...); end if;` as bounded statement metadata (`Statement_Else_Action` plus embedded simple action shape), while Outline remains a declaration/navigation projection and does not display the action as a row.

Phase 579 pass 274 note: parser-owned statement awareness now records compact same-line `if ... elsif ... then` action metadata. The parser keeps visible elsif-actions such as `if Ready then null; elsif Retry then Worker.Deliver (...); end if;` as bounded statement metadata (`Statement_Elsif_Action` plus embedded simple action shape), while Outline remains a declaration/navigation projection and does not display the action as a row.

Phase 579 pass 275 note: parser-owned statement awareness now records compact same-line loop-body action metadata. The parser keeps visible loop-body actions such as `while Ready loop Worker.Deliver (...); end loop;` as bounded statement metadata (`Statement_Loop_Action` plus embedded simple action shape), while Outline remains a declaration/navigation projection and does not display the action as a row.

## Pass 276 statement-awareness note

Phase 579 pass 276 note: parser-owned statement awareness now records compact same-line case alternative action metadata. The Outline projection remains declaration/navigation-only; compact executable alternatives such as `case Mode is when A => Do_It; when others => null; end case;` do not become Outline rows.

## Pass 277 statement-awareness note

Phase 579 pass 277 note: parser-owned statement awareness now records compact same-line exception handler action metadata. The Outline projection remains declaration/navigation-only; compact handlers such as `exception when Constraint_Error => Recover; when others => null;` do not become Outline rows, scopes, symbols, declarations, or navigation targets.

Phase 579 pass 278 note: parser-owned statement awareness now records compact same-line handled-sequence `begin` actions. The parser keeps visible actions such as `begin Worker.Deliver (...); end P;` as bounded metadata (`Statement_Begin_Action` plus embedded simple action shape), while Outline remains a declaration/navigation projection and does not display the action as a row.

## Pass 279 statement-awareness note

Phase 579 pass 279 note: parser-owned statement awareness now records visible `goto` label-target shape as bounded metadata. The Outline projection remains declaration/navigation-only; `goto Retry;` and `when A => goto Done;` do not create Outline rows or label navigation targets.

Phase 579 pass 280 note: Outline continues to suppress executable statements, but the parser-owned language model now fingerprints compact conditional entry-call select statements with `Statement_Select_Entry_Call`. The entry target is not exposed as an Outline row or navigation target.

Phase 579 pass 281 note: Outline still suppresses executable statements, but the parser-owned language model now fingerprints compact conditional entry-call select else fallbacks with `Statement_Select_Else_Action`. The fallback action is retained only as statement metadata and is not exposed as an Outline row or navigation target.


Pass 282 parser update: compact timed entry-call select statements now retain select-delay fallback metadata (`Statement_Select_Delay_Fallback`, including relative and `delay until` forms) without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.

Pass 283 parser update: compact asynchronous select statements now retain select-level then-abort fallback metadata (`Statement_Select_Then_Abort_Fallback`) while preserving the embedded abortable action shape. This remains bounded parser-owned statement awareness only and does not create Outline rows, semantic symbols, scopes, declarations, or navigation targets.

Pass 285 parser update: compact selective-accept terminate fallbacks and compact asynchronous-select abortable triggering calls now retain explicit parser-owned metadata (`Statement_Select_Terminate_Fallback` and `Statement_Select_Abortable_Call`) without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.

Phase 579 pass 286 note: parser-owned statement awareness now records compact same-line declare-block actions. The parser keeps visible forms such as `declare Local : Natural := 0; begin Worker.Deliver (...); end;` as bounded metadata (`Statement_Declare_Action` plus embedded begin-action shape), while Outline remains a declaration/navigation projection and does not display the action as a row.

Phase 579 pass 287: parser-owned statement awareness now records anonymous block terminators.  Bare `end;` from block/declare-block syntax contributes `Statement_End_Block` fingerprint metadata so compact and multiline block shapes remain visible to the language model.  Named `end Name;` is still not promoted to statement metadata because it overlaps package/subprogram/body terminators in the lightweight declaration parser.  No Outline rows or navigation targets are created from this syntax.


Pass 288 update: the Ada declaration parser now preserves attribute-reference procedure-call statement shape as bounded language-model metadata. Calls such as `Buffer_Type'Write (Stream, Buffer);` and `Buffer_Type'Read (Stream, Buffer);` remain ordinary call statements, retain argument metadata, and additionally stamp `Statement_Call_Attribute_Name`. Qualified-expression code statements remain separate from call metadata, and attribute names are not projected into Outline rows, semantic symbols, scopes, or navigation targets.

Pass 289 update: the Ada declaration parser now preserves pragma statements that appear inside executable statement sequences or executable alternatives as bounded language-model metadata. `pragma Assert (Ready);` and `when A => pragma Assert (Ready);` stamp `Statement_Pragma`, pragmas with parenthesized argument lists also stamp `Statement_Pragma_With_Arguments`, and pragma names/arguments are not projected into Outline rows, semantic symbols, scopes, declarations, or navigation targets.

Pass 290 update: the Ada declaration parser now distinguishes pragma statements used as executable alternative actions. `when A => pragma Assert (Ready);` still stamps `Statement_Pragma` and `Statement_Pragma_With_Arguments` where applicable, and now also stamps `Statement_Alternative_Pragma`. This remains parser-owned statement metadata only: pragma names and arguments are not projected into Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets.

Phase 579 pass 291 note: Outline still suppresses executable statements, but the parser-owned language model now fingerprints compact conditional entry-call select `else` fallback action classes. Null, assignment, return, raise, call, and code fallbacks remain statement metadata only and are not exposed as Outline rows or navigation targets.

Phase 579 pass 292 note: Outline still suppresses executable statements, including compact conditional entry-call select `else` fallback control/tasking actions. The parser-owned language model now fingerprints visible fallback forms such as exit, goto, delay, requeue, abort, and pragma statements as statement metadata only; none of these become Outline rows or navigation targets.

Phase 579 pass 293 note: Outline still suppresses executable statements, including refined compact conditional entry-call select `else` fallback subforms. The parser-owned language model now fingerprints relative versus `delay until` fallback delays, requeue-with-abort fallbacks, and pragma fallbacks with arguments as statement metadata only; none of these become Outline rows or navigation targets.
Pass 295 parser update: compact timed entry-call select delay fallbacks now retain the simple fallback body action shape (`Statement_Select_Delay_Fallback_Action`, including null, call, assignment, return, raise, and code-action forms) without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.
Pass 296 parser update: compact timed entry-call select delay fallback bodies now retain additional control/tasking/pragma action shape metadata (`Statement_Select_Delay_Fallback_Exit`, `..._Goto`, `..._Delay`, `..._Requeue`, `..._Abort`, `..._Pragma`, and `..._Pragma_With_Arguments`) without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.
Pass 297 parser update: compact timed entry-call select delay fallback bodies now refine nested delay and requeue action metadata (`Statement_Select_Delay_Fallback_Delay_Until`, `..._Delay_Relative`, and `..._Requeue_With_Abort`) without creating Outline rows, semantic symbols, scopes, declarations, or navigation targets.

Pass 298 parser update: compact timed entry-call select delay fallback call bodies now preserve selected-name, argument-list, named-association, access-dereference, and entry-family call-shape metadata. This remains parser-owned statement fingerprinting only; Outline rows and navigation targets are not created from fallback call syntax.

## Pass 299 syntax tree foundation

Outline remains declaration-driven, but the Ada parser now also attaches a parser-owned `Editor.Ada_Syntax_Tree` to the shared language analysis.  The tree currently stores deterministic source-shape nodes under a compilation-unit root and is not projected directly as Outline rows.  This keeps Outline navigation stable while introducing the syntax-tree ownership layer required for future full Ada statement, expression, name, aspect, pragma, and representation-clause parsing.

Phase 579 pass 300: completeness pass for the Ada syntax-tree foundation.  `Editor.Ada_Syntax_Tree.Parse` now assigns nested parent/child ownership using a bounded source-shape scope stack instead of attaching every parsed node directly to the compilation-unit root.  Package bodies own nested subprogram bodies, subprogram bodies own begin/statement/end nodes, and `end` nodes pop the parser-owned tree stack.  This is still a conservative syntax-tree foundation, not a full Ada grammar AST, and it does not create Outline rows, semantic symbols, scopes, declarations, or navigation targets from statement syntax.

## Pass 301 syntax-tree alternative ownership

The parser-owned Ada syntax tree now retains explicit source-shape nodes for `elsif`, `else`, `when`, and `exception` sections. These nodes own their nested statement-shape children and are siblings under the enclosing `if`, `case`, `select`, or handled sequence where the bounded source-shape parser can identify that relationship. Outline extraction still derives rows from declaration symbols, not executable alternatives, so this pass does not add statement rows or navigation targets.

### Phase 579 pass 302 — expression/name children in the syntax tree

The Outline-backed Ada language analysis now retains expression/name syntax-tree children under declaration and statement source-shape nodes. This lets the internal tree preserve names, selected names, attributes, calls, slices, ranges, associations, operators, conditional/case/quantified expressions, and qualified expressions without turning them into Outline rows or semantic declarations. The feature remains bounded and snapshot-owned; malformed or unsupported expression fragments degrade to conservative expression/name nodes.

### Pass 303 expression/name syntax-tree completeness

The Ada syntax tree now retains additional expression/name children under the source-shape nodes used by Outline and semantic colouring.  Membership tests, short-circuit operators, unary expressions, parenthesized expressions, explicit dereferences, allocators, and named/positional associations are represented as bounded syntax-tree nodes.  This improves the internal parser foundation without turning Outline into a compiler frontend or adding render-side parsing.


### Phase 579 pass 304 — control-statement syntax-tree coverage

Pass 304 extends the parser-owned `Editor.Ada_Syntax_Tree` source-shape layer with explicit control/tasking statement nodes for labels, `delay`, `exit`, `goto`, and `requeue` statements.  These nodes now receive bounded expression/name children for loop labels, delay times, exit conditions, requeue targets, goto labels, and raise-with message operands where visible.  The pass also removes a duplicate type/subtype case arm in the syntax-tree detail attachment path so the node model remains compile-clean.  This is still deterministic editor metadata; it does not create Outline rows, semantic symbols, scopes, declarations, navigation targets, or GNAT-equivalent legality analysis from executable statement syntax.

Phase 579 pass 305 note: executable statement-awareness is now represented in the parser-owned syntax tree as structured statement nodes for compact action sequences, alternatives, targets, conditions, selectors, arguments, modes, and raise-with messages.  Outline extraction still ignores these executable statement nodes for declaration rows; they exist so later language-model work can consume structured statement shape without duplicating line-level metadata parsing.

### Phase 579 pass 306 statement syntax tree detail

The shared Ada syntax tree no longer represents ordinary statement metadata by inserting duplicate same-kind child statements. Statement target/action/condition detail is owned directly by the parsed statement node, while compact embedded actions remain nested statement nodes under statement-sequence nodes. Outline extraction remains declaration-focused and does not create outline rows for these executable statement details.

### Phase 579 pass 307 compact embedded control-flow nodes

The parser-owned syntax tree now preserves compact embedded control-flow actions as structured statement nodes. Inline executable `if`, `case`, loop, block, select, alternative, and exception-handler tails under statement sequences no longer collapse to generic call-statement nodes. Outline remains a declaration/navigation projection and still does not display executable statement rows, but its shared parser foundation now carries more complete statement-shape metadata for validation and future IDE features.

Phase 579 pass 308 note: compact asynchronous select statements now retain both triggering and abortable statement sequences in `Editor.Ada_Syntax_Tree`. Outline still projects declarations only, but stale-row validation and future IDE features can now consume structured select then-abort statement shape without reparsing line text.

Phase 579 pass 309 note: parser-owned syntax-tree metadata now includes explicit `Node_Select_Alternative` nodes for `or` alternatives in selective accept statements. Outline remains declaration-focused and does not render executable select alternatives, but the shared parser tree now preserves their ownership and child statement shape for validation and future navigation-adjacent IDE features.
Pass 309 also prevents same-line compact select constructs from leaving stale syntax-tree scopes that could incorrectly own following `end` nodes. This is still parser metadata only, but it keeps Outline's declaration projection anchored to the correct enclosing subprogram/package nodes.

Phase 579 pass 310 note: line-level select alternatives now match the compact select tree shape. Standalone asynchronous-select `then abort`, selective-accept `else`, and `terminate` alternatives are retained as structured select-alternative syntax-tree metadata. Outline remains declaration-focused and does not render executable select alternatives, but parser-owned validation and future IDE features can consume the complete select-alternative shape without reparsing source lines.

Phase 579 pass 311 note: parser-owned syntax-tree metadata now distinguishes exception handlers from case `when` alternatives. `when ... =>` lines inside an exception section are retained as `Node_Exception_Handler` children of `Node_Exception_Section`, with handler choice metadata and structured body statements. Outline remains declaration-focused and does not render executable exception handlers as declaration rows.


Pass 312 note: parser-owned statement structure now preserves select entry-call alternatives separately from generic calls, improving navigation metadata for conditional/timed select shapes.

### Pass 313 metadata structure

The outline language-model backend now receives structured syntax-tree nodes for Ada aspect specifications, pragma arguments, representation clauses, and generic actual associations. Outline labels may still display conservative summaries, but the backing parser tree preserves the relevant target/item/formal/actual child nodes for later richer navigation and indexing.

Pass 314 representation-clause structure: record representation clauses are now parsed as bounded syntax-tree scopes. Component clauses inside `for T use record ... end record;` are retained under the representation clause as structured component-clause nodes with target and range metadata. They remain non-outline metadata unless a later navigation feature explicitly projects them.

### Pass 315 structured metadata association children

The parser-owned syntax tree now splits metadata associations below aspects, pragma arguments, and generic actual parts into domain-specific child nodes. Aspect associations retain separate aspect-name and aspect-value nodes, generic actual associations retain formal-name and actual-value nodes, and named pragma arguments retain explicit pragma-argument association nodes. Split aspect clauses and split generic actual parts are attached to the preceding declaration or instantiation when the snapshot context is still valid; they remain metadata only and do not create Outline rows, semantic symbols, or navigation targets.


Pass 316 note: the Ada syntax-tree declaration grammar now represents the remaining Ada declaration families structurally, including generic formal declarations, incomplete types, private extensions, named numbers, task/protected declarations and bodies, entries, record components, discriminants, private parts, and body stubs. Declaration nodes expose shared declaration-name/subtype/default/mode child metadata for Outline and semantic-colouring consumers.

### Pass 317 declaration grammar refinement

Outline input from the Ada language model now receives distinct syntax-tree nodes for abstract subprogram declarations, null procedure declarations, and expression function declarations.  The syntax tree also retains declaration-profile and function-result child nodes so navigation labels and overload summaries can be derived from structured declaration data rather than from ad-hoc text splitting.

### Pass 318 declaration grammar completeness

Outline continues to project declarations conservatively from the shared Ada language model, but the backing parser-owned syntax tree now records enumeration literals, record variants, entry bodies, entry body stubs, and renaming targets as structured declaration-shape nodes. These nodes improve future navigation/index metadata without turning representation, variant, or executable body internals into ordinary Outline rows.

### Pass 319 declaration grammar completeness

The syntax-tree layer now distinguishes typed constants, deferred constants, named numbers, and executable assignments before Outline projection. Deferred constants and initialized typed constants are first-class declaration nodes with declaration-mode metadata, while named numbers remain distinct and ordinary `:=` statements remain statement nodes.

Pass 320 note: Outline's parser-owned syntax tree now keeps Ada concurrent declaration forms distinct. Single task/protected declarations and task/protected type declarations are separate node families, with explicit declaration-mode metadata, before Outline projection. This preserves source spelling and avoids flattening `task Worker` and `task type Worker` or `protected Lock` and `protected type Lock` into the same declaration shape.

### pass 321 grammar-aware syntax-tree recovery

Phase 579 pass 321 adds grammar-aware recovery nodes to `Editor.Ada_Syntax_Tree`.  When malformed Ada text crosses a known grammar boundary, the syntax tree now records explicit recovery structure instead of silently attaching the remainder of the file under the wrong owner.  Mismatched `end` lines synchronize against the nearest compatible open construct, missing inner endings are represented as `Node_Missing_End`, synchronization sites are represented as `Node_Recovery_Point`, unexpected endings are represented as `Node_Unexpected_End`, and orphan alternatives such as an `else` without an owning `if` are represented as `Node_Mismatched_End`.  Outline projection remains conservative: recovery nodes are parser diagnostics/structure, not declaration symbols or navigation targets.

Phase 579 pass 322 extends grammar-aware recovery to named end targets.  Named `end` lines retain explicit end-target detail nodes, and a compatible end boundary with the wrong source name produces a structured mismatch diagnostic with expected/actual target children.  These recovery diagnostics remain parser-owned and are not Outline declaration rows or cross-file navigation targets.

Pass 323 note: grammar-aware recovery now distinguishes true missing explicit Ada endings from implicit closure of handled statement parts at enclosing body/block end boundaries. The syntax tree exposes Node_Implicit_End for this bounded parser-owned recovery case, while preserving Node_Missing_End for malformed nesting.

Pass 324 note: grammar-aware recovery now closes generic formal parts at the grammar boundary where the generic package/subprogram unit starts.  The syntax tree emits `Node_Implicit_End` for this parser-owned closure, keeps formal declarations under `Node_Generic_Declaration`, and avoids false end-of-file `Node_Missing_End` diagnostics for well-formed generic declarations.

Pass 325 note: syntax-tree recovery now retains expected-token diagnostics for malformed Ada headers.  These parser-owned `Node_Recovery_Point`/`Node_Expected_Token` nodes remain non-outline metadata and do not become navigation rows.

Pass 326 note: malformed Ada alternatives now recover structurally. Missing `=>` in case alternatives, record variants, or exception handlers is represented as parser-owned recovery metadata and does not create Outline rows. Variant parts synchronize at `end case;` and the enclosing record still owns the record declaration/navigation row.

Pass 327 note: malformed declaration recovery is parser-owned syntax-tree metadata only. Missing `is`/`;` diagnostics stay in `Node_Recovery_Point`/`Node_Expected_Token` nodes and do not become Outline rows, while the recovered declaration node remains available for conservative navigation only when its normal stale-snapshot checks pass.

Pass 328 note: grammar-aware recovery now covers malformed delimited metadata lists and end boundaries. Unterminated pragmas, aspect specifications, representation clauses, and generic actual parts retain their structural nodes and receive parser-owned expected-token diagnostics. `end` boundaries without semicolons likewise keep `Node_End` structure and expected-`;` recovery metadata. These diagnostics do not become Outline rows or navigation targets.

Pass 329 note: implicit-begin recovery is parser-owned syntax-tree metadata only. A missing `begin` before executable statements in a body creates `Node_Implicit_Begin` plus expected-token diagnostics, but it does not create Outline rows or bypass stale snapshot checks.

Pass330 note: the Ada syntax-tree layer now performs grammar-aware recovery for malformed subprogram and concurrent declaration headers. It preserves the declaration node shape for malformed subprogram/task/protected declarations and attaches expected-token recovery metadata for missing `is` or missing `;` boundaries.

Pass331 note: grammar-aware recovery now detects declarations that appear after a handled-sequence `begin`.  Such late declarations are represented by parser-owned `Node_Unexpected_Declaration` diagnostics with an expected `declare` detail.  The recovered declaration remains syntax-tree structure only and does not become a new Outline row unless normal declaration extraction independently accepts a valid declaration in a valid declaration part.

Pass332 note: EOF recovery for handled statement parts remains parser-owned metadata.  `Node_Implicit_End` entries created at end-of-file do not become Outline rows, while the enclosing body still receives missing-end recovery diagnostics and normal stale-snapshot validation remains unchanged.

Pass333 note: private sections are now scope-owning syntax-tree nodes. Declarations following `private` in package/task/protected specifications are owned by `Node_Private_Part`, and the section is closed with parser-owned `Node_Implicit_End` metadata at the enclosing `end`. This improves Outline/source-shape fidelity without making private-part recovery nodes into navigation rows.


### Pass 334 — token-cursor Ada grammar layer

Added `Editor.Ada_Token_Cursor`, a UI-free token stream and cursor grammar package. The syntax tree now records a bounded `Node_Token_Cursor_Grammar` subtree with `Node_Grammar_Production` events for compilation units, declarations, statements, association lists, and expression-precedence productions. The previous structured syntax-tree path remains as a compatibility projection while the new grammar layer becomes the parser substrate for further IDE-grade Outline and semantic-colouring work.

Pass 335 note: the internal Ada token-cursor grammar now retains detailed declaration and expression production events for parameter profiles, generic formals, discriminants, enumeration literals, records/components/variants, selected names, indexed components, attribute references, and conditional/case/quantified expression forms. These productions are parser-owned metadata for Outline/semantic-colouring integration and remain bounded/conservative rather than compiler legality checks.

Pass 336 note: the internal Ada token-cursor grammar now retains explicit statement production events for handled statement sequences, elsif/else branches, case/select alternatives, loop-parameter specifications, extended returns, null/exit/goto/delay/requeue/abort statements, exception sections, and entry/call actual parts. The events are parser-owned metadata for later Outline/semantic-colouring integration and remain bounded/conservative rather than GNAT-equivalent legality checks.


### Pass 337 parser note

The shared Ada token-cursor grammar now retains type-definition and subtype-constraint productions for array, access, derived, private, interface, integer, modular, floating point, and fixed point forms. Outline remains projected from the language model, but the parser substrate now exposes these productions for richer future projection.

### Pass338 token-cursor metadata grammar update

The Ada token-cursor grammar now retains structured productions for pragma argument associations, aspect associations, generic actual parts/associations, record representation clauses, and representation component clauses. This keeps metadata-heavy Ada declarations from being treated as opaque declaration tails in the grammar layer.



### Pass 339 note

The shared token-cursor grammar now retains context/use clauses and labels structurally. Outline remains declaration-oriented, but the parser substrate no longer treats these Ada grammar forms as skipped text.

### Pass 340 — token-cursor separate/body-stub grammar

The shared Ada token-cursor grammar now exposes separate subunits and body stubs as structured productions. Outline remains projected from the language model, but the parser substrate now has explicit production events for separate subunit parent names and package/subprogram/task/protected/entry body stubs.


Pass 341 note: the token-cursor Ada grammar now retains task definitions, protected definitions, entry-family definitions, and entry-body barriers as first-class productions. Task/protected definitions with nested entries or protected operations are no longer skipped as a single semicolon-delimited header in the token-cursor grammar layer.

### Pass 342 — token-cursor expression grammar completeness

The shared Ada token-cursor grammar now exposes allocator expressions, raise expressions, membership choice lists, short-circuit operators, delta aggregates, reduction attributes, and unary-expression productions. Outline remains declaration-oriented, but the parser substrate now has production-level expression detail for later navigation and diagnostics.

Pass 343 update: the Ada token-cursor grammar now distinguishes generic formal declaration families, including formal objects, formal private/derived/discrete/scalar/composite/access/interface types, formal subprograms, and formal packages with actual parts.

Pass 344 parser note: the token-cursor Ada grammar now retains subprogram modifier/declaration distinctions for overriding indicators, abstract subprogram declarations, null procedures, expression functions, and defaulted formal subprograms. These productions are parser metadata available to the language model and do not imply compiler-grade dispatch or overload legality checking.


Pass 345 note: the token-cursor Ada grammar now records defining names explicitly, including quoted operator symbols for operator functions and generic formal operator subprograms.


Pass 346 extends the shared Ada token-cursor grammar with modified context-clause productions for limited/private with clauses. Outline consumers can keep treating these as context metadata while the grammar retains the modifier information for later indexing and navigation work.

### Pass 347 — representation-clause grammar detail

The shared Ada token-cursor grammar now distinguishes attribute definition clauses, enumeration representation clauses, address clauses, and record representation clauses. Outline remains declaration-oriented, but the parser substrate now preserves these representation forms for future metadata projection and navigation diagnostics.

### Syntax-tree projection into Outline symbols

The Ada declaration analysis now projects parser-owned syntax-tree declaration
nodes back into `Editor.Ada_Language_Model.Analysis_Result`.  Outline therefore
receives richer symbol kinds and metadata for constructs that were previously
retained only as syntax-tree detail, including record representation clauses,
variant record metadata, generic actual parts, body-stub metadata, and structured
record components discovered by the grammar tree.

Phase 579 pass 349 selected metadata target note: syntax-tree projection now resolves selected metadata targets through retained parent ownership metadata. A representation clause such as `for Inner.Rec use record ...` can mark the nested `Rec` symbol when the parser has retained the `Inner` parent chain. Dotted metadata targets still do not fall back to leaf-only matching; unresolved or ambiguous targets degrade conservatively.

### Pass 350 scoped selected-name lookup guard

Outline and navigation resolution now reject unresolved scoped selected-name queries before the ordinary lexical leaf walk. A query such as `Missing.Widget` from inside a scope containing an unrelated direct `Widget` no longer resolves to that leaf symbol. Exact selected declarations and valid prefix-owned children remain supported.


### Pass 351 — bounded record representation layout metadata

Record representation component clauses inside `for T use record ... end record;` are now projected from the parser-owned syntax tree into bounded language-model layout metadata. Each retained component clause records the target record symbol, the component name, the linked component symbol when resolvable, source range, source spelling for the storage unit and bit range, and parsed static decimal storage/bit values for simple numeric clauses. This is intentionally not GNAT-equivalent representation legality checking or full layout computation for arbitrary static expressions; unresolved or non-decimal expressions remain preserved as source text and degrade conservatively.

### Pass 352 — representation-layout completeness pass

Record representation component metadata is now independently budgeted. Exceeding the layout-entry budget marks analysis overflow and changes the language-model fingerprint so stale or truncated layout metadata cannot be mistaken for complete analysis. The interpreted static-value fields now support simple Ada integer literals with underscores and based notation, such as `16#10#` and `2#1_111#`. Named constants, attributes, and arbitrary unsupported static expressions remain preserved as source text only; a bounded numeric arithmetic subset is interpreted.

### Pass 353 — visibility-clause model rows

Outline remains declaration-oriented, but the shared Ada language model now retains concrete visibility clauses with source range and lexical scope. Context clauses still do not create outline rows for imported package names. The retained rows allow resolver/navigation consumers to reason about `use Pkg;` when the used package and child declarations are already present in the bounded analysis or project index. Unavailable, ambiguous, or unindexed visibility still degrades conservatively.

### Pass 354 — use-type visibility remains non-outline metadata

The shared Ada model now distinguishes package `use` visibility from `use type` visibility. `use type` clauses are retained as bounded visibility metadata for resolver and semantic-colouring consumers, but they do not create Outline rows and they do not expose type-owned child rows such as record components as navigable declarations in the enclosing scope. Primitive operator functions can be resolved through `use type` only when both the selected type and matching operator are present in the retained analysis.

### Pass 355 — selected nested package use-clause metadata

The shared resolver can now interpret retained `use Parent.Child;` clauses when `Parent` and its nested `Child` package are present in the bounded language model. Outline rows remain declaration-derived; the visibility clause does not create an imported-package row. Navigation and semantic consumers may use the clause only when the selected package target resolves through validated parent/child ownership, otherwise they degrade conservatively.

### Pass 356 — overload-selection resolver API

Outline/navigation consumers can now call `Editor.Ada_Symbol_Resolver.Resolve_Call_In_Scope` when they have a bounded call shape. The resolver filters retained callable overloads by actual count, positional/named actual type names, and optional expected result type while preserving ambiguous candidate sets. This improves overload disambiguation for parser-owned profiles without claiming compiler-equivalent overload legality, expression typing, defaulted formal handling, dispatching, or generic contract resolution.

### Pass 357 defaulted-formal overload filtering

Phase 579 pass 357 note: the shared Ada resolver now applies retained formal default metadata during conservative call overload selection. Outline/navigation consumers that provide a call-shape can match overloads with omitted trailing defaults or named actuals that skip defaulted formals, while candidates with omitted required formals remain rejected. The implementation does not evaluate default expressions and does not claim compiler-equivalent overload legality.

### Pass 358 expression-aware overload selection

Outline/navigation consumers now have an expression-aware overload-resolution entry point in the shared Ada symbol resolver.  `Resolve_Call_Expression_In_Scope` turns simple actual expressions and expected target expressions into conservative type-profile metadata before filtering overload sets.  This improves call-target disambiguation for retained in-buffer symbols without changing the Outline invariant that ambiguous, stale, or compiler-complex cases must degrade instead of guessing.

### Pass 359 expression-aware operator expressions

The shared resolver used by Outline/navigation can now infer bounded types for parenthesized expressions, signed numeric literals, and simple top-level operator expressions.  This improves overload-target filtering for call-like navigation while preserving the same conservative failure mode: unknown operands and ambiguous operator calls do not select a target.

### Pass 360 expression-aware unary and membership expressions

Outline/navigation consumers using the shared resolver now receive conservative type inference for unary `not`, unary `abs`, membership tests (`in` and `not in`), exponentiation, and concatenation.  These additions improve overload target filtering for call navigation while preserving the existing failure mode: unresolved operands do not create wildcard overload matches and ambiguous expressions still require callers/UI to handle multiple or absent candidates safely.

### Pass 361 expression-aware conditional expressions

Outline/navigation consumers using the shared resolver now receive conservative type inference for conditional expressions used as call actuals.  This improves overload target filtering for simple `if ... then ... else ...` expressions while preserving the existing safety rule that unknown, stale, or branch-incompatible expressions do not select a navigation target.

### Pass 362 — cross-file Ada unit relationship indexing

`Editor.Ada_Project_Index` now owns a bounded Ada unit table in addition to broad symbol lookup.  Unit rows are keyed by normalized Ada unit name and retain role metadata for package specs, private package specs, package bodies, subprogram specs, subprogram bodies, and separate bodies.  New APIs (`Resolve_Unit`, `Resolve_Unique_Unit_Target`, `Resolve_Related_Unit_Target`, and `Resolve_Separate_Parent_Target`) let navigation consumers pair spec/body/separate targets through validated indexed unit identity instead of relying only on same-leaf symbol searches.  The table is rebuilt from retained file analyses after every index mutation, so path, buffer, revision, lifecycle, clear, and subtree invalidation remove stale unit relationships with the underlying file row.  Duplicate or overflowed unit relationships degrade conservatively.

### Pass 363 — child-unit parent relationship lookup

This pass extends the cross-file Ada unit table with a conservative child-unit
parent lookup API. `Editor.Ada_Project_Index.Resolve_Parent_Unit_Target` derives
the normalized parent unit from an indexed child unit such as `Parent.Child` and
resolves it through the first-class unit table instead of falling back to a
project-wide symbol name scan. The lookup keeps the existing stale-safe
`Unique_Target_Result` behaviour: missing parents, duplicate parents, unit-table
overflow, or non-unit inputs degrade to unavailable/ambiguous rather than
fabricating a navigation target.

Regression coverage: `Test_Project_Index_Child_Unit_Parent_Relationship_Target`.

### Pass 364 — direct child-unit listing

This pass adds the inverse of child-unit parent lookup. `Editor.Ada_Project_Index.Resolve_Child_Units` returns direct indexed child units for a validated parent unit through the first-class Ada unit table, with optional role filtering. The lookup intentionally excludes grandchildren so outline/navigation consumers can build deterministic unit trees one level at a time, and it keeps the existing overflow/stale-safe degradation behaviour instead of scanning paths or leaf symbol names.

Regression coverage: `Test_Project_Index_Parent_Lists_Direct_Child_Units`.

### Pass 365 — validated unit-family target listing

`Editor.Ada_Project_Index.Resolve_Unit_Family` now exposes all indexed rows for the normalized Ada unit identity of a validated starting unit target. Navigation and outline consumers can request the complete spec/body/separate family, or filter that family by unit role, without scanning file paths or falling back to leaf symbol names. The result preserves duplicate matches for caller disambiguation and propagates index/unit overflow through the existing conservative `Unit_Resolution_Result` path.

Regression coverage: `Test_Project_Index_Unit_Family_Lists_Validated_Targets`.


### Pass 366 — library-unit-only unit table rows

`Editor.Ada_Project_Index` now restricts the first-class Ada unit table to top-level library units. Nested package and subprogram declarations still participate in ordinary project-wide symbol lookup, but they no longer become cross-file spec/body/separate unit rows. This prevents a nested declaration such as `package Inner is` inside `Outer` from being misinterpreted as a separately navigable library child unit `Outer.Inner`. Dotted library child units such as `Outer.Child` remain indexed because they are retained as top-level unit symbols.

Regression coverage: `Test_Project_Index_Unit_Table_Excludes_Nested_Declarations`.


### Pass 367 generic semantic expansion

The Ada language model now retains generic actual associations and the resolver exposes a bounded expanded view for selected names through generic package instances. Calls such as `Instance.Operation (...)` can use retained generic actuals to substitute formal type names during overload filtering and expected-result checks. This remains conservative: it does not clone full instance bodies or perform GNAT-equivalent generic legality checking.

### Pass 368 generic instance expression inference

The Ada resolver can now infer effective expression types through selected generic package instances by substituting retained actuals for generic formal object/result types. Outline remains conservative and does not clone instance bodies, but cross-feature navigation and semantic consumers can use the effective instantiated type where the mapping is unambiguous.


Phase 579 pass 369: IDE navigation ambiguity handling now has a first-class candidate API in `Editor.Ada_Project_Index`. Unique goto commands can continue to require a single validated target, while chooser-style UI can request the full validated candidate set for declaration/body/spec/unit-family navigation and distinguish unavailable, unique, ambiguous, and overflow states without falling back to unsafe first-match jumps.


Phase 579 pass 370: ambiguity-aware navigation candidates now have stable display/detail label formatters in `Editor.Ada_Project_Index`. Outline chooser consumers can show all validated declaration/body/spec candidates with file position, kind, profile, and body/generic/rename/instantiation/separate details while preserving the existing rule that direct goto commands require one unique target.


Pass371: representation-clause interpretation now covers bounded non-record metadata, including enumeration representation associations and attribute clauses such as Size, Alignment, Bit_Order, Address, Storage_Size, and Storage_Pool. The model retains raw source text and parses simple Ada integer literal values, while leaving legality checking and full arbitrary static-expression evaluation out of scope.

### Pass 372 — bounded static expression interpretation for representation clauses

Outline/language-model metadata can now retain parsed numeric values for a bounded subset of representation-clause static expressions. The supported subset covers numeric literals, parentheses, `+`, `-`, `*`, `/`, `mod`, `rem`, and `**`, and is applied to enumeration representation associations, attribute representation clauses, and record representation component layout values. Unsupported expressions remain source text only, so navigation and Outline metadata never guess layout legality.

Pass 374 note: representation-clause metadata includes bounded numeric interpretation of prior named-number constants for enumeration representation associations, attribute representation clauses, and record component layout clauses. This remains conservative and does not perform compiler-grade legality or arbitrary static-expression evaluation.


Pass 375 adds bounded executable-statement semantic binding metadata for loop parameters, declare-block objects, exception choices, assignment/call targets, selected components, labels, and goto targets. Semantic colouring consumes these parser-owned bindings where targets are known and degrades unresolved executable expressions to ordinary identifiers.

Pass 376 note: executable binding metadata now includes call targets embedded in executable expressions, such as condition calls, assignment RHS calls, and nested actual calls. Outline remains declaration-focused; these bindings feed semantic colouring/navigation metadata only and do not create Outline rows.

Pass 377 note: executable selected-component bindings are retained as language-model metadata for navigation/semantic consumers. Outline remains declaration-focused and does not create rows for expression-level component uses.

Pass 378 note: executable binding metadata now distinguishes `case` alternatives from exception-handler choices. Case alternatives are retained as `Binding_Case_Choice`, while exception-section handlers remain `Binding_Exception_Handler_Choice`; Outline remains declaration-focused and does not create rows for either executable alternative kind.


Pass 379: executable statement semantic binding now retains deeper expression/name binding metadata for array indexing and slicing, explicit dereference, allocator targets, named aggregate associations, and qualified-expression targets. These bindings remain bounded and conservative; unresolved expressions still degrade rather than being guessed.

Pass 380: executable expression/name binding now retains Ada attribute prefixes such as `Obj'Length`, `X'Size`, and `T'Image (...)` as parser-owned `Binding_Attribute_Prefix` metadata. Qualified expressions such as `T'(...)` remain distinct qualified-expression target bindings, so attribute prefix binding improves semantic colouring/navigation without turning attributes into guessed calls or rendering-side parsing.

Pass 381: executable expression/name binding now retains transfer/tasking targets as parser-owned metadata: `raise E;` becomes `Binding_Raise_Target`, `requeue Start;` becomes `Binding_Requeue_Target`, and `accept Start;` becomes `Binding_Accept_Entry`. These bindings preserve source spelling, scope/range, expression text, and optional local targets without performing tasking or exception legality checking.

Pass 382 note: the language model now retains executable block/loop labels and `exit` targets as bounded semantic metadata. These bindings support local navigation/colouring consumers without making Outline responsible for statement parsing or compiler-grade control-flow validation.

Pass 383 note: executable return bindings are now retained as parser-owned metadata. `return Saved;` records a `Binding_Return_Target`, while extended returns such as `return Result : Rec := Saved do` record `Binding_Return_Object`. These bindings support semantic/navigation consumers without making Outline display executable statement rows or perform return-legality checking.

Pass 384 note: executable delay and abort targets are retained as language-model metadata. `delay until Next_Time;`, `delay Period;`, and `abort A, B;` support semantic/navigation consumers without creating Outline rows or performing Ada tasking/timing legality checks.

Pass 385 note: executable condition/selector and iteration-source targets are retained as language-model metadata. `if`, `elsif`, `while`, `case`, and `for ... in/of ... loop` source names can support semantic/navigation consumers without creating Outline rows or performing compiler-equivalent expression legality checks.

Pass 386 note: select-statement executable bindings remain language-model metadata, not Outline rows. Select guards and selective entry-call alternatives can support navigation/semantic consumers without changing the declaration outline model.

Pass 387 note: timed select alternatives remain language-model executable metadata, not declaration outline rows. `Binding_Select_Delay_Target` can support navigation/semantic consumers without changing the declaration outline model.


Pass 388 note: select terminate alternatives remain executable metadata, not declaration outline rows. `Binding_Select_Terminate` is retained for semantic/navigation consumers without promoting terminate alternatives into declaration outline entries.

Pass 389 note: protected entry barrier expressions remain executable metadata, not declaration outline rows. `Binding_Entry_Barrier` is retained for semantic/navigation consumers without promoting barrier expressions into declaration outline entries.

Pass 390 note: executable range bounds remain semantic/navigation metadata rather than declaration outline rows. `Binding_Range_Bound` records bound names from loop ranges and slices without promoting those names into outline declarations.

Pass 391 note: executable pragma argument bindings remain semantic/navigation metadata only. Assertion-style pragma arguments are retained as `Binding_Pragma_Argument` and are not promoted into outline declaration rows.


Pass 392 update: executable semantic binding now retains bounded quantified-expression metadata. `for all` / `for some` parameters are stored as local executable bindings and simple quantified domains are retained as source bindings for semantic colouring/navigation consumers. This remains conservative and does not perform compiler-grade quantified-expression legality or domain type checking.

Pass 393 note: executable named-actual bindings remain semantic/navigation metadata only. `Binding_Named_Actual` records call parameter association names and does not promote them into outline declaration rows.


Pass394 update: executable expression binding now distinguishes Ada case-expression selectors and choices from statement case alternatives, retaining simple selector/choice names as bounded semantic metadata without compiler-grade case-expression legality checking.

### Pass 395 note

Conditional-expression bindings are retained as executable metadata only.  `Binding_Conditional_Expression_Condition` and `Binding_Conditional_Expression_Branch` allow navigation/semantic consumers to distinguish expression-local `if ... then ... else ...` names from statement-level condition targets without adding outline declaration rows or guessed targets.

Pass 396 note: raise expressions are retained as executable binding metadata only. They do not create Outline rows, but they remain available to semantic/navigation consumers as `Binding_Raise_Expression_Target` where the parser can safely identify the exception target.

### Phase 579 pass397

Executable delta aggregate bindings are retained in the shared language model for semantic/navigation consumers, not as Outline declaration rows. The parser records bounded `with delta` base/component metadata while keeping Outline focused on declarations and validated navigation targets.

Pass398 retains explicit executable type-conversion target metadata in the shared Ada language model for safer navigation/colouring of conversion-shaped expressions.

### Pass399 contract aspect metadata

Outline/language-model analysis now retains executable expression bindings from
contract/assertion-style aspect clauses while keeping the declaration row itself
separate from executable statement parsing.


Pass 400 note: executable semantic binding now retains accept statement formal parameters as bounded `Binding_Accept_Parameter` metadata, distinct from accept entry targets. This lets semantic-colouring/navigation consumers treat accept-body formals as local value-like names where safe.
Pass 401 note: executable semantic binding now retains exception occurrence identifiers, such as `when Occ : Constraint_Error =>`, as bounded `Binding_Exception_Occurrence` metadata distinct from exception-handler choices.


Pass 402 note: executable-language metadata now distinguishes filtered-loop iterator domains from iterator filters. This remains parser-owned language-model metadata and does not affect outline row ownership or rendering-side parsing invariants.

Pass 403 note: asynchronous select `then abort` alternatives remain executable language-model metadata, not declaration outline rows. `Binding_Select_Abort` supports semantic/navigation consumers without promoting select control-flow markers into outline declarations.

### Pass 404 — entry-family executable metadata

Executable tasking metadata now distinguishes retained entry-family indexes from ordinary array indexing.  Outline rows remain declaration-backed, while the shared language model can expose `Binding_Entry_Family_Index` to semantic/navigation consumers for expressions such as `Gate.Take (1)` when `Take` resolves to an indexed entry declaration.

### Pass 405 — token-cursor name/statement grammar completeness

The internal Ada token-cursor grammar now parses full name prefixes before classifying identifier-led constructs as declarations, assignments, or calls. Selected-name, indexed-component, slice, and explicit-dereference forms are retained structurally for statement targets such as `Obj.Field := X`, `Arr (I) := X`, `Arr (A .. B) := X`, `Ptr.all := X`, and selected calls such as `Pkg.Op (...)`. This removes another line-parser approximation from the grammar substrate used by Outline and semantic consumers. The implementation remains syntactic and bounded; target assignability, overload legality, accessibility checks, and subtype legality are still compiler responsibilities.

### Phase 579 pass 406: entry-index grammar is parser-owned metadata

The token-cursor grammar now keeps entry-body index specifications and accept-statement entry-index expressions separate from ordinary parameter profiles. This improves Ada tasking grammar coverage for parser fingerprints and downstream semantic classification. Outline still exposes declarations, not executable accept statements; entry-index expressions remain parser-owned metadata rather than navigation rows.

Pass407: token-cursor Ada grammar now retains discrete choice lists/range choices in case statements, case expressions, and record variant alternatives instead of flattening them to a single selector expression.

Pass408: token-cursor Ada grammar now disambiguates statement identifiers from object declarations, preserving labelled compound statement grammar for forms such as `Named_Loop : for ... loop`, `Named_Block : declare`, and `Named_If : if ... then` while keeping `X : Integer := 0;` as an object declaration.

Pass409: parser-owned statement grammar now retains Ada generalized iterator-loop productions (`for Item of Container loop`) separately from discrete loop-parameter specifications. This improves body-range recovery and statement awareness without creating outline rows for executable loop variables.

Pass410: the parser substrate now preserves quantified-expression loop schemes. This improves body-range and statement recovery around declarations containing `for all` / `for some` expressions, while legality checking remains conservative.

Pass411: the parser substrate now preserves Ada 2022 declare expressions. This helps Outline/body-range recovery when declaration initializers or executable statements contain `(declare ... begin ...)` expression primaries; nested declarations are retained as parser metadata, not promoted to independent Outline rows unless the surrounding language model safely exposes them.

Pass412 note: the token-cursor grammar now retains task/protected type headers with discriminants as first-class concurrent type productions. This prevents `task type` and `protected type` declarations from being flattened into opaque single concurrent declarations before Outline/body-range recovery sees the nested entries, protected operations, private parts, or discriminant metadata.

Pass413 note: aggregate iterated component associations are now parser-owned grammar metadata. This helps body-range recovery and avoids confusing aggregate `for ... =>` syntax with quantified expressions; Outline still does not expose aggregate iterator variables as navigation rows.

Pass414 note: unconstrained array index subtype definitions are now parser-owned grammar metadata. This improves Outline/body-range recovery around declarations such as `type Vector is array (Positive range <>) of Integer;` without turning index subtype boxes into navigation rows or compiler-grade legality checks.

Pass415 note: null-exclusion access syntax is now parser-owned grammar metadata. This improves Outline/body-range recovery around declarations such as `type Ptr is not null access all T;` and access-to-subprogram profiles without turning null exclusions into outline rows or compiler-grade accessibility/nullability checks.

Pass416 parser-completeness note: membership-choice ranges are now token-cursor grammar productions (`Production_Membership_Choice` with `Production_Range_Expression`) rather than opaque expression tails. This does not create Outline rows directly, but it improves body-range recovery for declarations whose executable parts contain `in`/`not in` range membership tests.

Pass417 parser-completeness note: Ada 2022 target-name expressions (`@`) are now retained by the token-cursor grammar as `Production_Target_Name`. This does not create Outline rows directly, but it improves body-range recovery for declarations containing assignment expressions that reference the current assignment target.

Pass418 parser-completeness note: parameter profiles and discriminant parts are now structurally scanned by the Ada token cursor. Defining-name lists, `aliased` qualifiers, `in`/`out` modes, anonymous access items, null exclusions, and default expressions are retained as grammar productions. Outline still does not create standalone rows for profile items unless the language model deliberately projects them, but body-range recovery and profile summaries have more accurate grammar input.

Pass419 parser note: the shared Ada token-cursor parser now retains modified type-definition headers such as `abstract tagged limited record`, `tagged private`, `synchronized interface`, and `abstract new Root and Iface with private` before converting them into language-model/outline rows. This remains syntax retention, not full Ada legality validation.

Pass420 parser note: delay statements are now retained as distinct token-cursor grammar alternatives (`Production_Delay_Until_Statement` and `Production_Delay_Relative_Statement`). This improves body-range recovery inside tasking-heavy bodies without creating Outline rows for executable delay statements or performing clock/time legality checks.

Pass421 parser-completeness note: extended return statements now retain their return-object declaration headers and optional initializers as token-cursor grammar metadata. They do not create Outline declaration rows, but the richer structure improves body-range recovery inside functions using `return X : T := Expr do ... end return;`.

Pass422 parser-completeness note: requeue statements now retain their entry-name target and optional `with abort` marker as token-cursor grammar metadata. They do not create Outline rows, but the richer structure improves tasking-statement recovery inside accept/select bodies and prevents selected/indexed requeue targets from being flattened into opaque semicolon skips.

Pass423 parser note: abort statements now retain task-name target lists through `Production_Abort_Target` rather than opaque semicolon skipping. This improves statement recovery inside tasking-heavy bodies without creating Outline rows for executable abort statements or performing tasking legality checks.

Pass424 parser-completeness note: exception handlers now retain optional choice parameters and exception choice lists structurally. Forms such as `when Failure : Constraint_Error | Program_Error =>` emit `Production_Exception_Choice_Parameter`, `Production_Exception_Choice_List`, and `Production_Exception_Choice` before the handler statement sequence. This remains syntactic parser metadata; exception propagation, handler matching legality, and exception identity checks remain compiler/runtime responsibilities.


Pass425 parser-completeness note: raise statements now retain bare re-raise and message-bearing raise forms as token-cursor grammar metadata. This improves body-range recovery in exception-heavy bodies but does not create Outline rows or validate handler placement, exception identity, or propagation legality.

## Phase 579 pass 426: exit/goto transfer-statement token-cursor grammar

The Ada token-cursor grammar now parses transfer statement targets structurally instead of opaque-skipping them to semicolons. `exit Main when Done;` retains `Production_Exit_Target` and `Production_Exit_When_Condition`; `exit when Should_Stop;` retains the condition without fabricating a target; and `goto Finished;` retains `Production_Goto_Target`. This remains syntactic retention only; label visibility, loop-name legality, transfer legality, and control-flow semantics remain compiler checks.

### Pass 427 select-alternative grammar retention

The Ada token-cursor grammar now distinguishes select-statement alternatives from case alternatives more explicitly. Guarded alternatives such as `when Ready => accept Take;` retain `Production_Select_Guard`, conditional-select `else` alternatives retain `Production_Select_Else_Part`, terminate alternatives retain `Production_Terminate_Alternative`, and asynchronous `then abort` sections retain `Production_Abortable_Part`. Outline/body-range recovery can therefore see the select structure without treating every `when` as a case/discrete-choice alternative. This remains syntactic retention only; select legality and tasking semantics are not compiler-checked by the editor.

- Pass428: token-cursor grammar now retains attribute argument parts on attribute references (`Values'First (1)`, `Integer'Image (Value)`, reduction attributes) instead of misclassifying them as ordinary indexed-component suffixes.


Pass 429 note: the Ada token-cursor parser now retains Ada box expressions (`<>`) as `Production_Box_Expression`, including aggregate associations such as `others => <>` and generic actual associations such as `Element => <>`. This is syntactic grammar retention, not compiler-grade legality or expected-type validation.

Pass 430 note: the Ada token-cursor parser now retains incomplete type declarations explicitly as `Production_Incomplete_Type_Declaration`, including discriminated incomplete declarations and tagged incomplete declarations such as `type Root is tagged;` through `Production_Tagged_Incomplete_Type_Declaration`. This is syntactic grammar retention and outline/navigation metadata support, not compiler-grade completion checking or private/incomplete type legality validation.

Pass 431 note: the Ada token-cursor parser now retains object declaration qualifiers through `Production_Object_Qualifier`, including `aliased`, `constant`, and `aliased not null access` object declarations. This improves outline/language-model recovery for qualified object declarations without claiming compiler-grade object legality or accessibility validation.

Pass 432 note: Ada unknown discriminant parts are now retained structurally by the token-cursor parser. Forms such as `type T (<>) is private;` and `type Deferred (<>);` produce `Production_Unknown_Discriminant_Part` under `Production_Discriminant_Part` instead of treating the box token as a malformed discriminant specification. This remains parser grammar retention only, not compiler-grade private/full-view matching or discriminant legality validation.

Pass 433 note: Ada numeric subtype constraints are now retained structurally by the token-cursor parser. `digits` and `delta` constraints inside subtype indications now produce dedicated grammar nodes before optional range constraints, improving declaration recovery for floating- and fixed-point subtype declarations without claiming compiler-grade numeric subtype legality validation.

Pass 434 note: record component grammar is now more structural. Component declarations inside record and variant parts retain component-definition details including defining-name lists, `aliased`, access/null-exclusion forms, subtype indications, and default expressions. This improves outline/body-range recovery for record declarations without claiming compiler-grade component legality validation.


Pass 435 note: named discriminant constraints are now retained structurally by the Ada token-cursor parser. Subtype indications such as `Bounds (Low => 1, High => 10)` produce `Production_Discriminant_Constraint` and `Production_Discriminant_Association`, while ordinary array index constraints such as `Table (1 .. 5)` continue to use `Production_Index_Constraint`. This is syntactic grammar retention only; positional discriminant-vs-index disambiguation, discriminant legality, and subtype conformance remain compiler-grade semantic checks.

Pass 436 note: Ada aspect marks are now retained structurally by the token-cursor parser. Aspect specifications such as `with Preelaborate` and `Type_Invariant'Class => Is_Valid (Item)` produce `Production_Aspect_Mark` and, for class-wide marks, `Production_Classwide_Aspect_Mark` instead of being flattened into generic expression or attribute-reference recovery. This remains parser grammar retention only, not compiler-grade aspect placement, inheritance, freezing, staticness, or type legality validation.

Pass 437 note: record representation clauses now retain optional `at mod <expression>;` mod clauses structurally through `Production_Mod_Clause`, while preserving following component clauses such as `Field at 0 range 0 .. 7;`. This is parser grammar retention only, not compiler-grade alignment, storage-unit, layout-conflict, or target-specific representation legality validation.

Pass 438 parser-completeness note: generic formal object declarations now expose more complete grammar metadata to the shared language-analysis layer. The token cursor retains `in`/`out` modes and defaults such as `:= <>` for declarations like `Defaulted, Second : in out Element := <>;`. Outline projection remains conservative and does not treat this metadata as compiler-grade generic contract legality.


Pass 439 parser-completeness note: generic formal subprogram defaults are now retained as concrete token-cursor grammar alternatives. The parser distinguishes box defaults (`is <>`), null defaults (`is null`), abstract defaults (`is abstract`), and default-name expressions (`is Some.Default`) instead of treating everything after `is` as opaque recovery. This remains bounded grammar retention, not compiler-grade generic contract legality checking.

Pass 440 note: generic instantiation actual lists now expose named formal selectors and `=> <>` box actual defaults in the token-cursor grammar. Outline consumers can preserve instantiation shape without treating formal selector names as ordinary actual expressions.

Pass 444 parser note: outline/semantic consumers can now receive structural discriminant selector-name nodes for named discriminant constraints with selector lists such as `Low | High => Expr`. This prevents selector alternatives from degrading into expression recovery while keeping legality and subtype-conformance checks outside the outline layer.

Pass 446 note: outline remains declaration-oriented, but the shared Ada token-cursor substrate now retains use-clause name lists structurally. Ordinary package names and use-type subtype marks are separate grammar productions so outline and language-model projections no longer need to infer them from expression-only context-clause parsing.

Pass 448 note: renaming declaration parsing now preserves renamed-entity structure for package, subprogram, object, exception, and generic renames. Outline/navigation consumers can continue to use existing symbol metadata while token-cursor grammar consumers see the renamed target as a real production rather than a flat suffix.


### Pass 450: generic formal type detail

Generic formal type rows remain outline-compatible, while the parser now retains deeper grammar below those rows: scalar boxes, formal array domains/components, derived/interface lists, private/interface modifiers, and formal access callable profiles.

### Pass 451: attached aspect placement coverage

Aspect specifications are now retained consistently at declaration placements that feed outline and symbol metadata.  The token-cursor parser records attached `with ...` clauses on generic formals, package specs/bodies, type/subtype declarations, objects/exceptions, subprogram declarations/bodies, task/protected declarations, entries, and generic instantiations instead of letting branch-local semicolon recovery discard them.  Outline remains syntax-oriented; aspect legality and aspect-specific semantic effects are still compiler/resolver work.

Pass 479: stream operational attribute profile legality is now represented in the language-model diagnostics layer.

Pass 683 interface type grammar note: ordinary interface declarations with `and` parent lists now retain the parent-list and per-parent subtype positions in the token-cursor grammar. Outline remains language-model backed and does not perform interface legality checking.

## Pass 684 generic formal type grammar depth

Generic formal type declarations now expose more internal token-cursor structure for Outline and index consumers.  Formal private, derived, and interface type modifiers are retained as formal-type modifier productions; formal derived/interface `and` lists retain each parent subtype; formal derived `with private` is represented as a private-extension production; and formal array `of aliased ...` component definitions keep the aliased marker.  Outline remains language-model backed and this does not add compiler-grade generic contract legality checking.

Phase 579 pass 685 parser-completeness note: generic formal package declarations now retain their defining name and formal-package-specific actual associations in the token-cursor grammar. Outline consumers can distinguish `with package P is new G (...)` contracts from ordinary package instantiations while still seeing selected generic package names and bounded box metadata. No generic matching, conformance, or visibility legality is inferred.

Pass 686 parser note: pragma syntax now exposes nullary pragmas, pragma-specific argument lists, and argument expression positions through token-cursor productions. Outline remains declaration-oriented; these markers improve parser-owned structural recovery around pragma-heavy declaration and statement regions without creating rendering-side parsing or pragma legality checks.

## Pass 687 note - use-clause list structure

The shared Ada token-cursor grammar now retains explicit list-level structure for use clauses. Ordinary `use P, Q;` clauses emit `Production_Use_Package_Name_List`; `use type T, U;` and `use all type T, U;` clauses emit `Production_Use_Type_Subtype_Mark_List`; `use all type` also emits `Production_Use_All_Type_Prefix`. Comma separators are retained as `Production_Use_Clause_Separator`, and malformed empty or trailing-comma lists recover into following declarations. Outline remains declaration-oriented and does not display use clauses as symbols.

## Pass 688 note - representation and operational item value grammar

Representation and operational items now expose more of their internal value shape to parser-owned Outline inputs. Class-wide stream attributes such as `T'Class'Input` retain the class-wide prefix before the final attribute designator; stream attributes are classified distinctly from generic operational attributes; and representation, address, and enumeration representation values have dedicated value-expression markers. Outline remains declaration-oriented and does not perform representation legality, freezing, address staticness, stream profile conformance, or target visibility checks.

## Pass 689 note - subprogram contract/aspect grammar

Subprogram contract-related aspects now expose dedicated token-cursor grammar markers. `Pre`, `Post`, class-wide contract marks, `Type_Invariant`, `Global`, `Depends`, `Refined_Global`, and `Refined_Depends` remain ordinary aspect specifications for existing Outline consumers, but they also produce contract-specific association, mark, and value productions. `Global` and `Depends` style payloads have their own value-position markers, and malformed missing values recover into following declarations. Outline remains declaration-oriented and does not perform aspect legality, refinement conformance, staticness, visibility, or freezing checks.

## Pass 690 note - package declarative item boundaries

Package specifications and package bodies now expose finer token-cursor markers for declarative-part boundaries. Visible package items, private package items, and package-body declarative items are retained separately, while nested package specifications are skipped as bounded declarative items during boundary recovery so their `private` and `end` tokens do not reclassify the enclosing package part. Outline remains declaration-oriented and does not infer package visibility legality, private completion rules, body/spec conformance, freezing, elaboration, or declaration-order legality.

## Pass 691 note - anonymous access-to-subprogram profiles

Pass 691 adds explicit token-cursor productions for anonymous access-to-subprogram callable profiles. The parser now retains a profile-level marker, a procedure/function kind marker, and a separate access-to-function result-profile marker while preserving existing protected-prefix, parameter-profile, and result-subtype productions.

Outline consumers should continue treating anonymous access-to-subprogram profile parameters as profile metadata only. They must not become standalone outline symbols or command targets.

This is structural grammar coverage only. It does not imply compiler-grade checking for profile conformance, accessibility, protected-operation legality, visibility, null exclusion legality, or overload resolution.

## Pass 692 expression-family parser note

The Outline-facing Ada grammar now retains finer expression-family markers for conditional branches, case-expression alternatives, quantified-expression predicate arrows, and parallel/map reduction attributes. These markers are structural only and help avoid losing nested expression boundaries during recovery; they do not imply compiler-grade expression legality or type analysis.

## Pass 693 name-family parser note

The Outline-facing Ada token-cursor grammar now retains finer name-family boundaries. Selected names expose explicit prefix markers, selected operator/character literal selectors share a literal-selector marker while preserving their specific selector kinds, allocator subtype marks distinguish named subtype allocators from `new access ...` forms, and qualified expressions retain the apostrophe boundary between subtype mark and operand. Outline remains declaration-oriented and does not infer visibility, overload resolution, selected-name legality, allocator accessibility, or qualified-expression typing.

## Pass 694 task/protected grammar depth

The Outline-facing Ada token-cursor grammar now retains additional tasking and protected-object structure. Protected operation declarations/bodies, protected operation aspects, protected entry barriers, entry-family index subtypes, accept do-parts, select `or` alternatives, and `then abort` alternatives all have explicit structural markers. Outline remains declaration-oriented and snapshot-owned; these markers improve recovery and downstream classification without adding compiler-grade tasking legality, barrier semantics, requeue legality, or runtime task semantics.

### Pass695 profile-parameter legality note

The Outline-backed language model now retains enough callable profile information
to report duplicate parameter names in a bounded local pass. Outline rendering is
unchanged; the added diagnostic is model-owned and does not introduce rendering
side parsing or mutation.

### Pass 696 formal package contract edge cases

Formal package declarations now expose additional token-cursor structure for
nested actual associations and actual-list recovery boundaries. Outline remains
backed by the language model and does not infer generic contract legality, but
nested formal package contracts are less likely to be flattened or to obscure
following generic formal declarations after malformed actual lists.

### Pass 697 - local duplicate declaration diagnostics

The Ada language model now reports conservative duplicate-name diagnostics for
local declaration families whose ownership is already retained for Outline:
record components, discriminants, enumeration literals, and generic formal
items.  These diagnostics do not alter Outline construction and remain snapshot
owned, bounded, and side-effect free.

### Pass 698 discriminant grammar depth

The Ada token cursor now retains finer discriminant structure for known and
unknown discriminant parts, access discriminants, defaulted discriminants, and
named discriminant constraints. Outline consumers can continue to rely on the
language-model snapshot rather than reparsing in rendering code.

### Pass 699 variant record grammar note

Variant record input now carries more precise token-cursor structure for nested
variant parts, `when` choice arrows, `others` choices, and choice separators.
Outline consumers should treat these as structural hints for nested record
children and recovery only; they are not legality conclusions about choice
coverage or discriminant-dependent component rules.

### Phase 579 pass 700 note

Entry/select grammar coverage now retains tasking-specific structural markers
for select entry-call alternatives, timed entry-call delay alternatives,
conditional entry-call else alternatives, select delay/terminate alternatives,
entry-call target names, and indexed entry-call prefixes. Consumers must treat
these as parser-owned structural metadata only; they do not imply compiler-grade
entry resolution, guard legality, timed/conditional entry-call legality, or
runtime tasking semantics.

### Phase 579 pass 701 note

Exception grammar coverage now retains parser-owned markers for exception
renaming targets, handler-local names, handler choice separators/arrows, `others`
choices, raise-statement targets, and raise-expression target/message positions.
Outline consumers should treat these as structural recovery and presentation
metadata only; they do not imply exception visibility, reachability, handler
ordering, or raise typing legality.

### Phase 579 pass 702 note

Loop/block/declare grammar coverage now carries parser-owned markers for
statement identifiers, named loop/block statements, loop iterator filters,
declare-block declarative/begin parts, and explicit block or loop end-name
suffixes. Outline consumers may use these markers to recover nested executable
structure more safely, but they must not treat them as proof of label matching,
iterator legality, or control-flow semantics.


### Phase 579 pass 703 note

Body-stub and separate-subunit grammar coverage now carries parser-owned markers
for `separate (Parent.Unit)` parent unit names, nested separate-body declarations,
body-kind classification inside subunits, and explicit body-stub `separate`
completion keywords. Outline consumers may use these markers to distinguish stubs
from full body nodes and to recover separate-subunit structure, but they must not
treat them as proof of stub/subunit matching, parent resolution, or body/spec
conformance.

### Phase 579 pass 704 renaming target notes

Renaming declarations now expose additional parser-owned structural markers for
renamed object/package/subprogram/generic-unit target positions, selected renamed
targets, and operator-symbol renamed targets. Outline consumers may use these
markers to avoid flattening renaming-heavy declarations, but must continue to
avoid compiler-style renamed-entity resolution.

## Phase 579 pass705 attribute grammar depth

Attribute references now expose designator names, class-wide chains, subtype-mark attribute references, and attribute argument associations structurally. Outline consumers remain language-model-backed and do not perform rendering-side parsing or compiler legality checks.

## Pass706 note - semantic-colouring precision

Pass706 refines parser-owned Ada semantic-colouring fallback classification for executable bindings. Callable-shaped bindings such as call targets, select entry calls, requeue targets, and accept entries now use the subprogram token bucket when unresolved; type-shaped qualified-expression, conversion, and allocator targets use the type token bucket. Ambiguous unresolved reference-only forms such as selected components and attribute prefixes intentionally degrade to ordinary identifiers to reduce false positives. This remains structural language-model colouring, not compiler-grade name or overload resolution.


## Phase 579 pass 707 Outline precision

Outline extraction now presents several recently-expanded Ada language-model
constructs with more precise labels and detail metadata:

- variant record types are labelled as `variant record type ...`;
- entry-family declarations are labelled as `entry family ...`;
- generic formal detail text distinguishes formal packages, subprograms, types,
  and objects instead of flattening all of them to one generic-formal wording;
- body-stub, generic-actual, variant-record, and entry-family markers remain
  visible in row details when the parser supplies them.

The Outline still consumes snapshot-owned parser/language-model results only. It
does not parse in the renderer and does not prove generic contracts, entry-family
legality, variant choice coverage, separate-body matching, visibility, overload
resolution, or elaboration rules.


## Pass708 aggregate association structure

The Ada token-cursor now exposes finer aggregate association structure, including
positional components, named associations, choice lists, arrows, `others` choices,
and `null record` extension aggregate markers.  Outline extraction continues to
consume parser-owned language-model metadata only; these markers are retained so
future Outline refinements can distinguish aggregate shapes without rendering-side
parsing.

## Pass709 range/index constraint structure

The Ada token-cursor now exposes finer range and index-constraint structure,
including range lower/upper bounds, range-attribute references such as
`T'Range`, per-item index constraints, and bounded recovery markers for malformed
constraint fragments. Outline extraction remains parser/language-model backed;
these markers are retained for future structural presentation and must not be
treated as proof of subtype legality, staticness, dimension matching, or bound
ordering.

## Pass710 case-statement choice structure

The Ada token-cursor now exposes finer case-statement alternative structure,
including case-specific choice lists, `others` choices, `|` separators, `=>`
arrows, and bounded recovery markers for malformed alternatives. Outline
extraction remains parser/language-model backed; these markers are retained for
future structural presentation and must not be treated as proof of choice
coverage, staticness, selector typing, duplicate-choice legality, or reachability.

## Pass711 if-statement branch structure

The Ada token-cursor now exposes finer if-statement branch structure for
language-model consumers. It retains explicit branch-boundary markers for
`then`, `elsif`, `else`, and `end if`, and reports bounded recovery boundaries
for malformed branches that omit `then`.

Outline remains conservative: these markers support safer executable-region
recovery and future optional statement-node presentation, but they do not make
if statements compiler-validated control-flow entities.

## Pass712 assignment/call statement target structure

Pass712 keeps assignment and call statement target suffixes explicit in the
parser-owned language model. Selected, indexed, sliced, and dereferenced
assignment targets are now distinct from selected and actual-bearing call
targets. Outline remains declaration-oriented, but this statement structure
improves recovery around executable regions that contain nested declarations or
statement identifiers after malformed assignment/call syntax.


## Pass713 return statement grammar depth

Pass713 improves structural Ada return-statement coverage by retaining explicit markers for simple/expression returns, extended return-object defining names, subtype indications, initializers, `do` boundaries, `end return` boundaries, and bounded malformed-return recovery. This is parser-owned grammar metadata only, not compiler-grade return legality checking.

## Pass714 executable statement boundary notes

Pass714 adds parser-owned structural markers for exit/goto/null/delay statement
boundaries. These markers are intended to improve statement-region recovery and
future Outline detail choices without adding statement nodes by default.

## Pass715 note - subprogram body declarative-part metadata

The Ada token cursor now retains explicit structural metadata for subprogram body
declarative items and `begin`/`end` boundaries. This metadata is parser-owned and
supports future Outline precision for nested declarations in bodies without
requiring rendering-side parsing or compiler-grade body/spec analysis.

### Pass716 generic instantiation detail

The Ada token cursor now exposes package/procedure/function-specific generic
instantiation productions plus deeper actual-association metadata.  Outline
callers can use these productions to distinguish ordinary instantiations from
formal package declarations and to preserve useful detail text for positional,
named, boxed, and nested generic actuals without reparsing source text.

This remains structural Outline metadata only; it does not validate generic
contract conformance or instance legality.

## Pass717 array type definition metadata

Pass717 adds finer token-cursor structure for array type definitions. Outline
consumers continue to use the existing language-model type nodes, but the
underlying grammar stream now distinguishes constrained and unconstrained array
index parts, index subtype names/range boxes, ordinary component subtype
indications, and anonymous access component definitions. This is structural
metadata only and does not imply index or component legality checking.

### Pass718 - access type definition grammar depth

- The Ada token cursor now retains deeper structural markers for pool-specific access objects, general access objects, access object subtype marks, access-to-subprogram definitions, protected callable access profiles, and malformed access-type recovery boundaries.
- This improves parser-owned metadata available to Outline and semantic-colouring consumers without adding compiler-grade legality checking, external parser generators, LSP, rendering-side parsing, or dirty-state mutation.

## Pass 720 note

Pass 720 does not change Outline ownership or rendering. It adds parser-owned
local duplicate-choice diagnostics for case, variant, exception, aggregate, and
delta-aggregate structures that may already appear in Outline-adjacent language
metadata.

### Pass 721 type-family label precision

Pass 721 improves Outline presentation for Ada type declarations whose grammar
family is already represented in the language-model metadata. Instead of showing
all non-record type declarations as generic `type ...` rows, Outline now uses
more specific labels for array types, access object types, access-to-subprogram
types, derived types, private extensions, null extensions, interface types, and
tagged types. Generic formal type rows receive matching `formal ... type`
labels for array, access, access-to-subprogram, derived, private-extension, and
interface forms.

This remains a presentation-layer refinement over parser-owned metadata. It does
not perform compiler-grade legality checking for derivation, accessibility,
private completion, array index legality, interface implementation, visibility,
or freezing.

## Pass 722 — Semantic colouring precision after grammar expansion

Pass 722 refines parser-owned Ada semantic-colouring metadata after the grammar-depth passes.  It adds explicit binding roles for generic actual selectors, aggregate component selectors, and extended-return object defining names.  Unresolved selector-like roles now degrade to ordinary identifiers, while assignment targets, labels, and extended-return objects remain value-like local bindings and call targets remain callable bindings.  This improves colouring precision without adding compiler-grade resolution or rendering-side parsing.



## Pass 723 subtype-indication grammar depth

Pass 723 adds explicit token-cursor markers for subtype marks, subtype-context null exclusions, and subtype range/digits/delta/index/discriminant constraints. This improves parser-owned structure used by Outline and semantic-colouring consumers while remaining structural only, not compiler-grade subtype legality checking.

### Phase 579 pass724 — Object declaration grammar depth

The Ada token-cursor now retains finer object declaration structure, including
individual defining identifiers in grouped object declarations, defining-name
separators, aliased/constant qualifiers, and anonymous access object-definition
positions. Outline consumers can continue to use declaration metadata without
performing rendering-side parsing or compiler-grade legality checks.

## Phase 579 pass725 — number declaration grammar depth

The Ada token-cursor now retains finer named-number declaration structure,
including individual defining identifiers in grouped declarations, separators,
the number-specific `constant` keyword, initializer-expression boundaries, and
bounded recovery markers.  Outline remains declaration-oriented and does not
infer named-number staticness or numeric type legality from this syntax metadata.

## Phase 579 pass726 — formal package actual projection

Formal package actual parts are now projected from the syntax tree into the
language model under the owning formal package declaration. Named actuals such as
`Key_Type => Key` and `others => <>` are retained as bounded metadata for Outline
and index consumers, while whole-package `(<>)` defaults stay as box metadata and
do not create positional actual entries.

This improves structural grammar coverage for Ada formal package declarations;
it is not compiler-grade generic conformance checking.

## Phase 579 pass727 — use-clause projection metadata

Use clauses remain metadata rather than Outline symbols, but the language model
now exposes individual retained use-clause names through dedicated use-clause
accessors. Ordinary package `use` clauses, `use type`, and `use all type` entries
keep distinct visibility kinds and per-name source ranges so navigation and
outline-adjacent consumers can reason about the clause structure without display
pollution. No Ada visibility legality or overload legality is inferred.

## Phase 579 pass728 — formal package resolver projection

Formal package declarations that retain both a generic package target and named
actual associations now participate in the same conservative selected-name view
as ordinary generic package instances.  Outline/navigation consumers can resolve
selected children such as `Maps.Get` through the formal package symbol to the
retained generic-template declaration without creating synthetic declarations or
mutating buffer state.

This improves structural Outline metadata for formal package contracts.  It does
not validate formal package contract conformance.

## Phase 579 pass729 — pragma placement metadata

The Outline remains declaration-oriented: pragmas are not displayed as outline
symbols. The Ada language model now retains bounded pragma metadata from the
syntax tree, including pragma name, placement class, first target/argument text,
argument count, named argument count, scope, and range. This lets Outline and
related analysis distinguish configuration, declarative, statement, and
alternative pragmas without creating fake declaration rows.

This is structural metadata only. It does not validate pragma legality,
configuration pragma partition rules, or implementation-defined pragma meaning.

## Phase 579 pass730 — aspect placement grammar depth

The Outline remains declaration-oriented, but the parser now preserves more
precise aspect-placement metadata for declarations whose aspect positions are
otherwise easy to flatten: generic formals, task/protected declarations, entries,
protected operations, body stubs, type/private-completion-style declarations,
and package/task/protected bodies. This lets Outline-adjacent consumers display
or inspect aspect-bearing declarations with less lexical guessing while keeping
aspects as metadata on declarations rather than independent outline rows.

This is structural parser metadata only; it does not validate aspect legality or
contract semantics.

## Phase 579 pass731 representation metadata note

Representation and operational clauses remain parser-owned metadata rather than
Outline declarations. The language model now records a bounded source form for
representation rows so Outline/index consumers can distinguish metadata that
came from attribute-definition clauses, aspects, pragmas, address clauses,
enumeration representation clauses, record representation clauses, and record
component clauses without reparsing rendered text.

## Phase 579 pass732 package recovery note

Package specification/body recovery now retains explicit grammar recovery
boundaries for hostile declarative regions.  The token cursor records premature
`begin` in a package specification and unexpected `private` in a package body as
recovery metadata, then resumes scanning at deterministic package declarative
item or statement-sequence synchronization points.  This keeps Outline extraction
from losing subsequent declarations after malformed package items.

This is structural recovery only.  It does not validate package legality,
private completion conformance, generic contracts, or representation/freezing
rules.

## Phase 579 pass733 anonymous access-to-subprogram note

The Outline remains declaration-oriented, but the token-cursor grammar now
retains more precise metadata for anonymous access-to-subprogram declarations and
profiles. Protected access-to-subprogram forms, not-null access definitions,
parameter defaults inside nested access-to-subprogram profiles, not-null
access-function result subtypes, constrained access-function results, and
malformed access-function profile recovery are all visible as parser-owned
metadata rather than inferred from rendered text.

This is structural grammar coverage only. It does not validate accessibility,
profile conformance, overload legality, or null-exclusion legality.

## Pass734 expression/name edge metadata

Pass734 keeps additional expression/name edge cases visible to Outline-adjacent language-model consumers without turning them into declarations.  Allocator qualified expressions, qualified-expression/conversion ambiguity points, call/index suffix ambiguity, chained attributes, selected operator-literal names, and reduction recovery boundaries are retained as bounded token-cursor productions.

The Outline surface still avoids presenting these expression nodes as symbols.  The metadata is intended to preserve structure for navigation context and downstream semantic-colouring precision while avoiding compiler-grade legality claims.

## Phase 579 pass735 validation guard cleanup

The phase579 language validation guard now keeps recent pass724-pass734 grammar
coverage requirements in a pass-ordered matrix. This makes release validation
failures easier to trace back to the affected structural grammar family: object
declarations, number declarations, formal package actuals, use clauses, formal
package resolver views, pragmas, aspects, representation metadata, package
recovery, anonymous access-to-subprogram profiles, or expression/name recovery.

This is validation-tool organization only. It does not change the Outline
surface and does not promote parser-owned metadata into compiler-grade legality
checking.

## Phase 579 pass736 parser coverage matrix

Outline documentation now treats `docs/ada_parser_coverage_matrix.md` as the
canonical coverage-status table for the Ada parser/language-model layer.  The
matrix records which grammar families are token-cursor-owned, which data is
projected into the language model, which metadata is useful for Outline, and
which compiler-grade legality checks remain explicit non-goals.

This is documentation consolidation only.  Outline continues to consume
parser-backed, snapshot-owned metadata and does not perform rendering-side
parsing or compiler-backed symbol lookup.

## Phase 579 pass737 case-statement alternative depth

Case-statement alternatives now expose additional parser-owned metadata for the
`is` boundary, individual choices, range choices, `others` choices, and
null-statement alternatives. Outline remains declaration-focused, but this
statement metadata helps package/subprogram body recovery continue after richer
case alternatives without using rendering-side parsing.

This improves structural grammar coverage for case-statement alternatives. It
does not make Outline a compiler-grade case-choice legality, exhaustiveness, or
control-flow analyzer.

## Phase 579 pass738 select-statement alternative depth

Select-statement alternatives now expose parser-owned metadata for the first
alternative, accept alternatives, delay-until and relative-delay alternatives,
terminate alternatives, guard arrows, and null statements inside select
alternatives. Outline remains declaration-focused, but this statement metadata
helps tasking-body recovery continue across richer select statements without
rendering-side parsing.

This improves structural grammar coverage for select-statement alternatives. It
does not make Outline a compiler-grade tasking legality, select-alternative
legality, entry-call profile, guard semantic, or control-flow analyzer.


## Phase 579 pass739 exception-handler choice depth

Exception handlers now expose parser-owned metadata for named choices, selected
exception names, choice separators, `others` choices, and handler-local `null;`
statements. Outline remains declaration-focused, but this statement metadata
helps body recovery continue across richer exception sections without
rendering-side parsing.

This improves structural grammar coverage for exception-handler choices. It does
not make Outline a compiler-grade exception-name resolver, handler reachability
analyzer, exception coverage checker, or propagation analyzer.

## Phase 579 pass740 loop iteration-scheme metadata depth

Loop statements now expose parser-owned metadata for `while` loop scheme
keywords, discrete `for` reverse iteration, discrete range iteration,
iterator-loop reverse iteration, iterator-filter conditions, and loop-begin
keyword boundaries. Outline remains declaration-focused, but this statement
metadata helps body recovery continue across richer loop schemes without
rendering-side parsing.

This improves structural grammar coverage for loop iteration schemes. It does
not make Outline a compiler-grade loop legality checker, iterator resolver,
range/staticness validator, or control-flow analyzer.


## Phase 579 pass741 entry family/index metadata depth

Entry declarations, entry bodies, accept statements, barriers, and selected
entry-call forms now expose parser-owned metadata for range-shaped entry-family
definitions, entry-body index identifiers/subtypes, barrier `when` boundaries,
accept entry-index expressions, selected entry-call targets/names, and
entry-family call indexes. Outline remains declaration-focused, but this
statement/tasking metadata helps tasking-body recovery continue across richer
entry-family code without rendering-side parsing.

This improves structural grammar coverage for entry-family/index syntax. It does
not make Outline a compiler-grade tasking legality checker, entry-family subtype
validator, entry-call profile checker, protected-object resolver, barrier
semantic validator, or synchronization analyzer.

## Pass742 note

Pass742 deepens structural Ada variant-record component alternative metadata. The token cursor now retains explicit markers for individual variant choices, range choices, variant component declarations, and `null;` component alternatives, with AUnit and validation guard coverage. This is structural parser metadata only, not compiler-grade discriminant legality or variant coverage checking.

## Phase 579 pass743 note — aggregate association depth

Aggregate association parsing now exposes individual index/component choices,
range choices, box component values, and extension-aggregate component
associations as bounded token-cursor metadata. Outline remains declaration-based;
these aggregate markers support recovery and downstream structural awareness and
do not create declaration rows or perform aggregate legality checking.

## Phase 579 pass744 — profile parameter metadata

Callable profile parameters now have bounded language-model metadata for their
owning callable, defining name, mode classification, access-definition shape,
default expression presence/text, designated subtype text, and grouped-name
position. Outline consumers can use this metadata to display richer callable
profile details without reparsing source text. This is structural metadata only,
not profile legality or conformance checking.

## Pass745 generic formal type detail metadata

The language model now keeps bounded detail rows for generic formal type declarations. These rows classify the formal type family and retain conservative target/profile text for derived, array, access, access-to-subprogram, and interface forms. Outline remains symbol-driven; the extra metadata is available for precise labels and future navigation hints without treating formal type keywords as declarations.

### Pass746 conservative recovery diagnostics

The Ada language model now projects selected parser-owned recovery markers into
bounded legality-adjacent diagnostics.  Outline remains declaration-driven and
does not treat malformed pragmas, aspects, or alternatives as declarations, but
callers can surface clear local syntax defects such as missing terminators or
missing alternative arrows beside the affected source range.


## Phase 579 pass747 note

Pass747 adds hostile-source recovery regression coverage for mixed malformed Ada
constructs. The parser must retain bounded recovery metadata for malformed
generic formal package actuals, variants, aggregates, select alternatives, and
exception handlers, while resuming into later declarations and bodies. This is
structural recovery coverage only, not compiler-grade legality checking.

### Phase 579 pass748 extended return object qualifier depth

Extended return object declarations now expose parser-owned structural metadata
for return-object `aliased` and `constant` qualifiers, access definitions,
`not null` exclusions, and visibly constrained subtype indications. The metadata
is retained for Outline/detail consumers without creating extra declaration rows
or performing compiler-grade return-object legality, accessibility, or subtype
constraint validation.

- Pass749: Outline remains declaration-owned; abort-statement target-list metadata is retained for parser/colouring consumers without creating outline symbols.

## Pass750 raise grammar metadata

Raise statements and raise expressions now expose additional structural metadata
for selected exception names, message `with` boundaries, and malformed message
recovery. Outline consumers keep this as statement/expression metadata and do
not create exception declarations or legality diagnostics from it.

## Phase 579 pass751 note

Pass751 adds deeper standalone delay-statement grammar metadata. Delay statements
remain statement metadata rather than Outline declarations, but the parser now
retains `until` keyword boundaries, selected/qualified delay expression markers,
and semicolon terminator boundaries for downstream recovery and navigation
consumers.


## Phase 579 pass752 note

Requeue statements remain statement metadata rather than Outline declarations.
The token cursor now retains selected-entry targets, entry-family index targets,
`with abort` markers, and bounded malformed-target recovery for downstream
navigation and recovery consumers without creating tasking symbols or legality
claims.

## Phase 579 pass753 note

Labels and goto statements now expose deeper parser-owned metadata. Explicit
labels retain open/close delimiter boundaries and malformed-label recovery
markers. Goto statements retain label-reference and terminator metadata while
recovering conservatively from non-label-name tails. Outline remains declaration
owned; labels and gotos are retained as executable navigation metadata rather
than ordinary declaration rows.

## Phase 579 pass754 note

The Ada token-cursor grammar now retains deeper block-statement structure. Named blocks keep block-specific label metadata, declare blocks expose their declare keyword, declarative-item starts, declarative-to-begin boundary, and exception keyword markers. This is structural metadata for Outline/recovery consumers only; declaration legality, visibility, exception propagation, and control-flow remain outside the editor parser.


## Phase 579 pass755

Task/protected body internals now retain deeper structural metadata. Task bodies expose declarative-item starts plus explicit `begin`/`end` boundaries, and protected bodies expose operation-body `begin`/`end` markers plus bounded recovery for misplaced `private` sections. Consumers must continue treating this as structural parser metadata, not tasking legality or synchronization analysis.

## Phase 579 pass756 note

Call-shaped statements now expose richer token-cursor metadata for selected
prefixes, operation-name leaves, indexed prefixes, and entry-family/procedure-call
ambiguity. Outline consumers may use this metadata for navigation hints, but it
must remain parser-owned structural metadata rather than compiler-grade overload
or entry resolution.

## Pass757 separate subunit / body-stub depth

Pass757 deepens structural token-cursor metadata for Ada `separate` subunits and body stubs. Dotted parent-unit names retain separator and child-name markers; package, subprogram, task, and protected subunit bodies retain body-kind and local unit-name markers; body stubs retain conservative subunit-link hint metadata. This is grammar/model metadata only, not compiler-grade subunit legality or cross-file conformance checking.


## Phase 579 pass758 context-clause metadata

Context clauses are retained as bounded language-model visibility metadata rather than Outline declarations. Pass758 adds context-clause-specific accessors and modifier flags so Outline/navigation consumers can distinguish root context `with`/`use` clauses from declarative-region use clauses without reparsing source text. This remains structural metadata only and does not perform compiler-grade unit dependency or visibility legality checking.

## Phase 579 pass759 duplicate representation diagnostics

Pass759 keeps representation clauses as metadata rather than Outline declarations, but refines the diagnostic path used by Outline-adjacent consumers. Duplicate representation diagnostics now require the duplicate rows to resolve to the same retained target symbol, so nested declarations with the same short name do not create spurious Outline/diagnostic noise.

## Phase 579 pass760 coverage-matrix refresh

The Outline documentation now treats `docs/ada_parser_coverage_matrix.md` pass760 as the canonical coverage/status matrix after the later pass737-pass759 grammar/model passes. The refreshed matrix records statement-alternative depth, loop schemes, entry/tasking statements, variant and aggregate detail, generic/profile metadata, recovery diagnostics, separate subunits, context clauses, and local duplicate representation diagnostics as structural parser/model coverage only.

## Phase 579 pass761 semantic-colouring metadata consumption

Pass761 does not change Outline construction. It documents that several
Outline-adjacent parser metadata families now have semantic-colouring consumers:
context/use clauses, generic formal type details, profile parameters, pragma
metadata, and representation/operational source-form metadata. The connection is
through the language model and `Editor.Syntax_Semantics`, not through rendering
or a second parser.


## Phase 579 pass762 call ambiguity resolver hints

Pass762 records call-shaped ambiguity hints in the language model for later navigation and Outline-adjacent consumers. Selected calls and indexed call shapes now preserve enough syntax/model metadata to distinguish prefixes, operation leaves, and entry-family candidates without performing overload resolution.


## Phase 579 pass764 — formal package positional actuals

Outline and navigation consumers now receive formal-package-specific syntax metadata for positional actual associations in declarations such as `with package P is new G (Key, Element, others => <>);`. The parser still preserves generic-actual compatibility metadata, but the declaration remains a generic formal package contract rather than an ordinary package instantiation.

## Phase 579 pass765 — formal package defaulted actual parts

Outline and navigation consumers now receive explicit syntax metadata for omitted formal package actual parts through `Production_Formal_Package_Defaulted_Actual_Part`. This covers declarations such as `with package P is new G;` and aspect-bearing forms such as `with package P is new G with Preelaborate;` without confusing them with explicit `(<>)` box defaults or parenthesized actual association lists.

This is structural parser metadata only. It does not validate generic contract conformance, default availability, or formal package matching rules.


## Phase 579 pass766 note

Representation and operational pragma aliases are now classified by the token cursor with dedicated structural productions while preserving ordinary pragma syntax. Consumers should continue to treat this as conservative parser-owned metadata, not as a source of compiler-grade pragma legality or representation semantics.


Pass767 note: pragma argument associations now retain named, positional, and box argument-shape productions for parser-owned consumers; Outline remains conservative and does not turn pragma arguments into declarations.

Pass768 keeps selected subtype marks in qualified expressions visible to Outline-adjacent language-model consumers. Ordinary selected subtype marks such as `Math.Count'(1)`, selected operator-literal subtype marks such as `Operator_Types."+"'(5)`, and allocator qualified expressions such as `new Math.Count'(6)` now retain `Production_Qualified_Expression_Selected_Subtype_Mark` alongside the existing selected-name and qualified-expression markers. Outline remains declaration-oriented and does not infer subtype resolution, conversion legality, allocator accessibility, or overload results.


## Phase 579 pass769 body declarative recovery

Package-body and subprogram-body declarative recovery now has body-specific token-cursor metadata. Outline consumers can continue after malformed local declarations without reparsing render text, while still treating the affected region as conservative parser-owned recovery metadata rather than compiler-grade legality or body/spec conformance.

## Phase 579 pass775 note

Renaming declarations with trailing aspect specifications now carry renaming-specific parser placement metadata. Outline consumers should continue to use declaration symbols as the authoritative rows and treat `Production_Renaming_Aspect_Specification` as structural detail only; it must not create separate Outline declarations or imply renamed-entity legality.

## Phase 579 pass780 note

Asynchronous select statements now carry family-specific token-cursor metadata for the select statement, triggering alternative, delay trigger, and abortable part. Outline consumers should treat this as structural tasking-statement metadata only; it does not imply tasking legality, abort semantics, entry-call conformance, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.

### Pass788 accept statement end/recovery note

Accept-statement do-parts now expose accept-specific end and missing-end recovery metadata. Outline consumers may use this as bounded parser-owned structure when presenting tasking constructs, but must not infer tasking legality, entry matching, or body/spec conformance from these markers.

Pass1055: cross-unit selected-name expression inference added; expression metadata now preserves cross-unit selected-name target/selector identity and deterministic counters while maintaining snapshot-owned analysis invariants.

Pass1096: added final render-safe diagnostic recovery-render projection over recovery-render workspace/session state, preserving stable keys and rejected-state accounting without rendering-side semantic work.

Pass1201: Final remediation gate results are now represented as semantic closure rows. Unresolved prerequisite gates become first-class closure blockers while legal, preserved-error, and indeterminate rows retain their semantic identity.

Pass1212: Added Editor.Ada_Volatile_Atomic_Shared_State_Legality and its AUnit regression. The pass adds compiler-grade volatile/atomic/shared-variable legality integration with abstract/refined state, flow/contract proof, tasking/protected deep-edge evidence, and stabilized closure gating.

Pass1223 update: shared-state stabilization-gate rows now feed Editor.Ada_Shared_State_Stabilized_Closure_Legality. Stable accepted shared-state rows become first-class closure evidence; stable blockers remain explicit closure blockers with blocker-family identity preserved.


Pass1237 adds Editor.Ada_Predicate_Generic_Shared_State_Final_Legality. It connects predicate/invariant use-site and propagation evidence to the generic/shared-state final semantic chain, preserving blocker-family identity across generic replay, representation/freezing, tasking/protected, accessibility, discriminant/variant, exception/finalization, renaming/alias, dispatching Global/Depends, cross-unit closure, stabilized shared-state closure, source-fingerprint, substitution-fingerprint, multiple-blocker, and indeterminate states.


Pass1238 adds Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality. It integrates definite-initialization/dataflow legality with the generic/shared-state final chain, preserving blocker families for initialization, dataflow, predicates, generic replay, shared-state closure, representation/freezing, tasking/protected, accessibility, discriminants, exception/finalization, renaming, volatile/atomic representation, access escape, variant components, finalization, and fingerprint mismatches.

Pass1239: Added generic/shared-state final diagnostic integration and feed support. The integration exposes only blocking rows while preserving original semantic blocker-family identity and withholds accepted rows as current semantic evidence.


Pass1248 adds Editor.Ada_Tasking_Generic_Shared_State_RM_Hard_Case_Completion_Legality, closing tasking/protected RM hard cases over the stabilized generic/shared-state semantic chain while preserving blocker-family identity for protected action reentrancy, callbacks, entry queues, requeue/select paths, abort/finalization, task termination, protected shared-state access, abstract-state-backed task effects, and generic task/protected bodies.

Pass1254: Predicate/invariant RM completion now consumes the completed generic/shared-state RM chain and keeps prerequisite blocker families distinct for downstream semantic closure.


Pass1256: RM-completed generic/shared-state diagnostic integration now exposes completed-chain blockers while withholding accepted rows as current semantic evidence.


Pass1258 — Coverage-proven RM-completion AST repair legality
Adds coverage-proven AST repair over the RM-completed generic/shared-state chain while preserving blocker-family identity.

Pass1259: RM-completion generic/shared-state recheck eligibility now preserves blocker-family identity through the bounded recheck boundary.

Pass1260: Added generic/shared-state RM-completion recheck application legality, preserving RM-completion blocker-family identity while applying eligibility back into the semantic closure/feed boundary.


Pass1262 adds Editor.Ada_Generic_Shared_State_RM_Completion_Stabilization_Gate_Legality. It consumes RM-completion recheck convergence rows and promotes only stable generic/shared-state RM-completion conclusions while preserving prerequisite blocker-family identity for withheld rows.

Pass1266: Tasking/protected RM-completion closure consumer legality now consumes stabilized RM-completion closure evidence and preserves tasking/protected blocker-family identity.
