with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Integrated_Semantic_Closure.Generic_Backmapping;
with Editor.Ada_Overload_Type_Edge_Precision_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Integrated_Closure_Generic_Backmapping is

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
   package Bridge renames Editor.Ada_Integrated_Semantic_Closure.Generic_Backmapping;
   package Backmap renames Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
   use type Backmap.Generic_Backmap_Row_Id;
   use type Backmap.Generic_Backmap_Context_Kind;
   use type Backmap.Generic_Backmap_Status;
   use type Backmap.Generic_Backmap_Context_Info;
   use type Backmap.Generic_Backmap_Info;
   use type Backmap.Generic_Backmap_Context_Model;
   use type Backmap.Generic_Backmap_Set;
   use type Backmap.Generic_Backmap_Model;
   package Replay renames Editor.Ada_Generic_Instance_Body_Semantic_Replay;
   use type Replay.Replay_Context_Id;
   use type Replay.Replay_Row_Id;
   use type Replay.Replay_Context_Kind;
   use type Replay.Replay_Status;
   use type Replay.Replay_Context_Info;
   use type Replay.Replay_Info;
   use type Replay.Replay_Context_Model;
   use type Replay.Replay_Result_Set;
   use type Replay.Replay_Model;
   package Replay_CPD renames Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Replay_CPD.Generic_Replay_Representation_Row_Id;
   use type Replay_CPD.Generic_Replay_Representation_Context_Kind;
   use type Replay_CPD.Generic_Replay_Representation_Status;
   use type Replay_CPD.Generic_Replay_Representation_Context_Info;
   use type Replay_CPD.Generic_Replay_Representation_Info;
   use type Replay_CPD.Generic_Replay_Representation_Context_Model;
   use type Replay_CPD.Generic_Replay_Representation_Set;
   use type Replay_CPD.Generic_Replay_Representation_Model;
   package Overload_Edge renames Editor.Ada_Overload_Type_Edge_Precision_Legality;
   use type Overload_Edge.Overload_Type_Edge_Row_Id;
   use type Overload_Edge.Overload_Type_Edge_Context_Kind;
   use type Overload_Edge.Overload_Type_Edge_Status;
   use type Overload_Edge.Overload_Type_Edge_Context_Info;
   use type Overload_Edge.Overload_Type_Edge_Info;
   use type Overload_Edge.Overload_Type_Edge_Context_Model;
   use type Overload_Edge.Overload_Type_Edge_Result_Set;
   use type Overload_Edge.Overload_Type_Edge_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Integrated_Closure_Generic_Backmapping");
   end Name;

   procedure Fill_Common (C : in out Backmap.Generic_Backmap_Context_Info; Id : Natural) is
   begin
      C.Id := Backmap.Generic_Backmap_Row_Id (Id);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (118100 + Id);
      C.Generic_Source_Node := Editor.Ada_Syntax_Tree.Node_Id (118200 + Id);
      C.Instance_Node := Editor.Ada_Syntax_Tree.Node_Id (118300 + Id);
      C.Formal_Node := Editor.Ada_Syntax_Tree.Node_Id (118400 + Id);
      C.Actual_Node := Editor.Ada_Syntax_Tree.Node_Id (118500 + Id);
      C.Body_Node := Editor.Ada_Syntax_Tree.Node_Id (118600 + Id);
      C.Substituted_Node := Editor.Ada_Syntax_Tree.Node_Id (118700 + Id);
      C.Generic_Unit_Name := To_Unbounded_String ("G");
      C.Instance_Name := To_Unbounded_String ("I");
      C.Formal_Name := To_Unbounded_String ("Formal");
      C.Actual_Name := To_Unbounded_String ("Actual");
      C.Replay_Row := Replay.Replay_Row_Id (Id);
      C.Replay_Status := Replay.Replay_Legal_Substituted_Expression;
      C.Replay_CPD_Row := Replay_CPD.Generic_Replay_Representation_Row_Id (Id);
      C.Replay_CPD_Status := Replay_CPD.Generic_Replay_Representation_Legal_Body_Expression_Accepted;
      C.Replay_CPD_Matches := 1;
      C.Overload_Row := Overload_Edge.Overload_Type_Edge_Row_Id (Id);
      C.Overload_Status := Overload_Edge.Overload_Type_Edge_Legal_Nested_Generic_Selected;
      C.Overload_Matches := 1;
      C.Source_Fingerprint := 9000 + Id;
      C.Expected_Source_Fingerprint := 9000 + Id;
      C.Substitution_Fingerprint := 10000 + Id;
      C.Expected_Substitution_Fingerprint := 10000 + Id;
   end Fill_Common;

   function Sample_Backmap_Model return Backmap.Generic_Backmap_Model is
      Contexts : Backmap.Generic_Backmap_Context_Model;
      C        : Backmap.Generic_Backmap_Context_Info;
   begin
      Fill_Common (C, 1);
      C.Kind := Backmap.Generic_Backmap_Call_Replay;
      Backmap.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 2);
      C.Kind := Backmap.Generic_Backmap_Declaration_Replay;
      C.Generic_Source_Node := Editor.Ada_Syntax_Tree.No_Node;
      Backmap.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 3);
      C.Kind := Backmap.Generic_Backmap_Flow_Replay;
      C.Replay_Status := Replay.Replay_Flow_Effect_Error;
      Backmap.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 4);
      C.Kind := Backmap.Generic_Backmap_Predicate_Replay;
      C.Replay_CPD_Status := Replay_CPD.Generic_Replay_Representation_Coverage_Feedback_Blocker;
      Backmap.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 5);
      C.Kind := Backmap.Generic_Backmap_Accessibility_Replay;
      C.Replay_CPD_Row := Replay_CPD.No_Generic_Replay_Representation_Row;
      C.Replay_CPD_Status := Replay_CPD.Generic_Replay_Representation_Not_Checked;
      C.Replay_CPD_Matches := 0;
      Backmap.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 6);
      C.Kind := Backmap.Generic_Backmap_Representation_Replay;
      C.Replay_CPD_Status := Replay_CPD.Generic_Replay_Representation_Replay_Representation_Error;
      Backmap.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 7);
      C.Kind := Backmap.Generic_Backmap_Nested_Instance_Replay;
      C.Overload_Status := Overload_Edge.Overload_Type_Edge_Nested_Defaulted_Formal_Ambiguous;
      Backmap.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 8);
      C.Kind := Backmap.Generic_Backmap_Statement_Replay;
      C.Replay_CPD_Status := Replay_CPD.Generic_Replay_Representation_Indeterminate;
      Backmap.Add_Context (Contexts, C);

      return Backmap.Build (Contexts);
   end Sample_Backmap_Model;

   procedure Generic_Backmap_Rows_Become_Direct_Closure_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Empty_Context : Closure.Integrated_Closure_Context_Model;
      Model : constant Closure.Integrated_Closure_Model :=
        Bridge.Build_With_Generic_Backmapping (Empty_Context, Sample_Backmap_Model);
      Legal_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118101));
      Mapping_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118102));
      Flow_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118103));
      Predicate_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118104));
      Accessibility_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118105));
      Representation_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118106));
      Overload_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118107));
      Indeterminate_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118108));
   begin
      Assert (Closure.Closure_Count (Model) = 8,
              "all generic source/instance backmap rows should enter integrated closure");
      Assert (Legal_Row.Status = Closure.Integrated_Closure_Legal_Local,
              "fully backmapped generic replay row should remain legal local closure");
      Assert (Mapping_Row.Status = Closure.Integrated_Closure_Coverage_Gate_Blocker,
              "missing generic source/instance mapping should surface as a coverage-gate blocker");
      Assert (Flow_Row.Status = Closure.Integrated_Closure_Dataflow_Blocker,
              "generic replay flow blocker should remain a dataflow closure blocker");
      Assert (Predicate_Row.Status = Closure.Integrated_Closure_Contract_Blocker,
              "generic replay predicate blocker should remain a contract closure blocker");
      Assert (Accessibility_Row.Status = Closure.Integrated_Closure_Accessibility_Blocker,
              "generic replay accessibility blocker should remain an accessibility closure blocker");
      Assert (Representation_Row.Status = Closure.Integrated_Closure_Representation_Blocker,
              "generic replay representation blocker should remain a representation closure blocker");
      Assert (Overload_Row.Status = Closure.Integrated_Closure_Overload_Blocker,
              "generic replay overload/type ambiguity should remain an overload closure blocker");
      Assert (Indeterminate_Row.Status = Closure.Integrated_Closure_Indeterminate,
              "indeterminate generic backmapping should remain indeterminate closure");
      Assert (Closure.Count_Blocker (Model, Closure.Closure_Blocker_Coverage_Gate) = 1,
              "one generic mapping gap should be counted as coverage-gate blocker");
      Assert (Closure.Count_Blocker (Model, Closure.Closure_Blocker_Dataflow) = 1,
              "one generic flow replay row should be counted as dataflow blocker");
      Assert (Closure.Count_Blocker (Model, Closure.Closure_Blocker_Contract) = 1,
              "one generic predicate replay row should be counted as contract blocker");
      Assert (Closure.Count_Blocker (Model, Closure.Closure_Blocker_Accessibility) = 1,
              "one generic accessibility replay row should be counted as accessibility blocker");
      Assert (Closure.Count_Blocker (Model, Closure.Closure_Blocker_Representation) = 1,
              "one generic representation replay row should be counted as representation blocker");
      Assert (Closure.Count_Blocker (Model, Closure.Closure_Blocker_Overload) = 1,
              "one generic overload replay row should be counted as overload blocker");
      Assert (Closure.Blocker_Count (Model) = 6,
              "six non-legal generic backmap rows should be hard closure blockers and one remains indeterminate");
      Assert (Closure.Fingerprint (Model) /= 0,
              "generic backmapping closure bridge must have a deterministic fingerprint");
   end Generic_Backmap_Rows_Become_Direct_Closure_Blockers;

   procedure Existing_Closure_Contexts_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Base_Contexts : Closure.Integrated_Closure_Context_Model;
      Base_Context  : Closure.Integrated_Closure_Context_Info;
      Backmap_Contexts : Backmap.Generic_Backmap_Context_Model;
      C : Backmap.Generic_Backmap_Context_Info;
   begin
      Base_Context.Id := 1;
      Base_Context.Kind := Closure.Closure_Context_Package_Body;
      Base_Context.Unit_Name := To_Unbounded_String ("Pkg");
      Base_Context.Normalized_Unit_Name := To_Unbounded_String ("pkg");
      Base_Context.Dependency := Closure.Dependency_Local_Only;
      Base_Context.Node := Editor.Ada_Syntax_Tree.Node_Id (118151);
      Closure.Add_Context (Base_Contexts, Base_Context);

      Fill_Common (C, 52);
      C.Kind := Backmap.Generic_Backmap_Call_Replay;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (118152);
      Backmap.Add_Context (Backmap_Contexts, C);

      declare
         Backmap_Model : constant Backmap.Generic_Backmap_Model := Backmap.Build (Backmap_Contexts);
         Model : constant Closure.Integrated_Closure_Model :=
           Bridge.Build_With_Generic_Backmapping (Base_Contexts, Backmap_Model);
      begin
         Assert (Closure.Closure_Count (Model) = 2,
                 "base closure contexts should be preserved when generic backmaps are appended");
         Assert (Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118151)).Status =
                   Closure.Integrated_Closure_Legal_Local,
                 "pre-existing local closure row should remain legal");
         Assert (Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118152)).Status =
                   Closure.Integrated_Closure_Legal_Local,
                 "new legal generic backmap row should be appended as legal local closure");
      end;
   end Existing_Closure_Contexts_Are_Preserved;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Generic_Backmap_Rows_Become_Direct_Closure_Blockers'Access,
         "generic replay source/instance backmapping feeds integrated closure blockers");
      Register_Routine
        (T,
         Existing_Closure_Contexts_Are_Preserved'Access,
         "existing integrated closure contexts are preserved by generic backmapping bridge");
   end Register_Tests;

end Test_Ada_Integrated_Closure_Generic_Backmapping;
