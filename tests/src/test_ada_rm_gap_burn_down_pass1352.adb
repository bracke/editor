with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_RM_Gap_Burn_Down_Pass1352;

package body Test_Ada_RM_Gap_Burn_Down_Pass1352 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1352;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Pragma_Construct_Kind;
   use type Audit.Policy_Context_Kind;
   use type Audit.Burn_Down_Status;
   use type Audit.Burn_Down_Row;
   use type Audit.Burn_Down_Input;
   use type Audit.Burn_Down_Entry;
   use type Audit.Burn_Down_Model;
   package Matrix renames Audit.Matrix;
   package Remediation renames Audit.Remediation;
   package Consumers renames Audit.Consumers;
   package Precision renames Audit.Precision;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1352");
   end Name;

   procedure Add_Row
     (Input : in out Audit.Burn_Down_Input;
      Id : Natural;
      Expected : Audit.Precision_Classification;
      Gap : Audit.Burn_Down_Gap :=
        Audit.Gap_Pragma_Configuration_Categorization_Restrictions;
      Construct : Audit.Pragma_Construct_Kind :=
        Audit.Construct_Configuration_Pragma;
      Context : Audit.Policy_Context_Kind := Audit.Context_Configuration_File;
      Family : Audit.RM_Family := Matrix.Family_Contracts_Global_Depends_Flow;
      Owner : Audit.Implementing_Slice := Matrix.Slice_Contract_Aspect;
      Previous_State : Audit.Remediation_State := Remediation.State_Partial;
      Matrix_Before : Audit.Coverage_Level := Matrix.Coverage_Partial;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Source_Shaped : Boolean := True;
      Remediation_Present : Boolean := True;
      Matrix_Present : Boolean := True;
      Package_Present : Boolean := True;
      New_Rule : Boolean := True;
      Coverage_Updated : Boolean := True;
      Corpus_Balanced : Boolean := True;
      Consumed : Boolean := True;
      Consumer_Reached : Boolean := True;
      Stable_Blocker : Boolean := True;
      Configuration_Placement_OK : Boolean := True;
      Configuration_Target_OK : Boolean := True;
      Duplicate_Configuration : Boolean := False;
      Conflicting_Configuration : Boolean := False;
      Restriction_Rule_Known : Boolean := True;
      Hard_Restriction : Boolean := False;
      Restriction_Warning : Boolean := False;
      Restriction_Warning_Preserved : Boolean := True;
      Restriction_Warning_Hard : Boolean := False;
      Categorization_Conflict : Boolean := False;
      Dependency_Category_OK : Boolean := True;
      Body_Spec_Category_OK : Boolean := True;
      Pure_OK : Boolean := True;
      Preelaborate_OK : Boolean := True;
      Remote_Types_OK : Boolean := True;
      Shared_Passive_OK : Boolean := True;
      RCI_OK : Boolean := True;
      Suppress_Placement_OK : Boolean := True;
      Assert_Boolean : Boolean := True;
      Assertion_Policy_Known : Boolean := True;
      Assertion_Runtime_Check : Boolean := False;
      Suppressed_Check_Runtime : Boolean := False;
      Runtime_Check_Preserved : Boolean := True;
      Pack_Target_OK : Boolean := True;
      Inline_Target_OK : Boolean := True;
      Import_Export_Agrees : Boolean := True;
      No_Return_Agrees : Boolean := True;
      Volatile_Atomic_Agrees : Boolean := True;
      Tasking_Consumes : Boolean := True;
      Access_Consumes : Boolean := True;
      Exception_Finalization_Consumes : Boolean := True;
      Elaboration_Consumes : Boolean := True;
      Local_Consumes : Boolean := True;
      Consumer_Config_Agrees : Boolean := True;
      Consumer_Restriction_Agrees : Boolean := True;
      Consumer_Category_Agrees : Boolean := True;
      Consumer_Assertion_Agrees : Boolean := True;
      Consumer_Warning_Surface : Boolean := True;
      Consumer_Bridge_Agrees : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit : Boolean := False;
      Missing_Configuration : Boolean := False;
      Missing_Category : Boolean := False;
      Missing_Restriction : Boolean := False;
      Missing_Policy : Boolean := False;
      Evidence_Stale : Boolean := False;
      Expected_Burn_FP : Natural := 0;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Unit_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0;
      Expected_Policy_FP : Natural := 0;
      Expected_Category_FP : Natural := 0;
      Expected_Restriction_FP : Natural := 0;
      Expected_Consumer_FP : Natural := 0) is
      Row : Audit.Burn_Down_Row;
   begin
      Row.Id := Id;
      Row.Gap := Gap;
      Row.Family := Family;
      Row.Owner := Owner;
      Row.Previous_State := Previous_State;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix_Before;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Construct := Construct;
      Row.Context := Context;
      Row.Name := To_Unbounded_String ("pass1352 source-shaped row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1352");
      Row.Source_Shaped_Evidence := Source_Shaped;
      Row.Remediation_Entry_Present := Remediation_Present;
      Row.Matrix_Coverage_Present := Matrix_Present;
      Row.Implementing_Package_Present := Package_Present;
      Row.New_Legality_Rule_Added := New_Rule;
      Row.Coverage_Entry_Updated_To_Covered := Coverage_Updated;
      Row.Balanced_Regression_Evidence := Corpus_Balanced;
      Row.Semantic_Result_Consumed := Consumed;
      Row.Consumer_Reached := Consumer_Reached;
      Row.Stable_Blocker_Family := Stable_Blocker;
      Row.Configuration_Placement_OK := Configuration_Placement_OK;
      Row.Configuration_Target_OK := Configuration_Target_OK;
      Row.Duplicate_Configuration_Pragma := Duplicate_Configuration;
      Row.Conflicting_Configuration_Pragma := Conflicting_Configuration;
      Row.Restriction_Rule_Known := Restriction_Rule_Known;
      Row.Hard_Restriction_Violation := Hard_Restriction;
      Row.Restriction_Warning_Violation := Restriction_Warning;
      Row.Restriction_Warning_Preserved := Restriction_Warning_Preserved;
      Row.Restriction_Warning_Treated_As_Hard_Error := Restriction_Warning_Hard;
      Row.Categorization_Conflict := Categorization_Conflict;
      Row.Dependency_Category_Legal := Dependency_Category_OK;
      Row.Body_Spec_Category_Agrees := Body_Spec_Category_OK;
      Row.Pure_Restrictions_Hold := Pure_OK;
      Row.Preelaborate_Restrictions_Hold := Preelaborate_OK;
      Row.Remote_Types_Category_Legal := Remote_Types_OK;
      Row.Shared_Passive_Category_Legal := Shared_Passive_OK;
      Row.Remote_Call_Interface_Category_Legal := RCI_OK;
      Row.Suppress_Unsuppress_Placement_OK := Suppress_Placement_OK;
      Row.Assert_Expression_Boolean := Assert_Boolean;
      Row.Assertion_Policy_Known := Assertion_Policy_Known;
      Row.Assertion_Runtime_Check := Assertion_Runtime_Check;
      Row.Suppressed_Check_Runtime := Suppressed_Check_Runtime;
      Row.Runtime_Check_Evidence_Preserved := Runtime_Check_Preserved;
      Row.Pack_Target_OK := Pack_Target_OK;
      Row.Inline_No_Inline_Target_OK := Inline_Target_OK;
      Row.Import_Export_Convention_Agrees := Import_Export_Agrees;
      Row.No_Return_Flow_Agrees := No_Return_Agrees;
      Row.Volatile_Atomic_Independent_Agrees := Volatile_Atomic_Agrees;
      Row.Tasking_Consumes_Restrictions := Tasking_Consumes;
      Row.Access_Allocation_Consumes_Restrictions := Access_Consumes;
      Row.Exception_Finalization_Consumes_Restrictions :=
        Exception_Finalization_Consumes;
      Row.Elaboration_Consumes_Categorization := Elaboration_Consumes;
      Row.Local_Slices_Consume_Configuration_Policy := Local_Consumes;
      Row.Consumer_Configuration_Agrees := Consumer_Config_Agrees;
      Row.Consumer_Restriction_Agrees := Consumer_Restriction_Agrees;
      Row.Consumer_Categorization_Agrees := Consumer_Category_Agrees;
      Row.Consumer_Assertion_Agrees := Consumer_Assertion_Agrees;
      Row.Consumer_Warning_State_Surface := Consumer_Warning_Surface;
      Row.Consumer_Diagnostic_Bridge_Agrees := Consumer_Bridge_Agrees;
      Row.Private_View := Private_View;
      Row.Limited_View := Limited_View;
      Row.Incomplete_View := Incomplete_View;
      Row.Generic_Formal_View := Generic_Formal_View;
      Row.Missing_Full_View := Missing_Full_View;
      Row.Missing_Cross_Unit_Evidence := Missing_Cross_Unit;
      Row.Missing_Configuration_Evidence := Missing_Configuration;
      Row.Missing_Categorization_Evidence := Missing_Category;
      Row.Missing_Restriction_Evidence := Missing_Restriction;
      Row.Missing_Policy_Evidence := Missing_Policy;
      Row.Evidence_Stale := Evidence_Stale;
      Row.Expected_Burn_Down_Fingerprint := Expected_Burn_FP;
      Row.Expected_Source_Fingerprint := Expected_Source_FP;
      Row.Expected_AST_Fingerprint := Expected_AST_FP;
      Row.Expected_Unit_Fingerprint := Expected_Unit_FP;
      Row.Expected_Type_Fingerprint := Expected_Type_FP;
      Row.Expected_Profile_Fingerprint := Expected_Profile_FP;
      Row.Expected_Substitution_Fingerprint := Expected_Substitution_FP;
      Row.Expected_Effect_Fingerprint := Expected_Effect_FP;
      Row.Expected_Policy_Fingerprint := Expected_Policy_FP;
      Row.Expected_Category_Fingerprint := Expected_Category_FP;
      Row.Expected_Restriction_Fingerprint := Expected_Restriction_FP;
      Row.Expected_Consumer_Fingerprint := Expected_Consumer_FP;
      Audit.Add_Row (Input, Row);
   end Add_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status;
      Expected : Audit.Precision_Classification) is
      Feed_Item : constant Audit.Burn_Down_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Feed_Item.Status = Status, "unexpected pass1352 status");
      Assert (Audit.Expected_For_Status (Feed_Item.Status) = Expected,
              "unexpected pass1352 classification");
   end Expect_Status;

   procedure Test_Balanced_Pragma_Policy_Gap_Closes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal,
               Construct => Audit.Construct_Configuration_Pragma,
               Context => Audit.Context_Configuration_File);
      Add_Row (Input, 2, Precision.Class_Legal,
               Construct => Audit.Construct_Restriction_Warnings_Pragma,
               Context => Audit.Context_Restriction_Warning,
               Restriction_Warning => True);
      Add_Row (Input, 3, Precision.Class_Legal_With_Runtime_Check,
               Construct => Audit.Construct_Assert_Pragma,
               Context => Audit.Context_Assertion_Policy,
               Assertion_Runtime_Check => True);
      Add_Row (Input, 4, Precision.Class_Legal_With_Runtime_Check,
               Construct => Audit.Construct_Suppress_Pragma,
               Context => Audit.Context_Suppression_Policy,
               Suppressed_Check_Runtime => True);
      Add_Row (Input, 5, Precision.Class_Illegal,
               Construct => Audit.Construct_Restrictions_Pragma,
               Context => Audit.Context_Restriction_Enforcement,
               Hard_Restriction => True);
      Add_Row (Input, 6, Precision.Class_Indeterminate,
               Construct => Audit.Construct_Pure_Pragma,
               Context => Audit.Context_Library_Unit_Category,
               Missing_Configuration => True);

      Results := Audit.Build (Input);
      Assert (Audit.Count (Results) = 6, "all balanced rows retained");
      Assert
        (Audit.Pragma_Configuration_Categorization_Restrictions_Gap_Closed
           (Results),
         "balanced pragma/configuration/categorization gap closes");
      Expect_Status (Results, 1, Audit.Status_Legal_Gap_Burned_Down,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Warning_Restriction_Preserved,
                     Precision.Class_Legal);
      Expect_Status (Results, 3, Audit.Status_Runtime_Assertion_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 4, Audit.Status_Runtime_Suppressed_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 5, Audit.Status_Illegal_Hard_Restriction_Violation,
                     Precision.Class_Illegal);
      Expect_Status (Results, 6,
                     Audit.Status_Indeterminate_Missing_Configuration_Evidence,
                     Precision.Class_Indeterminate);
      Assert (Results.Warning_Count = 1, "warning-only restriction preserved");
      Assert (Results.Runtime_Check_Count = 2, "runtime policy checks preserved");
   end Test_Balanced_Pragma_Policy_Gap_Closes;

   procedure Test_Configuration_Restriction_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 10, Precision.Class_Illegal,
               Configuration_Placement_OK => False);
      Add_Row (Input, 11, Precision.Class_Illegal,
               Configuration_Target_OK => False);
      Add_Row (Input, 12, Precision.Class_Illegal,
               Duplicate_Configuration => True);
      Add_Row (Input, 13, Precision.Class_Illegal,
               Conflicting_Configuration => True);
      Add_Row (Input, 14, Precision.Class_Illegal,
               Restriction_Rule_Known => False);
      Add_Row (Input, 15, Precision.Class_Illegal,
               Restriction_Warning_Hard => True);
      Add_Row (Input, 16, Precision.Class_Unknown,
               Restriction_Warning => True,
               Restriction_Warning_Preserved => False);
      Add_Row (Input, 17, Precision.Class_Illegal,
               Tasking_Consumes => False);
      Add_Row (Input, 18, Precision.Class_Illegal,
               Access_Consumes => False);
      Add_Row (Input, 19, Precision.Class_Illegal,
               Exception_Finalization_Consumes => False);
      Add_Row (Input, 20, Precision.Class_Illegal,
               Local_Consumes => False);

      Results := Audit.Build (Input);
      Expect_Status (Results, 10,
                     Audit.Status_Illegal_Configuration_Pragma_Placement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11,
                     Audit.Status_Illegal_Configuration_Pragma_Target,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12,
                     Audit.Status_Illegal_Duplicate_Configuration_Pragma,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13,
                     Audit.Status_Illegal_Conflicting_Configuration_Pragma,
                     Precision.Class_Illegal);
      Expect_Status (Results, 14, Audit.Status_Illegal_Unknown_Restriction,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 15,
         Audit.Status_Illegal_Restriction_Warning_Treated_As_Hard_Error,
         Precision.Class_Illegal);
      Assert (Audit.Result_For (Results, 16).Status =
              Audit.Status_Warning_Restriction_Evidence_Lost,
              "lost restriction-warning evidence rejected");
      Expect_Status (Results, 17,
                     Audit.Status_Illegal_Task_Restriction_Not_Consumed,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 18,
         Audit.Status_Illegal_Access_Allocation_Restriction_Not_Consumed,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 19,
         Audit.Status_Illegal_Exception_Finalization_Restriction_Not_Consumed,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 20,
         Audit.Status_Illegal_Local_Slice_Ignores_Configuration_Policy,
         Precision.Class_Illegal);
   end Test_Configuration_Restriction_Blockers;

   procedure Test_Categorization_Assertion_Aspect_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 30, Precision.Class_Illegal,
               Construct => Audit.Construct_Pure_Pragma,
               Context => Audit.Context_Library_Unit_Category,
               Categorization_Conflict => True);
      Add_Row (Input, 31, Precision.Class_Illegal,
               Dependency_Category_OK => False);
      Add_Row (Input, 32, Precision.Class_Illegal,
               Body_Spec_Category_OK => False);
      Add_Row (Input, 33, Precision.Class_Illegal,
               Pure_OK => False);
      Add_Row (Input, 34, Precision.Class_Illegal,
               Preelaborate_OK => False);
      Add_Row (Input, 35, Precision.Class_Illegal,
               Remote_Types_OK => False);
      Add_Row (Input, 36, Precision.Class_Illegal,
               Shared_Passive_OK => False);
      Add_Row (Input, 37, Precision.Class_Illegal,
               RCI_OK => False);
      Add_Row (Input, 38, Precision.Class_Illegal,
               Suppress_Placement_OK => False);
      Add_Row (Input, 39, Precision.Class_Illegal,
               Assert_Boolean => False);
      Add_Row (Input, 40, Precision.Class_Illegal,
               Assertion_Policy_Known => False);
      Add_Row (Input, 41, Precision.Class_Illegal,
               Pack_Target_OK => False);
      Add_Row (Input, 42, Precision.Class_Illegal,
               Inline_Target_OK => False);
      Add_Row (Input, 43, Precision.Class_Illegal,
               Import_Export_Agrees => False);
      Add_Row (Input, 44, Precision.Class_Illegal,
               No_Return_Agrees => False);
      Add_Row (Input, 45, Precision.Class_Illegal,
               Volatile_Atomic_Agrees => False);

      Results := Audit.Build (Input);
      Expect_Status (Results, 30, Audit.Status_Illegal_Categorization_Conflict,
                     Precision.Class_Illegal);
      Expect_Status (Results, 31, Audit.Status_Illegal_Dependency_Category,
                     Precision.Class_Illegal);
      Expect_Status (Results, 32,
                     Audit.Status_Illegal_Body_Spec_Category_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 33,
                     Audit.Status_Illegal_Pure_Restriction_Violation,
                     Precision.Class_Illegal);
      Expect_Status (Results, 34,
                     Audit.Status_Illegal_Preelaborate_Restriction_Violation,
                     Precision.Class_Illegal);
      Expect_Status (Results, 35,
                     Audit.Status_Illegal_Remote_Types_Category_Violation,
                     Precision.Class_Illegal);
      Expect_Status (Results, 36,
                     Audit.Status_Illegal_Shared_Passive_Category_Violation,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 37,
         Audit.Status_Illegal_Remote_Call_Interface_Category_Violation,
         Precision.Class_Illegal);
      Expect_Status (Results, 38,
                     Audit.Status_Illegal_Suppress_Unsuppress_Placement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 39,
                     Audit.Status_Illegal_Assert_Expression_Not_Boolean,
                     Precision.Class_Illegal);
      Expect_Status (Results, 40, Audit.Status_Illegal_Unknown_Assertion_Policy,
                     Precision.Class_Illegal);
      Expect_Status (Results, 41, Audit.Status_Illegal_Pack_Target,
                     Precision.Class_Illegal);
      Expect_Status (Results, 42, Audit.Status_Illegal_Inline_No_Inline_Target,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 43,
         Audit.Status_Illegal_Import_Export_Convention_Disagreement,
         Precision.Class_Illegal);
      Expect_Status (Results, 44,
                     Audit.Status_Illegal_No_Return_Flow_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 45,
         Audit.Status_Illegal_Volatile_Atomic_Independent_Disagreement,
         Precision.Class_Illegal);
   end Test_Categorization_Assertion_Aspect_Blockers;

   procedure Test_Indeterminate_Consumers_And_Audit_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 50, Precision.Class_Indeterminate, Private_View => True);
      Add_Row (Input, 51, Precision.Class_Indeterminate, Limited_View => True);
      Add_Row (Input, 52, Precision.Class_Indeterminate, Incomplete_View => True);
      Add_Row (Input, 53, Precision.Class_Indeterminate,
               Generic_Formal_View => True);
      Add_Row (Input, 54, Precision.Class_Indeterminate,
               Missing_Full_View => True);
      Add_Row (Input, 55, Precision.Class_Indeterminate,
               Missing_Cross_Unit => True);
      Add_Row (Input, 56, Precision.Class_Indeterminate,
               Missing_Configuration => True);
      Add_Row (Input, 57, Precision.Class_Indeterminate,
               Missing_Category => True);
      Add_Row (Input, 58, Precision.Class_Indeterminate,
               Missing_Restriction => True);
      Add_Row (Input, 59, Precision.Class_Indeterminate, Missing_Policy => True);
      Add_Row (Input, 60, Precision.Class_Unknown, Source_Shaped => False);
      Add_Row (Input, 61, Precision.Class_Unknown, Remediation_Present => False);
      Add_Row (Input, 62, Precision.Class_Unknown, Matrix_Present => False);
      Add_Row (Input, 63, Precision.Class_Unknown, Package_Present => False);
      Add_Row (Input, 64, Precision.Class_Unknown, New_Rule => False);
      Add_Row (Input, 65, Precision.Class_Unknown, Coverage_Updated => False);
      Add_Row (Input, 66, Precision.Class_Unknown, Corpus_Balanced => False);
      Add_Row (Input, 67, Precision.Class_Unknown, Consumed => False);
      Add_Row (Input, 68, Precision.Class_Unknown, Consumer_Reached => False);
      Add_Row (Input, 69, Precision.Class_Unknown, Stable_Blocker => False);
      Add_Row (Input, 70, Precision.Class_Unknown,
               Consumer_Config_Agrees => False);
      Add_Row (Input, 71, Precision.Class_Unknown,
               Consumer_Restriction_Agrees => False);
      Add_Row (Input, 72, Precision.Class_Unknown,
               Consumer_Category_Agrees => False);
      Add_Row (Input, 73, Precision.Class_Unknown,
               Consumer_Assertion_Agrees => False);
      Add_Row (Input, 74, Precision.Class_Unknown,
               Consumer_Warning_Surface => False);
      Add_Row (Input, 75, Precision.Class_Unknown,
               Consumer_Bridge_Agrees => False);
      Add_Row (Input, 76, Precision.Class_Unknown, Evidence_Stale => True);
      Add_Row (Input, 77, Precision.Class_Unknown, Expected_Source_FP => 7);
      Add_Row (Input, 78, Precision.Class_Unknown, Expected_Unit_FP => 7);
      Add_Row (Input, 79, Precision.Class_Unknown, Expected_Policy_FP => 7);
      Add_Row (Input, 80, Precision.Class_Unknown, Expected_Category_FP => 7);
      Add_Row (Input, 81, Precision.Class_Unknown, Expected_Restriction_FP => 7);
      Add_Row (Input, 82, Precision.Class_Unknown, Expected_Consumer_FP => 7);

      Results := Audit.Build (Input);
      Expect_Status (Results, 50, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 51, Audit.Status_Indeterminate_Limited_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 52, Audit.Status_Indeterminate_Incomplete_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 53,
                     Audit.Status_Indeterminate_Generic_Formal_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 54,
                     Audit.Status_Indeterminate_Missing_Full_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 55,
                     Audit.Status_Indeterminate_Missing_Cross_Unit_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 56,
                     Audit.Status_Indeterminate_Missing_Configuration_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 57,
                     Audit.Status_Indeterminate_Missing_Categorization_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 58,
                     Audit.Status_Indeterminate_Missing_Restriction_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 59,
                     Audit.Status_Indeterminate_Missing_Policy_Evidence,
                     Precision.Class_Indeterminate);
      Assert (Audit.Result_For (Results, 60).Status =
              Audit.Status_Source_Shaped_Evidence_Missing,
              "non-source-shaped policy evidence rejected");
      Assert (Audit.Result_For (Results, 61).Status =
              Audit.Status_Missing_Remediation_Evidence,
              "missing remediation evidence rejected");
      Assert (Audit.Result_For (Results, 62).Status =
              Audit.Status_Missing_Matrix_Coverage,
              "missing matrix coverage rejected");
      Assert (Audit.Result_For (Results, 63).Status =
              Audit.Status_Missing_Implementing_Package,
              "missing package ownership rejected");
      Assert (Audit.Result_For (Results, 64).Status =
              Audit.Status_No_New_Legality_Rule,
              "burn-down without new policy rule rejected");
      Assert (Audit.Result_For (Results, 65).Status =
              Audit.Status_Coverage_Not_Updated_To_Covered,
              "coverage promotion gate enforced");
      Assert (Audit.Result_For (Results, 66).Status =
              Audit.Status_Regression_Corpus_Not_Balanced,
              "unbalanced policy corpus rejected");
      Assert (Audit.Result_For (Results, 67).Status =
              Audit.Status_Semantic_Result_Unconsumed,
              "unconsumed policy result rejected");
      Assert (Audit.Result_For (Results, 68).Status =
              Audit.Status_Consumer_Not_Reached,
              "unsurfaced policy consumer rejected");
      Assert (Audit.Result_For (Results, 69).Status =
              Audit.Status_Unstable_Blocker_Family,
              "unstable policy blocker rejected");
      Assert (Audit.Result_For (Results, 70).Status =
              Audit.Status_Consumer_Configuration_Model_Disagreement,
              "configuration consumer disagreement rejected");
      Assert (Audit.Result_For (Results, 71).Status =
              Audit.Status_Consumer_Restriction_Model_Disagreement,
              "restriction consumer disagreement rejected");
      Assert (Audit.Result_For (Results, 72).Status =
              Audit.Status_Consumer_Categorization_Model_Disagreement,
              "categorization consumer disagreement rejected");
      Assert (Audit.Result_For (Results, 73).Status =
              Audit.Status_Consumer_Assertion_Model_Disagreement,
              "assertion consumer disagreement rejected");
      Assert (Audit.Result_For (Results, 74).Status =
              Audit.Status_Consumer_Warning_State_Hidden,
              "warning state must be surfaced");
      Assert (Audit.Result_For (Results, 75).Status =
              Audit.Status_Consumer_Diagnostic_Bridge_Disagreement,
              "diagnostic bridge disagreement rejected");
      Assert (Audit.Result_For (Results, 76).Status =
              Audit.Status_Stale_Burn_Down_Fingerprint,
              "stale policy evidence rejected");
      Assert (Audit.Result_For (Results, 77).Status =
              Audit.Status_Source_Fingerprint_Mismatch,
              "source fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 78).Status =
              Audit.Status_Unit_Fingerprint_Mismatch,
              "unit fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 79).Status =
              Audit.Status_Policy_Fingerprint_Mismatch,
              "policy fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 80).Status =
              Audit.Status_Category_Fingerprint_Mismatch,
              "category fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 81).Status =
              Audit.Status_Restriction_Fingerprint_Mismatch,
              "restriction fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 82).Status =
              Audit.Status_Consumer_Fingerprint_Mismatch,
              "consumer fingerprint mismatch rejected");
   end Test_Indeterminate_Consumers_And_Audit_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Pragma_Policy_Gap_Closes'Access,
         "balanced pragma/configuration/categorization gap closure");
      Register_Routine
        (T, Test_Configuration_Restriction_Blockers'Access,
         "configuration and restriction blockers");
      Register_Routine
        (T, Test_Categorization_Assertion_Aspect_Blockers'Access,
         "categorization assertion and aspect blockers");
      Register_Routine
        (T, Test_Indeterminate_Consumers_And_Audit_Gates'Access,
         "indeterminate consumers and policy audit gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1352;
