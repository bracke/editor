with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Dataflow_Generic_Shared_State_Final_Legality is

   package C renames Editor.Ada_Dataflow_Generic_Shared_State_Final_Legality;
   use type C.Dataflow_Generic_Final_Row_Id;
   use type C.Dataflow_Generic_Final_Kind;
   use type C.Dataflow_Generic_Final_Blocker_Family;
   use type C.Dataflow_Generic_Final_Status;
   use type C.Dataflow_Generic_Final_Context;
   use type C.Dataflow_Generic_Final_Row;
   use type C.Dataflow_Generic_Final_Context_Model;
   use type C.Dataflow_Generic_Final_Model;
   use type C.Dataflow_Generic_Final_Set;
   package Init renames C.Init;
   package Dataflow_Init renames C.Dataflow_Init;
   package Predicate_Dataflow renames C.Predicate_Dataflow;
   package Predicate_Generic renames C.Predicate_Generic;
   package Generic_Replay renames C.Generic_Replay;
   package Closure renames C.Closure;
   package Rep_Generic renames C.Rep_Generic;
   package Tasking_Generic renames C.Tasking_Generic;
   package Access_Generic renames C.Access_Generic;
   package Disc_Generic renames C.Disc_Generic;
   package Exception_Generic renames C.Exception_Generic;
   package Renaming_Generic renames C.Renaming_Generic;
   package Volatile_Rep renames C.Volatile_Rep;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada dataflow generic shared-state final legality");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Dataflow_Generic_Final_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Dataflow_Generic_Final_Context is
      Result : C.Dataflow_Generic_Final_Context;
   begin
      Result.Id := C.Dataflow_Generic_Final_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Object_Name := To_Unbounded_String ("Obj" & Natural'Image (Id));
      Result.Component_Name := To_Unbounded_String ("Component" & Natural'Image (Id));
      Result.Operation_Name := To_Unbounded_String ("Op" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("G" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("I" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Initialization_Row := Init.Initialization_Legality_Id (Id);
      Result.Initialization_Status := Init.Initialization_Legality_Definitely_Initialized;
      Result.Dataflow_Init_Row := Dataflow_Init.Dataflow_Init_Row_Id (Id);
      Result.Dataflow_Init_Status := Dataflow_Init.Dataflow_Init_Legal_Read_Write_Accepted;
      Result.Predicate_Dataflow_Row := Predicate_Dataflow.Predicate_Dataflow_Row_Id (Id);
      Result.Predicate_Dataflow_Status := Predicate_Dataflow.Predicate_Dataflow_Legal_Flow_Effect_Accepted;
      Result.Predicate_Generic_Row := Predicate_Generic.Predicate_Generic_Final_Row_Id (Id);
      Result.Predicate_Generic_Status := Predicate_Generic.Predicate_Generic_Final_Legal_Dispatching_Call_Accepted;
      Result.Generic_Replay_Row := Generic_Replay.Generic_Abstract_Replay_Row_Id (Id);
      Result.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Legal_Nested_Instance_State_Accepted;
      Result.Stabilized_Closure_Row := Closure.Shared_State_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Accepted_Current;
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
      Result.Volatile_Representation_Row := Volatile_Rep.Volatile_Atomic_Representation_Row_Id (Id);
      Result.Volatile_Representation_Status := Volatile_Rep.Volatile_Atomic_Representation_Legal_Record_Layout_Accepted;
      Result.Source_Fingerprint := 1238 * Id;
      Result.Expected_Source_Fingerprint := 1238 * Id;
      Result.Substitution_Fingerprint := 8321 * Id;
      Result.Expected_Substitution_Fingerprint := 8321 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Dataflow_Requires_Generic_Shared_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Dataflow_Generic_Final_Context_Model;
      Variant_Component : C.Dataflow_Generic_Final_Context :=
        Complete_Context (1, C.Dataflow_Generic_Final_Variant_Component,
                          Editor.Ada_Syntax_Tree.Node_Id (123801));
      Volatile_Object : C.Dataflow_Generic_Final_Context :=
        Complete_Context (2, C.Dataflow_Generic_Final_Volatile_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (123802));
   begin
      Variant_Component.Requires_Discriminant_Generic := True;
      Variant_Component.Requires_Representation_Generic := True;
      Variant_Component.Requires_Predicate_Generic := True;
      Volatile_Object.Requires_Volatile_Representation := True;
      Volatile_Object.Requires_Tasking_Generic := True;
      Volatile_Object.Requires_Generic_Replay := True;
      C.Add_Context (Contexts, Variant_Component);
      C.Add_Context (Contexts, Volatile_Object);

      declare
         Model : constant C.Dataflow_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two dataflow generic shared-state rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete dataflow/shared-state evidence should accept");
         Assert (C.Blocked_Count (Model) = 0, "accepted dataflow rows should not block downstream legality");
         Assert
           (C.Count_By_Status (Model, C.Dataflow_Generic_Final_Legal_Variant_Component_Accepted) = 1,
            "variant-dependent component dataflow should be accepted");
         Assert
           (C.Count_By_Status (Model, C.Dataflow_Generic_Final_Legal_Volatile_Object_Accepted) = 1,
            "volatile object dataflow should be accepted");
      end;
   end Accepted_Dataflow_Requires_Generic_Shared_State_Evidence;

   procedure Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Dataflow_Generic_Final_Context_Model;
      Init_Blocker : C.Dataflow_Generic_Final_Context :=
        Complete_Context (1, C.Dataflow_Generic_Final_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (123821));
      Predicate_Blocker : C.Dataflow_Generic_Final_Context :=
        Complete_Context (2, C.Dataflow_Generic_Final_Dispatching_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (123822));
      Volatile_Blocker : C.Dataflow_Generic_Final_Context :=
        Complete_Context (3, C.Dataflow_Generic_Final_Atomic_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (123823));
   begin
      Init_Blocker.Initialization_Status := Init.Initialization_Legality_Read_Before_Write;
      Predicate_Blocker.Requires_Predicate_Generic := True;
      Predicate_Blocker.Predicate_Generic_Status := Predicate_Generic.Predicate_Generic_Final_Dispatching_Effect_Blocker;
      Volatile_Blocker.Requires_Volatile_Representation := True;
      Volatile_Blocker.Volatile_Representation_Status := Volatile_Rep.Volatile_Atomic_Representation_Atomic_Component_Blocker;
      C.Add_Context (Contexts, Init_Blocker);
      C.Add_Context (Contexts, Predicate_Blocker);
      C.Add_Context (Contexts, Volatile_Blocker);

      declare
         Model : constant C.Dataflow_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept dataflow conclusions");
         Assert (C.Blocked_Count (Model) = 3, "three prerequisite blockers should be retained");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Dataflow_Generic_Final_Blocker_Definite_Initialization) = 1,
            "definite-initialization blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Dataflow_Generic_Final_Blocker_Predicate_Generic_Shared_State) = 1,
            "predicate generic shared-state blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Dataflow_Generic_Final_Blocker_Volatile_Atomic_Representation) = 1,
            "volatile/atomic representation blocker family should be preserved");
      end;
   end Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family;

   procedure Local_Dataflow_RM_Errors_Block_Directly
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Dataflow_Generic_Final_Context_Model;
      Read_Error : C.Dataflow_Generic_Final_Context :=
        Complete_Context (1, C.Dataflow_Generic_Final_Read,
                          Editor.Ada_Syntax_Tree.Node_Id (123841));
      Finalization_Error : C.Dataflow_Generic_Final_Context :=
        Complete_Context (2, C.Dataflow_Generic_Final_Controlled_Finalization,
                          Editor.Ada_Syntax_Tree.Node_Id (123842));
      Access_Error : C.Dataflow_Generic_Final_Context :=
        Complete_Context (3, C.Dataflow_Generic_Final_Access_Escape,
                          Editor.Ada_Syntax_Tree.Node_Id (123843));
   begin
      Read_Error.Read_Before_Write_Blocker := True;
      Finalization_Error.Finalization_Blocker := True;
      Access_Error.Access_Escape_Blocker := True;
      C.Add_Context (Contexts, Read_Error);
      C.Add_Context (Contexts, Finalization_Error);
      C.Add_Context (Contexts, Access_Error);

      declare
         Model : constant C.Dataflow_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Dataflow_Generic_Final_Read_Before_Write_Blocker) = 1,
            "read-before-write errors should block directly");
         Assert
           (C.Count_By_Status (Model, C.Dataflow_Generic_Final_Finalization_Blocker) = 1,
            "finalization dataflow errors should block directly");
         Assert
           (C.Count_By_Status (Model, C.Dataflow_Generic_Final_Access_Escape_Blocker) = 1,
            "access escape dataflow errors should block directly");
      end;
   end Local_Dataflow_RM_Errors_Block_Directly;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Dataflow_Generic_Final_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (123861);
      Item : C.Dataflow_Generic_Final_Context :=
        Complete_Context (1, C.Dataflow_Generic_Final_Return_Object, Node);
   begin
      Item.Requires_Exception_Generic := True;
      Item.Exception_Generic_Status := Exception_Generic.Exception_Generic_Final_Finalization_Order_Blocker;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Dataflow_Generic_Final_Model := C.Build (Contexts);
         Row   : constant C.Dataflow_Generic_Final_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find dataflow generic shared-state evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find dataflow generic shared-state evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve the original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "dataflow generic shared-state final model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Dataflow_Requires_Generic_Shared_State_Evidence'Access,
         "accepted dataflow requires generic/shared-state evidence");
      Register_Routine
        (T, Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family'Access,
         "missing or blocked prerequisites preserve blocker family");
      Register_Routine
        (T, Local_Dataflow_RM_Errors_Block_Directly'Access,
         "local dataflow RM errors block directly");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and family");
   end Register_Tests;

end Test_Ada_Dataflow_Generic_Shared_State_Final_Legality;
