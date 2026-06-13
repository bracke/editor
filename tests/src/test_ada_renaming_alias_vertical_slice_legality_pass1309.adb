with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Renaming_Alias_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Renaming_Alias_Vertical_Slice_Legality_Pass1309 is

   package RA renames Editor.Ada_Renaming_Alias_Vertical_Slice_Legality;
   use type RA.Rename_Id;
   use type RA.Result_Id;
   use type RA.Rename_Kind;
   use type RA.Entity_Kind;
   use type RA.Type_Class;
   use type RA.Mode_Kind;
   use type RA.Legality_Status;
   use type RA.Rename_Info;
   use type RA.Result_Info;
   use type RA.Rename_Model;
   use type RA.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Renaming_Alias_Vertical_Slice_Legality_Pass1309");
   end Name;

   procedure Add_Renaming
     (Model : in out RA.Rename_Model;
      Id    : Natural;
      Kind  : RA.Rename_Kind;
      Text  : String;
      AST : Boolean := True;
      Context : Boolean := True;
      Has_Target : Boolean := True;
      Target_Visible : Boolean := True;
      Expected_Kind : RA.Entity_Kind := RA.Entity_Unknown;
      Actual_Kind : RA.Entity_Kind := RA.Entity_Unknown;
      Expected_Type : RA.Type_Class := RA.Type_Unknown;
      Actual_Type : RA.Type_Class := RA.Type_Unknown;
      Expected_Mode : RA.Mode_Kind := RA.Mode_None;
      Actual_Mode : RA.Mode_Kind := RA.Mode_None;
      Constant_View : Boolean := False;
      Target_Variable : Boolean := True;
      Limited_View : Boolean := False;
      Private_View : Boolean := False;
      Full_View_Visible : Boolean := True;
      Accessibility_OK : Boolean := True;
      Subprogram_Profile_OK : Boolean := True;
      Operator_Profile_OK : Boolean := True;
      Generic_Contract_OK : Boolean := True;
      Package_Contract_OK : Boolean := True;
      Entry_Family_OK : Boolean := True;
      Alias_Cycle : Boolean := False;
      Alias_Depth : Natural := 0;
      Alias_Limit : Natural := 32;
      Predicate_OK : Boolean := True;
      Runtime_Check : Boolean := False;
      Shared_State_OK : Boolean := True;
      Universal_OK : Boolean := True;
      Source_FP : Natural := 130900;
      AST_FP : Natural := 230900;
      Subst_FP : Natural := 330900;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Subst_FP : Natural := 0)
   is
      R : RA.Rename_Info;
   begin
      R.Id := RA.Rename_Id (Id);
      R.Node := Editor.Ada_Syntax_Tree.Node_Id (130900 + Id);
      R.Kind := Kind;
      R.Source_Name := To_Unbounded_String (Text);
      R.Has_AST_Coverage := AST;
      R.Has_Context := Context;
      R.Has_Target := Has_Target;
      R.Target_Visible := Target_Visible;
      R.Expected_Target_Kind := Expected_Kind;
      R.Actual_Target_Kind := Actual_Kind;
      R.Expected_Type := Expected_Type;
      R.Actual_Type := Actual_Type;
      R.Expected_Mode := Expected_Mode;
      R.Actual_Mode := Actual_Mode;
      R.Renaming_Defines_Constant_View := Constant_View;
      R.Target_Is_Variable := Target_Variable;
      R.Target_Is_Limited_View := Limited_View;
      R.Target_Is_Private_View := Private_View;
      R.Full_View_Visible := Full_View_Visible;
      R.Accessibility_Legal := Accessibility_OK;
      R.Subprogram_Profile_Matches := Subprogram_Profile_OK;
      R.Operator_Profile_Matches := Operator_Profile_OK;
      R.Generic_Contract_Matches := Generic_Contract_OK;
      R.Package_Contract_Matches := Package_Contract_OK;
      R.Entry_Family_Profile_Matches := Entry_Family_OK;
      R.Alias_Cycle_Detected := Alias_Cycle;
      R.Alias_Depth := Alias_Depth;
      R.Alias_Depth_Limit := Alias_Limit;
      R.Predicate_Legal := Predicate_OK;
      R.Runtime_Check_Required := Runtime_Check;
      R.Shared_State_Legal := Shared_State_OK;
      R.Universal_Compatible := Universal_OK;
      R.Source_Fingerprint := Source_FP + Id;
      R.AST_Fingerprint := AST_FP + Id;
      R.Substitution_Fingerprint := Subst_FP + Id;
      R.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      R.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      R.Expected_Substitution_Fingerprint :=
        (if Expected_Subst_FP = 0 then Subst_FP + Id else Expected_Subst_FP);
      RA.Add_Renaming (Model, R);
   end Add_Renaming;

   procedure Accepts_Source_Shaped_Renamings
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : RA.Rename_Model;
      Results : RA.Result_Model;
   begin
      Add_Renaming (Model, 1, RA.Rename_Object,
                    "X : Integer renames Obj",
                    Actual_Kind => RA.Entity_Object,
                    Expected_Type => RA.Type_Integer,
                    Actual_Type => RA.Type_Integer,
                    Expected_Mode => RA.Mode_In_Out,
                    Actual_Mode => RA.Mode_In_Out);
      Add_Renaming (Model, 2, RA.Rename_Subprogram,
                    "procedure P renames Q",
                    Actual_Kind => RA.Entity_Subprogram,
                    Subprogram_Profile_OK => True);
      Add_Renaming (Model, 3, RA.Rename_Operator,
                    "function ""+"" renames Int_Add",
                    Actual_Kind => RA.Entity_Operator,
                    Operator_Profile_OK => True);
      Add_Renaming (Model, 4, RA.Rename_Generic_Unit,
                    "generic package G2 renames G",
                    Actual_Kind => RA.Entity_Generic_Unit,
                    Generic_Contract_OK => True);
      Add_Renaming (Model, 5, RA.Rename_Object,
                    "C : constant Integer renames Runtime_Checked",
                    Actual_Kind => RA.Entity_Constant,
                    Expected_Type => RA.Type_Integer,
                    Actual_Type => RA.Type_Universal_Integer,
                    Constant_View => True,
                    Target_Variable => False,
                    Runtime_Check => True);

      Results := RA.Build (Model);

      Assert (RA.Result_Count (Results) = 5, "expected five renaming rows");
      Assert (RA.Count_Status (Results, RA.Legality_Legal) = 4,
              "concrete renamings should be legal");
      Assert (RA.Count_Status (Results, RA.Legality_Legal_With_Runtime_Check) = 1,
              "renaming with runtime predicate evidence should remain legal with check");
      Assert (RA.Fingerprint (Results) /= 0, "result fingerprint should be stable");
   end Accepts_Source_Shaped_Renamings;

   procedure Rejects_Renamed_Target_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : RA.Rename_Model;
      Results : RA.Result_Model;
   begin
      Add_Renaming (Model, 1, RA.Rename_Object,
                    "X renames Missing", Has_Target => False);
      Add_Renaming (Model, 2, RA.Rename_Exception,
                    "E renames Hidden.E", Actual_Kind => RA.Entity_Exception,
                    Target_Visible => False);
      Add_Renaming (Model, 3, RA.Rename_Package,
                    "package P renames Some_Object",
                    Actual_Kind => RA.Entity_Object);
      Add_Renaming (Model, 4, RA.Rename_Object,
                    "X : Integer renames Flag",
                    Actual_Kind => RA.Entity_Object,
                    Expected_Type => RA.Type_Integer,
                    Actual_Type => RA.Type_Boolean);
      Add_Renaming (Model, 5, RA.Rename_Object,
                    "X : in out Integer renames C",
                    Actual_Kind => RA.Entity_Constant,
                    Expected_Mode => RA.Mode_In_Out,
                    Actual_Mode => RA.Mode_In,
                    Target_Variable => False);

      Results := RA.Build (Model);

      Assert (RA.Count_Status (Results, RA.Legality_Target_Missing) = 1,
              "missing target should be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Target_Not_Visible) = 1,
              "invisible target should be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Renamed_Kind_Mismatch) = 1,
              "wrong renamed entity kind should be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Object_Type_Mismatch) = 1,
              "object type mismatch should be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Multiple_Blockers) = 1,
              "constant nonvariable in out rename should preserve multiple blockers");
   end Rejects_Renamed_Target_Errors;

   procedure Rejects_Profile_Contract_And_Alias_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : RA.Rename_Model;
      Results : RA.Result_Model;
   begin
      Add_Renaming (Model, 1, RA.Rename_Subprogram,
                    "procedure P (X : Integer) renames Q",
                    Actual_Kind => RA.Entity_Subprogram,
                    Subprogram_Profile_OK => False);
      Add_Renaming (Model, 2, RA.Rename_Operator,
                    "function ""*"" renames Bool_And",
                    Actual_Kind => RA.Entity_Operator,
                    Operator_Profile_OK => False);
      Add_Renaming (Model, 3, RA.Rename_Generic_Unit,
                    "generic package G2 renames G",
                    Actual_Kind => RA.Entity_Generic_Unit,
                    Generic_Contract_OK => False);
      Add_Renaming (Model, 4, RA.Rename_Package,
                    "package P2 renames P",
                    Actual_Kind => RA.Entity_Package,
                    Package_Contract_OK => False);
      Add_Renaming (Model, 5, RA.Rename_Entry,
                    "entry E renames Protected_Obj.E",
                    Actual_Kind => RA.Entity_Entry,
                    Entry_Family_OK => False);
      Add_Renaming (Model, 6, RA.Rename_Object,
                    "A renames B; B renames A",
                    Actual_Kind => RA.Entity_Object,
                    Alias_Cycle => True);
      Add_Renaming (Model, 7, RA.Rename_Object,
                    "Deep renames Alias_33",
                    Actual_Kind => RA.Entity_Object,
                    Alias_Depth => 33,
                    Alias_Limit => 32);

      Results := RA.Build (Model);

      Assert (RA.Count_Status (Results, RA.Legality_Subprogram_Profile_Mismatch) = 1,
              "subprogram profile mismatch should be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Operator_Profile_Mismatch) = 1,
              "operator profile mismatch should be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Generic_Contract_Mismatch) = 1,
              "generic contract mismatch should be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Package_Contract_Mismatch) = 1,
              "package contract mismatch should be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Entry_Family_Mismatch) = 1,
              "entry family mismatch should be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Alias_Cycle) = 1,
              "alias cycle should be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Alias_Depth_Exceeded) = 1,
              "alias depth overflow should be rejected");
   end Rejects_Profile_Contract_And_Alias_Errors;

   procedure Rejects_View_Lifetime_State_And_Fingerprint_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : RA.Rename_Model;
      Results : RA.Result_Model;
   begin
      Add_Renaming (Model, 1, RA.Rename_Object,
                    "X renames Limited_View_Obj",
                    Actual_Kind => RA.Entity_Object,
                    Limited_View => True);
      Add_Renaming (Model, 2, RA.Rename_Object,
                    "X renames Private_Obj",
                    Actual_Kind => RA.Entity_Object,
                    Private_View => True,
                    Full_View_Visible => False);
      Add_Renaming (Model, 3, RA.Rename_Object,
                    "X renames Local_Access.all",
                    Actual_Kind => RA.Entity_Object,
                    Accessibility_OK => False);
      Add_Renaming (Model, 4, RA.Rename_Object,
                    "X renames Predicated_Obj",
                    Actual_Kind => RA.Entity_Object,
                    Predicate_OK => False);
      Add_Renaming (Model, 5, RA.Rename_Object,
                    "X renames Shared_State_Obj",
                    Actual_Kind => RA.Entity_Object,
                    Shared_State_OK => False);
      Add_Renaming (Model, 6, RA.Rename_Object,
                    "X renames Stale",
                    Actual_Kind => RA.Entity_Object,
                    Expected_Source_FP => 1);
      Add_Renaming (Model, 7, RA.Rename_Object,
                    "X renames Stale_AST",
                    Actual_Kind => RA.Entity_Object,
                    Expected_AST_FP => 1);
      Add_Renaming (Model, 8, RA.Rename_Generic_Unit,
                    "generic package G2 renames Stale_G",
                    Actual_Kind => RA.Entity_Generic_Unit,
                    Expected_Subst_FP => 1);

      Results := RA.Build (Model);

      Assert (RA.Count_Status (Results, RA.Legality_Limited_View_Blocked) = 1,
              "limited view should block renaming legality");
      Assert (RA.Count_Status (Results, RA.Legality_Private_View_Blocked) = 1,
              "private view should block renaming legality");
      Assert (RA.Count_Status (Results, RA.Legality_Accessibility_Blocked) = 1,
              "accessibility escape should block renaming legality");
      Assert (RA.Count_Status (Results, RA.Legality_Predicate_Blocked) = 1,
              "predicate blocker should be preserved");
      Assert (RA.Count_Status (Results, RA.Legality_Shared_State_Blocked) = 1,
              "shared-state blocker should be preserved");
      Assert (RA.Count_Status (Results, RA.Legality_Source_Fingerprint_Mismatch) = 1,
              "source fingerprint mismatch should be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_AST_Fingerprint_Mismatch) = 1,
              "AST fingerprint mismatch should be rejected");
      Assert (RA.Count_Status (Results, RA.Legality_Substitution_Fingerprint_Mismatch) = 1,
              "substitution fingerprint mismatch should be rejected");
   end Rejects_View_Lifetime_State_And_Fingerprint_Errors;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Accepts_Source_Shaped_Renamings'Access,
                        "accepts source-shaped renaming declarations");
      Register_Routine (T, Rejects_Renamed_Target_Errors'Access,
                        "rejects target visibility kind type and mode errors");
      Register_Routine (T, Rejects_Profile_Contract_And_Alias_Errors'Access,
                        "rejects profile contract and alias-chain errors");
      Register_Routine (T, Rejects_View_Lifetime_State_And_Fingerprint_Errors'Access,
                        "rejects view lifetime state and fingerprint errors");
   end Register_Tests;

end Test_Ada_Renaming_Alias_Vertical_Slice_Legality_Pass1309;
