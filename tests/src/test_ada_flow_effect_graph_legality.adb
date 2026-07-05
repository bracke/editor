with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package body Test_Ada_Flow_Effect_Graph_Legality is

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
   package FEG renames Editor.Ada_Flow_Effect_Graph_Legality;
   use type FEG.Flow_Edge_Id;
   use type FEG.Flow_Graph_Context_Kind;
   use type FEG.Flow_Edge_Kind;
   use type FEG.Flow_Effect_Graph_Status;
   use type FEG.Flow_Effect_Context_Info;
   use type FEG.Flow_Effect_Info;
   use type FEG.Flow_Effect_Context_Model;
   use type FEG.Flow_Effect_Set;
   use type FEG.Flow_Effect_Graph_Model;
   package Gates renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;
   use type Gates.Enforcement_Row_Id;
   use type Gates.Widened_Legality_Engine;
   use type Gates.Enforcement_Status;
   use type Gates.Enforcement_Context_Info;
   use type Gates.Enforcement_Info;
   use type Gates.Enforcement_Context_Model;
   use type Gates.Enforcement_Set;
   use type Gates.Enforcement_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Flow_Effect_Graph_Legality");
   end Name;

   function Sample_Context_Model return FEG.Flow_Effect_Context_Model is
      Contexts : FEG.Flow_Effect_Context_Model;
      C        : FEG.Flow_Effect_Context_Info;
   begin
      C.Id := 1;
      C.Kind := FEG.Flow_Context_Subprogram_Spec;
      C.Edge := FEG.Flow_Edge_Object_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113801);
      C.Object_Name := To_Unbounded_String ("Config");
      C.Spec_Global_Mode := DGL.Global_Mode_In;
      C.Reads_Object := True;
      C.Source_Fingerprint := 801;
      FEG.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := FEG.Flow_Context_Subprogram_Body;
      C.Edge := FEG.Flow_Edge_Object_Write;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113802);
      C.Object_Name := To_Unbounded_String ("State");
      C.Spec_Global_Mode := DGL.Global_Mode_In;
      C.Body_Global_Mode := DGL.Global_Mode_Out;
      C.Writes_Object := True;
      C.Source_Fingerprint := 802;
      FEG.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := FEG.Flow_Context_Call;
      C.Edge := FEG.Flow_Edge_Call_Propagation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113803);
      C.Caller_Name := To_Unbounded_String ("Caller");
      C.Callee_Name := To_Unbounded_String ("Callee");
      C.Spec_Global_Mode := DGL.Global_Mode_In_Out;
      C.Reads_Object := True;
      C.Writes_Object := True;
      C.Effect_Propagated := False;
      C.Source_Fingerprint := 803;
      FEG.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := FEG.Flow_Context_Generic_Formal_Actual;
      C.Edge := FEG.Flow_Edge_Generic_Substitution;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113804);
      C.Formal_Name := To_Unbounded_String ("Formal_State");
      C.Actual_Name := To_Unbounded_String ("Actual_State");
      C.Spec_Global_Mode := DGL.Global_Mode_In_Out;
      C.Body_Global_Mode := DGL.Global_Mode_In;
      C.Effect_Propagated := True;
      C.Source_Fingerprint := 804;
      FEG.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := FEG.Flow_Context_Protected_Function;
      C.Edge := FEG.Flow_Edge_Protected_State;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113805);
      C.Object_Name := To_Unbounded_String ("Protected_State");
      C.Spec_Global_Mode := DGL.Global_Mode_In_Out;
      C.Writes_Object := True;
      C.Protected_Function := True;
      C.Source_Fingerprint := 805;
      FEG.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := FEG.Flow_Context_Task_Body;
      C.Edge := FEG.Flow_Edge_Task_Activation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113806);
      C.Object_Name := To_Unbounded_String ("Activation_State");
      C.Spec_Global_Mode := DGL.Global_Mode_Not_Declared;
      C.Reads_Object := True;
      C.Task_Activation := True;
      C.Source_Fingerprint := 806;
      FEG.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := FEG.Flow_Context_Refined_Depends;
      C.Edge := FEG.Flow_Edge_Depends;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113807);
      C.Source_Name := To_Unbounded_String ("Input");
      C.Target_Name := To_Unbounded_String ("Output");
      C.Source_Global_Mode := DGL.Global_Mode_Out;
      C.Target_Global_Mode := DGL.Global_Mode_Out;
      C.Source_Fingerprint := 807;
      FEG.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := FEG.Flow_Context_Subprogram_Body;
      C.Edge := FEG.Flow_Edge_Object_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113808);
      C.Object_Name := To_Unbounded_String ("Unparsed");
      C.Spec_Global_Mode := DGL.Global_Mode_In;
      C.Reads_Object := True;
      C.Gate_Status := Gates.Enforcement_Parser_AST_Blocker;
      C.Source_Fingerprint := 808;
      FEG.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Flow_Graph_Deepens_Global_Depends_Effects
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant FEG.Flow_Effect_Graph_Model := FEG.Build (Sample_Context_Model);
      Read_Row : constant FEG.Flow_Effect_Info :=
        FEG.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113801));
      Body_Row : constant FEG.Flow_Effect_Info :=
        FEG.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113802));
      Call_Row : constant FEG.Flow_Effect_Info :=
        FEG.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113803));
      Generic_Row : constant FEG.Flow_Effect_Info :=
        FEG.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113804));
      Protected_Row : constant FEG.Flow_Effect_Info :=
        FEG.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113805));
      Task_Row : constant FEG.Flow_Effect_Info :=
        FEG.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113806));
      Depends_Row : constant FEG.Flow_Effect_Info :=
        FEG.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113807));
      Gate_Row : constant FEG.Flow_Effect_Info :=
        FEG.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (113808));
   begin
      Assert (FEG.Row_Count (Model) = 8,
              "all explicit flow-effect graph edges should be analyzed");
      Assert (Read_Row.Status = FEG.Flow_Graph_Legal_Read_Edge,
              "Global input should cover object reads");
      Assert (Body_Row.Status = FEG.Flow_Graph_Write_To_In_Global,
              "body write through input-only Global should be rejected");
      Assert (Call_Row.Status = FEG.Flow_Graph_Call_Effect_Not_Propagated,
              "callee effects must propagate into caller effect graph");
      Assert (Generic_Row.Status = FEG.Flow_Graph_Generic_Actual_Mode_Mismatch,
              "generic actual effect mode should satisfy formal effect mode");
      Assert (Protected_Row.Status = FEG.Flow_Graph_Protected_Function_Writes_State,
              "protected functions may not write protected state");
      Assert (Task_Row.Status = FEG.Flow_Graph_Read_Not_In_Global,
              "task activation effects still require Global coverage");
      Assert (Depends_Row.Status = FEG.Flow_Graph_Refined_Depends_Source_Not_Input,
              "Depends source must be a Global input");
      Assert (Gate_Row.Status = FEG.Flow_Graph_Coverage_Gate_Blocker,
              "coverage gates should block confident flow conclusions");
      Assert (FEG.Legal_Count (Model) = 1,
              "one row should remain a confident legal flow edge");
      Assert (FEG.Global_Error_Count (Model) = 2,
              "write and task activation coverage errors should count as Global errors");
      Assert (FEG.Depends_Error_Count (Model) = 1,
              "invalid Depends source should count as Depends error");
      Assert (FEG.Propagation_Error_Count (Model) = 1,
              "call propagation failure should be counted");
      Assert (FEG.Generic_Error_Count (Model) = 1,
              "generic effect substitution mismatch should be counted");
      Assert (FEG.Tasking_Protected_Error_Count (Model) = 1,
              "protected state write failure should be counted");
      Assert (FEG.Coverage_Gate_Error_Count (Model) = 1,
              "coverage gate blocker should be counted");
      Assert (FEG.Fingerprint (Model) /= 0,
              "flow graph model should have a deterministic non-zero fingerprint");
   end Flow_Graph_Deepens_Global_Depends_Effects;

   procedure Dataflow_Rows_Are_Converted_To_Flow_Graph_Edges
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : DGL.Dataflow_Context_Model;
      C        : DGL.Dataflow_Context_Info;
   begin
      C.Id := 1;
      C.Kind := DGL.Dataflow_Context_Subprogram;
      C.Effect := DGL.Dataflow_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113821);
      C.Object_Name := To_Unbounded_String ("Config");
      C.Declared_Global_Mode := DGL.Global_Mode_In;
      C.Reads_Object := True;
      DGL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := DGL.Dataflow_Context_Subprogram;
      C.Effect := DGL.Dataflow_Effect_Write;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113822);
      C.Object_Name := To_Unbounded_String ("Hidden");
      C.Declared_Global_Mode := DGL.Global_Mode_Not_Declared;
      C.Writes_Object := True;
      DGL.Add_Context (Contexts, C);

      declare
         Dataflow : constant DGL.Dataflow_Legality_Model := DGL.Build (Contexts);
         Graph    : constant FEG.Flow_Effect_Graph_Model := FEG.Build_From_Dataflow (Dataflow);
         Read_Row : constant FEG.Flow_Effect_Info :=
           FEG.First_For_Node (Graph, Editor.Ada_Syntax_Tree.Node_Id (113821));
         Write_Row : constant FEG.Flow_Effect_Info :=
           FEG.First_For_Node (Graph, Editor.Ada_Syntax_Tree.Node_Id (113822));
      begin
         Assert (FEG.Row_Count (Graph) = 2,
                 "dataflow rows should become flow-effect graph edges");
         Assert (Read_Row.Edge = FEG.Flow_Edge_Object_Read,
                 "read dataflow row should map to object-read graph edge");
         Assert (Write_Row.Status = FEG.Flow_Graph_Linked_Dataflow_Error,
                 "dataflow error should be preserved as a linked flow graph blocker");
         Assert (FEG.Linked_Error_Count (Graph) = 1,
                 "linked dataflow blocker should be counted");
      end;
   end Dataflow_Rows_Are_Converted_To_Flow_Graph_Edges;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Flow_Graph_Deepens_Global_Depends_Effects'Access,
         "flow graph deepens Global/Depends read/write/call/generic/task effects");
      Register_Routine
        (T,
         Dataflow_Rows_Are_Converted_To_Flow_Graph_Edges'Access,
         "Case 1123 dataflow rows are converted into flow graph edges");
   end Register_Tests;

end Test_Ada_Flow_Effect_Graph_Legality;
