with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Expression_Types;
with Editor.Ada_Return_Legality;

package body Test_Ada_Control_Flow_Legality is

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

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Control_Flow_Legality");
   end Name;

   function Empty_Returns return RL.Return_Legality_Model is
      Assignment_Contexts : AL.Assignment_Context_Model;
      Expressions         : Editor.Ada_Expression_Types.Expression_Type_Model;
      Assignments         : constant AL.Assignment_Legality_Model :=
        AL.Build (Assignment_Contexts, Expressions);
      Return_Contexts     : RL.Return_Context_Model;
   begin
      return RL.Build (Return_Contexts, Assignments);
   end Empty_Returns;

   procedure Test_Boolean_Case_And_Target_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CF.Flow_Context_Model;
      Context  : CF.Flow_Context_Info;
      Returns  : constant RL.Return_Legality_Model := Empty_Returns;
   begin
      Context.Id := 1;
      Context.Kind := CF.Flow_Context_If_Statement;
      Context.Condition_Type_Resolved := True;
      Context.Condition_Is_Boolean := True;
      Context.Condition_Subtype := To_Unbounded_String ("Boolean");
      CF.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 2;
      Context.Kind := CF.Flow_Context_While_Loop;
      Context.Condition_Type_Resolved := True;
      Context.Condition_Is_Boolean := False;
      Context.Condition_Subtype := To_Unbounded_String ("Integer");
      CF.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 3;
      Context.Kind := CF.Flow_Context_Case_Statement;
      Context.Case_Expression_Resolved := True;
      Context.Case_Choices_Static := True;
      Context.Case_Choices_Complete := False;
      Context.Case_Expression_Subtype := To_Unbounded_String ("Color");
      CF.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 4;
      Context.Kind := CF.Flow_Context_Goto_Statement;
      Context.Goto_Target_Resolved := False;
      Context.Target_Name := To_Unbounded_String ("Missing_Label");
      CF.Add_Context (Contexts, Context);

      declare
         Model : constant CF.Flow_Legality_Model := CF.Build (Contexts, Returns);
      begin
         Assert (CF.Legality_Count (Model) = 4,
                 "four flow legality rows expected");
         Assert (CF.Compatible_Count (Model) = 1,
                 "only the Boolean if condition should be compatible");
         Assert (CF.Boolean_Context_Error_Count (Model) = 1,
                 "non-Boolean while condition should be rejected");
         Assert (CF.Case_Error_Count (Model) = 1,
                 "incomplete case choices should be rejected");
         Assert (CF.Exit_Goto_Error_Count (Model) = 1,
                 "missing goto target should be rejected");
         Assert (CF.Count_Status
                   (Model, CF.Flow_Legality_Condition_Not_Boolean) = 1,
                 "condition-not-Boolean status should be counted");
         Assert (CF.Fingerprint (Model) /= 0,
                 "flow legality model should expose deterministic fingerprint");
      end;
   end Test_Boolean_Case_And_Target_Legality;

   procedure Test_Exception_Tasking_And_Return_Path_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : CF.Flow_Context_Model;
      Context  : CF.Flow_Context_Info;
      Returns  : constant RL.Return_Legality_Model := Empty_Returns;
   begin
      Context.Id := 10;
      Context.Kind := CF.Flow_Context_Exception_Handler;
      Context.Exception_Choice_Resolved := True;
      Context.Exception_Choice_Duplicate := True;
      CF.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 20;
      Context.Kind := CF.Flow_Context_Accept_Statement;
      Context.Accept_Entry_Resolved := False;
      CF.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 30;
      Context.Kind := CF.Flow_Context_Subprogram_Body;
      Context.Subprogram_Requires_Return := True;
      Context.Subprogram_Has_Complete_Return_Path := False;
      CF.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 40;
      Context.Kind := CF.Flow_Context_Label;
      Context.Label_Is_Duplicate := False;
      Context.Target_Name := To_Unbounded_String ("Done");
      CF.Add_Context (Contexts, Context);

      declare
         Model : constant CF.Flow_Legality_Model := CF.Build (Contexts, Returns);
         Labels : constant CF.Flow_Legality_Result_Set :=
           CF.Rows_For_Target (Model, To_Unbounded_String ("Done"));
      begin
         Assert (CF.Exception_Error_Count (Model) = 1,
                 "duplicate exception choice should be rejected");
         Assert (CF.Tasking_Error_Count (Model) = 1,
                 "missing accept entry should be rejected");
         Assert (CF.Return_Path_Error_Count (Model) = 1,
                 "missing function return path should be rejected");
         Assert (CF.Compatible_Count (Model) = 1,
                 "legal label should remain compatible");
         Assert (CF.Result_Count (Labels) = 1,
                 "target-name lookup should find the label row");
      end;
   end Test_Exception_Tasking_And_Return_Path_Legality;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Boolean_Case_And_Target_Legality'Access,
         "Case 1102 control-flow Boolean/case/target legality");
      Register_Routine
        (T, Test_Exception_Tasking_And_Return_Path_Legality'Access,
         "Case 1102 exception/tasking/return-path legality");
   end Register_Tests;

end Test_Ada_Control_Flow_Legality;
