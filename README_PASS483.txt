Pass 483 - Stream attribute profile conformance

Implemented stream operational attribute profile completeness for Ada representation clauses.

Highlights:
- Tightened Read/Write/Input/Output stream attribute profile conformance.
- Requires the first formal of stream handlers to be an access parameter designating
  Ada.Streams.Root_Stream_Type'Class instead of accepting any formal named Stream.
- Requires Read, Write, and Output handlers to have exactly two formals.
- Requires the second formal of Read/Write/Output handlers to match the represented
  type/subtype target by retained subtype mark.
- Preserves the existing Input rule requiring one stream formal and a return type
  matching the represented type.
- Keeps mode diagnostics separate from profile diagnostics so Read item-mode errors
  continue to surface as mode conformance failures.
- Added regression coverage for valid stream handlers and bad stream-formal, arity,
  and item-subtype profiles.
