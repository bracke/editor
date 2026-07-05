pass 269: selective-accept delay alternatives

Implemented parser-owned metadata for delay alternatives in selective accept statements.

Changes:
- Added Statement_Delay_Alternative.
- Added Statement_Delay_Alternative_Until.
- Added Statement_Delay_Alternative_Relative.
- Centralized delay statement stamping through Mark_Delay_Details.
- Parser now recognizes same-line selective-accept forms such as:
    or delay 1.0;
    or delay until Deadline;
- Delay alternatives retain base Statement_Delay metadata plus relative/until metadata.
- No Outline rows, semantic declaration symbols, scopes, declarations, or navigation targets are created from delay alternatives.
- Extended AUnit statement-awareness coverage.
- Extended language_validation_check.
- Updated README, outline docs, semantic-colouring docs, and release checklist.
