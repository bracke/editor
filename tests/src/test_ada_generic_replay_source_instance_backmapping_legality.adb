with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Generic_Instance_Body_Semantic_Replay;
with Editor.Ada_Generic_Replay_Representation_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
with Editor.Ada_Overload_Type_Edge_Precision_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Generic_Replay_Source_Instance_Backmapping_Legality is

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
   package Backmap renames Editor.Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
   use type Backmap.Generic_Backmap_Row_Id;
   use type Backmap.Generic_Backmap_Context_Kind;
   use type Backmap.Generic_Backmap_Status;
   use type Backmap.Generic_Backmap_Context_Info;
   use type Backmap.Generic_Backmap_Info;
   use type Backmap.Generic_Backmap_Context_Model;
   use type Backmap.Generic_Backmap_Set;
   use type Backmap.Generic_Backmap_Model;
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
      return AUnit.Format ("Test_Ada_Generic_Replay_Source_Instance_Backmapping_Legality");
   end Name;

   procedure Fill_Common (C : in out Backmap.Generic_Backmap_Context_Info; Id : Natural) is
   begin
      C.Id := Backmap.Generic_Backmap_Row_Id (Id);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (118000 + Id);
      C.Generic_Source_Node := Editor.Ada_Syntax_Tree.Node_Id (118100 + Id);
      C.Instance_Node := Editor.Ada_Syntax_Tree.Node_Id (118200 + Id);
      C.Formal_Node := Editor.Ada_Syntax_Tree.Node_Id (118300 + Id);
      C.Actual_Node := Editor.Ada_Syntax_Tree.Node_Id (118400 + Id);
      C.Body_Node := Editor.Ada_Syntax_Tree.Node_Id (118500 + Id);
      C.Substituted_Node := Editor.Ada_Syntax_Tree.Node_Id (118600 + Id);
      C.Generic_Unit_Name := To_Unbounded_String ("G");
      C.Instance_Name := To_Unbounded_String ("I");
      C.Formal_Name := To_Unbounded_String ("T");
      C.Actual_Name := To_Unbounded_String ("Integer");
      C.Replay_Row := Replay.Replay_Row_Id (Id);
      C.Replay_Status := Replay.Replay_Legal_Substituted_Expression;
      C.Replay_CPD_Row := Replay_CPD.Generic_Replay_Representation_Row_Id (Id);
      C.Replay_CPD_Status := Replay_CPD.Generic_Replay_Representation_Legal_Body_Expression_Accepted;
      C.Replay_CPD_Matches := 1;
      C.Overload_Row := Overload_Edge.Overload_Type_Edge_Row_Id (Id);
      C.Overload_Status := Overload_Edge.Overload_Type_Edge_Legal_Nested_Generic_Selected;
      C.Overload_Matches := 1;
      C.Source_Fingerprint := 7000 + Id;
      C.Expected_Source_Fingerprint := 7000 + Id;
      C.Substitution_Fingerprint := 8000 + Id;
      C.Expected_Substitution_Fingerprint := 8000 + Id;
   end Fill_Common;

   function Sample_Context_Model return Backmap.Generic_Backmap_Context_Model is
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
      C.Kind := Backmap.Generic_Backmap_Statement_Replay;
      C.Formal_Actual_Map_Present := False;
      Backmap.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 4);
      C.Kind := Backmap.Generic_Backmap_Representation_Replay;
      C.Expected_Substitution_Fingerprint := 999999;
      Backmap.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 5);
      C.Kind := Backmap.Generic_Backmap_Flow_Replay;
      C.Replay_Status := Replay.Replay_Flow_Effect_Error;
      Backmap.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 6);
      C.Kind := Backmap.Generic_Backmap_Predicate_Replay;
      C.Replay_CPD_Status := Replay_CPD.Generic_Replay_Representation_Coverage_Feedback_Blocker;
      Backmap.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 7);
      C.Kind := Backmap.Generic_Backmap_Nested_Instance_Replay;
      C.Overload_Status := Overload_Edge.Overload_Type_Edge_Nested_Defaulted_Formal_Ambiguous;
      Backmap.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 8);
      C.Kind := Backmap.Generic_Backmap_Accessibility_Replay;
      C.Overload_Row := Overload_Edge.No_Overload_Type_Edge_Row;
      C.Overload_Status := Overload_Edge.Overload_Type_Edge_Not_Checked;
      C.Overload_Matches := 0;
      Backmap.Add_Context (Contexts, C);

      C := (others => <>);
      Fill_Common (C, 9);
      C.Kind := Backmap.Generic_Backmap_Return_Replay;
      C.Replay_CPD_Matches := 2;
      Backmap.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Backmap.Generic_Backmap_Model := Backmap.Build (Sample_Context_Model);
   begin
      Assert (Backmap.Row_Count (Model) = 9, "expected nine generic backmap rows");
      Assert (Backmap.Legal_Count (Model) = 1, "only fully mapped generic replay row should remain legal");
      Assert (Backmap.Count_Status (Model, Backmap.Generic_Backmap_Missing_Generic_Source_Node) = 1,
              "missing generic source node must block backmapping");
      Assert (Backmap.Count_Status (Model, Backmap.Generic_Backmap_Missing_Formal_Actual_Map) = 1,
              "formal/actual mapping gaps must block backmapping");
      Assert (Backmap.Count_Status (Model, Backmap.Generic_Backmap_Substitution_Fingerprint_Mismatch) = 1,
              "substitution fingerprint mismatch must block backmapping");
      Assert (Backmap.Count_Status (Model, Backmap.Generic_Backmap_Base_Replay_Error) = 1,
              "base replay errors must dominate later consumer evidence");
      Assert (Backmap.Count_Status (Model, Backmap.Generic_Backmap_Replay_CPD_Blocker) = 1,
              "replay CPD blockers must be preserved");
      Assert (Backmap.Count_Status (Model, Backmap.Generic_Backmap_Overload_Type_Edge_Ambiguous) = 1,
              "generic overload ambiguity must remain a backmap blocker");
      Assert (Backmap.Count_Status (Model, Backmap.Generic_Backmap_Missing_Overload_Type_Edge_Row) = 1,
              "missing overload/type edge evidence must block confident backmaps");
      Assert (Backmap.Count_Status (Model, Backmap.Generic_Backmap_Multiple_Matching_Replay_CPD_Rows) = 1,
              "multiple replay CPD matches must not be flattened");
      Assert (Backmap.Mapping_Error_Count (Model) = 3, "expected three mapping/fingerprint blockers");
      Assert (Backmap.Replay_Error_Count (Model) = 1, "expected one base replay blocker");
      Assert (Backmap.Replay_CPD_Error_Count (Model) = 2, "expected replay CPD blocker plus duplicate match");
      Assert (Backmap.Overload_Error_Count (Model) = 2, "expected overload ambiguity plus missing overload row");
      Assert (Backmap.Ambiguous_Count (Model) = 1, "expected one ambiguity blocker");
      Assert (Backmap.Fingerprint (Model) /= 0, "backmap model fingerprint must be nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Backmap.Generic_Backmap_Model := Backmap.Build (Sample_Context_Model);
      Row   : constant Backmap.Generic_Backmap_Info :=
        Backmap.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (118007));
      By_Instance : constant Backmap.Generic_Backmap_Set := Backmap.Rows_For_Instance (Model, "I");
      By_Generic  : constant Backmap.Generic_Backmap_Set := Backmap.Rows_For_Generic_Unit (Model, "G");
   begin
      Assert (Row.Status = Backmap.Generic_Backmap_Overload_Type_Edge_Ambiguous,
              "node lookup must preserve nested generic overload ambiguity");
      Assert (Backmap.Set_Count (By_Instance) = 9, "all rows belong to instance I");
      Assert (Backmap.Set_Count (By_Generic) = 9, "all rows belong to generic unit G");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "generic replay source/instance backmap blockers");
      Register_Routine (T, Test_Queries'Access, "generic replay backmap lookups preserve source and instance context");
   end Register_Tests;

end Test_Ada_Generic_Replay_Source_Instance_Backmapping_Legality;
