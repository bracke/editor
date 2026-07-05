# Editor pass739 — exception-handler choice depth grammar

Pass739 deepens structural token-cursor metadata for Ada exception-handler
choices.  Exception handlers now retain explicit named-choice metadata,
selected exception-name metadata, `others` choice metadata, handler-local
`null;` statement markers, and recovery markers for empty or malformed handler
statement sequences.

The new regression
`Test_Language_Model_Token_Cursor_Exception_Handler_Choice_Depth` keeps named
choices, selected exception choices such as `Ada.IO_Exceptions.Name_Error`,
choice separators, choice parameters, `others`, and null handler bodies from
collapsing into opaque statement recovery.

This improves structural grammar coverage for Ada exception-handler choices. It
is not compiler-grade exception-name resolution, exception coverage checking,
handler reachability analysis, or exception propagation analysis.
