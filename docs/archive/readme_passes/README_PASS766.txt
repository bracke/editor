Editor pass766 — representation/operational pragma item depth

This pass deepens token-cursor grammar coverage for Ada representation and operational pragma aliases.

Implemented:
- Added Production_Representation_Pragma.
- Added Production_Operational_Pragma.
- Classified common representation pragmas such as Pack, Atomic, Import, Export, Convention, Interface, External, Linker_Section, Machine_Attribute, Attach_Handler, Interrupt_Handler, and related component/object representation pragmas.
- Classified operational pragmas such as Priority, Interrupt_Priority, CPU, Dispatching_Domain, Relative_Deadline, Inline, No_Return, Preelaborate, Pure, policy pragmas, Suppress/Unsuppress, and SPARK_Mode.
- Preserved ordinary pragma identifier and pragma argument-list productions.
- Routed classified operational pragmas through Production_Operational_Item so parser consumers do not need a separate pragma-only recognizer.
- Added AUnit regression Test_Language_Model_Token_Cursor_Representation_Pragma_Item_Depth.
- Updated validation guards, parser coverage documentation, semantic-colouring documentation, and release checklist notes.

This improves structural grammar coverage for representation and operational pragma items. It is not compiler-grade pragma legality checking, representation legality, freezing analysis, stream profile conformance, layout validation, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
