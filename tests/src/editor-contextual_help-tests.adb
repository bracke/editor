with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Editor.Commands;
with Editor.Feature_Panel;
with Editor.Keybindings;
with Editor.Status_Bar;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Contextual_Help.Tests is

   overriding function Name
     (T : Contextual_Help_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Contextual_Help");
   end Name;

   procedure Test_Empty_State_Text_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert
        (Empty_Messages_Detail =
         "Command feedback appears here; nothing to clear.",
         "Messages empty-state help must be stable");
      Assert
        (Empty_Diagnostics_Detail =
         "Diagnostics appear here; nothing to navigate.",
         "Diagnostics empty-state help must be stable");
      Assert
        (Empty_Search_Results_Detail (False) =
         "Search the active buffer to list matches here.",
         "Search empty-state help must be stable before first query");
      Assert
        (Empty_Search_Results_Detail (True) =
         "No matches in the active buffer.",
         "Search no-match help must be stable after a query");
      Assert
        (Empty_Outline_Detail (False) =
         "Open a buffer before refreshing the outline.",
         "Outline missing-buffer hint must be stable");
      Assert
        (Empty_File_Tree_Text (False) = "Open a project to show files",
         "File tree missing-project hint must be stable");
      Assert
        (Command_Palette_No_Match_Detail (False) =
         "Clear the query to show available commands.",
         "Command Palette no-match guidance must be stable");
   end Test_Empty_State_Text_Is_Deterministic;

   procedure Test_Shortcut_Hints_Use_Active_Keybindings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Chord : constant Editor.Keybindings.Key_Chord :=
        (Key       => Editor.Keybindings.Key_P,
         Modifiers => (Ctrl => True, Shift => False, Alt => False, Meta => False));
      Command : constant Editor.Commands.Command_Id :=
        Editor.Commands.Command_Open_Command_Palette;
   begin
      Editor.Keybindings.Clear;
      Assert (Shortcut_Text (Command, True) = "",
              "Unbound command must not produce a shortcut hint");

      Editor.Keybindings.Bind (Chord, Command);
      Assert (Shortcut_Text (Command, True) = "Ctrl+P",
              "Active runtime binding must be projected into hints");
      Assert (Shortcut_Text (Command, False) = "",
              "Disabled shortcut display must hide shortcut hints");
      Assert (With_Shortcut ("Open palette", Command, True) =
              "Open palette [Ctrl+P]",
              "Shortcut decoration must be deterministic");

      Editor.Keybindings.Unbind_Command (Command);
      Assert (Shortcut_Text (Command, True) = "",
              "Removed shortcut must disappear from hints");
   end Test_Shortcut_Hints_Use_Active_Keybindings;

   procedure Test_Public_Build_Command_Is_Never_Hinted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Chord : constant Editor.Keybindings.Key_Chord :=
        (Key       => Editor.Keybindings.Key_F12,
         Modifiers => (Ctrl => True, Shift => False, Alt => False, Meta => False));
      Command : constant Editor.Commands.Command_Id :=
        Editor.Commands.Command_Build_Run_User_Opt_In_Test_Seam;
   begin
      Editor.Keybindings.Clear;
      Editor.Keybindings.Bind (Chord, Command);
      Assert (Shortcut_Text (Command, True) = "",
              "Internal/public-build test-seam command must not be hinted");
      Assert (Index (With_Shortcut ("Run build", Command, True), "F12") = 0,
              "Build shortcut text must not leak into help");
   end Test_Public_Build_Command_Is_Never_Hinted;

   procedure Test_Focus_Hints_Are_Compact
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Focus_Hint ("Command Palette", True) =
              "type to filter, Enter to run, Esc to close",
              "Command Palette focus hint must be stable");
      Assert (Focus_Hint ("Feature Panel", True) =
              "Up/Down to move, Enter to open, Esc to editor",
              "Feature Panel focus hint must be stable");
      Assert (Focus_Hint ("File Tree", True) =
              "Up/Down to move, Enter to open, Esc to editor",
              "File Tree focus hint must be stable");
      Assert (Focus_Hint ("Search Results", True) =
              "Up/Down to move, Enter to open, Esc to editor",
              "Search Results focus hint must be stable");
      Assert (Focus_Hint ("Problems", True) =
              "Up/Down to move, Enter to open, Esc to editor",
              "Problems focus hint must be stable");
      Assert (Focus_Hint ("Quick Open", True) =
              "type to filter, Enter to open, Esc to close",
              "Quick Open focus hint must be keyboard-specific");
      Assert (Focus_Hint ("Search Query", True) =
              "type query, Enter to search, Esc to cancel",
              "Search input focus hint must be stable");
      Assert (Focus_Hint ("Unknown", True) = "",
              "Unknown focus surfaces must not emit noisy hints");
   end Test_Focus_Hints_Are_Compact;

   procedure Test_Status_Bar_Formats_Focus_Hint
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Snapshot : Editor.Status_Bar.Status_Bar_Snapshot;
      Text     : Unbounded_String;
   begin
      Snapshot.Line_Number_Mode := To_Unbounded_String ("absolute lines");
      Snapshot.Focus_Label := To_Unbounded_String ("Command Palette");
      Snapshot.Focus_Hint := To_Unbounded_String
        ("type to filter, Enter to run, Esc to close");
      Text := To_Unbounded_String (Editor.Status_Bar.Format_Right (Snapshot));
      Assert (Index (To_String (Text), "type to filter") > 0,
              "Status Bar must include focused-surface guidance when present");
   end Test_Status_Bar_Formats_Focus_Hint;

   procedure Test_Selected_Row_Action_Hint
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Empty_Row : constant Editor.Feature_Panel.Feature_Panel_Render_Row :=
        (Kind => Editor.Feature_Panel.Feature_Row_Empty_State,
         Label => Null_Unbounded_String,
         Detail => Null_Unbounded_String,
         Selected => False,
         Is_Current_Symbol => False,
         Selectable => False,
         Activatable => False,
         Has_Target => False,
         Is_Diagnostic => False,
         Can_Open => False,
         Can_Copy => False,
         Can_Clear => False,
         Can_Reveal => False,
         Action_Id => Editor.Feature_Panel.No_Feature_Action,
         Source_Index => 0,
         Severity => Editor.Feature_Panel.Feature_Row_No_Severity);
      Open_Row : constant Editor.Feature_Panel.Feature_Panel_Render_Row :=
        (Kind => Editor.Feature_Panel.Feature_Row_Item,
         Label => Null_Unbounded_String,
         Detail => Null_Unbounded_String,
         Selected => True,
         Is_Current_Symbol => False,
         Selectable => True,
         Activatable => True,
         Has_Target => True,
         Is_Diagnostic => False,
         Can_Open => True,
         Can_Copy => False,
         Can_Clear => False,
         Can_Reveal => False,
         Action_Id => Editor.Feature_Panel.No_Feature_Action,
         Source_Index => 1,
         Severity => Editor.Feature_Panel.Feature_Row_No_Severity);
   begin
      Assert (Selected_Row_Action_Hint (Empty_Row, True) = "",
              "Empty-state rows must not advertise activation");
      Assert (Index (Selected_Row_Action_Hint (Open_Row, False), "opens") > 0,
              "Openable rows must describe Enter activation");
      Assert (Command_Row_Action_Hint
                (Editor.Commands.Command_Save_File, True, "", False) =
              "Enter runs selected command",
              "Available command rows must describe Enter execution");
      Assert (Command_Row_Action_Hint
                (Editor.Commands.Command_Save_File, False, "No active buffer.", True) =
              "No active buffer.",
              "Disabled command rows must project the disabled reason");
      Assert (File_Tree_Row_Action_Hint (False, False, False) =
              "Enter opens selected file",
              "File rows must describe primary open activation");
      Assert (File_Tree_Row_Action_Hint (True, False, False) =
              "Enter expands selected folder",
              "Collapsed folder rows must describe expand activation");
      Assert (File_Tree_Row_Action_Hint (True, True, False) =
              "Enter collapses selected folder",
              "Expanded folder rows must describe collapse activation");
      Assert (Open_Buffer_Row_Action_Hint (False, True, False) =
              "Enter activates selected buffer, close available",
              "Open-buffer rows must project activate and close affordances");
   end Test_Selected_Row_Action_Hint;


   procedure Test_Row_Accessible_Labels_Are_Readable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Diagnostic_Row : constant Editor.Feature_Panel.Feature_Panel_Render_Row :=
        (Kind => Editor.Feature_Panel.Feature_Row_Item,
         Label => To_Unbounded_String ("Unused variable"),
         Detail => To_Unbounded_String ("main.adb:12"),
         Selected => True,
         Is_Current_Symbol => False,
         Selectable => True,
         Activatable => True,
         Has_Target => True,
         Is_Diagnostic => True,
         Can_Open => True,
         Can_Copy => True,
         Can_Clear => True,
         Can_Reveal => False,
         Action_Id => Editor.Feature_Panel.No_Feature_Action,
         Source_Index => 1,
         Severity => Editor.Feature_Panel.Feature_Row_Warning_Severity);
      Empty_Row : constant Editor.Feature_Panel.Feature_Panel_Render_Row :=
        (Kind => Editor.Feature_Panel.Feature_Row_Empty_State,
         Label => Null_Unbounded_String,
         Detail => To_Unbounded_String ("No matches"),
         Selected => False,
         Is_Current_Symbol => False,
         Selectable => False,
         Activatable => False,
         Has_Target => False,
         Is_Diagnostic => False,
         Can_Open => False,
         Can_Copy => False,
         Can_Clear => False,
         Can_Reveal => False,
         Action_Id => Editor.Feature_Panel.No_Feature_Action,
         Source_Index => 0,
         Severity => Editor.Feature_Panel.Feature_Row_No_Severity);
   begin
      Assert
        (Row_Accessible_Label (Diagnostic_Row) =
         "warning: Unused variable — main.adb:12",
         "Diagnostic-style row labels must include severity, text, and location");
      Assert
        (Row_Accessible_Label (Empty_Row) = "empty: No matches",
         "Empty rows need deterministic readable fallback text");
      Assert
        (Command_Row_Accessible_Label
           ("Save File", "File", "Write active buffer", True, "") =
         "Save File (File) — Write active buffer",
         "Command rows must be readable without icon-only affordances");
      Assert
        (Command_Row_Accessible_Label
           ("Save File", "File", "", False, "No active buffer.") =
         "Save File (File) — No active buffer.",
         "Disabled command rows must expose the user-facing reason");
      Assert
        (File_Tree_Row_Accessible_Label ("src", True, True) =
         "folder selected: src",
         "File tree labels must distinguish folders from files");
      Assert
        (File_Tree_Row_Accessible_Label ("main.adb", False, False) =
         "file: main.adb",
         "File tree labels must distinguish files from folders");
   end Test_Row_Accessible_Labels_Are_Readable;

   procedure Test_Truncation_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Truncate ("abcdef", 0) = "", "Zero width truncates to empty");
      Assert (Truncate ("abcdef", 2) = "ab", "Narrow width truncates directly");
      Assert (Truncate ("abcdef", 5) = "ab...", "Wide truncation uses ASCII ellipsis");
      Assert (Truncate ("abc", 5) = "abc", "Short text is unchanged");
   end Test_Truncation_Is_Deterministic;

   overriding procedure Register_Tests
     (T : in out Contextual_Help_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Empty_State_Text_Is_Deterministic'Access,
         "Empty State Text Is Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Shortcut_Hints_Use_Active_Keybindings'Access,
         "Shortcut Hints Use Active Keybindings");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Public_Build_Command_Is_Never_Hinted'Access,
         "Public Build Command Is Never Hinted");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Focus_Hints_Are_Compact'Access,
         "Focus Hints Are Compact");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Status_Bar_Formats_Focus_Hint'Access,
         "Status Bar Formats Focus Hint");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Selected_Row_Action_Hint'Access,
         "Selected Row Action Hint");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Row_Accessible_Labels_Are_Readable'Access,
         "Row Accessible Labels Are Readable");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Truncation_Is_Deterministic'Access,
         "Truncation Is Deterministic");
   end Register_Tests;

end Editor.Contextual_Help.Tests;
