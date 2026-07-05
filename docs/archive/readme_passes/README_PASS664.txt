# Editor Pass 664

Pass 664 improves structural token-cursor grammar coverage for Ada entry
declaration and entry body internals.

Implemented changes:

- Added `Production_Entry_Identifier` for the entry defining identifier in
  entry declarations and entry bodies.
- Added `Production_Entry_Family_Discrete_Subtype_Definition` for the discrete
  subtype definition part of entry-family declarations.
- Added `Production_Entry_Parameter_Profile` before routing entry declaration
  and entry body parameter lists through the existing parameter-profile parser.
- Preserved existing entry productions for current consumers, including
  `Production_Entry_Declaration`, `Production_Entry_Family_Definition`,
  `Production_Entry_Index_Specification`, `Production_Entry_Barrier`, and the
  ordinary parameter-profile productions.
- Extended AUnit concurrent grammar coverage so task/protected entries assert
  entry identifiers, entry-family discrete subtype definitions, parameter
  profiles, barriers, and protected/task declaration recovery.

This pass improves structural grammar coverage for Ada entry declaration and
entry body internals. It is not compiler-grade legality checking for
entry-family conformance, entry-profile conformance, barrier boolean typing,
tasking-context legality, or rendezvous semantics.
