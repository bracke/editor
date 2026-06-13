Pass 624 - Base-qualified compatible subtype discrete constants

- Corrected bounded qualified discrete constant retention for qualifiers that explicitly name 'Base on a constrained scalar subtype.
- Primary_Color'Base'(Blue) now evaluates the operand against the scalar root while preserving the final declared object subtype range check.
- Added regression coverage for accepting a Color object initialized from Primary_Color'Base'(Blue) and rejecting a Primary_Color object initialized from the same value.
