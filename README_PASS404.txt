Pass 404 — executable entry-family index metadata

Implemented one more executable Ada expression/name binding completeness pass.

Changes:
- Added Binding_Entry_Family_Index to Editor.Ada_Language_Model.
- Parser-owned executable binding extraction now distinguishes entry-family calls such as:
  G.Take (1);
  from array indexing when the parenthesized prefix resolves to a retained entry declaration.
- Entry-family indexes are retained as tasking/name-shape metadata rather than Binding_Array_Index, avoiding false array-index classification for protected/task entry families.
- Declaration-shaped `entry ...` lines are excluded from generic executable expression scans while existing entry barrier metadata remains parser-owned.
- Added AUnit coverage for entry-family index binding retention and non-regression against array-index classification.

Still conservative:
- No GNAT-equivalent entry-family legality checking.
- No tasking control-flow model.
- The binding records the entry prefix/index shape; it does not infer runtime dispatch or queueing semantics.
