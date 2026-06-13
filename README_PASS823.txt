Pass823 - Protected operation body end-name and terminator recovery depth

Pass823 deepens Ada protected operation body end metadata. Protected procedure, function, and entry bodies inside protected bodies now retain explicit operation end-name and operation end-terminator productions, plus a bounded operation-specific missing-end-terminator recovery production when an in-progress operation body reaches the enclosing protected-body end without its own semicolon. The scanner also avoids classifying nested statement closes such as `end if;`, `end loop;`, `end case;`, `end record;`, and `end select;` as protected operation body ends.

Implementation notes:
- Added `Production_Protected_Body_Operation_End_Name`.
- Added `Production_Protected_Body_Operation_End_Terminator`.
- Added `Production_Protected_Body_Operation_Missing_End_Terminator_Recovery_Boundary`.
- Updated protected-body operation scanning to retain operation end details without consuming the enclosing protected body end.
- Added AUnit regression `Test_Language_Model_Token_Cursor_Protected_Operation_End_Detail_Pass823`.

Scope note: this improves structural grammar coverage for protected operation body completion. It is not compiler-grade protected operation legality checking, nested statement semantic validation, barrier legality checking, visibility analysis, overload resolution, compiler invocation, LSP integration, render-side parsing, or dirty-state mutation.
