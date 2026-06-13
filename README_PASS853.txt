Pass853 - Accept statement missing-terminator recovery depth

This pass improves structural grammar coverage for Ada accept statements by
adding accept-specific missing-terminator recovery metadata after a parsed
accept do-part end marker.

Added token-cursor production:
- Production_Accept_Missing_Terminator_Recovery_Boundary

The parser now distinguishes a well-formed accept do-part terminator such as
`end Step;` from an in-progress or malformed accept do-part close such as
`end Broken` before a following statement. The recovery remains bounded and
preserves the accept statement, end keyword, end name, and following statement
metadata for Outline, diagnostics, and semantic-colouring consumers.

Regression coverage is in:
- Test_Language_Model_Token_Cursor_Accept_Terminator_Recovery_Pass853

This is structural parser/token-cursor metadata only. It is not compiler-grade
accept statement legality checking, entry profile conformance, tasking legality
checking, overload resolution, compiler invocation, LSP integration,
render-side parsing, or dirty-state mutation.
