with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Dirty_Guards;

package body Editor.Dirty_Guards.Tests is

   use type Editor.Dirty_Guards.Dirty_Transition_Status;

   function Name
     (T : Dirty_Guards_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Dirty_Guards.Tests");
   end Name;

   procedure Test_Allowed_Result_Has_Empty_Reason
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : constant Editor.Dirty_Guards.Dirty_Buffer_Summary :=
        (Dirty_Count => 0, Untitled_Count => 0, File_Backed_Count => 0);
      Result : constant Editor.Dirty_Guards.Dirty_Transition_Result :=
        Editor.Dirty_Guards.Allowed (Summary);
   begin
      Assert (Editor.Dirty_Guards.Is_Allowed (Result),
              "Allowed result must be allowed");
      Assert (Editor.Dirty_Guards.Reason (Result) = "",
              "Allowed result must not carry a blocked reason");
   end Test_Allowed_Result_Has_Empty_Reason;

   procedure Test_Blocked_Result_Stores_Reason_And_Counts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : constant Editor.Dirty_Guards.Dirty_Buffer_Summary :=
        (Dirty_Count => 3, Untitled_Count => 1, File_Backed_Count => 2);
      Result : constant Editor.Dirty_Guards.Dirty_Transition_Result :=
        Editor.Dirty_Guards.Blocked (Summary, "Unsaved changes");
   begin
      Assert (not Editor.Dirty_Guards.Is_Allowed (Result),
              "Blocked result must not be allowed");
      Assert (Editor.Dirty_Guards.Reason (Result) = "Unsaved changes",
              "Blocked result must preserve its reason");
      Assert (Result.Summary.Dirty_Count = 3
              and then Result.Summary.Untitled_Count = 1
              and then Result.Summary.File_Backed_Count = 2,
              "Blocked result must preserve dirty summary counts");
   end Test_Blocked_Result_Stores_Reason_And_Counts;

   procedure Test_Clean_Transition_Is_Allowed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.Dirty_Guards.Dirty_Transition_Result :=
        Editor.Dirty_Guards.Guard_Transition
          (Editor.Dirty_Guards.Open_Project_Transition,
           (Dirty_Count => 0, Untitled_Count => 0, File_Backed_Count => 0));
   begin
      Assert (Editor.Dirty_Guards.Is_Allowed (Result),
              "clean project transition must be allowed");
   end Test_Clean_Transition_Is_Allowed;

   procedure Test_Dirty_Project_Switch_Is_Blocked
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.Dirty_Guards.Dirty_Transition_Result :=
        Editor.Dirty_Guards.Guard_Transition
          (Editor.Dirty_Guards.Open_Project_Transition,
           (Dirty_Count => 1, Untitled_Count => 0, File_Backed_Count => 1));
   begin
      Assert (not Editor.Dirty_Guards.Is_Allowed (Result),
              "dirty project switch must be blocked");
      Assert (Editor.Dirty_Guards.Reason (Result) =
                "Cannot switch project with unsaved changes",
              "project switch block reason must be canonical");
   end Test_Dirty_Project_Switch_Is_Blocked;

   procedure Test_Project_Lifecycle_Transitions_Are_Classified
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Summary : constant Editor.Dirty_Guards.Dirty_Buffer_Summary :=
        (Dirty_Count => 1, Untitled_Count => 0, File_Backed_Count => 1);
      Result : Editor.Dirty_Guards.Dirty_Transition_Result;
   begin
      Result := Editor.Dirty_Guards.Guard_Transition
        (Editor.Dirty_Guards.Close_Project_Transition, Summary);
      Assert (not Editor.Dirty_Guards.Is_Allowed (Result),
              "dirty close-project transition must be blocked");
      Assert (Editor.Dirty_Guards.Reason (Result) =
                "Cannot close project with unsaved changes",
              "close-project block reason must be canonical");

      Result := Editor.Dirty_Guards.Guard_Transition
        (Editor.Dirty_Guards.Clear_Project_Transition, Summary);
      Assert (not Editor.Dirty_Guards.Is_Allowed (Result),
              "dirty clear-project transition must be blocked");
   end Test_Project_Lifecycle_Transitions_Are_Classified;



   procedure Test_Canonical_Wording_Helpers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
   begin
      Assert (Editor.Dirty_Guards.No_Dirty_File_Backed_Buffers_Message =
                "No dirty file-backed buffers",
              "dirty file-backed empty message must be canonical");
      Assert (Editor.Dirty_Guards.No_Clean_Buffers_Message =
                "No clean buffers",
              "clean-buffer empty message must be canonical");
      Assert (Editor.Dirty_Guards.No_Pending_Transition_Message =
                "No pending transition",
              "pending empty message must be canonical");
      Assert (Editor.Dirty_Guards.Save_Or_Resolve_Changes_First_Message =
                "Save or resolve changes first",
              "retry dirty-blocked message must not reference removed discard actions");
      Assert (Editor.Dirty_Guards.Pending_Transition_Canceled_Message =
                "Pending transition canceled",
              "cancel message must be canonical");
      Assert (Editor.Dirty_Guards.Pending_Transition_No_Longer_Valid_Message =
                "Pending transition is no longer valid",
              "stale pending message must be canonical");
      Assert (Editor.Dirty_Guards.Workspace_State_Saved_Message =
                "Workspace state saved",
              "workspace-state save message must not imply file save");
      Assert (Editor.Dirty_Guards.Workspace_State_Restored_Message =
                "Workspace restored.",
              "workspace restore message must use product-facing wording");
   end Test_Canonical_Wording_Helpers;


   overriding procedure Register_Tests
     (T : in out Dirty_Guards_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Allowed_Result_Has_Empty_Reason'Access,
         "allowed result has empty reason");
      Register_Routine
        (T, Test_Blocked_Result_Stores_Reason_And_Counts'Access,
         "blocked result stores reason and counts");
      Register_Routine
        (T, Test_Clean_Transition_Is_Allowed'Access,
         "clean transition is allowed");
      Register_Routine
        (T, Test_Dirty_Project_Switch_Is_Blocked'Access,
         "dirty project switch is blocked");
      Register_Routine
        (T, Test_Project_Lifecycle_Transitions_Are_Classified'Access,
         "project lifecycle transitions are classified");
      Register_Routine
        (T, Test_Canonical_Wording_Helpers'Access,
         "canonical dirty-transition wording helpers");
   end Register_Tests;

end Editor.Dirty_Guards.Tests;
