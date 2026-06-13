Pass 563 - static discrete bound-attribute constants

Implemented another bounded static-evaluation improvement in the Ada semantic
language model.

Changes:
- Added retained typed discrete constants initialized from scalar bound
  attributes:
  - T'First
  - T'Last
  - T'Base'First
  - T'Base'Last
- Bound-attribute initialized constants now feed later static representation
  expressions, for example:
  - First_Color : constant Color := Color'First;
  - Last_Color  : constant Color := Color'Last;
  - for Target'Size use Color'Pos (Last_Color) * 8;
- Preserved subtype compatibility and range validation before adding these
  constants to the reusable discrete static environment.
- Out-of-range constrained subtype constants initialized from a wider base
  bound remain nonstatic and produce the existing static-value diagnostic.
- Extended regression coverage for First, Last, Base'Last, and constrained
  subtype rejection.
