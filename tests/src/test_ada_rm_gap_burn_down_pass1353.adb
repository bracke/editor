with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_RM_Gap_Burn_Down_Pass1353;

package body Test_Ada_RM_Gap_Burn_Down_Pass1353 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1353;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Access_Construct_Kind;
   use type Audit.Memory_Context_Kind;
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
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1353");
   end Name;

   procedure Add_Row
     (Input : in out Audit.Burn_Down_Input;
      Id : Natural;
      Expected : Audit.Precision_Classification;
      Gap : Audit.Burn_Down_Gap :=
        Audit.Gap_Allocator_Storage_Pool_Unchecked_Operations;
      Construct : Audit.Access_Construct_Kind :=
        Audit.Construct_Initialized_Allocator;
      Context : Audit.Memory_Context_Kind := Audit.Context_Access_Type;
      Family : Audit.RM_Family := Matrix.Family_Access_Types_Accessibility;
      Owner : Audit.Implementing_Slice :=
        Matrix.Slice_Access_Type_Access_Subprogram;
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
      Designated_Present : Boolean := True;
      Designated_Available : Boolean := True;
      Limited_Allocator_OK : Boolean := True;
      Controlled_Finalized_OK : Boolean := True;
      Null_Exclusion : Boolean := False;
      Pool_Present : Boolean := True;
      Pool_Conflict : Boolean := False;
      Storage_Static : Boolean := True;
      Storage_Compatible : Boolean := True;
      Pool_Frozen : Boolean := False;
      Pool_Constraints_OK : Boolean := True;
      Representation_Agrees : Boolean := True;
      Allocator_Consumes_Rep : Boolean := True;
      Access_Conversion_OK : Boolean := True;
      Access_Discriminant_Escape : Boolean := False;
      Anonymous_Access_Escape : Boolean := False;
      Generic_Substitution_OK : Boolean := True;
      Static_Access_Escape : Boolean := False;
      Runtime_Access_Check : Boolean := False;
      Runtime_Constraint_Check : Boolean := False;
      Runtime_Check_Preserved : Boolean := True;
      Unchecked_Conversion_Profile_OK : Boolean := True;
      Unchecked_Size_View : Boolean := True;
      Unchecked_Deallocation_Access_OK : Boolean := True;
      Unchecked_Deallocation_Finalization_OK : Boolean := True;
      Restriction_Known : Boolean := True;
      No_Allocators_Violation : Boolean := False;
      Allocation_Warning : Boolean := False;
      Warning_Preserved : Boolean := True;
      Warning_Treated_Hard : Boolean := False;
      Access_Consumes_Policy : Boolean := True;
      Finalization_Consumes : Boolean := True;
      Generic_Replay_Consumes : Boolean := True;
      Consumer_Storage_Agrees : Boolean := True;
      Consumer_Lifetime_Agrees : Boolean := True;
      Consumer_Unchecked_Agrees : Boolean := True;
      Consumer_Policy_Agrees : Boolean := True;
      Consumer_Warning_Surface : Boolean := True;
      Consumer_Bridge_Agrees : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit : Boolean := False;
      Missing_Designated : Boolean := False;
      Missing_Pool : Boolean := False;
      Missing_Lifetime : Boolean := False;
      Missing_Unchecked_Profile : Boolean := False;
      Missing_Size_View : Boolean := False;
      Missing_Policy : Boolean := False;
      Evidence_Stale : Boolean := False;
      Expected_Burn_FP : Natural := 0;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0;
      Expected_Policy_FP : Natural := 0;
      Expected_Pool_FP : Natural := 0;
      Expected_Lifetime_FP : Natural := 0;
      Expected_Representation_FP : Natural := 0;
      Expected_Consumer_FP : Natural := 0) is
      Row : Audit.Burn_Down_Row;
   begin
      Row.Id := Id;
      Row.Gap := Gap;
      Row.Family := Family;
      Row.Owner := Owner;
      Row.Previous_State := Remediation.State_Partial;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Construct := Construct;
      Row.Context := Context;
      Row.Name := To_Unbounded_String ("pass1353 source-shaped row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1353");
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
      Row.Designated_Subtype_Present := Designated_Present;
      Row.Designated_Subtype_Available := Designated_Available;
      Row.Limited_Type_Allocation_Allowed := Limited_Allocator_OK;
      Row.Controlled_Finalized_Allocation_Safe := Controlled_Finalized_OK;
      Row.Null_Exclusion_Violation := Null_Exclusion;
      Row.Storage_Pool_Present := Pool_Present;
      Row.Storage_Pool_Conflict := Pool_Conflict;
      Row.Storage_Size_Static := Storage_Static;
      Row.Storage_Size_Compatible := Storage_Compatible;
      Row.Storage_Pool_Frozen := Pool_Frozen;
      Row.Pool_Specific_Constraints_OK := Pool_Constraints_OK;
      Row.Representation_Freezing_Agrees := Representation_Agrees;
      Row.Allocator_Consumes_Representation := Allocator_Consumes_Rep;
      Row.Access_Conversion_Compatible := Access_Conversion_OK;
      Row.Access_Discriminant_Escape := Access_Discriminant_Escape;
      Row.Anonymous_Access_Assignment_Escape := Anonymous_Access_Escape;
      Row.Generic_Access_Substitution_Agrees := Generic_Substitution_OK;
      Row.Static_Accessibility_Escape := Static_Access_Escape;
      Row.Runtime_Accessibility_Check := Runtime_Access_Check;
      Row.Runtime_Constraint_Check := Runtime_Constraint_Check;
      Row.Runtime_Check_Evidence_Preserved := Runtime_Check_Preserved;
      Row.Unchecked_Conversion_Profile_OK := Unchecked_Conversion_Profile_OK;
      Row.Unchecked_Conversion_Size_View_Evidence := Unchecked_Size_View;
      Row.Unchecked_Deallocation_Access_Type_OK :=
        Unchecked_Deallocation_Access_OK;
      Row.Unchecked_Deallocation_Finalization_Safe :=
        Unchecked_Deallocation_Finalization_OK;
      Row.Restriction_Rule_Known := Restriction_Known;
      Row.No_Allocators_Restriction_Violation := No_Allocators_Violation;
      Row.Allocation_Restriction_Warning := Allocation_Warning;
      Row.Restriction_Warning_Preserved := Warning_Preserved;
      Row.Restriction_Warning_Treated_As_Hard_Error := Warning_Treated_Hard;
      Row.Access_Slice_Consumes_Policy := Access_Consumes_Policy;
      Row.Finalization_Consumes_Allocation_Evidence := Finalization_Consumes;
      Row.Generic_Replay_Consumes_Access_Actual := Generic_Replay_Consumes;
      Row.Consumer_Storage_Agrees := Consumer_Storage_Agrees;
      Row.Consumer_Lifetime_Agrees := Consumer_Lifetime_Agrees;
      Row.Consumer_Unchecked_Operation_Agrees := Consumer_Unchecked_Agrees;
      Row.Consumer_Policy_Agrees := Consumer_Policy_Agrees;
      Row.Consumer_Warning_State_Surface := Consumer_Warning_Surface;
      Row.Consumer_Diagnostic_Bridge_Agrees := Consumer_Bridge_Agrees;
      Row.Private_View := Private_View;
      Row.Limited_View := Limited_View;
      Row.Incomplete_View := Incomplete_View;
      Row.Generic_Formal_View := Generic_Formal_View;
      Row.Missing_Full_View := Missing_Full_View;
      Row.Missing_Cross_Unit_Evidence := Missing_Cross_Unit;
      Row.Missing_Designated_Subtype_Evidence := Missing_Designated;
      Row.Missing_Storage_Pool_Evidence := Missing_Pool;
      Row.Missing_Lifetime_Evidence := Missing_Lifetime;
      Row.Missing_Unchecked_Profile_Evidence := Missing_Unchecked_Profile;
      Row.Missing_Size_View_Evidence := Missing_Size_View;
      Row.Missing_Policy_Evidence := Missing_Policy;
      Row.Evidence_Stale := Evidence_Stale;
      Row.Expected_Burn_Down_Fingerprint := Expected_Burn_FP;
      Row.Expected_Source_Fingerprint := Expected_Source_FP;
      Row.Expected_AST_Fingerprint := Expected_AST_FP;
      Row.Expected_Type_Fingerprint := Expected_Type_FP;
      Row.Expected_Profile_Fingerprint := Expected_Profile_FP;
      Row.Expected_Substitution_Fingerprint := Expected_Substitution_FP;
      Row.Expected_Effect_Fingerprint := Expected_Effect_FP;
      Row.Expected_Policy_Fingerprint := Expected_Policy_FP;
      Row.Expected_Storage_Pool_Fingerprint := Expected_Pool_FP;
      Row.Expected_Lifetime_Fingerprint := Expected_Lifetime_FP;
      Row.Expected_Representation_Fingerprint := Expected_Representation_FP;
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
      Assert (Feed_Item.Status = Status, "unexpected pass1353 status");
      Assert (Audit.Expected_For_Status (Feed_Item.Status) = Expected,
              "unexpected pass1353 classification");
   end Expect_Status;

   procedure Test_Balanced_Allocator_Gap_Closes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal,
               Construct => Audit.Construct_Initialized_Allocator);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Construct => Audit.Construct_No_Allocators_Restriction,
               Context => Audit.Context_Restriction_Enforcement,
               No_Allocators_Violation => True);
      Add_Row (Input, 3, Precision.Class_Legal,
               Construct => Audit.Construct_No_Allocators_Restriction,
               Context => Audit.Context_Restriction_Warning,
               Allocation_Warning => True,
               Warning_Preserved => True);
      Add_Row (Input, 4, Precision.Class_Legal_With_Runtime_Check,
               Construct => Audit.Construct_Anonymous_Access_Assignment,
               Runtime_Access_Check => True);
      Add_Row (Input, 5, Precision.Class_Indeterminate,
               Missing_Pool => True);
      Add_Row (Input, 6, Precision.Class_Illegal,
               Construct => Audit.Construct_Unchecked_Deallocation_Instantiation,
               Unchecked_Deallocation_Access_OK => False);

      Results := Audit.Build (Input);

      Assert (Audit.Allocator_Storage_Pool_Unchecked_Operations_Gap_Closed
                (Results),
              "balanced allocator/storage/unchecked-operation gap closes");
      Assert (Results.Legal_Count = 2, "legal and warning rows counted");
      Assert (Results.Illegal_Count = 2, "illegal rows counted");
      Assert (Results.Runtime_Check_Count = 1, "runtime-check row counted");
      Assert (Results.Indeterminate_Count = 1, "indeterminate row counted");
      Expect_Status (Results, 1, Audit.Status_Legal_Gap_Burned_Down,
                     Precision.Class_Legal);
      Expect_Status (Results, 2,
                     Audit.Status_Illegal_Restriction_No_Allocators_Violation,
                     Precision.Class_Illegal);
      Expect_Status (Results, 3,
                     Audit.Status_Warning_Allocation_Restriction_Preserved,
                     Precision.Class_Legal);
      Expect_Status (Results, 4,
                     Audit.Status_Runtime_Accessibility_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 5,
                     Audit.Status_Indeterminate_Missing_Storage_Pool_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status
        (Results, 6,
         Audit.Status_Illegal_Unchecked_Deallocation_Incompatible_Access_Type,
         Precision.Class_Illegal);
   end Test_Balanced_Allocator_Gap_Closes;

   procedure Test_Allocator_Storage_And_Lifetime_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 10, Precision.Class_Illegal,
               Designated_Present => False);
      Add_Row (Input, 11, Precision.Class_Illegal,
               Designated_Available => False);
      Add_Row (Input, 12, Precision.Class_Illegal,
               Construct => Audit.Construct_Limited_Type_Allocator,
               Limited_Allocator_OK => False);
      Add_Row (Input, 13, Precision.Class_Illegal,
               Controlled_Finalized_OK => False);
      Add_Row (Input, 14, Precision.Class_Illegal,
               Null_Exclusion => True);
      Add_Row (Input, 15, Precision.Class_Illegal,
               Pool_Present => False);
      Add_Row (Input, 16, Precision.Class_Illegal,
               Pool_Conflict => True);
      Add_Row (Input, 17, Precision.Class_Illegal,
               Storage_Static => False);
      Add_Row (Input, 18, Precision.Class_Illegal,
               Storage_Compatible => False);
      Add_Row (Input, 19, Precision.Class_Illegal,
               Pool_Frozen => True);
      Add_Row (Input, 20, Precision.Class_Illegal,
               Pool_Constraints_OK => False);
      Add_Row (Input, 21, Precision.Class_Illegal,
               Representation_Agrees => False);
      Add_Row (Input, 22, Precision.Class_Illegal,
               Access_Conversion_OK => False);
      Add_Row (Input, 23, Precision.Class_Illegal,
               Static_Access_Escape => True);
      Add_Row (Input, 24, Precision.Class_Illegal,
               Access_Discriminant_Escape => True);
      Add_Row (Input, 25, Precision.Class_Illegal,
               Anonymous_Access_Escape => True);

      Results := Audit.Build (Input);

      Expect_Status
        (Results, 10,
         Audit.Status_Illegal_Allocator_Missing_Designated_Subtype,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 11,
         Audit.Status_Illegal_Allocator_Designated_Subtype_Unavailable,
         Precision.Class_Illegal);
      Expect_Status (Results, 12, Audit.Status_Illegal_Limited_Type_Allocator,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 13,
         Audit.Status_Illegal_Controlled_Finalized_Allocator_Hazard,
         Precision.Class_Illegal);
      Expect_Status (Results, 14, Audit.Status_Illegal_Null_Exclusion_Violation,
                     Precision.Class_Illegal);
      Expect_Status (Results, 15, Audit.Status_Illegal_Storage_Pool_Missing,
                     Precision.Class_Illegal);
      Expect_Status (Results, 16, Audit.Status_Illegal_Storage_Pool_Conflict,
                     Precision.Class_Illegal);
      Expect_Status (Results, 17, Audit.Status_Illegal_Storage_Size_Not_Static,
                     Precision.Class_Illegal);
      Expect_Status (Results, 18, Audit.Status_Illegal_Storage_Size_Incompatible,
                     Precision.Class_Illegal);
      Expect_Status (Results, 19, Audit.Status_Illegal_Storage_Pool_Frozen,
                     Precision.Class_Illegal);
      Expect_Status (Results, 20, Audit.Status_Illegal_Storage_Pool_Constraint,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 21, Audit.Status_Illegal_Representation_Freezing_Disagreement,
         Precision.Class_Illegal);
      Expect_Status (Results, 22,
                     Audit.Status_Illegal_Access_Conversion_Incompatible,
                     Precision.Class_Illegal);
      Expect_Status (Results, 23,
                     Audit.Status_Illegal_Static_Accessibility_Escape,
                     Precision.Class_Illegal);
      Expect_Status (Results, 24,
                     Audit.Status_Illegal_Access_Discriminant_Escape,
                     Precision.Class_Illegal);
      Expect_Status (Results, 25,
                     Audit.Status_Illegal_Anonymous_Access_Assignment_Escape,
                     Precision.Class_Illegal);
   end Test_Allocator_Storage_And_Lifetime_Blockers;

   procedure Test_Unchecked_Generic_Restriction_And_Consumer_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 30, Precision.Class_Illegal,
               Generic_Substitution_OK => False);
      Add_Row (Input, 31, Precision.Class_Illegal,
               Construct => Audit.Construct_Unchecked_Conversion_Instantiation,
               Unchecked_Conversion_Profile_OK => False);
      Add_Row (Input, 32, Precision.Class_Indeterminate,
               Construct => Audit.Construct_Unchecked_Conversion_Instantiation,
               Unchecked_Size_View => False);
      Add_Row (Input, 33, Precision.Class_Illegal,
               Construct => Audit.Construct_Unchecked_Deallocation_Instantiation,
               Unchecked_Deallocation_Finalization_OK => False);
      Add_Row (Input, 34, Precision.Class_Illegal,
               Restriction_Known => False);
      Add_Row (Input, 35, Precision.Class_Illegal,
               Warning_Treated_Hard => True);
      Add_Row (Input, 36, Precision.Class_Illegal,
               Access_Consumes_Policy => False);
      Add_Row (Input, 37, Precision.Class_Illegal,
               Generic_Replay_Consumes => False);
      Add_Row (Input, 38, Precision.Class_Illegal,
               Finalization_Consumes => False);
      Add_Row (Input, 39, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Constraint_Check => True);
      Add_Row (Input, 40, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Constraint_Check => True,
               Runtime_Check_Preserved => False);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30,
                     Audit.Status_Illegal_Generic_Access_Substitution_Mismatch,
                     Precision.Class_Illegal);
      Expect_Status (Results, 31,
                     Audit.Status_Illegal_Unchecked_Conversion_Profile,
                     Precision.Class_Illegal);
      Expect_Status (Results, 32,
                     Audit.Status_Indeterminate_Missing_Size_View_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status
        (Results, 33,
         Audit.Status_Illegal_Unchecked_Deallocation_Controlled_Finalized_Hazard,
         Precision.Class_Illegal);
      Expect_Status (Results, 34, Audit.Status_Illegal_Unknown_Restriction,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 35,
         Audit.Status_Illegal_Restriction_Warning_Treated_As_Hard_Error,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 36,
         Audit.Status_Illegal_Local_Slice_Ignores_Allocation_Policy,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 37,
         Audit.Status_Illegal_Generic_Replay_Access_Substitution_Lost,
         Precision.Class_Illegal);
      Expect_Status (Results, 38,
                     Audit.Status_Illegal_Finalization_Evidence_Disagreement,
                     Precision.Class_Illegal);
      Expect_Status (Results, 39,
                     Audit.Status_Runtime_Constraint_Check_Preserved,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 40, Audit.Status_Runtime_Check_Evidence_Lost,
                     Precision.Class_Legal_With_Runtime_Check);
   end Test_Unchecked_Generic_Restriction_And_Consumer_Blockers;

   procedure Test_Indeterminate_Consumer_And_Audit_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 50, Precision.Class_Indeterminate, Private_View => True);
      Add_Row (Input, 51, Precision.Class_Indeterminate, Limited_View => True);
      Add_Row (Input, 52, Precision.Class_Indeterminate,
               Missing_Designated => True);
      Add_Row (Input, 53, Precision.Class_Indeterminate,
               Missing_Lifetime => True);
      Add_Row (Input, 54, Precision.Class_Indeterminate,
               Missing_Unchecked_Profile => True);
      Add_Row (Input, 55, Precision.Class_Unknown,
               Source_Shaped => False);
      Add_Row (Input, 56, Precision.Class_Unknown,
               Remediation_Present => False);
      Add_Row (Input, 57, Precision.Class_Unknown,
               Consumed => False);
      Add_Row (Input, 58, Precision.Class_Unknown,
               Consumer_Storage_Agrees => False);
      Add_Row (Input, 59, Precision.Class_Unknown,
               Consumer_Lifetime_Agrees => False);
      Add_Row (Input, 60, Precision.Class_Unknown,
               Consumer_Unchecked_Agrees => False);
      Add_Row (Input, 61, Precision.Class_Unknown,
               Consumer_Policy_Agrees => False);
      Add_Row (Input, 62, Precision.Class_Unknown,
               Consumer_Warning_Surface => False);
      Add_Row (Input, 63, Precision.Class_Unknown,
               Consumer_Bridge_Agrees => False);
      Add_Row (Input, 64, Precision.Class_Unknown,
               Evidence_Stale => True);
      Add_Row (Input, 65, Precision.Class_Unknown,
               Expected_Pool_FP => 99);
      Add_Row (Input, 66, Precision.Class_Unknown,
               Expected_Lifetime_FP => 99);
      Add_Row (Input, 67, Precision.Class_Unknown,
               Expected_Representation_FP => 99);
      Add_Row (Input, 68, Precision.Class_Unknown,
               Expected_Consumer_FP => 99);

      Results := Audit.Build (Input);

      Expect_Status (Results, 50, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 51, Audit.Status_Indeterminate_Limited_View,
                     Precision.Class_Indeterminate);
      Expect_Status
        (Results, 52,
         Audit.Status_Indeterminate_Missing_Designated_Subtype_Evidence,
         Precision.Class_Indeterminate);
      Expect_Status (Results, 53,
                     Audit.Status_Indeterminate_Missing_Lifetime_Evidence,
                     Precision.Class_Indeterminate);
      Expect_Status
        (Results, 54,
         Audit.Status_Indeterminate_Missing_Unchecked_Profile_Evidence,
         Precision.Class_Indeterminate);
      Assert (Audit.Result_For (Results, 55).Status =
              Audit.Status_Source_Shaped_Evidence_Missing,
              "non-source-shaped allocation evidence rejected");
      Assert (Audit.Result_For (Results, 56).Status =
              Audit.Status_Missing_Remediation_Evidence,
              "missing allocation remediation evidence rejected");
      Assert (Audit.Result_For (Results, 57).Status =
              Audit.Status_Semantic_Result_Unconsumed,
              "unconsumed allocation result rejected");
      Assert (Audit.Result_For (Results, 58).Status =
              Audit.Status_Consumer_Storage_Model_Disagreement,
              "storage consumer disagreement rejected");
      Assert (Audit.Result_For (Results, 59).Status =
              Audit.Status_Consumer_Lifetime_Model_Disagreement,
              "lifetime consumer disagreement rejected");
      Assert (Audit.Result_For (Results, 60).Status =
              Audit.Status_Consumer_Unchecked_Operation_Model_Disagreement,
              "unchecked-operation consumer disagreement rejected");
      Assert (Audit.Result_For (Results, 61).Status =
              Audit.Status_Consumer_Policy_Model_Disagreement,
              "policy consumer disagreement rejected");
      Assert (Audit.Result_For (Results, 62).Status =
              Audit.Status_Consumer_Warning_State_Hidden,
              "warning-only allocation policy must surface");
      Assert (Audit.Result_For (Results, 63).Status =
              Audit.Status_Consumer_Diagnostic_Bridge_Disagreement,
              "diagnostic bridge disagreement rejected");
      Assert (Audit.Result_For (Results, 64).Status =
              Audit.Status_Stale_Burn_Down_Fingerprint,
              "stale allocation evidence rejected");
      Assert (Audit.Result_For (Results, 65).Status =
              Audit.Status_Storage_Pool_Fingerprint_Mismatch,
              "storage-pool fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 66).Status =
              Audit.Status_Lifetime_Fingerprint_Mismatch,
              "lifetime fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 67).Status =
              Audit.Status_Representation_Fingerprint_Mismatch,
              "representation fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 68).Status =
              Audit.Status_Consumer_Fingerprint_Mismatch,
              "consumer fingerprint mismatch rejected");
   end Test_Indeterminate_Consumer_And_Audit_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Allocator_Gap_Closes'Access,
         "balanced allocator storage unchecked-operation gap closure");
      Register_Routine
        (T, Test_Allocator_Storage_And_Lifetime_Blockers'Access,
         "allocator storage and lifetime blockers");
      Register_Routine
        (T, Test_Unchecked_Generic_Restriction_And_Consumer_Blockers'Access,
         "unchecked generic restriction and consumer blockers");
      Register_Routine
        (T, Test_Indeterminate_Consumer_And_Audit_Gates'Access,
         "indeterminate consumer and allocator audit gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1353;
