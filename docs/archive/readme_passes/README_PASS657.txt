Editor Pass 657
============================

Focus
-----
Improve structural grammar coverage for statement-level call and entry-call forms by retaining target-name and actual-part positions explicitly.

Implementation
--------------
- Added token-cursor productions:
  - Production_Call_Target
  - Production_Call_Actual_Part
  - Production_Entry_Call_Target
  - Production_Entry_Call_Actual_Part
- Updated identifier-led statement classification so ordinary calls emit their target position.
- Calls with apparent actual parts now emit an explicit call actual-part production.
- Entry-call-shaped statements with selected/indexed suffixes or actual parts retain target and actual-part positions separately from the generic call statement classification.
- Existing selected-name, indexed-component, and generic call/entry-call productions remain intact for current consumers.

Tests
-----
- Added AUnit regression coverage for:
  - bare call statements
  - selected calls with named actuals
  - entry-family-shaped calls with indexes and actuals
  - parser recovery into a following assignment statement
- Extended the broader statement grammar completeness test to require call/entry-call target and actual-part productions.

Scope
-----
This improves structural grammar coverage for Ada call and entry-call statement targets and actual parts. It is not compiler-grade legality checking for callable target resolution, entry-family conformance, overload resolution, parameter-mode legality, or dispatching semantics.
