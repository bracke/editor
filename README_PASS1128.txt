Pass1128 - Accessibility precision legality

This pass adds Editor.Ada_Accessibility_Precision_Legality.

The new package deepens the existing accessibility/lifetime legality layer by connecting nested access levels, anonymous access parameters, allocator masters, access discriminants, return accessibility, generic instance actual/formal lifetime substitution, and record/variant aggregate discriminant contexts.

The pass is semantic rather than projection-only. It classifies short-lived anonymous access parameters, escaping access parameters, allocator masters that do not outlive the target, return access values and return objects that may outlive designated objects, access discriminant lifetime errors, generic actual lifetime mismatches, aggregate discriminant lifetime errors, private/limited/cross-unit barriers, and linked accessibility/generic/aggregate blockers.

The model is deterministic and snapshot-owned. It performs no parsing, file IO, compiler invocation, render-side analysis, command registration, keybinding mutation, workspace mutation, dirty-state mutation, save, reload, or editor lifecycle changes.

AUnit coverage added:
- Test_Ada_Accessibility_Precision_Legality_Pass1128

This pass adds one compiler-grade building block for Ada accessibility and lifetime precision. Full compiler-grade Ada analysis remains incomplete until the remaining Ada legality, overload/type resolution, generic, representation/freezing, accessibility/lifetime, flow, tasking/protected, and cross-unit semantic closure layers are fully integrated.
