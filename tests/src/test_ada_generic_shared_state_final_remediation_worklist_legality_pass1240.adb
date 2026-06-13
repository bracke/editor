with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
with Editor.Ada_Generic_Shared_State_Final_Diagnostic_Integration;
with Editor.Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality_Pass1240 is

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
      return AUnit.Format ("Ada generic shared-state final remediation worklist legality pass1240");
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
      Result.Source_Fingerprint := 1240 * Id;
      Result.Expected_Source_Fingerprint := 1240 * Id;
      Result.Substitution_Fingerprint := 4210 * Id;
      Result.Expected_Substitution_Fingerprint := 4210 * Id;
      return Result;
   end Complete_Context;

   function Build_Diagnostics return Diag.Generic_Shared_State_Final_Diagnostic_Model is
      Contexts : D.Dataflow_Generic_Final_Context_Model;
      Accepted : D.Dataflow_Generic_Final_Context :=
        Complete_Context (1, D.Dataflow_Generic_Final_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (124001));
      Generic_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (2, D.Dataflow_Generic_Final_Generic_Formal_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (124002));
      Representation_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (3, D.Dataflow_Generic_Final_Variant_Component,
                          Editor.Ada_Syntax_Tree.Node_Id (124003));
      Predicate_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (4, D.Dataflow_Generic_Final_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (124004));
      Fingerprint_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (5, D.Dataflow_Generic_Final_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (124005));
      Local_Dataflow_Blocker : D.Dataflow_Generic_Final_Context :=
        Complete_Context (6, D.Dataflow_Generic_Final_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (124006));
   begin
      Accepted.Requires_Generic_Replay := True;
      Accepted.Requires_Stabilized_Closure := True;

      Generic_Blocker.Requires_Generic_Replay := True;
      Generic_Blocker.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Source_Fingerprint_Mismatch;

      Representation_Blocker.Requires_Representation_Generic := True;
      Representation_Blocker.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Private_View_Freezing_Blocker;

      Predicate_Blocker.Requires_Predicate_Generic := True;
      Predicate_Blocker.Predicate_Generic_Status := Predicate_Generic.Predicate_Generic_Final_Source_Fingerprint_Mismatch;

      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;

      Local_Dataflow_Blocker.Read_Before_Write_Blocker := True;

      D.Add_Context (Contexts, Accepted);
      D.Add_Context (Contexts, Generic_Blocker);
      D.Add_Context (Contexts, Representation_Blocker);
      D.Add_Context (Contexts, Predicate_Blocker);
      D.Add_Context (Contexts, Fingerprint_Blocker);
      D.Add_Context (Contexts, Local_Dataflow_Blocker);
      return Diag.Build (D.Build (Contexts));
   end Build_Diagnostics;

   procedure Diagnostic_Blockers_Become_Ordered_Work_Items
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Worklist : constant W.Generic_Shared_State_Final_Worklist_Model := W.Build (Build_Diagnostics);
   begin
      Assert (W.Count (Worklist) = 6, "six generic/shared-state worklist rows expected");
      Assert (W.Current_Evidence_Count (Worklist) = 1,
              "accepted diagnostic row should remain current semantic evidence");
      Assert (W.Ready_For_Recheck_Count (Worklist) = 5,
              "blocking rows should become recheck-ready remediation work");
      Assert (W.Blocked_Downstream_Count (Worklist) = 5,
              "blocking remediation rows should block downstream semantic trust");
   end Diagnostic_Blockers_Become_Ordered_Work_Items;

   procedure Prerequisite_Families_Map_To_Semantic_Actions
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Worklist : constant W.Generic_Shared_State_Final_Worklist_Model := W.Build (Build_Diagnostics);
   begin
      Assert
        (W.Count_Action (Worklist, W.Generic_Shared_State_Final_Worklist_Replay_Generic_Abstract_State) = 1,
         "generic abstract replay blocker should map to replay action");
      Assert
        (W.Count_Action (Worklist, W.Generic_Shared_State_Final_Worklist_Resolve_Representation_Generic_Shared_State) = 1,
         "representation generic shared-state blocker should map to representation action");
      Assert
        (W.Count_Action (Worklist, W.Generic_Shared_State_Final_Worklist_Resolve_Predicate_Generic_Shared_State) = 1,
         "predicate generic shared-state blocker should map to predicate action");
      Assert
        (W.Count_Action (Worklist, W.Generic_Shared_State_Final_Worklist_Resolve_Local_Dataflow_RM) = 1,
         "local Ada dataflow blocker should map to dataflow action");
   end Prerequisite_Families_Map_To_Semantic_Actions;

   procedure Priorities_Preserve_Remediation_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Worklist : constant W.Generic_Shared_State_Final_Worklist_Model := W.Build (Build_Diagnostics);
   begin
      Assert
        (W.Count_Priority (Worklist, W.Generic_Shared_State_Final_Worklist_Priority_Current_Evidence) = 1,
         "current evidence priority should be retained");
      Assert
        (W.Count_Priority (Worklist, W.Generic_Shared_State_Final_Worklist_Priority_Stale_Or_Fingerprint) = 1,
         "fingerprint mismatch priority should be retained");
      Assert
        (W.Count_Priority (Worklist, W.Generic_Shared_State_Final_Worklist_Priority_Generic_Replay) = 1,
         "generic replay priority should be retained");
      Assert
        (W.Count_Priority (Worklist, W.Generic_Shared_State_Final_Worklist_Priority_Representation) = 1,
         "representation priority should be retained");
      Assert
        (W.Count_Priority (Worklist, W.Generic_Shared_State_Final_Worklist_Priority_Dataflow) = 1,
         "dataflow priority should be retained");
   end Priorities_Preserve_Remediation_Order;

   procedure Queries_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Worklist : constant W.Generic_Shared_State_Final_Worklist_Model := W.Build (Build_Diagnostics);
      Row : constant W.Generic_Shared_State_Final_Worklist_Item := W.Row_At (Worklist, 2);
   begin
      Assert (W.Query_Count (W.Query_Node (Worklist, Row.Node)) = 1,
              "node query should recover the work item");
      Assert (W.Query_Count (W.Query_Source_Fingerprint (Worklist, Row.Source_Fingerprint)) = 1,
              "source fingerprint query should recover the work item");
      Assert (W.Count_Family (Worklist, Diag.Generic_Shared_State_Final_Diagnostic_Generic_Abstract_Replay) = 1,
              "family query should preserve generic replay blocker identity");
      Assert (W.Fingerprint_Mismatch_Count (Worklist) = 1,
              "fingerprint mismatch count should be deterministic");
      Assert (W.Stable_Fingerprint (Worklist) /= 0,
              "worklist stable fingerprint should be non-zero");
   end Queries_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Diagnostic_Blockers_Become_Ordered_Work_Items'Access,
         "diagnostic blockers become ordered work items");
      Register_Routine
        (T, Prerequisite_Families_Map_To_Semantic_Actions'Access,
         "prerequisite families map to semantic actions");
      Register_Routine
        (T, Priorities_Preserve_Remediation_Order'Access,
         "priorities preserve remediation order");
      Register_Routine
        (T, Queries_And_Fingerprints_Are_Deterministic'Access,
         "queries and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_Generic_Shared_State_Final_Remediation_Worklist_Legality_Pass1240;
