with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Feature_Diagnostics;
with Editor.Feature_Messages;
with Editor.Feature_Panel;
with Editor.Feature_Panel_Audit;
with Editor.Feature_Panel_Controller;
with Editor.Feature_Search_Results;
with Editor.Message_Producers;
with Editor.Producer_Contracts;
with Editor.State;

use type Editor.Feature_Diagnostics.Diagnostic_Severity;
use type Editor.Feature_Messages.Message_Severity;
use type Editor.Feature_Panel.Feature_Id;
use type Editor.Feature_Panel.Feature_Panel_Fingerprint;
use type Editor.Producer_Contracts.Producer_Result_Status;

package body Editor.Producer_Contracts.Tests is

   overriding function Name
     (T : Producer_Contracts_Test_Case) return AUnit.Message_String
   is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Editor.Producer_Contracts");
   end Name;

   procedure Prepare_State
     (S : out Editor.State.State_Type)
   is
   begin
      Editor.State.Init (S);
      Editor.State.Load_Text (S, "alpha" & ASCII.LF & "beta" & ASCII.LF & "gamma");
   end Prepare_State;

   procedure Test_Producer_Audit_Passes_For_Messages_And_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Result : constant Editor.Feature_Panel_Audit.Feature_Panel_Audit_Result :=
        Editor.Feature_Panel_Audit.Run_Feature_Panel_Audit;
   begin
      Assert (Result.Passed, Editor.Feature_Panel_Audit.Summary (Result));
      Assert (Editor.Feature_Panel_Audit.Producer_Boundary_Audit_Passes,
              "producer boundary audit covers Messages and Diagnostics");
      Assert (Editor.Feature_Panel_Audit.Producer_Capable_Feature_Covers
                (Editor.Feature_Panel.Messages_Feature),
              "Messages producer boundary is feature-owned and audited");
      Assert (Editor.Feature_Panel_Audit.Producer_Capable_Feature_Covers
                (Editor.Feature_Panel.Diagnostics_Feature),
              "Diagnostics producer boundary is feature-owned and audited");
   end Test_Producer_Audit_Passes_For_Messages_And_Diagnostics;

   procedure Test_Producer_Audit_Is_Side_Effect_Free
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      After  : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      Result : Editor.Feature_Panel_Audit.Feature_Panel_Audit_Result;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Messages_Feature),
              "test can activate Messages");
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Result := Editor.Feature_Panel_Audit.Run_Feature_Panel_Audit;
      Assert (Result.Passed, Editor.Feature_Panel_Audit.Summary (Result));
      After := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      Assert (Before = After, "producer audit must be side-effect-free");
   end Test_Producer_Audit_Is_Side_Effect_Free;

   procedure Test_Messages_Producer_Post_Targeted_Validates_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Producer_Contracts.Producer_Result;
   begin
      Prepare_State (S);
      R := Editor.Message_Producers.Post_Targeted_Message_With_Result
        (S, Editor.Feature_Messages.Info_Message, "producer info", "unit-test",
         Editor.Feature_Messages.Editor_Source, S.Registry_Token, 1, 1);
      Assert (R.Status = Editor.Producer_Contracts.Producer_Accepted,
              "valid targeted message is accepted with target kept");
      Assert (R.Row_Accepted and then R.Target_Kept,
              "valid targeted message result records row and target acceptance");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "message producer appends one row");
      Assert (Editor.Feature_Messages.Item_Has_Target (S.Feature_Messages, 1),
              "valid targeted message keeps target metadata");
   end Test_Messages_Producer_Post_Targeted_Validates_Target;

   procedure Test_Messages_Producer_Invalid_Target_Becomes_Untargeted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Producer_Contracts.Producer_Result;
   begin
      Prepare_State (S);
      R := Editor.Message_Producers.Post_Targeted_Message_With_Result
        (S, Editor.Feature_Messages.Warning_Message, "producer warning", "unit-test",
         Editor.Feature_Messages.Editor_Source, S.Registry_Token + 999, 1, 1);
      Assert (R.Status = Editor.Producer_Contracts.Producer_Accepted_Untargeted,
              "invalid message target is accepted as untargeted");
      Assert (R.Row_Accepted and then not R.Target_Kept,
              "invalid message target result clears target kept");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "invalid-target message still stores row");
      Assert (not Editor.Feature_Messages.Item_Has_Target (S.Feature_Messages, 1),
              "invalid-target message clears Has_Target");
   end Test_Messages_Producer_Invalid_Target_Becomes_Untargeted;

   procedure Test_Messages_Producer_Rejects_Empty_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Producer_Contracts.Producer_Result;
   begin
      Prepare_State (S);
      R := Editor.Message_Producers.Post_Message_With_Result
        (S, Editor.Feature_Messages.Info_Message, "   ", "unit-test",
         Editor.Feature_Messages.Editor_Source);
      Assert (R.Status = Editor.Producer_Contracts.Producer_Rejected_Empty_Text,
              "empty message text is rejected deterministically");
      Assert (not R.Row_Accepted, "rejected empty message stores no row");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 0,
              "empty message producer call does not append");
   end Test_Messages_Producer_Rejects_Empty_Text;

   procedure Test_Diagnostics_Producer_Post_Targeted_Validates_Target
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Producer_Contracts.Producer_Result;
   begin
      Prepare_State (S);
      R := Editor.State.Post_Targeted_Diagnostic_With_Result
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "producer diagnostic",
         "unit-test", S.Registry_Token, 2, 1);
      Assert (R.Status = Editor.Producer_Contracts.Producer_Accepted,
              "valid targeted diagnostic is accepted with target kept");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "diagnostic producer appends one row");
      Assert (Editor.Feature_Diagnostics.Item_Has_Target (S.Feature_Diagnostics, 1),
              "valid targeted diagnostic keeps target metadata");
   end Test_Diagnostics_Producer_Post_Targeted_Validates_Target;

   procedure Test_Diagnostics_Producer_Invalid_Target_Becomes_Untargeted
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Producer_Contracts.Producer_Result;
   begin
      Prepare_State (S);
      R := Editor.State.Post_Targeted_Diagnostic_With_Result
        (S, Editor.Feature_Diagnostics.Diagnostic_Warning, "producer diagnostic",
         "unit-test", S.Registry_Token, 999, 1);
      Assert (R.Status = Editor.Producer_Contracts.Producer_Accepted_Untargeted,
              "invalid diagnostic target is accepted as untargeted");
      Assert (not R.Target_Kept, "invalid diagnostic target reports target cleared");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "invalid-target diagnostic still stores row");
      Assert (not Editor.Feature_Diagnostics.Item_Has_Target (S.Feature_Diagnostics, 1),
              "invalid-target diagnostic clears Has_Target");
   end Test_Diagnostics_Producer_Invalid_Target_Becomes_Untargeted;

   procedure Test_Diagnostics_Producer_Rejects_Empty_Text
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Producer_Contracts.Producer_Result;
   begin
      Prepare_State (S);
      R := Editor.State.Post_Diagnostic_With_Result
        (S, Editor.Feature_Diagnostics.Diagnostic_Info, " ", "unit-test");
      Assert (R.Status = Editor.Producer_Contracts.Producer_Rejected_Empty_Text,
              "empty diagnostic text is rejected deterministically");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "empty diagnostic producer call does not append");
   end Test_Diagnostics_Producer_Rejects_Empty_Text;

   procedure Test_Producer_Post_While_Another_Feature_Active_Does_Not_Switch
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      R : Editor.Producer_Contracts.Producer_Result;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Outline_Feature),
              "test can activate Outline");
      R := Editor.Message_Producers.Post_Message_With_Result
        (S, Editor.Feature_Messages.Info_Message, "producer info", "unit-test",
         Editor.Feature_Messages.Editor_Source);
      Assert (R.Row_Accepted, "message producer accepts row while Outline active");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                Editor.Feature_Panel.Outline_Feature,
              "message producer must not switch active feature");
      R := Editor.State.Post_Diagnostic_With_Result
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "producer diagnostic",
         "unit-test");
      Assert (R.Row_Accepted, "diagnostic producer accepts row while Outline active");
      Assert (Editor.Feature_Panel.Active_Feature (S.Feature_Panel) =
                Editor.Feature_Panel.Outline_Feature,
              "diagnostic producer must not switch active feature");
   end Test_Producer_Post_While_Another_Feature_Active_Does_Not_Switch;

   procedure Test_Producer_Post_While_Feature_Panel_Hidden_Is_State_Only
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Before : Editor.Feature_Panel.Feature_Panel_Fingerprint;
      R : Editor.Producer_Contracts.Producer_Result;
   begin
      Prepare_State (S);
      Editor.Feature_Panel.Set_Visible (S.Feature_Panel, False);
      Before := Editor.Feature_Panel.Fingerprint (S.Feature_Panel);
      R := Editor.Message_Producers.Post_Message_With_Result
        (S, Editor.Feature_Messages.Info_Message, "hidden panel", "unit-test",
         Editor.Feature_Messages.Editor_Source);
      Assert (R.Row_Accepted, "message producer accepts while panel hidden");
      Assert (Before = Editor.Feature_Panel.Fingerprint (S.Feature_Panel),
              "hidden-panel post does not mutate generic projection state");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "hidden-panel post updates feature-owned Messages state");
   end Test_Producer_Post_While_Feature_Panel_Hidden_Is_State_Only;

   procedure Test_Producer_Target_Cleanup_On_Buffer_Close
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Prepare_State (S);
      Editor.Message_Producers.Post_Targeted_Message
        (S, Editor.Feature_Messages.Info_Message, "targeted message", "unit-test",
         Editor.Feature_Messages.Editor_Source, S.Registry_Token, 1, 1);
      Editor.State.Post_Targeted_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "targeted diagnostic",
         "unit-test", S.Registry_Token, 1, 1);
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 1,
              "targeted message stored before buffer close");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 1,
              "targeted diagnostic stored before buffer close");
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Buffer_Close
        (S, S.Registry_Token);
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 0,
              "buffer close removes targeted producer messages");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "buffer close removes targeted producer diagnostics");
   end Test_Producer_Target_Cleanup_On_Buffer_Close;

   procedure Test_Producer_Project_And_Workspace_Close_Clear_Transient_Rows
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
   begin
      Prepare_State (S);
      Editor.Message_Producers.Post_Message
        (S, Editor.Feature_Messages.Info_Message, "project message", "unit-test",
         Editor.Feature_Messages.Editor_Source);
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "project diagnostic",
         "unit-test");
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Project_Close (S);
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 0,
              "project close clears producer messages");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "project close clears producer diagnostics");

      Editor.Message_Producers.Post_Message
        (S, Editor.Feature_Messages.Info_Message, "workspace message", "unit-test",
         Editor.Feature_Messages.Editor_Source);
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "workspace diagnostic",
         "unit-test");
      Editor.Feature_Panel_Controller.Reset_All_Features_For_Workspace_Close (S);
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = 0,
              "workspace close clears producer messages");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) = 0,
              "workspace close clears producer diagnostics");
   end Test_Producer_Project_And_Workspace_Close_Clear_Transient_Rows;

   procedure Test_Producer_Post_Does_Not_Mutate_Unrelated_Features
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Search_Rows_Before : Natural := 0;
      Diagnostics_Before : Natural := 0;
      Messages_Before    : Natural := 0;
   begin
      Prepare_State (S);
      Search_Rows_Before := Editor.Feature_Search_Results.Row_Count
        (S.Feature_Search_Results);
      Diagnostics_Before := Editor.Feature_Diagnostics.Row_Count
        (S.Feature_Diagnostics);
      Editor.Message_Producers.Post_Message
        (S, Editor.Feature_Messages.Info_Message, "isolated message", "unit-test",
         Editor.Feature_Messages.Editor_Source);
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) =
                Search_Rows_Before,
              "message producer does not mutate Search Results");
      Assert (Editor.Feature_Diagnostics.Row_Count (S.Feature_Diagnostics) =
                Diagnostics_Before,
              "message producer does not mutate Diagnostics");

      Messages_Before := Editor.Feature_Messages.Row_Count (S.Feature_Messages);
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "isolated diagnostic",
         "unit-test");
      Assert (Editor.Feature_Messages.Row_Count (S.Feature_Messages) = Messages_Before,
              "diagnostic producer does not mutate Messages");
      Assert (Editor.Feature_Search_Results.Row_Count (S.Feature_Search_Results) =
                Search_Rows_Before,
              "diagnostic producer does not mutate Search Results");
   end Test_Producer_Post_Does_Not_Mutate_Unrelated_Features;

   procedure Test_Producer_Post_Does_Not_Revive_Stale_Projection_Token
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      S : Editor.State.State_Type;
      Token : Editor.Feature_Panel.Feature_Projection_Token;
   begin
      Prepare_State (S);
      Assert (Editor.Feature_Panel_Controller.Show_Feature
                (S, Editor.Feature_Panel.Messages_Feature),
              "test can activate Messages");
      Token := Editor.Feature_Panel.Build_Feature_Projection_Token (S.Feature_Panel);
      Editor.Feature_Panel.Clear_Rows (S.Feature_Panel);
      Assert (not Editor.Feature_Panel.Validate_Feature_Projection_Token
                (S.Feature_Panel, Token),
              "clearing rows makes token stale");
      Editor.State.Post_Diagnostic
        (S, Editor.Feature_Diagnostics.Diagnostic_Error, "diagnostic", "unit-test");
      Assert (not Editor.Feature_Panel.Validate_Feature_Projection_Token
                (S.Feature_Panel, Token),
              "producer post cannot revive stale projection token");
   end Test_Producer_Post_Does_Not_Revive_Stale_Projection_Token;

   overriding procedure Register_Tests
     (T : in out Producer_Contracts_Test_Case)
   is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Producer_Audit_Passes_For_Messages_And_Diagnostics'Access,
                        "Producer audit passes for Messages and Diagnostics");
      Register_Routine (T, Test_Producer_Audit_Is_Side_Effect_Free'Access,
                        "Producer audit is side-effect-free");
      Register_Routine (T, Test_Messages_Producer_Post_Targeted_Validates_Target'Access,
                        "Messages producer targeted post validates target");
      Register_Routine (T, Test_Messages_Producer_Invalid_Target_Becomes_Untargeted'Access,
                        "Messages producer invalid target becomes untargeted");
      Register_Routine (T, Test_Messages_Producer_Rejects_Empty_Text'Access,
                        "Messages producer rejects empty text");
      Register_Routine (T, Test_Diagnostics_Producer_Post_Targeted_Validates_Target'Access,
                        "Diagnostics producer targeted post validates target");
      Register_Routine (T, Test_Diagnostics_Producer_Invalid_Target_Becomes_Untargeted'Access,
                        "Diagnostics producer invalid target becomes untargeted");
      Register_Routine (T, Test_Diagnostics_Producer_Rejects_Empty_Text'Access,
                        "Diagnostics producer rejects empty text");
      Register_Routine (T, Test_Producer_Post_While_Another_Feature_Active_Does_Not_Switch'Access,
                        "Producer posts do not switch active feature");
      Register_Routine (T, Test_Producer_Post_While_Feature_Panel_Hidden_Is_State_Only'Access,
                        "Producer posts while panel hidden update feature state only");
      Register_Routine (T, Test_Producer_Target_Cleanup_On_Buffer_Close'Access,
                        "Producer targets clean up on buffer close");
      Register_Routine (T, Test_Producer_Project_And_Workspace_Close_Clear_Transient_Rows'Access,
                        "Project and workspace close clear producer rows");
      Register_Routine (T, Test_Producer_Post_Does_Not_Mutate_Unrelated_Features'Access,
                        "Producer posts do not mutate unrelated features");
      Register_Routine (T, Test_Producer_Post_Does_Not_Revive_Stale_Projection_Token'Access,
                        "Producer posts do not revive stale projection tokens");
   end Register_Tests;

end Editor.Producer_Contracts.Tests;
