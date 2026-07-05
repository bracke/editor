pass 324 completeness pass

Focus: grammar-aware recovery for generic formal parts.

Implemented:
- Added syntax-tree recognition for the generic-unit boundary after a generic formal part.
- The parser now emits Node_Implicit_End when a package/subprogram generic unit starts, closing the preceding generic formal part without leaving a false EOF missing-end diagnostic.
- Generic formal declarations remain owned by the Node_Generic_Declaration, while the generic unit remains structured and can own its normal package/subprogram scope.
- Added AUnit coverage for generic formal-part recovery.
- Extended language_validation_check guards.

Validation notes:
- The output archive was checked for duplicate Node_Kind enumerators.
- No Python, Python bytecode, or shell scripts are present in the project tree.
