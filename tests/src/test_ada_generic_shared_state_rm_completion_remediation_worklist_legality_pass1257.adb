with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Generic_Shared_State_RM_Completion_Diagnostic_Integration;
with Editor.Ada_Generic_Shared_State_RM_Completion_Remediation_Worklist_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Shared_State_RM_Completion_Remediation_Worklist_Legality_Pass1257 is

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
   package Prior renames D.Prior_Dataflow;
   package Cross_RM renames D.Cross_RM;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada generic shared-state RM completion remediation worklist pass1257");
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
      Result.Source_Fingerprint := 1257 * Id;
      Result.Expected_Source_Fingerprint := 1257 * Id;
      Result.Substitution_Fingerprint := 7521 * Id;
      Result.Expected_Substitution_Fingerprint := 7521 * Id;
      return Result;
   end Complete_Context;

   function Build_Worklist return W.RM_Completion_Worklist_Model is
      Contexts : D.Dataflow_RM_Completion_Context_Model;
      Accepted : D.Dataflow_RM_Completion_Context :=
        Complete_Context (1, D.Dataflow_RM_Completion_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (125701));
      Cross_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (2, D.Dataflow_RM_Completion_Read_Write,
                          Editor.Ada_Syntax_Tree.Node_Id (125702));
      Representation_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (3, D.Dataflow_RM_Completion_Volatile_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (125703));
      Local_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (4, D.Dataflow_RM_Completion_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (125704));
      Fingerprint_Blocker : D.Dataflow_RM_Completion_Context :=
        Complete_Context (5, D.Dataflow_RM_Completion_Generic_Formal_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (125705));
   begin
      Cross_Blocker.Cross_RM_Row := Cross_RM.No_Cross_Unit_RM_Completion_Closure;
      Representation_Blocker.Requires_Representation_RM := True;
      Local_Blocker.Read_Before_Write_Blocker := True;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 999_999;

      D.Add_Context (Contexts, Accepted);
      D.Add_Context (Contexts, Cross_Blocker);
      D.Add_Context (Contexts, Representation_Blocker);
      D.Add_Context (Contexts, Local_Blocker);
      D.Add_Context (Contexts, Fingerprint_Blocker);
      return W.Build (Diag.Build (D.Build (Contexts)));
   end Build_Worklist;

   procedure Diagnostic_Blockers_Become_RM_Work_Items
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Worklist : constant W.RM_Completion_Worklist_Model := Build_Worklist;
   begin
      Assert (W.Count (Worklist) = 5, "five RM-completion worklist rows expected");
      Assert (W.Current_Evidence_Count (Worklist) = 1,
              "accepted diagnostic row should remain current semantic evidence");
      Assert (W.Ready_For_Recheck_Count (Worklist) = 4,
              "blocking rows should become recheck-ready RM remediation work");
      Assert (W.Blocked_Downstream_Count (Worklist) = 4,
              "blocking remediation rows should block downstream semantic trust");
   end Diagnostic_Blockers_Become_RM_Work_Items;

   procedure Families_Map_To_Completion_Actions
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Worklist : constant W.RM_Completion_Worklist_Model := Build_Worklist;
   begin
      Assert
        (W.Count_Action (Worklist, W.RM_Completion_Worklist_Resolve_Cross_Unit_RM_Completion) = 1,
         "cross-unit RM-completion blocker should map to cross-unit action");
      Assert
        (W.Count_Action (Worklist, W.RM_Completion_Worklist_Resolve_Representation_RM_Completion) = 1,
         "representation RM-completion blocker should map to representation action");
      Assert
        (W.Count_Action (Worklist, W.RM_Completion_Worklist_Resolve_Read_Before_Write) = 1,
         "read-before-write blocker should map to local dataflow action");
      Assert
        (W.Count_Action (Worklist, W.RM_Completion_Worklist_Recheck_Fingerprint) = 1,
         "source fingerprint mismatch should map to fingerprint recheck");
   end Families_Map_To_Completion_Actions;

   procedure Priorities_Preserve_RM_Remediation_Order
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Worklist : constant W.RM_Completion_Worklist_Model := Build_Worklist;
   begin
      Assert
        (W.Count_Priority (Worklist, W.RM_Completion_Worklist_Priority_Current_Evidence) = 1,
         "current evidence priority should be retained");
      Assert
        (W.Count_Priority (Worklist, W.RM_Completion_Worklist_Priority_Cross_Unit_Closure) = 1,
         "cross-unit priority should be retained");
      Assert
        (W.Count_Priority (Worklist, W.RM_Completion_Worklist_Priority_Representation) = 1,
         "representation priority should be retained");
      Assert
        (W.Count_Priority (Worklist, W.RM_Completion_Worklist_Priority_Dataflow) = 1,
         "dataflow priority should be retained");
      Assert
        (W.Count_Priority (Worklist, W.RM_Completion_Worklist_Priority_Stale_Or_Fingerprint) = 1,
         "fingerprint priority should be retained");
   end Priorities_Preserve_RM_Remediation_Order;

   procedure Queries_And_Fingerprints_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Worklist : constant W.RM_Completion_Worklist_Model := Build_Worklist;
      Row : constant W.RM_Completion_Worklist_Item := W.Row_At (Worklist, 2);
   begin
      Assert (W.Query_Count (W.Query_Node (Worklist, Row.Node)) = 1,
              "node query should recover RM-completion work item");
      Assert (W.Query_Count (W.Query_Source_Fingerprint (Worklist, Row.Source_Fingerprint)) = 1,
              "source fingerprint query should recover RM-completion work item");
      Assert (W.Count_Family (Worklist, Diag.RM_Completion_Diagnostic_Cross_Unit_RM_Completion) = 1,
              "family query should preserve RM-completion blocker identity");
      Assert (W.Fingerprint_Mismatch_Count (Worklist) = 1,
              "fingerprint mismatch count should be deterministic");
      Assert (W.Stable_Fingerprint (Worklist) /= 0,
              "RM-completion worklist stable fingerprint should be non-zero");
   end Queries_And_Fingerprints_Are_Deterministic;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Diagnostic_Blockers_Become_RM_Work_Items'Access,
         "diagnostic blockers become RM-completion work items");
      Register_Routine
        (T, Families_Map_To_Completion_Actions'Access,
         "families map to completion actions");
      Register_Routine
        (T, Priorities_Preserve_RM_Remediation_Order'Access,
         "priorities preserve RM remediation order");
      Register_Routine
        (T, Queries_And_Fingerprints_Are_Deterministic'Access,
         "queries and fingerprints are deterministic");
   end Register_Tests;

end Test_Ada_Generic_Shared_State_RM_Completion_Remediation_Worklist_Legality_Pass1257;
