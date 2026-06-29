with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Generic_Abstract_State_Replay_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Abstract_State_Replay_Legality is

   package Registration renames AUnit.Test_Cases.Registration;
   package C renames Editor.Ada_Generic_Abstract_State_Replay_Legality;
   use type C.Generic_Abstract_Replay_Row_Id;
   use type C.Generic_Abstract_Replay_Kind;
   use type C.Generic_Abstract_Replay_Blocker_Family;
   use type C.Generic_Abstract_Replay_Status;
   use type C.Generic_Abstract_Replay_Context;
   use type C.Generic_Abstract_Replay_Row;
   use type C.Generic_Abstract_Replay_Context_Model;
   use type C.Generic_Abstract_Replay_Model;
   use type C.Generic_Abstract_Replay_Set;
   package Backmap renames C.Backmap;
   package Nested renames C.Nested;
   package Abstract_Consumers renames C.Abstract_Consumers;
   package Shared renames C.Shared;
   package Dispatching renames C.Dispatching;
   package Closure renames C.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada generic abstract-state replay legality");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Generic_Abstract_Replay_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Generic_Abstract_Replay_Context is
      Result : C.Generic_Abstract_Replay_Context;
   begin
      Result.Id := C.Generic_Abstract_Replay_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Generic_Unit_Name := To_Unbounded_String ("Generic_Unit" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("Instance" & Natural'Image (Id));
      Result.Formal_Name := To_Unbounded_String ("Formal" & Natural'Image (Id));
      Result.Actual_Name := To_Unbounded_String ("Actual" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Backmap_Row := Backmap.Generic_Backmap_Row_Id (Id);
      Result.Backmap_Status := Backmap.Generic_Backmap_Legal_Nested_Instance_Backmapped;
      Result.Nested_Row := Nested.Nested_Generic_Closure_Row_Id (Id);
      Result.Nested_Status := Nested.Nested_Generic_Legal_Nested_Instance_Closed;
      Result.Abstract_Consumer_Row := Abstract_Consumers.Abstract_State_Consumer_Row_Id (Id);
      Result.Abstract_Consumer_Status := Abstract_Consumers.Abstract_State_Consumer_Legal_Generic_Replay_Accepted;
      Result.Shared_State_Row := Shared.Shared_State_Row_Id (Id);
      Result.Shared_State_Status := Shared.Shared_State_Legal_Abstract_State_Effect_Accepted;
      Result.Dispatching_Row := Dispatching.Dispatching_Global_Row_Id (Id);
      Result.Dispatching_Status := Dispatching.Dispatching_Global_Legal_Generic_Formal_Dispatch_Accepted;
      Result.Stabilized_Closure_Row := Closure.Shared_State_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1227 * Id;
      Result.Expected_Source_Fingerprint := 1227 * Id;
      Result.Substitution_Fingerprint := 2271 * Id;
      Result.Expected_Substitution_Fingerprint := 2271 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Generic_Replay_Requires_State_And_Backmapping_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Generic_Abstract_Replay_Context_Model;
      Global : C.Generic_Abstract_Replay_Context :=
        Complete_Context (1, C.Generic_Abstract_Replay_Global_Aspect,
                          Editor.Ada_Syntax_Tree.Node_Id (122701));
      Nested_State : C.Generic_Abstract_Replay_Context :=
        Complete_Context (2, C.Generic_Abstract_Replay_Nested_Instance_State,
                          Editor.Ada_Syntax_Tree.Node_Id (122702));
   begin
      Nested_State.Requires_Nested_Closure := True;
      Nested_State.Requires_Shared_State := True;
      C.Add_Context (Contexts, Global);
      C.Add_Context (Contexts, Nested_State);

      declare
         Model : constant C.Generic_Abstract_Replay_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two generic abstract-state replay rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete replay evidence should be accepted");
         Assert (C.Blocked_Count (Model) = 0, "accepted replay rows must not block downstream consumers");
         Assert
           (C.Count_By_Status (Model, C.Generic_Abstract_Replay_Legal_Global_Aspect_Accepted) = 1,
            "Global aspect replay should be accepted");
         Assert
           (C.Count_By_Status (Model, C.Generic_Abstract_Replay_Legal_Nested_Instance_State_Accepted) = 1,
            "nested instance state replay should be accepted");
      end;
   end Accepted_Generic_Replay_Requires_State_And_Backmapping_Evidence;

   procedure Missing_Or_Blocked_Prerequisites_Preserve_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Generic_Abstract_Replay_Context_Model;
      Backmap_Blocker : C.Generic_Abstract_Replay_Context :=
        Complete_Context (1, C.Generic_Abstract_Replay_Depends_Aspect,
                          Editor.Ada_Syntax_Tree.Node_Id (122721));
      Shared_Blocker : C.Generic_Abstract_Replay_Context :=
        Complete_Context (2, C.Generic_Abstract_Replay_Volatile_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (122722));
      Dispatch_Blocker : C.Generic_Abstract_Replay_Context :=
        Complete_Context (3, C.Generic_Abstract_Replay_Dispatching_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (122723));
   begin
      Backmap_Blocker.Backmap_Status := Backmap.Generic_Backmap_Source_Instance_Fingerprint_Mismatch;
      Shared_Blocker.Requires_Shared_State := True;
      Shared_Blocker.Shared_State_Status := Shared.Shared_State_Volatile_Read_Order_Blocker;
      Dispatch_Blocker.Requires_Dispatching := True;
      Dispatch_Blocker.Dispatching_Status := Dispatching.Dispatching_Global_Generic_Formal_Effect_Blocker;
      C.Add_Context (Contexts, Backmap_Blocker);
      C.Add_Context (Contexts, Shared_Blocker);
      C.Add_Context (Contexts, Dispatch_Blocker);

      declare
         Model : constant C.Generic_Abstract_Replay_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked replay prerequisites must not accept");
         Assert (C.Blocked_Count (Model) = 3, "three blocker rows should be retained");
         Assert
           (C.Count_By_Blocker_Family
              (Model, C.Generic_Abstract_Replay_Blocker_Source_Instance_Backmap) = 1,
            "source/instance backmap blocker should be preserved");
         Assert
           (C.Count_By_Blocker_Family
              (Model, C.Generic_Abstract_Replay_Blocker_Volatile_Atomic_Shared_State) = 1,
            "volatile/atomic shared-state blocker should be preserved");
         Assert
           (C.Count_By_Blocker_Family
              (Model, C.Generic_Abstract_Replay_Blocker_Dispatching_Global) = 1,
            "dispatching Global blocker should be preserved");
      end;
   end Missing_Or_Blocked_Prerequisites_Preserve_Family;

   procedure Formal_Substitution_And_Fingerprint_Errors_Block_Directly
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Generic_Abstract_Replay_Context_Model;
      Formal_Missing : C.Generic_Abstract_Replay_Context :=
        Complete_Context (1, C.Generic_Abstract_Replay_Formal_Package_State,
                          Editor.Ada_Syntax_Tree.Node_Id (122741));
      Mode_Mismatch : C.Generic_Abstract_Replay_Context :=
        Complete_Context (2, C.Generic_Abstract_Replay_Atomic_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (122742));
      Source_Mismatch : C.Generic_Abstract_Replay_Context :=
        Complete_Context (3, C.Generic_Abstract_Replay_Shared_Variable_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (122743));
   begin
      Formal_Missing.Formal_Actual_Missing := True;
      Mode_Mismatch.Formal_Actual_Mode_Mismatch := True;
      Source_Mismatch.Source_Fingerprint := 1;
      Source_Mismatch.Expected_Source_Fingerprint := 2;
      C.Add_Context (Contexts, Formal_Missing);
      C.Add_Context (Contexts, Mode_Mismatch);
      C.Add_Context (Contexts, Source_Mismatch);

      declare
         Model : constant C.Generic_Abstract_Replay_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Generic_Abstract_Replay_Formal_Actual_Missing) = 1,
            "missing formal/actual map should block directly");
         Assert
           (C.Count_By_Status (Model, C.Generic_Abstract_Replay_Formal_Actual_Mode_Mismatch) = 1,
            "formal/actual mode mismatch should block directly");
         Assert
           (C.Count_By_Status (Model, C.Generic_Abstract_Replay_Source_Fingerprint_Mismatch) = 1,
            "source fingerprint mismatch should block directly");
      end;
   end Formal_Substitution_And_Fingerprint_Errors_Block_Directly;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Generic_Abstract_Replay_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (122761);
      Item : C.Generic_Abstract_Replay_Context :=
        Complete_Context (1, C.Generic_Abstract_Replay_Refined_State, Node);
   begin
      Item.Formal_Actual_State_Mismatch := True;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Generic_Abstract_Replay_Model := C.Build (Contexts);
         Row   : constant C.Generic_Abstract_Replay_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find generic replay evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find generic replay evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "generic abstract-state replay model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Generic_Replay_Requires_State_And_Backmapping_Evidence'Access,
         "accepted generic replay requires state and backmapping evidence");
      Register_Routine
        (T, Missing_Or_Blocked_Prerequisites_Preserve_Family'Access,
         "missing or blocked prerequisites preserve family");
      Register_Routine
        (T, Formal_Substitution_And_Fingerprint_Errors_Block_Directly'Access,
         "formal substitution and fingerprint errors block directly");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and blocker family");
   end Register_Tests;

end Test_Ada_Generic_Abstract_State_Replay_Legality;
