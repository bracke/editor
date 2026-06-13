Pass 487 - Component representation pragma/aspect unification

Implemented the next representation legality completeness pass after pass 486.

Highlights:
- Added retained representation-clause kinds for Atomic_Components, Volatile_Components, and Independent_Components.
- Lowered pragma Atomic_Components, pragma Volatile_Components, and pragma Independent_Components into the same representation metadata stream used by aspects and attribute-definition clauses.
- Lowered Atomic_Components, Volatile_Components, and Independent_Components aspects into the same path, with implicit boolean True for bare aspects.
- Added attribute-definition clause mapping for X'Atomic_Components, X'Volatile_Components, and X'Independent_Components.
- Reused duplicate representation detection across pragma/aspect/attribute-definition forms.
- Added legality checking that component representation items require array type targets.
- Reused the static Boolean value legality path for component representation items.
- Added regression coverage for pragma lowering, aspect lowering, attribute-definition lowering, mixed duplicate detection, non-array target diagnostics, and invalid Boolean values.
