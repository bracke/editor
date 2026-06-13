Editor Phase 579 - Pass 662
===========================

Focus
-----
Improve structural token-cursor grammar coverage for Ada entry body barrier
conditions.

Changes
-------
* Added Production_Entry_Barrier_Condition.
* Updated entry body parsing so the condition after `when` is retained as a
  distinct structural position before the normal expression parser runs.
* Preserved existing Production_Entry_Barrier and Production_Entry_Body output.
* Added AUnit coverage for an entry body stub with a short-circuit barrier
  condition and recovery into a following object declaration.
* Updated README and release checklist notes.

Scope
-----
This improves structural grammar coverage for Ada entry body barrier
conditions. It is not compiler-grade legality checking for tasking context,
protected-entry placement, boolean type conformance, or rendezvous semantics.
