with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
with Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality;
with Editor.Ada_Predicate_Invariant_Propagation_Legality;
with Editor.Ada_Syntax_Tree;
use type Editor.Ada_Syntax_Tree.Node_Id;

package body Test_Ada_Predicate_Dataflow_Initialization_Consumer_Legality is

   package PDC renames Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality;
   use type PDC.Predicate_Dataflow_Row_Id;
   use type PDC.Predicate_Dataflow_Status;
   use type PDC.Predicate_Dataflow_Context_Info;
   use type PDC.Predicate_Dataflow_Info;
   use type PDC.Predicate_Dataflow_Context_Model;
   use type PDC.Predicate_Dataflow_Set;
   use type PDC.Predicate_Dataflow_Model;
   package DIC renames Editor.Ada_Dataflow_Definite_Initialization_Consumer_Legality;
   use type DIC.Dataflow_Init_Row_Id;
   use type DIC.Dataflow_Init_Status;
   use type DIC.Dataflow_Init_Context_Info;
   use type DIC.Dataflow_Init_Info;
   use type DIC.Dataflow_Init_Context_Model;
   use type DIC.Dataflow_Init_Set;
   use type DIC.Dataflow_Init_Model;
   package PIP renames Editor.Ada_Predicate_Invariant_Propagation_Legality;
   use type PIP.Propagation_Row_Id;
   use type PIP.Propagation_Context_Kind;
   use type PIP.Propagation_Obligation_Kind;
   use type PIP.Propagation_Status;
   use type PIP.Propagation_Context_Info;
   use type PIP.Propagation_Info;
   use type PIP.Propagation_Context_Model;
   use type PIP.Propagation_Set;
   use type PIP.Propagation_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Predicate_Dataflow_Initialization_Consumer_Legality");
   end Name;

   function Sample_Context_Model return PDC.Predicate_Dataflow_Context_Model is
      Contexts : PDC.Predicate_Dataflow_Context_Model;
      C        : PDC.Predicate_Dataflow_Context_Info;
   begin
      C.Id := 1;
      C.Kind := PIP.Propagation_Context_Assignment;
      C.Obligation := PIP.Obligation_Static_Predicate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116601);
      C.Subtype_Name := To_Unbounded_String ("Positive");
      C.Object_Name := To_Unbounded_String ("Ready_Value");
      C.Propagation_Row := PIP.Propagation_Row_Id (1);
      C.Propagation_Status := PIP.Propagation_Legal_Static_Predicate_Preserved;
      C.Dataflow_Init_Row := DIC.Dataflow_Init_Row_Id (1);
      C.Dataflow_Init_Status := DIC.Dataflow_Init_Legal_Read_Accepted;
      C.Dataflow_Init_Matches := 1;
      C.Requires_Dataflow_State := True;
      C.Source_Fingerprint := 1601;
      C.Propagation_Fingerprint := 2601;
      C.Dataflow_Init_Fingerprint := 3601;
      PDC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := PIP.Propagation_Context_Visible_State_Update;
      C.Obligation := PIP.Obligation_Type_Invariant;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116602);
      C.Object_Name := To_Unbounded_String ("Before_Write");
      C.Propagation_Status := PIP.Propagation_Legal_Invariant_Preserved;
      C.Dataflow_Init_Row := DIC.Dataflow_Init_Row_Id (2);
      C.Dataflow_Init_Status := DIC.Dataflow_Init_Read_Before_Write_Blocker;
      C.Dataflow_Init_Matches := 1;
      C.Requires_Dataflow_State := True;
      C.State_Was_Updated := True;
      C.Source_Fingerprint := 1602;
      PDC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := PIP.Propagation_Context_Return;
      C.Obligation := PIP.Obligation_Dynamic_Invariant;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116603);
      C.Object_Name := To_Unbounded_String ("Result_Object");
      C.Propagation_Status := PIP.Propagation_Legal_Dynamic_Invariant_Propagated;
      C.Dataflow_Init_Row := DIC.Dataflow_Init_Row_Id (3);
      C.Dataflow_Init_Status := DIC.Dataflow_Init_Return_Object_Not_Initialized_Blocker;
      C.Dataflow_Init_Matches := 1;
      C.Requires_Dataflow_State := True;
      C.Dynamic_Check := True;
      C.Source_Fingerprint := 1603;
      PDC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := PIP.Propagation_Context_Call_Source;
      C.Obligation := PIP.Obligation_Call_Chain_Predicate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116604);
      C.Callee_Name := To_Unbounded_String ("Needs_Initialized_Global");
      C.Propagation_Status := PIP.Propagation_Legal_Flow_Effect_Propagated;
      C.Dataflow_Init_Row := DIC.Dataflow_Init_Row_Id (4);
      C.Dataflow_Init_Status := DIC.Dataflow_Init_Flow_Global_Blocker;
      C.Dataflow_Init_Matches := 1;
      C.Flow_Effect_Obligation := True;
      C.Source_Fingerprint := 1604;
      PDC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := PIP.Propagation_Context_Generic_Instance;
      C.Obligation := PIP.Obligation_Generic_Actual_Predicate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116605);
      C.Object_Name := To_Unbounded_String ("Formal_State");
      C.Propagation_Status := PIP.Propagation_Legal_Generic_Substitution_Propagated;
      C.Dataflow_Init_Row := DIC.Dataflow_Init_Row_Id (5);
      C.Dataflow_Init_Status := DIC.Dataflow_Init_Flow_Generic_Blocker;
      C.Dataflow_Init_Matches := 1;
      C.Requires_Dataflow_State := True;
      C.Generic_Obligation := True;
      C.Source_Fingerprint := 1605;
      PDC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := PIP.Propagation_Context_Private_View;
      C.Obligation := PIP.Obligation_Private_View_Invariant;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116606);
      C.Object_Name := To_Unbounded_String ("Private_State");
      C.Propagation_Status := PIP.Propagation_Legal_Private_Full_View_Propagated;
      C.Dataflow_Init_Row := DIC.Dataflow_Init_Row_Id (6);
      C.Dataflow_Init_Status := DIC.Dataflow_Init_Discriminant_Representation_Blocker;
      C.Dataflow_Init_Matches := 1;
      C.Requires_Dataflow_State := True;
      C.Private_View_Obligation := True;
      C.Source_Fingerprint := 1606;
      PDC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := PIP.Propagation_Context_Flow_Effect;
      C.Obligation := PIP.Obligation_State_Update_Invariant;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116607);
      C.Object_Name := To_Unbounded_String ("Missing_Flow_State");
      C.Propagation_Status := PIP.Propagation_Legal_Flow_Effect_Propagated;
      C.Dataflow_Init_Row := DIC.No_Dataflow_Init_Row;
      C.Dataflow_Init_Matches := 0;
      C.Flow_Effect_Obligation := True;
      C.Source_Fingerprint := 1607;
      PDC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := PIP.Propagation_Context_Assignment;
      C.Obligation := PIP.Obligation_Dynamic_Predicate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116608);
      C.Object_Name := To_Unbounded_String ("Coverage_State");
      C.Propagation_Status := PIP.Propagation_Legal_Dynamic_Predicate_Propagated;
      C.Dataflow_Init_Row := DIC.Dataflow_Init_Row_Id (8);
      C.Dataflow_Init_Status := DIC.Dataflow_Init_Coverage_Blocker;
      C.Dataflow_Init_Matches := 1;
      C.Requires_Dataflow_State := True;
      C.Source_Fingerprint := 1608;
      PDC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := PIP.Propagation_Context_Derived_Type;
      C.Obligation := PIP.Obligation_Derived_Type_Invariant;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116609);
      C.Propagation_Status := PIP.Propagation_Invariant_Lost;
      C.Source_Fingerprint := 1609;
      PDC.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := PIP.Propagation_Context_Call_Result;
      C.Obligation := PIP.Obligation_Dynamic_Predicate;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116610);
      C.Object_Name := To_Unbounded_String ("Dead_State");
      C.Propagation_Status := PIP.Propagation_Legal_Dynamic_Predicate_Propagated;
      C.Dataflow_Init_Row := DIC.Dataflow_Init_Row_Id (10);
      C.Dataflow_Init_Status := DIC.Dataflow_Init_Use_After_Finalization_Blocker;
      C.Dataflow_Init_Matches := 1;
      C.Requires_Dataflow_State := True;
      C.Source_Fingerprint := 1610;
      PDC.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant PDC.Predicate_Dataflow_Model := PDC.Build (Sample_Context_Model);
   begin
      Assert (PDC.Row_Count (Model) = 10, "expected ten predicate dataflow consumer rows");
      Assert (PDC.Legal_Count (Model) = 1, "only the initialized static predicate row should remain confident");
      Assert (PDC.Count_Status (Model, PDC.Predicate_Dataflow_Read_Before_Write_Blocker) = 1,
              "read-before-write must block invariant preservation");
      Assert (PDC.Count_Status (Model, PDC.Predicate_Dataflow_Return_Object_Not_Initialized_Blocker) = 1,
              "return object initialization must block invariant propagation");
      Assert (PDC.Count_Status (Model, PDC.Predicate_Dataflow_Global_Blocker) = 1,
              "Global flow blockers must affect predicate call chains");
      Assert (PDC.Count_Status (Model, PDC.Predicate_Dataflow_Generic_Effect_Blocker) = 1,
              "generic flow blockers must affect generic predicate substitutions");
      Assert (PDC.Count_Status (Model, PDC.Predicate_Dataflow_Discriminant_Representation_Blocker) = 1,
              "discriminant/representation blockers must affect private invariants");
      Assert (PDC.Count_Status (Model, PDC.Predicate_Dataflow_Missing_Dataflow_Init_Row) = 1,
              "missing dataflow initialization evidence must be explicit");
      Assert (PDC.Count_Status (Model, PDC.Predicate_Dataflow_Coverage_Blocker) = 1,
              "coverage blockers must be preserved");
      Assert (PDC.Count_Status (Model, PDC.Predicate_Dataflow_Base_Predicate_Propagation_Error) = 1,
              "base predicate propagation errors must be preserved");
      Assert (PDC.Count_Status (Model, PDC.Predicate_Dataflow_Use_After_Finalization_Blocker) = 1,
              "use-after-finalization must block predicate propagation");
      Assert (PDC.Dataflow_Error_Count (Model) = 3, "three dataflow-side blockers expected");
      Assert (PDC.Initialization_Error_Count (Model) = 3, "three initialization-side blockers expected");
      Assert (PDC.Coverage_Error_Count (Model) = 1, "one coverage blocker expected");
      Assert (PDC.Error_Count (Model) = 9, "nine rows should be blocked");
      Assert (PDC.Fingerprint (Model) /= 0, "model fingerprint must be deterministic and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant PDC.Predicate_Dataflow_Model := PDC.Build (Sample_Context_Model);
      Row   : constant PDC.Predicate_Dataflow_Info :=
        PDC.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (116602));
      Set   : constant PDC.Predicate_Dataflow_Set := PDC.Rows_For_Object (Model, "Before_Write");
   begin
      Assert (Row.Status = PDC.Predicate_Dataflow_Read_Before_Write_Blocker,
              "node lookup must preserve read-before-write blocker");
      Assert (PDC.Set_Count (Set) = 1, "object lookup should find Before_Write row");
      Assert (PDC.Set_At (Set, 1).Node = Editor.Ada_Syntax_Tree.Node_Id (116602),
              "object lookup should return the expected node");
      Assert (PDC.Count_Kind (Model, PIP.Propagation_Context_Assignment) = 2,
              "assignment propagation contexts should be counted");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Statuses'Access, "predicate dataflow initialization statuses");
      Register_Routine
        (T, Test_Queries'Access, "predicate dataflow initialization queries");
   end Register_Tests;

end Test_Ada_Predicate_Dataflow_Initialization_Consumer_Legality;
