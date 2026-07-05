Editor IDE-grade Outline/Semantic Colouring - Pass 194

Completeness focus:
- Removed the dormant Append_Ada_Line declaration-leading Ada scanner from Editor.Outline_Extractor.
- Kept parser-owned Ada declaration extraction as the only normal Ada outline source.
- Preserved marker-only fallback for explicit @outline rows when parser analysis yields zero symbols.
- Extended release_check so the removed scanner procedure cannot be reintroduced silently.
- Updated docs/outline.md and README.md.

Validation performed in this environment:
- Static grep confirmed no procedure Append_Ada_Line remains.
- Static grep confirmed no Append_Source_Line remains.
- Static grep confirmed no Ada_Like outline gate remains.
- Static grep confirmed no Python or shell scripts were added.

GNAT/gprbuild/AUnit were not available in this environment, so compile and unit-test validation must be run in a proper Ada toolchain environment.
