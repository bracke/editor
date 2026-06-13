Editor Phase 579 - Pass 676
===========================

Pass 676 adds explicit token-cursor productions for record component declaration
internals. Component declarations now retain the grouped defining-name-list side,
the subtype-indication side, and default-expression side as distinct structural
positions while preserving existing component-declaration, component-definition,
aliased-part, subtype-indication, default-expression, aspect, and recovery paths.

AUnit coverage was extended for grouped record components, aliased component
definitions, selected operator subtype marks, qualified default expressions, and
recovery into following object declarations.

This improves structural grammar coverage for Ada record component declaration
internals. It is not compiler-grade legality checking for component subtype
compatibility, default-expression conformance, record representation, component
visibility, or discriminant-dependent component legality.
