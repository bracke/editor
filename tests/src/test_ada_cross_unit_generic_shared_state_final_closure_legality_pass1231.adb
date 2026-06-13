with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality_Pass1231 is

   package Registration renames AUnit.Test_Cases.Registration;
   package C renames Editor.Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality;
   use type C.Cross_Unit_Generic_Final_Row_Id;
   use type C.Cross_Unit_Generic_Final_Kind;
   use type C.Cross_Unit_Generic_Dependency_State;
   use type C.Cross_Unit_Generic_Final_Blocker_Family;
   use type C.Cross_Unit_Generic_Final_Status;
   use type C.Cross_Unit_Generic_Final_Context;
   use type C.Cross_Unit_Generic_Final_Row;
   use type C.Cross_Unit_Generic_Final_Context_Model;
   use type C.Cross_Unit_Generic_Final_Model;
   use type C.Cross_Unit_Generic_Final_Set;
   package Cross_Shared renames C.Cross_Shared;
   package Generic_Replay renames C.Generic_Replay;
   package Overload_Generic renames C.Overload_Generic;
   package Rep_Generic renames C.Rep_Generic;
   package Tasking_Generic renames C.Tasking_Generic;
   package Abstract_Consumers renames C.Abstract_Consumers;
   package Closure renames C.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada cross-unit generic shared-state final closure legality pass1231");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Cross_Unit_Generic_Final_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Cross_Unit_Generic_Final_Context is
      Result : C.Cross_Unit_Generic_Final_Context;
   begin
      Result.Id := C.Cross_Unit_Generic_Final_Row_Id (Id);
      Result.Kind := Kind;
      Result.Dependency := C.Generic_Dependency_With_Visible;
      Result.Node := Node;
      Result.Unit_Name := To_Unbounded_String ("Unit" & Natural'Image (Id));
      Result.Dependency_Name := To_Unbounded_String ("Dep" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("Generic" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("Instance" & Natural'Image (Id));
      Result.Cross_Shared_Row := Cross_Shared.Cross_Unit_Shared_State_Row_Id (Id);
      Result.Cross_Shared_Status := Cross_Shared.Cross_Unit_Shared_State_Legal_Generic_Instance_Accepted;
      Result.Generic_Replay_Row := Generic_Replay.Generic_Abstract_Replay_Row_Id (Id);
      Result.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Legal_Nested_Instance_State_Accepted;
      Result.Overload_Generic_Row := Overload_Generic.Overload_Generic_Final_Row_Id (Id);
      Result.Overload_Generic_Status := Overload_Generic.Overload_Generic_Final_Legal_Dispatching_Call_Accepted;
      Result.Representation_Generic_Row := Rep_Generic.Representation_Generic_Final_Row_Id (Id);
      Result.Representation_Generic_Status := Rep_Generic.Representation_Generic_Final_Legal_Generic_Instance_Representation_Accepted;
      Result.Tasking_Generic_Row := Tasking_Generic.Tasking_Generic_Final_Row_Id (Id);
      Result.Tasking_Generic_Status := Tasking_Generic.Tasking_Generic_Final_Legal_Generic_Task_Body_Accepted;
      Result.Abstract_Consumer_Row := Abstract_Consumers.Abstract_State_Consumer_Row_Id (Id);
      Result.Abstract_Consumer_Status := Abstract_Consumers.Abstract_State_Consumer_Legal_Cross_Unit_Closure_Accepted;
      Result.Stabilized_Closure_Row := Closure.Shared_State_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1231 * Id;
      Result.Expected_Source_Fingerprint := 1231 * Id;
      Result.Substitution_Fingerprint := 1321 * Id;
      Result.Expected_Substitution_Fingerprint := 1321 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Cross_Unit_Generic_Closure_Requires_All_Final_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Cross_Unit_Generic_Final_Context_Model;
      Generic_Instance : C.Cross_Unit_Generic_Final_Context :=
        Complete_Context (1, C.Cross_Unit_Generic_Final_Generic_Instance,
                          Editor.Ada_Syntax_Tree.Node_Id (123101));
      Tasking_Path : C.Cross_Unit_Generic_Final_Context :=
        Complete_Context (2, C.Cross_Unit_Generic_Final_Tasking_Protected,
                          Editor.Ada_Syntax_Tree.Node_Id (123102));
   begin
      Generic_Instance.Requires_Generic_Replay := True;
      Generic_Instance.Requires_Overload_Generic := True;
      Generic_Instance.Requires_Representation_Generic := True;
      Tasking_Path.Requires_Tasking_Generic := True;
      Tasking_Path.Requires_Abstract_Consumer := True;
      C.Add_Context (Contexts, Generic_Instance);
      C.Add_Context (Contexts, Tasking_Path);

      declare
         Model : constant C.Cross_Unit_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two cross-unit generic closure rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete final evidence should accept");
         Assert (C.Blocked_Count (Model) = 0, "accepted closure rows must not block downstream");
         Assert
           (C.Count_By_Status (Model, C.Cross_Unit_Generic_Final_Legal_Generic_Instance_Accepted) = 1,
            "generic instance closure should accept with replay/overload/representation evidence");
         Assert
           (C.Count_By_Status (Model, C.Cross_Unit_Generic_Final_Legal_Tasking_Protected_Accepted) = 1,
            "tasking/protected closure should accept with tasking and abstract evidence");
      end;
   end Accepted_Cross_Unit_Generic_Closure_Requires_All_Final_Evidence;

   procedure Dependency_View_And_Generic_Blockers_Preserve_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Cross_Unit_Generic_Final_Context_Model;
      Missing_Dependency : C.Cross_Unit_Generic_Final_Context :=
        Complete_Context (1, C.Cross_Unit_Generic_Final_With_Use,
                          Editor.Ada_Syntax_Tree.Node_Id (123121));
      View_Blocker : C.Cross_Unit_Generic_Final_Context :=
        Complete_Context (2, C.Cross_Unit_Generic_Final_Limited_View,
                          Editor.Ada_Syntax_Tree.Node_Id (123122));
      Generic_Blocker : C.Cross_Unit_Generic_Final_Context :=
        Complete_Context (3, C.Cross_Unit_Generic_Final_Generic_Body,
                          Editor.Ada_Syntax_Tree.Node_Id (123123));
   begin
      Missing_Dependency.Dependency := C.Generic_Dependency_Missing;
      View_Blocker.Limited_View_Barrier := True;
      Generic_Blocker.Requires_Generic_Replay := True;
      Generic_Blocker.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Backmap_Blocker;
      C.Add_Context (Contexts, Missing_Dependency);
      C.Add_Context (Contexts, View_Blocker);
      C.Add_Context (Contexts, Generic_Blocker);

      declare
         Model : constant C.Cross_Unit_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked closure rows must not accept");
         Assert (C.Blocked_Count (Model) = 3, "three blockers should be retained");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Cross_Unit_Generic_Final_Blocker_Dependency) = 1,
            "dependency blocker should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Cross_Unit_Generic_Final_Blocker_View_Barrier) = 1,
            "view barrier should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Cross_Unit_Generic_Final_Blocker_Generic_Abstract_Replay) = 1,
            "generic replay blocker should be preserved");
      end;
   end Dependency_View_And_Generic_Blockers_Preserve_Family;

   procedure Final_Consumer_And_Fingerprint_Blockers_Block_Directly
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Cross_Unit_Generic_Final_Context_Model;
      Overload_Blocker : C.Cross_Unit_Generic_Final_Context :=
        Complete_Context (1, C.Cross_Unit_Generic_Final_Overload_Type,
                          Editor.Ada_Syntax_Tree.Node_Id (123141));
      Tasking_Blocker : C.Cross_Unit_Generic_Final_Context :=
        Complete_Context (2, C.Cross_Unit_Generic_Final_Tasking_Protected,
                          Editor.Ada_Syntax_Tree.Node_Id (123142));
      Fingerprint_Blocker : C.Cross_Unit_Generic_Final_Context :=
        Complete_Context (3, C.Cross_Unit_Generic_Final_Representation,
                          Editor.Ada_Syntax_Tree.Node_Id (123143));
   begin
      Overload_Blocker.Requires_Overload_Generic := True;
      Overload_Blocker.Overload_Generic_Status := Overload_Generic.Overload_Generic_Final_Generic_Replay_Blocker;
      Tasking_Blocker.Tasking_Effect_Blocker := True;
      Fingerprint_Blocker.Source_Fingerprint := 1;
      Fingerprint_Blocker.Expected_Source_Fingerprint := 2;
      C.Add_Context (Contexts, Overload_Blocker);
      C.Add_Context (Contexts, Tasking_Blocker);
      C.Add_Context (Contexts, Fingerprint_Blocker);

      declare
         Model : constant C.Cross_Unit_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Cross_Unit_Generic_Final_Overload_Generic_Blocker) = 1,
            "overload/generic blocker should block directly");
         Assert
           (C.Count_By_Status (Model, C.Cross_Unit_Generic_Final_Tasking_Effect_Blocker) = 1,
            "tasking effect blocker should block directly");
         Assert
           (C.Count_By_Status (Model, C.Cross_Unit_Generic_Final_Source_Fingerprint_Mismatch) = 1,
            "source fingerprint mismatch should block directly");
      end;
   end Final_Consumer_And_Fingerprint_Blockers_Block_Directly;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Cross_Unit_Generic_Final_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (123161);
      Item : C.Cross_Unit_Generic_Final_Context :=
        Complete_Context (1, C.Cross_Unit_Generic_Final_Representation, Node);
   begin
      Item.Representation_Effect_Blocker := True;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Cross_Unit_Generic_Final_Model := C.Build (Contexts);
         Row   : constant C.Cross_Unit_Generic_Final_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find cross-unit generic closure evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find cross-unit generic closure evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "cross-unit generic closure model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Cross_Unit_Generic_Closure_Requires_All_Final_Evidence'Access,
         "accepted cross-unit generic closure requires all final evidence");
      Register_Routine
        (T, Dependency_View_And_Generic_Blockers_Preserve_Family'Access,
         "dependency view and generic blockers preserve family");
      Register_Routine
        (T, Final_Consumer_And_Fingerprint_Blockers_Block_Directly'Access,
         "final consumer and fingerprint blockers block directly");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and blocker family");
   end Register_Tests;

end Test_Ada_Cross_Unit_Generic_Shared_State_Final_Closure_Legality_Pass1231;
