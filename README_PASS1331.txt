Pass1331: Ada library unit / separate subunit vertical slice legality

Added Editor.Ada_Library_Unit_Subunit_Vertical_Slice_Legality.

This pass continues the post-Pass1296 vertical-slice strategy with a concrete
Ada library-unit and subunit legality engine.  It checks separate subunits,
body stubs, parent unit matching, nested separate bodies, library unit
completion, child unit legality, private child body visibility, body/spec
ordering, duplicate bodies/subunits, limited/private/incomplete/generic-formal
view blockers, and source/unit/body/stub/closure fingerprint freshness.

Added AUnit coverage in
Test_Ada_Library_Unit_Subunit_Vertical_Slice_Legality_Pass1331 and registered
it in Core_Suite.
