with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration;
with Editor.Ada_Generic_Shared_State_RM_Completion_Remediation_Worklist_Legality;
with Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Eligibility_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Shared_State_RM_Completion_Recheck_Eligibility_Legality_Pass1259 is

   package D renames Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
   use type D.Dataflow_RM_Completion_Row_Id;
   use type D.Dataflow_RM_Completion_Kind;
   use type D.Dataflow_RM_Completion_Blocker_Family;
   use type D.Dataflow_RM_Completion_Status;
   use type D.Dataflow_RM_Completion_Context;
   use type D.Dataflow_RM_Completion_Row;
   use type D.Dataflow_RM_Completion_Context_Model;
   use type D.Dataflow_RM_Completion_Model;
   use type D.Query_Result;
   package Diag renames Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration;
   use type Diag.RM_Completion_Diagnostic_Id;
   use type Diag.RM_Completion_Diagnostic_Family;
   use type Diag.RM_Completion_Diagnostic_Severity;
   use type Diag.RM_Completion_Diagnostic_Status;
   use type Diag.RM_Completion_Diagnostic_Row;
   use type Diag.RM_Completion_Diagnostic_Set;
   use type Diag.RM_Completion_Diagnostic_Model;
   package W renames Editor.Ada_Generic_Shared_State_RM_Completion_Remediation_Worklist_Legality;
   use type W.RM_Completion_Worklist_Id;
   use type W.RM_Completion_Worklist_Family;
   use type W.RM_Completion_Worklist_Diagnostic_Status;
   use type W.RM_Completion_Worklist_Action;
   use type W.RM_Completion_Worklist_Priority;
   use type W.RM_Completion_Worklist_Item;
   use type W.RM_Completion_Worklist_Model;
   use type W.RM_Completion_Worklist_Set;
   package R renames Editor.Ada_Generic_Shared_State_RM_Completion_Recheck_Eligibility_Legality;
   use type R.RM_Completion_Recheck_Family;
   use type R.RM_Completion_Recheck_Work_Action;
   use type R.RM_Completion_Recheck_Work_Priority;
   use type R.RM_Completion_Recheck_Id;
   use type R.RM_Completion_Recheck_Status;
   use type R.RM_Completion_Recheck_Action;
   use type R.RM_Completion_Recheck_Row;
   use type R.RM_Completion_Recheck_Model;
   use type R.RM_Completion_Recheck_Set;
   package Prior renames D.Prior_Dataflow;
   package Cross_RM renames D.Cross_RM;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada generic shared-state RM completion recheck eligibility pass1259");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : D.Dataflow_RM_Completion_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return D.Dataflow_RM_Completion_Context is
      Result : D.Dataflow_RM_Completion_Context;
   begin
      Result.Id := D.Dataflow_RM_Completion_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Prior_Dataflow_Row := Prior.Dataflow_Generic_Final_Row_Id (Id);
      Result.Prior_Dataflow_Status := Prior.Dataflow_Generic_Final_Legal_Variant_Component_Accepted;
      Result.Cross_RM_Row := Cross_RM.Cross_Unit_RM_Completion_Closure_Id (Id);
      Result.Cross_RM_Status := Cross_RM.Cross_Unit_RM_Completion_Legal_Generic_Instance_Accepted;
      Result.Source_Fingerprint := 1259 * Id;
      Result.Expected_Source_Fingerprint := 1259 * Id;
      Result.Substitution_Fingerprint := 9521 * Id;
      Result.Expected_Substitution_Fingerprint := 9521 * Id;
      return Result;
   end Complete_Context;

   function Build_Recheck return R.RM_Completion_Recheck_Model is
      Contexts : D.Dataflow_RM_Completion_Context_Model;
      Accepted : D.Dataflow_RM_Completion_Context :=
        Complete_Context (1, D.Dataflow_RM_Completion_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (125901));
      Cross_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (2, D.Dataflow_RM_Completion_Read_Write,
                          Editor.Ada_Syntax_Tree.Node_Id (125902));
      Representation_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (3, D.Dataflow_RM_Completion_Volatile_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (125903));
      Dataflow_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (4, D.Dataflow_RM_Completion_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (125904));
      Fingerprint_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (5, D.Dataflow_RM_Completion_Generic_Formal_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (125905));
   begin
      Cross_Blocker.Cross_RM_Row := Cross_RM.No_Cross_Unit_RM_Completion_Closure;
      Representation_Blocker.Requires_Representation_RM := True;
      Dataflow_Blocker.Read_Before_Write_Blocker := True;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;

      D.Add_Context (Contexts, Accepted);
      D.Add_Context (Contexts, Cross_Blocker);
      D.Add_Context (Contexts, Representation_Blocker);
      D.Add_Context (Contexts, Dataflow_Blocker);
      D.Add_Context (Contexts, Fingerprint_Blocker);
      return R.Build (W.Build (Diag.Build (D.Build (Contexts))));
   end Build_Recheck;

   procedure Worklist_Becomes_Bounded_Eligibility
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.RM_Completion_Recheck_Model := Build_Recheck;
   begin
      Assert (R.Row_Count (Model) = 5, "five RM-completion recheck rows expected");
      Assert (R.Current_Evidence_Count (Model) = 1,
              "accepted row should be preserved as current evidence");
      Assert (R.Eligible_Count (Model) = 0,
              "blocked prerequisites should not be eligible prematurely");
      Assert (R.Blocked_Count (Model) = 4,
              "four prerequisite blockers should withhold downstream trust");
   end Worklist_Becomes_Bounded_Eligibility;

   procedure Prerequisites_Map_To_Recheck_Statuses
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.RM_Completion_Recheck_Model := Build_Recheck;
   begin
      Assert (R.Count_Status (Model, R.RM_Completion_Recheck_Not_Required_Current) = 1,
              "accepted evidence should require no recheck");
      Assert (R.Count_Status (Model, R.RM_Completion_Recheck_Blocked_By_Cross_Unit) = 1,
              "cross-unit prerequisite should be explicit");
      Assert (R.Representation_Blocked_Count (Model) = 1,
              "representation prerequisite should be explicit");
      Assert (R.Dataflow_Blocked_Count (Model) = 1,
              "dataflow prerequisite should be explicit");
      Assert (R.Fingerprint_Blocked_Count (Model) = 1,
              "fingerprint prerequisite should be explicit");
   end Prerequisites_Map_To_Recheck_Statuses;

   procedure Recheck_Actions_Preserve_Wait_Reasons
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.RM_Completion_Recheck_Model := Build_Recheck;
   begin
      Assert (R.Count_Action (Model, R.RM_Completion_Recheck_Action_Keep_Current) = 1,
              "current evidence should map to keep-current action");
      Assert (R.Count_Action (Model, R.RM_Completion_Recheck_Action_Wait_For_Cross_Unit) = 1,
              "cross-unit blocker should wait for cross-unit closure");
      Assert (R.Count_Action (Model, R.RM_Completion_Recheck_Action_Wait_For_Representation) = 1,
              "representation blocker should wait for representation evidence");
      Assert (R.Count_Action (Model, R.RM_Completion_Recheck_Action_Wait_For_Dataflow) = 1,
              "dataflow blocker should wait for dataflow evidence");
      Assert (R.Count_Action (Model, R.RM_Completion_Recheck_Action_Wait_For_Fingerprint) = 1,
              "fingerprint blocker should wait for refreshed fingerprints");
   end Recheck_Actions_Preserve_Wait_Reasons;

   procedure Queries_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.RM_Completion_Recheck_Model := Build_Recheck;
      Row : constant R.RM_Completion_Recheck_Row := R.Row_At (Model, 2);
   begin
      Assert (R.Query_Count (R.Query_Node (Model, Row.Node)) = 1,
              "node query should recover the eligibility row");
      Assert (R.Query_Count (R.Query_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
              "source fingerprint query should recover the eligibility row");
      Assert (R.Count_Family (Model, Diag.RM_Completion_Diagnostic_Cross_Unit_RM_Completion) = 1,
              "family query should preserve cross-unit RM-completion identity");
      Assert (R.Query_Count (R.Query_Status (Model, Row.Status)) >= 1,
              "status query should recover matching rows");
      Assert (R.Fingerprint (Model) /= 0,
              "eligibility model fingerprint should be non-zero");
   end Queries_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Worklist_Becomes_Bounded_Eligibility'Access,
         "worklist becomes bounded RM-completion recheck eligibility");
      Register_Routine
        (T, Prerequisites_Map_To_Recheck_Statuses'Access,
         "prerequisites map to RM-completion recheck statuses");
      Register_Routine
        (T, Recheck_Actions_Preserve_Wait_Reasons'Access,
         "recheck actions preserve wait reasons");
      Register_Routine
        (T, Queries_And_Fingerprints_Are_Deterministic'Access,
         "queries and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_Generic_Shared_State_RM_Completion_Recheck_Eligibility_Legality_Pass1259;
