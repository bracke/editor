Pass 592 - Constrained String constant bounds

Implemented bounded retention of declared constrained String bounds on static String constants.

Changes:
- Added optional `First`/`Last` metadata to retained static String constants.
- Registered constrained String constant bounds from the declared subtype after component-count validation.
- Exposed those object bounds through static `First`, `Last`, and `Length` evaluation before falling back to image-derived 1-based bounds.
- Let existing static index/slice logic reuse the retained object bounds for named constrained String constants.
- Added regression coverage for `Offset_Object : constant Offset_Name := Offset_Name'("Green")` feeding representation-expression static values.

Scope:
- This remains bounded static evaluation for IDE-grade diagnostics and representation-expression metadata, not a complete Ada array object model.
