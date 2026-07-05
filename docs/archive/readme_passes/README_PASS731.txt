# Editor pass731 — representation / operational projection consistency

This pass deepens Ada representation and operational clause projection in the
language model without changing the editor architecture.

Implemented:

* Added `Representation_Source_Form` metadata to distinguish representation
  data that originated from:
  * attribute-definition clauses,
  * aspects,
  * representation pragmas,
  * address clauses,
  * enumeration representation clauses,
  * record representation clauses,
  * record component clauses.
* Extended `Representation_Clause_Info` and `Representation_Component_Info`
  with bounded source-form metadata.
* Updated syntax-tree-to-language-model projection so attribute-definition,
  address, enumeration, record, stream operational, pragma-backed, and
  aspect-backed representation rows all retain a consistent source form while
  still using the existing representation-kind catalog.
* Kept stream attributes such as `Read`, `Write`, `Input`, `Output`, and
  `Stream_Size` in the same attribute-definition projection path while making
  their operational kind explicit through `Representation_Clause_Kind`.
* Added AUnit regression coverage:
  * `Test_Language_Model_Representation_Operational_Projection_Metadata`
* Updated phase validation guards and user-facing parser/colouring docs.

This improves structural grammar/model coverage for representation and
operational clause metadata. It is not compiler-grade representation legality
checking, stream profile conformance checking, freezing-rule validation, or
implementation-defined representation semantics.
