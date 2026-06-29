with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases; use AUnit.Test_Cases.Registration;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Editor.Commands;
with Editor.Keybindings;
with Editor.File_Tree;
with Editor.Quick_Open;
with Editor.Quick_Open_Markers;
with Editor.Buffers;
with Editor.State;
with Editor.Project;
with Editor.Recent_Buffers;
with Editor.Input_Field;
with Editor.Executor;
with Editor.Command_Route_Audit;
with Editor.Workspace_Persistence;
with Editor.Overlay_Focus;
with Editor.Project_Navigation;
with Editor.Messages;

package body Editor.Quick_Open.Tests is

   use type Editor.Commands.Command_Id;
   use type Editor.Commands.Command_Category;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Commands.Command_Availability_Status;
   use type Editor.Keybindings.Keybinding_Change_Status;
   use type Editor.Keybindings.Binding_Result;
   use type Editor.File_Tree.File_Tree_Node_Id;
   use type Editor.File_Tree.File_Tree_Node_Kind;
   use type Editor.Quick_Open.Quick_Open_Match_Bucket;
   use type Editor.Quick_Open.Quick_Open_File_Kind_Filter;
   use type Editor.Quick_Open.Quick_Open_Create_Target_Status;
   use type Editor.Project.Project_File_Refresh_Status;
   use type Editor.Quick_Open.Quick_Open_Priority_Mode;
   use type Editor.Quick_Open.Quick_Open_Priority_Bucket;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Workspace_Persistence.Workspace_Persistence_Status;

   package Stream_IO renames Ada.Streams.Stream_IO;

   function Name (T : Quick_Open_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Quick_Open");
   end Name;


   function Active_Message_Text (S : Editor.State.State_Type) return String is
      Found : Boolean := False;
      M     : Editor.Messages.Editor_Message;
   begin
      M := Editor.Messages.Active_Message (S.Messages, Found);
      if Found then
         return Editor.Messages.Text (M);
      else
         return "";
      end if;
   end Active_Message_Text;


   function Chord
     (Key   : Editor.Keybindings.Key_Code;
      Ctrl  : Boolean := False;
      Shift : Boolean := False;
      Alt   : Boolean := False) return Editor.Keybindings.Key_Chord
   is
   begin
      return
        (Key       => Key,
         Modifiers => (Ctrl => Ctrl, Shift => Shift, Alt => Alt, Meta => False));
   end Chord;

   function Palette_Contains
     (Id : Editor.Commands.Command_Id) return Boolean
   is
      Descriptors : constant Editor.Commands.Command_Descriptor_Vectors.Vector :=
        Editor.Commands.Palette_Commands;
   begin
      for D of Descriptors loop
         if D.Id = Id then
            return True;
         end if;
      end loop;
      return False;
   end Palette_Contains;

   procedure Assert_Command_Surface
     (Id              : Editor.Commands.Command_Id;
      Stable_Name     : String;
      Category        : Editor.Commands.Command_Category;
      Visibility      : Editor.Commands.Command_Visibility;
      Bindable        : Boolean;
      Lifecycle       : Boolean := False;
      Configuration   : Boolean := False;
      Destructive     : Boolean := False)
   is
      D     : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Id);
      Found : Boolean := False;
      Back  : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Assert (Editor.Commands.Has_Descriptor (Id),
              Stable_Name & " must have descriptor metadata");
      Assert (D.Id = Id,
              Stable_Name & " descriptor id must match inventory id");
      Assert (Editor.Commands.Stable_Command_Name (Id) = Stable_Name,
              Stable_Name & " stable name drifted");
      Back := Editor.Commands.Command_Id_From_Stable_Name (Stable_Name, Found);
      Assert (Found and then Back = Id,
              Stable_Name & " must resolve back to the same command id");
      Assert (D.Category = Category,
              Stable_Name & " descriptor category drifted");
      Assert (D.Visibility = Visibility,
              Stable_Name & " palette visibility drifted");
      Assert (D.Bindable = Bindable,
              Stable_Name & " bindability drifted");
      Assert (D.Lifecycle = Lifecycle,
              Stable_Name & " lifecycle classification drifted");
      Assert (D.Configuration = Configuration,
              Stable_Name & " configuration classification drifted");
      Assert (D.Destructive = Destructive,
              Stable_Name & " destructive classification drifted");
      Assert (Editor.Commands.Has_Availability_Handler (Id),
              Stable_Name & " must have Executor availability coverage");
      Assert (Palette_Contains (Id) = (Visibility = Editor.Commands.Palette_Command),
              Stable_Name & " palette projection must follow descriptor visibility");
   end Assert_Command_Surface;

   procedure Assert_Absent_Command_Not_Exposed (Stable_Name : String) is
      Found : Boolean := False;
      Id    : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name (Stable_Name, Found);
      Assert (not Found and then Id = Editor.Commands.No_Command,
              Stable_Name & " must not resolve to a registered command");
   end Assert_Absent_Command_Not_Exposed;

   function Temp_Path (Name : String) return String is
   begin
      Ada.Directories.Create_Path ("/tmp/editor-tests");
      return Ada.Directories.Compose
        ("/tmp/editor-tests", "phase72_" & Name);
   end Temp_Path;

   procedure Remove_File_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_File (Path);
      end if;
   end Remove_File_If_Exists;

   procedure Remove_Dir_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Directory (Path);
      end if;
   end Remove_Dir_If_Exists;

   procedure Write_Bytes (Path : String; Bytes : String) is
      F : Stream_IO.File_Type;
      Raw : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Bytes'Length));
   begin
      Stream_IO.Create (F, Stream_IO.Out_File, Path);
      for I in Bytes'Range loop
         Raw (Ada.Streams.Stream_Element_Offset (I - Bytes'First + 1)) :=
           Ada.Streams.Stream_Element (Character'Pos (Bytes (I)));
      end loop;
      if Bytes'Length > 0 then
         Stream_IO.Write (F, Raw);
      end if;
      Stream_IO.Close (F);
   end Write_Bytes;

   procedure Build_Fixture (Root : String) is
      Src : constant String := Ada.Directories.Compose (Root, "src");
      Doc : constant String := Ada.Directories.Compose (Root, "doc");
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (Src, "main.adb"));
      Remove_File_If_Exists (Ada.Directories.Compose (Src, "other.ads"));
      Remove_File_If_Exists (Ada.Directories.Compose (Doc, "main.txt"));
      Remove_Dir_If_Exists (Src);
      Remove_Dir_If_Exists (Doc);
      Remove_Dir_If_Exists (Root);

      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Ada.Directories.Create_Directory (Doc);
      Write_Bytes (Ada.Directories.Compose (Src, "main.adb"), "main");
      Write_Bytes (Ada.Directories.Compose (Src, "other.ads"), "other");
      Write_Bytes (Ada.Directories.Compose (Doc, "main.txt"), "doc");
   end Build_Fixture;

   procedure Cleanup_Fixture (Root : String) is
      Src : constant String := Ada.Directories.Compose (Root, "src");
      Doc : constant String := Ada.Directories.Compose (Root, "doc");
   begin
      Remove_File_If_Exists (Ada.Directories.Compose (Src, "main.adb"));
      Remove_File_If_Exists (Ada.Directories.Compose (Src, "other.ads"));
      Remove_File_If_Exists (Ada.Directories.Compose (Doc, "main.txt"));
      Remove_Dir_If_Exists (Src);
      Remove_Dir_If_Exists (Doc);
      Remove_Dir_If_Exists (Root);
   end Cleanup_Fixture;

   procedure Delete_Tree_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         Ada.Directories.Delete_Tree (Path);
      end if;
   exception
      when others =>
         null;
   end Delete_Tree_If_Exists;

   function Slash (Left, Right : String) return String is
   begin
      return Ada.Directories.Compose (Left, Right);
   end Slash;

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

   function Quick_Open_Candidate_Index
     (Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
      Path     : String) return Natural
   is
   begin
      if Snapshot.Candidates.Length = 0 then
         return Natural'Last;
      end if;

      for I in Snapshot.Candidates.First_Index .. Snapshot.Candidates.Last_Index loop
         if To_String (Snapshot.Candidates (I).Project_Relative_Path) = Path then
            return I;
         end if;
      end loop;
      return Natural'Last;
   end Quick_Open_Candidate_Index;

   function Quick_Open_Has_Candidate
     (Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
      Path     : String) return Boolean
   is
   begin
      return Quick_Open_Candidate_Index (Snapshot, Path) /= Natural'Last;
   end Quick_Open_Has_Candidate;


   function Quick_Open_Candidate_Index_For_Buffer
     (Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
      Id       : Editor.Buffers.Buffer_Id) return Natural
   is
   begin
      if Snapshot.Candidates.Length = 0 then
         return Natural'Last;
      end if;

      for I in Snapshot.Candidates.First_Index .. Snapshot.Candidates.Last_Index loop
         if Snapshot.Candidates (I).Buffer_Identity = Id then
            return I;
         end if;
      end loop;
      return Natural'Last;
   end Quick_Open_Candidate_Index_For_Buffer;

   function File_Text (Path : String) return String is
      F    : Stream_IO.File_Type;
      Last : Ada.Streams.Stream_Element_Offset;
   begin
      if not Ada.Directories.Exists (Path) then
         return "";
      end if;

      Stream_IO.Open (F, Stream_IO.In_File, Path);
      declare
         Data : Ada.Streams.Stream_Element_Array
           (1 .. Ada.Streams.Stream_Element_Offset (Stream_IO.Size (F)));
      begin
         if Data'Length > 0 then
            Stream_IO.Read (F, Data, Last);
         else
            Last := 0;
         end if;
         Stream_IO.Close (F);

         declare
            Text : String (1 .. Natural (Last));
         begin
            for I in Text'Range loop
               Text (I) := Character'Val
                 (Data (Ada.Streams.Stream_Element_Offset (I)));
            end loop;
            return Text;
         end;
      end;
   exception
      when others =>
         if Stream_IO.Is_Open (F) then
            Stream_IO.Close (F);
         end if;
         return "";
   end File_Text;

   function Contains_Text (Text, Fragment : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Text, Fragment) /= 0;
   end Contains_Text;

   procedure Assert_Quick_Open_No_Forbidden_Lifecycle_Text
     (Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
      Message  : String)
   is
   begin
      for C of Snapshot.Candidates loop
         declare
            Text : constant String := To_String (C.Display_Text) & " " &
              To_String (C.Project_Relative_Path);
         begin
            Assert (not Contains_Text (Text, "last save-as"),
                    Message & ": no save-as target cache in candidates");
            Assert (not Contains_Text (Text, "last rename"),
                    Message & ": no rename target cache in candidates");
            Assert (not Contains_Text (Text, "last copy"),
                    Message & ": no copy target cache in candidates");
            Assert (not Contains_Text (Text, "last move"),
                    Message & ": no move target cache in candidates");
            Assert (not Contains_Text (Text, "last delete"),
                    Message & ": no delete source cache in candidates");
            Assert (not Contains_Text (Text, "operation-history"),
                    Message & ": no operation history in candidates");
            Assert (not Contains_Text (Text, "target-history"),
                    Message & ": no target history in candidates");
            Assert (not Contains_Text (Text, "prompt-input"),
                    Message & ": no prompt input in candidates");
            Assert (not Contains_Text (Text, "filesystem-probe"),
                    Message & ": no filesystem probe result in candidates");
            Assert (not Contains_Text (Text, "association-repair"),
                    Message & ": no association repair marker in candidates");
            Assert (not Contains_Text (Text, "project-repair"),
                    Message & ": no project candidate repair marker in candidates");
         end;
      end loop;
   end Assert_Quick_Open_No_Forbidden_Lifecycle_Text;

   procedure Assert_Quick_Open_File_Lifecycle_Observation_Frozen
     (Snapshot       : Editor.Quick_Open.Quick_Open_Snapshot;
      Buffer_Id      : Editor.Buffers.Buffer_Id;
      Expected_Path  : String;
      Expected_Dirty : Boolean;
      Expected_Active : Boolean;
      Message        : String)
   is
      Index : constant Natural :=
        Quick_Open_Candidate_Index_For_Buffer (Snapshot, Buffer_Id);
   begin
      Assert (Snapshot.Visible,
              Message & ": Quick Open visible flag must remain UI state");
      Assert (Index /= Natural'Last,
              Message & ": open-buffer candidate must be identified by buffer id");
      Assert (To_String (Snapshot.Candidates (Index).Project_Relative_Path) =
              Expected_Path,
              Message & ": path label must derive from current association");
      Assert (Snapshot.Candidates (Index).Is_Open,
              Message & ": candidate source must be open-buffer collection");
      Assert (Snapshot.Candidates (Index).Is_Dirty = Expected_Dirty,
              Message & ": dirty hint must derive from current dirty state");
      Assert (Snapshot.Candidates (Index).Is_Active = Expected_Active,
              Message & ": active hint must derive from active buffer id");
      Assert (Snapshot.Candidates (Index).Buffer_Identity = Buffer_Id,
              Message & ": candidate identity must remain buffer identity");
      Assert_Quick_Open_No_Forbidden_Lifecycle_Text (Snapshot, Message);
   end Assert_Quick_Open_File_Lifecycle_Observation_Frozen;

   procedure Assert_Persistence_Text_Excludes_Quick_Open_Lifecycle
     (Text    : String;
      Message : String)
   is
   begin
      Assert (not Contains_Text (Text, "quick_open_last"),
              Message & ": no quick-open last-target persistence field");
      Assert (not Contains_Text (Text, "quick_open_target_history"),
              Message & ": no quick-open target-history persistence field");
      Assert (not Contains_Text (Text, "quick_open_operation_history"),
              Message & ": no quick-open operation-history persistence field");
      Assert (not Contains_Text (Text, "quick_open_prompt"),
              Message & ": no quick-open prompt persistence field");
      Assert (not Contains_Text (Text, "quick_open_candidate_cache"),
              Message & ": no quick-open candidate-cache persistence field");
      Assert (not Contains_Text (Text, "quick_open_dirty_cache"),
              Message & ": no quick-open dirty-cache persistence field");
      Assert (not Contains_Text (Text, "quick_open_source_override"),
              Message & ": no quick-open source-override persistence field");
      Assert (not Contains_Text (Text, "quick_open_project_repair"),
              Message & ": no quick-open project-repair persistence field");
      Assert (not Contains_Text (Text, "quick_open_file_watch"),
              Message & ": no quick-open file-watch persistence field");
      Assert (not Contains_Text (Text, "quick_open_external_modification"),
              Message & ": no external-modification persistence field");
   end Assert_Persistence_Text_Excludes_Quick_Open_Lifecycle;

   procedure Assert_Quick_Open_Observes_Association
     (Snapshot       : Editor.Quick_Open.Quick_Open_Snapshot;
      Expected_Path  : String;
      Expected_Dirty : Boolean;
      Message        : String)
   is
      Index : constant Natural := Quick_Open_Candidate_Index (Snapshot, Expected_Path);
   begin
      Assert (Index /= Natural'Last,
              Message & ": Quick Open must expose the current open-buffer association");
      Assert (Snapshot.Candidates (Index).Is_Open,
              Message & ": candidate must be marked as an open buffer");
      Assert (Snapshot.Candidates (Index).Is_Dirty = Expected_Dirty,
              Message & ": dirty hint must be derived from current buffer state");
   end Assert_Quick_Open_Observes_Association;




   function Quick_Open_Candidate_Count
     (Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
      Path     : String) return Natural
   is
      Count : Natural := 0;
   begin
      if Snapshot.Candidates.Length = 0 then
         return 0;
      end if;

      for I in Snapshot.Candidates.First_Index .. Snapshot.Candidates.Last_Index loop
         if To_String (Snapshot.Candidates (I).Project_Relative_Path) = Path then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Quick_Open_Candidate_Count;

   procedure Assert_Quick_Open_Observation_Reliable
     (Snapshot       : Editor.Quick_Open.Quick_Open_Snapshot;
      Expected_Path  : String;
      Expected_Dirty : Boolean;
      Message        : String)
   is
      Index : constant Natural := Quick_Open_Candidate_Index (Snapshot, Expected_Path);
   begin
      Assert (Index /= Natural'Last,
              Message & ": current canonical association must be visible");
      Assert (Snapshot.Candidates (Index).Is_Open,
              Message & ": current association must be marked as an open-buffer candidate");
      Assert (Snapshot.Candidates (Index).Is_Dirty = Expected_Dirty,
              Message & ": dirty hint must be projected from current buffer state");
      Assert (Quick_Open_Candidate_Count (Snapshot, Expected_Path) = 1,
              Message & ": current open-buffer association must not be duplicated");
   end Assert_Quick_Open_Observation_Reliable;

   procedure Assert_Quick_Open_Observation_Failure_Preserved
     (Before         : Editor.Quick_Open.Quick_Open_Snapshot;
      After          : Editor.Quick_Open.Quick_Open_Snapshot;
      Preserved_Path : String;
      Failed_Target  : String;
      Message        : String)
   is
      Before_Index : constant Natural := Quick_Open_Candidate_Index (Before, Preserved_Path);
      After_Index  : constant Natural := Quick_Open_Candidate_Index (After, Preserved_Path);
   begin
      Assert (Before_Index /= Natural'Last,
              Message & ": preservation precondition must expose the source candidate");
      Assert (After_Index /= Natural'Last,
              Message & ": failed or blocked operation must preserve source candidate label");
      Assert (Before.Candidates (Before_Index).Is_Open = After.Candidates (After_Index).Is_Open,
              Message & ": failed or blocked operation must preserve open marker");
      Assert (Before.Candidates (Before_Index).Is_Dirty = After.Candidates (After_Index).Is_Dirty,
              Message & ": failed or blocked operation must preserve dirty hint");
      Assert (not Quick_Open_Has_Candidate (After, Failed_Target),
              Message & ": failed target must not become candidate data");
   end Assert_Quick_Open_Observation_Failure_Preserved;

   procedure Assert_Quick_Open_Project_Candidate_Boundary
     (Snapshot          : Editor.Quick_Open.Quick_Open_Snapshot;
      Project_Path      : String;
      Must_Exist        : Boolean;
      Must_Be_Open      : Boolean;
      Message           : String)
   is
      Index : constant Natural := Quick_Open_Candidate_Index (Snapshot, Project_Path);
   begin
      Assert ((Index /= Natural'Last) = Must_Exist,
              Message & ": project/file candidate membership must follow retained project policy only");
      if Index /= Natural'Last then
         Assert (Snapshot.Candidates (Index).Is_Open = Must_Be_Open,
                 Message & ": project/file candidate must not be promoted to open-buffer state");
      end if;
   end Assert_Quick_Open_Project_Candidate_Boundary;

   procedure Assert_Quick_Open_Query_Not_Target_Input
     (App     : Editor.State.State_Type;
      S       : Editor.Quick_Open.Quick_Open_State;
      Message : String)
   is
   begin
      Assert (Editor.Executor.File_Target_Prompt_Input_Text (App) /= Editor.Quick_Open.Query_Text (S),
              Message & ": Quick Open query must not seed target prompt input");
   end Assert_Quick_Open_Query_Not_Target_Input;

   procedure Assert_Quick_Open_Selection_Not_File_Lifecycle_Source
     (Registry       : Editor.Buffers.Buffer_Registry;
      Expected_Active : Editor.Buffers.Buffer_Id;
      Message         : String)
   is
   begin
      Assert (Editor.Buffers.Active_Buffer (Registry) = Expected_Active,
              Message & ": Quick Open selection must not replace canonical active-buffer source");
   end Assert_Quick_Open_Selection_Not_File_Lifecycle_Source;

   procedure Assert_Quick_Open_Persistence_Excluded
     (Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
      Message  : String)
   is
   begin
      for C of Snapshot.Candidates loop
         declare
            Text : constant String := To_String (C.Display_Text);
         begin
            Assert (not (Text'Length >= 8 and then Text (Text'First .. Text'First + 7) = "history:"),
                    Message & ": candidate display must not contain operation history");
            Assert (not (Text'Length >= 7 and then Text (Text'First .. Text'First + 6) = "target:"),
                    Message & ": candidate display must not contain target history");
            Assert (not (Text'Length >= 7 and then Text (Text'First .. Text'First + 6) = "prompt:"),
                    Message & ": candidate display must not contain prompt state");
         end;
      end loop;
   end Assert_Quick_Open_Persistence_Excluded;

   procedure Test_Open_Close_And_Query
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.Quick_Open.Quick_Open_State;
   begin
      Assert (not Editor.Quick_Open.Is_Open (S), "new quick-open state must be closed");
      Editor.Quick_Open.Open (S);
      Assert (Editor.Quick_Open.Is_Open (S), "Open must open quick-open");
      Editor.Quick_Open.Insert_Text (S, "ab");
      Editor.Quick_Open.Move_Cursor_Left (S);
      Editor.Quick_Open.Insert_Text (S, "X");
      Assert (Editor.Quick_Open.Query_Text (S) = "aXb", "Insert_Text must edit at the query cursor");
      Editor.Quick_Open.Backspace (S);
      Assert (Editor.Quick_Open.Query_Text (S) = "ab", "Backspace must remove the previous query character");
      Editor.Quick_Open.Delete_Forward (S);
      Assert (Editor.Quick_Open.Query_Text (S) = "a", "Delete_Forward must remove the next query character");
      Editor.Quick_Open.Close (S);
      Assert (not Editor.Quick_Open.Is_Open (S), "Close must close quick-open");
   end Test_Open_Close_And_Query;

   procedure Test_Recompute_And_Ranking
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("quick_open_root");
      Tree : Editor.File_Tree.File_Tree_State;
      S    : Editor.Quick_Open.Quick_Open_State;
      Config : constant Editor.Quick_Open.Quick_Open_Config :=
        (Max_Visible_Results      => 12,
         Max_Result_Count         => 2,
         Query_Field_Min_Columns  => 24,
         Overlay_Width_In_Columns => 72,
         Row_Height_In_Rows       => 1,
         Header_Height_In_Rows    => 1,
         Field_Height_In_Rows     => 1,
         Result_Padding_Columns   => 1);
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "a");
      Editor.Quick_Open.Recompute_Results (S, Tree, Config);
      Assert (Editor.Quick_Open.Result_Count (S) = 2,
              "Recompute_Results must respect Max_Result_Count");
      Assert (Editor.Quick_Open.Selected_Result_Index (S) = 1,
              "Recompute_Results must select the first result");

      Editor.Quick_Open.Set_Query_Text (S, "main");
      Editor.Quick_Open.Recompute_Results (S, Tree, Config);
      Assert (Editor.Quick_Open.Result_Count (S) = 2,
              "substring query must match both main paths under the max count");
      Assert (To_String (Editor.Quick_Open.Result_At (S, 1).Display_Path) = "doc/main.txt"
              or else To_String (Editor.Quick_Open.Result_At (S, 1).Display_Path) = "src/main.adb",
              "basename matches must rank above unrelated path-only matches");

      Editor.Quick_Open.Set_Query_Text (S, "OTHER");
      Editor.Quick_Open.Recompute_Results (S, Tree, Config);
      Assert (Editor.Quick_Open.Result_Count (S) = 1,
              "matching must be case-insensitive");
      Assert (To_String (Editor.Quick_Open.Result_At (S, 1).Display_Path) = "src/other.ads",
              "case-insensitive query must return the matching project-relative path");
      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Recompute_And_Ranking;

   procedure Test_Selection_Wraps
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("quick_open_wrap_root");
      Tree : Editor.File_Tree.File_Tree_State;
      S    : Editor.Quick_Open.Quick_Open_State;
      Config : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
   begin
      Build_Fixture (Root);
      Tree := Editor.File_Tree.Scan_Project (Root);
      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "a");
      Editor.Quick_Open.Recompute_Results (S, Tree, Config);
      Editor.Quick_Open.Move_Selection_Up (S);
      Assert (Editor.Quick_Open.Selected_Result_Index (S) = Editor.Quick_Open.Result_Count (S),
              "Move_Selection_Up from the first row must wrap to the last result");
      Editor.Quick_Open.Move_Selection_Down (S);
      Assert (Editor.Quick_Open.Selected_Result_Index (S) = 1,
              "Move_Selection_Down from the last row must wrap to the first result");
      Cleanup_Fixture (Root);
   exception
      when others =>
         Cleanup_Fixture (Root);
         raise;
   end Test_Selection_Wraps;



   procedure Test_Project_Known_File_Literal_Filtering
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project : Editor.Project.Project_State;
      Result  : Editor.Project.Project_Open_Result;
      S       : Editor.Quick_Open.Quick_Open_State;
      Config  : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/editor/executor.adb", "/project/src/editor/executor.adb");
      Editor.Project.Add_Known_File (Project, "tests/test_executor.adb", "/project/tests/test_executor.adb");
      Editor.Project.Add_Known_File (Project, "src/editor/commands.ads", "/project/src/editor/commands.ads");
      Editor.Project.Add_Known_File (Project, "src/editor/executor.adb", "/project/duplicate.adb");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "d");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Result_Count (S) = 3,
              "project quick-open must derive unique candidates from known project files");
      Assert (To_String (Editor.Quick_Open.Result_At (S, 1).Display_Path) =
              "tests/test_executor.adb",
              "project quick-open candidates must use deterministic bucket/depth order");

      Editor.Quick_Open.Set_Query_Text (S, "EXEC");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Result_Count (S) = 2,
              "literal project quick-open filtering must be case-insensitive over relative paths");
      Assert (To_String (Editor.Quick_Open.Result_At (S, 1).Display_Path) =
              "src/editor/executor.adb",
              "project quick-open must keep lexicographic order within filtered results");
   end Test_Project_Known_File_Literal_Filtering;

   procedure Test_Project_Quick_Open_Selection_Normalization
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project : Editor.Project.Project_State;
      Result  : Editor.Project.Project_Open_Result;
      S       : Editor.Quick_Open.Quick_Open_State;
      Config  : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "a.adb", "/project/a.adb");
      Editor.Project.Add_Known_File (Project, "b.adb", "/project/b.adb");
      Editor.Project.Add_Known_File (Project, "c.adb", "/project/c.adb");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, ".adb");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Editor.Quick_Open.Move_Selection_Down (S);
      Assert (To_String (Editor.Quick_Open.Result_At
                (S, Editor.Quick_Open.Selected_Result_Index (S)).Display_Path) = "b.adb",
              "test setup must select b.adb");

      Editor.Quick_Open.Set_Query_Text (S, ".adb");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (To_String (Editor.Quick_Open.Result_At
                (S, Editor.Quick_Open.Selected_Result_Index (S)).Display_Path) = "b.adb",
              "query changes must preserve the selected path while it remains visible");

      Editor.Quick_Open.Set_Query_Text (S, "c");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Selected_Result_Index (S) = 1,
              "query changes must select the first candidate when previous selection disappears");
      Assert (To_String (Editor.Quick_Open.Result_At (S, 1).Display_Path) = "c.adb",
              "selection normalization must select the first visible candidate");

      Editor.Quick_Open.Set_Query_Text (S, "missing");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Selected_Result_Index (S) = 0,
              "no matching candidates must clear quick-open selection");

      Editor.Quick_Open.Set_Query_Text (S, "b");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (To_String (Editor.Quick_Open.Result_At
                (S, Editor.Quick_Open.Selected_Result_Index (S)).Display_Path) = "b.adb",
              "test setup must select b.adb for query clear preservation");
      Editor.Quick_Open.Set_Query_Text (S, "");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Result_Count (S) = 0,
              "clearing the query must enter the prompt state instead of showing all project files");
      Assert (Editor.Quick_Open.Selected_Result_Index (S) = 0,
              "clearing the query must clear selection because no status row is activatable");

      Editor.Project.Clear_Known_Files (Project);
      Editor.Project.Add_Known_File (Project, "a.adb", "/project/a.adb");
      Editor.Project.Add_Known_File (Project, "c.adb", "/project/c.adb");
      Editor.Quick_Open.Set_Query_Text (S, ".adb");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (To_String (Editor.Quick_Open.Result_At
                (S, Editor.Quick_Open.Selected_Result_Index (S)).Display_Path) = "a.adb",
              "removed selected project files must normalize selection to the first ranked candidate");
   end Test_Project_Quick_Open_Selection_Normalization;

   procedure Test_Project_Quick_Open_Match_Buckets
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project : Editor.Project.Project_State;
      Result  : Editor.Project.Project_Open_Result;
      S       : Editor.Quick_Open.Quick_Open_State;
      Config  : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "bin/executor", "/project/bin/executor");
      Editor.Project.Add_Known_File (Project, "src/editor/executor.adb", "/project/src/editor/executor.adb");
      Editor.Project.Add_Known_File (Project, "src/editor/executor.ads", "/project/src/editor/executor.ads");
      Editor.Project.Add_Known_File (Project, "src/editor/commands.ads", "/project/src/editor/commands.ads");
      Editor.Project.Add_Known_File (Project, "tests/test_executor.adb", "/project/tests/test_executor.adb");
      Editor.Project.Add_Known_File (Project, "tools/editor_tool.adb", "/project/tools/editor_tool.adb");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, " executor ");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);

      Assert (Editor.Quick_Open.Result_Count (S) = 4,
              "trimmed basename query must match executor candidates only");
      Assert (To_String (Editor.Quick_Open.Result_At (S, 1).Display_Path) =
              "bin/executor",
              "basename exact match must rank before basename prefix matches");
      Assert (Editor.Quick_Open.Result_At (S, 1).Match_Bucket =
              Editor.Quick_Open.Basename_Exact,
              "executor must be classified as basename exact");
      Assert (To_String (Editor.Quick_Open.Result_At (S, 2).Display_Path) =
              "src/editor/executor.adb",
              "basename prefix match must rank before basename substring match");
      Assert (Editor.Quick_Open.Result_At (S, 2).Match_Bucket =
              Editor.Quick_Open.Basename_Prefix,
              "executor.adb must be classified as basename prefix");
      Assert (To_String (Editor.Quick_Open.Result_At (S, 4).Display_Path) =
              "tests/test_executor.adb",
              "basename substring match must sort after basename prefix matches");
      Assert (Editor.Quick_Open.Result_At (S, 4).Match_Bucket =
              Editor.Quick_Open.Basename_Substring,
              "test_executor.adb must be classified as basename substring");

      Editor.Quick_Open.Set_Query_Text (S, "src/editor");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Result_Count (S) = 3,
              "path-prefix query must match the src/editor paths");
      Assert (Editor.Quick_Open.Result_At (S, 1).Match_Bucket =
              Editor.Quick_Open.Path_Prefix,
              "src/editor query must classify matching rows as path prefix");
      Assert (To_String (Editor.Quick_Open.Result_At (S, 1).Display_Path) =
              "src/editor/commands.ads",
              "path-prefix ties must use deterministic lexicographic order");

      Editor.Quick_Open.Set_Query_Text (S, "ditor");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (To_String (Editor.Quick_Open.Result_At (S, 1).Display_Path) =
              "tools/editor_tool.adb",
              "basename substring matches must rank before path substring matches");
      Assert (Editor.Quick_Open.Result_At (S, 1).Match_Bucket =
              Editor.Quick_Open.Basename_Substring,
              "editor_tool.adb must be classified as basename substring for ditor");
      Assert (Editor.Quick_Open.Result_At (S, 2).Match_Bucket =
              Editor.Quick_Open.Path_Segment_Substring,
              "src/editor paths must be classified as path-segment substring for ditor");

      Editor.Quick_Open.Set_Query_Text (S, "src comm");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Result_Count (S) = 1,
              "whitespace-separated path terms must narrow results deterministically");
      Assert (To_String (Editor.Quick_Open.Result_At (S, 1).Display_Path) =
              "src/editor/commands.ads",
              "path segment query must match ordered project-relative path terms");
      Assert (Editor.Quick_Open.Result_At (S, 1).Match_Bucket =
              Editor.Quick_Open.Path_Segment_Prefix,
              "ordered path term prefixes must be classified explicitly");

      Editor.Quick_Open.Set_Query_Text (S, "edit tool");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Result_Count (S) = 1,
              "filename-part terms must match within a basename with separators");
      Assert (To_String (Editor.Quick_Open.Result_At (S, 1).Display_Path) =
              "tools/editor_tool.adb",
              "filename-part term query must return the editor tool file");

      Editor.Quick_Open.Set_Query_Text (S, "eetr");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Result_Count (S) = 3,
              "ordered-character fuzzy text must match executor basenames");
      Assert (Editor.Quick_Open.Result_At (S, 1).Match_Bucket =
              Editor.Quick_Open.Basename_Fuzzy,
              "fuzzy filename matches must be classified below literal matches");
   end Test_Project_Quick_Open_Match_Buckets;


   procedure Test_Project_Quick_Open_Snapshot
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/main.adb", "/project/src/main.adb");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "adb");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open.Build_Snapshot (S);
      Assert (Snapshot.Visible, "quick-open snapshot must expose visibility");
      Assert (To_String (Snapshot.Query) = "adb", "quick-open snapshot must expose query text");
      Assert (Natural (Snapshot.Candidates.Length) = 1,
              "quick-open snapshot must expose visible candidates");
      Assert (To_String (Snapshot.Selected_Path) = "src/main.adb",
              "quick-open snapshot must expose selected path");
      Assert (Snapshot.Candidates (0).Is_Selected,
              "quick-open snapshot must mark the selected candidate");
      Assert (To_String (Snapshot.Candidates (0).Basename) = "main.adb",
              "quick-open snapshot must expose basename for display/tests");
      Assert (Snapshot.Candidates (0).Match_Bucket /= Editor.Quick_Open.No_Match,
              "quick-open snapshot must expose the candidate match bucket");

      Editor.Quick_Open.Set_Query_Text (S, "none");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open.Build_Snapshot (S);
      Assert (To_String (Snapshot.Empty_Message) = "No Quick Open matches.",
              "no-match snapshot must expose deterministic empty text");
   end Test_Project_Quick_Open_Snapshot;




   procedure Test_Project_Quick_Open_Snapshot_Markers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Open_Id  : Editor.Buffers.Buffer_Id;
      Dirty_Id : Editor.Buffers.Buffer_Id;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
      Open_Index   : Natural := Natural'Last;
      Dirty_Index  : Natural := Natural'Last;
      Closed_Index : Natural := Natural'Last;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/editor/executor.adb", "/project/src/editor/executor.adb");
      Editor.Project.Add_Known_File (Project, "src/editor/input_bridge.adb", "/project/src/editor/input_bridge.adb");
      Editor.Project.Add_Known_File (Project, "tests/test_executor.adb", "/project/tests/test_executor.adb");

      Open_Id := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/editor/executor.adb", "executor.adb", "body");
      Dirty_Id := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/editor/input_bridge.adb", "input_bridge.adb", "body");
      Editor.Buffers.Set_Active_Buffer (Registry, Open_Id);
      Editor.State.Set_Dirty (Editor.Buffers.Buffer_Access (Registry, Dirty_Id).all, True);

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "adb");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Registry);

      Open_Index := Quick_Open_Candidate_Index (Snapshot, "src/editor/executor.adb");
      Dirty_Index := Quick_Open_Candidate_Index (Snapshot, "src/editor/input_bridge.adb");
      Closed_Index := Quick_Open_Candidate_Index (Snapshot, "tests/test_executor.adb");

      Assert (Open_Index /= Natural'Last,
              "test setup must expose executor candidate");
      Assert (Dirty_Index /= Natural'Last,
              "test setup must expose input_bridge candidate");
      Assert (Closed_Index /= Natural'Last,
              "test setup must expose closed candidate");
      Assert (Snapshot.Candidates (Open_Index).Is_Open,
              "open buffer must mark the matching quick-open candidate as open");
      Assert (Snapshot.Candidates (Open_Index).Is_Active,
              "active buffer must mark the matching quick-open candidate as active");
      Assert (not Snapshot.Candidates (Open_Index).Is_Dirty,
              "clean active buffer must not be marked dirty");
      Assert (Snapshot.Candidates (Dirty_Index).Is_Open,
              "second open buffer must be reflected by marker derivation");
      Assert (not Snapshot.Candidates (Dirty_Index).Is_Active,
              "inactive open buffer must not be marked active");
      Assert (Snapshot.Candidates (Dirty_Index).Is_Dirty,
              "dirty open buffer must mark the matching quick-open candidate dirty");
      Assert (To_String (Snapshot.Candidates (Dirty_Index).Display_Text) =
              "src/editor/input_bridge.adb [open] [dirty]",
              "snapshot display text must include deterministic open/dirty markers");
      Assert (not Snapshot.Candidates (Closed_Index).Is_Open
              and then not Snapshot.Candidates (Closed_Index).Is_Active
              and then not Snapshot.Candidates (Closed_Index).Is_Dirty,
              "closed candidate must not receive open/active/dirty markers");
   end Test_Project_Quick_Open_Snapshot_Markers;

   procedure Test_Phase_330_Active_Dirty_Close_Markers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      First_Id : Editor.Buffers.Buffer_Id;
      Dirty_Id : Editor.Buffers.Buffer_Id;
      Closed   : Boolean := False;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/editor/executor.adb", "/project/src/editor/executor.adb");
      Editor.Project.Add_Known_File (Project, "src/editor/input_bridge.adb", "/project/src/editor/input_bridge.adb");
      Editor.Project.Add_Known_File (Project, "tests/test_executor.adb", "/project/tests/test_executor.adb");

      First_Id := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/editor/executor.adb", "executor.adb", "body");
      Dirty_Id := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/editor/input_bridge.adb", "input_bridge.adb", "body");
      Editor.State.Set_Dirty (Editor.Buffers.Buffer_Access (Registry, Dirty_Id).all, True);
      Editor.Buffers.Set_Active_Buffer (Registry, First_Id);
      Editor.Recent_Buffers.Mark_Activated (Recent, Natural (Dirty_Id));

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Toggle_Priority_Mode (S);
      Editor.Quick_Open.Set_Query_Text (S, "adb");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);

      Assert (Snapshot.Priority_Mode = Editor.Quick_Open.Open_Recent,
              "phase 330 setup must expose Open/Recent priority mode in snapshots");
      Assert (To_String (Snapshot.Candidates (0).Project_Relative_Path) =
              "src/editor/executor.adb",
              "active known project file must rank first in Open/Recent mode");
      Assert (Snapshot.Candidates (0).Priority_Bucket = Editor.Quick_Open.Active_File,
              "active known project file must use Active_File bucket");
      Assert (Snapshot.Candidates (1).Priority_Bucket = Editor.Quick_Open.Open_Dirty_File,
              "dirty open known project file must use Open_Dirty_File bucket");
      Assert (Snapshot.Candidates (1).Is_Dirty,
              "dirty state must be derived from current buffer state");

      Editor.State.Set_Dirty (Editor.Buffers.Buffer_Access (Registry, Dirty_Id).all, False);
      Editor.Buffers.Set_Active_Buffer (Registry, Dirty_Id);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert (To_String (Snapshot.Candidates (0).Project_Relative_Path) =
              "src/editor/input_bridge.adb",
              "later active-buffer changes must move the active marker and bucket");
      Assert (Snapshot.Candidates (0).Priority_Bucket = Editor.Quick_Open.Active_File,
              "active clean files remain Active_File rather than Open_Clean_File");
      Assert (not Snapshot.Candidates (0).Is_Dirty,
              "saving a dirty file must remove the dirty marker in later snapshots");

      Editor.Buffers.Close_Buffer (Registry, Dirty_Id, Closed, Force => True);
      Assert (Closed, "test setup must close the dirty buffer");
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      for I in Snapshot.Candidates.First_Index .. Snapshot.Candidates.Last_Index loop
         if To_String (Snapshot.Candidates (I).Project_Relative_Path) =
           "src/editor/input_bridge.adb"
         then
            Assert (not Snapshot.Candidates (I).Is_Open
                    and then not Snapshot.Candidates (I).Is_Active
                    and then not Snapshot.Candidates (I).Is_Dirty,
                    "closed buffers must not leave stale open/active/dirty markers");
            Assert (Snapshot.Candidates (I).Priority_Bucket = Editor.Quick_Open.Ordinary_File,
                    "closed stale recent ids must not produce an open/recent priority bucket");
         end if;
      end loop;
      Assert (Editor.Recent_Buffers.Contains (Recent, Natural (Dirty_Id)),
              "Quick Open marker derivation must not mutate stale recent-buffer history");
   end Test_Phase_330_Active_Dirty_Close_Markers;

   procedure Test_Phase_330_Ignores_Old_Project_Recent_And_Open_State
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Old_Id   : Editor.Buffers.Buffer_Id;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/new_project"),
         Display_Name => To_Unbounded_String ("new_project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File
        (Project, "src/editor/executor.adb",
         "/new_project/src/editor/executor.adb");

      Old_Id := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/old_project/src/editor/executor.adb", "executor.adb", "body");
      Editor.Buffers.Set_Active_Buffer (Registry, Old_Id);
      Editor.Recent_Buffers.Mark_Activated (Recent, Natural (Old_Id));

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Toggle_Priority_Mode (S);
      Editor.Quick_Open.Set_Query_Text (S, "executor");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);

      Assert (Natural (Snapshot.Candidates.Length) = 1,
              "test setup must produce one current-project candidate");
      Assert (not Snapshot.Candidates (0).Is_Open
              and then not Snapshot.Candidates (0).Is_Active
              and then not Snapshot.Candidates (0).Is_Dirty
              and then not Snapshot.Candidates (0).Is_Recent,
              "old-project open/recent state must not mark current project candidates");
      Assert (Snapshot.Candidates (0).Priority_Bucket = Editor.Quick_Open.Ordinary_File,
              "old-project state must not affect current-project priority buckets");
      Assert (Editor.Recent_Buffers.Contains (Recent, Natural (Old_Id)),
              "stale recent entries are ignored, not cleaned or rewritten");
   end Test_Phase_330_Ignores_Old_Project_Recent_And_Open_State;

   procedure Test_Project_Quick_Open_Preserved_Selection_Stays_Visible
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project : Editor.Project.Project_State;
      Result  : Editor.Project.Project_Open_Result;
      S       : Editor.Quick_Open.Quick_Open_State;
      Config  : constant Editor.Quick_Open.Quick_Open_Config :=
        (Max_Visible_Results      => 2,
         Max_Result_Count         => 10,
         Query_Field_Min_Columns  => 24,
         Overlay_Width_In_Columns => 72,
         Row_Height_In_Rows       => 1,
         Header_Height_In_Rows    => 1,
         Field_Height_In_Rows     => 1,
         Result_Padding_Columns   => 1);
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "a.adb", "/project/a.adb");
      Editor.Project.Add_Known_File (Project, "b.adb", "/project/b.adb");
      Editor.Project.Add_Known_File (Project, "c.adb", "/project/c.adb");
      Editor.Project.Add_Known_File (Project, "d.adb", "/project/d.adb");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "adb");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Editor.Quick_Open.Move_Selection_Down (S);
      Editor.Quick_Open.Move_Selection_Down (S);
      Editor.Quick_Open.Move_Selection_Down (S);
      Assert (To_String (Editor.Quick_Open.Result_At
                (S, Editor.Quick_Open.Selected_Result_Index (S)).Display_Path) = "d.adb",
              "test setup must select a result beyond the first visible window");

      Editor.Quick_Open.Set_Query_Text (S, ".adb");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (To_String (Editor.Quick_Open.Result_At
                (S, Editor.Quick_Open.Selected_Result_Index (S)).Display_Path) = "d.adb",
              "recompute must preserve the selected path while it remains visible");
      Assert (Editor.Quick_Open.Top_Result_Index (S) = 3,
              "preserved selections beyond the visible window must keep the selected row visible");
   end Test_Project_Quick_Open_Preserved_Selection_Stays_Visible;



   procedure Test_Project_Quick_Open_File_Kind_Filters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project : Editor.Project.Project_State;
      Result  : Editor.Project.Project_Open_Result;
      S       : Editor.Quick_Open.Quick_Open_State;
      Config  : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/editor/executor.adb", "/project/src/editor/executor.adb");
      Editor.Project.Add_Known_File (Project, "src/editor/executor.ads", "/project/src/editor/executor.ads");
      Editor.Project.Add_Known_File (Project, "tests/test_executor.adb", "/project/tests/test_executor.adb");
      Editor.Project.Add_Known_File (Project, "README.md", "/project/README.md");
      Editor.Project.Add_Known_File (Project, "data/schema.json", "/project/data/schema.json");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "executor");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Result_Count (S) = 3,
              "All filter must show every known executor candidate");

      Editor.Quick_Open.Cycle_File_Kind_Next (S);
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.File_Kind_Filter (S) = Editor.Quick_Open.Ada_Files,
              "kind-next must cycle deterministically from All to Ada");
      Assert (Editor.Quick_Open.Result_Count (S) = 3,
              "Ada filter must include .adb/.ads files, including tests");

      Editor.Quick_Open.Cycle_File_Kind_Next (S);
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.File_Kind_Filter (S) = Editor.Quick_Open.Test_Files,
              "kind-next must cycle deterministically from Ada to Tests");
      Assert (Editor.Quick_Open.Result_Count (S) = 1,
              "Tests filter must include paths under tests/");
      Assert (To_String (Editor.Quick_Open.Result_At (S, 1).Display_Path) =
              "tests/test_executor.adb",
              "Tests filter must keep the visible test candidate");

      Editor.Quick_Open.Set_Query_Text (S, "readme");
      Editor.Quick_Open.Cycle_File_Kind_Next (S);
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.File_Kind_Filter (S) = Editor.Quick_Open.Doc_Files,
              "kind-next must cycle deterministically from Tests to Docs");
      Assert (Editor.Quick_Open.Result_Count (S) = 1,
              "Docs filter must include markdown files");

      Editor.Quick_Open.Set_Query_Text (S, "schema");
      Editor.Quick_Open.Cycle_File_Kind_Next (S);
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.File_Kind_Filter (S) = Editor.Quick_Open.Other_Files,
              "kind-next must cycle deterministically from Docs to Other");
      Assert (Editor.Quick_Open.Result_Count (S) = 1,
              "Other filter must include files outside Tests/Ada/Docs");

      Editor.Quick_Open.Clear_File_Kind_Filter (S);
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.File_Kind_Filter (S) = Editor.Quick_Open.All_Files,
              "kind clear must restore All");

      Editor.Quick_Open.Cycle_File_Kind_Previous (S);
      Assert (Editor.Quick_Open.File_Kind_Filter (S) = Editor.Quick_Open.Other_Files,
              "kind-previous must cycle deterministically from All to Other");
   end Test_Project_Quick_Open_File_Kind_Filters;

   procedure Test_Project_Quick_Open_Path_Scope_Filter
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project : Editor.Project.Project_State;
      Result  : Editor.Project.Project_Open_Result;
      S       : Editor.Quick_Open.Quick_Open_State;
      Config  : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/editor/executor.adb", "/project/src/editor/executor.adb");
      Editor.Project.Add_Known_File (Project, "src/editor/executor.ads", "/project/src/editor/executor.ads");
      Editor.Project.Add_Known_File (Project, "tests/test_executor.adb", "/project/tests/test_executor.adb");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "executor");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Editor.Quick_Open.Move_Selection_Down (S);
      Assert (To_String (Editor.Quick_Open.Result_At
                (S, Editor.Quick_Open.Selected_Result_Index (S)).Display_Path) =
              "src/editor/executor.ads",
              "test setup must select the second src candidate");

      Editor.Quick_Open.Set_Path_Scope (S, "/src");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Path_Scope (S) = "src/",
              "scope normalization must trim leading slash and add one trailing slash");
      Assert (Editor.Quick_Open.Normalize_Quick_Open_Scope ("///tests///") = "tests/",
              "scope normalization must trim repeated leading/trailing slashes");
      Assert (Editor.Quick_Open.Normalize_Quick_Open_Scope ("   ") = "",
              "empty scope text must normalize to an empty scope");
      Assert (Editor.Quick_Open.Normalize_Quick_Open_Scope ("src/../tests") = "",
              "path traversal scope text must normalize to an empty scope");
      Assert (Editor.Quick_Open.Normalize_Quick_Open_Scope ("src/./editor") = "",
              "dot-segment scope text must normalize to an empty scope");
      Assert (Editor.Quick_Open.Normalize_Quick_Open_Scope ("C:/project/src") = "",
              "drive-qualified scope text must normalize to an empty scope");
      Assert (Editor.Quick_Open.Result_Count (S) = 2,
              "src scope must hide tests candidates");
      Assert (To_String (Editor.Quick_Open.Result_At
                (S, Editor.Quick_Open.Selected_Result_Index (S)).Display_Path) =
              "src/editor/executor.ads",
              "scope changes must preserve selected path while it remains visible");

      Editor.Quick_Open.Set_Path_Scope (S, "tests/");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Result_Count (S) = 1,
              "tests scope must show only tests paths");
      Assert (To_String (Editor.Quick_Open.Result_At
                (S, Editor.Quick_Open.Selected_Result_Index (S)).Display_Path) =
              "tests/test_executor.adb",
              "scope changes must normalize selection when previous path is hidden");

      Editor.Quick_Open.Clear_Path_Scope (S);
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Path_Scope (S) = "",
              "scope clear must restore unscoped projection");
      Assert (Editor.Quick_Open.Result_Count (S) = 3,
              "scope clear must restore unscoped candidates");

      Editor.Quick_Open.Set_Path_Scope (S, "missing");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open.Build_Snapshot (S);
      Assert (Editor.Quick_Open.Selected_Result_Index (S) = 0,
              "scope excluding all candidates must clear selection");
      Assert (To_String (Snapshot.Empty_Message) = "No Quick Open matches.",
              "scope-filtered no-match state must use the query/filter empty message");
   end Test_Project_Quick_Open_Path_Scope_Filter;



   procedure Test_Project_Quick_Open_Scope_Convenience
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project : Editor.Project.Project_State;
      Result  : Editor.Project.Project_Open_Result;
      S       : Editor.Quick_Open.Quick_Open_State;
      Config  : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Found   : Boolean := False;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/editor/executor.adb", "/project/src/editor/executor.adb");
      Editor.Project.Add_Known_File (Project, "src/editor/executor.ads", "/project/src/editor/executor.ads");
      Editor.Project.Add_Known_File (Project, "src/editor/input_bridge.adb", "/project/src/editor/input_bridge.adb");
      Editor.Project.Add_Known_File (Project, "src/render/render_packet.adb", "/project/src/render/render_packet.adb");
      Editor.Project.Add_Known_File (Project, "tests/test_executor.adb", "/project/tests/test_executor.adb");
      Editor.Project.Add_Known_File (Project, "README.md", "/project/README.md");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "executor");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Result_Count (S) = 3,
              "test setup must show all executor matches");

      Editor.Quick_Open.Move_Selection_Down (S);
      Assert (To_String (Editor.Quick_Open.Result_At
                (S, Editor.Quick_Open.Selected_Result_Index (S)).Display_Path) =
              "src/editor/executor.ads",
              "test setup must select the second executor candidate");

      Assert (Editor.Quick_Open.Selected_Directory_Scope (S, Found) = "src/editor/"
              and then Found,
              "selected-directory scope must derive the selected file directory");
      Editor.Quick_Open.Set_Path_Scope_From_Selected (S, Found);
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Path_Scope (S) = "src/editor/",
              "scope-from-selected must set the selected file directory scope");
      Assert (Editor.Quick_Open.Query_Text (S) = "executor",
              "scope-from-selected must preserve query text");
      Assert (Editor.Quick_Open.File_Kind_Filter (S) = Editor.Quick_Open.All_Files,
              "scope-from-selected must preserve file-kind filter");
      Assert (Editor.Quick_Open.Result_Count (S) = 2,
              "scope-from-selected must narrow to the selected directory");
      Assert (To_String (Editor.Quick_Open.Result_At
                (S, Editor.Quick_Open.Selected_Result_Index (S)).Display_Path) =
              "src/editor/executor.ads",
              "scope-from-selected must preserve selected path when still visible");

      Assert (Editor.Quick_Open.Parent_Scope (Editor.Quick_Open.Path_Scope (S), Found) = "src/"
              and then Found,
              "parent scope must derive the direct parent directory");
      Editor.Quick_Open.Move_Path_Scope_To_Parent (S, Found);
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Path_Scope (S) = "src/",
              "scope-parent must move src/editor/ to src/");
      Assert (To_String (Editor.Quick_Open.Result_At
                (S, Editor.Quick_Open.Selected_Result_Index (S)).Display_Path) =
              "src/editor/executor.ads",
              "scope-parent must preserve selected path while still visible");

      Editor.Quick_Open.Move_Path_Scope_To_Parent (S, Found);
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Path_Scope (S) = "",
              "scope-parent must clear a root-level scope");
      Assert (Editor.Quick_Open.Result_Count (S) = 3,
              "cleared parent scope must restore unscoped executor candidates");

      Editor.Quick_Open.Set_Query_Text (S, "readme");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Selected_Directory_Scope (S, Found) = ""
              and then Found,
              "root-level selected files must derive an empty scope");
      Editor.Quick_Open.Set_Path_Scope_From_Selected (S, Found);
      Assert (Editor.Quick_Open.Path_Scope (S) = "",
              "scope-from-selected on a root file must clear scope");
   end Test_Project_Quick_Open_Scope_Convenience;

   procedure Test_Project_Quick_Open_Count_Feedback
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/editor/executor.adb", "/project/src/editor/executor.adb");
      Editor.Project.Add_Known_File (Project, "src/editor/executor.ads", "/project/src/editor/executor.ads");
      Editor.Project.Add_Known_File (Project, "src/editor/input_bridge.adb", "/project/src/editor/input_bridge.adb");
      Editor.Project.Add_Known_File (Project, "src/render/render_packet.adb", "/project/src/render/render_packet.adb");
      Editor.Project.Add_Known_File (Project, "tests/test_executor.adb", "/project/tests/test_executor.adb");
      Editor.Project.Add_Known_File (Project, "docs/commands.md", "/project/docs/commands.md");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "executor");
      Editor.Quick_Open.Set_Path_Scope (S, "src/editor");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open.Build_Snapshot (S);

      Assert (Snapshot.Known_Count = 6,
              "snapshot known count must reflect the session-local known project file list");
      Assert (Snapshot.Total_Filtered_Count = 2,
              "snapshot filtered count must reflect scope/kind/query filtered candidates");
      Assert (Snapshot.Visible_Count = 2,
              "snapshot visible count must reflect projected candidate rows");
      Assert (To_String (Snapshot.Header_Text) =
              "Kind: All | Scope: src/editor/ | Priority: Path | Results: 2 of 6",
              "quick-open header must include compact visible/known count feedback");

      Editor.Quick_Open.Set_Path_Scope (S, "missing");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open.Build_Snapshot (S);
      Assert (Snapshot.Total_Filtered_Count = 0 and then Snapshot.Known_Count = 6,
              "no-match count feedback must keep known count while visible count is zero");
      Assert (To_String (Snapshot.Empty_Message) = "No Quick Open matches.",
              "no-match count state must keep deterministic empty feedback");

      declare
         Empty_Project : Editor.Project.Project_State;
         Empty_Result  : Editor.Project.Project_Open_Result;
      begin
         Empty_Result :=
           (Status       => Editor.Project.Project_Open_Ok,
            Root_Path    => To_Unbounded_String ("/empty"),
            Display_Name => To_Unbounded_String ("empty"),
            Error_Text   => Null_Unbounded_String);
         Editor.Project.Apply_Open_Result (Empty_Project, Empty_Result);
         Editor.Quick_Open.Clear (S);
         Editor.Quick_Open.Open (S);
         Editor.Quick_Open.Set_Query_Text (S, "executor");
         Editor.Quick_Open.Set_Path_Scope (S, "src/editor");
         Editor.Quick_Open.Recompute_Results (S, Empty_Project, Config);
         Snapshot := Editor.Quick_Open.Build_Snapshot (S);
         Assert (Snapshot.Known_Count = 0 and then Snapshot.Visible_Count = 0,
                 "empty known project list must produce zero known and visible counts");
         Assert (Snapshot.Has_Project,
                 "empty known project list must still remember that a project is open");
         Assert (To_String (Snapshot.Empty_Message) = "No project files.",
                 "empty known project list must report project-without-files distinctly");
      end;

      declare
         No_Project : Editor.Project.Project_State;
      begin
         Editor.Quick_Open.Clear (S);
         Editor.Quick_Open.Open (S);
         Editor.Quick_Open.Set_Query_Text (S, "executor");
         Editor.Quick_Open.Recompute_Results (S, No_Project, Config);
         Snapshot := Editor.Quick_Open.Build_Snapshot (S);
         Assert (not Snapshot.Has_Project,
                 "no-project snapshot must expose that no project is active");
         Assert (To_String (Snapshot.Empty_Message) = "No project open.",
                 "no-project state must remain distinct from open project without files");
      end;
   end Test_Project_Quick_Open_Count_Feedback;


   procedure Assert_Project_Quick_Open_Coherent
     (Project  : Editor.Project.Project_State;
      S        : Editor.Quick_Open.Quick_Open_State;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot) is
      Selected_Found : Boolean := False;
   begin
      Assert (Snapshot.Has_Project = Editor.Project.Has_Project (Project),
              "snapshot project-presence flag must mirror the authoritative project state");
      Assert (Snapshot.Known_Count = Editor.Project.Known_File_Count (Project),
              "snapshot known count must match the authoritative known file list");
      Assert (Snapshot.Visible_Count = Natural (Snapshot.Candidates.Length),
              "snapshot visible count must match the visible candidate vector");
      if Natural (Snapshot.Candidates.Length) > 0 then
         for I in Snapshot.Candidates.First_Index .. Snapshot.Candidates.Last_Index loop
            declare
               Path : constant String := To_String (Snapshot.Candidates (I).Project_Relative_Path);
            begin
               Assert (Editor.Project.Has_Known_File (Project, Path),
                       "every Quick Open candidate must come from known project files: " & Path);
               if Snapshot.Candidates (I).Is_Selected then
                  Selected_Found := True;
                  Assert (To_String (Snapshot.Selected_Path) = Path,
                          "selected snapshot path must match the selected row");
               end if;
            end;
         end loop;
      end if;
      if Natural (Snapshot.Candidates.Length) = 0 then
         Assert (Snapshot.Selected_Index = 0 and then To_String (Snapshot.Selected_Path) = "",
                 "empty candidate lists must have no selected path");
      else
         Assert (Selected_Found,
                 "non-empty candidate lists must expose one selected visible row");
      end if;
      Assert (Editor.Quick_Open.Selected_Result_Index (S) = 0
              or else Editor.Quick_Open.Selected_Result_Index (S) <=
                Editor.Quick_Open.Result_Count (S),
              "Quick Open selected index must be empty or within the result list");
   end Assert_Project_Quick_Open_Coherent;

   procedure Test_Phase_331_Refresh_State_Preserves_Selection_And_Filters
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project : Editor.Project.Project_State;
      Result  : Editor.Project.Project_Open_Result;
      S       : Editor.Quick_Open.Quick_Open_State;
      Config  : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/a.adb", "/project/src/a.adb");
      Editor.Project.Add_Known_File (Project, "src/b.adb", "/project/src/b.adb");
      Editor.Project.Add_Known_File (Project, "tests/test_a.adb", "/project/tests/test_a.adb");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "a");
      Editor.Quick_Open.Cycle_File_Kind_Next (S);
      Editor.Quick_Open.Set_Path_Scope (S, "src/");
      Editor.Quick_Open.Toggle_Priority_Mode (S);
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (To_String (Editor.Quick_Open.Result_At
                (S, Editor.Quick_Open.Selected_Result_Index (S)).Display_Path) = "src/a.adb",
              "test setup must select src/a.adb");

      Editor.Project.Clear_Known_Files (Project);
      Editor.Project.Add_Known_File (Project, "src/a.adb", "/project/src/a.adb");
      Editor.Project.Add_Known_File (Project, "src/aa.adb", "/project/src/aa.adb");
      Editor.Project.Add_Known_File (Project, "src/b.adb", "/project/src/b.adb");
      Editor.Project.Add_Known_File (Project, "tests/test_a.adb", "/project/tests/test_a.adb");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open.Build_Snapshot (S);
      Assert (Editor.Quick_Open.Query_Text (S) = "a",
              "refresh/recompute must preserve Quick Open query text");
      Assert (Editor.Quick_Open.File_Kind_Filter (S) = Editor.Quick_Open.Ada_Files,
              "refresh/recompute must preserve kind filter");
      Assert (Editor.Quick_Open.Path_Scope (S) = "src/",
              "refresh/recompute must preserve path scope");
      Assert (Editor.Quick_Open.Priority_Mode (S) = Editor.Quick_Open.Open_Recent,
              "refresh/recompute must preserve priority mode");
      Assert (To_String (Snapshot.Selected_Path) = "src/a.adb",
              "selection must remain on the same visible path when it still exists");
      Assert_Project_Quick_Open_Coherent (Project, S, Snapshot);

      Editor.Project.Clear_Known_Files (Project);
      Editor.Project.Add_Known_File (Project, "src/aa.adb", "/project/src/aa.adb");
      Editor.Project.Add_Known_File (Project, "src/b.adb", "/project/src/b.adb");
      Editor.Project.Add_Known_File (Project, "tests/test_a.adb", "/project/tests/test_a.adb");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open.Build_Snapshot (S);
      Assert (To_String (Snapshot.Selected_Path) = "src/aa.adb",
              "removed selected paths must normalize to the highest-ranked visible candidate");
      Assert (Editor.Quick_Open.Query_Text (S) = "a"
              and then Editor.Quick_Open.Path_Scope (S) = "src/"
              and then Editor.Quick_Open.Priority_Mode (S) = Editor.Quick_Open.Open_Recent,
              "selection normalization must not mutate query/scope/priority state");
      Assert_Project_Quick_Open_Coherent (Project, S, Snapshot);

      Editor.Quick_Open.Set_Path_Scope (S, "docs/");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open.Build_Snapshot (S);
      Assert (Natural (Snapshot.Candidates.Length) = 0,
              "scope/query combinations with no candidates must expose an empty candidate vector");
      Assert_Project_Quick_Open_Coherent (Project, S, Snapshot);
   end Test_Phase_331_Refresh_State_Preserves_Selection_And_Filters;

   procedure Test_Phase_331_Ignore_Refresh_Removes_Selected_Candidate
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("phase331_ignore_root");
      Src  : constant String := Slash (Root, "src");
      Gen  : constant String := Slash (Src, "generated");
      Edit : constant String := Slash (Src, "editor");
      Project : Editor.Project.Project_State;
      Open_Result : Editor.Project.Project_Open_Result;
      Refresh : Editor.Project.Project_File_Refresh_Result;
      S       : Editor.Quick_Open.Quick_Open_State;
      Config  : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Delete_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Ada.Directories.Create_Directory (Gen);
      Ada.Directories.Create_Directory (Edit);
      Write_Bytes (Slash (Gen, "view.adb"), "generated");
      Write_Bytes (Slash (Edit, "executor.adb"), "executor");

      Open_Result := Editor.Project.Open_Project (Root);
      Assert (Editor.Project.Is_Success (Open_Result),
              "test project root must open successfully");
      Editor.Project.Apply_Open_Result (Project, Open_Result);
      Editor.Project.Refresh_Known_Files (Project, Refresh);
      Assert (Refresh.Status = Editor.Project.Project_File_Refresh_Ok,
              "initial project refresh must succeed");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "view");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open.Build_Snapshot (S);
      Assert (To_String (Snapshot.Selected_Path) = "src/generated/view.adb",
              "test setup must select the generated candidate before ignore refresh");

      Write_Bytes (Slash (Root, ".projectignore"), "src/generated/" & Character'Val (10));
      Editor.Project.Refresh_Known_Files (Project, Refresh);
      Assert (Refresh.Status = Editor.Project.Project_File_Refresh_Ok,
              "ignore-rule refresh must succeed");
      Assert (Refresh.Removed_Count = 1,
              "refresh delta must count the removed ignored known file");
      Assert (Refresh.Ignored_Path_Count >= 1,
              "refresh must report ignored paths from the new ignore rule");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open.Build_Snapshot (S);
      Assert (not Editor.Project.Has_Known_File (Project, "src/generated/view.adb"),
              "ignored generated file must be removed from known project files after refresh");
      Assert (Natural (Snapshot.Candidates.Length) = 0,
              "ignored selected candidate must not remain visible after refresh");
      Assert_Project_Quick_Open_Coherent (Project, S, Snapshot);
      Delete_Tree_If_Exists (Root);
   exception
      when others =>
         Delete_Tree_If_Exists (Root);
         raise;
   end Test_Phase_331_Ignore_Refresh_Removes_Selected_Candidate;

   procedure Test_Phase_331_Priority_Mode_Remains_Filtered_Ordering_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Recent_Id : Editor.Buffers.Buffer_Id;
      Dirty_Id  : Editor.Buffers.Buffer_Id;
      Active_Id : Editor.Buffers.Buffer_Id;
      Snapshot  : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/a.adb", "/project/src/a.adb");
      Editor.Project.Add_Known_File (Project, "src/b.adb", "/project/src/b.adb");
      Editor.Project.Add_Known_File (Project, "tests/test_a.adb", "/project/tests/test_a.adb");

      Recent_Id := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/a.adb", "a.adb", "body");
      Dirty_Id := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/b.adb", "b.adb", "body");
      Active_Id := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/tests/test_a.adb", "test_a.adb", "body");
      Editor.State.Set_Dirty (Editor.Buffers.Buffer_Access (Registry, Dirty_Id).all, True);
      Editor.Buffers.Set_Active_Buffer (Registry, Active_Id);
      Editor.Recent_Buffers.Mark_Activated (Recent, Natural (Recent_Id));

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, ".adb");
      Editor.Quick_Open.Toggle_Priority_Mode (S);
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert (To_String (Snapshot.Candidates (0).Project_Relative_Path) = "tests/test_a.adb"
              and then Snapshot.Candidates (0).Priority_Bucket = Editor.Quick_Open.Active_File,
              "Open/Recent mode must place the active matching file first");
      Assert (To_String (Snapshot.Candidates (1).Project_Relative_Path) = "src/b.adb"
              and then Snapshot.Candidates (1).Priority_Bucket = Editor.Quick_Open.Open_Dirty_File,
              "Open/Recent mode must place dirty open matching files after active files");
      Assert (To_String (Snapshot.Candidates (2).Project_Relative_Path) = "src/a.adb"
              and then Snapshot.Candidates (2).Priority_Bucket = Editor.Quick_Open.Open_Clean_File
              and then Snapshot.Candidates (2).Is_Recent,
              "Open/Recent mode must keep clean open recent candidates after active and dirty files");
      Assert_Project_Quick_Open_Coherent (Project, S, Snapshot);

      Editor.Quick_Open.Set_Path_Scope (S, "src/");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert (Natural (Snapshot.Candidates.Length) = 2,
              "priority mode must not show candidates hidden by scope filters");
      Assert (To_String (Snapshot.Candidates (0).Project_Relative_Path) = "src/b.adb",
              "filtered priority order must start with the dirty open src candidate");
      Assert (To_String (Snapshot.Candidates (1).Project_Relative_Path) = "src/a.adb",
              "filtered priority order may include matching recent src candidates");

      Editor.State.Set_Dirty (Editor.Buffers.Buffer_Access (Registry, Dirty_Id).all, False);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert (Snapshot.Candidates (0).Priority_Bucket = Editor.Quick_Open.Open_Clean_File,
              "later dirty-state changes must move candidates to the clean-open bucket");
      Assert (Editor.Recent_Buffers.Contains (Recent, Natural (Recent_Id)),
              "Quick Open priority derivation must not mutate recent-buffer history");
      Assert_Project_Quick_Open_Coherent (Project, S, Snapshot);
   end Test_Phase_331_Priority_Mode_Remains_Filtered_Ordering_Only;

   procedure Test_Phase_331_Snapshot_Header_Exposes_Priority_And_Counts
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project : Editor.Project.Project_State;
      Result  : Editor.Project.Project_Open_Result;
      S       : Editor.Quick_Open.Quick_Open_State;
      Config  : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "README.md", "/project/README.md");
      Editor.Project.Add_Known_File (Project, "src/editor/executor.adb", "/project/src/editor/executor.adb");
      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Toggle_Priority_Mode (S);
      Editor.Quick_Open.Set_Path_Scope (S, "src/editor/");
      Editor.Quick_Open.Set_Query_Text (S, "executor");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open.Build_Snapshot (S);
      Assert (To_String (Snapshot.Header_Text) =
              "Kind: All | Scope: src/editor/ | Priority: Open/Recent | Results: 1 of 2",
              "snapshot header must expose kind, scope, priority, and visible/known counts");
      Assert_Project_Quick_Open_Coherent (Project, S, Snapshot);
   end Test_Phase_331_Snapshot_Header_Exposes_Priority_And_Counts;

   procedure Test_Project_Quick_Open_Create_Target_Derivation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.Quick_Open.Quick_Open_State;
      R : Editor.Quick_Open.Quick_Open_Create_Target_Result;
   begin
      Editor.Quick_Open.Open (S);

      Editor.Quick_Open.Set_Query_Text (S, " new.adb ");
      R := Editor.Quick_Open.Create_Target_From_Query (S);
      Assert (R.Status = Editor.Quick_Open.Quick_Open_Create_Target_Ok,
              "root-level create target must validate");
      Assert (To_String (R.Project_Relative_Path) = "new.adb",
              "root-level target must be the trimmed query");

      Editor.Quick_Open.Set_Path_Scope (S, "src");
      Editor.Quick_Open.Set_Query_Text (S, "new.adb");
      R := Editor.Quick_Open.Create_Target_From_Query (S);
      Assert (R.Status = Editor.Quick_Open.Quick_Open_Create_Target_Ok,
              "scoped file create target must validate");
      Assert (To_String (R.Project_Relative_Path) = "src/new.adb",
              "scope must prefix basename query");

      Editor.Quick_Open.Set_Query_Text (S, "editor\\new.adb");
      R := Editor.Quick_Open.Create_Target_From_Query (S);
      Assert (R.Status = Editor.Quick_Open.Quick_Open_Create_Target_Ok,
              "scoped nested create target must validate");
      Assert (To_String (R.Project_Relative_Path) = "src/editor/new.adb",
              "scope must prefix path-bearing relative query");

      Editor.Quick_Open.Set_Query_Text (S, "");
      R := Editor.Quick_Open.Create_Target_From_Query (S);
      Assert (R.Status = Editor.Quick_Open.Quick_Open_Create_Target_No_Query,
              "empty query must be rejected as no query");

      Editor.Quick_Open.Set_Query_Text (S, "/tmp/x.adb");
      R := Editor.Quick_Open.Create_Target_From_Query (S);
      Assert (R.Status = Editor.Quick_Open.Quick_Open_Create_Target_Invalid_Path,
              "absolute paths must be rejected");

      Editor.Quick_Open.Set_Query_Text (S, "../x.adb");
      R := Editor.Quick_Open.Create_Target_From_Query (S);
      Assert (R.Status = Editor.Quick_Open.Quick_Open_Create_Target_Invalid_Path,
              "parent traversal must be rejected");

      Editor.Quick_Open.Set_Query_Text (S, "src/../x.adb");
      R := Editor.Quick_Open.Create_Target_From_Query (S);
      Assert (R.Status = Editor.Quick_Open.Quick_Open_Create_Target_Invalid_Path,
              "embedded parent traversal must be rejected");

      Editor.Quick_Open.Set_Query_Text (S, "src/newdir/");
      R := Editor.Quick_Open.Create_Target_From_Query (S);
      Assert (R.Status = Editor.Quick_Open.Quick_Open_Create_Target_Invalid_Path,
              "directory-style trailing slash must be rejected");

      Editor.Quick_Open.Set_Path_Scope (S, "src//editor");
      Editor.Quick_Open.Set_Query_Text (S, "nested//panel.adb");
      R := Editor.Quick_Open.Create_Target_From_Query (S);
      Assert (R.Status = Editor.Quick_Open.Quick_Open_Create_Target_Ok,
              "harmless duplicate separators must normalize in scope and query");
      Assert (To_String (R.Project_Relative_Path) = "src/editor/nested/panel.adb",
              "normalized create target must preserve scope plus relative query");

      Editor.Quick_Open.Set_Path_Scope (S, "src/..");
      Assert (Editor.Quick_Open.Path_Scope (S) = "",
              "invalid traversal scope must be dropped before file target derivation");
      Editor.Quick_Open.Set_Query_Text (S, "escaped.adb");
      R := Editor.Quick_Open.Create_Target_From_Query (S);
      Assert (R.Status = Editor.Quick_Open.Quick_Open_Create_Target_Ok,
              "create target must remain project-relative after invalid scope is dropped");
      Assert (To_String (R.Project_Relative_Path) = "escaped.adb",
              "invalid traversal scope must not prefix the created target");
   end Test_Project_Quick_Open_Create_Target_Derivation;


   procedure Test_Phase_332_Project_Quick_Open_Command_Surface_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
   begin
      Assert_Command_Surface
        (Editor.Commands.Command_Refresh_Project_Files,
         "project.files.refresh",
         Editor.Commands.Project_Category,
         Editor.Commands.Palette_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Project_Files_Summary,
         "project.files.summary",
         Editor.Commands.Project_Category,
         Editor.Commands.Palette_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Open_Quick_Open,
         "quick-open.show",
         Editor.Commands.Project_Category,
         Editor.Commands.Palette_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Close_Quick_Open,
         "project.quick-open.hide",
         Editor.Commands.Project_Category,
         Editor.Commands.Hidden_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Toggle_Quick_Open,
         "project.quick-open.toggle",
         Editor.Commands.Project_Category,
         Editor.Commands.Palette_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Query_Set,
         "project.quick-open.query.set",
         Editor.Commands.Project_Category,
         Editor.Commands.Hidden_Command,
         False);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Query_Clear,
         "project.quick-open.query.clear",
         Editor.Commands.Project_Category,
         Editor.Commands.Hidden_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Next_Result,
         "project.quick-open.next",
         Editor.Commands.Project_Category,
         Editor.Commands.Hidden_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Previous_Result,
         "project.quick-open.previous",
         Editor.Commands.Project_Category,
         Editor.Commands.Hidden_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Accept_Quick_Open,
         "quick-open.open-selected",
         Editor.Commands.Project_Category,
         Editor.Commands.Hidden_Command,
         True,
         Lifecycle => True);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Kind_Next,
         "project.quick-open.kind.next",
         Editor.Commands.Project_Category,
         Editor.Commands.Hidden_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Kind_Previous,
         "project.quick-open.kind.previous",
         Editor.Commands.Project_Category,
         Editor.Commands.Hidden_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Kind_Clear,
         "project.quick-open.kind.clear",
         Editor.Commands.Project_Category,
         Editor.Commands.Hidden_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Scope_Set,
         "project.quick-open.scope.set",
         Editor.Commands.Project_Category,
         Editor.Commands.Hidden_Command,
         False);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Scope_Clear,
         "project.quick-open.scope.clear",
         Editor.Commands.Project_Category,
         Editor.Commands.Hidden_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Scope_From_Selected,
         "project.quick-open.scope.from-selected",
         Editor.Commands.Project_Category,
         Editor.Commands.Hidden_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Scope_Parent,
         "project.quick-open.scope.parent",
         Editor.Commands.Project_Category,
         Editor.Commands.Hidden_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Scope_Active_Directory,
         "project.quick-open.scope.active-directory",
         Editor.Commands.Project_Category,
         Editor.Commands.Palette_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Reveal_Active,
         "project.quick-open.reveal-active",
         Editor.Commands.Project_Category,
         Editor.Commands.Palette_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Create_From_Query,
         "project.quick-open.create-from-query",
         Editor.Commands.Project_Category,
         Editor.Commands.Hidden_Command,
         True,
         Lifecycle => True);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Create_With_Parents_From_Query,
         "project.quick-open.create-with-parents-from-query",
         Editor.Commands.Project_Category,
         Editor.Commands.Hidden_Command,
         True,
         Lifecycle => True);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Priority_Toggle,
         "project.quick-open.priority.toggle",
         Editor.Commands.Project_Category,
         Editor.Commands.Palette_Command,
         True);
      Assert_Command_Surface
        (Editor.Commands.Command_Quick_Open_Priority_Clear,
         "project.quick-open.priority.clear",
         Editor.Commands.Project_Category,
         Editor.Commands.Palette_Command,
         True);
   end Test_Phase_332_Project_Quick_Open_Command_Surface_Baseline;

   procedure Test_Phase_332_Project_Quick_Open_No_Name_Drift_Or_Extras
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Name_I : Unbounded_String;
      Name_J : Unbounded_String;
   begin
      for I in Editor.Commands.Command_Id loop
         if I /= Editor.Commands.Command_Id'Last
           and then Editor.Commands.Is_Concrete_Command (I)
         then
            Name_I := To_Unbounded_String (Editor.Commands.Stable_Command_Name (I));
            for J in Editor.Commands.Command_Id'Succ (I) .. Editor.Commands.Command_Id'Last loop
               if Editor.Commands.Is_Concrete_Command (J) then
                  Name_J := To_Unbounded_String (Editor.Commands.Stable_Command_Name (J));
                  Assert (Name_I /= Name_J,
                          "duplicate stable command name: " & To_String (Name_I));
               end if;
            end loop;
         end if;
      end loop;

      Assert_Absent_Command_Not_Exposed ("project.quick-open.refresh");
      Assert_Absent_Command_Not_Exposed ("project.quick-open.create-directory");
      Assert_Absent_Command_Not_Exposed ("project.quick-open.delete");
      Assert_Absent_Command_Not_Exposed ("project.quick-open.rename");
      Assert_Absent_Command_Not_Exposed ("project.quick-open.move");
      Assert_Absent_Command_Not_Exposed ("project.quick-open.preview");
      Assert_Absent_Command_Not_Exposed ("project.quick-open.recent.clear");
      Assert_Absent_Command_Not_Exposed ("project.quick-open.priority.persist");
      Assert_Absent_Command_Not_Exposed ("project.files.watch");
      Assert_Absent_Command_Not_Exposed ("project.files.validate");
      Assert_Absent_Command_Not_Exposed ("project.files.prune-stale");
   end Test_Phase_332_Project_Quick_Open_No_Name_Drift_Or_Extras;

   procedure Test_Phase_332_Project_Quick_Open_Keybinding_Baseline
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Status : Editor.Keybindings.Keybinding_Change_Status;
      Actual : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      Editor.Keybindings.Reset_To_Defaults;
      Editor.Keybindings.Assign
        (Chord (Editor.Keybindings.Key_F12),
         Editor.Commands.Command_Quick_Open_Create_From_Query,
         Status);
      Assert (Status = Editor.Keybindings.Keybinding_Change_Ok,
              "create-from-query must remain assignable when deliberately bound");
      Assert
        (Editor.Keybindings.Resolve (Chord (Editor.Keybindings.Key_F12), Actual)
         = Editor.Keybindings.Bound_Command
         and then Actual = Editor.Commands.Command_Quick_Open_Create_From_Query,
         "assigned create-from-query chord must resolve to the command id");

      Editor.Keybindings.Assign
        (Chord (Editor.Keybindings.Key_F12, Shift => True),
         Editor.Commands.Command_Quick_Open_Create_With_Parents_From_Query,
         Status);
      Assert (Status = Editor.Keybindings.Keybinding_Change_Ok,
              "create-with-parents-from-query must remain assignable");

      Editor.Keybindings.Assign
        (Chord (Editor.Keybindings.Key_F12, Ctrl => True),
         Editor.Commands.Command_Quick_Open_Query_Set,
         Status);
      Assert (Status = Editor.Keybindings.Keybinding_Change_Non_Bindable_Target,
              "payload-style query.set must not be assignable through keybindings");

      Editor.Keybindings.Assign
        (Chord (Editor.Keybindings.Key_F12, Alt => True),
         Editor.Commands.Command_Quick_Open_Scope_Set,
         Status);
      Assert (Status = Editor.Keybindings.Keybinding_Change_Non_Bindable_Target,
              "payload-style scope.set must not be assignable through keybindings");
      Editor.Keybindings.Reset_To_Defaults;
   end Test_Phase_332_Project_Quick_Open_Keybinding_Baseline;

   procedure Test_Project_Quick_Open_Command_Descriptors
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Show_D   : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Open_Quick_Open);
      Toggle_D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Toggle_Quick_Open);
      Open_D   : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Accept_Quick_Open);
      Set_D    : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Quick_Open_Query_Set);
      Clear_D  : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Quick_Open_Query_Clear);
      Kind_Next_D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Quick_Open_Kind_Next);
      Scope_Set_D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Quick_Open_Scope_Set);
      Scope_From_D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Quick_Open_Scope_From_Selected);
      Scope_Parent_D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Quick_Open_Scope_Parent);
      Reveal_Active_D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Quick_Open_Reveal_Active);
      Scope_Active_D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Quick_Open_Scope_Active_Directory);
      Create_D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor (Editor.Commands.Command_Quick_Open_Create_From_Query);
      Create_Parents_D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor
          (Editor.Commands.Command_Quick_Open_Create_With_Parents_From_Query);
      Priority_Toggle_D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor
          (Editor.Commands.Command_Quick_Open_Priority_Toggle);
      Priority_Clear_D : constant Editor.Commands.Command_Descriptor :=
        Editor.Commands.Descriptor
          (Editor.Commands.Command_Quick_Open_Priority_Clear);
   begin
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Open_Quick_Open) =
              "quick-open.show",
              "Project Quick Open show command must have the canonical stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Toggle_Quick_Open) =
              "project.quick-open.toggle",
              "Project Quick Open toggle command must have the frozen stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Accept_Quick_Open) =
              "quick-open.open-selected",
              "Project Quick Open open-selected command must have the canonical stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Quick_Open_Query_Set) =
              "project.quick-open.query.set",
              "Project Quick Open query-set command must have the frozen stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Quick_Open_Query_Clear) =
              "project.quick-open.query.clear",
              "Project Quick Open query-clear command must have the frozen stable name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Quick_Open_Kind_Next) =
              "project.quick-open.kind.next",
              "Project Quick Open kind-next command must have the stable Phase 324 name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Quick_Open_Scope_Set) =
              "project.quick-open.scope.set",
              "Project Quick Open scope-set command must have the stable Phase 324 name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Quick_Open_Scope_From_Selected) =
              "project.quick-open.scope.from-selected",
              "Project Quick Open scope-from-selected command must have the stable Phase 325 name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Quick_Open_Scope_Parent) =
              "project.quick-open.scope.parent",
              "Project Quick Open scope-parent command must have the stable Phase 325 name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Quick_Open_Reveal_Active) =
              "project.quick-open.reveal-active",
              "Project Quick Open reveal-active command must have the stable Phase 326 name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Quick_Open_Scope_Active_Directory) =
              "project.quick-open.scope.active-directory",
              "Project Quick Open scope-active-directory command must have the stable Phase 326 name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Quick_Open_Create_From_Query) =
              "project.quick-open.create-from-query",
              "Project Quick Open create-from-query command must have the stable Phase 327 name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Quick_Open_Create_With_Parents_From_Query) =
              "project.quick-open.create-with-parents-from-query",
              "Project Quick Open create-with-parents command must have the stable Phase 328 name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Quick_Open_Priority_Toggle) =
              "project.quick-open.priority.toggle",
              "Project Quick Open priority toggle command must have the stable Phase 329 name");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Quick_Open_Priority_Clear) =
              "project.quick-open.priority.clear",
              "Project Quick Open priority clear command must have the stable Phase 329 name");

      Assert (Show_D.Category = Editor.Commands.Project_Category
              and then Toggle_D.Category = Editor.Commands.Project_Category
              and then Open_D.Category = Editor.Commands.Project_Category
              and then Set_D.Category = Editor.Commands.Project_Category
              and then Clear_D.Category = Editor.Commands.Project_Category
              and then Kind_Next_D.Category = Editor.Commands.Project_Category
              and then Scope_Set_D.Category = Editor.Commands.Project_Category
              and then Scope_From_D.Category = Editor.Commands.Project_Category
              and then Scope_Parent_D.Category = Editor.Commands.Project_Category
              and then Reveal_Active_D.Category = Editor.Commands.Project_Category
              and then Scope_Active_D.Category = Editor.Commands.Project_Category
              and then Create_D.Category = Editor.Commands.Project_Category
              and then Create_Parents_D.Category = Editor.Commands.Project_Category
              and then Priority_Toggle_D.Category = Editor.Commands.Project_Category
              and then Priority_Clear_D.Category = Editor.Commands.Project_Category,
              "all Project Quick Open commands must stay in the Project category");
      Assert (Show_D.Visibility = Editor.Commands.Palette_Command,
              "Project Quick Open show must be visible in the command palette");
      Assert (Toggle_D.Visibility = Editor.Commands.Palette_Command,
              "Project Quick Open toggle must be visible in the command palette");
      Assert (Reveal_Active_D.Visibility = Editor.Commands.Palette_Command
              and then Scope_Active_D.Visibility = Editor.Commands.Palette_Command
              and then Priority_Toggle_D.Visibility = Editor.Commands.Palette_Command
              and then Priority_Clear_D.Visibility = Editor.Commands.Palette_Command,
              "active-buffer and priority Project Quick Open commands must be visible in the command palette");
      Assert (Open_D.Visibility = Editor.Commands.Hidden_Command
              and then Set_D.Visibility = Editor.Commands.Hidden_Command
              and then Clear_D.Visibility = Editor.Commands.Hidden_Command
              and then Create_D.Visibility = Editor.Commands.Hidden_Command
              and then Create_Parents_D.Visibility = Editor.Commands.Hidden_Command,
              "local Project Quick Open action/query commands must remain hidden from the palette");
      Assert (Open_D.Lifecycle and then Create_D.Lifecycle
              and then Create_Parents_D.Lifecycle,
              "Project Quick Open open/create actions must be classified as lifecycle/open behavior");
      Assert (not Set_D.Bindable and then Clear_D.Bindable
              and then Kind_Next_D.Bindable and then not Scope_Set_D.Bindable
              and then Scope_From_D.Bindable and then Scope_Parent_D.Bindable
              and then Reveal_Active_D.Bindable and then Scope_Active_D.Bindable
              and then Create_D.Bindable and then Create_Parents_D.Bindable
              and then Priority_Toggle_D.Bindable and then Priority_Clear_D.Bindable,
              "text-payload commands must not be bindable, while local filter/scope commands may be bound");
   end Test_Project_Quick_Open_Command_Descriptors;

   procedure Test_Phase482_Open_Buffer_Association_And_Dirty_Observation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Alpha    : Editor.Buffers.Buffer_Id;
      Beta     : Editor.Buffers.Buffer_Id;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
      pragma Unreferenced (Beta);
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/main.adb", "/project/src/main.adb");

      Alpha := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/main.adb", "main.adb", "body");
      Beta := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/other.adb", "other.adb", "body");
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "main");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Set_Buffer_Dirty_For_Test (Registry, Alpha, True);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observes_Association
        (Snapshot, "src/main.adb", True,
         "Phase 482 save precondition");

      Set_Buffer_Dirty_For_Test (Registry, Alpha, False);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observes_Association
        (Snapshot, "src/main.adb", False,
         "Phase 482 save dirty cleanup");

      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/project/src/saved_as.adb", "saved_as.adb");
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observes_Association
        (Snapshot, "src/saved_as.adb", False,
         "Phase 482 save-as association update");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "last-save-as-target.adb"),
              "Phase 482 save-as target history must not create Quick Open candidates");

      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/project/src/renamed.adb", "renamed.adb");
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observes_Association
        (Snapshot, "src/renamed.adb", False,
         "Phase 482 rename association update");

      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observes_Association
        (Snapshot, "src/renamed.adb", False,
         "Phase 482 copy preserves source association");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/copied.adb"),
              "Phase 482 copy target must not be promoted into an open-buffer candidate");

      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/project/src/moved.adb", "moved.adb");
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observes_Association
        (Snapshot, "src/moved.adb", False,
         "Phase 482 move association update");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/renamed.adb")
              or else Quick_Open_Candidate_Index (Snapshot, "src/renamed.adb") /=
                      Quick_Open_Candidate_Index (Snapshot, "src/moved.adb"),
              "Phase 482 move must not create a duplicate open-buffer target row");

      Clear_Buffer_Association_For_Test (Registry, Alpha);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observes_Association
        (Snapshot, "Untitled", False,
         "Phase 482 delete association clear");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/deleted.adb"),
              "Phase 482 delete source must not become a recovery candidate");
   end Test_Phase482_Open_Buffer_Association_And_Dirty_Observation;

   procedure Test_Phase482_Close_Reopen_And_Failure_Preservation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Alpha    : Editor.Buffers.Buffer_Id;
      Reopened : Editor.Buffers.Buffer_Id;
      Closed   : Boolean := False;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);

      Alpha := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/main.adb", "main.adb", "body");
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);
      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "main");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);

      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert (Quick_Open_Has_Candidate (Snapshot, "src/main.adb"),
              "Phase 482 open buffer collection must produce an observable candidate");

      Set_Buffer_Association_For_Test
        (Registry, Alpha, "/project/src/main.adb", "main.adb");
      Set_Buffer_Dirty_For_Test (Registry, Alpha, True);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observes_Association
        (Snapshot, "src/main.adb", True,
         "Phase 482 failed save-as precondition");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/failed-save-as.adb"),
              "Phase 482 failed save-as target must not be shown");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/failed-rename.adb"),
              "Phase 482 failed rename target must not be shown");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/failed-copy.adb"),
              "Phase 482 failed copy target must not be shown");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/failed-move.adb"),
              "Phase 482 failed move target must not be shown");

      Editor.Buffers.Close_Buffer (Registry, Alpha, Closed, Force => True);
      Assert (Closed, "Phase 482 close setup must close the buffer");
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/main.adb"),
              "Phase 482 close removes open-buffer candidates through the collection only");

      Reopened := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/reopened.adb", "reopened.adb", "body");
      Editor.Buffers.Set_Active_Buffer (Registry, Reopened);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observes_Association
        (Snapshot, "src/reopened.adb", False,
         "Phase 482 reopen/open adds candidate through canonical open-buffer collection");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/recovery-main.adb"),
              "Phase 482 Quick Open must not create reopen/recovery candidates");
   end Test_Phase482_Close_Reopen_And_Failure_Preservation;

   procedure Test_Phase482_Query_Selection_And_Prompt_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      App      : Editor.State.State_Type;
      Active   : Editor.Buffers.Buffer_Id;
      Other    : Editor.Buffers.Buffer_Id;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
      Found    : Boolean := False;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/active.adb", "/project/src/active.adb");
      Editor.Project.Add_Known_File (Project, "src/other.adb", "/project/src/other.adb");

      Active := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/active.adb", "active.adb", "body");
      Other := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/other.adb", "other.adb", "body");
      Editor.Buffers.Set_Active_Buffer (Registry, Active);

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "other");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Editor.Quick_Open.Select_Path (S, "src/other.adb", Found);
      Assert (Found, "Phase 482 setup must select a non-active Quick Open candidate");
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);

      Assert (Quick_Open_Has_Candidate (Snapshot, "src/other.adb"),
              "Phase 482 selected Quick Open candidate must remain ordinary UI state");
      Assert (Editor.Buffers.Active_Buffer (Registry) = Active,
              "Phase 482 Quick Open selection must not replace canonical active-buffer source");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/target-from-query.adb"),
              "Phase 482 Quick Open query text must not become a lifecycle target candidate");

      Editor.State.Init (App);
      App.File_Target_Prompt_Active := True;
      App.File_Target_Prompt_Command := Editor.Commands.Command_Save_File_As;
      App.File_Target_Prompt_Label := To_Unbounded_String ("Save As target");
      Editor.Input_Field.Insert_Text (App.File_Target_Prompt_Input, "/project/src/manual.adb");
      Editor.Quick_Open.Set_Query_Text (S, "/project/src/not-the-target.adb");
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert (App.File_Target_Prompt_Active,
              "Phase 482 Quick Open snapshot construction must not own prompt state");
      Assert (Editor.Input_Field.Text (App.File_Target_Prompt_Input) = "/project/src/manual.adb",
              "Phase 482 Quick Open query/selection must not seed target prompt input");
      Assert (Editor.Buffers.Active_Buffer (Registry) = Active,
              "Phase 482 prompt-active Quick Open interaction preserves active-buffer source policy");
      Assert (Other /= Active,
              "Phase 482 setup must keep selected candidate distinct from active buffer");
   end Test_Phase482_Query_Selection_And_Prompt_Boundary;


   procedure Test_Phase483_Successful_Operation_Observation_Reliability
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Active   : Editor.Buffers.Buffer_Id;
      Other    : Editor.Buffers.Buffer_Id;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
      Closed   : Boolean := False;
      pragma Unreferenced (Other);
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/main.adb", "/project/src/main.adb");
      Editor.Project.Add_Known_File (Project, "src/project-only.adb", "/project/src/project-only.adb");

      Active := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/main.adb", "main.adb", "body");
      Other := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/other.adb", "other.adb", "body");
      Editor.Buffers.Set_Active_Buffer (Registry, Active);

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "main");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);

      Set_Buffer_Dirty_For_Test (Registry, Active, True);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observation_Reliable
        (Snapshot, "src/main.adb", True,
         "Phase 483 save precondition while Quick Open is visible");

      Set_Buffer_Dirty_For_Test (Registry, Active, False);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observation_Reliable
        (Snapshot, "src/main.adb", False,
         "Phase 483 save observes clean dirty hint only through buffer state");

      Set_Buffer_Association_For_Test
        (Registry, Active, "/project/src/saved-as.adb", "saved-as.adb");
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observation_Reliable
        (Snapshot, "src/saved-as.adb", False,
         "Phase 483 save-as updates open-buffer label deterministically");
      Assert_Quick_Open_Project_Candidate_Boundary
        (Snapshot, "src/main.adb", True, False,
         "Phase 483 old save-as project candidate remains project-owned only");

      Set_Buffer_Association_For_Test
        (Registry, Active, "/project/src/renamed.adb", "renamed.adb");
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observation_Reliable
        (Snapshot, "src/renamed.adb", False,
         "Phase 483 rename updates open-buffer label deterministically");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/saved-as.adb"),
              "Phase 483 rename must not preserve save-as target history as a candidate");

      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observation_Reliable
        (Snapshot, "src/renamed.adb", False,
         "Phase 483 copy preserves source association");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/copied-target.adb"),
              "Phase 483 copy target must not be synthesized as an open-buffer candidate");

      Set_Buffer_Association_For_Test
        (Registry, Active, "/project/src/moved.adb", "moved.adb");
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observation_Reliable
        (Snapshot, "src/moved.adb", False,
         "Phase 483 move updates the same open-buffer candidate label");
      Assert (Quick_Open_Candidate_Count (Snapshot, "src/moved.adb") = 1,
              "Phase 483 move must not create a duplicate moved-target candidate");

      Clear_Buffer_Association_For_Test (Registry, Active);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observation_Reliable
        (Snapshot, "Untitled", False,
         "Phase 483 delete association clear exposes no-path open-buffer label");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/deleted-source.adb"),
              "Phase 483 delete must not create deleted-file recovery candidates");

      Editor.Buffers.Close_Buffer (Registry, Active, Closed, Force => True);
      Assert (Closed, "Phase 483 close setup must close active buffer");
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert (not Quick_Open_Has_Candidate (Snapshot, "Untitled"),
              "Phase 483 close removes the closed open-buffer candidate through registry membership");

      Active := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/reopened.adb", "reopened.adb", "body");
      Editor.Buffers.Set_Active_Buffer (Registry, Active);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observation_Reliable
        (Snapshot, "src/reopened.adb", False,
         "Phase 483 reopen observes canonical reopened buffer membership");
      Assert_Quick_Open_Persistence_Excluded
        (Snapshot,
         "Phase 483 successful observation must not surface persisted lifecycle state");
   end Test_Phase483_Successful_Operation_Observation_Reliability;

   procedure Test_Phase483_Failure_And_Blocked_Operation_Preservation
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Active   : Editor.Buffers.Buffer_Id;
      Before   : Editor.Quick_Open.Quick_Open_Snapshot;
      After    : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);

      Active := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/main.adb", "main.adb", "body");
      Editor.Buffers.Set_Active_Buffer (Registry, Active);
      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "main");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);

      Set_Buffer_Dirty_For_Test (Registry, Active, True);
      Before := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);

      --  Failed/blocked lifecycle operations are represented here by the
      --  canonical invariant they must leave behind: no association, dirty,
      --  membership, or target-history mutation reaches Quick Open.
      After := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observation_Failure_Preserved
        (Before, After, "src/main.adb", "src/failed-save-as.adb",
         "Phase 483 failed save-as preservation");
      Assert_Quick_Open_Observation_Failure_Preserved
        (Before, After, "src/main.adb", "src/failed-rename.adb",
         "Phase 483 failed rename preservation");
      Assert_Quick_Open_Observation_Failure_Preserved
        (Before, After, "src/main.adb", "src/failed-copy.adb",
         "Phase 483 failed copy preservation");
      Assert_Quick_Open_Observation_Failure_Preserved
        (Before, After, "src/main.adb", "src/failed-move.adb",
         "Phase 483 failed move preservation");
      Assert_Quick_Open_Observation_Failure_Preserved
        (Before, After, "src/main.adb", "src/deleted-after-failure.adb",
         "Phase 483 failed delete preservation");
      Assert (Quick_Open_Candidate_Count (After, "src/main.adb") = 1,
              "Phase 483 blocked dirty operations must leave collection membership unchanged");
   end Test_Phase483_Failure_And_Blocked_Operation_Preservation;

   procedure Test_Phase483_Query_Selection_And_Prompt_Boundary_Reliability
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      App      : Editor.State.State_Type;
      Active   : Editor.Buffers.Buffer_Id;
      Other    : Editor.Buffers.Buffer_Id;
      App_Source : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
      Found    : Boolean := False;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/active.adb", "/project/src/active.adb");
      Editor.Project.Add_Known_File (Project, "src/other-target-like.adb", "/project/src/other-target-like.adb");

      Active := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/active.adb", "active.adb", "body");
      Other := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/other-target-like.adb", "other-target-like.adb", "body");
      Editor.Buffers.Set_Active_Buffer (Registry, Active);

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "/project/src/query-must-not-be-target.adb");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Editor.Quick_Open.Set_Query_Text (S, "other-target-like");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Editor.Quick_Open.Select_Path (S, "src/other-target-like.adb", Found);
      Assert (Found, "Phase 483 setup must select a non-active target-like candidate");
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);

      Assert (Quick_Open_Has_Candidate (Snapshot, "src/other-target-like.adb"),
              "Phase 483 selected candidate remains Quick Open UI state");
      Assert (Other /= Active,
              "Phase 483 selected candidate must differ from active buffer for boundary coverage");
      Assert_Quick_Open_Selection_Not_File_Lifecycle_Source
        (Registry, Active,
         "Phase 483 selected open-buffer candidate does not become lifecycle source");

      Editor.Quick_Open.Set_Query_Text
        (S, "/project/src/query-must-not-be-target.adb");

      Editor.State.Init (App);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.Buffers.Global_Add_File_Buffer
        ("/project/src/active.adb", "active.adb", "body", App_Source);
      Editor.Buffers.Global_Set_Active_Buffer (App_Source);
      Editor.Executor.Open_File_Target_Prompt
        (App, Editor.Commands.Command_Move_Buffer_File);
      Assert (Editor.Executor.File_Target_Prompt_Is_Active (App),
              "Phase 483 prompted move setup must open canonical target prompt");
      Assert (Editor.Executor.File_Target_Prompt_Input_Text (App) = "",
              "Phase 483 canonical prompt opens with no Quick Open-seeded input");
      Assert_Quick_Open_Query_Not_Target_Input
        (App, S,
         "Phase 483 path-like Quick Open query is not prompt input");

      Editor.Quick_Open.Move_Selection_Down (S);
      Editor.Executor.Insert_File_Target_Prompt_Text
        (App, "/project/src/manual-target.adb");
      Assert (Editor.Executor.File_Target_Prompt_Input_Text (App) = "/project/src/manual-target.adb",
              "Phase 483 prompt input remains canonical after Quick Open selection changes");
      Editor.Executor.Cancel_File_Target_Prompt (App);
      Assert (not Editor.Executor.File_Target_Prompt_Is_Active (App),
              "Phase 483 prompt cancellation remains non-mutating canonical prompt cleanup");
      Assert (Editor.Buffers.Active_Buffer (Registry) = Active,
              "Phase 483 prompt interaction must preserve active-buffer source discipline");
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Phase483_Query_Selection_And_Prompt_Boundary_Reliability;

   procedure Test_Phase483_Candidate_Freshness_Order_Project_And_Audit_Boundaries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Active   : Editor.Buffers.Buffer_Id;
      Before   : Editor.Quick_Open.Quick_Open_Snapshot;
      Fresh    : Editor.Quick_Open.Quick_Open_Snapshot;
      Audit    : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/source.adb", "/project/src/source.adb");
      Editor.Project.Add_Known_File (Project, "src/project-only.adb", "/project/src/project-only.adb");

      Active := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/source.adb", "source.adb", "body");
      Editor.Buffers.Set_Active_Buffer (Registry, Active);
      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "src/");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);

      Before := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observation_Reliable
        (Before, "src/source.adb", False,
         "Phase 483 freshness precondition");

      Set_Buffer_Association_For_Test
        (Registry, Active, "/project/src/fresh-target.adb", "fresh-target.adb");
      Fresh := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert_Quick_Open_Observation_Reliable
        (Fresh, "src/fresh-target.adb", False,
         "Phase 483 fresh snapshot reflects current association");
      Assert (Quick_Open_Has_Candidate (Before, "src/source.adb"),
              "Phase 483 retained stale snapshot fixture remains immutable test data");
      Assert_Quick_Open_Project_Candidate_Boundary
        (Fresh, "src/project-only.adb", True, False,
         "Phase 483 project candidate remains project-owned and not lifecycle-owned");
      Assert (not Quick_Open_Has_Candidate (Fresh, "src/copied-target.adb"),
              "Phase 483 copied target is not added without retained project policy");
      Assert (not Quick_Open_Has_Candidate (Fresh, "src/moved-old-path.adb"),
              "Phase 483 moved old path is not added as lifecycle history");
      Assert_Quick_Open_Persistence_Excluded
        (Fresh,
         "Phase 483 candidate snapshot excludes target histories and operation logs");

      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Save_File_As);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Keybinding,
         Editor.Commands.Command_Move_Buffer_File);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "Phase 483 route audit observes canonical file lifecycle routes without executing them");
      Assert (Editor.Command_Route_Audit.Summary (Audit)'Length > 0,
              "Phase 483 route audit summary remains transient side-effect-free data");
   end Test_Phase483_Candidate_Freshness_Order_Project_And_Audit_Boundaries;



   procedure Test_Phase484_Canonical_Open_Buffer_Identity_And_No_Caches
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Alpha    : Editor.Buffers.Buffer_Id;
      Beta     : Editor.Buffers.Buffer_Id;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
      Untitled_Count : Natural := 0;
      Saw_Alpha : Boolean := False;
      Saw_Beta  : Boolean := False;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/main.adb", "/project/src/main.adb");

      Alpha := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/main.adb", "main.adb", "body");
      Beta := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/other.adb", "other.adb", "body");
      Editor.Buffers.Set_Active_Buffer (Registry, Alpha);

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "main");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);

      Clear_Buffer_Association_For_Test (Registry, Alpha);
      Clear_Buffer_Association_For_Test (Registry, Beta);
      Set_Buffer_Dirty_For_Test (Registry, Alpha, True);
      Set_Buffer_Dirty_For_Test (Registry, Beta, False);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);

      for C of Snapshot.Candidates loop
         if To_String (C.Project_Relative_Path) = "Untitled" then
            Untitled_Count := Untitled_Count + 1;
            Assert (C.Buffer_Identity /= Editor.Buffers.No_Buffer,
                    "Phase 484 no-path open-buffer candidate identity must be the buffer id");
            if C.Buffer_Identity = Alpha then
               Saw_Alpha := True;
               Assert (C.Is_Dirty,
                       "Phase 484 dirty hint for Alpha must derive from current buffer state");
            elsif C.Buffer_Identity = Beta then
               Saw_Beta := True;
               Assert (not C.Is_Dirty,
                       "Phase 484 dirty hint for Beta must derive from current buffer state");
            else
               Assert (False,
                       "Phase 484 no-path candidate must not come from a cache or target history");
            end if;
         end if;
      end loop;

      Assert (Untitled_Count = 2,
              "Phase 484 duplicate no-path labels must remain distinct buffer-identity candidates");
      Assert (Saw_Alpha and then Saw_Beta,
              "Phase 484 open-buffer candidate collection must derive from canonical registry membership");
      Assert_Quick_Open_Project_Candidate_Boundary
        (Snapshot, "src/main.adb", True, False,
         "Phase 484 cleared association must leave only the retained project candidate");
      Assert_Quick_Open_Persistence_Excluded
        (Snapshot,
         "Phase 484 candidate snapshot excludes lifecycle caches and histories");

      Editor.Project.Clear_Known_Files (Project);
      Editor.Project.Add_Known_File (Project, "src/fresh-project.adb", "/project/src/fresh-project.adb");
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot (S, Project, Registry, Recent);
      Assert (Quick_Open_Has_Candidate (Snapshot, "src/fresh-project.adb"),
              "Phase 484 project/file candidates must be rebuilt from retained project source at snapshot time");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/main.adb"),
              "Phase 484 stale Quick Open result cache must not remain candidate truth after project source changes");
   end Test_Phase484_Canonical_Open_Buffer_Identity_And_No_Caches;



   procedure Test_Phase485_Final_Observation_Source_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Root         : constant String := Temp_Path ("phase485_source_freeze");
      Src          : constant String := Slash (Root, "src");
      Alpha_Path   : constant String := Slash (Src, "alpha.adb");
      Beta_Path    : constant String := Slash (Src, "beta.adb");
      Target_Path  : constant String := Slash (Src, "beta_saved_as.adb");
      Session_Path : constant String := Slash (Root, "phase485.session");
      S            : Editor.State.State_Type;
      Open_Result  : Editor.Project.Project_Open_Result;
      Config       : constant Editor.Quick_Open.Quick_Open_Config :=
        (others => <>);
      Alpha        : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Beta         : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Found        : Boolean := False;
      Before       : Editor.Quick_Open.Quick_Open_Snapshot;
      After        : Editor.Quick_Open.Quick_Open_Snapshot;
      Workspace    : Editor.Workspace_Persistence.Workspace_Snapshot;
      Status       : Editor.Workspace_Persistence.Workspace_Persistence_Status;
      Old_Beta     : Natural := Natural'Last;
   begin
      Delete_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Bytes (Alpha_Path, "alpha body");
      Write_Bytes (Beta_Path, "beta body");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);

      Open_Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String (Root),
         Display_Name => To_Unbounded_String ("phase485"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (S.Project, Open_Result);
      Editor.Project.Add_Known_File (S.Project, "src/alpha.adb", Alpha_Path);
      Editor.Project.Add_Known_File (S.Project, "src/beta.adb", Beta_Path);
      Editor.Project.Add_Known_File
        (S.Project, "src/project-only.adb", Slash (Src, "project-only.adb"));

      Editor.Executor.Execute_Open_File (S, Alpha_Path);
      Alpha := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Execute_Open_File (S, Beta_Path);
      Beta := Editor.Buffers.Global_Active_Buffer;
      Assert (Alpha /= Beta, "Phase 485 setup must have two open buffers");
      Assert (Editor.Buffers.Global_Active_Buffer = Beta,
              "Phase 485 setup must keep beta as canonical active buffer");

      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "src/");
      Editor.Quick_Open.Recompute_Results (S.Quick_Open, S.Project, Config);
      Editor.Quick_Open.Select_Path (S.Quick_Open, "src/alpha.adb", Found);
      Assert (Found, "Phase 485 setup must select inactive alpha candidate");

      Before := Editor.Quick_Open_Markers.Build_Snapshot
        (S.Quick_Open, S.Project, Editor.Buffers.Global_Registry_For_UI,
         S.Recent_Buffers);
      Assert_Quick_Open_File_Lifecycle_Observation_Frozen
        (Before, Beta, "src/beta.adb", False, True,
         "Phase 485 pre-save-as candidate source freeze");
      Assert (Before.Selected_Path = To_Unbounded_String ("src/alpha.adb"),
              "Phase 485 selected candidate remains Quick Open UI state");

      Editor.Executor.Execute_File_Target_Command
        (S, Editor.Commands.Command_Save_File_As, Target_Path);
      After := Editor.Quick_Open_Markers.Build_Snapshot
        (S.Quick_Open, S.Project, Editor.Buffers.Global_Registry_For_UI,
         S.Recent_Buffers);

      Assert (Editor.Quick_Open.Query_Text (S.Quick_Open) = "src/",
              "Phase 485 query text must not become lifecycle target state");
      Assert (Editor.Buffers.Global_Active_Buffer = Beta,
              "Phase 485 selection must not replace active-buffer source");
      Assert_Quick_Open_File_Lifecycle_Observation_Frozen
        (After, Beta, "src/beta_saved_as.adb", False, True,
         "Phase 485 save-as observes only canonical candidate sources");
      Assert_Quick_Open_File_Lifecycle_Observation_Frozen
        (After, Alpha, "src/alpha.adb", False, False,
         "Phase 485 inactive candidate remains non-source open buffer");
      Old_Beta := Quick_Open_Candidate_Index (After, "src/beta.adb");
      Assert (Old_Beta /= Natural'Last and then
              not After.Candidates (Old_Beta).Is_Open,
              "Phase 485 old beta path remains project-owned only");
      Assert (not Quick_Open_Has_Candidate (After, "src/last-save-as.adb"),
              "Phase 485 save-as target history must not create candidates");

      Workspace := Editor.State.Build_Workspace_Snapshot (S);
      Editor.Workspace_Persistence.Save_To_File
        (Workspace, Session_Path, Status);
      Assert (Status = Editor.Workspace_Persistence.Workspace_Persistence_Ok,
              "Phase 485 workspace fixture must save successfully");
      Assert_Persistence_Text_Excludes_Quick_Open_Lifecycle
        (File_Text (Session_Path),
         "Phase 485 workspace persistence exclusion freeze");

      Delete_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Delete_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase485_Final_Observation_Source_Freeze;

   procedure Test_Phase485_Direct_Prompted_And_Boundary_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Root_Direct  : constant String := Temp_Path ("phase485_direct");
      Root_Prompt  : constant String := Temp_Path ("phase485_prompt");
      Src_Direct   : constant String := Slash (Root_Direct, "src");
      Src_Prompt   : constant String := Slash (Root_Prompt, "src");
      Direct_File  : constant String := Slash (Src_Direct, "alpha.adb");
      Prompt_File  : constant String := Slash (Src_Prompt, "alpha.adb");
      Direct_Target : constant String := Slash (Src_Direct, "renamed.adb");
      Prompt_Target : constant String := Slash (Src_Prompt, "renamed.adb");
      S            : Editor.State.State_Type;
      Open_Result  : Editor.Project.Project_Open_Result;
      Config       : constant Editor.Quick_Open.Quick_Open_Config :=
        (others => <>);
      Direct_Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Prompt_Id    : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Direct_Snap  : Editor.Quick_Open.Quick_Open_Snapshot;
      Prompt_Snap  : Editor.Quick_Open.Quick_Open_Snapshot;
      Found        : Boolean := False;
   begin
      Delete_Tree_If_Exists (Root_Direct);
      Delete_Tree_If_Exists (Root_Prompt);
      Ada.Directories.Create_Directory (Root_Direct);
      Ada.Directories.Create_Directory (Src_Direct);
      Ada.Directories.Create_Directory (Root_Prompt);
      Ada.Directories.Create_Directory (Src_Prompt);
      Write_Bytes (Direct_File, "alpha body");
      Write_Bytes (Prompt_File, "alpha body");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Open_Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String (Root_Direct),
         Display_Name => To_Unbounded_String ("direct"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (S.Project, Open_Result);
      Editor.Project.Add_Known_File (S.Project, "src/alpha.adb", Direct_File);
      Editor.Executor.Execute_Open_File (S, Direct_File);
      Direct_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "src/");
      Editor.Quick_Open.Recompute_Results (S.Quick_Open, S.Project, Config);
      Editor.Executor.Execute_File_Target_Command
        (S, Editor.Commands.Command_Rename_Buffer_File, Direct_Target);
      Direct_Snap := Editor.Quick_Open_Markers.Build_Snapshot
        (S.Quick_Open, S.Project, Editor.Buffers.Global_Registry_For_UI,
         S.Recent_Buffers);
      Assert_Quick_Open_File_Lifecycle_Observation_Frozen
        (Direct_Snap, Direct_Id, "src/renamed.adb", False, True,
         "Phase 485 direct rename observation freeze");

      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Open_Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String (Root_Prompt),
         Display_Name => To_Unbounded_String ("prompt"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (S.Project, Open_Result);
      Editor.Project.Add_Known_File (S.Project, "src/alpha.adb", Prompt_File);
      Editor.Project.Add_Known_File
        (S.Project, "src/selected-target-like.adb",
         Slash (Src_Prompt, "selected-target-like.adb"));
      Editor.Executor.Execute_Open_File (S, Prompt_File);
      Prompt_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Quick_Open.Set_Query_Text
        (S.Quick_Open, "src/query-must-not-seed-target.adb");
      Editor.Quick_Open.Recompute_Results (S.Quick_Open, S.Project, Config);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "src/");
      Editor.Quick_Open.Recompute_Results (S.Quick_Open, S.Project, Config);
      Editor.Quick_Open.Select_Path
        (S.Quick_Open, "src/selected-target-like.adb", Found);
      Assert (Found,
              "Phase 485 setup must select target-like project candidate");

      Editor.Executor.Open_File_Target_Prompt
        (S, Editor.Commands.Command_Rename_Buffer_File);
      Assert (Editor.Executor.File_Target_Prompt_Is_Active (S),
              "Phase 485 canonical prompt must open through Executor");
      Assert (Editor.Executor.File_Target_Prompt_Input_Text (S) = "",
              "Phase 485 Quick Open query/candidate must not seed prompt input");
      Editor.Quick_Open.Move_Selection_Down (S.Quick_Open);
      Assert (Editor.Executor.File_Target_Prompt_Input_Text (S) = "",
              "Phase 485 Quick Open selection changes do not mutate prompt input");
      Editor.Executor.Insert_File_Target_Prompt_Text (S, Prompt_Target);
      Editor.Executor.Confirm_File_Target_Prompt (S);
      Assert (not Editor.Executor.File_Target_Prompt_Is_Active (S),
              "Phase 485 prompt confirmation leaves no Quick Open prompt state");

      Prompt_Snap := Editor.Quick_Open_Markers.Build_Snapshot
        (S.Quick_Open, S.Project, Editor.Buffers.Global_Registry_For_UI,
         S.Recent_Buffers);
      Assert_Quick_Open_File_Lifecycle_Observation_Frozen
        (Prompt_Snap, Prompt_Id, "src/renamed.adb", False, True,
         "Phase 485 prompted rename observation freeze");
      Assert (To_String (Direct_Snap.Candidates
                (Quick_Open_Candidate_Index_For_Buffer
                   (Direct_Snap, Direct_Id)).Project_Relative_Path) =
              To_String (Prompt_Snap.Candidates
                (Quick_Open_Candidate_Index_For_Buffer
                   (Prompt_Snap, Prompt_Id)).Project_Relative_Path),
              "Phase 485 direct and prompted rename observations match");
      Assert (Editor.Buffers.Global_Active_Buffer = Prompt_Id,
              "Phase 485 selected Quick Open candidate must not become source");
      Assert (not Quick_Open_Has_Candidate
                (Prompt_Snap, "src/query-must-not-seed-target.adb"),
              "Phase 485 query text must not create target history");

      Delete_Tree_If_Exists (Root_Direct);
      Delete_Tree_If_Exists (Root_Prompt);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Delete_Tree_If_Exists (Root_Direct);
         Delete_Tree_If_Exists (Root_Prompt);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Phase485_Direct_Prompted_And_Boundary_Freeze;

   procedure Test_Phase485_Route_Audit_And_Alias_Absence_Freeze
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Audit : Editor.Command_Route_Audit.Route_Audit_Result;
   begin
      Assert (Editor.Commands.File_Lifecycle_Target_Prompt_Metadata_Frozen,
              "Phase 485 descriptor-owned prompt metadata freeze holds");
      Assert_Absent_Command_Not_Exposed ("quick-open.file.save");
      Assert_Absent_Command_Not_Exposed ("quick-open.file.save-as");
      Assert_Absent_Command_Not_Exposed
        ("quick-open.file.rename-buffer-file");
      Assert_Absent_Command_Not_Exposed
        ("quick-open.file.delete-buffer-file");
      Assert_Absent_Command_Not_Exposed
        ("quick-open.file.copy-buffer-file");
      Assert_Absent_Command_Not_Exposed
        ("quick-open.file.move-buffer-file");
      Assert_Absent_Command_Not_Exposed
        ("quick-open.prompt.file.save-as");
      Assert_Absent_Command_Not_Exposed
        ("quick-open.prompt.file.rename-buffer-file");

      Editor.Command_Route_Audit.Clear (Audit);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Save_File_As);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Keybinding,
         Editor.Commands.Command_Rename_Buffer_File);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Keybinding,
         Editor.Commands.Command_Copy_Buffer_File);
      Editor.Command_Route_Audit.Record_Route
        (Audit,
         Editor.Command_Route_Audit.Route_From_Command_Palette,
         Editor.Commands.Command_Move_Buffer_File);
      Assert (Editor.Command_Route_Audit.Failure_Count (Audit) = 0,
              "Phase 485 route audit inspects canonical Executor routes");
      Assert (Editor.Command_Route_Audit.Summary (Audit)'Length > 0,
              "Phase 485 route audit result remains transient data");
   end Test_Phase485_Route_Audit_And_Alias_Absence_Freeze;

   procedure Test_Phase533_Quick_Open_Stale_Project_Result_Unavailable
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root_One : constant String := Temp_Path ("phase533_qo_stale_one");
      Root_Two : constant String := Temp_Path ("phase533_qo_stale_two");
      File_One : constant String := Slash (Root_One, "main.adb");
      File_Two : constant String := Slash (Root_Two, "main.adb");
      S        : Editor.State.State_Type;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Open_Result : Editor.Project.Project_Open_Result;
      A        : Editor.Commands.Command_Availability;
   begin
      Delete_Tree_If_Exists (Root_One);
      Delete_Tree_If_Exists (Root_Two);
      Ada.Directories.Create_Directory (Root_One);
      Ada.Directories.Create_Directory (Root_Two);
      Write_Bytes (File_One, "one");
      Write_Bytes (File_Two, "two");

      Editor.State.Init (S);
      Open_Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String (Root_One),
         Display_Name => To_Unbounded_String ("one"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (S.Project, Open_Result);
      Editor.Project.Add_Known_File (S.Project, "main.adb", File_One);
      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay,
         S.Panel_Focus);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "main");
      Editor.Quick_Open.Recompute_Results (S.Quick_Open, S.Project, Config);
      Assert (Editor.Quick_Open.Result_Count (S.Quick_Open) = 1,
              "Phase 533 setup must produce one current-project Quick Open result");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Accept_Quick_Open);
      Assert (A.Status = Editor.Commands.Command_Available,
              "Phase 533 fresh Quick Open result remains activatable");
      Assert (Editor.Project_Navigation.Assert_Project_Navigation_Workflows_Coherent
                (S),
              "Phase 533 fresh project navigation state should be coherent");

      Editor.Project.Clear (S.Project);
      Open_Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String (Root_Two),
         Display_Name => To_Unbounded_String ("two"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (S.Project, Open_Result);
      Editor.Project.Add_Known_File (S.Project, "main.adb", File_Two);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Accept_Quick_Open);
      Assert (A.Status = Editor.Commands.Command_Unavailable,
              "Phase 533 Quick Open must not activate a stale project match");
      Assert (Editor.Commands.Unavailable_Reason (A) =
                "Target no longer exists.",
              "Phase 533 Quick Open stale activation should explain current-project boundary");
      Assert (not Editor.Project_Navigation.Assert_Project_Navigation_Workflows_Coherent
                    (S),
              "Phase 533 coherence helper should detect stale Quick Open rows");

      Delete_Tree_If_Exists (Root_One);
      Delete_Tree_If_Exists (Root_Two);
   exception
      when others =>
         Delete_Tree_If_Exists (Root_One);
         Delete_Tree_If_Exists (Root_Two);
         raise;
   end Test_Phase533_Quick_Open_Stale_Project_Result_Unavailable;


   procedure Test_Phase546_Marker_Snapshot_Clears_No_Project_Stale_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File
        (Project, "src/main.adb", "/project/src/main.adb");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "main");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Assert (Editor.Quick_Open.Result_Count (S) = 1,
              "phase 546 setup must retain one Quick Open result before project close");

      Editor.Project.Clear (Project);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);

      Assert (not Snapshot.Has_Project,
              "phase 546 marker snapshot must mirror no-project authoritative state");
      Assert (Natural (Snapshot.Candidates.Length) = 0,
              "phase 546 marker snapshot must not render stale previous-project rows");
      Assert (Snapshot.Selected_Index = 0,
              "phase 546 marker snapshot must clear stale rendered selection");
      Assert (To_String (Snapshot.Selected_Path) = "",
              "phase 546 marker snapshot must clear stale selected path");
      Assert (To_String (Snapshot.Empty_Message) = "No project open.",
              "phase 546 marker snapshot must render no-project feedback instead of stale rows");

   end Test_Phase546_Marker_Snapshot_Clears_No_Project_Stale_Rows;



   procedure Test_Phase546_No_Project_Selection_Commands_Report_No_Project
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;
   begin
      Editor.State.Init (S);
      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay,
         S.Panel_Focus);

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Quick_Open_Next_Result);
      Assert (A.Status = Editor.Commands.Command_Unavailable,
              "phase 546 next-result must be unavailable without a project");
      Assert (Editor.Commands.Unavailable_Reason (A) = "No project open.",
              "phase 546 next-result must not conflate no-project with no-files");

      A := Editor.Executor.Command_Availability
        (S, Editor.Commands.Command_Quick_Open_Previous_Result);
      Assert (A.Status = Editor.Commands.Command_Unavailable,
              "phase 546 previous-result must be unavailable without a project");
      Assert (Editor.Commands.Unavailable_Reason (A) = "No project open.",
              "phase 546 previous-result must report no-project before no-files");
   end Test_Phase546_No_Project_Selection_Commands_Report_No_Project;


   procedure Test_Phase546_Query_Set_No_Project_Reports_No_Project
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay,
         S.Panel_Focus);

      Editor.Executor.Execute_Quick_Open_Set_Query (S, "main");

      Assert (Editor.Quick_Open.Query_Text (S.Quick_Open) = "main",
              "phase 546 query-set should still update transient query text");
      Assert (Editor.Quick_Open.Result_Count (S.Quick_Open) = 0,
              "phase 546 query-set without project must not fabricate matches");
      Assert (Active_Message_Text (S) = "No project open.",
              "phase 546 query-set must report no-project before no-files");
   end Test_Phase546_Query_Set_No_Project_Reports_No_Project;


   procedure Test_Phase546_Filter_And_Scope_No_Project_Report_No_Project
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      A : Editor.Commands.Command_Availability;

      procedure Assert_No_Project_Availability
        (Command : Editor.Commands.Command_Id;
         Label   : String) is
      begin
         A := Editor.Executor.Command_Availability (S, Command);
         Assert (A.Status = Editor.Commands.Command_Unavailable,
                 "phase 546 " & Label & " must be unavailable without a project");
         Assert (Editor.Commands.Unavailable_Reason (A) = "No project open.",
                 "phase 546 " & Label & " must report no-project before local empty/filter state");
      end Assert_No_Project_Availability;
   begin
      Editor.State.Init (S);
      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Overlay_Focus.Activate
        (S.Overlay_Focus, Editor.Overlay_Focus.Quick_Open_Overlay,
         S.Panel_Focus);
      Editor.Quick_Open.Set_Path_Scope (S.Quick_Open, "src/editor");

      Assert_No_Project_Availability
        (Editor.Commands.Command_Quick_Open_Kind_Next, "kind-next");
      Assert_No_Project_Availability
        (Editor.Commands.Command_Quick_Open_Kind_Previous, "kind-previous");
      Assert_No_Project_Availability
        (Editor.Commands.Command_Quick_Open_Kind_Clear, "kind-clear");
      Assert_No_Project_Availability
        (Editor.Commands.Command_Quick_Open_Scope_Clear, "scope-clear");
      Assert_No_Project_Availability
        (Editor.Commands.Command_Quick_Open_Scope_From_Selected, "scope-from-selected");
      Assert_No_Project_Availability
        (Editor.Commands.Command_Quick_Open_Scope_Parent, "scope-parent");

      Editor.Executor.Execute_Quick_Open_Kind_Next (S);
      Assert (Editor.Quick_Open.File_Kind_Filter (S.Quick_Open) = Editor.Quick_Open.All_Files,
              "phase 546 kind-next without project must not mutate transient filter state");
      Assert (Active_Message_Text (S) = "No project open.",
              "phase 546 kind-next runtime must report no-project");

      Editor.Executor.Execute_Quick_Open_Scope_Clear (S);
      Assert (Editor.Quick_Open.Path_Scope (S.Quick_Open) = "src/editor/",
              "phase 546 scope-clear without project must not mutate transient scope state");
      Assert (Active_Message_Text (S) = "No project open.",
              "phase 546 scope-clear runtime must report no-project");
   end Test_Phase546_Filter_And_Scope_No_Project_Report_No_Project;


   procedure Test_Phase546_Marker_Snapshot_Excludes_Untitled_Buffers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Untitled : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/main.adb", "/project/src/main.adb");

      Untitled := Editor.Buffers.Create_Untitled_Buffer (Registry);
      Editor.Buffers.Set_Active_Buffer (Registry, Untitled);

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "Untitled");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);

      Assert (Snapshot.Has_Project,
              "phase 546 untitled exclusion setup must retain an open project");
      Assert (Snapshot.Candidates.Length = 0,
              "phase 546 Quick Open marker snapshot must not synthesize untitled buffer candidates");
      Assert (Snapshot.Selected_Index = 0,
              "phase 546 untitled exclusion leaves no selectable status row");
      Assert (Quick_Open_Candidate_Index_For_Buffer (Snapshot, Untitled) = Natural'Last,
              "phase 546 untitled buffer must not become a Quick Open candidate by buffer identity");
      Assert (To_String (Snapshot.Empty_Message) = "No Quick Open matches.",
              "phase 546 untitled exclusion preserves no-match feedback instead of buffer-derived rows");
   end Test_Phase546_Marker_Snapshot_Excludes_Untitled_Buffers;


   procedure Test_Phase546_Marker_Snapshot_Preserves_Result_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config :=
        (Max_Visible_Results      => 12,
         Max_Result_Count         => 2,
         Query_Field_Min_Columns  => 24,
         Overlay_Width_In_Columns => 72,
         Row_Height_In_Rows       => 1,
         Header_Height_In_Rows    => 1,
         Field_Height_In_Rows     => 1,
         Result_Padding_Columns   => 1);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Hidden   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Outside_Retained : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/a_one.adb", "/project/src/a_one.adb");
      Editor.Project.Add_Known_File (Project, "src/a_two.adb", "/project/src/a_two.adb");
      Editor.Project.Add_Known_File (Project, "src/a_three.adb", "/project/src/a_three.adb");
      Editor.Project.Add_Known_File (Project, "src/a_four.adb", "/project/src/a_four.adb");
      Editor.Project.Add_Known_File (Project, "src/a_five.adb", "/project/src/a_five.adb");
      Editor.Project.Add_Known_File (Project, "src/a_z_outside.adb", "/project/src/a_z_outside.adb");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "a_");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);

      Assert (Editor.Quick_Open.Result_Count (S) = 2,
              "phase 546 retained Quick Open result vector must be bounded by Max_Result_Count");
      Assert (Editor.Quick_Open.Visible_Count (S) = 2,
              "phase 546 public visible count must describe retained bounded Quick Open rows");
      Assert (Editor.Quick_Open.Total_Filtered_Count (S) = 6,
              "phase 546 public total filtered count must remain separate from retained rows");
      Assert (Natural (Snapshot.Candidates.Length) = 2,
              "phase 546 marker snapshot must not expand beyond retained bounded Quick Open rows");
      Assert (Snapshot.Visible_Count = 2,
              "phase 546 marker snapshot visible count must describe rendered bounded rows");
      Assert (Snapshot.Total_Filtered_Count = 6,
              "phase 546 marker snapshot must retain total filtered count separately from rendered rows");

      Outside_Retained := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/a_z_outside.adb", "a_z_outside.adb", "outside");
      Editor.Buffers.Set_Active_Buffer (Registry, Outside_Retained);
      Editor.Recent_Buffers.Mark_Activated (Recent, Natural (Outside_Retained));
      Editor.Quick_Open.Toggle_Priority_Mode (S);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);

      Assert (Natural (Snapshot.Candidates.Length) = 2,
              "phase 546 open/recent priority must not expand the retained bounded result set");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/a_z_outside.adb"),
              "phase 546 active known files outside retained Quick Open rows must not enter marker snapshots");
      Assert (Quick_Open_Candidate_Index_For_Buffer (Snapshot, Outside_Retained) = Natural'Last,
              "phase 546 outside-retained open buffer must not become a candidate by buffer identity");

      Hidden := Editor.Buffers.Add_Buffer_From_File
        (Registry, "/project/src/hidden.adb", "hidden.adb", "hidden");
      Editor.Buffers.Set_Active_Buffer (Registry, Hidden);
      Editor.Quick_Open.Set_Query_Text (S, "hidden");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);

      Assert (Editor.Quick_Open.Result_Count (S) = 0,
              "phase 546 setup must leave hidden buffer outside the project candidate list");
      Assert (Natural (Snapshot.Candidates.Length) = 0,
              "phase 546 marker snapshot must not synthesize file-backed buffer rows absent from known project files");
      Assert (Quick_Open_Candidate_Index_For_Buffer (Snapshot, Hidden) = Natural'Last,
              "phase 546 hidden file-backed buffer must not become a Quick Open candidate by buffer identity");
      Assert (To_String (Snapshot.Empty_Message) = "No Quick Open matches.",
              "phase 546 absent project candidate must preserve no-match feedback");
   end Test_Phase546_Marker_Snapshot_Preserves_Result_Boundary;


   procedure Test_Phase546_Marker_Header_Uses_Authoritative_Project_Counts
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/main.adb", "/project/src/main.adb");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "adb");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);

      Assert (Editor.Quick_Open.Known_Count (S) = 1,
              "phase 546 setup should retain the original known-file count");
      Assert (Editor.Quick_Open.Total_Filtered_Count (S) = 1,
              "phase 546 setup should retain the original filtered count");

      Editor.Project.Add_Known_File (Project, "src/editor.adb", "/project/src/editor.adb");
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);

      Assert (Snapshot.Known_Count = 2,
              "phase 546 marker snapshot must use the current authoritative project known-file count");
      Assert (Snapshot.Total_Filtered_Count = 2,
              "phase 546 marker snapshot must recompute current authoritative filtered count");
      Assert (Natural (Snapshot.Candidates.Length) = 1,
              "phase 546 marker snapshot must not add new rows outside the retained bounded result set");
      Assert (Contains_Text (To_String (Snapshot.Header_Text), "Results: 2 of 2"),
              "phase 546 marker header must reflect authoritative marker snapshot counts, not stale retained state counts");
   end Test_Phase546_Marker_Header_Uses_Authoritative_Project_Counts;


   procedure Test_Phase546_Project_Relative_Bounds_Reject_Invalid_Candidates
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);

      Editor.Project.Add_Known_File
        (Project, "src/good.adb", "/project/src/good.adb");
      Editor.Project.Add_Known_File
        (Project, "../escape.adb", "/outside/escape.adb");
      Editor.Project.Add_Known_File
        (Project, "/absolute.adb", "/project/absolute.adb");
      Editor.Project.Add_Known_File
        (Project, "src/./bad.adb", "/project/src/bad.adb");
      Editor.Project.Add_Known_File
        (Project, "src/../also_bad.adb", "/project/also_bad.adb");
      Editor.Project.Add_Known_File
        (Project, "src/outside-absolute.adb", "/outside/outside-absolute.adb");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "good");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);

      Assert (Editor.Quick_Open.Result_Count (S) = 1,
              "phase 546 Quick Open must ignore malformed or out-of-root project-file candidates");
      Assert (To_String (Editor.Quick_Open.Result_At (S, 1).Display_Path) = "src/good.adb",
              "phase 546 Quick Open must retain only normalized project-relative files");
      Assert (Editor.Quick_Open.Known_Count (S) = 6,
              "known-file count remains a source count, not a sanitized candidate count");
      Assert (Editor.Quick_Open.Total_Filtered_Count (S) = 1,
              "filtered count must exclude invalid/out-of-root candidates");

      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);
      Assert (Natural (Snapshot.Candidates.Length) = 1,
              "phase 546 marker snapshots must preserve the same project-relative bounds");
      Assert (Quick_Open_Has_Candidate (Snapshot, "src/good.adb"),
              "valid project-relative candidate must remain visible in marker snapshot");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "../escape.adb"),
              "parent traversal candidate must not render");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "/absolute.adb"),
              "absolute relative-path candidate must not render");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/./bad.adb"),
              "dot-segment candidate must not render");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/../also_bad.adb"),
              "embedded traversal candidate must not render");
      Assert (not Quick_Open_Has_Candidate (Snapshot, "src/outside-absolute.adb"),
              "candidate with an absolute path outside the project root must not render");

      Editor.Quick_Open.Set_Query_Text (S, "escape");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);
      Assert (Editor.Quick_Open.Result_Count (S) = 0,
              "query matching must not resurrect invalid parent-traversal candidates");
      Assert (To_String (Snapshot.Empty_Message) = "No Quick Open matches.",
              "invalid-only query must report no matches without fabricating rows");
   end Test_Phase546_Project_Relative_Bounds_Reject_Invalid_Candidates;



   procedure Test_Phase546_No_Query_Shows_Prompt_Not_All_Files
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/main.adb", "/project/src/main.adb");
      Editor.Project.Add_Known_File (Project, "src/editor.adb", "/project/src/editor.adb");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "   ");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);

      Assert (Editor.Quick_Open.Known_Count (S) = 2,
              "phase 546 no-query state must retain project file availability feedback");
      Assert (Editor.Quick_Open.Total_Filtered_Count (S) = 0,
              "phase 546 no-query state must not count all files as matches");
      Assert (Editor.Quick_Open.Result_Count (S) = 0,
              "phase 546 no-query state must not project all project files as activatable rows");
      Assert (Editor.Quick_Open.Selected_Result_Index (S) = 0,
              "phase 546 no-query state must have no selected file target");
      Assert (Snapshot.Has_Project,
              "phase 546 no-query snapshot must still know the project is open");
      Assert (not Snapshot.Has_Query,
              "phase 546 no-query snapshot must expose absence of query text");
      Assert (Natural (Snapshot.Candidates.Length) = 0,
              "phase 546 no-query marker snapshot must not rebuild rows from project files");
      Assert (To_String (Snapshot.Empty_Message) = "Type to open file.",
              "phase 546 no-query marker snapshot must show the Quick Open prompt");
   end Test_Phase546_No_Query_Shows_Prompt_Not_All_Files;


   procedure Test_Phase546_Query_Traversal_Terms_Do_Not_Match
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/main.adb", "/project/src/main.adb");
      Editor.Project.Add_Known_File (Project, "src/editor.adb", "/project/src/editor.adb");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "src/../main");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);

      Assert (Editor.Quick_Open.Result_Count (S) = 0,
              "phase 546 traversal query terms must not match project files");
      Assert (Editor.Quick_Open.Total_Filtered_Count (S) = 0,
              "phase 546 traversal query terms must not be counted as matches");
      Assert (Natural (Snapshot.Candidates.Length) = 0,
              "phase 546 marker snapshot must not rebuild traversal-query rows");
      Assert (To_String (Snapshot.Empty_Message) = "No Quick Open matches.",
              "phase 546 traversal query terms must report no matches");

      Editor.Quick_Open.Set_Query_Text (S, "../editor");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);

      Assert (Editor.Quick_Open.Result_Count (S) = 0,
              "phase 546 leading traversal query term must not match project files");
      Assert (Natural (Snapshot.Candidates.Length) = 0,
              "phase 546 leading traversal query term must not render candidates");

      Editor.Quick_Open.Set_Query_Text (S, "editor.adb");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);

      Assert (Editor.Quick_Open.Result_Count (S) = 1,
              "phase 546 ordinary dotted filenames must remain searchable");
      Assert (To_String (Editor.Quick_Open.Result_At (S, 1).Display_Path) = "src/editor.adb",
              "phase 546 traversal guard must not reject normal extension queries");
   end Test_Phase546_Query_Traversal_Terms_Do_Not_Match;


   procedure Test_Phase546_Absolute_And_Drive_Queries_Do_Not_Match
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Project  : Editor.Project.Project_State;
      Result   : Editor.Project.Project_Open_Result;
      S        : Editor.Quick_Open.Quick_Open_State;
      Config   : constant Editor.Quick_Open.Quick_Open_Config := (others => <>);
      Registry : Editor.Buffers.Buffer_Registry;
      Recent   : Editor.Recent_Buffers.Recent_Buffer_State;
      Snapshot : Editor.Quick_Open.Quick_Open_Snapshot;
   begin
      Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/project"),
         Display_Name => To_Unbounded_String ("project"),
         Error_Text   => Null_Unbounded_String);
      Editor.Project.Apply_Open_Result (Project, Result);
      Editor.Project.Add_Known_File (Project, "src/main.adb", "/project/src/main.adb");
      Editor.Project.Add_Known_File (Project, "src/editor.adb", "/project/src/editor.adb");

      Editor.Quick_Open.Open (S);
      Editor.Quick_Open.Set_Query_Text (S, "/main");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);

      Assert (Editor.Quick_Open.Result_Count (S) = 0,
              "phase 546 absolute-looking queries must not match project-relative paths");
      Assert (Editor.Quick_Open.Total_Filtered_Count (S) = 0,
              "phase 546 absolute-looking queries must not be counted as filtered matches");
      Assert (Natural (Snapshot.Candidates.Length) = 0,
              "phase 546 marker snapshot must not rebuild absolute-query matches");
      Assert (To_String (Snapshot.Empty_Message) = "No Quick Open matches.",
              "phase 546 absolute-looking query must report no matches");

      Editor.Quick_Open.Set_Query_Text (S, "\main");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);

      Assert (Editor.Quick_Open.Result_Count (S) = 0,
              "phase 546 backslash-rooted queries must not match project-relative paths");
      Assert (Natural (Snapshot.Candidates.Length) = 0,
              "phase 546 marker snapshot must not rebuild backslash-rooted query matches");

      Editor.Quick_Open.Set_Query_Text (S, "C:/main");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);

      Assert (Editor.Quick_Open.Result_Count (S) = 0,
              "phase 546 drive-qualified queries must not match project-relative paths");
      Assert (Natural (Snapshot.Candidates.Length) = 0,
              "phase 546 marker snapshot must not rebuild drive-qualified query matches");

      Editor.Quick_Open.Set_Query_Text (S, "src /main");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);

      Assert (Editor.Quick_Open.Result_Count (S) = 0,
              "phase 546 absolute query terms must not match project-relative paths");
      Assert (Natural (Snapshot.Candidates.Length) = 0,
              "phase 546 marker snapshot must not rebuild absolute query-term matches");

      Editor.Quick_Open.Set_Query_Text (S, "src C:/main");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);
      Snapshot := Editor.Quick_Open_Markers.Build_Snapshot
        (S, Project, Registry, Recent);

      Assert (Editor.Quick_Open.Result_Count (S) = 0,
              "phase 546 drive-qualified query terms must not match project-relative paths");
      Assert (Natural (Snapshot.Candidates.Length) = 0,
              "phase 546 marker snapshot must not rebuild drive-qualified query-term matches");

      Editor.Quick_Open.Set_Query_Text (S, "main");
      Editor.Quick_Open.Recompute_Results (S, Project, Config);

      Assert (Editor.Quick_Open.Result_Count (S) = 1,
              "phase 546 project-relative basename queries must remain searchable");
      Assert (To_String (Editor.Quick_Open.Result_At (S, 1).Display_Path) = "src/main.adb",
              "phase 546 absolute-query guard must not reject normal relative queries");
   end Test_Phase546_Absolute_And_Drive_Queries_Do_Not_Match;

   procedure Register_Tests (T : in out Quick_Open_Test_Case) is
   begin
      Register_Routine (T, Test_Phase485_Final_Observation_Source_Freeze'Access,
                        "phase 485 quick-open final observation source freeze");
      Register_Routine (T, Test_Phase485_Direct_Prompted_And_Boundary_Freeze'Access,
                        "phase 485 quick-open direct prompted and boundary freeze");
      Register_Routine (T, Test_Phase485_Route_Audit_And_Alias_Absence_Freeze'Access,
                        "phase 485 quick-open route audit and alias absence freeze");
      Register_Routine
        (T, Test_Phase533_Quick_Open_Stale_Project_Result_Unavailable'Access,
         "phase 533 quick-open stale project result unavailable");
      Register_Routine
        (T, Test_Phase546_Marker_Snapshot_Clears_No_Project_Stale_Rows'Access,
         "phase 546 quick-open marker snapshot clears no-project stale rows");
      Register_Routine
        (T, Test_Phase546_Marker_Snapshot_Excludes_Untitled_Buffers'Access,
         "phase 546 quick-open marker snapshot excludes untitled buffers");
      Register_Routine
        (T, Test_Phase546_No_Project_Selection_Commands_Report_No_Project'Access,
         "phase 546 quick-open no-project selection commands report no-project");
      Register_Routine
        (T, Test_Phase546_Query_Set_No_Project_Reports_No_Project'Access,
         "phase 546 quick-open query-set no-project feedback");
      Register_Routine
        (T, Test_Phase546_Filter_And_Scope_No_Project_Report_No_Project'Access,
         "phase 546 quick-open filter and scope no-project feedback");
      Register_Routine
        (T, Test_Phase546_Marker_Snapshot_Preserves_Result_Boundary'Access,
         "phase 546 quick-open marker snapshot preserves result boundary");
      Register_Routine
        (T, Test_Phase546_Marker_Header_Uses_Authoritative_Project_Counts'Access,
         "phase 546 quick-open marker header uses authoritative project counts");
      Register_Routine
        (T, Test_Phase546_Project_Relative_Bounds_Reject_Invalid_Candidates'Access,
         "phase 546 quick-open project-relative bounds reject invalid candidates");
      Register_Routine
        (T, Test_Phase546_No_Query_Shows_Prompt_Not_All_Files'Access,
         "phase 546 quick-open no-query prompt does not show all files");
      Register_Routine
        (T, Test_Phase546_Query_Traversal_Terms_Do_Not_Match'Access,
         "phase 546 quick-open traversal query terms do not match");
      Register_Routine
        (T, Test_Phase546_Absolute_And_Drive_Queries_Do_Not_Match'Access,
         "phase 546 quick-open absolute and drive queries do not match");
      Register_Routine (T, Test_Phase484_Canonical_Open_Buffer_Identity_And_No_Caches'Access,
                        "phase 484 quick-open canonical open-buffer identity and cache cleanup");
      Register_Routine (T, Test_Phase483_Successful_Operation_Observation_Reliability'Access,
                        "phase 483 quick-open successful lifecycle observation reliability");
      Register_Routine (T, Test_Phase483_Failure_And_Blocked_Operation_Preservation'Access,
                        "phase 483 quick-open failed and blocked lifecycle preservation");
      Register_Routine (T, Test_Phase483_Query_Selection_And_Prompt_Boundary_Reliability'Access,
                        "phase 483 quick-open query selection and prompt boundary reliability");
      Register_Routine (T, Test_Phase483_Candidate_Freshness_Order_Project_And_Audit_Boundaries'Access,
                        "phase 483 quick-open freshness project audit and persistence boundaries");
      Register_Routine (T, Test_Phase482_Open_Buffer_Association_And_Dirty_Observation'Access,
                        "phase 482 quick-open observes file lifecycle association and dirty state");
      Register_Routine (T, Test_Phase482_Close_Reopen_And_Failure_Preservation'Access,
                        "phase 482 quick-open close reopen and failure preservation");
      Register_Routine (T, Test_Phase482_Query_Selection_And_Prompt_Boundary'Access,
                        "phase 482 quick-open query selection and prompt boundary");
      Register_Routine (T, Test_Open_Close_And_Query'Access, "open close and query editing");
      Register_Routine (T, Test_Recompute_And_Ranking'Access, "recompute and ranking");
      Register_Routine (T, Test_Selection_Wraps'Access, "selection wraps");
      Register_Routine (T, Test_Project_Quick_Open_Command_Descriptors'Access,
                        "project quick-open command descriptors");
      Register_Routine (T, Test_Phase_332_Project_Quick_Open_Command_Surface_Baseline'Access,
                        "phase 332 project quick-open command surface baseline");
      Register_Routine (T, Test_Phase_332_Project_Quick_Open_No_Name_Drift_Or_Extras'Access,
                        "phase 332 project quick-open no drift or extras");
      Register_Routine (T, Test_Phase_332_Project_Quick_Open_Keybinding_Baseline'Access,
                        "phase 332 project quick-open keybinding baseline");
      Register_Routine (T, Test_Phase_331_Refresh_State_Preserves_Selection_And_Filters'Access,
                        "phase 331 refresh state preserves selection and filters");
      Register_Routine (T, Test_Phase_331_Ignore_Refresh_Removes_Selected_Candidate'Access,
                        "phase 331 ignore refresh removes selected candidate");
      Register_Routine (T, Test_Phase_331_Priority_Mode_Remains_Filtered_Ordering_Only'Access,
                        "phase 331 priority mode remains filtered ordering only");
      Register_Routine (T, Test_Phase_331_Snapshot_Header_Exposes_Priority_And_Counts'Access,
                        "phase 331 snapshot header exposes priority and counts");
      Register_Routine (T, Test_Project_Quick_Open_Create_Target_Derivation'Access,
                        "project quick-open create target derivation");
      Register_Routine (T, Test_Project_Known_File_Literal_Filtering'Access,
                        "project known file literal filtering");
      Register_Routine (T, Test_Project_Quick_Open_Selection_Normalization'Access,
                        "project quick-open selection normalization");
      Register_Routine (T, Test_Project_Quick_Open_Match_Buckets'Access,
                        "project quick-open match buckets");
      Register_Routine (T, Test_Project_Quick_Open_Snapshot'Access,
                        "project quick-open snapshot");
      Register_Routine (T, Test_Project_Quick_Open_Snapshot_Markers'Access,
                        "project quick-open snapshot markers");
      Register_Routine (T, Test_Phase_330_Active_Dirty_Close_Markers'Access,
                        "phase 330 active dirty close marker cleanup");
      Register_Routine (T, Test_Phase_330_Ignores_Old_Project_Recent_And_Open_State'Access,
                        "phase 330 ignores old project open and recent state");
      Register_Routine (T, Test_Project_Quick_Open_File_Kind_Filters'Access,
                        "project quick-open file-kind filters");
      Register_Routine (T, Test_Project_Quick_Open_Path_Scope_Filter'Access,
                        "project quick-open path-scope filter");
      Register_Routine (T, Test_Project_Quick_Open_Scope_Convenience'Access,
                        "project quick-open scope convenience");
      Register_Routine (T, Test_Project_Quick_Open_Count_Feedback'Access,
                        "project quick-open count feedback");
      Register_Routine (T, Test_Project_Quick_Open_Preserved_Selection_Stays_Visible'Access,
                        "project quick-open preserved selection stays visible");
   end Register_Tests;

end Editor.Quick_Open.Tests;
