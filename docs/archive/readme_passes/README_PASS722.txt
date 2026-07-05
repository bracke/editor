# Editor Pass 722 — Semantic Colouring Precision After Grammar Expansion

This pass continues from `editor_ide_grade_outline_semantic_language_model_pass721.zip`.

## Focus

Improve semantic-colouring precision for parser-owned Ada language-model metadata after the recent grammar-depth passes.

The pass remains structural and conservative.  It does not add rendering-side parsing, compiler invocation, LSP integration, background project scans, or dirty-state mutation.

## Changes

* Added executable binding roles for grammar-expanded selector/definition contexts:
  * `Binding_Generic_Actual_Selector`
  * `Binding_Aggregate_Component_Selector`
  * `Binding_Return_Object_Defining_Name`
* Refined `Editor.Syntax_Semantics.Build_Map_From_Analysis` so unresolved selector-like roles degrade to ordinary `Identifier`:
  * call named-actual selectors
  * generic actual selectors
  * aggregate component selectors
  * delta aggregate component selectors
* Kept definition/value-like roles colourable with the existing local-value bucket:
  * assignment targets
  * extended-return object defining names
  * labels
* Kept callable roles colourable as subprogram identifiers:
  * call targets
  * select entry calls
  * accept/requeue targets
* Updated aggregate selector retention in the parser to use the more precise aggregate-selector binding kind while preserving duplicate aggregate-selector diagnostics.

## Tests

Added AUnit coverage:

* `Test_Semantic_Colouring_Expanded_Grammar_Precision`

The validation guard now requires the new regression and the new semantic role markers.

## Scope boundary

This improves semantic-colouring precision for expanded Ada grammar metadata.  It is not compiler-grade name resolution, overload resolution, generic contract matching, aggregate typing, selector legality, return-type checking, visibility checking, or expected-type analysis.
