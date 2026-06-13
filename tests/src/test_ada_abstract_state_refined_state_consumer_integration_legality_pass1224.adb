with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Abstract_State_Refined_State_Consumer_Integration_Legality_Pass1224 is

   package Registration renames AUnit.Test_Cases.Registration;
   package C renames Editor.Ada_Abstract_State_Refined_State_Consumer_Integration_Legality;
   use type C.Abstract_State_Consumer_Row_Id;
   use type C.Abstract_State_Consumer_Kind;
   use type C.Abstract_State_Consumer_Blocker_Family;
   use type C.Abstract_State_Consumer_Status;
   use type C.Abstract_State_Consumer_Context;
   use type C.Abstract_State_Consumer_Row;
   use type C.Abstract_State_Consumer_Context_Model;
   use type C.Abstract_State_Consumer_Model;
   use type C.Abstract_State_Consumer_Set;
   package States renames C.States;
   package Shared renames C.Shared;
   package O renames C.Overload_State;
   package Rep renames C.Rep_State;
   package Tasking renames C.Tasking_State;
   package CU renames C.Cross_Unit_State;
   package Closure renames C.Stabilized_State;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada abstract/refined state consumer integration legality pass1224");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Abstract_State_Consumer_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Abstract_State_Consumer_Context is
      Result : C.Abstract_State_Consumer_Context;
   begin
      Result.Id := C.Abstract_State_Consumer_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Consumer_Name := To_Unbounded_String ("Consumer" & Natural'Image (Id));
      Result.Unit_Name := To_Unbounded_String ("Unit" & Natural'Image (Id));
      Result.Abstract_State_Row := States.Abstract_State_Row_Id (Id);
      Result.Abstract_State_Status := States.Abstract_State_Legal_Global_Use_Accepted;
      Result.Shared_State_Row := Shared.Shared_State_Row_Id (Id);
      Result.Shared_State_Status := Shared.Shared_State_Legal_Abstract_State_Effect_Accepted;
      Result.Overload_State_Row := O.Overload_Shared_State_Row_Id (Id);
      Result.Overload_State_Status := O.Overload_Shared_State_Legal_Abstract_State_Effect_Accepted;
      Result.Representation_State_Row := Rep.Representation_Shared_State_Row_Id (Id);
      Result.Representation_State_Status := Rep.Representation_Shared_State_Legal_Abstract_State_View_Accepted;
      Result.Tasking_State_Row := Tasking.Tasking_Shared_State_Row_Id (Id);
      Result.Tasking_State_Status := Tasking.Tasking_Shared_State_Legal_Abstract_State_Access_Accepted;
      Result.Cross_Unit_State_Row := CU.Cross_Unit_Shared_State_Row_Id (Id);
      Result.Cross_Unit_State_Status := CU.Cross_Unit_Shared_State_Legal_Abstract_State_Accepted;
      Result.Stabilized_Closure_Row := Closure.Shared_State_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1224 * Id;
      Result.Expected_Source_Fingerprint := 1224 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Consumers_Remain_Current_When_All_State_Evidence_Agrees
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Abstract_State_Consumer_Context_Model;
      Global : C.Abstract_State_Consumer_Context :=
        Complete_Context (1, C.Abstract_State_Consumer_Global_Refinement,
                          Editor.Ada_Syntax_Tree.Node_Id (122401));
      Dispatching : C.Abstract_State_Consumer_Context :=
        Complete_Context (2, C.Abstract_State_Consumer_Dispatching_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (122402));
   begin
      Dispatching.Requires_Shared_State := True;
      Dispatching.Requires_Overload_State := True;
      C.Add_Context (Contexts, Global);
      C.Add_Context (Contexts, Dispatching);

      declare
         Model : constant C.Abstract_State_Consumer_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two abstract-state consumer rows expected");
         Assert (C.Accepted_Count (Model) = 2, "all complete consumers should be accepted");
         Assert (C.Blocked_Count (Model) = 0, "complete state evidence must not block consumers");
         Assert
           (C.Count_By_Status (Model, C.Abstract_State_Consumer_Legal_Global_Refinement_Accepted) = 1,
            "global refinement consumer should be accepted");
         Assert
           (C.Count_By_Status (Model, C.Abstract_State_Consumer_Legal_Dispatching_Effect_Accepted) = 1,
            "dispatching effect consumer should be accepted");
      end;
   end Accepted_Consumers_Remain_Current_When_All_State_Evidence_Agrees;

   procedure Required_Consumer_Evidence_Blocks_Downstream_Confidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Abstract_State_Consumer_Context_Model;
      Rep_Blocker : C.Abstract_State_Consumer_Context :=
        Complete_Context (1, C.Abstract_State_Consumer_Representation_Freezing,
                          Editor.Ada_Syntax_Tree.Node_Id (122421));
      Task_Blocker : C.Abstract_State_Consumer_Context :=
        Complete_Context (2, C.Abstract_State_Consumer_Tasking_Protected,
                          Editor.Ada_Syntax_Tree.Node_Id (122422));
      Closure_Blocker : C.Abstract_State_Consumer_Context :=
        Complete_Context (3, C.Abstract_State_Consumer_Shared_State_Stabilized_Closure,
                          Editor.Ada_Syntax_Tree.Node_Id (122423));
   begin
      Rep_Blocker.Requires_Representation_State := True;
      Rep_Blocker.Representation_State_Status := Rep.Representation_Shared_State_Final_Representation_Blocker;
      Task_Blocker.Requires_Tasking_State := True;
      Task_Blocker.Tasking_State_Status := Tasking.Tasking_Shared_State_Representation_Effect_Blocker;
      Closure_Blocker.Requires_Stabilized_Closure := True;
      Closure_Blocker.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Blocker_Abstract_State;
      C.Add_Context (Contexts, Rep_Blocker);
      C.Add_Context (Contexts, Task_Blocker);
      C.Add_Context (Contexts, Closure_Blocker);

      declare
         Model : constant C.Abstract_State_Consumer_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 3, "three blocked consumer rows expected");
         Assert (C.Accepted_Count (Model) = 0, "blocked consumers must not be accepted");
         Assert (C.Blocked_Count (Model) = 3, "all missing or blocked consumers should withhold confidence");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Abstract_State_Consumer_Blocker_Representation_Freezing) = 1,
            "representation/freezing blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Abstract_State_Consumer_Blocker_Tasking_Protected) = 1,
            "tasking/protected blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Abstract_State_Consumer_Blocker_Stabilized_Closure) = 1,
            "stabilized-closure blocker family should be preserved");
      end;
   end Required_Consumer_Evidence_Blocks_Downstream_Confidence;

   procedure Local_Abstract_State_Errors_Override_Downstream_Consumers
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Abstract_State_Consumer_Context_Model;
      Global_Mode : C.Abstract_State_Consumer_Context :=
        Complete_Context (1, C.Abstract_State_Consumer_Global_Refinement,
                          Editor.Ada_Syntax_Tree.Node_Id (122441));
      Depends_Edge : C.Abstract_State_Consumer_Context :=
        Complete_Context (2, C.Abstract_State_Consumer_Depends_Refinement,
                          Editor.Ada_Syntax_Tree.Node_Id (122442));
   begin
      Global_Mode.Global_Mode_Error := True;
      Depends_Edge.Depends_Edge_Error := True;
      C.Add_Context (Contexts, Global_Mode);
      C.Add_Context (Contexts, Depends_Edge);

      declare
         Model : constant C.Abstract_State_Consumer_Model := C.Build (Contexts);
      begin
         Assert (C.Count_By_Status (Model, C.Abstract_State_Consumer_Global_Mode_Blocker) = 1,
                 "Global abstract-state mode errors should block consumers directly");
         Assert (C.Count_By_Status (Model, C.Abstract_State_Consumer_Depends_Edge_Blocker) = 1,
                 "Depends abstract-state edge errors should block consumers directly");
         Assert (C.Count_By_Blocker_Family (Model, C.Abstract_State_Consumer_Blocker_Abstract_State) = 2,
                 "local abstract-state blocker family should be retained");
      end;
   end Local_Abstract_State_Errors_Override_Downstream_Consumers;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Abstract_State_Consumer_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (122461);
      Item : C.Abstract_State_Consumer_Context :=
        Complete_Context (1, C.Abstract_State_Consumer_Cross_Unit_Closure, Node);
   begin
      Item.Requires_Cross_Unit_State := True;
      Item.Cross_Unit_Visibility_Error := True;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Abstract_State_Consumer_Model := C.Build (Contexts);
         Row   : constant C.Abstract_State_Consumer_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find abstract-state consumer evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find consumer evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve the original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "consumer integration model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Consumers_Remain_Current_When_All_State_Evidence_Agrees'Access,
         "accepted consumers remain current when all abstract/refined-state evidence agrees");
      Register_Routine
        (T, Required_Consumer_Evidence_Blocks_Downstream_Confidence'Access,
         "required consumer evidence blocks downstream confidence");
      Register_Routine
        (T, Local_Abstract_State_Errors_Override_Downstream_Consumers'Access,
         "local abstract/refined-state errors override downstream consumers");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and blocker family");
   end Register_Tests;

end Test_Ada_Abstract_State_Refined_State_Consumer_Integration_Legality_Pass1224;
