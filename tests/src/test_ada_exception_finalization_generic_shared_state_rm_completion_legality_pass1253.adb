with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality_Pass1253 is

   package Registration renames AUnit.Test_Cases.Registration;
   package C renames Editor.Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality;
   use type C.Exception_RM_Completion_Row_Id;
   use type C.Exception_RM_Completion_Kind;
   use type C.Exception_RM_Completion_Blocker_Family;
   use type C.Exception_RM_Completion_Status;
   use type C.Exception_RM_Completion_Context;
   use type C.Exception_RM_Completion_Row;
   use type C.Exception_RM_Completion_Context_Model;
   use type C.Exception_RM_Completion_Model;
   use type C.Exception_RM_Completion_Set;
   package Cross_RM renames C.Cross_RM;
   package Prior_Exception renames C.Prior_Exception;
   package Elaboration_RM renames C.Elaboration_RM;
   package Accessibility_RM renames C.Accessibility_RM;
   package Overload_RM renames C.Overload_RM;
   package Representation_RM renames C.Representation_RM;
   package Tasking_RM renames C.Tasking_RM;
   package AST_Repair renames C.AST_Repair;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada exception finalization generic shared-state RM completion legality pass1253");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Exception_RM_Completion_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Exception_RM_Completion_Context is
      Result : C.Exception_RM_Completion_Context;
   begin
      Result.Id := C.Exception_RM_Completion_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Unit_Name := To_Unbounded_String ("Unit" & Natural'Image (Id));
      Result.Exception_Name := To_Unbounded_String ("Exception" & Natural'Image (Id));
      Result.Object_Name := To_Unbounded_String ("Object" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("Generic" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("Instance" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Cross_RM_Row := Cross_RM.Cross_Unit_RM_Completion_Closure_Id (Id);
      Result.Cross_RM_Status := Cross_RM.Cross_Unit_RM_Completion_Legal_Generic_Instance_Accepted;
      Result.Prior_Exception_Row := Prior_Exception.Exception_Generic_Final_Row_Id (Id);
      Result.Prior_Exception_Status := Prior_Exception.Exception_Generic_Final_Legal_Controlled_Finalize_Accepted;
      Result.Elaboration_RM_Row := Elaboration_RM.Elaboration_RM_Completion_Row_Id (Id);
      Result.Elaboration_RM_Status := Elaboration_RM.Elaboration_RM_Completion_Legal_Exception_Finalization_Accepted;
      Result.Accessibility_RM_Row := Accessibility_RM.Accessibility_RM_Completion_Row_Id (Id);
      Result.Accessibility_RM_Status := Accessibility_RM.Accessibility_RM_Completion_Legal_Controlled_Finalization_Accepted;
      Result.Overload_RM_Row := Overload_RM.Overload_Generic_RM_Edge_Completion_Id (Id);
      Result.Overload_RM_Status := Overload_RM.Overload_Generic_RM_Edge_Legal_Access_Subprogram_Effect_Profile_Accepted;
      Result.Representation_RM_Row := Representation_RM.Representation_Generic_RM_Hard_Case_Id (Id);
      Result.Representation_RM_Status := Representation_RM.Representation_Generic_RM_Hard_Case_Legal_Controlled_Finalized_Component_Accepted;
      Result.Tasking_RM_Row := Tasking_RM.Tasking_Generic_RM_Hard_Case_Id (Id);
      Result.Tasking_RM_Status := Tasking_RM.Tasking_Generic_RM_Hard_Case_Legal_Abort_Finalization_Ordering_Accepted;
      Result.AST_Repair_Row := AST_Repair.Coverage_Proven_AST_Repair_Id (Id);
      Result.AST_Repair_Status := AST_Repair.Coverage_Proven_AST_Repair_Consumer_Integration_Repaired;
      Result.Source_Fingerprint := 1253 * Id;
      Result.Expected_Source_Fingerprint := 1253 * Id;
      Result.Substitution_Fingerprint := 3521 * Id;
      Result.Expected_Substitution_Fingerprint := 3521 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Exception_Finalization_Consumes_Completed_RM_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Exception_RM_Completion_Context_Model;
      Controlled_Finalize : C.Exception_RM_Completion_Context :=
        Complete_Context (1, C.Exception_RM_Completion_Controlled_Finalize,
                          Editor.Ada_Syntax_Tree.Node_Id (125301));
      Master_Finalization : C.Exception_RM_Completion_Context :=
        Complete_Context (2, C.Exception_RM_Completion_Master_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (125302));
   begin
      Controlled_Finalize.Requires_AST_Repair := True;
      Master_Finalization.Requires_AST_Repair := True;
      C.Add_Context (Contexts, Controlled_Finalize);
      C.Add_Context (Contexts, Master_Finalization);

      declare
         Model : constant C.Exception_RM_Completion_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two exception/finalization RM completion rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete RM evidence should accept finalization conclusions");
         Assert (C.Blocked_Count (Model) = 0, "accepted rows should not block downstream closure");
         Assert
           (C.Count_By_Status (Model, C.Exception_RM_Completion_Legal_Controlled_Finalize_Accepted) = 1,
            "controlled finalize should be accepted");
         Assert
           (C.Count_By_Status (Model, C.Exception_RM_Completion_Legal_Master_Finalization_Accepted) = 1,
            "master finalization should be accepted");
      end;
   end Accepted_Exception_Finalization_Consumes_Completed_RM_Evidence;

   procedure Missing_Or_Blocked_Completion_Prerequisites_Preserve_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Exception_RM_Completion_Context_Model;
      Cross_Blocker : C.Exception_RM_Completion_Context :=
        Complete_Context (1, C.Exception_RM_Completion_Cross_Unit_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (125321));
      Elaboration_Blocker : C.Exception_RM_Completion_Context :=
        Complete_Context (2, C.Exception_RM_Completion_Exception_Propagation,
                          Editor.Ada_Syntax_Tree.Node_Id (125322));
      Accessibility_Blocker : C.Exception_RM_Completion_Context :=
        Complete_Context (3, C.Exception_RM_Completion_Accessibility_Master_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (125323));
   begin
      Cross_Blocker.Cross_RM_Status := Cross_RM.Cross_Unit_RM_Completion_State_Visibility_Blocker;
      Elaboration_Blocker.Elaboration_RM_Status := Elaboration_RM.Elaboration_RM_Completion_Elaboration_Order_Blocker;
      Accessibility_Blocker.Accessibility_RM_Status := Accessibility_RM.Accessibility_RM_Completion_Master_Escape_Blocker;
      C.Add_Context (Contexts, Cross_Blocker);
      C.Add_Context (Contexts, Elaboration_Blocker);
      C.Add_Context (Contexts, Accessibility_Blocker);

      declare
         Model : constant C.Exception_RM_Completion_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept exception/finalization conclusions");
         Assert (C.Blocked_Count (Model) = 3, "three blockers should be retained");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Exception_RM_Completion_Blocker_Cross_Unit_RM_Completion) = 1,
            "cross-unit RM blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Exception_RM_Completion_Blocker_Elaboration_RM_Completion) = 1,
            "elaboration RM blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Exception_RM_Completion_Blocker_Accessibility_RM_Completion) = 1,
            "accessibility RM blocker family should be preserved");
      end;
   end Missing_Or_Blocked_Completion_Prerequisites_Preserve_Families;

   procedure Local_Exception_Finalization_RM_Errors_Block_Before_Downstream_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Exception_RM_Completion_Context_Model;
      Propagation : C.Exception_RM_Completion_Context :=
        Complete_Context (1, C.Exception_RM_Completion_Exception_Propagation,
                          Editor.Ada_Syntax_Tree.Node_Id (125341));
      Finalize : C.Exception_RM_Completion_Context :=
        Complete_Context (2, C.Exception_RM_Completion_Controlled_Finalize,
                          Editor.Ada_Syntax_Tree.Node_Id (125342));
      Cleanup : C.Exception_RM_Completion_Context :=
        Complete_Context (3, C.Exception_RM_Completion_Cleanup_Action,
                          Editor.Ada_Syntax_Tree.Node_Id (125343));
   begin
      Propagation.Exception_Propagation_Error := True;
      Finalize.Finalize_Order_Error := True;
      Cleanup.Cleanup_Path_Error := True;
      C.Add_Context (Contexts, Propagation);
      C.Add_Context (Contexts, Finalize);
      C.Add_Context (Contexts, Cleanup);

      declare
         Model : constant C.Exception_RM_Completion_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Exception_RM_Completion_Exception_Propagation_Blocker) = 1,
            "exception propagation should block directly");
         Assert
           (C.Count_By_Status (Model, C.Exception_RM_Completion_Finalize_Order_Blocker) = 1,
            "finalization order should block directly");
         Assert
           (C.Count_By_Status (Model, C.Exception_RM_Completion_Cleanup_Path_Blocker) = 1,
            "cleanup path should block directly");
      end;
   end Local_Exception_Finalization_RM_Errors_Block_Before_Downstream_Evidence;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Exception_RM_Completion_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (125361);
      Item : C.Exception_RM_Completion_Context :=
        Complete_Context (1, C.Exception_RM_Completion_Task_Termination, Node);
   begin
      Item.Task_Termination_Error := True;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Exception_RM_Completion_Model := C.Build (Contexts);
         Row   : constant C.Exception_RM_Completion_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find exception/finalization RM completion evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find exception/finalization RM completion evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve the original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "exception/finalization RM completion model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Exception_Finalization_Consumes_Completed_RM_Evidence'Access,
         "accepted exception/finalization consumes completed RM evidence");
      Register_Routine
        (T, Missing_Or_Blocked_Completion_Prerequisites_Preserve_Families'Access,
         "missing or blocked completion prerequisites preserve families");
      Register_Routine
        (T, Local_Exception_Finalization_RM_Errors_Block_Before_Downstream_Evidence'Access,
         "local exception/finalization RM errors block before downstream evidence");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and blocker family");
   end Register_Tests;

end Test_Ada_Exception_Finalization_Generic_Shared_State_RM_Completion_Legality_Pass1253;
