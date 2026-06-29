with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality is

   package Registration renames AUnit.Test_Cases.Registration;
   package C renames Editor.Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality;
   use type C.Elaboration_RM_Completion_Row_Id;
   use type C.Elaboration_RM_Completion_Kind;
   use type C.Elaboration_RM_Completion_Blocker_Family;
   use type C.Elaboration_RM_Completion_Status;
   use type C.Elaboration_RM_Completion_Context;
   use type C.Elaboration_RM_Completion_Row;
   use type C.Elaboration_RM_Completion_Context_Model;
   use type C.Elaboration_RM_Completion_Model;
   use type C.Elaboration_RM_Completion_Set;
   package Cross_RM renames C.Cross_RM;
   package Prior_Elab renames C.Prior_Elab;
   package Overload_RM renames C.Overload_RM;
   package Representation_RM renames C.Representation_RM;
   package Tasking_RM renames C.Tasking_RM;
   package AST_Repair renames C.AST_Repair;
   package Exception_Generic renames C.Exception_Generic;
   package Renaming_Generic renames C.Renaming_Generic;
   package Predicate_Generic renames C.Predicate_Generic;
   package Dataflow_Generic renames C.Dataflow_Generic;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada elaboration generic shared-state RM completion legality");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Elaboration_RM_Completion_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Elaboration_RM_Completion_Context is
      Result : C.Elaboration_RM_Completion_Context;
   begin
      Result.Id := C.Elaboration_RM_Completion_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Unit_Name := To_Unbounded_String ("Unit" & Natural'Image (Id));
      Result.Target_Name := To_Unbounded_String ("Target" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("Generic" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("Instance" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Cross_RM_Row := Cross_RM.Cross_Unit_RM_Completion_Closure_Id (Id);
      Result.Cross_RM_Status := Cross_RM.Cross_Unit_RM_Completion_Legal_Generic_Instance_Accepted;
      Result.Prior_Elaboration_Row := Prior_Elab.Elaboration_Generic_Final_Row_Id (Id);
      Result.Prior_Elaboration_Status := Prior_Elab.Elaboration_Generic_Final_Legal_Generic_Instance_Accepted;
      Result.Overload_RM_Row := Overload_RM.Overload_Generic_RM_Edge_Completion_Id (Id);
      Result.Overload_RM_Status := Overload_RM.Overload_Generic_RM_Edge_Legal_Dispatching_Abstract_State_Effect_Accepted;
      Result.Representation_RM_Row := Representation_RM.Representation_Generic_RM_Hard_Case_Id (Id);
      Result.Representation_RM_Status := Representation_RM.Representation_Generic_RM_Hard_Case_Legal_Generic_Formal_Instance_Freezing_Accepted;
      Result.Tasking_RM_Row := Tasking_RM.Tasking_Generic_RM_Hard_Case_Id (Id);
      Result.Tasking_RM_Status := Tasking_RM.Tasking_Generic_RM_Hard_Case_Legal_Generic_Task_Protected_Body_Effect_Accepted;
      Result.AST_Repair_Row := AST_Repair.Coverage_Proven_AST_Repair_Id (Id);
      Result.AST_Repair_Status := AST_Repair.Coverage_Proven_AST_Repair_Consumer_Integration_Repaired;
      Result.Exception_Generic_Row := Exception_Generic.Exception_Generic_Final_Row_Id (Id);
      Result.Exception_Generic_Status := Exception_Generic.Exception_Generic_Final_Legal_Cross_Unit_Finalization_Accepted;
      Result.Renaming_Generic_Row := Renaming_Generic.Renaming_Generic_Final_Row_Id (Id);
      Result.Renaming_Generic_Status := Renaming_Generic.Renaming_Generic_Final_Legal_Generic_Renaming_Accepted;
      Result.Predicate_Generic_Row := Predicate_Generic.Predicate_Generic_Final_Row_Id (Id);
      Result.Predicate_Generic_Status := Predicate_Generic.Predicate_Generic_Final_Legal_Cross_Unit_State_Accepted;
      Result.Dataflow_Generic_Row := Dataflow_Generic.Dataflow_Generic_Final_Row_Id (Id);
      Result.Dataflow_Generic_Status := Dataflow_Generic.Dataflow_Generic_Final_Legal_Cross_Unit_State_Accepted;
      Result.Source_Fingerprint := 1251 * Id;
      Result.Expected_Source_Fingerprint := 1251 * Id;
      Result.Substitution_Fingerprint := 1521 * Id;
      Result.Expected_Substitution_Fingerprint := 1521 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Elaboration_Consumes_Completed_RM_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Elaboration_RM_Completion_Context_Model;
      Instance : C.Elaboration_RM_Completion_Context :=
        Complete_Context (1, C.Elaboration_RM_Completion_Generic_Instance,
                          Editor.Ada_Syntax_Tree.Node_Id (125101));
      Task_Activation : C.Elaboration_RM_Completion_Context :=
        Complete_Context (2, C.Elaboration_RM_Completion_Task_Activation,
                          Editor.Ada_Syntax_Tree.Node_Id (125102));
   begin
      Instance.Requires_AST_Repair := True;
      Task_Activation.Requires_AST_Repair := True;
      C.Add_Context (Contexts, Instance);
      C.Add_Context (Contexts, Task_Activation);

      declare
         Model : constant C.Elaboration_RM_Completion_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two elaboration RM completion rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete RM evidence should accept elaboration conclusions");
         Assert (C.Blocked_Count (Model) = 0, "accepted rows should not block downstream closure");
         Assert
           (C.Count_By_Status (Model, C.Elaboration_RM_Completion_Legal_Generic_Instance_Accepted) = 1,
            "generic instance elaboration should be accepted");
         Assert
           (C.Count_By_Status (Model, C.Elaboration_RM_Completion_Legal_Task_Activation_Accepted) = 1,
            "task activation elaboration should be accepted");
      end;
   end Accepted_Elaboration_Consumes_Completed_RM_Evidence;

   procedure Missing_Or_Blocked_Completion_Prerequisites_Preserve_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Elaboration_RM_Completion_Context_Model;
      Cross_Blocker : C.Elaboration_RM_Completion_Context :=
        Complete_Context (1, C.Elaboration_RM_Completion_Cross_Unit_Body,
                          Editor.Ada_Syntax_Tree.Node_Id (125121));
      Representation_Blocker : C.Elaboration_RM_Completion_Context :=
        Complete_Context (2, C.Elaboration_RM_Completion_Representation_Item,
                          Editor.Ada_Syntax_Tree.Node_Id (125122));
      Dataflow_Blocker : C.Elaboration_RM_Completion_Context :=
        Complete_Context (3, C.Elaboration_RM_Completion_Dataflow_Edge,
                          Editor.Ada_Syntax_Tree.Node_Id (125123));
   begin
      Cross_Blocker.Cross_RM_Status := Cross_RM.Cross_Unit_RM_Completion_Representation_RM_Blocker;
      Representation_Blocker.Representation_RM_Status := Representation_RM.Representation_Generic_RM_Hard_Case_Protected_Task_Representation_Blocker;
      Dataflow_Blocker.Dataflow_Generic_Status := Dataflow_Generic.Dataflow_Generic_Final_Exception_Path_Blocker;
      C.Add_Context (Contexts, Cross_Blocker);
      C.Add_Context (Contexts, Representation_Blocker);
      C.Add_Context (Contexts, Dataflow_Blocker);

      declare
         Model : constant C.Elaboration_RM_Completion_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept elaboration RM conclusions");
         Assert (C.Blocked_Count (Model) = 3, "three blockers should be retained");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Elaboration_RM_Completion_Blocker_Cross_Unit_RM_Completion) = 1,
            "cross-unit RM blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Elaboration_RM_Completion_Blocker_Representation_RM_Completion) = 1,
            "representation RM blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Elaboration_RM_Completion_Blocker_Dataflow_Initialization) = 1,
            "dataflow blocker family should be preserved");
      end;
   end Missing_Or_Blocked_Completion_Prerequisites_Preserve_Families;

   procedure Local_Elaboration_RM_Errors_Block_Before_Downstream_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Elaboration_RM_Completion_Context_Model;
      Order_Error : C.Elaboration_RM_Completion_Context :=
        Complete_Context (1, C.Elaboration_RM_Completion_Aspect_Expression,
                          Editor.Ada_Syntax_Tree.Node_Id (125141));
      Pure_Error : C.Elaboration_RM_Completion_Context :=
        Complete_Context (2, C.Elaboration_RM_Completion_Pure_Policy,
                          Editor.Ada_Syntax_Tree.Node_Id (125142));
      Shared_Passive_Error : C.Elaboration_RM_Completion_Context :=
        Complete_Context (3, C.Elaboration_RM_Completion_Shared_Passive_Policy,
                          Editor.Ada_Syntax_Tree.Node_Id (125143));
   begin
      Order_Error.Elaboration_Order_Error := True;
      Pure_Error.Pure_Policy_Error := True;
      Shared_Passive_Error.Shared_Passive_Policy_Error := True;
      C.Add_Context (Contexts, Order_Error);
      C.Add_Context (Contexts, Pure_Error);
      C.Add_Context (Contexts, Shared_Passive_Error);

      declare
         Model : constant C.Elaboration_RM_Completion_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Elaboration_RM_Completion_Elaboration_Order_Blocker) = 1,
            "elaboration order errors should block directly");
         Assert
           (C.Count_By_Status (Model, C.Elaboration_RM_Completion_Pure_Policy_Blocker) = 1,
            "Pure policy errors should block directly");
         Assert
           (C.Count_By_Status (Model, C.Elaboration_RM_Completion_Shared_Passive_Policy_Blocker) = 1,
            "Shared_Passive policy errors should block directly");
      end;
   end Local_Elaboration_RM_Errors_Block_Before_Downstream_Evidence;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Elaboration_RM_Completion_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (125161);
      Item : C.Elaboration_RM_Completion_Context :=
        Complete_Context (1, C.Elaboration_RM_Completion_Exception_Finalization, Node);
   begin
      Item.Exception_Generic_Status := Exception_Generic.Exception_Generic_Final_Finalization_Order_Blocker;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Elaboration_RM_Completion_Model := C.Build (Contexts);
         Row   : constant C.Elaboration_RM_Completion_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find elaboration RM completion evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find elaboration RM completion evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve the original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "elaboration RM completion model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Elaboration_Consumes_Completed_RM_Evidence'Access,
         "accepted elaboration consumes completed RM evidence");
      Register_Routine
        (T, Missing_Or_Blocked_Completion_Prerequisites_Preserve_Families'Access,
         "missing or blocked completion prerequisites preserve families");
      Register_Routine
        (T, Local_Elaboration_RM_Errors_Block_Before_Downstream_Evidence'Access,
         "local elaboration RM errors block before downstream evidence");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and blocker family");
   end Register_Tests;

end Test_Ada_Elaboration_Generic_Shared_State_RM_Completion_Legality;
