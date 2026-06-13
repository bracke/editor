Editor Phase 579 Pass890 — Task/protected body declarative-item recovery

Base snapshot: editor_phase579_ide_grade_outline_semantic_language_model_pass889.zip

Implemented bounded grammar family
----------------------------------

Pass890 improves structural recovery for malformed declarative items inside task
bodies and protected operation bodies.

New parser productions
----------------------

* Production_Task_Body_Declarative_Item_Recovery_Boundary
* Production_Task_Body_Declarative_Begin_Boundary
* Production_Task_Body_Declarative_End_Boundary
* Production_Protected_Body_Declarative_Item_Start
* Production_Protected_Body_Declarative_Item_Recovery_Boundary
* Production_Protected_Body_Declarative_Begin_Boundary
* Production_Protected_Body_Declarative_End_Boundary

Regression coverage
-------------------

* Test_Language_Model_Token_Cursor_Task_Protected_Body_Declarative_Recovery_Pass890

Validation/release guard updates
--------------------------------

* tools/phase579_language_validation_check.adb
* docs/ada_parser_coverage_matrix.md
* docs/syntax_colouring.md
* docs/release/RELEASE_CHECKLIST.md
* README.md

Scope note
----------

This improves structural grammar coverage for task/protected body declarative
item recovery. It is not compiler-grade tasking legality checking, protected
operation legality checking, declaration legality checking, overload resolution,
compiler invocation, LSP integration, render-side parsing, background
whole-project scanning, or dirty-state mutation.
