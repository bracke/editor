with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Generic_Shared_State_RM_Completion_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Accessibility_Generic_Shared_State_RM_Completion_Legality_Pass1252 is

   package Registration renames AUnit.Test_Cases.Registration;
   package C renames Editor.Ada_Accessibility_Generic_Shared_State_RM_Completion_Legality;
   use type C.Accessibility_RM_Completion_Row_Id;
   use type C.Accessibility_RM_Completion_Kind;
   use type C.Accessibility_RM_Completion_Blocker_Family;
   use type C.Accessibility_RM_Completion_Status;
   use type C.Accessibility_RM_Completion_Context;
   use type C.Accessibility_RM_Completion_Row;
   use type C.Accessibility_RM_Completion_Context_Model;
   use type C.Accessibility_RM_Completion_Model;
   use type C.Accessibility_RM_Completion_Set;
   package Cross_RM renames C.Cross_RM;
   package Prior_Access renames C.Prior_Access;
   package Elaboration_RM renames C.Elaboration_RM;
   package Overload_RM renames C.Overload_RM;
   package Representation_RM renames C.Representation_RM;
   package Tasking_RM renames C.Tasking_RM;
   package AST_Repair renames C.AST_Repair;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada accessibility generic shared-state RM completion legality pass1252");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Accessibility_RM_Completion_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Accessibility_RM_Completion_Context is
      Result : C.Accessibility_RM_Completion_Context;
   begin
      Result.Id := C.Accessibility_RM_Completion_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Object_Name := To_Unbounded_String ("Object" & Natural'Image (Id));
      Result.Type_Name := To_Unbounded_String ("Type" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("Generic" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("Instance" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Cross_RM_Row := Cross_RM.Cross_Unit_RM_Completion_Closure_Id (Id);
      Result.Cross_RM_Status := Cross_RM.Cross_Unit_RM_Completion_Legal_Generic_Instance_Accepted;
      Result.Prior_Accessibility_Row := Prior_Access.Accessibility_Generic_Final_Row_Id (Id);
      Result.Prior_Accessibility_Status := Prior_Access.Accessibility_Generic_Final_Legal_Generic_Access_Actual_Accepted;
      Result.Elaboration_RM_Row := Elaboration_RM.Elaboration_RM_Completion_Row_Id (Id);
      Result.Elaboration_RM_Status := Elaboration_RM.Elaboration_RM_Completion_Legal_Generic_Instance_Accepted;
      Result.Overload_RM_Row := Overload_RM.Overload_Generic_RM_Edge_Completion_Id (Id);
      Result.Overload_RM_Status := Overload_RM.Overload_Generic_RM_Edge_Legal_Access_Subprogram_Effect_Profile_Accepted;
      Result.Representation_RM_Row := Representation_RM.Representation_Generic_RM_Hard_Case_Id (Id);
      Result.Representation_RM_Status := Representation_RM.Representation_Generic_RM_Hard_Case_Legal_Controlled_Finalized_Component_Accepted;
      Result.Tasking_RM_Row := Tasking_RM.Tasking_Generic_RM_Hard_Case_Id (Id);
      Result.Tasking_RM_Status := Tasking_RM.Tasking_Generic_RM_Hard_Case_Legal_Protected_Shared_State_Access_Accepted;
      Result.AST_Repair_Row := AST_Repair.Coverage_Proven_AST_Repair_Id (Id);
      Result.AST_Repair_Status := AST_Repair.Coverage_Proven_AST_Repair_Consumer_Integration_Repaired;
      Result.Source_Fingerprint := 1252 * Id;
      Result.Expected_Source_Fingerprint := 1252 * Id;
      Result.Substitution_Fingerprint := 2521 * Id;
      Result.Expected_Substitution_Fingerprint := 2521 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Accessibility_Consumes_Completed_RM_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Accessibility_RM_Completion_Context_Model;
      Access_Actual : C.Accessibility_RM_Completion_Context :=
        Complete_Context (1, C.Accessibility_RM_Completion_Generic_Access_Actual,
                          Editor.Ada_Syntax_Tree.Node_Id (125201));
      Return_Access : C.Accessibility_RM_Completion_Context :=
        Complete_Context (2, C.Accessibility_RM_Completion_Return_Access,
                          Editor.Ada_Syntax_Tree.Node_Id (125202));
   begin
      Access_Actual.Requires_AST_Repair := True;
      Return_Access.Requires_AST_Repair := True;
      C.Add_Context (Contexts, Access_Actual);
      C.Add_Context (Contexts, Return_Access);

      declare
         Model : constant C.Accessibility_RM_Completion_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two accessibility RM completion rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete RM evidence should accept accessibility conclusions");
         Assert (C.Blocked_Count (Model) = 0, "accepted rows should not block downstream closure");
         Assert
           (C.Count_By_Status (Model, C.Accessibility_RM_Completion_Legal_Generic_Access_Actual_Accepted) = 1,
            "generic access actual accessibility should be accepted");
         Assert
           (C.Count_By_Status (Model, C.Accessibility_RM_Completion_Legal_Return_Access_Accepted) = 1,
            "return access accessibility should be accepted");
      end;
   end Accepted_Accessibility_Consumes_Completed_RM_Evidence;

   procedure Missing_Or_Blocked_Completion_Prerequisites_Preserve_Families
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Accessibility_RM_Completion_Context_Model;
      Cross_Blocker : C.Accessibility_RM_Completion_Context :=
        Complete_Context (1, C.Accessibility_RM_Completion_Cross_Unit_Lifetime,
                          Editor.Ada_Syntax_Tree.Node_Id (125221));
      Elaboration_Blocker : C.Accessibility_RM_Completion_Context :=
        Complete_Context (2, C.Accessibility_RM_Completion_Allocator_Master,
                          Editor.Ada_Syntax_Tree.Node_Id (125222));
      Representation_Blocker : C.Accessibility_RM_Completion_Context :=
        Complete_Context (3, C.Accessibility_RM_Completion_Representation_Sensitive_Lifetime,
                          Editor.Ada_Syntax_Tree.Node_Id (125223));
   begin
      Cross_Blocker.Cross_RM_Status := Cross_RM.Cross_Unit_RM_Completion_State_Visibility_Blocker;
      Elaboration_Blocker.Elaboration_RM_Status := Elaboration_RM.Elaboration_RM_Completion_Elaboration_Order_Blocker;
      Representation_Blocker.Representation_RM_Status := Representation_RM.Representation_Generic_RM_Hard_Case_Controlled_Finalization_Blocker;
      C.Add_Context (Contexts, Cross_Blocker);
      C.Add_Context (Contexts, Elaboration_Blocker);
      C.Add_Context (Contexts, Representation_Blocker);

      declare
         Model : constant C.Accessibility_RM_Completion_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept accessibility RM conclusions");
         Assert (C.Blocked_Count (Model) = 3, "three blockers should be retained");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Accessibility_RM_Completion_Blocker_Cross_Unit_RM_Completion) = 1,
            "cross-unit RM blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Accessibility_RM_Completion_Blocker_Elaboration_RM_Completion) = 1,
            "elaboration RM blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Accessibility_RM_Completion_Blocker_Representation_RM_Completion) = 1,
            "representation RM blocker family should be preserved");
      end;
   end Missing_Or_Blocked_Completion_Prerequisites_Preserve_Families;

   procedure Local_Accessibility_RM_Errors_Block_Before_Downstream_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Accessibility_RM_Completion_Context_Model;
      Master_Escape : C.Accessibility_RM_Completion_Context :=
        Complete_Context (1, C.Accessibility_RM_Completion_Return_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (125241));
      Variant_Access : C.Accessibility_RM_Completion_Context :=
        Complete_Context (2, C.Accessibility_RM_Completion_Variant_Component_Access,
                          Editor.Ada_Syntax_Tree.Node_Id (125242));
      Protected_Access : C.Accessibility_RM_Completion_Context :=
        Complete_Context (3, C.Accessibility_RM_Completion_Protected_Access,
                          Editor.Ada_Syntax_Tree.Node_Id (125243));
   begin
      Master_Escape.Master_Escape_Blocker := True;
      Variant_Access.Variant_Component_Access_Blocker := True;
      Protected_Access.Protected_Access_Blocker := True;
      C.Add_Context (Contexts, Master_Escape);
      C.Add_Context (Contexts, Variant_Access);
      C.Add_Context (Contexts, Protected_Access);

      declare
         Model : constant C.Accessibility_RM_Completion_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Accessibility_RM_Completion_Master_Escape_Blocker) = 1,
            "master escape should block directly");
         Assert
           (C.Count_By_Status (Model, C.Accessibility_RM_Completion_Variant_Component_Access_Blocker) = 1,
            "variant component access should block directly");
         Assert
           (C.Count_By_Status (Model, C.Accessibility_RM_Completion_Protected_Access_Blocker) = 1,
            "protected access should block directly");
      end;
   end Local_Accessibility_RM_Errors_Block_Before_Downstream_Evidence;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Accessibility_RM_Completion_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (125261);
      Item : C.Accessibility_RM_Completion_Context :=
        Complete_Context (1, C.Accessibility_RM_Completion_Controlled_Finalization, Node);
   begin
      Item.Finalization_Master_Blocker := True;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Accessibility_RM_Completion_Model := C.Build (Contexts);
         Row   : constant C.Accessibility_RM_Completion_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find accessibility RM completion evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find accessibility RM completion evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve the original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "accessibility RM completion model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Accessibility_Consumes_Completed_RM_Evidence'Access,
         "accepted accessibility consumes completed RM evidence");
      Register_Routine
        (T, Missing_Or_Blocked_Completion_Prerequisites_Preserve_Families'Access,
         "missing or blocked completion prerequisites preserve families");
      Register_Routine
        (T, Local_Accessibility_RM_Errors_Block_Before_Downstream_Evidence'Access,
         "local accessibility RM errors block before downstream evidence");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and blocker family");
   end Register_Tests;

end Test_Ada_Accessibility_Generic_Shared_State_RM_Completion_Legality_Pass1252;
