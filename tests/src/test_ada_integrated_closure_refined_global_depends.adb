with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Integrated_Semantic_Closure.Refined_Global_Depends;
with Editor.Ada_Refined_Global_Depends_Conformance_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Integrated_Closure_Refined_Global_Depends is

   package Closure renames Editor.Ada_Integrated_Semantic_Closure;
   use type Closure.Wide_Diagnostic_Status;
   use type Closure.Overload_Status;
   use type Closure.Static_Status;
   use type Closure.Accessibility_Status;
   use type Closure.Contract_Status;
   use type Closure.Elaboration_Status;
   use type Closure.Completion_Status;
   use type Closure.Renaming_Status;
   use type Closure.Exception_Status;
   use type Closure.Representation_Status;
   use type Closure.Refined_Global_Depends_Status;
   use type Closure.Integrated_Closure_Context_Id;
   use type Closure.Integrated_Closure_Id;
   use type Closure.Integrated_Closure_Context_Kind;
   use type Closure.Closure_Dependency_State;
   use type Closure.Closure_Blocker_Family;
   use type Closure.Integrated_Closure_Status;
   use type Closure.Integrated_Closure_Context_Info;
   use type Closure.Integrated_Closure_Info;
   use type Closure.Integrated_Closure_Context_Model;
   use type Closure.Integrated_Closure_Result_Set;
   use type Closure.Integrated_Closure_Model;
   package Bridge renames Editor.Ada_Integrated_Semantic_Closure.Refined_Global_Depends;
   package DGL renames Editor.Ada_Dataflow_Global_Depends_Legality;
   use type DGL.Contract_Legality_Status;
   use type DGL.Flow_Contract_State;
   use type DGL.Initialization_Legality_Status;
   use type DGL.Object_State;
   use type DGL.Dataflow_Context_Id;
   use type DGL.Dataflow_Legality_Id;
   use type DGL.Dataflow_Context_Kind;
   use type DGL.Dataflow_Effect_Kind;
   use type DGL.Global_Mode;
   use type DGL.Dependency_State;
   use type DGL.Dataflow_Legality_Status;
   use type DGL.Dataflow_Context_Info;
   use type DGL.Dataflow_Legality_Info;
   use type DGL.Dataflow_Context_Model;
   use type DGL.Dataflow_Result_Set;
   use type DGL.Dataflow_Legality_Model;
   package Refined renames Editor.Ada_Refined_Global_Depends_Conformance_Legality;
   use type Refined.Refined_Conformance_Id;
   use type Refined.Refined_Context_Kind;
   use type Refined.Refined_Effect_Kind;
   use type Refined.Refined_Conformance_Status;
   use type Refined.Refined_Context_Info;
   use type Refined.Refined_Conformance_Info;
   use type Refined.Refined_Context_Model;
   use type Refined.Refined_Conformance_Set;
   use type Refined.Refined_Conformance_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Integrated_Closure_Refined_Global_Depends");
   end Name;

   function Sample_Refined_Model return Refined.Refined_Conformance_Model is
      Contexts : Refined.Refined_Context_Model;
      C        : Refined.Refined_Context_Info;
   begin
      C.Id := 1;
      C.Kind := Refined.Refined_Context_Subprogram_Body;
      C.Effect := Refined.Refined_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115401);
      C.Subprogram_Name := To_Unbounded_String ("Load_Config");
      C.Object_Name := To_Unbounded_String ("Config");
      C.Spec_Global_Mode := DGL.Global_Mode_In;
      C.Refined_Global_Mode := DGL.Global_Mode_In;
      C.Reads_Object := True;
      C.Source_Fingerprint := 401;
      Refined.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := Refined.Refined_Context_Subprogram_Body;
      C.Effect := Refined.Refined_Effect_Write;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115402);
      C.Subprogram_Name := To_Unbounded_String ("Update_State");
      C.Object_Name := To_Unbounded_String ("State");
      C.Spec_Global_Mode := DGL.Global_Mode_In;
      C.Refined_Global_Mode := DGL.Global_Mode_In;
      C.Writes_Object := True;
      C.Source_Fingerprint := 402;
      Refined.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := Refined.Refined_Context_Refined_Depends_Edge;
      C.Effect := Refined.Refined_Effect_Depends_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115403);
      C.Source_Name := To_Unbounded_String ("Output");
      C.Target_Name := To_Unbounded_String ("Result");
      C.Source_Global_Mode := DGL.Global_Mode_Out;
      C.Target_Global_Mode := DGL.Global_Mode_Out;
      C.Source_Fingerprint := 403;
      Refined.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := Refined.Refined_Context_Call_Propagation;
      C.Effect := Refined.Refined_Effect_Call_Propagation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115404);
      C.Subprogram_Name := To_Unbounded_String ("Driver");
      C.Effect_Propagated := False;
      C.Source_Fingerprint := 404;
      Refined.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := Refined.Refined_Context_Subprogram_Body;
      C.Effect := Refined.Refined_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115405);
      C.Subprogram_Name := To_Unbounded_String ("Maybe_Load");
      C.Object_Name := To_Unbounded_String ("Pending");
      C.Spec_Global_Mode := DGL.Global_Mode_In;
      C.Refined_Global_Mode := DGL.Global_Mode_In;
      C.Reads_Object := True;
      C.Coverage_Eligible := False;
      C.Source_Fingerprint := 405;
      Refined.Add_Context (Contexts, C);

      return Refined.Build (Contexts);
   end Sample_Refined_Model;

   procedure Refined_Conformance_Failures_Become_Closure_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Empty_Context : Closure.Integrated_Closure_Context_Model;
      Refined_Model : constant Refined.Refined_Conformance_Model := Sample_Refined_Model;
      Model : constant Closure.Integrated_Closure_Model :=
        Bridge.Build_With_Refined_Global_Depends (Empty_Context, Refined_Model);
      Legal_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115401));
      Missing_Global : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115402));
      Bad_Depends : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115403));
      Missing_Call_Propagation : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115404));
      Coverage_Blocker : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115405));
   begin
      Assert (Closure.Closure_Count (Model) = 5,
              "all refined conformance rows should enter integrated closure");
      Assert (Legal_Row.Status = Closure.Integrated_Closure_Legal_Local,
              "legal refined conformance should remain a confident local closure row");
      Assert (Missing_Global.Status = Closure.Integrated_Closure_Refined_Global_Depends_Blocker,
              "missing Global coverage should become a first-class refined Global/Depends blocker");
      Assert (Bad_Depends.Status = Closure.Integrated_Closure_Refined_Global_Depends_Blocker,
              "invalid Refined_Depends source mode should become a closure blocker");
      Assert (Missing_Call_Propagation.Status = Closure.Integrated_Closure_Refined_Global_Depends_Blocker,
              "unpropagated call effects should become a closure blocker");
      Assert (Coverage_Blocker.Status = Closure.Integrated_Closure_Refined_Global_Depends_Blocker,
              "coverage feedback blocking refined conformance should remain visible in closure");
      Assert (Missing_Global.Blocker = Closure.Closure_Blocker_Refined_Global_Depends,
              "blocker family should identify refined Global/Depends conformance");
      Assert (Closure.Count_Blocker (Model, Closure.Closure_Blocker_Refined_Global_Depends) = 4,
              "four refined conformance failures should be counted as closure blockers");
      Assert (Closure.Blocker_Count (Model) = 4,
              "closure blocker count should include refined conformance failures");
      Assert (Closure.Legal_Count (Model) = 1,
              "one refined conformance row should remain legal closure");
      Assert (Closure.Fingerprint (Model) /= 0,
              "integrated refined conformance closure should have a deterministic fingerprint");
   end Refined_Conformance_Failures_Become_Closure_Blockers;

   procedure Existing_Contexts_Are_Preserved_When_Refined_Rows_Are_Added
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Base_Contexts : Closure.Integrated_Closure_Context_Model;
      Base_Context  : Closure.Integrated_Closure_Context_Info;
      Refined_Contexts : Refined.Refined_Context_Model;
      Refined_Context  : Refined.Refined_Context_Info;
   begin
      Base_Context.Id := 1;
      Base_Context.Kind := Closure.Closure_Context_Package_Body;
      Base_Context.Unit_Name := To_Unbounded_String ("Pkg");
      Base_Context.Normalized_Unit_Name := To_Unbounded_String ("pkg");
      Base_Context.Dependency := Closure.Dependency_Local_Only;
      Base_Context.Node := Editor.Ada_Syntax_Tree.Node_Id (115451);
      Closure.Add_Context (Base_Contexts, Base_Context);

      Refined_Context.Id := 1;
      Refined_Context.Kind := Refined.Refined_Context_Subprogram_Body;
      Refined_Context.Effect := Refined.Refined_Effect_Read;
      Refined_Context.Node := Editor.Ada_Syntax_Tree.Node_Id (115452);
      Refined_Context.Subprogram_Name := To_Unbounded_String ("Read_State");
      Refined_Context.Object_Name := To_Unbounded_String ("State");
      Refined_Context.Spec_Global_Mode := DGL.Global_Mode_In;
      Refined_Context.Refined_Global_Mode := DGL.Global_Mode_In;
      Refined_Context.Reads_Object := True;
      Refined.Add_Context (Refined_Contexts, Refined_Context);

      declare
         Refined_Model : constant Refined.Refined_Conformance_Model := Refined.Build (Refined_Contexts);
         Model : constant Closure.Integrated_Closure_Model :=
           Bridge.Build_With_Refined_Global_Depends (Base_Contexts, Refined_Model);
      begin
         Assert (Closure.Closure_Count (Model) = 2,
                 "base closure contexts should be preserved while refined rows are appended");
         Assert (Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115451)).Status =
                   Closure.Integrated_Closure_Legal_Local,
                 "pre-existing local closure should remain legal");
         Assert (Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115452)).Status =
                   Closure.Integrated_Closure_Legal_Local,
                 "legal refined row should be appended as legal local closure");
      end;
   end Existing_Contexts_Are_Preserved_When_Refined_Rows_Are_Added;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Refined_Conformance_Failures_Become_Closure_Blockers'Access,
         "Refined_Global/Depends conformance feeds integrated closure blockers");
      Register_Routine
        (T,
         Existing_Contexts_Are_Preserved_When_Refined_Rows_Are_Added'Access,
         "existing integrated closure contexts are preserved when refined rows are added");
   end Register_Tests;

end Test_Ada_Integrated_Closure_Refined_Global_Depends;
