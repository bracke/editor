Pass 340: token-cursor separate/body-stub grammar completeness

Implemented first-class token-cursor productions for separate subunits and body stubs:
- Production_Separate_Subunit
- Production_Package_Body_Stub
- Production_Subprogram_Body_Stub
- Production_Task_Body_Stub
- Production_Protected_Body_Stub
- Production_Entry_Body_Stub

Separate parent unit names are parsed through the existing expression/name path, which records selected-name productions for dotted parent units.
