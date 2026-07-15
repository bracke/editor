with Editor.Test_Temp;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Pending_Transitions;
with Editor.Dirty_Guards;

package body Editor.Pending_Transitions.Tests is

   function Name
     (T : Pending_Transitions_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Pending_Transitions.Tests");
   end Name;

   function Summary return Editor.Dirty_Guards.Dirty_Buffer_Summary is
   begin
      return (Dirty_Count => 2, Untitled_Count => 1, File_Backed_Count => 1);
   end Summary;

   procedure Test_New_State_Has_No_Pending
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Pending_Transitions.Pending_Transition_State;
   begin
      Assert (not Editor.Pending_Transitions.Has_Pending (State),
              "new pending-transition state must be empty");
      Assert (Editor.Pending_Transitions.Display_Text (State) = "",
              "empty pending-transition state must have empty display text");
   end Test_New_State_Has_No_Pending;

   procedure Test_Set_Pending_Stores_Target_And_Summary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Pending_Transitions.Pending_Transition_State;
      Target : Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Project,
         Path       => To_Unbounded_String (Editor.Test_Temp.Base & "/project"),
         Display    => To_Unbounded_String ("project"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => True,
         others     => <>);
      Stored : Editor.Pending_Transitions.Pending_Transition_Target;
      Stored_Summary : Editor.Dirty_Guards.Dirty_Buffer_Summary;
   begin
      Editor.Pending_Transitions.Set_Pending (State, Target, Summary);
      Stored := Editor.Pending_Transitions.Target (State);
      Stored_Summary := Editor.Pending_Transitions.Dirty_Summary (State);

      Assert (Editor.Pending_Transitions.Has_Pending (State),
              "set pending must make state pending");
      Assert (Stored.Kind = Editor.Pending_Transitions.Pending_Open_Project,
              "pending target kind must be stored");
      Assert (Stored.Has_Path and then To_String (Stored.Path) = Editor.Test_Temp.Base & "/project",
              "pending target path metadata must be stored");
      Assert (Stored_Summary.Dirty_Count = 2
              and then Stored_Summary.Untitled_Count = 1
              and then Stored_Summary.File_Backed_Count = 1,
              "pending dirty summary must be stored");
   end Test_Set_Pending_Stores_Target_And_Summary;

   procedure Test_Clear_Removes_Pending
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Pending_Transitions.Pending_Transition_State;
      Target : Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Close_Buffer,
         Path       => Null_Unbounded_String,
         Display    => To_Unbounded_String ("main.adb"),
         Buffer_Id  => 3,
         Has_Buffer => True,
         Has_Path   => False,
         others     => <>);
   begin
      Editor.Pending_Transitions.Set_Pending (State, Target, Summary);
      Editor.Pending_Transitions.Clear (State);
      Assert (not Editor.Pending_Transitions.Has_Pending (State),
              "clear must remove pending transition");
   end Test_Clear_Removes_Pending;

   procedure Test_New_Pending_Replaces_Previous
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Pending_Transitions.Pending_Transition_State;
      First_Target : Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Close_Buffer,
         Path       => Null_Unbounded_String,
         Display    => To_Unbounded_String ("first"),
         Buffer_Id  => 1,
         Has_Buffer => True,
         Has_Path   => False,
         others     => <>);
      Second_Target : Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Restore_Workspace,
         Path       => To_Unbounded_String (Editor.Test_Temp.Base & "/project"),
         Display    => To_Unbounded_String ("workspace"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => True,
         others     => <>);
   begin
      Editor.Pending_Transitions.Set_Pending (State, First_Target, Summary);
      Editor.Pending_Transitions.Set_Pending (State, Second_Target, Summary);
      Assert (Editor.Pending_Transitions.Target (State).Kind =
                Editor.Pending_Transitions.Pending_Restore_Workspace,
              "new pending transition must replace previous target");
   end Test_New_Pending_Replaces_Previous;


   procedure Test_Display_Text_Is_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Pending_Transitions.Pending_Transition_State;
      Target : Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Recent_Project,
         Path       => To_Unbounded_String (Editor.Test_Temp.Base & "/recent"),
         Display    => To_Unbounded_String ("recent"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => True,
         others     => <>);
      First  : Unbounded_String;
      Second : Unbounded_String;
   begin
      Editor.Pending_Transitions.Set_Pending (State, Target, Summary);
      First := To_Unbounded_String (Editor.Pending_Transitions.Display_Text (State));
      Second := To_Unbounded_String (Editor.Pending_Transitions.Display_Text (State));

      Assert (Length (First) > 0,
              "pending display text must not be empty");
      Assert (To_String (First) = To_String (Second),
              "pending display text must be deterministic");
      Assert (Ada.Strings.Unbounded.Index (First, "Discard") /= 0,
              "pending transition display should name explicit discard action");
      Assert (Ada.Strings.Unbounded.Index (First, "Close Clean") /= 0,
              "pending transition display should name the retained clean-close path");
   end Test_Display_Text_Is_Deterministic;

   procedure Test_Target_Stores_Buffer_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Pending_Transitions.Pending_Transition_State;
      Target : Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Close_Buffer,
         Path       => Null_Unbounded_String,
         Display    => To_Unbounded_String ("buffer.adb"),
         Buffer_Id  => 42,
         Has_Buffer => True,
         Has_Path   => False,
         others     => <>);
      Stored : Editor.Pending_Transitions.Pending_Transition_Target;
   begin
      Editor.Pending_Transitions.Set_Pending (State, Target, Summary);
      Stored := Editor.Pending_Transitions.Target (State);

      Assert (Stored.Has_Buffer,
              "buffer pending target must retain Has_Buffer metadata");
      Assert (Stored.Buffer_Id = 42,
              "buffer pending target must retain buffer id metadata");
      Assert (not Stored.Has_Path,
              "buffer pending target must not invent path metadata");
   end Test_Target_Stores_Buffer_Metadata;
   procedure Test_Target_Accessors_Are_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Pending_Transitions.Pending_Transition_State;
      Target : Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Project,
         Path       => To_Unbounded_String (Editor.Test_Temp.Base & "/project-b"),
         Display    => To_Unbounded_String ("project-b"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => True,
         others     => <>);
      Found : Boolean := True;
      Path  : Unbounded_String;
   begin
      Assert (Editor.Pending_Transitions.Target_Kind (State) =
                Editor.Pending_Transitions.No_Pending_Transition,
              "empty pending state must report no target kind");
      Assert (not Editor.Pending_Transitions.Has_Target_Path (State),
              "empty pending state must not report a path target");
      Assert (Editor.Pending_Transitions.Target_Path (State, Found) = "",
              "empty pending state must return an empty path");
      Assert (not Found,
              "empty pending state must clear the path Found flag");

      Editor.Pending_Transitions.Set_Pending (State, Target, Summary);
      Path := To_Unbounded_String
        (Editor.Pending_Transitions.Target_Path (State, Found));

      Assert (Editor.Pending_Transitions.Target_Kind (State) =
                Editor.Pending_Transitions.Pending_Open_Project,
              "target kind accessor must expose the current pending kind");
      Assert (Editor.Pending_Transitions.Has_Target_Path (State),
              "path accessor must report stored path metadata");
      Assert (Found and then To_String (Path) = Editor.Test_Temp.Base & "/project-b",
              "path accessor must return the stored path and Found flag");
      Assert (not Editor.Pending_Transitions.Has_Target_Buffer (State),
              "path-only target must not report a buffer target");
   end Test_Target_Accessors_Are_Side_Effect_Free;

   procedure Test_Display_Text_Uses_Replaced_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      State : Editor.Pending_Transitions.Pending_Transition_State;
      First_Target : Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Project,
         Path       => To_Unbounded_String (Editor.Test_Temp.Base & "/project-a"),
         Display    => To_Unbounded_String ("Project A"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => True,
         others     => <>);
      Second_Target : Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Open_Project,
         Path       => To_Unbounded_String (Editor.Test_Temp.Base & "/project-b"),
         Display    => To_Unbounded_String ("Project B"),
         Buffer_Id  => 0,
         Has_Buffer => False,
         Has_Path   => True,
         others     => <>);
      Text : Unbounded_String;
   begin
      Editor.Pending_Transitions.Set_Pending (State, First_Target, Summary);
      Editor.Pending_Transitions.Set_Pending (State, Second_Target, Summary);
      Text := To_Unbounded_String (Editor.Pending_Transitions.Display_Text (State));

      Assert (Ada.Strings.Unbounded.Index (Text, "Project B") /= 0,
              "display text must show the replacement target");
      Assert (Ada.Strings.Unbounded.Index (Text, "Project A") = 0,
              "display text must not retain the replaced target");
   end Test_Display_Text_Uses_Replaced_Target;

   procedure Test_File_Lifecycle_Display_Uses_Lifecycle_Actions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Reload_State : Editor.Pending_Transitions.Pending_Transition_State;
      Revert_State : Editor.Pending_Transitions.Pending_Transition_State;
      Reload_Target : Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Reload_Active_Buffer,
         Path       => To_Unbounded_String (Editor.Test_Temp.Base & "/main.adb"),
         Display    => To_Unbounded_String ("main.adb"),
         Buffer_Id  => 7,
         Has_Buffer => True,
         Has_Path   => True,
         others     => <>);
      Revert_Target : Editor.Pending_Transitions.Pending_Transition_Target :=
        (Kind       => Editor.Pending_Transitions.Pending_Revert_Active_Buffer,
         Path       => To_Unbounded_String (Editor.Test_Temp.Base & "/main.adb"),
         Display    => To_Unbounded_String ("main.adb"),
         Buffer_Id  => 7,
         Has_Buffer => True,
         Has_Path   => True,
         others     => <>);
      Reload_Text : Unbounded_String;
      Revert_Text : Unbounded_String;
   begin
      Editor.Pending_Transitions.Set_Pending (Reload_State, Reload_Target, Summary);
      Editor.Pending_Transitions.Set_Pending (Revert_State, Revert_Target, Summary);

      Reload_Text := To_Unbounded_String
        (Editor.Pending_Transitions.Display_Text (Reload_State));
      Revert_Text := To_Unbounded_String
        (Editor.Pending_Transitions.Display_Text (Revert_State));

      Assert (Ada.Strings.Unbounded.Index (Reload_Text, "reloading buffer from disk") /= 0,
              "reload prompt must name the reload operation");
      Assert (Ada.Strings.Unbounded.Index (Reload_Text, "Retry or Cancel") /= 0,
              "reload prompt must advertise only retry/cancel lifecycle choices");
      Assert (Ada.Strings.Unbounded.Index (Reload_Text, "Close Clean") = 0,
              "reload prompt must not advertise clean-close as reload confirmation");

      Assert (Ada.Strings.Unbounded.Index (Revert_Text, "reverting buffer") /= 0,
              "revert prompt must name the revert operation");
      Assert (Ada.Strings.Unbounded.Index (Revert_Text, "Retry or Cancel") /= 0,
              "revert prompt must advertise only retry/cancel lifecycle choices");
      Assert (Ada.Strings.Unbounded.Index (Revert_Text, "Close Clean") = 0,
              "revert prompt must not advertise clean-close as revert confirmation");
   end Test_File_Lifecycle_Display_Uses_Lifecycle_Actions;

   procedure Test_Dirty_Guarded_Lifecycle_Targets_Carry_Revalidation_Metadata
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);

      procedure Check
        (Kind           : Editor.Pending_Transitions.Pending_Transition_Kind;
         Path_Required  : Boolean;
         Buffer_Required : Boolean)
      is
         State : Editor.Pending_Transitions.Pending_Transition_State;
         Target : constant Editor.Pending_Transitions.Pending_Transition_Target :=
           (Kind       => Kind,
            Path       => To_Unbounded_String (Editor.Test_Temp.Base & "/lifecycle-target"),
            Display    => To_Unbounded_String ("lifecycle-target"),
            Buffer_Id  => 42,
            Has_Buffer => Buffer_Required,
            Has_Path   => Path_Required,
            others     => <>);
         Audit : Editor.Pending_Transitions.Pending_Transition_Boundary_Audit;
         Found : Boolean := False;
      begin
         Editor.Pending_Transitions.Set_Pending (State, Target, Summary);
         Audit := Editor.Pending_Transitions.Audit_Pending_Transition_Boundary (State);

         Assert (Editor.Pending_Transitions.Target_Kind (State) = Kind,
                 "pending lifecycle target kind must round-trip");
         Assert (Editor.Pending_Transitions.Has_Target_Path (State) = Path_Required,
                 "path revalidation metadata must match lifecycle target kind");
         if Path_Required then
            Assert (Editor.Pending_Transitions.Target_Path (State, Found) =
                    Editor.Test_Temp.Base & "/lifecycle-target",
                    "path revalidation key must round-trip");
            Assert (Found, "path target lookup must report found");
         end if;
         Assert (Editor.Pending_Transitions.Has_Target_Buffer (State) = Buffer_Required,
                 "buffer revalidation metadata must match lifecycle target kind");
         Assert (Audit.Boundary_Safe,
                 "dirty-guarded lifecycle target must pass boundary audit");
      end Check;
   begin
      Check (Editor.Pending_Transitions.Pending_Open_Project, True, False);
      Check (Editor.Pending_Transitions.Pending_Switch_Project, True, False);
      Check (Editor.Pending_Transitions.Pending_Open_Recent_Project, True, False);
      Check (Editor.Pending_Transitions.Pending_Restore_Workspace, True, False);
      Check (Editor.Pending_Transitions.Pending_Close_Project, False, False);
      Check (Editor.Pending_Transitions.Pending_Clear_Project, False, False);
      Check (Editor.Pending_Transitions.Pending_Reload_Active_Buffer, True, True);
      Check (Editor.Pending_Transitions.Pending_Revert_Active_Buffer, True, True);
   end Test_Dirty_Guarded_Lifecycle_Targets_Carry_Revalidation_Metadata;


   overriding procedure Register_Tests
     (T : in out Pending_Transitions_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_New_State_Has_No_Pending'Access,
         "new state has no pending transition");
      Register_Routine
        (T, Test_Set_Pending_Stores_Target_And_Summary'Access,
         "set pending stores target and summary");
      Register_Routine
        (T, Test_Clear_Removes_Pending'Access,
         "clear removes pending transition");
      Register_Routine
        (T, Test_New_Pending_Replaces_Previous'Access,
         "new pending transition replaces previous target");
      Register_Routine
        (T, Test_Display_Text_Is_Deterministic'Access,
         "display text is deterministic");
      Register_Routine
        (T, Test_Target_Stores_Buffer_Metadata'Access,
         "pending target stores buffer metadata");
      Register_Routine
        (T, Test_Target_Accessors_Are_Side_Effect_Free'Access,
         "pending target accessors are side-effect-free");
      Register_Routine
        (T, Test_Display_Text_Uses_Replaced_Target'Access,
         "display text uses replacement target");
      Register_Routine
        (T, Test_File_Lifecycle_Display_Uses_Lifecycle_Actions'Access,
         "file lifecycle pending text uses lifecycle actions");
      Register_Routine
        (T, Test_Dirty_Guarded_Lifecycle_Targets_Carry_Revalidation_Metadata'Access,
         "dirty-guarded lifecycle targets carry revalidation metadata");
   end Register_Tests;

end Editor.Pending_Transitions.Tests;
