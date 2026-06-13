# Build everything (default crate target)
alias eb='alr build'

# --- App ---
alias eab='alr exec -- gprbuild -P editor_app.gpr'
alias ear='alr exec -- bin/main'
alias eac='alr exec -- gprclean -P editor_app.gpr'

# --- Core (library only) ---
alias ecb='alr exec -- gprbuild -P editor_core.gpr'
alias ecc='alr exec -- gprclean -P editor_core.gpr'

# --- Full clean ---
alias eclean='rm -rf obj bin lib'

# --- Quick rebuild & run ---
alias et='etb && etr'
alias ea='eab && ear'
