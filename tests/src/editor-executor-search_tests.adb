with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Commands;
with Editor.Cursors;
with Editor.Executor.Test_Support; use Editor.Executor.Test_Support;
with Editor.Executor.File_Open_Commands;
with Editor.Executor.Find_Replace_Commands;
with Editor.Executor.Find_Replace_Input_Commands;
with Editor.Executor.Project_Search_Result_Commands;
with Editor.Executor.Project_Search_Surface_Commands;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.Executor.Project_Search_Replace_Commands;
with Editor.Executor.Search_Commands;
with Editor.Executor.Search_Results_Commands;
with Editor.Feature_Panel;
with Editor.Feature_Search_Results;
with Editor.Go_To_Line;
with Editor.History;
with Editor.Input_Bridge;
with Editor.Input_Field;
with Editor.Messages;
with Editor.Navigation_History;
with Editor.Panel_Focus;
with Editor.Panels;
with Editor.Project_Search;
with Editor.Project_Search_Bar;
with Editor.Quick_Open;
with Editor.Render_Model;
with Editor.Search;
with Editor.State;
with Editor.Test_Helper;

package body Editor.Executor.Search_Tests is

   use type Editor.Panel_Focus.Bottom_Focus_Content;
   use type Editor.Panel_Focus.Focus_Target;
   use type Editor.Panels.Bottom_Panel_Content;
   use type Editor.Project_Search.Project_Search_File_Kind_Filter;
   use type Editor.Project_Search.Project_Search_Status;
   use type Editor.Search.Search_Match_Index;
   use type Editor.Commands.Command_Availability_Status;
   use type Editor.Commands.Command_Id;

   overriding function Name (T : Search_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Executor.Search_Tests");
   end Name;

   procedure Test_Focus_Search_Results_Shows_And_Focuses
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("focus_results_root");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");
      Editor.Panels.Set_Visible (S.Panels, Editor.Panels.Bottom_Panel, False);

      Editor.Executor.Search_Results_Commands.Execute_Focus_Search_Results (S);

      Assert
        (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
         "focus Search Results should show the bottom panel when results exist");
      Assert
        (Editor.Panels.Active_Bottom_Content (S.Panels) =
           Editor.Panels.Search_Results_Content,
         "focus Search Results should select Search Results bottom content");
      Assert
        (Editor.Panel_Focus.Target (S.Panel_Focus) =
           Editor.Panel_Focus.Bottom_Panel_Focus
         and then Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
           Editor.Panel_Focus.Search_Results_Focus,
         "focus Search Results should move keyboard ownership to Search Results");

      Cleanup_Project_Search_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Focus_Search_Results_Shows_And_Focuses;

   procedure Test_Search_Results_Move_Is_Selection_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("selection_only_root");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Multi_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");
      Editor.Executor.Search_Results_Commands.Execute_Focus_Search_Results (S);

      Assert
        (Editor.Project_Search.Result_Count (S.Project_Search) = 3,
         "multi-result fixture should produce three results");
      Assert
        (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 1,
         "search should start with the first result selected");

      Editor.Executor.Search_Results_Commands.Execute_Search_Results_Move_Down (S);

      Assert
        (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 2,
         "focused Down should move Search Results selection only");
      Assert
        (To_String (S.File_Info.Display_Name) = "Untitled",
         "focused Down must not open the selected result");
      Assert
        (Editor.Panel_Focus.Bottom_Content (S.Panel_Focus) =
           Editor.Panel_Focus.Search_Results_Focus,
         "focused movement should keep Search Results focus");

      Editor.Executor.Search_Results_Commands.Execute_Search_Results_Move_Up (S);
      Editor.Executor.Search_Results_Commands.Execute_Search_Results_Move_Up (S);

      Assert
        (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 1,
         "focused Up should not wrap past the first result");

      Cleanup_Project_Search_Multi_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Multi_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Search_Results_Move_Is_Selection_Only;

   procedure Test_Search_Results_Open_Returns_To_Editor_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("open_selected_root");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Multi_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");
      Editor.Executor.Search_Results_Commands.Execute_Focus_Search_Results (S);
      Editor.Executor.Search_Results_Commands.Execute_Search_Results_Move_Down (S);
      Editor.Executor.Search_Results_Commands.Execute_Search_Results_Open_Selected (S);

      Assert
        (To_String (S.File_Info.Display_Name) = "needle_multi.txt",
         "Enter should open the selected Search Results match");
      Assert
        (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 2,
         "ordinary Search Results Enter keeps project-search row selection as activation source");
      Assert
        (not Editor.State.Has_Pending_Quick_Fix_Workflow (S),
         "ordinary Search Results Enter does not require quick-fix workflow payloads");
      Assert
        (Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus),
         "Enter should return focus to editor text after opening a result");
      Assert
        (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
         "Enter should keep Search Results panel visible");

      Cleanup_Project_Search_Multi_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Multi_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Search_Results_Open_Returns_To_Editor_Text;

   procedure Test_Search_Results_Escape_Returns_To_Editor_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("escape_root");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");
      Editor.Executor.Search_Results_Commands.Execute_Focus_Search_Results (S);
      Editor.Executor.Search_Results_Commands.Execute_Search_Results_Close_Or_Hide (S);

      Assert
        (Editor.Panel_Focus.Editor_Text_Has_Focus (S.Panel_Focus),
         "Escape should return focus to editor text");
      Assert
        (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
         "Escape should not hide the Search Results panel");

      Cleanup_Project_Search_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Search_Results_Escape_Returns_To_Editor_Text;

   procedure Test_Run_Project_Search_No_Project
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);

      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");

      Assert
        (Editor.Project_Search.Status (S.Project_Search) =
           Editor.Project_Search.Project_Search_No_Project,
         "project search without an open project should report No_Project status");
      Assert
        (Editor.Panels.Is_Visible (S.Panels, Editor.Panels.Bottom_Panel),
         "project search failure should still show the bottom panel");
      Assert
        (Editor.Panels.Active_Bottom_Content (S.Panels) =
           Editor.Panels.Search_Results_Content,
         "running project search should switch bottom content to Search Results");
   end Test_Run_Project_Search_No_Project;

   procedure Test_Run_Search_And_Open_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("project_search_root");
      S : Editor.State.State_Type;
      Before_Text : constant String := "untouched";
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Editor.State.Load_Text (S, Before_Text);
      Build_Project_Search_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");

      Assert
        (Editor.Project_Search.Status (S.Project_Search) =
           Editor.Project_Search.Project_Search_Ok,
         "project search over fixture should complete with Ok status");
      Assert
        (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
         "project search fixture should produce one result");
      Assert
        (Editor.Panels.Active_Bottom_Content (S.Panels) =
           Editor.Panels.Search_Results_Content,
         "successful project search should select Search Results bottom content");

      Editor.Executor.Project_Search_Result_Commands.Execute_Open_Selected_Project_Search_Result (S);

      Assert
        (To_String (S.File_Info.Display_Name) = "needle.txt",
         "opening selected project search result should activate the matching file");
      Assert
        (S.Carets (S.Carets.First_Index).Anchor = 11
         and then S.Carets (S.Carets.First_Index).Pos = 17,
         "opening selected project search result should select the matched text range");
      Assert
        (not S.File_Info.Dirty,
         "opening a project search result must not dirty the target buffer");

      Cleanup_Project_Search_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Run_Search_And_Open_Result;

   procedure Test_Replace_All_Continues_After_First_File_Stales_Preview
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("replace_all_root");
      S    : Editor.State.State_Type;
      Msg  : Unbounded_String := Null_Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "a.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "b.txt"));
      Remove_Dir_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (Ada.Directories.Compose (Root, "a.txt"), "needle a" & ASCII.LF);
      Write_Text_File (Ada.Directories.Compose (Root, "b.txt"), "needle b" & ASCII.LF);

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 2,
              "replace-all setup should find matches in both files");

      Editor.Project_Search.Set_Replace_Text (S.Project_Search, "pin");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Project_Search_Replace_Preview);
      Assert (Editor.Project_Search.Replace_Preview_Count (S.Project_Search) = 2,
              "replace-all setup should preview both file matches");

      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Project_Search_Replace_All_Included);
      Msg := To_Unbounded_String (Latest_Message_Text (S));
      Assert (Ada.Strings.Fixed.Index (To_String (Msg), "Replaced") /= 0
              and then Ada.Strings.Fixed.Index (To_String (Msg), "2 matches") /= 0
              and then Ada.Strings.Fixed.Index (To_String (Msg), "2 files") /= 0,
              "replace all should continue after the first changed file stales preview rows");
      Assert (Editor.Buffers.Global_Dirty_File_Backed_Buffer_Count = 2,
              "replace all should dirty every changed file-backed buffer");
      Assert (Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search),
              "replace all should leave the used preview stale after mutation");

      Remove_File_If_Exists (Ada.Directories.Compose (Root, "a.txt"));
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "b.txt"));
      Remove_Dir_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Ada.Directories.Compose (Root, "a.txt"));
         Remove_File_If_Exists (Ada.Directories.Compose (Root, "b.txt"));
         Remove_Dir_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Replace_All_Continues_After_First_File_Stales_Preview;


   procedure Test_Project_Replace_Uses_UTF8_Byte_Offsets_Safely
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("utf8_replace_root");
      Path : constant String := Ada.Directories.Compose (Root, "utf8.txt");
      S    : Editor.State.State_Type;
      E_Acute : constant String := Character'Val (16#C3#) & Character'Val (16#A9#);
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File_If_Exists (Path);
      Remove_Dir_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (Path, E_Acute & "needle" & ASCII.LF);

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
              "UTF-8 setup should find the literal match after a multibyte prefix");

      Editor.Project_Search.Set_Replace_Text (S.Project_Search, "pin");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Project_Search_Replace_Preview);
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Project_Search_Replace_All_Included);

      Assert (Editor.State.Current_Text (S) = E_Acute & "pin" & ASCII.LF,
              "project replace apply should translate search byte offsets to buffer code-point columns");
      Assert (S.File_Info.Dirty,
              "UTF-8 project replacement should dirty the changed target buffer");

      Remove_File_If_Exists (Path);
      Remove_Dir_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Remove_Dir_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Replace_Uses_UTF8_Byte_Offsets_Safely;

   procedure Test_Replace_Preview_Stales_Dirty_Open_Targets
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("dirty_preview_root");
      Path : constant String := Ada.Directories.Compose (Root, "dirty.txt");
      S    : Editor.State.State_Type;
      Cmd  : Editor.Commands.Command;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Remove_File_If_Exists (Path);
      Remove_Dir_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (Path, "needle" & ASCII.LF);

      Init_Executor_Test_State (S);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);

      Cmd.Kind := Editor.Commands.Insert_Text_Input;
      Cmd.Ch := 'x';
      Cmd.Text := To_Unbounded_String ("x");
      Cmd.Code := Wide_Wide_Character'Val (0);
      Cmd.Shift := False;
      Cmd.Click_X := 0;
      Cmd.Click_Y := 0;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (S.File_Info.Dirty,
              "setup should keep the target file open and dirty");

      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
              "dirty-preview setup should still find the on-disk match");

      Editor.Project_Search.Set_Replace_Text (S.Project_Search, "pin");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Project_Search_Replace_Preview);

      Assert (Editor.Project_Search.Replace_Preview_Is_Stale (S.Project_Search),
              "replacement preview rows for open dirty target buffers must be stale immediately");
      Assert (Editor.Project_Search.Included_Replacement_Count (S.Project_Search) = 0,
              "stale dirty-buffer preview rows must not remain included");

      Remove_File_If_Exists (Path);
      Remove_Dir_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_File_If_Exists (Path);
         Remove_Dir_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Replace_Preview_Stales_Dirty_Open_Targets;

   procedure Test_Project_Search_From_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("selection_root");
      Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose
           (Ada.Directories.Compose (Root, "src"), "editor"),
         "executor.adb");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 25,
          Anchor                => 10,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));

      Editor.Executor.Project_Search_Result_Commands.Execute_Project_Search_From_Selection (S);

      Assert (Editor.Project_Search.Query (S.Project_Search) = "Execute_Command",
              "selection search must set the derived query");
      Assert (Editor.Project_Search.Status (S.Project_Search) =
                Editor.Project_Search.Project_Search_Ok,
              "selection search must run the bounded project search");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) >= 2,
              "selection search should find project-wide matches");
      Assert (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 1,
              "selection search should select the first result");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Search_From_Selection;

   procedure Test_Project_Search_From_Active_Word
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("word_root");
      Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose
           (Ada.Directories.Compose (Root, "src"), "editor"),
         "executor.adb");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 18,
          Anchor                => 18,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));

      Editor.Executor.Project_Search_Result_Commands.Execute_Project_Search_From_Active_Word (S);

      Assert (Editor.Project_Search.Query (S.Project_Search) = "Execute_Command",
              "active-word search must expand [A-Za-z0-9_]+ token");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) >= 2,
              "active-word search must run project-wide search");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Search_From_Active_Word;

   procedure Test_Active_Word_Dotted_Token_Boundary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("dotted_word_root");
      Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose
           (Ada.Directories.Compose (Root, "src"), "editor"),
         "executor.adb");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Set_Buffer_Text (S, "Foo.Bar");

      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 4,
          Anchor                => 4,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      Editor.Executor.Project_Search_Result_Commands.Execute_Project_Search_From_Active_Word (S);
      Assert (Editor.Project_Search.Query (S.Project_Search) = "Bar",
              "active-word extraction should use the token under the caret after a dot");

      Editor.Project_Search.Set_Query (S.Project_Search, "before");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 3,
          Anchor                => 3,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      Editor.Executor.Project_Search_Result_Commands.Execute_Project_Search_From_Active_Word (S);
      Assert (Editor.Project_Search.Query (S.Project_Search) = "before",
              "caret on punctuation must not back up to the previous token");
      Assert (Latest_Message_Text (S) = "No searchable text at cursor",
              "caret on dotted separator should report no searchable text");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Active_Word_Dotted_Token_Boundary;

   procedure Test_Project_Search_Active_Directory
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("active_dir_root");
      Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose
           (Ada.Directories.Compose (Root, "src"), "editor"),
         "executor.adb");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 18,
          Anchor                => 18,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));

      Editor.Executor.Project_Search_Result_Commands.Execute_Project_Search_Active_Directory (S);

      Assert (Editor.Project_Search.Query (S.Project_Search) = "Execute_Command",
              "active-directory search must derive the context query");
      Assert (Editor.Project_Search.Path_Scope (S.Project_Search) = "src/editor/",
              "active-directory search must set containing directory scope");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 2,
              "active-directory search must not include sibling directories");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Project_Search_Active_Directory;

   procedure Test_Context_Search_Failure_Is_Atomic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("failure_root");
      Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose
           (Ada.Directories.Compose (Root, "src"), "editor"),
         "executor.adb");
      S : Editor.State.State_Type;
      Before_Query : constant String := "before";
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Project_Search.Set_Query (S.Project_Search, Before_Query);
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 9,
          Anchor                => 9,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));

      Editor.Executor.Project_Search_Result_Commands.Execute_Project_Search_From_Active_Word (S);

      Assert (Editor.Project_Search.Query (S.Project_Search) = Before_Query,
              "punctuation failure must preserve previous query");
      Assert (Latest_Message_Text (S) = "No searchable text at cursor",
              "punctuation failure must report deterministic no-op");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Context_Search_Failure_Is_Atomic;

   procedure Test_First_Last_Project_Search_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("first_last_root");
      Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose
           (Ada.Directories.Compose (Root, "src"), "editor"),
         "executor.adb");
      S : Editor.State.State_Type;
      Before_Display : Unbounded_String := Null_Unbounded_String;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Before_Display := S.File_Info.Display_Name;
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "Execute_Command");

      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 4,
              "first/last fixture should expose four stored results");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Project_Search_Result_Commands.Execute_Last_Project_Search_Result (S);
      Assert (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 4,
              "last command should select the final stored result");
      Assert (Latest_Message_Text (S) = "Selected last project search result",
              "last command should emit the expected navigation message");
      Assert (S.File_Info.Display_Name = Before_Display,
              "last command must not open or activate files");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Project_Search_Result_Commands.Execute_First_Project_Search_Result (S);
      Assert (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 1,
              "first command should select the first stored result");
      Assert (Latest_Message_Text (S) = "Selected first project search result",
              "first command should emit the expected navigation message");
      Assert (S.File_Info.Display_Name = Before_Display,
              "first command must not open or activate files");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_First_Last_Project_Search_Result;


   procedure Test_Reveal_Active_Project_Search_Result
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("reveal_active_root");
      Path : constant String := Ada.Directories.Compose
        (Ada.Directories.Compose
           (Ada.Directories.Compose (Root, "src"), "editor"),
         "executor.adb");
      S : Editor.State.State_Type;
      Found : Boolean := False;
      Result : Editor.Project_Search.Project_Search_Result;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.File_Open_Commands.Execute_Open_File (S, Path);
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "Execute_Command");
      Found := Editor.Project_Search.Select_First_Result_For_Path
        (S.Project_Search, "src/other/other.adb");
      Assert (Found,
              "setup should select a result outside the active file");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Project_Search_Result_Commands.Execute_Reveal_Active_Project_Search_Result (S);
      Result := Editor.Project_Search.Result_At
        (S.Project_Search,
         Positive (Editor.Project_Search.Selected_Result_Index (S.Project_Search)));

      Assert (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 1,
              "reveal-active should select the first result for the active file");
      Assert (To_String (Result.Relative_Path) = "src/editor/executor.adb",
              "reveal-active should use structured result identities, not rendered rows");
      Assert (Latest_Message_Text (S) =
                "Selected project search result in active file: src/editor/executor.adb:1",
              "reveal-active should report the concrete active-file result location");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Project_Search_Result_Commands.Execute_Reveal_Active_Project_Search_Result (S);
      Assert (Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 1,
              "reveal-active should preserve a selection already in the active file");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Reveal_Active_Project_Search_Result;


   procedure Test_Scope_Selected_Project_Search_Directory
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("scope_selected_root");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Context_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Project_Search.Cycle_File_Kind_Filter (S.Project_Search, True);
      Editor.Project_Search.Set_Case_Sensitive (S.Project_Search, True);
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "Execute_Command");

      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 4,
              "scope setup should have current results before scoping");
      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Search_Commands.Execute_Project_Search_Scope_Selected_Directory (S);

      Assert (Editor.Project_Search.Path_Scope (S.Project_Search) = "src/editor/",
              "scope-selected should derive scope from the selected result directory");
      Assert (Editor.Project_Search.Query (S.Project_Search) = "Execute_Command",
              "scope-selected should preserve the current Project Search query");
      Assert (Editor.Project_Search.File_Kind_Filter (S.Project_Search) =
                Editor.Project_Search.Project_Search_Kind_Ada,
              "scope-selected should preserve the Project Search kind filter");
      Assert (Editor.Project_Search.Case_Sensitive (S.Project_Search),
              "scope-selected should preserve case sensitivity");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 0
              and then Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 0
              and then Editor.Project_Search.Status (S.Project_Search) =
                Editor.Project_Search.Project_Search_Idle,
              "scope-selected should clear stale results, selection, and summary");
      Assert (Latest_Message_Text (S) = "Project search scope: src/editor/",
              "scope-selected should report the derived scope without claiming a rerun");

      Cleanup_Project_Search_Context_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Context_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Scope_Selected_Project_Search_Directory;


   procedure Test_Project_Search_Navigation_No_Result_Messages
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);

      Editor.Executor.Project_Search_Result_Commands.Execute_First_Project_Search_Result (S);
      Assert (Latest_Message_Text (S) = "No project search results",
              "first on empty results should report no results");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Project_Search_Result_Commands.Execute_Last_Project_Search_Result (S);
      Assert (Latest_Message_Text (S) = "No project search results",
              "last on empty results should report no results");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Project_Search_Result_Commands.Execute_Reveal_Active_Project_Search_Result (S);
      Assert (Latest_Message_Text (S) = "No active buffer.",
              "reveal-active without active buffer should report no active buffer");

      Editor.Messages.Clear (S.Messages);
      Editor.Executor.Search_Commands.Execute_Project_Search_Scope_Selected_Directory (S);
      Assert (Latest_Message_Text (S) = "No search result selected.",
              "scope-selected without selection should report no selected result");
   end Test_Project_Search_Navigation_No_Result_Messages;


   procedure Test_Open_Selected_Single_Location_Message
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("single_message_root");
      S : Editor.State.State_Type;
      Msg : Editor.Messages.Editor_Message;
      Found : Boolean := False;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");
      Editor.Messages.Clear (S.Messages);

      Editor.Executor.Project_Search_Result_Commands.Execute_Open_Selected_Project_Search_Result (S);

      Assert (Editor.Messages.Count (S.Messages) = 1,
              "open-selected should emit exactly one primary message");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (Msg) = "Opened needle.txt:2",
              "open-selected should report the concrete result location");
      Assert (To_String (S.File_Info.Display_Name) = "needle.txt",
              "open-selected should still use the existing open-buffer path");

      Cleanup_Project_Search_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Open_Selected_Single_Location_Message;

   procedure Test_Stale_Open_Failure_Preserves_Result_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("stale_search_root");
      S : Editor.State.State_Type;
      Msg : Editor.Messages.Editor_Message;
      Found : Boolean := False;
      Before_Count : Natural := 0;
      Before_Selected : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");
      Before_Count := Editor.Project_Search.Result_Count (S.Project_Search);
      Before_Selected := Editor.Project_Search.Selected_Result_Index (S.Project_Search);
      Remove_File_If_Exists (Ada.Directories.Compose (Root, "needle.txt"));
      Editor.Messages.Clear (S.Messages);

      Editor.Executor.Project_Search_Result_Commands.Execute_Open_Selected_Project_Search_Result (S);

      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = Before_Count
              and then Editor.Project_Search.Selected_Result_Index (S.Project_Search) = Before_Selected,
              "stale open failure should preserve search results and selection");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "stale open failure should emit exactly one primary message");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (Msg) = "Could not open needle.txt: file not found",
              "stale open failure should be deterministic and path-relative");

      Cleanup_Project_Search_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Stale_Open_Failure_Preserves_Result_State;


   procedure Test_Out_Of_Range_Project_Search_Result_Does_Not_Clamp
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("out_of_range_search_root");
      S : Editor.State.State_Type;
      Msg : Editor.Messages.Editor_Message;
      Found : Boolean := False;
      Before_Count : Natural := 0;
      Before_Selected : Natural := 0;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");
      Before_Count := Editor.Project_Search.Result_Count (S.Project_Search);
      Before_Selected := Editor.Project_Search.Selected_Result_Index (S.Project_Search);

      --  Simulate an external/project lifecycle drift that leaves the searched
      --  file present but removes the retained result row.  Activation must not
      --  clamp the stale location to a different line.
      Write_Text_File (Ada.Directories.Compose (Root, "needle.txt"), "short" & ASCII.LF);
      Editor.Messages.Clear (S.Messages);

      Editor.Executor.Project_Search_Result_Commands.Execute_Open_Selected_Project_Search_Result (S);

      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = Before_Count
              and then Editor.Project_Search.Selected_Result_Index (S.Project_Search) = Before_Selected,
              "out-of-range activation should preserve search results and selection");
      Assert (Editor.Messages.Count (S.Messages) = 1,
              "out-of-range activation should emit exactly one primary message");
      Msg := Editor.Messages.Active_Message (S.Messages, Found);
      Assert (Found and then Editor.Messages.Text (Msg) =
                "Search result target unavailable: line 2 is no longer available in needle.txt",
              "out-of-range activation should report unavailable target without clamping");

      Cleanup_Project_Search_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Cleanup_Project_Search_Fixture (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Out_Of_Range_Project_Search_Result_Does_Not_Clamp;


   procedure Test_Open_Project_Search_Bar
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("open_search_bar_root");
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Editor.Quick_Open.Open (S.Quick_Open);

      Editor.Executor.Project_Search_Surface_Commands.Execute_Open_Project_Search_Bar (S);

      Assert (Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar),
              "opening project-search bar should open the bar");
      Assert (not Editor.Quick_Open.Is_Open (S.Quick_Open),
              "opening project-search bar should close quick open");
      Assert (Editor.Project_Search_Bar.Query_Text (S.Project_Search_Bar) = "needle",
              "opening project-search bar should mirror current project-search query");
      Cleanup_Project_Search_Fixture (Root);
   end Test_Open_Project_Search_Bar;

   procedure Test_Run_Project_Search_From_Bar
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Editor.Executor.Project_Search_Surface_Commands.Execute_Open_Project_Search_Bar (S);
      Editor.Project_Search_Bar.Set_Query_Text (S.Project_Search_Bar, "needle");

      Editor.Executor.Project_Search_Surface_Commands.Execute_Run_Project_Search_From_Bar (S);

      Assert (Editor.Project_Search.Query (S.Project_Search) = "needle",
              "running from bar should copy bar query to Project_Search");
      Assert (Editor.Project_Search.Status (S.Project_Search) =
                Editor.Project_Search.Project_Search_No_Project,
              "running from bar without a project should report no-project deterministically");
      Assert (Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar),
              "running from bar should keep project-search bar open");
      Assert (Editor.Panels.Active_Bottom_Content (S.Panels) =
                Editor.Panels.Search_Results_Content,
              "running from bar should show Search Results content");
   end Test_Run_Project_Search_From_Bar;

   procedure Test_Close_And_Clear_Project_Search_Bar
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("close_search_bar_root");
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_Search_Surface_Commands.Execute_Open_Project_Search_Bar (S);
      Editor.Project_Search_Bar.Set_Query_Text (S.Project_Search_Bar, "needle");
      Editor.Project_Search.Set_Query (S.Project_Search, "needle");

      Editor.Executor.Project_Search_Surface_Commands.Execute_Close_Project_Search_Bar (S);
      Assert (not Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar),
              "close project-search bar should close only the input surface");
      Assert (Editor.Project_Search.Query (S.Project_Search) = "needle",
              "close project-search bar should preserve project-search results/query");

      Editor.Project_Search_Bar.Open (S.Project_Search_Bar);
      Editor.Executor.Project_Search_Result_Commands.Execute_Clear_Project_Search (S);
      Assert (Editor.Project_Search.Query (S.Project_Search) = "",
              "clear project search should clear project-search query");
      Assert (Editor.Project_Search_Bar.Query_Text (S.Project_Search_Bar) = "",
              "clear project search should clear open bar field");
      Assert (Editor.Project_Search_Bar.Is_Open (S.Project_Search_Bar),
              "clear project search must not close project-search bar");
   end Test_Close_And_Clear_Project_Search_Bar;

   procedure Test_Query_Edit_And_Refresh_Clear_Results
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := Temp_Path ("query_refresh_root");
      S : Editor.State.State_Type;
   begin
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);
      Build_Project_Search_Fixture (Root);

      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project (S, Root);
      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
              "fixture should produce one Project Search result before query edit");

      Editor.Executor.Project_Search_Surface_Commands.Execute_Open_Project_Search_Bar (S);
      Editor.Project_Search_Bar.Set_Query_Text (S.Project_Search_Bar, "needle");
      Editor.Executor.Project_Search_Surface_Commands.Execute_Project_Search_Bar_Insert_Text (S, "x");
      Assert (Editor.Project_Search.Query (S.Project_Search) = "needlex",
              "query edit should update Project Search query state");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 0
              and then Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 0,
              "query edit should clear old Project Search results and selection");

      Editor.Executor.Project_Search_Result_Commands.Execute_Run_Project_Search (S, "needle");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 1,
              "fixture should produce one Project Search result before refresh");
      Editor.Executor.Execute_Command
        (S, Editor.Commands.Command_Refresh_Project_Files);
      Assert (Editor.Project_Search.Query (S.Project_Search) = "needle",
              "project file refresh should preserve visible Project Search query");
      Assert (Editor.Project_Search.Result_Count (S.Project_Search) = 0
              and then Editor.Project_Search.Selected_Result_Index (S.Project_Search) = 0,
              "project file refresh should clear Project Search results and selection");

      Cleanup_Project_Search_Fixture (Root);
      Editor.Buffers.Reset_Global_For_Test;
   end Test_Query_Edit_And_Refresh_Clear_Results;

   procedure Test_Find_Navigation_Is_Incremental_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Insert_Text (S, "alpha");

      Cmd.Kind := Editor.Commands.Active_Find_Next;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Search.Has_Match (S.Active_Find_Match),
              "find-next must activate an active-buffer match");
      Assert (Natural (S.Carets (0).Anchor) = 11
                and then Natural (S.Carets (0).Pos) = 11,
              "find-next must reveal the next literal match start");
      Assert (Editor.Feature_Search_Results.Is_Empty (S.Feature_Search_Results),
              "find-next must not populate Feature Panel Search Results");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0,
              "find-next must not create Feature Panel rows");
      Assert (not S.File_Info.Dirty,
              "find navigation must not dirty the buffer");
   end Test_Find_Navigation_Is_Incremental_Only;

   procedure Test_Active_Find_Previous_Wraps_Deterministically
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "one two one");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Insert_Text (S, "one");

      Cmd.Kind := Editor.Commands.Active_Find_Previous;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.Search.Has_Match (S.Active_Find_Match),
              "find-previous must activate a match");
      Assert (Natural (S.Carets (0).Anchor) = 8
                and then Natural (S.Carets (0).Pos) = 8,
              "find-previous from the start must wrap to the final match");
   end Test_Active_Find_Previous_Wraps_Deterministically;

   procedure Test_Find_Query_Persists_Across_Buffer_Switch
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("find_switch_root");
      S      : Editor.State.State_Type;
      A_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      B_Path : constant String := Ada.Directories.Compose (Root, "b.txt");
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      Cmd    : Editor.Commands.Command;
      Closed : Boolean := False;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "alpha only");
      Write_Text_File (B_Path, "beta alpha");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Insert_Text (S, "alpha");
      Cmd.Kind := Editor.Commands.Active_Find_Next;
      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Search.Has_Match (S.Active_Find_Match),
              "setup should find a match in the first buffer");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);

      Assert (Editor.Input_Field.Text (S.Active_Find_Input) = "alpha",
              "find query must persist across buffer switches");
      Assert (not Editor.Search.Has_Match (S.Active_Find_Match),
              "active match must clear after switching buffers");

      Editor.Executor.Execute_No_Log (S, Cmd);
      Assert (Editor.Search.Has_Match (S.Active_Find_Match)
                and then Natural (S.Active_Find_Match.Start_Index) = 5,
              "find-next after switch must search the newly active buffer");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert (Buffer_Text (S) = "alpha only",
              "find state must not mutate the old buffer content");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Find_Query_Persists_Across_Buffer_Switch;


   procedure Test_Find_Highlights_Clear_When_Find_Closes
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Insert_Text (S, "alpha");
      Editor.Input_Bridge.Set_State_For_Test (S);
      declare
         Snapshot_State : Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
      begin
         Editor.Render_Model.Build_Render_Snapshot (Snapshot_State, Snap);
      end;
      Assert (Snap.Active_Find_Match_Count = 2,
              "open find must project visible active-buffer matches");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Hide (S);
      Editor.Input_Bridge.Set_State_For_Test (S);
      declare
         Snapshot_State : Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
      begin
         Editor.Render_Model.Build_Render_Snapshot (Snapshot_State, Snap);
      end;
      Assert (Snap.Active_Find_Match_Count = 0,
              "closing find must clear projected highlights");
      Assert (S.Active_Find_Matches.Is_Empty,
              "closing find must clear transient session-local query results");
   end Test_Find_Highlights_Clear_When_Find_Closes;

   procedure Test_Query_Edit_Recomputes_Current_From_Caret
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
          (Pos                   => 6,
          Anchor                => 6,
          Virtual_Column        => 0,
          Anchor_Virtual_Column => 0));
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Insert_Text (S, "alpha");

      Assert (Editor.Search.Has_Match (S.Active_Find_Match),
              "query edit must compute a current match");
      Assert (Natural (S.Active_Find_Match.Start_Index) = 11,
              "current match after query edit must be at or after cursor");
      Assert (Natural (S.Carets (0).Pos) = 6,
              "query editing must preserve editor cursor");
   end Test_Query_Edit_Recomputes_Current_From_Caret;

   procedure Test_Wrap_Status_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Insert_Text (S, "alpha");
      Cmd.Kind := Editor.Commands.Active_Find_Previous;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (S.Active_Find_Wrapped,
              "wrapped find navigation must mark wrapped status");
      Assert (Natural (S.Active_Find_Match.Start_Index) = 11,
              "previous from first current match wraps to final match");
   end Test_Wrap_Status_Is_Deterministic;

   procedure Test_Current_Match_Emphasis_Is_Projected
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Insert_Text (S, "alpha");

      Editor.Input_Bridge.Set_State_For_Test (S);
      declare
         Snapshot_State : Editor.State.State_Type := Editor.Input_Bridge.Get_State_For_Test;
      begin
         Editor.Render_Model.Build_Render_Snapshot (Snapshot_State, Snap);
      end;

      Assert (Snap.Active_Find_Match_Count = 2,
              "snapshot must project all visible find matches");
      Assert (Editor.Search.Has_Match (Snap.Active_Find_Match),
              "snapshot must project the current match for emphasis");
      Assert (Natural (Snap.Active_Find_Match.Start_Index) = 0,
              "current-match emphasis must point at the recomputed match");
      Assert (Snap.Active_Find_Matches (1).Index = Snap.Active_Find_Match.Index,
              "projected match metadata must preserve the active match index");
   end Test_Current_Match_Emphasis_Is_Projected;

   procedure Test_Find_Query_Edit_Stays_Out_Of_Feature_Search
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Insert_Text (S, "alpha");

      Assert (Editor.Feature_Search_Results.Is_Empty (S.Feature_Search_Results),
              "find query edits must not populate Feature Search Results");
      Assert (Editor.Feature_Panel.Row_Count (S.Feature_Panel) = 0,
              "find query edits must not create Feature Panel rows");
      Assert (not S.File_Info.Dirty,
              "find query edits must not dirty the active buffer");
   end Test_Find_Query_Edit_Stays_Out_Of_Feature_Search;


   procedure Test_Replace_Show_Hide_Clears_Transient_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");

      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Assert (S.Active_Find_Prompt,
              "replace.show must make canonical Find visible");
      Assert (S.Active_Replace_Prompt,
              "replace.show must make Replace visible");
      Assert (Latest_Message_Text (S) = "Replace shown",
              "replace.show must emit one primary message");

      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");
      Assert (To_String (S.Active_Replace_Text) = "Execute",
              "replace.text.set must store literal transient text");

      Editor.Executor.Find_Replace_Commands.Execute_Replace_Hide (S);
      Assert (not S.Active_Replace_Prompt,
              "replace.hide must hide Replace");
      Assert (S.Active_Find_Prompt,
              "replace.hide must preserve Find visibility");
      Assert (Length (S.Active_Replace_Text) = 0,
              "replace.hide must clear replacement text");
      Assert (Length (S.Active_Replace_Error_Message) = 0,
              "replace.hide must clear replacement errors");

      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Again");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Hide (S);
      Assert (not S.Active_Find_Prompt and then not S.Active_Replace_Prompt,
              "find.hide must hide Replace with Find");
      Assert (Length (S.Active_Replace_Text) = 0,
              "find.hide must clear replacement text");
   end Test_Replace_Show_Hide_Clears_Transient_Text;


   procedure Test_Replace_Current_Uses_Find_And_Dirties_No_History
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");

      Cmd.Kind := Editor.Commands.Active_Replace_Current;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.State.Current_Text (S) = "Execute Run",
              "replace.current must replace exactly the selected canonical Find match");
      Assert (S.File_Info.Dirty,
              "replace.current must dirty the active buffer through the edit path");
      Assert (Natural (S.Active_Find_Matches.Length) = 1,
              "replace.current must recompute post-edit Find matches");
      Assert (Latest_Message_Text (S) = "Replaced current match",
              "replace.current must emit one primary success message");
      Assert (not Editor.History.Undo_Stack.Is_Empty,
              "replace.current must create one undo entry when text changes");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert (Editor.State.Current_Text (S) = "Run Run",
              "undo after replace.current restores previous buffer text");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert (Editor.State.Current_Text (S) = "Execute Run",
              "redo after replace.current reapplies replacement");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "replace.current must not record Navigation History");
      Assert (Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "replace.current must not mutate forward Navigation History");
   end Test_Replace_Current_Uses_Find_And_Dirties_No_History;


   procedure Test_Replace_All_Is_Literal_Offset_Safe_And_Recomputes
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run (Run) Run");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "\1");

      Cmd.Kind := Editor.Commands.Active_Replace_All;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.State.Current_Text (S) = "\1 (\1) \1",
              "replace.all must insert backslash/capture-like text literally");
      Assert (S.File_Info.Dirty,
              "replace.all must dirty the active buffer");
      Assert (Natural (S.Active_Find_Matches.Length) = 0,
              "replace.all must recompute Find matches after replacement");
      Assert (Latest_Message_Text (S) = "Replaced 3 matches",
              "replace.all must report the original canonical replacement count");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "replace.all must create one grouped undo entry");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Undo);
      Assert (Editor.State.Current_Text (S) = "Run (Run) Run",
              "undo after replace.all restores entire previous buffer text");
      Editor.Executor.Execute_No_Log (S, Editor.Test_Helper.Redo);
      Assert (Editor.State.Current_Text (S) = "\1 (\1) \1",
              "redo after replace.all reapplies entire replacement result");
      Assert (Natural (Editor.History.Undo_Stack.Length) = 1,
              "replace.all remains one grouped undo entry after redo");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0,
              "replace.all must not record Navigation History");
   end Test_Replace_All_Is_Literal_Offset_Safe_And_Recomputes;


   procedure Test_Replace_All_Uses_Canonical_Non_Overlapping_Matches
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "aaaa");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "aa");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "b");

      Cmd.Kind := Editor.Commands.Active_Replace_All;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.State.Current_Text (S) = "bb",
              "replace.all must use canonical non-overlapping Find matches");
      Assert (Latest_Message_Text (S) = "Replaced 2 matches",
              "replace.all must count canonical non-overlapping matches");
   end Test_Replace_All_Uses_Canonical_Non_Overlapping_Matches;


   procedure Test_Replace_Empty_Text_Deletes_Matches
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S   : Editor.State.State_Type;
      Cmd : Editor.Commands.Command;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run and Run");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Clear_Text (S);

      Cmd.Kind := Editor.Commands.Active_Replace_All;
      Editor.Executor.Execute_No_Log (S, Cmd);

      Assert (Editor.State.Current_Text (S) = " and ",
              "empty replacement text must delete matched text");
      Assert (Latest_Message_Text (S) = "Replaced 2 matches",
              "delete-style replace must still report replacements");
   end Test_Replace_Empty_Text_Deletes_Matches;



   procedure Test_Replace_Text_Newline_Is_Rejected
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");

      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Line" & ASCII.LF & "Break");

      Assert (To_String (S.Active_Replace_Text) = "Execute",
              "invalid multiline replacement text must not replace prior text");
      Assert (To_String (S.Active_Replace_Error_Message) = "Replacement text must be single-line",
              "invalid multiline replacement text must set renderable Replace error");
      Assert (Latest_Message_Text (S) = "Replacement text must be single-line.",
              "invalid multiline replacement text must emit one primary message");

      Editor.Executor.Find_Replace_Commands.Execute_Replace_Clear_Text (S);
      Assert (Length (S.Active_Replace_Error_Message) = 0,
              "replace.text.clear must clear validation error");
   end Test_Replace_Text_Newline_Is_Rejected;


   procedure Test_Replace_Current_Preserves_Valid_Selected_Match
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Back_Before : Natural := 0;
      Forward_Before : Natural := 0;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run one Run");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Next (S);
      Assert (Editor.Search.Has_Match (S.Active_Find_Match)
              and then Natural (S.Active_Find_Match.Start_Index) = 8,
              "precondition: second Find match selected");
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Forward_Before := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Current (S);

      Assert (Editor.State.Current_Text (S) = "Run one Execute",
              "replace.current must keep the still-valid selected match across recompute");
      Assert (Natural (S.Active_Find_Matches.Length) = 1,
              "replace.current must recompute post-replacement matches");
      Assert (Editor.Search.Has_Match (S.Active_Find_Match)
              and then Natural (S.Active_Find_Match.Start_Index) = 0,
              "post-replace selection must wrap to the first remaining match");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Forward_Before,
              "replace.current must not add or clear navigation history");
   end Test_Replace_Current_Preserves_Valid_Selected_Match;


   procedure Test_Replace_Current_Does_Not_Trust_Stale_Deleted_Range
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run one Run");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Next (S);
      Assert (Natural (S.Active_Find_Match.Start_Index) = 8,
              "precondition: stale selected range points at second Run");

      Set_Buffer_Text (S, "Run one done");
      S.Active_Find_Query := To_Unbounded_String ("Run");
      S.Active_Find_Stale := True;
      S.Active_Find_Match.Start_Index := 8;
      S.Active_Find_Match.End_Index := 11;
      S.Active_Find_Match.Index := 2;

      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Current (S);

      Assert (Editor.State.Current_Text (S) = "Execute one done",
              "replace.current must target recomputed current text, not stale deleted coordinates");
      Assert (Latest_Message_Text (S) = "Replaced current match; no more matches",
              "replace.current must report no remaining post-replacement matches");
   end Test_Replace_Current_Does_Not_Trust_Stale_Deleted_Range;


   procedure Test_Replace_All_Does_Not_Recursively_Replace_New_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "foo foo");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "foo");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "foofoo");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_All (S);

      Assert (Editor.State.Current_Text (S) = "foofoo foofoo",
              "replace.all must replace only the original canonical match set");
      Assert (Latest_Message_Text (S) = "Replaced 2 matches",
              "replace.all must report the original canonical count");
      Assert (Natural (S.Active_Find_Matches.Length) = 4,
              "post-replacement Find matches must reflect current text after non-recursive replace-all");
   end Test_Replace_All_Does_Not_Recursively_Replace_New_Text;



   procedure Test_Replace_Lifecycle_Find_Hide_And_Render_Coherence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Before_Back : Natural := 0;
      Before_Forward : Natural := 0;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Forward := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Assert (S.Active_Find_Prompt and then S.Active_Replace_Prompt,
              "replace.show must keep canonical Find visible and show Replace");
      Assert (To_String (S.Active_Find_Query) = "Run"
              and then Natural (S.Active_Find_Matches.Length) = 2,
              "replace.show must not clear Find query/options/matches");
      Assert (Latest_Message_Text (S) = "Replace shown",
              "replace.show must emit exactly its primary shown message");

      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Hide (S);
      Assert ((not S.Active_Replace_Prompt) and then S.Active_Find_Prompt,
              "replace.hide must hide only Replace under the policy");
      Assert (Length (S.Active_Replace_Text) = 0
              and then Length (S.Active_Replace_Error_Message) = 0,
              "replace.hide must clear replacement text and error");
      Assert (To_String (S.Active_Find_Query) = "Run"
              and then Natural (S.Active_Find_Matches.Length) = 2,
              "replace.hide must not clear canonical Find state");

      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Toggle (S);
      Assert (not S.Active_Replace_Prompt,
              "replace.toggle must hide when Replace is visible");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Toggle (S);
      Assert (S.Active_Replace_Prompt and then S.Active_Find_Prompt,
              "replace.toggle must show Replace and compatible Find when hidden");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Before_Back
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Before_Forward,
              "replace visibility commands must not mutate Navigation History");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Hide (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert ((not S.Active_Find_Prompt) and then (not S.Active_Replace_Prompt),
              "find.hide must clear Replace so it cannot remain orphaned");
      Assert (Length (S.Active_Find_Query) = 0
              and then S.Active_Find_Matches.Is_Empty
              and then Length (S.Active_Replace_Text) = 0
              and then Length (S.Active_Replace_Error_Message) = 0,
              "find.hide must clear Find and Replace transient state together");
      Assert ((not Snap.Find_Visible) and then (not Snap.Replace_Visible)
              and then Snap.Active_Find_Match_Count = 0,
              "snapshot after find.hide must expose no Find ranges or Replace field");
   end Test_Replace_Lifecycle_Find_Hide_And_Render_Coherence;


   procedure Test_Replacement_Text_Literal_Matrix_And_No_Recompute
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Matches : Natural := 0;
      Before_Query : Unbounded_String;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Before_Matches := Natural (S.Active_Find_Matches.Length);
      Before_Query := S.Active_Find_Query;

      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Dispatch_Command");
      Assert (To_String (S.Active_Replace_Text) = "Dispatch_Command",
              "ordinary replacement text must be stored literally");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "");
      Assert (Length (S.Active_Replace_Text) = 0,
              "empty replacement text must be stored and later delete matches");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "  spaced value  ");
      Assert (To_String (S.Active_Replace_Text) = "  spaced value  ",
              "replacement text must preserve surrounding spaces literally");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "\1");
      Assert (To_String (S.Active_Replace_Text) = "\1",
              "backslash capture-like text must be literal replacement text");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "$1");
      Assert (To_String (S.Active_Replace_Text) = "$1",
              "dollar capture-like text must be literal replacement text");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Run.Run");
      Assert (To_String (S.Active_Replace_Text) = "Run.Run",
              "punctuation must be literal replacement text");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "tab" & ASCII.HT & "value");
      Assert (To_String (S.Active_Replace_Text) = "tab" & ASCII.HT & "value",
              "tab replacement text must follow the current single-line field policy");
      Assert (To_String (S.Active_Find_Query) = To_String (Before_Query)
              and then Natural (S.Active_Find_Matches.Length) = Before_Matches,
              "replace.text.set must not recompute or mutate canonical Find matches");

      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Line" & ASCII.LF & "Break");
      Assert (To_String (S.Active_Replace_Text) = "tab" & ASCII.HT & "value"
              and then To_String (S.Active_Replace_Error_Message) = "Replacement text must be single-line"
              and then Latest_Message_Text (S) = "Replacement text must be single-line.",
              "newline replacement text must be rejected atomically with one primary message");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Clear_Text (S);
      Assert (Length (S.Active_Replace_Text) = 0
              and then Length (S.Active_Replace_Error_Message) = 0,
              "replace.text.clear must clear text and prior validation error");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = 0
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = 0,
              "replacement text edits must not record Navigation History");
   end Test_Replacement_Text_Literal_Matrix_And_No_Recompute;


   procedure Test_Replace_Current_Selected_Stale_And_No_Selected_Workflows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
      Back_Before : Natural := 0;
      Forward_Before : Natural := 0;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run;" & ASCII.LF & "Run;" & ASCII.LF & "Run;");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Next (S);
      Assert (Natural (S.Active_Find_Match.Start_Row) = 1,
              "precondition: second match selected");
      Back_Before := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Forward_Before := Editor.Navigation_History.Forward_Count (S.Navigation_History);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Current (S);
      Assert (Buffer_Text (S) = "Run;" & ASCII.LF & "Execute;" & ASCII.LF & "Run;",
              "replace.current must replace only the selected canonical match");
      Assert (S.File_Info.Dirty and then Natural (S.Active_Find_Matches.Length) = 2,
              "replace.current must dirty and recompute post-replacement Find matches");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Active_Find_Match_Count = 2
              and then Snap.Active_Find_Matches (1).Start_Row = 0
              and then Snap.Active_Find_Matches (2).Start_Row = 2,
              "rendered Find ranges after replace.current must correspond to post-replacement text");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Back_Before
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Forward_Before,
              "replace.current must not add or clear Navigation History");

      Set_Buffer_Text (S, "xx Run yy Run");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      S.Active_Find_Match := Editor.Search.No_Match;
      S.Carets.Replace_Element
        (S.Carets.First_Index,
         Editor.Cursors.Caret_State'
           (Pos => 1, Anchor => 1, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Current (S);
      Assert (Buffer_Text (S) = "xx Execute yy Run",
              "replace.current without selected match must select the nearest match at or after the caret");

      Set_Buffer_Text (S, "Run one Run");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Next (S);
      Set_Buffer_Text (S, "Run one done");
      S.Active_Find_Query := To_Unbounded_String ("Run");
      S.Active_Find_Stale := True;
      S.Active_Find_Match.Start_Index := 8;
      S.Active_Find_Match.End_Index := 11;
      S.Active_Find_Match.Index := 2;
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Current (S);
      Assert (Buffer_Text (S) = "Execute one done",
              "replace.current must recompute stale matches and never trust stale deleted coordinates");

      Set_Buffer_Text (S, "No hits here");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Current (S);
      Assert (Buffer_Text (S) = "No hits here"
              and then Latest_Message_Text (S) = "No matches",
              "replace.current with no recomputed matches must be atomic and report no matches");
   end Test_Replace_Current_Selected_Stale_And_No_Selected_Workflows;


   procedure Test_Replace_Current_Active_Buffer_Switch_Uses_Current_Buffer
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root   : constant String := Temp_Path ("replace_switch_root");
      S      : Editor.State.State_Type;
      A_Path : constant String := Ada.Directories.Compose (Root, "a.txt");
      B_Path : constant String := Ada.Directories.Compose (Root, "b.txt");
      A_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
      B_Id   : Editor.Buffers.Buffer_Id := Editor.Buffers.No_Buffer;
   begin
      Remove_Tree_If_Exists (Root);
      Ada.Directories.Create_Directory (Root);
      Write_Text_File (A_Path, "Run in A");
      Write_Text_File (B_Path, "Run in B");
      Editor.Buffers.Reset_Global_For_Test;
      Init_Executor_Test_State (S);

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, A_Path);
      A_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Next (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");

      Editor.Executor.File_Open_Commands.Execute_Open_File (S, B_Path);
      B_Id := Editor.Buffers.Global_Active_Buffer;
      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, B_Id);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Current (S);
      Assert (Buffer_Text (S) = "Execute in B",
              "replace.current after buffer switch must operate on the active buffer only");

      Editor.Executor.File_Open_Commands.Execute_Switch_Buffer (S, A_Id);
      Assert (Buffer_Text (S) = "Run in A",
              "replace.current after switch must not mutate the old selected-buffer range");

      Remove_Tree_If_Exists (Root);
      Editor.Buffers.Reset_Global_For_Test;
   exception
      when others =>
         Remove_Tree_If_Exists (Root);
         Editor.Buffers.Reset_Global_For_Test;
         raise;
   end Test_Replace_Current_Active_Buffer_Switch_Uses_Current_Buffer;


   procedure Test_Replace_All_Options_Span_Empty_And_Same_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run" & ASCII.LF & "PreRun" & ASCII.LF & "Run_One" & ASCII.LF & "Run.");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_All (S);
      Assert (Buffer_Text (S) = "Execute Execute" & ASCII.LF & "PreExecute" & ASCII.LF & "Execute_One" & ASCII.LF & "Execute.",
              "replace.all must replace all canonical substring matches with offset-safe edits");
      Assert (Latest_Message_Text (S) = "Replaced 5 matches",
              "replace.all count must equal the original canonical match count");

      Set_Buffer_Text (S, "Run run Runner runner PreRun preRun Run_One run_one Run.Run");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Case_Toggle (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_All (S);
      Assert (Buffer_Text (S) = "Execute run Runner runner PreRun preRun Run_One run_one Execute.Execute",
              "replace.all must respect current case-sensitive whole-word canonical Find options");
      Assert (S.Active_Find_Case_Sensitive and then S.Active_Find_Whole_Word,
              "replace.all must not reset Find options");

      Set_Buffer_Text (S, "aaa");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "a");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Case_Clear (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Whole_Word_Clear (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "aa");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_All (S);
      Assert (Buffer_Text (S) = "aaaaaa"
              and then Latest_Message_Text (S) = "Replaced 3 matches",
              "replace.all must not recursively replace text inserted during the same invocation");

      Set_Buffer_Text (S, "abc abc abc");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "abc");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_All (S);
      Assert (Buffer_Text (S) = "  "
              and then Natural (S.Active_Find_Matches.Length) = 0,
              "empty replacement replace.all must delete all original canonical matches and recompute no ranges");

      Set_Buffer_Text (S, "Run Run");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_All (S);
      Assert (Buffer_Text (S) = "Run Run"
              and then Latest_Message_Text (S) = "Replaced 2 matches",
              "replacement text equal to query must complete deterministically without recursive replacement");
   end Test_Replace_All_Options_Span_Empty_And_Same_Text;


   procedure Test_Context_Derived_Query_Render_Dirty_And_Failure_Atomicity
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      S.Carets.Clear;
      S.Carets.Append
        (Editor.Cursors.Caret_State'
           (Pos => 10, Anchor => 6, Virtual_Column => 0, Anchor_Virtual_Column => 0));
      Editor.Executor.Find_Replace_Commands.Execute_Find_From_Selection (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "BETA");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Current (S);
      Assert (Buffer_Text (S) = "alpha BETA alpha"
              and then S.File_Info.Dirty,
              "replace.current must use context-derived canonical Find query on dirty in-memory text");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Replace_Visible
              and then To_String (Snap.Replace_Text) = "BETA"
              and then Snap.Active_Find_Match_Count = 0,
              "render snapshot after replacement must expose Replace text and post-replacement Find ranges only");

      Editor.Executor.Find_Replace_Commands.Execute_Replace_Current (S);
      Assert (Buffer_Text (S) = "alpha BETA alpha"
              and then Latest_Message_Text (S) = "No matches",
              "replace.current no-match failure after recompute must not mutate buffer text");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "alpha");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Line" & ASCII.LF & "Break");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_All (S);
      Assert (Buffer_Text (S) = "alpha BETA alpha"
              and then Latest_Message_Text (S) = "Replacement text must be single-line.",
              "invalid replacement text must fail before any replace-all mutation");
   end Test_Context_Derived_Query_Render_Dirty_And_Failure_Atomicity;


   procedure Test_Feature_Independence_Navigation_And_Lifecycle_Cleanup
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before_Back : Natural := 0;
      Before_Forward : Natural := 0;
      Before_Project_Search_Query : constant String := "project token";
      Before_Quick_Open_Query : constant String := "quick token";
      Before_Goto_Text : constant String := "22";
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");
      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, Before_Goto_Text);
      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, Before_Quick_Open_Query);
      Editor.Project_Search.Set_Query (S.Project_Search, Before_Project_Search_Query);
      Editor.Navigation_History.Record_Explicit_Navigation
        (S.Navigation_History, (Buffer_Id => 1, Line => 1, Column => 0, others => <>));
      Before_Back := Editor.Navigation_History.Back_Count (S.Navigation_History);
      Before_Forward := Editor.Navigation_History.Forward_Count (S.Navigation_History);

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Current (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_All (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Hide (S);

      Assert (Editor.Go_To_Line.Text (S.Go_To_Line) = Before_Goto_Text,
              "Replace commands must not mutate Go To Line state except established overlay policy");
      Assert (Editor.Quick_Open.Query_Text (S.Quick_Open) = Before_Quick_Open_Query,
              "Replace commands must not mutate Quick Open query state");
      Assert (Editor.Project_Search.Query (S.Project_Search) = Before_Project_Search_Query,
              "Replace commands must not mutate Project Search state");
      Assert (Editor.Navigation_History.Back_Count (S.Navigation_History) = Before_Back
              and then Editor.Navigation_History.Forward_Count (S.Navigation_History) = Before_Forward,
              "Replace commands must not push back stack or clear forward stack");

      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Dispatch_Command");
      S.Active_Replace_Error_Message := To_Unbounded_String ("synthetic replace error");
      Editor.State.Reset_Project_Scoped_State (S);
      Assert ((not S.Active_Replace_Prompt)
              and then Length (S.Active_Replace_Text) = 0
              and then Length (S.Active_Replace_Error_Message) = 0,
              "project lifecycle cleanup must clear all transient Replace state");
   end Test_Feature_Independence_Navigation_And_Lifecycle_Cleanup;


   procedure Test_Routes_Availability_Absent_Commands_And_Persistence
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary : Unbounded_String;
      Found : Boolean := True;
      Id : Editor.Commands.Command_Id := Editor.Commands.No_Command;
      Availability : Editor.Commands.Command_Availability;

      procedure Check_Absent (Name : String) is
      begin
         Id := Editor.Commands.Command_Id_From_Stable_Name (Name, Found);
         Assert ((not Found) and then Id = Editor.Commands.No_Command,
                 Name & " must remain absent from descriptors, palette, default bindings, input routes, and Executor dispatch");
      end Check_Absent;
   begin
      Id := Editor.Commands.Command_Id_From_Stable_Name ("edit.replace.show", Found);
      Assert (Found and then Id = Editor.Commands.Command_Replace_Show,
              "edit.replace.show route must resolve through command metadata");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("edit.replace.current", Found);
      Assert (Found and then Id = Editor.Commands.Command_Replace_Current,
              "edit.replace.current route must resolve through command metadata");
      Id := Editor.Commands.Command_Id_From_Stable_Name ("edit.replace.all", Found);
      Assert (Found and then Id = Editor.Commands.Command_Replace_All,
              "edit.replace.all route must resolve through command metadata");

      Check_Absent ("edit.replace.regex");
      Check_Absent ("edit.replace.preview");
      Check_Absent ("edit.replace.confirm-next");
      Check_Absent ("edit.replace.history");
      Check_Absent ("edit.replace.in-project");
      Check_Absent ("edit.replace.all-in-project");
      Check_Absent ("edit.replace.selection-only");
      Check_Absent ("edit.replace.capture-group");
      Check_Absent ("edit.replace.smart-case");

      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Dispatch_Command");
      Availability := Editor.Executor.Command_Availability (S, Editor.Commands.Command_Replace_All);
      Assert (Availability.Status = Editor.Commands.Command_Available,
              "replace.all availability must report available for current active-buffer Replace state");
      Assert (Buffer_Text (S) = "Run Run"
              and then To_String (S.Active_Replace_Text) = "Dispatch_Command"
              and then Natural (S.Active_Find_Matches.Length) = 2,
              "replace availability must be side-effect-free over buffer, Replace, and Find state");

      S.Active_Replace_Error_Message := To_Unbounded_String ("Replacement text must be single-line");
      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Snapshot));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), "Dispatch_Command") = 0
              and then Ada.Strings.Fixed.Index (To_String (Summary), "Replacement text") = 0
              and then Ada.Strings.Fixed.Index (To_String (Summary), "replace") = 0
              and then Ada.Strings.Fixed.Index (To_String (Summary), "Run") = 0,
              "workspace persistence must exclude Replace text/error/counts and Find transient query/matches");
   end Test_Routes_Availability_Absent_Commands_And_Persistence;

   procedure Test_Replace_Render_Uses_Canonical_Overlay_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S    : Editor.State.State_Type;
      Snap : Editor.Render_Model.Render_Snapshot;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run Run");

      S.Active_Find_Prompt := False;
      S.Active_Replace_Prompt := True;
      S.Active_Replace_Text := To_Unbounded_String ("removed-visible-text");
      S.Active_Replace_Error_Message := To_Unbounded_String ("removed-visible-error");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert ((not Snap.Replace_Visible)
              and then Length (Snap.Replace_Text) = 0
              and then Length (Snap.Replace_Error_Message) = 0,
              "render must not resurrect a Replace surface without canonical Find visibility");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");
      S.Active_Replace_Error_Message := To_Unbounded_String ("canonical replace error");
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert (Snap.Replace_Visible
              and then To_String (Snap.Replace_Text) = "Execute"
              and then To_String (Snap.Replace_Error_Message) = "canonical replace error"
              and then Snap.Active_Find_Match_Count = 2,
              "render snapshot must project Replace only from canonical state and canonical Find matches");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Hide (S);
      Editor.Render_Model.Build_Render_Snapshot (S, Snap);
      Assert ((not Snap.Replace_Visible)
              and then Length (Snap.Replace_Text) = 0
              and then Length (Snap.Replace_Error_Message) = 0,
              "Find hide must hide and clear the canonical Replace render surface");
   end Test_Replace_Render_Uses_Canonical_Overlay_State;


   procedure Test_Replace_Operations_Use_Only_Canonical_Find_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "Run run Runner PreRun Run_One Run");

      Editor.Project_Search.Set_Query (S.Project_Search, "run");
      Editor.Quick_Open.Open (S.Quick_Open);
      Editor.Quick_Open.Set_Query_Text (S.Quick_Open, "Runner");
      Editor.Go_To_Line.Open (S.Go_To_Line);
      Editor.Go_To_Line.Set_Text (S.Go_To_Line, "42");

      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "Run");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Case_Toggle (S);
      Editor.Executor.Find_Replace_Commands.Execute_Find_Whole_Word_Toggle (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "Execute");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_All (S);

      Assert (Buffer_Text (S) = "Execute run Runner PreRun Run_One Execute",
              "replace.all must use canonical Find query/options rather than any other feature query");
      Assert (Editor.Project_Search.Query (S.Project_Search) = "run",
              "replace.all must not mutate Project Search state");
      Assert (Editor.Quick_Open.Query_Text (S.Quick_Open) = "Runner",
              "replace.all must not mutate Quick Open state");
      Assert (Editor.Go_To_Line.Text (S.Go_To_Line) = "42",
              "replace.all must not mutate Go To Line state");
      Assert (Natural (S.Active_Find_Matches.Length) = 0
              and then S.Active_Find_Case_Sensitive
              and then S.Active_Find_Whole_Word,
              "post-replace Find state must be recomputed with the same canonical options");
   end Test_Replace_Operations_Use_Only_Canonical_Find_State;


   procedure Test_Replace_Lifecycle_And_Persistence_Exclude_State
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S        : Editor.State.State_Type;
      Snapshot : Editor.Workspace_Persistence.Workspace_Snapshot;
      Summary  : Unbounded_String;
   begin
      Init_Executor_Test_State (S);
      Set_Buffer_Text (S, "alpha beta alpha");
      Editor.Executor.Find_Replace_Commands.Execute_Find_Set_Query (S, "alpha");
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Show (S);
      Editor.Executor.Find_Replace_Commands.Execute_Replace_Set_Text (S, "OMEGA");
      S.Active_Replace_Error_Message := To_Unbounded_String ("synthetic replace error");
      Snapshot := Editor.State.Build_Workspace_Snapshot (S);
      Summary := To_Unbounded_String (Editor.Workspace_Persistence.Debug_Summary (Snapshot));
      Assert (Ada.Strings.Fixed.Index (To_String (Summary), "OMEGA") = 0
              and then Ada.Strings.Fixed.Index (To_String (Summary), "synthetic replace error") = 0
              and then Ada.Strings.Fixed.Index (To_String (Summary), "replace") = 0
              and then Ada.Strings.Fixed.Index (To_String (Summary), "alpha") = 0,
              "workspace snapshot must exclude canonical and removed-name-like Replace/Find transient state");

      Editor.State.Reset_Project_Scoped_State (S);
      Assert ((not S.Active_Replace_Prompt)
              and then Length (S.Active_Replace_Text) = 0
              and then Length (S.Active_Replace_Error_Message) = 0,
              "project lifecycle reset must clear the single canonical Replace state owner");
   end Test_Replace_Lifecycle_And_Persistence_Exclude_State;


   overriding procedure Register_Tests (T : in out Search_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Focus_Search_Results_Shows_And_Focuses'Access,
         "focuses Search Results and shows the bottom panel");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Search_Results_Move_Is_Selection_Only'Access,
         "focused Search Results movement is selection-only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Search_Results_Open_Returns_To_Editor_Text'Access,
         "focused Search Results Enter opens result and restores editor focus");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Search_Results_Escape_Returns_To_Editor_Text'Access,
         "focused Search Results Escape restores editor focus");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Find_Navigation_Is_Incremental_Only'Access,
         "find navigation is incremental only");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Active_Find_Previous_Wraps_Deterministically'Access,
         "find previous wraps deterministically");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Find_Query_Persists_Across_Buffer_Switch'Access,
         "find query persists across buffer switch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Find_Highlights_Clear_When_Find_Closes'Access,
         "find highlights clear when find closes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Query_Edit_Recomputes_Current_From_Caret'Access,
         "query edit recomputes current from caret");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Wrap_Status_Is_Deterministic'Access,
         "wrap status is deterministic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Current_Match_Emphasis_Is_Projected'Access,
         "current match emphasis is projected");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Find_Query_Edit_Stays_Out_Of_Feature_Search'Access,
         "find query edit stays out of feature search");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Run_Project_Search_No_Project'Access,
         "project search without project reports no-project");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Run_Search_And_Open_Result'Access,
         "project search run and open result");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_All_Continues_After_First_File_Stales_Preview'Access,
         "replace all continues after first file stales preview");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Replace_Uses_UTF8_Byte_Offsets_Safely'Access,
         "project replace uses UTF-8 byte offsets safely");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Preview_Stales_Dirty_Open_Targets'Access,
         "replace preview stales dirty open targets");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Search_From_Selection'Access,
         "project search from selection");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Search_From_Active_Word'Access,
         "project search from active word");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Active_Word_Dotted_Token_Boundary'Access,
         "active word dotted token boundary");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Search_Active_Directory'Access,
         "project search active directory");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Context_Search_Failure_Is_Atomic'Access,
         "context search failure is atomic");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_First_Last_Project_Search_Result'Access,
         "first and last project search result");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Reveal_Active_Project_Search_Result'Access,
         "reveal active project search result");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Scope_Selected_Project_Search_Directory'Access,
         "scope selected project search directory");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Search_Navigation_No_Result_Messages'Access,
         "project search navigation no-result messages");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Selected_Single_Location_Message'Access,
         "open selected single location message");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Stale_Open_Failure_Preserves_Result_State'Access,
         "stale open failure preserves result state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Out_Of_Range_Project_Search_Result_Does_Not_Clamp'Access,
         "out-of-range project search result does not clamp");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Open_Project_Search_Bar'Access,
         "open project search bar");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Run_Project_Search_From_Bar'Access,
         "run project search from bar");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Close_And_Clear_Project_Search_Bar'Access,
         "close and clear project search bar");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Query_Edit_And_Refresh_Clear_Results'Access,
         "query edit and refresh clear results");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Lifecycle_Find_Hide_And_Render_Coherence'Access,
         "replace lifecycle find hide render coherence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replacement_Text_Literal_Matrix_And_No_Recompute'Access,
         "replacement text literal matrix no recompute");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Current_Selected_Stale_And_No_Selected_Workflows'Access,
         "replace current selected stale no-selected workflows");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Current_Active_Buffer_Switch_Uses_Current_Buffer'Access,
         "replace current active buffer switch");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_All_Options_Span_Empty_And_Same_Text'Access,
         "replace all options span empty same-text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Context_Derived_Query_Render_Dirty_And_Failure_Atomicity'Access,
         "context query render dirty failure atomicity");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Feature_Independence_Navigation_And_Lifecycle_Cleanup'Access,
         "feature independence navigation lifecycle cleanup");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Routes_Availability_Absent_Commands_And_Persistence'Access,
         "routes availability absent commands persistence");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Render_Uses_Canonical_Overlay_State'Access,
         "replace render uses canonical overlay state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Operations_Use_Only_Canonical_Find_State'Access,
         "replace operations use canonical Find state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Lifecycle_And_Persistence_Exclude_State'Access,
         "replace lifecycle and persistence exclude state");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Show_Hide_Clears_Transient_Text'Access,
         "replace show hide clears transient text");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Current_Uses_Find_And_Dirties_No_History'Access,
         "replace current uses Find and no history");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_All_Is_Literal_Offset_Safe_And_Recomputes'Access,
         "replace all literal offset safe recomputes");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_All_Uses_Canonical_Non_Overlapping_Matches'Access,
         "replace all uses canonical non-overlapping matches");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Empty_Text_Deletes_Matches'Access,
         "empty replacement deletes matches");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Text_Newline_Is_Rejected'Access,
         "replace text newline rejected");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Current_Preserves_Valid_Selected_Match'Access,
         "replace current selected match survives recompute");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_Current_Does_Not_Trust_Stale_Deleted_Range'Access,
         "replace current ignores stale deleted range");
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Replace_All_Does_Not_Recursively_Replace_New_Text'Access,
         "replace all non recursive literal text");
   end Register_Tests;

end Editor.Executor.Search_Tests;
