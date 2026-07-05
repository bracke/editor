# Editor pass733 — anonymous access-to-subprogram edge grammar

This pass improves structural Ada token-cursor coverage for anonymous
access-to-subprogram profiles.  The goal is more precise parser-owned metadata
for Outline and semantic-colouring consumers, especially around protected
profiles, not-null forms, nested defaults, constrained access-function results,
and bounded recovery after malformed profiles.

Implemented changes:

* Added access-to-subprogram edge productions:
  * `Production_Access_Subprogram_Null_Exclusion`
  * `Production_Access_Subprogram_Parameter_Default`
  * `Production_Access_Subprogram_Result_Null_Exclusion`
  * `Production_Access_Subprogram_Result_Constraint`
  * `Production_Access_Subprogram_Profile_Recovery_Boundary`
* Retained explicit metadata for nested defaults inside anonymous
  access-to-subprogram parameter profiles.
* Retained explicit metadata for not-null anonymous access-to-function result
  subtypes.
* Retained explicit metadata when anonymous access-to-function result subtypes
  have constraints such as discriminant/index constraints or range/digits/delta
  constraints.
* Added bounded recovery metadata when an access-to-function profile is missing
  its result subtype.

Regression coverage:

* `Test_Language_Model_Token_Cursor_Anonymous_Access_Subprogram_Edge_Recovery`

The regression covers protected anonymous access-to-subprogram parameters,
nested access-to-subprogram defaults, not-null access-function results,
constrained access-function result subtypes, malformed access-function profiles,
and recovery into following declarations.

Non-goals:

* No compiler-grade accessibility checking.
* No subprogram profile conformance checking.
* No overload legality checking.
* No null-exclusion legality checking.
* No rendering-side parsing, LSP, compiler invocation, or external parser
  generator.
