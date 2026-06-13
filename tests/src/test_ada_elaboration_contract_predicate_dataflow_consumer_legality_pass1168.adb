with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Elaboration_Graph_Closure_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality_Pass1168 is

   package ECP renames Editor.Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality;
   use type ECP.Elaboration_Contract_Predicate_Row_Id;
   use type ECP.Elaboration_Contract_Predicate_Context_Kind;
   use type ECP.Elaboration_Contract_Predicate_Status;
   use type ECP.Elaboration_Contract_Predicate_Context_Info;
   use type ECP.Elaboration_Contract_Predicate_Info;
   use type ECP.Elaboration_Contract_Predicate_Context_Model;
   use type ECP.Elaboration_Contract_Predicate_Set;
   use type ECP.Elaboration_Contract_Predicate_Model;
   package CPD renames Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
   use type CPD.Contract_Predicate_Row_Id;
   use type CPD.Contract_Predicate_Status;
   use type CPD.Contract_Predicate_Context_Info;
   use type CPD.Contract_Predicate_Info;
   use type CPD.Contract_Predicate_Context_Model;
   use type CPD.Contract_Predicate_Set;
   use type CPD.Contract_Predicate_Model;
   package EGC renames Editor.Ada_Elaboration_Graph_Closure_Legality;
   use type EGC.Elaboration_Graph_Edge_Id;
   use type EGC.Elaboration_Graph_Context_Kind;
   use type EGC.Elaboration_Graph_Closure_Status;
   use type EGC.Elaboration_Graph_Context_Info;
   use type EGC.Elaboration_Graph_Closure_Info;
   use type EGC.Elaboration_Graph_Context_Model;
   use type EGC.Elaboration_Graph_Result_Set;
   use type EGC.Elaboration_Graph_Closure_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality_Pass1168");
   end Name;

   function Sample_Context_Model return ECP.Elaboration_Contract_Predicate_Context_Model is
      Contexts : ECP.Elaboration_Contract_Predicate_Context_Model;
      C        : ECP.Elaboration_Contract_Predicate_Context_Info;
   begin
      C.Id := 1;
      C.Kind := ECP.Elaboration_Contract_Predicate_Direct_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116801);
      C.Source_Unit_Name := To_Unbounded_String ("Pkg.Body_Info");
      C.Target_Unit_Name := To_Unbounded_String ("Pkg.Callee");
      C.Graph_Row := EGC.Elaboration_Graph_Edge_Id (1);
      C.Graph_Status := EGC.Graph_Closure_Legal_Direct_Call_Order;
      C.Contract_Predicate_Row := CPD.Contract_Predicate_Row_Id (1);
      C.Contract_Predicate_Status := CPD.Contract_Predicate_Legal_Precondition_Accepted;
      C.Contract_Predicate_Matches := 1;
      C.Contract_Name := To_Unbounded_String ("Pre_Ready");
      C.Source_Fingerprint := 16801;
      ECP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := ECP.Elaboration_Contract_Predicate_Default_Expression;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116802);
      C.Graph_Row := EGC.Elaboration_Graph_Edge_Id (2);
      C.Graph_Status := EGC.Graph_Closure_Legal_Default_Expression_Order;
      C.Contract_Predicate_Row := CPD.Contract_Predicate_Row_Id (2);
      C.Contract_Predicate_Status := CPD.Contract_Predicate_Read_Before_Write_Blocker;
      C.Contract_Predicate_Matches := 1;
      C.Contract_Name := To_Unbounded_String ("Default_Reads_Unwritten");
      C.Source_Fingerprint := 16802;
      ECP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := ECP.Elaboration_Contract_Predicate_Aspect_Expression;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116803);
      C.Graph_Row := EGC.Elaboration_Graph_Edge_Id (3);
      C.Graph_Status := EGC.Graph_Closure_Legal_Aspect_Expression_Order;
      C.Contract_Predicate_Row := CPD.Contract_Predicate_Row_Id (3);
      C.Contract_Predicate_Status := CPD.Contract_Predicate_Base_Predicate_Propagation_Error;
      C.Contract_Predicate_Matches := 1;
      C.Contract_Name := To_Unbounded_String ("Aspect_Predicate");
      C.Source_Fingerprint := 16803;
      ECP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := ECP.Elaboration_Contract_Predicate_Representation_Item;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116804);
      C.Graph_Row := EGC.Elaboration_Graph_Edge_Id (4);
      C.Graph_Status := EGC.Graph_Closure_Legal_Representation_Item_Order;
      C.Contract_Predicate_Row := CPD.Contract_Predicate_Row_Id (4);
      C.Contract_Predicate_Status := CPD.Contract_Predicate_Global_Blocker;
      C.Contract_Predicate_Matches := 1;
      C.Contract_Name := To_Unbounded_String ("Representation_Global");
      C.Source_Fingerprint := 16804;
      ECP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := ECP.Elaboration_Contract_Predicate_Generic_Instance;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116805);
      C.Graph_Row := EGC.Elaboration_Graph_Edge_Id (5);
      C.Graph_Status := EGC.Graph_Closure_Legal_Generic_Instance_Order;
      C.Contract_Predicate_Row := CPD.Contract_Predicate_Row_Id (5);
      C.Contract_Predicate_Status := CPD.Contract_Predicate_Discriminant_Representation_Blocker;
      C.Contract_Predicate_Matches := 1;
      C.Contract_Name := To_Unbounded_String ("Generic_Invariant");
      C.Source_Fingerprint := 16805;
      ECP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := ECP.Elaboration_Contract_Predicate_Preelaboration_Policy;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116806);
      C.Graph_Row := EGC.Elaboration_Graph_Edge_Id (6);
      C.Graph_Status := EGC.Graph_Closure_Legal_Preelaboration_Policy;
      C.Contract_Predicate_Row := CPD.Contract_Predicate_Row_Id (6);
      C.Contract_Predicate_Status := CPD.Contract_Predicate_Coverage_Blocker;
      C.Contract_Predicate_Matches := 1;
      C.Contract_Name := To_Unbounded_String ("Preelab_Coverage");
      C.Source_Fingerprint := 16806;
      ECP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := ECP.Elaboration_Contract_Predicate_Task_Activation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116807);
      C.Graph_Row := EGC.Elaboration_Graph_Edge_Id (7);
      C.Graph_Status := EGC.Graph_Closure_Legal_Direct_Call_Order;
      C.Contract_Predicate_Row := CPD.Contract_Predicate_Row_Id (7);
      C.Contract_Predicate_Status := CPD.Contract_Predicate_Tasking_Protected_Blocker;
      C.Contract_Predicate_Matches := 1;
      C.Contract_Name := To_Unbounded_String ("Task_Global");
      C.Source_Fingerprint := 16807;
      ECP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := ECP.Elaboration_Contract_Predicate_Indirect_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116808);
      C.Graph_Row := EGC.Elaboration_Graph_Edge_Id (8);
      C.Graph_Status := EGC.Graph_Closure_Direct_Call_Before_Body;
      C.Contract_Predicate_Row := CPD.Contract_Predicate_Row_Id (8);
      C.Contract_Predicate_Status := CPD.Contract_Predicate_Legal_Postcondition_Accepted;
      C.Contract_Predicate_Matches := 1;
      C.Contract_Name := To_Unbounded_String ("Base_Elab_Error");
      C.Source_Fingerprint := 16808;
      ECP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := ECP.Elaboration_Contract_Predicate_Dispatching_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116809);
      C.Graph_Row := EGC.Elaboration_Graph_Edge_Id (9);
      C.Graph_Status := EGC.Graph_Closure_Legal_Dispatching_Call_Order;
      C.Contract_Predicate_Row := CPD.No_Contract_Predicate_Row;
      C.Contract_Predicate_Matches := 0;
      C.Contract_Name := To_Unbounded_String ("Missing_Contract_Predicate");
      C.Source_Fingerprint := 16809;
      ECP.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := ECP.Elaboration_Contract_Predicate_Pure_Policy;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116810);
      C.Graph_Row := EGC.Elaboration_Graph_Edge_Id (10);
      C.Graph_Status := EGC.Graph_Closure_Legal_Pure_Policy;
      C.Contract_Predicate_Row := CPD.Contract_Predicate_Row_Id (10);
      C.Contract_Predicate_Status := CPD.Contract_Predicate_Indeterminate;
      C.Contract_Predicate_Matches := 1;
      C.Contract_Name := To_Unbounded_String ("Pure_Indeterminate");
      C.Source_Fingerprint := 16810;
      ECP.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant ECP.Elaboration_Contract_Predicate_Model := ECP.Build (Sample_Context_Model);
   begin
      Assert (ECP.Row_Count (Model) = 10, "expected ten elaboration contract predicate/dataflow rows");
      Assert (ECP.Legal_Count (Model) = 1, "only the direct call should remain confident");
      Assert (ECP.Count_Status (Model, ECP.Elaboration_Contract_Predicate_Read_Before_Write_Blocker) = 1,
              "read-before-write must block elaboration defaults");
      Assert (ECP.Count_Status (Model, ECP.Elaboration_Contract_Predicate_Base_Predicate_Propagation_Error) = 1,
              "predicate propagation must block elaboration aspects");
      Assert (ECP.Count_Status (Model, ECP.Elaboration_Contract_Predicate_Global_Blocker) = 1,
              "Global blockers must affect representation elaboration");
      Assert (ECP.Count_Status (Model, ECP.Elaboration_Contract_Predicate_Discriminant_Representation_Blocker) = 1,
              "discriminant/representation blockers must affect generic instances");
      Assert (ECP.Count_Status (Model, ECP.Elaboration_Contract_Predicate_Coverage_Blocker) = 1,
              "coverage blockers must be preserved for policy contexts");
      Assert (ECP.Count_Status (Model, ECP.Elaboration_Contract_Predicate_Tasking_Protected_Blocker) = 1,
              "tasking blockers must affect task activation");
      Assert (ECP.Count_Status (Model, ECP.Elaboration_Contract_Predicate_Base_Elaboration_Error) = 1,
              "base elaboration graph errors must be preserved");
      Assert (ECP.Count_Status (Model, ECP.Elaboration_Contract_Predicate_Missing_Contract_Predicate_Row) = 1,
              "missing contract predicate rows must be explicit");
      Assert (ECP.Indeterminate_Count (Model) = 1, "indeterminate contract predicate evidence must remain indeterminate");
      Assert (ECP.Initialization_Error_Count (Model) = 1, "initialization blockers must be counted");
      Assert (ECP.Predicate_Error_Count (Model) = 2, "predicate/discriminant blockers must be counted");
      Assert (ECP.Dataflow_Error_Count (Model) = 2, "Global/tasking dataflow blockers must be counted");
      Assert (ECP.Coverage_Error_Count (Model) = 1, "coverage blockers must be counted");
      Assert (ECP.Policy_Error_Count (Model) = 2, "policy-sensitive failures must be counted");
      Assert (ECP.Fingerprint (Model) /= 0, "fingerprint should be stable and non-zero");
   end Test_Statuses;

   procedure Test_Lookups (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant ECP.Elaboration_Contract_Predicate_Model := ECP.Build (Sample_Context_Model);
      By_Status : constant ECP.Elaboration_Contract_Predicate_Set :=
        ECP.Rows_For_Status (Model, ECP.Elaboration_Contract_Predicate_Global_Blocker);
      By_Kind : constant ECP.Elaboration_Contract_Predicate_Set :=
        ECP.Rows_For_Kind (Model, ECP.Elaboration_Contract_Predicate_Representation_Item);
      Found : constant ECP.Elaboration_Contract_Predicate_Info :=
        ECP.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (116804));
   begin
      Assert (ECP.Set_Count (By_Status) = 1, "status lookup should find Global blocker");
      Assert (ECP.Set_Count (By_Kind) = 1, "kind lookup should find representation item");
      Assert (Found.Status = ECP.Elaboration_Contract_Predicate_Global_Blocker,
              "node lookup should preserve blocker status");
      Assert (ECP.Set_At (By_Status, 1).Contract_Name = To_Unbounded_String ("Representation_Global"),
              "status set should preserve contract name");
   end Test_Lookups;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "elaboration contract predicate/dataflow statuses");
      Register_Routine (T, Test_Lookups'Access, "elaboration contract predicate/dataflow lookups");
   end Register_Tests;

end Test_Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality_Pass1168;
