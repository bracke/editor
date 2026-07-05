with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Expression_Types;
with Editor.Ada_Return_Legality;
with Editor.Ada_Tasking_Protected_Legality;

package body Test_Ada_Tasking_Protected_Legality is

   package AL renames Editor.Ada_Assignment_Legality;
   use type AL.Expression_Type_Id;
   use type AL.Assignment_Context_Id;
   use type AL.Assignment_Legality_Id;
   use type AL.Assignment_Context_Kind;
   use type AL.Assignment_Target_Mode;
   use type AL.Assignment_Legality_Status;
   use type AL.Assignment_Context_Info;
   use type AL.Assignment_Legality_Info;
   use type AL.Assignment_Context_Model;
   use type AL.Assignment_Legality_Result_Set;
   use type AL.Assignment_Legality_Model;
   package CF renames Editor.Ada_Control_Flow_Legality;
   use type CF.Flow_Context_Id;
   use type CF.Flow_Legality_Id;
   use type CF.Flow_Context_Kind;
   use type CF.Flow_Legality_Status;
   use type CF.Flow_Context_Info;
   use type CF.Flow_Legality_Info;
   use type CF.Flow_Context_Model;
   use type CF.Flow_Legality_Result_Set;
   use type CF.Flow_Legality_Model;
   package RL renames Editor.Ada_Return_Legality;
   use type RL.Assignment_Context_Id;
   use type RL.Assignment_Legality_Status;
   use type RL.Return_Context_Id;
   use type RL.Return_Legality_Id;
   use type RL.Return_Context_Kind;
   use type RL.Return_Legality_Status;
   use type RL.Return_Context_Info;
   use type RL.Return_Legality_Info;
   use type RL.Return_Context_Model;
   use type RL.Return_Legality_Result_Set;
   use type RL.Return_Legality_Model;
   package TL renames Editor.Ada_Tasking_Protected_Legality;
   use type TL.Tasking_Context_Id;
   use type TL.Tasking_Legality_Id;
   use type TL.Tasking_Context_Kind;
   use type TL.Tasking_Legality_Status;
   use type TL.Tasking_Context_Info;
   use type TL.Tasking_Legality_Info;
   use type TL.Tasking_Context_Model;
   use type TL.Tasking_Result_Set;
   use type TL.Tasking_Legality_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Tasking_Protected_Legality");
   end Name;

   function Empty_Flow return CF.Flow_Legality_Model is
      Assignment_Contexts : AL.Assignment_Context_Model;
      Expressions         : Editor.Ada_Expression_Types.Expression_Type_Model;
      Assignments         : constant AL.Assignment_Legality_Model :=
        AL.Build (Assignment_Contexts, Expressions);
      Return_Contexts     : RL.Return_Context_Model;
      Returns             : constant RL.Return_Legality_Model :=
        RL.Build (Return_Contexts, Assignments);
      Flow_Contexts       : CF.Flow_Context_Model;
   begin
      return CF.Build (Flow_Contexts, Returns);
   end Empty_Flow;

   function Flow_With_Illegal_Accept return CF.Flow_Legality_Model is
      Assignment_Contexts : AL.Assignment_Context_Model;
      Expressions         : Editor.Ada_Expression_Types.Expression_Type_Model;
      Assignments         : constant AL.Assignment_Legality_Model :=
        AL.Build (Assignment_Contexts, Expressions);
      Return_Contexts     : RL.Return_Context_Model;
      Returns             : constant RL.Return_Legality_Model :=
        RL.Build (Return_Contexts, Assignments);
      Flow_Contexts       : CF.Flow_Context_Model;
      Context             : CF.Flow_Context_Info;
   begin
      Context.Id := 1;
      Context.Kind := CF.Flow_Context_Accept_Statement;
      Context.Accept_Entry_Resolved := False;
      CF.Add_Context (Flow_Contexts, Context);
      return CF.Build (Flow_Contexts, Returns);
   end Flow_With_Illegal_Accept;

   procedure Test_Task_Protected_Spec_Body_And_Entries
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : TL.Tasking_Context_Model;
      Context  : TL.Tasking_Context_Info;
      Flow     : constant CF.Flow_Legality_Model := Empty_Flow;
   begin
      Context.Id := 1;
      Context.Kind := TL.Tasking_Context_Task_Body;
      Context.Unit_Name := To_Unbounded_String ("Worker");
      Context.Spec_Resolved := True;
      Context.Kind_Matches := True;
      Context.Profile_Matches := True;
      TL.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 2;
      Context.Kind := TL.Tasking_Context_Protected_Body;
      Context.Unit_Name := To_Unbounded_String ("Store");
      Context.Spec_Resolved := False;
      TL.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 3;
      Context.Kind := TL.Tasking_Context_Entry_Body;
      Context.Entry_Name := To_Unbounded_String ("Put");
      Context.Entry_Resolved := True;
      Context.Profile_Matches := False;
      TL.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 4;
      Context.Kind := TL.Tasking_Context_Entry_Family;
      Context.Entry_Name := To_Unbounded_String ("Slot");
      Context.Entry_Is_Family := True;
      Context.Entry_Family_Index_Resolved := True;
      Context.Entry_Family_Index_Compatible := False;
      TL.Add_Context (Contexts, Context);

      declare
         Model : constant TL.Tasking_Legality_Model := TL.Build (Contexts, Flow);
         Store : constant TL.Tasking_Result_Set :=
           TL.Rows_For_Unit (Model, To_Unbounded_String ("Store"));
      begin
         Assert (TL.Legality_Count (Model) = 4,
                 "four tasking legality rows expected");
         Assert (TL.Compatible_Count (Model) = 1,
                 "task body should be compatible");
         Assert (TL.Spec_Body_Error_Count (Model) = 2,
                 "missing spec and profile mismatch should be spec/body errors");
         Assert (TL.Entry_Error_Count (Model) = 1,
                 "entry family index mismatch should be counted");
         Assert (TL.Result_Count (Store) = 1,
                 "unit lookup should find protected body row");
         Assert (TL.Count_Status
                   (Model, TL.Tasking_Legality_Entry_Family_Index_Mismatch) = 1,
                 "entry-family index mismatch status should be counted");
         Assert (TL.Fingerprint (Model) /= 0,
                 "tasking model should expose deterministic fingerprint");
      end;
   end Test_Task_Protected_Spec_Body_And_Entries;

   procedure Test_Barrier_Accept_Requeue_And_Protected_Operation_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : TL.Tasking_Context_Model;
      Context  : TL.Tasking_Context_Info;
      Flow     : constant CF.Flow_Legality_Model := Flow_With_Illegal_Accept;
   begin
      Context.Id := 10;
      Context.Kind := TL.Tasking_Context_Protected_Entry;
      Context.Entry_Name := To_Unbounded_String ("Take");
      Context.Barrier_Present := True;
      Context.Barrier_Type_Resolved := True;
      Context.Barrier_Is_Boolean := False;
      TL.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 20;
      Context.Kind := TL.Tasking_Context_Accept_Statement;
      Context.Entry_Name := To_Unbounded_String ("Serve");
      Context.Accept_Is_In_Task_Body := False;
      TL.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 30;
      Context.Kind := TL.Tasking_Context_Requeue_Statement;
      Context.Entry_Name := To_Unbounded_String ("Other");
      Context.Requeue_Target_Resolved := True;
      Context.Requeue_Target_Is_Entry := False;
      TL.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 40;
      Context.Kind := TL.Tasking_Context_Protected_Function;
      Context.Protected_Function_Modifies_State := True;
      TL.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 50;
      Context.Kind := TL.Tasking_Context_Select_Statement;
      Context.Flow_Legality := 1;
      TL.Add_Context (Contexts, Context);

      declare
         Model : constant TL.Tasking_Legality_Model := TL.Build (Contexts, Flow);
         Other : constant TL.Tasking_Result_Set :=
           TL.Rows_For_Entry (Model, To_Unbounded_String ("Other"));
      begin
         Assert (TL.Barrier_Error_Count (Model) = 1,
                 "non-Boolean protected barrier should be rejected");
         Assert (TL.Accept_Requeue_Error_Count (Model) = 2,
                 "accept outside task and requeue to non-entry should be rejected");
         Assert (TL.Protected_Operation_Error_Count (Model) = 1,
                 "state-modifying protected function should be rejected");
         Assert (TL.Flow_Error_Count (Model) = 1,
                 "linked illegal flow row should be surfaced");
         Assert (TL.Error_Count (Model) = 5,
                 "five illegal tasking/protected rows expected");
         Assert (TL.Result_Count (Other) = 1,
                 "entry lookup should find requeue target row");
      end;
   end Test_Barrier_Accept_Requeue_And_Protected_Operation_Legality;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Task_Protected_Spec_Body_And_Entries'Access,
         "Case 1103 task/protected spec-body and entry legality");
      Register_Routine
        (T, Test_Barrier_Accept_Requeue_And_Protected_Operation_Legality'Access,
         "Case 1103 barrier/accept/requeue/protected-operation legality");
   end Register_Tests;

end Test_Ada_Tasking_Protected_Legality;
