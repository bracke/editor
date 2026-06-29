with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Contract_Flow_Refinement_Consumer_Legality;
with Editor.Ada_Elaboration_Contract_Flow_Consumer_Legality;
with Editor.Ada_Elaboration_Graph_Closure_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Elaboration_Contract_Flow_Consumer_Legality is

   package Contract_Flow renames Editor.Ada_Contract_Flow_Refinement_Consumer_Legality;
   use type Contract_Flow.Contract_Flow_Row_Id;
   use type Contract_Flow.Contract_Flow_Context_Kind;
   use type Contract_Flow.Contract_Flow_Status;
   use type Contract_Flow.Contract_Flow_Context_Info;
   use type Contract_Flow.Contract_Flow_Info;
   use type Contract_Flow.Contract_Flow_Context_Model;
   use type Contract_Flow.Contract_Flow_Set;
   use type Contract_Flow.Contract_Flow_Model;
   package Elab_Contract renames Editor.Ada_Elaboration_Contract_Flow_Consumer_Legality;
   use type Elab_Contract.Elaboration_Contract_Flow_Row_Id;
   use type Elab_Contract.Elaboration_Contract_Flow_Context_Kind;
   use type Elab_Contract.Elaboration_Contract_Flow_Status;
   use type Elab_Contract.Elaboration_Contract_Flow_Context_Info;
   use type Elab_Contract.Elaboration_Contract_Flow_Info;
   use type Elab_Contract.Elaboration_Contract_Flow_Context_Model;
   use type Elab_Contract.Elaboration_Contract_Flow_Set;
   use type Elab_Contract.Elaboration_Contract_Flow_Model;
   package Graph renames Editor.Ada_Elaboration_Graph_Closure_Legality;
   use type Graph.Elaboration_Graph_Edge_Id;
   use type Graph.Elaboration_Graph_Context_Kind;
   use type Graph.Elaboration_Graph_Closure_Status;
   use type Graph.Elaboration_Graph_Context_Info;
   use type Graph.Elaboration_Graph_Closure_Info;
   use type Graph.Elaboration_Graph_Context_Model;
   use type Graph.Elaboration_Graph_Result_Set;
   use type Graph.Elaboration_Graph_Closure_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Elaboration_Contract_Flow_Consumer_Legality");
   end Name;

   function Sample_Context_Model return Elab_Contract.Elaboration_Contract_Flow_Context_Model is
      Contexts : Elab_Contract.Elaboration_Contract_Flow_Context_Model;
      C        : Elab_Contract.Elaboration_Contract_Flow_Context_Info;
   begin
      C.Id := 1;
      C.Kind := Elab_Contract.Elaboration_Contract_Flow_Direct_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115701);
      C.Source_Unit_Name := To_Unbounded_String ("Driver");
      C.Target_Unit_Name := To_Unbounded_String ("Worker");
      C.Graph_Row := Graph.Elaboration_Graph_Edge_Id (1);
      C.Graph_Status := Graph.Graph_Closure_Legal_Direct_Call_Order;
      C.Contract_Flow_Row := Contract_Flow.Contract_Flow_Row_Id (1);
      C.Contract_Flow_Status := Contract_Flow.Contract_Flow_Legal_Call_Propagation_Accepted;
      C.Contract_Flow_Matches := 1;
      C.Source_Fingerprint := 701;
      Elab_Contract.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := Elab_Contract.Elaboration_Contract_Flow_Direct_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115702);
      C.Source_Unit_Name := To_Unbounded_String ("Driver");
      C.Target_Unit_Name := To_Unbounded_String ("Update_State");
      C.Graph_Row := Graph.Elaboration_Graph_Edge_Id (2);
      C.Graph_Status := Graph.Graph_Closure_Legal_Direct_Call_Order;
      C.Contract_Flow_Row := Contract_Flow.Contract_Flow_Row_Id (2);
      C.Contract_Flow_Status := Contract_Flow.Contract_Flow_Refined_Global_Missing_Write;
      C.Contract_Flow_Matches := 1;
      C.Source_Fingerprint := 702;
      Elab_Contract.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := Elab_Contract.Elaboration_Contract_Flow_Aspect_Expression;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115703);
      C.Source_Unit_Name := To_Unbounded_String ("Spec");
      C.Target_Unit_Name := To_Unbounded_String ("State");
      C.Graph_Row := Graph.Elaboration_Graph_Edge_Id (3);
      C.Graph_Status := Graph.Graph_Closure_Legal_Aspect_Expression_Order;
      C.Contract_Flow_Row := Contract_Flow.Contract_Flow_Row_Id (3);
      C.Contract_Flow_Status := Contract_Flow.Contract_Flow_Refined_Depends_Missing_Edge;
      C.Contract_Flow_Matches := 1;
      C.Source_Fingerprint := 703;
      Elab_Contract.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := Elab_Contract.Elaboration_Contract_Flow_Generic_Instance;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115704);
      C.Source_Unit_Name := To_Unbounded_String ("Instantiate");
      C.Target_Unit_Name := To_Unbounded_String ("Generic_Body");
      C.Graph_Row := Graph.Elaboration_Graph_Edge_Id (4);
      C.Graph_Status := Graph.Graph_Closure_Legal_Generic_Instance_Order;
      C.Contract_Flow_Row := Contract_Flow.Contract_Flow_Row_Id (4);
      C.Contract_Flow_Status := Contract_Flow.Contract_Flow_Call_Effect_Not_Propagated;
      C.Contract_Flow_Matches := 1;
      C.Source_Fingerprint := 704;
      Elab_Contract.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := Elab_Contract.Elaboration_Contract_Flow_Representation_Item;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115705);
      C.Graph_Row := Graph.Elaboration_Graph_Edge_Id (5);
      C.Graph_Status := Graph.Graph_Closure_Legal_Representation_Item_Order;
      C.Contract_Flow_Row := Contract_Flow.Contract_Flow_Row_Id (5);
      C.Contract_Flow_Status := Contract_Flow.Contract_Flow_Coverage_Feedback_Blocker;
      C.Contract_Flow_Matches := 1;
      C.Source_Fingerprint := 705;
      Elab_Contract.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := Elab_Contract.Elaboration_Contract_Flow_Preelaboration_Policy;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115706);
      C.Graph_Row := Graph.Elaboration_Graph_Edge_Id (6);
      C.Graph_Status := Graph.Graph_Closure_Legal_Preelaboration_Policy;
      C.Contract_Flow_Row := Contract_Flow.Contract_Flow_Row_Id (6);
      C.Contract_Flow_Status := Contract_Flow.Contract_Flow_Consumer_Indeterminate;
      C.Contract_Flow_Matches := 1;
      C.Source_Fingerprint := 706;
      Elab_Contract.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := Elab_Contract.Elaboration_Contract_Flow_Default_Expression;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115707);
      C.Graph_Row := Graph.Elaboration_Graph_Edge_Id (7);
      C.Graph_Status := Graph.Graph_Closure_Direct_Call_Before_Body;
      C.Contract_Flow_Row := Contract_Flow.Contract_Flow_Row_Id (7);
      C.Contract_Flow_Status := Contract_Flow.Contract_Flow_Legal_Global_Aspect_Accepted;
      C.Contract_Flow_Matches := 1;
      C.Source_Fingerprint := 707;
      Elab_Contract.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := Elab_Contract.Elaboration_Contract_Flow_Indirect_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115708);
      C.Graph_Row := Graph.Elaboration_Graph_Edge_Id (8);
      C.Graph_Status := Graph.Graph_Closure_Legal_Indirect_Call_Order;
      C.Contract_Flow_Row := Contract_Flow.No_Contract_Flow_Row;
      C.Contract_Flow_Status := Contract_Flow.Contract_Flow_Not_Checked;
      C.Contract_Flow_Matches := 0;
      C.Source_Fingerprint := 708;
      Elab_Contract.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Elab_Contract.Elaboration_Contract_Flow_Model :=
        Elab_Contract.Build (Sample_Context_Model);
   begin
      Assert (Elab_Contract.Row_Count (Model) = 8, "expected eight elaboration contract-flow rows");
      Assert (Elab_Contract.Legal_Count (Model) = 1, "only the call with accepted refined-flow evidence should remain legal");
      Assert (Elab_Contract.Count_Status (Model, Elab_Contract.Elaboration_Contract_Flow_Refined_Global_Missing_Write) = 1,
              "elaboration call must consume missing Refined_Global write blocker");
      Assert (Elab_Contract.Count_Status (Model, Elab_Contract.Elaboration_Contract_Flow_Refined_Depends_Missing_Edge) = 1,
              "aspect-expression elaboration must consume missing Refined_Depends edge blocker");
      Assert (Elab_Contract.Count_Status (Model, Elab_Contract.Elaboration_Contract_Flow_Call_Effect_Not_Propagated) = 1,
              "generic instance elaboration must consume unpropagated call-effect blocker");
      Assert (Elab_Contract.Count_Status (Model, Elab_Contract.Elaboration_Contract_Flow_Coverage_Feedback_Blocker) = 1,
              "representation item elaboration must preserve repaired coverage blockers");
      Assert (Elab_Contract.Count_Status (Model, Elab_Contract.Elaboration_Contract_Flow_Contract_Flow_Indeterminate) = 1,
              "policy-sensitive elaboration must preserve indeterminate refined-flow state");
      Assert (Elab_Contract.Count_Status (Model, Elab_Contract.Elaboration_Contract_Flow_Base_Elaboration_Error) = 1,
              "base elaboration errors must not be hidden by legal contract-flow rows");
      Assert (Elab_Contract.Count_Status (Model, Elab_Contract.Elaboration_Contract_Flow_Missing_Contract_Flow_Row) = 1,
              "legal elaboration edge without contract-flow evidence must not remain confident");
      Assert (Elab_Contract.Global_Error_Count (Model) = 1, "expected one refined Global elaboration blocker");
      Assert (Elab_Contract.Depends_Error_Count (Model) = 1, "expected one refined Depends elaboration blocker");
      Assert (Elab_Contract.Propagation_Error_Count (Model) = 1, "expected one call-propagation elaboration blocker");
      Assert (Elab_Contract.Coverage_Error_Count (Model) = 1, "expected one coverage blocker");
      Assert (Elab_Contract.Policy_Error_Count (Model) = 1, "expected one policy-sensitive refined-flow blocker");
      Assert (Elab_Contract.Fingerprint (Model) /= 0, "model fingerprint must be deterministic and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Elab_Contract.Elaboration_Contract_Flow_Model :=
        Elab_Contract.Build (Sample_Context_Model);
      Row   : constant Elab_Contract.Elaboration_Contract_Flow_Info :=
        Elab_Contract.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115704));
      Set   : constant Elab_Contract.Elaboration_Contract_Flow_Set :=
        Elab_Contract.Rows_For_Kind (Model, Elab_Contract.Elaboration_Contract_Flow_Direct_Call);
   begin
      Assert (Row.Status = Elab_Contract.Elaboration_Contract_Flow_Call_Effect_Not_Propagated,
              "node lookup must preserve generic-instance call-propagation blocker");
      Assert (Elab_Contract.Set_Count (Set) = 2, "two direct-call-style rows are expected");
      Assert (Elab_Contract.Set_Count (Elab_Contract.Rows_For_Unit (Model, "Driver")) = 2,
              "unit lookup must preserve source/target elaboration unit identity");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "elaboration consumes contract-flow refinement blockers");
      Register_Routine (T, Test_Queries'Access, "elaboration contract-flow lookups preserve blockers");
   end Register_Tests;

end Test_Ada_Elaboration_Contract_Flow_Consumer_Legality;
