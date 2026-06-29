with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
with Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
with Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
with Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
with Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
with Editor.Ada_Exception_Finalization_Legality;
with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Overload_Type_Edge_Precision_Legality;
with Editor.Ada_Refined_Global_Depends_Conformance_Legality;
with Editor.Ada_Renaming_Alias_Visibility_Legality;
with Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Final_Effects_Legality;
with Editor.Ada_Unit_Completion_Order_Legality;

package body Test_Ada_Cross_Unit_Final_Semantic_Closure_Legality is

   package Final renames Editor.Ada_Cross_Unit_Final_Semantic_Closure_Legality;
   use type Final.Cross_Unit_Final_Row_Id;
   use type Final.Cross_Unit_Final_Context_Kind;
   use type Final.Cross_Unit_Dependency_State;
   use type Final.Cross_Unit_Final_Status;
   use type Final.Cross_Unit_Final_Context_Info;
   use type Final.Cross_Unit_Final_Info;
   use type Final.Cross_Unit_Final_Context_Model;
   use type Final.Cross_Unit_Final_Set;
   use type Final.Cross_Unit_Final_Model;
   package Access_Final renames Editor.Ada_Accessibility_Master_Scope_Final_Consumer_Legality;
   use type Access_Final.Master_Scope_Final_Row_Id;
   use type Access_Final.Master_Scope_Final_Context_Kind;
   use type Access_Final.Master_Scope_Final_Status;
   use type Access_Final.Master_Scope_Final_Context_Info;
   use type Access_Final.Master_Scope_Final_Info;
   use type Access_Final.Master_Scope_Final_Context_Model;
   use type Access_Final.Master_Scope_Final_Set;
   use type Access_Final.Master_Scope_Final_Model;
   package Contract_CPD renames Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Contract_CPD.Contract_Predicate_Row_Id;
   use type Contract_CPD.Contract_Predicate_Status;
   use type Contract_CPD.Contract_Predicate_Context_Info;
   use type Contract_CPD.Contract_Predicate_Info;
   use type Contract_CPD.Contract_Predicate_Context_Model;
   use type Contract_CPD.Contract_Predicate_Set;
   use type Contract_CPD.Contract_Predicate_Model;
   package Dataflow_Init renames Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
   use type Dataflow_Init.Dataflow_Init_Row_Id;
   use type Dataflow_Init.Dataflow_Init_Status;
   use type Dataflow_Init.Dataflow_Init_Context_Info;
   use type Dataflow_Init.Dataflow_Init_Info;
   use type Dataflow_Init.Dataflow_Init_Context_Model;
   use type Dataflow_Init.Dataflow_Init_Set;
   use type Dataflow_Init.Dataflow_Init_Model;
   package Disc renames Editor.Ada_Discriminant_Variant_Consumer_Integration_Legality;
   use type Disc.Discriminant_Consumer_Row_Id;
   use type Disc.Discriminant_Consumer_Context_Kind;
   use type Disc.Discriminant_Consumer_Status;
   use type Disc.Discriminant_Consumer_Context_Info;
   use type Disc.Discriminant_Consumer_Info;
   use type Disc.Discriminant_Consumer_Context_Model;
   use type Disc.Discriminant_Consumer_Set;
   use type Disc.Discriminant_Consumer_Model;
   package Elab renames Editor.Ada_Elaboration_Graph_Final_Consumer_Legality;
   use type Elab.Final_Elaboration_Row_Id;
   use type Elab.Final_Elaboration_Context_Kind;
   use type Elab.Final_Elaboration_Status;
   use type Elab.Final_Elaboration_Context_Info;
   use type Elab.Final_Elaboration_Info;
   use type Elab.Final_Elaboration_Context_Model;
   use type Elab.Final_Elaboration_Set;
   use type Elab.Final_Elaboration_Model;
   package Exc renames Editor.Ada_Exception_Finalization_Legality;
   use type Exc.Accessibility_Legality_Status;
   use type Exc.Contract_Legality_Status;
   use type Exc.Flow_Legality_Status;
   use type Exc.Elaboration_Legality_Status;
   use type Exc.Renaming_Legality_Status;
   use type Exc.Completion_Legality_Status;
   use type Exc.Exception_Context_Id;
   use type Exc.Exception_Legality_Id;
   use type Exc.Exception_Context_Kind;
   use type Exc.Exception_Target_State;
   use type Exc.Handler_State;
   use type Exc.Finalization_State;
   use type Exc.No_Return_State;
   use type Exc.Exception_Legality_Status;
   use type Exc.Exception_Context_Info;
   use type Exc.Exception_Legality_Info;
   use type Exc.Exception_Context_Model;
   use type Exc.Exception_Result_Set;
   use type Exc.Exception_Legality_Model;
   package Backmap renames Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
   use type Backmap.Generic_Backmap_Row_Id;
   use type Backmap.Generic_Backmap_Context_Kind;
   use type Backmap.Generic_Backmap_Status;
   use type Backmap.Generic_Backmap_Context_Info;
   use type Backmap.Generic_Backmap_Info;
   use type Backmap.Generic_Backmap_Context_Model;
   use type Backmap.Generic_Backmap_Set;
   use type Backmap.Generic_Backmap_Model;
   package Integrated renames Editor.Ada_Integrated_Semantic_Closure;
   use type Integrated.Wide_Diagnostic_Status;
   use type Integrated.Overload_Status;
   use type Integrated.Static_Status;
   use type Integrated.Accessibility_Status;
   use type Integrated.Contract_Status;
   use type Integrated.Elaboration_Status;
   use type Integrated.Completion_Status;
   use type Integrated.Renaming_Status;
   use type Integrated.Exception_Status;
   use type Integrated.Representation_Status;
   use type Integrated.Refined_Global_Depends_Status;
   use type Integrated.Integrated_Closure_Context_Id;
   use type Integrated.Integrated_Closure_Id;
   use type Integrated.Integrated_Closure_Context_Kind;
   use type Integrated.Closure_Dependency_State;
   use type Integrated.Closure_Blocker_Family;
   use type Integrated.Integrated_Closure_Status;
   use type Integrated.Integrated_Closure_Context_Info;
   use type Integrated.Integrated_Closure_Info;
   use type Integrated.Integrated_Closure_Context_Model;
   use type Integrated.Integrated_Closure_Result_Set;
   use type Integrated.Integrated_Closure_Model;
   package Overload renames Editor.Ada_Overload_Type_Edge_Precision_Legality;
   use type Overload.Overload_Type_Edge_Row_Id;
   use type Overload.Overload_Type_Edge_Context_Kind;
   use type Overload.Overload_Type_Edge_Status;
   use type Overload.Overload_Type_Edge_Context_Info;
   use type Overload.Overload_Type_Edge_Info;
   use type Overload.Overload_Type_Edge_Context_Model;
   use type Overload.Overload_Type_Edge_Result_Set;
   use type Overload.Overload_Type_Edge_Model;
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
   package Rename renames Editor.Ada_Renaming_Alias_Visibility_Legality;
   use type Rename.Accessibility_Legality_Status;
   use type Rename.Cross_Unit_Semantic_Status;
   use type Rename.Overload_Legality_Status;
   use type Rename.Completion_Legality_Status;
   use type Rename.Renaming_Context_Id;
   use type Rename.Renaming_Legality_Id;
   use type Rename.Renaming_Context_Kind;
   use type Rename.Renamed_Entity_Kind;
   use type Rename.Visibility_State;
   use type Rename.Alias_State;
   use type Rename.Use_Clause_State;
   use type Rename.Renaming_Legality_Status;
   use type Rename.Renaming_Context_Info;
   use type Rename.Renaming_Legality_Info;
   use type Rename.Renaming_Context_Model;
   use type Rename.Renaming_Result_Set;
   use type Rename.Renaming_Legality_Model;
   package Rep renames Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Rep.Representation_Tasking_CPD_Row_Id;
   use type Rep.Representation_Tasking_CPD_Context_Kind;
   use type Rep.Representation_Tasking_CPD_Status;
   use type Rep.Representation_Tasking_CPD_Context_Info;
   use type Rep.Representation_Tasking_CPD_Info;
   use type Rep.Representation_Tasking_CPD_Context_Model;
   use type Rep.Representation_Tasking_CPD_Set;
   use type Rep.Representation_Tasking_CPD_Model;
   package Tasking renames Editor.Ada_Tasking_Protected_Final_Effects_Legality;
   use type Tasking.Final_Tasking_Row_Id;
   use type Tasking.Final_Tasking_Context_Kind;
   use type Tasking.Final_Tasking_Status;
   use type Tasking.Final_Tasking_Context_Info;
   use type Tasking.Final_Tasking_Info;
   use type Tasking.Final_Tasking_Context_Model;
   use type Tasking.Final_Tasking_Set;
   use type Tasking.Final_Tasking_Model;
   package Completion renames Editor.Ada_Unit_Completion_Order_Legality;
   use type Completion.Cross_Unit_Semantic_Status;
   use type Completion.Contract_Legality_Status;
   use type Completion.Elaboration_Legality_Status;
   use type Completion.Instance_Legality_Status;
   use type Completion.Accessibility_Legality_Status;
   use type Completion.Completion_Context_Id;
   use type Completion.Completion_Legality_Id;
   use type Completion.Unit_Completion_Kind;
   use type Completion.Completion_Subject_Kind;
   use type Completion.Completion_Relation_State;
   use type Completion.Completion_Order_State;
   use type Completion.Completion_Visibility_State;
   use type Completion.Completion_Legality_Status;
   use type Completion.Completion_Context_Info;
   use type Completion.Completion_Legality_Info;
   use type Completion.Completion_Context_Model;
   use type Completion.Completion_Result_Set;
   use type Completion.Completion_Legality_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Cross_Unit_Final_Semantic_Closure_Legality");
   end Name;

   procedure Fill_Common (C : in out Final.Cross_Unit_Final_Context_Info; Id : Natural) is
   begin
      C.Id := Final.Cross_Unit_Final_Row_Id (Id);
      C.Kind := Final.Cross_Unit_Final_With_Use;
      C.Dependency := Final.Dependency_With_Visible;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (118600 + Id);
      C.Unit_Name := To_Unbounded_String ("Pkg" & Natural'Image (Id));
      C.Dependency_Name := To_Unbounded_String ("Dep" & Natural'Image (Id));
      C.Integrated_Status := Integrated.Integrated_Closure_Legal_Cross_Unit;
      C.Overload_Row := Overload.Overload_Type_Edge_Row_Id (Id);
      C.Overload_Status := Overload.Overload_Type_Edge_Legal_Class_Wide_Controlling_Accepted;
      C.Generic_Backmap_Row := Backmap.Generic_Backmap_Row_Id (Id);
      C.Generic_Backmap_Status := Backmap.Generic_Backmap_Legal_Nested_Instance_Backmapped;
      C.Discriminant_Row := Disc.Discriminant_Consumer_Row_Id (Id);
      C.Discriminant_Status := Disc.Discriminant_Consumer_Legal_Private_Full_View_Accepted;
      C.Accessibility_Row := Access_Final.Master_Scope_Final_Row_Id (Id);
      C.Accessibility_Status := Access_Final.Master_Scope_Final_Legal_Cross_Unit_Lifetime_Accepted;
      C.Elaboration_Row := Elab.Final_Elaboration_Row_Id (Id);
      C.Elaboration_Status := Elab.Final_Elaboration_Legal_Generic_Instance_Accepted;
      C.Tasking_Row := Tasking.Final_Tasking_Row_Id (Id);
      C.Tasking_Status := Tasking.Final_Tasking_Legal_Task_Activation_Accepted;
      C.Representation_Row := Rep.Representation_Tasking_CPD_Row_Id (Id);
      C.Representation_Status := Rep.Representation_Tasking_CPD_Legal_Representation_Clause_Accepted;
      C.Contract_Row := Contract_CPD.Contract_Predicate_Row_Id (Id);
      C.Contract_Status := Contract_CPD.Contract_Predicate_Legal_Precondition_Accepted;
      C.Dataflow_Row := Dataflow_Init.Dataflow_Init_Row_Id (Id);
      C.Dataflow_Status := Dataflow_Init.Dataflow_Init_Legal_Call_Propagation_Accepted;
      C.Refined_Row := Refined.Refined_Conformance_Id (Id);
      C.Refined_Status := Refined.Refined_Conformance_Legal_Global_Refinement;
      C.Completion_Row := Completion.Completion_Legality_Id (Id);
      C.Completion_Status := Completion.Completion_Legality_Legal_Unit_Body;
      C.Renaming_Row := Rename.Renaming_Legality_Id (Id);
      C.Renaming_Status := Rename.Renaming_Legality_Legal_Selected_Alias;
      C.Exception_Row := Exc.Exception_Legality_Id (Id);
      C.Exception_Status := Exc.Exception_Legality_Legal_Finalization;
      C.Source_Fingerprint := 1_186_000 + Id;
      C.Closure_Fingerprint := 1_187_000 + Id;
      C.Consumer_Fingerprint := 1_188_000 + Id;
   end Fill_Common;

   function Sample_Context_Model return Final.Cross_Unit_Final_Context_Model is
      Contexts : Final.Cross_Unit_Final_Context_Model;
      C        : Final.Cross_Unit_Final_Context_Info;
   begin
      Fill_Common (C, 1);
      C.Kind := Final.Cross_Unit_Final_With_Use;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 2);
      C.Dependency := Final.Dependency_Missing;
      C.Missing_Dependency := True;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 3);
      C.Private_View_Barrier := True;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 4);
      C.Requires_Completion := True;
      C.Completion_Status := Completion.Completion_Legality_Body_Stub_Not_Completed;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 5);
      C.Requires_Generic_Backmap := True;
      C.Generic_Backmap_Status := Backmap.Generic_Backmap_Missing_Source_Instance_Map;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 6);
      C.Requires_Representation := True;
      C.Representation_Status := Rep.Representation_Tasking_CPD_Base_Freezing_Error;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 7);
      C.Requires_Elaboration := True;
      C.Elaboration_Status := Elab.Final_Elaboration_Base_Elaboration_Error;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 8);
      C.Requires_Overload := True;
      C.Overload_Status := Overload.Overload_Type_Edge_Dispatching_Nondispatching_Ambiguous;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 9);
      C.Requires_Accessibility := True;
      C.Accessibility_Status := Access_Final.Master_Scope_Final_Return_Access_Master_Blocker;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 10);
      C.Requires_Discriminant := True;
      C.Discriminant_Status := Disc.Discriminant_Consumer_Variant_Coverage_Blocker;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 11);
      C.Requires_Contract := True;
      C.Contract_Status := Contract_CPD.Contract_Predicate_Base_Predicate_Propagation_Error;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 12);
      C.Requires_Refined := True;
      C.Refined_Status := Refined.Refined_Conformance_Refined_Depends_Missing_Edge;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 13);
      C.Requires_Tasking := True;
      C.Tasking_Status := Tasking.Final_Tasking_Requeue_With_Abort_Unsafe;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 14);
      C.Requires_Exception := True;
      C.Exception_Status := Exc.Exception_Legality_Finalization_Abort_Unsafe;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 15);
      C.Requires_Renaming := True;
      C.Renaming_Status := Rename.Renaming_Legality_Hidden_By_Homograph;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 16);
      C.Integrated_Status := Integrated.Integrated_Closure_AST_Coverage_Blocker;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 17);
      C.Blocker_Count := 2;
      Final.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 18);
      C.Elaboration_Status := Elab.Final_Elaboration_Indeterminate;
      Final.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Final.Cross_Unit_Final_Model := Final.Build (Sample_Context_Model);
   begin
      Assert (Final.Row_Count (Model) = 18, "expected eighteen final cross-unit closure rows");
      Assert (Final.Legal_Count (Model) = 1, "only one fully closed row should remain legal");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Missing_Dependency) = 1, "missing dependency must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Private_View_Barrier) = 1, "private view barrier must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Body_Spec_Completion_Blocker) = 1, "body/spec blocker must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Generic_Backmapping_Blocker) = 1, "generic backmapping blocker must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Representation_Freezing_Blocker) = 1, "representation/freezing blocker must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Elaboration_Dependence_Blocker) = 1, "elaboration blocker must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Dispatching_Inherited_Primitive_Blocker) = 1, "dispatching/inherited primitive ambiguity must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Accessibility_Lifetime_Blocker) = 1, "accessibility blocker must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Discriminant_Variant_Blocker) = 1, "discriminant/variant blocker must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Predicate_Invariant_Blocker) = 1, "predicate/invariant blocker must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Refined_Global_Depends_Blocker) = 1, "refined Global/Depends blocker must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Tasking_Protected_Final_Effect_Blocker) = 1, "tasking final effect blocker must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Exception_Finalization_Blocker) = 1, "exception/finalization blocker must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Renaming_Alias_Visibility_Blocker) = 1, "renaming/visibility blocker must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_AST_Repair_Blocker) = 1, "AST repair blocker must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Multiple_Blockers) = 1, "multiple blocker state must be preserved");
      Assert (Final.Count_Status (Model, Final.Cross_Unit_Final_Indeterminate) = 1, "indeterminate closure must be preserved");
      Assert (Final.Dependency_Error_Count (Model) = 1, "expected one dependency error");
      Assert (Final.View_Barrier_Count (Model) = 1, "expected one view barrier");
      Assert (Final.Generic_Error_Count (Model) = 1, "expected one generic error");
      Assert (Final.Representation_Error_Count (Model) = 1, "expected one representation error");
      Assert (Final.Elaboration_Error_Count (Model) = 1, "expected one elaboration error");
      Assert (Final.Tasking_Error_Count (Model) = 1, "expected one tasking error");
      Assert (Final.Type_Access_Discriminant_Error_Count (Model) = 3, "expected overload/access/discriminant errors");
      Assert (Final.Contract_Dataflow_Error_Count (Model) = 2, "expected contract/refined errors");
      Assert (Final.Completion_Visibility_Exception_Error_Count (Model) = 3, "expected completion/exception/renaming errors");
      Assert (Final.Coverage_Error_Count (Model) = 2, "expected AST/multiple coverage-family errors");
      Assert (Final.Indeterminate_Count (Model) = 1, "expected one indeterminate row");
      Assert (Final.Fingerprint (Model) /= 0, "model fingerprint must be stable and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Final.Cross_Unit_Final_Model := Final.Build (Sample_Context_Model);
      Row   : constant Final.Cross_Unit_Final_Info :=
        Final.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118608));
      By_Unit : constant Final.Cross_Unit_Final_Set := Final.Rows_For_Unit (Model, "pkg 8");
      By_Kind : constant Final.Cross_Unit_Final_Set :=
        Final.Rows_For_Kind (Model, Final.Cross_Unit_Final_With_Use);
   begin
      Assert (Row.Status = Final.Cross_Unit_Final_Dispatching_Inherited_Primitive_Blocker,
              "node lookup must preserve overload/type-edge blocker");
      Assert (Final.Set_Count (By_Unit) = 1, "unit lookup must be deterministic and case-insensitive");
      Assert (Final.Set_Count (By_Kind) = 18, "all sample rows use with/use final closure kind");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "final cross-unit semantic closure blockers");
      Register_Routine (T, Test_Queries'Access, "final cross-unit semantic closure lookups");
   end Register_Tests;

end Test_Ada_Cross_Unit_Final_Semantic_Closure_Legality;
