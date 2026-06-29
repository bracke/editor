with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Expression_Types;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Return_Legality is

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
      return AUnit.Format ("Test_Ada_Return_Legality");
   end Name;

   function Build_Assignments
     (Contexts : AL.Assignment_Context_Model)
      return AL.Assignment_Legality_Model is
      Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
   begin
      return AL.Build (Contexts, Expressions);
   end Build_Assignments;

   procedure Test_Procedure_And_Function_Returns
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Assignment_Contexts : AL.Assignment_Context_Model;
      Return_Contexts     : RL.Return_Context_Model;
      A_Context           : AL.Assignment_Context_Info;
      R_Context           : RL.Return_Context_Info;
   begin
      A_Context.Id := 10;
      A_Context.Kind := AL.Assignment_Context_Object_Initialization;
      A_Context.Target_Mode := AL.Assignment_Target_Variable;
      A_Context.Target_Subtype := To_Unbounded_String ("Integer");
      A_Context.Source_Subtype := To_Unbounded_String ("Integer");
      AL.Add_Context (Assignment_Contexts, A_Context);

      R_Context.Id := 1;
      R_Context.Kind := RL.Return_Context_Procedure_Return;
      R_Context.Is_Procedure_Context := True;
      R_Context.Has_Expression := False;
      RL.Add_Context (Return_Contexts, R_Context);

      R_Context := (others => <>);
      R_Context.Id := 2;
      R_Context.Kind := RL.Return_Context_Function_Return;
      R_Context.Is_Function_Context := True;
      R_Context.Has_Expression := True;
      R_Context.Assignment_Context := 10;
      R_Context.Expected_Result_Subtype := To_Unbounded_String ("Integer");
      RL.Add_Context (Return_Contexts, R_Context);

      declare
         Assignments : constant AL.Assignment_Legality_Model :=
           Build_Assignments (Assignment_Contexts);
         Model : constant RL.Return_Legality_Model :=
           RL.Build (Return_Contexts, Assignments);
      begin
         Assert (RL.Legality_Count (Model) = 2,
                 "two return legality rows expected");
         Assert (RL.Compatible_Count (Model) = 2,
                 "procedure return and compatible function return should pass");
         Assert (RL.Error_Count (Model) = 0,
                 "compatible return contexts should not be errors");
         Assert (RL.Fingerprint (Model) /= 0,
                 "return legality model should expose deterministic fingerprint");
      end;
   end Test_Procedure_And_Function_Returns;

   procedure Test_Missing_And_Illegal_Expressions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Assignment_Contexts : AL.Assignment_Context_Model;
      Assignments         : constant AL.Assignment_Legality_Model :=
        Build_Assignments (Assignment_Contexts);
      Return_Contexts     : RL.Return_Context_Model;
      R_Context           : RL.Return_Context_Info;
   begin
      R_Context.Id := 10;
      R_Context.Kind := RL.Return_Context_Procedure_Return;
      R_Context.Is_Procedure_Context := True;
      R_Context.Has_Expression := True;
      RL.Add_Context (Return_Contexts, R_Context);

      R_Context := (others => <>);
      R_Context.Id := 20;
      R_Context.Kind := RL.Return_Context_Function_Return;
      R_Context.Is_Function_Context := True;
      R_Context.Has_Expression := False;
      RL.Add_Context (Return_Contexts, R_Context);

      R_Context := (others => <>);
      R_Context.Id := 30;
      R_Context.Kind := RL.Return_Context_No_Return_Subprogram;
      R_Context.Is_No_Return_Subprogram := True;
      RL.Add_Context (Return_Contexts, R_Context);

      declare
         Model : constant RL.Return_Legality_Model :=
           RL.Build (Return_Contexts, Assignments);
      begin
         Assert (RL.Procedure_With_Expression_Count (Model) = 1,
                 "procedure return with expression should be rejected");
         Assert (RL.Function_Missing_Expression_Count (Model) = 1,
                 "function return missing expression should be rejected");
         Assert (RL.No_Return_Subprogram_Return_Count (Model) = 1,
                 "No_Return subprogram return should be rejected");
         Assert (RL.Error_Count (Model) = 3,
                 "three return legality errors expected");
      end;
   end Test_Missing_And_Illegal_Expressions;

   procedure Test_Result_Errors_And_Lookups
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Assignment_Contexts : AL.Assignment_Context_Model;
      Return_Contexts     : RL.Return_Context_Model;
      A_Context           : AL.Assignment_Context_Info;
      R_Context           : RL.Return_Context_Info;
   begin
      A_Context.Id := 100;
      A_Context.Kind := AL.Assignment_Context_Object_Initialization;
      A_Context.Target_Mode := AL.Assignment_Target_Variable;
      A_Context.Target_Subtype := To_Unbounded_String ("Small_Int");
      A_Context.Source_Subtype := To_Unbounded_String ("Integer");
      A_Context.Source_Static_Status := Editor.Ada_Static_Expressions.Static_Value_Integer;
      A_Context.Source_Static_Integer_Value := 99;
      A_Context.Target_Has_Static_Range := True;
      A_Context.Target_Static_First := 1;
      A_Context.Target_Static_Last := 10;
      AL.Add_Context (Assignment_Contexts, A_Context);

      R_Context.Id := 1000;
      R_Context.Kind := RL.Return_Context_Function_Return;
      R_Context.Is_Function_Context := True;
      R_Context.Has_Expression := True;
      R_Context.Assignment_Context := 100;
      R_Context.Return_Node := Editor.Ada_Syntax_Tree.Node_Id (44);
      RL.Add_Context (Return_Contexts, R_Context);

      declare
         Assignments : constant AL.Assignment_Legality_Model :=
           Build_Assignments (Assignment_Contexts);
         Model : constant RL.Return_Legality_Model :=
           RL.Build (Return_Contexts, Assignments);
         Row  : RL.Return_Legality_Info;
         Rows : RL.Return_Legality_Result_Set;
      begin
         Assert (RL.Static_Range_Violation_Count (Model) = 1,
                 "static return range violation should be projected");
         Assert (RL.Error_Count (Model) = 1,
                 "range violation should count as a return error");

         Row := RL.First_For_Assignment_Context (Model, 100);
         Assert (RL.Has_Legality (Row)
                 and then Row.Status = RL.Return_Legality_Result_Static_Range_Violation,
                 "lookup by assignment context should find range violation");

         Row := RL.First_For_Return_Node (Model, Editor.Ada_Syntax_Tree.Node_Id (44));
         Assert (RL.Has_Legality (Row),
                 "lookup by return node should find return row");

         Rows := RL.Results_For_Status
           (Model, RL.Return_Legality_Result_Static_Range_Violation);
         Assert (RL.Result_Count (Rows) = 1,
                 "status lookup should find one static range violation");
      end;
   end Test_Result_Errors_And_Lookups;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Procedure_And_Function_Returns'Access,
         "Pass1100 accepts legal procedure and function returns");
      Register_Routine
        (T, Test_Missing_And_Illegal_Expressions'Access,
         "Pass1100 rejects return expression-shape errors");
      Register_Routine
        (T, Test_Result_Errors_And_Lookups'Access,
         "Pass1100 maps assignment legality into return result errors");
   end Register_Tests;

end Test_Ada_Return_Legality;
