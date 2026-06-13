with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Exception_Finalization_Generic_Shared_State_Final_Legality_Pass1235 is

   package C renames Editor.Ada_Exception_Finalization_Generic_Shared_State_Final_Legality;
   use type C.Exception_Generic_Final_Row_Id;
   use type C.Exception_Generic_Final_Kind;
   use type C.Exception_Generic_Final_Blocker_Family;
   use type C.Exception_Generic_Final_Status;
   use type C.Exception_Generic_Final_Context;
   use type C.Exception_Generic_Final_Row;
   use type C.Exception_Generic_Final_Context_Model;
   use type C.Exception_Generic_Final_Model;
   use type C.Exception_Generic_Final_Set;
   package Exception_Final renames C.Exception_Final;
   package Cross_Generic renames C.Cross_Generic;
   package Elab_Generic renames C.Elab_Generic;
   package Generic_Replay renames C.Generic_Replay;
   package Overload_Generic renames C.Overload_Generic;
   package Rep_Generic renames C.Rep_Generic;
   package Tasking_Generic renames C.Tasking_Generic;
   package Access_Generic renames C.Access_Generic;
   package Disc_Generic renames C.Disc_Generic;
   package Closure renames C.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada exception/finalization generic shared-state final legality pass1235");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Exception_Generic_Final_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Exception_Generic_Final_Context is
      Result : C.Exception_Generic_Final_Context;
   begin
      Result.Id := C.Exception_Generic_Final_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Exception_Name := To_Unbounded_String ("E" & Natural'Image (Id));
      Result.Object_Name := To_Unbounded_String ("Obj" & Natural'Image (Id));
      Result.Type_Name := To_Unbounded_String ("T" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("G" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("I" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Exception_Final_Row := Exception_Final.Exception_Legality_Id (Id);
      Result.Exception_Final_Status := Exception_Final.Exception_Legality_Legal_Finalization;
      Result.Cross_Generic_Row := Cross_Generic.Cross_Unit_Generic_Final_Row_Id (Id);
      Result.Cross_Generic_Status := Cross_Generic.Cross_Unit_Generic_Final_Legal_Generic_Instance_Accepted;
      Result.Elaboration_Generic_Row := Elab_Generic.Elaboration_Generic_Final_Row_Id (Id);
      Result.Elaboration_Generic_Status := Elab_Generic.Elaboration_Generic_Final_Legal_Generic_Instance_Accepted;
      Result.Generic_Replay_Row := Generic_Replay.Generic_Abstract_Replay_Row_Id (Id);
      Result.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Legal_Nested_Instance_State_Accepted;
      Result.Overload_Generic_Row := Overload_Generic.Overload_Generic_Final_Row_Id (Id);
      Result.Overload_Generic_Status := Overload_Generic.Overload_Generic_Final_Legal_Generic_Formal_Subprogram_Accepted;
      Result.Representation_Generic_Row := Rep_Generic.Representation_Generic_Final_Row_Id (Id);
      Result.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Legal_Variant_Record_Layout_Accepted;
      Result.Tasking_Generic_Row := Tasking_Generic.Tasking_Generic_Final_Row_Id (Id);
      Result.Tasking_Generic_Status := Tasking_Generic.Tasking_Generic_Final_Legal_Generic_Protected_Body_Accepted;
      Result.Accessibility_Generic_Row := Access_Generic.Accessibility_Generic_Final_Row_Id (Id);
      Result.Accessibility_Generic_Status := Access_Generic.Accessibility_Generic_Final_Legal_Controlled_Finalization_Accepted;
      Result.Discriminant_Generic_Row := Disc_Generic.Discriminant_Generic_Final_Row_Id (Id);
      Result.Discriminant_Generic_Status := Disc_Generic.Discriminant_Generic_Final_Legal_Variant_Record_Layout_Accepted;
      Result.Stabilized_Closure_Row := Closure.Shared_State_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1235 * Id;
      Result.Expected_Source_Fingerprint := 1235 * Id;
      Result.Substitution_Fingerprint := 5321 * Id;
      Result.Expected_Substitution_Fingerprint := 5321 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Exception_Finalization_Requires_Generic_Shared_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Exception_Generic_Final_Context_Model;
      Finalize : C.Exception_Generic_Final_Context :=
        Complete_Context (1, C.Exception_Generic_Final_Controlled_Finalize,
                          Editor.Ada_Syntax_Tree.Node_Id (123501));
      Terminate_Context : C.Exception_Generic_Final_Context :=
        Complete_Context (2, C.Exception_Generic_Final_Task_Termination,
                          Editor.Ada_Syntax_Tree.Node_Id (123502));
   begin
      Finalize.Requires_Representation_Generic := True;
      Finalize.Requires_Accessibility_Generic := True;
      Finalize.Requires_Discriminant_Generic := True;
      Terminate_Context.Requires_Tasking_Generic := True;
      Terminate_Context.Requires_Elaboration_Generic := True;
      Terminate_Context.Requires_Generic_Replay := True;
      C.Add_Context (Contexts, Finalize);
      C.Add_Context (Contexts, Terminate_Context);

      declare
         Model : constant C.Exception_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two exception/finalization rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete finalization and shared-state evidence should accept");
         Assert (C.Blocked_Count (Model) = 0, "accepted finalization rows should not block downstream legality");
         Assert
           (C.Count_By_Status (Model, C.Exception_Generic_Final_Legal_Controlled_Finalize_Accepted) = 1,
            "controlled finalization should be accepted");
         Assert
           (C.Count_By_Status (Model, C.Exception_Generic_Final_Legal_Task_Termination_Accepted) = 1,
            "task termination finalization should be accepted");
      end;
   end Accepted_Exception_Finalization_Requires_Generic_Shared_State_Evidence;

   procedure Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Exception_Generic_Final_Context_Model;
      Exception_Blocker : C.Exception_Generic_Final_Context :=
        Complete_Context (1, C.Exception_Generic_Final_Raise_Statement,
                          Editor.Ada_Syntax_Tree.Node_Id (123521));
      Tasking_Blocker : C.Exception_Generic_Final_Context :=
        Complete_Context (2, C.Exception_Generic_Final_Task_Termination,
                          Editor.Ada_Syntax_Tree.Node_Id (123522));
      Disc_Blocker : C.Exception_Generic_Final_Context :=
        Complete_Context (3, C.Exception_Generic_Final_Controlled_Finalize,
                          Editor.Ada_Syntax_Tree.Node_Id (123523));
   begin
      Exception_Blocker.Exception_Final_Status := Exception_Final.Exception_Legality_Raise_Target_Unresolved;
      Tasking_Blocker.Requires_Tasking_Generic := True;
      Tasking_Blocker.Tasking_Generic_Status := Tasking_Generic.Tasking_Generic_Final_Representation_Sensitive_Tasking_Blocker;
      Disc_Blocker.Requires_Discriminant_Generic := True;
      Disc_Blocker.Discriminant_Generic_Status := Disc_Generic.Discriminant_Generic_Final_Variant_Coverage_Blocker;
      C.Add_Context (Contexts, Exception_Blocker);
      C.Add_Context (Contexts, Tasking_Blocker);
      C.Add_Context (Contexts, Disc_Blocker);

      declare
         Model : constant C.Exception_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept finalization conclusions");
         Assert (C.Blocked_Count (Model) = 3, "three prerequisite blockers should be retained");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Exception_Generic_Final_Blocker_Exception_Finalization) = 1,
            "exception/finalization blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Exception_Generic_Final_Blocker_Tasking_Generic_Shared_State) = 1,
            "tasking generic/shared-state blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Exception_Generic_Final_Blocker_Discriminant_Generic_Shared_State) = 1,
            "discriminant generic/shared-state blocker family should be preserved");
      end;
   end Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family;

   procedure Local_Exception_Finalization_RM_Errors_Block_Directly
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Exception_Generic_Final_Context_Model;
      Handler_Error : C.Exception_Generic_Final_Context :=
        Complete_Context (1, C.Exception_Generic_Final_Handler,
                          Editor.Ada_Syntax_Tree.Node_Id (123541));
      Order_Error : C.Exception_Generic_Final_Context :=
        Complete_Context (2, C.Exception_Generic_Final_Master_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (123542));
      Abort_Error : C.Exception_Generic_Final_Context :=
        Complete_Context (3, C.Exception_Generic_Final_Abort_Deferred_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (123543));
   begin
      Handler_Error.Handler_Coverage_Blocker := True;
      Order_Error.Finalization_Order_Blocker := True;
      Abort_Error.Abort_Finalization_Blocker := True;
      C.Add_Context (Contexts, Handler_Error);
      C.Add_Context (Contexts, Order_Error);
      C.Add_Context (Contexts, Abort_Error);

      declare
         Model : constant C.Exception_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Exception_Generic_Final_Handler_Coverage_Blocker) = 1,
            "handler coverage errors should block directly");
         Assert
           (C.Count_By_Status (Model, C.Exception_Generic_Final_Finalization_Order_Blocker) = 1,
            "finalization ordering errors should block directly");
         Assert
           (C.Count_By_Status (Model, C.Exception_Generic_Final_Abort_Finalization_Blocker) = 1,
            "abort/deferred-finalization errors should block directly");
      end;
   end Local_Exception_Finalization_RM_Errors_Block_Directly;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Exception_Generic_Final_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (123561);
      Item : C.Exception_Generic_Final_Context :=
        Complete_Context (1, C.Exception_Generic_Final_Cross_Unit_Finalization, Node);
   begin
      Item.Requires_Representation_Generic := True;
      Item.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Variant_Layout_Blocker;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Exception_Generic_Final_Model := C.Build (Contexts);
         Row   : constant C.Exception_Generic_Final_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find exception/finalization generic shared-state evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find exception/finalization generic shared-state evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve the original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "exception/finalization generic shared-state final model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Exception_Finalization_Requires_Generic_Shared_State_Evidence'Access,
         "accepted exception/finalization requires generic shared-state evidence");
      Register_Routine
        (T, Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family'Access,
         "missing or blocked prerequisites preserve blocker family");
      Register_Routine
        (T, Local_Exception_Finalization_RM_Errors_Block_Directly'Access,
         "local exception/finalization RM errors block directly");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and blocker family");
   end Register_Tests;

end Test_Ada_Exception_Finalization_Generic_Shared_State_Final_Legality_Pass1235;
