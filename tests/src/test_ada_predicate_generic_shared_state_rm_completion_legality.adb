with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Predicate_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Predicate_Generic_Shared_State_RM_Completion_Legality is

   package Registration renames AUnit.Test_Cases.Registration;
   package C renames Editor.Ada_Predicate_Generic_Shared_State_RM_Completion_Legality;
   use type C.Predicate_RM_Completion_Row_Id;
   use type C.Predicate_RM_Completion_Kind;
   use type C.Predicate_RM_Completion_Blocker_Family;
   use type C.Predicate_RM_Completion_Status;
   use type C.Predicate_RM_Completion_Context;
   use type C.Predicate_RM_Completion_Row;
   use type C.Predicate_RM_Completion_Context_Model;
   use type C.Predicate_RM_Completion_Model;
   use type C.Predicate_RM_Completion_Set;
   package Prior renames C.Prior_Predicate;
   package Cross_RM renames C.Cross_RM;
   package Elaboration_RM renames C.Elaboration_RM;
   package Accessibility_RM renames C.Accessibility_RM;
   package Exception_RM renames C.Exception_RM;
   package Dataflow renames C.Dataflow_Final;
   package Overload_RM renames C.Overload_RM;
   package Representation_RM renames C.Representation_RM;
   package Tasking_RM renames C.Tasking_RM;
   package AST_Repair renames C.AST_Repair;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada predicate generic shared-state RM completion legality");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Predicate_RM_Completion_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Predicate_RM_Completion_Context is
      Result : C.Predicate_RM_Completion_Context;
   begin
      Result.Id := C.Predicate_RM_Completion_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Subtype_Name := To_Unbounded_String ("Subtype" & Natural'Image (Id));
      Result.Object_Name := To_Unbounded_String ("Object" & Natural'Image (Id));
      Result.Type_Name := To_Unbounded_String ("Type" & Natural'Image (Id));
      Result.Operation_Name := To_Unbounded_String ("Operation" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("Generic" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("Instance" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Prior_Predicate_Row := Prior.Predicate_Generic_Final_Row_Id (Id);
      Result.Prior_Predicate_Status := Prior.Predicate_Generic_Final_Legal_Dispatching_Call_Accepted;
      Result.Cross_RM_Row := Cross_RM.Cross_Unit_RM_Completion_Closure_Id (Id);
      Result.Cross_RM_Status := Cross_RM.Cross_Unit_RM_Completion_Legal_Generic_Instance_Accepted;
      Result.Elaboration_RM_Row := Elaboration_RM.Elaboration_RM_Completion_Row_Id (Id);
      Result.Elaboration_RM_Status := Elaboration_RM.Elaboration_RM_Completion_Legal_Predicate_Check_Accepted;
      Result.Accessibility_RM_Row := Accessibility_RM.Accessibility_RM_Completion_Row_Id (Id);
      Result.Accessibility_RM_Status := Accessibility_RM.Accessibility_RM_Completion_Legal_Private_Full_View_Accepted;
      Result.Exception_RM_Row := Exception_RM.Exception_RM_Completion_Row_Id (Id);
      Result.Exception_RM_Status := Exception_RM.Exception_RM_Completion_Legal_Predicate_Check_Finalization_Accepted;
      Result.Dataflow_Row := Dataflow.Dataflow_Generic_Final_Row_Id (Id);
      Result.Dataflow_Status := Dataflow.Dataflow_Generic_Final_Legal_Variant_Component_Accepted;
      Result.Overload_RM_Row := Overload_RM.Overload_Generic_RM_Edge_Completion_Id (Id);
      Result.Overload_RM_Status := Overload_RM.Overload_Generic_RM_Edge_Legal_Dispatching_Abstract_State_Effect_Accepted;
      Result.Representation_RM_Row := Representation_RM.Representation_Generic_RM_Hard_Case_Id (Id);
      Result.Representation_RM_Status := Representation_RM.Representation_Generic_RM_Hard_Case_Legal_Independent_Component_Accepted;
      Result.Tasking_RM_Row := Tasking_RM.Tasking_Generic_RM_Hard_Case_Id (Id);
      Result.Tasking_RM_Status := Tasking_RM.Tasking_Generic_RM_Hard_Case_Legal_Protected_Action_Reentrancy_Accepted;
      Result.AST_Repair_Row := AST_Repair.Coverage_Proven_AST_Repair_Id (Id);
      Result.AST_Repair_Status := AST_Repair.Coverage_Proven_AST_Repair_Consumer_Integration_Repaired;
      Result.Source_Fingerprint := 1254 * Id;
      Result.Expected_Source_Fingerprint := 1254 * Id;
      Result.Substitution_Fingerprint := 4521 * Id;
      Result.Expected_Substitution_Fingerprint := 4521 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Predicate_Completion_Consumes_Completed_RM_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Predicate_RM_Completion_Context_Model;
      Static_Use : C.Predicate_RM_Completion_Context :=
        Complete_Context (1, C.Predicate_RM_Completion_Assignment,
                          Editor.Ada_Syntax_Tree.Node_Id (125401));
      Variant_Use : C.Predicate_RM_Completion_Context :=
        Complete_Context (2, C.Predicate_RM_Completion_Variant_Component,
                          Editor.Ada_Syntax_Tree.Node_Id (125402));
   begin
      Static_Use.Requires_Elaboration_RM := True;
      Static_Use.Requires_Overload_RM := True;
      Static_Use.Requires_AST_Repair := True;
      Variant_Use.Requires_Dataflow := True;
      Variant_Use.Requires_Representation_RM := True;
      Variant_Use.Requires_Tasking_RM := True;
      C.Add_Context (Contexts, Static_Use);
      C.Add_Context (Contexts, Variant_Use);

      declare
         Model : constant C.Predicate_RM_Completion_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two predicate RM completion rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete RM evidence should accept predicate conclusions");
         Assert (C.Blocked_Count (Model) = 0, "accepted rows should not block downstream closure");
         Assert
           (C.Count_By_Status (Model, C.Predicate_RM_Completion_Legal_Assignment_Accepted) = 1,
            "assignment predicate should be accepted");
         Assert
           (C.Count_By_Status (Model, C.Predicate_RM_Completion_Legal_Variant_Component_Accepted) = 1,
            "variant predicate should be accepted");
      end;
   end Accepted_Predicate_Completion_Consumes_Completed_RM_Evidence;

   procedure Missing_Or_Blocked_Completion_Prerequisites_Preserve_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Predicate_RM_Completion_Context_Model;
      Cross_Blocker : C.Predicate_RM_Completion_Context :=
        Complete_Context (1, C.Predicate_RM_Completion_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (125421));
      Exception_Blocker : C.Predicate_RM_Completion_Context :=
        Complete_Context (2, C.Predicate_RM_Completion_Controlled_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (125422));
      Dataflow_Blocker : C.Predicate_RM_Completion_Context :=
        Complete_Context (3, C.Predicate_RM_Completion_Call_Result,
                          Editor.Ada_Syntax_Tree.Node_Id (125423));
   begin
      Cross_Blocker.Cross_RM_Status := Cross_RM.Cross_Unit_RM_Completion_State_Visibility_Blocker;
      Exception_Blocker.Requires_Exception_RM := True;
      Exception_Blocker.Exception_RM_Status := Exception_RM.Exception_RM_Completion_Finalize_Order_Blocker;
      Dataflow_Blocker.Requires_Dataflow := True;
      Dataflow_Blocker.Dataflow_Status := Dataflow.Dataflow_Generic_Final_Exception_Path_Blocker;
      C.Add_Context (Contexts, Cross_Blocker);
      C.Add_Context (Contexts, Exception_Blocker);
      C.Add_Context (Contexts, Dataflow_Blocker);

      declare
         Model : constant C.Predicate_RM_Completion_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept predicate conclusions");
         Assert (C.Blocked_Count (Model) = 3, "three blockers should be retained");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Predicate_RM_Completion_Blocker_Cross_Unit_RM_Completion) = 1,
            "cross-unit RM blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Predicate_RM_Completion_Blocker_Exception_Finalization_RM_Completion) = 1,
            "exception/finalization RM blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Predicate_RM_Completion_Blocker_Dataflow_Final) = 1,
            "dataflow blocker family should be preserved");
      end;
   end Missing_Or_Blocked_Completion_Prerequisites_Preserve_Families;

   procedure Local_Predicate_RM_Errors_Block_Before_Downstream_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Predicate_RM_Completion_Context_Model;
      Static_Predicate : C.Predicate_RM_Completion_Context :=
        Complete_Context (1, C.Predicate_RM_Completion_Assignment,
                          Editor.Ada_Syntax_Tree.Node_Id (125441));
      Invariant : C.Predicate_RM_Completion_Context :=
        Complete_Context (2, C.Predicate_RM_Completion_Derived_Type,
                          Editor.Ada_Syntax_Tree.Node_Id (125442));
      Volatile_Effect : C.Predicate_RM_Completion_Context :=
        Complete_Context (3, C.Predicate_RM_Completion_Volatile_Atomic_State,
                          Editor.Ada_Syntax_Tree.Node_Id (125443));
   begin
      Static_Predicate.Static_Predicate_Error := True;
      Invariant.Invariant_Error := True;
      Volatile_Effect.Volatile_Atomic_Effect_Error := True;
      C.Add_Context (Contexts, Static_Predicate);
      C.Add_Context (Contexts, Invariant);
      C.Add_Context (Contexts, Volatile_Effect);

      declare
         Model : constant C.Predicate_RM_Completion_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Predicate_RM_Completion_Static_Predicate_Blocker) = 1,
            "static predicate should block directly");
         Assert
           (C.Count_By_Status (Model, C.Predicate_RM_Completion_Invariant_Blocker) = 1,
            "invariant should block directly");
         Assert
           (C.Count_By_Status (Model, C.Predicate_RM_Completion_Volatile_Atomic_Effect_Blocker) = 1,
            "volatile/atomic effect should block directly");
      end;
   end Local_Predicate_RM_Errors_Block_Before_Downstream_Evidence;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Predicate_RM_Completion_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (125461);
      Item : C.Predicate_RM_Completion_Context :=
        Complete_Context (1, C.Predicate_RM_Completion_Dispatching_Call, Node);
   begin
      Item.Dispatching_Effect_Error := True;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Predicate_RM_Completion_Model := C.Build (Contexts);
         Row   : constant C.Predicate_RM_Completion_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find predicate RM completion evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find predicate RM completion evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve the original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "predicate RM completion model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Predicate_Completion_Consumes_Completed_RM_Evidence'Access,
         "accepted predicate completion consumes completed RM evidence");
      Register_Routine
        (T, Missing_Or_Blocked_Completion_Prerequisites_Preserve_Families'Access,
         "missing or blocked completion prerequisites preserve families");
      Register_Routine
        (T, Local_Predicate_RM_Errors_Block_Before_Downstream_Evidence'Access,
         "local predicate RM errors block before downstream evidence");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and blocker family");
   end Register_Tests;

end Test_Ada_Predicate_Generic_Shared_State_RM_Completion_Legality;
