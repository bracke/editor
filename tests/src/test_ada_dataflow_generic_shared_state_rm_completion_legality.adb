with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality is

   package Registration renames AUnit.Test_Cases.Registration;
   package C renames Editor.Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
   use type C.Dataflow_RM_Completion_Row_Id;
   use type C.Dataflow_RM_Completion_Kind;
   use type C.Dataflow_RM_Completion_Blocker_Family;
   use type C.Dataflow_RM_Completion_Status;
   use type C.Dataflow_RM_Completion_Context;
   use type C.Dataflow_RM_Completion_Row;
   use type C.Dataflow_RM_Completion_Context_Model;
   use type C.Dataflow_RM_Completion_Model;
   use type C.Query_Result;
   package Prior renames C.Prior_Dataflow;
   package Cross_RM renames C.Cross_RM;
   package Elaboration_RM renames C.Elaboration_RM;
   package Accessibility_RM renames C.Accessibility_RM;
   package Exception_RM renames C.Exception_RM;
   package Predicate_RM renames C.Predicate_RM;
   package Overload_RM renames C.Overload_RM;
   package Representation_RM renames C.Representation_RM;
   package Tasking_RM renames C.Tasking_RM;
   package AST_Repair renames C.AST_Repair;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada dataflow generic shared-state RM completion legality");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Dataflow_RM_Completion_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Dataflow_RM_Completion_Context is
      Result : C.Dataflow_RM_Completion_Context;
   begin
      Result.Id := C.Dataflow_RM_Completion_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Object_Name := To_Unbounded_String ("Object" & Natural'Image (Id));
      Result.Component_Name := To_Unbounded_String ("Component" & Natural'Image (Id));
      Result.Operation_Name := To_Unbounded_String ("Operation" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("Generic" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("Instance" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Prior_Dataflow_Row := Prior.Dataflow_Generic_Final_Row_Id (Id);
      Result.Prior_Dataflow_Status := Prior.Dataflow_Generic_Final_Legal_Variant_Component_Accepted;
      Result.Cross_RM_Row := Cross_RM.Cross_Unit_RM_Completion_Closure_Id (Id);
      Result.Cross_RM_Status := Cross_RM.Cross_Unit_RM_Completion_Legal_Generic_Instance_Accepted;
      Result.Elaboration_RM_Row := Elaboration_RM.Elaboration_RM_Completion_Row_Id (Id);
      Result.Elaboration_RM_Status := Elaboration_RM.Elaboration_RM_Completion_Legal_Dispatching_Call_Accepted;
      Result.Accessibility_RM_Row := Accessibility_RM.Accessibility_RM_Completion_Row_Id (Id);
      Result.Accessibility_RM_Status := Accessibility_RM.Accessibility_RM_Completion_Legal_Return_Object_Accepted;
      Result.Exception_RM_Row := Exception_RM.Exception_RM_Completion_Row_Id (Id);
      Result.Exception_RM_Status := Exception_RM.Exception_RM_Completion_Legal_Controlled_Finalize_Accepted;
      Result.Predicate_RM_Row := Predicate_RM.Predicate_RM_Completion_Row_Id (Id);
      Result.Predicate_RM_Status := Predicate_RM.Predicate_RM_Completion_Legal_Variant_Component_Accepted;
      Result.Overload_RM_Row := Overload_RM.Overload_Generic_RM_Edge_Completion_Id (Id);
      Result.Overload_RM_Status := Overload_RM.Overload_Generic_RM_Edge_Legal_Dispatching_Abstract_State_Effect_Accepted;
      Result.Representation_RM_Row := Representation_RM.Representation_Generic_RM_Hard_Case_Id (Id);
      Result.Representation_RM_Status := Representation_RM.Representation_Generic_RM_Hard_Case_Legal_Discriminant_Dependent_Layout_Accepted;
      Result.Tasking_RM_Row := Tasking_RM.Tasking_Generic_RM_Hard_Case_Id (Id);
      Result.Tasking_RM_Status := Tasking_RM.Tasking_Generic_RM_Hard_Case_Legal_Abstract_State_Backed_Task_Effect_Accepted;
      Result.AST_Repair_Row := AST_Repair.Coverage_Proven_AST_Repair_Id (Id);
      Result.AST_Repair_Status := AST_Repair.Coverage_Proven_AST_Repair_Consumer_Integration_Repaired;
      Result.Source_Fingerprint := 1255 * Id;
      Result.Expected_Source_Fingerprint := 1255 * Id;
      Result.Substitution_Fingerprint := 5521 * Id;
      Result.Expected_Substitution_Fingerprint := 5521 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Dataflow_Completion_Consumes_Completed_RM_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Dataflow_RM_Completion_Context_Model;
      Variant_Flow : C.Dataflow_RM_Completion_Context :=
        Complete_Context (1, C.Dataflow_RM_Completion_Variant_Component,
                          Editor.Ada_Syntax_Tree.Node_Id (125501));
      Dispatching_Flow : C.Dataflow_RM_Completion_Context :=
        Complete_Context (2, C.Dataflow_RM_Completion_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (125502));
   begin
      Variant_Flow.Requires_Predicate_RM := True;
      Variant_Flow.Requires_Representation_RM := True;
      Variant_Flow.Requires_AST_Repair := True;
      Dispatching_Flow.Requires_Elaboration_RM := True;
      Dispatching_Flow.Requires_Overload_RM := True;
      Dispatching_Flow.Requires_Tasking_RM := True;
      C.Add_Context (Contexts, Variant_Flow);
      C.Add_Context (Contexts, Dispatching_Flow);

      declare
         Model : constant C.Dataflow_RM_Completion_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two dataflow RM completion rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete RM evidence should accept dataflow conclusions");
         Assert (C.Blocked_Count (Model) = 0, "accepted rows should not block downstream closure");
         Assert
           (C.Count_By_Status (Model, C.Dataflow_RM_Completion_Legal_Variant_Component_Accepted) = 1,
            "variant-component dataflow should be accepted");
         Assert
           (C.Count_By_Status (Model, C.Dataflow_RM_Completion_Legal_Dispatching_Call_Accepted) = 1,
            "dispatching-call dataflow should be accepted");
      end;
   end Accepted_Dataflow_Completion_Consumes_Completed_RM_Evidence;

   procedure Missing_Or_Blocked_Completion_Prerequisites_Preserve_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Dataflow_RM_Completion_Context_Model;
      Cross_Blocker : C.Dataflow_RM_Completion_Context :=
        Complete_Context (1, C.Dataflow_RM_Completion_Cross_Unit_State,
                          Editor.Ada_Syntax_Tree.Node_Id (125521));
      Predicate_Blocker : C.Dataflow_RM_Completion_Context :=
        Complete_Context (2, C.Dataflow_RM_Completion_Return_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (125522));
      Representation_Blocker : C.Dataflow_RM_Completion_Context :=
        Complete_Context (3, C.Dataflow_RM_Completion_Volatile_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (125523));
   begin
      Cross_Blocker.Cross_RM_Row := Cross_RM.No_Cross_Unit_RM_Completion_Closure;
      Predicate_Blocker.Requires_Predicate_RM := True;
      Predicate_Blocker.Predicate_RM_Row := Predicate_RM.No_Predicate_RM_Completion_Row;
      Representation_Blocker.Requires_Representation_RM := True;
      Representation_Blocker.Representation_RM_Row := Representation_RM.No_Representation_Generic_RM_Hard_Case;
      C.Add_Context (Contexts, Cross_Blocker);
      C.Add_Context (Contexts, Predicate_Blocker);
      C.Add_Context (Contexts, Representation_Blocker);

      declare
         Model : constant C.Dataflow_RM_Completion_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept dataflow conclusions");
         Assert (C.Blocked_Count (Model) = 3, "three blockers should be retained");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Dataflow_RM_Completion_Blocker_Cross_Unit_RM_Completion) = 1,
            "cross-unit RM blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Dataflow_RM_Completion_Blocker_Predicate_RM_Completion) = 1,
            "predicate RM blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Dataflow_RM_Completion_Blocker_Representation_RM_Completion) = 1,
            "representation RM blocker family should be preserved");
      end;
   end Missing_Or_Blocked_Completion_Prerequisites_Preserve_Families;

   procedure Local_Dataflow_RM_Errors_Block_Before_Downstream_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Dataflow_RM_Completion_Context_Model;
      Read_Error : C.Dataflow_RM_Completion_Context :=
        Complete_Context (1, C.Dataflow_RM_Completion_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (125541));
      Merge_Error : C.Dataflow_RM_Completion_Context :=
        Complete_Context (2, C.Dataflow_RM_Completion_Read_Write,
                          Editor.Ada_Syntax_Tree.Node_Id (125542));
      Atomic_Error : C.Dataflow_RM_Completion_Context :=
        Complete_Context (3, C.Dataflow_RM_Completion_Atomic_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (125543));
   begin
      Read_Error.Read_Before_Write_Blocker := True;
      Merge_Error.Branch_Loop_Merge_Blocker := True;
      Atomic_Error.Volatile_Atomic_Effect_Blocker := True;
      C.Add_Context (Contexts, Read_Error);
      C.Add_Context (Contexts, Merge_Error);
      C.Add_Context (Contexts, Atomic_Error);

      declare
         Model : constant C.Dataflow_RM_Completion_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Dataflow_RM_Completion_Read_Before_Write_Blocker) = 1,
            "read-before-write should block directly");
         Assert
           (C.Count_By_Status (Model, C.Dataflow_RM_Completion_Branch_Loop_Merge_Blocker) = 1,
            "branch/loop merge should block directly");
         Assert
           (C.Count_By_Status (Model, C.Dataflow_RM_Completion_Volatile_Atomic_Effect_Blocker) = 1,
            "volatile/atomic effect should block directly");
      end;
   end Local_Dataflow_RM_Errors_Block_Before_Downstream_Evidence;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Dataflow_RM_Completion_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (125561);
      Item : C.Dataflow_RM_Completion_Context :=
        Complete_Context (1, C.Dataflow_RM_Completion_Access_Escape, Node);
   begin
      Item.Access_Escape_Blocker := True;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Dataflow_RM_Completion_Model := C.Build (Contexts);
         Row   : constant C.Dataflow_RM_Completion_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find dataflow RM completion evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find dataflow RM completion evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve the original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "dataflow RM completion model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Dataflow_Completion_Consumes_Completed_RM_Evidence'Access,
         "accepted dataflow completion consumes completed RM evidence");
      Register_Routine
        (T, Missing_Or_Blocked_Completion_Prerequisites_Preserve_Families'Access,
         "missing or blocked completion prerequisites preserve families");
      Register_Routine
        (T, Local_Dataflow_RM_Errors_Block_Before_Downstream_Evidence'Access,
         "local dataflow RM errors block before downstream evidence");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and family");
   end Register_Tests;

end Test_Ada_Dataflow_Generic_Shared_State_RM_Completion_Legality;
