Editor Phase 579 — Pass913
===========================

This pass improves structural Ada grammar recovery for malformed case-statement
selectors at reserved statement-sequence boundaries.

New production metadata:

* Production_Case_Statement_Selector_Reserved_Boundary_Recovery_Boundary

Parser/token-cursor updates:

* Refined `case` statement selector recovery for forms such as:

      case is
         when others => null;
      end case;

* The parser now avoids fabricating reserved boundary tokens such as `is`,
  `when`, `then`, `else`, `or`, `exception`, `end`, separators, and delimiters
  as selector expressions.

Preserved metadata:

* Production_Case_Statement
* Production_Case_Statement_Selector for valid following selectors
* Production_Case_Statement_Is_Keyword
* Production_Case_End_Terminator
* Production_Recovery_Point

Regression coverage:

* Test_Language_Model_Token_Cursor_Case_Selector_Reserved_Boundary_Recovery_Pass913

Updated files:

* src/core/editor-ada_token_cursor.ads
* src/core/editor-ada_token_cursor.adb
* tests/src/editor-syntax_semantics-tests.adb
* tools/phase579_language_validation_check.adb
* docs/ada_parser_coverage_matrix.md
* docs/syntax_colouring.md
* docs/release/RELEASE_CHECKLIST.md
* README.md

This improves structural grammar coverage for malformed Ada case-statement
selectors. It is not selector expression legality checking, discrete-choice
legality checking, case coverage checking, overload resolution, compiler
invocation, LSP integration, render-side parsing, background whole-project
scanning, or dirty-state mutation.
