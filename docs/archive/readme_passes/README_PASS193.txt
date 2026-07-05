Editor IDE-grade outline / semantic colouring language model pass 193

Implemented fix nr 3 from the remaining-gap list: indexed Outline body/spec navigation no longer chooses the first project-index match when multiple candidates still satisfy the name/kind/body/profile filters.

Changes:
- Added Editor.Ada_Project_Index.Resolve_Unique_Navigation_Target.
- Updated outline.goto-body / outline.goto-spec target discovery to use the unique-target helper.
- Duplicate same-name retained targets now return Ambiguous and no available navigation target.
- Profile-specific overload candidates still resolve when exactly one indexed symbol matches.
- Added AUnit coverage for ambiguous duplicate rejection and profile-specific unique target selection.
- Updated docs/outline.md, docs/syntax_colouring.md, docs/commands.md, and release_check guards.

Validation in this environment:
- Static source inspection only; GNAT/gprbuild/AUnit are unavailable here.
- Confirmed no Python or shell scripts were added.
