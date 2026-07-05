Editor IDE-grade Outline / Semantic Colouring / Ada Parser - Pass 652

Focus: accept-statement entry/index/profile grammar.

Changes:
- Added accept-statement-specific token-cursor productions for accepted entry names, entry-family index expressions, optional accept parameter profiles, and accept do-part statement sequences.
- Updated accept-statement parsing so `accept E;`, `accept E (Index) (...) do ...`, and nested accept statements inside select alternatives retain their header/body structure explicitly.
- Preserved existing generic productions such as `Production_Name`, `Production_Entry_Index_Specification`, `Production_Parameter_Profile`, and generic statement-sequence markers for current consumers.
- Extended AUnit select/accept regression coverage with an indexed entry-family accept carrying a parameter profile and do-part statements.
- Updated README.md and docs/release/RELEASE_CHECKLIST.md with the pass652 scope and guard notes.

Boundary:
This improves structural grammar coverage for Ada accept statements. It is not compiler-grade legality checking for tasking context, entry-family conformance, accept-profile conformance, or rendezvous semantics.
