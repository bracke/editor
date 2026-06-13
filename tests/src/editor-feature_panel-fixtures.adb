with Editor.State;
with Ada.Directories;
with Editor.Project;
with Editor.Pending_Transitions;
with Editor.Keybindings;
with Editor.Keybinding_Config;
with Editor.Executor;
with Editor.Dirty_Guards;
with Editor.Commands;
with Ada.Strings.Unbounded;

package body Editor.Feature_Panel.Fixtures is


   procedure Set_Placeholder_Rows
     (Panel : in out Feature_Panel_State)
   is
   begin
      Clear_Rows (Panel);
      Append_Row
        (Panel, Feature_Row_Header, "Feature Panel", "test fixture rows",
         Selectable => False, Is_Diagnostic => True);
      Append_Row
        (Panel, Feature_Row_Item, "Placeholder Item", "test fixture data",
         Selectable => True, Can_Clear => True);
      Append_Row
        (Panel, Feature_Row_Item, "Another Placeholder Item", "test fixture data",
         Selectable => True, Can_Clear => True);
      pragma Assert (Row_Count (Panel) = 3,
                     "feature-panel placeholder fixture row count");
      pragma Assert (not Has_Selection (Panel),
                     "feature-panel placeholder fixture does not select");
   end Set_Placeholder_Rows;

   function Base_State return Editor.State.State_Type
   is
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      pragma Assert (Invariant_Holds (S.Feature_Panel),
                     "feature-panel fixture base invariant");
      return S;
   end Base_State;

   function State_With_Feature_Panel_Hidden
     return Editor.State.State_Type
   is
      S : Editor.State.State_Type := Base_State;
   begin
      Set_Visible (S.Feature_Panel, False);
      pragma Assert (not Is_Visible (S.Feature_Panel),
                     "hidden fixture postcondition");
      return S;
   end State_With_Feature_Panel_Hidden;

   function State_With_Feature_Panel_Visible
     return Editor.State.State_Type
   is
      S : Editor.State.State_Type := Base_State;
   begin
      Set_Visible (S.Feature_Panel, True);
      pragma Assert (Is_Visible (S.Feature_Panel),
                     "visible fixture postcondition");
      return S;
   end State_With_Feature_Panel_Visible;

   function State_With_Feature_Panel_Focused
     return Editor.State.State_Type
   is
      S : Editor.State.State_Type := State_With_Feature_Panel_Visible;
   begin
      Set_Focused (S.Feature_Panel, True);
      pragma Assert (Is_Focused (S.Feature_Panel),
                     "focused fixture postcondition");
      return S;
   end State_With_Feature_Panel_Focused;

   function State_With_Feature_Panel_Rows
     return Editor.State.State_Type
   is
      S : Editor.State.State_Type := State_With_Feature_Panel_Visible;
   begin
      Set_Placeholder_Rows (S.Feature_Panel);
      pragma Assert (Row_Count (S.Feature_Panel) = 3,
                     "rows fixture postcondition");
      pragma Assert (not Has_Selection (S.Feature_Panel),
                     "rows fixture does not select implicitly");
      return S;
   end State_With_Feature_Panel_Rows;

   function State_With_Feature_Panel_Selected_Row
     return Editor.State.State_Type
   is
      S : Editor.State.State_Type := State_With_Feature_Panel_Rows;
   begin
      Select_First (S.Feature_Panel);
      pragma Assert (Has_Selection (S.Feature_Panel),
                     "selected-row fixture postcondition");
      return S;
   end State_With_Feature_Panel_Selected_Row;

   function State_With_Feature_Panel_Visible_And_Empty
     return Editor.State.State_Type
   is
      S : Editor.State.State_Type := State_With_Feature_Panel_Visible;
   begin
      Clear_Rows (S.Feature_Panel);
      pragma Assert (Row_Count (S.Feature_Panel) = 0,
                     "visible-empty fixture postcondition");
      return S;
   end State_With_Feature_Panel_Visible_And_Empty;


   function State_With_Project_And_Feature_Panel_Rows
     return Editor.State.State_Type
   is
      S : Editor.State.State_Type := State_With_Feature_Panel_Rows;
      Path   : constant String := "/tmp/editor-phase118-project";
      Result : Editor.Project.Project_Open_Result;
   begin
      if not Ada.Directories.Exists (Path) then
         Ada.Directories.Create_Directory (Path);
      end if;
      Result := Editor.Project.Open_Project (Path);
      Editor.Project.Apply_Open_Result (S.Project, Result);
      pragma Assert (Editor.Project.Has_Project (S.Project),
                     "project + rows fixture opens project root");
      pragma Assert (Row_Count (S.Feature_Panel) = 3,
                     "project + rows fixture preserves rows");
      return S;
   end State_With_Project_And_Feature_Panel_Rows;

   function State_With_Dirty_Buffer_And_Feature_Panel_Rows
     return Editor.State.State_Type
   is
      S : Editor.State.State_Type := State_With_Feature_Panel_Rows;
   begin
      Editor.State.Set_Dirty (S, True);
      pragma Assert (Editor.State.Is_Dirty (S),
                     "dirty-buffer fixture marks active buffer dirty");
      pragma Assert (Row_Count (S.Feature_Panel) = 3,
                     "dirty-buffer fixture preserves feature rows");
      return S;
   end State_With_Dirty_Buffer_And_Feature_Panel_Rows;

   function State_With_Pending_Transition_And_Feature_Panel_Rows
     return Editor.State.State_Type
   is
      S : Editor.State.State_Type := State_With_Feature_Panel_Rows;
      Target : Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Project,
         Path       => Ada.Strings.Unbounded.To_Unbounded_String ("/tmp/phase118-next"),
         Display    => Ada.Strings.Unbounded.To_Unbounded_String ("phase118-next"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => True,
         others     => <>);
      Summary : Editor.Dirty_Guards.Dirty_Buffer_Summary :=
        (Dirty_Count => 1, Untitled_Count => 0, File_Backed_Count => 1);
   begin
      Editor.Pending_Transitions.Set_Pending (S.Pending_Transitions, Target, Summary);
      pragma Assert (Editor.Pending_Transitions.Has_Pending (S.Pending_Transitions),
                     "pending-transition fixture has pending state");
      pragma Assert (Row_Count (S.Feature_Panel) = 3,
                     "pending-transition fixture preserves feature rows");
      return S;
   end State_With_Pending_Transition_And_Feature_Panel_Rows;

   function State_With_Command_Palette_And_Feature_Panel_Rows
     return Editor.State.State_Type
   is
      S : Editor.State.State_Type := State_With_Feature_Panel_Rows;
   begin
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Open_Command_Palette);
      pragma Assert (Row_Count (S.Feature_Panel) = 3,
                     "command-palette fixture preserves feature rows");
      return S;
   end State_With_Command_Palette_And_Feature_Panel_Rows;

   function State_With_Custom_Keybindings_For_Feature_Panel
     return Editor.State.State_Type
   is
      S      : Editor.State.State_Type := State_With_Feature_Panel_Rows;
      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Chord  : Editor.Keybindings.Key_Chord;
      Found  : Boolean := False;
   begin
      Editor.Keybinding_Config.Clear (Config);
      Chord := Editor.Keybindings.Parse_Chord ("Ctrl+Alt+F", Found);
      pragma Assert (Found, "feature-panel fixture chord parses");
      Editor.Keybinding_Config.Bind
        (Config, Editor.Commands.Command_Toggle_Feature_Panel, Chord);
      Editor.Keybinding_Config.Apply_To_Runtime (Config);
      pragma Assert
        (Editor.Keybindings.Primary_Binding_For_Command
           (Editor.Commands.Command_Toggle_Feature_Panel).Has_Binding,
         "custom-keybinding fixture exposes feature-panel chord");
      return S;
   end State_With_Custom_Keybindings_For_Feature_Panel;

end Editor.Feature_Panel.Fixtures;
