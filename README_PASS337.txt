Pass 337 — token-cursor type-definition grammar completeness

This pass extends the Ada token-cursor grammar layer added in pass334 and expanded in passes335-336.

Implemented:
- first-class token-cursor productions for Ada type definitions and subtype constraints;
- array type definitions and index constraints;
- access type definitions, including access-to-subprogram and access protected subprogram shapes;
- derived type definitions and private extensions;
- private and limited private type definitions;
- interface type definitions;
- signed integer, modular, floating point, ordinary fixed point, and decimal fixed point definitions;
- subtype indications and range constraints;
- object declaration subtype-indication parsing before default-expression parsing.

Validation updates:
- added AUnit coverage for token-cursor type-definition and constraint productions;
- extended phase579_language_validation_check guards;
- updated README/docs/release checklist language for the broader token-cursor grammar.
