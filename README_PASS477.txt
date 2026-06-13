Pass 477 - Interfacing representation conflict legality

Focus:
- Extended representation/operational legality beyond per-attribute target/value checks into interfacing clause combinations.

Implemented:
- Added diagnostics for unknown convention identifiers in the bounded model.
- Added diagnostics when both Import and Export are enabled for the same retained representation target.
- Added diagnostics when External_Name or Link_Name is specified without an enabled Import or Export clause for the same target.
- Added helpers for static True/False recognition and enabled Import/Export lookup.
- Added regression coverage in Test_Language_Model_Legality_Interfacing_Conflict_Representation_Pass.

Scope:
- This remains a bounded language-model legality pass. Full convention-specific ABI/profile legality still belongs to later resolver/type-inference work.
