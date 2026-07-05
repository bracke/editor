Pass 524 - Suppress/Unsuppress named association unification

Implemented a focused convergence fix in the representation/operational pragma lowering layer.

Changes:
- Replaced the brittle Suppress/Unsuppress target scanner with the shared named-association target scanner.
- `pragma Suppress (Check_Name => X, On=>Entity);` and out-of-order named forms now bind the retained representation item to `Entity`.
- Added `Check_Name =>` as an accepted named value source for `Suppress` and `Unsuppress`.
- Kept the lowered metadata on the shared `Representation_Kind_For` resolver path, so duplicate detection, target compatibility and value diagnostics remain shared with aspect and attribute-definition forms.
