Editor Phase 579 pass399

This pass extends executable expression/name binding to declaration contract
aspects.  Contract/assertion-style aspect expressions (Pre, Post, Pre'Class,
Post'Class, Type_Invariant, predicates, Default_Initial_Condition, and related
forms) are now retained as parser-owned executable semantic metadata even when
they appear on declaration lines.

Changes:
- Added Binding_Aspect_Expression to Editor.Ada_Language_Model.
- Added conservative aspect-expression extraction in Editor.Ada_Declaration_Parser.
- Nested expression scanners now process retained contract aspect expressions,
  so calls/components/conversions inside aspects remain available to semantic
  colouring and navigation metadata.
- Semantic-colouring map construction consumes safe Binding_Aspect_Expression
  rows.
- Added Test_Language_Model_Executable_Aspect_Expression_Bindings.

Conservative limits:
- No GNAT-equivalent aspect legality checking.
- No aspect policy interpretation.
- Non-contract/non-executable aspects do not produce executable bindings.
- Unknown names degrade through No_Symbol rather than guessed targets.
