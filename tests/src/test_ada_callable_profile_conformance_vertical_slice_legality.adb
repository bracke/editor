with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Callable_Profile_Conformance_Vertical_Slice_Legality;

package body Test_Ada_Callable_Profile_Conformance_Vertical_Slice_Legality is

   package PL renames Editor.Ada_Callable_Profile_Conformance_Vertical_Slice_Legality;
   use type PL.Callable_Id;
   use type PL.Profile_Id;
   use type PL.Type_Id;
   use type PL.Result_Id;
   use type PL.Callable_Kind;
   use type PL.Profile_Context_Kind;
   use type PL.Profile_View_Kind;
   use type PL.Profile_Status;
   use type PL.Profile_Info;
   use type PL.Callable_Info;
   use type PL.Check_Info;
   use type PL.Result_Info;
   use type PL.Callable_Model;
   use type PL.Profile_Model;
   use type PL.Check_Model;
   use type PL.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Callable_Profile_Conformance_Vertical_Slice_Legality");
   end Name;

   procedure Add_Callable
     (Model : in out PL.Callable_Model;
      Id : Natural;
      Name : String;
      Kind : PL.Callable_Kind := PL.Callable_Subprogram;
      Profile : Natural := 0;
      Source_FP : Natural := 132500;
      Expected_Source_FP : Natural := 0)
   is
      C : PL.Callable_Info;
   begin
      C.Id := PL.Callable_Id (Id);
      C.Name := To_Unbounded_String (Name);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (132500 + Id);
      C.Kind := Kind;
      C.Declared_Profile := PL.Profile_Id (Profile);
      C.Source_Fingerprint := Source_FP + Id;
      C.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      PL.Add_Callable (Model, C);
   end Add_Callable;

   procedure Add_Profile
     (Model : in out PL.Profile_Model;
      Id : Natural;
      Name : String;
      Kind : PL.Callable_Kind := PL.Callable_Subprogram;
      View : PL.Profile_View_Kind := PL.View_Full;
      Formals : Natural := 1;
      Required : Natural := 1;
      Result_Type : Natural := 1;
      Convention : String := "Ada";
      Modes_OK : Boolean := True;
      Types_OK : Boolean := True;
      Defaults_OK : Boolean := True;
      Nulls_OK : Boolean := True;
      Result_OK : Boolean := True;
      Access_OK : Boolean := True;
      Overriding_OK : Boolean := True;
      Renaming_OK : Boolean := True;
      Generic_OK : Boolean := True;
      Source_FP : Natural := 232500;
      Profile_FP : Natural := 332500;
      Type_FP : Natural := 432500;
      Expected_Source_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Type_FP : Natural := 0)
   is
      P : PL.Profile_Info;
   begin
      P.Id := PL.Profile_Id (Id);
      P.Name := To_Unbounded_String (Name);
      P.Node := Editor.Ada_Syntax_Tree.Node_Id (232500 + Id);
      P.Kind := Kind;
      P.View := View;
      P.Formal_Count := Formals;
      P.Required_Formal_Count := Required;
      P.Result_Type := PL.Type_Id (Result_Type);
      P.Convention := To_Unbounded_String (Convention);
      P.Modes_Conformant := Modes_OK;
      P.Types_Conformant := Types_OK;
      P.Default_Expressions_Conformant := Defaults_OK;
      P.Null_Exclusions_Conformant := Nulls_OK;
      P.Result_Type_Conformant := Result_OK;
      P.Access_Profile_Conformant := Access_OK;
      P.Overriding_Profile_Conformant := Overriding_OK;
      P.Renaming_Profile_Conformant := Renaming_OK;
      P.Generic_Formal_Profile_Conformant := Generic_OK;
      P.Source_Fingerprint := Source_FP + Id;
      P.Profile_Fingerprint := Profile_FP + Id;
      P.Type_Fingerprint := Type_FP + Id;
      P.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      P.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      P.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      PL.Add_Profile (Model, P);
   end Add_Profile;

   procedure Add_Check
     (Model : in out PL.Check_Model;
      Id : Natural;
      Callable : Natural;
      Declared : Natural;
      Expected : Natural;
      Context : PL.Profile_Context_Kind := PL.Context_Declaration;
      Expected_Kind : PL.Callable_Kind := PL.Callable_Subprogram;
      Actuals : Natural := 1;
      Allow_Defaults : Boolean := False;
      Require_Defaults : Boolean := False;
      Require_Result : Boolean := False;
      Require_Access : Boolean := False;
      Require_Overriding : Boolean := False;
      Require_Renaming : Boolean := False;
      Require_Generic : Boolean := False;
      Convention : String := "Ada";
      Source_FP : Natural := 532500;
      Profile_FP : Natural := 632500;
      Type_FP : Natural := 732500;
      Expected_Source_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Type_FP : Natural := 0)
   is
      C : PL.Check_Info;
   begin
      C.Id := PL.Result_Id (Id);
      C.Callable := PL.Callable_Id (Callable);
      C.Declared_Profile := PL.Profile_Id (Declared);
      C.Expected_Profile := PL.Profile_Id (Expected);
      C.Node := Editor.Ada_Syntax_Tree.Node_Id (332500 + Id);
      C.Context := Context;
      C.Expected_Kind := Expected_Kind;
      C.Actual_Count := Actuals;
      C.Allow_Defaulted_Formals := Allow_Defaults;
      C.Require_Default_Conformance := Require_Defaults;
      C.Require_Result_Conformance := Require_Result;
      C.Require_Access_Profile_Conformance := Require_Access;
      C.Require_Overriding_Conformance := Require_Overriding;
      C.Require_Renaming_Conformance := Require_Renaming;
      C.Require_Generic_Formal_Conformance := Require_Generic;
      C.Expected_Convention := To_Unbounded_String (Convention);
      C.Source_Fingerprint := Source_FP + Id;
      C.Profile_Fingerprint := Profile_FP + Id;
      C.Type_Fingerprint := Type_FP + Id;
      C.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      C.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Profile_FP + Id else Expected_Profile_FP);
      C.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      PL.Add_Check (Model, C);
   end Add_Check;

   procedure Test_Legal_Exact_Profile

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Callables : PL.Callable_Model;
      Profiles : PL.Profile_Model;
      Checks : PL.Check_Model;
      Results : PL.Result_Model;
   begin
      Add_Callable (Callables, 1, "P", Profile => 10);
      Add_Profile (Profiles, 10, "P profile");
      Add_Profile (Profiles, 20, "expected profile");
      Add_Check (Checks, 1, 1, 10, 20, Require_Result => True);
      Results := PL.Build (Callables, Profiles, Checks);
      Assert (PL.Result_Count (Results) = 1, "one result expected");
      Assert (PL.Result_At (Results, 1).Status = PL.Profile_Legal, "exact conformance accepted");
      Assert (PL.Legal_Count (Results) = 1, "legal counted");
   end Test_Legal_Exact_Profile;

   procedure Test_Defaulted_Formals

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Callables : PL.Callable_Model;
      Profiles : PL.Profile_Model;
      Checks : PL.Check_Model;
      Results : PL.Result_Model;
   begin
      Add_Callable (Callables, 1, "P", Profile => 10);
      Add_Profile (Profiles, 10, "P profile", Formals => 2, Required => 1);
      Add_Profile (Profiles, 20, "expected profile", Formals => 2, Required => 1);
      Add_Check (Checks, 1, 1, 10, 20, Actuals => 1, Allow_Defaults => True);
      Results := PL.Build (Callables, Profiles, Checks);
      Assert (PL.Result_At (Results, 1).Status = PL.Profile_Legal_Defaulted_Formals,
              "defaulted formals accepted when allowed");
   end Test_Defaulted_Formals;

   procedure Test_Arity_Mode_And_Type_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Callables : PL.Callable_Model;
      Profiles : PL.Profile_Model;
      Checks : PL.Check_Model;
      Results : PL.Result_Model;
   begin
      Add_Callable (Callables, 1, "P", Profile => 10);
      Add_Profile (Profiles, 10, "P profile", Formals => 2, Required => 2, Modes_OK => False);
      Add_Profile (Profiles, 20, "expected profile", Formals => 2, Required => 2, Types_OK => False);
      Add_Check (Checks, 1, 1, 10, 20, Actuals => 1);
      Results := PL.Build (Callables, Profiles, Checks);
      Assert (PL.Result_At (Results, 1).Status = PL.Profile_Multiple_Blockers,
              "arity plus profile conformance blockers preserved");
      Assert (PL.Error_Count (Results) = 1, "error counted");
   end Test_Arity_Mode_And_Type_Blockers;

   procedure Test_Convention_And_Result_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Callables : PL.Callable_Model;
      Profiles : PL.Profile_Model;
      Checks : PL.Check_Model;
      Results : PL.Result_Model;
   begin
      Add_Callable (Callables, 1, "F", Kind => PL.Callable_Access_Subprogram, Profile => 10);
      Add_Profile (Profiles, 10, "F profile", Kind => PL.Callable_Access_Subprogram,
                   Result_Type => 1, Convention => "C");
      Add_Profile (Profiles, 20, "expected profile", Kind => PL.Callable_Access_Subprogram,
                   Result_Type => 2, Convention => "Ada");
      Add_Check (Checks, 1, 1, 10, 20,
                 Context => PL.Context_Access_Subprogram_Conversion,
                 Expected_Kind => PL.Callable_Access_Subprogram,
                 Require_Result => True,
                 Require_Access => True,
                 Convention => "Ada");
      Results := PL.Build (Callables, Profiles, Checks);
      Assert (PL.Result_At (Results, 1).Status = PL.Profile_Multiple_Blockers,
              "convention and result mismatches are both blockers");
   end Test_Convention_And_Result_Blockers;

   procedure Test_Overriding_Renaming_And_Generic_Formal

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Callables : PL.Callable_Model;
      Profiles : PL.Profile_Model;
      Checks : PL.Check_Model;
      Results : PL.Result_Model;
   begin
      Add_Callable (Callables, 1, "Op", Kind => PL.Callable_Primitive, Profile => 10);
      Add_Profile (Profiles, 10, "primitive profile", Kind => PL.Callable_Primitive,
                   Overriding_OK => False, Renaming_OK => False, Generic_OK => False);
      Add_Profile (Profiles, 20, "expected primitive", Kind => PL.Callable_Primitive);
      Add_Check (Checks, 1, 1, 10, 20,
                 Context => PL.Context_Overriding,
                 Expected_Kind => PL.Callable_Primitive,
                 Require_Overriding => True,
                 Require_Renaming => True,
                 Require_Generic => True);
      Results := PL.Build (Callables, Profiles, Checks);
      Assert (PL.Result_At (Results, 1).Status = PL.Profile_Multiple_Blockers,
              "overriding, renaming, and generic formal mismatches preserved");
   end Test_Overriding_Renaming_And_Generic_Formal;

   procedure Test_View_And_Fingerprint_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Callables : PL.Callable_Model;
      Profiles : PL.Profile_Model;
      Checks : PL.Check_Model;
      Results : PL.Result_Model;
   begin
      Add_Callable (Callables, 1, "P", Profile => 10, Expected_Source_FP => 999);
      Add_Profile (Profiles, 10, "private profile", View => PL.View_Private);
      Add_Profile (Profiles, 20, "expected profile", Expected_Profile_FP => 888);
      Add_Check (Checks, 1, 1, 10, 20, Expected_Type_FP => 777);
      Results := PL.Build (Callables, Profiles, Checks);
      Assert (PL.Result_At (Results, 1).Status = PL.Profile_Multiple_Blockers,
              "view and stale fingerprints remain distinct blockers");
   end Test_View_And_Fingerprint_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Legal_Exact_Profile'Access, "legal exact profile conformance");
      Register_Routine (T, Test_Defaulted_Formals'Access, "defaulted formal legality");
      Register_Routine (T, Test_Arity_Mode_And_Type_Blockers'Access, "arity/mode/type blockers");
      Register_Routine (T, Test_Convention_And_Result_Blockers'Access, "convention/result blockers");
      Register_Routine (T, Test_Overriding_Renaming_And_Generic_Formal'Access,
                        "overriding renaming generic formal blockers");
      Register_Routine (T, Test_View_And_Fingerprint_Blockers'Access,
                        "view and fingerprint blockers");
   end Register_Tests;

end Test_Ada_Callable_Profile_Conformance_Vertical_Slice_Legality;
