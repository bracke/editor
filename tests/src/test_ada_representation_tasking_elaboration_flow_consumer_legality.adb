with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Representation_Freezing_Exact_Propagation_Legality;
with Editor.Ada_Representation_Tasking_Elaboration_Flow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality;

package body Test_Ada_Representation_Tasking_Elaboration_Flow_Consumer_Legality is

   package Freezing renames Editor.Ada_Representation_Freezing_Exact_Propagation_Legality;
   use type Freezing.Freezing_Propagation_Id;
   use type Freezing.Freezing_Propagation_Context_Kind;
   use type Freezing.Freezing_Propagation_Status;
   use type Freezing.Freezing_Propagation_Context_Info;
   use type Freezing.Freezing_Propagation_Info;
   use type Freezing.Freezing_Propagation_Context_Model;
   use type Freezing.Freezing_Propagation_Model;
   use type Freezing.Freezing_Propagation_Set;
   package Rep_Task renames Editor.Ada_Representation_Tasking_Elaboration_Flow_Consumer_Legality;
   use type Rep_Task.Representation_Tasking_Row_Id;
   use type Rep_Task.Representation_Tasking_Context_Kind;
   use type Rep_Task.Representation_Tasking_Status;
   use type Rep_Task.Representation_Tasking_Context_Info;
   use type Rep_Task.Representation_Tasking_Info;
   use type Rep_Task.Representation_Tasking_Context_Model;
   use type Rep_Task.Representation_Tasking_Set;
   use type Rep_Task.Representation_Tasking_Model;
   package Task_Flow renames Editor.Ada_Tasking_Elaboration_Contract_Flow_Consumer_Legality;
   use type Task_Flow.Tasking_Elab_Contract_Row_Id;
   use type Task_Flow.Tasking_Elab_Contract_Context_Kind;
   use type Task_Flow.Tasking_Elab_Contract_Status;
   use type Task_Flow.Tasking_Elab_Contract_Context_Info;
   use type Task_Flow.Tasking_Elab_Contract_Info;
   use type Task_Flow.Tasking_Elab_Contract_Context_Model;
   use type Task_Flow.Tasking_Elab_Contract_Set;
   use type Task_Flow.Tasking_Elab_Contract_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Representation_Tasking_Elaboration_Flow_Consumer_Legality");
   end Name;

   function Sample_Context_Model return Rep_Task.Representation_Tasking_Context_Model is
      Contexts : Rep_Task.Representation_Tasking_Context_Model;
      C        : Rep_Task.Representation_Tasking_Context_Info;
   begin
      C.Id := 1;
      C.Kind := Rep_Task.Representation_Tasking_Representation_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115901);
      C.Target_Name := To_Unbounded_String ("Device_State");
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (1);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Explicit_Representation_Before_Freezing;
      C.Tasking_Flow_Row := Task_Flow.Tasking_Elab_Contract_Row_Id (1);
      C.Tasking_Flow_Status := Task_Flow.Tasking_Elab_Contract_Legal_Task_Activation_Accepted;
      C.Tasking_Flow_Matches := 1;
      C.Source_Fingerprint := 901;
      Rep_Task.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := Rep_Task.Representation_Tasking_Operational_Attribute;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115902);
      C.Target_Name := To_Unbounded_String ("Protected_State");
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (2);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Operational_Effect;
      C.Tasking_Flow_Row := Task_Flow.Tasking_Elab_Contract_Row_Id (2);
      C.Tasking_Flow_Status := Task_Flow.Tasking_Elab_Contract_Refined_Global_Missing_Write;
      C.Tasking_Flow_Matches := 1;
      C.Source_Fingerprint := 902;
      Rep_Task.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := Rep_Task.Representation_Tasking_Stream_Attribute;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115903);
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (3);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Stream_Effect;
      C.Tasking_Flow_Row := Task_Flow.Tasking_Elab_Contract_Row_Id (3);
      C.Tasking_Flow_Status := Task_Flow.Tasking_Elab_Contract_Refined_Depends_Missing_Edge;
      C.Tasking_Flow_Matches := 1;
      C.Source_Fingerprint := 903;
      Rep_Task.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := Rep_Task.Representation_Tasking_Requeue_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115904);
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (4);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Implicit_Freezing;
      C.Tasking_Flow_Row := Task_Flow.Tasking_Elab_Contract_Row_Id (4);
      C.Tasking_Flow_Status := Task_Flow.Tasking_Elab_Contract_Call_Effect_Not_Propagated;
      C.Tasking_Flow_Matches := 1;
      C.Source_Fingerprint := 904;
      Rep_Task.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := Rep_Task.Representation_Tasking_Select_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115905);
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (5);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Operational_Effect;
      C.Tasking_Flow_Row := Task_Flow.Tasking_Elab_Contract_Row_Id (5);
      C.Tasking_Flow_Status := Task_Flow.Tasking_Elab_Contract_Coverage_Feedback_Blocker;
      C.Tasking_Flow_Matches := 1;
      C.Source_Fingerprint := 905;
      Rep_Task.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := Rep_Task.Representation_Tasking_Task_Termination_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115906);
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (6);
      C.Freezing_Status := Freezing.Freezing_Propagation_Representation_After_Implicit_Use;
      C.Tasking_Flow_Row := Task_Flow.Tasking_Elab_Contract_Row_Id (6);
      C.Tasking_Flow_Status := Task_Flow.Tasking_Elab_Contract_Legal_Task_Termination_Accepted;
      C.Tasking_Flow_Matches := 1;
      C.Source_Fingerprint := 906;
      Rep_Task.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := Rep_Task.Representation_Tasking_Protected_Call_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115907);
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (7);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Operational_Effect;
      C.Tasking_Flow_Row := Task_Flow.Tasking_Elab_Contract_Row_Id (7);
      C.Tasking_Flow_Status := Task_Flow.Tasking_Elab_Contract_Base_Tasking_Effect_Error;
      C.Tasking_Flow_Matches := 1;
      C.Source_Fingerprint := 907;
      Rep_Task.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := Rep_Task.Representation_Tasking_Record_Layout;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (115908);
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (8);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Discriminant_Representation;
      C.Tasking_Flow_Row := Task_Flow.No_Tasking_Elab_Contract_Row;
      C.Tasking_Flow_Status := Task_Flow.Tasking_Elab_Contract_Not_Checked;
      C.Tasking_Flow_Matches := 0;
      C.Source_Fingerprint := 908;
      Rep_Task.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Rep_Task.Representation_Tasking_Model :=
        Rep_Task.Build (Sample_Context_Model);
   begin
      Assert (Rep_Task.Row_Count (Model) = 8, "expected eight representation tasking-flow rows");
      Assert (Rep_Task.Legal_Count (Model) = 1, "only the representation clause with accepted tasking flow should remain legal");
      Assert (Rep_Task.Count_Status (Model, Rep_Task.Representation_Tasking_Refined_Global_Missing_Write) = 1,
              "operational attribute must consume missing Refined_Global write blocker");
      Assert (Rep_Task.Count_Status (Model, Rep_Task.Representation_Tasking_Refined_Depends_Missing_Edge) = 1,
              "stream attribute must consume missing Refined_Depends edge blocker");
      Assert (Rep_Task.Count_Status (Model, Rep_Task.Representation_Tasking_Call_Effect_Not_Propagated) = 1,
              "requeue representation effect must consume call propagation blocker");
      Assert (Rep_Task.Count_Status (Model, Rep_Task.Representation_Tasking_Coverage_Feedback_Blocker) = 1,
              "select effect must preserve repaired coverage blocker");
      Assert (Rep_Task.Count_Status (Model, Rep_Task.Representation_Tasking_Base_Freezing_Error) = 1,
              "base representation/freezing errors must not be hidden by legal tasking flow");
      Assert (Rep_Task.Count_Status (Model, Rep_Task.Representation_Tasking_Base_Tasking_Effect_Error) = 1,
              "protected call representation effect must preserve tasking effect blocker");
      Assert (Rep_Task.Count_Status (Model, Rep_Task.Representation_Tasking_Missing_Tasking_Flow_Row) = 1,
              "legal record layout without tasking flow evidence must not remain confident");
      Assert (Rep_Task.Freezing_Error_Count (Model) = 1, "expected one base freezing blocker");
      Assert (Rep_Task.Global_Error_Count (Model) = 1, "expected one Refined_Global representation blocker");
      Assert (Rep_Task.Depends_Error_Count (Model) = 1, "expected one Refined_Depends representation blocker");
      Assert (Rep_Task.Propagation_Error_Count (Model) = 1, "expected one tasking call-propagation blocker");
      Assert (Rep_Task.Coverage_Error_Count (Model) = 1, "expected one coverage blocker");
      Assert (Rep_Task.Tasking_Error_Count (Model) = 1, "expected one tasking effect blocker");
      Assert (Rep_Task.Fingerprint (Model) /= 0, "model fingerprint must be deterministic and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Rep_Task.Representation_Tasking_Model :=
        Rep_Task.Build (Sample_Context_Model);
      Row   : constant Rep_Task.Representation_Tasking_Info :=
        Rep_Task.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (115904));
      Set   : constant Rep_Task.Representation_Tasking_Set :=
        Rep_Task.Rows_For_Kind (Model, Rep_Task.Representation_Tasking_Operational_Attribute);
   begin
      Assert (Row.Status = Rep_Task.Representation_Tasking_Call_Effect_Not_Propagated,
              "node lookup must preserve requeue propagation blocker");
      Assert (Rep_Task.Set_Count (Set) = 1, "one operational attribute row is expected");
      Assert (Rep_Task.Count_Kind (Model, Rep_Task.Representation_Tasking_Representation_Clause) = 1,
              "kind count must preserve representation clause row");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Statuses'Access, "representation/freezing consumes tasking elaboration-flow blockers");
      Register_Routine (T, Test_Queries'Access, "representation tasking-flow lookups preserve blockers");
   end Register_Tests;

end Test_Ada_Representation_Tasking_Elaboration_Flow_Consumer_Legality;
