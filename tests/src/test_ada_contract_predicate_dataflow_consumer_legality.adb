with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

use type Editor.Ada_Syntax_Tree.Node_Id;

package body Test_Ada_Contract_Predicate_Dataflow_Consumer_Legality is

   package CPD renames Editor.Ada_Contract_Predicate_Dataflow_Consumer_Legality;
   use type CPD.Contract_Predicate_Row_Id;
   use type CPD.Contract_Predicate_Status;
   use type CPD.Contract_Predicate_Context_Info;
   use type CPD.Contract_Predicate_Info;
   use type CPD.Contract_Predicate_Context_Model;
   use type CPD.Contract_Predicate_Set;
   use type CPD.Contract_Predicate_Model;
   package CAL renames Editor.Ada_Contract_Aspect_Legality;
   use type CAL.Assignment_Legality_Status;
   use type CAL.Return_Legality_Status;
   use type CAL.Static_Legality_Status;
   use type CAL.Accessibility_Legality_Status;
   use type CAL.Overload_Legality_Status;
   use type CAL.Cross_Unit_Semantic_Status;
   use type CAL.Contract_Context_Id;
   use type CAL.Contract_Legality_Id;
   use type CAL.Contract_Context_Kind;
   use type CAL.Contract_Subject_Kind;
   use type CAL.Boolean_Expression_State;
   use type CAL.Aspect_Placement;
   use type CAL.Flow_Contract_State;
   use type CAL.Contract_Legality_Status;
   use type CAL.Contract_Context_Info;
   use type CAL.Contract_Legality_Info;
   use type CAL.Contract_Context_Model;
   use type CAL.Contract_Result_Set;
   use type CAL.Contract_Legality_Model;
   package PDC renames Editor.Ada_Predicate_Dataflow_Initialization_Consumer_Legality;
   use type PDC.Predicate_Dataflow_Row_Id;
   use type PDC.Predicate_Dataflow_Status;
   use type PDC.Predicate_Dataflow_Context_Info;
   use type PDC.Predicate_Dataflow_Info;
   use type PDC.Predicate_Dataflow_Context_Model;
   use type PDC.Predicate_Dataflow_Set;
   use type PDC.Predicate_Dataflow_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Contract_Predicate_Dataflow_Consumer_Legality");
   end Name;

   function Sample_Context_Model return CPD.Contract_Predicate_Context_Model is
      Contexts : CPD.Contract_Predicate_Context_Model;
      C        : CPD.Contract_Predicate_Context_Info;
   begin
      C.Id := 1;
      C.Kind := CAL.Contract_Context_Precondition;
      C.Subject := CAL.Contract_Subject_Subprogram;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116701);
      C.Name := To_Unbounded_String ("Pre_Ready");
      C.Contract_Row := CAL.Contract_Legality_Id (1);
      C.Contract_Status := CAL.Contract_Legality_Legal_Precondition;
      C.Predicate_Dataflow_Row := PDC.Predicate_Dataflow_Row_Id (1);
      C.Predicate_Dataflow_Status := PDC.Predicate_Dataflow_Legal_Static_Predicate_Accepted;
      C.Predicate_Dataflow_Matches := 1;
      C.Requires_Predicate_Evidence := True;
      C.Source_Fingerprint := 1701;
      CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := CAL.Contract_Context_Postcondition;
      C.Subject := CAL.Contract_Subject_Subprogram;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116702);
      C.Name := To_Unbounded_String ("Post_Uses_Unwritten");
      C.Contract_Row := CAL.Contract_Legality_Id (2);
      C.Contract_Status := CAL.Contract_Legality_Legal_Postcondition;
      C.Predicate_Dataflow_Row := PDC.Predicate_Dataflow_Row_Id (2);
      C.Predicate_Dataflow_Status := PDC.Predicate_Dataflow_Read_Before_Write_Blocker;
      C.Predicate_Dataflow_Matches := 1;
      C.Requires_Initialization_Evidence := True;
      C.Source_Fingerprint := 1702;
      CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := CAL.Contract_Context_Type_Invariant;
      C.Subject := CAL.Contract_Subject_Type;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116703);
      C.Name := To_Unbounded_String ("Invariant_Representation");
      C.Contract_Status := CAL.Contract_Legality_Legal_Invariant;
      C.Predicate_Dataflow_Row := PDC.Predicate_Dataflow_Row_Id (3);
      C.Predicate_Dataflow_Status := PDC.Predicate_Dataflow_Discriminant_Representation_Blocker;
      C.Predicate_Dataflow_Matches := 1;
      C.Requires_Invariant_Evidence := True;
      C.Source_Fingerprint := 1703;
      CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := CAL.Contract_Context_Static_Predicate;
      C.Subject := CAL.Contract_Subject_Subtype;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116704);
      C.Name := To_Unbounded_String ("Static_Predicate_Bad_Base");
      C.Contract_Status := CAL.Contract_Legality_Static_Predicate_Failed;
      C.Predicate_Dataflow_Row := PDC.Predicate_Dataflow_Row_Id (4);
      C.Predicate_Dataflow_Status := PDC.Predicate_Dataflow_Legal_Static_Predicate_Accepted;
      C.Predicate_Dataflow_Matches := 1;
      C.Requires_Predicate_Evidence := True;
      C.Source_Fingerprint := 1704;
      CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := CAL.Contract_Context_Dynamic_Predicate;
      C.Subject := CAL.Contract_Subject_Subtype;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116705);
      C.Name := To_Unbounded_String ("Dynamic_Predicate_Missing");
      C.Contract_Status := CAL.Contract_Legality_Legal_Predicate;
      C.Predicate_Dataflow_Row := PDC.No_Predicate_Dataflow_Row;
      C.Predicate_Dataflow_Matches := 0;
      C.Requires_Predicate_Evidence := True;
      C.Source_Fingerprint := 1705;
      CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := CAL.Contract_Context_Refined_Global;
      C.Subject := CAL.Contract_Subject_Package;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116706);
      C.Name := To_Unbounded_String ("Refined_Global_State");
      C.Contract_Status := CAL.Contract_Legality_Legal_Flow_Aspect;
      C.Predicate_Dataflow_Row := PDC.Predicate_Dataflow_Row_Id (6);
      C.Predicate_Dataflow_Status := PDC.Predicate_Dataflow_Global_Blocker;
      C.Predicate_Dataflow_Matches := 1;
      C.Requires_Flow_Evidence := True;
      C.Source_Fingerprint := 1706;
      CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := CAL.Contract_Context_Refined_Depends;
      C.Subject := CAL.Contract_Subject_Package;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116707);
      C.Name := To_Unbounded_String ("Refined_Depends_Edge");
      C.Contract_Status := CAL.Contract_Legality_Legal_Flow_Aspect;
      C.Predicate_Dataflow_Row := PDC.Predicate_Dataflow_Row_Id (7);
      C.Predicate_Dataflow_Status := PDC.Predicate_Dataflow_Depends_Blocker;
      C.Predicate_Dataflow_Matches := 1;
      C.Requires_Flow_Evidence := True;
      C.Source_Fingerprint := 1707;
      CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := CAL.Contract_Context_Assertion;
      C.Subject := CAL.Contract_Subject_Subprogram;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116708);
      C.Name := To_Unbounded_String ("Assert_Coverage");
      C.Contract_Status := CAL.Contract_Legality_Legal_Assertion;
      C.Predicate_Dataflow_Row := PDC.Predicate_Dataflow_Row_Id (8);
      C.Predicate_Dataflow_Status := PDC.Predicate_Dataflow_Coverage_Blocker;
      C.Predicate_Dataflow_Matches := 1;
      C.Requires_Predicate_Evidence := True;
      C.Source_Fingerprint := 1708;
      CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := CAL.Contract_Context_Contract_Case;
      C.Subject := CAL.Contract_Subject_Subprogram;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116709);
      C.Name := To_Unbounded_String ("Case_Propagation_Error");
      C.Contract_Status := CAL.Contract_Legality_Legal_Contract_Case;
      C.Predicate_Dataflow_Row := PDC.Predicate_Dataflow_Row_Id (9);
      C.Predicate_Dataflow_Status := PDC.Predicate_Dataflow_Base_Predicate_Propagation_Error;
      C.Predicate_Dataflow_Matches := 1;
      C.Requires_Predicate_Evidence := True;
      C.Source_Fingerprint := 1709;
      CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := CAL.Contract_Context_Depends_Aspect;
      C.Subject := CAL.Contract_Subject_Subprogram;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116710);
      C.Name := To_Unbounded_String ("Depends_Call_Propagation");
      C.Contract_Status := CAL.Contract_Legality_Legal_Flow_Aspect;
      C.Predicate_Dataflow_Row := PDC.Predicate_Dataflow_Row_Id (10);
      C.Predicate_Dataflow_Status := PDC.Predicate_Dataflow_Call_Propagation_Blocker;
      C.Predicate_Dataflow_Matches := 1;
      C.Requires_Flow_Evidence := True;
      C.Source_Fingerprint := 1710;
      CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := CAL.Contract_Context_Global_Aspect;
      C.Subject := CAL.Contract_Subject_Task;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116711);
      C.Name := To_Unbounded_String ("Task_Global");
      C.Contract_Status := CAL.Contract_Legality_Legal_Flow_Aspect;
      C.Predicate_Dataflow_Row := PDC.Predicate_Dataflow_Row_Id (11);
      C.Predicate_Dataflow_Status := PDC.Predicate_Dataflow_Tasking_Protected_Blocker;
      C.Predicate_Dataflow_Matches := 1;
      C.Requires_Flow_Evidence := True;
      C.Source_Fingerprint := 1711;
      CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := CAL.Contract_Context_Postcondition;
      C.Subject := CAL.Contract_Subject_Subprogram;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116712);
      C.Name := To_Unbounded_String ("Post_Indeterminate");
      C.Contract_Status := CAL.Contract_Legality_Legal_Postcondition;
      C.Predicate_Dataflow_Row := PDC.Predicate_Dataflow_Row_Id (12);
      C.Predicate_Dataflow_Status := PDC.Predicate_Dataflow_Indeterminate;
      C.Predicate_Dataflow_Matches := 1;
      C.Requires_Initialization_Evidence := True;
      C.Source_Fingerprint := 1712;
      CPD.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant CPD.Contract_Predicate_Model := CPD.Build (Sample_Context_Model);
   begin
      Assert (CPD.Row_Count (Model) = 12, "expected twelve contract predicate/dataflow rows");
      Assert (CPD.Legal_Count (Model) = 1, "only the precondition should remain confident");
      Assert (CPD.Count_Status (Model, CPD.Contract_Predicate_Read_Before_Write_Blocker) = 1,
              "read-before-write must block postconditions");
      Assert (CPD.Count_Status (Model, CPD.Contract_Predicate_Discriminant_Representation_Blocker) = 1,
              "discriminant/representation blockers must block invariants");
      Assert (CPD.Count_Status (Model, CPD.Contract_Predicate_Base_Contract_Error) = 1,
              "base static predicate errors must be preserved");
      Assert (CPD.Count_Status (Model, CPD.Contract_Predicate_Missing_Predicate_Dataflow_Row) = 1,
              "missing predicate/dataflow evidence must be explicit");
      Assert (CPD.Count_Status (Model, CPD.Contract_Predicate_Global_Blocker) = 1,
              "Global blockers must affect refined Global contracts");
      Assert (CPD.Count_Status (Model, CPD.Contract_Predicate_Depends_Blocker) = 1,
              "Depends blockers must affect refined Depends contracts");
      Assert (CPD.Count_Status (Model, CPD.Contract_Predicate_Coverage_Blocker) = 1,
              "coverage blockers must be preserved");
      Assert (CPD.Count_Status (Model, CPD.Contract_Predicate_Base_Predicate_Propagation_Error) = 1,
              "predicate propagation errors must block contract cases");
      Assert (CPD.Count_Status (Model, CPD.Contract_Predicate_Call_Propagation_Blocker) = 1,
              "call-propagation blockers must affect Depends aspects");
      Assert (CPD.Count_Status (Model, CPD.Contract_Predicate_Tasking_Protected_Blocker) = 1,
              "tasking/protected blockers must affect Global aspects");
      Assert (CPD.Indeterminate_Count (Model) = 1, "one indeterminate contract row expected");
      Assert (CPD.Initialization_Error_Count (Model) = 1, "one initialization-side blocker expected");
      Assert (CPD.Dataflow_Error_Count (Model) = 5, "five dataflow-side blockers expected");
      Assert (CPD.Coverage_Error_Count (Model) = 1, "one coverage blocker expected");
      Assert (CPD.Error_Count (Model) = 10, "ten rows should be concrete errors");
      Assert (CPD.Fingerprint (Model) /= 0, "model fingerprint must be deterministic and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant CPD.Contract_Predicate_Model := CPD.Build (Sample_Context_Model);
      Row   : constant CPD.Contract_Predicate_Info :=
        CPD.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (116706));
      Set   : constant CPD.Contract_Predicate_Set := CPD.Rows_For_Name (Model, "Task_Global");
   begin
      Assert (Row.Status = CPD.Contract_Predicate_Global_Blocker,
              "node lookup must preserve refined Global blocker");
      Assert (CPD.Set_Count (Set) = 1, "name lookup should find Task_Global row");
      Assert (CPD.Set_At (Set, 1).Node = Editor.Ada_Syntax_Tree.Node_Id (116711),
              "name lookup should return the task Global row");
      Assert (CPD.Count_Kind (Model, CAL.Contract_Context_Postcondition) = 2,
              "postcondition contract contexts should be counted");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Statuses'Access, "contract predicate dataflow statuses");
      Register_Routine
        (T, Test_Queries'Access, "contract predicate dataflow queries");
   end Register_Tests;

end Test_Ada_Contract_Predicate_Dataflow_Consumer_Legality;
