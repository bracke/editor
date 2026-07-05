Pass 682 - Derived type definition internal grammar

This pass improves structural grammar coverage for ordinary Ada derived type
definitions.  The token cursor now retains the parent subtype after `new`, the
presence of an interface list introduced by `and`, and each interface subtype
inside that list.

Implemented changes:

- Added `Production_Derived_Parent_Subtype`.
- Added `Production_Derived_Interface_List`.
- Added `Production_Derived_Interface_Subtype`.
- Updated ordinary derived type parsing so `type T is new Parent.Root with ...`
  retains the parent subtype position explicitly.
- Updated derived extension parsing so `type T is new Root and I1 and I2 with ...`
  retains the interface-list and each interface subtype position before parsing
  the private or record extension.
- Preserved existing derived type, private extension, record extension,
  subtype-indication, selected-name, and recovery behaviour.
- Added AUnit coverage for derived parent subtype retention, interface-list
  retention, individual interface subtype retention, private extensions, record
  extensions, and recovery into following declarations.

This is structural parser coverage for editor language intelligence.  It is not
compiler-grade legality checking for parent subtype legality, interface
conformance, tagged type legality, extension legality, or visibility.
