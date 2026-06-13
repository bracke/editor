Pass 464 - call named-actual legality

This pass extends the bounded Ada legality diagnostic layer with duplicate
named-actual checking for ordinary subprogram and entry-call association lists.

Implemented:
- Added Legality_Duplicate_Call_Named_Actual.
- Added a top-level argument-list scanner used by legality checking to count
  repeated named actual selectors within one retained call.
- Diagnoses calls such as:
    Configure (Mode => Fast, Count => 1, Mode => Slow);
- Keeps the check bounded and syntactic: it does not depend on overload
  resolution or target visibility, but avoids conflating unrelated calls by
  scanning the individual retained argument list.
- Added AUnit regression coverage in
  Test_Language_Model_Legality_Call_Named_Actual_Pass.
