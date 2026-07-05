Pass 448: renaming declaration grammar is now structural in the token-cursor Ada grammar.

Implemented coverage:
- package renaming declarations retain a package-renaming production and renamed package target;
- procedure/function renaming declarations retain a subprogram-renaming production, defining names/operator symbols, profiles, return subtype marks, and renamed callable targets;
- object renaming declarations retain object-renaming production, subtype indication/null-exclusion structure, and renamed object target;
- exception renaming declarations retain exception-renaming production and renamed exception target;
- generic package/procedure/function renaming declarations retain generic renaming productions and renamed generic-unit targets;
- all renaming forms emit Production_Renamed_Entity before parsing the target name/selected name/attribute-shaped entity.

Regression coverage:
- Test_Language_Model_Token_Cursor_Renaming_Declaration_Grammar_Completeness
