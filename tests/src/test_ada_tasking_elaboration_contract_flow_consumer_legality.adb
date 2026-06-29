with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Elaboration_Contract_Flow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality;
with Editor.Ada_Tasking_Protected_Effects_Legality;

package body Test_Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality is

   package Elab_Contract renames Editor.Ada_Elaboration_Contract_Flow_Consumer_Legality;
   use type Elab_Contract.Elaboration_Contract_Flow_Row_Id;
   use type Elab_Contract.Elaboration_Contract_Flow_Context_Kind;
   use type Elab_Contract.Elaboration_Contract_Flow_Status;
   use type Elab_Contract.Elaboration_Contract_Flow_Context_Info;
   use type Elab_Contract.Elaboration_Contract_Flow_Info;
   use type Elab_Contract.Elaboration_Contract_Flow_Context_Model;
   use type Elab_Contract.Elaboration_Contract_Flow_Set;
   use type Elab_Contract.Elaboration_Contract_Flow_Model;
   package Task_Elab renames Editor.Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality;
   use type Task_Elab.Tasking_Elab_Contract_Row_Id;
   use type Task_Elab.Tasking_Elab_Contract_Context_Kind;
   use type Task_Elab.Tasking_Elab_Contract_Status;
   use type Task_Elab.Tasking_Elab_Contract_Context_Info;
   use type Task_Elab.Tasking_Elab_Contract_Info;
   use type Task_Elab.Tasking_Elab_Contract_Context_Model;
   use type Task_Elab.Tasking_Elab_Contract_Set;
   use type Task_Elab.Tasking_Elab_Contract_Model;
   package Task_Effects renames Editor.Ada_Tasking_Protected_Effects_Legality;
   use type Task_Effects.Tasking_Effect_Id;
   use type Task_Effects.Tasking_Effect_Context_Kind;
   use type Task_Effects.Tasking_Effect_Status;
   use type Task_Effects.Tasking_Effect_Context_Info;
   use type Task_Effects.Tasking_Effect_Info;
   use type Task_Effects.Tasking_Effect_Context_Model;
   use type Task_Effects.Tasking_Effect_Set;
   use type Task_Effects.Tasking_Effect_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality");
   end Name;

   function Sample_Context_Model return Task_Elab.Tasking_Elab_Contract_Context_Model is
      Contexts : Task_Elab.Tasking_Elab_Contract_Context_Model;
      C        : Task_Elab.Tasking_Elab_Contract_Context_Info;
   begin
      C.Id := 1;
      C.Kind := Task_Elab.Tasking_Elab_Contract_Task_Activation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115801);
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (1);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Task_Activation;
      C.Elaboration_Contract_Row := Elab_Contract.Elaboration_Contract_Flow_Row_Id (1);
      C.Elaboration_Contract_Status := Elab_Contract.Elaboration_Contract_Flow_Legal_Task_Activation_Accepted;
      C.Elaboration_Contract_Matches := 1;
      C.Source_Fingerprint := 801;
      Task_Elab.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := Task_Elab.Tasking_Elab_Contract_Protected_Write;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115802);
      C.Object_Name := To_Unbounded_String ("Protected_State");
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (2);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Protected_Write;
      C.Elaboration_Contract_Row := Elab_Contract.Elaboration_Contract_Flow_Row_Id (2);
      C.Elaboration_Contract_Status := Elab_Contract.Elaboration_Contract_Flow_Refined_Global_Missing_Write;
      C.Elaboration_Contract_Matches := 1;
      C.Source_Fingerprint := 802;
      Task_Elab.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := Task_Elab.Tasking_Elab_Contract_Accept_Body;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115803);
      C.Entry_Name := To_Unbounded_String ("Start");
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (3);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Accept_Body;
      C.Elaboration_Contract_Row := Elab_Contract.Elaboration_Contract_Flow_Row_Id (3);
      C.Elaboration_Contract_Status := Elab_Contract.Elaboration_Contract_Flow_Refined_Depends_Missing_Edge;
      C.Elaboration_Contract_Matches := 1;
      C.Source_Fingerprint := 803;
      Task_Elab.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := Task_Elab.Tasking_Elab_Contract_Requeue;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115804);
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (4);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Requeue;
      C.Elaboration_Contract_Row := Elab_Contract.Elaboration_Contract_Flow_Row_Id (4);
      C.Elaboration_Contract_Status := Elab_Contract.Elaboration_Contract_Flow_Call_Effect_Not_Propagated;
      C.Elaboration_Contract_Matches := 1;
      C.Source_Fingerprint := 804;
      Task_Elab.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := Task_Elab.Tasking_Elab_Contract_Select_Alternative;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115805);
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (5);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Select_Alternative;
      C.Elaboration_Contract_Row := Elab_Contract.Elaboration_Contract_Flow_Row_Id (5);
      C.Elaboration_Contract_Status := Elab_Contract.Elaboration_Contract_Flow_Coverage_Feedback_Blocker;
      C.Elaboration_Contract_Matches := 1;
      C.Source_Fingerprint := 805;
      Task_Elab.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := Task_Elab.Tasking_Elab_Contract_Protected_Function_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115806);
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (6);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Protected_Function_Writes_State;
      C.Elaboration_Contract_Row := Elab_Contract.Elaboration_Contract_Flow_Row_Id (6);
      C.Elaboration_Contract_Status := Elab_Contract.Elaboration_Contract_Flow_Legal_Call_Accepted;
      C.Elaboration_Contract_Matches := 1;
      C.Source_Fingerprint := 806;
      Task_Elab.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := Task_Elab.Tasking_Elab_Contract_Delay_Alternative;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115807);
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (7);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Delay_Alternative;
      C.Elaboration_Contract_Row := Elab_Contract.Elaboration_Contract_Flow_Row_Id (7);
      C.Elaboration_Contract_Status := Elab_Contract.Elaboration_Contract_Flow_Contract_Flow_Indeterminate;
      C.Elaboration_Contract_Matches := 1;
      C.Source_Fingerprint := 807;
      Task_Elab.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := Task_Elab.Tasking_Elab_Contract_Protected_Entry_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115808);
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (8);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Protected_Entry_Call;
      C.Elaboration_Contract_Row := Elab_Contract.No_Elaboration_Contract_Flow_Row;
      C.Elaboration_Contract_Status := Elab_Contract.Elaboration_Contract_Flow_Not_Checked;
      C.Elaboration_Contract_Matches := 0;
      C.Source_Fingerprint := 808;
      Task_Elab.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Task_Elab.Tasking_Elab_Contract_Model :=
        Task_Elab.Build (Sample_Context_Model);
   begin
      Assert (Task_Elab.Row_Count (Model) = 8, "expected eight tasking elaboration-contract rows");
      Assert (Task_Elab.Legal_Count (Model) = 1, "only the task activation with accepted elaboration contract-flow should remain legal");
      Assert (Task_Elab.Count_Status (Model, Task_Elab.Tasking_Elab_Contract_Refined_Global_Missing_Write) = 1,
              "protected write must consume missing Refined_Global write blocker");
      Assert (Task_Elab.Count_Status (Model, Task_Elab.Tasking_Elab_Contract_Refined_Depends_Missing_Edge) = 1,
              "accept body must consume missing Refined_Depends edge blocker");
      Assert (Task_Elab.Count_Status (Model, Task_Elab.Tasking_Elab_Contract_Call_Effect_Not_Propagated) = 1,
              "requeue must consume unpropagated call-effect blocker");
      Assert (Task_Elab.Count_Status (Model, Task_Elab.Tasking_Elab_Contract_Coverage_Feedback_Blocker) = 1,
              "select alternative must preserve repaired coverage blocker");
      Assert (Task_Elab.Count_Status (Model, Task_Elab.Tasking_Elab_Contract_Base_Tasking_Effect_Error) = 1,
              "base tasking/protected effect errors must not be hidden by legal elaboration contract-flow");
      Assert (Task_Elab.Count_Status (Model, Task_Elab.Tasking_Elab_Contract_Elaboration_Contract_Indeterminate) = 1,
              "delay alternative must preserve indeterminate elaboration contract-flow");
      Assert (Task_Elab.Count_Status (Model, Task_Elab.Tasking_Elab_Contract_Missing_Elaboration_Contract_Row) = 1,
              "legal protected entry call without elaboration contract-flow evidence must not remain confident");
      Assert (Task_Elab.Global_Error_Count (Model) = 1, "expected one Refined_Global tasking blocker");
      Assert (Task_Elab.Depends_Error_Count (Model) = 1, "expected one Refined_Depends tasking blocker");
      Assert (Task_Elab.Propagation_Error_Count (Model) = 1, "expected one call propagation blocker");
      Assert (Task_Elab.Coverage_Error_Count (Model) = 1, "expected one coverage blocker");
      Assert (Task_Elab.Tasking_Error_Count (Model) = 1, "expected one base tasking effect blocker");
      Assert (Task_Elab.Fingerprint (Model) /= 0, "model fingerprint must be deterministic and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Task_Elab.Tasking_Elab_Contract_Model :=
        Task_Elab.Build (Sample_Context_Model);
      Row   : constant Task_Elab.Tasking_Elab_Contract_Info :=
        Task_Elab.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115804));
      Set   : constant Task_Elab.Tasking_Elab_Contract_Set :=
        Task_Elab.Rows_For_Kind (Model, Task_Elab.Tasking_Elab_Contract_Protected_Write);
   begin
      Assert (Row.Status = Task_Elab.Tasking_Elab_Contract_Call_Effect_Not_Propagated,
              "node lookup must preserve requeue call-propagation blocker");
      Assert (Task_Elab.Set_Count (Set) = 1, "one protected write row is expected");
      Assert (Task_Elab.Count_Kind (Model, Task_Elab.Tasking_Elab_Contract_Task_Activation) = 1,
              "kind count must preserve task activation row");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "tasking/protected effects consume elaboration contract-flow blockers");
      Register_Routine (T, Test_Queries'Access, "tasking elaboration-contract lookups preserve blockers");
   end Register_Tests;

end Test_Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality;
