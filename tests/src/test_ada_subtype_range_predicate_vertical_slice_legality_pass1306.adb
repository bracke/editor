with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Subtype_Range_Predicate_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Subtype_Range_Predicate_Vertical_Slice_Legality_Pass1306 is

   package SR renames Editor.Ada_Subtype_Range_Predicate_Vertical_Slice_Legality;
   use type SR.Subtype_Id;
   use type SR.Result_Id;
   use type SR.Constraint_Kind;
   use type SR.Type_Class;
   use type SR.Legality_Status;
   use type SR.Subtype_Info;
   use type SR.Result_Info;
   use type SR.Subtype_Model;
   use type SR.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Subtype_Range_Predicate_Vertical_Slice_Legality_Pass1306");
   end Name;

   procedure Add_Sub
     (Model : in out SR.Subtype_Model;
      Id    : Natural;
      Kind  : SR.Constraint_Kind;
      Text  : String;
      Base  : SR.Type_Class := SR.Type_Integer;
      Expected : SR.Type_Class := SR.Type_Integer;
      Base_Low : Long_Long_Integer := 0;
      Base_High : Long_Long_Integer := 100;
      Low : Long_Long_Integer := 0;
      High : Long_Long_Integer := 10;
      Modulus : Long_Long_Integer := 0;
      Digits_Value : Natural := 6;
      Delta_Numerator : Natural := 1;
      Delta_Denominator : Natural := 10;
      AST : Boolean := True;
      Has_Base : Boolean := True;
      Has_Static_Low : Boolean := True;
      Has_Static_High : Boolean := True;
      Has_Static_Value : Boolean := True;
      Predicate_Type : SR.Type_Class := SR.Type_Boolean;
      Predicate_Boolean : Boolean := True;
      Predicate_Static : Boolean := True;
      Predicate_In_Range : Boolean := True;
      Runtime_Check : Boolean := False;
      Index_Discrete : Boolean := True;
      Source_FP : Natural := 130600;
      AST_FP : Natural := 230600;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0)
   is
      S : SR.Subtype_Info;
   begin
      S.Id := SR.Subtype_Id (Id);
      S.Node := Editor.Ada_Syntax_Tree.Node_Id (130600 + Id);
      S.Kind := Kind;
      S.Source_Name := To_Unbounded_String (Text);
      S.Base_Type := Base;
      S.Expected_Type := Expected;
      S.Base_Low := Base_Low;
      S.Base_High := Base_High;
      S.Low := Low;
      S.High := High;
      S.Modulus := Modulus;
      S.Digits_Value := Digits_Value;
      S.Delta_Numerator := Delta_Numerator;
      S.Delta_Denominator := Delta_Denominator;
      S.Has_AST_Coverage := AST;
      S.Has_Base_Type := Has_Base;
      S.Has_Static_Lower := Has_Static_Low;
      S.Has_Static_Upper := Has_Static_High;
      S.Has_Static_Value := Has_Static_Value;
      S.Predicate_Type := Predicate_Type;
      S.Predicate_Is_Boolean := Predicate_Boolean;
      S.Predicate_Is_Static := Predicate_Static;
      S.Predicate_Value_In_Range := Predicate_In_Range;
      S.Predicate_Needs_Runtime_Check := Runtime_Check;
      S.Index_Discrete := Index_Discrete;
      S.Source_Fingerprint := Source_FP + Id;
      S.AST_Fingerprint := AST_FP + Id;
      S.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      S.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      SR.Add_Subtype (Model, S);
   end Add_Sub;

   procedure Accepts_Concrete_Subtype_Constraints
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Subs : SR.Subtype_Model;
      Results : SR.Result_Model;
   begin
      Add_Sub (Subs, 1, SR.Constraint_Range,
               "subtype Small is Integer range 1 .. 10",
               Low => 1, High => 10);
      Add_Sub (Subs, 2, SR.Constraint_Modular_Range,
               "subtype Byte_Low is Byte range 0 .. 127",
               Base => SR.Type_Modular, Expected => SR.Type_Modular,
               Base_Low => 0, Base_High => 255,
               Low => 0, High => 127, Modulus => 256);
      Add_Sub (Subs, 3, SR.Constraint_Floating_Digits,
               "type Real_6 is digits 6",
               Base => SR.Type_Real, Expected => SR.Type_Real);
      Add_Sub (Subs, 4, SR.Constraint_Fixed_Delta,
               "type Money is delta 0.01 range 0.0 .. 100.0",
               Base => SR.Type_Fixed, Expected => SR.Type_Fixed,
               Delta_Numerator => 1, Delta_Denominator => 100);
      Add_Sub (Subs, 5, SR.Constraint_Index_Range,
               "subtype Index is Positive range 1 .. 10",
               Low => 1, High => 10);

      Results := SR.Build (Subs);

      Assert (SR.Result_Count (Results) = 5, "expected five subtype rows");
      Assert (SR.Legal_Count (Results) = 5, "all complete subtype constraints should be legal");
      Assert (SR.Count_Status (Results, SR.Legality_Legal) = 5,
              "complete subtype rows should be classified legal");
      Assert (SR.Fingerprint (Results) /= 0, "result fingerprint should be stable");
   end Accepts_Concrete_Subtype_Constraints;

   procedure Rejects_Range_Modular_Digits_Delta_And_Index_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Subs : SR.Subtype_Model;
      Results : SR.Result_Model;
   begin
      Add_Sub (Subs, 1, SR.Constraint_Range,
               "subtype Bad is Integer range 10 .. 1",
               Low => 10, High => 1);
      Add_Sub (Subs, 2, SR.Constraint_Modular_Range,
               "subtype Bad_Mod is Byte range 0 .. 300",
               Base => SR.Type_Modular, Expected => SR.Type_Modular,
               Low => 0, High => 300, Modulus => 256);
      Add_Sub (Subs, 3, SR.Constraint_Floating_Digits,
               "type Bad_Real is digits 0",
               Base => SR.Type_Real, Expected => SR.Type_Real,
               Digits_Value => 0);
      Add_Sub (Subs, 4, SR.Constraint_Fixed_Delta,
               "type Bad_Fixed is delta 0.0 range 0.0 .. 1.0",
               Base => SR.Type_Fixed, Expected => SR.Type_Fixed,
               Delta_Numerator => 0);
      Add_Sub (Subs, 5, SR.Constraint_Index_Range,
               "A : array (Float range 1.0 .. 2.0) of Integer",
               Base => SR.Type_Real, Expected => SR.Type_Real,
               Index_Discrete => False);

      Results := SR.Build (Subs);

      Assert (SR.Error_Count (Results) = 5, "all invalid constraint rows should reject");
      Assert (SR.Count_Status (Results, SR.Legality_Range_Null) = 1,
              "null range should be classified");
      Assert (SR.Count_Status (Results, SR.Legality_Modular_Range_Invalid) = 1,
              "modular range overflow should be classified");
      Assert (SR.Count_Status (Results, SR.Legality_Digits_Invalid) = 1,
              "invalid digits value should be classified");
      Assert (SR.Count_Status (Results, SR.Legality_Delta_Invalid) = 1,
              "invalid delta value should be classified");
      Assert (SR.Count_Status (Results, SR.Legality_Index_Not_Discrete) = 1,
              "non-discrete index subtype should be classified");
   end Rejects_Range_Modular_Digits_Delta_And_Index_Errors;

   procedure Checks_Static_And_Dynamic_Predicates
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Subs : SR.Subtype_Model;
      Results : SR.Result_Model;
   begin
      Add_Sub (Subs, 1, SR.Constraint_Static_Predicate,
               "subtype Even is Integer with Static_Predicate => Even mod 2 = 0",
               Predicate_Static => True,
               Predicate_In_Range => True);
      Add_Sub (Subs, 2, SR.Constraint_Predicate,
               "subtype Bad is Integer with Predicate => 42",
               Predicate_Type => SR.Type_Integer,
               Predicate_Boolean => False);
      Add_Sub (Subs, 3, SR.Constraint_Static_Predicate,
               "subtype Bad_Static is Integer with Static_Predicate => F (X)",
               Predicate_Static => False);
      Add_Sub (Subs, 4, SR.Constraint_Static_Predicate,
               "subtype Outside is Integer range 1 .. 10 with Static_Predicate => 20",
               Predicate_In_Range => False);
      Add_Sub (Subs, 5, SR.Constraint_Dynamic_Predicate,
               "subtype Runtime_Checked is Integer with Dynamic_Predicate => F (Runtime_Checked)",
               Predicate_Static => False,
               Runtime_Check => True);

      Results := SR.Build (Subs);

      Assert (SR.Count_Status (Results, SR.Legality_Legal) = 1,
              "static Boolean predicate in range should be legal");
      Assert (SR.Count_Status (Results, SR.Legality_Predicate_Not_Boolean) = 1,
              "non-Boolean predicate should reject");
      Assert (SR.Count_Status (Results, SR.Legality_Static_Predicate_Not_Static) = 1,
              "non-static static predicate should reject");
      Assert (SR.Count_Status (Results, SR.Legality_Static_Predicate_Out_Of_Range) = 1,
              "static predicate outside range should reject");
      Assert (SR.Count_Status (Results, SR.Legality_Legal_With_Runtime_Check) = 1,
              "dynamic predicate should be legal with runtime check");
   end Checks_Static_And_Dynamic_Predicates;

   procedure Preserves_AST_Fingerprint_Multiple_And_Indeterminate_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Subs : SR.Subtype_Model;
      Results : SR.Result_Model;
   begin
      Add_Sub (Subs, 1, SR.Constraint_Range,
               "subtype Missing_AST is Integer range 1 .. 10",
               AST => False);
      Add_Sub (Subs, 2, SR.Constraint_Range,
               "subtype Stale_Source is Integer range 1 .. 10",
               Expected_Source_FP => 99_999);
      Add_Sub (Subs, 3, SR.Constraint_Range,
               "subtype Stale_AST is Integer range 1 .. 10",
               Expected_AST_FP => 88_888);
      Add_Sub (Subs, 4, SR.Constraint_Range,
               "subtype Many is Integer range 20 .. 10",
               Low => 20, High => 10,
               Expected_AST_FP => 77_777);
      Add_Sub (Subs, 5, SR.Constraint_Unknown,
               "unknown subtype constraint",
               Base => SR.Type_Unknown, Expected => SR.Type_Unknown,
               Has_Base => True);

      Results := SR.Build (Subs);

      Assert (SR.Count_Status (Results, SR.Legality_Missing_AST_Coverage) = 1,
              "missing AST coverage should be classified");
      Assert (SR.Count_Status (Results, SR.Legality_Source_Fingerprint_Mismatch) = 1,
              "source fingerprint mismatch should be classified");
      Assert (SR.Count_Status (Results, SR.Legality_AST_Fingerprint_Mismatch) = 1,
              "AST fingerprint mismatch should be classified");
      Assert (SR.Count_Status (Results, SR.Legality_Multiple_Blockers) = 1,
              "multiple blockers should be preserved");
      Assert (SR.Count_Status (Results, SR.Legality_Indeterminate) = 1,
              "unknown constraint should stay indeterminate");
      Assert (SR.Has_Result (SR.Result_At (Results, 1)), "first result should be present");
   end Preserves_AST_Fingerprint_Multiple_And_Indeterminate_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Concrete_Subtype_Constraints'Access,
         "accepts concrete subtype constraints");
      Register_Routine
        (T, Rejects_Range_Modular_Digits_Delta_And_Index_Errors'Access,
         "rejects range, modular, digits, delta, and index errors");
      Register_Routine
        (T, Checks_Static_And_Dynamic_Predicates'Access,
         "checks static and dynamic predicates");
      Register_Routine
        (T, Preserves_AST_Fingerprint_Multiple_And_Indeterminate_Blockers'Access,
         "preserves AST, fingerprint, multiple, and indeterminate blockers");
   end Register_Tests;

end Test_Ada_Subtype_Range_Predicate_Vertical_Slice_Legality_Pass1306;
