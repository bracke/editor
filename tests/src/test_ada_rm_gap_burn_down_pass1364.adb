with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Gap_Burn_Down_Pass1364;

package body Test_Ada_RM_Gap_Burn_Down_Pass1364 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1364;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Span_Kind;
   use type Audit.Blocker_Precision;
   use type Audit.Diagnostic_Role;
   use type Audit.Burn_Down_Status;
   use type Audit.Burn_Down_Row;
   use type Audit.Burn_Down_Input;
   use type Audit.Burn_Down_Entry;
   use type Audit.Burn_Down_Model;
   package Matrix renames Audit.Matrix;
   package Remediation renames Audit.Remediation;
   package Consumers renames Audit.Consumers;
   package Precision renames Audit.Precision;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1364");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification;
      Span : Audit.Span_Kind;
      Blocker : Audit.Blocker_Precision;
      Diagnostic_Kind : Audit.Diagnostic_Role;
      Gap : Audit.Burn_Down_Gap := Audit.Gap_Diagnostic_Blocker_Source_Span_Closure;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics)
      return Audit.Burn_Down_Row is
      Row : Audit.Burn_Down_Row;
   begin
      Row.Id := Id;
      Row.Gap := Gap;
      Row.Family := Matrix.Family_Diagnostics_Consumer_Readiness;
      Row.Owner := Matrix.Slice_Semantic_Integration_Audit;
      Row.Previous_State := Remediation.State_Partial;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Span := Span;
      Row.Blocker := Blocker;
      Row.Diagnostic_Kind := Diagnostic_Kind;
      Row.Diagnostic_Key := To_Unbounded_String ("P1364" & Natural'Image (Id));
      Row.Blocker_Family := To_Unbounded_String ("RM.P1364.Source_Span");
      Row.Source_File := To_Unbounded_String ("src/project-root.adb");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1364");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Burn_Down_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1364 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1364 classification");
   end Expect_Status;

   procedure Test_Balanced_Diagnostic_Closure

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row
        (1, Precision.Class_Illegal, Audit.Span_Association,
         Audit.Blocker_Precise_RM_Family, Audit.Role_Primary,
         Audit.Gap_Diagnostic_Blocker_Source_Span_Closure,
         Consumers.Consumer_Diagnostics);
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (2, Precision.Class_Legal_With_Runtime_Check, Audit.Span_Actual,
         Audit.Blocker_Runtime_Check, Audit.Role_Primary,
         Audit.Gap_Diagnostic_Blocker_Source_Span_Closure,
         Consumers.Consumer_Hover_Details);
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (3, Precision.Class_Illegal, Audit.Span_Attribute,
         Audit.Blocker_Warning_Only, Audit.Role_Primary,
         Audit.Gap_Diagnostic_Blocker_Source_Span_Closure,
         Consumers.Consumer_Build_Diagnostic_Bridge);
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (4, Precision.Class_Indeterminate, Audit.Span_Recovered_Partial,
         Audit.Blocker_Indeterminate, Audit.Role_Recovered_Syntax,
         Audit.Gap_Diagnostic_Blocker_Source_Span_Closure,
         Consumers.Consumer_Semantic_Colouring);
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (5, Precision.Class_Legal, Audit.Span_Operator,
         Audit.Blocker_Precise_RM_Family, Audit.Role_Secondary_Evidence,
         Audit.Gap_Diagnostic_Deduplication_Ordering,
         Consumers.Consumer_Outline_Model);
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (6, Precision.Class_Legal, Audit.Span_Selector,
         Audit.Blocker_Precise_RM_Family, Audit.Role_Consumer_State,
         Audit.Gap_Incremental_Diagnostic_Stability,
         Consumers.Consumer_Semantic_Navigation);
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Diagnostic_Blocker_Source_Span_Gap_Closed (Results),
              "diagnostic/source-span gap closes with balanced rows");
      Assert (Results.Normalized_Count = 1, "normalized count");
      Assert (Results.Runtime_Check_Count = 1, "runtime check count");
      Assert (Results.Warning_Only_Count = 1, "warning count");
      Assert (Results.Indeterminate_Surface_Count = 1, "indeterminate count");
      Assert (Results.Deduplicated_Ordering_Count = 1, "ordering count");
      Assert (Results.Incremental_Stability_Count = 1, "stability count");

      Expect_Status (Results, 1, Audit.Status_Legal_Normalized_Diagnostic,
                     Precision.Class_Legal);
      Expect_Status (Results, 2, Audit.Status_Legal_Runtime_Check_Surface,
                     Precision.Class_Legal_With_Runtime_Check);
      Expect_Status (Results, 3, Audit.Status_Legal_Warning_Only_Surface,
                     Precision.Class_Legal);
      Expect_Status (Results, 4, Audit.Status_Legal_Indeterminate_Surface,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 5, Audit.Status_Legal_Deduplicated_Ordered,
                     Precision.Class_Legal);
      Expect_Status (Results, 6, Audit.Status_Legal_Incrementally_Stable,
                     Precision.Class_Legal);
   end Test_Balanced_Diagnostic_Closure;

   procedure Test_Blocker_Normalization_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row
        (10, Precision.Class_Illegal, Audit.Span_Actual,
         Audit.Blocker_Precise_RM_Family, Audit.Role_Primary);
      Row.Duplicate_Canonical_Diagnostic := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (11, Precision.Class_Illegal, Audit.Span_Actual,
         Audit.Blocker_Duplicate_Spelling, Audit.Role_Primary);
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (12, Precision.Class_Illegal, Audit.Span_Actual,
         Audit.Blocker_Generic_Fallback, Audit.Role_Primary);
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (13, Precision.Class_Illegal, Audit.Span_Actual,
         Audit.Blocker_Precise_RM_Family, Audit.Role_Primary);
      Row.Precise_Blocker_Used := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (14, Precision.Class_Illegal, Audit.Span_Actual,
         Audit.Blocker_Indeterminate, Audit.Role_Primary);
      Row.Hard_Diagnostic_From_Indeterminate := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (15, Precision.Class_Legal_With_Runtime_Check, Audit.Span_Actual,
         Audit.Blocker_Runtime_Check, Audit.Role_Primary);
      Row.Runtime_Check_Emitted_As_Hard := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (16, Precision.Class_Illegal, Audit.Span_Actual,
         Audit.Blocker_Warning_Only, Audit.Role_Primary);
      Row.Warning_Only_Emitted_As_Hard := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Illegal_Duplicate_Canonical_Diagnostic,
                     Precision.Class_Illegal);
      Expect_Status (Results, 11, Audit.Status_Illegal_Duplicate_Blocker_Spelling,
                     Precision.Class_Illegal);
      Expect_Status (Results, 12, Audit.Status_Illegal_Generic_Fallback_Blocker,
                     Precision.Class_Illegal);
      Expect_Status (Results, 13, Audit.Status_Illegal_Precise_Blocker_Missing,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 14, Audit.Status_Illegal_Hard_Diagnostic_From_Indeterminate,
         Precision.Class_Illegal);
      Expect_Status (Results, 15, Audit.Status_Illegal_Runtime_Check_Emitted_As_Hard,
                     Precision.Class_Illegal);
      Expect_Status (Results, 16, Audit.Status_Illegal_Warning_Only_Emitted_As_Hard,
                     Precision.Class_Illegal);
   end Test_Blocker_Normalization_Rejections;

   procedure Test_Source_Span_Precision_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row
        (20, Precision.Class_Indeterminate, Audit.Span_Association,
         Audit.Blocker_Precise_RM_Family, Audit.Role_Primary);
      Row.Smallest_Source_Span_Used := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (21, Precision.Class_Illegal, Audit.Span_Whole_Declaration,
         Audit.Blocker_Precise_RM_Family, Audit.Role_Primary);
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (22, Precision.Class_Illegal, Audit.Span_Local_Reference,
         Audit.Blocker_Precise_RM_Family,
         Audit.Role_Cross_Unit_Local_Reference);
      Row.Cross_Unit_Target_Span_Preserved := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (23, Precision.Class_Illegal, Audit.Span_Recovered_Partial,
         Audit.Blocker_Indeterminate, Audit.Role_Recovered_Syntax);
      Row.Recovered_Syntax_Has_Complete_Span := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20, Audit.Status_Smallest_Source_Span_Missing,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 21, Audit.Status_Illegal_Whole_Declaration_Span_Used,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 22, Audit.Status_Illegal_Cross_Unit_Evidence_Span_Missing,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 23, Audit.Status_Illegal_Recovered_Syntax_Complete_Span_Pretended,
         Precision.Class_Illegal);
   end Test_Source_Span_Precision_Rejections;

   procedure Test_Ordering_Consumers_And_Staleness_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row
        (30, Precision.Class_Illegal, Audit.Span_Actual,
         Audit.Blocker_Precise_RM_Family, Audit.Role_Primary);
      Row.Deterministic_Diagnostic_Order := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (31, Precision.Class_Illegal, Audit.Span_Actual,
         Audit.Blocker_Precise_RM_Family, Audit.Role_Secondary_Evidence);
      Row.Primary_Before_Secondary := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (32, Precision.Class_Illegal, Audit.Span_Actual,
         Audit.Blocker_Precise_RM_Family, Audit.Role_Consumer_State);
      Row.Consumer_Reclassified_State := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (33, Precision.Class_Illegal, Audit.Span_Actual,
         Audit.Blocker_Precise_RM_Family, Audit.Role_Consumer_State,
         Audit.Gap_Consumer_Visible_State_Consistency,
         Consumers.Consumer_Build_Diagnostic_Bridge);
      Row.Build_Diagnostic_Conflated := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (34, Precision.Class_Illegal, Audit.Span_Actual,
         Audit.Blocker_Precise_RM_Family, Audit.Role_Primary,
         Audit.Gap_Incremental_Diagnostic_Stability);
      Row.Unchanged_Error_Blocker_Identity_Preserved := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (35, Precision.Class_Illegal, Audit.Span_Actual,
         Audit.Blocker_Precise_RM_Family, Audit.Role_Primary,
         Audit.Gap_Incremental_Diagnostic_Stability);
      Row.Source_Span_Moved_Deterministically := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (36, Precision.Class_Illegal, Audit.Span_Actual,
         Audit.Blocker_Precise_RM_Family, Audit.Role_Primary,
         Audit.Gap_Incremental_Diagnostic_Stability);
      Row.Stale_Diagnostic_Reused := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (37, Precision.Class_Illegal, Audit.Span_Actual,
         Audit.Blocker_Precise_RM_Family, Audit.Role_Consumer_State,
         Audit.Gap_Incremental_Diagnostic_Stability);
      Row.Stale_Consumer_State_Reused := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 30, Audit.Status_Illegal_Nondeterministic_Diagnostic_Order,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 31, Audit.Status_Illegal_Primary_Secondary_Order_Inverted,
         Precision.Class_Illegal);
      Expect_Status (Results, 32, Audit.Status_Illegal_Consumer_Reclassified_State,
                     Precision.Class_Illegal);
      Expect_Status (Results, 33, Audit.Status_Illegal_Build_Diagnostic_Conflated,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 34, Audit.Status_Illegal_Unchanged_Error_Blocker_Churn,
         Precision.Class_Illegal);
      Expect_Status (Results, 35, Audit.Status_Illegal_Source_Span_Drift,
                     Precision.Class_Illegal);
      Expect_Status (Results, 36, Audit.Status_Illegal_Stale_Diagnostic_Reused,
                     Precision.Class_Illegal);
      Expect_Status (Results, 37, Audit.Status_Illegal_Stale_Consumer_State_Reused,
                     Precision.Class_Illegal);
   end Test_Ordering_Consumers_And_Staleness_Rejections;

   procedure Test_Fingerprint_And_Audit_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row
        (40, Precision.Class_Indeterminate, Audit.Span_Actual,
         Audit.Blocker_Indeterminate, Audit.Role_Primary);
      Row.Source_Fingerprint := 1;
      Row.Expected_Source_Fingerprint := 2;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (41, Precision.Class_Indeterminate, Audit.Span_Actual,
         Audit.Blocker_Indeterminate, Audit.Role_Primary);
      Row.Project_Index_Fingerprint := 10;
      Row.Expected_Project_Index_Fingerprint := 11;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (42, Precision.Class_Indeterminate, Audit.Span_Actual,
         Audit.Blocker_Indeterminate, Audit.Role_Primary);
      Row.Consumer_Fingerprint := 20;
      Row.Expected_Consumer_Fingerprint := 21;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (43, Precision.Class_Indeterminate, Audit.Span_Actual,
         Audit.Blocker_Indeterminate, Audit.Role_Primary);
      Row.Request_Fingerprint := 30;
      Row.Expected_Request_Fingerprint := 31;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (44, Precision.Class_Indeterminate, Audit.Span_Actual,
         Audit.Blocker_Indeterminate, Audit.Role_Primary);
      Row.Source_Shaped_Evidence := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (45, Precision.Class_Indeterminate, Audit.Span_Actual,
         Audit.Blocker_Indeterminate, Audit.Role_Primary);
      Row.Semantic_Result_Consumed := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 40, Audit.Status_Source_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status
        (Results, 41, Audit.Status_Project_Index_Fingerprint_Mismatch,
         Precision.Class_Indeterminate);
      Expect_Status (Results, 42, Audit.Status_Consumer_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 43, Audit.Status_Request_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 44, Audit.Status_Source_Shaped_Evidence_Missing,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 45, Audit.Status_Semantic_Result_Unconsumed,
                     Precision.Class_Indeterminate);
   end Test_Fingerprint_And_Audit_Gates;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Diagnostic_Closure'Access,
         "balanced diagnostic closure");
      Register_Routine
        (T, Test_Blocker_Normalization_Rejections'Access,
         "blocker normalization rejects duplicates and hard misclassification");
      Register_Routine
        (T, Test_Source_Span_Precision_Rejections'Access,
         "source span precision rejects broad or false spans");
      Register_Routine
        (T, Test_Ordering_Consumers_And_Staleness_Rejections'Access,
         "ordering, consumers, and stale diagnostic evidence are enforced");
      Register_Routine
        (T, Test_Fingerprint_And_Audit_Gates'Access,
         "fingerprint and audit gates reject stale or unconsumed evidence");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1364;
