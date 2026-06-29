with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality is

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
   package Gen_Rep renames Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Gen_Rep.Generic_Replay_Representation_Row_Id;
   use type Gen_Rep.Generic_Replay_Representation_Context_Kind;
   use type Gen_Rep.Generic_Replay_Representation_Status;
   use type Gen_Rep.Generic_Replay_Representation_Context_Info;
   use type Gen_Rep.Generic_Replay_Representation_Info;
   use type Gen_Rep.Generic_Replay_Representation_Context_Model;
   use type Gen_Rep.Generic_Replay_Representation_Set;
   use type Gen_Rep.Generic_Replay_Representation_Model;
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
      return AUnit.Format ("Test_Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality");
   end Name;

   function Sample_Context_Model return Gen_Rep.Generic_Replay_Representation_Context_Model is
      Contexts : Gen_Rep.Generic_Replay_Representation_Context_Model;
      C        : Gen_Rep.Generic_Replay_Representation_Context_Info;
   begin
      C.Id := 1;
      C.Kind := Gen_Rep.Generic_Replay_Representation_Representation_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117101);
      C.Generic_Source_Node := Editor.Ada_Syntax_Tree.Node_Id (117101);
      C.Instance_Node := Editor.Ada_Syntax_Tree.Node_Id (117201);
      C.Generic_Unit_Name := To_Unbounded_String ("G");
      C.Instance_Name := To_Unbounded_String ("I");
      C.Target_Name := To_Unbounded_String ("Device_State");
      C.Replay_Row := Replay.Replay_Row_Id (1);
      C.Replay_Status := Replay.Replay_Legal_Representation_Freezing;
      C.Representation_CPD_Row := Rep_CPD.Representation_Tasking_CPD_Row_Id (1);
      C.Representation_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Legal_Representation_Clause_Accepted;
      C.Representation_CPD_Matches := 1;
      C.Source_Fingerprint := 1001;
      C.Substitution_Fingerprint := 2001;
      Gen_Rep.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := Gen_Rep.Generic_Replay_Representation_Operational_Attribute;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117102);
      C.Instance_Name := To_Unbounded_String ("I");
      C.Replay_Row := Replay.Replay_Row_Id (2);
      C.Replay_Status := Replay.Replay_Legal_Representation_Freezing;
      C.Representation_CPD_Row := Rep_CPD.Representation_Tasking_CPD_Row_Id (2);
      C.Representation_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Read_Before_Write_Blocker;
      C.Representation_CPD_Matches := 1;
      C.Source_Fingerprint := 1002;
      C.Substitution_Fingerprint := 2002;
      Gen_Rep.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := Gen_Rep.Generic_Replay_Representation_Stream_Attribute;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117103);
      C.Instance_Name := To_Unbounded_String ("I");
      C.Replay_Row := Replay.Replay_Row_Id (3);
      C.Replay_Status := Replay.Replay_Legal_Representation_Freezing;
      C.Representation_CPD_Row := Rep_CPD.Representation_Tasking_CPD_Row_Id (3);
      C.Representation_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Global_Depends_Blocker;
      C.Representation_CPD_Matches := 1;
      C.Source_Fingerprint := 1003;
      C.Substitution_Fingerprint := 2003;
      Gen_Rep.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := Gen_Rep.Generic_Replay_Representation_Nested_Generic_Instance;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117104);
      C.Instance_Name := To_Unbounded_String ("Nested_I");
      C.Replay_Row := Replay.Replay_Row_Id (4);
      C.Replay_Status := Replay.Replay_Legal_Nested_Instance;
      C.Representation_CPD_Row := Rep_CPD.Representation_Tasking_CPD_Row_Id (4);
      C.Representation_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Call_Propagation_Blocker;
      C.Representation_CPD_Matches := 1;
      C.Source_Fingerprint := 1004;
      C.Substitution_Fingerprint := 2004;
      Gen_Rep.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := Gen_Rep.Generic_Replay_Representation_Record_Layout;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117105);
      C.Instance_Name := To_Unbounded_String ("I");
      C.Replay_Row := Replay.Replay_Row_Id (5);
      C.Replay_Status := Replay.Replay_Legal_Representation_Freezing;
      C.Representation_CPD_Row := Rep_CPD.Representation_Tasking_CPD_Row_Id (5);
      C.Representation_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Coverage_Blocker;
      C.Representation_CPD_Matches := 1;
      C.Source_Fingerprint := 1005;
      C.Substitution_Fingerprint := 2005;
      Gen_Rep.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := Gen_Rep.Generic_Replay_Representation_Freezing_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117106);
      C.Instance_Name := To_Unbounded_String ("I");
      C.Replay_Row := Replay.Replay_Row_Id (6);
      C.Replay_Status := Replay.Replay_Representation_Freezing_Error;
      C.Representation_CPD_Row := Rep_CPD.Representation_Tasking_CPD_Row_Id (6);
      C.Representation_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Legal_Generic_Instance_Effect_Accepted;
      C.Representation_CPD_Matches := 1;
      C.Source_Fingerprint := 1006;
      C.Substitution_Fingerprint := 2006;
      Gen_Rep.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := Gen_Rep.Generic_Replay_Representation_Tasking_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117107);
      C.Instance_Name := To_Unbounded_String ("I");
      C.Replay_Row := Replay.Replay_Row_Id (7);
      C.Replay_Status := Replay.Replay_Legal_Representation_Freezing;
      C.Representation_CPD_Row := Rep_CPD.Representation_Tasking_CPD_Row_Id (7);
      C.Representation_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Base_Tasking_Effect_Error;
      C.Representation_CPD_Matches := 1;
      C.Source_Fingerprint := 1007;
      C.Substitution_Fingerprint := 2007;
      Gen_Rep.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := Gen_Rep.Generic_Replay_Representation_Private_Full_View;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117108);
      C.Instance_Name := To_Unbounded_String ("I");
      C.Replay_Row := Replay.Replay_Row_Id (8);
      C.Replay_Status := Replay.Replay_Legal_Representation_Freezing;
      C.Representation_CPD_Row := Rep_CPD.No_Representation_Tasking_CPD_Row;
      C.Representation_CPD_Status := Rep_CPD.Representation_Tasking_CPD_Not_Checked;
      C.Representation_CPD_Matches := 0;
      C.Source_Fingerprint := 1008;
      C.Substitution_Fingerprint := 2008;
      Gen_Rep.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Gen_Rep.Generic_Replay_Representation_Model :=
        Gen_Rep.Build (Sample_Context_Model);
   begin
      Assert (Gen_Rep.Row_Count (Model) = 8, "expected eight generic replay representation CPD rows");
      Assert (Gen_Rep.Legal_Count (Model) = 1, "only accepted representation replay should remain legal");
      Assert (Gen_Rep.Count_Status (Model, Gen_Rep.Generic_Replay_Representation_Linked_Flow_Graph_Error) = 1,
              "generic replay must consume object-state blocker");
      Assert (Gen_Rep.Count_Status (Model, Gen_Rep.Generic_Replay_Representation_Base_Contract_Flow_Error) = 1,
              "generic replay must consume Global/Depends blocker");
      Assert (Gen_Rep.Count_Status (Model, Gen_Rep.Generic_Replay_Representation_Call_Effect_Not_Propagated) = 1,
              "nested generic replay must consume call propagation blocker");
      Assert (Gen_Rep.Count_Status (Model, Gen_Rep.Generic_Replay_Representation_Coverage_Feedback_Blocker) = 1,
              "generic replay must preserve representation coverage blocker");
      Assert (Gen_Rep.Count_Status (Model, Gen_Rep.Generic_Replay_Representation_Replay_Representation_Error) = 1,
              "base replay representation errors must dominate legal representation CPD rows");
      Assert (Gen_Rep.Count_Status (Model, Gen_Rep.Generic_Replay_Representation_Base_Tasking_Effect_Error) = 1,
              "generic replay must consume tasking representation-effect blocker");
      Assert (Gen_Rep.Count_Status (Model, Gen_Rep.Generic_Replay_Representation_Missing_Representation_CPD_Row) = 1,
              "generic replay without representation CPD row must not remain confident");
      Assert (Gen_Rep.Replay_Error_Count (Model) = 1, "expected one base replay blocker");
      Assert (Gen_Rep.Global_Error_Count (Model) = 0, "CPD blockers are preserved by concrete status, not old Refined_Global counters");
      Assert (Gen_Rep.Depends_Error_Count (Model) = 0, "CPD blockers are preserved by concrete status, not old Refined_Depends counters");
      Assert (Gen_Rep.Propagation_Error_Count (Model) = 1, "expected one call propagation blocker");
      Assert (Gen_Rep.Coverage_Error_Count (Model) = 1, "expected one coverage blocker");
      Assert (Gen_Rep.Tasking_Error_Count (Model) = 1, "expected one tasking effect blocker");
      Assert (Gen_Rep.Fingerprint (Model) /= 0, "model fingerprint must be deterministic and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Gen_Rep.Generic_Replay_Representation_Model :=
        Gen_Rep.Build (Sample_Context_Model);
      Row   : constant Gen_Rep.Generic_Replay_Representation_Info :=
        Gen_Rep.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (117104));
      Set   : constant Gen_Rep.Generic_Replay_Representation_Set :=
        Gen_Rep.Rows_For_Instance (Model, "I");
   begin
      Assert (Row.Status = Gen_Rep.Generic_Replay_Representation_Call_Effect_Not_Propagated,
              "node lookup must preserve nested generic propagation blocker");
      Assert (Gen_Rep.Set_Count (Set) = 7, "seven rows belong to instance I");
      Assert (Gen_Rep.Count_Kind (Model, Gen_Rep.Generic_Replay_Representation_Representation_Clause) = 1,
              "kind count must preserve representation clause replay row");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "generic replay consumes representation CPD blockers");
      Register_Routine (T, Test_Queries'Access, "generic replay representation CPD lookups preserve blockers");
   end Register_Tests;

end Test_Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;
