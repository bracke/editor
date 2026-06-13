with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
with Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

package Editor.Ada_RM_Gap_Burn_Down_Pass1359 is

   --  Pass1359 is the seventeenth RM gap burn-down pass.  It closes the
   --  source-unit semantic closure gap by requiring realistic Ada source
   --  units to produce one canonical final verdict across vertical slices,
   --  RM coverage/remediation, precision state, balanced regression evidence,
   --  and real semantic consumers.  The pass audits whole package, generic,
   --  tagged/interface, concurrent, and representation/interfacing scenarios
   --  instead of accepting slice-local success as compiler-grade closure.

   package Matrix renames Editor.Ada_RM_Coverage_Matrix_Audit_Pass1338;
   package Remediation renames Editor.Ada_RM_Coverage_Gap_Remediation_Audit_Pass1339;
   package Consumers renames Editor.Ada_Semantic_Consumer_Enforcement_Audit_Pass1340;
   package Precision renames Editor.Ada_Partial_Evidence_Precision_Audit_Pass1341;

   subtype RM_Family is Matrix.RM_Family;
   subtype Implementing_Slice is Matrix.Implementing_Slice;
   subtype Coverage_Level is Matrix.Coverage_Level;
   subtype Remediation_State is Remediation.Remediation_State;
   subtype Semantic_Consumer is Consumers.Semantic_Consumer;
   subtype Precision_Classification is Precision.Precision_Classification;

   type Burn_Down_Gap is
     (Gap_Source_Unit_Semantic_Closure,
      Gap_Whole_Package_Spec_Body_Closure,
      Gap_Whole_Generic_Unit_Closure,
      Gap_Whole_Tagged_Interface_Hierarchy_Closure,
      Gap_Whole_Concurrent_Unit_Closure,
      Gap_Whole_Representation_Interfacing_Closure,
      Gap_Consumer_Visible_Final_Verdict,
      Gap_Unknown);

   type Source_Unit_Kind is
     (Unit_Package_Spec_Body,
      Unit_Generic_Package_Instantiation,
      Unit_Tagged_Interface_Hierarchy,
      Unit_Task_Protected_Concurrent,
      Unit_Representation_Interfacing,
      Unit_Mixed_Compilation_Closure,
      Unit_Unknown);

   type Closure_Context_Kind is
     (Context_Whole_Source_Unit,
      Context_Context_Clause_Private_Part,
      Context_Generic_Substitution_Replay,
      Context_Tagged_Interface_Dispatching,
      Context_Task_Protected_Parallel,
      Context_Representation_Freezing_Interfacing,
      Context_Final_Consumer_Verdict,
      Context_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Source_Unit_Closure,
      Status_Runtime_Check_Final_Verdict_Preserved,
      Status_Runtime_Check_Evidence_Lost,
      Status_Illegal_Source_Unit_Canonical_Closure_Failed,
      Status_Illegal_Context_Closure_Disagreement,
      Status_Illegal_Private_Full_View_Disagreement,
      Status_Illegal_Body_Spec_Conformance_Disagreement,
      Status_Illegal_Elaboration_Closure_Disagreement,
      Status_Illegal_Representation_Freezing_Disagreement,
      Status_Illegal_Contract_Flow_Disagreement,
      Status_Illegal_Generic_Substitution_Not_Propagated,
      Status_Illegal_Generic_Body_Replay_Disagreement,
      Status_Illegal_Overload_Profile_Disagreement,
      Status_Illegal_Literal_Operator_Substitution_Disagreement,
      Status_Illegal_Tagged_Interface_Disagreement,
      Status_Illegal_Dispatching_Effect_Join_Missing,
      Status_Illegal_Class_Wide_Conversion_Disagreement,
      Status_Illegal_Concurrent_Shared_State_Disagreement,
      Status_Illegal_Protected_Barrier_Disagreement,
      Status_Illegal_Parallel_Iterator_Disagreement,
      Status_Illegal_Finalization_Abort_Disagreement,
      Status_Illegal_Representation_Consumer_Disagreement,
      Status_Illegal_RM_Coverage_Remediation_Missing,
      Status_Illegal_Balanced_Regression_Missing,
      Status_Illegal_Partial_Evidence_Precision_Lost,
      Status_Illegal_Consumer_Final_Verdict_Conflict,
      Status_Illegal_Diagnostics_Final_Verdict_Disagreement,
      Status_Illegal_Colouring_Final_Verdict_Disagreement,
      Status_Illegal_Outline_Final_Verdict_Disagreement,
      Status_Illegal_Navigation_Final_Verdict_Disagreement,
      Status_Illegal_Hover_Final_Verdict_Disagreement,
      Status_Illegal_Diagnostic_Bridge_Final_Verdict_Disagreement,
      Status_Indeterminate_Private_View,
      Status_Indeterminate_Limited_View,
      Status_Indeterminate_Incomplete_View,
      Status_Indeterminate_Generic_Formal_View,
      Status_Indeterminate_Missing_Full_View,
      Status_Indeterminate_Missing_Source_Unit_Evidence,
      Status_Indeterminate_Missing_AST_Evidence,
      Status_Indeterminate_Missing_Type_Evidence,
      Status_Indeterminate_Missing_Profile_Evidence,
      Status_Indeterminate_Missing_Unit_Evidence,
      Status_Indeterminate_Missing_Substitution_Evidence,
      Status_Indeterminate_Missing_Effect_Evidence,
      Status_Indeterminate_Missing_Policy_Evidence,
      Status_Indeterminate_Missing_Consumer_Evidence,
      Status_Missing_Remediation_Evidence,
      Status_Missing_Matrix_Coverage,
      Status_Missing_Implementing_Package,
      Status_No_New_Legality_Rule,
      Status_Coverage_Not_Updated_To_Covered,
      Status_Regression_Corpus_Not_Balanced,
      Status_Semantic_Result_Unconsumed,
      Status_Consumer_Not_Reached,
      Status_Source_Shaped_Evidence_Missing,
      Status_Unstable_Blocker_Family,
      Status_Unexpected_Classification,
      Status_Stale_Burn_Down_Fingerprint,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Unit_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Policy_Fingerprint_Mismatch,
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
      Unit_Kind : Source_Unit_Kind := Unit_Unknown;
      Context : Closure_Context_Kind := Context_Unknown;
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
      Canonical_Closure_Agrees : Boolean := True;
      Context_Closure_Agrees : Boolean := True;
      Private_Full_View_Agrees : Boolean := True;
      Body_Spec_Conformance_Agrees : Boolean := True;
      Elaboration_Closure_Agrees : Boolean := True;
      Representation_Freezing_Agrees : Boolean := True;
      Contract_Flow_Agrees : Boolean := True;
      Generic_Substitution_Propagated : Boolean := True;
      Generic_Body_Replay_Agrees : Boolean := True;
      Overload_Profile_Agrees : Boolean := True;
      Literal_Operator_Substitution_Agrees : Boolean := True;
      Tagged_Interface_Agrees : Boolean := True;
      Dispatching_Effect_Join_Present : Boolean := True;
      Class_Wide_Conversion_Agrees : Boolean := True;
      Concurrent_Shared_State_Agrees : Boolean := True;
      Protected_Barrier_Agrees : Boolean := True;
      Parallel_Iterator_Agrees : Boolean := True;
      Finalization_Abort_Agrees : Boolean := True;
      Representation_Consumer_Agrees : Boolean := True;
      RM_Coverage_Remediation_Present : Boolean := True;
      Balanced_Final_Regression_Evidence : Boolean := True;
      Partial_Evidence_Precision_Preserved : Boolean := True;
      Runtime_Check_Final_Verdict : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;
      Consumer_Final_Verdict_Agrees : Boolean := True;
      Diagnostics_Agrees : Boolean := True;
      Colouring_Agrees : Boolean := True;
      Outline_Agrees : Boolean := True;
      Navigation_Agrees : Boolean := True;
      Hover_Agrees : Boolean := True;
      Bridge_Agrees : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Source_Unit_Evidence : Boolean := False;
      Missing_AST_Evidence : Boolean := False;
      Missing_Type_Evidence : Boolean := False;
      Missing_Profile_Evidence : Boolean := False;
      Missing_Unit_Evidence : Boolean := False;
      Missing_Substitution_Evidence : Boolean := False;
      Missing_Effect_Evidence : Boolean := False;
      Missing_Policy_Evidence : Boolean := False;
      Missing_Consumer_Evidence : Boolean := False;
      Evidence_Stale : Boolean := False;
      Burn_Down_Fingerprint : Natural := 0;
      Expected_Burn_Down_Fingerprint : Natural := 0;
      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Type_Fingerprint : Natural := 0;
      Expected_Type_Fingerprint : Natural := 0;
      Profile_Fingerprint : Natural := 0;
      Expected_Profile_Fingerprint : Natural := 0;
      Unit_Fingerprint : Natural := 0;
      Expected_Unit_Fingerprint : Natural := 0;
      Substitution_Fingerprint : Natural := 0;
      Expected_Substitution_Fingerprint : Natural := 0;
      Effect_Fingerprint : Natural := 0;
      Expected_Effect_Fingerprint : Natural := 0;
      Policy_Fingerprint : Natural := 0;
      Expected_Policy_Fingerprint : Natural := 0;
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
      Consumer : Semantic_Consumer := Consumers.Consumer_Unknown;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Unit_Kind : Source_Unit_Kind := Unit_Unknown;
      Context : Closure_Context_Kind := Context_Unknown;
      Status : Burn_Down_Status := Status_Not_Checked;
      Blocker_Count : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Burn_Down_Entry);

   type Burn_Down_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Legal_Count : Natural := 0;
      Illegal_Count : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Blocked_Count : Natural := 0;
      Consumer_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Burn_Down_Input; Row : Burn_Down_Row);
   function Build (Input : Burn_Down_Input) return Burn_Down_Model;
   function Count (Results : Burn_Down_Model) return Natural;
   function Result_At (Results : Burn_Down_Model; Index : Positive)
     return Burn_Down_Entry;
   function Result_For (Results : Burn_Down_Model; Id : Natural)
     return Burn_Down_Entry;
   function Source_Unit_Semantic_Closure_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;
   function Is_Valid_Status (Status : Burn_Down_Status) return Boolean;
   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification;

end Editor.Ada_RM_Gap_Burn_Down_Pass1359;
