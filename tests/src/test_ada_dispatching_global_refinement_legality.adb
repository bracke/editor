with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Dispatching_Global_Refinement_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Dispatching_Global_Refinement_Legality is

   package Registration renames AUnit.Test_Cases.Registration;
   package C renames Editor.Ada_Dispatching_Global_Refinement_Legality;
   use type C.Dispatching_Global_Row_Id;
   use type C.Dispatching_Global_Kind;
   use type C.Dispatching_Global_Blocker_Family;
   use type C.Dispatching_Global_Status;
   use type C.Dispatching_Global_Context;
   use type C.Dispatching_Global_Row;
   use type C.Dispatching_Global_Context_Model;
   use type C.Dispatching_Global_Model;
   use type C.Dispatching_Global_Set;
   package Flow renames C.Flow;
   package Abstract_State renames C.Abstract_State;
   package Abstract_Consumers renames C.Abstract_Consumers;
   package Overload_State renames C.Overload_State;
   package Volatile_Rep renames C.Volatile_Rep;
   package Closure renames C.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada dispatching Global/Depends refinement legality");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Dispatching_Global_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Dispatching_Global_Context is
      Result : C.Dispatching_Global_Context;
   begin
      Result.Id := C.Dispatching_Global_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Operation_Name := To_Unbounded_String ("Dispatching_Op" & Natural'Image (Id));
      Result.Type_Name := To_Unbounded_String ("Tagged_Type" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("Abstract_State" & Natural'Image (Id));
      Result.Unit_Name := To_Unbounded_String ("Unit" & Natural'Image (Id));
      Result.Flow_Proof_Row := Flow.Flow_Contract_Proof_Row_Id (Id);
      Result.Flow_Proof_Status := Flow.Flow_Contract_Proof_Legal_Dispatching_Global_Accepted;
      Result.Abstract_State_Row := Abstract_State.Abstract_State_Row_Id (Id);
      Result.Abstract_State_Status := Abstract_State.Abstract_State_Legal_Global_Use_Accepted;
      Result.Abstract_Consumer_Row := Abstract_Consumers.Abstract_State_Consumer_Row_Id (Id);
      Result.Abstract_Consumer_Status := Abstract_Consumers.Abstract_State_Consumer_Legal_Dispatching_Effect_Accepted;
      Result.Overload_Shared_Row := Overload_State.Overload_Shared_State_Row_Id (Id);
      Result.Overload_Shared_Status := Overload_State.Overload_Shared_State_Legal_Dispatching_Call_Accepted;
      Result.Volatile_Representation_Row := Volatile_Rep.Volatile_Atomic_Representation_Row_Id (Id);
      Result.Volatile_Representation_Status := Volatile_Rep.Volatile_Atomic_Representation_Legal_Atomic_Record_Component_Accepted;
      Result.Stabilized_Closure_Row := Closure.Shared_State_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1226 * Id;
      Result.Expected_Source_Fingerprint := 1226 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Dispatching_Effects_Require_Agreed_State_Proof
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Dispatching_Global_Context_Model;
      Class_Wide : C.Dispatching_Global_Context :=
        Complete_Context (1, C.Dispatching_Global_Class_Wide_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (122601));
      Dynamic_Join : C.Dispatching_Global_Context :=
        Complete_Context (2, C.Dispatching_Global_Dynamic_Effect_Join,
                          Editor.Ada_Syntax_Tree.Node_Id (122602));
   begin
      Dynamic_Join.Requires_Volatile_Representation := True;
      C.Add_Context (Contexts, Class_Wide);
      C.Add_Context (Contexts, Dynamic_Join);

      declare
         Model : constant C.Dispatching_Global_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two dispatching refinement rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete state proof should accept dispatching effects");
         Assert (C.Blocked_Count (Model) = 0, "accepted dispatching effects must not block downstream legality");
         Assert
           (C.Count_By_Status (Model, C.Dispatching_Global_Legal_Class_Wide_Call_Accepted) = 1,
            "class-wide dispatching Global proof should be accepted");
         Assert
           (C.Count_By_Status (Model, C.Dispatching_Global_Legal_Dynamic_Effect_Join_Accepted) = 1,
            "dynamic effect join should be accepted");
      end;
   end Accepted_Dispatching_Effects_Require_Agreed_State_Proof;

   procedure Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Dispatching_Global_Context_Model;
      Flow_Blocker : C.Dispatching_Global_Context :=
        Complete_Context (1, C.Dispatching_Global_Controlling_Operation,
                          Editor.Ada_Syntax_Tree.Node_Id (122621));
      Abstract_Blocker : C.Dispatching_Global_Context :=
        Complete_Context (2, C.Dispatching_Global_Abstract_State_Join,
                          Editor.Ada_Syntax_Tree.Node_Id (122622));
      Closure_Blocker : C.Dispatching_Global_Context :=
        Complete_Context (3, C.Dispatching_Global_Interface_Dispatch,
                          Editor.Ada_Syntax_Tree.Node_Id (122623));
   begin
      Flow_Blocker.Flow_Proof_Status := Flow.Flow_Contract_Proof_Dispatching_Global_Not_Refined;
      Abstract_Blocker.Abstract_Consumer_Status := Abstract_Consumers.Abstract_State_Consumer_Dispatching_Effect_Blocker;
      Closure_Blocker.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Blocker_Abstract_State;
      C.Add_Context (Contexts, Flow_Blocker);
      C.Add_Context (Contexts, Abstract_Blocker);
      C.Add_Context (Contexts, Closure_Blocker);

      declare
         Model : constant C.Dispatching_Global_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept dispatching refinement");
         Assert (C.Blocked_Count (Model) = 3, "three dispatching prerequisite blockers should be retained");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Dispatching_Global_Blocker_Flow_Contract) = 1,
            "flow/contract blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Dispatching_Global_Blocker_Abstract_State_Consumer) = 1,
            "abstract-state consumer blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Dispatching_Global_Blocker_Stabilized_Shared_State_Closure) = 1,
            "stabilized shared-state closure blocker family should be preserved");
      end;
   end Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family;

   procedure Dispatching_Local_RM_Errors_Block_Directly
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Dispatching_Global_Context_Model;
      Global_Mode : C.Dispatching_Global_Context :=
        Complete_Context (1, C.Dispatching_Global_Prefixed_Call,
                          Editor.Ada_Syntax_Tree.Node_Id (122641));
      Join_Error : C.Dispatching_Global_Context :=
        Complete_Context (2, C.Dispatching_Global_Dynamic_Effect_Join,
                          Editor.Ada_Syntax_Tree.Node_Id (122642));
      Generic_Error : C.Dispatching_Global_Context :=
        Complete_Context (3, C.Dispatching_Global_Generic_Formal_Dispatch,
                          Editor.Ada_Syntax_Tree.Node_Id (122643));
   begin
      Global_Mode.Global_Mode_Error := True;
      Join_Error.Dynamic_Effect_Join_Error := True;
      Generic_Error.Generic_Formal_Effect_Error := True;
      C.Add_Context (Contexts, Global_Mode);
      C.Add_Context (Contexts, Join_Error);
      C.Add_Context (Contexts, Generic_Error);

      declare
         Model : constant C.Dispatching_Global_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Dispatching_Global_Mode_Mismatch) = 1,
            "dispatching Global mode mismatch should block directly");
         Assert
           (C.Count_By_Status (Model, C.Dispatching_Global_Dynamic_Effect_Join_Blocker) = 1,
            "dynamic dispatch effect join errors should block directly");
         Assert
           (C.Count_By_Status (Model, C.Dispatching_Global_Generic_Formal_Effect_Blocker) = 1,
            "generic formal dispatch effect errors should block directly");
      end;
   end Dispatching_Local_RM_Errors_Block_Directly;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Dispatching_Global_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (122661);
      Item : C.Dispatching_Global_Context :=
        Complete_Context (1, C.Dispatching_Global_Renamed_Primitive, Node);
   begin
      Item.Renamed_Primitive_Effect_Error := True;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Dispatching_Global_Model := C.Build (Contexts);
         Row   : constant C.Dispatching_Global_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find dispatching refinement evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find dispatching refinement evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve the original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "dispatching refinement model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Dispatching_Effects_Require_Agreed_State_Proof'Access,
         "accepted dispatching effects require agreed state proof");
      Register_Routine
        (T, Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family'Access,
         "missing or blocked prerequisites preserve blocker family");
      Register_Routine
        (T, Dispatching_Local_RM_Errors_Block_Directly'Access,
         "dispatching local RM errors block directly");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and blocker family");
   end Register_Tests;

end Test_Ada_Dispatching_Global_Refinement_Legality;
