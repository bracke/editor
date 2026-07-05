# Editor pass744 — subprogram/profile parameter mode projection

Pass744 deepens Ada language-model projection for callable profile parameters.
The parser now projects each retained subprogram/function/entry-style profile
parameter into bounded `Profile_Parameter_Info` metadata with the owning callable
symbol, parameter symbol, defining name, explicit/default mode classification,
access-definition flags, access-to-subprogram profile flags, aliased/default
expression flags, retained default text, retained designated subtype text, and
position inside grouped defining-name lists.

This pass adds the AUnit regression
`Test_Language_Model_Subprogram_Profile_Parameter_Mode_Metadata`, covering grouped
`in out` parameters, explicit `in` and `out` modes, access-to-subprogram
parameters, aliased access-to-object parameters, designated subtype metadata, and
default-expression retention.

This improves structural grammar/model coverage for Ada callable profile
parameter metadata used by Outline, resolver, and semantic-colouring consumers.
It is not compiler-grade parameter legality checking, mode-conformance checking,
default-expression legality checking, accessibility checking, or overload/profile
conformance checking.
