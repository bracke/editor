with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Accessibility_Scope_Graph_Legality;
with Editor.Ada_Elaboration_Graph_Closure_Legality;
with Editor.Ada_Exception_Finalization_Legality;
with Editor.Ada_Flow_Effect_Graph_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Effects_Legality;
with Editor.Ada_Tasking_Protected_Precision_Legality;
with Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;

package body Test_Ada_Tasking_Protected_Effects_Legality is

   package E renames Editor.Ada_Tasking_Protected_Effects_Legality;
   use type E.Tasking_Effect_Id;
   use type E.Tasking_Effect_Context_Kind;
   use type E.Tasking_Effect_Status;
   use type E.Tasking_Effect_Context_Info;
   use type E.Tasking_Effect_Info;
   use type E.Tasking_Effect_Context_Model;
   use type E.Tasking_Effect_Set;
   use type E.Tasking_Effect_Model;
   package Precision renames Editor.Ada_Tasking_Protected_Precision_Legality;
   use type Precision.Tasking_Legality_Status;
   use type Precision.Tasking_Context_Kind;
   use type Precision.Dataflow_Legality_Status;
   use type Precision.Elaboration_Precision_Status;
   use type Precision.Accessibility_Precision_Status;
   use type Precision.Tasking_Precision_Context_Id;
   use type Precision.Tasking_Precision_Legality_Id;
   use type Precision.Tasking_Precision_Context_Kind;
   use type Precision.Tasking_Precision_Status;
   use type Precision.Tasking_Precision_Context_Info;
   use type Precision.Tasking_Precision_Legality_Info;
   use type Precision.Tasking_Precision_Context_Model;
   use type Precision.Tasking_Precision_Result_Set;
   use type Precision.Tasking_Precision_Legality_Model;
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
   package Elab renames Editor.Ada_Elaboration_Graph_Closure_Legality;
   use type Elab.Elaboration_Graph_Edge_Id;
   use type Elab.Elaboration_Graph_Context_Kind;
   use type Elab.Elaboration_Graph_Closure_Status;
   use type Elab.Elaboration_Graph_Context_Info;
   use type Elab.Elaboration_Graph_Closure_Info;
   use type Elab.Elaboration_Graph_Context_Model;
   use type Elab.Elaboration_Graph_Result_Set;
   use type Elab.Elaboration_Graph_Closure_Model;
   package Scope renames Editor.Ada_Accessibility_Scope_Graph_Legality;
   use type Scope.Scope_Context_Id;
   use type Scope.Scope_Legality_Id;
   use type Scope.Scope_Level;
   use type Scope.Scope_Context_Kind;
   use type Scope.Scope_Legality_Status;
   use type Scope.Scope_Context_Info;
   use type Scope.Scope_Legality_Info;
   use type Scope.Scope_Context_Model;
   use type Scope.Scope_Result_Set;
   use type Scope.Scope_Legality_Model;
   package Finalization renames Editor.Ada_Exception_Finalization_Legality;
   use type Finalization.Accessibility_Legality_Status;
   use type Finalization.Contract_Legality_Status;
   use type Finalization.Flow_Legality_Status;
   use type Finalization.Elaboration_Legality_Status;
   use type Finalization.Renaming_Legality_Status;
   use type Finalization.Completion_Legality_Status;
   use type Finalization.Exception_Context_Id;
   use type Finalization.Exception_Legality_Id;
   use type Finalization.Exception_Context_Kind;
   use type Finalization.Exception_Target_State;
   use type Finalization.Handler_State;
   use type Finalization.Finalization_State;
   use type Finalization.No_Return_State;
   use type Finalization.Exception_Legality_Status;
   use type Finalization.Exception_Context_Info;
   use type Finalization.Exception_Legality_Info;
   use type Finalization.Exception_Context_Model;
   use type Finalization.Exception_Result_Set;
   use type Finalization.Exception_Legality_Model;
   package Gates renames Editor.Ada_Widened_Legality_Coverage_Gate_Enforcement;
   use type Gates.Enforcement_Row_Id;
   use type Gates.Widened_Legality_Engine;
   use type Gates.Enforcement_Status;
   use type Gates.Enforcement_Context_Info;
   use type Gates.Enforcement_Info;
   use type Gates.Enforcement_Context_Model;
   use type Gates.Enforcement_Set;
   use type Gates.Enforcement_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Tasking_Protected_Effects_Legality");
   end Name;

   function Sample_Contexts return E.Tasking_Effect_Context_Model is
      Contexts : E.Tasking_Effect_Context_Model;
      C        : E.Tasking_Effect_Context_Info;
   begin
      C.Id := 1;
      C.Kind := E.Tasking_Effect_Context_Task_Activation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114501);
      C.Object_Name := To_Unbounded_String ("Worker");
      C.Task_Body_Elaborated := True;
      C.Source_Fingerprint := 1_145_001;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := E.Tasking_Effect_Context_Protected_Read;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114502);
      C.Object_Name := To_Unbounded_String ("State");
      C.Reads_Protected_State := True;
      C.Flow_Status := Flow.Flow_Graph_Read_Not_In_Global;
      C.Source_Fingerprint := 1_145_002;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := E.Tasking_Effect_Context_Protected_Function_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114503);
      C.Object_Name := To_Unbounded_String ("State");
      C.Writes_Protected_State := True;
      C.Source_Fingerprint := 1_145_003;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := E.Tasking_Effect_Context_Entry_Queue;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114504);
      C.Entry_Name := To_Unbounded_String ("Submit");
      C.Queue_Name := To_Unbounded_String ("Submit'Queue");
      C.Queue_Target_Resolved := False;
      C.Source_Fingerprint := 1_145_004;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := E.Tasking_Effect_Context_Entry_Queue;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114505);
      C.Entry_Name := To_Unbounded_String ("Drain");
      C.Scope_Status := Scope.Scope_Legality_Access_Parameter_Escapes;
      C.Source_Fingerprint := 1_145_005;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := E.Tasking_Effect_Context_Accept_Body;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114506);
      C.Entry_Name := To_Unbounded_String ("Accept_Submit");
      C.Accept_State_Effect_Matches := False;
      C.Source_Fingerprint := 1_145_006;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := E.Tasking_Effect_Context_Requeue;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114507);
      C.Entry_Name := To_Unbounded_String ("Forward");
      C.Requeue_With_Abort := True;
      C.Requeue_Abort_Safe := False;
      C.Source_Fingerprint := 1_145_007;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := E.Tasking_Effect_Context_Select_Guard;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114508);
      C.Select_Guard_Boolean := False;
      C.Source_Fingerprint := 1_145_008;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := E.Tasking_Effect_Context_Select_Alternative;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114509);
      C.Select_Terminate_With_Delay := True;
      C.Source_Fingerprint := 1_145_009;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := E.Tasking_Effect_Context_Abortable_Part;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114510);
      C.Abortable_Finalization_Safe := False;
      C.Source_Fingerprint := 1_145_010;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := E.Tasking_Effect_Context_Task_Termination;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114511);
      C.Finalization_Status := Finalization.Exception_Legality_Finalization_Abort_Unsafe;
      C.Source_Fingerprint := 1_145_011;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := E.Tasking_Effect_Context_Protected_Procedure_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114512);
      C.Precision_Status := Precision.Tasking_Precision_Protected_Procedure_Global_Mismatch;
      C.Source_Fingerprint := 1_145_012;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 13;
      C.Kind := E.Tasking_Effect_Context_Protected_Entry_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114513);
      C.Elaboration_Status := Elab.Graph_Closure_Direct_Call_Before_Body;
      C.Source_Fingerprint := 1_145_013;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 14;
      C.Kind := E.Tasking_Effect_Context_Protected_Write;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114514);
      C.Gate_Status := Gates.Enforcement_Metadata_Blocker;
      C.Source_Fingerprint := 1_145_014;
      E.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 15;
      C.Kind := E.Tasking_Effect_Context_Delay_Alternative;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (114515);
      C.Delay_Time_Static := False;
      C.Source_Fingerprint := 1_145_015;
      E.Add_Context (Contexts, C);

      return Contexts;
   end Sample_Contexts;

   procedure Test_Effect_Statuses (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Contexts : constant E.Tasking_Effect_Context_Model := Sample_Contexts;
      Model    : constant E.Tasking_Effect_Model := E.Build (Contexts);
   begin
      Assert (E.Context_Count (Contexts) = 15, "all tasking/protected effect contexts are recorded");
      Assert (E.Row_Count (Model) = 15, "all tasking/protected effect contexts produce rows");
      Assert (E.Count_Status (Model, E.Tasking_Effect_Legal_Task_Activation) = 1,
              "legal task activation effect is preserved");
      Assert (E.Count_Status (Model, E.Tasking_Effect_Protected_Read_Not_In_Global) = 1,
              "protected reads must be covered by Global effects");
      Assert (E.Count_Status (Model, E.Tasking_Effect_Protected_Function_Writes_State) = 1,
              "protected functions cannot write protected state");
      Assert (E.Count_Status (Model, E.Tasking_Effect_Entry_Queue_Target_Unresolved) = 1,
              "entry queue target resolution is checked");
      Assert (E.Count_Status (Model, E.Tasking_Effect_Entry_Queue_Accessibility_Error) = 1,
              "entry queue accessibility errors are preserved");
      Assert (E.Count_Status (Model, E.Tasking_Effect_Accept_Body_State_Effect_Mismatch) = 1,
              "accept body state effects are checked");
      Assert (E.Count_Status (Model, E.Tasking_Effect_Requeue_With_Abort_Unsafe) = 1,
              "requeue with abort safety is checked");
      Assert (E.Count_Status (Model, E.Tasking_Effect_Select_Guard_Not_Boolean) = 1,
              "select guards must be Boolean");
      Assert (E.Count_Status (Model, E.Tasking_Effect_Select_Terminate_With_Delay) = 1,
              "terminate alternatives conflict with delay alternatives");
      Assert (E.Count_Status (Model, E.Tasking_Effect_Abortable_Part_Finalization_Unsafe) = 1,
              "abortable finalization hazards are preserved");
      Assert (E.Count_Status (Model, E.Tasking_Effect_Linked_Finalization_Error) = 1,
              "linked finalization errors participate in tasking effects");
      Assert (E.Count_Status (Model, E.Tasking_Effect_Linked_Precision_Error) = 1,
              "linked tasking precision errors are preserved");
      Assert (E.Count_Status (Model, E.Tasking_Effect_Linked_Elaboration_Error) = 1,
              "linked elaboration graph errors are preserved");
      Assert (E.Count_Status (Model, E.Tasking_Effect_Coverage_Gate_Blocker) = 1,
              "coverage gates block unsafe tasking conclusions");
      Assert (E.Count_Status (Model, E.Tasking_Effect_Delay_Alternative_Non_Static_Time) = 1,
              "delay alternative staticness is checked");
      Assert (E.Error_Count (Model) = 14, "all non-activation rows are errors");
      Assert (E.Queue_Error_Count (Model) = 2, "queue-specific errors are counted");
      Assert (E.Select_Error_Count (Model) = 3, "select/delay errors are counted");
      Assert (E.Protected_State_Error_Count (Model) = 2, "protected-state errors are counted");
      Assert (E.Requeue_Error_Count (Model) = 1, "requeue errors are counted");
      Assert (E.Finalization_Error_Count (Model) = 2, "finalization tasking effects are counted");
      Assert (E.Linked_Error_Count (Model) = 2, "linked precision/elaboration errors are counted");
      Assert (E.Coverage_Gate_Error_Count (Model) = 1, "coverage gate blockers are counted");
      Assert (E.Fingerprint (Model) /= 0, "model fingerprint is stable and non-zero");
   end Test_Effect_Statuses;

   procedure Test_Lookups (T : in out AUnit.Test_Cases.Test_Case'Class) is
      pragma Unreferenced (T);
      Model : constant E.Tasking_Effect_Model := E.Build (Sample_Contexts);
      Row   : constant E.Tasking_Effect_Info :=
        E.First_For_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (114507));
      Requeues : constant E.Tasking_Effect_Set :=
        E.Rows_For_Kind (Model, E.Tasking_Effect_Context_Requeue);
      Entry_Rows : constant E.Tasking_Effect_Set :=
        E.Rows_For_Entry (Model, "Forward");
      State_Rows : constant E.Tasking_Effect_Set :=
        E.Rows_For_Object (Model, "State");
   begin
      Assert (Row.Status = E.Tasking_Effect_Requeue_With_Abort_Unsafe,
              "node lookup returns requeue-with-abort row");
      Assert (E.Has_Error (Row), "requeue row is an error");
      Assert (E.Result_Count (Requeues) = 1, "kind lookup returns requeue row");
      Assert (E.Result_Count (Entry_Rows) = 1, "entry lookup returns named requeue row");
      Assert (E.Result_Count (State_Rows) = 2, "object lookup returns protected-state rows");
      Assert (E.Result_At (Requeues, 1).Fingerprint /= 0, "result fingerprints are preserved");
   end Test_Lookups;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Effect_Statuses'Access, "tasking/protected effect statuses");
      Register_Routine
        (T, Test_Lookups'Access, "tasking/protected effect lookups");
   end Register_Tests;

end Test_Ada_Tasking_Protected_Effects_Legality;
