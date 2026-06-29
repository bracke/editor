with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Discriminant_Generic_Shared_State_Final_Legality is

   package C renames Editor.Ada_Discriminant_Generic_Shared_State_Final_Legality;
   use type C.Discriminant_Generic_Final_Row_Id;
   use type C.Discriminant_Generic_Final_Kind;
   use type C.Discriminant_Generic_Final_Blocker_Family;
   use type C.Discriminant_Generic_Final_Status;
   use type C.Discriminant_Generic_Final_Context;
   use type C.Discriminant_Generic_Final_Row;
   use type C.Discriminant_Generic_Final_Context_Model;
   use type C.Discriminant_Generic_Final_Model;
   use type C.Discriminant_Generic_Final_Set;
   package Disc_Final renames C.Disc_Final;
   package Cross_Generic renames C.Cross_Generic;
   package Elab_Generic renames C.Elab_Generic;
   package Generic_Replay renames C.Generic_Replay;
   package Overload_Generic renames C.Overload_Generic;
   package Rep_Generic renames C.Rep_Generic;
   package Tasking_Generic renames C.Tasking_Generic;
   package Access_Generic renames C.Access_Generic;
   package Closure renames C.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada discriminant/generic shared-state final legality");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Discriminant_Generic_Final_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Discriminant_Generic_Final_Context is
      Result : C.Discriminant_Generic_Final_Context;
   begin
      Result.Id := C.Discriminant_Generic_Final_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Type_Name := To_Unbounded_String ("T" & Natural'Image (Id));
      Result.Object_Name := To_Unbounded_String ("Obj" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("G" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("I" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Discriminant_Consumer_Row := Disc_Final.Discriminant_Consumer_Row_Id (Id);
      Result.Discriminant_Consumer_Status := Disc_Final.Discriminant_Consumer_Legal_Record_Layout_Accepted;
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
      Result.Accessibility_Generic_Status := Access_Generic.Accessibility_Generic_Final_Legal_Access_Discriminant_Accepted;
      Result.Stabilized_Closure_Row := Closure.Shared_State_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1234 * Id;
      Result.Expected_Source_Fingerprint := 1234 * Id;
      Result.Substitution_Fingerprint := 4321 * Id;
      Result.Expected_Substitution_Fingerprint := 4321 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Discriminants_Require_Generic_Shared_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Discriminant_Generic_Final_Context_Model;
      Variant : C.Discriminant_Generic_Final_Context :=
        Complete_Context (1, C.Discriminant_Generic_Final_Variant_Record_Layout,
                          Editor.Ada_Syntax_Tree.Node_Id (123401));
      Access_Disc : C.Discriminant_Generic_Final_Context :=
        Complete_Context (2, C.Discriminant_Generic_Final_Access_Discriminant,
                          Editor.Ada_Syntax_Tree.Node_Id (123402));
   begin
      Variant.Requires_Representation_Generic := True;
      Variant.Requires_Generic_Replay := True;
      Access_Disc.Requires_Accessibility_Generic := True;
      Access_Disc.Requires_Stabilized_Closure := True;
      C.Add_Context (Contexts, Variant);
      C.Add_Context (Contexts, Access_Disc);

      declare
         Model : constant C.Discriminant_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two discriminant/generic rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete discriminant and shared-state evidence should accept");
         Assert (C.Blocked_Count (Model) = 0, "accepted rows should not block downstream legality");
         Assert
           (C.Count_By_Status (Model, C.Discriminant_Generic_Final_Legal_Variant_Record_Layout_Accepted) = 1,
            "variant record layout should be accepted");
         Assert
           (C.Count_By_Status (Model, C.Discriminant_Generic_Final_Legal_Access_Discriminant_Accepted) = 1,
            "access discriminant should be accepted");
      end;
   end Accepted_Discriminants_Require_Generic_Shared_State_Evidence;

   procedure Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Discriminant_Generic_Final_Context_Model;
      Disc_Blocker : C.Discriminant_Generic_Final_Context :=
        Complete_Context (1, C.Discriminant_Generic_Final_Record_Layout,
                          Editor.Ada_Syntax_Tree.Node_Id (123421));
      Rep_Blocker : C.Discriminant_Generic_Final_Context :=
        Complete_Context (2, C.Discriminant_Generic_Final_Representation_Clause,
                          Editor.Ada_Syntax_Tree.Node_Id (123422));
      Access_Blocker : C.Discriminant_Generic_Final_Context :=
        Complete_Context (3, C.Discriminant_Generic_Final_Access_Discriminant,
                          Editor.Ada_Syntax_Tree.Node_Id (123423));
   begin
      Disc_Blocker.Discriminant_Consumer_Status := Disc_Final.Discriminant_Consumer_Variant_Coverage_Blocker;
      Rep_Blocker.Requires_Representation_Generic := True;
      Rep_Blocker.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Variant_Layout_Blocker;
      Access_Blocker.Requires_Accessibility_Generic := True;
      Access_Blocker.Accessibility_Generic_Status := Access_Generic.Accessibility_Generic_Final_Master_Escape_Blocker;
      C.Add_Context (Contexts, Disc_Blocker);
      C.Add_Context (Contexts, Rep_Blocker);
      C.Add_Context (Contexts, Access_Blocker);

      declare
         Model : constant C.Discriminant_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept discriminant conclusions");
         Assert (C.Blocked_Count (Model) = 3, "three prerequisite blockers should be retained");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Discriminant_Generic_Final_Blocker_Discriminant_Consumer) = 1,
            "discriminant consumer blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Discriminant_Generic_Final_Blocker_Representation_Generic_Shared_State) = 1,
            "representation generic/shared-state blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Discriminant_Generic_Final_Blocker_Accessibility_Generic_Shared_State) = 1,
            "accessibility generic/shared-state blocker family should be preserved");
      end;
   end Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family;

   procedure Local_Discriminant_RM_Errors_Block_Directly
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Discriminant_Generic_Final_Context_Model;
      Constraint_Error : C.Discriminant_Generic_Final_Context :=
        Complete_Context (1, C.Discriminant_Generic_Final_Assignment_Conversion,
                          Editor.Ada_Syntax_Tree.Node_Id (123441));
      Variant_Error : C.Discriminant_Generic_Final_Context :=
        Complete_Context (2, C.Discriminant_Generic_Final_Record_Aggregate,
                          Editor.Ada_Syntax_Tree.Node_Id (123442));
      Tasking_Error : C.Discriminant_Generic_Final_Context :=
        Complete_Context (3, C.Discriminant_Generic_Final_Task_Protected_Discriminant,
                          Editor.Ada_Syntax_Tree.Node_Id (123443));
   begin
      Constraint_Error.Discriminant_Constraint_Blocker := True;
      Variant_Error.Variant_Coverage_Blocker := True;
      Tasking_Error.Task_Protected_Effect_Blocker := True;
      C.Add_Context (Contexts, Constraint_Error);
      C.Add_Context (Contexts, Variant_Error);
      C.Add_Context (Contexts, Tasking_Error);

      declare
         Model : constant C.Discriminant_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Discriminant_Generic_Final_Discriminant_Constraint_Blocker) = 1,
            "discriminant constraints should block directly");
         Assert
           (C.Count_By_Status (Model, C.Discriminant_Generic_Final_Variant_Coverage_Blocker) = 1,
            "variant coverage errors should block directly");
         Assert
           (C.Count_By_Status (Model, C.Discriminant_Generic_Final_Task_Protected_Effect_Blocker) = 1,
            "task/protected discriminant effects should block directly");
      end;
   end Local_Discriminant_RM_Errors_Block_Directly;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Discriminant_Generic_Final_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (123461);
      Item : C.Discriminant_Generic_Final_Context :=
        Complete_Context (1, C.Discriminant_Generic_Final_Cross_Unit_Discriminant, Node);
   begin
      Item.Requires_Tasking_Generic := True;
      Item.Tasking_Generic_Status := Tasking_Generic.Tasking_Generic_Final_Representation_Sensitive_Tasking_Blocker;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Discriminant_Generic_Final_Model := C.Build (Contexts);
         Row   : constant C.Discriminant_Generic_Final_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find discriminant/generic evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find discriminant/generic evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve the original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "discriminant/generic shared-state final model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Discriminants_Require_Generic_Shared_State_Evidence'Access,
         "accepted discriminants require generic shared-state evidence");
      Register_Routine
        (T, Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family'Access,
         "missing or blocked prerequisites preserve blocker family");
      Register_Routine
        (T, Local_Discriminant_RM_Errors_Block_Directly'Access,
         "local discriminant RM errors block directly");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and blocker family");
   end Register_Tests;

end Test_Ada_Discriminant_Generic_Shared_State_Final_Legality;
