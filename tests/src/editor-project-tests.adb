with Editor.Test_Temp;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Containers;
with Ada.Directories;
with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Commands;
with Editor.File_Tree;
with Editor.Executor;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Command_Surface_Commands;
with Editor.Executor.Quick_Open_Commands;
with Editor.Executor.File_Tree_Commands;
with Editor.Executor.Project_File_Index_Commands;
with Editor.Executor.File_Save_Basic_Commands;
with Editor.Executor.File_Operation_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Project_Search_Result_Commands;
with Editor.Messages;
with Editor.Project_Search;
with Editor.Project;
with Editor.Quick_Open;
with Editor.Recent_Projects;
with Editor.State;
with Editor.Test_Helper;
with Editor.History;
with Text_Buffer;

package body Editor.Project.Tests is

   use type Editor.Project.Project_Open_Status;
   use type Editor.Project.Project_File_Refresh_Status;
   use type Editor.Quick_Open.Quick_Open_Priority_Mode;
   use type Editor.Commands.Command_Id;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Messages.Message_Severity;
   use type Editor.Recent_Projects.Recent_Project_Status;
   use type Ada.Containers.Count_Type;
   use type Ada.Directories.File_Kind;

   package Stream_IO renames Ada.Streams.Stream_IO;

   function Temp_Path (Name : String) return String is
   begin
      Ada.Directories.Create_Path (Editor.Test_Temp.Base & "/editor-tests");
      return Ada.Directories.Compose
        (Editor.Test_Temp.Base & "/editor-tests", "" & Name);
   end Temp_Path;

   procedure Remove_If_Exists (Path : String) is
   begin
      if Ada.Directories.Exists (Path) then
         if Ada.Directories.Kind (Path) = Ada.Directories.Directory then
            Ada.Directories.Delete_Tree (Path);
         else
            Ada.Directories.Delete_File (Path);
         end if;
      end if;
   end Remove_If_Exists;

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

   function Last_Message_Text (S : Editor.State.State_Type) return String is
      Found : Boolean;
      Msg   : constant Editor.Messages.Editor_Message :=
        Editor.Messages.Active_Message (S.Messages, Found);
   begin
      if Found then
         return To_String (Msg.Text);
      else
         return "";
      end if;
   end Last_Message_Text;


   function Known_File_Present
     (State : Editor.Project.Project_State;
      Relative_Path : String) return Boolean
   is
   begin
      for I in 1 .. Editor.Project.Known_File_Count (State) loop
         if To_String (Editor.Project.Known_File_At (State, I).Relative_Path) = Relative_Path then
            return True;
         end if;
      end loop;
      return False;
   end Known_File_Present;

   function Project_Search_Has_Result_Path
     (Search : Editor.Project_Search.Project_Search_State;
      Relative_Path : String) return Boolean
   is
   begin
      for I in 1 .. Editor.Project_Search.Result_Count (Search) loop
         if To_String (Editor.Project_Search.Result_At (Search, I).Relative_Path) = Relative_Path then
            return True;
         end if;
      end loop;
      return False;
   end Project_Search_Has_Result_Path;

   function Descriptor_Exists (Id : Editor.Commands.Command_Id) return Boolean is
      Descriptors : constant Editor.Commands.Command_Descriptor_Vectors.Vector :=
        Editor.Commands.Palette_Commands;
   begin
      for D of Descriptors loop
         if D.Id = Id then
            return True;
         end if;
      end loop;
      return False;
   end Descriptor_Exists;

   overriding function Name
     (T : Project_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Project");
   end Name;

   procedure Test_State_Clear_And_Query
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Project.Project_State;
   begin
      Assert (not Editor.Project.Has_Project (State),
              "Default project state must have no project");
      Editor.Project.Clear (State);
      Assert (not Editor.Project.Has_Project (State),
              "Clear must remove the project root");
      Assert (Editor.Project.Root_Path (State) = "",
              "Clear must reset the stored root path");
   end Test_State_Clear_And_Query;

   procedure Test_Open_Project_Validation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Missing : constant String := Temp_Path ("missing_project");
      File_P  : constant String := Temp_Path ("project_file.txt");
      Dir_P   : constant String := Temp_Path ("project_dir");
      Result  : Editor.Project.Project_Open_Result;
   begin
      Remove_If_Exists (Missing);
      Remove_If_Exists (File_P);
      Remove_If_Exists (Dir_P);

      Result := Editor.Project.Open_Project ("");
      Assert (Result.Status = Editor.Project.Project_Open_Invalid_Path,
              "Open_Project must reject an empty path");

      Result := Editor.Project.Open_Project (Missing);
      Assert (Result.Status = Editor.Project.Project_Open_Not_Found,
              "Open_Project must reject a missing path");

      Write_Bytes (File_P, "not a dir");
      Result := Editor.Project.Open_Project (File_P);
      Assert (Result.Status = Editor.Project.Project_Open_Not_Directory,
              "Open_Project must reject a regular file path");

      Ada.Directories.Create_Directory (Dir_P);
      Result := Editor.Project.Open_Project (Dir_P);
      Assert (Result.Status = Editor.Project.Project_Open_Ok,
              "Open_Project must accept an existing directory");
      Assert (To_String (Result.Display_Name) = "project_dir",
              "Open_Project must derive the directory display name");

      Remove_If_Exists (File_P);
      Remove_If_Exists (Dir_P);
   end Test_Open_Project_Validation;

   procedure Test_Result_Helpers_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : Editor.Project.Project_Open_Result;
   begin
      Result.Status := Editor.Project.Project_Open_Ok;
      Assert (Editor.Project.Is_Success (Result),
              "Is_Success must accept only Project_Open_Ok");
      Assert (Editor.Project.Status_Message (Result) = "ok",
              "Success status message must be deterministic");

      Result.Status := Editor.Project.Project_Open_Not_Found;
      Assert (not Editor.Project.Is_Success (Result),
              "Is_Success must reject failures");
      Assert (Editor.Project.Status_Message (Result) = "not found",
              "Missing status message must be deterministic");

      Result.Status := Editor.Project.Project_Open_Not_Directory;
      Assert (Editor.Project.Status_Message (Result) = "not a directory",
              "Not-directory status message must be deterministic");

      Result.Status := Editor.Project.Project_Open_Invalid_Path;
      Assert (Editor.Project.Status_Message (Result) = "invalid path",
              "Invalid-path status message must be deterministic");

      Result.Status := Editor.Project.Project_Open_Permission_Denied;
      Assert (Editor.Project.Status_Message (Result) = "permission denied",
              "Permission-denied status message must be deterministic");

      Result.Status := Editor.Project.Project_Open_Error;
      Assert (Editor.Project.Status_Message (Result) = "project open error",
              "Generic project-open status message must be deterministic");
   end Test_Result_Helpers_Are_Deterministic;

   procedure Test_Apply_Open_Result_Only_Applies_Success
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Dir_P  : constant String := Temp_Path ("apply_project");
      State  : Editor.Project.Project_State;
      Good   : Editor.Project.Project_Open_Result;
      Bad    : Editor.Project.Project_Open_Result;
      Before : Unbounded_String;
   begin
      Remove_If_Exists (Dir_P);
      Ada.Directories.Create_Directory (Dir_P);
      Good := Editor.Project.Open_Project (Dir_P);
      Editor.Project.Apply_Open_Result (State, Good);
      Assert (Editor.Project.Has_Project (State),
              "Successful open result must set project state");
      Before := To_Unbounded_String (Editor.Project.Root_Path (State));

      Bad.Status := Editor.Project.Project_Open_Not_Found;
      Bad.Root_Path := To_Unbounded_String ("/does/not/exist");
      Bad.Display_Name := To_Unbounded_String ("bad");
      Editor.Project.Apply_Open_Result (State, Bad);
      Assert (To_String (Before) = Editor.Project.Root_Path (State),
              "Failed open result must not change project state");
      Remove_If_Exists (Dir_P);
   end Test_Apply_Open_Result_Only_Applies_Success;

   procedure Test_Project_Relative_Path_Helpers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("relative_root");
      Subdir : constant String := Ada.Directories.Compose (Root, "src");
      File_P : constant String := Ada.Directories.Compose (Subdir, "main.adb");
      Other  : constant String := Temp_Path ("outside.adb");
      State  : Editor.Project.Project_State;
      Result : Editor.Project.Project_Open_Result;
   begin
      Remove_If_Exists (Other);
      Remove_If_Exists (Subdir);
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Subdir);
      Write_Bytes (File_P, "procedure Main is begin null; end Main;");
      Write_Bytes (Other, "outside");

      Result := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (State, Result);

      Assert (Editor.Project.Is_Under_Project (State, File_P),
              "File below root must be under project");
      Assert (Editor.Project.Is_Under_Project (State, Root),
              "Root itself must be under project");
      Assert (not Editor.Project.Is_Under_Project (State, Other),
              "Outside file must not be under project");
      Assert (Editor.Project.Relative_Path (State, Root) = ".",
              "Relative path for root itself must be dot");
      Assert (Editor.Project.Relative_Path (State, File_P) = "src/main.adb",
              "Relative path must be stable for a file under root");
      Assert (Editor.Project.Relative_Path (State, Other) = Other,
              "Relative path for outside file must return the original path");

      Remove_If_Exists (File_P);
      Remove_If_Exists (Other);
      Remove_If_Exists (Subdir);
      Remove_If_Exists (Root);
   end Test_Project_Relative_Path_Helpers;

   procedure Test_Execute_Open_Project_Updates_State_And_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Root : constant String := Temp_Path ("exec_project");
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Editor.State.Init (S);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Assert (Editor.Project.Has_Project (S.Project),
              "Execute_Open_Project must set editor-global project state");
      Assert (Editor.Project.Display_Name (S.Project) = "exec_project",
              "Execute_Open_Project must store the project display name");
      Assert (Last_Message_Text (S) = "Opened project exec_project",
              "Execute_Open_Project must publish a success message");
      Remove_If_Exists (Root);
   end Test_Execute_Open_Project_Updates_State_And_Message;

   procedure Test_Execute_Open_Project_Failure_Preserves_Previous_Project
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Root    : constant String := Temp_Path ("preserve_project");
      Missing : constant String := Temp_Path ("missing_after_project");
      Before  : Unbounded_String;
   begin
      Remove_If_Exists (Root);
      Remove_If_Exists (Missing);
      Ada.Directories.Create_Directory (Root);
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Before := To_Unbounded_String (Editor.Project.Root_Path (S.Project));

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Missing);

      Assert (Editor.Project.Root_Path (S.Project) = To_String (Before),
              "Failed project open must preserve previous project state");
      Assert (Last_Message_Text (S) = "Open project failed: not found",
              "Failed project open must publish a deterministic failure message");
      Remove_If_Exists (Root);
   end Test_Execute_Open_Project_Failure_Preserves_Previous_Project;

   procedure Test_Execute_Open_Project_Is_Non_Destructive
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Root       : constant String := Temp_Path ("non_destructive_project");
      First      : Editor.Buffers.Buffer_Id;
      Second     : Editor.Buffers.Buffer_Id;
      Active     : Editor.Buffers.Buffer_Id;
      Count      : Natural;
      Dirty      : Boolean;
      Text_Before : Unbounded_String;
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      First := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Second := Editor.Buffers.Global_Active_Buffer;
      Editor.State.Load_Text (S, "dirty text");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Insert (0, 'x'));
      Text_Before := To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
      S.File_Info.Dirty := True;
      Editor.Buffers.Sync_Global_Active_From_State (S);
      Active := Editor.Buffers.Global_Active_Buffer;
      Count := Editor.Buffers.Global_Count;
      Dirty := S.File_Info.Dirty;

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Assert (Editor.Buffers.Global_Count = Count,
              "Open project must not close buffers");
      Assert (Editor.Buffers.Global_Active_Buffer = Active,
              "Open project must not switch the active buffer");
      Assert (Active = Second and then Active /= First,
              "Test setup must have a distinct active buffer");
      Assert (S.File_Info.Dirty = Dirty,
              "Open project must not clear dirty state");
      Assert (Text_Buffer.UTF8_Text (S.Buffer) = To_String (Text_Before),
              "Open project must not replace active buffer contents");
      Assert (not Editor.History.Undo_Stack.Is_Empty,
              "Open project must not clear undo history");
      Remove_If_Exists (Root);
   end Test_Execute_Open_Project_Is_Non_Destructive;




   procedure Test_Execute_Refresh_File_Tree
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S      : Editor.State.State_Type;
      Root   : constant String := Temp_Path ("refresh_tree_project");
      File_P : constant String := Ada.Directories.Compose (Root, "file.txt");
   begin
      Remove_If_Exists (File_P);
      Remove_If_Exists (Root);
      Editor.State.Init (S);

      Editor.Executor.Project_File_Index_Commands.Execute_Refresh_File_Tree (S);
      Assert (Editor.File_Tree.Is_Empty (S.File_Tree),
              "Refresh without a project must leave the file tree empty");
      Assert (Last_Message_Text (S) = "No project open.",
              "Refresh without a project must publish a deterministic warning");

      Ada.Directories.Create_Directory (Root);
      Write_Bytes (File_P, "file");
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.File_Tree.Clear (S.File_Tree);
      Editor.Executor.Project_File_Index_Commands.Execute_Refresh_File_Tree (S);

      Assert (not Editor.File_Tree.Is_Empty (S.File_Tree),
              "Refresh with an active project must scan the tree");
      Assert (Editor.File_Tree.Node_Count (S.File_Tree) = 2,
              "Refresh must replace the file tree with scanned nodes");
      Assert (Last_Message_Text (S) = "File tree refreshed",
              "Refresh success must publish a success message");

      Remove_If_Exists (File_P);
      Remove_If_Exists (Root);
   end Test_Execute_Refresh_File_Tree;

   procedure Test_File_Lifecycle_Operations_Refresh_Project_File_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S              : Editor.State.State_Type;
      Root           : constant String := Temp_Path ("lifecycle_refresh_project");
      Src            : constant String := Ada.Directories.Compose (Root, "src");
      Save_As_Source : constant String := Ada.Directories.Compose (Src, "save_as.adb");
      Save_As_Target : constant String := Ada.Directories.Compose (Src, "save_as_new.adb");
      Rename_Source  : constant String := Ada.Directories.Compose (Src, "rename.adb");
      Rename_Target  : constant String := Ada.Directories.Compose (Src, "rename_new.adb");
      Copy_Source    : constant String := Ada.Directories.Compose (Src, "copy.adb");
      Copy_Target    : constant String := Ada.Directories.Compose (Src, "copy_new.adb");
      Move_Source    : constant String := Ada.Directories.Compose (Src, "move.adb");
      Move_Target    : constant String := Ada.Directories.Compose (Src, "move_new.adb");
      Delete_Source  : constant String := Ada.Directories.Compose (Src, "delete.adb");
      Refresh_Added  : constant String := Ada.Directories.Compose (Src, "refresh_added.adb");

      procedure Assert_Project_File_State
        (Relative : String;
         Present  : Boolean;
         Context  : String)
      is
         Found : Boolean := False;
      begin
         declare
            Node : constant Editor.File_Tree.File_Tree_Node_Id :=
              Editor.File_Tree.Find_By_Path (S.File_Tree, Relative, Found);
            pragma Unreferenced (Node);
         begin
            Assert
              (Found = Present,
               Context & ": file-tree presence mismatch for " & Relative);
         end;
      end Assert_Project_File_State;
   begin
      Remove_If_Exists (Delete_Source);
      Remove_If_Exists (Refresh_Added);
      Remove_If_Exists (Move_Target);
      Remove_If_Exists (Move_Source);
      Remove_If_Exists (Copy_Target);
      Remove_If_Exists (Copy_Source);
      Remove_If_Exists (Rename_Target);
      Remove_If_Exists (Rename_Source);
      Remove_If_Exists (Save_As_Target);
      Remove_If_Exists (Save_As_Source);
      Remove_If_Exists (Src);
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Bytes (Save_As_Source, "save as needle");
      Write_Bytes (Rename_Source, "rename needle");
      Write_Bytes (Copy_Source, "copy needle");
      Write_Bytes (Move_Source, "move needle");
      Write_Bytes (Delete_Source, "delete needle");
      Write_Bytes (Refresh_Added, "refresh needle");

      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Assert_Project_File_State ("src/save_as.adb", True, "project open");
      Assert_Project_File_State ("src/rename.adb", True, "project open");
      Assert_Project_File_State ("src/copy.adb", True, "project open");
      Assert_Project_File_State ("src/move.adb", True, "project open");
      Assert_Project_File_State ("src/delete.adb", True, "project open");

      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search
        (S, "needle");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) > 0,
              "initial project search should see the seeded matches");
      Assert (not Editor.Project_Search.Is_Stale (S.Project_Search),
              "initial project search should be coherent");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Save_As_Source);
      Editor.Executor.File_Save_Basic_Commands.Execute_Save_As (S, Save_As_Target);
      Assert_Project_File_State ("src/save_as.adb", True, "save-as keeps source");
      Assert_Project_File_State ("src/save_as_new.adb", True, "save-as adds target");
      Assert (not Editor.Project.Has_Known_File (S.Project, "src/save_as_new.adb"),
              "save-as target must not be promoted to retained project search source");
      Assert (Project_Search_Has_Result_Path (S.Project_Search, "src/save_as_new.adb"),
              "save-as target should appear in refreshed project search results");
      Assert (not Editor.Project_Search.Is_Stale (S.Project_Search),
              "save-as should leave refreshed search results coherent");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Rename_Source);
      Editor.Executor.File_Operation_Commands.Execute_Rename_Buffer_File (S, Rename_Target);
      Assert_Project_File_State ("src/rename.adb", False, "rename removes source");
      Assert_Project_File_State ("src/rename_new.adb", True, "rename adds target");
      Assert (not Editor.Project.Has_Known_File (S.Project, "src/rename_new.adb"),
              "rename target must not be promoted to retained project search source");
      Assert (not Project_Search_Has_Result_Path (S.Project_Search, "src/rename.adb"),
              "rename should remove the old search result path");
      Assert (Project_Search_Has_Result_Path (S.Project_Search, "src/rename_new.adb"),
              "rename should add the new search result path");
      Assert (not Editor.Project_Search.Is_Stale (S.Project_Search),
              "rename should leave refreshed search results coherent");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Copy_Source);
      Editor.Executor.File_Operation_Commands.Execute_Copy_Buffer_File (S, Copy_Target);
      Assert_Project_File_State ("src/copy.adb", True, "copy keeps source");
      Assert_Project_File_State ("src/copy_new.adb", True, "copy adds target");
      Assert (not Editor.Project.Has_Known_File (S.Project, "src/copy_new.adb"),
              "copy target must not be promoted to retained project search source");
      Assert (Project_Search_Has_Result_Path (S.Project_Search, "src/copy_new.adb"),
              "copy target should appear in refreshed project search results");
      Assert (not Editor.Project_Search.Is_Stale (S.Project_Search),
              "copy should leave refreshed search results coherent");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Move_Source);
      Editor.Executor.File_Operation_Commands.Execute_Move_Buffer_File (S, Move_Target);
      Assert_Project_File_State ("src/move.adb", False, "move removes source");
      Assert_Project_File_State ("src/move_new.adb", True, "move adds target");
      Assert (not Editor.Project.Has_Known_File (S.Project, "src/move_new.adb"),
              "move target must not be promoted to retained project search source");
      Assert (not Project_Search_Has_Result_Path (S.Project_Search, "src/move.adb"),
              "move should remove the old search result path");
      Assert (Project_Search_Has_Result_Path (S.Project_Search, "src/move_new.adb"),
              "move should add the new search result path");
      Assert (not Editor.Project_Search.Is_Stale (S.Project_Search),
              "move should leave refreshed search results coherent");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Delete_Source);
      Editor.Executor.File_Operation_Commands.Execute_Delete_Buffer_File (S);
      Assert_Project_File_State ("src/delete.adb", False, "delete removes source");
      Assert (not Project_Search_Has_Result_Path (S.Project_Search, "src/delete.adb"),
              "delete should remove the deleted search result path");
      Assert (not Editor.Project_Search.Is_Stale (S.Project_Search),
              "delete should leave refreshed search results coherent");

      Write_Bytes (Refresh_Added, "refresh needle");
      Editor.Executor.Project_File_Index_Commands.Execute_Refresh_Project_Files (S);
      Assert (Project_Search_Has_Result_Path (S.Project_Search, "src/refresh_added.adb"),
              "project-files refresh should surface the new search result path");
      Assert (not Editor.Project_Search.Is_Stale (S.Project_Search),
              "project-files refresh should leave project search coherent");

      Editor.Buffers.Reset_Global_For_Test;
      Remove_If_Exists (Delete_Source);
      Remove_If_Exists (Refresh_Added);
      Remove_If_Exists (Move_Target);
      Remove_If_Exists (Move_Source);
      Remove_If_Exists (Copy_Target);
      Remove_If_Exists (Copy_Source);
      Remove_If_Exists (Rename_Target);
      Remove_If_Exists (Rename_Source);
      Remove_If_Exists (Save_As_Target);
      Remove_If_Exists (Save_As_Source);
      Remove_If_Exists (Src);
      Remove_If_Exists (Root);
   exception
      when others =>
         Editor.Buffers.Reset_Global_For_Test;
         Remove_If_Exists (Delete_Source);
         Remove_If_Exists (Refresh_Added);
         Remove_If_Exists (Move_Target);
         Remove_If_Exists (Move_Source);
         Remove_If_Exists (Copy_Target);
         Remove_If_Exists (Copy_Source);
         Remove_If_Exists (Rename_Target);
         Remove_If_Exists (Rename_Source);
         Remove_If_Exists (Save_As_Target);
         Remove_If_Exists (Save_As_Source);
         Remove_If_Exists (Src);
         Remove_If_Exists (Root);
         raise;
   end Test_File_Lifecycle_Operations_Refresh_Project_File_State;

   procedure Test_Project_State_Survives_Buffer_Switch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S          : Editor.State.State_Type;
      Root       : constant String := Temp_Path ("switch_project");
      Folder     : constant String := Ada.Directories.Compose (Root, "folder");
      Nested     : constant String := Ada.Directories.Compose (Folder, "nested.txt");
      First      : Editor.Buffers.Buffer_Id;
      Second     : Editor.Buffers.Buffer_Id;
      Before     : Unbounded_String;
      Found      : Boolean := False;
      Folder_Id  : Editor.File_Tree.File_Tree_Node_Id;
      Rows_Before : Natural;
   begin
      Remove_If_Exists (Nested);
      Remove_If_Exists (Folder);
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Folder);
      Write_Bytes (Nested, "nested");
      Editor.Buffers.Reset_Global_For_Test;
      Editor.State.Init (S);
      Editor.Buffers.Ensure_Global_Registry (S);
      First := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_New_Buffer (S);
      Second := Editor.Buffers.Global_Active_Buffer;

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Before := To_Unbounded_String (Editor.Project.Root_Path (S.Project));
      Folder_Id := Editor.File_Tree.Find_By_Path (S.File_Tree, "folder", Found);
      Assert (Found,
              "Test setup must scan the project folder into the file tree");
      Editor.File_Tree.Set_Expanded (S.File_Tree, Folder_Id, True);
      Rows_Before := Editor.File_Tree.Visible_Row_Count (S.File_Tree);

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, First);
      Assert (Editor.Project.Root_Path (S.Project) = To_String (Before),
              "Switching to another buffer must preserve editor-global project");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Rows_Before,
              "Switching to another buffer must preserve editor-global file tree rows");
      Assert (Editor.File_Tree.Node (S.File_Tree, Folder_Id).Is_Expanded,
              "Switching to another buffer must preserve file tree expansion state");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, Second);
      Assert (Editor.Project.Root_Path (S.Project) = To_String (Before),
              "Switching back must preserve editor-global project");
      Assert (Editor.File_Tree.Visible_Row_Count (S.File_Tree) = Rows_Before,
              "Switching back must preserve editor-global file tree rows");
      Assert (Editor.File_Tree.Node (S.File_Tree, Folder_Id).Is_Expanded,
              "Switching back must preserve file tree expansion state");

      Remove_If_Exists (Nested);
      Remove_If_Exists (Folder);
      Remove_If_Exists (Root);
   end Test_Project_State_Survives_Buffer_Switch;


   procedure Test_Execute_Open_Project_Adds_Recent_Project
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("recent_open_root");
      Config_Dir : constant String := Temp_Path ("recent_config");
      S : Editor.State.State_Type;
   begin
      Remove_If_Exists (Root);
      Remove_If_Exists (Config_Dir);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Config_Dir);
      Editor.Recent_Projects.Set_Config_Directory_For_Tests (Config_Dir);
      Editor.State.Init (S);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);

      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "successful project open must add a recent-project entry");
      Assert
        (To_String (Editor.Recent_Projects.Item (S.Recent_Projects, 1).Display_Name) =
           Editor.Project.Display_Name (S.Project),
         "recent-project entry must use the project display name");
      Assert (Ada.Directories.Exists (Editor.Recent_Projects.Recent_Projects_File_Path),
              "successful project open must persist the global recent-projects file best-effort");

      Editor.Recent_Projects.Clear_Config_Directory_Override;
      Remove_If_Exists (Root);
      Remove_If_Exists (Config_Dir);
   end Test_Execute_Open_Project_Adds_Recent_Project;

   procedure Test_Failed_Open_Project_Does_Not_Add_Recent_Project
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Missing : constant String := Temp_Path ("missing_recent_open_root");
      Config_Dir : constant String := Temp_Path ("recent_config_missing");
      S : Editor.State.State_Type;
   begin
      Remove_If_Exists (Missing);
      Remove_If_Exists (Config_Dir);
      Ada.Directories.Create_Directory (Config_Dir);
      Editor.Recent_Projects.Set_Config_Directory_For_Tests (Config_Dir);
      Editor.State.Init (S);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Missing);

      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 0,
              "failed project open must not add a recent-project entry");

      Editor.Recent_Projects.Clear_Config_Directory_Override;
      Remove_If_Exists (Config_Dir);
   end Test_Failed_Open_Project_Does_Not_Add_Recent_Project;

   procedure Test_Clear_Recent_Projects_Command
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Config_Dir : constant String := Temp_Path ("recent_config_clear");
      S : Editor.State.State_Type;
   begin
      Remove_If_Exists (Config_Dir);
      Ada.Directories.Create_Directory (Config_Dir);
      Editor.Recent_Projects.Set_Config_Directory_For_Tests (Config_Dir);
      Editor.State.Init (S);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, Editor.Test_Temp.Base & "/editor", "editor", 1);

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Clear_Recent_Projects);

      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 0,
              "Clear Recent Projects command must clear the in-memory list");
      Assert (Last_Message_Text (S) = "Cleared recent projects",
              "Clear Recent Projects command must publish deterministic feedback");

      Editor.Recent_Projects.Clear_Config_Directory_Override;
      Remove_If_Exists (Config_Dir);
   end Test_Clear_Recent_Projects_Command;

   procedure Test_Open_Project_Command_Without_Path_Publishes_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command :=
        Editor.Commands.Command_For_Id (Editor.Commands.Command_Open_Project);
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (not Editor.Project.Has_Project (S.Project),
              "Open Project command without path must not set project state");
      Assert (Last_Message_Text (S) = "Open Project requires a path",
              "Open Project command without path must publish deterministic message");
   end Test_Open_Project_Command_Without_Path_Publishes_Message;

   procedure Test_Command_Palette_Project_Descriptors_Exist
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Descriptor_Exists (Editor.Commands.Command_Open_Project),
              "Open Project descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Close_Project),
              "Close Project palette descriptor must exist");
      Assert (Editor.Commands.Descriptor (Editor.Commands.Command_Clear_Project).Id =
                Editor.Commands.Command_Clear_Project,
              "Clear Project Context descriptor must exist as hidden/internal command");
      Assert (Descriptor_Exists (Editor.Commands.Command_Refresh_File_Tree),
              "Refresh File Tree descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Show_Recent_Projects),
              "Show Recent Projects descriptor must exist");
      Assert (Descriptor_Exists (Editor.Commands.Command_Clear_Recent_Projects),
              "Clear Recent Projects descriptor must exist");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Remove_Selected_Recent_Project).Id =
              Editor.Commands.Command_Remove_Selected_Recent_Project,
              "Remove Selected Recent Project descriptor must exist as hidden/internal command");
      Assert (Descriptor_Exists (Editor.Commands.Command_Remove_Missing_Recent_Projects),
              "Remove Missing Recent Projects descriptor must exist");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Select_Next_Recent_Project).Id =
              Editor.Commands.Command_Select_Next_Recent_Project,
              "Select Next Recent Project descriptor must exist as hidden/internal command");
      Assert (Editor.Commands.Descriptor
                (Editor.Commands.Command_Select_Previous_Recent_Project).Id =
              Editor.Commands.Command_Select_Previous_Recent_Project,
              "Select Previous Recent Project descriptor must exist as hidden/internal command");
   end Test_Command_Palette_Project_Descriptors_Exist;



   procedure Test_Project_File_Refresh_Respects_Projectignore
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root      : constant String := Temp_Path ("quick_open_ignore_root");
      Src       : constant String := Ada.Directories.Compose (Root, "src");
      Docs      : constant String := Ada.Directories.Compose (Root, "docs");
      Generated : constant String := Ada.Directories.Compose (Root, "generated");
      Obj       : constant String := Ada.Directories.Compose (Root, "obj");
      State     : Editor.Project.Project_State;
      Opened    : Editor.Project.Project_Open_Result;
      Result    : Editor.Project.Project_File_Refresh_Result;
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Ada.Directories.Create_Directory (Docs);
      Ada.Directories.Create_Directory (Generated);
      Ada.Directories.Create_Directory (Obj);
      Write_Bytes (Ada.Directories.Compose (Src, "main.adb"), "main");
      Write_Bytes (Ada.Directories.Compose (Src, "generated_config.adb"), "generated");
      Write_Bytes (Ada.Directories.Compose (Src, "auto.gen.adb"), "generated");
      Write_Bytes (Ada.Directories.Compose (Docs, "notes.md"), "notes");
      Write_Bytes (Ada.Directories.Compose (Generated, "table.ads"), "table");
      Write_Bytes (Ada.Directories.Compose (Obj, "main.o"), "object");
      Write_Bytes
        (Ada.Directories.Compose (Root, ".projectignore"),
         "" & ASCII.LF
         & "# project quick-open ignores" & ASCII.LF
         & "docs/" & ASCII.LF
         & "generated/" & ASCII.LF
         & "*.gen.adb" & ASCII.LF
         & "src/generated_config.adb" & ASCII.LF
         & "!negation" & ASCII.LF
         & "/anchored.adb" & ASCII.LF
         & "**/recursive" & ASCII.LF
         & "file[0].adb" & ASCII.LF
         & "{a,b}.adb" & ASCII.LF);

      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (State, Opened);
      Editor.Project.Refresh_Known_Files (State, Result);

      Assert (Result.Status = Editor.Project.Project_File_Refresh_Ok,
              "projectignore refresh should succeed despite invalid ignored patterns");
      Assert (Known_File_Present (State, "src/main.adb"),
              "non-ignored project file must remain known");
      Assert (Known_File_Present (State, ".projectignore"),
              "root projectignore remains an ordinary known project file unless ignored");
      Assert (not Known_File_Present (State, "docs/notes.md"),
              "directory ignore rule must exclude descendants");
      Assert (not Known_File_Present (State, "generated/table.ads"),
              "literal directory prefix rule must exclude descendants");
      Assert (not Known_File_Present (State, "src/auto.gen.adb"),
              "basename suffix rule must exclude matching files");
      Assert (not Known_File_Present (State, "src/generated_config.adb"),
              "literal file rule must exclude exact path");
      Assert (not Known_File_Present (State, "obj/main.o"),
              "built-in excluded directory must not be discovered");
      Assert (Result.Ignored_Path_Count = 4,
              "ignored directories/files must be counted once per skipped path");
      Assert (Result.Invalid_Ignore_Pattern_Count = 5,
              "unsupported ignore patterns must be counted and ignored deterministically");
      Assert (Result.Skipped_Directory_Count = 1,
              "built-in excluded directories must keep using skipped-directory count");

      Remove_If_Exists (Root);
   end Test_Project_File_Refresh_Respects_Projectignore;

   procedure Test_Project_File_Refresh_Delta_Treats_New_Ignore_As_Removal
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("quick_open_ignore_delta");
      Src    : constant String := Ada.Directories.Compose (Root, "src");
      Docs   : constant String := Ada.Directories.Compose (Root, "docs");
      State  : Editor.Project.Project_State;
      Opened : Editor.Project.Project_Open_Result;
      First  : Editor.Project.Project_File_Refresh_Result;
      Second : Editor.Project.Project_File_Refresh_Result;
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Ada.Directories.Create_Directory (Docs);
      Write_Bytes (Ada.Directories.Compose (Src, "main.adb"), "main");
      Write_Bytes (Ada.Directories.Compose (Docs, "notes.md"), "notes");
      Write_Bytes (Ada.Directories.Compose (Root, ".projectignore"), "# none" & ASCII.LF);

      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (State, Opened);
      Editor.Project.Refresh_Known_Files (State, First);
      Assert (Known_File_Present (State, "docs/notes.md"),
              "setup refresh must initially know docs file");

      Write_Bytes (Ada.Directories.Compose (Root, ".projectignore"), "docs/" & ASCII.LF);
      Editor.Project.Refresh_Known_Files (State, Second);

      Assert (Second.Status = Editor.Project.Project_File_Refresh_Ok,
              "refresh with changed ignore rule must succeed");
      Assert (Second.Removed_Count = 1,
              "previously known file that becomes ignored must count as removed");
      Assert (Second.Added_Count = 0,
              "changing only ignore contents must not add project files");
      Assert (Second.Ignored_Path_Count = 1,
              "ignored directory must count as one ignored path without enumerating children");
      Assert (not Known_File_Present (State, "docs/notes.md"),
              "known file list must atomically drop newly ignored file");

      Remove_If_Exists (Root);
   end Test_Project_File_Refresh_Delta_Treats_New_Ignore_As_Removal;

   procedure Test_Unreadable_Projectignore_Preserves_Known_Files
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("quick_open_ignore_unreadable");
      State  : Editor.Project.Project_State;
      Opened : Editor.Project.Project_Open_Result;
      Result : Editor.Project.Project_File_Refresh_Result;
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Ada.Directories.Compose (Root, "keep.adb"), "keep");
      Ada.Directories.Create_Directory (Ada.Directories.Compose (Root, ".projectignore"));

      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (State, Opened);
      Editor.Project.Add_Known_File
        (State, "previous.adb", Ada.Directories.Compose (Root, "previous.adb"));

      Editor.Project.Refresh_Known_Files (State, Result);

      Assert (Result.Status = Editor.Project.Project_File_Refresh_Read_Error,
              "unreadable projectignore must be a hard refresh failure");
      Assert (To_String (Result.Failure_Reason) = "could not read .projectignore",
              "unreadable projectignore failure reason must be deterministic");
      Assert (Editor.Project.Known_File_Count (State) = 1,
              "failed refresh must preserve previous known file list");
      Assert (Known_File_Present (State, "previous.adb"),
              "failed refresh must preserve previous known path");

      Remove_If_Exists (Root);
   end Test_Unreadable_Projectignore_Preserves_Known_Files;


   procedure Test_Project_File_Refresh_Summary_Cleared_On_Project_Reset
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("quick_open_ignore_summary_clear");
      State  : Editor.Project.Project_State;
      Opened : Editor.Project.Project_Open_Result;
      Result : Editor.Project.Project_File_Refresh_Result;
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes (Ada.Directories.Compose (Root, "keep.adb"), "keep");

      Opened := Editor.Project.Open_Project (Root);
      Editor.Project.Apply_Open_Result (State, Opened);
      Editor.Project.Refresh_Known_Files (State, Result);
      Assert (Editor.Project.Has_Last_Refresh_Summary (State),
              "successful refresh must store a session-local summary");

      Editor.Project.Clear_Known_Files (State);
      Assert (not Editor.Project.Has_Last_Refresh_Summary (State),
              "clearing known files must also clear stale last-refresh summary");

      Editor.Project.Refresh_Known_Files (State, Result);
      Assert (Editor.Project.Has_Last_Refresh_Summary (State),
              "setup must restore summary before project-open clearing check");
      Editor.Project.Apply_Open_Result (State, Opened);
      Assert (not Editor.Project.Has_Last_Refresh_Summary (State),
              "applying a project-open result must clear stale last-refresh summary");

      Remove_If_Exists (Root);
   end Test_Project_File_Refresh_Summary_Cleared_On_Project_Reset;

   procedure Test_Project_File_Refresh_Message_Includes_Ignore_Counts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("quick_open_ignore_message");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Docs : constant String := Ada.Directories.Compose (Root, "docs");
      S    : Editor.State.State_Type;
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Ada.Directories.Create_Directory (Docs);
      Write_Bytes (Ada.Directories.Compose (Src, "main.adb"), "main");
      Write_Bytes (Ada.Directories.Compose (Docs, "notes.md"), "notes");
      Write_Bytes
        (Ada.Directories.Compose (Root, ".projectignore"),
         "docs/" & ASCII.LF & "!unsupported" & ASCII.LF);

      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_File_Index_Commands.Execute_Refresh_Project_Files (S);

      Assert
        (Last_Message_Text (S) =
           "Project files refreshed: 2 files; removed 1; excluded 1 ignored path; ignored 1 invalid pattern",
         "refresh message must report ignored and invalid projectignore counts");

      Remove_If_Exists (Root);
   end Test_Project_File_Refresh_Message_Includes_Ignore_Counts;



   procedure Test_Quick_Open_Create_With_Parents_Creates_File
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Root : constant String := Temp_Path ("quick_open_create_parents");
      File_Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose
           (Ada.Directories.Compose (Root, "src"), "panels"),
         "view.adb");
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Ada.Directories.Compose (Root, "src"));
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "panels/view.adb");
      Editor.Quick_Open.Set_Path_Scope (S.Quick_Open, "src/");

      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Create_With_Parents_From_Query (S);

      Assert (Ada.Directories.Exists (Ada.Directories.Compose
                (Ada.Directories.Compose (Root, "src"), "panels")),
              "create-with-parents must create the missing parent directory");
      Assert (Ada.Directories.Exists (File_Path),
              "create-with-parents must create the target file");
      Assert (Editor.Project.Has_Known_File (S.Project, "src/panels/view.adb"),
              "create-with-parents must insert only the created file into known project files");
      Assert (not Editor.Project.Has_Known_File (S.Project, "src/panels"),
              "create-with-parents must not add created directories as known files");
      Assert (Last_Message_Text (S) = "Created src/panels/view.adb",
              "create-with-parents must emit one concise create message");
      Assert (not Editor.Quick_Open.Is_Open (S.Quick_Open),
              "successful create/open must hide Quick Open under the existing policy");
      Remove_If_Exists (Root);
   end Test_Quick_Open_Create_With_Parents_Creates_File;

   procedure Test_Quick_Open_Create_With_Parents_Creates_Nested_Parents
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Root : constant String := Temp_Path ("quick_open_create_nested_parents");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Panels : constant String := Ada.Directories.Compose (Src, "panels");
      Sidebar : constant String := Ada.Directories.Compose (Panels, "sidebar");
      File_Path : constant String := Ada.Directories.Compose (Sidebar, "view.adb");
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "panels/sidebar/view.adb");
      Editor.Quick_Open.Set_Path_Scope (S.Quick_Open, "src/");

      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Create_With_Parents_From_Query (S);

      Assert (Ada.Directories.Exists (Panels),
              "create-with-parents must create the first missing nested parent");
      Assert (Ada.Directories.Exists (Sidebar),
              "create-with-parents must create the deepest missing nested parent");
      Assert (Ada.Directories.Exists (File_Path),
              "create-with-parents must create the nested target file");
      Assert (Editor.Project.Has_Known_File (S.Project, "src/panels/sidebar/view.adb"),
              "create-with-parents must insert the nested file path into known project files");
      Assert (not Editor.Project.Has_Known_File (S.Project, "src/panels"),
              "create-with-parents must not insert the first created directory");
      Assert (not Editor.Project.Has_Known_File (S.Project, "src/panels/sidebar"),
              "create-with-parents must not insert the deepest created directory");
      Assert (Last_Message_Text (S) = "Created src/panels/sidebar/view.adb",
              "nested create-with-parents must emit one concise create message");
      Remove_If_Exists (Root);
   end Test_Quick_Open_Create_With_Parents_Creates_Nested_Parents;

   procedure Test_Quick_Open_Create_With_Parents_Rejects_File_Parent
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Root : constant String := Temp_Path ("quick_open_create_file_parent_conflict");
      Src  : constant String := Ada.Directories.Compose (Root, "src");
      Panels_File : constant String := Ada.Directories.Compose (Src, "panels");
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Write_Bytes (Panels_File, "not a directory");
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "panels/sidebar/view.adb");
      Editor.Quick_Open.Set_Path_Scope (S.Quick_Open, "src/");

      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Create_With_Parents_From_Query (S);

      Assert (Last_Message_Text (S) = "Parent path is not a directory: src/panels",
              "file parent conflict must emit deterministic parent-not-directory message");
      Assert (not Editor.Project.Has_Known_File (S.Project, "src/panels/sidebar/view.adb"),
              "file parent conflict must not insert the target into known project files");
      Assert (Editor.Quick_Open.Is_Open (S.Quick_Open),
              "failed create-with-parents must preserve Quick Open visibility");
      Remove_If_Exists (Root);
   end Test_Quick_Open_Create_With_Parents_Rejects_File_Parent;

   procedure Test_Quick_Open_Create_With_Parents_Rejects_Ignored_Parent_Before_Create
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Root : constant String := Temp_Path ("quick_open_create_ignored_parent");
      Generated : constant String := Ada.Directories.Compose (Root, "generated");
      Target_File : constant String := Ada.Directories.Compose (Generated, "view.adb");
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Bytes
        (Ada.Directories.Compose (Root, ".projectignore"),
         "generated/" & ASCII.LF);
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "generated/view.adb");

      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Create_With_Parents_From_Query (S);

      Assert (Last_Message_Text (S) = "Path is ignored by project rules: generated/view.adb",
              "ignored parent directory rule must reject the target before directory creation");
      Assert (not Ada.Directories.Exists (Generated),
              "ignored parent directory must not be created");
      Assert (not Ada.Directories.Exists (Target_File),
              "ignored target file must not be created");
      Assert (not Editor.Project.Has_Known_File (S.Project, "generated/view.adb"),
              "ignored target must not be inserted into known project files");
      Remove_If_Exists (Root);
   end Test_Quick_Open_Create_With_Parents_Rejects_Ignored_Parent_Before_Create;


   procedure Test_Create_From_Query_Rejects_Ignored_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Root : constant String := Temp_Path ("create_ignored_narrow");
      Generated : constant String := Ada.Directories.Compose (Root, "generated");
      Target_File : constant String := Ada.Directories.Compose (Generated, "view.adb");
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Generated);
      Write_Bytes
        (Ada.Directories.Compose (Root, ".projectignore"),
         "generated/" & ASCII.LF);
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "generated/view.adb");

      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Create_From_Query (S);

      Assert (Last_Message_Text (S) = "Path is ignored by project rules: generated/view.adb",
              "create-from-query must reject ignored targets before file creation");
      Assert (not Ada.Directories.Exists (Target_File),
              "ignored create-from-query target must not be created");
      Assert (not Editor.Project.Has_Known_File (S.Project, "generated/view.adb"),
              "ignored create-from-query target must not be inserted into known files");
      Assert (Editor.Quick_Open.Is_Open (S.Quick_Open)
              and then Editor.Quick_Open.Query_Text (S.Quick_Open) = "generated/view.adb",
              "ignored create-from-query failure must preserve Quick Open state");
      Remove_If_Exists (Root);
   exception
      when others =>
         Remove_If_Exists (Root);
         raise;
   end Test_Create_From_Query_Rejects_Ignored_Target;

   procedure Test_Quick_Open_Create_From_Query_Remains_Narrow
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Root : constant String := Temp_Path ("quick_open_create_narrow");
      Parent : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose (Root, "src"), "panels");
      File_Path : constant String := Ada.Directories.Compose (Parent, "view.adb");
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Ada.Directories.Compose (Root, "src"));
      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "panels/view.adb");
      Editor.Quick_Open.Set_Path_Scope (S.Quick_Open, "src/");

      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Create_From_Query (S);

      Assert (not Ada.Directories.Exists (Parent),
              "create-from-query must not create missing parents");
      Assert (not Ada.Directories.Exists (File_Path),
              "create-from-query must not create the target when the parent is missing");
      Assert (Last_Message_Text (S) = "Parent directory is unavailable.",
              "create-from-query must preserve its missing-parent failure message");
      Assert (not Editor.Project.Has_Known_File (S.Project, "src/panels/view.adb"),
              "failed narrow create must not insert the target into known project files");
      Remove_If_Exists (Root);
   end Test_Quick_Open_Create_From_Query_Remains_Narrow;


   procedure Test_Create_From_Query_Then_Refresh_No_Duplicate
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Root    : constant String := Temp_Path ("create_refresh");
      Src     : constant String := Ada.Directories.Compose (Root, "src");
      Editor_Dir : constant String := Ada.Directories.Compose (Src, "editor");
      File_Path  : constant String := Ada.Directories.Compose (Editor_Dir, "new_panel.adb");
      Refresh : Editor.Project.Project_File_Refresh_Result;
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);
      Ada.Directories.Create_Directory (Editor_Dir);

      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Quick_Open.Set_Path_Scope (S.Quick_Open, "src/editor/");
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "new_panel.adb");

      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Create_From_Query (S);

      Assert (Ada.Directories.Exists (File_Path),
              "create-from-query must create the requested file");
      Assert (Editor.Project.Has_Known_File (S.Project, "src/editor/new_panel.adb"),
              "create-from-query must insert the created file into known files");
      Assert (Editor.Project.Known_File_Count (S.Project) = 1,
              "create-from-query must insert exactly one known file");
      Assert (Last_Message_Text (S) = "Created src/editor/new_panel.adb",
              "create-from-query success must emit one create message");
      Assert (not Editor.Quick_Open.Is_Open (S.Quick_Open),
              "create/open success must hide Quick Open under existing policy");

      Editor.Project.Refresh_Known_Files (S.Project, Refresh);
      Assert (Refresh.Status = Editor.Project.Project_File_Refresh_Ok,
              "refresh after create must succeed");
      Assert (Refresh.Total_Count = 1
              and then Refresh.Previous_Count = 1
              and then Refresh.Added_Count = 0
              and then Refresh.Removed_Count = 0
              and then Refresh.Unchanged_Count = 1,
              "refresh after create must discover no duplicate or added copy");
      Assert (Editor.Project.Known_File_Count (S.Project) = 1,
              "known file list must remain de-duplicated after refresh");

      Remove_If_Exists (Root);
   exception
      when others =>
         Remove_If_Exists (Root);
         raise;
   end Test_Create_From_Query_Then_Refresh_No_Duplicate;

   procedure Test_Create_With_Parents_After_Narrow_Failure_Then_Refresh
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S       : Editor.State.State_Type;
      Root    : constant String := Temp_Path ("create_parents_refresh");
      Src     : constant String := Ada.Directories.Compose (Root, "src");
      Panels  : constant String := Ada.Directories.Compose (Src, "panels");
      Sidebar : constant String := Ada.Directories.Compose (Panels, "sidebar");
      File_Path : constant String := Ada.Directories.Compose (Sidebar, "view.adb");
      Refresh : Editor.Project.Project_File_Refresh_Result;
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Ada.Directories.Create_Directory (Src);

      Editor.State.Init (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Quick_Open_Commands.Execute_Open_Quick_Open (S);
      Editor.Quick_Open.Set_Path_Scope (S.Quick_Open, "src/");
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "panels/sidebar/view.adb");
      Editor.Quick_Open.Toggle_Priority_Mode (S.Quick_Open);

      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Create_From_Query (S);

      Assert (not Ada.Directories.Exists (Panels),
              "narrow create failure must not create missing parent directories");
      Assert (not Ada.Directories.Exists (File_Path),
              "narrow create failure must not create target file");
      Assert (Editor.Quick_Open.Is_Open (S.Quick_Open)
              and then Editor.Quick_Open.Path_Scope (S.Quick_Open) = "src/"
              and then Editor.Quick_Open.Query_Text (S.Quick_Open) = "panels/sidebar/view.adb"
              and then Editor.Quick_Open.Priority_Mode (S.Quick_Open) = Editor.Quick_Open.Open_Recent,
              "narrow create failure must preserve Quick Open transient state");
      Assert (Editor.Project.Known_File_Count (S.Project) = 0,
              "narrow create failure must not mutate known files");

      Editor.Executor.Quick_Open_Commands.Execute_Quick_Open_Create_With_Parents_From_Query (S);

      Assert (Ada.Directories.Exists (Panels)
              and then Ada.Directories.Exists (Sidebar)
              and then Ada.Directories.Exists (File_Path),
              "create-with-parents must create parents and target after narrow failure");
      Assert (Editor.Project.Has_Known_File (S.Project, "src/panels/sidebar/view.adb"),
              "create-with-parents must insert the created target file");
      Assert (not Editor.Project.Has_Known_File (S.Project, "src/panels")
              and then not Editor.Project.Has_Known_File (S.Project, "src/panels/sidebar"),
              "create-with-parents must not insert created directories");
      Assert (Editor.Project.Known_File_Count (S.Project) = 1,
              "create-with-parents must insert exactly one known file");
      Assert (Last_Message_Text (S) = "Created src/panels/sidebar/view.adb",
              "create-with-parents success must emit one create message");

      Editor.Project.Refresh_Known_Files (S.Project, Refresh);
      Assert (Refresh.Status = Editor.Project.Project_File_Refresh_Ok
              and then Refresh.Total_Count = 1
              and then Refresh.Added_Count = 0
              and then Refresh.Removed_Count = 0
              and then Refresh.Unchanged_Count = 1,
              "refresh after create-with-parents must not duplicate the created file");
      Assert (Editor.Project.Known_File_Count (S.Project) = 1,
              "known files must remain one file after create-with-parents refresh");

      Remove_If_Exists (Root);
   exception
      when others =>
         Remove_If_Exists (Root);
         raise;
   end Test_Create_With_Parents_After_Narrow_Failure_Then_Refresh;


   procedure Test_Open_Selected_Recent_Refreshes_Missing_Marker
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("stale-recent-root");
      S    : Editor.State.State_Type;
   begin
      Remove_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Editor.State.Init (S);
      Editor.Recent_Projects.Clear (S.Recent_Projects);
      S.Recent_Project_Selected_Index := 0;
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, Root, "stale-recent-root", 559);

      Remove_If_Exists (Root);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Open_Selected_Recent_Project);

      Assert (Last_Message_Text (S) = Editor.Commands.Reason_Target_Missing,
              "opening a stale recent project must fail with the shared missing-target message");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "failed recent-project open must not remove the entry implicitly");
      Assert (not Editor.Recent_Projects.Is_Available
                (Editor.Recent_Projects.Item (S.Recent_Projects, 1)),
              "failed recent-project open must refresh the cached unavailable marker");
      Assert (not Editor.Project.Has_Project (S.Project),
              "failed recent-project open must not fabricate project context");
   exception
      when others =>
         Remove_If_Exists (Root);
         raise;
   end Test_Open_Selected_Recent_Refreshes_Missing_Marker;

   overriding procedure Register_Tests
     (T : in out Project_Test_Case)
   is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_State_Clear_And_Query'Access,
         "State Clear And Query");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Project_Validation'Access,
         "Open Project Validation");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Result_Helpers_Are_Deterministic'Access,
         "Result Helpers Are Deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Apply_Open_Result_Only_Applies_Success'Access,
         "Apply Open Result Only Applies Success");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Relative_Path_Helpers'Access,
         "Project Relative Path Helpers");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Open_Project_Updates_State_And_Message'Access,
         "Execute Open Project Updates State And Message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Open_Project_Failure_Preserves_Previous_Project'Access,
         "Execute Open Project Failure Preserves Previous Project");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Open_Project_Is_Non_Destructive'Access,
         "Execute Open Project Is Non Destructive");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Refresh_File_Tree'Access,
         "Execute Refresh File Tree");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_File_Lifecycle_Operations_Refresh_Project_File_State'Access,
         "File Lifecycle Operations Refresh Project File State");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_State_Survives_Buffer_Switch'Access,
         "Project State Survives Buffer Switch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Execute_Open_Project_Adds_Recent_Project'Access,
         "Execute Open Project Adds Recent Project");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Failed_Open_Project_Does_Not_Add_Recent_Project'Access,
         "Failed Open Project Does Not Add Recent Project");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Clear_Recent_Projects_Command'Access,
         "Clear Recent Projects Command");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Selected_Recent_Refreshes_Missing_Marker'Access,
         "Open Selected Recent Refreshes Missing Marker");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Project_Command_Without_Path_Publishes_Message'Access,
         "Open Project Command Without Path Publishes Message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Command_Palette_Project_Descriptors_Exist'Access,
         "Command Palette Project Descriptors Exist");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_File_Refresh_Respects_Projectignore'Access,
         "Project File Refresh Respects Projectignore");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_File_Refresh_Delta_Treats_New_Ignore_As_Removal'Access,
         "Project File Refresh Delta Treats New Ignore As Removal");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Unreadable_Projectignore_Preserves_Known_Files'Access,
         "Unreadable Projectignore Preserves Known Files");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_File_Refresh_Summary_Cleared_On_Project_Reset'Access,
         "Project File Refresh Summary Cleared On Project Reset");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_File_Refresh_Message_Includes_Ignore_Counts'Access,
         "Project File Refresh Message Includes Ignore Counts");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Quick_Open_Create_With_Parents_Creates_File'Access,
         "Quick Open Create With Parents Creates File");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Quick_Open_Create_With_Parents_Creates_Nested_Parents'Access,
         "Quick Open Create With Parents Creates Nested Parents");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Quick_Open_Create_With_Parents_Rejects_File_Parent'Access,
         "Quick Open Create With Parents Rejects File Parent");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Quick_Open_Create_With_Parents_Rejects_Ignored_Parent_Before_Create'Access,
         "Quick Open Create With Parents Rejects Ignored Parent Before Create");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Create_From_Query_Rejects_Ignored_Target'Access,
         "create from query rejects ignored target");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Quick_Open_Create_From_Query_Remains_Narrow'Access,
         "Quick Open Create From Query Remains Narrow");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Create_From_Query_Then_Refresh_No_Duplicate'Access,
         "create from query then refresh no duplicate");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Create_With_Parents_After_Narrow_Failure_Then_Refresh'Access,
         "create with parents after narrow failure then refresh");
   end Register_Tests;

end Editor.Project.Tests;
