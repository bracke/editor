with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Integrated_Semantic_Closure;
with Editor.Ada_Integrated_Semantic_Closure.Consumer_Chain;
with Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Integrated_Closure_Semantic_Consumer_Chain_Pass1172 is

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
   package Bridge renames Editor.Ada_Integrated_Semantic_Closure.Consumer_Chain;
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
   package GRR renames Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;
   use type GRR.Generic_Replay_Representation_Row_Id;
   use type GRR.Generic_Replay_Representation_Context_Kind;
   use type GRR.Generic_Replay_Representation_Status;
   use type GRR.Generic_Replay_Representation_Context_Info;
   use type GRR.Generic_Replay_Representation_Info;
   use type GRR.Generic_Replay_Representation_Context_Model;
   use type GRR.Generic_Replay_Representation_Set;
   use type GRR.Generic_Replay_Representation_Model;
   package Rep_CPD renames Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Rep_CPD.Representation_Tasking_CPD_Row_Id;
   use type Rep_CPD.Representation_Tasking_CPD_Context_Kind;
   use type Rep_CPD.Representation_Tasking_CPD_Status;
   use type Rep_CPD.Representation_Tasking_CPD_Context_Info;
   use type Rep_CPD.Representation_Tasking_CPD_Info;
   use type Rep_CPD.Representation_Tasking_CPD_Context_Model;
   use type Rep_CPD.Representation_Tasking_CPD_Set;
   use type Rep_CPD.Representation_Tasking_CPD_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Integrated_Closure_Semantic_Consumer_Chain_Pass1172");
   end Name;

   procedure Add_Row
     (Contexts : in out GRR.Generic_Replay_Representation_Context_Model;
      Id       : GRR.Generic_Replay_Representation_Row_Id;
      Kind     : GRR.Generic_Replay_Representation_Context_Kind;
      Node     : Editor.Ada_Syntax_Tree.Node_Id;
      Rep_Status : Rep_CPD.Representation_Tasking_CPD_Status;
      Replay_Status : Replay.Replay_Status := Replay.Replay_Legal_Representation_Freezing)
   is
      C : GRR.Generic_Replay_Representation_Context_Info;
   begin
      C.Id := Id;
      C.Kind := Kind;
      C.Node := Node;
      C.Instance_Name := To_Unbounded_String ("I");
      C.Generic_Unit_Name := To_Unbounded_String ("G");
      C.Target_Name := To_Unbounded_String ("State");
      C.Replay_Row := Replay.Replay_Row_Id (Id);
      C.Replay_Status := Replay_Status;
      C.Representation_CPD_Row := Rep_CPD.Representation_Tasking_CPD_Row_Id (Id);
      C.Representation_CPD_Status := Rep_Status;
      C.Representation_CPD_Matches := 1;
      C.Source_Fingerprint := Natural (Id) * 101;
      C.Substitution_Fingerprint := Natural (Id) * 211;
      GRR.Add_Context (Contexts, C);
   end Add_Row;

   function Sample_Generic_Replay_Model return GRR.Generic_Replay_Representation_Model is
      Contexts : GRR.Generic_Replay_Representation_Context_Model;
   begin
      Add_Row
        (Contexts,
         1,
         GRR.Generic_Replay_Representation_Representation_Clause,
         Editor.Ada_Syntax_Tree.Node_Id (117201),
         Rep_CPD.Representation_Tasking_CPD_Legal_Representation_Clause_Accepted);
      Add_Row
        (Contexts,
         2,
         GRR.Generic_Replay_Representation_Operational_Attribute,
         Editor.Ada_Syntax_Tree.Node_Id (117202),
         Rep_CPD.Representation_Tasking_CPD_Read_Before_Write_Blocker);
      Add_Row
        (Contexts,
         3,
         GRR.Generic_Replay_Representation_Stream_Attribute,
         Editor.Ada_Syntax_Tree.Node_Id (117203),
         Rep_CPD.Representation_Tasking_CPD_Global_Depends_Blocker);
      Add_Row
        (Contexts,
         4,
         GRR.Generic_Replay_Representation_Nested_Generic_Instance,
         Editor.Ada_Syntax_Tree.Node_Id (117204),
         Rep_CPD.Representation_Tasking_CPD_Call_Propagation_Blocker);
      Add_Row
        (Contexts,
         5,
         GRR.Generic_Replay_Representation_Record_Layout,
         Editor.Ada_Syntax_Tree.Node_Id (117205),
         Rep_CPD.Representation_Tasking_CPD_Coverage_Blocker);
      Add_Row
        (Contexts,
         6,
         GRR.Generic_Replay_Representation_Tasking_Effect,
         Editor.Ada_Syntax_Tree.Node_Id (117206),
         Rep_CPD.Representation_Tasking_CPD_Base_Tasking_Effect_Error);
      Add_Row
        (Contexts,
         7,
         GRR.Generic_Replay_Representation_Freezing_Effect,
         Editor.Ada_Syntax_Tree.Node_Id (117207),
         Rep_CPD.Representation_Tasking_CPD_Legal_Generic_Instance_Effect_Accepted,
         Replay.Replay_Representation_Freezing_Error);

      return GRR.Build (Contexts);
   end Sample_Generic_Replay_Model;

   procedure Consumer_Chain_Rows_Become_Direct_Closure_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Empty_Context : Closure.Integrated_Closure_Context_Model;
      Generic_Model : constant GRR.Generic_Replay_Representation_Model := Sample_Generic_Replay_Model;
      Model : constant Closure.Integrated_Closure_Model :=
        Bridge.Build_With_Consumer_Chain (Empty_Context, Generic_Model);
      Legal_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (117201));
      Dataflow_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (117202));
      Contract_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (117203));
      Propagation_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (117204));
      Coverage_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (117205));
      Tasking_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (117206));
      Representation_Row : constant Closure.Integrated_Closure_Info :=
        Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (117207));
   begin
      Assert (Closure.Closure_Count (Model) = 7,
              "all generic replay consumer rows should enter integrated closure");
      Assert (Legal_Row.Status = Closure.Integrated_Closure_Legal_Local,
              "accepted generic replay representation CPD row should remain legal closure");
      Assert (Dataflow_Row.Status = Closure.Integrated_Closure_Dataflow_Blocker,
              "read-before-write evidence should surface as a dataflow blocker");
      Assert (Contract_Row.Status = Closure.Integrated_Closure_Contract_Blocker,
              "Global/Depends evidence should surface as a contract/dataflow blocker family");
      Assert (Propagation_Row.Status = Closure.Integrated_Closure_Dataflow_Blocker,
              "call propagation evidence should surface as dataflow closure blocker");
      Assert (Coverage_Row.Status = Closure.Integrated_Closure_Coverage_Gate_Blocker,
              "coverage feedback should remain a coverage-gate closure blocker");
      Assert (Tasking_Row.Status = Closure.Integrated_Closure_Wide_Legality_Blocker,
              "tasking/protected replay effect blockers should not remain legal closure");
      Assert (Representation_Row.Status = Closure.Integrated_Closure_Representation_Blocker,
              "base replay representation failures should surface as representation blockers");
      Assert (Closure.Count_Blocker (Model, Closure.Closure_Blocker_Dataflow) = 2,
              "two consumer-chain rows should become dataflow blockers");
      Assert (Closure.Count_Blocker (Model, Closure.Closure_Blocker_Coverage_Gate) = 1,
              "one consumer-chain row should become a coverage-gate blocker");
      Assert (Closure.Blocker_Count (Model) = 6,
              "six non-legal consumer-chain rows should be counted as blockers");
      Assert (Closure.Legal_Count (Model) = 1,
              "one consumer-chain row should remain legal");
      Assert (Closure.Fingerprint (Model) /= 0,
              "integrated consumer-chain closure must have a deterministic fingerprint");
   end Consumer_Chain_Rows_Become_Direct_Closure_Blockers;

   procedure Existing_Closure_Contexts_Are_Preserved
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Base_Contexts : Closure.Integrated_Closure_Context_Model;
      Base_Context  : Closure.Integrated_Closure_Context_Info;
      Generic_Contexts : GRR.Generic_Replay_Representation_Context_Model;
   begin
      Base_Context.Id := 1;
      Base_Context.Kind := Closure.Closure_Context_Package_Body;
      Base_Context.Unit_Name := To_Unbounded_String ("Pkg");
      Base_Context.Normalized_Unit_Name := To_Unbounded_String ("pkg");
      Base_Context.Dependency := Closure.Dependency_Local_Only;
      Base_Context.Node := Editor.Ada_Syntax_Tree.Node_Id (117251);
      Closure.Add_Context (Base_Contexts, Base_Context);

      Add_Row
        (Generic_Contexts,
         1,
         GRR.Generic_Replay_Representation_Representation_Clause,
         Editor.Ada_Syntax_Tree.Node_Id (117252),
         Rep_CPD.Representation_Tasking_CPD_Legal_Representation_Clause_Accepted);

      declare
         Generic_Model : constant GRR.Generic_Replay_Representation_Model := GRR.Build (Generic_Contexts);
         Model : constant Closure.Integrated_Closure_Model :=
           Bridge.Build_With_Consumer_Chain (Base_Contexts, Generic_Model);
      begin
         Assert (Closure.Closure_Count (Model) = 2,
                 "base integrated closure contexts should be preserved while consumer-chain rows are appended");
         Assert (Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (117251)).Status =
                   Closure.Integrated_Closure_Legal_Local,
                 "pre-existing local closure should remain legal");
         Assert (Closure.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (117252)).Status =
                   Closure.Integrated_Closure_Legal_Local,
                 "legal generic replay consumer row should be appended as legal local closure");
      end;
   end Existing_Closure_Contexts_Are_Preserved;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Consumer_Chain_Rows_Become_Direct_Closure_Blockers'Access,
         "semantic consumer-chain rows feed integrated closure blockers");
      Register_Routine
        (T,
         Existing_Closure_Contexts_Are_Preserved'Access,
         "existing integrated closure contexts are preserved by consumer-chain bridge");
   end Register_Tests;

end Test_Ada_Integrated_Closure_Semantic_Consumer_Chain_Pass1172;
