with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_RM_Gap_Burn_Down_Case_1363;

package body Test_Ada_RM_Gap_Burn_Down_Case_1363 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Case_1363;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Source_Origin;
   use type Audit.Unit_Role;
   use type Audit.Invalidation_Kind;
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
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification;
      Source : Audit.Source_Origin;
      Role : Audit.Unit_Role;
      Invalidation : Audit.Invalidation_Kind;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics)
      return Audit.Burn_Down_Row is
      Row : Audit.Burn_Down_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Gap_Project_Semantic_Index_Multi_Buffer_Closure;
      Row.Family := Matrix.Family_Library_Context_Subunits_Elaboration;
      Row.Owner := Matrix.Slice_Semantic_Integration_Audit;
      Row.Previous_State := Remediation.State_Partial;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Source := Source;
      Row.Role := Role;
      Row.Invalidation := Invalidation;
      Row.Unit_Name := To_Unbounded_String ("Project.Root");
      Row.Source_Path := To_Unbounded_String ("src/project-root.ads");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Case_1363");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Burn_Down_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected case 1363 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected case 1363 classification");
   end Expect_Status;

   procedure Test_Balanced_Project_Index_Closure

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row
        (1, Precision.Class_Legal, Audit.Source_Dirty_Open_Buffer,
         Audit.Role_Package_Spec, Audit.Invalidation_None,
         Consumers.Consumer_Diagnostics);
      Row.Open_Buffer_Precedence := True;
      Row.Dirty_Buffer_Uses_Snapshot := True;
      Row.Project_Index_Row_Present := True;
      Row.Unit_Name_Matches_Source := True;
      Row.Context_Lookup_Uses_Index := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (2, Precision.Class_Legal, Audit.Source_Project_File,
         Audit.Role_Package_Body, Audit.Invalidation_None,
         Consumers.Consumer_Outline_Model);
      Row.Project_Index_Row_Present := True;
      Row.Unit_Name_Matches_Source := True;
      Row.Spec_Body_Paired := True;
      Row.Context_Lookup_Uses_Index := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (3, Precision.Class_Legal, Audit.Source_Project_File,
         Audit.Role_Package_Spec, Audit.Invalidation_Spec_Edit,
         Consumers.Consumer_Semantic_Navigation);
      Row.Dependent_Spec_Invalidated := True;
      Row.Project_Index_Row_Present := True;
      Row.Unit_Name_Matches_Source := True;
      Row.Context_Lookup_Uses_Index := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (4, Precision.Class_Indeterminate, Audit.Source_Missing_File,
         Audit.Role_Package_Body, Audit.Invalidation_File_Delete_Or_Rename,
         Consumers.Consumer_Hover_Details);
      Row.Missing_File_Blocker_Preserved := True;
      Row.File_Identity_Invalidated := True;
      Row.Project_Index_Row_Present := True;
      Row.Unit_Name_Matches_Source := True;
      Row.Spec_Body_Paired := True;
      Row.Context_Lookup_Uses_Index := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (5, Precision.Class_Legal, Audit.Source_Project_File,
         Audit.Role_Child_Unit, Audit.Invalidation_Unrelated_Edit,
         Consumers.Consumer_Semantic_Colouring);
      Row.Stable_Entity_Identity_Preserved := True;
      Row.Project_Index_Row_Present := True;
      Row.Unit_Name_Matches_Source := True;
      Row.Child_Index_Present := True;
      Row.Context_Lookup_Uses_Index := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Project_Index_Multi_Buffer_Gap_Closed (Results),
              "project semantic index gap closes with balanced source-shaped rows");
      Assert (Results.Open_Buffer_Precedence_Count = 1,
              "open-buffer precedence counted");
      Assert (Results.Project_Index_Count = 1, "project index closure counted");
      Assert (Results.Invalidation_Count = 1, "cross-buffer invalidation counted");
      Assert (Results.Missing_File_Blocker_Count = 1,
              "missing file blocker counted");
      Assert (Results.Stable_Preservation_Count = 1,
              "stable preservation counted");

      Expect_Status
        (Results, 1, Audit.Status_Legal_Open_Buffer_Snapshot_Precedence,
         Precision.Class_Legal);
      Expect_Status
        (Results, 2, Audit.Status_Legal_Project_Index_Closure,
         Precision.Class_Legal);
      Expect_Status
        (Results, 3, Audit.Status_Legal_Cross_Buffer_Invalidation,
         Precision.Class_Legal);
      Expect_Status
        (Results, 4, Audit.Status_Legal_Missing_File_Blocked,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 5, Audit.Status_Legal_Stable_Unrelated_Edit_Preserved,
         Precision.Class_Legal);
   end Test_Balanced_Project_Index_Closure;

   procedure Test_Open_Buffer_Source_Ownership_Is_Enforced

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row
        (10, Precision.Class_Indeterminate, Audit.Source_Dirty_Open_Buffer,
         Audit.Role_Package_Spec, Audit.Invalidation_None);
      Row.Open_Buffer_Precedence := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (11, Precision.Class_Indeterminate, Audit.Source_Dirty_Open_Buffer,
         Audit.Role_Package_Spec, Audit.Invalidation_None);
      Row.Dirty_Buffer_Uses_Snapshot := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (12, Precision.Class_Illegal, Audit.Source_Open_Buffer,
         Audit.Role_Package_Spec, Audit.Invalidation_None);
      Row.Disk_Text_Used_For_Open_Buffer := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (13, Precision.Class_Illegal, Audit.Source_Scratch_Buffer,
         Audit.Role_Package_Spec, Audit.Invalidation_None);
      Row.Scratch_Became_Library_Unit := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (14, Precision.Class_Illegal, Audit.Source_Missing_File,
         Audit.Role_Package_Body, Audit.Invalidation_None);
      Row.Missing_File_Treated_As_Empty_Unit := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (15, Precision.Class_Indeterminate, Audit.Source_Deleted_File,
         Audit.Role_Package_Body, Audit.Invalidation_File_Delete_Or_Rename);
      Row.Missing_File_Blocker_Preserved := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 10, Audit.Status_Open_Buffer_Precedence_Missing,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 11, Audit.Status_Dirty_Buffer_Snapshot_Missing,
                     Precision.Class_Indeterminate);
      Expect_Status
        (Results, 12, Audit.Status_Illegal_Disk_Text_Used_For_Open_Buffer,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 13, Audit.Status_Illegal_Scratch_Buffer_Became_Library_Unit,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 14, Audit.Status_Illegal_Missing_File_Treated_As_Empty_Unit,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 15, Audit.Status_Missing_File_Blocker_Missing,
         Precision.Class_Indeterminate);
   end Test_Open_Buffer_Source_Ownership_Is_Enforced;

   procedure Test_Project_Index_Rejects_Ambiguous_Or_Leaky_Units

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row
        (20, Precision.Class_Indeterminate, Audit.Source_Project_File,
         Audit.Role_Context_Client, Audit.Invalidation_None);
      Row.Project_Index_Row_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (21, Precision.Class_Indeterminate, Audit.Source_Project_File,
         Audit.Role_Package_Spec, Audit.Invalidation_None);
      Row.Unit_Name_Matches_Source := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (22, Precision.Class_Illegal, Audit.Source_Duplicate_Unit,
         Audit.Role_Package_Spec, Audit.Invalidation_None);
      Row.Duplicate_Library_Unit := True;
      Row.Duplicate_Unit_Rejected := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (23, Precision.Class_Indeterminate, Audit.Source_Project_File,
         Audit.Role_Package_Body, Audit.Invalidation_None);
      Row.Spec_Body_Paired := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (24, Precision.Class_Indeterminate, Audit.Source_Project_File,
         Audit.Role_Private_Child, Audit.Invalidation_None);
      Row.Child_Index_Present := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (25, Precision.Class_Illegal, Audit.Source_Project_File,
         Audit.Role_Private_Child, Audit.Invalidation_None);
      Row.Private_Child_Visibility_Leaked := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (26, Precision.Class_Indeterminate, Audit.Source_Project_File,
         Audit.Role_Separate_Subunit, Audit.Invalidation_None);
      Row.Separate_Subunit_Indexed := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (27, Precision.Class_Illegal, Audit.Source_Project_File,
         Audit.Role_Context_Client, Audit.Invalidation_None);
      Row.Context_Lookup_Uses_Index := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (28, Precision.Class_Illegal, Audit.Source_Project_File,
         Audit.Role_Context_Client, Audit.Invalidation_None,
         Consumers.Consumer_Hover_Details);
      Row.Consumer_Resolved_Independently := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status (Results, 20, Audit.Status_Project_Index_Row_Missing,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 21, Audit.Status_Unit_Name_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status
        (Results, 22, Audit.Status_Illegal_Duplicate_Library_Unit_Accepted,
         Precision.Class_Illegal);
      Expect_Status (Results, 23, Audit.Status_Spec_Body_Pairing_Missing,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 24, Audit.Status_Child_Index_Missing,
                     Precision.Class_Indeterminate);
      Expect_Status
        (Results, 25, Audit.Status_Illegal_Private_Child_Visibility_Leak,
         Precision.Class_Illegal);
      Expect_Status (Results, 26, Audit.Status_Separate_Subunit_Index_Missing,
                     Precision.Class_Indeterminate);
      Expect_Status
        (Results, 27, Audit.Status_Illegal_Context_Lookup_Bypassed_Index,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 28,
         Audit.Status_Illegal_Consumer_Resolved_Cross_Unit_Independently,
         Precision.Class_Illegal);
   end Test_Project_Index_Rejects_Ambiguous_Or_Leaky_Units;

   procedure Test_Cross_Buffer_Invalidation_Is_Required

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row
        (30, Precision.Class_Illegal, Audit.Source_Open_Buffer,
         Audit.Role_Package_Spec, Audit.Invalidation_Spec_Edit);
      Row.Dependent_Spec_Invalidated := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (31, Precision.Class_Illegal, Audit.Source_Open_Buffer,
         Audit.Role_Package_Body, Audit.Invalidation_Body_Edit);
      Row.Body_Availability_Invalidated := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (32, Precision.Class_Illegal, Audit.Source_Open_Buffer,
         Audit.Role_Package_Spec, Audit.Invalidation_Private_Part_Edit);
      Row.Private_View_Invalidated := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (33, Precision.Class_Illegal, Audit.Source_Open_Buffer,
         Audit.Role_Generic_Spec, Audit.Invalidation_Generic_Spec_Edit);
      Row.Generic_Instances_Invalidated := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (34, Precision.Class_Illegal, Audit.Source_Deleted_File,
         Audit.Role_Package_Spec, Audit.Invalidation_File_Delete_Or_Rename);
      Row.File_Identity_Invalidated := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (35, Precision.Class_Illegal, Audit.Source_Project_File,
         Audit.Role_Child_Unit, Audit.Invalidation_Unrelated_Edit);
      Row.Stable_Entity_Identity_Preserved := False;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (36, Precision.Class_Illegal, Audit.Source_Project_File,
         Audit.Role_Context_Client, Audit.Invalidation_Context_Clause_Edit);
      Row.Stale_Project_Index_Row_Used := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (37, Precision.Class_Illegal, Audit.Source_Project_File,
         Audit.Role_Context_Client, Audit.Invalidation_Context_Clause_Edit);
      Row.Cross_Unit_Closure_Stale := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (38, Precision.Class_Illegal, Audit.Source_Project_File,
         Audit.Role_Context_Client, Audit.Invalidation_Context_Clause_Edit,
         Consumers.Consumer_Semantic_Navigation);
      Row.Consumer_Feed_Stale := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (39, Precision.Class_Illegal, Audit.Source_Project_File,
         Audit.Role_Package_Body, Audit.Invalidation_Body_Edit);
      Row.Spec_Body_Pairing_Stale := True;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status
        (Results, 30, Audit.Status_Illegal_Dependent_Spec_Not_Invalidated,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 31, Audit.Status_Illegal_Body_Availability_Not_Invalidated,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 32, Audit.Status_Illegal_Private_View_Not_Invalidated,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 33, Audit.Status_Illegal_Generic_Instances_Not_Invalidated,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 34, Audit.Status_Illegal_File_Identity_Not_Invalidated,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 35, Audit.Status_Illegal_Open_Buffer_Identity_Churn,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 36, Audit.Status_Illegal_Stale_Project_Index_Row_Used,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 37, Audit.Status_Illegal_Stale_Cross_Unit_Closure_Used,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 38, Audit.Status_Illegal_Stale_Consumer_Feed_Used,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 39, Audit.Status_Illegal_Spec_Body_Pairing_Stale_Reused,
         Precision.Class_Illegal);
   end Test_Cross_Buffer_Invalidation_Is_Required;

   procedure Test_Invariants_And_Fingerprints_Are_Enforced

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row
        (40, Precision.Class_Illegal, Audit.Source_Open_Buffer,
         Audit.Role_Package_Spec, Audit.Invalidation_None);
      Row.File_Save_Reload_During_Analysis := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (41, Precision.Class_Illegal, Audit.Source_Open_Buffer,
         Audit.Role_Package_Spec, Audit.Invalidation_None);
      Row.Dirty_State_Mutation := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (42, Precision.Class_Illegal, Audit.Source_Open_Buffer,
         Audit.Role_Package_Spec, Audit.Invalidation_None);
      Row.Rendering_Side_Parsing := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (43, Precision.Class_Illegal, Audit.Source_Open_Buffer,
         Audit.Role_Package_Spec, Audit.Invalidation_None);
      Row.Command_Keybinding_Workspace_Render_Mutation := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (44, Precision.Class_Indeterminate, Audit.Source_Project_File,
         Audit.Role_Context_Client, Audit.Invalidation_None);
      Row.Project_Fingerprint := 100;
      Row.Expected_Project_Fingerprint := 101;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (45, Precision.Class_Indeterminate, Audit.Source_Project_File,
         Audit.Role_Context_Client, Audit.Invalidation_None);
      Row.Index_Fingerprint := 200;
      Row.Expected_Index_Fingerprint := 201;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (46, Precision.Class_Indeterminate, Audit.Source_Project_File,
         Audit.Role_Context_Client, Audit.Invalidation_None);
      Row.Closure_Fingerprint := 300;
      Row.Expected_Closure_Fingerprint := 301;
      Audit.Add_Row (Input, Row);

      Row := Base_Row
        (47, Precision.Class_Indeterminate, Audit.Source_Project_File,
         Audit.Role_Context_Client, Audit.Invalidation_None,
         Consumers.Consumer_Hover_Details);
      Row.Consumer_Fingerprint := 400;
      Row.Expected_Consumer_Fingerprint := 401;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status
        (Results, 40, Audit.Status_Illegal_File_Save_Reload_During_Analysis,
         Precision.Class_Illegal);
      Expect_Status (Results, 41, Audit.Status_Illegal_Dirty_State_Mutation,
                     Precision.Class_Illegal);
      Expect_Status (Results, 42, Audit.Status_Illegal_Rendering_Side_Parsing,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 43,
         Audit.Status_Illegal_Command_Keybinding_Workspace_Render_Mutation,
         Precision.Class_Illegal);
      Expect_Status (Results, 44, Audit.Status_Project_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 45, Audit.Status_Index_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 46, Audit.Status_Closure_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
      Expect_Status (Results, 47, Audit.Status_Consumer_Fingerprint_Mismatch,
                     Precision.Class_Indeterminate);
   end Test_Invariants_And_Fingerprints_Are_Enforced;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Project_Index_Closure'Access,
         "balanced project index closure");
      Register_Routine
        (T, Test_Open_Buffer_Source_Ownership_Is_Enforced'Access,
         "open-buffer source ownership is enforced");
      Register_Routine
        (T, Test_Project_Index_Rejects_Ambiguous_Or_Leaky_Units'Access,
         "project index rejects ambiguous or leaky units");
      Register_Routine
        (T, Test_Cross_Buffer_Invalidation_Is_Required'Access,
         "cross-buffer invalidation is required");
      Register_Routine
        (T, Test_Invariants_And_Fingerprints_Are_Enforced'Access,
         "invariants and fingerprints are enforced");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Case_1363;
