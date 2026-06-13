Pass 619 - Direct nested discrete Pos operands

- Extended bounded `T'Pos` static integer evaluation so the operand scanner keeps a complete nested static discrete expression instead of stopping at the first right parenthesis.
- Direct representation expressions such as `Color'Pos (Color'Max (Color'Min (Red, Green), Blue)) * 8` now evaluate through the retained discrete static environment.
- The scanner skips Ada string literals, Ada character literals, and nested parentheses while selecting the outer `T'Pos` argument close.
- Preserved existing literal and named-discrete-constant `T'Pos` behavior.
- Added regression coverage in the qualified discrete constant pass.
