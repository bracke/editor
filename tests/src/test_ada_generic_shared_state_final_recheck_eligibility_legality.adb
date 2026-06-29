with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
with Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration;
with Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality;
with Editor.Ada_Generic_Shared_State_Final_Recheck_Eligibility_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Shared_State_Final_Recheck_Eligibility_Legality is

   package D renames Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
   use type D.Dataflow_Generic_Final_Row_Id;
   use type D.Dataflow_Generic_Final_Kind;
   use type D.Dataflow_Generic_Final_Blocker_Family;
   use type D.Dataflow_Generic_Final_Status;
   use type D.Dataflow_Generic_Final_Context;
   use type D.Dataflow_Generic_Final_Row;
   use type D.Dataflow_Generic_Final_Context_Model;
   use type D.Dataflow_Generic_Final_Model;
   use type D.Dataflow_Generic_Final_Set;
   package Diag renames Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration;
   use type Diag.Generic_Shared_State_Final_Diagnostic_Id;
   use type Diag.Generic_Shared_State_Final_Diagnostic_Family;
   use type Diag.Generic_Shared_State_Final_Diagnostic_Severity;
   use type Diag.Generic_Shared_State_Final_Diagnostic_Status;
   use type Diag.Generic_Shared_State_Final_Diagnostic_Row;
   use type Diag.Generic_Shared_State_Final_Diagnostic_Set;
   use type Diag.Generic_Shared_State_Final_Diagnostic_Model;
   package W renames Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality;
   use type W.Generic_Shared_State_Final_Worklist_Id;
   use type W.Generic_Shared_State_Final_Worklist_Family;
   use type W.Generic_Shared_State_Final_Worklist_Diagnostic_Status;
   use type W.Generic_Shared_State_Final_Worklist_Action;
   use type W.Generic_Shared_State_Final_Worklist_Priority;
   use type W.Generic_Shared_State_Final_Worklist_Item;
   use type W.Generic_Shared_State_Final_Worklist_Model;
   use type W.Generic_Shared_State_Final_Worklist_Set;
   package R renames Editor.Ada_Generic_Shared_State_Final_Recheck_Eligibility_Legality;
   use type R.Generic_Shared_State_Final_Recheck_Family;
   use type R.Generic_Shared_State_Final_Recheck_Work_Action;
   use type R.Generic_Shared_State_Final_Recheck_Work_Priority;
   use type R.Generic_Shared_State_Final_Recheck_Id;
   use type R.Generic_Shared_State_Final_Recheck_Status;
   use type R.Generic_Shared_State_Final_Recheck_Action;
   use type R.Generic_Shared_State_Final_Recheck_Row;
   use type R.Generic_Shared_State_Final_Recheck_Model;
   use type R.Generic_Shared_State_Final_Recheck_Set;
   package Init renames D.Init;
   package Dataflow_Init renames D.Dataflow_Init;
   package Predicate_Dataflow renames D.Predicate_Dataflow;
   package Predicate_Generic renames D.Predicate_Generic;
   package Generic_Replay renames D.Generic_Replay;
   package Closure renames D.Closure;
   package Rep_Generic renames D.Rep_Generic;
   package Tasking_Generic renames D.Tasking_Generic;
   package Access_Generic renames D.Access_Generic;
   package Disc_Generic renames D.Disc_Generic;
   package Exception_Generic renames D.Exception_Generic;
   package Renaming_Generic renames D.Renaming_Generic;
   package Volatile_Rep renames D.Volatile_Rep;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada generic shared-state final recheck eligibility legality");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : D.Dataflow_Generic_Final_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return D.Dataflow_Generic_Final_Context is
      Result : D.Dataflow_Generic_Final_Context;
   begin
      Result.Id := D.Dataflow_Generic_Final_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Object_Name := To_Unbounded_String ("Obj" & Natural'Image (Id));
      Result.Component_Name := To_Unbounded_String ("Component" & Natural'Image (Id));
      Result.Operation_Name := To_Unbounded_String ("Op" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("G" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("I" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Initialization_Row := Init.Initialization_Legality_Id (Id);
      Result.Initialization_Status := Init.Initialization_Legality_Definitely_Initialized;
      Result.Dataflow_Init_Row := Dataflow_Init.Dataflow_Init_Row_Id (Id);
      Result.Dataflow_Init_Status := Dataflow_Init.Dataflow_Init_Legal_Read_Write_Accepted;
      Result.Predicate_Dataflow_Row := Predicate_Dataflow.Predicate_Dataflow_Row_Id (Id);
      Result.Predicate_Dataflow_Status := Predicate_Dataflow.Predicate_Dataflow_Legal_Flow_Effect_Accepted;
      Result.Predicate_Generic_Row := Predicate_Generic.Predicate_Generic_Final_Row_Id (Id);
      Result.Predicate_Generic_Status := Predicate_Generic.Predicate_Generic_Final_Legal_Dispatching_Call_Accepted;
      Result.Generic_Replay_Row := Generic_Replay.Generic_Abstract_Replay_Row_Id (Id);
      Result.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Legal_Nested_Instance_State_Accepted;
      Result.Stabilized_Closure_Row := Closure.Shared_State_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Accepted_Current;
      Result.Representation_Generic_Row := Rep_Generic.Representation_Generic_Final_Row_Id (Id);
      Result.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Legal_Variant_Record_Layout_Accepted;
      Result.Tasking_Generic_Row := Tasking_Generic.Tasking_Generic_Final_Row_Id (Id);
      Result.Tasking_Generic_Status := Tasking_Generic.Tasking_Generic_Final_Legal_Generic_Protected_Body_Accepted;
      Result.Accessibility_Generic_Row := Access_Generic.Accessibility_Generic_Final_Row_Id (Id);
      Result.Accessibility_Generic_Status := Access_Generic.Accessibility_Generic_Final_Legal_Controlled_Finalization_Accepted;
      Result.Discriminant_Generic_Row := Disc_Generic.Discriminant_Generic_Final_Row_Id (Id);
      Result.Discriminant_Generic_Status := Disc_Generic.Discriminant_Generic_Final_Legal_Variant_Record_Layout_Accepted;
      Result.Exception_Generic_Row := Exception_Generic.Exception_Generic_Final_Row_Id (Id);
      Result.Exception_Generic_Status := Exception_Generic.Exception_Generic_Final_Legal_Controlled_Finalize_Accepted;
      Result.Renaming_Generic_Row := Renaming_Generic.Renaming_Generic_Final_Row_Id (Id);
      Result.Renaming_Generic_Status := Renaming_Generic.Renaming_Generic_Final_Legal_Selected_Alias_Accepted;
      Result.Volatile_Representation_Row := Volatile_Rep.Volatile_Atomic_Representation_Row_Id (Id);
      Result.Volatile_Representation_Status := Volatile_Rep.Volatile_Atomic_Representation_Legal_Record_Layout_Accepted;
      Result.Source_Fingerprint := 1241 * Id;
      Result.Expected_Source_Fingerprint := 1241 * Id;
      Result.Substitution_Fingerprint := 4211 * Id;
      Result.Expected_Substitution_Fingerprint := 4211 * Id;
      return Result;
   end Complete_Context;

   function Build_Worklist return W.Generic_Shared_State_Final_Worklist_Model is
      Contexts : D.Dataflow_Generic_Final_Context_Model;
      Accepted : D.Dataflow_Generic_Final_Context :=
        Complete_Context (1, D.Dataflow_Generic_Final_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (124101));
      Generic_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (2, D.Dataflow_Generic_Final_Generic_Formal_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (124102));
      Shared_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (3, D.Dataflow_Generic_Final_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (124103));
      Representation_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (4, D.Dataflow_Generic_Final_Variant_Component,
                          Editor.Ada_Syntax_Tree.Node_Id (124104));
      Predicate_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (5, D.Dataflow_Generic_Final_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (124105));
      Fingerprint_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (6, D.Dataflow_Generic_Final_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (124106));
      Local_Dataflow_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (7, D.Dataflow_Generic_Final_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (124107));
   begin
      Accepted.Requires_Generic_Replay := True;
      Accepted.Requires_Stabilized_Closure := True;

      Generic_Blocker.Requires_Generic_Replay := True;
      Generic_Blocker.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Source_Fingerprint_Mismatch;

      Shared_Blocker.Requires_Stabilized_Closure := True;
      Shared_Blocker.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Blocker_Abstract_State;

      Representation_Blocker.Requires_Representation_Generic := True;
      Representation_Blocker.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Private_View_Freezing_Blocker;

      Predicate_Blocker.Requires_Predicate_Generic := True;
      Predicate_Blocker.Predicate_Generic_Status := Predicate_Generic.Predicate_Generic_Final_Source_Fingerprint_Mismatch;

      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;

      Local_Dataflow_Blocker.Read_Before_Write_Blocker := True;

      D.Add_Context (Contexts, Accepted);
      D.Add_Context (Contexts, Generic_Blocker);
      D.Add_Context (Contexts, Shared_Blocker);
      D.Add_Context (Contexts, Representation_Blocker);
      D.Add_Context (Contexts, Predicate_Blocker);
      D.Add_Context (Contexts, Fingerprint_Blocker);
      D.Add_Context (Contexts, Local_Dataflow_Blocker);
      return W.Build (Diag.Build (D.Build (Contexts)));
   end Build_Worklist;

   procedure Worklist_Becomes_Bounded_Recheck_Eligibility
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Generic_Shared_State_Final_Recheck_Model := R.Build (Build_Worklist);
   begin
      Assert (R.Row_Count (Model) = 7, "seven generic/shared-state recheck rows expected");
      Assert (R.Current_Evidence_Count (Model) = 1,
              "current evidence should be preserved as not-required recheck");
      Assert (R.Eligible_Count (Model) = 0,
              "blocked prerequisites should not become eligible prematurely");
      Assert (R.Blocked_Count (Model) = 6,
              "six prerequisite blockers should withhold downstream recheck");
   end Worklist_Becomes_Bounded_Recheck_Eligibility;

   procedure Prerequisites_Map_To_Recheck_Statuses
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Generic_Shared_State_Final_Recheck_Model := R.Build (Build_Worklist);
   begin
      Assert (R.Count_Status (Model, R.Generic_Shared_State_Final_Recheck_Not_Required_Current) = 1,
              "accepted evidence should require no recheck");
      Assert (R.Generic_Replay_Blocked_Count (Model) = 1,
              "generic replay prerequisite should be explicit");
      Assert (R.Shared_State_Blocked_Count (Model) = 1,
              "stabilized shared-state prerequisite should be explicit");
      Assert (R.Representation_Blocked_Count (Model) = 1,
              "representation prerequisite should be explicit");
      Assert (R.Predicate_Blocked_Count (Model) = 1,
              "predicate prerequisite should be explicit");
      Assert (R.Fingerprint_Blocked_Count (Model) = 1,
              "source fingerprint prerequisite should be explicit");
      Assert (R.Dataflow_Blocked_Count (Model) = 1,
              "local dataflow prerequisite should be explicit");
   end Prerequisites_Map_To_Recheck_Statuses;

   procedure Recheck_Actions_Preserve_Wait_Reasons
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Generic_Shared_State_Final_Recheck_Model := R.Build (Build_Worklist);
   begin
      Assert (R.Count_Action (Model, R.Generic_Shared_State_Final_Recheck_Action_Keep_Current) = 1,
              "current evidence should map to keep-current action");
      Assert (R.Count_Action (Model, R.Generic_Shared_State_Final_Recheck_Action_Wait_For_Generic_Replay) = 1,
              "generic replay blocker should wait for generic replay");
      Assert (R.Count_Action (Model, R.Generic_Shared_State_Final_Recheck_Action_Wait_For_Shared_State) = 1,
              "shared-state blocker should wait for stabilized shared-state evidence");
      Assert (R.Count_Action (Model, R.Generic_Shared_State_Final_Recheck_Action_Wait_For_Representation) = 1,
              "representation blocker should wait for representation evidence");
      Assert (R.Count_Action (Model, R.Generic_Shared_State_Final_Recheck_Action_Wait_For_Dataflow) = 1,
              "dataflow blocker should wait for dataflow evidence");
   end Recheck_Actions_Preserve_Wait_Reasons;

   procedure Queries_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant R.Generic_Shared_State_Final_Recheck_Model := R.Build (Build_Worklist);
      Row : constant R.Generic_Shared_State_Final_Recheck_Row := R.Row_At (Model, 2);
   begin
      Assert (R.Query_Count (R.Query_Node (Model, Row.Node)) = 1,
              "node query should recover the eligibility row");
      Assert (R.Query_Count (R.Query_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
              "source fingerprint query should recover the eligibility row");
      Assert (R.Count_Family (Model, Diag.Generic_Shared_State_Final_Diagnostic_Generic_Abstract_Replay) = 1,
              "family query should preserve generic replay identity");
      Assert (R.Query_Count (R.Query_Status (Model, Row.Status)) >= 1,
              "status query should recover matching rows");
      Assert (R.Fingerprint (Model) /= 0,
              "eligibility model fingerprint should be non-zero");
   end Queries_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Worklist_Becomes_Bounded_Recheck_Eligibility'Access,
         "worklist becomes bounded recheck eligibility");
      Register_Routine
        (T, Prerequisites_Map_To_Recheck_Statuses'Access,
         "prerequisites map to recheck statuses");
      Register_Routine
        (T, Recheck_Actions_Preserve_Wait_Reasons'Access,
         "recheck actions preserve wait reasons");
      Register_Routine
        (T, Queries_And_Fingerprints_Are_Deterministic'Access,
         "queries and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_Generic_Shared_State_Final_Recheck_Eligibility_Legality;
