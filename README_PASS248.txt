Editor phase 579 pass 248

This pass expands parser-owned Ada statement-awareness metadata with qualified simple statement forms:

- Statement_Exit_When for conditional exits such as `exit when Done;` and named conditional exits.
- Statement_Raise_With_Message for `raise Some_Error with Expr;`.
- Statement_Requeue_With_Abort for `requeue Target with abort;`.

The parser still records the base statement kinds (`Statement_Exit`, `Statement_Raise`, and `Statement_Requeue`) while adding the more specific metadata.  These statement forms remain bounded analysis metadata only: they do not create Outline rows, semantic declaration symbols, scopes, or navigation targets.

Updated AUnit coverage verifies the new statement metadata and keeps the parser's statement-awareness path separate from declaration extraction.
