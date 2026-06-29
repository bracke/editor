with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Diagnostic_Action_Router;
with Editor.Ada_Diagnostic_Action_Execution;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Ada_Diagnostic_Navigation;
with Editor.Ada_Diagnostic_Panel_Projection;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Diagnostic_Quick_Fix_Skeleton;
with Editor.Ada_Diagnostic_Status_Line;
with Editor.Ada_Final_Semantic_Diagnostic_Integration;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Diagnostic_Action_Execution is

   package Execution renames Editor.Ada_Diagnostic_Action_Execution;
   package Commands renames Editor.Ada_Diagnostic_Command_Projection;
   package Router renames Editor.Ada_Diagnostic_Action_Router;
   package Final_Diag renames Editor.Ada_Final_Semantic_Diagnostic_Integration;
   package Cross_Final renames Final_Diag.Cross_Final;
   package Navigation renames Editor.Ada_Diagnostic_Navigation;
   package Panel renames Editor.Ada_Diagnostic_Panel_Projection;
   package Provenance renames Editor.Ada_Diagnostic_Provenance;
   package Quick_Fixes renames Editor.Ada_Diagnostic_Quick_Fix_Skeleton;
   package Status_Line renames Editor.Ada_Diagnostic_Status_Line;
   package SC renames Editor.Ada_Semantic_Colour_Projection;
   package Feed renames Editor.Ada_Semantic_Diagnostic_Feed;
   package Index renames Editor.Ada_Semantic_Diagnostic_Index;
   package Guards renames Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;

   use type Execution.Diagnostic_Action_Execution_Effect;
   use type Execution.Diagnostic_Action_Execution_Status;
   use type Commands.Diagnostic_Command_Descriptor_Id;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Diagnostic_Action_Execution");
   end Name;

   function Current_Guard return Guards.Guarded_Semantic_Diagnostic_Model is
      Projection : SC.Semantic_Colour_Model;
      Key : constant Guards.Diagnostic_Snapshot_Key :=
        Guards.Make_Key ("diagnostic-execution.adb", 1203, 2, 3, 5,
                         SC.Fingerprint (Projection));
   begin
      return Guards.Build (Key, Key, Projection);
   end Current_Guard;

   function Final_Model return Final_Diag.Final_Diagnostic_Model is
      Contexts : Final_Diag.Final_Diagnostic_Context_Model;
      Cross : Final_Diag.Final_Diagnostic_Context_Info;
   begin
      Cross.Id := 1;
      Cross.Family := Final_Diag.Final_Diagnostic_Cross_Unit;
      Cross.Node := Editor.Ada_Syntax_Tree.Node_Id (120301);
      Cross.Cross_Unit_Status :=
        Cross_Final.Cross_Unit_Final_Missing_Dependency;
      Cross.Source_Fingerprint := 1203;
      Cross.Expected_Source_Fingerprint := 1203;
      Cross.Message := To_Unbounded_String ("diagnostic execution workflow");
      Cross.Start_Line := 41;
      Cross.Start_Column := 6;
      Cross.End_Line := 41;
      Cross.End_Column := 24;
      Final_Diag.Add_Context (Contexts, Cross);
      return Final_Diag.Build (Contexts);
   end Final_Model;

   function Command_Model return Commands.Diagnostic_Command_Projection_Model is
      Final : constant Final_Diag.Final_Diagnostic_Model := Final_Model;
      Feed_Model : constant Feed.Semantic_Diagnostic_Feed_Model :=
        Feed.Build_With_Final_Semantic_Diagnostics (Current_Guard, Final);
      Indexed : constant Index.Semantic_Diagnostic_Index_Model :=
        Index.Build (Feed_Model);
      Quick : constant Quick_Fixes.Diagnostic_Quick_Fix_Model :=
        Quick_Fixes.Build (Indexed);
      Nav : constant Navigation.Diagnostic_Navigation_Model :=
        Navigation.Build (Indexed);
      Pan : constant Panel.Diagnostic_Panel_Model :=
        Panel.Build (Indexed);
      Prov : constant Provenance.Diagnostic_Provenance_Model :=
        Provenance.Build (Indexed);
      Status : constant Status_Line.Diagnostic_Status_Line_Model :=
        Status_Line.Build (Indexed, 41, 6);
      Routes : constant Router.Diagnostic_Action_Router_Model :=
        Router.Build (Quick, Nav, Pan, Prov, Status);
   begin
      return Commands.Build (Routes);
   end Command_Model;

   function Edited_Command_Model return Commands.Diagnostic_Command_Projection_Model is
      Final : constant Final_Diag.Final_Diagnostic_Model := Final_Model;
      Feed_Model : constant Feed.Semantic_Diagnostic_Feed_Model :=
        Feed.Build_With_Final_Semantic_Diagnostics (Current_Guard, Final);
      Edited_Feed : constant Feed.Semantic_Diagnostic_Feed_Model :=
        Feed.With_Edit_Hint
          (Feed_Model,
           Feed.Entry_At (Feed_Model, 1).Id,
           41, 6, 41, 24,
           "with Missing.Dependency;");
      Indexed : constant Index.Semantic_Diagnostic_Index_Model :=
        Index.Build (Edited_Feed);
      Quick : constant Quick_Fixes.Diagnostic_Quick_Fix_Model :=
        Quick_Fixes.Build (Indexed);
      Nav : constant Navigation.Diagnostic_Navigation_Model :=
        Navigation.Build (Indexed);
      Pan : constant Panel.Diagnostic_Panel_Model :=
        Panel.Build (Indexed);
      Prov : constant Provenance.Diagnostic_Provenance_Model :=
        Provenance.Build (Indexed);
      Status : constant Status_Line.Diagnostic_Status_Line_Model :=
        Status_Line.Build (Indexed, 41, 6);
      Routes : constant Router.Diagnostic_Action_Router_Model :=
        Router.Build (Quick, Nav, Pan, Prov, Status);
   begin
      return Commands.Build (Routes);
   end Edited_Command_Model;

   function Descriptor
     (Id           : Commands.Diagnostic_Command_Descriptor_Id;
      Kind         : Commands.Diagnostic_Command_Kind;
      Availability : Commands.Diagnostic_Command_Availability)
      return Commands.Diagnostic_Command_Descriptor
   is
      Result : Commands.Diagnostic_Command_Descriptor;
   begin
      Result.Id := Id;
      Result.Command_Kind := Kind;
      Result.Availability := Availability;
      Result.Display_Label := To_Unbounded_String ("Review diagnostic");
      Result.Start_Line := 3;
      Result.Start_Column := 7;
      Result.End_Line := 3;
      Result.End_Column := 18;
      Result.Fingerprint := 42;
      return Result;
   end Descriptor;

   procedure Test_Available_Command_Executes_To_Effect
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      D : constant Commands.Diagnostic_Command_Descriptor :=
        Descriptor
          (1, Commands.Diagnostic_Command_Navigate_To_Diagnostic,
           Commands.Diagnostic_Command_Available);
      R : constant Execution.Diagnostic_Action_Execution_Result :=
        Execution.Execute (D);
   begin
      Assert (Execution.Is_Executable (D), "available descriptor is executable");
      Assert (Execution.Is_Success (R), "execution should succeed");
      Assert (R.Status = Execution.Diagnostic_Action_Execution_Executed,
              "execution status should be executed");
      Assert (R.Effect = Execution.Diagnostic_Action_Effect_Navigate,
              "navigation descriptor should produce navigation effect");
      Assert (R.Start_Line = 3 and then R.Start_Column = 7,
              "execution retains source target span");
      Assert (R.Fingerprint /= 0, "execution fingerprint is deterministic");
   end Test_Available_Command_Executes_To_Effect;

   procedure Test_Unavailable_And_Stale_Commands_Do_Not_Execute
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Missing : constant Commands.Diagnostic_Command_Descriptor :=
        Descriptor
          (2, Commands.Diagnostic_Command_Explain_Diagnostic,
           Commands.Diagnostic_Command_Missing_Target);
      Stale : constant Commands.Diagnostic_Command_Descriptor :=
        Descriptor
          (3, Commands.Diagnostic_Command_Review_Expression,
           Commands.Diagnostic_Command_Rejected_Stale);
      Missing_Result : constant Execution.Diagnostic_Action_Execution_Result :=
        Execution.Execute (Missing);
      Stale_Result : constant Execution.Diagnostic_Action_Execution_Result :=
        Execution.Execute (Stale);
   begin
      Assert (not Execution.Is_Executable (Missing),
              "missing target descriptor is not executable");
      Assert (Missing_Result.Status =
              Execution.Diagnostic_Action_Execution_Unavailable,
              "missing target stays unavailable");
      Assert (Missing_Result.Effect = Execution.Diagnostic_Action_Effect_None,
              "missing target has no effect");
      Assert (Stale_Result.Status =
              Execution.Diagnostic_Action_Execution_Rejected_Stale,
              "stale descriptor is rejected");
      Assert (Stale_Result.Effect = Execution.Diagnostic_Action_Effect_None,
              "stale descriptor has no effect");
   end Test_Unavailable_And_Stale_Commands_Do_Not_Execute;

   procedure Test_Batch_Execution_Preserves_Action_Order_And_Counts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Descriptors : constant Execution.Diagnostic_Command_Descriptor_Array :=
        (Descriptor
           (4, Commands.Diagnostic_Command_Review_Expression,
            Commands.Diagnostic_Command_Available),
         Descriptor
           (5, Commands.Diagnostic_Command_Explain_Diagnostic,
            Commands.Diagnostic_Command_Missing_Target),
         Descriptor
           (6, Commands.Diagnostic_Command_Review_Generic,
            Commands.Diagnostic_Command_Rejected_Stale),
         Descriptor
           (7, Commands.Diagnostic_Command_Review_Cross_Unit,
            Commands.Diagnostic_Command_Available));
      Results : constant Execution.Diagnostic_Action_Execution_Result_Set :=
        Execution.Execute_All (Descriptors);
      First : constant Execution.Diagnostic_Action_Execution_Result :=
        Execution.First_Success (Results);
   begin
      Assert (Execution.Result_Count (Results) = 4,
              "batch execution returns one result per descriptor");
      Assert (Execution.Executed_Count (Results) = 2,
              "batch execution counts executable actions");
      Assert (Execution.Unavailable_Count (Results) = 1,
              "batch execution counts unavailable actions");
      Assert (Execution.Rejected_Stale_Count (Results) = 1,
              "batch execution counts stale rejections");
      Assert (First.Descriptor_Id = 4,
              "first success preserves descriptor order");
      Assert (First.Effect = Execution.Diagnostic_Action_Effect_Review_Expression,
              "first success exposes concrete effect");
      Assert (Execution.Result_At (Results, 4).Effect =
              Execution.Diagnostic_Action_Effect_Review_Cross_Unit,
              "later executable action remains addressable by index");
      Assert (Execution.Fingerprint (Results) /= 0,
              "batch execution fingerprint is deterministic");
   end Test_Batch_Execution_Preserves_Action_Order_And_Counts;

   procedure Test_Editable_Command_Executes_As_Edit_Action
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Editable : Commands.Diagnostic_Command_Descriptor :=
        Descriptor
          (8, Commands.Diagnostic_Command_Explain_Diagnostic,
           Commands.Diagnostic_Command_Available);
      Plain : constant Commands.Diagnostic_Command_Descriptor :=
        Descriptor
          (9, Commands.Diagnostic_Command_Explain_Diagnostic,
           Commands.Diagnostic_Command_Available);
      Edit_Result : Execution.Diagnostic_Action_Execution_Result;
      Results : Execution.Diagnostic_Action_Execution_Result_Set;
   begin
      Editable.Has_Edit := True;
      Editable.Edit_Start_Line := 3;
      Editable.Edit_Start_Column := 18;
      Editable.Edit_End_Line := 3;
      Editable.Edit_End_Column := 18;
      Editable.Replacement_Text := To_Unbounded_String (";");
      Edit_Result := Execution.Execute (Editable);
      Results := Execution.Execute_All ((Editable, Plain));

      Assert (Execution.Is_Success (Edit_Result),
              "editable diagnostic command should execute");
      Assert (Edit_Result.Has_Edit,
              "editable diagnostic command should preserve edit metadata");
      Assert (Edit_Result.Effect = Execution.Diagnostic_Action_Effect_Edit,
              "editable diagnostic command should produce edit effect");
      Assert (Edit_Result.Edit_Start_Line = 3
              and then Edit_Result.Edit_Start_Column = 18
              and then Edit_Result.Edit_End_Line = 3
              and then Edit_Result.Edit_End_Column = 18
              and then To_String (Edit_Result.Replacement_Text) = ";",
              "editable diagnostic command should preserve edit payload");
      Assert (Execution.Executed_Count (Results) = 2,
              "batch execution should still count both commands as executed");
      Assert (Execution.Editable_Count (Results) = 1,
              "batch execution should count only editable actions");
      Assert (Execution.Result_At (Results, 2).Effect =
              Execution.Diagnostic_Action_Effect_Explain,
              "non-edit command should keep its original effect");
      Assert (Execution.Result_At (Results, 2).Fingerprint /=
              Edit_Result.Fingerprint,
              "edit metadata should participate in fingerprints");
   end Test_Editable_Command_Executes_As_Edit_Action;

   procedure Test_Model_Execution_Uses_Projectable_Diagnostic_Actions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant Commands.Diagnostic_Command_Projection_Model :=
        Command_Model;
      Results : constant Execution.Diagnostic_Action_Execution_Result_Set :=
        Execution.Execute_All (Model);
      First : constant Execution.Diagnostic_Action_Execution_Result :=
        Execution.First_Success (Results);
   begin
      Assert (Commands.Descriptor_Count (Model) = 3,
              "single real diagnostic should project three command descriptors");
      Assert (Execution.Result_Count (Results) = Commands.Descriptor_Count (Model),
              "model execution should return one result per projected descriptor");
      Assert (Execution.Executed_Count (Results) = 3,
              "complete projected diagnostic commands should all execute");
      Assert (Execution.Unavailable_Count (Results) = 0,
              "complete projected diagnostic commands should not be unavailable");
      Assert (Execution.Rejected_Stale_Count (Results) = 0,
              "current projected diagnostic commands should not be stale");
      Assert (First.Effect = Execution.Diagnostic_Action_Effect_Navigate,
              "first projected action should navigate to the diagnostic");
      Assert (Execution.Result_At (Results, 2).Effect =
              Execution.Diagnostic_Action_Effect_Explain,
              "second projected action should explain the diagnostic");
      Assert (Execution.Result_At (Results, 3).Effect =
              Execution.Diagnostic_Action_Effect_Review_Cross_Unit,
              "third projected action should keep the source-specific review effect");
      Assert (First.Start_Line = 41 and then First.Start_Column = 6,
              "model execution should preserve the diagnostic source span");
      Assert (Execution.Fingerprint (Results) /= 0,
              "model execution should produce a deterministic fingerprint");
   end Test_Model_Execution_Uses_Projectable_Diagnostic_Actions;

   procedure Test_Model_Execution_Uses_Feed_Edit_Hints
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant Commands.Diagnostic_Command_Projection_Model :=
        Edited_Command_Model;
      Results : constant Execution.Diagnostic_Action_Execution_Result_Set :=
        Execution.Execute_All (Model);
      First : constant Execution.Diagnostic_Action_Execution_Result :=
        Execution.First_Success (Results);
   begin
      Assert (Commands.Descriptor_Count (Model) = 3,
              "edited diagnostic should still project three command descriptors");
      Assert (Execution.Result_Count (Results) = 3,
              "edited model execution should return one result per descriptor");
      Assert (Execution.Executed_Count (Results) = 3,
              "edited projected diagnostic commands should all execute");
      Assert (Execution.Editable_Count (Results) = 3,
              "feed edit hints should execute as edit effects through the projected model");
      Assert
        (First.Effect = Execution.Diagnostic_Action_Effect_Edit
         and then First.Has_Edit
         and then First.Edit_Start_Line = 41
         and then First.Edit_Start_Column = 6
         and then First.Edit_End_Line = 41
         and then First.Edit_End_Column = 24
         and then To_String (First.Replacement_Text) = "with Missing.Dependency;",
         "model execution should preserve explicit feed edit metadata");
   end Test_Model_Execution_Uses_Feed_Edit_Hints;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Available_Command_Executes_To_Effect'Access,
         "Ada diagnostic action execution maps available commands to effects");
      Register_Routine
        (T, Test_Unavailable_And_Stale_Commands_Do_Not_Execute'Access,
         "Ada diagnostic action execution rejects unavailable and stale commands");
      Register_Routine
        (T, Test_Batch_Execution_Preserves_Action_Order_And_Counts'Access,
         "Ada diagnostic action execution batches ordered code actions");
      Register_Routine
        (T, Test_Editable_Command_Executes_As_Edit_Action'Access,
         "Ada diagnostic action execution preserves editable code actions");
      Register_Routine
        (T, Test_Model_Execution_Uses_Projectable_Diagnostic_Actions'Access,
         "Ada diagnostic action execution runs projected code-action models");
      Register_Routine
        (T, Test_Model_Execution_Uses_Feed_Edit_Hints'Access,
         "Ada diagnostic action execution runs projected feed edit hints");
   end Register_Tests;

end Test_Ada_Diagnostic_Action_Execution;
