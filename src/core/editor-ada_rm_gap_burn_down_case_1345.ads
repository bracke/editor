with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;

package Editor.Ada_RM_Gap_Burn_Down_Case_1345 is

   --  Case 1345 is the third RM gap burn-down case.  It closes a concrete
   --  cross-unit Ada legality gap by requiring context clauses, library-unit
   --  identity, body/spec completion, separate subunits, cross-unit view
   --  propagation, elaboration legality, remediation evidence, and semantic
   --  consumers to agree on one canonical source-shaped result.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit;
   package Remediation renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
   package Consumers renames Editor.Ada_Semantic_Consumer_Enforcement_Audit;
   package Precision renames Editor.Ada_Partial_Evidence_Precision_Audit;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Coverage_Level is Matrix.Coverage_Level;
   subtype Remediation_State is Remediation.Remediation_State;
   subtype Semantic_Consumer is Consumers.Semantic_Consumer;
   subtype Precision_Classification is Precision.Precision_Classification;

   type Burn_Down_Gap is
     (Gap_Context_Library_Elaboration,
      Gap_Context_Clauses,
      Gap_Library_Unit_Identity,
      Gap_Separate_Subunit_Closure,
      Gap_Cross_Unit_View_Propagation,
      Gap_Elaboration_Legality,
      Gap_Unknown);

   type Context_Item_Kind is
     (Context_With_Clause,
      Context_Private_With_Clause,
      Context_Limited_With_Clause,
      Context_Use_Package_Clause,
      Context_Use_Type_Clause,
      Context_Body_Propagation,
      Context_Generic_Unit,
      Context_Unknown);

   type Library_Unit_Kind is
     (Unit_Package_Spec,
      Unit_Package_Body,
      Unit_Subprogram_Spec,
      Unit_Subprogram_Body,
      Unit_Child_Package,
      Unit_Private_Child,
      Unit_Body_Stub,
      Unit_Separate_Subunit,
      Unit_Unknown);

   type Elaboration_Context_Kind is
     (Elab_None,
      Elab_Pragma_Elaborate,
      Elab_Pragma_Elaborate_All,
      Elab_Preelaborate_Unit,
      Elab_Pure_Unit,
      Elab_Call_Before_Body,
      Elab_Dependency_Cycle,
      Elab_Generic_Body_Availability,
      Elab_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Gap_Burned_Down,
      Status_Illegal_Duplicate_With_Clause,
      Status_Illegal_Duplicate_Use_Clause,
      Status_Illegal_Context_Target_Unresolved,
      Status_Illegal_Unit_Name_Mismatch,
      Status_Illegal_Private_With_Placement,
      Status_Illegal_Private_Child_Visibility_Leak,
      Status_Illegal_Full_View_Use_Through_Limited_With,
      Status_Illegal_Nonlimited_Dependency_Cycle,
      Status_Illegal_Limited_Cycle_Full_View_Leak,
      Status_Illegal_Missing_Library_Unit,
      Status_Illegal_Body_Spec_Kind_Mismatch,
      Status_Illegal_Body_Spec_Profile_Mismatch,
      Status_Illegal_Missing_Completion,
      Status_Illegal_Duplicate_Body,
      Status_Illegal_Body_Order,
      Status_Illegal_Private_Child_Spec_Missing,
      Status_Illegal_Separate_Without_Stub,
      Status_Illegal_Stub_Parent_Mismatch,
      Status_Illegal_Separate_Parent_Mismatch,
      Status_Illegal_Nested_Separate_Parent_Mismatch,
      Status_Illegal_Duplicate_Subunit,
      Status_Illegal_Inherited_Context_Missing,
      Status_Illegal_Cross_Unit_View_Not_Propagated,
      Status_Illegal_Pragma_Elaborate_Not_Satisfied,
      Status_Illegal_Pragma_Elaborate_All_Not_Satisfied,
      Status_Illegal_Preelaborate_Restriction,
      Status_Illegal_Pure_Restriction,
      Status_Illegal_Call_Before_Body_Elaboration,
      Status_Illegal_Elaboration_Dependency_Cycle,
      Status_Illegal_Generic_Body_Unavailable,
      Status_Runtime_Elaboration_Check_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Missing_Full_View,
      Status_Indeterminate_Missing_Cross_Unit_Evidence,
      Status_Missing_Remediation_Evidence,
      Status_Missing_Matrix_Coverage,
      Status_Missing_Implementing_Package,
      Status_No_New_Legality_Rule,
      Status_Coverage_Not_Updated_To_Covered,
      Status_Regression_Corpus_Not_Balanced,
      Status_Semantic_Result_Unconsumed,
      Status_Consumer_Not_Reached,
      Status_Consumer_Unit_Model_Disagreement,
      Status_Consumer_Completion_Model_Disagreement,
      Status_Consumer_View_Model_Disagreement,
      Status_Consumer_Elaboration_Model_Disagreement,
      Status_Source_Shaped_Evidence_Missing,
      Status_Unstable_Blocker_Family,
      Status_Unexpected_Classification,
      Status_Stale_Burn_Down_Fingerprint,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Unit_Fingerprint_Mismatch,
      Status_View_Fingerprint_Mismatch,
      Status_Closure_Fingerprint_Mismatch,
      Status_Elaboration_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Multiple_Blockers,
      Status_Indeterminate);

   type Burn_Down_Row is record
      Id : Natural := 0;
      Gap : Burn_Down_Gap := Gap_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Owner : Implementing_Slice := Matrix.Slice_Unknown;
      Previous_State : Remediation_State := Remediation.State_Unknown;
      Target_State : Remediation_State := Remediation.State_Covered;
      Matrix_Level_Before : Coverage_Level := Matrix.Coverage_Unknown;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Covered;
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Context_Item : Context_Item_Kind := Context_Unknown;
      Unit_Kind : Library_Unit_Kind := Unit_Unknown;
      Elaboration_Context : Elaboration_Context_Kind := Elab_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Implementing_Package : Ada.Strings.Unbounded.Unbounded_String;
      Node : Editor.Ada_Syntax_Tree.Node_Id := 0;
      Source_Shaped_Evidence : Boolean := True;
      Remediation_Entry_Present : Boolean := True;
      Matrix_Coverage_Present : Boolean := True;
      Implementing_Package_Present : Boolean := True;
      New_Legality_Rule_Added : Boolean := True;
      Coverage_Entry_Updated_To_Covered : Boolean := True;
      Balanced_Regression_Evidence : Boolean := True;
      Semantic_Result_Consumed : Boolean := True;
      Consumer_Reached : Boolean := True;
      Stable_Blocker_Family : Boolean := True;
      Context_Target_Resolved : Boolean := True;
      Unit_Name_Matches : Boolean := True;
      Duplicate_With_Clause : Boolean := False;
      Duplicate_Use_Clause : Boolean := False;
      Private_With_Placement_Legal : Boolean := True;
      Private_Child_Visibility_Allowed : Boolean := True;
      Full_View_Used_Through_Limited_With : Boolean := False;
      Nonlimited_Dependency_Cycle : Boolean := False;
      Limited_With_Cycle_Uses_Only_Limited_Views : Boolean := True;
      Library_Unit_Present : Boolean := True;
      Body_Spec_Kind_Conformant : Boolean := True;
      Body_Spec_Profile_Conformant : Boolean := True;
      Body_Completion_Present : Boolean := True;
      Duplicate_Body : Boolean := False;
      Body_Order_Legal : Boolean := True;
      Private_Child_Spec_Present : Boolean := True;
      Body_Stub_Present : Boolean := True;
      Separate_Body_Has_Matching_Stub : Boolean := True;
      Stub_Parent_Matches : Boolean := True;
      Separate_Parent_Matches : Boolean := True;
      Nested_Separate_Parent_Matches : Boolean := True;
      Duplicate_Subunit : Boolean := False;
      Inherited_Context_Visible : Boolean := True;
      Cross_Unit_View_Propagated : Boolean := True;
      Pragma_Elaborate_Satisfied : Boolean := True;
      Pragma_Elaborate_All_Satisfied : Boolean := True;
      Preelaborate_Restrictions_Satisfied : Boolean := True;
      Pure_Restrictions_Satisfied : Boolean := True;
      Call_Before_Body_Elaboration : Boolean := False;
      Elaboration_Dependency_Cycle : Boolean := False;
      Generic_Body_Available : Boolean := True;
      Runtime_Elaboration_Check : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Private_View_Barrier : Boolean := False;
      Limited_View_Barrier : Boolean := False;
      Incomplete_View_Barrier : Boolean := False;
      Generic_Formal_View_Barrier : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit_Evidence : Boolean := False;
      Consumer_Unit_Model_Agrees : Boolean := True;
      Consumer_Completion_Model_Agrees : Boolean := True;
      Consumer_View_Model_Agrees : Boolean := True;
      Consumer_Elaboration_Model_Agrees : Boolean := True;
      Evidence_Stale : Boolean := False;
      Burn_Down_Fingerprint : Natural := 0;
      Expected_Burn_Down_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Unit_Fingerprint : Natural := 0;
      Expected_Unit_Fingerprint : Natural := 0;
      View_Fingerprint : Natural := 0;
      Expected_View_Fingerprint : Natural := 0;
      Closure_Fingerprint : Natural := 0;
      Expected_Closure_Fingerprint : Natural := 0;
      Elaboration_Fingerprint : Natural := 0;
      Expected_Elaboration_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Burn_Down_Row);

   type Burn_Down_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Burn_Down_Entry is record
      Id : Natural := 0;
      Gap : Burn_Down_Gap := Gap_Unknown;
      Family : RM_Family := Matrix.Family_Unknown;
      Owner : Implementing_Slice := Matrix.Slice_Unknown;
      Previous_State : Remediation_State := Remediation.State_Unknown;
      Promoted_State : Remediation_State := Remediation.State_Unknown;
      Matrix_Level_After : Coverage_Level := Matrix.Coverage_Unknown;
      Consumer : Semantic_Consumer := Consumers.Consumer_Unknown;
      Classification : Precision_Classification := Precision.Class_Unknown;
      Status : Burn_Down_Status := Status_Not_Checked;
      Blocker_Count : Natural := 0;
      Entry_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Burn_Down_Entry);

   type Burn_Down_Model is record
      Items : Entry_Vectors.Vector;
      Burned_Down_Count : Natural := 0;
      Legal_Count : Natural := 0;
      Illegal_Count : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Invalid_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Burn_Down_Row
     (Input : in out Burn_Down_Input;
      Row : Burn_Down_Row);

   function Build (Input : Burn_Down_Input) return Burn_Down_Model;
   function Count (Results : Burn_Down_Model) return Natural;
   function Result_At (Results : Burn_Down_Model; Index : Positive) return Burn_Down_Entry;
   function Result_For (Results : Burn_Down_Model; Id : Natural) return Burn_Down_Entry;
   function RM_Gap_Burn_Down_Ready (Results : Burn_Down_Model) return Boolean;
   function Context_Library_Elaboration_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;

end Editor.Ada_RM_Gap_Burn_Down_Case_1345;
