with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Project_Lifecycle;

package body Editor.Project_Lifecycle.Tests is

   function Name
     (T : Project_Lifecycle_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Project_Lifecycle.Tests");
   end Name;

   procedure Test_Default_Result_Has_No_Mutation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.Project_Lifecycle.Project_Lifecycle_Result :=
        (others => <>);
   begin
      Assert (not Result.Project_Changed,
              "default lifecycle result must not mark project changed");
      Assert (not Result.Project_Closed,
              "default lifecycle result must not mark project closed");
      Assert (Result.Buffers_Closed = 0,
              "default lifecycle result must not close buffers");
      Assert (Editor.Project_Lifecycle.Summary_Text (Result) =
                "No project lifecycle changes",
              "default lifecycle summary must be explicit");
   end Test_Default_Result_Has_No_Mutation;

   procedure Test_Project_Closed_Summary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.Project_Lifecycle.Project_Lifecycle_Result :=
        (Project_Changed          => True,
         Project_Closed           => True,
         Buffers_Closed           => 0,
         Dirty_Buffers_Blocked    => 0,
         Project_State_Reset      => True,
         Recent_Project_Promoted  => False,
         Workspace_State_Restored => False);
   begin
      Assert (Editor.Project_Lifecycle.Summary_Text (Result) =
                "Project closed, project state reset",
              "project close summary must mention close and reset only");
   end Test_Project_Closed_Summary;

   procedure Test_Buffers_Closed_Summary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.Project_Lifecycle.Project_Lifecycle_Result :=
        (Project_Changed          => False,
         Project_Closed           => False,
         Buffers_Closed           => 2,
         Dirty_Buffers_Blocked    => 0,
         Project_State_Reset      => False,
         Recent_Project_Promoted  => False,
         Workspace_State_Restored => False);
   begin
      Assert (Editor.Project_Lifecycle.Summary_Text (Result) =
                "2 buffers closed",
              "buffer close count summary must be deterministic");
   end Test_Buffers_Closed_Summary;

   procedure Test_Workspace_Restored_Summary
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.Project_Lifecycle.Project_Lifecycle_Result :=
        (Project_Changed          => True,
         Project_Closed           => False,
         Buffers_Closed           => 0,
         Dirty_Buffers_Blocked    => 0,
         Project_State_Reset      => False,
         Recent_Project_Promoted  => False,
         Workspace_State_Restored => True);
   begin
      Assert (Editor.Project_Lifecycle.Summary_Text (Result) =
                "Project changed, workspace state restored",
              "workspace restore summary must preserve lifecycle terminology");
   end Test_Workspace_Restored_Summary;

   procedure Test_Transition_Enum_Covers_Project_Lifecycle
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use type Editor.Project_Lifecycle.Project_Lifecycle_Transition;
   begin
      Assert
        (Editor.Project_Lifecycle.Open_Project_Lifecycle_Transition /=
           Editor.Project_Lifecycle.No_Project_Lifecycle_Transition,
         "open project transition must be distinct");
      Assert
        (Editor.Project_Lifecycle.Open_Recent_Project_Lifecycle_Transition /=
           Editor.Project_Lifecycle.Open_Project_Lifecycle_Transition,
         "open recent project transition must be distinct");
      Assert
        (Editor.Project_Lifecycle.Switch_Project_Lifecycle_Transition /=
           Editor.Project_Lifecycle.Open_Recent_Project_Lifecycle_Transition,
         "switch project transition must be distinct");
      Assert
        (Editor.Project_Lifecycle.Reset_Project_Lifecycle_Transition /=
           Editor.Project_Lifecycle.Switch_Project_Lifecycle_Transition,
         "reset project transition must be distinct");
      Assert
        (Editor.Project_Lifecycle.Close_Project_Lifecycle_Transition /=
           Editor.Project_Lifecycle.Clear_Project_Context_Lifecycle_Transition,
         "close and clear lifecycle transitions must be distinguishable");
      Assert
        (Editor.Project_Lifecycle.Restore_Workspace_Lifecycle_Transition /=
           Editor.Project_Lifecycle.Close_Project_Lifecycle_Transition,
         "restore workspace transition must be distinct");
   end Test_Transition_Enum_Covers_Project_Lifecycle;


   procedure Test_Transition_Classification_Helpers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      use Editor.Project_Lifecycle;
   begin
      Assert
        (Is_Project_Opening_Transition (Open_Project_Lifecycle_Transition),
         "open project must classify as opening transition");
      Assert
        (Is_Project_Opening_Transition (Open_Recent_Project_Lifecycle_Transition),
         "open recent project must classify as opening transition");
      Assert
        (Is_Project_Opening_Transition (Switch_Project_Lifecycle_Transition),
         "switch project must classify as opening transition");
      Assert
        (Is_Project_Opening_Transition (Reset_Project_Lifecycle_Transition),
         "reset project must classify as canonical project transition");
      Assert
        (not Is_Project_Opening_Transition (Close_Project_Lifecycle_Transition),
         "close project must not classify as opening transition");

      Assert
        (Is_Project_Closing_Transition (Close_Project_Lifecycle_Transition),
         "close project must classify as closing transition");
      Assert
        (Is_Project_Closing_Transition (Clear_Project_Context_Lifecycle_Transition),
         "clear project context must classify as closing transition");
      Assert
        (not Is_Project_Closing_Transition (Restore_Workspace_Lifecycle_Transition),
         "restore workspace must not classify as closing transition");

      Assert
        (Requires_Dirty_Guard (Open_Project_Lifecycle_Transition)
         and then Requires_Dirty_Guard (Open_Recent_Project_Lifecycle_Transition)
         and then Requires_Dirty_Guard (Switch_Project_Lifecycle_Transition)
         and then Requires_Dirty_Guard (Reset_Project_Lifecycle_Transition)
         and then Requires_Dirty_Guard (Close_Project_Lifecycle_Transition)
         and then Requires_Dirty_Guard (Clear_Project_Context_Lifecycle_Transition)
         and then Requires_Dirty_Guard (Restore_Workspace_Lifecycle_Transition),
         "all mutating lifecycle transitions must require dirty guard");
      Assert
        (not Requires_Dirty_Guard (No_Project_Lifecycle_Transition),
         "no transition must not require dirty guard");

      Assert
        (Resets_Project_Scoped_State (Open_Project_Lifecycle_Transition)
         and then Resets_Project_Scoped_State (Open_Recent_Project_Lifecycle_Transition)
         and then Resets_Project_Scoped_State (Switch_Project_Lifecycle_Transition)
         and then Resets_Project_Scoped_State (Reset_Project_Lifecycle_Transition)
         and then Resets_Project_Scoped_State (Close_Project_Lifecycle_Transition)
         and then Resets_Project_Scoped_State (Clear_Project_Context_Lifecycle_Transition)
         and then Resets_Project_Scoped_State (Restore_Workspace_Lifecycle_Transition),
         "lifecycle transitions must declare project-scoped reset behavior");
      Assert
        (not Resets_Project_Scoped_State (No_Project_Lifecycle_Transition),
         "no transition must not reset project-scoped state");
   end Test_Transition_Classification_Helpers;

   overriding procedure Register_Tests
     (T : in out Project_Lifecycle_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Default_Result_Has_No_Mutation'Access,
         "default result has no mutation");
      Register_Routine
        (T, Test_Project_Closed_Summary'Access,
         "project closed summary");
      Register_Routine
        (T, Test_Buffers_Closed_Summary'Access,
         "buffers closed summary");
      Register_Routine
        (T, Test_Workspace_Restored_Summary'Access,
         "workspace restored summary");
      Register_Routine
        (T, Test_Transition_Enum_Covers_Project_Lifecycle'Access,
         "transition enum covers project lifecycle");
      Register_Routine
        (T, Test_Transition_Classification_Helpers'Access,
         "transition classification helpers");
   end Register_Tests;

end Editor.Project_Lifecycle.Tests;
