Editor Pass1115

This pass adds Editor.Ada_Renaming_Alias_Visibility_Legality, a widened snapshot-owned Ada semantic legality layer for renaming declarations, alias views, and use/direct visibility legality.

Covered semantic areas:
- object, exception, package, subprogram, generic package, generic subprogram, and formal-object renaming
- use package and use type visibility contexts
- selected-name and alias-view targets
- target presence, ambiguity, and bounded lookup overflow
- kind, subprogram profile, generic profile, and object-subtype mismatch classification
- self-renaming and circular-renaming classification
- constant-as-variable renaming rejection metadata
- aliased-target requirements and non-aliased target failures
- dangling rename risk metadata
- hidden-by-homograph visibility failures
- duplicate use clauses and invalid use package/use type targets
- private-view and limited-view barriers
- linked accessibility/lifetime, overload, cross-unit semantic closure, and unit completion/order blockers

The package is deterministic and bounded. It consumes immutable semantic facts supplied by earlier passes and performs no parsing, file IO, save/reload, dirty-state mutation, command registration, command aliases, keybinding mutation, workspace/session mutation, render mutation, compiler invocation, LSP integration, external parser generation, Python integration, or shell-script integration.

Regression coverage:
- Test_Ada_Renaming_Alias_Visibility_Legality_Pass1115

Core_Suite registration:
- Test_Ada_Renaming_Alias_Visibility_Legality_Pass1115.Test_Case
