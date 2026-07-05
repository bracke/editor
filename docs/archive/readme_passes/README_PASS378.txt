Editor IDE-grade outline/semantic language model pass378

This pass extends executable-statement semantic binding with a concrete
case/exception alternative distinction.

Implemented:
- Added Binding_Case_Choice to Editor.Ada_Language_Model.
- Parser-owned executable binding extraction now tracks exception sections
  conservatively while scanning sanitized source lines.
- `when ... =>` inside an exception part remains
  Binding_Exception_Handler_Choice.
- Ordinary executable `case` alternatives are now retained as
  Binding_Case_Choice instead of being misclassified as exception choices.
- Added regression coverage:
  Test_Language_Model_Executable_Case_Choices_Are_Distinct.

Conservative limits:
- This is not GNAT-equivalent statement legality checking.
- It does not turn case alternatives into Outline rows.
- Unknown or unresolved choices still degrade through the ordinary semantic
  fallback path.
