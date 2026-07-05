Pass654: select statements now retain guarded alternative condition positions, per-alternative statement-sequence positions, select-else statement sequences, and abortable-part statement sequences structurally for parser consumers.

Scope:
- improves structural grammar coverage for Ada select statements and select alternatives;
- preserves existing generic statement-sequence markers for current consumers;
- does not perform compiler-grade legality checking for select kind, guard typing, alternative compatibility, termination alternatives, abortable-part legality, or tasking semantics.
