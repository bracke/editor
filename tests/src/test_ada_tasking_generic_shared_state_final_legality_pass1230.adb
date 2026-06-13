with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Tasking_Generic_Shared_State_Final_Legality_Pass1230 is

   package Registration renames AUnit.Test_Cases.Registration;
   package C renames Editor.Ada_Tasking_Generic_Shared_State_Final_Legality;
   use type C.Tasking_Generic_Final_Row_Id;
   use type C.Tasking_Generic_Final_Kind;
   use type C.Tasking_Generic_Final_Blocker_Family;
   use type C.Tasking_Generic_Final_Status;
   use type C.Tasking_Generic_Final_Context;
   use type C.Tasking_Generic_Final_Row;
   use type C.Tasking_Generic_Final_Context_Model;
   use type C.Tasking_Generic_Final_Model;
   use type C.Tasking_Generic_Final_Set;
   package Tasking_Deep renames C.Tasking_Deep;
   package Tasking_Shared renames C.Tasking_Shared;
   package Generic_Replay renames C.Generic_Replay;
   package Overload_Generic renames C.Overload_Generic;
   package Rep_Generic renames C.Rep_Generic;
   package Abstract_Consumers renames C.Abstract_Consumers;
   package Closure renames C.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada tasking generic shared-state final legality pass1230");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Tasking_Generic_Final_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Tasking_Generic_Final_Context is
      Result : C.Tasking_Generic_Final_Context;
   begin
      Result.Id := C.Tasking_Generic_Final_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Operation_Name := To_Unbounded_String ("Op" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("Generic" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("Instance" & Natural'Image (Id));
      Result.Deep_Tasking_Row := Tasking_Deep.Deep_Tasking_Row_Id (Id);
      Result.Deep_Tasking_Status := Tasking_Deep.Deep_Tasking_Legal_Protected_Reentrancy_Path_Accepted;
      Result.Tasking_Shared_Row := Tasking_Shared.Tasking_Shared_State_Row_Id (Id);
      Result.Tasking_Shared_Status := Tasking_Shared.Tasking_Shared_State_Legal_Protected_Procedure_Write_Accepted;
      Result.Generic_Replay_Row := Generic_Replay.Generic_Abstract_Replay_Row_Id (Id);
      Result.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Legal_Nested_Instance_State_Accepted;
      Result.Overload_Generic_Row := Overload_Generic.Overload_Generic_Final_Row_Id (Id);
      Result.Overload_Generic_Status := Overload_Generic.Overload_Generic_Final_Legal_Dispatching_Call_Accepted;
      Result.Representation_Generic_Row := Rep_Generic.Representation_Generic_Final_Row_Id (Id);
      Result.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Legal_Protected_Object_Representation_Accepted;
      Result.Abstract_Consumer_Row := Abstract_Consumers.Abstract_State_Consumer_Row_Id (Id);
      Result.Abstract_Consumer_Status := Abstract_Consumers.Abstract_State_Consumer_Legal_Tasking_Protected_Accepted;
      Result.Stabilized_Closure_Row := Closure.Shared_State_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1230 * Id;
      Result.Expected_Source_Fingerprint := 1230 * Id;
      Result.Substitution_Fingerprint := 3210 * Id;
      Result.Expected_Substitution_Fingerprint := 3210 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Tasking_Requires_Generic_Representation_And_Shared_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Tasking_Generic_Final_Context_Model;
      Generic_Task : C.Tasking_Generic_Final_Context :=
        Complete_Context (1, C.Tasking_Generic_Final_Generic_Task_Body,
                          Editor.Ada_Syntax_Tree.Node_Id (123001));
      Protected_Action : C.Tasking_Generic_Final_Context :=
        Complete_Context (2, C.Tasking_Generic_Final_Protected_Action,
                          Editor.Ada_Syntax_Tree.Node_Id (123002));
   begin
      Generic_Task.Requires_Generic_Replay := True;
      Generic_Task.Requires_Overload_Generic := True;
      Generic_Task.Requires_Representation_Generic := True;
      Protected_Action.Requires_Abstract_Consumer := True;
      Protected_Action.Requires_Representation_Generic := True;
      C.Add_Context (Contexts, Generic_Task);
      C.Add_Context (Contexts, Protected_Action);

      declare
         Model : constant C.Tasking_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two tasking/generic final rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete tasking/generic evidence should be accepted");
         Assert (C.Blocked_Count (Model) = 0, "accepted tasking rows must not block downstream");
         Assert
           (C.Count_By_Status (Model, C.Tasking_Generic_Final_Legal_Generic_Task_Body_Accepted) = 1,
            "generic task body should accept after replay and representation evidence");
         Assert
           (C.Count_By_Status (Model, C.Tasking_Generic_Final_Legal_Protected_Action_Accepted) = 1,
            "protected action should accept after abstract-state and representation evidence");
      end;
   end Accepted_Tasking_Requires_Generic_Representation_And_Shared_State_Evidence;

   procedure Missing_Or_Blocked_Prerequisites_Preserve_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Tasking_Generic_Final_Context_Model;
      Deep_Blocker : C.Tasking_Generic_Final_Context :=
        Complete_Context (1, C.Tasking_Generic_Final_Protected_Action,
                          Editor.Ada_Syntax_Tree.Node_Id (123021));
      Generic_Blocker : C.Tasking_Generic_Final_Context :=
        Complete_Context (2, C.Tasking_Generic_Final_Generic_Protected_Body,
                          Editor.Ada_Syntax_Tree.Node_Id (123022));
      Representation_Blocker : C.Tasking_Generic_Final_Context :=
        Complete_Context (3, C.Tasking_Generic_Final_Representation_Sensitive_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (123023));
   begin
      Deep_Blocker.Deep_Tasking_Status := Tasking_Deep.Deep_Tasking_Indirect_Reentrancy_Blocker;
      Generic_Blocker.Requires_Generic_Replay := True;
      Generic_Blocker.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Backmap_Blocker;
      Representation_Blocker.Requires_Representation_Generic := True;
      Representation_Blocker.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Task_Protected_Representation_Blocker;
      C.Add_Context (Contexts, Deep_Blocker);
      C.Add_Context (Contexts, Generic_Blocker);
      C.Add_Context (Contexts, Representation_Blocker);

      declare
         Model : constant C.Tasking_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept");
         Assert (C.Blocked_Count (Model) = 3, "three blocker rows should be retained");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Tasking_Generic_Final_Blocker_Deep_Tasking) = 1,
            "deep tasking blocker should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Tasking_Generic_Final_Blocker_Generic_Abstract_Replay) = 1,
            "generic replay blocker should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Tasking_Generic_Final_Blocker_Representation_Generic_Shared_State) = 1,
            "representation/generic blocker should be preserved");
      end;
   end Missing_Or_Blocked_Prerequisites_Preserve_Family;

   procedure RM_Edge_And_Fingerprint_Errors_Block_Directly
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Tasking_Generic_Final_Context_Model;
      Queue_Blocker : C.Tasking_Generic_Final_Context :=
        Complete_Context (1, C.Tasking_Generic_Final_Entry_Family_Queue,
                          Editor.Ada_Syntax_Tree.Node_Id (123041));
      Abort_Blocker : C.Tasking_Generic_Final_Context :=
        Complete_Context (2, C.Tasking_Generic_Final_Abort_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (123042));
      Source_Mismatch : C.Tasking_Generic_Final_Context :=
        Complete_Context (3, C.Tasking_Generic_Final_Task_Termination,
                          Editor.Ada_Syntax_Tree.Node_Id (123043));
   begin
      Queue_Blocker.Entry_Family_Queue_Blocker := True;
      Abort_Blocker.Abort_Finalization_Blocker := True;
      Source_Mismatch.Source_Fingerprint := 1;
      Source_Mismatch.Expected_Source_Fingerprint := 2;
      C.Add_Context (Contexts, Queue_Blocker);
      C.Add_Context (Contexts, Abort_Blocker);
      C.Add_Context (Contexts, Source_Mismatch);

      declare
         Model : constant C.Tasking_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Tasking_Generic_Final_Entry_Family_Queue_Blocker) = 1,
            "entry-family queue blockers should block directly");
         Assert
           (C.Count_By_Status (Model, C.Tasking_Generic_Final_Abort_Finalization_Blocker) = 1,
            "abort/finalization blockers should block directly");
         Assert
           (C.Count_By_Status (Model, C.Tasking_Generic_Final_Source_Fingerprint_Mismatch) = 1,
            "source fingerprint mismatch should block directly");
      end;
   end RM_Edge_And_Fingerprint_Errors_Block_Directly;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Tasking_Generic_Final_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (123061);
      Item : C.Tasking_Generic_Final_Context :=
        Complete_Context (1, C.Tasking_Generic_Final_Representation_Sensitive_Effect, Node);
   begin
      Item.Representation_Sensitive_Tasking_Blocker := True;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Tasking_Generic_Final_Model := C.Build (Contexts);
         Row   : constant C.Tasking_Generic_Final_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find tasking/generic final evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find tasking/generic final evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "tasking/generic final model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Tasking_Requires_Generic_Representation_And_Shared_State_Evidence'Access,
         "accepted tasking requires generic representation and shared-state evidence");
      Register_Routine
        (T, Missing_Or_Blocked_Prerequisites_Preserve_Family'Access,
         "missing or blocked prerequisites preserve family");
      Register_Routine
        (T, RM_Edge_And_Fingerprint_Errors_Block_Directly'Access,
         "RM edge and fingerprint errors block directly");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and blocker family");
   end Register_Tests;

end Test_Ada_Tasking_Generic_Shared_State_Final_Legality_Pass1230;
