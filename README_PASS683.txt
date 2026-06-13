Pass 683 - Interface type parent-list internal grammar

This pass improves structural grammar coverage for ordinary Ada interface type
definitions.  The token cursor now retains interface parent-list positions and
each parent subtype inside an ordinary interface type definition.

Implemented changes:

- Added `Production_Interface_Parent_List`.
- Added `Production_Interface_Parent_Subtype`.
- Updated ordinary interface type parsing so `type T is interface and I1 and I2;`
  emits a parent-list production at the `and` introducer.
- Updated ordinary interface type parsing so every parent subtype in the list is
  retained before parsing the subtype mark.
- Preserved existing type-modifier, interface-type, subtype-indication,
  selected-name, attribute-reference, and declaration recovery behaviour.
- Added AUnit coverage for limited/synchronized interface modifiers, parent-list
  retention, individual parent subtype retention, attribute suffix preservation,
  and recovery into following declarations.

This is structural parser coverage for editor language intelligence.  It is not
compiler-grade legality checking for interface inheritance, synchronized/task/
protected interface legality, class-wide subtype legality, visibility, or parent
cycle rules.
