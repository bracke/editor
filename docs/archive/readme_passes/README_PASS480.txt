Pass 480 - Record representation clause legality completeness

Focus:
- Extend the bounded Ada legality layer for record representation clauses beyond duplicate/missing/invalid same-unit checks.

Implemented:
- Added diagnostics for record representation component bit positions outside the retained storage-unit model.
- Added global storage-place overlap detection so components that span into adjacent storage units can conflict with later component clauses.
- Added retained component-subtype size compatibility checks when the component subtype has a static Size/Object_Size/Value_Size clause.
- Added regression coverage for cross-storage overlap, out-of-storage-unit bit ranges, and too-small component clauses.

Notes:
- This remains a bounded IDE legality layer. Full GNAT-equivalent record layout legality still depends on target ABI/machine-scalar details and full type resolution.
