Pass 496 - Real-time/concurrency representation/operational property unification

Implemented another aspect/attribute-definition unification pass for remaining
real-time and concurrency properties that were still opaque to the retained
representation item stream.

Highlights:
- Added explicit retained representation/operational clause kinds for:
  - Interrupt_Handler
  - Attach_Handler
  - Async_Readers
  - Async_Writers
  - Effective_Reads
  - Effective_Writes
- Unified aspect lowering and attribute-definition clause lowering for these
  properties, e.g.:
  - with Interrupt_Handler
  - for ISR'Interrupt_Handler use False;
  - with Attach_Handler => Some_Interrupt
  - for Hook'Attach_Handler use Other_Interrupt;
  - with Async_Readers / Async_Writers / Effective_Reads / Effective_Writes
  - for Obj'Async_Readers use False;
- Added default True handling for Boolean aspect forms without explicit values.
- Routed Boolean-valued properties through the existing static Boolean legality
  diagnostics.
- Added target compatibility routing:
  - Interrupt_Handler and Attach_Handler require subprogram-like targets.
  - Async_Readers, Async_Writers, Effective_Reads, and Effective_Writes allow
    type-like or object-like targets.
- Extended representation pragma lowering for Interrupt_Handler and Attach_Handler
  so pragma/aspect/attribute forms share retained metadata where possible.
- Expanded regression coverage in the representation/operational unification test.
