Editor Phase 579 IDE-grade outline / semantic language model pass391

Focus:
- Another bounded executable expression/name binding completeness pass.

Implemented:
- Added Binding_Pragma_Argument to Editor.Ada_Language_Model.
- Parser-owned executable binding extraction now retains assertion-style pragma
  argument names from pragmas such as Assert and Loop_Invariant.
- The pragma scanner is conservative: representation/import pragmas do not create
  executable argument bindings.
- Nested call/component/deep expression scanners are applied to retained
  executable pragma arguments, so constructs such as Check (Count) remain
  navigable/colourable through existing binding metadata.
- Fallback standalone-call scanning now excludes pragma-led lines, avoiding
  bogus Binding_Call_Target entries for the Ada keyword pragma.

Added regression test:
- Test_Language_Model_Executable_Pragma_Argument_Bindings

Still conservative:
- No GNAT-equivalent pragma legality checking.
- No full pragma semantics or policy handling.
- Only assertion/executable expression pragmas are interpreted as statement
  expression metadata; unknown pragmas degrade without guessed bindings.

No Python, shell scripts, .pyc, parser generators, rendering-side parsing,
external compiler integration, or LSP integration were added.
