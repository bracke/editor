Pass 406 extends the token-cursor Ada grammar for tasking constructs.

Implemented:
- Added Production_Entry_Index_Specification to the token-cursor grammar model.
- Added Parse_Entry_Parenthesized_Parts to distinguish:
  * entry body indexes: entry E (for I in Index) (...)
  * entry-family declarations: entry E (Positive) (...)
  * ordinary entry parameter profiles: entry E (Item : T)
- Updated accept statement parsing to consume the entry name, optional index expression, optional parameter profile, and do-part statement sequence structurally.
- Added AUnit coverage for entry-index and accept-statement grammar retention.
- Extended language validation/release guards and docs for the new grammar production.

This remains bounded editor grammar support. It does not validate tasking legality, barrier legality, protected/task placement, subtype conformance, or runtime rendezvous semantics.
