with Ada.Command_Line;
with Ada.Calendar;
with Ada.Directories;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Editor_Tool_Common; use Editor_Tool_Common;
with GNAT.OS_Lib;
with Unit_Test_Build_Lock;

procedure Unit_Tests is
   use type Ada.Calendar.Time;

   Tool : constant String := "unit_tests";
   Tool_Failed : Boolean := False;

   procedure Fail (Tool : String; Message : String) is
   begin
      Tool_Failed := True;
      Editor_Tool_Common.Fail (Tool, Message);
   end Fail;

   Status : Integer;
   Root   : constant String := Ada.Directories.Current_Directory;
   Started_At : constant Ada.Calendar.Time := Ada.Calendar.Clock;

   procedure Print_Usage is
   begin
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "usage: tools/bin/unit_tests "
         & "<all|editor-core|executor-diagnostics|executor-search"
         & "|executor-navigation|executor-buffer-switcher"
         & "|executor-buffer-prune|executor-lifecycle|editor-ui|project-workspace"
         & "|diagnostics-problems"
         & "|build-tools|ada-parser-outline|ada-language-service"
         & "|ada-language|ada-rm-validation|text> "
         & "[--no-build]");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "development slices:");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  editor-core        buffers, files, editing, search, selection, history, navigation");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  executor-diagnostics focused Executor diagnostics and quick-fix routes");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  executor-search    focused Executor search/find/replace routes");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  executor-navigation focused Executor navigation/history routes");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  executor-buffer-switcher focused Executor buffer-switcher routes");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  executor-buffer-prune focused Executor buffer-switcher prune routes");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  executor-lifecycle focused Executor close/save/project lifecycle routes");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  editor-ui          render model, palette, keybindings, panels, gutter, status, input");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  project-workspace  projects, file tree, project search, workspace persistence, lifecycle");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  diagnostics-problems diagnostics, Problems panel, diagnostics review UX");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  build-tools        diagnostics, build UI, terminal tasks, producers, command extensions");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  ada-parser-outline Ada parser, outline, syntax cache, syntax semantics");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  ada-language-service Ada language service integration");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  ada-language       Ada semantic legality and language model");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  ada-rm-validation  Ada RM audit, burn-down, remediation, and release validation");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  text               text buffer primitives");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "release only:");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "  all                full All_Suites aggregate");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "helper: tools/bin/test_slice_for <changed-path>");
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "fast rerun: append --no-build after a slice that is already built");
   end Print_Usage;

   function Main_Source (Slice : String) return String is
   begin
      if Slice = "all" then
         return "tests.adb";
      elsif Slice = "editor-core" then
         return "editor_core_tests.adb";
      elsif Slice = "executor-diagnostics" then
         return "executor_diagnostics_tests.adb";
      elsif Slice = "executor-search" then
         return "executor_search_tests.adb";
      elsif Slice = "executor-navigation" then
         return "executor_navigation_tests.adb";
      elsif Slice = "executor-buffer-switcher" then
         return "executor_buffer_switcher_tests.adb";
      elsif Slice = "executor-buffer-prune" then
         return "executor_buffer_prune_tests.adb";
      elsif Slice = "executor-lifecycle" then
         return "executor_lifecycle_tests.adb";
      elsif Slice = "editor-ui" then
         return "editor_ui_tests.adb";
      elsif Slice = "project-workspace" then
         return "project_workspace_tests.adb";
      elsif Slice = "diagnostics-problems" then
         return "diagnostics_problems_tests.adb";
      elsif Slice = "build-tools" then
         return "build_tools_tests.adb";
      elsif Slice = "ada-parser-outline" then
         return "ada_parser_outline_tests.adb";
      elsif Slice = "ada-language-service" then
         return "ada_language_service_tests.adb";
      elsif Slice = "ada-language" then
         return "ada_language_tests.adb";
      elsif Slice = "ada-rm-validation" then
         return "ada_rm_validation_tests.adb";
      elsif Slice = "text" then
         return "text_tests.adb";
      else
         return "";
      end if;
   end Main_Source;

   function Executable (Slice : String) return String is
   begin
      if Slice = "all" then
         return "tests";
      elsif Slice = "editor-core" then
         return "editor_core_tests";
      elsif Slice = "executor-diagnostics" then
         return "executor_diagnostics_tests";
      elsif Slice = "executor-search" then
         return "executor_search_tests";
      elsif Slice = "executor-navigation" then
         return "executor_navigation_tests";
      elsif Slice = "executor-buffer-switcher" then
         return "executor_buffer_switcher_tests";
      elsif Slice = "executor-buffer-prune" then
         return "executor_buffer_prune_tests";
      elsif Slice = "executor-lifecycle" then
         return "executor_lifecycle_tests";
      elsif Slice = "editor-ui" then
         return "editor_ui_tests";
      elsif Slice = "project-workspace" then
         return "project_workspace_tests";
      elsif Slice = "diagnostics-problems" then
         return "diagnostics_problems_tests";
      elsif Slice = "build-tools" then
         return "build_tools_tests";
      elsif Slice = "ada-parser-outline" then
         return "ada_parser_outline_tests";
      elsif Slice = "ada-language-service" then
         return "ada_language_service_tests";
      elsif Slice = "ada-language" then
         return "ada_language_tests";
      elsif Slice = "ada-rm-validation" then
         return "ada_rm_validation_tests";
      elsif Slice = "text" then
         return "text_tests";
      else
         return "";
      end if;
   end Executable;

   Slice       : constant String :=
     (if Ada.Command_Line.Argument_Count in 1 .. 2 then Ada.Command_Line.Argument (1) else "");
   Skip_Build  : constant Boolean :=
     Ada.Command_Line.Argument_Count = 2
     and then Ada.Command_Line.Argument (2) = "--no-build";
   Main        : constant String := Main_Source (Slice);
   Program     : constant String := Executable (Slice);
   Output_Path : constant String := "/tmp/editor_unit_tests_" & Program & ".out";
   Timing_Path : constant String := "/tmp/editor_unit_test_timings.tsv";
begin
   if Main = "" or else Program = ""
     or else (Ada.Command_Line.Argument_Count = 2 and then not Skip_Build)
   then
      Print_Usage;
      Fail (Tool, "missing or unknown test slice");
   end if;

   if Slice = "all" and then Env ("EDITOR_RELEASE_VALIDATION") /= "1" then
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         "unit_tests: warning: all is release-only; "
         & "set EDITOR_RELEASE_VALIDATION=1 for release validation");
   end if;

   Require_File (Tool, "tests/tests.gpr");
   if not Command_Exists ("alr") and then not Command_Exists ("gprbuild") then
      if Strict ("EDITOR_REQUIRE_UNIT_TESTS") then
         Fail (Tool, "neither alr nor gprbuild found");
      else
         Info (Tool, "neither alr nor gprbuild found; unit tests skipped");
         return;
      end if;
   end if;

   if Skip_Build then
      Require_File (Tool, "tests/bin/" & Program);
   else
      if not Unit_Test_Build_Lock.Acquire (300) then
         Fail (Tool, "timed out waiting for unit test build lock");
      end if;
      Ada.Directories.Set_Directory ("tests");
      if Command_Exists ("alr") then
         if Ada.Environment_Variables.Exists ("HOME") then
            declare
               Home : constant String := Ada.Environment_Variables.Value ("HOME");
            begin
               if not Ada.Environment_Variables.Exists ("XDG_CONFIG_HOME") then
                  Ada.Environment_Variables.Set
                    ("XDG_CONFIG_HOME", Home & "/.config");
               end if;
               if not Ada.Environment_Variables.Exists ("XDG_DATA_HOME") then
                  Ada.Environment_Variables.Set
                    ("XDG_DATA_HOME", Home & "/.local/share");
               end if;
               if not Ada.Environment_Variables.Exists ("XDG_CACHE_HOME") then
                  Ada.Environment_Variables.Set
                    ("XDG_CACHE_HOME", Home & "/.cache");
               end if;
            end;
         end if;
         declare
            Args : GNAT.OS_Lib.Argument_List (1 .. 6) :=
              (new String'("exec"),
               new String'("--"),
               new String'("gprbuild"),
               new String'("-P"),
               new String'("tests.gpr"),
               new String'(Main));
         begin
            Status := Run ("alr", Args);
         end;
      else
         declare
            Args : GNAT.OS_Lib.Argument_List (1 .. 3) :=
              (new String'("-P"),
               new String'("tests.gpr"),
               new String'(Main));
         begin
            Status := Run ("gprbuild", Args);
         end;
      end if;

      Ada.Directories.Set_Directory (Root);
      Unit_Test_Build_Lock.Release;

      if Status /= 0 then
         Fail (Tool, "unit test build failed");
      end if;
   end if;

   declare
      No_Args : GNAT.OS_Lib.Argument_List (1 .. 0);
      Result  : constant Captured_Command_Output :=
        Run_Capture_Bounded
          ("tests/bin/" & Program, No_Args, Output_Path,
           Max_Bytes => 2_000_000);
   begin
      if not AUnit_Output_Passed (Result) then
         Fail
           (Tool,
            "unit tests failed; see " & Output_Path);
      end if;
      if Output_Contains (Result, "Total Tests Run:   0") then
         Fail
           (Tool,
            "unit test slice registered zero tests; see " & Output_Path);
      end if;
   end;

   declare
      Elapsed : constant Duration := Ada.Calendar.Clock - Started_At;
      Timing_File : Ada.Text_IO.File_Type;
   begin
      if Ada.Directories.Exists (Timing_Path) then
         Ada.Text_IO.Open (Timing_File, Ada.Text_IO.Append_File, Timing_Path);
      else
         Ada.Text_IO.Create (Timing_File, Ada.Text_IO.Out_File, Timing_Path);
      end if;
      Ada.Text_IO.Put_Line
        (Timing_File,
         Slice & ASCII.HT & Program & ASCII.HT & Duration'Image (Elapsed));
      Ada.Text_IO.Close (Timing_File);
      Info
        (Tool,
         Slice & " unit tests passed in "
         & Duration'Image (Elapsed) & "s");
   end;
exception
   when Program_Error =>
      if Ada.Directories.Current_Directory /= Root then
         Ada.Directories.Set_Directory (Root);
      end if;
      Unit_Test_Build_Lock.Release;
      if Tool_Failed then
         null;
      else
         Unexpected_Program_Error (Tool);
      end if;
   when others =>
      if Ada.Directories.Current_Directory /= Root then
         Ada.Directories.Set_Directory (Root);
      end if;
      Unit_Test_Build_Lock.Release;
      Fail (Tool, "unexpected failure");
end Unit_Tests;
