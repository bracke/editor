with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Accessibility_Precision_Legality;
with Editor.Ada_Dataflow_Global_Depends_Legality;
with Editor.Ada_Elaboration_Precision_Legality;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tasking_Protected_Legality;
with Editor.Ada_Tasking_Protected_Precision_Legality;

package body Test_Ada_Tasking_Protected_Precision_Legality_Pass1130 is

   package TPL renames Editor.Ada_Tasking_Protected_Precision_Legality;
   use type TPL.Tasking_Legality_Status;
   use type TPL.Tasking_Context_Kind;
   use type TPL.Dataflow_Legality_Status;
   use type TPL.Elaboration_Precision_Status;
   use type TPL.Accessibility_Precision_Status;
   use type TPL.Tasking_Precision_Context_Id;
   use type TPL.Tasking_Precision_Legality_Id;
   use type TPL.Tasking_Precision_Context_Kind;
   use type TPL.Tasking_Precision_Status;
   use type TPL.Tasking_Precision_Context_Info;
   use type TPL.Tasking_Precision_Legality_Info;
   use type TPL.Tasking_Precision_Context_Model;
   use type TPL.Tasking_Precision_Result_Set;
   use type TPL.Tasking_Precision_Legality_Model;
   package BTL renames Editor.Ada_Tasking_Protected_Legality;
   use type BTL.Tasking_Context_Id;
   use type BTL.Tasking_Legality_Id;
   use type BTL.Tasking_Context_Kind;
   use type BTL.Tasking_Legality_Status;
   use type BTL.Tasking_Context_Info;
   use type BTL.Tasking_Legality_Info;
   use type BTL.Tasking_Context_Model;
   use type BTL.Tasking_Result_Set;
   use type BTL.Tasking_Legality_Model;
   package DFL renames Editor.Ada_Dataflow_Global_Depends_Legality;
   use type DFL.Contract_Legality_Status;
   use type DFL.Flow_Contract_State;
   use type DFL.Initialization_Legality_Status;
   use type DFL.Object_State;
   use type DFL.Dataflow_Context_Id;
   use type DFL.Dataflow_Legality_Id;
   use type DFL.Dataflow_Context_Kind;
   use type DFL.Dataflow_Effect_Kind;
   use type DFL.Global_Mode;
   use type DFL.Dependency_State;
   use type DFL.Dataflow_Legality_Status;
   use type DFL.Dataflow_Context_Info;
   use type DFL.Dataflow_Legality_Info;
   use type DFL.Dataflow_Context_Model;
   use type DFL.Dataflow_Result_Set;
   use type DFL.Dataflow_Legality_Model;
   package EPL renames Editor.Ada_Elaboration_Precision_Legality;
   use type EPL.Elaboration_Legality_Status;
   use type EPL.Elaboration_Order_State;
   use type EPL.Elaboration_Policy_State;
   use type EPL.Dataflow_Legality_Status;
   use type EPL.Generic_Body_Expansion_Status;
   use type EPL.Preference_Legality_Status;
   use type EPL.Accessibility_Precision_Status;
   use type EPL.Elaboration_Precision_Context_Id;
   use type EPL.Elaboration_Precision_Legality_Id;
   use type EPL.Elaboration_Precision_Context_Kind;
   use type EPL.Elaboration_Precision_Status;
   use type EPL.Elaboration_Precision_Context_Info;
   use type EPL.Elaboration_Precision_Legality_Info;
   use type EPL.Elaboration_Precision_Context_Model;
   use type EPL.Elaboration_Precision_Result_Set;
   use type EPL.Elaboration_Precision_Legality_Model;
   package APL renames Editor.Ada_Accessibility_Precision_Legality;
   use type APL.Accessibility_Legality_Status;
   use type APL.Accessibility_Level;
   use type APL.Access_Context_Kind;
   use type APL.Record_Aggregate_Legality_Status;
   use type APL.Generic_Body_Expansion_Status;
   use type APL.Accessibility_Precision_Context_Id;
   use type APL.Accessibility_Precision_Legality_Id;
   use type APL.Accessibility_Precision_Context_Kind;
   use type APL.Accessibility_Precision_Status;
   use type APL.Accessibility_Precision_Context_Info;
   use type APL.Accessibility_Precision_Legality_Info;
   use type APL.Accessibility_Precision_Context_Model;
   use type APL.Accessibility_Precision_Result_Set;
   use type APL.Accessibility_Precision_Legality_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Tasking_Protected_Precision_Legality_Pass1130");
   end Name;

   procedure Builds_Tasking_Protected_Precision_Closure
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : TPL.Tasking_Precision_Context_Model;
      C        : TPL.Tasking_Precision_Context_Info;
   begin
      C.Id := 1;
      C.Kind := TPL.Tasking_Precision_Context_Task_Activation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113001);
      C.Object_Name := To_Unbounded_String ("Worker");
      TPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 2;
      C.Kind := TPL.Tasking_Precision_Context_Task_Activation;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113002);
      C.Task_Activated := False;
      TPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 3;
      C.Kind := TPL.Tasking_Precision_Context_Protected_Function;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113003);
      C.Object_Name := To_Unbounded_String ("PO.State");
      C.Protected_Function_Writes_State := True;
      TPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 4;
      C.Kind := TPL.Tasking_Precision_Context_Protected_Function;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113004);
      C.Dataflow_Status := DFL.Dataflow_Legality_Write_Not_In_Global;
      TPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 5;
      C.Kind := TPL.Tasking_Precision_Context_Protected_Procedure;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113005);
      C.Protected_Procedure_Has_Barrier := True;
      TPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 6;
      C.Kind := TPL.Tasking_Precision_Context_Entry_Barrier;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113006);
      C.Entry_Name := To_Unbounded_String ("Start");
      C.Barrier_Present := False;
      TPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 7;
      C.Kind := TPL.Tasking_Precision_Context_Entry_Barrier;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113007);
      C.Entry_Name := To_Unbounded_String ("Start");
      C.Dataflow_Status := DFL.Dataflow_Legality_Read_Before_Write;
      TPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 8;
      C.Kind := TPL.Tasking_Precision_Context_Entry_Family_Index;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113008);
      C.Entry_Family_Index_Static := False;
      TPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 9;
      C.Kind := TPL.Tasking_Precision_Context_Accept_Statement;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113009);
      C.Accept_In_Task_Body := False;
      TPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 10;
      C.Kind := TPL.Tasking_Precision_Context_Requeue_Statement;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113010);
      C.Requeue_With_Abort_Allowed := False;
      TPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 11;
      C.Kind := TPL.Tasking_Precision_Context_Select_Alternative;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113011);
      C.Select_Terminate_With_Delay := True;
      TPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 12;
      C.Kind := TPL.Tasking_Precision_Context_Queued_Entry_Call;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113012);
      C.Accessibility_Status := APL.Accessibility_Precision_Access_Parameter_Escapes;
      TPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 13;
      C.Kind := TPL.Tasking_Precision_Context_Protected_Object_State;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113013);
      C.Object_Name := To_Unbounded_String ("PO.State");
      C.Protected_State_Finalized := True;
      TPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 14;
      C.Kind := TPL.Tasking_Precision_Context_Task_Body;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113014);
      C.Elaboration_Status := EPL.Elaboration_Precision_Body_Elaborated_After_Call;
      TPL.Add_Context (Contexts, C);

      C := (others => <>);
      C.Id := 15;
      C.Kind := TPL.Tasking_Precision_Context_Protected_Entry;
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (113015);
      C.Base_Tasking_Status := BTL.Tasking_Legality_Profile_Mismatch;
      TPL.Add_Context (Contexts, C);

      declare
         Model : constant TPL.Tasking_Precision_Legality_Model := TPL.Build (Contexts);
         State_Rows : constant TPL.Tasking_Precision_Result_Set :=
           TPL.Rows_For_Object (Model, "PO.State");
         Barrier_Rows : constant TPL.Tasking_Precision_Result_Set :=
           TPL.Rows_For_Entry (Model, "Start");
      begin
         Assert (TPL.Legality_Count (Model) = 15,
                 "all tasking precision contexts should produce rows");
         Assert (TPL.Legal_Count (Model) = 1,
                 "only the first activation context should be legal");
         Assert (TPL.Error_Count (Model) = 14,
                 "remaining tasking precision rows should be errors");
         Assert (TPL.Activation_Error_Count (Model) = 2,
                 "task activation and elaboration-linked errors should be counted");
         Assert (TPL.Protected_Operation_Error_Count (Model) = 3,
                 "protected function/procedure effect errors should be counted");
         Assert (TPL.Barrier_Error_Count (Model) = 3,
                 "barrier and entry family index errors should be counted");
         Assert (TPL.Accept_Requeue_Error_Count (Model) = 2,
                 "accept/requeue flow errors should be counted");
         Assert (TPL.Select_Error_Count (Model) = 1,
                 "select alternative errors should be counted");
         Assert (TPL.State_Error_Count (Model) = 2,
                 "queued-call and finalized-state errors should be counted");
         Assert (TPL.Linked_Error_Count (Model) = 1,
                 "linked base tasking error should be counted");
         Assert (TPL.Result_Count (State_Rows) = 2,
                 "object lookup should preserve protected-state rows");
         Assert (TPL.Result_Count (Barrier_Rows) = 2,
                 "entry lookup should preserve barrier rows");
         Assert (TPL.First_For_Node
                   (Model, Editor.Ada_Syntax_Tree.Node_Id (113003)).Status =
                 TPL.Tasking_Precision_Protected_Function_Writes_State,
                 "node lookup should preserve protected-function classification");
         Assert (TPL.Count_Status
                   (Model, TPL.Tasking_Precision_Requeue_With_Abort_Not_Allowed) = 1,
                 "requeue-with-abort restriction should be classified directly");
         Assert (TPL.Count_Kind
                   (Model, TPL.Tasking_Precision_Context_Entry_Barrier) = 2,
                 "kind lookup should preserve both entry-barrier contexts");
         Assert (TPL.Fingerprint (Model) /= 0,
                 "tasking precision legality fingerprint should be deterministic and non-zero");
      end;
   end Builds_Tasking_Protected_Precision_Closure;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Builds_Tasking_Protected_Precision_Closure'Access,
         "builds tasking/protected precision legality closure");
   end Register_Tests;

end Test_Ada_Tasking_Protected_Precision_Legality_Pass1130;
