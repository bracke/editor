Pass 468 - Static representation expression legality
===================================================

Focus
-----
This pass adds another bounded Ada legality layer for representation clauses:
values that the parser already retains structurally must be statically evaluable
where Ada requires static representation expressions.

Implemented
-----------
- Added `Legality_Enumeration_Representation_Static_Value_Required`.
- Added `Legality_Record_Component_Static_Position_Required`.
- Added `Legality_Record_Component_Static_Bit_Range_Required`.
- Enumeration representation associations now diagnose nonstatic values such as
  `Red => Dynamic_Value`.
- Record representation component clauses now diagnose nonstatic storage-unit
  positions after `at`.
- Record representation component clauses now diagnose nonstatic first/last bit
  bounds after `range`.
- Existing duplicate/value/overlap/target diagnostics remain unchanged.

Regression coverage
-------------------
- Added `Test_Language_Model_Legality_Representation_Static_Component_Pass`.

Notes
-----
The check intentionally uses the language model's current static-natural
recognizer. Full static expression folding through named constants and operators
remains a later full static-expression-evaluation pass.
