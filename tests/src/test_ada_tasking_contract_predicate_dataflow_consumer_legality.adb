with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Tasking_Protected_Effects_Legality;

package body Test_Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality is

   package Elab_Predicate renames Editor.Ada_Elaboration_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Elab_Predicate.Elaboration_Contract_Predicate_Row_Id;
   use type Elab_Predicate.Elaboration_Contract_Predicate_Context_Kind;
   use type Elab_Predicate.Elaboration_Contract_Predicate_Status;
   use type Elab_Predicate.Elaboration_Contract_Predicate_Context_Info;
   use type Elab_Predicate.Elaboration_Contract_Predicate_Info;
   use type Elab_Predicate.Elaboration_Contract_Predicate_Context_Model;
   use type Elab_Predicate.Elaboration_Contract_Predicate_Set;
   use type Elab_Predicate.Elaboration_Contract_Predicate_Model;
   package Task_CPD renames Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Task_CPD.Tasking_Contract_Predicate_Row_Id;
   use type Task_CPD.Tasking_Contract_Predicate_Context_Kind;
   use type Task_CPD.Tasking_Contract_Predicate_Status;
   use type Task_CPD.Tasking_Contract_Predicate_Context_Info;
   use type Task_CPD.Tasking_Contract_Predicate_Info;
   use type Task_CPD.Tasking_Contract_Predicate_Context_Model;
   use type Task_CPD.Tasking_Contract_Predicate_Set;
   use type Task_CPD.Tasking_Contract_Predicate_Model;
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
      return AUnit.Format ("Test_Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality");
   end Name;

   function Sample_Context_Model return Task_CPD.Tasking_Contract_Predicate_Context_Model is
      Contexts : Task_CPD.Tasking_Contract_Predicate_Context_Model;
      C        : Task_CPD.Tasking_Contract_Predicate_Context_Info;
   begin
      C.Id := 1;
      C.Kind := Task_CPD.Tasking_Contract_Predicate_Task_Activation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116901);
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (1);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Task_Activation;
      C.Elaboration_Predicate_Row := Elab_Predicate.Elaboration_Contract_Predicate_Row_Id (1);
      C.Elaboration_Predicate_Status := Elab_Predicate.Elaboration_Contract_Predicate_Legal_Task_Activation_Accepted;
      C.Elaboration_Predicate_Matches := 1;
      C.Source_Fingerprint := 16901;
      Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := Task_CPD.Tasking_Contract_Predicate_Protected_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116902);
      C.Object_Name := To_Unbounded_String ("Protected_State");
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (2);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Protected_Read;
      C.Elaboration_Predicate_Row := Elab_Predicate.Elaboration_Contract_Predicate_Row_Id (2);
      C.Elaboration_Predicate_Status := Elab_Predicate.Elaboration_Contract_Predicate_Read_Before_Write_Blocker;
      C.Elaboration_Predicate_Matches := 1;
      C.Source_Fingerprint := 16902;
      Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := Task_CPD.Tasking_Contract_Predicate_Entry_Barrier;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116903);
      C.Entry_Name := To_Unbounded_String ("Ready");
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (3);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Entry_Barrier;
      C.Elaboration_Predicate_Row := Elab_Predicate.Elaboration_Contract_Predicate_Row_Id (3);
      C.Elaboration_Predicate_Status := Elab_Predicate.Elaboration_Contract_Predicate_Base_Predicate_Propagation_Error;
      C.Elaboration_Predicate_Matches := 1;
      C.Source_Fingerprint := 16903;
      Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := Task_CPD.Tasking_Contract_Predicate_Accept_Body;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116904);
      C.Entry_Name := To_Unbounded_String ("Start");
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (4);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Accept_Body;
      C.Elaboration_Predicate_Row := Elab_Predicate.Elaboration_Contract_Predicate_Row_Id (4);
      C.Elaboration_Predicate_Status := Elab_Predicate.Elaboration_Contract_Predicate_Global_Blocker;
      C.Elaboration_Predicate_Matches := 1;
      C.Source_Fingerprint := 16904;
      Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := Task_CPD.Tasking_Contract_Predicate_Requeue;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116905);
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (5);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Requeue;
      C.Elaboration_Predicate_Row := Elab_Predicate.Elaboration_Contract_Predicate_Row_Id (5);
      C.Elaboration_Predicate_Status := Elab_Predicate.Elaboration_Contract_Predicate_Call_Propagation_Blocker;
      C.Elaboration_Predicate_Matches := 1;
      C.Source_Fingerprint := 16905;
      Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := Task_CPD.Tasking_Contract_Predicate_Select_Alternative;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116906);
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (6);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Select_Alternative;
      C.Elaboration_Predicate_Row := Elab_Predicate.Elaboration_Contract_Predicate_Row_Id (6);
      C.Elaboration_Predicate_Status := Elab_Predicate.Elaboration_Contract_Predicate_Coverage_Blocker;
      C.Elaboration_Predicate_Matches := 1;
      C.Source_Fingerprint := 16906;
      Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := Task_CPD.Tasking_Contract_Predicate_Protected_Function_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116907);
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (7);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Protected_Function_Writes_State;
      C.Elaboration_Predicate_Row := Elab_Predicate.Elaboration_Contract_Predicate_Row_Id (7);
      C.Elaboration_Predicate_Status := Elab_Predicate.Elaboration_Contract_Predicate_Legal_Call_Accepted;
      C.Elaboration_Predicate_Matches := 1;
      C.Source_Fingerprint := 16907;
      Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := Task_CPD.Tasking_Contract_Predicate_Delay_Alternative;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116908);
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (8);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Delay_Alternative;
      C.Elaboration_Predicate_Row := Elab_Predicate.Elaboration_Contract_Predicate_Row_Id (8);
      C.Elaboration_Predicate_Status := Elab_Predicate.Elaboration_Contract_Predicate_Contract_Predicate_Indeterminate;
      C.Elaboration_Predicate_Matches := 1;
      C.Source_Fingerprint := 16908;
      Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := Task_CPD.Tasking_Contract_Predicate_Protected_Entry_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116909);
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (9);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Protected_Entry_Call;
      C.Elaboration_Predicate_Row := Elab_Predicate.No_Elaboration_Contract_Predicate_Row;
      C.Elaboration_Predicate_Status := Elab_Predicate.Elaboration_Contract_Predicate_Not_Checked;
      C.Elaboration_Predicate_Matches := 0;
      C.Source_Fingerprint := 16909;
      Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := Task_CPD.Tasking_Contract_Predicate_Terminate_Alternative;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (116910);
      C.Tasking_Row := Task_Effects.Tasking_Effect_Id (10);
      C.Tasking_Status := Task_Effects.Tasking_Effect_Legal_Terminate_Alternative;
      C.Elaboration_Predicate_Row := Elab_Predicate.Elaboration_Contract_Predicate_Row_Id (10);
      C.Elaboration_Predicate_Status := Elab_Predicate.Elaboration_Contract_Predicate_Tasking_Protected_Blocker;
      C.Elaboration_Predicate_Matches := 2;
      C.Source_Fingerprint := 16910;
      Task_CPD.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Task_CPD.Tasking_Contract_Predicate_Model :=
        Task_CPD.Build (Sample_Context_Model);
   begin
      Assert (Task_CPD.Row_Count (Model) = 10, "expected ten tasking contract predicate/dataflow rows");
      Assert (Task_CPD.Legal_Count (Model) = 1, "only the task activation with accepted elaboration evidence should remain legal");
      Assert (Task_CPD.Count_Status (Model, Task_CPD.Tasking_Contract_Predicate_Read_Before_Write_Blocker) = 1,
              "protected read must consume read-before-write blocker");
      Assert (Task_CPD.Count_Status (Model, Task_CPD.Tasking_Contract_Predicate_Predicate_Propagation_Blocker) = 1,
              "entry barrier must consume predicate propagation blocker");
      Assert (Task_CPD.Count_Status (Model, Task_CPD.Tasking_Contract_Predicate_Global_Depends_Blocker) = 1,
              "accept body must consume Global/Depends blocker");
      Assert (Task_CPD.Count_Status (Model, Task_CPD.Tasking_Contract_Predicate_Call_Propagation_Blocker) = 1,
              "requeue must consume call propagation blocker");
      Assert (Task_CPD.Count_Status (Model, Task_CPD.Tasking_Contract_Predicate_Coverage_Blocker) = 1,
              "select alternative must preserve coverage blocker");
      Assert (Task_CPD.Count_Status (Model, Task_CPD.Tasking_Contract_Predicate_Base_Tasking_Effect_Error) = 1,
              "base tasking/protected effect errors must not be hidden by legal elaboration evidence");
      Assert (Task_CPD.Count_Status (Model, Task_CPD.Tasking_Contract_Predicate_Elaboration_Predicate_Indeterminate) = 1,
              "delay alternative must preserve indeterminate elaboration evidence");
      Assert (Task_CPD.Count_Status (Model, Task_CPD.Tasking_Contract_Predicate_Missing_Elaboration_Predicate_Row) = 1,
              "legal protected entry call without elaboration evidence must not remain confident");
      Assert (Task_CPD.Count_Status (Model, Task_CPD.Tasking_Contract_Predicate_Multiple_Matching_Blockers) = 1,
              "multiple matching blockers must be explicit");
      Assert (Task_CPD.Initialization_Error_Count (Model) = 1, "expected one initialization blocker");
      Assert (Task_CPD.Predicate_Error_Count (Model) = 1, "expected one predicate blocker");
      Assert (Task_CPD.Dataflow_Error_Count (Model) = 2, "expected two dataflow blockers");
      Assert (Task_CPD.Coverage_Error_Count (Model) = 1, "expected one coverage blocker");
      Assert (Task_CPD.Tasking_Error_Count (Model) = 1, "expected one base tasking effect blocker");
      Assert (Task_CPD.Indeterminate_Count (Model) = 1, "expected one indeterminate row");
      Assert (Task_CPD.Fingerprint (Model) /= 0, "model fingerprint must be deterministic and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Task_CPD.Tasking_Contract_Predicate_Model :=
        Task_CPD.Build (Sample_Context_Model);
      Row   : constant Task_CPD.Tasking_Contract_Predicate_Info :=
        Task_CPD.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (116905));
      Set   : constant Task_CPD.Tasking_Contract_Predicate_Set :=
        Task_CPD.Rows_For_Kind (Model, Task_CPD.Tasking_Contract_Predicate_Protected_Read);
   begin
      Assert (Row.Status = Task_CPD.Tasking_Contract_Predicate_Call_Propagation_Blocker,
              "node lookup must preserve requeue call-propagation blocker");
      Assert (Task_CPD.Set_Count (Set) = 1, "one protected read row is expected");
      Assert (Task_CPD.Count_Kind (Model, Task_CPD.Tasking_Contract_Predicate_Task_Activation) = 1,
              "kind count must preserve task activation row");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "tasking/protected effects consume elaboration contract predicate/dataflow blockers");
      Register_Routine (T, Test_Queries'Access, "tasking contract predicate/dataflow lookups preserve blockers");
   end Register_Tests;

end Test_Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
