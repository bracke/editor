with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Flow_Refinement_Consumer_Legality;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Refined_Global_Depends_Conformance_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Flow_Refinement_Consumer_Legality_Pass1155 is

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
   package Consumer renames Editor.Ada_Flow_Refinement_Consumer_Legality;
   use type Consumer.Consumer_Row_Id;
   use type Consumer.Consumer_Kind;
   use type Consumer.Consumer_Effect_Kind;
   use type Consumer.Consumer_Status;
   use type Consumer.Consumer_Context_Info;
   use type Consumer.Consumer_Info;
   use type Consumer.Consumer_Context_Model;
   use type Consumer.Consumer_Set;
   use type Consumer.Consumer_Model;
   package Flow renames Editor.Ada_Flow_Effect_Graph_Legality;
   use type Flow.Flow_Edge_Id;
   use type Flow.Flow_Graph_Context_Kind;
   use type Flow.Flow_Edge_Kind;
   use type Flow.Flow_Effect_Graph_Status;
   use type Flow.Flow_Effect_Context_Info;
   use type Flow.Flow_Effect_Info;
   use type Flow.Flow_Effect_Context_Model;
   use type Flow.Flow_Effect_Set;
   use type Flow.Flow_Effect_Graph_Model;
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
      return AUnit.Format ("Test_Ada_Flow_Refinement_Consumer_Legality_Pass1155");
   end Name;

   function Sample_Context_Model return Consumer.Consumer_Context_Model is
      Contexts : Consumer.Consumer_Context_Model;
      C        : Consumer.Consumer_Context_Info;
   begin
      C.Id := 1;
      C.Consumer := Consumer.Consumer_Integrated_Closure;
      C.Effect := Consumer.Consumer_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115501);
      C.Object_Name := To_Unbounded_String ("Config");
      C.Flow_Row := Flow.Flow_Edge_Id (1);
      C.Flow_Status := Flow.Flow_Graph_Legal_Read_Edge;
      C.Refined_Row := Refined.Refined_Conformance_Id (1);
      C.Refined_Status := Refined.Refined_Conformance_Legal_Global_Refinement;
      C.Refined_Match_Count := 1;
      C.Spec_Global_Mode := DGL.Global_Mode_In;
      C.Refined_Global_Mode := DGL.Global_Mode_In;
      C.Source_Fingerprint := 501;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Consumer := Consumer.Consumer_Integrated_Closure;
      C.Effect := Consumer.Consumer_Effect_Write;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115502);
      C.Object_Name := To_Unbounded_String ("State");
      C.Flow_Row := Flow.Flow_Edge_Id (2);
      C.Flow_Status := Flow.Flow_Graph_Legal_Write_Edge;
      C.Refined_Row := Refined.Refined_Conformance_Id (2);
      C.Refined_Status := Refined.Refined_Conformance_Body_Write_Missing_From_Refined_Global;
      C.Refined_Match_Count := 1;
      C.Spec_Global_Mode := DGL.Global_Mode_In_Out;
      C.Refined_Global_Mode := DGL.Global_Mode_In;
      C.Source_Fingerprint := 502;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Consumer := Consumer.Consumer_Call;
      C.Effect := Consumer.Consumer_Effect_Call_Propagation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115503);
      C.Caller_Name := To_Unbounded_String ("Driver");
      C.Callee_Name := To_Unbounded_String ("Update_State");
      C.Flow_Row := Flow.Flow_Edge_Id (3);
      C.Flow_Status := Flow.Flow_Graph_Legal_Call_Propagation;
      C.Refined_Row := Refined.Refined_Conformance_Id (3);
      C.Refined_Status := Refined.Refined_Conformance_Call_Effect_Not_Propagated;
      C.Refined_Match_Count := 1;
      C.Source_Fingerprint := 503;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Consumer := Consumer.Consumer_Integrated_Closure;
      C.Effect := Consumer.Consumer_Effect_Depends;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115504);
      C.Source_Name := To_Unbounded_String ("Input");
      C.Target_Name := To_Unbounded_String ("Output");
      C.Flow_Row := Flow.Flow_Edge_Id (4);
      C.Flow_Status := Flow.Flow_Graph_Legal_Depends_Edge;
      C.Refined_Row := Refined.Refined_Conformance_Id (4);
      C.Refined_Status := Refined.Refined_Conformance_Refined_Depends_Missing_Edge;
      C.Refined_Match_Count := 1;
      C.Source_Global_Mode := DGL.Global_Mode_In;
      C.Target_Global_Mode := DGL.Global_Mode_Out;
      C.Source_Fingerprint := 504;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Consumer := Consumer.Consumer_Generic_Instance;
      C.Effect := Consumer.Consumer_Effect_Generic_Substitution;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115505);
      C.Object_Name := To_Unbounded_String ("Actual_State");
      C.Flow_Row := Flow.Flow_Edge_Id (5);
      C.Flow_Status := Flow.Flow_Graph_Legal_Generic_Substitution;
      C.Refined_Row := Refined.Refined_Conformance_Id (5);
      C.Refined_Status := Refined.Refined_Conformance_Coverage_Feedback_Blocker;
      C.Refined_Match_Count := 1;
      C.Source_Fingerprint := 505;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Consumer := Consumer.Consumer_Task_Protected;
      C.Effect := Consumer.Consumer_Effect_Protected_State;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115506);
      C.Object_Name := To_Unbounded_String ("Protected_State");
      C.Flow_Row := Flow.Flow_Edge_Id (6);
      C.Flow_Status := Flow.Flow_Graph_Protected_Function_Writes_State;
      C.Refined_Row := Refined.Refined_Conformance_Id (6);
      C.Refined_Status := Refined.Refined_Conformance_Legal_Global_Refinement;
      C.Refined_Match_Count := 1;
      C.Source_Fingerprint := 506;
      Consumer.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Consumer := Consumer.Consumer_Integrated_Closure;
      C.Effect := Consumer.Consumer_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115507);
      C.Object_Name := To_Unbounded_String ("Unknown");
      C.Flow_Row := Flow.Flow_Edge_Id (7);
      C.Flow_Status := Flow.Flow_Graph_Legal_Read_Edge;
      C.Refined_Row := Refined.No_Refined_Conformance;
      C.Refined_Status := Refined.Refined_Conformance_Not_Checked;
      C.Refined_Match_Count := 0;
      C.Source_Fingerprint := 507;
      Consumer.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Consumer.Consumer_Model := Consumer.Build (Sample_Context_Model);
   begin
      Assert (Consumer.Row_Count (Model) = 7, "expected seven consumer rows");
      Assert (Consumer.Legal_Count (Model) = 1, "only one row should be fully accepted");
      Assert (Consumer.Count_Status (Model, Consumer.Consumer_Refined_Global_Missing_Write) = 1,
              "missing Refined_Global write must block consumers");
      Assert (Consumer.Count_Status (Model, Consumer.Consumer_Call_Effect_Not_Propagated) = 1,
              "unpropagated call effect must block consumers");
      Assert (Consumer.Count_Status (Model, Consumer.Consumer_Refined_Depends_Missing_Edge) = 1,
              "missing Refined_Depends edge must block consumers");
      Assert (Consumer.Count_Status (Model, Consumer.Consumer_Coverage_Feedback_Blocker) = 1,
              "coverage feedback blocker must remain a consumer blocker");
      Assert (Consumer.Count_Status (Model, Consumer.Consumer_Flow_Graph_Error) = 1,
              "underlying flow graph errors must block consumers");
      Assert (Consumer.Count_Status (Model, Consumer.Consumer_Missing_Refinement_Row) = 1,
              "flow rows without refinement rows must not be accepted");
      Assert (Consumer.Global_Error_Count (Model) = 1, "expected one Global refinement error");
      Assert (Consumer.Depends_Error_Count (Model) = 1, "expected one Depends refinement error");
      Assert (Consumer.Propagation_Error_Count (Model) = 1, "expected one propagation error");
      Assert (Consumer.Coverage_Error_Count (Model) = 1, "expected one coverage feedback error");
      Assert (Consumer.Fingerprint (Model) /= 0, "model fingerprint must be stable and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Consumer.Consumer_Model := Consumer.Build (Sample_Context_Model);
      Row   : constant Consumer.Consumer_Info :=
        Consumer.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115503));
      Set   : constant Consumer.Consumer_Set :=
        Consumer.Rows_For_Consumer (Model, Consumer.Consumer_Call);
   begin
      Assert (Row.Status = Consumer.Consumer_Call_Effect_Not_Propagated,
              "node lookup must preserve call propagation blocker");
      Assert (Consumer.Set_Count (Set) = 1, "one call consumer row expected");
      Assert (Consumer.Set_At (Set, 1).Callee_Name = To_Unbounded_String ("Update_State"),
              "callee identity must be preserved");
      Assert (Consumer.Set_Count (Consumer.Rows_For_Object (Model, "State")) = 1,
              "object lookup must preserve flow object identity");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "flow consumers reject failed refined conformance");
      Register_Routine (T, Test_Queries'Access, "flow consumer lookups preserve refined blockers");
   end Register_Tests;

end Test_Ada_Flow_Refinement_Consumer_Legality_Pass1155;
