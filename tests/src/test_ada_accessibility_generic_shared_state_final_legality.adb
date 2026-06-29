with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Accessibility_Generic_Shared_State_Final_Legality is

   package Registration renames AUnit.Test_Cases.Registration;
   package C renames Editor.Ada_Accessibility_Generic_Shared_State_Final_Legality;
   use type C.Accessibility_Generic_Final_Row_Id;
   use type C.Accessibility_Generic_Final_Kind;
   use type C.Accessibility_Generic_Final_Blocker_Family;
   use type C.Accessibility_Generic_Final_Status;
   use type C.Accessibility_Generic_Final_Context;
   use type C.Accessibility_Generic_Final_Row;
   use type C.Accessibility_Generic_Final_Context_Model;
   use type C.Accessibility_Generic_Final_Model;
   use type C.Accessibility_Generic_Final_Query;
   package Access_Final renames C.Access_Final;
   package Cross_Generic renames C.Cross_Generic;
   package Elab_Generic renames C.Elab_Generic;
   package Generic_Replay renames C.Generic_Replay;
   package Overload_Generic renames C.Overload_Generic;
   package Rep_Generic renames C.Rep_Generic;
   package Closure renames C.Closure;
   package Tasking_Generic renames C.Tasking_Generic;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada accessibility/generic shared-state final legality");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Accessibility_Generic_Final_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Accessibility_Generic_Final_Context is
      Result : C.Accessibility_Generic_Final_Context;
   begin
      Result.Id := C.Accessibility_Generic_Final_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Object_Name := To_Unbounded_String ("Obj" & Natural'Image (Id));
      Result.Type_Name := To_Unbounded_String ("Typ" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("Gen" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("Inst" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Final_Accessibility_Row := Access_Final.Master_Scope_Final_Row_Id (Id);
      Result.Final_Accessibility_Status := Access_Final.Master_Scope_Final_Legal_Return_Access_Accepted;
      Result.Cross_Generic_Row := Cross_Generic.Cross_Unit_Generic_Final_Row_Id (Id);
      Result.Cross_Generic_Status := Cross_Generic.Cross_Unit_Generic_Final_Legal_Generic_Instance_Accepted;
      Result.Elaboration_Generic_Row := Elab_Generic.Elaboration_Generic_Final_Row_Id (Id);
      Result.Elaboration_Generic_Status := Elab_Generic.Elaboration_Generic_Final_Legal_Generic_Instance_Accepted;
      Result.Generic_Replay_Row := Generic_Replay.Generic_Abstract_Replay_Row_Id (Id);
      Result.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Legal_Nested_Instance_State_Accepted;
      Result.Overload_Generic_Row := Overload_Generic.Overload_Generic_Final_Row_Id (Id);
      Result.Overload_Generic_Status := Overload_Generic.Overload_Generic_Final_Legal_Generic_Formal_Subprogram_Accepted;
      Result.Representation_Generic_Row := Rep_Generic.Representation_Generic_Final_Row_Id (Id);
      Result.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Legal_Generic_Instance_Representation_Accepted;
      Result.Tasking_Generic_Row := Tasking_Generic.Tasking_Generic_Final_Row_Id (Id);
      Result.Tasking_Generic_Status := Tasking_Generic.Tasking_Generic_Final_Legal_Generic_Task_Body_Accepted;
      Result.Stabilized_Closure_Row := Closure.Shared_State_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1233 * Id;
      Result.Expected_Source_Fingerprint := 1233 * Id;
      Result.Substitution_Fingerprint := 3321 * Id;
      Result.Expected_Substitution_Fingerprint := 3321 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Accessibility_Requires_Generic_Shared_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Accessibility_Generic_Final_Context_Model;
      Return_Access : C.Accessibility_Generic_Final_Context :=
        Complete_Context (1, C.Accessibility_Generic_Final_Return_Access,
                          Editor.Ada_Syntax_Tree.Node_Id (123301));
      Generic_Escape : C.Accessibility_Generic_Final_Context :=
        Complete_Context (2, C.Accessibility_Generic_Final_Generic_Replay_Escape,
                          Editor.Ada_Syntax_Tree.Node_Id (123302));
   begin
      Return_Access.Requires_Elaboration_Generic := True;
      Return_Access.Requires_Overload_Generic := True;
      Generic_Escape.Requires_Generic_Replay := True;
      Generic_Escape.Requires_Stabilized_Closure := True;
      C.Add_Context (Contexts, Return_Access);
      C.Add_Context (Contexts, Generic_Escape);

      declare
         Model : constant C.Accessibility_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two accessibility/generic rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete accessibility and shared-state evidence should accept");
         Assert (C.Blocked_Count (Model) = 0, "accepted accessibility rows should not block downstream legality");
         Assert
           (C.Count_By_Status (Model, C.Accessibility_Generic_Final_Legal_Return_Access_Accepted) = 1,
            "return access lifetime should be accepted");
         Assert
           (C.Count_By_Status (Model, C.Accessibility_Generic_Final_Legal_Generic_Replay_Escape_Accepted) = 1,
            "generic replay escape should be accepted");
      end;
   end Accepted_Accessibility_Requires_Generic_Shared_State_Evidence;

   procedure Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Accessibility_Generic_Final_Context_Model;
      Access_Blocker : C.Accessibility_Generic_Final_Context :=
        Complete_Context (1, C.Accessibility_Generic_Final_Anonymous_Access_Result,
                          Editor.Ada_Syntax_Tree.Node_Id (123321));
      Cross_Blocker : C.Accessibility_Generic_Final_Context :=
        Complete_Context (2, C.Accessibility_Generic_Final_Cross_Unit_Lifetime,
                          Editor.Ada_Syntax_Tree.Node_Id (123322));
      Tasking_Blocker : C.Accessibility_Generic_Final_Context :=
        Complete_Context (3, C.Accessibility_Generic_Final_Task_Protected_Lifetime,
                          Editor.Ada_Syntax_Tree.Node_Id (123323));
   begin
      Access_Blocker.Final_Accessibility_Status := Access_Final.Master_Scope_Final_Return_Access_Master_Blocker;
      Cross_Blocker.Cross_Generic_Status := Cross_Generic.Cross_Unit_Generic_Final_Generic_Replay_Blocker;
      Tasking_Blocker.Requires_Tasking_Generic := True;
      Tasking_Blocker.Tasking_Generic_Status := Tasking_Generic.Tasking_Generic_Final_Task_Activation_Termination_Blocker;
      C.Add_Context (Contexts, Access_Blocker);
      C.Add_Context (Contexts, Cross_Blocker);
      C.Add_Context (Contexts, Tasking_Blocker);

      declare
         Model : constant C.Accessibility_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept accessibility conclusions");
         Assert (C.Blocked_Count (Model) = 3, "three prerequisite blockers should be retained");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Accessibility_Generic_Final_Blocker_Final_Accessibility) = 1,
            "final accessibility blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Accessibility_Generic_Final_Blocker_Cross_Unit_Generic_Shared_State) = 1,
            "cross-unit generic/shared-state blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Accessibility_Generic_Final_Blocker_Tasking_Generic_Shared_State) = 1,
            "tasking generic/shared-state blocker family should be preserved");
      end;
   end Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family;

   procedure Local_Accessibility_RM_Errors_Block_Directly
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Accessibility_Generic_Final_Context_Model;
      Level_Error : C.Accessibility_Generic_Final_Context :=
        Complete_Context (1, C.Accessibility_Generic_Final_Access_Conversion,
                          Editor.Ada_Syntax_Tree.Node_Id (123341));
      Escape_Error : C.Accessibility_Generic_Final_Context :=
        Complete_Context (2, C.Accessibility_Generic_Final_Allocator_Master,
                          Editor.Ada_Syntax_Tree.Node_Id (123342));
      Rep_Error : C.Accessibility_Generic_Final_Context :=
        Complete_Context (3, C.Accessibility_Generic_Final_Representation_Sensitive_Lifetime,
                          Editor.Ada_Syntax_Tree.Node_Id (123343));
   begin
      Level_Error.Access_Level_Blocker := True;
      Escape_Error.Master_Escape_Blocker := True;
      Rep_Error.Representation_Sensitive_Lifetime_Blocker := True;
      C.Add_Context (Contexts, Level_Error);
      C.Add_Context (Contexts, Escape_Error);
      C.Add_Context (Contexts, Rep_Error);

      declare
         Model : constant C.Accessibility_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Accessibility_Generic_Final_Access_Level_Blocker) = 1,
            "access-level errors should block directly");
         Assert
           (C.Count_By_Status (Model, C.Accessibility_Generic_Final_Master_Escape_Blocker) = 1,
            "master escape errors should block directly");
         Assert
           (C.Count_By_Status (Model, C.Accessibility_Generic_Final_Representation_Sensitive_Lifetime_Blocker) = 1,
            "representation-sensitive lifetime errors should block directly");
      end;
   end Local_Accessibility_RM_Errors_Block_Directly;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Accessibility_Generic_Final_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (123361);
      Item : C.Accessibility_Generic_Final_Context :=
        Complete_Context (1, C.Accessibility_Generic_Final_Controlled_Finalization, Node);
   begin
      Item.Requires_Representation_Generic := True;
      Item.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Task_Protected_Representation_Blocker;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Accessibility_Generic_Final_Model := C.Build (Contexts);
         Row   : constant C.Accessibility_Generic_Final_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find accessibility/generic evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find accessibility/generic evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve the original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "accessibility/generic shared-state final model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Accessibility_Requires_Generic_Shared_State_Evidence'Access,
         "accepted accessibility requires generic shared-state evidence");
      Register_Routine
        (T, Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family'Access,
         "missing or blocked prerequisites preserve blocker family");
      Register_Routine
        (T, Local_Accessibility_RM_Errors_Block_Directly'Access,
         "local accessibility RM errors block directly");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and blocker family");
   end Register_Tests;

end Test_Ada_Accessibility_Generic_Shared_State_Final_Legality;
