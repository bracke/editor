with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Definite_Initialization_Object_Flow_Consumer_Legality;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Dataflow_Definite_Initialization_Consumer_Legality is

   package DIC renames Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
   use type DIC.Dataflow_Init_Row_Id;
   use type DIC.Dataflow_Init_Status;
   use type DIC.Dataflow_Init_Context_Info;
   use type DIC.Dataflow_Init_Info;
   use type DIC.Dataflow_Init_Context_Model;
   use type DIC.Dataflow_Init_Set;
   use type DIC.Dataflow_Init_Model;
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
   package IOF renames Editor.Ada_Definite_Initialization_Object_Flow_Consumer_Legality;
   use type IOF.Initialization_Object_Flow_Row_Id;
   use type IOF.Initialization_Object_Flow_Status;
   use type IOF.Initialization_Object_Flow_Context_Info;
   use type IOF.Initialization_Object_Flow_Info;
   use type IOF.Initialization_Object_Flow_Context_Model;
   use type IOF.Initialization_Object_Flow_Set;
   use type IOF.Initialization_Object_Flow_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Dataflow_Definite_Initialization_Consumer_Legality");
   end Name;

   function Sample_Context_Model return DIC.Dataflow_Init_Context_Model is
      Contexts : DIC.Dataflow_Init_Context_Model;
      C        : DIC.Dataflow_Init_Context_Info;
   begin
      C.Id := 1;
      C.Kind := DGL.Dataflow_Context_Subprogram;
      C.Effect := DGL.Dataflow_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116501);
      C.Object_Name := To_Unbounded_String ("Ready_Input");
      C.Dataflow_Row := DGL.Dataflow_Legality_Id (1);
      C.Dataflow_Status := DGL.Dataflow_Legality_Legal_Read;
      C.Flow_Edge_Row := FEG.Flow_Edge_Id (1);
      C.Flow_Status := FEG.Flow_Graph_Legal_Read_Edge;
      C.Flow_Edge := FEG.Flow_Edge_Object_Read;
      C.Flow_Matches := 1;
      C.Initialization_Row := IOF.Initialization_Object_Flow_Row_Id (1);
      C.Initialization_Status := IOF.Initialization_Object_Flow_Legal_Definite_Init_Accepted;
      C.Initialization_Matches := 1;
      C.Reads_Object := True;
      C.Source_Fingerprint := 1501;
      C.Dataflow_Fingerprint := 2501;
      C.Flow_Fingerprint := 3501;
      C.Initialization_Fingerprint := 4501;
      DIC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := DGL.Dataflow_Context_Subprogram;
      C.Effect := DGL.Dataflow_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116502);
      C.Object_Name := To_Unbounded_String ("Before_Write");
      C.Dataflow_Status := DGL.Dataflow_Legality_Legal_Read;
      C.Flow_Edge_Row := FEG.Flow_Edge_Id (2);
      C.Flow_Status := FEG.Flow_Graph_Legal_Read_Edge;
      C.Flow_Edge := FEG.Flow_Edge_Object_Read;
      C.Flow_Matches := 1;
      C.Initialization_Row := IOF.Initialization_Object_Flow_Row_Id (2);
      C.Initialization_Status := IOF.Initialization_Object_Flow_Preserved_Read_Before_Write;
      C.Initialization_Matches := 1;
      C.Reads_Object := True;
      C.Source_Fingerprint := 1502;
      DIC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := DGL.Dataflow_Context_Subprogram;
      C.Effect := DGL.Dataflow_Effect_Write;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116503);
      C.Object_Name := To_Unbounded_String ("Out_Result");
      C.Dataflow_Status := DGL.Dataflow_Legality_Legal_Write;
      C.Flow_Edge_Row := FEG.Flow_Edge_Id (3);
      C.Flow_Status := FEG.Flow_Graph_Legal_Write_Edge;
      C.Flow_Edge := FEG.Flow_Edge_Object_Write;
      C.Flow_Matches := 1;
      C.Initialization_Row := IOF.Initialization_Object_Flow_Row_Id (3);
      C.Initialization_Status := IOF.Initialization_Object_Flow_Preserved_Out_Parameter_Not_Assigned;
      C.Initialization_Matches := 1;
      C.Writes_Object := True;
      C.Source_Fingerprint := 1503;
      DIC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := DGL.Dataflow_Context_Entry;
      C.Effect := DGL.Dataflow_Effect_Depends_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116504);
      C.Source_Name := To_Unbounded_String ("Source_A");
      C.Target_Name := To_Unbounded_String ("Target_B");
      C.Dataflow_Status := DGL.Dataflow_Legality_Legal_Depends_Edge;
      C.Flow_Edge_Row := FEG.Flow_Edge_Id (4);
      C.Flow_Status := FEG.Flow_Graph_Refined_Depends_Missing_Source;
      C.Flow_Edge := FEG.Flow_Edge_Depends;
      C.Flow_Matches := 1;
      C.Source_Fingerprint := 1504;
      DIC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := DGL.Dataflow_Context_Protected_Operation;
      C.Effect := DGL.Dataflow_Effect_Read_Write;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116505);
      C.Object_Name := To_Unbounded_String ("Protected_State");
      C.Dataflow_Status := DGL.Dataflow_Legality_Legal_Read_Write;
      C.Flow_Edge_Row := FEG.Flow_Edge_Id (5);
      C.Flow_Status := FEG.Flow_Graph_Protected_Function_Writes_State;
      C.Flow_Edge := FEG.Flow_Edge_Protected_State;
      C.Flow_Matches := 1;
      C.Tasking_Protected_Effect := True;
      C.Source_Fingerprint := 1505;
      DIC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := DGL.Dataflow_Context_Statement;
      C.Effect := DGL.Dataflow_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116506);
      C.Object_Name := To_Unbounded_String ("Missing_Init");
      C.Dataflow_Status := DGL.Dataflow_Legality_Legal_Read;
      C.Flow_Edge_Row := FEG.Flow_Edge_Id (6);
      C.Flow_Status := FEG.Flow_Graph_Legal_Read_Edge;
      C.Flow_Edge := FEG.Flow_Edge_Object_Read;
      C.Flow_Matches := 1;
      C.Reads_Object := True;
      C.Initialization_Row := IOF.No_Initialization_Object_Flow_Row;
      C.Initialization_Matches := 0;
      C.Source_Fingerprint := 1506;
      DIC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := DGL.Dataflow_Context_Expression;
      C.Effect := DGL.Dataflow_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116507);
      C.Object_Name := To_Unbounded_String ("Dead_Object");
      C.Dataflow_Status := DGL.Dataflow_Legality_Legal_Read;
      C.Flow_Edge_Row := FEG.Flow_Edge_Id (7);
      C.Flow_Status := FEG.Flow_Graph_Legal_Read_Edge;
      C.Flow_Edge := FEG.Flow_Edge_Object_Read;
      C.Flow_Matches := 1;
      C.Initialization_Row := IOF.Initialization_Object_Flow_Row_Id (7);
      C.Initialization_Status := IOF.Initialization_Object_Flow_Preserved_Use_After_Finalization;
      C.Initialization_Matches := 1;
      C.Reads_Object := True;
      C.Source_Fingerprint := 1507;
      DIC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := DGL.Dataflow_Context_Subprogram;
      C.Effect := DGL.Dataflow_Effect_Null;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116508);
      C.Dataflow_Status := DGL.Dataflow_Legality_Legal_Null_Effect;
      C.Flow_Edge_Row := FEG.No_Flow_Edge;
      C.Flow_Status := FEG.Flow_Graph_Not_Checked;
      C.Flow_Matches := 0;
      C.Source_Fingerprint := 1508;
      DIC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := DGL.Dataflow_Context_Generic_Instance;
      C.Effect := DGL.Dataflow_Effect_Refinement;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116509);
      C.Dataflow_Status := DGL.Dataflow_Legality_Read_Not_In_Global;
      C.Source_Fingerprint := 1509;
      DIC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := DGL.Dataflow_Context_Generic_Instance;
      C.Effect := DGL.Dataflow_Effect_Refinement;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116510);
      C.Dataflow_Status := DGL.Dataflow_Legality_Legal_Refinement;
      C.Flow_Edge_Row := FEG.No_Flow_Edge;
      C.Flow_Status := FEG.Flow_Graph_Not_Checked;
      C.Flow_Matches := 0;
      C.Source_Fingerprint := 1510;
      DIC.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant DIC.Dataflow_Init_Model := DIC.Build (Sample_Context_Model);
   begin
      Assert (DIC.Row_Count (Model) = 10, "expected ten dataflow initialization consumer rows");
      Assert (DIC.Legal_Count (Model) = 2, "clean read and null effect should remain confident");
      Assert (DIC.Count_Status (Model, DIC.Dataflow_Init_Read_Before_Write_Blocker) = 1,
              "read-before-write must block Global read flow");
      Assert (DIC.Count_Status (Model, DIC.Dataflow_Init_Out_Parameter_Not_Assigned_Blocker) = 1,
              "out-parameter obligations must block write flow");
      Assert (DIC.Count_Status (Model, DIC.Dataflow_Init_Flow_Depends_Blocker) = 1,
              "Refined_Depends flow blockers must be preserved");
      Assert (DIC.Count_Status (Model, DIC.Dataflow_Init_Flow_Tasking_Protected_Blocker) = 1,
              "tasking/protected flow blockers must be preserved");
      Assert (DIC.Count_Status (Model, DIC.Dataflow_Init_Missing_Initialization_Object_Flow_Row) = 1,
              "missing initialization evidence must be explicit");
      Assert (DIC.Count_Status (Model, DIC.Dataflow_Init_Use_After_Finalization_Blocker) = 1,
              "use-after-finalization must block dataflow use");
      Assert (DIC.Count_Status (Model, DIC.Dataflow_Init_Base_Dataflow_Error) = 1,
              "base dataflow errors must be preserved");
      Assert (DIC.Count_Status (Model, DIC.Dataflow_Init_Missing_Flow_Edge_Row) = 1,
              "missing flow graph rows must block refinement consumers");
      Assert (DIC.Flow_Error_Count (Model) = 3, "three flow graph blockers expected");
      Assert (DIC.Initialization_Error_Count (Model) = 4, "four initialization blockers expected");
      Assert (DIC.Error_Count (Model) = 8, "eight rows should be hard blocked");
      Assert (DIC.Fingerprint (Model) /= 0, "model fingerprint must be deterministic and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant DIC.Dataflow_Init_Model := DIC.Build (Sample_Context_Model);
      Row   : constant DIC.Dataflow_Init_Info :=
        DIC.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (116502));
      Set   : constant DIC.Dataflow_Init_Set := DIC.Rows_For_Object (Model, "Before_Write");
   begin
      Assert (Row.Status = DIC.Dataflow_Init_Read_Before_Write_Blocker,
              "node lookup must preserve initialization blocker");
      Assert (DIC.Set_Count (Set) = 1, "object lookup must preserve dataflow row");
      Assert (DIC.Count_Kind (Model, DGL.Dataflow_Context_Subprogram) = 4,
              "kind lookup must preserve all subprogram rows");
      Assert (DIC.Set_Count (DIC.Rows_For_Status (Model, DIC.Dataflow_Init_Missing_Flow_Edge_Row)) = 1,
              "status lookup must preserve missing flow edge blocker");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "dataflow consumers require definite initialization evidence");
      Register_Routine (T, Test_Queries'Access, "dataflow initialization consumer lookups preserve blockers");
   end Register_Tests;

end Test_Ada_Dataflow_Definite_Initialization_Consumer_Legality;
