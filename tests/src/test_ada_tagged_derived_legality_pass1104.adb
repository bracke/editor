with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Dispatching_Call_Legality;
with Editor.Ada_Return_Legality;
with Editor.Ada_Tagged_Derived_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Tagged_Derived_Legality_Pass1104 is

   package TD renames Editor.Ada_Tagged_Derived_Legality;
   use type TD.Tagged_Context_Id;
   use type TD.Tagged_Legality_Id;
   use type TD.Tagged_Context_Kind;
   use type TD.Tagged_Legality_Status;
   use type TD.Tagged_Context_Info;
   use type TD.Tagged_Legality_Info;
   use type TD.Tagged_Context_Model;
   use type TD.Tagged_Result_Set;
   use type TD.Tagged_Legality_Model;
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
   package DL renames Editor.Ada_Dispatching_Call_Legality;
   use type DL.Expression_Info;
   use type DL.Dispatching_Legality_Id;
   use type DL.Dispatching_Legality_Status;
   use type DL.Dispatching_Legality_Info;
   use type DL.Dispatching_Legality_Result_Set;
   use type DL.Dispatching_Legality_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Tagged_Derived_Legality_Pass1104");
   end Name;

   function Build
     (Contexts : TD.Tagged_Context_Model) return TD.Tagged_Legality_Model
   is
      Assignments : AL.Assignment_Legality_Model;
      Returns     : RL.Return_Legality_Model;
      Dispatching : DL.Dispatching_Legality_Model;
   begin
      return TD.Build (Contexts, Assignments, Returns, Dispatching);
   end Build;

   procedure Test_Derivation_Interface_And_Private_View_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : TD.Tagged_Context_Model;
      Context  : TD.Tagged_Context_Info;
   begin
      Context.Id := 1;
      Context.Kind := TD.Tagged_Context_Type_Derivation;
      Context.Type_Name := To_Unbounded_String ("Child");
      Context.Parent_Name := To_Unbounded_String ("Root");
      Context.Parent_Resolved := True;
      Context.Parent_Is_Tagged := True;
      Context.Derived_Is_Limited := False;
      Context.Parent_Is_Limited := False;
      TD.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 2;
      Context.Kind := TD.Tagged_Context_Interface_Derivation;
      Context.Type_Name := To_Unbounded_String ("Widget");
      Context.Parent_Name := To_Unbounded_String ("Drawable");
      Context.Interface_Operation_Present := False;
      TD.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 3;
      Context.Kind := TD.Tagged_Context_Private_Extension;
      Context.Type_Name := To_Unbounded_String ("Hidden_Child");
      Context.Private_View_Barrier := True;
      TD.Add_Context (Contexts, Context);

      declare
         Model  : constant TD.Tagged_Legality_Model := Build (Contexts);
         Child  : constant TD.Tagged_Result_Set :=
           TD.Rows_For_Type (Model, To_Unbounded_String ("Child"));
      begin
         Assert (TD.Legality_Count (Model) = 3,
                 "three tagged legality rows expected");
         Assert (TD.Compatible_Count (Model) = 1,
                 "one legal derivation expected");
         Assert (TD.Interface_Error_Count (Model) = 1,
                 "missing interface operation should be counted");
         Assert (TD.Parent_Error_Count (Model) = 1,
                 "private view barrier should be counted as parent/view error");
         Assert (TD.Result_Count (Child) = 1,
                 "type lookup should find child derivation");
         Assert (TD.Count_Status
                   (Model, TD.Tagged_Legality_Interface_Missing_Operation) = 1,
                 "missing interface operation status should be counted");
         Assert (TD.Fingerprint (Model) /= 0,
                 "tagged legality model should expose deterministic fingerprint");
      end;
   end Test_Derivation_Interface_And_Private_View_Legality;

   procedure Test_Overriding_Abstract_Dispatching_And_Conversion_Legality
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Contexts : TD.Tagged_Context_Model;
      Context  : TD.Tagged_Context_Info;
   begin
      Context.Id := 10;
      Context.Kind := TD.Tagged_Context_Overriding_Declaration;
      Context.Operation_Name := To_Unbounded_String ("Draw");
      Context.Requires_Overriding := True;
      Context.Overriding_Present := True;
      Context.Override_Is_Primitive := True;
      Context.Override_Profile_Matches := False;
      TD.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 20;
      Context.Kind := TD.Tagged_Context_Abstract_Type;
      Context.Type_Name := To_Unbounded_String ("Concrete");
      Context.Type_Is_Abstract := False;
      Context.Operation_Is_Abstract := True;
      Context.Abstract_Operation_Overridden := False;
      TD.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 30;
      Context.Kind := TD.Tagged_Context_Dispatching_Call;
      Context.Dispatch_Node := Editor.Ada_Syntax_Tree.Node_Id (44);
      Context.Controlling_Operand_Present := False;
      TD.Add_Context (Contexts, Context);

      Context := (others => <>);
      Context.Id := 40;
      Context.Kind := TD.Tagged_Context_Class_Wide_Conversion;
      Context.Class_Wide_Conversion_Compatible := False;
      TD.Add_Context (Contexts, Context);

      declare
         Model : constant TD.Tagged_Legality_Model := Build (Contexts);
         Draws : constant TD.Tagged_Result_Set :=
           TD.Rows_For_Operation (Model, To_Unbounded_String ("Draw"));
      begin
         Assert (TD.Legality_Count (Model) = 4,
                 "four tagged legality rows expected");
         Assert (TD.Override_Error_Count (Model) = 1,
                 "override profile mismatch should be counted");
         Assert (TD.Abstract_Error_Count (Model) = 1,
                 "nonabstract type with abstract operation should be counted");
         Assert (TD.Dispatching_Error_Count (Model) = 1,
                 "missing controlling operand should be counted");
         Assert (TD.Error_Count (Model) = 4,
                 "all four rows should be semantic errors");
         Assert (TD.Result_Count (Draws) = 1,
                 "operation lookup should find Draw override");
         Assert (TD.Count_Kind (Model, TD.Tagged_Context_Class_Wide_Conversion) = 1,
                 "class-wide conversion kind should be counted");
      end;
   end Test_Overriding_Abstract_Dispatching_And_Conversion_Legality;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Derivation_Interface_And_Private_View_Legality'Access,
         "tagged derivation, interface, and private view legality");
      Register_Routine
        (T, Test_Overriding_Abstract_Dispatching_And_Conversion_Legality'Access,
         "overriding, abstract operation, dispatching, and conversion legality");
   end Register_Tests;

end Test_Ada_Tagged_Derived_Legality_Pass1104;
