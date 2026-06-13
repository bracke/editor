with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality;

package body Test_Ada_Volatile_Atomic_Representation_Consumer_Legality_Pass1225 is

   package Registration renames AUnit.Test_Cases.Registration;
   package C renames Editor.Ada_Volatile_Atomic_Representation_Consumer_Legality;
   use type C.Volatile_Atomic_Representation_Row_Id;
   use type C.Volatile_Atomic_Representation_Kind;
   use type C.Volatile_Atomic_Representation_Blocker_Family;
   use type C.Volatile_Atomic_Representation_Status;
   use type C.Volatile_Atomic_Representation_Context;
   use type C.Volatile_Atomic_Representation_Row;
   use type C.Volatile_Atomic_Representation_Context_Model;
   use type C.Volatile_Atomic_Representation_Model;
   use type C.Volatile_Atomic_Representation_Set;
   package Shared renames C.Shared;
   package Rep renames C.Rep;
   package Abstract_Consumers renames C.Abstract_Consumers;
   package Closure renames C.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada volatile/atomic representation consumer legality pass1225");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Volatile_Atomic_Representation_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Volatile_Atomic_Representation_Context is
      Result : C.Volatile_Atomic_Representation_Context;
   begin
      Result.Id := C.Volatile_Atomic_Representation_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Object_Name := To_Unbounded_String ("Object" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Unit_Name := To_Unbounded_String ("Unit" & Natural'Image (Id));
      Result.Shared_State_Row := Shared.Shared_State_Row_Id (Id);
      Result.Shared_State_Status := Shared.Shared_State_Legal_Atomic_Read_Write_Accepted;
      Result.Representation_Row := Rep.Representation_Shared_State_Row_Id (Id);
      Result.Representation_Status := Rep.Representation_Shared_State_Legal_Atomic_Object_Clause_Accepted;
      Result.Abstract_Consumer_Row := Abstract_Consumers.Abstract_State_Consumer_Row_Id (Id);
      Result.Abstract_Consumer_Status := Abstract_Consumers.Abstract_State_Consumer_Legal_Representation_Freezing_Accepted;
      Result.Stabilized_Closure_Row := Closure.Shared_State_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1225 * Id;
      Result.Expected_Source_Fingerprint := 1225 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Representation_Consumers_Require_Agreed_Shared_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Volatile_Atomic_Representation_Context_Model;
      Atomic : C.Volatile_Atomic_Representation_Context :=
        Complete_Context (1, C.Volatile_Atomic_Representation_Atomic_Record_Component,
                          Editor.Ada_Syntax_Tree.Node_Id (122501));
      Stream : C.Volatile_Atomic_Representation_Context :=
        Complete_Context (2, C.Volatile_Atomic_Representation_Stream_Attribute,
                          Editor.Ada_Syntax_Tree.Node_Id (122502));
   begin
      Stream.Requires_Abstract_Consumer := True;
      Stream.Requires_Stabilized_Closure := True;
      C.Add_Context (Contexts, Atomic);
      C.Add_Context (Contexts, Stream);

      declare
         Model : constant C.Volatile_Atomic_Representation_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two volatile/atomic representation consumer rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete shared-state and representation evidence should accept consumers");
         Assert (C.Blocked_Count (Model) = 0, "accepted consumers must not block downstream representation legality");
         Assert
           (C.Count_By_Status (Model, C.Volatile_Atomic_Representation_Legal_Atomic_Record_Component_Accepted) = 1,
            "atomic record component representation should be accepted");
         Assert
           (C.Count_By_Status (Model, C.Volatile_Atomic_Representation_Legal_Stream_Attribute_Accepted) = 1,
            "stream attribute representation should be accepted");
      end;
   end Accepted_Representation_Consumers_Require_Agreed_Shared_State_Evidence;

   procedure Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Volatile_Atomic_Representation_Context_Model;
      Shared_Blocker : C.Volatile_Atomic_Representation_Context :=
        Complete_Context (1, C.Volatile_Atomic_Representation_Volatile_Full_Access_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (122521));
      Rep_Blocker : C.Volatile_Atomic_Representation_Context :=
        Complete_Context (2, C.Volatile_Atomic_Representation_Record_Layout,
                          Editor.Ada_Syntax_Tree.Node_Id (122522));
      Closure_Blocker : C.Volatile_Atomic_Representation_Context :=
        Complete_Context (3, C.Volatile_Atomic_Representation_Representation_Clause,
                          Editor.Ada_Syntax_Tree.Node_Id (122523));
   begin
      Shared_Blocker.Shared_State_Status := Shared.Shared_State_Atomic_Alignment_Blocker;
      Rep_Blocker.Representation_Status := Rep.Representation_Shared_State_Shared_Record_Layout_Blocker;
      Closure_Blocker.Requires_Stabilized_Closure := True;
      Closure_Blocker.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Blocker_Volatile_Atomic;
      C.Add_Context (Contexts, Shared_Blocker);
      C.Add_Context (Contexts, Rep_Blocker);
      C.Add_Context (Contexts, Closure_Blocker);

      declare
         Model : constant C.Volatile_Atomic_Representation_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept representation consumers");
         Assert (C.Blocked_Count (Model) = 3, "three prerequisite blockers should be retained");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Volatile_Atomic_Representation_Blocker_Volatile_Atomic_Shared_State) = 1,
            "volatile/atomic blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Volatile_Atomic_Representation_Blocker_Representation_Freezing) = 1,
            "representation/freezing blocker family should be preserved");
         Assert
           (C.Count_By_Blocker_Family (Model, C.Volatile_Atomic_Representation_Blocker_Stabilized_Closure) = 1,
            "stabilized closure blocker family should be preserved");
      end;
   end Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family;

   procedure Local_Volatile_Atomic_Representation_Errors_Block_Directly
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Volatile_Atomic_Representation_Context_Model;
      Full_Access : C.Volatile_Atomic_Representation_Context :=
        Complete_Context (1, C.Volatile_Atomic_Representation_Volatile_Full_Access_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (122541));
      Independent : C.Volatile_Atomic_Representation_Context :=
        Complete_Context (2, C.Volatile_Atomic_Representation_Independent_Component_Clause,
                          Editor.Ada_Syntax_Tree.Node_Id (122542));
      Protected_Obj : C.Volatile_Atomic_Representation_Context :=
        Complete_Context (3, C.Volatile_Atomic_Representation_Protected_Shared_Object,
                          Editor.Ada_Syntax_Tree.Node_Id (122543));
   begin
      Full_Access.Volatile_Full_Access_Error := True;
      Independent.Independent_Component_Overlap := True;
      Protected_Obj.Protected_Shared_Object_Error := True;
      C.Add_Context (Contexts, Full_Access);
      C.Add_Context (Contexts, Independent);
      C.Add_Context (Contexts, Protected_Obj);

      declare
         Model : constant C.Volatile_Atomic_Representation_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Volatile_Atomic_Representation_Volatile_Full_Access_Blocker) = 1,
            "volatile full-access errors should block directly");
         Assert
           (C.Count_By_Status (Model, C.Volatile_Atomic_Representation_Independent_Component_Overlap) = 1,
            "independent component overlap should block directly");
         Assert
           (C.Count_By_Status (Model, C.Volatile_Atomic_Representation_Protected_Shared_Object_Blocker) = 1,
            "protected shared-object representation errors should block directly");
      end;
   end Local_Volatile_Atomic_Representation_Errors_Block_Directly;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Volatile_Atomic_Representation_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (122561);
      Item : C.Volatile_Atomic_Representation_Context :=
        Complete_Context (1, C.Volatile_Atomic_Representation_Operational_Attribute, Node);
   begin
      Item.Operational_Attribute_Error := True;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Volatile_Atomic_Representation_Model := C.Build (Contexts);
         Row   : constant C.Volatile_Atomic_Representation_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find volatile/atomic representation consumer evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find representation consumer evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve the original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "consumer model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Representation_Consumers_Require_Agreed_Shared_State_Evidence'Access,
         "accepted representation consumers require agreed shared-state evidence");
      Register_Routine
        (T, Missing_Or_Blocked_Prerequisites_Preserve_Blocker_Family'Access,
         "missing or blocked prerequisites preserve blocker family");
      Register_Routine
        (T, Local_Volatile_Atomic_Representation_Errors_Block_Directly'Access,
         "local volatile/atomic representation errors block directly");
      Register_Routine
        (T, Query_Surface_Preserves_Node_Fingerprint_And_Family'Access,
         "query surface preserves node fingerprint and blocker family");
   end Register_Tests;

end Test_Ada_Volatile_Atomic_Representation_Consumer_Legality_Pass1225;
