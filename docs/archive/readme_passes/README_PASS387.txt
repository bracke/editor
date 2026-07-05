Editor IDE-grade outline/semantic language model - pass387

This pass extends executable select-statement binding for timed select alternatives.

Changes:
- Added Binding_Select_Delay_Target to Editor.Ada_Language_Model.
- Parser-owned executable binding extraction now recognizes select delay
  alternatives separately from entry-call alternatives.
- `or delay until Deadline;` and `select delay Timeout;` retain the delay
  expression target as Binding_Select_Delay_Target.
- Select delay alternatives no longer disappear merely because `delay` is an Ada
  keyword and no longer risk being confused with selectable entry calls.
- Added regression coverage in Test_Language_Model_Executable_Select_Bindings.

Still conservative:
- No GNAT-equivalent select/timed-entry-call legality checking.
- No full tasking semantic model.
- Unknown select delay expressions degrade through No_Symbol instead of being
  guessed.
- No rendering-side parsing, external compiler/LSP integration, Python, shell
  scripts, .pyc files, or parser generators were added.
