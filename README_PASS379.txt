Pass 379 — Executable expression/name binding completeness

Implemented a bounded executable-expression binding pass on top of pass378.

Highlights:
- Added additional executable binding kinds in Editor.Ada_Language_Model:
  - Binding_Array_Index
  - Binding_Array_Slice
  - Binding_Dereference
  - Binding_Allocator
  - Binding_Aggregate_Component
  - Binding_Qualified_Expression_Target
- Extended Editor.Ada_Declaration_Parser executable binding extraction to retain:
  - object/constant indexing expressions such as Values (I)
  - slice expressions such as Values (1 .. 3)
  - explicit dereferences such as Ptr.all
  - allocator target names such as new Integer'(4)
  - named aggregate associations such as (A => ..., B => ...)
  - qualified-expression target names such as Integer'(...)
- Indexing/slicing is conservative: the scanned prefix must resolve to an object-like retained symbol.
- Declarations, visibility clauses, attributes, unknown expressions, and unsupported shapes still degrade instead of guessing.

Tests:
- Added Test_Language_Model_Executable_Deep_Expression_Name_Bindings.

No Python, shell scripts, parser generators, rendering-side parsing, external compiler integration, or LSP integration were added.
