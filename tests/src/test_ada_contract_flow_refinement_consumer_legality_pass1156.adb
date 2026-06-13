with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Contract_Aspect_Legality;
with Editor.Ada_Contract_Flow_Refinement_Consumer_Legality;
with Editor.Ada_Flow_Refinement_Consumer_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Contract_Flow_Refinement_Consumer_Legality_Pass1156 is

   package Contracts renames Editor.Ada_Contract_Aspect_Legality;
   use type Contracts.Assignment_Legality_Status;
   use type Contracts.Return_Legality_Status;
   use type Contracts.Static_Legality_Status;
   use type Contracts.Accessibility_Legality_Status;
   use type Contracts.Overload_Legality_Status;
   use type Contracts.Cross_Unit_Semantic_Status;
   use type Contracts.Contract_Context_Id;
   use type Contracts.Contract_Legality_Id;
   use type Contracts.Contract_Context_Kind;
   use type Contracts.Contract_Subject_Kind;
   use type Contracts.Boolean_Expression_State;
   use type Contracts.Aspect_Placement;
   use type Contracts.Flow_Contract_State;
   use type Contracts.Contract_Legality_Status;
   use type Contracts.Contract_Context_Info;
   use type Contracts.Contract_Legality_Info;
   use type Contracts.Contract_Context_Model;
   use type Contracts.Contract_Result_Set;
   use type Contracts.Contract_Legality_Model;
   package Contract_Flow renames Editor.Ada_Contract_Flow_Refinement_Consumer_Legality;
   use type Contract_Flow.Contract_Flow_Row_Id;
   use type Contract_Flow.Contract_Flow_Context_Kind;
   use type Contract_Flow.Contract_Flow_Status;
   use type Contract_Flow.Contract_Flow_Context_Info;
   use type Contract_Flow.Contract_Flow_Info;
   use type Contract_Flow.Contract_Flow_Context_Model;
   use type Contract_Flow.Contract_Flow_Set;
   use type Contract_Flow.Contract_Flow_Model;
   package Flow_Consumers renames Editor.Ada_Flow_Refinement_Consumer_Legality;
   use type Flow_Consumers.Consumer_Row_Id;
   use type Flow_Consumers.Consumer_Kind;
   use type Flow_Consumers.Consumer_Effect_Kind;
   use type Flow_Consumers.Consumer_Status;
   use type Flow_Consumers.Consumer_Context_Info;
   use type Flow_Consumers.Consumer_Info;
   use type Flow_Consumers.Consumer_Context_Model;
   use type Flow_Consumers.Consumer_Set;
   use type Flow_Consumers.Consumer_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Contract_Flow_Refinement_Consumer_Legality_Pass1156");
   end Name;

   function Sample_Context_Model return Contract_Flow.Contract_Flow_Context_Model is
      Contexts : Contract_Flow.Contract_Flow_Context_Model;
      C        : Contract_Flow.Contract_Flow_Context_Info;
   begin
      C.Id := 1;
      C.Kind := Contract_Flow.Contract_Flow_Refined_Global;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115601);
      C.Object_Name := To_Unbounded_String ("Config");
      C.Contract_Row := Contracts.Contract_Legality_Id (1);
      C.Contract_Status := Contracts.Contract_Legality_Legal_Flow_Aspect;
      C.Contract_Flow_State := Contracts.Flow_Contract_Resolved;
      C.Consumer_Row := Flow_Consumers.Consumer_Row_Id (1);
      C.Consumer_Status := Flow_Consumers.Consumer_Legal_Flow_Edge_Accepted;
      C.Consumer_Matches := 1;
      C.Source_Fingerprint := 601;
      Contract_Flow.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := Contract_Flow.Contract_Flow_Refined_Global;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115602);
      C.Object_Name := To_Unbounded_String ("State");
      C.Contract_Row := Contracts.Contract_Legality_Id (2);
      C.Contract_Status := Contracts.Contract_Legality_Legal_Flow_Aspect;
      C.Contract_Flow_State := Contracts.Flow_Contract_Resolved;
      C.Consumer_Row := Flow_Consumers.Consumer_Row_Id (2);
      C.Consumer_Status := Flow_Consumers.Consumer_Refined_Global_Missing_Write;
      C.Consumer_Matches := 1;
      C.Source_Fingerprint := 602;
      Contract_Flow.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := Contract_Flow.Contract_Flow_Refined_Depends;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115603);
      C.Source_Name := To_Unbounded_String ("Input");
      C.Target_Name := To_Unbounded_String ("Output");
      C.Contract_Row := Contracts.Contract_Legality_Id (3);
      C.Contract_Status := Contracts.Contract_Legality_Legal_Flow_Aspect;
      C.Contract_Flow_State := Contracts.Flow_Contract_Resolved;
      C.Consumer_Row := Flow_Consumers.Consumer_Row_Id (3);
      C.Consumer_Status := Flow_Consumers.Consumer_Refined_Depends_Missing_Edge;
      C.Consumer_Matches := 1;
      C.Source_Fingerprint := 603;
      Contract_Flow.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := Contract_Flow.Contract_Flow_Call_Propagation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115604);
      C.Caller_Name := To_Unbounded_String ("Driver");
      C.Callee_Name := To_Unbounded_String ("Update_State");
      C.Contract_Row := Contracts.Contract_Legality_Id (4);
      C.Contract_Status := Contracts.Contract_Legality_Legal_Flow_Aspect;
      C.Contract_Flow_State := Contracts.Flow_Contract_Resolved;
      C.Consumer_Row := Flow_Consumers.Consumer_Row_Id (4);
      C.Consumer_Status := Flow_Consumers.Consumer_Call_Effect_Not_Propagated;
      C.Consumer_Matches := 1;
      C.Source_Fingerprint := 604;
      Contract_Flow.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := Contract_Flow.Contract_Flow_Generic_Instance;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115605);
      C.Object_Name := To_Unbounded_String ("Actual_State");
      C.Contract_Row := Contracts.Contract_Legality_Id (5);
      C.Contract_Status := Contracts.Contract_Legality_Legal_Flow_Aspect;
      C.Consumer_Row := Flow_Consumers.Consumer_Row_Id (5);
      C.Consumer_Status := Flow_Consumers.Consumer_Coverage_Feedback_Blocker;
      C.Consumer_Matches := 1;
      C.Source_Fingerprint := 605;
      Contract_Flow.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := Contract_Flow.Contract_Flow_Global;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115606);
      C.Contract_Row := Contracts.Contract_Legality_Id (6);
      C.Contract_Status := Contracts.Contract_Legality_Flow_Illegal_Refinement;
      C.Consumer_Row := Flow_Consumers.Consumer_Row_Id (6);
      C.Consumer_Status := Flow_Consumers.Consumer_Legal_Flow_Edge_Accepted;
      C.Consumer_Matches := 1;
      C.Source_Fingerprint := 606;
      Contract_Flow.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := Contract_Flow.Contract_Flow_Depends;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115607);
      C.Contract_Row := Contracts.Contract_Legality_Id (7);
      C.Contract_Status := Contracts.Contract_Legality_Legal_Flow_Aspect;
      C.Consumer_Row := Flow_Consumers.No_Consumer_Row;
      C.Consumer_Status := Flow_Consumers.Consumer_Not_Checked;
      C.Consumer_Matches := 0;
      C.Source_Fingerprint := 607;
      Contract_Flow.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Contract_Flow.Contract_Flow_Model := Contract_Flow.Build (Sample_Context_Model);
   begin
      Assert (Contract_Flow.Row_Count (Model) = 7, "expected seven contract flow consumer rows");
      Assert (Contract_Flow.Legal_Count (Model) = 1, "only repaired/refined Global row should be accepted");
      Assert (Contract_Flow.Count_Status (Model, Contract_Flow.Contract_Flow_Refined_Global_Missing_Write) = 1,
              "missing Refined_Global write must invalidate contract flow legality");
      Assert (Contract_Flow.Count_Status (Model, Contract_Flow.Contract_Flow_Refined_Depends_Missing_Edge) = 1,
              "missing Refined_Depends edge must invalidate contract flow legality");
      Assert (Contract_Flow.Count_Status (Model, Contract_Flow.Contract_Flow_Call_Effect_Not_Propagated) = 1,
              "unpropagated call effects must invalidate contract flow legality");
      Assert (Contract_Flow.Count_Status (Model, Contract_Flow.Contract_Flow_Coverage_Feedback_Blocker) = 1,
              "coverage feedback blockers must remain contract blockers");
      Assert (Contract_Flow.Count_Status (Model, Contract_Flow.Contract_Flow_Base_Contract_Error) = 1,
              "pre-existing contract errors must be preserved");
      Assert (Contract_Flow.Count_Status (Model, Contract_Flow.Contract_Flow_Missing_Consumer_Row) = 1,
              "legal flow aspect without consumer evidence must not be accepted");
      Assert (Contract_Flow.Global_Error_Count (Model) = 1, "expected one refined Global consumer error");
      Assert (Contract_Flow.Depends_Error_Count (Model) = 1, "expected one refined Depends consumer error");
      Assert (Contract_Flow.Propagation_Error_Count (Model) = 1, "expected one call propagation error");
      Assert (Contract_Flow.Coverage_Error_Count (Model) = 1, "expected one coverage feedback error");
      Assert (Contract_Flow.Fingerprint (Model) /= 0, "model fingerprint must be stable and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Contract_Flow.Contract_Flow_Model := Contract_Flow.Build (Sample_Context_Model);
      Row   : constant Contract_Flow.Contract_Flow_Info :=
        Contract_Flow.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115604));
      Set   : constant Contract_Flow.Contract_Flow_Set :=
        Contract_Flow.Rows_For_Kind (Model, Contract_Flow.Contract_Flow_Refined_Global);
   begin
      Assert (Row.Status = Contract_Flow.Contract_Flow_Call_Effect_Not_Propagated,
              "node lookup must preserve call propagation blocker");
      Assert (Contract_Flow.Set_Count (Set) = 2, "two Refined_Global contract rows expected");
      Assert (Contract_Flow.Set_Count (Contract_Flow.Rows_For_Object (Model, "State")) = 1,
              "object lookup must preserve refined Global object identity");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "contract flow aspects consume refined-flow legality");
      Register_Routine (T, Test_Queries'Access, "contract flow consumer lookups preserve blockers");
   end Register_Tests;

end Test_Ada_Contract_Flow_Refinement_Consumer_Legality_Pass1156;
