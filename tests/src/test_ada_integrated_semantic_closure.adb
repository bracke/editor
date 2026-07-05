with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Integrated_Semantic_Closure is

   package ISC renames Editor.Ada_Integrated_Semantic_Closure;
   use type ISC.Wide_Diagnostic_Status;
   use type ISC.Overload_Status;
   use type ISC.Static_Status;
   use type ISC.Accessibility_Status;
   use type ISC.Contract_Status;
   use type ISC.Elaboration_Status;
   use type ISC.Completion_Status;
   use type ISC.Renaming_Status;
   use type ISC.Exception_Status;
   use type ISC.Representation_Status;
   use type ISC.Refined_Global_Depends_Status;
   use type ISC.Integrated_Closure_Context_Id;
   use type ISC.Integrated_Closure_Id;
   use type ISC.Integrated_Closure_Context_Kind;
   use type ISC.Closure_Dependency_State;
   use type ISC.Closure_Blocker_Family;
   use type ISC.Integrated_Closure_Status;
   use type ISC.Integrated_Closure_Context_Info;
   use type ISC.Integrated_Closure_Info;
   use type ISC.Integrated_Closure_Context_Model;
   use type ISC.Integrated_Closure_Result_Set;
   use type ISC.Integrated_Closure_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Integrated_Semantic_Closure");
   end Name;

   procedure Builds_Integrated_Semantic_Closure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : ISC.Integrated_Closure_Context_Model;
      C        : ISC.Integrated_Closure_Context_Info;
   begin
      C.Id := 1;
      C.Kind := ISC.Closure_Context_Package_Spec;
      C.Unit_Name := To_Unbounded_String ("Root");
      C.Normalized_Unit_Name := To_Unbounded_String ("root");
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111801);
      C.Dependency := ISC.Dependency_Local_Only;
      ISC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := ISC.Closure_Context_Package_Body;
      C.Unit_Name := To_Unbounded_String ("Root.Body_Info");
      C.Normalized_Unit_Name := To_Unbounded_String ("root.body");
      C.Dependency_Name := To_Unbounded_String ("Root");
      C.Normalized_Dependency := To_Unbounded_String ("root");
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111802);
      C.Dependency := ISC.Dependency_With_Visible;
      ISC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := ISC.Closure_Context_Expression;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111803);
      C.Dependency := ISC.Dependency_Closed;
      C.Overload_Error := True;
      ISC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := ISC.Closure_Context_Statement;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111804);
      C.Dependency := ISC.Dependency_Closed;
      C.Staticness_Error := True;
      C.Accessibility_Error := True;
      ISC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := ISC.Closure_Context_Generic_Instance;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111805);
      C.Dependency := ISC.Dependency_Missing;
      ISC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := ISC.Closure_Context_Private_Part;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111806);
      C.Dependency := ISC.Dependency_Private_View;
      ISC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := ISC.Closure_Context_Representation_Item;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111807);
      C.Dependency := ISC.Dependency_Closed;
      C.Representation_Error := True;
      ISC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := ISC.Closure_Context_Compilation_Unit;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111808);
      C.Dependency := ISC.Dependency_Rejected;
      ISC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := ISC.Closure_Context_Subprogram_Body;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (111809);
      C.Dependency := ISC.Dependency_Closed;
      C.Contract_Error := True;
      ISC.Add_Context (Contexts, C);

      declare
         Model : constant ISC.Integrated_Closure_Model := ISC.Build (Contexts);
      begin
         Assert (ISC.Closure_Count (Model) = 9, "all closure contexts projected");
         Assert (ISC.Legal_Count (Model) = 2, "local and with-visible closure counted as legal");
         Assert (ISC.Blocker_Count (Model) = 4, "semantic blockers counted");
         Assert (ISC.Dependency_Error_Count (Model) = 1, "missing dependency counted");
         Assert (ISC.View_Barrier_Count (Model) = 1, "private view barrier counted");
         Assert (ISC.Stale_Rejected_Count (Model) = 1, "rejected stale input counted");
         Assert (ISC.Count_Status (Model, ISC.Integrated_Closure_Multiple_Blockers) = 1,
                 "multiple blockers classified");
         Assert (ISC.Count_Blocker (Model, ISC.Closure_Blocker_Representation) = 1,
                 "representation blocker preserved");
         Assert (ISC.Result_Count (ISC.Rows_For_Dependency (Model, ISC.Dependency_With_Visible)) = 1,
                 "dependency lookup works");
         Assert (ISC.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (111803)).Status =
                   ISC.Integrated_Closure_Overload_Blocker,
                 "node lookup preserves overload blocker");
         Assert (ISC.First_For_Unit (Model, To_Unbounded_String ("root")).Status =
                   ISC.Integrated_Closure_Legal_Local,
                 "unit lookup preserves normalized name");
         Assert (ISC.Fingerprint (Model) /= 0, "model has deterministic fingerprint");
      end;
   end Builds_Integrated_Semantic_Closure;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Builds_Integrated_Semantic_Closure'Access,
         "Case 1118 integrated semantic closure legality");
   end Register_Tests;

end Test_Ada_Integrated_Semantic_Closure;
