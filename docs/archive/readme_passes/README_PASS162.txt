Editor pass 162

Focused change:
- Hardened Editor.Ada_Project_Index qualified-name construction.
- Selected-name prefixes are now built only through declaration-owning parent symbols.
- Malformed rows attached to value-like parent symbols no longer fabricate project-wide selected targets.
- Added Test_Project_Index_Non_Owner_Parent_Does_Not_Qualify_Name.
- Updated outline/semantic-colouring docs and release_check guards.

Build note:
- GNAT/gprbuild was not available in this environment, so the Ada build/AUnit suite was not run here.
