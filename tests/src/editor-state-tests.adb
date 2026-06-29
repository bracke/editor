with AUnit.Assertions; use AUnit.Assertions;
with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Executor;
with Editor.Project;
with Editor.Project_Search;
with Editor.Recent_Projects;
with Editor.Pending_Transitions;
with Editor.Dirty_Guards;
with Editor.Test_Helper;
with Editor.Ada_Language_Service;
with Editor.External_Producers;
with Text_Buffer;

package body Editor.State.Tests is

   procedure Test_Caret_Validity
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);

      Editor.Executor.Execute_No_Log
        (S, Editor.Test_Helper.Insert (0, 'a'));

      Assert (S.Carets (0).Pos <= Text_Buffer.Length (S.Buffer) + 1,
              "Caret position must remain valid after execution");

      Assert (S.Carets (0).Anchor <= Text_Buffer.Length (S.Buffer) + 1,
              "Caret anchor must remain valid after execution");
   end Test_Caret_Validity;

   procedure Test_Phase17_Line_Helper_Queries
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "ab" & ASCII.LF & "cde" & ASCII.LF & "f");

      Assert
        (Editor.State.Row_For_Index (S, 0) = 0
         and then Editor.State.Row_For_Index (S, 2) = 0
         and then Editor.State.Row_For_Index (S, 3) = 1
         and then Editor.State.Row_For_Index (S, 7) = 2,
         "Row_For_Index must map boundary positions through the line index");

      Assert
        (Editor.State.Line_Start (S, 0) = 0
         and then Editor.State.Line_Start (S, 1) = 3
         and then Editor.State.Line_Start (S, 2) = 7,
         "Line_Start must return exact indexed row starts");

      Assert
        (Editor.State.Line_End (S, 0) = 2
         and then Editor.State.Line_End (S, 1) = 6
         and then Editor.State.Line_End (S, 2) = 8,
         "Line_End must return LF-exclusive row ends");
   end Test_Phase17_Line_Helper_Queries;


   procedure Test_Project_Scoped_Summary_And_Reset
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);

      S : Editor.State.State_Type;
      Before : Editor.State.Project_Scoped_State_Summary;
      After  : Editor.State.Project_Scoped_State_Summary;
      Config_Dir : constant String := Ada.Directories.Compose
        ("/tmp/editor-tests", "phase99_recent_config");
      Open_Result : constant Editor.Project.Project_Open_Result :=
        (Status       => Editor.Project.Project_Open_Ok,
         Root_Path    => To_Unbounded_String ("/tmp/editor-phase99-a"),
         Display_Name => To_Unbounded_String ("editor-phase99-a"),
         Error_Text   => Null_Unbounded_String);
      Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Project,
         Path       => To_Unbounded_String ("/tmp/editor-phase99-b"),
         Display    => To_Unbounded_String ("editor-phase99-b"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => True,
         others     => <>);
      Summary : constant Editor.Dirty_Guards.Dirty_Buffer_Summary :=
        (Dirty_Count => 1, Untitled_Count => 0, File_Backed_Count => 1);
      Lines : Editor.External_Producers.Diagnostic_Text_Line_Array;
   begin
      if Ada.Directories.Exists (Config_Dir) then
         Ada.Directories.Delete_Tree (Config_Dir);
      end if;
      Ada.Directories.Create_Path (Config_Dir);
      Editor.Recent_Projects.Set_Config_Directory_For_Tests (Config_Dir);
      Editor.State.Init (S);
      Editor.Project.Apply_Open_Result (S.Project, Open_Result);
      Editor.Project_Search.Set_Query (S.Project_Search, "needle");
      Editor.Pending_Transitions.Set_Pending
        (S.Pending_Transitions, Target, Summary);
      Editor.Recent_Projects.Add_Or_Promote
        (S.Recent_Projects, "/tmp/editor-phase99-a", "editor-phase99-a", 10);
      Lines.Append
        (To_Unbounded_String
           ("src/stale_project.adb:3:2: error: stale project diagnostic"));
      Editor.Ada_Language_Service.Put_Compiler_Diagnostic_Lines
        (S.Language_Service, Lines, Tool_Name => "gprbuild");

      Before := Editor.State.Project_Scoped_State_Summary_For (S);
      Assert (Before.Has_Project_Root,
              "summary must report active project root");
      Assert (Before.Has_Project_Search_Query,
              "summary must report project-search query state");
      Assert (Before.Has_Pending_Project_Target,
              "summary must report project-targeted pending transition");

      Editor.State.Reset_Project_Scoped_State (S);
      After := Editor.State.Project_Scoped_State_Summary_For (S);

      Assert (not After.Has_Project_Root,
              "project-scoped reset must clear project root");
      Assert (After.File_Tree_Node_Count = 0,
              "project-scoped reset must clear file tree nodes");
      Assert (After.File_Tree_Expansion_Count = 0,
              "project-scoped reset must clear file tree expansions");
      Assert (After.Project_Search_Result_Count = 0,
              "project-scoped reset must clear project-search results");
      Assert (not After.Has_Project_Search_Query,
              "project-scoped reset must clear project-search query");
      Assert (not After.Has_Pending_Project_Target,
              "project-scoped reset must clear project-targeted pending transition");
      Assert (not Editor.Ada_Language_Service.Compiler_Status
                (S.Language_Service).Has_Run
              and then Editor.Ada_Language_Service.Compiler_Diagnostic_Count
                (S.Language_Service) = 0,
              "project-scoped reset must clear retained compiler-backed language diagnostics");
      Assert (Editor.Recent_Projects.Count (S.Recent_Projects) = 1,
              "project-scoped reset must preserve global recent projects");

      Editor.Recent_Projects.Clear_Config_Directory_Override;
      if Ada.Directories.Exists (Config_Dir) then
         Ada.Directories.Delete_Tree (Config_Dir);
      end if;
   exception
      when others =>
         Editor.Recent_Projects.Clear_Config_Directory_Override;
         if Ada.Directories.Exists (Config_Dir) then
            Ada.Directories.Delete_Tree (Config_Dir);
         end if;
         raise;
   end Test_Project_Scoped_Summary_And_Reset;

   overriding function Name
     (T : State_Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.State");
   end Name;

   overriding procedure Register_Tests
     (T : in out State_Test_Case) is
   begin
      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Caret_Validity'Access, "Caret Validity");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Phase17_Line_Helper_Queries'Access,
         "Phase 17 Line Helper Queries");

      AUnit.Test_Cases.Registration.Register_Routine
        (T, Test_Project_Scoped_Summary_And_Reset'Access,
         "Project-scoped summary and reset");
   end Register_Tests;

end Editor.State.Tests;
