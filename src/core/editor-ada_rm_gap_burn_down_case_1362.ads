with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Coverage_Matrix_Audit;
with Editor.Ada_RM_Coverage_Gap_Remediation_Audit;
with Editor.Ada_Semantic_Consumer_Enforcement_Audit;
with Editor.Ada_Partial_Evidence_Precision_Audit;

package Editor.Ada_RM_Gap_Burn_Down_Case_1362 is

   --  Case 1362 is the twentieth RM gap burn-down case.  It closes the
   --  bounded semantic work, cancellation, supersession, deterministic
   --  scheduling, and graceful budget exhaustion gap for live editor Ada
   --  analysis.  The pass verifies that semantic work is snapshot-owned,
   --  budgeted, cancellable, deterministically ordered, and consumed through
   --  canonical cancellation/budget evidence without mutating editor state.

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
     (Gap_Bounded_Semantic_Work_Cancellation_Scheduling,
      Gap_Work_Budget_Ownership,
      Gap_Cancellation_Supersession,
      Gap_Deterministic_Scheduling,
      Gap_Graceful_Budget_Exhaustion,
      Gap_Editor_Invariant_Safety,
      Gap_Unknown);

   type Work_Unit_Kind is
     (Work_None,
      Work_AST_Recovery,
      Work_Name_Visibility,
      Work_Type_Profile,
      Work_Overload_Call,
      Work_Generic_Body_Replay,
      Work_Cross_Unit_Closure,
      Work_Representation_Freezing,
      Work_Contract_Flow,
      Work_Consumer_Surface,
      Work_Unknown);

   type Schedule_Phase is
     (Phase_Not_Scheduled,
      Phase_Queued,
      Phase_Running,
      Phase_Cancelled,
      Phase_Superseded,
      Phase_Completed,
      Phase_Budget_Exhausted,
      Phase_Unknown);

   type Burn_Down_Status is
     (Status_Not_Checked,
      Status_Gap_Burned_Down,
      Status_Legal_Work_Completed_Within_Budget,
      Status_Legal_Work_Cancelled_By_Newer_Request,
      Status_Legal_Work_Superseded_And_Rejected,
      Status_Legal_Deterministic_Order_Preserved,
      Status_Legal_Partial_Result_Preserved,
      Status_Legal_Runtime_Check_Preserved,
      Status_Indeterminate_Budget_Exceeded,
      Status_Illegal_Work_Budget_Exceeded_As_Legal,
      Status_Illegal_Work_Budget_Exceeded_As_Illegal,
      Status_Illegal_Unbounded_Generic_Replay,
      Status_Illegal_Unbounded_Overload_Exploration,
      Status_Illegal_Unbounded_Cross_Unit_Closure,
      Status_Illegal_Diagnostic_Emitted_After_Cancellation,
      Status_Illegal_Stale_Partial_Result_Reused,
      Status_Illegal_Cancelled_Result_Consumed,
      Status_Illegal_Superseded_Result_Consumed,
      Status_Illegal_Nondeterministic_Work_Order,
      Status_Illegal_Nondeterministic_Blocker_Order,
      Status_Illegal_Nondeterministic_Diagnostic_Order,
      Status_Illegal_Nondeterministic_Outline_Order,
      Status_Illegal_Hash_Or_Timing_Dependent_Order,
      Status_Illegal_Consumer_Bypassed_Cancellation_State,
      Status_Illegal_Consumer_Bypassed_Budget_State,
      Status_Illegal_Diagnostics_Missing_Blocker_Family,
      Status_Illegal_File_Save_Reload_During_Analysis,
      Status_Illegal_Dirty_State_Mutation,
      Status_Illegal_Rendering_Side_Parsing,
      Status_Illegal_Command_Keybinding_Workspace_Render_Mutation,
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
      Status_Buffer_Identity_Mismatch,
      Status_Source_Revision_Mismatch,
      Status_Lifecycle_Generation_Mismatch,
      Status_Request_Token_Mismatch,
      Status_Source_Fingerprint_Mismatch,
      Status_AST_Fingerprint_Mismatch,
      Status_Type_Fingerprint_Mismatch,
      Status_Profile_Fingerprint_Mismatch,
      Status_Unit_Fingerprint_Mismatch,
      Status_Substitution_Fingerprint_Mismatch,
      Status_Effect_Fingerprint_Mismatch,
      Status_Policy_Fingerprint_Mismatch,
      Status_Recovery_Fingerprint_Mismatch,
      Status_Schedule_Fingerprint_Mismatch,
      Status_Consumer_Fingerprint_Mismatch,
      Status_Unexpected_Classification,
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
      Work : Work_Unit_Kind := Work_Unknown;
      Phase : Schedule_Phase := Phase_Unknown;
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
      Diagnostics_Blocker_Family_Present : Boolean := True;

      Buffer_Identity : Natural := 0;
      Expected_Buffer_Identity : Natural := 0;
      Source_Revision : Natural := 0;
      Expected_Source_Revision : Natural := 0;
      Lifecycle_Generation : Natural := 0;
      Expected_Lifecycle_Generation : Natural := 0;
      Request_Token : Natural := 0;
      Expected_Request_Token : Natural := 0;

      Per_Buffer_Budget : Natural := 0;
      Request_Budget : Natural := 0;
      Slice_Budget : Natural := 0;
      Steps_Consumed : Natural := 0;
      Slice_Steps_Consumed : Natural := 0;
      Candidate_Count : Natural := 0;
      Candidate_Limit : Natural := 0;
      Replay_Depth : Natural := 0;
      Replay_Depth_Limit : Natural := 0;
      Cross_Unit_Depth : Natural := 0;
      Cross_Unit_Depth_Limit : Natural := 0;

      Work_Completed : Boolean := False;
      Work_Cancelled : Boolean := False;
      Work_Superseded : Boolean := False;
      Partial_Result_Available : Boolean := False;
      Partial_Result_Preserved : Boolean := False;
      Result_Rejected_By_Consumer : Boolean := False;
      Diagnostic_Emitted : Boolean := False;
      Runtime_Check_Context : Boolean := False;
      Runtime_Check_Evidence_Preserved : Boolean := True;

      Budget_Exhausted : Boolean := False;
      Budget_Exhaustion_Classified_Indeterminate : Boolean := True;
      Budget_Exhaustion_Treated_As_Legal : Boolean := False;
      Budget_Exhaustion_Treated_As_Illegal : Boolean := False;
      Partial_Evidence_Preserved_On_Budget_Exhaustion : Boolean := True;

      Deterministic_Work_Order : Boolean := True;
      Deterministic_Blocker_Order : Boolean := True;
      Deterministic_Diagnostic_Order : Boolean := True;
      Deterministic_Outline_Order : Boolean := True;
      Hash_Or_Timing_Dependent_Order : Boolean := False;

      Unbounded_Generic_Replay : Boolean := False;
      Unbounded_Overload_Exploration : Boolean := False;
      Unbounded_Cross_Unit_Closure : Boolean := False;
      Stale_Partial_Result_Reused : Boolean := False;
      Cancelled_Result_Consumed : Boolean := False;
      Superseded_Result_Consumed : Boolean := False;
      Consumer_Bypassed_Cancellation_State : Boolean := False;
      Consumer_Bypassed_Budget_State : Boolean := False;

      File_Save_Reload_During_Analysis : Boolean := False;
      Dirty_State_Mutation : Boolean := False;
      Rendering_Side_Parsing : Boolean := False;
      Command_Keybinding_Workspace_Render_Mutation : Boolean := False;

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
      Recovery_Fingerprint : Natural := 0;
      Expected_Recovery_Fingerprint : Natural := 0;
      Schedule_Fingerprint : Natural := 0;
      Expected_Schedule_Fingerprint : Natural := 0;
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
      Consumer : Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Expected : Precision_Classification := Precision.Class_Unknown;
      Work : Work_Unit_Kind := Work_Unknown;
      Phase : Schedule_Phase := Phase_Unknown;
      Status : Burn_Down_Status := Status_Not_Checked;
      Blocker_Count : Natural := 0;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Burn_Down_Entry);

   type Burn_Down_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Completed_Count : Natural := 0;
      Cancelled_Count : Natural := 0;
      Superseded_Count : Natural := 0;
      Budget_Exceeded_Count : Natural := 0;
      Deterministic_Count : Natural := 0;
      Consumer_Count : Natural := 0;
      Illegal_Count : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Blocked_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Burn_Down_Input; Row : Burn_Down_Row);
   function Build (Input : Burn_Down_Input) return Burn_Down_Model;
   function Count (Results : Burn_Down_Model) return Natural;
   function Result_At (Results : Burn_Down_Model; Index : Positive)
     return Burn_Down_Entry;
   function Result_For (Results : Burn_Down_Model; Id : Natural)
     return Burn_Down_Entry;
   function Expected_For_Status
     (Status : Burn_Down_Status) return Precision_Classification;
   function Bounded_Work_Scheduling_Gap_Closed
     (Results : Burn_Down_Model) return Boolean;

end Editor.Ada_RM_Gap_Burn_Down_Case_1362;
