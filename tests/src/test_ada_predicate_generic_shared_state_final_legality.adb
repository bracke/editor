with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Predicate_Generic_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Predicate_Generic_Shared_State_Final_Legality is

   package C renames Editor.Ada_Predicate_Generic_Shared_State_Final_Legality;
   use type C.Predicate_Generic_Final_Row_Id;
   use type C.Predicate_Generic_Final_Kind;
   use type C.Predicate_Generic_Final_Blocker_Family;
   use type C.Predicate_Generic_Final_Status;
   use type C.Predicate_Generic_Final_Context;
   use type C.Predicate_Generic_Final_Row;
   use type C.Predicate_Generic_Final_Context_Model;
   use type C.Predicate_Generic_Final_Model;
   use type C.Predicate_Generic_Final_Set;
   package PIU renames C.PIU;
   package PIP renames C.PIP;
   package Cross_Generic renames C.Cross_Generic;
   package Generic_Replay renames C.Generic_Replay;
   package Overload_Generic renames C.Overload_Generic;
   package Rep_Generic renames C.Rep_Generic;
   package Tasking_Generic renames C.Tasking_Generic;
   package Access_Generic renames C.Access_Generic;
   package Disc_Generic renames C.Disc_Generic;
   package Exception_Generic renames C.Exception_Generic;
   package Renaming_Generic renames C.Renaming_Generic;
   package Dispatching_Global renames C.Dispatching_Global;
   package Closure renames C.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada predicate generic shared-state final legality");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Predicate_Generic_Final_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Predicate_Generic_Final_Context is
      Result : C.Predicate_Generic_Final_Context;
   begin
      Result.Id := C.Predicate_Generic_Final_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Subtype_Name := To_Unbounded_String ("Subtype" & Natural'Image (Id));
      Result.Object_Name := To_Unbounded_String ("Obj" & Natural'Image (Id));
      Result.Type_Name := To_Unbounded_String ("T" & Natural'Image (Id));
      Result.Operation_Name := To_Unbounded_String ("Op" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("G" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("I" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Predicate_Use_Row := PIU.Predicate_Use_Legality_Id (Id);
      Result.Predicate_Use_Status := PIU.Predicate_Use_Legality_Legal_Dynamic_Predicate_Check;
      Result.Propagation_Row := PIP.Propagation_Row_Id (Id);
      Result.Propagation_Status := PIP.Propagation_Legal_Dynamic_Predicate_Propagated;
      Result.Cross_Generic_Row := Cross_Generic.Cross_Unit_Generic_Final_Row_Id (Id);
      Result.Cross_Generic_Status := Cross_Generic.Cross_Unit_Generic_Final_Legal_Generic_Instance_Accepted;
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
      Result.Exception_Generic_Row := Exception_Generic.Exception_Generic_Final_Row_Id (Id);
      Result.Exception_Generic_Status := Exception_Generic.Exception_Generic_Final_Legal_Controlled_Finalize_Accepted;
      Result.Renaming_Generic_Row := Renaming_Generic.Renaming_Generic_Final_Row_Id (Id);
      Result.Renaming_Generic_Status := Renaming_Generic.Renaming_Generic_Final_Legal_Selected_Alias_Accepted;
      Result.Dispatching_Global_Row := Dispatching_Global.Dispatching_Global_Row_Id (Id);
      Result.Dispatching_Global_Status := Dispatching_Global.Dispatching_Global_Legal_Abstract_State_Join_Accepted;
      Result.Stabilized_Closure_Row := Closure.Shared_State_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1237 * Id;
      Result.Expected_Source_Fingerprint := 1237 * Id;
      Result.Substitution_Fingerprint := 7321 * Id;
      Result.Expected_Substitution_Fingerprint := 7321 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Predicate_Invariant_Requires_Generic_Shared_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Predicate_Generic_Final_Context_Model;
      Dispatching_Call : C.Predicate_Generic_Final_Context :=
        Complete_Context (1, C.Predicate_Generic_Final_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (123701));
      Finalization_Path : C.Predicate_Generic_Final_Context :=
        Complete_Context (2, C.Predicate_Generic_Final_Controlled_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (123702));
   begin
      Dispatching_Call.Requires_Dispatching_Global := True;
      Dispatching_Call.Requires_Generic_Replay := True;
      Dispatching_Call.Requires_Overload_Generic := True;
      Finalization_Path.Requires_Exception_Generic := True;
      Finalization_Path.Requires_Accessibility_Generic := True;
      Finalization_Path.Requires_Discriminant_Generic := True;
      Finalization_Path.Requires_Representation_Generic := True;
      C.Add_Context (Contexts, Dispatching_Call);
      C.Add_Context (Contexts, Finalization_Path);

      declare
         Model : constant C.Predicate_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two predicate/invariant generic shared-state rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete predicate/invariant and shared-state evidence should accept");
         Assert (C.Blocked_Count (Model) = 0, "accepted predicate/invariant rows should not block downstream legality");
         Assert
           (C.Count_By_Status (Model, C.Predicate_Generic_Final_Legal_Dispatching_Call_Accepted) = 1,
            "dispatching predicate obligation should be accepted");
         Assert
           (C.Count_By_Status (Model, C.Predicate_Generic_Final_Legal_Controlled_Finalization_Accepted) = 1,
            "controlled finalization invariant obligation should be accepted");
      end;
   end Accepted_Predicate_Invariant_Requires_Generic_Shared_State_Evidence;

   procedure Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Predicate_Generic_Final_Context_Model;
      Predicate_Use_Blocker : C.Predicate_Generic_Final_Context :=
        Complete_Context (1, C.Predicate_Generic_Final_Assignment,
                          Editor.Ada_Syntax_Tree.Node_Id (123721));
      Exception_Blocker : C.Predicate_Generic_Final_Context :=
        Complete_Context (2, C.Predicate_Generic_Final_Controlled_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (123722));
      Renaming_Blocker : C.Predicate_Generic_Final_Context :=
        Complete_Context (3, C.Predicate_Generic_Final_Renamed_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (123723));
   begin
      Predicate_Use_Blocker.Predicate_Use_Status := PIU.Predicate_Use_Legality_Invariant_Violation;
      Exception_Blocker.Requires_Exception_Generic := True;
      Exception_Blocker.Exception_Generic_Status := Exception_Generic.Exception_Generic_Final_Finalization_Order_Blocker;
      Renaming_Blocker.Requires_Renaming_Generic := True;
      Renaming_Blocker.Renaming_Generic_Status := Renaming_Generic.Renaming_Generic_Final_Visibility_Blocker;
      C.Add_Context (Contexts, Predicate_Use_Blocker);
      C.Add_Context (Contexts, Exception_Blocker);
      C.Add_Context (Contexts, Renaming_Blocker);

      declare
         Model : constant C.Predicate_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept predicate/invariant conclusions");
         Assert (C.Blocked_Count (Model) = 3, "three prerequisite blockers should be retained");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Predicate_Generic_Final_Blocker_Predicate_Use_Site) = 1,
            "predicate use-site blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Predicate_Generic_Final_Blocker_Exception_Finalization_Generic_Shared_State) = 1,
            "exception/finalization blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Predicate_Generic_Final_Blocker_Renaming_Generic_Shared_State) = 1,
            "renaming blocker family should be preserved");
      end;
   end Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family;

   procedure Local_Predicate_Invariant_RM_Errors_Block_Directly
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Predicate_Generic_Final_Context_Model;
      Static_Error : C.Predicate_Generic_Final_Context :=
        Complete_Context (1, C.Predicate_Generic_Final_Generic_Actual,
                          Editor.Ada_Syntax_Tree.Node_Id (123741));
      Invariant_Error : C.Predicate_Generic_Final_Context :=
        Complete_Context (2, C.Predicate_Generic_Final_Derived_Type,
                          Editor.Ada_Syntax_Tree.Node_Id (123742));
      Dispatching_Error : C.Predicate_Generic_Final_Context :=
        Complete_Context (3, C.Predicate_Generic_Final_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (123743));
   begin
      Static_Error.Static_Predicate_Blocker := True;
      Invariant_Error.Derived_Invariant_Blocker := True;
      Dispatching_Error.Dispatching_Effect_Blocker := True;
      C.Add_Context (Contexts, Static_Error);
      C.Add_Context (Contexts, Invariant_Error);
      C.Add_Context (Contexts, Dispatching_Error);

      declare
         Model : constant C.Predicate_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Predicate_Generic_Final_Static_Predicate_Blocker) = 1,
            "static predicate errors should block directly");
         Assert
           (C.Count_By_Status (Model, C.Predicate_Generic_Final_Derived_Invariant_Blocker) = 1,
            "derived invariant errors should block directly");
         Assert
           (C.Count_By_Status (Model, C.Predicate_Generic_Final_Dispatching_Effect_Blocker) = 1,
            "dispatching effect errors should block directly");
      end;
   end Local_Predicate_Invariant_RM_Errors_Block_Directly;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Predicate_Generic_Final_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (123761);
      Item : C.Predicate_Generic_Final_Context :=
        Complete_Context (1, C.Predicate_Generic_Final_Discriminant_Dependent_Object, Node);
   begin
      Item.Requires_Discriminant_Generic := True;
      Item.Discriminant_Generic_Status := Disc_Generic.Discriminant_Generic_Final_Variant_Coverage_Blocker;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Predicate_Generic_Final_Model := C.Build (Contexts);
         Row   : constant C.Predicate_Generic_Final_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find predicate/invariant generic shared-state evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find predicate/invariant generic shared-state evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve the original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "predicate/invariant generic shared-state final model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Predicate_Invariant_Requires_Generic_Shared_State_Evidence'Access,
         "accepted predicate/invariant requires generic shared-state evidence");
      Register_Routine
        (T, Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family'Access,
         "missing or blocked prerequisites preserve blocker family");
      Register_Routine
        (T, Local_Predicate_Invariant_RM_Errors_Block_Directly'Access,
         "local predicate/invariant RM errors block directly");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and blocker family");
   end Register_Tests;

end Test_Ada_Predicate_Generic_Shared_State_Final_Legality;
