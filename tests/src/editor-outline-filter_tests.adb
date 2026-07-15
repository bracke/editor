with Editor.Test_Temp;
with Ada.Characters.Handling;
with Editor.Test_Helper;
with Editor.Pending_Transitions;
with Editor.Buffers;
with Ada.Text_IO;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Outline.Fixtures; use Editor.Outline.Fixtures;
with Editor.Ada_Syntax_Core;
with Editor.Commands;
with Editor.Cursors;
with Editor.Executor;
with Editor.Executor.File_Save_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Outline_Commands;
with Editor.Feature_Panel;
with Editor.Feature_Panel.Fixtures; use Editor.Feature_Panel.Fixtures;
with Editor.Keybinding_Config;
with Editor.Keybindings;
with Editor.Messages;
with Editor.Outline_Extractor;
with Editor.Outline_Audit;
with Editor.Panel_Focus;
with Editor.State;
with Editor.Render_Model;
with Editor.Workspace_Persistence;

package body Editor.Outline.Filter_Tests is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Executor.Command_Execution_Status;
   use type Editor.Outline.Outline_Item_Kind;
   use type Editor.Outline.Outline_Target_Kind;
   use type Editor.Outline.Outline_Refresh_Status;
   use type Editor.Outline.Outline_Refresh_Failure_Kind;
   use type Editor.Cursors.Cursor_Index;
   use type Editor.Keybindings.Binding_Result;
   use type Editor.Keybindings.Keybinding_Validation_Status;
   use type Editor.Panel_Focus.Focus_Target;
   use type Editor.Outline.Outline_Source_Class;
   use type Editor.Outline.Outline_Freshness;
   use type Editor.Outline_Extractor.Extraction_Status;
   use type Editor.Outline_Extractor.Extraction_Failure_Kind;
   use type Editor.Feature_Panel.Feature_Panel_Row_Kind;
   use type Editor.Feature_Panel.Feature_Panel_Fingerprint;

   function Active_Message_Text (S : Editor.State.State_Type) return String is
      Found : Boolean := False;
      Msg   : Editor.Messages.Editor_Message;
   begin
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      if Found then
         return Editor.Messages.Text (Msg);
      end if;
      return "";
   end Active_Message_Text;

   function Name (T : Filter_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Outline.Filter.Tests");
   end Name;

   procedure Populate_Synthetic_Outline
     (O : in out Outline_State)
   is
      Result : constant Outline_Refresh_Result := Editor.Outline.Fixtures.Populate_Synthetic_Outline (O);
   begin
      pragma Assert (Result.Status = Outline_Refresh_Ok,
                     "synthetic outline fixture refresh succeeds");
   end Populate_Synthetic_Outline;

   function First_Label_Index
     (O     : Outline_State;
      Label : String) return Natural
   is
   begin
      for I in 1 .. Item_Count (O) loop
         if Item_Label (O, I) = Label then
            return I;
         end if;
      end loop;

      return 0;
   end First_Label_Index;

   function Has_Label
     (O     : Outline_State;
      Label : String) return Boolean
   is
   begin
      return First_Label_Index (O, Label) /= 0;
   end Has_Label;

   procedure Assert_Has_Label
     (O       : Outline_State;
      Label   : String;
      Message : String)
   is
   begin
      Assert (Has_Label (O, Label), Message);
   end Assert_Has_Label;

   function Temp_Path (Name : String) return String is
   begin
      return Editor.Test_Temp.Base & "/editor_outline_" & Name;
   end Temp_Path;

   procedure Remove_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   exception
      when others =>
         null;
   end Remove_If_Exists;

   procedure Write_Text
     (Path : String;
      Text : String)
   is
      package Stream_IO renames Ada.Streams.Stream_IO;
      File  : Stream_IO.File_Type;
      Bytes : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Text'Length));
   begin
      for I in Text'Range loop
         Bytes (Ada.Streams.Stream_Element_Offset (I - Text'First + 1)) :=
           Ada.Streams.Stream_Element (Character'Pos (Text (I)));
      end loop;

      Stream_IO.Create (File, Stream_IO.Out_File, Path);
      if Text'Length > 0 then
         Stream_IO.Write (File, Bytes);
      end if;
      Stream_IO.Close (File);
   exception
      when others =>
         if Stream_IO.Is_Open (File) then
            Stream_IO.Close (File);
         end if;
         raise;
   end Write_Text;


   function Contains_Lexical_State_Term (Text : String) return Boolean is
      Lower : constant String := Ada.Characters.Handling.To_Lower (Text);
   begin
      return Ada.Strings.Fixed.Index (Lower, "scanner") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "sanitized") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "token mask") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "lexical state") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "comment map") /= 0
        or else Ada.Strings.Fixed.Index (Lower, "string map") /= 0;
   end Contains_Lexical_State_Term;

   procedure Test_Outline_Filter_Matches_Label_Case_Insensitive
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Package,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Editor.Outline"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("package"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 1,
            Column       => 1),
         2 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 1,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4),
         3 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 1,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Select_Item (O, 3);
      Apply_Filter (O, "REFRESH");
      Set_Rows_From_Outline (O, P);

      Assert (Filter_Is_Active (O), "filter is active after non-empty query");
      Assert (Filtered_Row_Count (O) = 1, "filter keeps exactly the matching row");
      Assert (Editor.Feature_Panel.Row_Count (P) = 1,
              "filtered projection exposes only matching rows");
      Assert (Editor.Feature_Panel.Row_Label (P, 1) = "Refresh_Model",
              "case-insensitive label filter projects matching symbol");
      Assert (Selected_Index (O) = 2,
              "hidden selection is reconciled to first visible selectable row");
      Assert (Editor.Feature_Panel.Selected_Row (P) = 1,
              "panel selection uses visible filtered row index");
      Assert (Map_Panel_Row_To_Outline_Row (O, P, 1) = 2,
              "filtered visible row maps back to underlying outline row");
   end Test_Outline_Filter_Matches_Label_Case_Insensitive;

   procedure Test_Outline_Clear_Filter_Restores_All_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Package,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Editor.Outline"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("package"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 1,
            Column       => 1),
         2 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 1,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Apply_Filter (O, "procedure");
      Set_Rows_From_Outline (O, P);
      Assert (Editor.Feature_Panel.Row_Count (P) = 1,
              "kind-text filter keeps procedure row");

      Clear_Filter (O);
      Set_Rows_From_Outline (O, P);
      Assert (not Filter_Is_Active (O), "clear-filter deactivates filter");
      Assert (Filtered_Row_Count (O) = 2, "clear-filter restores full count");
      Assert (Editor.Feature_Panel.Row_Count (P) = 2,
              "clear-filter restores all projected rows");
      Assert (Map_Panel_Row_To_Outline_Row (O, P, 2) = 2,
              "unfiltered row mapping remains direct after clear");
   end Test_Outline_Clear_Filter_Restores_All_Rows;

   procedure Test_Outline_Focus_Filter_Activates_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Apply_Filter (O, "ref");
      Activate_Filter_Input (O);

      Assert (Filter_Input_Is_Active (O),
              "focus-filter activates outline filter input mode");
      Assert (Filter_Text (O) = "ref",
              "focus-filter preserves existing filter text");
      Assert (Filter_Caret (O) = 3,
              "focus-filter places the caret at the end of the filter");
   end Test_Outline_Focus_Filter_Activates_Input;

   procedure Test_Filter_Input_Text_Rebuilds_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4),
         2 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Activate_Filter_Input (O);
      Insert_Filter_Character (O, 'c');
      Insert_Filter_Character (O, 'l');
      Set_Rows_From_Outline (O, P);

      Assert (Filter_Input_Is_Active (O),
              "typing keeps outline filter input active");
      Assert (Filter_Text (O) = "cl",
              "printable keys update filter text");
      Assert (Filtered_Row_Count (O) = 1,
              "filter text edit rebuilds filtered projection count");
      Assert (Editor.Feature_Panel.Row_Count (P) = 1,
              "filter text edit projects only matching rows");
      Assert (Editor.Feature_Panel.Row_Label (P, 1) = "Clear_Model",
              "filter text edit exposes the matching visible row");
   end Test_Filter_Input_Text_Rebuilds_Projection;

   procedure Test_Filter_Input_Backspace_Rebuilds_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4),
         2 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Activate_Filter_Input (O);
      Insert_Filter_Text (O, "clex");
      Delete_Filter_Character_Backward (O);
      Set_Rows_From_Outline (O, P);

      Assert (Filter_Text (O) = "cle",
              "Backspace removes the previous filter character");
      Assert (Filtered_Row_Count (O) = 1,
              "Backspace rebuilds filtered row count");
      Assert (Editor.Feature_Panel.Row_Label (P, 1) = "Clear_Model",
              "Backspace rebuilds visible projection");
   end Test_Filter_Input_Backspace_Rebuilds_Projection;

   procedure Test_Filter_Input_Escape_Rule
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Activate_Filter_Input (O);
      Insert_Filter_Text (O, "ref");
      Clear_Filter_Text (O);

      Assert (Filter_Input_Is_Active (O),
              "Escape with non-empty filter clears text but keeps input active");
      Assert (not Filter_Is_Active (O),
              "Escape clear restores unfiltered projection state");
      Assert (Filter_Text (O) = "",
              "Escape clear removes filter text");

      Deactivate_Filter_Input (O);
      Assert (not Filter_Input_Is_Active (O),
              "Escape with empty filter deactivates input mode");
   end Test_Filter_Input_Escape_Rule;

   procedure Test_Filter_Edit_Selection_Reconciliation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4),
         2 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Select_Item (O, 2);
      Activate_Filter_Input (O);
      Insert_Filter_Text (O, "clear");
      Assert (Selected_Index (O) = 2,
              "live filter preserves selected underlying row when still visible");

      Clear_Filter_Text (O);
      Insert_Filter_Text (O, "refresh");
      Assert (Selected_Index (O) = 1,
              "live filter selects first visible match when previous selection is hidden");

      Clear_Filter_Text (O);
      Insert_Filter_Text (O, "xyz");
      Assert (Selected_Index (O) = 0,
              "live filter clears selection when no selectable rows match");
   end Test_Filter_Edit_Selection_Reconciliation;

   procedure Test_Filter_Cleared_On_Outline_Clear
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Activate_Filter_Input (O);
      Insert_Filter_Text (O, "ref");
      Clear (O);

      Assert (Item_Count (O) = 0, "clear removes outline rows");
      Assert (not Filter_Input_Is_Active (O),
              "clear deactivates filter input");
      Assert (not Filter_Is_Active (O),
              "clear deactivates filter projection");
      Assert (Filter_Text (O) = "",
              "clear removes filter text");
   end Test_Filter_Cleared_On_Outline_Clear;

   procedure Test_Filter_Header_Shows_Text_And_Count
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4),
         2 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Activate_Filter_Input (O);
      Insert_Filter_Text (O, "ref");

      Assert (Outline_Header_Text (O) = "Outline: filter ""ref"" -- 1 of 2 symbols",
              "header shows filter text and match count");

      Clear_Filter_Text (O);
      Insert_Filter_Text (O, "xyz");
      Assert (Outline_Header_Text (O) = "Outline: filter ""xyz"" -- no matches",
              "header shows filter text and no-match state");
   end Test_Filter_Header_Shows_Text_And_Count;

   procedure Test_Filter_Command_Palette_Registers_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id;
   begin
      Assert (Editor.Commands.Label (Editor.Commands.Command_Focus_Outline_Filter) =
                "Focus Outline Filter",
              "focus filter has concise palette label");
      Assert (Editor.Commands.Label (Editor.Commands.Command_Clear_Outline_Filter) =
                "Clear Outline Filter",
              "clear filter has concise palette label");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("focus-outline-filter", Found);
      Assert (Found and then Id = Editor.Commands.Command_Focus_Outline_Filter,
              "focus filter stable command name round trips");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("toggle-outline-filter", Found);
      Assert (Found and then Id = Editor.Commands.Command_Toggle_Outline_Filter,
              "toggle filter stable command name round trips");
      Assert (Editor.Commands.Label
                (Editor.Commands.Command_Outline_Filter_History_Previous) =
                "Outline: Previous Filter",
              "previous filter history command has concise palette label");
      Id := Editor.Commands.Command_Id_From_Stable_Name
        ("outline-filter-history-previous", Found);
      Assert
        (Found and then
           Id = Editor.Commands.Command_Outline_Filter_History_Previous,
         "previous filter history stable command name round trips");
   end Test_Filter_Command_Palette_Registers_Commands;

   procedure Test_Filter_History_Adds_Deduplicates_And_Trims
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Apply_Filter (O, "Refresh");
      Commit_Filter_To_History (O);
      Apply_Filter (O, "");
      Commit_Filter_To_History (O);
      Assert (Filter_History_Count (O) = 1,
              "history stores non-empty committed filter only");
      Assert (Filter_History_Entry (O, 1) = "refresh",
              "history normalizes committed filter text");

      Apply_Filter (O, "clear");
      Commit_Filter_To_History (O);
      Apply_Filter (O, "refresh");
      Commit_Filter_To_History (O);
      Assert (Filter_History_Count (O) = 2,
              "duplicate history entry is moved instead of duplicated");
      Assert (Filter_History_Entry (O, 1) = "refresh",
              "duplicate history entry moves to most recent slot");

      for I in 1 .. 12 loop
         Apply_Filter (O, "filter" & Natural'Image (I));
         Commit_Filter_To_History (O);
      end loop;
      Assert (Filter_History_Count (O) = 10,
              "history enforces the fixed maximum size");
   end Test_Filter_History_Adds_Deduplicates_And_Trims;

   procedure Test_Filter_History_Navigation_Rebuilds_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4),
         2 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Apply_Filter (O, "clear");
      Commit_Filter_To_History (O);
      Apply_Filter (O, "refresh");
      Commit_Filter_To_History (O);
      Clear_Filter_Text (O);

      Assert (not Select_Previous_Filter_History_Entry (O),
              "history navigation no-ops while input is inactive");
      Activate_Filter_Input (O);
      Assert (Select_Previous_Filter_History_Entry (O),
              "previous history replaces active filter text");
      Set_Rows_From_Outline (O, P);
      Assert (Filter_Text (O) = "refresh",
              "previous history selects newest filter first");
      Assert (Editor.Feature_Panel.Row_Count (P) = 1,
              "previous history rebuilds filtered projection");
      Assert (Editor.Feature_Panel.Row_Label (P, 1) = "Refresh_Model",
              "previous history projection exposes matching row");

      Assert (Select_Previous_Filter_History_Entry (O),
              "second previous history selects older entry");
      Assert (Filter_Text (O) = "clear",
              "second previous history replaces filter with older entry");
      Assert (Select_Next_Filter_History_Entry (O),
              "next history moves toward newer entry");
      Assert (Filter_Text (O) = "refresh",
              "next history restores newer entry");
   end Test_Filter_History_Navigation_Rebuilds_Projection;

   procedure Test_Clear_Filter_History_Removes_Entries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
   begin
      Apply_Filter (O, "refresh");
      Commit_Filter_To_History (O);
      Clear_Filter_History (O);
      Activate_Filter_Input (O);
      Assert (Filter_History_Count (O) = 0,
              "clear history removes all filter entries");
      Assert (not Select_Previous_Filter_History_Entry (O),
              "cleared history cannot be navigated");
   end Test_Clear_Filter_History_Removes_Entries;

   procedure Test_Filter_Remembered_Per_Buffer_And_Restored
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4),
         2 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Activate_Filter_Input (O);
      Apply_Filter (O, "clear");
      Remember_Filter_For_Buffer (O, 7);
      Clear_Filter (O);

      Assert (Restore_Filter_For_Buffer (O, 7),
              "remembered filter restores for matching live buffer identity");
      Set_Rows_From_Outline (O, P);
      Assert (Filter_Text (O) = "clear",
              "restored filter text is preserved per buffer");
      Assert (not Filter_Input_Is_Active (O),
              "restored filter does not automatically activate input focus");
      Assert (Editor.Feature_Panel.Row_Count (P) = 1,
              "restored filter rebuilds projection from accepted rows");
      Assert (Editor.Feature_Panel.Row_Label (P, 1) = "Clear_Model",
              "restored filter projection is reconciled");
   end Test_Filter_Remembered_Per_Buffer_And_Restored;

   procedure Test_Filter_Not_Restored_For_Closed_Or_Reused_Label
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items_A : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("main.adb"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4));
      Items_B : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("main.adb"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 8,
            Line         => 10,
            Column       => 4));
   begin
      Replace_Items (O, Items_A);
      Apply_Filter (O, "refresh");
      Remember_Filter_For_Buffer (O, 7);
      Forget_Filter_For_Buffer (O, 7);
      Assert (Remembered_Filter_Count (O) = 0,
              "closing a buffer forgets its remembered filter");
      Assert (not Restore_Filter_For_Buffer (O, 7),
              "closed buffer filter cannot be restored");

      Apply_Filter (O, "refresh");
      Remember_Filter_For_Buffer (O, 7);
      Replace_Items (O, Items_B);
      Clear_Filter (O);
      Assert (not Restore_Filter_For_Buffer (O, 8),
              "same display label with different buffer identity does not inherit stale filter");
      Assert (Filter_Text (O) = "",
              "label-only reuse leaves filter text empty");
   end Test_Filter_Not_Restored_For_Closed_Or_Reused_Label;

   procedure Test_Filter_Reset_Clears_Transient_Cursor_And_Project_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 4));
   begin
      Replace_Items (O, Items);
      Apply_Filter (O, "refresh");
      Commit_Filter_To_History (O);
      Activate_Filter_Input (O);
      Assert (Select_Previous_Filter_History_Entry (O),
              "setup selects a history cursor entry");
      Reset_Filter_State_For_Lifecycle (O);
      Assert (Filter_Text (O) = "",
              "lifecycle reset clears filter text");
      Assert (not Filter_Input_Is_Active (O),
              "lifecycle reset deactivates filter input");
      Activate_Filter_Input (O);
      Assert (Select_Previous_Filter_History_Entry (O),
              "lifecycle reset clears history cursor without deleting history");

      Apply_Filter (O, "refresh");
      Remember_Filter_For_Buffer (O, 7);
      Reset_For_Project_Close (O);
      Assert (Filter_History_Count (O) = 0,
              "project close clears session-local filter history");
      Assert (Remembered_Filter_Count (O) = 0,
              "project close clears remembered per-buffer filters");
   end Test_Filter_Reset_Clears_Transient_Cursor_And_Project_State;

   procedure Test_Projection_Generation_Changes_On_Filter_And_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      Rows_Before   : Natural;
      Filter_Before : Natural;
      Proj_Before   : Natural;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Run"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 2,
            Column       => 1));
   begin
      Rows_Before := Rows_Generation (O);
      Proj_Before := Projection_Generation (O);
      Replace_Items (O, Items);
      Assert (Rows_Generation (O) /= Rows_Before,
              "accepted refresh changes row generation");
      Assert (Projection_Generation (O) /= Proj_Before,
              "accepted refresh invalidates projection generation");

      Filter_Before := Filter_Generation (O);
      Proj_Before := Projection_Generation (O);
      Apply_Filter (O, "run");
      Assert (Filter_Generation (O) /= Filter_Before,
              "filter edit changes filter generation");
      Assert (Projection_Generation (O) /= Proj_Before,
              "filter edit invalidates projection generation");
   end Test_Projection_Generation_Changes_On_Filter_And_Rows;

   procedure Test_Repeated_Filter_Clear_Restores_Stable_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O : Outline_State;
      P : Editor.Feature_Panel.Feature_Panel_State;
      Base_Fingerprint : Natural := 0;
      Items : constant Outline_Item_Array :=
        (1 =>
           (Kind        => Outline_Package,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Editor.Outline"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("package"),
            Depth       => 0,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 1,
            Column       => 1),
         2 =>
           (Kind        => Outline_Procedure,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Refresh_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("procedure"),
            Depth       => 1,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 10,
            Column       => 1),
         3 =>
           (Kind        => Outline_Function,
            Label       => Ada.Strings.Unbounded.To_Unbounded_String ("Clear_Model"),
            Detail      => Ada.Strings.Unbounded.To_Unbounded_String ("function"),
            Depth       => 1,
            Target_Kind  => Buffer_Position_Target,
            Buffer_Token => 7,
            Line         => 20,
            Column       => 1));
   begin
      Replace_Items (O, Items);
      Base_Fingerprint := Fingerprint (O);

      for I in 1 .. 20 loop
         Apply_Filter (O, (if I mod 2 = 0 then "refresh" else "clear"));
         Set_Rows_From_Outline (O, P);
         Assert (Editor.Feature_Panel.Row_Count (P) = 1,
                 "repeated filter edit keeps projection bounded");
         Assert (Projection_Invariant_Holds (O, P),
                 "filtered projection invariant holds during repetition");

         Clear_Filter (O);
         Set_Rows_From_Outline (O, P);
         Assert (Editor.Feature_Panel.Row_Count (P) = 3,
                 "repeated clear-filter restores every row");
         Assert (Fingerprint (O) = Base_Fingerprint,
                 "filter-only operations do not mutate accepted rows");
      end loop;
   end Test_Repeated_Filter_Clear_Restores_Stable_Rows;

   procedure Test_Filtered_Mouse_Activation_Uses_Current_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Result : Editor.Executor.Command_Execution_Result;
      Row    : Natural := 0;
      Col    : Natural := 0;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "@outline procedure Refresh" & ASCII.LF &
            "body" & ASCII.LF &
            "@outline procedure Clear" & ASCII.LF &
            "body");
      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Refresh_Outline);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "refresh setup executes");

      Apply_Filter (S.Outline, "clear");
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 1,
              "fixture has one filtered visible row");
      Assert (Map_Panel_Row_To_Outline_Row (S.Outline, S.Feature_Panel, 1) = 2,
              "filtered visible row maps to second outline row");

      Result :=
        Editor.Executor.Outline_Commands.Execute_Outline_Row_Activation (S, 1);
      Assert (Result.Status = Editor.Executor.Command_Executed,
              "mouse activation uses visible row through shared open handler");
      Assert (Selected_Index (S.Outline) = 2,
              "mouse activation stores the mapped outline row as selection");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 1,
              "mouse activation keeps the visible panel row selected");
      Editor.State.Row_Col_For_Index (S, S.Carets (0).Pos, Row, Col);
      Assert (Row = 2 and then Col = 0,
              "activation navigates to the filtered symbol target");
   end Test_Filtered_Mouse_Activation_Uses_Current_Projection;

   procedure Test_Buffer_Identity_Helper_And_Filter_Restore_Reject_Stale_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O        : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Run;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 555,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Assert (Outline_Buffer_Identity_Matches (O, 555),
              "buffer identity helper accepts current extracted rows");
      Assert (Has_Navigable_Symbol_For_Buffer (O, 555),
              "navigable-symbol helper sees accepted active-buffer rows");
      Assert (not Outline_Buffer_Identity_Matches (O, 556),
              "buffer identity helper rejects another active buffer token");

      Apply_Filter (O, "run");
      Remember_Filter_For_Buffer (O, 555);
      Clear_Filter (O);
      Assert (Restore_Filter_For_Buffer (O, 555),
              "transient filter restore accepts live matching rows");

      Mark_Stale_Result (O);
      Clear_Filter (O);
      Assert (not Outline_Buffer_Identity_Matches (O, 555),
              "buffer identity helper rejects retained stale rows");
      Assert (not Has_Navigable_Symbol_For_Buffer (O, 555),
              "navigable-symbol helper rejects retained stale rows");
      Assert (not Restore_Filter_For_Buffer (O, 555),
              "filter restore rejects retained stale rows");
   end Test_Buffer_Identity_Helper_And_Filter_Restore_Reject_Stale_Rows;

   procedure Test_Filter_Match_Availability_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      O        : Outline_State;
      Snapshot : Editor.Outline_Extractor.Buffer_Text_Snapshot;
      Before_Selected : Natural := 0;
   begin
      Snapshot := Editor.Outline_Extractor.Make_Snapshot
        ("package Demo is" & ASCII.LF &
         "   procedure Alpha;" & ASCII.LF &
         "   procedure Beta;" & ASCII.LF &
         "end Demo;",
         Active_Buffer_Token  => 550,
         Buffer_Revision      => 1,
         Lifecycle_Generation => 1,
         Request_Token        => Next_Request_Token (O));
      Begin_Extraction (O, Editor.Outline_Extractor.Identity (Snapshot));
      Editor.Outline_Extractor.Apply_To_Outline
        (Editor.Outline_Extractor.Extract (Snapshot), O);

      Apply_Filter (O, "beta");
      Select_Item (O, 0);
      Before_Selected := Selected_Index (O);

      Assert (Has_Selectable_Filter_Match (O),
              "filter availability sees matching selectable symbols");
      Assert (Selected_Index (O) = Before_Selected,
              "filter availability helper does not reconcile or mutate selection");

      Apply_Filter (O, "line 2");
      Assert (Has_Selectable_Filter_Match (O),
              "filter availability matches deterministic row detail text");

      Apply_Filter (O, "not-present");
      Assert (not Has_Selectable_Filter_Match (O),
              "filter availability rejects no-match filters");

      Clear_Filter (O);
      Mark_Stale_Result (O);
      Assert (not Has_Selectable_Filter_Match (O),
              "filter availability rejects retained stale rows");
   end Test_Filter_Match_Availability_Is_Side_Effect_Free;

   procedure Test_Filtered_Selection_Clamps_At_Visible_Bounds
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text
        (S, "package Demo is" & ASCII.LF &
            "   procedure Alpha;" & ASCII.LF &
            "   procedure Beta;" & ASCII.LF &
            "   procedure Gamma;" & ASCII.LF &
            "end Demo;");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Refresh_Outline);
      Apply_Filter (S.Outline, "Beta");
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 1,
              "filter reduces outline projection to one visible row");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 1,
              "filtered outline selects the only visible row");

      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Next_Outline_Item);
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 1,
              "select-next clamps at filtered end");
      Editor.Executor.Execute_Command (S, Editor.Commands.Command_Select_Previous_Outline_Item);
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) = 1,
              "select-previous clamps at filtered beginning");

      Clear_Filter (S.Outline);
      Set_Rows_From_Outline (S.Outline, S.Feature_Panel);
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) >= 4,
              "clear filter restores full outline projection");
      Assert (Editor.Feature_Panel.Selected_Row (S.Feature_Panel) /= 0,
              "clear filter leaves a deterministic selection");
   end Test_Filtered_Selection_Clamps_At_Visible_Bounds;

   overriding procedure Register_Tests (T : in out Filter_Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Outline_Filter_Matches_Label_Case_Insensitive'Access,
         "outline filter matches label case-insensitively");
      Register_Routine
        (T, Test_Outline_Clear_Filter_Restores_All_Rows'Access,
         "outline clear filter restores all rows");
      Register_Routine
        (T, Test_Outline_Focus_Filter_Activates_Input'Access,
         "outline focus filter activates input");
      Register_Routine
        (T, Test_Filter_Input_Text_Rebuilds_Projection'Access,
         "outline filter input text rebuilds projection");
      Register_Routine
        (T, Test_Filter_Input_Backspace_Rebuilds_Projection'Access,
         "outline filter input backspace rebuilds projection");
      Register_Routine
        (T, Test_Filter_Input_Escape_Rule'Access,
         "outline filter input escape rule");
      Register_Routine
        (T, Test_Filter_Edit_Selection_Reconciliation'Access,
         "outline filter edit reconciles selection");
      Register_Routine
        (T, Test_Filter_Cleared_On_Outline_Clear'Access,
         "outline clear removes filter state");
      Register_Routine
        (T, Test_Filter_Header_Shows_Text_And_Count'Access,
         "outline filter header shows text and count");
      Register_Routine
        (T, Test_Filter_Command_Palette_Registers_Commands'Access,
         "outline filter commands are registered");
      Register_Routine
        (T, Test_Filter_History_Adds_Deduplicates_And_Trims'Access,
         "outline filter history adds, deduplicates, and trims");
      Register_Routine
        (T, Test_Filter_History_Navigation_Rebuilds_Projection'Access,
         "outline filter history navigation rebuilds projection");
      Register_Routine
        (T, Test_Clear_Filter_History_Removes_Entries'Access,
         "outline clear filter history removes entries");
      Register_Routine
        (T, Test_Filter_Remembered_Per_Buffer_And_Restored'Access,
         "outline filter remembered per buffer and restored");
      Register_Routine
        (T, Test_Filter_Not_Restored_For_Closed_Or_Reused_Label'Access,
         "outline filter rejects closed and label-reused buffers");
      Register_Routine
        (T, Test_Filter_Reset_Clears_Transient_Cursor_And_Project_State'Access,
         "outline filter lifecycle reset clears transient state");
      Register_Routine
        (T, Test_Projection_Generation_Changes_On_Filter_And_Rows'Access,
         "projection generation changes on filter and row edits");
      Register_Routine
        (T, Test_Repeated_Filter_Clear_Restores_Stable_Rows'Access,
         "repeated filter clear restores stable rows");
      Register_Routine
        (T, Test_Filtered_Mouse_Activation_Uses_Current_Projection'Access,
         "filtered mouse activation uses current projection");
      Register_Routine
        (T, Test_Buffer_Identity_Helper_And_Filter_Restore_Reject_Stale_Rows'Access,
         "buffer identity helper and filter restore reject stale rows");
      Register_Routine
        (T, Test_Filter_Match_Availability_Is_Side_Effect_Free'Access,
         "filter match availability is side-effect-free");
      Register_Routine
        (T, Test_Filtered_Selection_Clamps_At_Visible_Bounds'Access,
         "filtered selection clamps at visible bounds");
   end Register_Tests;

end Editor.Outline.Filter_Tests;
