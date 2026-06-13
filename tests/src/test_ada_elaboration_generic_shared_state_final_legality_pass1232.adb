with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Elaboration_Generic_Shared_State_Final_Legality_Pass1232 is

   package Registration renames AUnit.Test_Cases.Registration;
   package C renames Editor.Ada_Elaboration_Generic_Shared_State_Final_Legality;
   use type C.Elaboration_Generic_Final_Row_Id;
   use type C.Elaboration_Generic_Final_Kind;
   use type C.Elaboration_Generic_Final_Blocker_Family;
   use type C.Elaboration_Generic_Final_Status;
   use type C.Elaboration_Generic_Final_Context;
   use type C.Elaboration_Generic_Final_Row;
   use type C.Elaboration_Generic_Final_Context_Model;
   use type C.Elaboration_Generic_Final_Model;
   use type C.Elaboration_Generic_Final_Set;
   package Cross_Generic renames C.Cross_Generic;
   package Dispatching_Global renames C.Dispatching_Global;
   package Elaboration_Final renames C.Elaboration_Final;
   package Generic_Replay renames C.Generic_Replay;
   package Rep_Generic renames C.Rep_Generic;
   package Tasking_Generic renames C.Tasking_Generic;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada elaboration generic shared-state final legality pass1232");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Elaboration_Generic_Final_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Elaboration_Generic_Final_Context is
      Result : C.Elaboration_Generic_Final_Context;
   begin
      Result.Id := C.Elaboration_Generic_Final_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Unit_Name := To_Unbounded_String ("Unit" & Natural'Image (Id));
      Result.Target_Name := To_Unbounded_String ("Target" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("Generic" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Final_Elaboration_Row := Elaboration_Final.Final_Elaboration_Row_Id (Id);
      Result.Final_Elaboration_Status := Elaboration_Final.Final_Elaboration_Legal_Call_Accepted;
      Result.Cross_Generic_Row := Cross_Generic.Cross_Unit_Generic_Final_Row_Id (Id);
      Result.Cross_Generic_Status := Cross_Generic.Cross_Unit_Generic_Final_Legal_Generic_Instance_Accepted;
      Result.Dispatching_Global_Row := Dispatching_Global.Dispatching_Global_Row_Id (Id);
      Result.Dispatching_Global_Status := Dispatching_Global.Dispatching_Global_Legal_Class_Wide_Call_Accepted;
      Result.Generic_Replay_Row := Generic_Replay.Generic_Abstract_Replay_Row_Id (Id);
      Result.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Legal_Nested_Instance_State_Accepted;
      Result.Representation_Generic_Row := Rep_Generic.Representation_Generic_Final_Row_Id (Id);
      Result.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Legal_Generic_Instance_Representation_Accepted;
      Result.Tasking_Generic_Row := Tasking_Generic.Tasking_Generic_Final_Row_Id (Id);
      Result.Tasking_Generic_Status := Tasking_Generic.Tasking_Generic_Final_Legal_Generic_Task_Body_Accepted;
      Result.Source_Fingerprint := 1232 * Id;
      Result.Expected_Source_Fingerprint := 1232 * Id;
      Result.Substitution_Fingerprint := 2321 * Id;
      Result.Expected_Substitution_Fingerprint := 2321 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Elaboration_Requires_Generic_Shared_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Elaboration_Generic_Final_Context_Model;
      Dispatching : C.Elaboration_Generic_Final_Context :=
        Complete_Context (1, C.Elaboration_Generic_Final_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (123201));
      Instance : C.Elaboration_Generic_Final_Context :=
        Complete_Context (2, C.Elaboration_Generic_Final_Generic_Instance,
                          Editor.Ada_Syntax_Tree.Node_Id (123202));
   begin
      Dispatching.Requires_Dispatching_Global := True;
      Instance.Requires_Generic_Replay := True;
      C.Add_Context (Contexts, Dispatching);
      C.Add_Context (Contexts, Instance);

      declare
         Model : constant C.Elaboration_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two elaboration/generic rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete elaboration and shared-state evidence should accept");
         Assert (C.Blocked_Count (Model) = 0, "accepted elaboration rows should not block downstream legality");
         Assert
           (C.Count_By_Status (Model, C.Elaboration_Generic_Final_Legal_Dispatching_Call_Accepted) = 1,
            "dispatching elaboration should be accepted");
         Assert
           (C.Count_By_Status (Model, C.Elaboration_Generic_Final_Legal_Generic_Instance_Accepted) = 1,
            "generic instance elaboration should be accepted");
      end;
   end Accepted_Elaboration_Requires_Generic_Shared_State_Evidence;

   procedure Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Elaboration_Generic_Final_Context_Model;
      Elab_Blocker : C.Elaboration_Generic_Final_Context :=
        Complete_Context (1, C.Elaboration_Generic_Final_Default_Expression,
                          Editor.Ada_Syntax_Tree.Node_Id (123221));
      Cross_Blocker : C.Elaboration_Generic_Final_Context :=
        Complete_Context (2, C.Elaboration_Generic_Final_Generic_Body_Replay,
                          Editor.Ada_Syntax_Tree.Node_Id (123222));
      Tasking_Blocker : C.Elaboration_Generic_Final_Context :=
        Complete_Context (3, C.Elaboration_Generic_Final_Task_Activation,
                          Editor.Ada_Syntax_Tree.Node_Id (123223));
   begin
      Elab_Blocker.Final_Elaboration_Status := Elaboration_Final.Final_Elaboration_Base_Elaboration_Error;
      Cross_Blocker.Cross_Generic_Status := Cross_Generic.Cross_Unit_Generic_Final_Generic_Replay_Blocker;
      Tasking_Blocker.Requires_Tasking_Generic := True;
      Tasking_Blocker.Tasking_Generic_Status := Tasking_Generic.Tasking_Generic_Final_Task_Activation_Termination_Blocker;
      C.Add_Context (Contexts, Elab_Blocker);
      C.Add_Context (Contexts, Cross_Blocker);
      C.Add_Context (Contexts, Tasking_Blocker);

      declare
         Model : constant C.Elaboration_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept elaboration conclusions");
         Assert (C.Blocked_Count (Model) = 3, "three prerequisite blockers should be retained");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Elaboration_Generic_Final_Blocker_Final_Elaboration) = 1,
            "final elaboration blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Elaboration_Generic_Final_Blocker_Cross_Unit_Generic_Shared_State) = 1,
            "cross-unit generic/shared-state blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Elaboration_Generic_Final_Blocker_Tasking_Generic_Shared_State) = 1,
            "tasking generic/shared-state blocker family should be preserved");
      end;
   end Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family;

   procedure Local_Elaboration_RM_Errors_Block_Directly
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Elaboration_Generic_Final_Context_Model;
      Order_Error : C.Elaboration_Generic_Final_Context :=
        Complete_Context (1, C.Elaboration_Generic_Final_Aspect_Expression,
                          Editor.Ada_Syntax_Tree.Node_Id (123241));
      Pure_Error : C.Elaboration_Generic_Final_Context :=
        Complete_Context (2, C.Elaboration_Generic_Final_Pure_Policy,
                          Editor.Ada_Syntax_Tree.Node_Id (123242));
      Shared_Passive_Error : C.Elaboration_Generic_Final_Context :=
        Complete_Context (3, C.Elaboration_Generic_Final_Shared_Passive_Policy,
                          Editor.Ada_Syntax_Tree.Node_Id (123243));
   begin
      Order_Error.Elaboration_Order_Error := True;
      Pure_Error.Pure_Policy_Error := True;
      Shared_Passive_Error.Shared_Passive_Policy_Error := True;
      C.Add_Context (Contexts, Order_Error);
      C.Add_Context (Contexts, Pure_Error);
      C.Add_Context (Contexts, Shared_Passive_Error);

      declare
         Model : constant C.Elaboration_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Elaboration_Generic_Final_Elaboration_Order_Blocker) = 1,
            "elaboration order errors should block directly");
         Assert
           (C.Count_By_Status (Model, C.Elaboration_Generic_Final_Pure_Policy_Blocker) = 1,
            "Pure policy errors should block directly");
         Assert
           (C.Count_By_Status (Model, C.Elaboration_Generic_Final_Shared_Passive_Policy_Blocker) = 1,
            "Shared_Passive policy errors should block directly");
      end;
   end Local_Elaboration_RM_Errors_Block_Directly;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Elaboration_Generic_Final_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (123261);
      Item : C.Elaboration_Generic_Final_Context :=
        Complete_Context (1, C.Elaboration_Generic_Final_Representation_Item, Node);
   begin
      Item.Requires_Representation_Generic := True;
      Item.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Task_Protected_Representation_Blocker;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Elaboration_Generic_Final_Model := C.Build (Contexts);
         Row   : constant C.Elaboration_Generic_Final_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find elaboration/generic evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find elaboration/generic evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve the original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "elaboration/generic shared-state final model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Elaboration_Requires_Generic_Shared_State_Evidence'Access,
         "accepted elaboration requires generic shared-state evidence");
      Register_Routine
        (T, Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family'Access,
         "missing or blocked prerequisites preserve blocker family");
      Register_Routine
        (T, Local_Elaboration_RM_Errors_Block_Directly'Access,
         "local elaboration RM errors block directly");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and blocker family");
   end Register_Tests;

end Test_Ada_Elaboration_Generic_Shared_State_Final_Legality_Pass1232;
