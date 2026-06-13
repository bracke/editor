Pass1215 — Tasking shared-state final legality

Added Editor.Ada_Tasking_Shared_State_Final_Legality.

This pass connects hard tasking/protected RM edge evidence with abstract/refined state, volatile/atomic/shared-variable evidence, overload shared-state RM edge legality, and representation/freezing shared-state legality.

It applies to protected function reads, protected procedure writes, protected entry barriers, entry-family queues, accept-body effects, requeue effects, select alternatives, task activation, task termination, abortable finalization, abstract-state-backed tasking access, and representation-sensitive tasking effects.

The model preserves blockers for missing or blocked deep tasking rows, shared-state rows, abstract-state rows, overload shared-state rows, representation shared-state rows, protected read/write mode errors, barrier side effects, entry-family queue errors, accept-body effect errors, requeue/select shared-state errors, task activation/termination shared-state errors, abort/finalization shared-state errors, abstract-state mode errors, representation effects, source fingerprint mismatches, multiple blockers, and indeterminate states.

Added Test_Ada_Tasking_Shared_State_Final_Legality_Pass1215 and registered it in tests/src/core_suite.adb.
