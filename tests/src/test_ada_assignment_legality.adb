with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Declarative_Regions;
with Editor.Ada_Direct_Visibility;
with Editor.Ada_Expression_Types;
with Editor.Ada_Static_Expressions;
with Editor.Ada_Subtype_Compatibility;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Type_Graph;
with Editor.Ada_View_Aware_Compatibility;

package body Test_Ada_Assignment_Legality is

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
   use type Editor.Ada_Subtype_Compatibility.Compatibility_Status;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Assignment_Legality");
   end Name;

   procedure Add
     (Contexts : in out AL.Assignment_Context_Model;
      Context  : AL.Assignment_Context_Info) is
   begin
      AL.Add_Context (Contexts, Context);
   end Add;

   function Build
     (Contexts : AL.Assignment_Context_Model)
      return AL.Assignment_Legality_Model is
      Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
   begin
      return AL.Build (Contexts, Expressions);
   end Build;

   procedure Test_Compatible_Static_Assignment
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : AL.Assignment_Context_Model;
      Context  : AL.Assignment_Context_Info;
   begin
      Context.Kind := AL.Assignment_Context_Assignment_Statement;
      Context.Target_Mode := AL.Assignment_Target_Variable;
      Context.Target_Subtype := To_Unbounded_String ("Integer");
      Context.Source_Subtype := To_Unbounded_String ("Integer");
      Context.Source_Static_Status := Editor.Ada_Static_Expressions.Static_Value_Integer;
      Context.Source_Static_Integer_Value := 4;
      Context.Target_Has_Static_Range := True;
      Context.Target_Static_First := 1;
      Context.Target_Static_Last := 10;
      Add (Contexts, Context);

      declare
         Model : constant AL.Assignment_Legality_Model := Build (Contexts);
         Info  : constant AL.Assignment_Legality_Info := AL.Legality_At (Model, 1);
      begin
         Assert (AL.Legality_Count (Model) = 1,
                 "one assignment legality row expected");
         Assert (Info.Status = AL.Assignment_Legality_Static_Range_Compatible,
                 "static integer assignment should be range-compatible");
         Assert (AL.Compatible_Count (Model) = 1,
                 "compatible static assignment should count as compatible");
         Assert (AL.Error_Count (Model) = 0,
                 "compatible static assignment should not be an error");
         Assert (AL.Fingerprint (Model) /= 0,
                 "assignment legality model should expose deterministic fingerprint");
      end;
   end Test_Compatible_Static_Assignment;

   procedure Test_Static_Range_And_Null_Exclusion_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : AL.Assignment_Context_Model;
      Range_Context : AL.Assignment_Context_Info;
      Null_Context  : AL.Assignment_Context_Info;
   begin
      Range_Context.Kind := AL.Assignment_Context_Object_Initialization;
      Range_Context.Target_Mode := AL.Assignment_Target_Variable;
      Range_Context.Target_Subtype := To_Unbounded_String ("Small_Int");
      Range_Context.Source_Subtype := To_Unbounded_String ("Integer");
      Range_Context.Source_Static_Status := Editor.Ada_Static_Expressions.Static_Value_Integer;
      Range_Context.Source_Static_Integer_Value := 99;
      Range_Context.Target_Has_Static_Range := True;
      Range_Context.Target_Static_First := 1;
      Range_Context.Target_Static_Last := 10;
      Add (Contexts, Range_Context);

      Null_Context.Kind := AL.Assignment_Context_Object_Initialization;
      Null_Context.Target_Mode := AL.Assignment_Target_Variable;
      Null_Context.Target_Subtype := To_Unbounded_String ("access Integer");
      Null_Context.Source_Subtype := To_Unbounded_String ("access Integer");
      Null_Context.Target_Is_Null_Excluding := True;
      Null_Context.Source_Is_Null_Literal := True;
      Add (Contexts, Null_Context);

      declare
         Model : constant AL.Assignment_Legality_Model := Build (Contexts);
      begin
         Assert (AL.Legality_Count (Model) = 2,
                 "two assignment legality rows expected");
         Assert (AL.Static_Range_Violation_Count (Model) = 1,
                 "one static range violation expected");
         Assert (AL.Null_Exclusion_Violation_Count (Model) = 1,
                 "one null-exclusion violation expected");
         Assert (AL.Error_Count (Model) = 2,
                 "range and null-exclusion violations should be errors");
      end;
   end Test_Static_Range_And_Null_Exclusion_Errors;

   procedure Test_Derived_Specific_Assignment_Requires_Explicit_Conversion
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Source : constant String :=
        "package body Client is" & ASCII.LF &
        "   type Amount is range 0 .. 100;" & ASCII.LF &
        "   type USD is new Amount;" & ASCII.LF &
        "begin" & ASCII.LF &
        "   null;" & ASCII.LF &
        "end Client;";
      Tree : constant Editor.Ada_Syntax_Tree.Tree_Type :=
        Editor.Ada_Syntax_Tree.Parse (Source);
      Regions : constant Editor.Ada_Declarative_Regions.Region_Model :=
        Editor.Ada_Declarative_Regions.Build (Tree);
      Visibility : constant Editor.Ada_Direct_Visibility.Visibility_Model :=
        Editor.Ada_Direct_Visibility.Build (Tree, Regions);
      Types : constant Editor.Ada_Type_Graph.Type_Model :=
        Editor.Ada_Type_Graph.Build (Tree, Regions, Visibility);
      Expressions : Editor.Ada_Expression_Types.Expression_Type_Model;
      Views : Editor.Ada_View_Aware_Compatibility.View_Compatibility_Model;
      Contexts : AL.Assignment_Context_Model;
      Context : AL.Assignment_Context_Info;
   begin
      Context.Kind := AL.Assignment_Context_Object_Initialization;
      Context.Target_Mode := AL.Assignment_Target_Variable;
      Context.Target_Subtype := To_Unbounded_String ("Amount");
      Context.Source_Subtype := To_Unbounded_String ("USD");
      Add (Contexts, Context);

      declare
         Model : constant AL.Assignment_Legality_Model :=
           AL.Build_With_Type_Graph (Contexts, Expressions, Views, Types);
         Info : constant AL.Assignment_Legality_Info := AL.Legality_At (Model, 1);
      begin
         Assert (Info.Subtype_Status =
                 Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Type_Graph_Derived_From,
                 "assignment legality must retain type-graph derived subtype evidence");
         Assert (Info.Status = AL.Assignment_Legality_Incompatible_Subtype,
                 "assignment legality must require explicit conversions for distinct derived specific types");
         Assert (AL.Compatible_Count (Model) = 0,
                 "derived specific assignment must not count as assignment-compatible");
         Assert (AL.Error_Count (Model) = 1,
                 "derived specific assignment without conversion should be an error");
      end;
   end Test_Derived_Specific_Assignment_Requires_Explicit_Conversion;

   procedure Test_Constant_In_Formal_And_Lookups
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : AL.Assignment_Context_Model;
      Constant_Context : AL.Assignment_Context_Info;
      Formal_Context   : AL.Assignment_Context_Info;
   begin
      Constant_Context.Id := 10;
      Constant_Context.Kind := AL.Assignment_Context_Assignment_Statement;
      Constant_Context.Target_Mode := AL.Assignment_Target_Constant;
      Constant_Context.Target_Subtype := To_Unbounded_String ("Integer");
      Constant_Context.Source_Subtype := To_Unbounded_String ("Integer");
      Add (Contexts, Constant_Context);

      Formal_Context.Id := 20;
      Formal_Context.Kind := AL.Assignment_Context_Assignment_Statement;
      Formal_Context.Target_Mode := AL.Assignment_Target_In_Formal;
      Formal_Context.Target_Subtype := To_Unbounded_String ("Integer");
      Formal_Context.Source_Subtype := To_Unbounded_String ("Integer");
      Add (Contexts, Formal_Context);

      declare
         Model : constant AL.Assignment_Legality_Model := Build (Contexts);
         Row   : AL.Assignment_Legality_Info;
         Rows  : AL.Assignment_Legality_Result_Set;
      begin
         Assert (AL.Constant_Target_Count (Model) = 1,
                 "assignment to constant should be classified");
         Assert (AL.In_Formal_Target_Count (Model) = 1,
                 "assignment to in-mode formal should be classified");

         Row := AL.First_For_Context (Model, 10);
         Assert (AL.Has_Legality (Row)
                 and then Row.Status = AL.Assignment_Legality_Assignment_To_Constant,
                 "lookup by context should find constant-target error");

         Rows := AL.Results_For_Status
           (Model, AL.Assignment_Legality_Assignment_To_In_Formal);
         Assert (AL.Result_Count (Rows) = 1,
                 "status lookup should find in-formal error");
      end;
   end Test_Constant_In_Formal_And_Lookups;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Compatible_Static_Assignment'Access,
         "Case 1099 accepts static in-range assignment");
      Register_Routine
        (T, Test_Static_Range_And_Null_Exclusion_Errors'Access,
         "Case 1099 rejects range and null-exclusion assignment errors");
      Register_Routine
        (T, Test_Derived_Specific_Assignment_Requires_Explicit_Conversion'Access,
         "assignment legality rejects derived specific assignments without explicit conversion");
      Register_Routine
        (T, Test_Constant_In_Formal_And_Lookups'Access,
         "Case 1099 rejects constant and in-formal assignment targets");
   end Register_Tests;

end Test_Ada_Assignment_Legality;
