with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Representation_Generic_Shared_State_Final_Legality_Pass1229 is

   package Registration renames AUnit.Test_Cases.Registration;
   package C renames Editor.Ada_Representation_Generic_Shared_State_Final_Legality;
   use type C.Representation_Generic_Final_Row_Id;
   use type C.Representation_Generic_Final_Kind;
   use type C.Representation_Generic_Final_Blocker_Family;
   use type C.Representation_Generic_Final_Status;
   use type C.Representation_Generic_Final_Context;
   use type C.Representation_Generic_Final_Row;
   use type C.Representation_Generic_Final_Context_Model;
   use type C.Representation_Generic_Final_Model;
   use type C.Representation_Generic_Final_Set;
   package Rep_Final renames C.Rep_Final;
   package Rep_Shared renames C.Rep_Shared;
   package Generic_Replay renames C.Generic_Replay;
   package Overload_Generic renames C.Overload_Generic;
   package Volatile_Rep renames C.Volatile_Rep;
   package Closure renames C.Closure;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Ada representation generic shared-state final legality pass1229");
   end Name;

   function Complete_Context
     (Id   : Natural;
      Kind : C.Representation_Generic_Final_Kind;
      Node : Editor.Ada_Syntax_Tree.Node_Id) return C.Representation_Generic_Final_Context is
      Result : C.Representation_Generic_Final_Context;
   begin
      Result.Id := C.Representation_Generic_Final_Row_Id (Id);
      Result.Kind := Kind;
      Result.Node := Node;
      Result.Representation_Name := To_Unbounded_String ("Rep" & Natural'Image (Id));
      Result.Type_Name := To_Unbounded_String ("T" & Natural'Image (Id));
      Result.State_Name := To_Unbounded_String ("State" & Natural'Image (Id));
      Result.Generic_Unit_Name := To_Unbounded_String ("Generic" & Natural'Image (Id));
      Result.Instance_Name := To_Unbounded_String ("Instance" & Natural'Image (Id));
      Result.Final_Representation_Row := Rep_Final.Final_Representation_Row_Id (Id);
      Result.Final_Representation_Status := Rep_Final.Final_Representation_Legal_Generic_Instance_Representation_Accepted;
      Result.Representation_Shared_Row := Rep_Shared.Representation_Shared_State_Row_Id (Id);
      Result.Representation_Shared_Status := Rep_Shared.Representation_Shared_State_Legal_Shared_Record_Layout_Accepted;
      Result.Generic_Replay_Row := Generic_Replay.Generic_Abstract_Replay_Row_Id (Id);
      Result.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Legal_Nested_Instance_State_Accepted;
      Result.Overload_Generic_Row := Overload_Generic.Overload_Generic_Final_Row_Id (Id);
      Result.Overload_Generic_Status := Overload_Generic.Overload_Generic_Final_Legal_Generic_Formal_Subprogram_Accepted;
      Result.Volatile_Representation_Row := Volatile_Rep.Volatile_Atomic_Representation_Row_Id (Id);
      Result.Volatile_Representation_Status := Volatile_Rep.Volatile_Atomic_Representation_Legal_Atomic_Record_Component_Accepted;
      Result.Stabilized_Closure_Row := Closure.Shared_State_Stabilized_Closure_Id (Id);
      Result.Stabilized_Closure_Status := Closure.Shared_State_Stabilized_Closure_Accepted_Current;
      Result.Source_Fingerprint := 1229 * Id;
      Result.Expected_Source_Fingerprint := 1229 * Id;
      Result.Substitution_Fingerprint := 9221 * Id;
      Result.Expected_Substitution_Fingerprint := 9221 * Id;
      return Result;
   end Complete_Context;

   procedure Accepted_Representation_Requires_Generic_And_Shared_State_Evidence
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Representation_Generic_Final_Context_Model;
      Generic_Instance : C.Representation_Generic_Final_Context :=
        Complete_Context (1, C.Representation_Generic_Final_Generic_Instance_Representation,
                          Editor.Ada_Syntax_Tree.Node_Id (122901));
      Atomic_Layout : C.Representation_Generic_Final_Context :=
        Complete_Context (2, C.Representation_Generic_Final_Volatile_Atomic_Record_Layout,
                          Editor.Ada_Syntax_Tree.Node_Id (122902));
   begin
      Generic_Instance.Requires_Generic_Replay := True;
      Generic_Instance.Requires_Overload_Generic := True;
      Atomic_Layout.Requires_Volatile_Representation := True;
      C.Add_Context (Contexts, Generic_Instance);
      C.Add_Context (Contexts, Atomic_Layout);

      declare
         Model : constant C.Representation_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Count (Model) = 2, "two representation/generic final rows expected");
         Assert (C.Accepted_Count (Model) = 2, "complete representation/generic evidence should be accepted");
         Assert (C.Blocked_Count (Model) = 0, "accepted representation rows must not block");
         Assert
           (C.Count_By_Status
              (Model, C.Representation_Generic_Final_Legal_Generic_Instance_Representation_Accepted) = 1,
            "generic instance representation should accept after replay and overload evidence");
         Assert
           (C.Count_By_Status
              (Model, C.Representation_Generic_Final_Legal_Volatile_Atomic_Record_Layout_Accepted) = 1,
            "volatile/atomic record layout should accept after representation evidence");
      end;
   end Accepted_Representation_Requires_Generic_And_Shared_State_Evidence;

   procedure Missing_Or_Blocked_Prerequisites_Preserve_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Representation_Generic_Final_Context_Model;
      Final_Blocker : C.Representation_Generic_Final_Context :=
        Complete_Context (1, C.Representation_Generic_Final_Private_Full_View_Freezing,
                          Editor.Ada_Syntax_Tree.Node_Id (122921));
      Shared_Blocker : C.Representation_Generic_Final_Context :=
        Complete_Context (2, C.Representation_Generic_Final_Stream_Attribute,
                          Editor.Ada_Syntax_Tree.Node_Id (122922));
      Generic_Blocker : C.Representation_Generic_Final_Context :=
        Complete_Context (3, C.Representation_Generic_Final_Generic_Formal_Freezing,
                          Editor.Ada_Syntax_Tree.Node_Id (122923));
   begin
      Final_Blocker.Final_Representation_Status := Rep_Final.Final_Representation_Private_Full_View_Freezing_Blocker;
      Shared_Blocker.Representation_Shared_Status := Rep_Shared.Representation_Shared_State_Stream_Attribute_Blocker;
      Generic_Blocker.Requires_Generic_Replay := True;
      Generic_Blocker.Generic_Replay_Status := Generic_Replay.Generic_Abstract_Replay_Backmap_Blocker;
      C.Add_Context (Contexts, Final_Blocker);
      C.Add_Context (Contexts, Shared_Blocker);
      C.Add_Context (Contexts, Generic_Blocker);

      declare
         Model : constant C.Representation_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert (C.Accepted_Count (Model) = 0, "blocked prerequisites must not accept");
         Assert (C.Blocked_Count (Model) = 3, "three blocker rows should be retained");
         Assert
           (C.Count_By_Blocker_Family
              (Model, C.Representation_Generic_Final_Blocker_Final_Representation) = 1,
            "final representation blocker should be preserved");
         Assert
           (C.Count_By_Blocker_Family
              (Model, C.Representation_Generic_Final_Blocker_Representation_Shared_State) = 1,
            "representation shared-state blocker should be preserved");
         Assert
           (C.Count_By_Blocker_Family
              (Model, C.Representation_Generic_Final_Blocker_Generic_Abstract_Replay) = 1,
            "generic replay blocker should be preserved");
      end;
   end Missing_Or_Blocked_Prerequisites_Preserve_Family;

   procedure RM_Edge_And_Fingerprint_Errors_Block_Directly
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Representation_Generic_Final_Context_Model;
      Stream_Blocker : C.Representation_Generic_Final_Context :=
        Complete_Context (1, C.Representation_Generic_Final_Stream_Attribute,
                          Editor.Ada_Syntax_Tree.Node_Id (122941));
      Variant_Blocker : C.Representation_Generic_Final_Context :=
        Complete_Context (2, C.Representation_Generic_Final_Variant_Record_Layout,
                          Editor.Ada_Syntax_Tree.Node_Id (122942));
      Source_Mismatch : C.Representation_Generic_Final_Context :=
        Complete_Context (3, C.Representation_Generic_Final_Task_Object_Representation,
                          Editor.Ada_Syntax_Tree.Node_Id (122943));
   begin
      Stream_Blocker.Stream_Attribute_Effect_Blocker := True;
      Variant_Blocker.Variant_Layout_Blocker := True;
      Source_Mismatch.Source_Fingerprint := 1;
      Source_Mismatch.Expected_Source_Fingerprint := 2;
      C.Add_Context (Contexts, Stream_Blocker);
      C.Add_Context (Contexts, Variant_Blocker);
      C.Add_Context (Contexts, Source_Mismatch);

      declare
         Model : constant C.Representation_Generic_Final_Model := C.Build (Contexts);
      begin
         Assert
           (C.Count_By_Status (Model, C.Representation_Generic_Final_Stream_Attribute_Effect_Blocker) = 1,
            "stream attribute effects should block directly");
         Assert
           (C.Count_By_Status (Model, C.Representation_Generic_Final_Variant_Layout_Blocker) = 1,
            "variant layout blockers should be preserved directly");
         Assert
           (C.Count_By_Status (Model, C.Representation_Generic_Final_Source_Fingerprint_Mismatch) = 1,
            "source fingerprint mismatch should block directly");
      end;
   end RM_Edge_And_Fingerprint_Errors_Block_Directly;

   procedure Query_Surface_Preserves_Node_Fingerprint_And_Family
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : C.Representation_Generic_Final_Context_Model;
      Node : constant Editor.Ada_Syntax_Tree.Node_Id := Editor.Ada_Syntax_Tree.Node_Id (122961);
      Item : C.Representation_Generic_Final_Context :=
        Complete_Context (1, C.Representation_Generic_Final_Protected_Object_Representation, Node);
   begin
      Item.Task_Protected_Representation_Blocker := True;
      C.Add_Context (Contexts, Item);

      declare
         Model : constant C.Representation_Generic_Final_Model := C.Build (Contexts);
         Row   : constant C.Representation_Generic_Final_Row := C.Row_At (Model, 1);
      begin
         Assert (C.Query_Count (C.Find_By_Node (Model, Node)) = 1,
                 "node lookup should find representation/generic final evidence");
         Assert (C.Query_Count (C.Find_By_Source_Fingerprint (Model, Row.Source_Fingerprint)) = 1,
                 "source-fingerprint lookup should find representation/generic final evidence");
         Assert (C.Query_Count (C.Query_Blocker_Family (Model, Row.Blocker_Family)) = 1,
                 "blocker-family query should preserve original blocker");
         Assert (C.Stable_Fingerprint (Model) /= 0,
                 "representation/generic final model should have deterministic fingerprint");
      end;
   end Query_Surface_Preserves_Node_Fingerprint_And_Family;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepted_Representation_Requires_Generic_And_Shared_State_Evidence'Access,
         "accepted representation requires generic and shared-state evidence");
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

end Test_Ada_Representation_Generic_Shared_State_Final_Legality_Pass1229;
