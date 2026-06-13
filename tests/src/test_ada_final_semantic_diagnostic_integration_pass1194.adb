with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit; use AUnit;
with Editor.Ada_Final_Semantic_Diagnostic_Integration;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Final_Semantic_Diagnostic_Integration_Pass1194 is

   package Final_Diag renames Editor.Ada_Final_Semantic_Diagnostic_Integration;
   use type Final_Diag.Final_Diagnostic_Id;
   use type Final_Diag.Final_Diagnostic_Source_Family;
   use type Final_Diag.Final_Diagnostic_Severity;
   use type Final_Diag.Final_Diagnostic_Status;
   use type Final_Diag.Final_Diagnostic_Context_Info;
   use type Final_Diag.Final_Diagnostic_Info;
   use type Final_Diag.Final_Diagnostic_Context_Model;
   use type Final_Diag.Final_Diagnostic_Model;
   use type Final_Diag.Final_Diagnostic_Set;
   package Access_Final renames Final_Diag.Access_Final;
   package Cross_Final renames Final_Diag.Cross_Final;
   package Discriminant_Final renames Final_Diag.Discriminant_Final;
   package Elaboration_Final renames Final_Diag.Elaboration_Final;
   package Flow_Final renames Final_Diag.Flow_Final;
   package Generic_Final renames Final_Diag.Generic_Final;
   package Overload_Final renames Final_Diag.Overload_Final;
   package Representation_Final renames Final_Diag.Representation_Final;
   package Tasking_Final renames Final_Diag.Tasking_Final;

   function Name (T : Test_Case) return Message_String is
      pragma Unreferenced (T);
   begin
      return Format ("Test_Ada_Final_Semantic_Diagnostic_Integration_Pass1194");
   end Name;

   function Base_Context
     (Id     : Final_Diag.Final_Diagnostic_Id;
      Family : Final_Diag.Final_Diagnostic_Source_Family;
      Node   : Editor.Ada_Syntax_Tree.Node_Id)
      return Final_Diag.Final_Diagnostic_Context_Info is
      C : Final_Diag.Final_Diagnostic_Context_Info;
   begin
      C.Id := Id;
      C.Family := Family;
      C.Node := Node;
      C.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Accepted;
      C.Overload_Status := Overload_Final.Final_RM_Legal_Prefixed_Call_Primitive_Selected;
      C.Generic_Status := Generic_Final.Nested_Generic_Legal_Nested_Instance_Closed;
      C.Representation_Status := Representation_Final.Final_Representation_Legal_Implicit_Freezing_Order_Accepted;
      C.Flow_Status := Flow_Final.Flow_Contract_Proof_Legal_Transitive_Depends_Accepted;
      C.Tasking_Status := Tasking_Final.Deep_Tasking_Legal_Entry_Family_Queue_Accepted;
      C.Elaboration_Status := Elaboration_Final.Final_Elaboration_Legal_Generic_Instance_Accepted;
      C.Accessibility_Status := Access_Final.Master_Scope_Final_Legal_Return_Access_Accepted;
      C.Discriminant_Status := Discriminant_Final.Discriminant_Consumer_Legal_Record_Aggregate_Accepted;
      C.Source_Fingerprint := Natural (Id) * 1194;
      C.Expected_Source_Fingerprint := Natural (Id) * 1194;
      C.Message := To_Unbounded_String ("final semantic diagnostic context");
      return C;
   end Base_Context;

   procedure Legal_Final_Rows_Are_Withheld_Not_Emitted
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : Final_Diag.Final_Diagnostic_Context_Model;
      C : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (1,
           Final_Diag.Final_Diagnostic_Overload_Type,
           Editor.Ada_Syntax_Tree.Node_Id (119401));
      Model : Final_Diag.Final_Diagnostic_Model;
   begin
      Final_Diag.Add_Context (Contexts, C);
      Model := Final_Diag.Build (Contexts);

      Assert (Final_Diag.Row_Count (Model) = 1, "expected one final diagnostic row");
      Assert (Final_Diag.Withheld_Legal_Count (Model) = 1, "legal row should be withheld");
      Assert (Final_Diag.Error_Count (Model) = 0, "legal row must not be an error");
      Assert
        (Final_Diag.Row_At (Model, 1).Status = Final_Diag.Final_Diagnostic_Withheld_Legal,
         "legal final row should be represented as withheld non-diagnostic");
      Assert
        (not Final_Diag.Is_Emitted (Final_Diag.Row_At (Model, 1).Status),
         "withheld legal rows are not emitted diagnostics");
   end Legal_Final_Rows_Are_Withheld_Not_Emitted;

   procedure Blocker_Families_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : Final_Diag.Final_Diagnostic_Context_Model;
      Overload : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (2,
           Final_Diag.Final_Diagnostic_Overload_Type,
           Editor.Ada_Syntax_Tree.Node_Id (119402));
      Representation : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (3,
           Final_Diag.Final_Diagnostic_Representation_Freezing,
           Editor.Ada_Syntax_Tree.Node_Id (119403));
      Access_Ctx : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (4,
           Final_Diag.Final_Diagnostic_Accessibility_Lifetime,
           Editor.Ada_Syntax_Tree.Node_Id (119404));
      Model : Final_Diag.Final_Diagnostic_Model;
   begin
      Overload.Overload_Status := Overload_Final.Final_RM_Prefixed_Call_Primitive_Not_Visible;
      Representation.Representation_Status := Representation_Final.Final_Representation_Generic_Formal_Freezing_Blocker;
      Access_Ctx.Accessibility_Status := Access_Final.Master_Scope_Final_Return_Access_Master_Blocker;

      Final_Diag.Add_Context (Contexts, Overload);
      Final_Diag.Add_Context (Contexts, Representation);
      Final_Diag.Add_Context (Contexts, Access_Ctx);
      Model := Final_Diag.Build (Contexts);

      Assert (Final_Diag.Error_Count (Model) = 3, "all three blocker rows should be errors");
      Assert
        (Final_Diag.Count_Status (Model, Final_Diag.Final_Diagnostic_Overload_Type_Blocker) = 1,
         "overload/type blocker family must be preserved");
      Assert
        (Final_Diag.Count_Status (Model, Final_Diag.Final_Diagnostic_Representation_Freezing_Blocker) = 1,
         "representation/freezing blocker family must be preserved");
      Assert
        (Final_Diag.Count_Status (Model, Final_Diag.Final_Diagnostic_Accessibility_Lifetime_Blocker) = 1,
         "accessibility/lifetime blocker family must be preserved");
   end Blocker_Families_Are_Preserved;

   procedure Stale_And_Multiple_Blockers_Are_Not_Flattened
     (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : Final_Diag.Final_Diagnostic_Context_Model;
      Stale : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (5,
           Final_Diag.Final_Diagnostic_Cross_Unit,
           Editor.Ada_Syntax_Tree.Node_Id (119405));
      Multiple : Final_Diag.Final_Diagnostic_Context_Info :=
        Base_Context
          (6,
           Final_Diag.Final_Diagnostic_Multiple,
           Editor.Ada_Syntax_Tree.Node_Id (119406));
      Model : Final_Diag.Final_Diagnostic_Model;
   begin
      Stale.Input_Current := False;
      Multiple.Cross_Unit_Status := Cross_Final.Cross_Unit_Final_Generic_Backmapping_Blocker;
      Multiple.Flow_Status := Flow_Final.Flow_Contract_Proof_Transitive_Depends_Cycle;
      Multiple.Tasking_Status := Tasking_Final.Deep_Tasking_Terminate_Dependency_Cycle;

      Final_Diag.Add_Context (Contexts, Stale);
      Final_Diag.Add_Context (Contexts, Multiple);
      Model := Final_Diag.Build (Contexts);

      Assert (Final_Diag.Stale_Count (Model) = 1, "stale input must remain visible");
      Assert
        (Final_Diag.Count_Status (Model, Final_Diag.Final_Diagnostic_Multiple_Blockers) = 1,
         "multiple semantic blockers must remain distinct from a generic error");
      Assert
        (Final_Diag.Warning_Count (Model) = 1,
         "stale input should be a warning rather than a hard semantic error");
   end Stale_And_Multiple_Blockers_Are_Not_Flattened;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Legal_Final_Rows_Are_Withheld_Not_Emitted'Access,
         "legal final rows are withheld as non-diagnostics");
      Register_Routine
        (T,
         Blocker_Families_Are_Preserved'Access,
         "final diagnostic integration preserves blocker families");
      Register_Routine
        (T,
         Stale_And_Multiple_Blockers_Are_Not_Flattened'Access,
         "stale and multiple blockers are not flattened");
   end Register_Tests;

end Test_Ada_Final_Semantic_Diagnostic_Integration_Pass1194;
