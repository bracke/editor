Pass 517 - Attach_Handler pragma value convergence

This pass fixes a remaining pragma/property lowering drift in the shared representation/operational metadata path.

Changes:
- Corrected pragma Attach_Handler named-argument lowering.
- Handler => now supplies the declaration target only.
- Interrupt => now supplies the retained representation item value.
- Positional Attach_Handler pragmas continue to use the second argument as the interrupt expression.
- Added regression coverage proving named Attach_Handler retains Hook_Interrupt rather than repeating Hook as the property value.
