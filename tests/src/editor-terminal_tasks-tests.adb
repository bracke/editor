with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers;
with Ada.Directories;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Executor.Project_Lifecycle_Commands;
with Editor.External_Producers;
with Editor.Input_Bridge;
with Editor.Keybindings;
with Editor.Project;
with Editor.Render_Model;
with Editor.State;
with Editor.Terminal_Tasks;

use type Editor.Command_Execution.Command_Execution_Status;
use type Editor.Commands.Command_Id;
use type Editor.External_Producers.Process_Run_Status;
use type Editor.Terminal_Tasks.Terminal_Task_Status;
use type Ada.Containers.Count_Type;

package body Editor.Terminal_Tasks.Tests is

   function Key
     (Code : Editor.Keybindings.Key_Code) return Editor.Keybindings.Key_Chord
   is
   begin
      return
        (Key       => Code,
         Modifiers => (Ctrl => False, Shift => False,
                       Alt => False, Meta => False));
   end Key;

   overriding function Name
     (T : Terminal_Tasks_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Terminal_Tasks");
   end Name;

   procedure Test_Task_Registration_Selection_And_Request
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Terminal_Tasks.Terminal_Task_State;
      First : Natural;
      Second : Natural;
      Request : Editor.External_Producers.Process_Run_Request;
      Snapshot : Editor.Terminal_Tasks.Terminal_Task_Render_Snapshot;
   begin
      Editor.Terminal_Tasks.Focus (S);
      First := Editor.Terminal_Tasks.Register_Task
        (S, "Build", "/usr/bin/alr", "/project",
         Editor.Terminal_Tasks.Task_Profile_Build);
      Editor.Terminal_Tasks.Append_Argument (S, First, "build");
      Second := Editor.Terminal_Tasks.Register_Task
        (S, "Tests", "/usr/bin/alr", "/project",
         Editor.Terminal_Tasks.Task_Profile_Test);
      Editor.Terminal_Tasks.Append_Argument (S, Second, "test");

      Snapshot := Editor.Terminal_Tasks.Build_Render_Snapshot (S);
      Assert (Snapshot.Visible and then Snapshot.Focused,
              "terminal can be visible and focused");
      Assert (Snapshot.Row_Count = 2, "registered tasks are rendered");
      Assert (Snapshot.Has_Selected, "a task is selected");

      Editor.Terminal_Tasks.Select_Next (S);
      Request := Editor.Terminal_Tasks.Selected_Task_Request (S);
      Assert (To_String (Request.Program_Label) = "/usr/bin/alr",
              "selected task request keeps structured program");
      Assert (To_String (Request.Working_Label) = "/project",
              "selected task request keeps working directory");
      Assert (Editor.External_Producers.Process_Argument_Count
                (Request.Structured_Arguments) = 1,
              "selected task request keeps structured arguments");
   end Test_Task_Registration_Selection_And_Request;

   procedure Test_Run_Result_Output_And_Rerun
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.Terminal_Tasks.Terminal_Task_State;
      Id : Natural;
      Snapshot : Editor.Terminal_Tasks.Terminal_Task_Render_Snapshot;
   begin
      Id := Editor.Terminal_Tasks.Register_Task
        (S, "Echo", "/bin/echo", "",
         Editor.Terminal_Tasks.Task_Profile_Custom);
      Editor.Terminal_Tasks.Append_Argument (S, Id, "hello");
      Editor.Terminal_Tasks.Run_Selected_With_Result
        (S, Editor.External_Producers.Build_Process_Run_Result
          (Editor.External_Producers.Process_Run_Succeeded,
           Exit_Code => 0,
           Has_Exit_Code => True,
           Stdout_Text => "hello" & ASCII.LF));

      Snapshot := Editor.Terminal_Tasks.Build_Render_Snapshot (S);
      Assert (Snapshot.Can_Rerun_Last, "successful task can be rerun");
      Assert (Snapshot.Output_Row_Count >= 2,
              "command line and stdout are captured");
      Assert (Snapshot.Rows (Snapshot.Selected_Index).Status =
                Editor.Terminal_Tasks.Task_Succeeded,
              "row records process status");

      Editor.Terminal_Tasks.Rerun_Last_With_Result
        (S, Editor.External_Producers.Build_Process_Run_Result
          (Editor.External_Producers.Process_Run_Failed,
           Exit_Code => 2,
           Has_Exit_Code => True,
           Stderr_Text => "failed" & ASCII.LF));

      Snapshot := Editor.Terminal_Tasks.Build_Render_Snapshot (S);
      Assert (Snapshot.Rows (Snapshot.Selected_Index).Status =
                Editor.Terminal_Tasks.Task_Failed,
              "rerun updates row status");
      Assert (Snapshot.Output_Row_Count >= 4,
              "rerun appends bounded output rows");
   end Test_Run_Result_Output_And_Rerun;

   procedure Test_Clear_Output_And_Render_Model_Projection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Id : Natural;
      Snapshot : Editor.Render_Model.Render_Snapshot;
   begin
      Editor.Terminal_Tasks.Show (S.Terminal_Tasks);
      Id := Editor.Terminal_Tasks.Register_Task
        (S.Terminal_Tasks, "Version", "/bin/echo");
      Editor.Terminal_Tasks.Append_Argument (S.Terminal_Tasks, Id, "--version");
      Editor.Terminal_Tasks.Run_Selected_With_Result
        (S.Terminal_Tasks,
         Editor.External_Producers.Build_Process_Run_Result
           (Editor.External_Producers.Process_Run_Succeeded,
            Stdout_Text => "1.0" & ASCII.LF));

      Editor.Render_Model.Build_Render_Snapshot (S, Snapshot);
      Assert (Snapshot.Terminal_Tasks.Visible,
              "render model projects terminal visibility");
      Assert (Snapshot.Terminal_Tasks.Row_Count = 1,
              "render model projects task rows");
      Assert (Snapshot.Terminal_Tasks.Output_Row_Count > 0,
              "render model projects terminal output");

      Editor.Terminal_Tasks.Clear_Output (S.Terminal_Tasks);
      Editor.Render_Model.Build_Render_Snapshot (S, Snapshot);
      Assert (Snapshot.Terminal_Tasks.Row_Count = 1,
              "clearing output preserves tasks");
      Assert (Snapshot.Terminal_Tasks.Output_Row_Count = 0,
              "clearing output removes output rows");
   end Test_Clear_Output_And_Render_Model_Projection;

   procedure Test_Focused_Terminal_Keyboard_Routes_Through_Input_Bridge
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      After : Editor.State.State_Type;
      First : Natural;
      Second : Natural;
      Snapshot : Editor.Terminal_Tasks.Terminal_Task_Render_Snapshot;
   begin
      Editor.Terminal_Tasks.Focus (S.Terminal_Tasks);
      First := Editor.Terminal_Tasks.Register_Task
        (S.Terminal_Tasks, "Echo One", "/bin/echo");
      Editor.Terminal_Tasks.Append_Argument
        (S.Terminal_Tasks, First, "one");
      Second := Editor.Terminal_Tasks.Register_Task
        (S.Terminal_Tasks, "Echo Two", "/bin/echo");
      Editor.Terminal_Tasks.Append_Argument
        (S.Terminal_Tasks, Second, "two");
      Editor.Input_Bridge.Set_State_For_Test (S);

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Down));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Snapshot := Editor.Terminal_Tasks.Build_Render_Snapshot
        (After.Terminal_Tasks);
      Assert (Snapshot.Selected_Index = 2,
              "Down selects the next terminal task through Input_Bridge");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Up));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Snapshot := Editor.Terminal_Tasks.Build_Render_Snapshot
        (After.Terminal_Tasks);
      Assert (Snapshot.Selected_Index = 1,
              "Up selects the previous terminal task through Input_Bridge");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Enter));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Snapshot := Editor.Terminal_Tasks.Build_Render_Snapshot
        (After.Terminal_Tasks);
      Assert (Snapshot.Output_Row_Count > 0,
              "Enter runs the selected terminal task through Input_Bridge");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Delete));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Snapshot := Editor.Terminal_Tasks.Build_Render_Snapshot
        (After.Terminal_Tasks);
      Assert (Snapshot.Output_Row_Count = 0,
              "Delete clears focused terminal output through Input_Bridge");

      Editor.Input_Bridge.Handle_Key_Chord
        (Key (Editor.Keybindings.Key_Escape));
      After := Editor.Input_Bridge.Get_State_For_Test;
      Snapshot := Editor.Terminal_Tasks.Build_Render_Snapshot
        (After.Terminal_Tasks);
      Assert (not Snapshot.Focused,
              "Escape returns focused terminal keyboard workflow to editor text");
   end Test_Focused_Terminal_Keyboard_Routes_Through_Input_Bridge;

   procedure Test_Terminal_Commands_Have_Stable_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Found : Boolean := False;
   begin
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Terminal_Toggle) =
              "terminal.toggle",
              "terminal toggle has a stable name");
      Assert (Editor.Commands.Command_Id_From_Stable_Name
                ("terminal.run-selected-task", Found) =
              Editor.Commands.Command_Terminal_Run_Selected_Task,
              "terminal run-selected command can be resolved");
      Assert (Found, "terminal run-selected stable name was found");
      Assert (Editor.Commands.Command_Id_From_Stable_Name
                ("terminal.rerun-last-task", Found) =
              Editor.Commands.Command_Terminal_Rerun_Last_Task,
              "terminal rerun-last command can be resolved");
      Assert (Found, "terminal rerun-last stable name was found");
      Assert (Editor.Commands.Stable_Command_Name
                (Editor.Commands.Command_Run_Project) =
              "project.run",
              "project run has a stable name");
      Assert (Editor.Commands.Command_Id_From_Stable_Name
                ("project.test", Found) =
              Editor.Commands.Command_Run_Tests,
              "project test command can be resolved");
      Assert (Found, "project test stable name was found");
   end Test_Terminal_Commands_Have_Stable_Names;

   procedure Test_Project_Open_Seeds_Default_Terminal_Tasks
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := "/tmp/editor-terminal-tasks-project";
      S : Editor.State.State_Type;
      Snapshot : Editor.Terminal_Tasks.Terminal_Task_Render_Snapshot;
      Build_Seen : Boolean := False;
      Run_Seen : Boolean := False;
      Development_Seen : Boolean := False;
      Release_Seen : Boolean := False;
      Validation_Seen : Boolean := False;
      Test_Seen : Boolean := False;
   begin
      Ada.Directories.Create_Path (Root);
      Editor.Executor.Project_Lifecycle_Commands.Execute_Open_Project
        (S, Root,
         Refresh_Build_Candidates => False,
         Apply_Workspace_Policy => False);

      Assert (Editor.Project.Has_Project (S.Project),
              "project open test should have an active project");
      Snapshot := Editor.Terminal_Tasks.Build_Render_Snapshot
        (S.Terminal_Tasks);
      Assert (Snapshot.Row_Count = 6,
              "project open seeds build, run, profile, and test terminal tasks");
      Assert (Snapshot.Has_Selected,
              "seeded project task is selected");

      for I in Snapshot.Rows.First_Index .. Snapshot.Rows.Last_Index loop
         if To_String (Snapshot.Rows (I).Label) = "Alire Build" then
            Build_Seen := True;
            Assert (To_String (Snapshot.Rows (I).Profile_Label) = "build",
                    "default build task exposes build profile");
            Assert (To_String (Snapshot.Rows (I).Working_Label) = Root,
                    "build task uses project root");
         elsif To_String (Snapshot.Rows (I).Label) = "Alire Run" then
            Run_Seen := True;
            Assert (To_String (Snapshot.Rows (I).Profile_Label) = "run",
                    "run task exposes run profile");
            Assert (Snapshot.Rows (I).Arguments.Length = 1
                    and then To_String
                      (Snapshot.Rows (I).Arguments.Last_Element) = "run",
                    "run task uses structured run argument");
         elsif To_String (Snapshot.Rows (I).Label) =
           "Alire Build Development"
         then
            Development_Seen := True;
            Assert (To_String (Snapshot.Rows (I).Profile_Label) =
                      "development",
                    "development task exposes profile");
            Assert (Snapshot.Rows (I).Arguments.Length = 2
                    and then To_String
                      (Snapshot.Rows (I).Arguments.Last_Element) =
                        "--development",
                    "development task uses structured profile argument");
         elsif To_String (Snapshot.Rows (I).Label) = "Alire Build Release" then
            Release_Seen := True;
            Assert (To_String (Snapshot.Rows (I).Profile_Label) = "release",
                    "release task exposes profile");
            Assert (Snapshot.Rows (I).Arguments.Length = 2
                    and then To_String
                      (Snapshot.Rows (I).Arguments.Last_Element) =
                        "--release",
                    "release task uses structured profile argument");
         elsif To_String (Snapshot.Rows (I).Label) =
           "Alire Build Validation"
         then
            Validation_Seen := True;
            Assert (To_String (Snapshot.Rows (I).Profile_Label) =
                      "validation",
                    "validation task exposes profile");
            Assert (Snapshot.Rows (I).Arguments.Length = 2
                    and then To_String
                      (Snapshot.Rows (I).Arguments.Last_Element) =
                        "--validation",
                    "validation task uses structured profile argument");
         elsif To_String (Snapshot.Rows (I).Label) = "Alire Test" then
            Test_Seen := True;
            Assert (To_String (Snapshot.Rows (I).Working_Label) = Root,
                    "test task uses project root");
         end if;
      end loop;

      Assert
         (Build_Seen
         and then Run_Seen
         and then Development_Seen
         and then Release_Seen
         and then Validation_Seen
         and then Test_Seen,
         "default project terminal tasks are visible");
   end Test_Project_Open_Seeds_Default_Terminal_Tasks;

   procedure Test_Terminal_Command_Path_Prepares_Project_Tasks
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := "/tmp/editor-terminal-tasks-command-project";
      S : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result;
      Snapshot : Editor.Terminal_Tasks.Terminal_Task_Render_Snapshot;
   begin
      Ada.Directories.Create_Path (Root);
      Editor.Project.Apply_Open_Result
        (S.Project, Editor.Project.Open_Project (Root));

      Result := Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Terminal_Show);
      Assert (Result.Status = Editor.Command_Execution.Command_Executed,
              "terminal show command executes");

      Snapshot := Editor.Terminal_Tasks.Build_Render_Snapshot
        (S.Terminal_Tasks);
      Assert (Snapshot.Visible, "terminal command shows the panel");
      Assert (Snapshot.Row_Count = 6,
              "terminal command path prepares project tasks");
      Assert (Snapshot.Can_Run_Selected,
              "terminal command path leaves a selected runnable task");
   end Test_Terminal_Command_Path_Prepares_Project_Tasks;

   procedure Test_Project_Run_And_Test_Profile_Selection
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Root : constant String := "/tmp/editor-terminal-tasks-profile-project";
      S : Editor.Terminal_Tasks.Terminal_Task_State;
      Request : Editor.External_Producers.Process_Run_Request;
   begin
      Editor.Terminal_Tasks.Ensure_Project_Default_Tasks (S, Root);

      Assert
        (Editor.Terminal_Tasks.Select_First_Profile
           (S, Editor.Terminal_Tasks.Task_Profile_Run),
         "project run command can select the seeded run task");
      Request := Editor.Terminal_Tasks.Selected_Task_Request (S);
      Assert (To_String (Request.Program_Label) = "alr",
              "run profile uses the structured Alire program");
      Assert (Editor.External_Producers.Process_Argument_Count
                (Request.Structured_Arguments) = 1,
              "run profile has one structured argument");

      Assert
        (Editor.Terminal_Tasks.Select_First_Profile
           (S, Editor.Terminal_Tasks.Task_Profile_Test),
         "project test command can select the seeded test task");
      Request := Editor.Terminal_Tasks.Selected_Task_Request (S);
      Assert (To_String (Request.Program_Label) = "alr",
              "test profile uses the structured Alire program");
      Assert (Editor.External_Producers.Process_Argument_Count
                (Request.Structured_Arguments) = 1,
              "test profile has one structured argument");
   end Test_Project_Run_And_Test_Profile_Selection;

   overriding procedure Register_Tests
     (T : in out Terminal_Tasks_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Task_Registration_Selection_And_Request'Access,
         "terminal tasks register, select, and expose structured request");
      Register_Routine
        (T, Test_Run_Result_Output_And_Rerun'Access,
         "terminal tasks record output and rerun last task");
      Register_Routine
        (T, Test_Clear_Output_And_Render_Model_Projection'Access,
         "terminal task render projection and clear output");
      Register_Routine
        (T, Test_Focused_Terminal_Keyboard_Routes_Through_Input_Bridge'Access,
         "focused terminal keyboard routes through Input_Bridge");
      Register_Routine
        (T, Test_Terminal_Commands_Have_Stable_Names'Access,
         "terminal task commands have stable names");
      Register_Routine
        (T, Test_Project_Open_Seeds_Default_Terminal_Tasks'Access,
         "project open seeds default terminal tasks");
      Register_Routine
        (T, Test_Terminal_Command_Path_Prepares_Project_Tasks'Access,
         "terminal command path prepares project tasks");
      Register_Routine
        (T, Test_Project_Run_And_Test_Profile_Selection'Access,
         "project run and test commands select seeded task profiles");
   end Register_Tests;

end Editor.Terminal_Tasks.Tests;
