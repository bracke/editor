with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Overload_Generic_Shared_State_Final_Legality is

   package Registration renames AUnit.Test_Cases.Registration;
   package C renames Editor.Ada_Overload_Generic_Shared_State_Final_Legality;
   use type C.Overload_Generic_Final_Row_Id;
   use type C.Overload_Generic_Final_Kind;
   use type C.Overload_Generic_Final_Blocker_Family;
   use type C.Overload_Generic_Final_Status;
   use type C.Overload_Generic_Final_Context;
   use type C.Overload_Generic_Final_Row;
   use type C.Overload_Generic_Final_Context_Model;
   use type C.Overload_Generic_Final_Model;
   use type C.Overload_Generic_Final_Set;
   package Overload renames C.Overload;
   package Generic_Replay renames C.Generic_Replay;
   package Dispatching renames C.Dispatching;
   package Volatile_Rep renames C.Volatile_Rep;
   package Abstract_Consumers renames C.Abstract_Consumers;
   package Closure renames C.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada overload generic shared-state final legality");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Overload_Generic_Final_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Overload_Generic_Final_Context is
      Result : C.Overload_Generic_Final_Context;
   begin
      Result.Id := C.Overload_Generic_Final_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Operation_Name := To_Unbounded_String ("Op" & Natural'Image (Id));
      Result.Type_Name := To_Unbounded_String ("T" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("Generic" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("Instance" & Natural'Image (Id));
      Result.Overload_Row := Overload.Overload_Shared_State_Row_Id (Id);
      Result.Overload_Status := Overload.Overload_Shared_State_Legal_Prefixed_Call_Accepted;
      Result.Generic_Replay_Row := Generic_Replay.Generic_Abstract_Replay_Row_Id (Id);
      Result.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Legal_Global_Aspect_Accepted;
      Result.Dispatching_Row := Dispatching.Dispatching_Global_Row_Id (Id);
      Result.Dispatching_Status := Dispatching.Dispatching_Global_Legal_Dynamic_Effect_Join_Accepted;
      Result.Volatile_Representation_Row := Volatile_Rep.Volatile_Atomic_Representation_Row_Id (Id);
      Result.Volatile_Representation_Status := Volatile_Rep.Volatile_Atomic_Representation_Legal_Stream_Attribute_Accepted;
      Result.Abstract_Consumer_Row := Abstract_Consumers.Abstract_State_Consumer_Row_Id (Id);
      Result.Abstract_Consumer_Status := Abstract_Consumers.Abstract_State_Consumer_Legal_Dispatching_Effect_Accepted;
      Result.Stabilized_Closure_Row := Closure.Shared_State_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1228 * Id;
      Result.Expected_Source_Fingerprint := 1228 * Id;
      Result.Substitution_Fingerprint := 8221 * Id;
      Result.Expected_Substitution_Fingerprint := 8221 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Final_Overload_Requires_Generic_And_Shared_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Overload_Generic_Final_Context_Model;
      Dispatching_Call : C.Overload_Generic_Final_Context :=
        Complete_Context (1, C.Overload_Generic_Final_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (122801));
      Generic_Formal : C.Overload_Generic_Final_Context :=
        Complete_Context (2, C.Overload_Generic_Final_Generic_Formal_Subprogram,
                          Editor.Ada_Syntax_Tree.Node_Id (122802));
   begin
      Dispatching_Call.Requires_Dispatching := True;
      Dispatching_Call.Requires_Abstract_Consumer := True;
      Generic_Formal.Requires_Generic_Replay := True;
      Generic_Formal.Requires_Volatile_Representation := True;
      C.Add_Context (Contexts, Dispatching_Call);
      C.Add_Context (Contexts, Generic_Formal);

      declare
         Model : constant C.Overload_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two overload/generic final rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete overload/generic evidence should be accepted");
         Assert (C.Blocked_Count (Model) = 0, "accepted overload/generic rows must not block");
         Assert
           (C.Count_By_Status (Model, C.Overload_Generic_Final_Legal_Dispatching_Call_Accepted) = 1,
            "dispatching call should accept only after dispatching and abstract-state evidence");
         Assert
           (C.Count_By_Status (Model, C.Overload_Generic_Final_Legal_Generic_Formal_Subprogram_Accepted) = 1,
            "generic formal subprogram should accept only after replay and representation evidence");
      end;
   end Accepted_Final_Overload_Requires_Generic_And_Shared_State_Evidence;

   procedure Missing_Or_Blocked_Prerequisites_Preserve_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Overload_Generic_Final_Context_Model;
      Overload_Blocker : C.Overload_Generic_Final_Context :=
        Complete_Context (1, C.Overload_Generic_Final_Prefixed_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (122821));
      Generic_Blocker : C.Overload_Generic_Final_Context :=
        Complete_Context (2, C.Overload_Generic_Final_Generic_Formal_Subprogram,
                          Editor.Ada_Syntax_Tree.Node_Id (122822));
      Representation_Blocker : C.Overload_Generic_Final_Context :=
        Complete_Context (3, C.Overload_Generic_Final_Volatile_Atomic_Effect,
                          Editor.Ada_Syntax_Tree.Node_Id (122823));
   begin
      Overload_Blocker.Overload_Status := Overload.Overload_Shared_State_Shared_State_Blocker;
      Generic_Blocker.Requires_Generic_Replay := True;
      Generic_Blocker.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Backmap_Blocker;
      Representation_Blocker.Requires_Volatile_Representation := True;
      Representation_Blocker.Volatile_Representation_Status :=
        Volatile_Rep.Volatile_Atomic_Representation_Atomic_Component_Blocker;
      C.Add_Context (Contexts, Overload_Blocker);
      C.Add_Context (Contexts, Generic_Blocker);
      C.Add_Context (Contexts, Representation_Blocker);

      declare
         Model : constant C.Overload_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept");
         Assert (C.Blocked_Count (Model) = 3, "three blocker rows should be retained");
         Assert
           (C.Count_By_Blocker_Family
              (Model, C.Overload_Generic_Final_Blocker_Overload_Shared_State) = 1,
            "overload shared-state blocker should be preserved");
         Assert
           (C.Count_By_Blocker_Family
              (Model, C.Overload_Generic_Final_Blocker_Generic_Abstract_Replay) = 1,
            "generic replay blocker should be preserved");
         Assert
           (C.Count_By_Blocker_Family
              (Model, C.Overload_Generic_Final_Blocker_Volatile_Atomic_Representation) = 1,
            "volatile/atomic representation blocker should be preserved");
      end;
   end Missing_Or_Blocked_Prerequisites_Preserve_Family;

   procedure RM_Edge_And_Fingerprint_Errors_Block_Directly
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Overload_Generic_Final_Context_Model;
      Access_Mismatch : C.Overload_Generic_Final_Context :=
        Complete_Context (1, C.Overload_Generic_Final_Access_Subprogram_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (122841));
      Numeric_Ambiguous : C.Overload_Generic_Final_Context :=
        Complete_Context (2, C.Overload_Generic_Final_Universal_Numeric_Operator,
                          Editor.Ada_Syntax_Tree.Node_Id (122842));
      Source_Mismatch : C.Overload_Generic_Final_Context :=
        Complete_Context (3, C.Overload_Generic_Final_Class_Wide_Result,
                          Editor.Ada_Syntax_Tree.Node_Id (122843));
   begin
      Access_Mismatch.Access_Profile_Effect_Mismatch := True;
      Numeric_Ambiguous.Universal_Numeric_State_Ambiguous := True;
      Source_Mismatch.Source_Fingerprint := 1;
      Source_Mismatch.Expected_Source_Fingerprint := 2;
      C.Add_Context (Contexts, Access_Mismatch);
      C.Add_Context (Contexts, Numeric_Ambiguous);
      C.Add_Context (Contexts, Source_Mismatch);

      declare
         Model : constant C.Overload_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Overload_Generic_Final_Access_Profile_Effect_Mismatch) = 1,
            "access-to-subprogram profile effects should block directly");
         Assert
           (C.Count_By_Status (Model, C.Overload_Generic_Final_Universal_Numeric_State_Ambiguous) = 1,
            "universal numeric state ambiguity should block directly");
         Assert
           (C.Count_By_Status (Model, C.Overload_Generic_Final_Source_Fingerprint_Mismatch) = 1,
            "source fingerprint mismatch should block directly");
      end;
   end RM_Edge_And_Fingerprint_Errors_Block_Directly;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Overload_Generic_Final_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (122861);
      Item : C.Overload_Generic_Final_Context :=
        Complete_Context (1, C.Overload_Generic_Final_Renamed_Primitive, Node);
   begin
      Item.Dispatching_Effect_Mismatch := True;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Overload_Generic_Final_Model := C.Build (Contexts);
         Row   : constant C.Overload_Generic_Final_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find overload/generic final evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find overload/generic final evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "overload/generic final model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Final_Overload_Requires_Generic_And_Shared_State_Evidence'Access,
         "accepted final overload requires generic and shared-state evidence");
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

end Test_Ada_Overload_Generic_Shared_State_Final_Legality;
