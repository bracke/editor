with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with AUnit;
with Editor.Ada_Representation_Freezing_Exact_Propagation_Legality;
with Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;

package body Test_Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality is

   package Freezing renames Editor.Ada_Representation_Freezing_Exact_Propagation_Legality;
   use type Freezing.Freezing_Propagation_Id;
   use type Freezing.Freezing_Propagation_Context_Kind;
   use type Freezing.Freezing_Propagation_Status;
   use type Freezing.Freezing_Propagation_Context_Info;
   use type Freezing.Freezing_Propagation_Info;
   use type Freezing.Freezing_Propagation_Context_Model;
   use type Freezing.Freezing_Propagation_Model;
   use type Freezing.Freezing_Propagation_Set;
   package Rep_Task_CPD renames Editor.Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Rep_Task_CPD.Representation_Tasking_CPD_Row_Id;
   use type Rep_Task_CPD.Representation_Tasking_CPD_Context_Kind;
   use type Rep_Task_CPD.Representation_Tasking_CPD_Status;
   use type Rep_Task_CPD.Representation_Tasking_CPD_Context_Info;
   use type Rep_Task_CPD.Representation_Tasking_CPD_Info;
   use type Rep_Task_CPD.Representation_Tasking_CPD_Context_Model;
   use type Rep_Task_CPD.Representation_Tasking_CPD_Set;
   use type Rep_Task_CPD.Representation_Tasking_CPD_Model;
   package Task_CPD renames Editor.Ada_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
   use type Task_CPD.Tasking_Contract_Predicate_Row_Id;
   use type Task_CPD.Tasking_Contract_Predicate_Context_Kind;
   use type Task_CPD.Tasking_Contract_Predicate_Status;
   use type Task_CPD.Tasking_Contract_Predicate_Context_Info;
   use type Task_CPD.Tasking_Contract_Predicate_Info;
   use type Task_CPD.Tasking_Contract_Predicate_Context_Model;
   use type Task_CPD.Tasking_Contract_Predicate_Set;
   use type Task_CPD.Tasking_Contract_Predicate_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality");
   end Name;

   function Sample_Context_Model return Rep_Task_CPD.Representation_Tasking_CPD_Context_Model is
      Contexts : Rep_Task_CPD.Representation_Tasking_CPD_Context_Model;
      C        : Rep_Task_CPD.Representation_Tasking_CPD_Context_Info;
   begin
      C.Id := 1;
      C.Kind := Rep_Task_CPD.Representation_Tasking_CPD_Representation_Clause;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117001);
      C.Target_Name := To_Unbounded_String ("Device_State");
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (1);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Explicit_Representation_Before_Freezing;
      C.Tasking_CPD_Row := Task_CPD.Tasking_Contract_Predicate_Row_Id (1);
      C.Tasking_CPD_Status := Task_CPD.Tasking_Contract_Predicate_Legal_Task_Activation_Accepted;
      C.Tasking_CPD_Matches := 1;
      C.Source_Fingerprint := 17001;
      Rep_Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := Rep_Task_CPD.Representation_Tasking_CPD_Protected_Read_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117002);
      C.Object_Name := To_Unbounded_String ("Buffer_State");
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (2);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Operational_Effect;
      C.Tasking_CPD_Row := Task_CPD.Tasking_Contract_Predicate_Row_Id (2);
      C.Tasking_CPD_Status := Task_CPD.Tasking_Contract_Predicate_Read_Before_Write_Blocker;
      C.Tasking_CPD_Matches := 1;
      C.Source_Fingerprint := 17002;
      Rep_Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := Rep_Task_CPD.Representation_Tasking_CPD_Entry_Barrier_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117003);
      C.Entry_Name := To_Unbounded_String ("Ready");
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (3);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Operational_Effect;
      C.Tasking_CPD_Row := Task_CPD.Tasking_Contract_Predicate_Row_Id (3);
      C.Tasking_CPD_Status := Task_CPD.Tasking_Contract_Predicate_Predicate_Propagation_Blocker;
      C.Tasking_CPD_Matches := 1;
      C.Source_Fingerprint := 17003;
      Rep_Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := Rep_Task_CPD.Representation_Tasking_CPD_Accept_Body_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117004);
      C.Entry_Name := To_Unbounded_String ("Start");
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (4);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Implicit_Freezing;
      C.Tasking_CPD_Row := Task_CPD.Tasking_Contract_Predicate_Row_Id (4);
      C.Tasking_CPD_Status := Task_CPD.Tasking_Contract_Predicate_Global_Depends_Blocker;
      C.Tasking_CPD_Matches := 1;
      C.Source_Fingerprint := 17004;
      Rep_Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := Rep_Task_CPD.Representation_Tasking_CPD_Requeue_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117005);
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (5);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Operational_Effect;
      C.Tasking_CPD_Row := Task_CPD.Tasking_Contract_Predicate_Row_Id (5);
      C.Tasking_CPD_Status := Task_CPD.Tasking_Contract_Predicate_Call_Propagation_Blocker;
      C.Tasking_CPD_Matches := 1;
      C.Source_Fingerprint := 17005;
      Rep_Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := Rep_Task_CPD.Representation_Tasking_CPD_Select_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117006);
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (6);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Operational_Effect;
      C.Tasking_CPD_Row := Task_CPD.Tasking_Contract_Predicate_Row_Id (6);
      C.Tasking_CPD_Status := Task_CPD.Tasking_Contract_Predicate_Coverage_Blocker;
      C.Tasking_CPD_Matches := 1;
      C.Source_Fingerprint := 17006;
      Rep_Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := Rep_Task_CPD.Representation_Tasking_CPD_Protected_Call_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117007);
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (7);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Operational_Effect;
      C.Tasking_CPD_Row := Task_CPD.Tasking_Contract_Predicate_Row_Id (7);
      C.Tasking_CPD_Status := Task_CPD.Tasking_Contract_Predicate_Base_Tasking_Effect_Error;
      C.Tasking_CPD_Matches := 1;
      C.Source_Fingerprint := 17007;
      Rep_Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := Rep_Task_CPD.Representation_Tasking_CPD_Task_Termination_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117008);
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (8);
      C.Freezing_Status := Freezing.Freezing_Propagation_Representation_After_Implicit_Use;
      C.Tasking_CPD_Row := Task_CPD.Tasking_Contract_Predicate_Row_Id (8);
      C.Tasking_CPD_Status := Task_CPD.Tasking_Contract_Predicate_Legal_Task_Termination_Accepted;
      C.Tasking_CPD_Matches := 1;
      C.Source_Fingerprint := 17008;
      Rep_Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := Rep_Task_CPD.Representation_Tasking_CPD_Record_Layout;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117009);
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (9);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Discriminant_Representation;
      C.Tasking_CPD_Row := Task_CPD.No_Tasking_Contract_Predicate_Row;
      C.Tasking_CPD_Status := Task_CPD.Tasking_Contract_Predicate_Not_Checked;
      C.Tasking_CPD_Matches := 0;
      C.Source_Fingerprint := 17009;
      Rep_Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := Rep_Task_CPD.Representation_Tasking_CPD_Abortable_Finalization_Effect;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117010);
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (10);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Operational_Effect;
      C.Tasking_CPD_Row := Task_CPD.Tasking_Contract_Predicate_Row_Id (10);
      C.Tasking_CPD_Status := Task_CPD.Tasking_Contract_Predicate_Lifetime_Accessibility_Blocker;
      C.Tasking_CPD_Matches := 2;
      C.Source_Fingerprint := 17010;
      Rep_Task_CPD.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := Rep_Task_CPD.Representation_Tasking_CPD_Stream_Attribute;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (117011);
      C.Freezing_Row := Freezing.Freezing_Propagation_Id (11);
      C.Freezing_Status := Freezing.Freezing_Propagation_Legal_Stream_Effect;
      C.Tasking_CPD_Row := Task_CPD.Tasking_Contract_Predicate_Row_Id (11);
      C.Tasking_CPD_Status := Task_CPD.Tasking_Contract_Predicate_Elaboration_Predicate_Indeterminate;
      C.Tasking_CPD_Matches := 1;
      C.Source_Fingerprint := 17011;
      Rep_Task_CPD.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Context_Model;

   procedure Test_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Rep_Task_CPD.Representation_Tasking_CPD_Model :=
        Rep_Task_CPD.Build (Sample_Context_Model);
   begin
      Assert
        (Rep_Task_CPD.Row_Count (Model) = 11,
         "expected eleven representation tasking CPD rows");
      Assert
        (Rep_Task_CPD.Legal_Count (Model) = 1,
         "only the representation clause with accepted tasking CPD evidence should remain legal");
      Assert (Rep_Task_CPD.Count_Status (Model, Rep_Task_CPD.Representation_Tasking_CPD_Read_Before_Write_Blocker) = 1,
              "protected read effect must consume read-before-write blocker");
      Assert
        (Rep_Task_CPD.Count_Status
           (Model, Rep_Task_CPD.Representation_Tasking_CPD_Predicate_Propagation_Blocker) = 1,
              "entry barrier effect must consume predicate propagation blocker");
      Assert (Rep_Task_CPD.Count_Status (Model, Rep_Task_CPD.Representation_Tasking_CPD_Global_Depends_Blocker) = 1,
              "accept body effect must consume Global/Depends blocker");
      Assert (Rep_Task_CPD.Count_Status (Model, Rep_Task_CPD.Representation_Tasking_CPD_Call_Propagation_Blocker) = 1,
              "requeue effect must consume call propagation blocker");
      Assert (Rep_Task_CPD.Count_Status (Model, Rep_Task_CPD.Representation_Tasking_CPD_Coverage_Blocker) = 1,
              "select effect must preserve repaired coverage blocker");
      Assert (Rep_Task_CPD.Count_Status (Model, Rep_Task_CPD.Representation_Tasking_CPD_Base_Tasking_Effect_Error) = 1,
              "base tasking/protected effect errors must not be hidden by legal freezing evidence");
      Assert (Rep_Task_CPD.Count_Status (Model, Rep_Task_CPD.Representation_Tasking_CPD_Base_Freezing_Error) = 1,
              "base representation/freezing errors must not be hidden by legal tasking evidence");
      Assert (Rep_Task_CPD.Count_Status (Model, Rep_Task_CPD.Representation_Tasking_CPD_Missing_Tasking_CPD_Row) = 1,
              "legal record layout without tasking CPD evidence must not remain confident");
      Assert
        (Rep_Task_CPD.Count_Status
           (Model, Rep_Task_CPD.Representation_Tasking_CPD_Multiple_Tasking_CPD_Blockers) = 1,
              "multiple matching tasking CPD blockers must be explicit");
      Assert (Rep_Task_CPD.Count_Status (Model, Rep_Task_CPD.Representation_Tasking_CPD_Tasking_CPD_Indeterminate) = 1,
              "stream attribute must preserve indeterminate tasking CPD evidence");
      Assert (Rep_Task_CPD.Freezing_Error_Count (Model) = 1, "expected one base freezing blocker");
      Assert (Rep_Task_CPD.Initialization_Error_Count (Model) = 1, "expected one initialization blocker");
      Assert (Rep_Task_CPD.Predicate_Error_Count (Model) = 1, "expected one predicate blocker");
      Assert (Rep_Task_CPD.Dataflow_Error_Count (Model) = 2, "expected two dataflow blockers");
      Assert (Rep_Task_CPD.Coverage_Error_Count (Model) = 1, "expected one coverage blocker");
      Assert (Rep_Task_CPD.Tasking_Error_Count (Model) = 1, "expected one base tasking effect blocker");
      Assert (Rep_Task_CPD.Indeterminate_Count (Model) = 1, "expected one indeterminate row");
      Assert (Rep_Task_CPD.Fingerprint (Model) /= 0, "model fingerprint must be deterministic and nonzero");
   end Test_Statuses;

   procedure Test_Queries (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant Rep_Task_CPD.Representation_Tasking_CPD_Model :=
        Rep_Task_CPD.Build (Sample_Context_Model);
      Row   : constant Rep_Task_CPD.Representation_Tasking_CPD_Info :=
        Rep_Task_CPD.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (117005));
      Set   : constant Rep_Task_CPD.Representation_Tasking_CPD_Set :=
        Rep_Task_CPD.Rows_For_Kind (Model, Rep_Task_CPD.Representation_Tasking_CPD_Entry_Barrier_Effect);
   begin
      Assert (Row.Status = Rep_Task_CPD.Representation_Tasking_CPD_Call_Propagation_Blocker,
              "node lookup must preserve requeue call-propagation blocker");
      Assert (Rep_Task_CPD.Set_Count (Set) = 1, "one entry barrier effect row is expected");
      Assert (Rep_Task_CPD.Count_Kind (Model, Rep_Task_CPD.Representation_Tasking_CPD_Representation_Clause) = 1,
              "kind count must preserve representation clause row");
   end Test_Queries;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Statuses'Access,
         "representation/freezing consumes tasking CPD blockers");
      Register_Routine
        (T, Test_Queries'Access,
         "representation tasking CPD lookups preserve blockers");
   end Register_Tests;

end Test_Ada_Representation_Tasking_Contract_Predicate_Dataflow_Consumer_Legality;
