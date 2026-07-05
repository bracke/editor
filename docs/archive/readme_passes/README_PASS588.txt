Pass 588 - Qualified constrained String expression bounds

- Extended bounded static String-bound evaluation so a constrained String qualified expression preserves the qualified subtype's retained bounds.
- Forms such as Offset_Name'("Green")'First, Offset_Name'("Green")'Last, and Offset_Name'("Green")'Length now feed representation-expression static values directly.
- Preserved component-count validation from pass586 before exposing qualified-expression bounds.
- Unconstrained String qualified expressions keep the existing literal/image-derived lower bound of 1.
- Added regression coverage to the static String Length/First/Last representation test path.
