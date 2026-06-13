Pass 339 — token-cursor context/use/label grammar completeness

This pass extends the Ada token-cursor grammar layer with structural productions for context clauses and labels:

* with clauses are retained as Production_With_Clause rather than only the coarse context-clause event;
* ordinary use clauses, use type clauses, and Ada 2012 use all type clauses are retained distinctly;
* selected names inside context/use clauses are parsed through the token-cursor name/expression path;
* Ada labels and labeled statements are retained through Production_Label and Production_Labeled_Statement;
* AUnit coverage and phase validation guards were extended for these productions.

The parser remains bounded and deterministic; this pass does not add compiler-grade legality checking.
