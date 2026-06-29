with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Refined_Global_Depends_Conformance_Legality;
with Editor.Ada_Repaired_Coverage_Semantic_Feedback;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Refined_Global_Depends_Conformance_Legality is

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
   package Feedback renames Editor.Ada_Repaired_Coverage_Semantic_Feedback;
   use type Feedback.Feedback_Row_Id;
   use type Feedback.Feedback_Status;
   use type Feedback.Feedback_Info;
   use type Feedback.Feedback_Model;
   use type Feedback.Feedback_Set;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Refined_Global_Depends_Conformance_Legality");
   end Name;

   function Sample_Context_Model return Refined.Refined_Context_Model is
      Contexts : Refined.Refined_Context_Model;
      C        : Refined.Refined_Context_Info;
   begin
      C.Id := 1;
      C.Kind := Refined.Refined_Context_Subprogram_Body;
      C.Effect := Refined.Refined_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115301);
      C.Subprogram_Name := To_Unbounded_String ("Load_Config");
      C.Object_Name := To_Unbounded_String ("Config");
      C.Spec_Global_Mode := DGL.Global_Mode_In;
      C.Refined_Global_Mode := DGL.Global_Mode_In;
      C.Reads_Object := True;
      C.Source_Fingerprint := 301;
      Refined.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := Refined.Refined_Context_Subprogram_Body;
      C.Effect := Refined.Refined_Effect_Write;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115302);
      C.Subprogram_Name := To_Unbounded_String ("Update_State");
      C.Object_Name := To_Unbounded_String ("State");
      C.Spec_Global_Mode := DGL.Global_Mode_In;
      C.Refined_Global_Mode := DGL.Global_Mode_In;
      C.Writes_Object := True;
      C.Source_Fingerprint := 302;
      Refined.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := Refined.Refined_Context_Refined_Global_Item;
      C.Effect := Refined.Refined_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115303);
      C.Object_Name := To_Unbounded_String ("Unused");
      C.Spec_Global_Mode := DGL.Global_Mode_In;
      C.Refined_Global_Mode := DGL.Global_Mode_In;
      C.Reads_Object := True;
      C.Refined_Item_Is_Extra := True;
      C.Source_Fingerprint := 303;
      Refined.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := Refined.Refined_Context_Refined_Depends_Edge;
      C.Effect := Refined.Refined_Effect_Depends_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115304);
      C.Source_Name := To_Unbounded_String ("Input");
      C.Target_Name := To_Unbounded_String ("Output");
      C.Source_Global_Mode := DGL.Global_Mode_In;
      C.Target_Global_Mode := DGL.Global_Mode_Out;
      C.Source_Fingerprint := 304;
      Refined.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := Refined.Refined_Context_Refined_Depends_Edge;
      C.Effect := Refined.Refined_Effect_Depends_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115305);
      C.Source_Name := To_Unbounded_String ("Output");
      C.Target_Name := To_Unbounded_String ("Result");
      C.Source_Global_Mode := DGL.Global_Mode_Out;
      C.Target_Global_Mode := DGL.Global_Mode_Out;
      C.Source_Fingerprint := 305;
      Refined.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := Refined.Refined_Context_Refined_Depends_Edge;
      C.Effect := Refined.Refined_Effect_Depends_Edge;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115306);
      C.Source_Name := To_Unbounded_String ("Input");
      C.Target_Name := To_Unbounded_String ("Output");
      C.Source_Global_Mode := DGL.Global_Mode_In;
      C.Target_Global_Mode := DGL.Global_Mode_Out;
      C.Refined_Depends_Present := False;
      C.Source_Fingerprint := 306;
      Refined.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := Refined.Refined_Context_Call_Propagation;
      C.Effect := Refined.Refined_Effect_Call_Propagation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115307);
      C.Effect_Propagated := False;
      C.Source_Fingerprint := 307;
      Refined.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := Refined.Refined_Context_Subprogram_Body;
      C.Effect := Refined.Refined_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115308);
      C.Object_Name := To_Unbounded_String ("Unrepaired");
      C.Spec_Global_Mode := DGL.Global_Mode_In;
      C.Refined_Global_Mode := DGL.Global_Mode_In;
      C.Reads_Object := True;
      C.Coverage_Feedback := Feedback.Feedback_Missing_Repair_Blocker;
      C.Coverage_Eligible := False;
      C.Source_Fingerprint := 308;
      Refined.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := Refined.Refined_Context_Subprogram_Body;
      C.Effect := Refined.Refined_Effect_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115309);
      C.Object_Name := To_Unbounded_String ("Bad_Flow");
      C.Spec_Global_Mode := DGL.Global_Mode_In;
      C.Refined_Global_Mode := DGL.Global_Mode_In;
      C.Reads_Object := True;
      C.Flow_Status := Flow.Flow_Graph_Read_Not_In_Global;
      C.Source_Fingerprint := 309;
      Refined.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Refined_Global_Depends_Conformance_Checks_Body_Spec_Effects
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : constant Refined.Refined_Conformance_Model := Refined.Build (Sample_Context_Model);
      Legal_Global : constant Refined.Refined_Conformance_Info :=
        Refined.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115301));
      Write_Missing : constant Refined.Refined_Conformance_Info :=
        Refined.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115302));
      Extra_Global : constant Refined.Refined_Conformance_Info :=
        Refined.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115303));
      Legal_Depends : constant Refined.Refined_Conformance_Info :=
        Refined.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115304));
      Bad_Source : constant Refined.Refined_Conformance_Info :=
        Refined.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115305));
      Missing_Depends : constant Refined.Refined_Conformance_Info :=
        Refined.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115306));
      Call_Propagation : constant Refined.Refined_Conformance_Info :=
        Refined.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115307));
      Coverage_Block : constant Refined.Refined_Conformance_Info :=
        Refined.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115308));
      Flow_Block : constant Refined.Refined_Conformance_Info :=
        Refined.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115309));
   begin
      Assert (Refined.Row_Count (Model) = 9,
              "all refined Global/Depends contexts should be analyzed");
      Assert (Legal_Global.Status = Refined.Refined_Conformance_Legal_Global_Refinement,
              "body read covered by spec Global and Refined_Global should be legal");
      Assert (Write_Missing.Status = Refined.Refined_Conformance_Body_Write_Missing_From_Spec_Global,
              "body write through input-only spec Global should be rejected");
      Assert (Extra_Global.Status = Refined.Refined_Conformance_Refined_Global_Extra_Item,
              "extra Refined_Global item should be rejected");
      Assert (Legal_Depends.Status = Refined.Refined_Conformance_Legal_Depends_Refinement,
              "Refined_Depends edge with input source and output target should be legal");
      Assert (Bad_Source.Status = Refined.Refined_Conformance_Refined_Depends_Source_Not_Spec_Input,
              "Refined_Depends source must be a spec Global input");
      Assert (Missing_Depends.Status = Refined.Refined_Conformance_Refined_Depends_Missing_Edge,
              "body dependency must be represented in Refined_Depends");
      Assert (Call_Propagation.Status = Refined.Refined_Conformance_Call_Effect_Not_Propagated,
              "call effects must propagate through the body/spec refinement graph");
      Assert (Coverage_Block.Status = Refined.Refined_Conformance_Coverage_Feedback_Blocker,
              "unrepaired coverage feedback should block refined conformance");
      Assert (Flow_Block.Status = Refined.Refined_Conformance_Linked_Flow_Graph_Error,
              "linked flow graph errors should be preserved");
      Assert (Refined.Legal_Count (Model) = 2,
              "two rows should remain legal refined conformance results");
      Assert (Refined.Global_Error_Count (Model) = 2,
              "Global refinement errors should be counted separately");
      Assert (Refined.Depends_Error_Count (Model) = 2,
              "Depends refinement errors should be counted separately");
      Assert (Refined.Coverage_Feedback_Error_Count (Model) = 1,
              "coverage feedback blockers should be counted separately");
      Assert (Refined.Flow_Linked_Error_Count (Model) = 1,
              "linked flow graph errors should be counted separately");
      Assert (Refined.Fingerprint (Model) /= 0,
              "refined conformance model should have a deterministic fingerprint");
   end Refined_Global_Depends_Conformance_Checks_Body_Spec_Effects;

   procedure Flow_Graph_Rows_Are_Converted_To_Refinement_Contexts
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Flow_Contexts : Flow.Flow_Effect_Context_Model;
      C             : Flow.Flow_Effect_Context_Info;
      Empty_Feedback : Feedback.Feedback_Model;
   begin
      C.Id := 1;
      C.Kind := Flow.Flow_Context_Subprogram_Body;
      C.Edge := Flow.Flow_Edge_Object_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115321);
      C.Object_Name := To_Unbounded_String ("Config");
      C.Spec_Global_Mode := DGL.Global_Mode_In;
      C.Reads_Object := True;
      C.Source_Fingerprint := 321;
      Flow.Add_Context (Flow_Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := Flow.Flow_Context_Refined_Depends;
      C.Edge := Flow.Flow_Edge_Depends;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115322);
      C.Source_Name := To_Unbounded_String ("Input");
      C.Target_Name := To_Unbounded_String ("Output");
      C.Source_Global_Mode := DGL.Global_Mode_In;
      C.Target_Global_Mode := DGL.Global_Mode_Out;
      C.Source_Fingerprint := 322;
      Flow.Add_Context (Flow_Contexts, C);

      declare
         Graph : constant Flow.Flow_Effect_Graph_Model := Flow.Build (Flow_Contexts);
         Model : constant Refined.Refined_Conformance_Model :=
           Refined.Build_From_Flow_Graph (Graph, Empty_Feedback);
         Read_Row : constant Refined.Refined_Conformance_Info :=
           Refined.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115321));
         Depends_Row : constant Refined.Refined_Conformance_Info :=
           Refined.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115322));
      begin
         Assert (Refined.Row_Count (Model) = 2,
                 "flow graph rows should become refinement conformance rows");
         Assert (Read_Row.Status = Refined.Refined_Conformance_Legal_Global_Refinement,
                 "legal flow read should convert to legal Global refinement");
         Assert (Depends_Row.Status = Refined.Refined_Conformance_Legal_Depends_Refinement,
                 "legal flow Depends edge should convert to legal Depends refinement");
      end;
   end Flow_Graph_Rows_Are_Converted_To_Refinement_Contexts;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T,
         Refined_Global_Depends_Conformance_Checks_Body_Spec_Effects'Access,
         "Refined_Global and Refined_Depends body/spec conformance checks semantic effects");
      Register_Routine
        (T,
         Flow_Graph_Rows_Are_Converted_To_Refinement_Contexts'Access,
         "flow-effect graph rows feed refined Global/Depends conformance");
   end Register_Tests;

end Test_Ada_Refined_Global_Depends_Conformance_Legality;
