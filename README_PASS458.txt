Pass 458 - generic others-association legality

Focus
- Adds the next bounded Ada legality pass on top of the pass 457 generic
  actual association checks.

Implemented
- Added legality diagnostics for malformed generic/formal-package
  ``others`` actual associations:
  * Legality_Generic_Others_Actual_Not_Last
  * Legality_Generic_Others_Actual_Must_Be_Box
- Checks retained generic actual metadata so ``others => <>`` is accepted
  only as a final catch-all association, and ``others`` with any non-box
  actual is diagnosed.
- Added focused AUnit coverage:
  * Test_Language_Model_Legality_Generic_Others_Association_Pass

Notes
- This remains intentionally bounded legality checking.  Generic contract
  matching, formal/actual type conformance, and expected-type resolution are
  still deeper semantic passes.
