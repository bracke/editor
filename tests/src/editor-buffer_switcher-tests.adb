with AUnit.Assertions; use AUnit.Assertions;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with AUnit.Test_Cases; use AUnit.Test_Cases.Registration;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Buffer_Switcher_Contextual_Hints;
with Editor.Commands;
with Editor.Command_Palette;
with Editor.Command_Route_Audit;
with Editor.Executor;
with Editor.Input_Field;
with Editor.Keybindings;
with Editor.Keybinding_Config;
with Editor.Overlay_Focus;
with Editor.Project;
with Editor.Render_Model;
with Editor.Workspace_Persistence;
with Editor.Recent_Buffers;
with Editor.Recent_Projects;
with Editor.Settings;
with Editor.State;
with Editor.Test_Helper;
with Text_Buffer;

package body Editor.Buffer_Switcher.Tests is
   use type Ada.Directories.File_Kind;
   use type Ada.Streams.Stream_Element_Offset;
   use type Editor.Commands.Command_Availability_Status;
   use type Editor.Commands.Command_Id;
   use type Editor.Keybindings.Binding_Result;
   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;
   use type Editor.Settings.Settings_Status;
   use type Editor.Recent_Projects.Recent_Project_Status;
   use type Editor.Keybinding_Config.Keybinding_Config_Status;


   function Name (T : Buffer_Switcher_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Buffer_Switcher");
   end Name;



   function Contains_Text (Haystack : String; Needle : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Haystack, Needle) /= 0;
   end Contains_Text;

   function Phase576_Command_Has_Payload
     (Id : Editor.Commands.Command_Id) return Boolean
   is
      Cmd : constant Editor.Commands.Command :=
        Editor.Commands.Command_For_Id (Id);
   begin
      return Cmd.Buffer_Id /= 0
        or else Length (Cmd.Text) /= 0
        or else Length (Cmd.Path) /= 0
        or else Length (Cmd.Query) /= 0
        or else not Cmd.Positions.Is_Empty
        or else not Cmd.Delete_Counts.Is_Empty
        or else not Cmd.Insert_Texts.Is_Empty;
   end Phase576_Command_Has_Payload;

   package Stream_IO renames Ada.Streams.Stream_IO;

   function Phase576_Temp_Path (Name : String) return String is
   begin
      return Ada.Directories.Compose
        (Ada.Directories.Current_Directory, "phase576_" & Name);
   end Phase576_Temp_Path;

   procedure Phase576_Write_Bytes (Path : String; Bytes : String) is
      F : Stream_IO.File_Type;
   begin
      Stream_IO.Create (F, Stream_IO.Out_File, Path);
      if Bytes'Length > 0 then
         declare
            Raw : Ada.Streams.Stream_Element_Array
              (1 .. Ada.Streams.Stream_Element_Offset (Bytes'Length));
         begin
            for I in Bytes'Range loop
               Raw (Ada.Streams.Stream_Element_Offset (I - Bytes'First + 1)) :=
                 Ada.Streams.Stream_Element (Character'Pos (Bytes (I)));
            end loop;
            Stream_IO.Write (F, Raw);
         end;
      end if;
      Stream_IO.Close (F);
   end Phase576_Write_Bytes;

   procedure Phase576_Remove_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         if Ada.Directories.Kind (Path) = Ada.Directories.Directory then
            Ada.Directories.Delete_Directory (Path);
         else
            Ada.Directories.Delete_File (Path);
         end if;
      end if;
   end Phase576_Remove_If_Exists;

   function Phase576_Read_Bytes (Path : String) return String is
      F : Stream_IO.File_Type;
   begin
      if not Ada.Directories.Exists (Path)
        or else Ada.Directories.Kind (Path) = Ada.Directories.Directory
      then
         return "";
      end if;

      Stream_IO.Open (F, Stream_IO.In_File, Path);
      declare
         Size : constant Ada.Streams.Stream_Element_Offset :=
           Ada.Streams.Stream_Element_Offset (Stream_IO.Size (F));
      begin
         if Size = 0 then
            Stream_IO.Close (F);
            return "";
         end if;

         declare
            Raw  : Ada.Streams.Stream_Element_Array (1 .. Size);
            Last : Ada.Streams.Stream_Element_Offset;
            Text : String (1 .. Natural (Size));
         begin
            Stream_IO.Read (F, Raw, Last);
            Stream_IO.Close (F);
            for I in 1 .. Natural (Last) loop
               Text (I) := Character'Val
                 (Raw (Ada.Streams.Stream_Element_Offset (I)));
            end loop;
            return Text (1 .. Natural (Last));
         end;
      end;
   exception
      when others =>
         if Stream_IO.Is_Open (F) then
            Stream_IO.Close (F);
         end if;
         raise;
   end Phase576_Read_Bytes;

   function Phase576_Buffer_Text (S : Editor.State.State_Type) return String is
   begin
      return Text_Buffer.UTF8_Text (S.Buffer);
   end Phase576_Buffer_Text;

   procedure Phase576_Insert_Text_At
     (S    : in out Editor.State.State_Type;
      Pos  : Natural;
      Text : String)
   is
      Offset : Natural := 0;
   begin
      for Ch of Text loop
         Editor.Executor.Execute_No_Log
           (S, Editor.Test_Helper.Insert (Pos + Offset, Ch));
         Offset := Offset + 1;
      end loop;
   end Phase576_Insert_Text_At;

   function Contains_Hint
     (Hints : Editor.Buffer_Switcher_Contextual_Hints.Switcher_Contextual_Hint_Vectors.Vector;
      Id    : Editor.Commands.Command_Id) return Boolean
   is
   begin
      for Hint of Hints loop
         if Hint.Command_Id = Id then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Hint;

   function Hint_Key_Text
     (Hints : Editor.Buffer_Switcher_Contextual_Hints.Switcher_Contextual_Hint_Vectors.Vector;
      Id    : Editor.Commands.Command_Id) return String
   is
   begin
      for Hint of Hints loop
         if Hint.Command_Id = Id then
            return To_String (Hint.Keybinding_Text);
         end if;
      end loop;
      return "";
   end Hint_Key_Text;

   procedure Setup_Global_Switcher_State
     (S     : in out Editor.State.State_Type;
      Alpha : out Editor.Buffers.Buffer_Id;
      Beta  : out Editor.Buffers.Buffer_Id)
   is
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/hints/alpha.adb", "alpha.adb", "procedure Alpha is begin null; end;", Alpha);
      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/hints/alphabet.adb", "alphabet.adb", "procedure Alphabet is begin null; end;", Beta);
      Editor.Buffers.Global_Set_Active_Buffer (Alpha);
      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Config);
      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus,
         Editor.Overlay_Focus.Buffer_Switcher_Overlay,
         S.Panel_Focus);
   end Setup_Global_Switcher_State;


   procedure Mark_Global_Buffer_Dirty
     (S    : in out Editor.State.State_Type;
      Id   : Editor.Buffers.Buffer_Id)
   is
   begin
      Editor.Buffers.Global_Set_Active_Buffer (Id);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
   end Mark_Global_Buffer_Dirty;

   function Formatted_Hints
     (Hints : Editor.Buffer_Switcher_Contextual_Hints.Switcher_Contextual_Hint_Vectors.Vector)
      return String
   is
   begin
      return Editor.Buffer_Switcher_Contextual_Hints.Format_Switcher_Contextual_Hints (Hints);
   end Formatted_Hints;

   procedure Build_Registry
     (Registry : in out Editor.Buffers.Buffer_Registry;
      Alpha    : out Editor.Buffers.Buffer_Id;
      Beta     : out Editor.Buffers.Buffer_Id;
      Untitled : out Editor.Buffers.Buffer_Id)
   is
   begin
      Alpha := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/project/src/main.adb", "main.adb", "procedure Main is begin null; end;");
      Beta := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/project/src/readme.txt", "readme.txt", "readme");
      Untitled := Editor.Buffers.Create_Untitled_Buffer (Registry);
      Editor.Buffers.Set_Active_Buffer (Registry, Beta);
   end Build_Registry;


   procedure Set_Buffer_Association_For_Test
     (Registry     : in out Editor.Buffers.Buffer_Registry;
      Id           : Editor.Buffers.Buffer_Id;
      Path         : String;
      Display_Name : String)
   is
   begin
      Editor.Buffers.Buffer_Access (Registry, Id).File_Info.Has_Path := True;
      Editor.Buffers.Buffer_Access (Registry, Id).File_Info.Path := To_Unbounded_String (Path);
      Editor.Buffers.Buffer_Access (Registry, Id).File_Info.Display_Name := To_Unbounded_String (Display_Name);
   end Set_Buffer_Association_For_Test;

   procedure Clear_Buffer_Association_For_Test
     (Registry : in out Editor.Buffers.Buffer_Registry;
      Id       : Editor.Buffers.Buffer_Id)
   is
   begin
      Editor.Buffers.Buffer_Access (Registry, Id).File_Info.Has_Path := False;
      Editor.Buffers.Buffer_Access (Registry, Id).File_Info.Path := Null_Unbounded_String;
      Editor.Buffers.Buffer_Access (Registry, Id).File_Info.Display_Name := To_Unbounded_String ("Untitled");
   end Clear_Buffer_Association_For_Test;

   procedure Set_Buffer_Dirty_For_Test
     (Registry : in out Editor.Buffers.Buffer_Registry;
      Id       : Editor.Buffers.Buffer_Id;
      Dirty    : Boolean)
   is
   begin
      Editor.Buffers.Buffer_Access (Registry, Id).File_Info.Dirty := Dirty;
   end Set_Buffer_Dirty_For_Test;

   function Row_Index_For
     (S  : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Id : Editor.Buffers.Buffer_Id) return Natural
   is
   begin
      for I in 1 .. Editor.Buffer_Switcher.Row_Count (S) loop
         if Editor.Buffer_Switcher.Row_At (S, I).Id = Id then
            return I;
         end if;
      end loop;
      return 0;
   end Row_Index_For;

   function Row_For
     (S  : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Id : Editor.Buffers.Buffer_Id) return Editor.Buffer_Switcher.Buffer_Switcher_Row
   is
      Index : constant Natural := Row_Index_For (S, Id);
   begin
      Assert (Index /= 0, "expected switcher row for buffer id" & Editor.Buffers.Buffer_Id'Image (Id));
      return Editor.Buffer_Switcher.Row_At (S, Index);
   end Row_For;

   procedure Recompute_For_Test
     (S        : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry)
   is
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
   begin
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
   end Recompute_For_Test;

   procedure Test_Open_Close_And_Filter_Input
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
   begin
      Assert (not Editor.Buffer_Switcher.Is_Open (S), "new switcher state must be closed");
      Editor.Buffer_Switcher.Open (S);
      Assert (Editor.Buffer_Switcher.Is_Open (S), "Open must open switcher");
      Editor.Buffer_Switcher.Insert_Text (S, "ma");
      Editor.Buffer_Switcher.Move_Cursor_Left (S);
      Editor.Buffer_Switcher.Insert_Text (S, "X");
      Assert (Editor.Buffer_Switcher.Filter_Text (S) = "mXa", "filter edits at cursor");
      Editor.Buffer_Switcher.Backspace (S);
      Assert (Editor.Buffer_Switcher.Filter_Text (S) = "ma", "backspace edits filter");
      Editor.Buffer_Switcher.Close (S);
      Assert (not Editor.Buffer_Switcher.Is_Open (S), "Close must close switcher");
   end Test_Open_Close_And_Filter_Input;

   procedure Test_Recompute_Uses_Open_Buffers_In_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 3, "empty filter lists all open buffers");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha, "row order follows open-buffer order");
      Assert (Editor.Buffer_Switcher.Row_At (S, 2).Id = Beta, "row order preserves second buffer");
      Assert (Editor.Buffer_Switcher.Row_At (S, 3).Id = Untitled, "untitled buffer is listed");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 2, "active buffer row is selected when visible");
      Assert (Editor.Buffer_Switcher.Row_At (S, 2).Is_Active, "active row is marked");
   end Test_Recompute_Uses_Open_Buffers_In_Order;

   procedure Test_Literal_Filtering_And_No_Match
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      pragma Unreferenced (Alpha, Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Filter_Text (S, "READ");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1, "literal filtering is case-insensitive");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta, "filter returns matching open buffer");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 1, "matching active row is selected");

      Editor.Buffer_Switcher.Set_Filter_Text (S, "not-open");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 0, "unmatched filter has no rows");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 0, "no-match state has no selection");
   end Test_Literal_Filtering_And_No_Match;

   procedure Test_Selection_Wraps
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      pragma Unreferenced (Alpha, Beta, Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Editor.Buffer_Switcher.Move_Selection_Down (S);
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 3, "next moves through visible rows");
      Editor.Buffer_Switcher.Move_Selection_Down (S);
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 1, "next wraps at end");
      Editor.Buffer_Switcher.Move_Selection_Up (S);
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 3, "previous wraps at start");
   end Test_Selection_Wraps;


   procedure Test_Dirty_Closed_And_Filtered_Active_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Closed : Boolean := False;
      pragma Unreferenced (Beta, Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := True;

      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Is_Dirty,
              "dirty open buffer row must expose dirty marker state");

      Editor.Buffer_Switcher.Set_Filter_Text (S, "main");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1,
              "filter should narrow to the visible matching open buffer");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 1,
              "when active buffer is filtered out, first visible row is selected");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha,
              "filtered row must be the matching open buffer");

      Editor.Buffers.Close_Buffer (Registry, Alpha, Closed, Force => True);
      Assert (Closed, "test setup should close the filtered buffer");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 0,
              "closed buffer must disappear from switcher rows");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 0,
              "closed/no-match state must have no selected row");
   end Test_Dirty_Closed_And_Filtered_Active_State;

   procedure Test_Metadata_Filters_Narrow_Candidates
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Pin_Buffer (Registry, Alpha);
      Editor.Buffers.Assign_Buffer_Group (Registry, Alpha, "core");
      Editor.Buffers.Assign_Buffer_Group (Registry, Beta, "docs");
      Editor.Buffers.Set_Buffer_Label (Registry, Beta, "test");
      Editor.Buffers.Set_Buffer_Note (Registry, Untitled, "scratch note");

      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Pinned_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1, "pinned filter shows only pinned buffers");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha, "pinned row is alpha");

      Editor.Buffer_Switcher.Set_Group_Filter (S, " core ");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1, "group filter trims and matches exactly");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha, "core group row is alpha");

      Editor.Buffer_Switcher.Set_Label_Filter (S, " test ");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1, "label filter trims and matches exactly");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta, "test label row is beta");

      Editor.Buffer_Switcher.Set_Noted_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1, "noted filter checks note presence only");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Untitled, "noted row is untitled");
   end Test_Metadata_Filters_Narrow_Candidates;

   procedure Test_Metadata_Filter_Replaces_And_Clear_Restores
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Pin_Buffer (Registry, Alpha);
      Editor.Buffers.Set_Buffer_Label (Registry, Beta, "test");

      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Pinned_Filter (S);
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S) = "pinned",
              "pinned filter description is compact");
      Editor.Buffer_Switcher.Set_Label_Filter (S, "test");
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S) = "label test",
              "setting label filter replaces pinned filter");

      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1, "replacement filter controls candidates");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta, "replacement filter returns label match");

      Editor.Buffer_Switcher.Clear_Metadata_Filter (S);
      Assert (not Editor.Buffer_Switcher.Has_Metadata_Filter (S), "clear removes metadata filter");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 3, "clear restores ordinary switcher candidates");
   end Test_Metadata_Filter_Replaces_And_Clear_Restores;

   procedure Test_Literal_Query_Filters_Within_Metadata_Filter
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      pragma Unreferenced (Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Buffer_Label (Registry, Alpha, "test");
      Editor.Buffers.Set_Buffer_Label (Registry, Beta, "test");

      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Label_Filter (S, "test");
      Editor.Buffer_Switcher.Set_Filter_Text (S, "read");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1,
              "literal query filters inside metadata-filtered candidates");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta,
              "literal query keeps only matching labelled buffer");
   end Test_Literal_Query_Filters_Within_Metadata_Filter;

   procedure Test_Stale_Metadata_Filter_Empty_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      pragma Unreferenced (Beta, Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Assign_Buffer_Group (Registry, Alpha, "core");
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Group_Filter (S, "core");
      Editor.Buffers.Clear_Buffer_Group (Registry, Alpha);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 0,
              "stale metadata filter is not lazily repaired by projection");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 0,
              "stale filter empty state has no selection");
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S) = "group core",
              "stale filter remains explicit until cleared");
   end Test_Stale_Metadata_Filter_Empty_State;


   procedure Test_Metadata_Filter_Empty_Pinned_And_Noted_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      pragma Unreferenced (Alpha, Beta, Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);

      Editor.Buffer_Switcher.Set_Pinned_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 0,
              "pinned filter with no pinned open buffers produces no matches");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 0,
              "empty pinned filter state has no selected row");
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S) = "pinned",
              "empty pinned filter remains explicit");

      Editor.Buffer_Switcher.Set_Noted_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 0,
              "noted filter with no noted open buffers produces no matches");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 0,
              "empty noted filter state has no selected row");
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S) = "noted",
              "empty noted filter remains explicit");
   end Test_Metadata_Filter_Empty_Pinned_And_Noted_Are_Deterministic;

   procedure Test_Group_And_Label_Filters_Do_Not_Mutate_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      pragma Unreferenced (Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Assign_Buffer_Group (Registry, Alpha, "core");
      Editor.Buffers.Assign_Buffer_Group (Registry, Beta, "docs");
      Editor.Buffers.Set_Active_Buffer_Group (Registry, "docs");
      Editor.Buffers.Set_Buffer_Label (Registry, Alpha, "api");
      Editor.Buffers.Set_Buffer_Label (Registry, Beta, "test");

      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Group_Filter (S, "core");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1,
              "group filter should narrow candidates");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha,
              "group filter should keep only matching group");
      Assert (Editor.Buffers.Has_Active_Buffer_Group (Registry),
              "group filter must not clear active group");
      Assert (Editor.Buffers.Active_Buffer_Group (Registry) = "docs",
              "group filter must not change active group");
      Assert (Editor.Buffers.Buffer_Group (Registry, Alpha) = "core",
              "group filter must not mutate matching membership");
      Assert (Editor.Buffers.Buffer_Group (Registry, Beta) = "docs",
              "group filter must not mutate nonmatching membership");

      Editor.Buffer_Switcher.Set_Label_Filter (S, "test");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1,
              "label filter should narrow candidates");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta,
              "label filter should keep only matching label");
      Assert (Editor.Buffers.Buffer_Label (Registry, Alpha) = "api",
              "label filter must not mutate nonmatching label");
      Assert (Editor.Buffers.Buffer_Label (Registry, Beta) = "test",
              "label filter must not mutate matching label");
   end Test_Group_And_Label_Filters_Do_Not_Mutate_Metadata;


   procedure Test_Sort_Modes_Order_Candidates
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Recent : Editor.Recent_Buffers.Recent_Buffer_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Pin_Buffer (Registry, Beta);
      Editor.Buffers.Assign_Buffer_Group (Registry, Alpha, "core");
      Editor.Buffers.Assign_Buffer_Group (Registry, Beta, "api");
      Editor.Buffers.Set_Buffer_Label (Registry, Alpha, "zeta");
      Editor.Buffers.Set_Buffer_Label (Registry, Beta, "alpha");
      Editor.Recent_Buffers.Mark_Activated (Recent, Natural (Alpha));
      Editor.Recent_Buffers.Mark_Activated (Recent, Natural (Untitled));
      Editor.Recent_Buffers.Mark_Activated (Recent, Natural (Beta));

      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Default_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Config);
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha,
              "default sort preserves existing open-buffer order");
      Assert (Editor.Buffer_Switcher.Row_At (S, 2).Id = Beta,
              "default sort keeps second open buffer");

      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Recent_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Config);
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta,
              "recent sort uses most recently activated buffer first");
      Assert (Editor.Buffer_Switcher.Row_At (S, 2).Id = Untitled,
              "recent sort preserves recent activation order");
      Assert (Editor.Recent_Buffers.Id_At (Recent, 1) = Natural (Beta),
              "recent sort must not mutate recent-buffer order");

      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Config);
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha,
              "name sort orders main.adb before readme.txt");
      Assert (Editor.Buffer_Switcher.Row_At (S, 3).Id = Untitled,
              "name sort deterministically places untitled by display label");

      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Pinned_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Config);
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta,
              "pinned sort places pinned buffers first");
      Assert (Editor.Buffer_Switcher.Row_At (S, 2).Id = Alpha,
              "pinned sort preserves fallback order among unpinned buffers");

      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Group_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Config);
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta,
              "group sort orders api before core");
      Assert (Editor.Buffer_Switcher.Row_At (S, 2).Id = Alpha,
              "group sort keeps grouped buffers before ungrouped buffers");
      Assert (Editor.Buffer_Switcher.Row_At (S, 3).Id = Untitled,
              "group sort places ungrouped buffers last");

      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Label_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Config);
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta,
              "label sort orders alpha before zeta");
      Assert (Editor.Buffer_Switcher.Row_At (S, 3).Id = Untitled,
              "label sort places unlabeled buffers last");
   end Test_Sort_Modes_Order_Candidates;

   procedure Test_Sort_Cycles_And_Composes_With_Filters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      pragma Unreferenced (Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Buffer_Label (Registry, Alpha, "test");
      Editor.Buffers.Set_Buffer_Label (Registry, Beta, "test");
      Editor.Buffers.Pin_Buffer (Registry, Beta);

      Editor.Buffer_Switcher.Open (S);
      Assert (Editor.Buffer_Switcher.Sort_Mode (S) = Editor.Buffer_Switcher.Default_Sort,
              "new switcher starts with default sort mode");
      Editor.Buffer_Switcher.Next_Sort_Mode (S);
      Assert (Editor.Buffer_Switcher.Sort_Mode (S) = Editor.Buffer_Switcher.Recent_Sort,
              "next sort advances to recent");
      Editor.Buffer_Switcher.Previous_Sort_Mode (S);
      Assert (Editor.Buffer_Switcher.Sort_Mode (S) = Editor.Buffer_Switcher.Default_Sort,
              "previous sort returns to default");
      Editor.Buffer_Switcher.Previous_Sort_Mode (S);
      Assert (Editor.Buffer_Switcher.Sort_Mode (S) = Editor.Buffer_Switcher.Label_Sort,
              "previous sort wraps to label");

      Editor.Buffer_Switcher.Set_Label_Filter (S, "test");
      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Pinned_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 2,
              "label filter still controls the candidate set under sort");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta,
              "filtered candidates are then ordered by active sort");
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S) = "label test",
              "setting sort mode does not clear metadata filter");
      Assert (Editor.Buffer_Switcher.Sort_Mode (S) = Editor.Buffer_Switcher.Pinned_Sort,
              "metadata filter does not clear sort mode");

      Editor.Buffer_Switcher.Set_Filter_Text (S, "main");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1,
              "literal query still filters after metadata filter under active sort");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha,
              "literal query keeps matching filtered buffer only");

      Editor.Buffer_Switcher.Clear_Metadata_Filter (S);
      Assert (Editor.Buffer_Switcher.Sort_Mode (S) = Editor.Buffer_Switcher.Pinned_Sort,
              "clearing metadata filter must not clear sort mode");
      Editor.Buffer_Switcher.Clear_Sort_Mode (S);
      Assert (Editor.Buffer_Switcher.Sort_Mode (S) = Editor.Buffer_Switcher.Default_Sort,
              "clearing sort restores default sort");
   end Test_Sort_Cycles_And_Composes_With_Filters;



   procedure Test_Sort_State_Survives_Open_Close_And_Uses_Future_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      pragma Unreferenced (Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);

      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Pinned_Sort);
      Editor.Buffer_Switcher.Close (S);
      Editor.Buffer_Switcher.Open (S);
      Assert (Editor.Buffer_Switcher.Sort_Mode (S) = Editor.Buffer_Switcher.Pinned_Sort,
              "switcher open/close must not clear active sort mode");

      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha,
              "pinned sort with no pinned buffers falls back to default order");

      Editor.Buffers.Pin_Buffer (Registry, Beta);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta,
              "future pin metadata affects later pinned-sort snapshots");

      Editor.Buffers.Unpin_Buffer (Registry, Beta);
      Editor.Buffers.Pin_Buffer (Registry, Alpha);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha,
              "future unpin/pin changes are reflected without mutating sort state");
      Assert (Editor.Buffer_Switcher.Sort_Mode (S) = Editor.Buffer_Switcher.Pinned_Sort,
              "metadata changes must not clear active sort mode");
   end Test_Sort_State_Survives_Open_Close_And_Uses_Future_Metadata;

   procedure Test_Notes_Do_Not_Participate_In_Sort_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      pragma Unreferenced (Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Buffer_Note (Registry, Beta, "aaa note that would sort first if notes mattered");
      Editor.Buffers.Set_Buffer_Note (Registry, Alpha, "zzz note that would sort last if notes mattered");

      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Pinned_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha,
              "notes must not affect pinned-sort fallback order");

      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Group_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha,
              "notes must not affect group-sort ungrouped fallback order");

      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Label_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha,
              "notes must not affect label-sort unlabeled fallback order");
      Assert (Editor.Buffer_Switcher.Row_At (S, 2).Id = Beta,
              "note text is display metadata only, not an ordering key");
   end Test_Notes_Do_Not_Participate_In_Sort_Order;


   procedure Test_Preview_State_Is_Session_Local_And_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      pragma Unreferenced (Alpha, Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);

      Assert (not Editor.Buffer_Switcher.Has_Preview (S),
              "preview starts hidden");
      Editor.Buffer_Switcher.Show_Preview (S);
      Editor.Buffer_Switcher.Set_Preview_Target (S, Beta, 2);
      Assert (Editor.Buffer_Switcher.Has_Preview (S),
              "show enables preview state");
      Assert (Editor.Buffer_Switcher.Preview_Target (S) = Beta,
              "preview target stores selected open-buffer identity, not row text");
      Assert (Editor.Buffer_Switcher.Preview_Anchor_Line (S) = 2,
              "preview anchor is explicit and one-based");

      Editor.Buffer_Switcher.Scroll_Preview_Next_Line (S);
      Assert (Editor.Buffer_Switcher.Preview_Scroll_Offset (S) = 1,
              "preview scroll is local to switcher preview state");
      Editor.Buffer_Switcher.Center_Preview_On_Line (S, 4);
      Assert (Editor.Buffer_Switcher.Preview_Anchor_Line (S) = 4,
              "center updates only preview anchor");
      Assert (Editor.Buffer_Switcher.Preview_Scroll_Offset (S) = 0,
              "center clears preview scroll offset");

      Editor.Buffer_Switcher.Hide_Preview (S);
      Assert (not Editor.Buffer_Switcher.Has_Preview (S),
              "hide disables preview");
      Assert (Editor.Buffer_Switcher.Preview_Target (S) = Editor.Buffers.No_Buffer,
              "hide clears transient preview target");

      Editor.Buffer_Switcher.Show_Preview (S);
      Editor.Buffer_Switcher.Set_Preview_Target (S, Beta, 2);
      Editor.Buffer_Switcher.Clear (S);
      Assert (not Editor.Buffer_Switcher.Has_Preview (S),
              "clear drops preview visibility for project/session reset");
      Assert (Editor.Buffer_Switcher.Preview_Target (S) = Editor.Buffers.No_Buffer,
              "clear drops preview target");
   end Test_Preview_State_Is_Session_Local_And_Bounded;



   procedure Test_Mark_Visible_And_Clear_Visible_Affect_Only_Projected_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Count : Natural := 0;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Filter_Text (S, "main");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);

      Editor.Buffer_Switcher.Mark_Visible_Marks (S, Count);
      Assert (Count = 1, "mark visible counts current projected rows");
      Assert (Editor.Buffer_Switcher.Is_Marked (S, Alpha),
              "mark visible marks the visible matching buffer identity");
      Assert (not Editor.Buffer_Switcher.Is_Marked (S, Beta)
              and then not Editor.Buffer_Switcher.Is_Marked (S, Untitled),
              "mark visible does not mark hidden buffers");

      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Clear_Visible_Marks (S, Count);
      Assert (Count = 1, "clear visible counts only visible marks removed");
      Assert (not Editor.Buffer_Switcher.Is_Marked (S, Alpha),
              "clear visible unmarks visible buffers");
      Assert (Editor.Buffer_Switcher.Is_Marked (S, Beta),
              "clear visible preserves hidden marked buffers");
   end Test_Mark_Visible_And_Clear_Visible_Affect_Only_Projected_Rows;



   procedure Test_Marked_Review_Narrows_And_Composes_With_Filter_Query_And_Sort
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Buffer_Label (Registry, Alpha, "test");
      Editor.Buffers.Set_Buffer_Label (Registry, Beta, "test");
      Editor.Buffers.Pin_Buffer (Registry, Beta);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);

      Editor.Buffer_Switcher.Show_Marked_Review (S);
      Assert (Editor.Buffer_Switcher.Has_Marked_Review (S),
              "show enables transient marked review state");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 2,
              "marked review shows only marked open buffers");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha,
              "marked review preserves projected order before sort");
      Assert (Editor.Buffer_Switcher.Row_At (S, 2).Id = Beta,
              "marked review includes the second marked row");

      Editor.Buffer_Switcher.Set_Label_Filter (S, "test");
      Editor.Buffer_Switcher.Set_Filter_Text (S, "read");
      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Pinned_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1,
              "metadata filter and literal query narrow marked review candidates");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta,
              "marked review composes before filters/query and sort");
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S) = "label test",
              "marked review does not clear metadata filter state");
      Assert (Editor.Buffer_Switcher.Filter_Text (S) = "read",
              "marked review does not clear literal switcher query");
      Assert (Editor.Buffer_Switcher.Sort_Mode (S) = Editor.Buffer_Switcher.Pinned_Sort,
              "marked review does not clear sort mode");

      Editor.Buffer_Switcher.Hide_Marked_Review (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (not Editor.Buffer_Switcher.Has_Marked_Review (S),
              "hide disables marked review only");
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1
              and then Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta,
              "ordinary projection is restored while filter/query/sort remain active");
      Assert (Editor.Buffer_Switcher.Is_Marked (S, Alpha)
              and then Editor.Buffer_Switcher.Is_Marked (S, Beta),
              "marked review show/hide does not mutate mark membership");
   end Test_Marked_Review_Narrows_And_Composes_With_Filter_Query_And_Sort;

   procedure Test_Marked_Review_Empty_Clear_And_Navigation_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Selected : Boolean := False;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Untitled);
      Editor.Buffer_Switcher.Show_Marked_Review (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);

      Assert (Editor.Buffer_Switcher.Select_Next_Marked_Buffer (S),
              "next marked selects a marked candidate");
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S, Selected);
      begin
         Assert (Selected and then Row.Id = Untitled,
                 "next marked follows current effective row order");
      end;
      Assert (Editor.Buffer_Switcher.Select_Previous_Marked_Buffer (S),
              "previous marked selects a marked candidate");
      declare
         Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
           Editor.Buffer_Switcher.Selected_Row (S, Selected);
      begin
         Assert (Selected and then Row.Id = Alpha,
                 "previous marked follows current effective row order");
      end;

      Editor.Buffer_Switcher.Clear_Mark (S, Alpha);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1,
              "clearing a mark removes that row from active marked review candidates");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Untitled,
              "remaining marked row is preserved after review recompute");

      Editor.Buffer_Switcher.Clear_All_Marks (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 0,
              "clear all marks while review is active yields deterministic empty review");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 0,
              "empty marked review has no selected row");
      Assert (Editor.Buffer_Switcher.Has_Marked_Review (S),
              "empty marked review is not lazily repaired or disabled by projection");
      Assert (not Editor.Buffer_Switcher.Select_Next_Marked_Buffer (S),
              "next marked reports no candidate in empty review");
      Assert (not Editor.Buffer_Switcher.Select_Previous_Marked_Buffer (S),
              "previous marked reports no candidate in empty review");
   end Test_Marked_Review_Empty_Clear_And_Navigation_Are_Deterministic;


   procedure Test_Pending_Marked_Review_Uses_Captured_Targets_And_Composes
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Closed : Boolean := False;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Buffer_Label (Registry, Alpha, "keep");
      Editor.Buffers.Set_Buffer_Label (Registry, Beta, "keep");
      Editor.Buffers.Pin_Buffer (Registry, Beta);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Assert (Count = 2 and then Dirty_Count = 0,
              "preparing pending marked close captures currently marked open targets");

      Editor.Buffer_Switcher.Clear_All_Marks (S);
      Editor.Buffer_Switcher.Set_Mark (S, Untitled);
      Editor.Buffer_Switcher.Show_Pending_Marked_Review (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Has_Pending_Marked_Review (S),
              "pending marked review is enabled explicitly");
      Assert (not Editor.Buffer_Switcher.Has_Marked_Review (S),
              "pending marked review is the only active review constraint");
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 2,
              "pending marked review uses captured targets, not current marks");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha
              and then Editor.Buffer_Switcher.Row_At (S, 2).Id = Beta,
              "captured pending targets retain ordinary order before filters and sort");
      Assert (not Editor.Buffer_Switcher.Row_At (S, 1).Is_Marked
              and then not Editor.Buffer_Switcher.Row_At (S, 2).Is_Marked,
              "pending marked review does not recreate or modify marks");
      Assert (Editor.Buffer_Switcher.Is_Marked (S, Untitled),
              "mark changes after preparation remain independent");

      Editor.Buffer_Switcher.Set_Label_Filter (S, "keep");
      Editor.Buffer_Switcher.Set_Filter_Text (S, "read");
      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Pinned_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1
              and then Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta,
              "pending marked review composes with metadata filters, literal query, and sort");
      Assert (Editor.Buffer_Switcher.Select_Next_Pending_Marked_Buffer (S),
              "pending next selects within current effective projected pending targets");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 1,
              "pending navigation does not activate or leave the projected row set");

      Editor.Buffer_Switcher.Set_Filter_Text (S, "missing");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 0,
              "pending review has deterministic empty state when filters exclude all targets");
      Assert (not Editor.Buffer_Switcher.Select_Next_Pending_Marked_Buffer (S),
              "pending navigation reports no candidate in empty state");

      Editor.Buffer_Switcher.Set_Filter_Text (S, "");
      Editor.Buffer_Switcher.Clear_Metadata_Filter (S);
      Editor.Buffers.Close_Buffer (Registry, Alpha, Closed);
      Assert (Closed, "test setup closes one captured target");
      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1
              and then Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta,
              "pending review displays only captured targets that are still open");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S) = 2,
              "projection does not refresh or shrink captured pending target set");
      Assert (Editor.Buffer_Switcher.Is_Marked (S, Alpha),
              "projection does not prune or repair current marks while reviewing pending targets");

      Editor.Buffer_Switcher.Clear_Pending_Marked_Action (S);
      Assert (not Editor.Buffer_Switcher.Has_Pending_Marked_Review (S),
              "clearing pending action clears pending marked review state");
   end Test_Pending_Marked_Review_Uses_Captured_Targets_And_Composes;


   procedure Test_Phase287_Count_Badge_Text_Is_Derived_And_Compact
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Removed : Boolean := False;
      Remaining : Natural := 0;
      Restored : Boolean := False;
      Restored_Target : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Restored_Name : Unbounded_String := Null_Unbounded_String;
      Closed : Boolean := False;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) = "",
              "ordinary switcher has no count badge text when no marks or pending close exist");

      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) = "Marked: 2",
              "marked badge counts currently open marks");

      Editor.Buffer_Switcher.Set_Label_Filter (S, "missing");
      Editor.Buffer_Switcher.Set_Filter_Text (S, "not-visible");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 0,
              "test setup hides all marked buffers through filter and query");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) = "Marked: 2",
              "marked badge remains global, not visible-only or query-limited");

      Editor.Buffers.Close_Buffer (Registry, Alpha, Closed, Force => True);
      Assert (Closed, "test setup closes one marked buffer");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) = "Marked: 1",
              "marked badge counts only currently open marked buffers");

      Editor.Buffer_Switcher.Clear_Metadata_Filter (S);
      Editor.Buffer_Switcher.Set_Filter_Text (S, "");
      Editor.Buffer_Switcher.Clear_All_Marks (S);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Set_Mark (S, Untitled);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Assert (Count = 2 and then Dirty_Count = 0,
              "pending marked close captures the two currently open marked buffers");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 2 | Pending close: 2",
              "pending badge displays active still-open pending close targets");

      Editor.Buffer_Switcher.Clear_All_Marks (S);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 1 | Pending close: 2",
              "changing current marks after preparation does not change pending count");

      Editor.Buffer_Switcher.Remove_Pending_Marked_Close_Target
        (S, Registry, Beta, Removed, Remaining);
      Assert (Removed and then Remaining = 1,
              "test setup prunes one pending marked close target");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 1 | Pending close: 1 | Pruned: 1",
              "pruning decreases pending badge count and increases pruned badge count");

      Editor.Buffer_Switcher.Restore_Last_Pruned_Pending_Marked_Close_Target
        (S, Registry, Restored, Restored_Target, Restored_Name, Remaining);
      Assert (Restored and then Restored_Target = Beta and then Remaining = 2,
              "test setup restores the last pruned target");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 1 | Pending close: 2",
              "restoring a pruned target updates pending and removes pruned badge when empty");

      Editor.Buffers.Close_Buffer (Registry, Untitled, Closed, Force => True);
      Assert (Closed, "test setup closes one still-pending target");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 1 | Pending close: 1",
              "pending badge uses still-open pending target count");

      Editor.Buffer_Switcher.Clear_Pending_Marked_Action (S);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) = "Marked: 1",
              "clearing pending action clears pending and pruned badge state without clearing marks");
   end Test_Phase287_Count_Badge_Text_Is_Derived_And_Compact;

   procedure Test_Phase287_Count_Badges_Compose_With_Reviews_Without_Mutation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Removed : Boolean := False;
      Remaining : Natural := 0;
      Before_Preview : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Scroll : Natural := 0;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Set_Mark (S, Untitled);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Remove_Pending_Marked_Close_Target
        (S, Registry, Beta, Removed, Remaining);
      Assert (Removed and then Remaining = 2,
              "test setup prunes one of three pending targets");

      Editor.Buffer_Switcher.Show_Preview (S);
      Editor.Buffer_Switcher.Set_Preview_Target (S, Alpha, 1);
      Editor.Buffer_Switcher.Scroll_Preview_Next_Line (S);
      Editor.Buffer_Switcher.Show_Marked_Review (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Before_Preview := Editor.Buffer_Switcher.Preview_Target (S);
      Before_Scroll := Editor.Buffer_Switcher.Preview_Scroll_Offset (S);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 2 | Pruned: 1",
              "count badges compose with marked review and retain distinct sets");
      Assert (Editor.Buffer_Switcher.Has_Marked_Review (S),
              "reading count badge text does not hide marked review");

      Editor.Buffer_Switcher.Show_Pending_Marked_Review (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 2 | Pruned: 1",
              "count badges compose with pending review");
      Assert (Editor.Buffer_Switcher.Has_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Marked_Review (S),
              "count badge derivation does not change pending review policy");

      Editor.Buffer_Switcher.Show_Pruned_Pending_Marked_Review (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 2 | Pruned: 1",
              "count badges compose with pruned pending review");
      Assert (Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Pending_Marked_Review (S),
              "count badge derivation does not alter pruned review activation");

      Assert (Editor.Buffer_Switcher.Is_Marked (S, Alpha)
              and then Editor.Buffer_Switcher.Is_Marked (S, Beta)
              and then Editor.Buffer_Switcher.Is_Marked (S, Untitled),
              "count badge derivation does not mutate marks");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, Alpha)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, Untitled)
              and then not Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, Beta),
              "count badge derivation does not mutate active pending targets");
      Assert (Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S, Beta),
              "count badge derivation does not mutate pruned target history");
      Assert (Editor.Buffer_Switcher.Preview_Target (S) = Before_Preview
              and then Editor.Buffer_Switcher.Preview_Scroll_Offset (S) = Before_Scroll,
              "count badge derivation does not mutate preview target or scroll state");
   end Test_Phase287_Count_Badges_Compose_With_Reviews_Without_Mutation;



   procedure Test_Phase288_Dirty_Pending_Badge_Is_Derived_From_Active_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Removed : Boolean := False;
      Remaining : Natural := 0;
      Restored : Boolean := False;
      Restored_Target : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Restored_Name : Unbounded_String := Null_Unbounded_String;
      Closed : Boolean := False;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := True;
      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) = "Marked: 1",
              "dirty pending badge is absent when no pending marked close action exists");

      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Assert (Count = 2 and then Dirty_Count = 1,
              "preparation reports dirty targets captured from current dirty state");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 2 | Pending close: 2 | Dirty: 1",
              "dirty badge displays the dirty subset of active pending targets");

      Editor.Buffers.Buffer_Access (Registry, Untitled).File_Info.Dirty := True;
      Editor.Buffer_Switcher.Set_Mark (S, Untitled);
      Editor.Buffer_Switcher.Clear_Mark (S, Alpha);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 2 | Pending close: 2 | Dirty: 1",
              "dirty marked buffers outside the captured pending set do not affect dirty pending count");

      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := True;
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 2 | Pending close: 2 | Dirty: 2",
              "dirtying a clean active pending target updates the derived dirty badge");

      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := False;
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 2 | Pending close: 2 | Dirty: 1",
              "saving or otherwise cleaning a dirty pending target updates the derived dirty badge");

      Editor.Buffer_Switcher.Remove_Pending_Marked_Close_Target
        (S, Registry, Beta, Removed, Remaining);
      Assert (Removed and then Remaining = 1,
              "test setup prunes the remaining dirty pending target");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 2 | Pending close: 1 | Pruned: 1",
              "dirty pruned targets are excluded from dirty pending count");

      Editor.Buffer_Switcher.Restore_Last_Pruned_Pending_Marked_Close_Target
        (S, Registry, Restored, Restored_Target, Restored_Name, Remaining);
      Assert (Restored and then Restored_Target = Beta and then Remaining = 2,
              "test setup restores the dirty pruned target");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 2 | Pending close: 2 | Dirty: 1",
              "restoring a dirty pruned target returns it to dirty pending count");

      Editor.Buffer_Switcher.Set_Label_Filter (S, "missing");
      Editor.Buffer_Switcher.Set_Filter_Text (S, "not-visible");
      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 0,
              "test setup hides active pending targets through metadata filter and literal query");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 2 | Pending close: 2 | Dirty: 1",
              "dirty pending count is global over active targets and unaffected by filters, query, and sort");

      Editor.Buffers.Close_Buffer (Registry, Beta, Closed, Force => True);
      Assert (Closed, "test setup closes the dirty active pending target");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 1 | Pending close: 1",
              "closed captured pending targets are excluded from pending and dirty pending badges");

      Editor.Buffer_Switcher.Clear_Pending_Marked_Action (S);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) = "Marked: 1",
              "clearing pending marked close clears dirty pending badge without clearing marks");
   end Test_Phase288_Dirty_Pending_Badge_Is_Derived_From_Active_Targets;


   procedure Test_Phase289_Dirty_Pending_Navigation_Uses_Visible_Derived_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Removed : Boolean := False;
      Remaining : Natural := 0;
      Restored : Boolean := False;
      Restored_Target : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Restored_Name : Unbounded_String := Null_Unbounded_String;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := True;
      Editor.Buffers.Set_Buffer_Label (Registry, Alpha, "keep");
      Editor.Buffers.Set_Buffer_Label (Registry, Beta, "hide");

      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Assert (Count = 2 and then Dirty_Count = 2,
              "test setup captures two dirty pending close targets");

      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 2,
              "active buffer starts selected in ordinary projection");
      Assert (Editor.Buffer_Switcher.Select_Next_Dirty_Pending_Marked_Buffer (S),
              "dirty next finds a visible dirty active pending target");
      Assert (Editor.Buffer_Switcher.Row_At
                (S, Editor.Buffer_Switcher.Selected_Row_Index (S)).Id = Alpha,
              "dirty next wraps through current effective order without activation");
      Assert (Editor.Buffer_Switcher.Select_Previous_Dirty_Pending_Marked_Buffer (S),
              "dirty previous finds a visible dirty active pending target");
      Assert (Editor.Buffer_Switcher.Row_At
                (S, Editor.Buffer_Switcher.Selected_Row_Index (S)).Id = Beta,
              "dirty previous follows current effective order");

      Editor.Buffer_Switcher.Set_Label_Filter (S, "keep");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1
              and then Editor.Buffer_Switcher.Row_At (S, 1).Id = Alpha,
              "metadata filter constrains visible dirty pending navigation candidates");
      Assert (Editor.Buffer_Switcher.Select_Next_Dirty_Pending_Marked_Buffer (S),
              "dirty next uses filtered projected rows");
      Assert (Editor.Buffer_Switcher.Row_At
                (S, Editor.Buffer_Switcher.Selected_Row_Index (S)).Id = Alpha,
              "dirty next selects the filtered dirty pending target");

      Editor.Buffer_Switcher.Remove_Pending_Marked_Close_Target
        (S, Registry, Alpha, Removed, Remaining);
      Assert (Removed and then Remaining = 1,
              "test setup prunes the only visible dirty pending target");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (not Editor.Buffer_Switcher.Select_Next_Dirty_Pending_Marked_Buffer (S),
              "pruned dirty targets are excluded from dirty pending navigation");
      Assert (Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S, Alpha),
              "dirty navigation failure does not mutate pruned history");

      Editor.Buffer_Switcher.Restore_Last_Pruned_Pending_Marked_Close_Target
        (S, Registry, Restored, Restored_Target, Restored_Name, Remaining);
      Assert (Restored and then Restored_Target = Alpha and then Remaining = 2,
              "test setup restores the pruned dirty pending target");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Select_Next_Dirty_Pending_Marked_Buffer (S),
              "restored dirty active pending targets become navigable again");

      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := False;
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (not Editor.Buffer_Switcher.Select_Next_Dirty_Pending_Marked_Buffer (S),
              "cleaned pending targets stop being dirty-navigable under the current projection");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, Alpha)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, Beta),
              "dirty navigation does not mutate active pending close targets");
      Assert (Editor.Buffer_Switcher.Is_Marked (S, Alpha)
              and then Editor.Buffer_Switcher.Is_Marked (S, Beta),
              "dirty navigation does not mutate marks");
   end Test_Phase289_Dirty_Pending_Navigation_Uses_Visible_Derived_Targets;



   procedure Test_Phase296_Dirty_Prune_Count_Badges_Are_Derived_And_Global
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Removed : Boolean := False;
      Remaining : Natural := 0;
      Restored : Boolean := False;
      Restored_Target : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Restored_Name : Unbounded_String := Null_Unbounded_String;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := True;
      Editor.Buffers.Set_Buffer_Label (Registry, Alpha, "shown");
      Editor.Buffers.Set_Buffer_Label (Registry, Beta, "hidden");

      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Set_Mark (S, Untitled);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 3 | Dirty: 2",
              "Phase 296 dirty-prune badges are absent before dirty-prune preview exists");

      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Assert (Count = 2,
              "test setup captures the two dirty active pending close targets");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 3 | Dirty: 2 | Dirty prune: 2 | Applicable: 2",
              "Phase 296 badge displays captured dirty-prune targets and currently applicable subset");

      Editor.Buffer_Switcher.Set_Label_Filter (S, "missing");
      Editor.Buffer_Switcher.Set_Filter_Text (S, "not-visible");
      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 0,
              "test setup hides all rows through metadata filter and literal query");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 3 | Dirty: 2 | Dirty prune: 2 | Applicable: 2",
              "Phase 296 dirty-prune badges are global and not limited by filter, query, or sort");

      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := False;
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 3 | Dirty: 1 | Dirty prune: 2 | Applicable: 1",
              "Phase 296 applicable count follows current dirty state without changing captured preview count");

      Editor.Buffers.Buffer_Access (Registry, Untitled).File_Info.Dirty := True;
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 3 | Dirty: 2 | Dirty prune: 2 | Applicable: 1",
              "Phase 296 dirty pending and applicable remain distinct when a non-preview pending target becomes dirty");

      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, Alpha, Removed, Remaining);
      Assert (Removed and then Remaining = 1,
              "test setup removes one applicable dirty-prune preview target");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 3 | Dirty: 2 | Dirty prune: 1 | Applicable: 0 | Removed: 1",
              "Phase 296 removing an applicable preview target decreases dirty-prune and applicable counts and increases removed count");

      Editor.Buffer_Switcher.Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, Restored, Restored_Target, Restored_Name, Remaining);
      Assert (Restored and then Restored_Target = Alpha and then Remaining = 2,
              "test setup restores the removed dirty-prune preview target");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 3 | Dirty: 2 | Dirty prune: 2 | Applicable: 1",
              "Phase 296 restoring a still-applicable target updates dirty-prune, applicable, and removed badges");

      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, Beta, Removed, Remaining);
      Assert (Removed and then Remaining = 1,
              "test setup removes one clean dirty-prune preview target");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 3 | Dirty: 2 | Dirty prune: 1 | Applicable: 1 | Removed: 1",
              "Phase 296 removing a clean preview target leaves applicable unchanged and increases removed count");
   end Test_Phase296_Dirty_Prune_Count_Badges_Are_Derived_And_Global;


   procedure Test_Phase296_Dirty_Prune_Count_Badges_Clear_And_Do_Not_Mutate_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Removed : Boolean := False;
      Remaining : Natural := 0;
      Before_Preview : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Scroll : Natural := 0;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := True;

      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Set_Mark (S, Untitled);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, Beta, Removed, Remaining);
      Assert (Removed and then Remaining = 1,
              "test setup creates dirty-prune preview and removed-target history");

      Editor.Buffer_Switcher.Show_Preview (S);
      Editor.Buffer_Switcher.Set_Preview_Target (S, Alpha, 1);
      Editor.Buffer_Switcher.Scroll_Preview_Next_Line (S);
      Before_Preview := Editor.Buffer_Switcher.Preview_Target (S);
      Before_Scroll := Editor.Buffer_Switcher.Preview_Scroll_Offset (S);

      Editor.Buffer_Switcher.Show_Marked_Review (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 3 | Dirty: 2 | Dirty prune: 1 | Applicable: 1 | Removed: 1",
              "Phase 296 dirty-prune counts compose with marked review");
      Assert (Editor.Buffer_Switcher.Has_Marked_Review (S),
              "Phase 296 count projection does not alter marked review mode");

      Editor.Buffer_Switcher.Show_Pending_Marked_Review (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 3 | Dirty: 2 | Dirty prune: 1 | Applicable: 1 | Removed: 1",
              "Phase 296 dirty-prune counts compose with pending marked review");
      Assert (Editor.Buffer_Switcher.Has_Pending_Marked_Review (S),
              "Phase 296 count projection does not alter pending review mode");

      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 3 | Dirty: 2 | Dirty prune: 1 | Applicable: 1 | Removed: 1",
              "Phase 296 dirty-prune counts compose with dirty-prune review");
      Assert (Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S),
              "Phase 296 count projection does not alter dirty-prune review mode");

      Assert (Editor.Buffer_Switcher.Is_Marked (S, Alpha)
              and then Editor.Buffer_Switcher.Is_Marked (S, Beta),
              "Phase 296 count projection does not mutate marks");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, Alpha)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, Beta),
              "Phase 296 count projection does not mutate pending targets");
      Assert (Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S, Alpha)
              and then not Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S, Beta),
              "Phase 296 count projection does not mutate active dirty-prune preview targets");
      Assert (Editor.Buffer_Switcher.Is_Removed_Dirty_Pending_Marked_Close_Prune_Target (S, Beta),
              "Phase 296 count projection does not mutate removed dirty-prune history");
      Assert (Editor.Buffer_Switcher.Preview_Target (S) = Before_Preview
              and then Editor.Buffer_Switcher.Preview_Scroll_Offset (S) = Before_Scroll,
              "Phase 296 count projection does not mutate preview target or scroll state");

      Editor.Buffer_Switcher.Cancel_Dirty_Pending_Marked_Close_Prune (S);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 3 | Dirty: 2",
              "Phase 296 cancel clears dirty-prune, applicable, and removed badge display");

      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 3 | Pending close: 3 | Dirty: 2 | Dirty prune: 2 | Applicable: 2",
              "Phase 296 refreshing the preview rebuilds counts and clears old removed badge display");

      Editor.Buffer_Switcher.Apply_Dirty_Pending_Marked_Close_Prune (S, Registry, Count, Remaining);
      Assert (Count = 2
              and then Remaining = 1
              and then Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
                "Marked: 3 | Pending close: 1 | Pruned: 2",
              "Phase 296 apply clears dirty-prune badges and leaves ordinary pruned badge distinct");

      Editor.Buffer_Switcher.Clear_Pending_Marked_Action (S);
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) = "Marked: 3",
              "Phase 296 clearing pending marked close clears all pending and dirty-prune badges");
   end Test_Phase296_Dirty_Prune_Count_Badges_Clear_And_Do_Not_Mutate_State;


   procedure Test_Phase297_Dirty_Prune_Clear_Stale_Is_Targeted_And_Non_Recording
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled, Gamma, Step_Delta : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Removed : Boolean := False;
      Pending_Remaining : Natural := 0;
      Preview_Remaining : Natural := 0;
      Cleared : Natural := 0;
      Closed : Boolean := False;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Gamma := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/project/src/gamma.adb", "gamma.adb", "gamma");
      Step_Delta := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/project/src/delta.adb", "delta.adb", "delta");
      Editor.Buffer_Switcher.Open (S);

      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Untitled).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Gamma).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Step_Delta).File_Info.Dirty := True;
      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Set_Mark (S, Untitled);
      Editor.Buffer_Switcher.Set_Mark (S, Gamma);
      Editor.Buffer_Switcher.Set_Mark (S, Step_Delta);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Assert (Count = 5, "Phase 297 setup captures all dirty pending targets");

      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, Gamma, Removed, Preview_Remaining);
      Assert (Removed and then Preview_Remaining = 4
              and then Editor.Buffer_Switcher.Removed_Dirty_Pending_Marked_Close_Prune_Target_Count (S) = 1,
              "Phase 297 setup records one explicit removed dirty-prune target");

      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := False;
      Editor.Buffers.Close_Buffer (Registry, Beta, Closed, Force => True);
      Assert (Closed, "Phase 297 setup closes one captured preview target");
      Editor.Buffer_Switcher.Remove_Pending_Marked_Close_Target
        (S, Registry, Untitled, Removed, Pending_Remaining);
      Assert (Removed and then Pending_Remaining = 4,
              "Phase 297 setup prunes one captured target from active pending close");

      Editor.Buffer_Switcher.Set_Filter_Text (S, "not-visible");
      Editor.Buffer_Switcher.Set_Label_Filter (S, "missing");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 0,
              "Phase 297 setup hides stale targets from visible rows");
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Stale_Target_Count
                (S, Registry) = 3,
              "Phase 297 stale count includes closed, non-pending, and clean preview targets");

      Editor.Buffer_Switcher.Clear_Stale_Dirty_Pending_Marked_Close_Prune_Targets
        (S, Registry, Cleared, Preview_Remaining);
      Assert (Cleared = 3 and then Preview_Remaining = 1,
              "Phase 297 clear-stale removes all stale targets including hidden rows");
      Assert (Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S, Step_Delta)
              and then not Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S, Alpha)
              and then not Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S, Beta)
              and then not Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S, Untitled),
              "Phase 297 clear-stale preserves only open active pending dirty preview targets");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, Alpha)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, Beta)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, Step_Delta),
              "Phase 297 clear-stale does not remove active pending close targets");
      Assert (Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S) = 1,
              "Phase 297 clear-stale does not add ordinary pruned pending targets");
      Assert (Editor.Buffer_Switcher.Removed_Dirty_Pending_Marked_Close_Prune_Target_Count (S) = 1
              and then Editor.Buffer_Switcher.Is_Removed_Dirty_Pending_Marked_Close_Prune_Target (S, Gamma),
              "Phase 297 clear-stale does not add targets to removed dirty-prune history");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 4 | Pending close: 3 | Dirty: 2 | Pruned: 1 | Dirty prune: 1 | Applicable: 1 | Removed: 1",
              "Phase 297 clear-stale updates dirty-prune and applicable counts without increasing removed count");
   end Test_Phase297_Dirty_Prune_Clear_Stale_Is_Targeted_And_Non_Recording;


   procedure Test_Phase297_Dirty_Prune_Clear_Stale_Zero_Target_Clears_Preview
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Cleared : Natural := 0;
      Remaining : Natural := 0;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := True;
      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S);
      Assert (Count = 2 and then Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S),
              "Phase 297 setup has an active dirty-prune review");

      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := False;
      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := False;
      Editor.Buffer_Switcher.Clear_Stale_Dirty_Pending_Marked_Close_Prune_Targets
        (S, Registry, Cleared, Remaining);
      Assert (Cleared = 2 and then Remaining = 0,
              "Phase 297 clear-stale can remove every active preview target");
      Assert (not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S)
              and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets (S),
              "Phase 297 zero-target policy clears dirty-prune preview, review, and removed-preview history");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S) = 2
              and then Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
                "Marked: 2 | Pending close: 2",
              "Phase 297 zero-target clear-stale leaves pending close and mark state intact");
   end Test_Phase297_Dirty_Prune_Clear_Stale_Zero_Target_Clears_Preview;


   procedure Test_Phase298_Dirty_Prune_Workflow_Reset_And_Zero_Target_Policy
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Removed : Boolean := False;
      Remaining : Natural := 0;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := True;

      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Assert (Count = 2
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S) = 2,
              "Phase 298 setup captures the dirty active pending close targets");

      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S);
      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, Alpha, Removed, Remaining);
      Assert (Removed
              and then Remaining = 1
              and then Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S)
              and then Editor.Buffer_Switcher.Removed_Dirty_Pending_Marked_Close_Prune_Target_Count (S) = 1,
              "Phase 298 setup creates active preview, active review, and removed-preview history");

      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := False;
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Assert (Count = 1
              and then Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S, Alpha)
              and then not Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S, Beta)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S)
              and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets (S),
              "Phase 298 preview refresh clears removed history and dirty-prune review state before recapturing current targets");

      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S);
      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, Alpha, Removed, Remaining);
      Assert (Removed and then Remaining = 0,
              "Phase 298 removing the final active preview target reports zero remaining targets");
      Assert (not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S)
              and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Targets (S),
              "Phase 298 zero-target removal clears the dirty-prune action, review mode, and removed-preview history");
      Assert (Editor.Buffer_Switcher.Pending_Marked_Target_Count (S) = 2
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S) = 0
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, Alpha)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, Beta)
              and then Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
                "Marked: 2 | Pending close: 2 | Dirty: 1",
              "Phase 298 zero-target removal leaves pending close, ordinary pruned history, marks, and dirty state independent");
   end Test_Phase298_Dirty_Prune_Workflow_Reset_And_Zero_Target_Policy;


   procedure Test_Phase299_Dirty_Prune_Apply_Prepare_Remove_Restore_And_Badges
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Applicable : Natural := 0;
      Removed : Boolean := False;
      Restored : Boolean := False;
      Target : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Name : Unbounded_String := Null_Unbounded_String;
      Remaining : Natural := 0;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := True;

      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Count, Applicable);

      Assert (Count = 2
              and then Applicable = 2
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S) = 2
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Apply_Target_Count (S) = 2,
              "Phase 299 apply preparation captures active preview targets without mutating the preview");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
                "Marked: 2 | Pending close: 2 | Dirty: 2 | Dirty prune: 2 | Applicable: 2 | Apply: 2 | Apply applicable: 2",
              "Phase 299 apply count badges are distinct from dirty-prune preview badges");

      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S, Alpha, 1);
      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Apply_Target
        (S, Registry, Alpha, Removed, Remaining);
      Assert (Removed
              and then Remaining = 1
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Apply_Target_Count (S) = 1
              and then Editor.Buffer_Switcher.Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count (S) = 1
              and then Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count (S) = 2
              and then Editor.Buffer_Switcher.Pending_Marked_Target_Count (S) = 2
              and then Editor.Buffer_Switcher.Pruned_Pending_Marked_Close_Target_Count (S) = 0,
              "Phase 299 apply target removal edits only apply-confirmation state");

      Editor.Buffer_Switcher.Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target
        (S, Registry, Restored, Target, Name, Remaining);
      Assert (Restored
              and then Target = Alpha
              and then Remaining = 2
              and then Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Apply_Target (S, Alpha)
              and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Targets (S),
              "Phase 299 restore-last-removed returns an open apply target to the captured apply set");
   end Test_Phase299_Dirty_Prune_Apply_Prepare_Remove_Restore_And_Badges;


   procedure Test_Phase299_Dirty_Prune_Apply_Confirm_Revalidates_And_Consumes_Preview
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Applicable : Natural := 0;
      Applied : Natural := 0;
      Skipped : Natural := 0;
      Remaining : Natural := 0;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := True;

      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Count, Applicable);

      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := False;
      Assert (Editor.Buffer_Switcher.Applicable_Dirty_Pending_Marked_Close_Prune_Apply_Target_Count (S, Registry) = 1,
              "Phase 299 applicable apply count is derived from current dirty pending state");

      Editor.Buffer_Switcher.Confirm_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Applied, Skipped, Remaining);
      Assert (Applied = 1
              and then Skipped = 1
              and then Remaining = 1
              and then not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune_Apply (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Close_Prune (S)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S, Alpha)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, Beta)
              and then not Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S, Beta),
              "Phase 299 confirm revalidates, prunes only applicable targets, records ordinary pruned history, and consumes preview/apply state");
      Assert (Editor.Buffers.Contains (Registry, Alpha)
              and then Editor.Buffers.Contains (Registry, Beta),
              "Phase 299 confirm does not close buffers");
   end Test_Phase299_Dirty_Prune_Apply_Confirm_Revalidates_And_Consumes_Preview;


   procedure Test_Phase300_Review_Mode_Is_Exclusive_And_Centralized
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Applicable : Natural := 0;
      Removed : Boolean := False;
      Remaining : Natural := 0;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := True;
      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Set_Mark (S, Untitled);

      Editor.Buffer_Switcher.Show_Marked_Review (S);
      Assert (Editor.Buffer_Switcher.Has_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Apply_Review (S),
              "Phase 300 marked review is the single active review mode");

      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Show_Pending_Marked_Review (S);
      Assert (Editor.Buffer_Switcher.Has_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Apply_Review (S),
              "Phase 300 pending review replaces marked review");

      Editor.Buffer_Switcher.Show_Dirty_Pending_Marked_Review (S);
      Assert (Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Apply_Review (S),
              "Phase 300 dirty pending review replaces pending review");

      Editor.Buffer_Switcher.Remove_Pending_Marked_Close_Target
        (S, Registry, Untitled, Removed, Remaining);
      Editor.Buffer_Switcher.Show_Pruned_Pending_Marked_Review (S);
      Assert (Removed
              and then Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Apply_Review (S),
              "Phase 300 pruned review replaces dirty pending review");

      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S);
      Assert (Count = 2
              and then Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S)
              and then not Editor.Buffer_Switcher.Has_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Prune_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Apply_Review (S),
              "Phase 300 dirty-prune preview review replaces pruned review");

      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, Alpha, Removed, Remaining);
      Editor.Buffer_Switcher.Show_Removed_Dirty_Prune_Review (S);
      Assert (Removed
              and then Editor.Buffer_Switcher.Has_Removed_Dirty_Prune_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Apply_Review (S),
              "Phase 300 removed dirty-prune preview review replaces preview review");

      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Count, Applicable);
      Editor.Buffer_Switcher.Show_Dirty_Prune_Apply_Review (S);
      Assert (Count = 1
              and then Applicable = 1
              and then Editor.Buffer_Switcher.Has_Dirty_Prune_Apply_Review (S)
              and then not Editor.Buffer_Switcher.Has_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Pruned_Pending_Marked_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Review (S)
              and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Prune_Review (S),
              "Phase 300 dirty-prune apply review replaces removed preview review");

      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Apply_Target
        (S, Registry, Beta, Removed, Remaining);
      Editor.Buffer_Switcher.Show_Removed_Dirty_Prune_Apply_Review (S);
      Assert (Removed
              and then Editor.Buffer_Switcher.Has_Removed_Dirty_Prune_Apply_Review (S)
              and then not Editor.Buffer_Switcher.Has_Dirty_Prune_Apply_Review (S)
              and then not Editor.Buffer_Switcher.Has_Removed_Dirty_Prune_Review (S),
              "Phase 300 removed dirty-prune apply review replaces apply review");

      Editor.Buffer_Switcher.Toggle_Removed_Dirty_Prune_Apply_Review (S);
      Assert (not Editor.Buffer_Switcher.Has_Removed_Dirty_Prune_Apply_Review (S),
              "Phase 300 toggling active removed apply review hides it through the shared core");
      Editor.Buffer_Switcher.Show_Dirty_Prune_Apply_Review (S);
      Editor.Buffer_Switcher.Toggle_Dirty_Prune_Apply_Review (S);
      Assert (not Editor.Buffer_Switcher.Has_Dirty_Prune_Apply_Review (S),
              "Phase 300 toggling the active review hides it through the shared core");
      Editor.Buffer_Switcher.Toggle_Marked_Review (S);
      Assert (Editor.Buffer_Switcher.Has_Marked_Review (S),
              "Phase 300 toggling an inactive review activates it through the shared core");

      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 3,
              "Phase 300 review mode remains a projection constraint over open buffers only");
   end Test_Phase300_Review_Mode_Is_Exclusive_And_Centralized;

   procedure Test_Phase300_Review_Projection_Order_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Buffer_Label (Registry, Alpha, "phase300");
      Editor.Buffers.Set_Buffer_Label (Registry, Beta, "phase300");
      Editor.Buffers.Pin_Buffer (Registry, Beta);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);

      Editor.Buffer_Switcher.Show_Pending_Marked_Review (S);
      Editor.Buffer_Switcher.Set_Label_Filter (S, "phase300");
      Editor.Buffer_Switcher.Set_Filter_Text (S, "read");
      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Pinned_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);

      Assert (Editor.Buffer_Switcher.Has_Pending_Marked_Review (S),
              "Phase 300 filter/query/sort changes do not clear active review mode");
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1
              and then Editor.Buffer_Switcher.Row_At (S, 1).Id = Beta,
              "Phase 300 projection applies review constraint before metadata filter, literal query, and sort");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 1,
              "Phase 300 selection normalizes after reviewed projection is built");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              "Marked: 2 | Pending close: 2",
              "Phase 300 count badges remain global derived state, not review-local state");
      Assert (Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, Alpha)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, Beta),
              "Phase 300 projection does not mutate reviewed target membership");
   end Test_Phase300_Review_Projection_Order_Is_Deterministic;


   procedure Test_Phase301_Batch_State_Snapshot_Centralizes_Counts_And_Badges
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Applicable : Natural := 0;
      Removed : Boolean := False;
      Remaining : Natural := 0;
      Snapshot : Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Untitled).File_Info.Dirty := True;

      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Set_Mark (S, Untitled);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, Beta, Removed, Remaining);
      Assert (Removed and then Remaining = 2,
              "Phase 301 setup records one removed dirty-prune preview target");

      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Count, Applicable);
      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Apply_Target
        (S, Registry, Alpha, Removed, Remaining);
      Assert (Removed and then Remaining = 1,
              "Phase 301 setup records one removed dirty-prune apply target without clearing apply confirmation");

      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Snapshot.Marked_Count = 3
              and then Snapshot.Pending_Close_Count = 3
              and then Snapshot.Dirty_Pending_Close_Count = 3
              and then Snapshot.Pruned_Pending_Close_Count = 0,
              "Phase 301 snapshot centralizes marked, pending, dirty, and ordinary-pruned counts");
      Assert (Snapshot.Dirty_Prune_Preview_Count = 2
              and then Snapshot.Applicable_Dirty_Prune_Preview_Count = 2
              and then Snapshot.Removed_Dirty_Prune_Preview_Count = 1
              and then Snapshot.Open_Removed_Dirty_Prune_Preview_Count = 1
              and then Snapshot.Stale_Dirty_Prune_Preview_Count = 0,
              "Phase 301 snapshot centralizes dirty-prune preview, removed, open-removed, applicable, and stale counts");
      Assert (Snapshot.Dirty_Prune_Apply_Count = 1
              and then Snapshot.Applicable_Dirty_Prune_Apply_Count = 1
              and then Snapshot.Removed_Dirty_Prune_Apply_Count = 1
              and then Snapshot.Open_Removed_Dirty_Prune_Apply_Count = 1
              and then Snapshot.Stale_Dirty_Prune_Apply_Count = 0,
              "Phase 301 snapshot centralizes dirty-prune apply, removed, open-removed, applicable, and stale counts");
      Assert (Snapshot.Has_Pending_Marked_Close
              and then Snapshot.Has_Dirty_Prune_Preview
              and then Snapshot.Has_Dirty_Prune_Apply_Confirmation,
              "Phase 301 snapshot derives workflow presence flags from existing session state");
      Assert (To_String (Snapshot.Header_Badge_Text) =
              "Marked: 3 | Pending close: 3 | Dirty: 3 | Dirty prune: 2 | Applicable: 2 | Removed: 1 | Apply: 1 | Apply applicable: 1 | Apply removed: 1",
              "Phase 301 snapshot owns deterministic count badge text");
      Assert (Editor.Buffer_Switcher.Count_Badge_Text (S, Registry) =
              To_String (Snapshot.Footer_Badge_Text),
              "Phase 301 previous count badge helper is backed by the centralized snapshot path");
      Assert (To_String (Snapshot.Footer_Badge_Text) =
              "Marked: 3 | Pending close: 3 | Dirty: 3 | Dirty prune: 2 | Applicable: 2 | Removed: 1 | Apply: 1 | Apply applicable: 1 | Apply removed: 1",
              "Phase 301 footer badge text is derived as compact count-only snapshot text");

      Editor.Buffer_Switcher.Show_Dirty_Prune_Apply_Review (S);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Snapshot.Active_Review_Mode = Editor.Buffer_Switcher.Dirty_Prune_Apply_Review
              and then To_String (Snapshot.Review_Display_Name) = "dirty-prune apply"
              and then To_String (Snapshot.Review_Empty_Message) = "No dirty-prune apply targets",
              "Phase 301 snapshot derives review labels and empty messages from the unified review discriminator");
      Assert (To_String (Snapshot.Header_Badge_Text) =
              "Review: dirty-prune apply | Marked: 3 | Pending close: 3 | Dirty: 3 | Dirty prune: 2 | Applicable: 2 | Removed: 1 | Apply: 1 | Apply applicable: 1 | Apply removed: 1",
              "Phase 301 header badge text composes the active review label with centralized counts");
      Assert (To_String (Snapshot.Footer_Badge_Text) =
              "Marked: 3 | Pending close: 3 | Dirty: 3 | Dirty prune: 2 | Applicable: 2 | Removed: 1 | Apply: 1 | Apply applicable: 1 | Apply removed: 1",
              "Phase 301 footer badge text remains count-only when header adds review context");
   end Test_Phase301_Batch_State_Snapshot_Centralizes_Counts_And_Badges;


   procedure Test_Phase301_Row_Markers_And_Global_Counts_Compose_With_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Applicable : Natural := 0;
      Removed : Boolean := False;
      Remaining : Natural := 0;
      Snapshot : Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffers.Buffer_Access (Registry, Alpha).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Beta).File_Info.Dirty := True;
      Editor.Buffers.Buffer_Access (Registry, Untitled).File_Info.Dirty := True;
      Editor.Buffers.Set_Buffer_Label (Registry, Untitled, "shown");

      Editor.Buffer_Switcher.Set_Mark (S, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S, Beta);
      Editor.Buffer_Switcher.Set_Mark (S, Untitled);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, Beta, Removed, Remaining);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Count, Applicable);
      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Apply_Target
        (S, Registry, Alpha, Removed, Remaining);

      Editor.Buffer_Switcher.Show_Dirty_Prune_Apply_Review (S);
      Editor.Buffer_Switcher.Set_Label_Filter (S, "shown");
      Editor.Buffer_Switcher.Set_Filter_Text (S, "Untitled");
      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);

      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1
              and then Editor.Buffer_Switcher.Row_At (S, 1).Id = Untitled,
              "Phase 301 projection still applies review, metadata filter, literal query, and sort to candidate rows");
      Assert (Editor.Buffer_Switcher.Row_At (S, 1).Is_Marked
              and then Editor.Buffer_Switcher.Row_At (S, 1).Is_Pending_Close_Target
              and then Editor.Buffer_Switcher.Row_At (S, 1).Is_Dirty
              and then Editor.Buffer_Switcher.Row_At (S, 1).Is_Dirty_Prune_Preview_Target
              and then Editor.Buffer_Switcher.Row_At (S, 1).Is_Dirty_Prune_Apply_Target,
              "Phase 301 row marker derivation preserves overlapping marker states on projected rows");
      Assert (not Editor.Buffer_Switcher.Row_At (S, 1).Is_Removed_Dirty_Prune_Preview_Target
              and then not Editor.Buffer_Switcher.Row_At (S, 1).Is_Removed_Dirty_Prune_Apply_Target,
              "Phase 301 row marker derivation does not invent removed markers for active targets");

      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Snapshot.Marked_Count = 3
              and then Snapshot.Pending_Close_Count = 3
              and then Snapshot.Dirty_Prune_Preview_Count = 2
              and then Snapshot.Removed_Dirty_Prune_Preview_Count = 1
              and then Snapshot.Dirty_Prune_Apply_Count = 1
              and then Snapshot.Removed_Dirty_Prune_Apply_Count = 1,
              "Phase 301 snapshot counts remain global even when review/filter/query hide counted targets");
      Assert (To_String (Snapshot.Header_Badge_Text) =
              "Review: dirty-prune apply | Filter: label shown | Query: Untitled | Sort: name | Marked: 3 | Pending close: 3 | Dirty: 3 | Dirty prune: 2 | Applicable: 2 | Removed: 1 | Apply: 1 | Apply applicable: 1 | Apply removed: 1",
              "Phase 301 header badge text composes review, filter, query, sort, and global batch counts deterministically");
      Assert (Editor.Buffer_Switcher.Is_Removed_Dirty_Pending_Marked_Close_Prune_Target (S, Beta)
              and then Editor.Buffer_Switcher.Is_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target (S, Alpha)
              and then Editor.Buffer_Switcher.Preview_Target (S) = Editor.Buffers.No_Buffer,
              "Phase 301 snapshot/projection does not mutate removed histories or preview state");
   end Test_Phase301_Row_Markers_And_Global_Counts_Compose_With_Projection;


   type Buffer_Id_Array is array (Positive range <>) of Editor.Buffers.Buffer_Id;

   function Add_Phase302_Buffer
     (Registry : in out Editor.Buffers.Buffer_Registry;
      Name     : String) return Editor.Buffers.Buffer_Id
   is
   begin
      return Editor.Buffers.Add_Buffer_From_File
        (Registry,
         "/tmp/project/src/" & Name,
         Name,
         "procedure " & Name & " is begin null; end;");
   end Add_Phase302_Buffer;

   procedure Build_Phase302_Registry
     (Registry : in out Editor.Buffers.Buffer_Registry;
      A        : out Editor.Buffers.Buffer_Id;
      B        : out Editor.Buffers.Buffer_Id;
      C        : out Editor.Buffers.Buffer_Id;
      D        : out Editor.Buffers.Buffer_Id)
   is
   begin
      A := Add_Phase302_Buffer (Registry, "A.adb");
      B := Add_Phase302_Buffer (Registry, "B.adb");
      C := Add_Phase302_Buffer (Registry, "C.adb");
      D := Add_Phase302_Buffer (Registry, "D.adb");
      Editor.Buffers.Set_Active_Buffer (Registry, A);
   end Build_Phase302_Registry;

   procedure Make_Dirty
     (Registry : in out Editor.Buffers.Buffer_Registry;
      Id       : Editor.Buffers.Buffer_Id) is
   begin
      Editor.Buffers.Buffer_Access (Registry, Id).File_Info.Dirty := True;
   end Make_Dirty;

   procedure Make_Clean
     (Registry : in out Editor.Buffers.Buffer_Registry;
      Id       : Editor.Buffers.Buffer_Id) is
   begin
      Editor.Buffers.Buffer_Access (Registry, Id).File_Info.Dirty := False;
   end Make_Clean;

   procedure Confirm_Pending_Marked_Close_For_Test
     (State        : in out Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry     : in out Editor.Buffers.Buffer_Registry;
      Closed_Count : out Natural)
   is
      Target_Count : constant Natural := Editor.Buffer_Switcher.Pending_Marked_Target_Count (State);
      Closed       : Boolean := False;
   begin
      Closed_Count := 0;
      if Target_Count > 0 then
         declare
            Targets : Buffer_Id_Array (1 .. Target_Count);
         begin
            for I in Targets'Range loop
               Targets (I) := Editor.Buffer_Switcher.Pending_Marked_Target_At (State, I);
            end loop;

            for I in Targets'Range loop
               Editor.Buffers.Close_Buffer (Registry, Targets (I), Closed, Force => False);
               if Closed then
                  Closed_Count := Closed_Count + 1;
               end if;
            end loop;
         end;
      end if;

      Editor.Buffer_Switcher.Clear_Pending_Marked_Action (State);
      Editor.Buffer_Switcher.Prune_Marks (State, Registry);
   end Confirm_Pending_Marked_Close_For_Test;

   procedure Assert_No_Workflow_State
     (State    : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Message  : String)
   is
      Snapshot : constant Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot :=
        Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (State, Registry);
   begin
      Assert (Snapshot.Pending_Close_Count = 0
              and then Snapshot.Dirty_Prune_Preview_Count = 0
              and then Snapshot.Dirty_Prune_Apply_Count = 0
              and then not Snapshot.Has_Pending_Marked_Close
              and then not Snapshot.Has_Dirty_Prune_Preview
              and then not Snapshot.Has_Dirty_Prune_Apply_Confirmation
              and then Snapshot.Active_Review_Mode = Editor.Buffer_Switcher.No_Review,
              Message);
   end Assert_No_Workflow_State;

   procedure Test_Phase302_Clean_And_Dirty_Marked_Close_End_To_End
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      A, B, C, D : Editor.Buffers.Buffer_Id;
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Closed_Count : Natural := 0;
      Snapshot : Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot;
      pragma Unreferenced (D);
   begin
      Build_Phase302_Registry (Registry, A, B, C, D);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Set_Mark (S, A);
      Editor.Buffer_Switcher.Set_Mark (S, B);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Count = 2
              and then Dirty_Count = 0
              and then Snapshot.Marked_Count = 2
              and then Snapshot.Pending_Close_Count = 2
              and then Snapshot.Dirty_Pending_Close_Count = 0
              and then Snapshot.Dirty_Prune_Preview_Count = 0
              and then Snapshot.Dirty_Prune_Apply_Count = 0,
              "Phase 302 clean marked-close preparation captures only marked buffers and creates no dirty-prune state");
      Assert (Editor.Buffers.Contains (Registry, A)
              and then Editor.Buffers.Contains (Registry, B)
              and then True,
              "Phase 302 marked-close preparation does not close buffers or create reopen entries");

      Confirm_Pending_Marked_Close_For_Test (S, Registry, Closed_Count);
      Assert (Closed_Count = 2
              and then not Editor.Buffers.Contains (Registry, A)
              and then not Editor.Buffers.Contains (Registry, B)
              and then Editor.Buffers.Contains (Registry, C)
              and then True,
              "Phase 436 clean marked-close confirmation must not create removed-name close-history/reopen-stack state");
      Assert_No_Workflow_State (S, Registry,
        "Phase 302 clean marked-close confirmation clears pending, dirty-prune, apply, and review state");

      declare
         Registry_2 : Editor.Buffers.Buffer_Registry;
         S_2 : Editor.Buffer_Switcher.Buffer_Switcher_State;
         A_2, B_2, C_2, D_2 : Editor.Buffers.Buffer_Id;
         pragma Unreferenced (C_2, D_2);
      begin
         Build_Phase302_Registry (Registry_2, A_2, B_2, C_2, D_2);
         Editor.Buffer_Switcher.Open (S_2);
         Make_Dirty (Registry_2, B_2);
         Editor.Buffer_Switcher.Set_Mark (S_2, A_2);
         Editor.Buffer_Switcher.Set_Mark (S_2, B_2);
         Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S_2, Registry_2, Count, Dirty_Count);
         Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S_2, Registry_2);
         Assert (Snapshot.Pending_Close_Count = 2
                 and then Snapshot.Dirty_Pending_Close_Count = 1,
                 "Phase 302 dirty pending marked-close path reports dirty pending targets before confirmation");

         Confirm_Pending_Marked_Close_For_Test (S_2, Registry_2, Closed_Count);
         Assert (Closed_Count = 1
                 and then not Editor.Buffers.Contains (Registry_2, A_2)
                 and then Editor.Buffers.Contains (Registry_2, B_2)
                 and then Editor.Buffers.Is_Dirty (Registry_2, B_2)
                 and then True,
                 "Phase 436 marked-close confirmation does not force-close dirty buffers and creates no removed-name reopen stack");
      end;
   end Test_Phase302_Clean_And_Dirty_Marked_Close_End_To_End;


   procedure Test_Phase302_Dirty_Prune_Apply_Does_Not_Close_Dirty_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      A, B, C, D : Editor.Buffers.Buffer_Id;
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Applicable : Natural := 0;
      Applied : Natural := 0;
      Skipped : Natural := 0;
      Remaining : Natural := 0;
      Closed_Count : Natural := 0;
      Snapshot : Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot;
      pragma Unreferenced (D);
   begin
      Build_Phase302_Registry (Registry, A, B, C, D);
      Editor.Buffer_Switcher.Open (S);
      Make_Dirty (Registry, B);
      Make_Dirty (Registry, C);
      Editor.Buffer_Switcher.Set_Mark (S, A);
      Editor.Buffer_Switcher.Set_Mark (S, B);
      Editor.Buffer_Switcher.Set_Mark (S, C);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Snapshot.Pending_Close_Count = 3
              and then Snapshot.Dirty_Pending_Close_Count = 2,
              "Phase 302 dirty-prune workflow starts from captured pending close and dirty pending counts");

      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Count = 2
              and then Snapshot.Dirty_Prune_Preview_Count = 2
              and then Snapshot.Applicable_Dirty_Prune_Preview_Count = 2,
              "Phase 302 dirty-prune preview captures all dirty active pending targets");

      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Count, Applicable);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Count = 2
              and then Applicable = 2
              and then Snapshot.Dirty_Prune_Apply_Count = 2
              and then Snapshot.Applicable_Dirty_Prune_Apply_Count = 2,
              "Phase 302 dirty-prune apply confirmation captures applicable preview targets");

      Editor.Buffer_Switcher.Confirm_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Applied, Skipped, Remaining);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Applied = 2
              and then Skipped = 0
              and then Remaining = 1
              and then Snapshot.Pending_Close_Count = 1
              and then Snapshot.Dirty_Pending_Close_Count = 0
              and then Snapshot.Pruned_Pending_Close_Count = 2
              and then Snapshot.Dirty_Prune_Preview_Count = 0
              and then Snapshot.Dirty_Prune_Apply_Count = 0,
              "Phase 302 dirty-prune apply prunes only pending close targets and consumes preview/apply state");
      Assert (Editor.Buffers.Contains (Registry, B)
              and then Editor.Buffers.Contains (Registry, C)
              and then Editor.Buffers.Is_Dirty (Registry, B)
              and then Editor.Buffers.Is_Dirty (Registry, C)
              and then True,
              "Phase 302 dirty-prune apply does not close dirty buffers or create reopen entries");

      Confirm_Pending_Marked_Close_For_Test (S, Registry, Closed_Count);
      Assert (Closed_Count = 1
              and then not Editor.Buffers.Contains (Registry, A)
              and then Editor.Buffers.Contains (Registry, B)
              and then Editor.Buffers.Contains (Registry, C)
              and then True,
              "Phase 436 final marked-close confirmation closes only clean pending target and creates no removed-name reopen stack");
   end Test_Phase302_Dirty_Prune_Apply_Does_Not_Close_Dirty_Buffers;


   procedure Test_Phase302_Dirty_Prune_Preview_Removal_Does_Not_Prune_Pending_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      A, B, C, D : Editor.Buffers.Buffer_Id;
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Applicable : Natural := 0;
      Removed : Boolean := False;
      Restored : Boolean := False;
      Target : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Name : Unbounded_String := Null_Unbounded_String;
      Remaining : Natural := 0;
      Applied : Natural := 0;
      Skipped : Natural := 0;
      Snapshot : Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot;
      pragma Unreferenced (D, Name);
   begin
      Build_Phase302_Registry (Registry, A, B, C, D);
      Editor.Buffer_Switcher.Open (S);
      Make_Dirty (Registry, B);
      Make_Dirty (Registry, C);
      Editor.Buffer_Switcher.Set_Mark (S, A);
      Editor.Buffer_Switcher.Set_Mark (S, B);
      Editor.Buffer_Switcher.Set_Mark (S, C);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);

      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, B, Removed, Remaining);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Removed
              and then Remaining = 1
              and then Snapshot.Dirty_Prune_Preview_Count = 1
              and then Snapshot.Removed_Dirty_Prune_Preview_Count = 1
              and then Snapshot.Pending_Close_Count = 3
              and then Snapshot.Dirty_Pending_Close_Count = 2
              and then Snapshot.Pruned_Pending_Close_Count = 0,
              "Phase 302 dirty-prune preview removal is not ordinary pending target pruning");

      Editor.Buffer_Switcher.Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, Restored, Target, Name, Remaining);
      Assert (Restored
              and then Target = B
              and then Remaining = 2
              and then Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S, B),
              "Phase 302 restore-last-removed restores preview targets, not ordinary pruned targets");

      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, B, Removed, Remaining);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Count, Applicable);
      Editor.Buffer_Switcher.Confirm_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Applied, Skipped, Remaining);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Applied = 1
              and then Snapshot.Pending_Close_Count = 2
              and then Snapshot.Dirty_Pending_Close_Count = 1
              and then Snapshot.Pruned_Pending_Close_Count = 1
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, B)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S, C),
              "Phase 302 apply after edited preview prunes only active preview targets and leaves removed dirty target pending");
   end Test_Phase302_Dirty_Prune_Preview_Removal_Does_Not_Prune_Pending_Close;


   procedure Test_Phase302_Apply_Target_Removal_Does_Not_Edit_Preview_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      A, B, C, D : Editor.Buffers.Buffer_Id;
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Applicable : Natural := 0;
      Removed : Boolean := False;
      Restored : Boolean := False;
      Target : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Name : Unbounded_String := Null_Unbounded_String;
      Remaining : Natural := 0;
      Applied : Natural := 0;
      Skipped : Natural := 0;
      Snapshot : Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot;
      pragma Unreferenced (Name);
   begin
      Build_Phase302_Registry (Registry, A, B, C, D);
      Editor.Buffer_Switcher.Open (S);
      Make_Dirty (Registry, B);
      Make_Dirty (Registry, C);
      Make_Dirty (Registry, D);
      Editor.Buffer_Switcher.Set_Mark (S, A);
      Editor.Buffer_Switcher.Set_Mark (S, B);
      Editor.Buffer_Switcher.Set_Mark (S, C);
      Editor.Buffer_Switcher.Set_Mark (S, D);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Count, Applicable);

      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Apply_Target
        (S, Registry, B, Removed, Remaining);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Removed
              and then Snapshot.Dirty_Prune_Apply_Count = 2
              and then Snapshot.Removed_Dirty_Prune_Apply_Count = 1
              and then Snapshot.Dirty_Prune_Preview_Count = 3
              and then Snapshot.Pending_Close_Count = 4
              and then Editor.Buffer_Switcher.Is_Dirty_Pending_Marked_Close_Prune_Target (S, B),
              "Phase 302 apply target removal edits only apply confirmation state, not preview or pending state");

      Editor.Buffer_Switcher.Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target
        (S, Registry, Restored, Target, Name, Remaining);
      Assert (Restored and then Target = B and then Remaining = 3,
              "Phase 302 restore-last-removed apply target returns the target to apply confirmation");

      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Apply_Target
        (S, Registry, B, Removed, Remaining);
      Editor.Buffer_Switcher.Confirm_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Applied, Skipped, Remaining);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Applied = 2
              and then Snapshot.Pending_Close_Count = 2
              and then Snapshot.Pruned_Pending_Close_Count = 2
              and then Snapshot.Dirty_Prune_Apply_Count = 0
              and then Snapshot.Dirty_Prune_Preview_Count = 0
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, B)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S, C)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S, D),
              "Phase 302 apply confirm prunes only active apply targets and consumes preview/apply state");
   end Test_Phase302_Apply_Target_Removal_Does_Not_Edit_Preview_Targets;


   procedure Test_Phase302_Stale_Dirty_Prune_Targets_Are_Cleaned_And_Revalidated
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      A, B, C, D : Editor.Buffers.Buffer_Id;
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Applicable : Natural := 0;
      Cleared : Natural := 0;
      Remaining : Natural := 0;
      Applied : Natural := 0;
      Skipped : Natural := 0;
      Snapshot : Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot;
      pragma Unreferenced (D);
   begin
      Build_Phase302_Registry (Registry, A, B, C, D);
      Editor.Buffer_Switcher.Open (S);
      Make_Dirty (Registry, B);
      Make_Dirty (Registry, C);
      Editor.Buffer_Switcher.Set_Mark (S, A);
      Editor.Buffer_Switcher.Set_Mark (S, B);
      Editor.Buffer_Switcher.Set_Mark (S, C);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);

      Make_Clean (Registry, B);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Snapshot.Dirty_Prune_Preview_Count = 2
              and then Snapshot.Applicable_Dirty_Prune_Preview_Count = 1
              and then Snapshot.Stale_Dirty_Prune_Preview_Count = 1,
              "Phase 302 saving a preview target makes it stale without mutating the preview set");
      Editor.Buffer_Switcher.Clear_Stale_Dirty_Pending_Marked_Close_Prune_Targets
        (S, Registry, Cleared, Remaining);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Cleared = 1
              and then Remaining = 1
              and then Snapshot.Dirty_Prune_Preview_Count = 1
              and then Snapshot.Applicable_Dirty_Prune_Preview_Count = 1
              and then Snapshot.Pruned_Pending_Close_Count = 0
              and then Snapshot.Removed_Dirty_Prune_Preview_Count = 0,
              "Phase 302 stale preview cleanup is targeted and non-recording");

      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Count, Applicable);
      Make_Clean (Registry, C);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Snapshot.Dirty_Prune_Apply_Count = 1
              and then Snapshot.Applicable_Dirty_Prune_Apply_Count = 0
              and then Snapshot.Stale_Dirty_Prune_Apply_Count = 1,
              "Phase 302 saving an apply target makes it stale before confirm");
      Editor.Buffer_Switcher.Confirm_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Applied, Skipped, Remaining);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Applied = 0
              and then Skipped = 1
              and then Snapshot.Pruned_Pending_Close_Count = 0
              and then Snapshot.Pending_Close_Count = 3
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, B)
              and then Editor.Buffer_Switcher.Is_Pending_Marked_Close_Target (S, C),
              "Phase 302 apply confirm revalidates and skips stale apply targets without pruning them");
   end Test_Phase302_Stale_Dirty_Prune_Targets_Are_Cleaned_And_Revalidated;


   procedure Test_Phase302_Hidden_Dirty_Targets_Are_Included_In_Global_Dirty_Prune
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      A, B, C, D : Editor.Buffers.Buffer_Id;
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Applicable : Natural := 0;
      Applied : Natural := 0;
      Skipped : Natural := 0;
      Remaining : Natural := 0;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Snapshot : Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot;
      pragma Unreferenced (D);
   begin
      Build_Phase302_Registry (Registry, A, B, C, D);
      Editor.Buffer_Switcher.Open (S);
      Make_Dirty (Registry, B);
      Make_Dirty (Registry, C);
      Editor.Buffers.Set_Buffer_Label (Registry, B, "test");
      Editor.Buffer_Switcher.Set_Mark (S, A);
      Editor.Buffer_Switcher.Set_Mark (S, B);
      Editor.Buffer_Switcher.Set_Mark (S, C);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Set_Label_Filter (S, "test");
      Editor.Buffer_Switcher.Set_Filter_Text (S, "B");
      Editor.Buffer_Switcher.Set_Sort_Mode (S, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1
              and then Editor.Buffer_Switcher.Row_At (S, 1).Id = B,
              "Phase 302 filter/query/sort hides unmatched pending targets from rows");

      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Count, Applicable);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Snapshot.Dirty_Prune_Preview_Count = 2
              and then Snapshot.Applicable_Dirty_Prune_Preview_Count = 2
              and then Snapshot.Dirty_Prune_Apply_Count = 2
              and then Snapshot.Applicable_Dirty_Prune_Apply_Count = 2,
              "Phase 302 dirty-prune target membership and counts are global, not visible-row local");

      Editor.Buffer_Switcher.Confirm_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Applied, Skipped, Remaining);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Applied = 2
              and then Snapshot.Pending_Close_Count = 1
              and then Snapshot.Pruned_Pending_Close_Count = 2
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S, B)
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S, C),
              "Phase 302 dirty-prune apply includes hidden applicable targets");
   end Test_Phase302_Hidden_Dirty_Targets_Are_Included_In_Global_Dirty_Prune;


   procedure Test_Phase302_Review_Mode_Switching_Does_Not_Change_Batch_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      A, B, C, D : Editor.Buffers.Buffer_Id;
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Applicable : Natural := 0;
      Removed : Boolean := False;
      Remaining : Natural := 0;
      Before : Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot;
      After : Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      pragma Unreferenced (D);
   begin
      Build_Phase302_Registry (Registry, A, B, C, D);
      Editor.Buffer_Switcher.Open (S);
      Make_Dirty (Registry, B);
      Make_Dirty (Registry, C);
      Editor.Buffer_Switcher.Set_Mark (S, A);
      Editor.Buffer_Switcher.Set_Mark (S, B);
      Editor.Buffer_Switcher.Set_Mark (S, C);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, C, Removed, Remaining);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Count, Applicable);
      Before := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);

      Editor.Buffer_Switcher.Show_Marked_Review (S);
      Assert (Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry).Active_Review_Mode =
              Editor.Buffer_Switcher.Marked_Review,
              "Phase 302 marked review becomes the active review mode");
      Editor.Buffer_Switcher.Show_Pending_Marked_Review (S);
      Assert (Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry).Active_Review_Mode =
              Editor.Buffer_Switcher.Pending_Marked_Close_Review,
              "Phase 302 pending review replaces marked review");
      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S);
      Assert (Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry).Active_Review_Mode =
              Editor.Buffer_Switcher.Dirty_Prune_Preview_Review,
              "Phase 302 dirty-prune preview review replaces pending review");
      Editor.Buffer_Switcher.Show_Removed_Dirty_Prune_Review (S);
      Assert (Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry).Active_Review_Mode =
              Editor.Buffer_Switcher.Removed_Dirty_Prune_Preview_Review,
              "Phase 302 removed preview review replaces dirty-prune preview review");
      Editor.Buffer_Switcher.Show_Dirty_Prune_Apply_Review (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      After := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (After.Active_Review_Mode = Editor.Buffer_Switcher.Dirty_Prune_Apply_Review
              and then To_String (After.Review_Display_Name) = "dirty-prune apply"
              and then After.Marked_Count = Before.Marked_Count
              and then After.Pending_Close_Count = Before.Pending_Close_Count
              and then After.Dirty_Prune_Preview_Count = Before.Dirty_Prune_Preview_Count
              and then After.Removed_Dirty_Prune_Preview_Count = Before.Removed_Dirty_Prune_Preview_Count
              and then After.Dirty_Prune_Apply_Count = Before.Dirty_Prune_Apply_Count,
              "Phase 302 review switching changes only the active review discriminator and display label");
      Editor.Buffer_Switcher.Hide_Dirty_Prune_Apply_Review (S);
      After := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (After.Active_Review_Mode = Editor.Buffer_Switcher.No_Review
              and then After.Pending_Close_Count = Before.Pending_Close_Count
              and then After.Dirty_Prune_Apply_Count = Before.Dirty_Prune_Apply_Count,
              "Phase 302 hiding active review returns to ordinary projection without mutating batch state");
   end Test_Phase302_Review_Mode_Switching_Does_Not_Change_Batch_State;


   procedure Test_Phase302_Selected_Close_During_Dirty_Prune_Revalidates_Apply_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      A, B, C, D : Editor.Buffers.Buffer_Id;
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Applicable : Natural := 0;
      Applied : Natural := 0;
      Skipped : Natural := 0;
      Remaining : Natural := 0;
      Closed : Boolean := False;
      Snapshot : Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot;
      pragma Unreferenced (D);
   begin
      Build_Phase302_Registry (Registry, A, B, C, D);
      Editor.Buffer_Switcher.Open (S);
      Make_Dirty (Registry, B);
      Make_Dirty (Registry, C);
      Editor.Buffer_Switcher.Set_Mark (S, A);
      Editor.Buffer_Switcher.Set_Mark (S, B);
      Editor.Buffer_Switcher.Set_Mark (S, C);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Count, Applicable);

      Editor.Buffers.Close_Buffer (Registry, B, Closed, Force => False);
      Assert (not Closed
              and then Editor.Buffers.Contains (Registry, B)
              and then True,
              "Phase 302 selected close during dirty-prune workflow obeys existing dirty close policy");

      Editor.Buffer_Switcher.Confirm_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Applied, Skipped, Remaining);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Applied = 2
              and then Skipped = 0
              and then Snapshot.Pending_Close_Count = 1
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S, B)
              and then Editor.Buffers.Contains (Registry, B)
              and then Editor.Buffers.Is_Dirty (Registry, B)
              and then True,
              "Phase 302 dirty-prune apply revalidates dirty open targets but still does not close them or create reopen entries");
   end Test_Phase302_Selected_Close_During_Dirty_Prune_Revalidates_Apply_Targets;


   procedure Test_Phase302_Marks_Are_Independent_From_Captured_Pending_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      A, B, C, D : Editor.Buffers.Buffer_Id;
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Applicable : Natural := 0;
      Applied : Natural := 0;
      Skipped : Natural := 0;
      Remaining : Natural := 0;
      Closed_Count : Natural := 0;
      Snapshot : Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot;
      pragma Unreferenced (C, D);
   begin
      Build_Phase302_Registry (Registry, A, B, C, D);
      Editor.Buffer_Switcher.Open (S);
      Make_Dirty (Registry, B);
      Editor.Buffer_Switcher.Set_Mark (S, A);
      Editor.Buffer_Switcher.Set_Mark (S, B);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Editor.Buffer_Switcher.Clear_All_Marks (S);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Snapshot.Marked_Count = 0
              and then Snapshot.Pending_Close_Count = 2
              and then Snapshot.Dirty_Pending_Close_Count = 1,
              "Phase 302 clearing marks after capture does not clear pending close targets");

      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Count, Applicable);
      Editor.Buffer_Switcher.Confirm_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Applied, Skipped, Remaining);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Applied = 1
              and then Snapshot.Marked_Count = 0
              and then Snapshot.Pending_Close_Count = 1
              and then Snapshot.Pruned_Pending_Close_Count = 1
              and then Editor.Buffer_Switcher.Is_Pruned_Pending_Marked_Close_Target (S, B),
              "Phase 302 dirty-prune preview derives from active pending dirty targets, not current marks");

      Confirm_Pending_Marked_Close_For_Test (S, Registry, Closed_Count);
      Assert (Closed_Count = 1
              and then not Editor.Buffers.Contains (Registry, A)
              and then Editor.Buffers.Contains (Registry, B)
              and then Editor.Buffers.Is_Dirty (Registry, B),
              "Phase 302 final close after mark clearing closes only the captured clean target left active pending");
   end Test_Phase302_Marks_Are_Independent_From_Captured_Pending_Close;


   procedure Test_Phase302_Snapshot_Consistency_Across_Representative_Workflow
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      A, B, C, D : Editor.Buffers.Buffer_Id;
      Count : Natural := 0;
      Dirty_Count : Natural := 0;
      Applicable : Natural := 0;
      Removed : Boolean := False;
      Restored : Boolean := False;
      Target : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Name : Unbounded_String := Null_Unbounded_String;
      Remaining : Natural := 0;
      Applied : Natural := 0;
      Skipped : Natural := 0;
      Snapshot : Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot;
      pragma Unreferenced (Name, Target);
   begin
      Build_Phase302_Registry (Registry, A, B, C, D);
      Editor.Buffer_Switcher.Open (S);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (To_String (Snapshot.Header_Badge_Text) = "",
              "Phase 302 snapshot is empty before workflow state exists");

      Make_Dirty (Registry, B);
      Make_Dirty (Registry, C);
      Make_Dirty (Registry, D);
      Editor.Buffer_Switcher.Set_Mark (S, A);
      Editor.Buffer_Switcher.Set_Mark (S, B);
      Editor.Buffer_Switcher.Set_Mark (S, C);
      Editor.Buffer_Switcher.Set_Mark (S, D);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Snapshot.Marked_Count = 4
              and then To_String (Snapshot.Header_Badge_Text) = "Marked: 4",
              "Phase 302 snapshot reflects mark state before pending close capture");

      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close (S, Registry, Count, Dirty_Count);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Snapshot.Pending_Close_Count = 4
              and then Snapshot.Dirty_Pending_Close_Count = 3
              and then To_String (Snapshot.Footer_Badge_Text) = "Marked: 4 | Pending close: 4 | Dirty: 3",
              "Phase 302 snapshot reflects pending close and dirty pending counts");

      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune (S, Registry, Count);
      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, B, Removed, Remaining);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Snapshot.Dirty_Prune_Preview_Count = 2
              and then Snapshot.Removed_Dirty_Prune_Preview_Count = 1
              and then To_String (Snapshot.Footer_Badge_Text) =
                "Marked: 4 | Pending close: 4 | Dirty: 3 | Dirty prune: 2 | Applicable: 2 | Removed: 1",
              "Phase 302 snapshot reflects dirty-prune preview removal through the centralized badge text");

      Editor.Buffer_Switcher.Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Target
        (S, Registry, Restored, Target, Name, Remaining);
      Make_Clean (Registry, B);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Restored
              and then Snapshot.Dirty_Prune_Preview_Count = 3
              and then Snapshot.Applicable_Dirty_Prune_Preview_Count = 2
              and then Snapshot.Stale_Dirty_Prune_Preview_Count = 1,
              "Phase 302 snapshot derives applicable and stale preview counts side-effect-free");

      Editor.Buffer_Switcher.Clear_Stale_Dirty_Pending_Marked_Close_Prune_Targets
        (S, Registry, Count, Remaining);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Count, Applicable);
      Editor.Buffer_Switcher.Remove_Dirty_Pending_Marked_Close_Prune_Apply_Target
        (S, Registry, C, Removed, Remaining);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Snapshot.Dirty_Prune_Apply_Count = 1
              and then Snapshot.Removed_Dirty_Prune_Apply_Count = 1
              and then Snapshot.Dirty_Prune_Preview_Count = 2,
              "Phase 302 snapshot reflects apply target removal independently from preview state");

      Editor.Buffer_Switcher.Restore_Last_Removed_Dirty_Pending_Marked_Close_Prune_Apply_Target
        (S, Registry, Restored, Target, Name, Remaining);
      Editor.Buffer_Switcher.Confirm_Dirty_Pending_Marked_Close_Prune_Apply
        (S, Registry, Applied, Skipped, Remaining);
      Snapshot := Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot (S, Registry);
      Assert (Applied = 2
              and then Snapshot.Pending_Close_Count = 2
              and then Snapshot.Pruned_Pending_Close_Count = 2
              and then Snapshot.Dirty_Prune_Preview_Count = 0
              and then Snapshot.Dirty_Prune_Apply_Count = 0
              and then To_String (Snapshot.Footer_Badge_Text) = "Marked: 4 | Pending close: 2 | Pruned: 2",
              "Phase 302 snapshot remains the authoritative display source after dirty-prune apply confirmation");
   end Test_Phase302_Snapshot_Consistency_Across_Representative_Workflow;



   procedure Test_Phase304_Contextual_Hints_Are_Known_Available_And_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Alpha, Beta : Editor.Buffers.Buffer_Id;
      Before_Selected : Natural;
      Before_Rows     : Natural;
      Hints : Editor.Buffer_Switcher_Contextual_Hints.Switcher_Contextual_Hint_Vectors.Vector;
      pragma Unreferenced (Beta);
   begin
      Setup_Global_Switcher_State (S, Alpha, Beta);
      Before_Selected := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Before_Rows := Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher);

      Hints := Editor.Buffer_Switcher_Contextual_Hints.Build_Switcher_Contextual_Hints (S);

      Assert (Natural (Hints.Length) <= Editor.Buffer_Switcher_Contextual_Hints.Default_Max_Hints,
              "Phase 304: contextual hints must stay bounded");
      Assert (Natural (Hints.Length) > 0,
              "Phase 304: ordinary switcher state should expose practical hints");

      for Hint of Hints loop
         Assert (Editor.Commands.Has_Descriptor (Hint.Command_Id),
                 "Phase 304: every hint command id must resolve to a descriptor");
         Assert (Editor.Commands.Has_Availability_Handler (Hint.Command_Id),
                 "Phase 304: every hint command id must be covered by executor availability");
         Assert (Editor.Commands.Is_Available
                   (Editor.Executor.Command_Availability (S, Hint.Command_Id)),
                 "Phase 304: displayed hint must be executor-available");
         Assert (Hint.Is_Enabled,
                 "Phase 304: default policy exposes enabled hints only");
      end loop;

      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher) = Before_Selected,
              "Phase 304: hint derivation must not alter selected row");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = Before_Rows,
              "Phase 304: hint derivation must not alter row projection");
      Assert (Editor.Buffer_Switcher.Filter_Text (S.Buffer_Switcher) = "",
              "Phase 304: hint derivation must not alter query text");
      Assert (Editor.Buffer_Switcher.Marked_Count (S.Buffer_Switcher) = 0,
              "Phase 304: hint derivation must not mutate marks");
      Assert (Alpha /= Editor.Buffers.No_Buffer,
              "Phase 304 setup keeps a concrete selected buffer");
   end Test_Phase304_Contextual_Hints_Are_Known_Available_And_Side_Effect_Free;

   procedure Test_Phase304_Selected_Mark_And_Pending_Close_Hints_Are_State_Based
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.Commands;
      S : Editor.State.State_Type;
      Alpha, Beta : Editor.Buffers.Buffer_Id;
      Count, Dirty_Count : Natural := 0;
      Hints : Editor.Buffer_Switcher_Contextual_Hints.Switcher_Contextual_Hint_Vectors.Vector;
      pragma Unreferenced (Beta, Dirty_Count);
   begin
      Setup_Global_Switcher_State (S, Alpha, Beta);

      Hints := Editor.Buffer_Switcher_Contextual_Hints.Build_Switcher_Contextual_Hints (S);
      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Mark_Set),
              "Phase 304: selected unmarked row should expose mark-selected hint");
      Assert (not Contains_Hint (Hints, Command_Buffer_Switcher_Mark_Clear),
              "Phase 304: selected unmarked row must not expose unmark-selected hint");

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, Alpha);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Hints := Editor.Buffer_Switcher_Contextual_Hints.Build_Switcher_Contextual_Hints (S);
      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Mark_Clear),
              "Phase 304: selected marked row should expose unmark-selected hint");
      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Mark_Close_Marked),
              "Phase 304: marked state should expose marked-close preparation hint");

      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Count, Dirty_Count);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Hints := Editor.Buffer_Switcher_Contextual_Hints.Build_Switcher_Contextual_Hints (S);

      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Mark_Confirm),
              "Phase 304: pending close should expose confirm hint");
      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Mark_Cancel),
              "Phase 304: pending close should expose cancel hint");
      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Review_Show),
              "Phase 304: pending close should expose review hint");
      Assert (not Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected),
              "Phase 304: clean pending target must not expose dirty-pending removal hint");
   end Test_Phase304_Selected_Mark_And_Pending_Close_Hints_Are_State_Based;

   procedure Test_Phase304_Hint_Keybinding_Text_Follows_Runtime_Display_Setting
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.Commands;
      S : Editor.State.State_Type;
      Alpha, Beta : Editor.Buffers.Buffer_Id;
      Chord : constant Editor.Keybindings.Key_Chord :=
        (Key       => Editor.Keybindings.Key_M,
         Modifiers => (Ctrl => True, Shift => False, Alt => False, Meta => False));
      Hints : Editor.Buffer_Switcher_Contextual_Hints.Switcher_Contextual_Hint_Vectors.Vector;
      pragma Unreferenced (Alpha, Beta);
   begin
      Setup_Global_Switcher_State (S, Alpha, Beta);
      Editor.Keybindings.Clear;
      Editor.Keybindings.Bind (Chord, Command_Buffer_Switcher_Mark_Set);
      Editor.Settings.Set_Command_Palette_Show_Keybindings (S.Settings, True);

      Hints := Editor.Buffer_Switcher_Contextual_Hints.Build_Switcher_Contextual_Hints (S);
      Assert (Hint_Key_Text (Hints, Command_Buffer_Switcher_Mark_Set) = "Ctrl+M",
              "Phase 304: hint keybinding text must follow active runtime bindings");

      Editor.Settings.Set_Command_Palette_Show_Keybindings (S.Settings, False);
      Hints := Editor.Buffer_Switcher_Contextual_Hints.Build_Switcher_Contextual_Hints (S);
      Assert (Hint_Key_Text (Hints, Command_Buffer_Switcher_Mark_Set) = "",
              "Phase 304: hint keybinding text must be hidden when display is disabled");

      Editor.Keybindings.Unbind (Chord);
      Editor.Settings.Set_Command_Palette_Show_Keybindings (S.Settings, True);
      Hints := Editor.Buffer_Switcher_Contextual_Hints.Build_Switcher_Contextual_Hints (S);
      Assert (Hint_Key_Text (Hints, Command_Buffer_Switcher_Mark_Set) = "",
              "Phase 304: hint keybinding text must disappear after runtime unbind");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Phase304_Hint_Keybinding_Text_Follows_Runtime_Display_Setting;


   procedure Test_Phase304_Dirty_Prune_Preview_And_Apply_Hints_Are_Prioritized
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.Commands;
      S : Editor.State.State_Type;
      Alpha, Beta : Editor.Buffers.Buffer_Id;
      Count, Dirty_Count, Applicable : Natural := 0;
      Hints : Editor.Buffer_Switcher_Contextual_Hints.Switcher_Contextual_Hint_Vectors.Vector;
   begin
      Setup_Global_Switcher_State (S, Alpha, Beta);
      Mark_Global_Buffer_Dirty (S, Alpha);
      Mark_Global_Buffer_Dirty (S, Beta);
      Editor.Buffers.Global_Set_Active_Buffer (Alpha);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));

      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, Beta);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Count, Dirty_Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Count);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, Alpha, 1);

      Hints := Editor.Buffer_Switcher_Contextual_Hints.Build_Switcher_Contextual_Hints (S);
      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply),
              "Phase 304: dirty-prune preview should expose apply preparation hint");
      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel),
              "Phase 304: dirty-prune preview should expose cancel hint");
      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected),
              "Phase 304: selected active preview target should expose remove-preview hint");
      Assert (not Contains_Hint (Hints, Command_Buffer_Switcher_Mark_Confirm),
              "Phase 304: preview workflow hints should outrank pending-close confirmation hints");

      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune_Apply
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Count, Applicable);
      Hints := Editor.Buffer_Switcher_Contextual_Hints.Build_Switcher_Contextual_Hints (S);
      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm),
              "Phase 304: apply confirmation should expose confirm-apply hint");
      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel),
              "Phase 304: apply confirmation should expose cancel-apply hint");
      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show),
              "Phase 304: apply confirmation should expose review-apply hint");
      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected),
              "Phase 304: selected captured apply target should expose remove-apply hint");
      Assert (not Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply),
              "Phase 304: apply confirmation hints must outrank preview apply-preparation hint");
   end Test_Phase304_Dirty_Prune_Preview_And_Apply_Hints_Are_Prioritized;

   procedure Test_Phase304_Review_Mode_Hints_And_Filtered_Selected_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.Commands;
      S : Editor.State.State_Type;
      Alpha, Beta : Editor.Buffers.Buffer_Id;
      Count, Dirty_Count : Natural := 0;
      Hints : Editor.Buffer_Switcher_Contextual_Hints.Switcher_Contextual_Hint_Vectors.Vector;
      Before_Targets : Natural := 0;
   begin
      Setup_Global_Switcher_State (S, Alpha, Beta);
      Mark_Global_Buffer_Dirty (S, Alpha);
      Mark_Global_Buffer_Dirty (S, Beta);
      Editor.Buffers.Global_Set_Active_Buffer (Alpha);
      Editor.Buffers.Load_Global_Active_Into_State (S);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, Beta);
      Editor.Buffer_Switcher.Prepare_Pending_Marked_Close
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Count, Dirty_Count);
      Editor.Buffer_Switcher.Prepare_Dirty_Pending_Marked_Close_Prune
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Count);
      Before_Targets := Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count
        (S.Buffer_Switcher);

      Editor.Buffer_Switcher.Show_Dirty_Prune_Review (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Hints := Editor.Buffer_Switcher_Contextual_Hints.Build_Switcher_Contextual_Hints (S);
      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide),
              "Phase 304: dirty-prune review mode should expose its own hide-review hint");
      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next)
              or else Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous),
              "Phase 304: dirty-prune review mode should expose relevant review navigation");
      Assert (not Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Review_Hide),
              "Phase 304: active dirty-prune review hints must not imply pending-close review");
      Assert (Editor.Buffer_Switcher.Dirty_Pending_Marked_Close_Prune_Target_Count
                (S.Buffer_Switcher) = Before_Targets,
              "Phase 304: review hint derivation must not mutate reviewed target set");

      Editor.Buffer_Switcher.Set_Filter_Text (S.Buffer_Switcher, "no-visible-target");
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, (others => <>));
      Hints := Editor.Buffer_Switcher_Contextual_Hints.Build_Switcher_Contextual_Hints (S);
      Assert (not Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected),
              "Phase 304: selected-target correction hint must disappear when candidates are hidden by query");
      Assert (Contains_Hint (Hints, Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply),
              "Phase 304: global dirty-prune workflow hints remain while filter hides candidates");
   end Test_Phase304_Review_Mode_Hints_And_Filtered_Selected_Targets;

   procedure Test_Phase304_Hint_Text_Formatting_Is_Deterministic_And_Deduplicated
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Alpha, Beta : Editor.Buffers.Buffer_Id;
      Hints : Editor.Buffer_Switcher_Contextual_Hints.Switcher_Contextual_Hint_Vectors.Vector;
      Text  : Unbounded_String;
   begin
      Setup_Global_Switcher_State (S, Alpha, Beta);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, Alpha);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, Beta);
      Hints := Editor.Buffer_Switcher_Contextual_Hints.Build_Switcher_Contextual_Hints (S);
      Text := To_Unbounded_String (Formatted_Hints (Hints));

      Assert (To_String (Text) = Editor.Buffer_Switcher_Contextual_Hints.Contextual_Hint_Text (S),
              "Phase 304: rendered hint text must be the formatted structured snapshot hints");
      Assert (Natural (Hints.Length) <= Editor.Buffer_Switcher_Contextual_Hints.Default_Max_Hints,
              "Phase 304: formatted hint line is derived from the bounded hint list");
      if Natural (Hints.Length) > 1 then
         for I in Hints.First_Index .. Hints.Last_Index loop
            for J in Hints.First_Index .. Hints.Last_Index loop
               if I < J then
                  Assert (To_String (Hints.Element (I).Label) /= To_String (Hints.Element (J).Label),
                          "Phase 304: one hint line must not repeat duplicate hint labels");
               end if;
            end loop;
         end loop;
      end if;
   end Test_Phase304_Hint_Text_Formatting_Is_Deterministic_And_Deduplicated;



   procedure Test_Phase478_Observes_File_Lifecycle_Association_And_Dirty_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Row : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      pragma Unreferenced (Beta, Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);
      Editor.Buffer_Switcher.Open (S);

      --  Save observes canonical dirty-state cleanup without changing association.
      Set_Buffer_Dirty_For_Test (Registry, Alpha, True);
      Recompute_For_Test (S, Registry);
      Row := Row_For (S, Alpha);
      Assert (Row.Is_Dirty, "Phase 478: switcher must observe dirty buffer state");
      Assert (Row.Has_Path, "Phase 478: switcher must observe associated source path");
      Assert (To_String (Row.Display_Label) = "main.adb",
              "Phase 478: save precondition label should be current buffer association label");

      Set_Buffer_Dirty_For_Test (Registry, Alpha, False);
      Recompute_For_Test (S, Registry);
      Row := Row_For (S, Alpha);
      Assert (not Row.Is_Dirty, "Phase 478: successful save cleanup is observed as clean");
      Assert (To_String (Row.Display_Label) = "main.adb",
              "Phase 478: save must not invent a new switcher path label");

      --  Save As / rename / move all update association through buffer state only.
      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/saved_as.adb", "saved_as.adb");
      Recompute_For_Test (S, Registry);
      Row := Row_For (S, Alpha);
      Assert (Row.Has_Path, "Phase 478: save-as association remains path-backed");
      Assert (not Row.Is_Dirty, "Phase 478: save-as clean state is observed");
      Assert (To_String (Row.Display_Label) = "saved_as.adb",
              "Phase 478: save-as association update is observed through buffer label");

      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/renamed.adb", "renamed.adb");
      Recompute_For_Test (S, Registry);
      Row := Row_For (S, Alpha);
      Assert (To_String (Row.Display_Label) = "renamed.adb",
              "Phase 478: rename association update is observed through buffer label");
      Assert (not Row.Is_Dirty, "Phase 478: rename does not create switcher dirty state");

      declare
         Before_Label : constant String := To_String (Row.Display_Label);
      begin
         --  Copy preserves association and must not add an opened copied-target row.
         Recompute_For_Test (S, Registry);
         Assert (Editor.Buffer_Switcher.Row_Count (S) = 3,
                 "Phase 478: copy must not add a copied target row");
         Row := Row_For (S, Alpha);
         Assert (To_String (Row.Display_Label) = Before_Label,
                 "Phase 478: copy preserves the observed source association label");
      end;

      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/moved.adb", "moved.adb");
      Recompute_For_Test (S, Registry);
      Row := Row_For (S, Alpha);
      Assert (To_String (Row.Display_Label) = "moved.adb",
              "Phase 478: move association update is observed through buffer label");
      Assert (not Row.Is_Dirty, "Phase 478: move does not create switcher dirty state");

      Clear_Buffer_Association_For_Test (Registry, Alpha);
      Recompute_For_Test (S, Registry);
      Row := Row_For (S, Alpha);
      Assert (not Row.Has_Path, "Phase 478: delete association clear is observed");
      Assert (To_String (Row.Display_Label)'Length > 0,
              "Phase 478: delete no-associated-file state uses canonical buffer label only");
   end Test_Phase478_Observes_File_Lifecycle_Association_And_Dirty_State;

   procedure Test_Phase478_Observes_Close_And_Reopen_Collection_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled, Reopened : Editor.Buffers.Buffer_Id;
      Closed : Boolean := False;
      pragma Unreferenced (Beta, Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Recompute_For_Test (S, Registry);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 3,
              "Phase 478: switcher starts from canonical open-buffer collection");

      Editor.Buffers.Close_Buffer (Registry, Alpha, Closed, Force => True);
      Assert (Closed, "Phase 478 test setup should close alpha through canonical close helper");
      Recompute_For_Test (S, Registry);
      Assert (Row_Index_For (S, Alpha) = 0,
              "Phase 478: closed buffer is no longer projected by the switcher");
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 2,
              "Phase 478: close observation only removes collection membership");

      Reopened := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/project/src/reopened.adb", "reopened.adb", "procedure Reopened is begin null; end;");
      Editor.Buffers.Set_Active_Buffer (Registry, Reopened);
      Recompute_For_Test (S, Registry);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 3,
              "Phase 478: reopen/open adds a row only through canonical open-buffer collection");
      Assert (Row_For (S, Reopened).Is_Active,
              "Phase 478: reopened buffer active state is observed from buffer registry");
      Assert (To_String (Row_For (S, Reopened).Display_Label) = "reopened.adb",
              "Phase 478: reopened row label is current buffer association label");
   end Test_Phase478_Observes_Close_And_Reopen_Collection_Only;

   procedure Test_Phase478_Prompt_And_Selection_Boundary_Is_Observation_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      App : Editor.State.State_Type;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);
      Editor.Buffer_Switcher.Open (S);
      Recompute_For_Test (S, Registry);
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S) = 1,
              "Phase 478 setup: active buffer starts selected");

      Editor.Buffer_Switcher.Move_Selection_Down (S);
      Assert (Editor.Buffer_Switcher.Row_At
                (S, Editor.Buffer_Switcher.Selected_Row_Index (S)).Id = Beta,
              "Phase 478 setup: switcher selection can differ from active buffer");
      Assert (Editor.Buffers.Active_Buffer (Registry) = Alpha,
              "Phase 478: moving switcher selection must not change active buffer source");

      Editor.State.Init (App);
      App.File_Target_Prompt_Active := True;
      App.File_Target_Prompt_Command := Editor.Commands.Command_Save_File_As;
      App.File_Target_Prompt_Label := To_Unbounded_String ("Save As target");
      Editor.Input_Field.Insert_Text (App.File_Target_Prompt_Input, "/tmp/explicit-target.adb");

      Recompute_For_Test (S, Registry);
      Assert (App.File_Target_Prompt_Active,
              "Phase 478: recomputing switcher rows must not own or clear prompt state");
      Assert (Editor.Input_Field.Text (App.File_Target_Prompt_Input) = "/tmp/explicit-target.adb",
              "Phase 478: switcher selection must not become target prompt input");
      Assert (Editor.Buffers.Active_Buffer (Registry) = Alpha,
              "Phase 478: prompt-active switcher interaction preserves active-buffer source policy");
   end Test_Phase478_Prompt_And_Selection_Boundary_Is_Observation_Only;

   procedure Test_Phase478_Rows_Contain_No_File_Lifecycle_Operation_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Row : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      pragma Unreferenced (Beta, Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/current.adb", "current.adb");
      Set_Buffer_Dirty_For_Test (Registry, Alpha, True);
      Editor.Buffer_Switcher.Open (S);
      Recompute_For_Test (S, Registry);
      Row := Row_For (S, Alpha);

      Assert (Row.Id = Alpha,
              "Phase 478: row carries buffer identity from canonical snapshot");
      Assert (To_String (Row.Display_Label) = "current.adb",
              "Phase 478: row carries current display label only");
      Assert (Row.Is_Dirty,
              "Phase 478: row carries current dirty indicator only");
      Assert (Row.Has_Path,
              "Phase 478: row carries current path-backed flag only");
      Assert (not Row.Is_Pending_Close_Target
                and then not Row.Is_Ordinary_Pruned_Target
                and then not Row.Is_Dirty_Prune_Preview_Target
                and then not Row.Is_Removed_Dirty_Prune_Preview_Target
                and then not Row.Is_Dirty_Prune_Apply_Target
                and then not Row.Is_Removed_Dirty_Prune_Apply_Target,
              "Phase 478: ordinary lifecycle observation rows must not expose operation histories, prompt targets, or recovery state");
   end Test_Phase478_Rows_Contain_No_File_Lifecycle_Operation_State;


   procedure Assert_Phase479_Row_State
     (S            : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Id           : Editor.Buffers.Buffer_Id;
      Expected_Name : String;
      Expected_Path : Boolean;
      Expected_Dirty : Boolean;
      Message       : String)
   is
      Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row := Row_For (S, Id);
   begin
      Assert (To_String (Row.Display_Label) = Expected_Name,
              Message & ": path/display label must be canonical current buffer state");
      Assert (Row.Has_Path = Expected_Path,
              Message & ": path-backed flag must be canonical current association state");
      Assert (Row.Is_Dirty = Expected_Dirty,
              Message & ": dirty marker must be canonical current dirty state");
   end Assert_Phase479_Row_State;

   procedure Test_Phase479_Successful_Observation_Reliable_Visible_And_Hidden
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      Visible_S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Hidden_S  : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled, Reopened : Editor.Buffers.Buffer_Id;
      Closed : Boolean := False;
      pragma Unreferenced (Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);
      Editor.Buffer_Switcher.Open (Visible_S);

      --  file.save: dirty state is observed as clean, association label is unchanged.
      Set_Buffer_Dirty_For_Test (Registry, Alpha, True);
      Recompute_For_Test (Visible_S, Registry);
      Assert_Phase479_Row_State
        (Visible_S, Alpha, "main.adb", True, True,
         "Phase 479 visible save precondition");
      Set_Buffer_Dirty_For_Test (Registry, Alpha, False);
      Recompute_For_Test (Visible_S, Registry);
      Recompute_For_Test (Hidden_S, Registry);
      Assert_Phase479_Row_State
        (Visible_S, Alpha, "main.adb", True, False,
         "Phase 479 visible save observation");
      Assert_Phase479_Row_State
        (Hidden_S, Alpha, "main.adb", True, False,
         "Phase 479 hidden save observation");

      --  file.save-as / prompted file.save-as final state: same buffer identity, new association.
      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/phase479_saved_as.adb", "phase479_saved_as.adb");
      Set_Buffer_Dirty_For_Test (Registry, Alpha, False);
      Recompute_For_Test (Visible_S, Registry);
      Recompute_For_Test (Hidden_S, Registry);
      Assert (Row_For (Visible_S, Alpha).Id = Alpha,
              "Phase 479 save-as must preserve row buffer identity");
      Assert_Phase479_Row_State
        (Visible_S, Alpha, "phase479_saved_as.adb", True, False,
         "Phase 479 visible save-as observation");
      Assert_Phase479_Row_State
        (Hidden_S, Alpha, "phase479_saved_as.adb", True, False,
         "Phase 479 hidden save-as observation");

      --  file.rename-buffer-file: same row identity, new association, no reordering.
      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/phase479_renamed.adb", "phase479_renamed.adb");
      Recompute_For_Test (Visible_S, Registry);
      Assert (Editor.Buffer_Switcher.Row_At (Visible_S, 1).Id = Alpha
                and then Editor.Buffer_Switcher.Row_At (Visible_S, 2).Id = Beta,
              "Phase 479 rename must not reorder open-buffer projection");
      Assert_Phase479_Row_State
        (Visible_S, Alpha, "phase479_renamed.adb", True, False,
         "Phase 479 rename observation");

      --  file.copy-buffer-file: copied target does not become an open-buffer row or label.
      Recompute_For_Test (Visible_S, Registry);
      Assert (Editor.Buffer_Switcher.Row_Count (Visible_S) = 3,
              "Phase 479 copy must not synthesize copied target rows");
      Assert (Row_Index_For (Visible_S, Beta) /= 0,
              "Phase 479 copy preserves existing open-buffer membership");
      Assert_Phase479_Row_State
        (Visible_S, Alpha, "phase479_renamed.adb", True, False,
         "Phase 479 copy observation");

      --  file.move-buffer-file: same row identity, moved association, no duplicate target row.
      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/phase479_moved.adb", "phase479_moved.adb");
      Recompute_For_Test (Visible_S, Registry);
      Assert (Editor.Buffer_Switcher.Row_Count (Visible_S) = 3,
              "Phase 479 move must not synthesize moved target rows");
      Assert_Phase479_Row_State
        (Visible_S, Alpha, "phase479_moved.adb", True, False,
         "Phase 479 move observation");

      --  file.delete-buffer-file: association clear is observed, buffer remains open.
      Clear_Buffer_Association_For_Test (Registry, Alpha);
      Set_Buffer_Dirty_For_Test (Registry, Alpha, False);
      Recompute_For_Test (Visible_S, Registry);
      Assert (Row_Index_For (Visible_S, Alpha) /= 0,
              "Phase 479 delete association clear must not close the buffer");
      Assert_Phase479_Row_State
        (Visible_S, Alpha, "Untitled", False, False,
         "Phase 479 delete observation");

      --  file.close-buffer / file.reopen-closed-buffer: membership follows canonical collection only.
      Editor.Buffers.Close_Buffer (Registry, Alpha, Closed, Force => True);
      Assert (Closed, "Phase 479 setup must close active buffer through canonical helper");
      Recompute_For_Test (Visible_S, Registry);
      Assert (Row_Index_For (Visible_S, Alpha) = 0,
              "Phase 479 close removes only the closed buffer row");
      Assert (Editor.Buffer_Switcher.Row_Count (Visible_S) = 2,
              "Phase 479 close leaves other open-buffer rows intact");
      Reopened := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/project/src/phase479_reopened.adb", "phase479_reopened.adb", "procedure R is begin null; end;");
      Editor.Buffers.Set_Active_Buffer (Registry, Reopened);
      Recompute_For_Test (Visible_S, Registry);
      Assert (Row_Index_For (Visible_S, Reopened) /= 0,
              "Phase 479 reopen is observed only through canonical open-buffer collection");
      Assert (Row_For (Visible_S, Reopened).Is_Active,
              "Phase 479 active marker follows canonical active buffer after reopen");
   end Test_Phase479_Successful_Observation_Reliable_Visible_And_Hidden;

   procedure Test_Phase479_Failed_And_Blocked_Operations_Preserve_Observation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Before_Count : Natural;
      pragma Unreferenced (Beta, Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);
      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/phase479_source.adb", "phase479_source.adb");
      Set_Buffer_Dirty_For_Test (Registry, Alpha, True);
      Recompute_For_Test (S, Registry);
      Before_Count := Editor.Buffer_Switcher.Row_Count (S);

      --  Invalid/colliding/failing save-as, rename, copy, move, delete, close, reload, and revert
      --  are represented here by the required preservation property: no canonical buffer state changed.
      Recompute_For_Test (S, Registry);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = Before_Count,
              "Phase 479 failed/blocked operations must not change projected collection");
      Assert_Phase479_Row_State
        (S, Alpha, "phase479_source.adb", True, True,
         "Phase 479 failed/blocked lifecycle preservation");
      Assert (Row_Index_For (S, Alpha) /= 0,
              "Phase 479 failed close/delete must not remove the source row");
      Assert (Row_Index_For (S, Editor.Buffers.No_Buffer) = 0,
              "Phase 479 failed operations must not create error/recovery rows");

      --  A failed target must never become a row label or synthetic open-buffer member.
      for I in 1 .. Editor.Buffer_Switcher.Row_Count (S) loop
         Assert (To_String (Editor.Buffer_Switcher.Row_At (S, I).Display_Label) /= "failed_target.adb",
                 "Phase 479 failed target paths must never be displayed by switcher rows");
      end loop;
   end Test_Phase479_Failed_And_Blocked_Operations_Preserve_Observation;

   procedure Test_Phase479_Selection_And_Prompt_Boundaries_Are_Reliable
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      App : Editor.State.State_Type;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Set_Buffer_Association_For_Test
        (Registry, Beta, "/tmp/project/src/path_like_target_name.adb", "path_like_target_name.adb");
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);
      Editor.Buffer_Switcher.Open (S);
      Recompute_For_Test (S, Registry);
      Editor.Buffer_Switcher.Move_Selection_Down (S);
      Assert (Editor.Buffer_Switcher.Row_At
                (S, Editor.Buffer_Switcher.Selected_Row_Index (S)).Id = Beta,
              "Phase 479 setup: switcher selection differs from active buffer");
      Assert (Editor.Buffers.Active_Buffer (Registry) = Alpha,
              "Phase 479 switcher selection must not become file lifecycle source");

      Editor.State.Init (App);
      Editor.Executor.Open_File_Target_Prompt
        (App, Editor.Commands.Command_Rename_Buffer_File);
      Assert (Editor.Executor.File_Target_Prompt_Is_Active (App),
              "Phase 479 prompted command opens canonical prompt state outside switcher ownership");
      Assert (Editor.Executor.File_Target_Prompt_Input_Text (App) = "",
              "Phase 479 switcher row labels must not seed target prompt input");
      Editor.Buffer_Switcher.Move_Selection_Up (S);
      Assert (Editor.Executor.File_Target_Prompt_Input_Text (App) = "",
              "Phase 479 switcher interaction must not mutate prompt input");
      Editor.Executor.Insert_File_Target_Prompt_Text (App, "/tmp/explicit_phase479_target.adb");
      Editor.Buffer_Switcher.Move_Selection_Down (S);
      Assert (Editor.Executor.File_Target_Prompt_Input_Text (App) = "/tmp/explicit_phase479_target.adb",
              "Phase 479 explicit prompt text remains owned by canonical prompt input");
      Editor.Executor.Cancel_File_Target_Prompt (App);
      Assert (not Editor.Executor.File_Target_Prompt_Is_Active (App),
              "Phase 479 prompt cancellation remains canonical and non-switcher-owned");
      Assert (Editor.Buffers.Active_Buffer (Registry) = Alpha,
              "Phase 479 prompt cancellation and switcher movement preserve active-buffer source");
   end Test_Phase479_Selection_And_Prompt_Boundaries_Are_Reliable;

   procedure Test_Phase479_Snapshot_Freshness_And_Stale_Snapshot_Immutability
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      Stale_S, Fresh_S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Beta, Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (Stale_S);
      Editor.Buffer_Switcher.Open (Fresh_S);
      Recompute_For_Test (Stale_S, Registry);
      Assert_Phase479_Row_State
        (Stale_S, Alpha, "main.adb", True, False,
         "Phase 479 stale snapshot setup");

      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/fresh_after_rename.adb", "fresh_after_rename.adb");
      Set_Buffer_Dirty_For_Test (Registry, Alpha, True);

      --  A retained stale snapshot is inert data; render must not repair it by probing or patching.
      Assert_Phase479_Row_State
        (Stale_S, Alpha, "main.adb", True, False,
         "Phase 479 stale snapshot remains unmutated before rebuild");
      Recompute_For_Test (Fresh_S, Registry);
      Assert_Phase479_Row_State
        (Fresh_S, Alpha, "fresh_after_rename.adb", True, True,
         "Phase 479 fresh snapshot reflects current canonical buffer state");
      Assert (Row_Index_For (Fresh_S, Alpha) = Row_Index_For (Stale_S, Alpha),
              "Phase 479 path label changes must not create new row identity or reorder non-close operations");
   end Test_Phase479_Snapshot_Freshness_And_Stale_Snapshot_Immutability;

   procedure Test_Phase479_Rows_Exclude_Lifecycle_Target_Histories_And_Operation_Logs
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Row : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      pragma Unreferenced (Beta, Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/current_phase479.adb", "current_phase479.adb");
      Set_Buffer_Dirty_For_Test (Registry, Alpha, True);
      Recompute_For_Test (S, Registry);
      Row := Row_For (S, Alpha);

      Assert (Row.Id = Alpha,
              "Phase 479 row identity is canonical buffer identity only");
      Assert (To_String (Row.Display_Label) = "current_phase479.adb",
              "Phase 479 row label is current association label only");
      Assert (Row.Is_Dirty and then Row.Has_Path,
              "Phase 479 row state is current dirty/path snapshot only");
      Assert (not Row.Is_Pending_Close_Target
                and then not Row.Is_Ordinary_Pruned_Target
                and then not Row.Is_Dirty_Prune_Preview_Target
                and then not Row.Is_Removed_Dirty_Prune_Preview_Target
                and then not Row.Is_Dirty_Prune_Apply_Target
                and then not Row.Is_Removed_Dirty_Prune_Apply_Target,
              "Phase 479 ordinary rows expose no file lifecycle target history, prompt text, probe cache, repair cache, or operation log");
   end Test_Phase479_Rows_Exclude_Lifecycle_Target_Histories_And_Operation_Logs;


   procedure Test_Phase480_Row_Projection_Helper_Is_Canonical_Buffer_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Summary : Editor.Buffers.Buffer_Summary :=
        (Id           => 42,
         Display_Name => To_Unbounded_String ("phase480_current.adb"),
         Is_Dirty     => True,
         Is_Active    => True,
         Has_Path     => True,
         Path         => To_Unbounded_String ("/tmp/project/demo.adb"),
         Last_Save_Failed => True,
         Last_Reload_Failed => False,
         Last_Revert_Failed => False,
         Missing_Target_Surfaced => True,
         Unreadable_Target_Surfaced => False,
         Unwritable_Target_Surfaced => True,
         External_Change_Surfaced => False,
         Blocked_Close_Surfaced  => True,
         Is_Pinned               => True,
         Has_Group               => True,
         Group_Name              => To_Unbounded_String ("core"),
         Has_Label               => True,
         Label_Text              => To_Unbounded_String ("lifecycle"),
         Has_Note                => True,
         Note_Text               => To_Unbounded_String ("not projected as file lifecycle state"));
      Row : Editor.Buffer_Switcher.Buffer_Switcher_Row;
   begin
      Row := Editor.Buffer_Switcher.Build_Open_Buffer_Switcher_Row_From_Buffer_Snapshot (Summary);

      Assert (Row.Id = Summary.Id,
              "Phase 480: row identity derives from canonical buffer identity");
      Assert (To_String (Row.Display_Label) = To_String (Summary.Display_Name),
              "Phase 480: row path/display label derives from current buffer summary only");
      Assert (Row.Is_Dirty = Summary.Is_Dirty,
              "Phase 480: row dirty indicator derives from current buffer dirty state only");
      Assert (Row.Is_Active = Summary.Is_Active,
              "Phase 480: row active marker derives from current active-buffer summary only");
      Assert (Row.Has_Path = Summary.Has_Path,
              "Phase 480: row path marker derives from current buffer association only");
      Assert (Row.Last_Save_Failed = Summary.Last_Save_Failed
                and then Row.Last_Reload_Failed = Summary.Last_Reload_Failed
                and then Row.Last_Revert_Failed = Summary.Last_Revert_Failed
                and then Row.Missing_Target_Surfaced = Summary.Missing_Target_Surfaced
                and then Row.Unreadable_Target_Surfaced = Summary.Unreadable_Target_Surfaced
                and then Row.Unwritable_Target_Surfaced = Summary.Unwritable_Target_Surfaced
                and then Row.External_Change_Surfaced = Summary.External_Change_Surfaced
                and then Row.Blocked_Close_Surfaced = Summary.Blocked_Close_Surfaced,
              "Phase 573: file lifecycle recovery markers derive from current buffer summary only");
      Assert (Row.Is_Pinned and then Row.Has_Group and then Row.Has_Label and then Row.Has_Note,
              "Phase 480: non-file-lifecycle row metadata remains snapshot-derived");
      Assert (not Row.Is_Marked
                and then not Row.Is_Pending_Close_Target
                and then not Row.Is_Ordinary_Pruned_Target
                and then not Row.Is_Dirty_Prune_Preview_Target
                and then not Row.Is_Removed_Dirty_Prune_Preview_Target
                and then not Row.Is_Dirty_Prune_Apply_Target
                and then not Row.Is_Removed_Dirty_Prune_Apply_Target,
              "Phase 480: canonical row projection helper does not import switcher target/history state");

      Summary.Display_Name := To_Unbounded_String ("phase480_after_move.adb");
      Summary.Is_Dirty := False;
      Summary.Has_Path := True;
      Row := Editor.Buffer_Switcher.Build_Open_Buffer_Switcher_Row_From_Buffer_Snapshot (Summary);
      Assert (To_String (Row.Display_Label) = "phase480_after_move.adb"
                and then not Row.Is_Dirty
                and then Row.Has_Path,
              "Phase 480: fresh projection follows the supplied current snapshot, not old labels or dirty caches");
   end Test_Phase480_Row_Projection_Helper_Is_Canonical_Buffer_Snapshot;

   procedure Test_Phase480_Recompute_Drops_Stale_Label_And_Dirty_Caches
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Beta, Untitled);
      Row : Editor.Buffer_Switcher.Buffer_Switcher_Row;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);
      Editor.Buffer_Switcher.Open (S);
      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/phase480_old.adb", "phase480_old.adb");
      Set_Buffer_Dirty_For_Test (Registry, Alpha, True);
      Recompute_For_Test (S, Registry);
      Assert_Phase479_Row_State
        (S, Alpha, "phase480_old.adb", True, True,
         "Phase 480 setup: initial row reflects current association and dirty state");

      --  Leave the switcher state and stale row snapshot allocated, then change
      --  only canonical buffer state.  A fresh recompute must replace visible
      --  lifecycle observation fields from the registry snapshot; no row-local
      --  label/dirty cache may participate.
      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/phase480_new.adb", "phase480_new.adb");
      Set_Buffer_Dirty_For_Test (Registry, Alpha, False);
      Recompute_For_Test (S, Registry);
      Row := Row_For (S, Alpha);
      Assert (To_String (Row.Display_Label) = "phase480_new.adb",
              "Phase 480: recompute drops stale path labels and projects current association");
      Assert (not Row.Is_Dirty,
              "Phase 480: recompute drops stale dirty indicators and projects current dirty state");
      Assert (Row.Is_Active,
              "Phase 480: active marker remains canonical active-buffer identity");
      Assert (Row_Index_For (S, Alpha) = 1,
              "Phase 480: association label changes do not alter canonical collection order");
   end Test_Phase480_Recompute_Drops_Stale_Label_And_Dirty_Caches;

   procedure Test_Phase480_Duplicate_Lifecycle_State_And_Prompt_Boundaries_Are_Absent
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      App : Editor.State.State_Type;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);
      Editor.Buffer_Switcher.Open (S);
      Recompute_For_Test (S, Registry);
      Editor.Buffer_Switcher.Move_Selection_Down (S);

      Assert (Editor.Buffer_Switcher.Open_Buffer_Switcher_No_Duplicate_Lifecycle_State (S),
              "Phase 480: switcher state owns no path/dirty caches, target histories, operation logs, probes, or repairs");
      Assert (Editor.Buffer_Switcher.Open_Buffer_Switcher_No_Prompt_State (S),
              "Phase 480: switcher state owns no file target prompt state");
      Assert (Editor.Buffer_Switcher.Open_Buffer_Switcher_No_File_Lifecycle_Source_Override (S),
              "Phase 480: switcher state owns no file lifecycle source override");
      Assert (Editor.Buffer_Switcher.Row_At
                (S, Editor.Buffer_Switcher.Selected_Row_Index (S)).Id = Beta,
              "Phase 480 setup: switcher selection is intentionally different from active buffer");
      Assert (Editor.Buffers.Active_Buffer (Registry) = Alpha,
              "Phase 480: switcher selection remains local UI state and not file lifecycle source");

      Editor.State.Init (App);
      Editor.Executor.Open_File_Target_Prompt
        (App, Editor.Commands.Command_Move_Buffer_File);
      Assert (Editor.Executor.File_Target_Prompt_Is_Active (App),
              "Phase 480: prompted file lifecycle state remains canonical Executor state");
      Assert (Editor.Executor.File_Target_Prompt_Input_Text (App) = "",
              "Phase 480: switcher row selection and labels do not seed prompt target text");
      Editor.Buffer_Switcher.Move_Selection_Up (S);
      Assert (Editor.Executor.File_Target_Prompt_Input_Text (App) = "",
              "Phase 480: switcher navigation does not mutate canonical prompt input");
   end Test_Phase480_Duplicate_Lifecycle_State_And_Prompt_Boundaries_Are_Absent;

   procedure Test_Phase480_Copy_Delete_Close_Reopen_Remain_Collection_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled, Reopened : Editor.Buffers.Buffer_Id;
      Closed : Boolean := False;
      pragma Unreferenced (Beta, Untitled);
      Before_Count : Natural := 0;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);
      Editor.Buffer_Switcher.Open (S);
      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/source_for_copy.adb", "source_for_copy.adb");
      Recompute_For_Test (S, Registry);
      Before_Count := Editor.Buffer_Switcher.Row_Count (S);

      --  Copy is represented by the required canonical property: source buffer
      --  association is unchanged and no target buffer is added to the open
      --  collection.
      Recompute_For_Test (S, Registry);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = Before_Count,
              "Phase 480: copy observation cannot create copied-target rows or history rows");
      Assert_Phase479_Row_State
        (S, Alpha, "source_for_copy.adb", True, False,
         "Phase 480 copy observation remains source-association only");

      Clear_Buffer_Association_For_Test (Registry, Alpha);
      Recompute_For_Test (S, Registry);
      Assert (Row_For (S, Alpha).Id = Alpha and then not Row_For (S, Alpha).Has_Path,
              "Phase 480: delete observation is no-associated-file buffer state, not deleted-path recovery state");
      for I in 1 .. Editor.Buffer_Switcher.Row_Count (S) loop
         Assert (To_String (Editor.Buffer_Switcher.Row_At (S, I).Display_Label) /= "source_for_copy.adb",
                 "Phase 480: delete must not retain deleted path as a switcher recovery label");
      end loop;

      Editor.Buffers.Close_Buffer (Registry, Alpha, Closed, Force => True);
      Assert (Closed, "Phase 480 setup must close alpha through canonical buffer helper");
      Recompute_For_Test (S, Registry);
      Assert (Row_Index_For (S, Alpha) = 0,
              "Phase 480: close observation is canonical open-buffer collection removal only");

      Reopened := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/project/src/phase480_reopened.adb", "phase480_reopened.adb", "procedure R is begin null; end;");
      Editor.Buffers.Set_Active_Buffer (Registry, Reopened);
      Recompute_For_Test (S, Registry);
      Assert (Row_For (S, Reopened).Is_Active
                and then To_String (Row_For (S, Reopened).Display_Label) = "phase480_reopened.adb",
              "Phase 480: reopen observation is canonical open-buffer addition only");
   end Test_Phase480_Copy_Delete_Close_Reopen_Remain_Collection_Only;



   procedure Assert_Phase481_Row_Frozen
     (S          : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Id         : Editor.Buffers.Buffer_Id;
      Label      : String;
      Has_Path   : Boolean;
      Is_Dirty   : Boolean;
      Is_Active  : Boolean;
      Expected_Index : Natural;
      Context    : String)
   is
      Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row := Row_For (S, Id);
   begin
      Assert (Row.Id = Id, Context & ": row identity derives from buffer identity");
      Assert (To_String (Row.Display_Label) = Label,
              Context & ": path/display label derives from current buffer association");
      Assert (Row.Has_Path = Has_Path,
              Context & ": has-path marker derives from current association state");
      Assert (Row.Is_Dirty = Is_Dirty,
              Context & ": dirty marker derives from current buffer dirty state");
      Assert (Row.Is_Active = Is_Active,
              Context & ": active marker derives from canonical active buffer identity");
      Assert (Row_Index_For (S, Id) = Expected_Index,
              Context & ": row order derives from canonical open-buffer collection order");
   end Assert_Phase481_Row_Frozen;

   procedure Test_Phase481_Canonical_Observation_Source_Final_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Active_Buffer (Registry, Beta);
      Editor.Buffer_Switcher.Open (S);
      Recompute_For_Test (S, Registry);

      Assert_Phase481_Row_Frozen
        (S, Alpha, "main.adb", True, False, False, 1,
         "Phase 481 source freeze alpha");
      Assert_Phase481_Row_Frozen
        (S, Beta, "readme.txt", True, False, True, 2,
         "Phase 481 source freeze beta");
      Assert_Phase481_Row_Frozen
        (S, Untitled, "Untitled", False, False, False, 3,
         "Phase 481 source freeze untitled");

      Editor.Buffer_Switcher.Move_Selection_Down (S);
      Assert (Editor.Buffer_Switcher.Row_At
                (S, Editor.Buffer_Switcher.Selected_Row_Index (S)).Id = Untitled,
              "Phase 481 selection marker remains switcher-local UI state");
      Assert (Editor.Buffers.Active_Buffer (Registry) = Beta,
              "Phase 481 selected row does not rewrite canonical active buffer identity");
      Assert (Editor.Buffer_Switcher.Open_Buffer_Switcher_File_Lifecycle_Observation_Frozen (S),
              "Phase 481 final helper freezes absence of duplicated lifecycle ownership");
   end Test_Phase481_Canonical_Observation_Source_Final_Freeze;

   procedure Test_Phase481_Operation_Observation_Final_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled, Reopened : Editor.Buffers.Buffer_Id;
      Closed : Boolean := False;
      Before_Count : Natural;
      pragma Unreferenced (Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);
      Editor.Buffer_Switcher.Open (S);
      Recompute_For_Test (S, Registry);
      Before_Count := Editor.Buffer_Switcher.Row_Count (S);

      Set_Buffer_Dirty_For_Test (Registry, Alpha, True);
      Recompute_For_Test (S, Registry);
      Assert_Phase481_Row_Frozen
        (S, Alpha, "main.adb", True, True, True, 1,
         "Phase 481 save-before dirty observation");

      Set_Buffer_Dirty_For_Test (Registry, Alpha, False);
      Recompute_For_Test (S, Registry);
      Assert_Phase481_Row_Frozen
        (S, Alpha, "main.adb", True, False, True, 1,
         "Phase 481 successful save observation");

      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/phase481_save_as.adb", "phase481_save_as.adb");
      Recompute_For_Test (S, Registry);
      Assert_Phase481_Row_Frozen
        (S, Alpha, "phase481_save_as.adb", True, False, True, 1,
         "Phase 481 successful save-as observation");
      Assert (Editor.Buffer_Switcher.Row_Count (S) = Before_Count,
              "Phase 481 save-as preserves row membership");

      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/phase481_renamed.adb", "phase481_renamed.adb");
      Recompute_For_Test (S, Registry);
      Assert_Phase481_Row_Frozen
        (S, Alpha, "phase481_renamed.adb", True, False, True, 1,
         "Phase 481 successful rename observation");

      Recompute_For_Test (S, Registry);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = Before_Count,
              "Phase 481 copy observation does not add copied-target rows");
      Assert_Phase481_Row_Frozen
        (S, Alpha, "phase481_renamed.adb", True, False, True, 1,
         "Phase 481 successful copy preserves source association observation");

      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/phase481_moved.adb", "phase481_moved.adb");
      Recompute_For_Test (S, Registry);
      Assert_Phase481_Row_Frozen
        (S, Alpha, "phase481_moved.adb", True, False, True, 1,
         "Phase 481 successful move observation");

      Clear_Buffer_Association_For_Test (Registry, Alpha);
      Recompute_For_Test (S, Registry);
      Assert_Phase481_Row_Frozen
        (S, Alpha, "Untitled", False, False, True, 1,
         "Phase 481 successful delete observation");

      Set_Buffer_Dirty_For_Test (Registry, Alpha, True);
      Recompute_For_Test (S, Registry);
      Assert_Phase481_Row_Frozen
        (S, Alpha, "Untitled", False, True, True, 1,
         "Phase 481 reload/revert dirty-result observation remains canonical");

      Editor.Buffers.Close_Buffer (Registry, Alpha, Closed, Force => True);
      Assert (Closed, "Phase 481 setup must close active buffer through canonical helper");
      Recompute_For_Test (S, Registry);
      Assert (Row_Index_For (S, Alpha) = 0,
              "Phase 481 close observation removes only the canonical closed buffer row");

      Reopened := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/project/src/phase481_reopened.adb", "phase481_reopened.adb", "procedure R is begin null; end;");
      Editor.Buffers.Set_Active_Buffer (Registry, Reopened);
      Recompute_For_Test (S, Registry);
      Assert (Row_For (S, Reopened).Is_Active,
              "Phase 481 reopen observation follows canonical open/reopen behavior");
      Assert (Row_For (S, Beta).Id = Beta,
              "Phase 481 close/reopen preserves unrelated row identity");
   end Test_Phase481_Operation_Observation_Final_Freeze;

   procedure Test_Phase481_Failed_And_Blocked_Observation_Final_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Before_Count : Natural;
      pragma Unreferenced (Beta, Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);
      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/phase481_source.adb", "phase481_source.adb");
      Set_Buffer_Dirty_For_Test (Registry, Alpha, True);
      Editor.Buffer_Switcher.Open (S);
      Recompute_For_Test (S, Registry);
      Before_Count := Editor.Buffer_Switcher.Row_Count (S);

      --  A failed or blocked lifecycle command is represented by unchanged
      --  canonical buffer state.  The switcher must not surface the failed
      --  target path as a row label, row identity, target history, or cache.
      Recompute_For_Test (S, Registry);
      Assert_Phase481_Row_Frozen
        (S, Alpha, "phase481_source.adb", True, True, True, 1,
         "Phase 481 failed save-as/rename/copy/move observation");
      Assert (Editor.Buffer_Switcher.Row_Count (S) = Before_Count,
              "Phase 481 failed operation cannot add target/history rows");
      for I in 1 .. Editor.Buffer_Switcher.Row_Count (S) loop
         Assert (To_String (Editor.Buffer_Switcher.Row_At (S, I).Display_Label) /= "failed_phase481_target.adb",
                 "Phase 481 failed target path is not retained in switcher rows");
      end loop;
      Assert (Editor.Buffer_Switcher.Open_Buffer_Switcher_File_Lifecycle_Observation_Frozen (S),
              "Phase 481 failed operation leaves no switcher lifecycle ownership");
   end Test_Phase481_Failed_And_Blocked_Observation_Final_Freeze;

   procedure Test_Phase481_Direct_Prompted_Selection_And_Target_Boundaries_Final_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      App : Editor.State.State_Type;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      pragma Unreferenced (Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);
      Set_Buffer_Association_For_Test
        (Registry, Beta, "/tmp/project/src/row_label_looks_like_target.adb", "row_label_looks_like_target.adb");
      Editor.Buffer_Switcher.Open (S);
      Recompute_For_Test (S, Registry);
      Editor.Buffer_Switcher.Move_Selection_Down (S);

      Assert (Editor.Buffer_Switcher.Row_At
                (S, Editor.Buffer_Switcher.Selected_Row_Index (S)).Id = Beta,
              "Phase 481 setup: selected row differs from active lifecycle source");
      Assert (Editor.Buffers.Active_Buffer (Registry) = Alpha,
              "Phase 481 switcher selection is not a file lifecycle source override");

      Editor.State.Init (App);
      Editor.Executor.Open_File_Target_Prompt
        (App, Editor.Commands.Command_Rename_Buffer_File);
      Assert (Editor.Executor.File_Target_Prompt_Is_Active (App),
              "Phase 481 prompt ownership remains canonical Executor state");
      Assert (Editor.Executor.File_Target_Prompt_Input_Text (App) = "",
              "Phase 481 selected row label does not seed target prompt input");
      Editor.Buffer_Switcher.Move_Selection_Up (S);
      Assert (Editor.Executor.File_Target_Prompt_Input_Text (App) = "",
              "Phase 481 switcher interaction does not mutate target prompt input");
      Assert (Editor.Buffer_Switcher.Open_Buffer_Switcher_No_Prompt_State (S),
              "Phase 481 switcher owns no target prompt state");

      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/phase481_direct.adb", "phase481_direct.adb");
      Recompute_For_Test (S, Registry);
      Assert_Phase481_Row_Frozen
        (S, Alpha, "phase481_direct.adb", True, False, True, 1,
         "Phase 481 direct explicit-target observation");

      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/phase481_prompted.adb", "phase481_prompted.adb");
      Recompute_For_Test (S, Registry);
      Assert_Phase481_Row_Frozen
        (S, Alpha, "phase481_prompted.adb", True, False, True, 1,
         "Phase 481 prompted explicit-target observation equivalence");
   end Test_Phase481_Direct_Prompted_Selection_And_Target_Boundaries_Final_Freeze;

   procedure Test_Phase481_Snapshot_Render_Audit_Persistence_Absence_Final_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      Stale_S, Fresh_S : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Stale_Row : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Fresh_Row : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      pragma Unreferenced (Beta, Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);
      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/phase481_before.adb", "phase481_before.adb");
      Set_Buffer_Dirty_For_Test (Registry, Alpha, True);
      Editor.Buffer_Switcher.Open (Stale_S);
      Recompute_For_Test (Stale_S, Registry);
      Stale_Row := Row_For (Stale_S, Alpha);

      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/tmp/project/src/phase481_after.adb", "phase481_after.adb");
      Set_Buffer_Dirty_For_Test (Registry, Alpha, False);
      Fresh_S := Stale_S;
      Recompute_For_Test (Fresh_S, Registry);
      Fresh_Row := Row_For (Fresh_S, Alpha);

      Assert (To_String (Stale_Row.Display_Label) = "phase481_before.adb" and then Stale_Row.Is_Dirty,
              "Phase 481 stale snapshot remains inert and is not repaired by mutation");
      Assert (To_String (Fresh_Row.Display_Label) = "phase481_after.adb" and then not Fresh_Row.Is_Dirty,
              "Phase 481 fresh snapshot reflects current canonical buffer state");
      Assert (Editor.Buffer_Switcher.Open_Buffer_Switcher_No_Duplicate_Lifecycle_State (Fresh_S),
              "Phase 481 render/audit/persistence forbidden cache/history/probe/repair state remains absent");
      Assert (Editor.Buffer_Switcher.Open_Buffer_Switcher_No_File_Lifecycle_Source_Override (Fresh_S),
              "Phase 481 switcher owns no local file lifecycle route or source override");
      Assert (Editor.Buffer_Switcher.Open_Buffer_Switcher_File_Lifecycle_Observation_Frozen (Fresh_S),
              "Phase 481 render audit and persistence boundaries remain inspectors/exclusions only");
   end Test_Phase481_Snapshot_Render_Audit_Persistence_Absence_Final_Freeze;


   procedure Test_Phase543_Row_State_Markers_Are_Snapshot_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : Editor.Buffers.Buffer_Summary :=
        (Id                       => 42,
         Display_Name             => To_Unbounded_String ("demo.adb"),
         Is_Dirty                 => True,
         Is_Active                => True,
         Has_Path                 => True,
         Path                     => To_Unbounded_String ("/tmp/project/demo.adb"),
         Last_Save_Failed         => True,
         Last_Reload_Failed       => True,
         Last_Revert_Failed       => False,
         Missing_Target_Surfaced  => True,
         Unreadable_Target_Surfaced => False,
         Unwritable_Target_Surfaced => True,
         External_Change_Surfaced => True,
         Blocked_Close_Surfaced   => True,
         Is_Pinned                => False,
         Has_Group                => False,
         Group_Name               => Null_Unbounded_String,
         Has_Label                => False,
         Label_Text               => Null_Unbounded_String,
         Has_Note                 => False,
         Note_Text                => Null_Unbounded_String);
      Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Editor.Buffer_Switcher.Build_Open_Buffer_Switcher_Row_From_Buffer_Snapshot (Summary);
      Markers : constant String := Editor.Buffer_Switcher.Buffer_Row_State_Markers (Row);
      Switcher_State : Editor.Buffer_Switcher.Buffer_Switcher_State;
   begin
      Assert (Row.Is_Active and then Row.Is_Dirty,
              "phase 543 row keeps active and dirty state from the registry snapshot");
      Assert (Row.Is_File_Backed and then not Row.Is_Unbacked,
              "phase 543 file-backed marker is derived from Has_Path only");
      Assert (Row.Last_Save_Failed
                and then Row.Last_Reload_Failed
                and then Row.Missing_Target_Surfaced
                and then Row.External_Change_Surfaced
                and then Row.Blocked_Close_Surfaced,
              "phase 573 lifecycle warning markers are copied observation-only");
      Assert (Markers = "active dirty file missing unreadable unwritable external-change guarded",
              "phase 573 marker text includes reload/revert and external-change recovery state deterministically");
   end Test_Phase543_Row_State_Markers_Are_Snapshot_Only;

   procedure Test_Phase543_Command_Aliases_Map_To_Executor_Routed_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
   begin
      Assert (Editor.Commands.Command_Id_From_Stable_Name ("buffer.list.show", Found) =
                Editor.Commands.Command_Open_Buffer_Switcher and then Found,
              "phase 543 buffer.list.show maps to the open-buffer list command");
      Assert (Editor.Commands.Command_Id_From_Stable_Name ("buffer.list.focus", Found) =
                Editor.Commands.Command_Open_Buffer_Switcher and then Found,
              "phase 543 buffer.list.focus maps to the same Executor command path");
      Assert (Editor.Commands.Command_Id_From_Stable_Name ("buffer.list.hide", Found) =
                Editor.Commands.Command_Close_Buffer_Switcher and then Found,
              "phase 543 buffer.list.hide maps to the switcher close command");
      Assert (Editor.Commands.Command_Id_From_Stable_Name ("buffer.switch-selected", Found) =
                Editor.Commands.Command_Accept_Buffer_Switcher and then Found,
              "phase 543 buffer.switch-selected aliases selected row activation");
      Assert (Editor.Commands.Command_Id_From_Stable_Name ("buffer.next", Found) =
                Editor.Commands.Command_Next_Buffer and then Found,
              "phase 543 buffer.next aliases deterministic next-buffer navigation");
      Assert (Editor.Commands.Command_Id_From_Stable_Name ("buffer.previous", Found) =
                Editor.Commands.Command_Previous_Buffer and then Found,
              "phase 543 buffer.previous aliases deterministic previous-buffer navigation");
   end Test_Phase543_Command_Aliases_Map_To_Executor_Routed_Commands;

   procedure Test_Phase543_Empty_State_And_Next_Previous_Availability
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Alpha : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Beta  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Initialize (S);
      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Config);

      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 0,
              "phase 543 empty buffer list has no activatable data rows");
      Assert (Editor.Buffer_Switcher.Buffer_List_Empty_State_Label
                (S.Buffer_Switcher, Editor.Buffers.Global_Count) = "No open buffers",
              "phase 543 empty buffer list reports no open buffers");

      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Next_Buffer);
      Assert (A.Status = Editor.Commands.Command_Unavailable
                and then To_String (A.Reason) = "No buffers open.",
              "phase 543 next buffer is unavailable with no open buffers");

      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/phase543/alpha.adb", "alpha.adb", "procedure Alpha is begin null; end;", Alpha);
      Editor.Buffers.Global_Set_Active_Buffer (Alpha);
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Previous_Buffer);
      Assert (A.Status = Editor.Commands.Command_Unavailable
                and then To_String (A.Reason) = "No other buffer.",
              "phase 543 previous buffer is unavailable with one open buffer");

      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/phase543/beta.adb", "beta.adb", "procedure Beta is begin null; end;", Beta);
      A := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Next_Buffer);
      Assert (A.Status = Editor.Commands.Command_Available,
              "phase 543 next buffer is available with multiple open buffers");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase543_Empty_State_And_Next_Previous_Availability;

   procedure Test_Phase543_Buffer_List_Descriptor_Names_Are_User_Facing
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (To_String (Editor.Commands.Descriptor
                (Editor.Commands.Command_Open_Buffer_Switcher).Name) =
              "Show Open Buffer List",
              "phase 543 descriptor presents the canonical buffer-list surface");
      Assert (To_String (Editor.Commands.Descriptor
                (Editor.Commands.Command_Accept_Buffer_Switcher).Name) =
              "Switch To Selected Buffer",
              "phase 543 selected activation descriptor is buffer-list oriented");
   end Test_Phase543_Buffer_List_Descriptor_Names_Are_User_Facing;

   procedure Test_Phase543_Stale_Selected_Buffer_Row_Is_Unavailable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Alpha  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Beta   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Closed : Boolean := False;
      A      : Editor.Commands.Command_Availability;
   begin
      Editor.State.Initialize (S);
      Setup_Global_Switcher_State (S, Alpha, Beta);

      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 2,
              "phase 543 stale-row test starts from visible real buffer rows");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher) = 1,
              "phase 543 selected row starts on the active buffer");

      Editor.Buffers.Global_Force_Close_Buffer (Alpha, Closed);
      Assert (Closed, "phase 543 test fixture closes selected buffer after snapshot");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Accept_Buffer_Switcher);
      Assert (A.Status = Editor.Commands.Command_Unavailable
                and then To_String (A.Reason) = "Selected buffer is no longer open",
              "phase 543 switch-selected rejects stale closed buffer rows before mutation");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase543_Stale_Selected_Buffer_Row_Is_Unavailable;



   procedure Test_Phase576_Project_Ownership_Markers_Are_Projection_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Config  : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Inside  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Outside : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Found   : Boolean := False;
      Row     : Editor.Buffer_Switcher.Buffer_Switcher_Row;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Initialize (S);
      Editor.Project.Apply_Open_Result
        (S.Project,
         (Status       => Editor.Project.Project_Open_Ok,
          Root_Path    => To_Unbounded_String ("/tmp/phase576/project"),
          Display_Name => To_Unbounded_String ("project"),
          Error_Text   => Null_Unbounded_String));

      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/phase576/project/src/main.adb", "main.adb", "procedure Main is begin null; end;", Inside);
      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/phase576/outside/other.adb", "other.adb", "procedure Other is begin null; end;", Outside);
      Editor.Buffers.Global_Set_Active_Buffer (Inside);
      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, S.Recent_Buffers, S.Project, Config);

      Row := Editor.Buffer_Switcher.Row_For_Buffer (S.Buffer_Switcher, Inside, Found);
      Assert (Found and then Row.Is_Project_Owned
                and then Row.Project_Ownership = Editor.Buffer_Switcher.Buffer_Project_Owned
                and then To_String (Row.Project_Ownership_Label) = "project",
              "Phase 576 inside-project buffer rows expose project-owned display markers only");
      Assert (Editor.Buffer_Switcher.Buffer_Row_State_Markers (Row) = "active file project",
              "Phase 576 project ownership marker composes with active/file markers deterministically");

      Row := Editor.Buffer_Switcher.Row_For_Buffer (S.Buffer_Switcher, Outside, Found);
      Assert (Found and then Row.Is_Outside_Project
                and then Row.Project_Ownership = Editor.Buffer_Switcher.Buffer_Project_Outside
                and then To_String (Row.Project_Ownership_Label) = "outside project",
              "Phase 576 outside-project buffer rows expose outside-project display markers only");
      Assert (Editor.Buffer_Switcher.Buffer_Row_State_Markers (Row) = "file outside-project",
              "Phase 576 outside-project marker is observational and does not alter buffer state");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase576_Project_Ownership_Markers_Are_Projection_Only;



   procedure Test_Phase576_Labels_Scratch_And_No_Project_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Config  : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Inside  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Outside : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Scratch : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Found   : Boolean := False;
      Row     : Editor.Buffer_Switcher.Buffer_Switcher_Row;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Initialize (S);
      Editor.Project.Apply_Open_Result
        (S.Project,
         (Status       => Editor.Project.Project_Open_Ok,
          Root_Path    => To_Unbounded_String ("/tmp/phase576/labels/project"),
          Display_Name => To_Unbounded_String ("project"),
          Error_Text   => Null_Unbounded_String));

      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/phase576/labels/project/src/main.adb", "main.adb", "procedure Main is begin null; end;", Inside);
      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/phase576/labels/outside/main.adb", "main.adb", "procedure Outside is begin null; end;", Outside);
      Editor.Buffers.Global_Add_Untitled_Buffer (Scratch);
      Editor.Buffers.Global_Set_Active_Buffer (Inside);
      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, S.Recent_Buffers, S.Project, Config);

      Row := Editor.Buffer_Switcher.Row_For_Buffer (S.Buffer_Switcher, Inside, Found);
      Assert (Found and then To_String (Row.Display_Label) = "src/main.adb",
              "Phase 576 project-owned rows use project-relative display labels");
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S.Buffer_Switcher, Outside, Found);
      Assert (Found and then To_String (Row.Display_Label) = "outside/main.adb",
              "Phase 576 outside-project duplicate basenames receive deterministic parent hints");
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S.Buffer_Switcher, Scratch, Found);
      Assert (Found and then Row.Project_Ownership = Editor.Buffer_Switcher.Buffer_Project_Scratch
                and then Editor.Buffer_Switcher.Buffer_Row_State_Markers (Row) = "scratch",
              "Phase 576 unbacked rows are labelled and marked as scratch without path payloads");

      --  Recompute against an empty project state to verify no-project ownership is explicit.
      declare
         No_Project : Editor.Project.Project_State;
      begin
         Editor.Buffer_Switcher.Recompute_Rows
           (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, S.Recent_Buffers, No_Project, Config);
      end;
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S.Buffer_Switcher, Inside, Found);
      Assert (Found and then Row.Project_Ownership = Editor.Buffer_Switcher.Buffer_Project_No_Project
                and then To_String (Row.Project_Ownership_Label) = "no project",
              "Phase 576 file-backed rows expose no-project ownership distinctly when no project is open");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase576_Labels_Scratch_And_No_Project_Are_Deterministic;

   procedure Test_Phase576_Selection_Preserves_And_Clamps_On_Recompute
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Config  : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Alpha   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Beta    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Gamma   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Found   : Boolean := False;
      Row     : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Closed  : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Initialize (S);
      Editor.Buffers.Global_Add_File_Buffer ("/tmp/phase576/sel/alpha.adb", "alpha.adb", "", Alpha);
      Editor.Buffers.Global_Add_File_Buffer ("/tmp/phase576/sel/beta.adb", "beta.adb", "", Beta);
      Editor.Buffers.Global_Add_File_Buffer ("/tmp/phase576/sel/gamma.adb", "gamma.adb", "", Gamma);
      Editor.Buffers.Global_Set_Active_Buffer (Alpha);
      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Config);
      Editor.Buffer_Switcher.Move_Selection_Down (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Move_Selection_Down (S.Buffer_Switcher);
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Found and then Row.Id = Gamma,
              "Phase 576 setup selects a non-active row before recompute");

      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Config);
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Found and then Row.Id = Gamma,
              "Phase 576 recompute preserves transient selected buffer identity while it remains visible");

      Editor.Buffers.Global_Force_Close_Buffer (Gamma, Closed);
      Assert (Closed, "Phase 576 setup closes the selected buffer");
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Config);
      Row := Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
      Assert (Found and then Row.Id = Alpha,
              "Phase 576 recompute clamps stale selection back to the active buffer row");
      Assert (Editor.Buffer_Switcher.Assert_Multi_Buffer_Management_Coherent
                (S.Buffer_Switcher),
              "Phase 576 milestone helper confirms coherent transient buffer-list projection");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase576_Selection_Preserves_And_Clamps_On_Recompute;

   procedure Test_Phase576_Lifecycle_Markers_And_Text_Exclusion_Are_Projection_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : Editor.Buffers.Buffer_Summary :=
        (Id                         => 576,
         Display_Name               => To_Unbounded_String ("not-the-buffer-text.adb"),
         Is_Dirty                   => False,
         Is_Active                  => False,
         Has_Path                   => True,
         Path                       => To_Unbounded_String ("/tmp/phase576/markers/not-the-buffer-text.adb"),
         Last_Save_Failed           => True,
         Last_Reload_Failed         => True,
         Last_Revert_Failed         => True,
         Missing_Target_Surfaced    => True,
         Unreadable_Target_Surfaced => True,
         Unwritable_Target_Surfaced => True,
         External_Change_Surfaced   => True,
         Blocked_Close_Surfaced     => True,
         Is_Pinned                  => False,
         Has_Group                  => False,
         Group_Name                 => Null_Unbounded_String,
         Has_Label                  => False,
         Label_Text                 => Null_Unbounded_String,
         Has_Note                   => False,
         Note_Text                  => Null_Unbounded_String);
      Row : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Editor.Buffer_Switcher.Build_Open_Buffer_Switcher_Row_From_Buffer_Snapshot (Summary);
      Markers : constant String := Editor.Buffer_Switcher.Buffer_Row_State_Markers (Row);
      Switcher_State : Editor.Buffer_Switcher.Buffer_Switcher_State;
   begin
      Assert (Markers = "file missing unreadable unwritable external-change guarded",
              "Phase 576 lifecycle markers are rendered from snapshot state without resolving conflicts");
      Assert (To_String (Row.Display_Label) = "not-the-buffer-text.adb"
                and then To_String (Row.Display_Label) /= "procedure Secret is begin null; end;",
              "Phase 576 rows carry display labels only and never copy buffer text contents");
      Assert (Editor.Buffer_Switcher.Open_Buffer_Switcher_No_Duplicate_Lifecycle_State
                (Switcher_State),
              "Phase 576 switcher state has no duplicated lifecycle marker cache");
   end Test_Phase576_Lifecycle_Markers_And_Text_Exclusion_Are_Projection_Only;



   procedure Test_Phase576_Duplicate_Project_Labels_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Config  : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Main_A  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Main_B  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Found   : Boolean := False;
      Row     : Editor.Buffer_Switcher.Buffer_Switcher_Row;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Initialize (S);
      Editor.Project.Apply_Open_Result
        (S.Project,
         (Status       => Editor.Project.Project_Open_Ok,
          Root_Path    => To_Unbounded_String ("/tmp/phase576/duplicate_project"),
          Display_Name => To_Unbounded_String ("duplicate_project"),
          Error_Text   => Null_Unbounded_String));

      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/phase576/duplicate_project/src/main.adb", "main.adb", "src", Main_A);
      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/phase576/duplicate_project/tests/main.adb", "main.adb", "tests", Main_B);
      Editor.Buffers.Global_Set_Active_Buffer (Main_A);
      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, S.Recent_Buffers, S.Project, Config);

      Row := Editor.Buffer_Switcher.Row_For_Buffer (S.Buffer_Switcher, Main_A, Found);
      Assert (Found and then To_String (Row.Display_Label) = "src/main.adb",
              "Phase 576 duplicate project basenames keep deterministic project-relative label for src/main.adb");
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S.Buffer_Switcher, Main_B, Found);
      Assert (Found and then To_String (Row.Display_Label) = "tests/main.adb",
              "Phase 576 duplicate project basenames keep deterministic project-relative label for tests/main.adb");
      Assert (Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = Main_A
                and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 2).Id = Main_B,
              "Phase 576 duplicate label disambiguation does not reorder buffer-list rows");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase576_Duplicate_Project_Labels_Are_Deterministic;


   procedure Test_Phase576_Label_Edge_Cases_Are_Bounded_Stable_And_Filter_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      No_Project_State : Editor.Buffer_Switcher.Buffer_Switcher_State;
      No_Project_Registry : Editor.Buffers.Buffer_Registry;
      Config  : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Project_Main : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Project_Test : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Outside_Main : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Outside_Deep : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Scratch      : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      No_Project_Id : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Found   : Boolean := False;
      Row     : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Project_Label_Before : Unbounded_String;
      Outside_Label_Before : Unbounded_String;
      Deep_Path : constant String :=
        "/tmp/phase576/labels/outside/a/b/c/d/e/final.adb";
      No_Project_Path : constant String :=
        "/tmp/phase576/labels/no_project/parent/main.adb";
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Initialize (S);
      Editor.Project.Apply_Open_Result
        (S.Project,
         (Status       => Editor.Project.Project_Open_Ok,
          Root_Path    => To_Unbounded_String ("/tmp/phase576/labels/project"),
          Display_Name => To_Unbounded_String ("project"),
          Error_Text   => Null_Unbounded_String));

      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/phase576/labels/project/src/main.adb",
         "main.adb", "project src", Project_Main);
      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/phase576/labels/project/tests/main.adb",
         "main.adb", "project tests", Project_Test);
      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/phase576/labels/outside/src/main.adb",
         "main.adb", "outside duplicate", Outside_Main);
      Editor.Buffers.Global_Add_File_Buffer
        (Deep_Path, "final.adb", "outside deep", Outside_Deep);
      Editor.Buffers.Global_Add_Untitled_Buffer (Scratch);
      Editor.Buffers.Global_Set_Active_Buffer (Project_Main);

      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher,
         Editor.Buffers.Global_Registry_For_UI,
         S.Recent_Buffers,
         S.Project,
         Config);

      Row := Editor.Buffer_Switcher.Row_For_Buffer
        (S.Buffer_Switcher, Project_Main, Found);
      Assert (Found and then To_String (Row.Display_Label) = "src/main.adb"
                and then Row.Is_Project_Owned,
              "Phase 576 project duplicate label keeps project-relative parent context");
      Project_Label_Before := Row.Display_Label;

      Row := Editor.Buffer_Switcher.Row_For_Buffer
        (S.Buffer_Switcher, Project_Test, Found);
      Assert (Found and then To_String (Row.Display_Label) = "tests/main.adb"
                and then Row.Is_Project_Owned,
              "Phase 576 same project basename is disambiguated by project-relative directory");

      Row := Editor.Buffer_Switcher.Row_For_Buffer
        (S.Buffer_Switcher, Outside_Main, Found);
      Assert (Found and then To_String (Row.Display_Label) = "src/main.adb"
                and then Row.Is_Outside_Project
                and then To_String (Row.Path) =
                  "/tmp/phase576/labels/outside/src/main.adb",
              "Phase 576 cross-category duplicate labels remain distinguished by ownership and path projection");
      Outside_Label_Before := Row.Display_Label;

      Row := Editor.Buffer_Switcher.Row_For_Buffer
        (S.Buffer_Switcher, Outside_Deep, Found);
      Assert (Found and then To_String (Row.Display_Label) = "e/final.adb"
                and then Row.Is_Outside_Project,
              "Phase 576 deep outside-project paths are bounded to parent/basename labels");
      Assert (Length (Row.Display_Label) < Deep_Path'Length
                and then not Contains_Text (To_String (Row.Display_Label),
                                            "/tmp/phase576"),
              "Phase 576 outside-project labels do not dump unbounded absolute paths");

      Row := Editor.Buffer_Switcher.Row_For_Buffer
        (S.Buffer_Switcher, Scratch, Found);
      Assert (Found and then Row.Is_Unbacked
                and then Row.Project_Ownership =
                  Editor.Buffer_Switcher.Buffer_Project_Scratch
                and then Length (Row.Display_Label) > 0,
              "Phase 576 scratch labels stay readable and pathless");

      Editor.Buffers.Global_Set_Active_Buffer (Outside_Main);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher,
         Editor.Buffers.Global_Registry_For_UI,
         S.Recent_Buffers,
         S.Project,
         Config);
      Row := Editor.Buffer_Switcher.Row_For_Buffer
        (S.Buffer_Switcher, Project_Main, Found);
      Assert (Found and then Row.Display_Label = Project_Label_Before,
              "Phase 576 project labels are stable after active-buffer recompute");
      Row := Editor.Buffer_Switcher.Row_For_Buffer
        (S.Buffer_Switcher, Outside_Main, Found);
      Assert (Found and then Row.Display_Label = Outside_Label_Before,
              "Phase 576 outside-project labels are stable after active-buffer recompute");

      Editor.Buffer_Switcher.Set_Filter_Text (S.Buffer_Switcher, "main.adb");
      Editor.Buffer_Switcher.Set_Sort_Mode
        (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher,
         Editor.Buffers.Global_Registry_For_UI,
         S.Recent_Buffers,
         S.Project,
         Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = 3
                and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 1).Id = Project_Main
                and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 2).Id = Project_Test
                and then Editor.Buffer_Switcher.Row_At (S.Buffer_Switcher, 3).Id = Outside_Main,
              "Phase 576 duplicate basename filter/name-sort ordering remains deterministic");

      No_Project_Id := Editor.Buffers.Add_Buffer_From_File
        (No_Project_Registry, No_Project_Path, "main.adb", "no project");
      Editor.Buffer_Switcher.Open (No_Project_State);
      Editor.Buffer_Switcher.Recompute_Rows
        (No_Project_State, No_Project_Registry, Config);
      Row := Editor.Buffer_Switcher.Row_For_Buffer
        (No_Project_State, No_Project_Id, Found);
      Assert (Found and then To_String (Row.Display_Label) = "main.adb"
                and then Row.Project_Ownership =
                  Editor.Buffer_Switcher.Buffer_Project_No_Project,
              "Phase 576 no-project file labels use canonical buffer display text");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase576_Label_Edge_Cases_Are_Bounded_Stable_And_Filter_Deterministic;

   procedure Test_Phase576_Real_Buffer_Lifecycle_Markers_Project_From_Registry
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S        : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Config   : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Id       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Found    : Boolean := False;
      Row      : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Markers  : Unbounded_String;
   begin
      Id := Editor.Buffers.Add_Buffer_From_File
        (Registry,
         "/tmp/phase576/lifecycle/conflicted.adb",
         "conflicted.adb",
         "buffer text must not appear in row markers");
      Editor.Buffers.Buffer_Access (Registry, Id).File_Info.Missing_Target_Surfaced := True;
      Editor.Buffers.Buffer_Access (Registry, Id).File_Info.Unreadable_Target_Surfaced := True;
      Editor.Buffers.Buffer_Access (Registry, Id).File_Info.Unwritable_Target_Surfaced := True;
      Editor.Buffers.Buffer_Access (Registry, Id).File_Info.External_Change_Surfaced := True;
      Editor.Buffers.Buffer_Access (Registry, Id).File_Info.Blocked_Close_Surfaced := True;
      Editor.Buffers.Buffer_Access (Registry, Id).File_Info.Last_Save_Failed := True;
      Editor.Buffers.Set_Active_Buffer (Registry, Id);

      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Config);
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S, Id, Found);
      Markers := To_Unbounded_String (Editor.Buffer_Switcher.Buffer_Row_State_Markers (Row));

      Assert (Found, "Phase 576 lifecycle marker test must project the real registry buffer");
      Assert (Row.Missing_Target_Surfaced
                and then Row.Unreadable_Target_Surfaced
                and then Row.Unwritable_Target_Surfaced
                and then Row.External_Change_Surfaced
                and then Row.Blocked_Close_Surfaced
                and then Row.Last_Save_Failed,
              "Phase 576 row markers are copied from the authoritative buffer lifecycle snapshot");
      Assert (Contains_Text (To_String (Markers), "missing")
                and then Contains_Text (To_String (Markers), "unreadable")
                and then Contains_Text (To_String (Markers), "unwritable")
                and then Contains_Text (To_String (Markers), "external-change")
                and then Contains_Text (To_String (Markers), "guarded"),
              "Phase 576 real lifecycle markers are display-only row markers");
      Assert (not Contains_Text (To_String (Markers), "buffer text"),
              "Phase 576 marker projection never copies buffer text contents");
   end Test_Phase576_Real_Buffer_Lifecycle_Markers_Project_From_Registry;

   procedure Test_Phase576_File_Lifecycle_Operation_Markers_Project_To_Buffer_List
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Assert_Active_Row_Has
        (S       : in out Editor.State.State_Type;
         Context : String;
         Missing : Boolean := False;
         External : Boolean := False;
         Unwritable : Boolean := False;
         Save_Failed : Boolean := False;
         Reload_Failed : Boolean := False;
         Revert_Failed : Boolean := False)
      is
         Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
         Id     : constant Editor.Buffers.Buffer_Id := Editor.Buffers.Global_Active_Buffer;
         Found  : Boolean := False;
         Row    : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      begin
         Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
         Editor.Buffer_Switcher.Recompute_Rows
           (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Config);
         Row := Editor.Buffer_Switcher.Row_For_Buffer (S.Buffer_Switcher, Id, Found);

         Assert (Found, Context & ": active buffer must have a Buffer List row");
         Assert ((not Missing) or else Row.Missing_Target_Surfaced,
                 Context & ": missing marker must project from lifecycle operation state");
         Assert ((not External) or else Row.External_Change_Surfaced,
                 Context & ": external-change marker must project from lifecycle operation state");
         Assert ((not Unwritable) or else Row.Unwritable_Target_Surfaced,
                 Context & ": unwritable marker must project from lifecycle operation state");
         Assert ((not Save_Failed) or else Row.Last_Save_Failed,
                 Context & ": failed-save marker must project from lifecycle operation state");
         Assert ((not Reload_Failed) or else Row.Last_Reload_Failed,
                 Context & ": failed-reload marker must project from lifecycle operation state");
         Assert ((not Revert_Failed) or else Row.Last_Revert_Failed,
                 Context & ": failed-revert marker must project from lifecycle operation state");
      end Assert_Active_Row_Has;

      Reload_State : Editor.State.State_Type;
      Revert_State : Editor.State.State_Type;
      Conflict_State : Editor.State.State_Type;
      Save_State : Editor.State.State_Type;
      Reload_Path : constant String := Phase576_Temp_Path ("lifecycle_reload_missing.txt");
      Revert_Path : constant String := Phase576_Temp_Path ("lifecycle_revert_missing.txt");
      Conflict_Path : constant String := Phase576_Temp_Path ("lifecycle_external_conflict.txt");
      Save_Path : constant String := Phase576_Temp_Path ("lifecycle_save_failed_dir");
   begin
      --  Missing backing file through the normal reload command path.
      Phase576_Remove_If_Exists (Reload_Path);
      Phase576_Write_Bytes (Reload_Path, "reload baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (Reload_State);
      Editor.Executor.Execute_Open_File (Reload_State, Reload_Path);
      Phase576_Remove_If_Exists (Reload_Path);
      Editor.Executor.Execute_Reload_Active_Buffer (Reload_State);
      Assert_Active_Row_Has
        (Reload_State,
         "Phase 576 reload-missing lifecycle path",
         Missing       => True,
         Reload_Failed => True);
      Assert (Phase576_Buffer_Text (Reload_State) = "reload baseline",
              "Phase 576 Buffer List marker projection must not resolve missing reload failure");

      --  Missing backing file through the normal dirty revert path.
      Phase576_Remove_If_Exists (Revert_Path);
      Phase576_Write_Bytes (Revert_Path, "revert baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (Revert_State);
      Editor.Executor.Execute_Open_File (Revert_State, Revert_Path);
      Phase576_Insert_Text_At
        (Revert_State, Phase576_Buffer_Text (Revert_State)'Length, " dirty");
      Phase576_Remove_If_Exists (Revert_Path);
      Editor.Executor.Execute_Revert_Active_Buffer (Revert_State);
      Editor.Executor.Execute_Command
        (Revert_State, Editor.Commands.Command_Retry_Pending_Transition);
      Assert_Active_Row_Has
        (Revert_State,
         "Phase 576 revert-missing lifecycle path",
         Missing       => True,
         Revert_Failed => True);
      Assert (Phase576_Buffer_Text (Revert_State) = "revert baseline dirty"
                and then Revert_State.File_Info.Dirty,
              "Phase 576 Buffer List marker projection must not discard dirty text during failed revert");

      --  External modification through the normal dirty save conflict path.
      Phase576_Remove_If_Exists (Conflict_Path);
      Phase576_Write_Bytes (Conflict_Path, "conflict baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (Conflict_State);
      Editor.Executor.Execute_Open_File (Conflict_State, Conflict_Path);
      Phase576_Insert_Text_At
        (Conflict_State, Phase576_Buffer_Text (Conflict_State)'Length, " dirty buffer");
      Phase576_Write_Bytes (Conflict_Path, "externally changed disk content");
      Editor.Executor.Execute_Save (Conflict_State);
      Assert (Conflict_State.File_Conflict_Prompt_Active,
              "Phase 576 setup must reach the normal external conflict prompt path");
      Assert_Active_Row_Has
        (Conflict_State,
         "Phase 576 external-conflict lifecycle path",
         External => True);
      Assert (Conflict_State.File_Conflict_Prompt_Active
                and then Conflict_State.File_Info.Dirty,
              "Phase 576 Buffer List marker projection must not resolve save conflict state");

      --  Save failure through the normal save command path where the target is a directory.
      Phase576_Remove_If_Exists (Save_Path);
      Ada.Directories.Create_Directory (Save_Path);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (Save_State);
      Editor.State.Load_Text (Save_State, "save failure dirty text");
      Save_State.File_Info.Has_Path := True;
      Save_State.File_Info.Path := To_Unbounded_String (Save_Path);
      Save_State.File_Info.Display_Name := To_Unbounded_String ("lifecycle_save_failed_dir");
      Save_State.File_Info.Dirty := True;
      Editor.Buffers.Ensure_Global_Registry (Save_State);
      Editor.Executor.Execute_Save (Save_State);
      Assert_Active_Row_Has
        (Save_State,
         "Phase 576 failed-save lifecycle path",
         Unwritable  => True,
         Save_Failed => True);
      Assert (Save_State.File_Info.Dirty,
              "Phase 576 Buffer List marker projection must not clear dirty state on save failure");

      Phase576_Remove_If_Exists (Reload_Path);
      Phase576_Remove_If_Exists (Revert_Path);
      Phase576_Remove_If_Exists (Conflict_Path);
      Phase576_Remove_If_Exists (Save_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Phase576_Remove_If_Exists (Reload_Path);
         Phase576_Remove_If_Exists (Revert_Path);
         Phase576_Remove_If_Exists (Conflict_Path);
         Phase576_Remove_If_Exists (Save_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase576_File_Lifecycle_Operation_Markers_Project_To_Buffer_List;

   procedure Test_Phase576_Workspace_Persistence_Excludes_Buffer_List_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Switcher : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      A, B : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Item : Editor.Workspace_Persistence.Workspace_File_Entry;
      Summary : Unbounded_String;
   begin
      A := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/phase576/persist/alpha.adb", "alpha.adb", "alpha");
      B := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/phase576/persist/beta.adb", "beta.adb", "beta");
      Editor.Buffers.Set_Active_Buffer (Registry, A);
      Editor.Buffer_Switcher.Open (Switcher);
      Editor.Buffer_Switcher.Set_Filter_Text (Switcher, "beta");
      Editor.Buffer_Switcher.Recompute_Rows (Switcher, Registry, Config);
      Editor.Buffer_Switcher.Move_Selection_Down (Switcher);

      Editor.Workspace_Persistence.Clear (Workspace);
      Editor.Workspace_Persistence.Set_Project_Root (Workspace, "/tmp/phase576/persist");
      Item.Path := To_Unbounded_String ("alpha.adb");
      Item.Is_Project_Relative := True;
      Editor.Workspace_Persistence.Add_Open_File (Workspace, Item);
      Editor.Workspace_Persistence.Set_Active_File_Path (Workspace, "alpha.adb");
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Workspace));

      Assert (Editor.Workspace_Persistence.Open_File_Count (Workspace) = 1,
              "Phase 576 workspace still persists structural open-file references under existing policy");
      Assert (not Contains_Text (To_String (Summary), "beta")
                and then not Contains_Text (To_String (Summary), "buffer-list")
                and then not Contains_Text (To_String (Summary), "Buffer_Switcher")
                and then not Contains_Text (To_String (Summary), "Selected_Row")
                and then not Contains_Text (To_String (Summary), Editor.Buffers.Buffer_Id'Image (B)),
              "Phase 576 workspace debug/persistence snapshot excludes buffer-list filter, selection, rows, and runtime buffer ids");
      Assert (Editor.Buffer_Switcher.Selected_Row_Index (Switcher) /= 0,
              "Phase 576 persistence exclusion test keeps transient selection only in the runtime buffer list");
   end Test_Phase576_Workspace_Persistence_Excludes_Buffer_List_State;


   procedure Test_Phase576_Workspace_Save_Load_Roundtrip_Excludes_Buffer_List_Runtime_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Switcher : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Workspace : Editor.Workspace_Persistence.Workspace_Snapshot;
      Loaded    : Editor.Workspace_Persistence.Workspace_Snapshot;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      A, B : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Item : Editor.Workspace_Persistence.Workspace_File_Entry;
      Path  : constant String := Phase576_Temp_Path ("workspace_roundtrip_excludes_buffer_list.session");
      Status : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Serialized : Unbounded_String;
      Loaded_Entry : Editor.Workspace_Persistence.Workspace_File_Entry;
   begin
      Phase576_Remove_If_Exists (Path);

      A := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/phase576/persist-roundtrip/alpha.adb", "alpha.adb", "alpha structural");
      B := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/phase576/persist-roundtrip/beta.adb", "beta.adb", "beta transient row");
      Editor.Buffers.Set_Active_Buffer (Registry, A);
      Set_Buffer_Dirty_For_Test (Registry, B, True);

      Editor.Buffer_Switcher.Open (Switcher);
      Editor.Buffer_Switcher.Set_Filter_Text (Switcher, "beta");
      Editor.Buffer_Switcher.Set_Dirty_Filter (Switcher);
      Editor.Buffer_Switcher.Set_Sort_Mode (Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Set_Mark (Switcher, B);
      Editor.Buffer_Switcher.Recompute_Rows (Switcher, Registry, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (Switcher) = 1
                and then Editor.Buffer_Switcher.Selected_Row_Index (Switcher) = 1
                and then Editor.Buffer_Switcher.Has_Metadata_Filter (Switcher)
                and then Editor.Buffer_Switcher.Filter_Text (Switcher) = "beta"
                and then Editor.Buffer_Switcher.Marked_Count (Switcher) = 1,
              "Phase 576 setup has transient buffer-list filter, selected row, sort, and mark state before workspace save");

      Editor.Workspace_Persistence.Clear (Workspace);
      Editor.Workspace_Persistence.Set_Project_Root
        (Workspace, "/tmp/phase576/persist-roundtrip");
      Item.Path := To_Unbounded_String ("alpha.adb");
      Item.Is_Project_Relative := True;
      Editor.Workspace_Persistence.Add_Open_File (Workspace, Item);
      Editor.Workspace_Persistence.Set_Active_File_Path (Workspace, "alpha.adb");

      Editor.Workspace_Persistence.Save_To_File (Workspace, Path, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "Phase 576 workspace roundtrip test saves the structural workspace snapshot");
      Serialized := To_Unbounded_String (Phase576_Read_Bytes (Path));

      Assert (Contains_Text (To_String (Serialized), "alpha.adb"),
              "Phase 576 workspace serialization still contains the structural open file reference");
      Assert (not Contains_Text (To_String (Serialized), "beta.adb")
                and then not Contains_Text (To_String (Serialized), "beta transient query")
                and then not Contains_Text (To_String (Serialized), "dirty buffers")
                and then not Contains_Text (To_String (Serialized), "Name_Sort")
                and then not Contains_Text (To_String (Serialized), "Buffer_Switcher")
                and then not Contains_Text (To_String (Serialized), "buffer-list")
                and then not Contains_Text (To_String (Serialized), "Selected_Row")
                and then not Contains_Text (To_String (Serialized), "Marked_Count")
                and then not Contains_Text (To_String (Serialized), Editor.Buffers.Buffer_Id'Image (B)),
              "Phase 576 serialized workspace excludes buffer-list rows, query/filter/sort/selection/marks, and runtime buffer ids");

      Editor.Workspace_Persistence.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "Phase 576 workspace roundtrip reloads without buffer-list transient fields");
      Assert (Editor.Workspace_Persistence.Open_File_Count (Loaded) = 1,
              "Phase 576 workspace reload restores only structural open-file entries");
      Loaded_Entry := Editor.Workspace_Persistence.Open_File (Loaded, 1);
      Assert (To_String (Loaded_Entry.Path) = "alpha.adb"
                and then Loaded_Entry.Is_Project_Relative
                and then Editor.Workspace_Persistence.Has_Active_File_Path (Loaded)
                and then Editor.Workspace_Persistence.Active_File_Path (Loaded) = "alpha.adb",
              "Phase 576 workspace reload restores structural active/open file data without Buffer List UI state");

      Phase576_Remove_If_Exists (Path);
   exception
      when others =>
         Phase576_Remove_If_Exists (Path);
         raise;
   end Test_Phase576_Workspace_Save_Load_Roundtrip_Excludes_Buffer_List_Runtime_State;

   procedure Test_Phase576_Render_Snapshot_Does_Not_Mutate_Buffer_List_Or_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Alpha, Beta : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Before_Selected : Natural := 0;
      Before_Rows : Natural := 0;
      Before_Filter : Unbounded_String;
      Before_Active : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Initialize (S);
      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/phase576/render/alpha.adb", "alpha.adb", "alpha", Alpha);
      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/phase576/render/beta.adb", "beta.adb", "beta", Beta);
      Editor.Buffers.Global_Set_Active_Buffer (Alpha);
      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Filter_Text (S.Buffer_Switcher, "adb");
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI, Config);
      Editor.Buffer_Switcher.Move_Selection_Down (S.Buffer_Switcher);
      Before_Selected := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Before_Rows := Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher);
      Before_Filter := To_Unbounded_String (Editor.Buffer_Switcher.Filter_Text (S.Buffer_Switcher));
      Before_Active := Editor.Buffers.Global_Active_Buffer;

      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);

      Assert (Editor.Buffers.Global_Active_Buffer = Before_Active,
              "Phase 576 render snapshot construction does not switch buffers");
      Assert (Editor.Buffers.Global_Contains (Alpha) and then Editor.Buffers.Global_Contains (Beta),
              "Phase 576 render snapshot construction does not close buffers");
      Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = Before_Rows
                and then Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher) = Before_Selected
                and then Editor.Buffer_Switcher.Filter_Text (S.Buffer_Switcher) = To_String (Before_Filter),
              "Phase 576 render snapshot construction does not mutate buffer-list rows, selection, or filter");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase576_Render_Snapshot_Does_Not_Mutate_Buffer_List_Or_Buffers;

   procedure Test_Phase576_Render_Does_Not_Save_Reload_Revert_Probe_Or_Clear_File_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Render_State : Editor.State.State_Type;
      Probe_State  : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Render_Path : constant String := Phase576_Temp_Path ("render_no_file_ops.txt");
      Probe_Path  : constant String := Phase576_Temp_Path ("render_no_probe_missing.txt");
      Dirty_Text  : constant String := "disk baseline dirty buffer";
   begin
      --  Dirty buffer vs. externally changed disk content: render may display
      --  state, but it must not save, reload, revert, or resolve conflicts.
      Phase576_Remove_If_Exists (Render_Path);
      Phase576_Write_Bytes (Render_Path, "disk baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (Render_State);
      Editor.Executor.Execute_Open_File (Render_State, Render_Path);
      Phase576_Insert_Text_At
        (Render_State, Phase576_Buffer_Text (Render_State)'Length, " dirty buffer");
      Phase576_Write_Bytes (Render_Path, "externally changed on disk");
      Render_State.File_Info.External_Change_Surfaced := True;
      Render_State.File_Info.Unwritable_Target_Surfaced := True;
      Render_State.File_Info.Last_Save_Failed := True;
      Render_State.File_Conflict_Prompt_Active := True;
      Render_State.File_Conflict_Prompt_Path := To_Unbounded_String (Render_Path);

      Editor.Render_Model.Build_Render_Snapshot (Render_State, Snap);
      Editor.Render_Model.Build_Render_Snapshot (Render_State, Snap);

      Assert (Phase576_Buffer_Text (Render_State) = Dirty_Text,
              "Phase 576 render must not reload or revert active dirty buffer text");
      Assert (Phase576_Read_Bytes (Render_Path) = "externally changed on disk",
              "Phase 576 render must not save active dirty buffer text to disk");
      Assert (Render_State.File_Info.Dirty,
              "Phase 576 render must not clear dirty state");
      Assert (Render_State.File_Info.External_Change_Surfaced
                and then Render_State.File_Info.Unwritable_Target_Surfaced
                and then Render_State.File_Info.Last_Save_Failed,
              "Phase 576 render must not clear lifecycle/conflict marker state");
      Assert (Render_State.File_Conflict_Prompt_Active
                and then To_String (Render_State.File_Conflict_Prompt_Path) = Render_Path,
              "Phase 576 render must not resolve or clear active file-conflict prompt state");

      --  Deleted backing file: render must not probe the filesystem and surface
      --  a missing/reload/revert/save marker merely because it displays state.
      Phase576_Remove_If_Exists (Probe_Path);
      Phase576_Write_Bytes (Probe_Path, "probe baseline");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (Probe_State);
      Editor.Executor.Execute_Open_File (Probe_State, Probe_Path);
      Phase576_Remove_If_Exists (Probe_Path);

      Editor.Render_Model.Build_Render_Snapshot (Probe_State, Snap);
      Editor.Render_Model.Build_Render_Snapshot (Probe_State, Snap);

      Assert (Phase576_Buffer_Text (Probe_State) = "probe baseline",
              "Phase 576 render must not reload/revert when a backing file disappears");
      Assert (not Probe_State.File_Info.Missing_Target_Surfaced
                and then not Probe_State.File_Info.Last_Reload_Failed
                and then not Probe_State.File_Info.Last_Revert_Failed
                and then not Probe_State.File_Info.Last_Save_Failed,
              "Phase 576 render must not probe filesystem or synthesize lifecycle failure markers");

      Phase576_Remove_If_Exists (Render_Path);
      Phase576_Remove_If_Exists (Probe_Path);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Phase576_Remove_If_Exists (Render_Path);
         Phase576_Remove_If_Exists (Probe_Path);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase576_Render_Does_Not_Save_Reload_Revert_Probe_Or_Clear_File_State;

   procedure Test_Phase576_Canonical_Buffer_List_Aliases_Are_No_Payload_Commands
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
   begin
      Assert (Editor.Commands.Command_Id_From_Stable_Name ("buffer-list.select-next", Found) =
                Editor.Commands.Command_Buffer_Switcher_Next_Result and then Found,
              "Phase 576 buffer-list.select-next aliases transient row selection without payloads");
      Assert (Editor.Commands.Command_Id_From_Stable_Name ("buffer-list.select-previous", Found) =
                Editor.Commands.Command_Buffer_Switcher_Previous_Result and then Found,
              "Phase 576 buffer-list.select-previous aliases transient row selection without payloads");
      Assert (Editor.Commands.Command_Id_From_Stable_Name ("buffer-list.close-selected", Found) =
                Editor.Commands.Command_Buffer_Switcher_Selected_Close and then Found,
              "Phase 576 buffer-list.close-selected resolves to the Executor-routed selected close command");
      Assert (Editor.Commands.Command_Id_From_Stable_Name ("buffer-list.switch-selected", Found) =
                Editor.Commands.Command_Accept_Buffer_Switcher and then Found,
              "Phase 576 buffer-list.switch-selected resolves without embedding a buffer id");
      Assert (Editor.Commands.Command_Id_From_Stable_Name ("buffer-list.close-clean", Found) =
                Editor.Commands.Command_Close_All_Clean_Buffers and then Found,
              "Phase 576 buffer-list.close-clean resolves to the existing safe close-clean workflow without payloads");
      Assert (Editor.Commands.Command_Id_From_Stable_Name ("buffer-list.toggle", Found) =
                Editor.Commands.Command_Open_Buffer_Switcher and then Found,
              "Phase 576 buffer-list.toggle remains a no-payload stable command alias for the list surface");
      Assert (To_String (Editor.Commands.Descriptor
                (Editor.Commands.Command_Buffer_Switcher_Next_Result).Name) =
              "Select Next Buffer List Row",
              "Phase 576 next-row descriptor uses buffer-list terminology");
      Assert (To_String (Editor.Commands.Descriptor
                (Editor.Commands.Command_Buffer_Switcher_Previous_Result).Name) =
              "Select Previous Buffer List Row",
              "Phase 576 previous-row descriptor uses buffer-list terminology");
      declare
         Next_Cmd : constant Editor.Commands.Command :=
           Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Next_Result);
         Prev_Cmd : constant Editor.Commands.Command :=
           Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Previous_Result);
         Switch_Cmd : constant Editor.Commands.Command :=
           Editor.Commands.Command_For_Id (Editor.Commands.Command_Accept_Buffer_Switcher);
         Close_Cmd : constant Editor.Commands.Command :=
           Editor.Commands.Command_For_Id (Editor.Commands.Command_Buffer_Switcher_Selected_Close);
         Clean_Cmd : constant Editor.Commands.Command :=
           Editor.Commands.Command_For_Id (Editor.Commands.Command_Close_All_Clean_Buffers);
      begin
         Assert (Next_Cmd.Buffer_Id = 0 and then Prev_Cmd.Buffer_Id = 0
                   and then Switch_Cmd.Buffer_Id = 0 and then Close_Cmd.Buffer_Id = 0
                   and then Clean_Cmd.Buffer_Id = 0,
                 "Phase 576 buffer-list commands carry no runtime buffer-id payloads");
         Assert (Length (Next_Cmd.Text) = 0 and then Length (Prev_Cmd.Text) = 0
                   and then Length (Switch_Cmd.Text) = 0 and then Length (Close_Cmd.Text) = 0
                   and then Length (Clean_Cmd.Text) = 0,
                 "Phase 576 buffer-list commands carry no text payloads through command palette/keybinding commands");
         Assert (Length (Next_Cmd.Path) = 0 and then Length (Prev_Cmd.Path) = 0
                   and then Length (Switch_Cmd.Path) = 0 and then Length (Close_Cmd.Path) = 0
                   and then Length (Clean_Cmd.Path) = 0,
                 "Phase 576 buffer-list commands carry no path payloads");
      end;
   end Test_Phase576_Canonical_Buffer_List_Aliases_Are_No_Payload_Commands;


   procedure Test_Phase576_Buffer_List_Routes_Keybindings_And_Availability_Are_No_Payload_And_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      type Command_Array is array (Positive range <>) of Editor.Commands.Command_Id;
      Commands : constant Command_Array :=
        (Editor.Commands.Command_Open_Buffer_Switcher,
         Editor.Commands.Command_Close_Buffer_Switcher,
         Editor.Commands.Command_Accept_Buffer_Switcher,
         Editor.Commands.Command_Buffer_Switcher_Next_Result,
         Editor.Commands.Command_Buffer_Switcher_Previous_Result,
         Editor.Commands.Command_Buffer_Switcher_Selected_Close,
         Editor.Commands.Command_Close_All_Clean_Buffers,
         Editor.Commands.Command_Next_Buffer,
         Editor.Commands.Command_Previous_Buffer);

      type Chord_Array is array (Positive range <>) of Editor.Keybindings.Key_Chord;
      Chords : constant Chord_Array :=
        ((Key => Editor.Keybindings.Key_F1,
          Modifiers => (Ctrl => True, Shift => False, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_F2,
          Modifiers => (Ctrl => True, Shift => False, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_F3,
          Modifiers => (Ctrl => True, Shift => False, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_F12,
          Modifiers => (Ctrl => True, Shift => False, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_N,
          Modifiers => (Ctrl => True, Shift => True, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_W,
          Modifiers => (Ctrl => True, Shift => True, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_L,
          Modifiers => (Ctrl => True, Shift => True, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_Tab,
          Modifiers => (Ctrl => True, Shift => False, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_Tab,
          Modifiers => (Ctrl => True, Shift => True, Alt => False, Meta => False)));

      S : Editor.State.State_Type;
      Candidates : Editor.Commands.Command_Palette_Candidate_Vectors.Vector;
      Snapshot   : Editor.Command_Palette.Command_Palette_Snapshot;
      Audit      : Editor.Command_Route_Audit.Route_Audit_Result;
      Found      : Boolean := False;
      Resolved   : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Before_Active : Natural := 0;
      Before_Count  : Natural := 0;
      Before_Row_Count : Natural := 0;
      Before_Selected  : Natural := 0;
      Before_Filter    : Unbounded_String := Null_Unbounded_String;
      Before_Open      : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Keybindings.Clear;
      Editor.Command_Palette.Reset;

      Before_Active := Natural (Editor.Buffers.Global_Active_Buffer);
      Before_Count := Editor.Buffers.Global_Count;
      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Filter_Text (S.Buffer_Switcher, "payload-audit");
      Before_Row_Count := Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher);
      Before_Selected := Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher);
      Before_Filter := To_Unbounded_String (Editor.Buffer_Switcher.Filter_Text (S.Buffer_Switcher));
      Before_Open := Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher);

      for I in Commands'Range loop
         declare
            Id : constant Editor.Commands.Command_Id := Commands (I);
            D  : constant Editor.Commands.Command_Descriptor :=
              Editor.Commands.Descriptor (Id);
            A  : Editor.Commands.Command_Availability;
         begin
            Assert (not Phase576_Command_Has_Payload (Id),
                    "Phase 576 Buffer List command template must not carry buffer ids, paths, text, query, or edit payloads");

            Editor.Command_Route_Audit.Record_Command_Palette_Route
              (Result                   => Audit,
               Command                  => Id,
               Routed_Through_Executor  => True,
               Used_Stable_Command_Name =>
                 Editor.Commands.Command_Id_From_Stable_Name
                   (Editor.Commands.Stable_Command_Name (Id), Found) = Id and then Found,
               Carried_Payload          => Phase576_Command_Has_Payload (Id));

            Editor.Command_Route_Audit.Record_Keybinding_Management_Route
              (Result                   => Audit,
               Command                  => Id,
               Routed_Through_Executor  => True,
               Used_Stable_Command_Name => True,
               Carried_Payload          => Phase576_Command_Has_Payload (Id));

            Editor.Keybindings.Bind (Chords (I), Id);
            Assert (Editor.Keybindings.Resolve (Chords (I), Resolved) = Editor.Keybindings.Bound_Command
                      and then Resolved = Id,
                    "Phase 576 Buffer List keybinding route resolves only to a stable command id");
            Assert (not Phase576_Command_Has_Payload (Resolved),
                    "Phase 576 Buffer List keybinding route must not synthesize a row/buffer/path payload");

            Candidates.Append
              (Editor.Commands.Command_Palette_Candidate'(Id                  => Id,
                Label               => D.Name,
                Description         => D.Description,
                Category            => D.Category,
                Category_Label      => To_Unbounded_String (Editor.Commands.Category_Label (D.Category)),
                Available           => True,
                Reason              => Null_Unbounded_String,
                Has_Keybinding      => Editor.Keybindings.Binding_Count_For_Command (Id) > 0,
                Keybinding_Display  => Editor.Keybindings.Primary_Binding_For_Command (Id).Display,
                Reference_Summary   => To_Unbounded_String (Editor.Commands.Stable_Command_Name (Id)),
                Family              => D.Family,
                Effect_Classification => D.Effect_Classification,
                Match_Score         => 0,
                Registry_Order      => I));

            A := Editor.Executor.Command_Availability (S, Id);
            pragma Unreferenced (A);
            Assert (Natural (Editor.Buffers.Global_Active_Buffer) = Before_Active,
                    "Phase 576 Buffer List availability must not switch buffers");
            Assert (Editor.Buffers.Global_Count = Before_Count,
                    "Phase 576 Buffer List availability must not close buffers");
            Assert (Editor.Buffer_Switcher.Row_Count (S.Buffer_Switcher) = Before_Row_Count,
                    "Phase 576 Buffer List availability must not recompute/mutate rows");
            Assert (Editor.Buffer_Switcher.Selected_Row_Index (S.Buffer_Switcher) = Before_Selected,
                    "Phase 576 Buffer List availability must not mutate transient selection");
            Assert (To_String (Before_Filter) = Editor.Buffer_Switcher.Filter_Text (S.Buffer_Switcher),
                    "Phase 576 Buffer List availability must not mutate transient filter/query");
            Assert (Editor.Buffer_Switcher.Is_Open (S.Buffer_Switcher) = Before_Open,
                    "Phase 576 Buffer List availability must not open/close the list surface");
         end;
      end loop;

      Snapshot := Editor.Command_Palette.Build_Snapshot
        (Candidates,
         (Max_Visible_Rows             => 16,
          Overlay_Width_In_Columns     => 72,
          Show_Unavailable_Commands    => True,
          Group_Empty_Query_By_Category => False,
          Show_Selected_Reason         => True,
          Show_Selected_Description    => True,
          Show_Keybindings             => True,
          Show_Help_Row                => False));

      Assert (Editor.Command_Palette.Candidate_Count (Snapshot) = Commands'Length,
              "Phase 576 command palette projection must expose every Buffer List command as descriptor rows only");

      for I in 0 .. Editor.Command_Palette.Candidate_Count (Snapshot) - 1 loop
         declare
            C : constant Editor.Commands.Command_Palette_Candidate :=
              Editor.Command_Palette.Candidate (Snapshot, I);
         begin
            Assert (not Phase576_Command_Has_Payload (C.Id),
                    "Phase 576 command palette candidate id must resolve to a no-payload command template");
            Assert (C.Reference_Summary = To_Unbounded_String (Editor.Commands.Stable_Command_Name (C.Id)),
                    "Phase 576 command palette candidate carries stable command identity, not row labels or buffer ids");
            Assert (Ada.Strings.Fixed.Index (To_String (C.Reference_Summary), "/") = 0,
                    "Phase 576 command palette candidate reference must not carry file paths");
         end;
      end loop;

      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "Phase 576 Buffer List command-palette/keybinding routes must use Executor, stable ids, and no payloads: "
              & Editor.Command_Route_Audit.Summary (Audit));

      Editor.Keybindings.Reset_To_Defaults;
      Editor.Command_Palette.Reset;
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Keybindings.Reset_To_Defaults;
         Editor.Command_Palette.Reset;
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase576_Buffer_List_Routes_Keybindings_And_Availability_Are_No_Payload_And_Side_Effect_Free;


   procedure Test_Phase576_Settings_And_Recent_Project_Saves_Exclude_Buffer_List_Runtime_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Registry : Editor.Buffers.Buffer_Registry;
      Recent_Buffers : Editor.Recent_Buffers.Recent_Buffer_State;
      Project : Editor.Project.Project_State;
      Config : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Alpha : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Beta  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Settings_Model : Editor.Settings.Settings_Model;
      Settings_Status : Editor.Settings.Settings_Status;
      Recent_List : Editor.Recent_Projects.Recent_Project_List;
      Recent_Status : Editor.Recent_Projects.Recent_Project_Status;
      Settings_Path : constant String := Phase576_Temp_Path ("settings_excludes_buffer_list_runtime.conf");
      Recent_Path   : constant String := Phase576_Temp_Path ("recent_projects_excludes_buffer_list_runtime.conf");
      Settings_Text : Unbounded_String;
      Recent_Text   : Unbounded_String;

      procedure Assert_Runtime_State_Excluded
        (Text : String;
         Domain : String)
      is
      begin
         Assert (not Contains_Text (Text, "phase576-settings-recent-query"),
                 "Phase 576 " & Domain & " persistence must exclude Buffer List query/filter text");
         Assert (not Contains_Text (Text, "buffer-list")
                   and then not Contains_Text (Text, "buffer_switcher")
                   and then not Contains_Text (Text, "buffer-switcher"),
                 "Phase 576 " & Domain & " persistence must exclude Buffer List runtime field names");
         Assert (not Contains_Text (Text, "selected-row")
                   and then not Contains_Text (Text, "Selected_Row")
                   and then not Contains_Text (Text, "marked")
                   and then not Contains_Text (Text, "review")
                   and then not Contains_Text (Text, "Dirty_Filter")
                   and then not Contains_Text (Text, "Name_Sort"),
                 "Phase 576 " & Domain & " persistence must exclude Buffer List selection, marks, review, filters, and sort state");
         Assert (not Contains_Text (Text, "runtime-buffer")
                   and then not Contains_Text (Text, "Buffer_Id")
                   and then not Contains_Text (Text, "phase576-live-a.adb")
                   and then not Contains_Text (Text, "phase576-live-b.adb")
                   and then not Contains_Text (Text, "/tmp/phase576-live"),
                 "Phase 576 " & Domain & " persistence must exclude runtime buffer ids, row labels, and paths");
      end Assert_Runtime_State_Excluded;
   begin
      Phase576_Remove_If_Exists (Settings_Path);
      Phase576_Remove_If_Exists (Recent_Path);
      Editor.State.Init (S);
      Editor.Settings.Reset;
      Editor.Recent_Projects.Clear (Recent_List);

      Alpha := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/phase576-live/a/phase576-live-a.adb", "phase576-live-a.adb", "alpha text");
      Beta := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/phase576-live/b/phase576-live-b.adb", "phase576-live-b.adb", "beta text");
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);
      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Filter_Text (S.Buffer_Switcher, "phase576-settings-recent-query");
      Editor.Buffer_Switcher.Set_Dirty_Filter (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Set_Sort_Mode (S.Buffer_Switcher, Editor.Buffer_Switcher.Name_Sort);
      Editor.Buffer_Switcher.Set_Mark (S.Buffer_Switcher, Beta);
      Editor.Buffer_Switcher.Show_Marked_Review (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows (S.Buffer_Switcher, Registry, Recent_Buffers, Project, Config);
      Editor.Buffer_Switcher.Select_Buffer_Or_Row (S.Buffer_Switcher, Beta, 1);

      Settings_Model := Editor.Settings.Build_From_Current;
      Editor.Settings.Save_To_File (Settings_Model, Settings_Path, Settings_Status);
      Assert (Settings_Status = Editor.Settings.Settings_Ok,
              "Phase 576 settings persistence should save successfully for exclusion audit");
      Settings_Text := To_Unbounded_String (Phase576_Read_Bytes (Settings_Path));
      Assert (Contains_Text (To_String (Settings_Text), "editor-settings-version=1"),
              "Phase 576 settings persistence audit should inspect the serialized settings file");
      Assert_Runtime_State_Excluded (To_String (Settings_Text), "settings");

      Editor.Recent_Projects.Add_Or_Promote
        (Recent_List, "/tmp/recent-domain-root", "recent-domain", 576);
      Editor.Recent_Projects.Save_To_File (Recent_List, Recent_Path, Recent_Status);
      Assert (Recent_Status = Editor.Recent_Projects.Recent_Project_Ok,
              "Phase 576 recent-projects persistence should save successfully for exclusion audit");
      Recent_Text := To_Unbounded_String (Phase576_Read_Bytes (Recent_Path));
      Assert (Contains_Text (To_String (Recent_Text), "editor-recent-projects-version=1"),
              "Phase 576 recent-projects persistence audit should inspect the serialized recent-projects file");
      Assert_Runtime_State_Excluded (To_String (Recent_Text), "recent-projects");

      Phase576_Remove_If_Exists (Settings_Path);
      Phase576_Remove_If_Exists (Recent_Path);
   exception
      when others =>
         Phase576_Remove_If_Exists (Settings_Path);
         Phase576_Remove_If_Exists (Recent_Path);
         raise;
   end Test_Phase576_Settings_And_Recent_Project_Saves_Exclude_Buffer_List_Runtime_State;


   procedure Test_Phase576_Keybinding_Save_Serializes_Buffer_List_Stable_Names_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      type Command_Array is array (Positive range <>) of Editor.Commands.Command_Id;
      Commands : constant Command_Array :=
        (Editor.Commands.Command_Open_Buffer_Switcher,
         Editor.Commands.Command_Close_Buffer_Switcher,
         Editor.Commands.Command_Accept_Buffer_Switcher,
         Editor.Commands.Command_Buffer_Switcher_Next_Result,
         Editor.Commands.Command_Buffer_Switcher_Previous_Result,
         Editor.Commands.Command_Buffer_Switcher_Selected_Close,
         Editor.Commands.Command_Close_All_Clean_Buffers,
         Editor.Commands.Command_Next_Buffer,
         Editor.Commands.Command_Previous_Buffer);

      type Chord_Array is array (Positive range <>) of Editor.Keybindings.Key_Chord;
      Chords : constant Chord_Array :=
        ((Key => Editor.Keybindings.Key_F1,
          Modifiers => (Ctrl => True, Shift => False, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_F2,
          Modifiers => (Ctrl => True, Shift => False, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_F3,
          Modifiers => (Ctrl => True, Shift => False, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_F12,
          Modifiers => (Ctrl => True, Shift => False, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_N,
          Modifiers => (Ctrl => True, Shift => True, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_W,
          Modifiers => (Ctrl => True, Shift => True, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_L,
          Modifiers => (Ctrl => True, Shift => True, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_Tab,
          Modifiers => (Ctrl => True, Shift => False, Alt => False, Meta => False)),
         (Key => Editor.Keybindings.Key_Tab,
          Modifiers => (Ctrl => True, Shift => True, Alt => False, Meta => False)));

      Config : Editor.Keybinding_Config.Keybinding_Config_Model;
      Loaded : Editor.Keybinding_Config.Keybinding_Config_Model;
      Status : Editor.Keybinding_Config.Keybinding_Config_Status;
      Path   : constant String := Phase576_Temp_Path ("keybindings_buffer_list_stable_names_only.conf");
      Text   : Unbounded_String;
      Found  : Boolean := False;
      Round  : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Bound  : Editor.Keybindings.Key_Chord;
   begin
      Phase576_Remove_If_Exists (Path);
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybinding_Config.Clear (Config);

      for I in Commands'Range loop
         Assert (Editor.Commands.Is_Bindable_Command (Commands (I)),
                 "Phase 576 Buffer List command must remain bindable before keybinding serialization");
         Assert (not Phase576_Command_Has_Payload (Commands (I)),
                 "Phase 576 Buffer List command template must be payload-free before keybinding serialization");
         Editor.Keybinding_Config.Bind (Config, Commands (I), Chords (I));
      end loop;

      Editor.Keybinding_Config.Save_To_File (Config, Path, Status);
      Assert (Status = Editor.Keybinding_Config.Keybinding_Config_Ok,
              "Phase 576 keybinding serialization must save Buffer List bindings successfully");
      Text := To_Unbounded_String (Phase576_Read_Bytes (Path));

      Assert (Contains_Text (To_String (Text), "editor-keybindings-version=1"),
              "Phase 576 keybinding serialization keeps the versioned keybinding file format");

      for I in Commands'Range loop
         declare
            Stable : constant String := Editor.Commands.Stable_Command_Name (Commands (I));
            Chord_Text : constant String := Editor.Keybindings.Format_Chord (Chords (I));
         begin
            Assert (Contains_Text (To_String (Text), Stable & "=" & Chord_Text),
                    "Phase 576 keybinding serialization writes only the stable command name and canonical chord for " & Stable);
            Round := Editor.Commands.Command_Id_From_Stable_Name (Stable, Found);
            Assert (Found and then Round = Commands (I),
                    "Phase 576 serialized Buffer List stable command name must round-trip: " & Stable);
         end;
      end loop;

      Assert (not Contains_Text (To_String (Text), "buffer-list.show")
                and then not Contains_Text (To_String (Text), "buffer-list.hide")
                and then not Contains_Text (To_String (Text), "buffer-list.switch-selected")
                and then not Contains_Text (To_String (Text), "buffer-list.select-next")
                and then not Contains_Text (To_String (Text), "buffer-list.select-previous")
                and then not Contains_Text (To_String (Text), "buffer-list.close-selected")
                and then not Contains_Text (To_String (Text), "buffer-list.close-clean"),
              "Phase 576 keybinding persistence writes canonical stable command names, not alternate Buffer List aliases");
      Assert (not Contains_Text (To_String (Text), "buffer.list.")
                and then not Contains_Text (To_String (Text), "phase576-keybinding-query")
                and then not Contains_Text (To_String (Text), "selected-row")
                and then not Contains_Text (To_String (Text), "Selected_Row")
                and then not Contains_Text (To_String (Text), "runtime-buffer")
                and then not Contains_Text (To_String (Text), "Buffer_Id")
                and then not Contains_Text (To_String (Text), "/tmp/phase576")
                and then not Contains_Text (To_String (Text), "alpha.adb")
                and then not Contains_Text (To_String (Text), "beta.adb"),
              "Phase 576 keybinding persistence excludes buffer-list selection, filters, row labels, paths, and runtime buffer ids");

      Editor.Keybinding_Config.Load_From_File (Path, Loaded, Status);
      Assert (Status = Editor.Keybinding_Config.Keybinding_Config_Ok,
              "Phase 576 serialized Buffer List keybindings must reload cleanly");
      for I in Commands'Range loop
         Bound := Editor.Keybinding_Config.Chord_For (Loaded, Commands (I), Found);
         Assert (Found and then Editor.Keybindings.Format_Chord (Bound) = Editor.Keybindings.Format_Chord (Chords (I)),
                 "Phase 576 reloaded Buffer List keybinding must bind the same stable command without payload");
      end loop;

      Phase576_Remove_If_Exists (Path);
      Editor.Keybindings.Reset_To_Defaults;
   exception
      when others =>
         Phase576_Remove_If_Exists (Path);
         Editor.Keybindings.Reset_To_Defaults;
         raise;
   end Test_Phase576_Keybinding_Save_Serializes_Buffer_List_Stable_Names_Only;




   procedure Test_Phase576_State_Filters_Are_Transient_And_Non_Mutating
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      Project  : Editor.Project.Project_State;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      S        : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Config   : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Dirty_Project : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Clean_Project : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Scratch       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Outside       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Missing       : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Found         : Boolean := False;
      Row           : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Original_Count : Natural := 0;
      Original_Active : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Dirty_Project := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/project/src/dirty.adb", "dirty.adb", "dirty project");
      Clean_Project := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/project/src/clean.adb", "clean.adb", "clean project");
      Scratch := Editor.Buffers.Create_Untitled_Buffer (Registry);
      Outside := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/outside/conflict.adb", "conflict.adb", "outside conflict");
      Missing := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/tmp/project/missing.adb", "missing.adb", "missing project");

      Editor.Buffers.Set_Active_Buffer (Registry, Clean_Project);
      Set_Buffer_Dirty_For_Test (Registry, Dirty_Project, True);
      Editor.Buffers.Buffer_Access (Registry, Outside).File_Info.External_Change_Surfaced := True;
      Editor.Buffers.Buffer_Access (Registry, Missing).File_Info.Missing_Target_Surfaced := True;

      Editor.Project.Apply_Open_Result
        (Project,
         (Status       => Editor.Project.Project_Open_Ok,
          Root_Path    => To_Unbounded_String ("/tmp/project"),
          Display_Name => To_Unbounded_String ("project"),
          Error_Text   => Null_Unbounded_String));

      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Project, Config);
      Original_Count := Editor.Buffers.Count (Registry);
      Original_Active := Editor.Buffers.Active_Buffer (Registry);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 5,
              "Phase 576 setup exposes all open buffers before state filters");

      Editor.Buffer_Switcher.Set_Dirty_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Project, Config);
      Assert (Editor.Buffer_Switcher.Metadata_Filter_Description (S) = "dirty buffers",
              "Phase 576 dirty state filter has deterministic transient description");
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1
                and then Editor.Buffer_Switcher.Row_At (S, 1).Id = Dirty_Project,
              "Phase 576 dirty filter shows only dirty buffers");

      Editor.Buffer_Switcher.Set_Clean_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Project, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 4,
              "Phase 576 clean filter hides dirty buffers without closing them");
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S, Dirty_Project, Found);
      Assert (not Found, "Phase 576 clean filter hides the dirty row only from projection");

      Editor.Buffer_Switcher.Set_Missing_Or_Conflict_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Project, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 2,
              "Phase 576 missing/conflict filter shows only affected lifecycle rows");
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S, Outside, Found);
      Assert (Found and then Row.External_Change_Surfaced,
              "Phase 576 missing/conflict filter includes external-conflict rows");
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S, Missing, Found);
      Assert (Found and then Row.Missing_Target_Surfaced,
              "Phase 576 missing/conflict filter includes missing backing-file rows");

      Editor.Buffer_Switcher.Set_Project_Owned_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Project, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 3,
              "Phase 576 project-owned filter shows only buffers under active project root");
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S, Outside, Found);
      Assert (not Found, "Phase 576 project-owned filter hides outside-project buffers");
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S, Scratch, Found);
      Assert (not Found, "Phase 576 project-owned filter hides scratch buffers");

      Editor.Buffer_Switcher.Set_Outside_Project_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Project, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1
                and then Editor.Buffer_Switcher.Row_At (S, 1).Id = Outside,
              "Phase 576 outside-project filter shows only outside-project buffers");

      Editor.Buffer_Switcher.Set_Scratch_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Project, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1
                and then Editor.Buffer_Switcher.Row_At (S, 1).Id = Scratch,
              "Phase 576 scratch filter shows only unbacked scratch buffers");

      Editor.Buffer_Switcher.Set_Filter_Text (S, "clean");
      Editor.Buffer_Switcher.Set_Project_Owned_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Project, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1
                and then Editor.Buffer_Switcher.Row_At (S, 1).Id = Clean_Project,
              "Phase 576 state filters compose with transient label/path query filtering");

      Assert (Editor.Buffers.Count (Registry) = Original_Count
                and then Editor.Buffers.Active_Buffer (Registry) = Original_Active
                and then Editor.Buffers.Is_Dirty (Registry, Dirty_Project),
              "Phase 576 state filters do not close, switch, save, or clear dirty state");
      Assert (Editor.Buffers.Buffer_Access (Registry, Outside).File_Info.External_Change_Surfaced
                and then Editor.Buffers.Buffer_Access (Registry, Missing).File_Info.Missing_Target_Surfaced,
              "Phase 576 state filters do not clear lifecycle conflict/missing markers");

      Editor.Buffer_Switcher.Clear_Metadata_Filter (S);
      Editor.Buffer_Switcher.Set_Filter_Text (S, "");
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Project, Config);
      Assert (not Editor.Buffer_Switcher.Has_Metadata_Filter (S)
                and then Editor.Buffer_Switcher.Row_Count (S) = 5,
              "Phase 576 clearing state filters restores the full transient buffer-list projection");
   end Test_Phase576_State_Filters_Are_Transient_And_Non_Mutating;



   procedure Test_Phase576_Final_Multi_Buffer_Management_Completion_Audit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Project  : Editor.Project.Project_State;
      Config   : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Clean_Project  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Dirty_Project  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Missing_Project : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Outside_Conflict : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Scratch : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Found : Boolean := False;
      Row   : Editor.Buffer_Switcher.Buffer_Switcher_Row;

      procedure Assert_Alias_No_Payload (Name : String; Expected : Editor.Commands.Command_Id) is
         Alias_Found : Boolean := False;
         Id : constant Editor.Commands.Command_Id :=
           Editor.Commands.Command_Id_From_Stable_Name (Name, Alias_Found);
      begin
         Assert (Alias_Found and then Id = Expected,
                 "Phase 576 final audit maps Buffer List alias " & Name & " to the canonical command id");
         Assert (not Phase576_Command_Has_Payload (Id),
                 "Phase 576 final audit keeps Buffer List alias " & Name & " payload-free");
      end Assert_Alias_No_Payload;
   begin
      Editor.Project.Apply_Open_Result
        (Project,
         (Status       => Editor.Project.Project_Open_Ok,
          Root_Path    => To_Unbounded_String ("/tmp/phase576/final/project"),
          Display_Name => To_Unbounded_String ("project"),
          Error_Text   => Null_Unbounded_String));

      Clean_Project := Editor.Buffers.Add_Buffer_From_File
        (Registry,
         "/tmp/phase576/final/project/src/clean.adb",
         "clean.adb",
         "clean buffer text must never appear in a row");
      Dirty_Project := Editor.Buffers.Add_Buffer_From_File
        (Registry,
         "/tmp/phase576/final/project/src/dirty.adb",
         "dirty.adb",
         "dirty buffer text must never appear in a row");
      Missing_Project := Editor.Buffers.Add_Buffer_From_File
        (Registry,
         "/tmp/phase576/final/project/src/missing.adb",
         "missing.adb",
         "missing buffer text must never appear in a row");
      Outside_Conflict := Editor.Buffers.Add_Buffer_From_File
        (Registry,
         "/tmp/phase576/final/outside/conflict.adb",
         "conflict.adb",
         "conflict buffer text must never appear in a row");
      Scratch := Editor.Buffers.Create_Untitled_Buffer (Registry);
      Editor.Buffers.Set_Active_Buffer (Registry, Clean_Project);
      Set_Buffer_Dirty_For_Test (Registry, Dirty_Project, True);
      Editor.Buffers.Buffer_Access (Registry, Missing_Project).File_Info.Missing_Target_Surfaced := True;
      Editor.Buffers.Buffer_Access (Registry, Outside_Conflict).File_Info.External_Change_Surfaced := True;

      Editor.Buffer_Switcher.Open (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Project, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 5,
              "Phase 576 final audit projects every open buffer into the Buffer List");
      Assert (Editor.Buffer_Switcher.Assert_Multi_Buffer_Management_Coherent (S),
              "Phase 576 final audit accepts the complete multi-buffer projection as coherent");

      Row := Editor.Buffer_Switcher.Row_For_Buffer (S, Clean_Project, Found);
      Assert (Found and then Row.Is_Active and then Row.Is_Project_Owned
                and then To_String (Row.Display_Label) = "src/clean.adb",
              "Phase 576 final audit shows active project-owned rows with project-relative labels");
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S, Dirty_Project, Found);
      Assert (Found and then Row.Is_Dirty and then Row.Is_Project_Owned
                and then Contains_Text (Editor.Buffer_Switcher.Buffer_Row_State_Markers (Row), "dirty"),
              "Phase 576 final audit shows dirty project-owned row markers");
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S, Missing_Project, Found);
      Assert (Found and then Row.Missing_Target_Surfaced and then Row.Is_Project_Owned
                and then Contains_Text (Editor.Buffer_Switcher.Buffer_Row_State_Markers (Row), "missing"),
              "Phase 576 final audit shows missing backing-file markers from the buffer snapshot");
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S, Outside_Conflict, Found);
      Assert (Found and then Row.External_Change_Surfaced and then Row.Is_Outside_Project
                and then Contains_Text (Editor.Buffer_Switcher.Buffer_Row_State_Markers (Row), "conflict"),
              "Phase 576 final audit shows outside-project external-conflict markers");
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S, Scratch, Found);
      Assert (Found and then Row.Project_Ownership = Editor.Buffer_Switcher.Buffer_Project_Scratch
                and then not Row.Has_Path
                and then Contains_Text (Editor.Buffer_Switcher.Buffer_Row_State_Markers (Row), "scratch"),
              "Phase 576 final audit shows scratch rows without backing path payloads");

      for I in 1 .. Editor.Buffer_Switcher.Row_Count (S) loop
         declare
            Label : constant String := To_String (Editor.Buffer_Switcher.Row_At (S, I).Display_Label);
         begin
            Assert (not Contains_Text (Label, "buffer text must never appear"),
                    "Phase 576 final audit confirms row labels never copy buffer text");
         end;
      end loop;

      Editor.Buffer_Switcher.Set_Dirty_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Project, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1
                and then Editor.Buffer_Switcher.Row_At (S, 1).Id = Dirty_Project,
              "Phase 576 final audit dirty filter is state-based and non-mutating");

      Editor.Buffer_Switcher.Set_Missing_Or_Conflict_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Project, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 2,
              "Phase 576 final audit missing/conflict filter shows affected buffers only");

      Editor.Buffer_Switcher.Set_Project_Owned_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Project, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 3,
              "Phase 576 final audit project-owned filter shows only active-project buffers");

      Editor.Buffer_Switcher.Set_Outside_Project_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Project, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1
                and then Editor.Buffer_Switcher.Row_At (S, 1).Id = Outside_Conflict,
              "Phase 576 final audit outside-project filter shows only outside-project buffers");

      Editor.Buffer_Switcher.Set_Scratch_Filter (S);
      Editor.Buffer_Switcher.Recompute_Rows (S, Registry, Recent, Project, Config);
      Assert (Editor.Buffer_Switcher.Row_Count (S) = 1
                and then Editor.Buffer_Switcher.Row_At (S, 1).Id = Scratch,
              "Phase 576 final audit scratch filter shows only unbacked buffers");

      Assert (Editor.Buffers.Count (Registry) = 5
                and then Editor.Buffers.Active_Buffer (Registry) = Clean_Project
                and then Editor.Buffers.Is_Dirty (Registry, Dirty_Project)
                and then Editor.Buffers.Buffer_Access (Registry, Missing_Project).File_Info.Missing_Target_Surfaced
                and then Editor.Buffers.Buffer_Access (Registry, Outside_Conflict).File_Info.External_Change_Surfaced,
              "Phase 576 final audit filters do not close, switch, save, clean, or clear lifecycle markers");

      Assert_Alias_No_Payload ("buffer-list.toggle", Editor.Commands.Command_Open_Buffer_Switcher);
      Assert_Alias_No_Payload ("buffer-list.switch-selected", Editor.Commands.Command_Accept_Buffer_Switcher);
      Assert_Alias_No_Payload ("buffer-list.close-selected", Editor.Commands.Command_Buffer_Switcher_Selected_Close);
      Assert_Alias_No_Payload ("buffer-list.close-clean", Editor.Commands.Command_Close_All_Clean_Buffers);
      Assert_Alias_No_Payload ("buffer.next", Editor.Commands.Command_Next_Buffer);
      Assert_Alias_No_Payload ("buffer.previous", Editor.Commands.Command_Previous_Buffer);
   end Test_Phase576_Final_Multi_Buffer_Management_Completion_Audit;

   procedure Test_Phase577_Buffer_List_Rows_Use_Metadata_Snapshot_As_Canonical_Source
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type Editor.Buffers.Buffer_Ownership_Kind;
      use type Editor.Buffer_Switcher.Buffer_Project_Ownership_Kind;
      S       : Editor.State.State_Type;
      Config  : constant Editor.Buffer_Switcher.Buffer_Switcher_Config := (others => <>);
      Inside  : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Outside : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Scratch : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Found   : Boolean := False;
      Row     : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Metadata : Editor.Buffers.Buffer_Metadata_Snapshot;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Initialize (S);
      Editor.Project.Apply_Open_Result
        (S.Project,
         (Status       => Editor.Project.Project_Open_Ok,
          Root_Path    => To_Unbounded_String ("/tmp/phase577/canonical/project"),
          Display_Name => To_Unbounded_String ("project"),
          Error_Text   => Null_Unbounded_String));

      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/phase577/canonical/project/./src/../src/main.adb",
         "main.adb",
         "procedure Main is begin null; end;",
         Inside);
      Editor.Buffers.Global_Add_File_Buffer
        ("/tmp/phase577/canonical/project/../outside/other.adb",
         "other.adb",
         "procedure Other is begin null; end;",
         Outside);
      Editor.Buffers.Global_Add_Untitled_Buffer (Scratch);
      Editor.Buffers.Global_Set_Active_Buffer (Inside);

      Editor.Buffer_Switcher.Open (S.Buffer_Switcher);
      Editor.Buffer_Switcher.Recompute_Rows
        (S.Buffer_Switcher,
         Editor.Buffers.Global_Registry_For_UI,
         S.Recent_Buffers,
         S.Project,
         Config);

      Metadata := Editor.Buffers.Metadata_For
        (Editor.Buffers.Global_Registry_For_UI, S.Project, Inside);
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S.Buffer_Switcher, Inside, Found);
      Assert (Found
                and then Metadata.Ownership = Editor.Buffers.Buffer_Project_Owned
                and then Row.Project_Ownership = Editor.Buffer_Switcher.Buffer_Project_Owned
                and then Row.Is_Project_Owned
                and then To_String (Row.Path) = To_String (Metadata.File_Path)
                and then To_String (Row.Display_Label) = To_String (Metadata.Project_Relative_Path),
              "Phase 577 Buffer List project rows derive path/ownership/display from Buffer_Metadata_Snapshot");

      Metadata := Editor.Buffers.Metadata_For
        (Editor.Buffers.Global_Registry_For_UI, S.Project, Outside);
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S.Buffer_Switcher, Outside, Found);
      Assert (Found
                and then Metadata.Ownership = Editor.Buffers.Buffer_Outside_Project
                and then Row.Project_Ownership = Editor.Buffer_Switcher.Buffer_Project_Outside
                and then Row.Is_Outside_Project
                and then To_String (Row.Path) = To_String (Metadata.File_Path),
              "Phase 577 Buffer List outside-project rows use normalized metadata classification rather than raw path prefixes");

      Metadata := Editor.Buffers.Metadata_For
        (Editor.Buffers.Global_Registry_For_UI, S.Project, Scratch);
      Row := Editor.Buffer_Switcher.Row_For_Buffer (S.Buffer_Switcher, Scratch, Found);
      Assert (Found
                and then Metadata.Ownership = Editor.Buffers.Buffer_Scratch_Unbacked
                and then Row.Project_Ownership = Editor.Buffer_Switcher.Buffer_Project_Scratch
                and then Row.Is_Unbacked
                and then not Row.Has_Path,
              "Phase 577 Buffer List scratch rows use metadata scratch/unbacked classification");

      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase577_Buffer_List_Rows_Use_Metadata_Snapshot_As_Canonical_Source;

   procedure Test_Phase577_Row_Ownership_Wrapper_Delegates_To_Canonical_Classifier
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type Editor.Buffers.Buffer_Ownership_Kind;
      use type Editor.Buffer_Switcher.Buffer_Project_Ownership_Kind;
      Project   : Editor.Project.Project_State;
      Row       : Editor.Buffer_Switcher.Buffer_Switcher_Row := (others => <>);
      Canonical : Editor.Buffers.Buffer_Ownership_Kind;
   begin
      Editor.Project.Apply_Open_Result
        (Project,
         (Status       => Editor.Project.Project_Open_Ok,
          Root_Path    => To_Unbounded_String ("/tmp/phase577/ownership/project"),
          Display_Name => To_Unbounded_String ("project"),
          Error_Text   => Null_Unbounded_String));

      Row.Has_Path := True;
      Row.Path := To_Unbounded_String
        ("/tmp/phase577/ownership/project/../outside/not_project.adb");

      Canonical := Editor.Buffers.Classify_Buffer_Ownership
        (Has_Path => Row.Has_Path,
         Path     => To_String (Row.Path),
         Project  => Project);

      Editor.Buffer_Switcher.Apply_Project_Ownership (Row, Project);

      Assert (Canonical = Editor.Buffers.Buffer_Outside_Project
                and then Row.Project_Ownership = Editor.Buffer_Switcher.Buffer_Project_Outside
                and then Row.Is_Outside_Project
                and then not Row.Is_Project_Owned
                and then To_String (Row.Project_Ownership_Label) = "outside project",
              "Phase 577 row ownership wrapper delegates to canonical normalized-path classifier");

      Row := (others => <>);
      Row.Has_Path := False;
      Canonical := Editor.Buffers.Classify_Buffer_Ownership
        (Has_Path => Row.Has_Path,
         Path     => To_String (Row.Path),
         Project  => Project);
      Editor.Buffer_Switcher.Apply_Project_Ownership (Row, Project);

      Assert (Canonical = Editor.Buffers.Buffer_Scratch_Unbacked
                and then Row.Project_Ownership = Editor.Buffer_Switcher.Buffer_Project_Scratch
                and then Row.Is_Unbacked
                and then not Row.Is_Project_Owned
                and then not Row.Is_Outside_Project,
              "Phase 577 scratch ownership projection is also canonical");
   end Test_Phase577_Row_Ownership_Wrapper_Delegates_To_Canonical_Classifier;



   procedure Test_Phase577_Selected_Buffer_List_State_Audit_Uses_Real_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Registry : Editor.Buffers.Buffer_Registry;
      S        : Editor.Buffer_Switcher.Buffer_Switcher_State;
      Alpha, Beta, Untitled : Editor.Buffers.Buffer_Id;
      Closed   : Boolean := False;
      Audit    : Editor.Buffer_Switcher.Selected_Buffer_List_Audit;
      pragma Unreferenced (Alpha, Untitled);
   begin
      Build_Registry (Registry, Alpha, Beta, Untitled);
      Editor.Buffer_Switcher.Open (S);
      Recompute_For_Test (S, Registry);

      Audit := Editor.Buffer_Switcher.Audit_Selected_Buffer_List_State (S, Registry);
      Assert (Audit.Selected_Row_Valid,
              "Phase 577 selected Buffer List audit accepts a selected registered buffer row");
      Assert (Audit.Selected_Buffer_Id = Beta,
              "Phase 577 selected Buffer List audit reports the real selected runtime buffer id");
      Assert (Audit.Selected_Row_Is_Buffer
                and then Audit.Selected_Runtime_Id_Registered
                and then Audit.Selection_Index_Clamped_To_Rows
                and then Audit.Selection_Skips_Status_Rows,
              "Phase 577 selected Buffer List audit verifies row/index/registered-buffer invariants");
      Assert (Audit.Selection_Is_Transient
                and then Audit.Selection_Not_Persisted
                and then Audit.Selection_Not_Keybinding_Payload,
              "Phase 577 selected Buffer List audit keeps selection runtime-only");

      Editor.Buffers.Close_Buffer (Registry, Beta, Closed, Force => True);
      Assert (Closed, "test setup closes the selected buffer without recomputing rows");
      Audit := Editor.Buffer_Switcher.Audit_Selected_Buffer_List_State (S, Registry);
      Assert (not Audit.Selected_Row_Valid,
              "Phase 577 selected Buffer List audit rejects stale selected rows after the target closes");
      Assert (not Audit.Selected_Runtime_Id_Registered,
              "Phase 577 selected Buffer List audit detects stale selected runtime ids directly from registry state");

      Editor.Buffer_Switcher.Set_Filter_Text (S, "not-open");
      Recompute_For_Test (S, Registry);
      Audit := Editor.Buffer_Switcher.Audit_Selected_Buffer_List_State (S, Registry);
      Assert (Audit.Row_Count = 0
                and then Audit.Selected_Row_Index = 0
                and then Audit.Selected_Row_Valid
                and then Audit.Selection_Cleared_When_No_Rows,
              "Phase 577 selected Buffer List audit verifies selection clears when there are no rows");
   end Test_Phase577_Selected_Buffer_List_State_Audit_Uses_Real_Selection;


   procedure Test_Phase577_Render_Buffer_List_Row_Metadata_Is_Explicit
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Metadata : Editor.Buffers.Buffer_Metadata_Snapshot := (others => <>);
      Summary  : Editor.Buffers.Buffer_Summary := (others => <>);
      Row      : Editor.Buffer_Switcher.Buffer_Switcher_Row;
      Label    : Unbounded_String := Null_Unbounded_String;
   begin
      Metadata.Id := 42;
      Metadata.Display_Label := To_Unbounded_String ("main.adb");
      Metadata.Has_File_Path := True;
      Metadata.File_Path := To_Unbounded_String ("/tmp/phase577/render/project/main.adb");
      Metadata.Has_Project_Relative_Path := True;
      Metadata.Project_Relative_Path := To_Unbounded_String ("src/main.adb");
      Metadata.Is_Dirty := True;
      Metadata.Is_Clean := False;
      Metadata.Ownership := Editor.Buffers.Buffer_Project_Owned;
      Metadata.Ownership_Label := To_Unbounded_String ("Project file");
      Metadata.Lifecycle_Status_Label := To_Unbounded_String ("Conflict pending");
      Metadata.External_Conflict := True;
      Metadata.Stale_Backing_State := True;
      Metadata.Close_Eligibility := Editor.Buffers.Buffer_Requires_Conflict_Resolution_Or_Discard;
      Metadata.Workspace_Persistability := Editor.Buffers.Buffer_Persistable_File_Reference;

      Summary.Id := Metadata.Id;
      Summary.Display_Name := Metadata.Display_Label;
      Summary.Has_Path := True;
      Summary.Path := Metadata.File_Path;

      Row := Editor.Buffer_Switcher.Build_Open_Buffer_Switcher_Row_From_Metadata_Snapshot
        (Metadata, Summary);
      Label := To_Unbounded_String
        (Editor.Buffer_Switcher.Buffer_Row_Metadata_Render_Label (Row));

      Assert (To_String (Row.Lifecycle_Status_Label) = "Conflict pending"
                and then Row.Stale_Backing_State
                and then To_String (Row.Close_Eligibility_Label) =
                  "Requires conflict resolution or discard"
                and then To_String (Row.Workspace_Persistability_Label) =
                  "Persistable file reference",
              "Phase 577 Buffer List rows carry explicit render-facing lifecycle/persistability/close metadata");

      Assert (Ada.Strings.Fixed.Index (To_String (Label), "project") /= 0
                and then Ada.Strings.Fixed.Index (To_String (Label), "Conflict pending") /= 0
                and then Ada.Strings.Fixed.Index (To_String (Label), "Persistable file reference") /= 0
                and then Ada.Strings.Fixed.Index (To_String (Label), "Requires conflict resolution or discard") /= 0
                and then Ada.Strings.Fixed.Index (To_String (Label), "Stale backing state") /= 0,
              "Phase 577 render label exposes all Buffer List row metadata from the snapshot projection");
   end Test_Phase577_Render_Buffer_List_Row_Metadata_Is_Explicit;


   procedure Register_Tests (T : in out Buffer_Switcher_Test_Case) is
   begin
      Register_Routine (T, Test_Open_Close_And_Filter_Input'Access,
                        "open/close and filter input are transient");
      Register_Routine (T, Test_Recompute_Uses_Open_Buffers_In_Order'Access,
                        "rows come from open buffers in order and mark active buffer");
      Register_Routine (T, Test_Literal_Filtering_And_No_Match'Access,
                        "literal filtering narrows rows without project files");
      Register_Routine (T, Test_Selection_Wraps'Access,
                        "selection wraps over visible rows");
      Register_Routine (T, Test_Dirty_Closed_And_Filtered_Active_State'Access,
                        "dirty, closed, and filtered-active switcher rows are deterministic");
      Register_Routine (T, Test_Metadata_Filters_Narrow_Candidates'Access,
                        "metadata filters narrow switcher candidates");
      Register_Routine (T, Test_Metadata_Filter_Replaces_And_Clear_Restores'Access,
                        "metadata filter replacement and clear are deterministic");
      Register_Routine (T, Test_Literal_Query_Filters_Within_Metadata_Filter'Access,
                        "literal query filters inside metadata-filtered candidates");
      Register_Routine (T, Test_Stale_Metadata_Filter_Empty_State'Access,
                        "stale metadata filter produces an explicit empty state");
      Register_Routine (T, Test_Metadata_Filter_Empty_Pinned_And_Noted_Are_Deterministic'Access,
                        "empty pinned and noted filters are deterministic");
      Register_Routine (T, Test_Group_And_Label_Filters_Do_Not_Mutate_Metadata'Access,
                        "group and label filters do not mutate buffer metadata");
      Register_Routine (T, Test_Sort_Modes_Order_Candidates'Access,
                        "sort modes order switcher candidates deterministically");
      Register_Routine (T, Test_Sort_Cycles_And_Composes_With_Filters'Access,
                        "sort modes cycle and compose with filters");
      Register_Routine (T, Test_Sort_State_Survives_Open_Close_And_Uses_Future_Metadata'Access,
                        "sort mode survives switcher close and follows future metadata snapshots");
      Register_Routine (T, Test_Notes_Do_Not_Participate_In_Sort_Order'Access,
                        "notes remain display-only under switcher sort modes");
      Register_Routine (T, Test_Preview_State_Is_Session_Local_And_Bounded'Access,
                        "preview state is switcher-local and reset deterministically");
      Register_Routine (T, Test_Mark_Visible_And_Clear_Visible_Affect_Only_Projected_Rows'Access,
                        "mark visible and clear visible affect only projected rows");
      Register_Routine (T, Test_Marked_Review_Narrows_And_Composes_With_Filter_Query_And_Sort'Access,
                        "marked review narrows candidates and composes with filter query and sort");
      Register_Routine (T, Test_Marked_Review_Empty_Clear_And_Navigation_Are_Deterministic'Access,
                        "marked review empty and navigation behavior is deterministic");
      Register_Routine (T, Test_Pending_Marked_Review_Uses_Captured_Targets_And_Composes'Access,
                        "pending marked review uses captured targets and composes deterministically");
      Register_Routine (T, Test_Phase287_Count_Badge_Text_Is_Derived_And_Compact'Access,
                        "phase 287 count badge text is derived and compact");
      Register_Routine (T, Test_Phase287_Count_Badges_Compose_With_Reviews_Without_Mutation'Access,
                        "phase 287 count badges compose with reviews without mutation");
      Register_Routine (T, Test_Phase288_Dirty_Pending_Badge_Is_Derived_From_Active_Targets'Access,
                        "phase 288 dirty pending badge is derived from active targets");
      Register_Routine (T, Test_Phase289_Dirty_Pending_Navigation_Uses_Visible_Derived_Targets'Access,
                        "phase 289 dirty pending navigation uses visible derived targets");
      Register_Routine (T, Test_Phase296_Dirty_Prune_Count_Badges_Are_Derived_And_Global'Access,
                        "phase 296 dirty-prune count badges are derived and global");
      Register_Routine (T, Test_Phase296_Dirty_Prune_Count_Badges_Clear_And_Do_Not_Mutate_State'Access,
                        "phase 296 dirty-prune count badges clear and do not mutate state");
      Register_Routine (T, Test_Phase297_Dirty_Prune_Clear_Stale_Is_Targeted_And_Non_Recording'Access,
                        "phase 297 dirty-prune clear stale is targeted and non-recording");
      Register_Routine (T, Test_Phase297_Dirty_Prune_Clear_Stale_Zero_Target_Clears_Preview'Access,
                        "phase 297 dirty-prune clear stale zero-target policy clears preview");
      Register_Routine (T, Test_Phase298_Dirty_Prune_Workflow_Reset_And_Zero_Target_Policy'Access,
                        "phase 298 dirty-prune workflow reset and zero-target policy");
      Register_Routine (T, Test_Phase299_Dirty_Prune_Apply_Prepare_Remove_Restore_And_Badges'Access,
                        "phase 299 dirty-prune apply prepare remove restore and badges");
      Register_Routine (T, Test_Phase299_Dirty_Prune_Apply_Confirm_Revalidates_And_Consumes_Preview'Access,
                        "phase 299 dirty-prune apply confirm revalidates and consumes preview");
      Register_Routine (T, Test_Phase300_Review_Mode_Is_Exclusive_And_Centralized'Access,
                        "phase 300 review modes are exclusive and centralized");
      Register_Routine (T, Test_Phase300_Review_Projection_Order_Is_Deterministic'Access,
                        "phase 300 review projection order is deterministic");
      Register_Routine (T, Test_Phase301_Batch_State_Snapshot_Centralizes_Counts_And_Badges'Access,
                        "phase 301 batch-state snapshot centralizes counts and badges");
      Register_Routine (T, Test_Phase301_Row_Markers_And_Global_Counts_Compose_With_Projection'Access,
                        "phase 301 row markers and global counts compose with projection");
      Register_Routine (T, Test_Phase302_Clean_And_Dirty_Marked_Close_End_To_End'Access,
                        "phase 302 clean and dirty marked close paths are safe end to end");
      Register_Routine (T, Test_Phase302_Dirty_Prune_Apply_Does_Not_Close_Dirty_Buffers'Access,
                        "phase 302 dirty-prune apply does not close dirty buffers");
      Register_Routine (T, Test_Phase302_Dirty_Prune_Preview_Removal_Does_Not_Prune_Pending_Close'Access,
                        "phase 302 dirty-prune preview removal does not prune pending close");
      Register_Routine (T, Test_Phase302_Apply_Target_Removal_Does_Not_Edit_Preview_Targets'Access,
                        "phase 302 apply target removal does not edit preview targets");
      Register_Routine (T, Test_Phase302_Stale_Dirty_Prune_Targets_Are_Cleaned_And_Revalidated'Access,
                        "phase 302 stale dirty-prune targets are cleaned and revalidated");
      Register_Routine (T, Test_Phase302_Hidden_Dirty_Targets_Are_Included_In_Global_Dirty_Prune'Access,
                        "phase 302 hidden dirty targets are included in global dirty-prune workflow");
      Register_Routine (T, Test_Phase302_Review_Mode_Switching_Does_Not_Change_Batch_State'Access,
                        "phase 302 review mode switching does not change batch state");
      Register_Routine (T, Test_Phase302_Selected_Close_During_Dirty_Prune_Revalidates_Apply_Targets'Access,
                        "phase 302 selected close during dirty-prune revalidates apply targets");
      Register_Routine (T, Test_Phase302_Marks_Are_Independent_From_Captured_Pending_Close'Access,
                        "phase 302 marks are independent from captured pending close");
      Register_Routine (T, Test_Phase302_Snapshot_Consistency_Across_Representative_Workflow'Access,
                        "phase 302 snapshot consistency across representative workflow");
      Register_Routine (T, Test_Phase304_Contextual_Hints_Are_Known_Available_And_Side_Effect_Free'Access,
                        "phase 304 contextual hints are known available and side-effect free");
      Register_Routine (T, Test_Phase304_Selected_Mark_And_Pending_Close_Hints_Are_State_Based'Access,
                        "phase 304 selected mark and pending close hints are state based");
      Register_Routine (T, Test_Phase304_Hint_Keybinding_Text_Follows_Runtime_Display_Setting'Access,
                        "phase 304 hint keybinding text follows runtime display setting");
      Register_Routine (T, Test_Phase304_Dirty_Prune_Preview_And_Apply_Hints_Are_Prioritized'Access,
                        "phase 304 dirty prune preview and apply hints are prioritized");
      Register_Routine (T, Test_Phase304_Review_Mode_Hints_And_Filtered_Selected_Targets'Access,
                        "phase 304 review mode hints and filtered selected targets");
      Register_Routine (T, Test_Phase304_Hint_Text_Formatting_Is_Deterministic_And_Deduplicated'Access,
                        "phase 304 hint text formatting is deterministic and deduplicated");
      Register_Routine (T, Test_Phase478_Observes_File_Lifecycle_Association_And_Dirty_State'Access,
                        "phase 478 switcher observes lifecycle association and dirty state");
      Register_Routine (T, Test_Phase478_Observes_Close_And_Reopen_Collection_Only'Access,
                        "phase 478 switcher observes close and reopen through collection only");
      Register_Routine (T, Test_Phase478_Prompt_And_Selection_Boundary_Is_Observation_Only'Access,
                        "phase 478 switcher selection and prompt boundary is observation-only");
      Register_Routine (T, Test_Phase478_Rows_Contain_No_File_Lifecycle_Operation_State'Access,
                        "phase 478 switcher rows contain no file lifecycle operation state");
      Register_Routine (T, Test_Phase479_Successful_Observation_Reliable_Visible_And_Hidden'Access,
                        "phase 479 successful lifecycle observations are reliable visible and hidden");
      Register_Routine (T, Test_Phase479_Failed_And_Blocked_Operations_Preserve_Observation'Access,
                        "phase 479 failed and blocked lifecycle operations preserve switcher observation");
      Register_Routine (T, Test_Phase479_Selection_And_Prompt_Boundaries_Are_Reliable'Access,
                        "phase 479 switcher selection and prompt boundaries are reliable");
      Register_Routine (T, Test_Phase479_Snapshot_Freshness_And_Stale_Snapshot_Immutability'Access,
                        "phase 479 fresh snapshots update and stale snapshots remain inert");
      Register_Routine (T, Test_Phase479_Rows_Exclude_Lifecycle_Target_Histories_And_Operation_Logs'Access,
                        "phase 479 rows exclude lifecycle target histories and operation logs");
      Register_Routine (T, Test_Phase480_Row_Projection_Helper_Is_Canonical_Buffer_Snapshot'Access,
                        "phase 480 row projection helper is canonical buffer snapshot only");
      Register_Routine (T, Test_Phase480_Recompute_Drops_Stale_Label_And_Dirty_Caches'Access,
                        "phase 480 recompute drops stale label and dirty caches");
      Register_Routine (T, Test_Phase480_Duplicate_Lifecycle_State_And_Prompt_Boundaries_Are_Absent'Access,
                        "phase 480 duplicate lifecycle state and prompt boundaries are absent");
      Register_Routine (T, Test_Phase480_Copy_Delete_Close_Reopen_Remain_Collection_Only'Access,
                        "phase 480 copy delete close reopen remain collection only");
      Register_Routine (T, Test_Phase481_Canonical_Observation_Source_Final_Freeze'Access,
                        "phase 481 canonical observation source final freeze");
      Register_Routine (T, Test_Phase481_Operation_Observation_Final_Freeze'Access,
                        "phase 481 operation observation final freeze");
      Register_Routine (T, Test_Phase481_Failed_And_Blocked_Observation_Final_Freeze'Access,
                        "phase 481 failed and blocked observation final freeze");
      Register_Routine (T, Test_Phase481_Direct_Prompted_Selection_And_Target_Boundaries_Final_Freeze'Access,
                        "phase 481 direct prompted selection and target boundaries final freeze");
      Register_Routine (T, Test_Phase481_Snapshot_Render_Audit_Persistence_Absence_Final_Freeze'Access,
                        "phase 481 snapshot render audit persistence absence final freeze");
      Register_Routine (T, Test_Phase543_Row_State_Markers_Are_Snapshot_Only'Access,
                        "phase 543 buffer list row markers are snapshot-only");
      Register_Routine (T, Test_Phase543_Command_Aliases_Map_To_Executor_Routed_Commands'Access,
                        "phase 543 canonical buffer navigation alternate names route to Executor commands");
      Register_Routine (T, Test_Phase543_Empty_State_And_Next_Previous_Availability'Access,
                        "phase 543 empty state and next/previous availability are deterministic");
      Register_Routine (T, Test_Phase576_Project_Ownership_Markers_Are_Projection_Only'Access,
                        "phase 576 buffer list project ownership markers are projection only");
      Register_Routine (T, Test_Phase576_Labels_Scratch_And_No_Project_Are_Deterministic'Access,
                        "phase 576 buffer list labels scratch and no-project ownership are deterministic");
      Register_Routine (T, Test_Phase576_Selection_Preserves_And_Clamps_On_Recompute'Access,
                        "phase 576 buffer list selection preserves and clamps on recompute");
      Register_Routine (T, Test_Phase576_Lifecycle_Markers_And_Text_Exclusion_Are_Projection_Only'Access,
                        "phase 576 lifecycle markers and text exclusion are projection-only");
      Register_Routine (T, Test_Phase576_Duplicate_Project_Labels_Are_Deterministic'Access,
                        "phase 576 duplicate project labels are deterministic");
      Register_Routine
        (T,
         Test_Phase576_Label_Edge_Cases_Are_Bounded_Stable_And_Filter_Deterministic'Access,
         "phase 576 label edge cases are bounded, stable, and deterministic");
      Register_Routine (T, Test_Phase576_Real_Buffer_Lifecycle_Markers_Project_From_Registry'Access,
                        "phase 576 real buffer lifecycle markers project from registry snapshots");
      Register_Routine (T, Test_Phase576_File_Lifecycle_Operation_Markers_Project_To_Buffer_List'Access,
                        "phase 576 lifecycle operation markers project to buffer list rows");
      Register_Routine (T, Test_Phase576_Workspace_Persistence_Excludes_Buffer_List_State'Access,
                        "phase 576 workspace persistence excludes buffer-list transient state");
      Register_Routine (T, Test_Phase576_Workspace_Save_Load_Roundtrip_Excludes_Buffer_List_Runtime_State'Access,
                        "phase 576 workspace save/load roundtrip excludes buffer-list runtime state");
      Register_Routine (T, Test_Phase576_Render_Snapshot_Does_Not_Mutate_Buffer_List_Or_Buffers'Access,
                        "phase 576 render snapshot does not mutate buffer list or buffers");
      Register_Routine (T, Test_Phase576_Render_Does_Not_Save_Reload_Revert_Probe_Or_Clear_File_State'Access,
                        "phase 576 render does not save reload revert probe or clear file state");
      Register_Routine (T, Test_Phase576_Canonical_Buffer_List_Aliases_Are_No_Payload_Commands'Access,
                        "phase 576 canonical buffer list alternate names remain no-payload commands");
      Register_Routine (T, Test_Phase576_Buffer_List_Routes_Keybindings_And_Availability_Are_No_Payload_And_Side_Effect_Free'Access,
                        "phase 576 buffer list command palette/keybinding routes and availability are no-payload and side-effect-free");
      Register_Routine (T, Test_Phase576_Settings_And_Recent_Project_Saves_Exclude_Buffer_List_Runtime_State'Access,
                        "Phase 576 settings/recent persistence excludes Buffer List runtime state");
      Register_Routine (T, Test_Phase576_Keybinding_Save_Serializes_Buffer_List_Stable_Names_Only'Access,
                        "phase 576 keybinding persistence serializes Buffer List stable names only");
      Register_Routine (T, Test_Phase576_State_Filters_Are_Transient_And_Non_Mutating'Access,
                        "phase 576 buffer list state filters are transient and non-mutating");
      Register_Routine (T, Test_Phase576_Final_Multi_Buffer_Management_Completion_Audit'Access,
                        "phase 576 final multi-buffer management completion audit");
      Register_Routine (T, Test_Phase577_Buffer_List_Rows_Use_Metadata_Snapshot_As_Canonical_Source'Access,
                        "phase 577 buffer list rows use metadata snapshot as canonical source");
      Register_Routine (T, Test_Phase577_Row_Ownership_Wrapper_Delegates_To_Canonical_Classifier'Access,
                        "phase 577 row ownership wrapper delegates to canonical classifier");
      Register_Routine (T, Test_Phase577_Selected_Buffer_List_State_Audit_Uses_Real_Selection'Access,
                        "phase 577 selected Buffer List state audit uses real selection");
      Register_Routine (T, Test_Phase577_Render_Buffer_List_Row_Metadata_Is_Explicit'Access,
                        "phase 577 render Buffer List rows expose explicit metadata projection");
      Register_Routine (T, Test_Phase543_Buffer_List_Descriptor_Names_Are_User_Facing'Access,
                        "phase 543 buffer-list descriptors are user-facing");
      Register_Routine (T, Test_Phase543_Stale_Selected_Buffer_Row_Is_Unavailable'Access,
                        "phase 543 stale selected buffer rows are unavailable");
   end Register_Tests;

end Editor.Buffer_Switcher.Tests;
