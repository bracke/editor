Pass 637 - Access-to-subprogram profile/result grammar

Implemented a focused token-cursor grammar pass for access-to-subprogram
definitions.  The access parser now emits dedicated productions for callable
parameter profiles and function result subtype indications before delegating to
the existing bounded parameter-profile and subtype-indication parsers.

Covered forms include named access-to-subprogram types, anonymous access
parameters, access components, protected access-to-subprogram definitions, and
generic formal access-to-subprogram types.

AUnit coverage was extended in the existing access-definition grammar regression
test to require both access-subprogram profile productions and access-function
result-subtype productions while preserving protected-marker, null-exclusion,
object-access, discriminant, parameter, and formal-access coverage.

This improves structural grammar coverage for Ada access-to-subprogram profiles
and result subtype indications.  It is not compiler-grade legality checking for
callable profile conformance, accessibility, null-exclusion legality, or result
subtype compatibility.
