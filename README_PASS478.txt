Pass 478 - Full Address-clause legality

Focus:
- Expanded Address representation clause legality beyond the previous literal-only rejection into target-class and System.Address-shaped value validation.

Implemented:
- Added Address-specific legality diagnostics for incompatible targets, missing values, raw non-address literals, null literal values, and arbitrary non-address names.
- Added Address target classification so address clauses require object-like or callable/entry targets in the retained language model.
- Tightened Address value recognition to accept clear System.Address-shaped forms:
  - System'To_Address (...)
  - System.Storage_Elements.To_Address (...)
  - System.Address'(...)
  - Obj'Address
  - retained address-denoting names such as Null_Address/System.Null_Address
- Rejected obvious non-address expressions:
  - raw numeric literals
  - Boolean literals
  - string literals
  - the null literal
  - arbitrary unresolved names that are not address-shaped
- Added regression coverage in Test_Language_Model_Legality_Full_Address_Clause_Pass.

Scope:
- This remains a bounded language-model legality pass. Exact System.Address type conformance for arbitrary names/calls still belongs to full resolver/type-inference work.
