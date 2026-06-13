with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Membership_Case_Choice_Vertical_Slice_Legality;
with Editor.Ada_Syntax_Tree;

package body Test_Ada_Membership_Case_Choice_Vertical_Slice_Legality_Pass1315 is

   package MC renames Editor.Ada_Membership_Case_Choice_Vertical_Slice_Legality;
   use type MC.Check_Id;
   use type MC.Result_Id;
   use type MC.Choice_Kind;
   use type MC.Discrete_Class;
   use type MC.Legality_Status;
   use type MC.Choice_Info;
   use type MC.Result_Info;
   use type MC.Choice_Model;
   use type MC.Result_Model;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Membership_Case_Choice_Vertical_Slice_Legality_Pass1315");
   end Name;

   procedure Add_Check
     (Model : in out MC.Choice_Model;
      Id    : Natural;
      Kind  : MC.Choice_Kind;
      Text  : String;
      Subject : MC.Discrete_Class := MC.Discrete_Integer;
      Choice  : MC.Discrete_Class := MC.Discrete_Integer;
      Expected : MC.Discrete_Class := MC.Discrete_Unknown;
      AST : Boolean := True;
      Type_Evidence : Boolean := True;
      Static_Evidence : Boolean := True;
      Subject_Discrete : Boolean := True;
      Type_OK : Boolean := True;
      Choice_Static : Boolean := True;
      Bounds_Static : Boolean := True;
      Bounds_In_Base : Boolean := True;
      Bounds_Reversed : Boolean := False;
      Null_Range_Allowed : Boolean := True;
      Runtime_Check : Boolean := False;
      Has_Choice : Boolean := True;
      Complete : Boolean := True;
      Overlap : Boolean := False;
      Others_Present_Param : Boolean := False;
      Others_Last : Boolean := True;
      Duplicate_Others : Boolean := False;
      Variant_OK : Boolean := True;
      Aggregate_OK : Boolean := True;
      Covered : Natural := 1;
      Expected_Count : Natural := 1;
      Source_FP : Natural := 131500;
      AST_FP : Natural := 231500;
      Type_FP : Natural := 331500;
      Static_FP : Natural := 431500;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Static_FP : Natural := 0)
   is
      I : MC.Choice_Info;
   begin
      I.Id := MC.Check_Id (Id);
      I.Node := Editor.Ada_Syntax_Tree.Node_Id (131500 + Id);
      I.Kind := Kind;
      I.Source_Name := To_Unbounded_String (Text);
      I.Subject_Type := Subject;
      I.Choice_Type := Choice;
      I.Expected_Type := Expected;
      I.Has_AST_Coverage := AST;
      I.Has_Type_Evidence := Type_Evidence;
      I.Has_Static_Evidence := Static_Evidence;
      I.Subject_Is_Discrete := Subject_Discrete;
      I.Choice_Type_Compatible := Type_OK;
      I.Choice_Is_Static := Choice_Static;
      I.Bounds_Are_Static := Bounds_Static;
      I.Bounds_In_Base := Bounds_In_Base;
      I.Bounds_Reversed := Bounds_Reversed;
      I.Null_Range_Allowed := Null_Range_Allowed;
      I.Runtime_Check_Allowed := Runtime_Check;
      I.Has_At_Least_One_Choice := Has_Choice;
      I.Case_Coverage_Complete := Complete;
      I.Choices_Overlap := Overlap;
      I.Others_Present := Others_Present_Param;
      I.Others_Is_Last := Others_Last;
      I.Duplicate_Others := Duplicate_Others;
      I.Variant_Governor_Compatible := Variant_OK;
      I.Aggregate_Choice_Compatible := Aggregate_OK;
      I.Low_Value := Long_Long_Integer (Id);
      I.High_Value := Long_Long_Integer (Id + 1);
      I.Covered_Choice_Count := Covered;
      I.Expected_Choice_Count := Expected_Count;
      I.Source_Fingerprint := Source_FP + Id;
      I.AST_Fingerprint := AST_FP + Id;
      I.Type_Fingerprint := Type_FP + Id;
      I.Static_Fingerprint := Static_FP + Id;
      I.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Source_FP + Id else Expected_Source_FP);
      I.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then AST_FP + Id else Expected_AST_FP);
      I.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Type_FP + Id else Expected_Type_FP);
      I.Expected_Static_Fingerprint :=
        (if Expected_Static_FP = 0 then Static_FP + Id else Expected_Static_FP);
      MC.Add_Choice (Model, I);
   end Add_Check;

   procedure Accepts_Source_Shaped_Membership_And_Case_Choices
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : MC.Choice_Model;
      Results : MC.Result_Model;
   begin
      Add_Check (Model, 1, MC.Choice_Membership_Test,
                 "X in 1 .. 10", Expected => MC.Discrete_Integer);
      Add_Check (Model, 2, MC.Choice_Not_In_Test,
                 "C not in 'A' .. 'Z'", Subject => MC.Discrete_Character,
                 Choice => MC.Discrete_Character, Expected => MC.Discrete_Character);
      Add_Check (Model, 3, MC.Choice_Case_Statement,
                 "case E is when Red | Green | Blue =>", Subject => MC.Discrete_Enumeration,
                 Choice => MC.Discrete_Enumeration, Complete => True,
                 Covered => 3, Expected_Count => 3);
      Add_Check (Model, 4, MC.Choice_Case_Expression,
                 "case B is when False => 0, when True => 1", Subject => MC.Discrete_Boolean,
                 Choice => MC.Discrete_Boolean, Complete => True,
                 Covered => 2, Expected_Count => 2);
      Add_Check (Model, 5, MC.Choice_Variant_Choice,
                 "when Kind_A => Field : Integer", Subject => MC.Discrete_Enumeration,
                 Choice => MC.Discrete_Enumeration, Variant_OK => True);
      Add_Check (Model, 6, MC.Choice_Array_Index_Choice,
                 "1 .. 3 => 0", Subject => MC.Discrete_Integer,
                 Choice => MC.Discrete_Integer, Aggregate_OK => True);

      Results := MC.Build (Model);

      Assert (MC.Result_Count (Results) = 6, "all source-shaped choices should produce results");
      Assert (MC.Legal_Count (Results) = 6, "well-typed static choices should be legal");
      Assert (MC.Error_Count (Results) = 0, "accepted choices should not emit errors");
      Assert (MC.Fingerprint (Results) /= 0, "result fingerprint should be stable and nonzero");
   end Accepts_Source_Shaped_Membership_And_Case_Choices;

   procedure Rejects_Case_Coverage_Overlap_And_Others_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : MC.Choice_Model;
      Results : MC.Result_Model;
   begin
      Add_Check (Model, 1, MC.Choice_Case_Statement,
                 "case X is -- no choices", Has_Choice => False);
      Add_Check (Model, 2, MC.Choice_Case_Statement,
                 "case Day is missing Sunday", Complete => False,
                 Covered => 6, Expected_Count => 7);
      Add_Check (Model, 3, MC.Choice_Case_Expression,
                 "when 1 .. 3 | 3 .. 5 =>", Overlap => True);
      Add_Check (Model, 4, MC.Choice_Case_Statement,
                 "when others => null; when 1 => null;", Others_Present_Param => True,
                 Others_Last => False);
      Add_Check (Model, 5, MC.Choice_Case_Statement,
                 "two others choices", Others_Present_Param => True,
                 Duplicate_Others => True);
      Add_Check (Model, 6, MC.Choice_Variant_Choice,
                 "variant with wrong governor", Subject => MC.Discrete_Enumeration,
                 Choice => MC.Discrete_Integer, Variant_OK => False);

      Results := MC.Build (Model);

      Assert (MC.Count_Status (Results, MC.Legality_Case_Missing_Choice) = 1,
              "case with no alternatives should be rejected");
      Assert (MC.Count_Status (Results, MC.Legality_Case_Incomplete) = 1,
              "incomplete case coverage should be rejected");
      Assert (MC.Count_Status (Results, MC.Legality_Case_Choice_Overlap) = 1,
              "overlapping discrete choices should be rejected");
      Assert (MC.Count_Status (Results, MC.Legality_Others_Not_Last) = 1,
              "others alternative before the last alternative should be rejected");
      Assert (MC.Count_Status (Results, MC.Legality_Duplicate_Others) = 1,
              "duplicate others choices should be rejected");
      Assert (MC.Count_Status (Results, MC.Legality_Multiple_Blockers) = 1,
              "variant with wrong choice type and wrong governor should preserve multiple blockers");
   end Rejects_Case_Coverage_Overlap_And_Others_Errors;

   procedure Rejects_Membership_Type_Static_And_Range_Errors
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : MC.Choice_Model;
      Results : MC.Result_Model;
   begin
      Add_Check (Model, 1, MC.Choice_Membership_Test,
                 "R in 1 .. 10", Subject => MC.Discrete_Not_Discrete,
                 Subject_Discrete => False);
      Add_Check (Model, 2, MC.Choice_Membership_Test,
                 "I in False .. True", Subject => MC.Discrete_Integer,
                 Choice => MC.Discrete_Boolean);
      Add_Check (Model, 3, MC.Choice_Membership_Test,
                 "I in F .. G", Choice_Static => False);
      Add_Check (Model, 4, MC.Choice_Membership_Test,
                 "I in 10 .. 1", Bounds_Reversed => True,
                 Null_Range_Allowed => False);
      Add_Check (Model, 5, MC.Choice_Membership_Test,
                 "I in Integer'First - 1 .. 0", Bounds_In_Base => False);
      Add_Check (Model, 6, MC.Choice_Aggregate_Choice,
                 "Bad_Index => Value", Aggregate_OK => False);
      Add_Check (Model, 7, MC.Choice_Membership_Test,
                 "runtime membership check", Bounds_Reversed => True,
                 Null_Range_Allowed => True, Runtime_Check => True);

      Results := MC.Build (Model);

      Assert (MC.Count_Status (Results, MC.Legality_Subject_Not_Discrete) = 1,
              "membership subject must be discrete");
      Assert (MC.Count_Status (Results, MC.Legality_Choice_Type_Mismatch) = 1,
              "choice type must match subject type");
      Assert (MC.Count_Status (Results, MC.Legality_Choice_Not_Static) = 1,
              "nonstatic discrete choice should be rejected in static choice context");
      Assert (MC.Count_Status (Results, MC.Legality_Range_Bounds_Reversed) = 1,
              "reversed range should be rejected where null ranges are not allowed");
      Assert (MC.Count_Status (Results, MC.Legality_Range_Out_Of_Base) = 1,
              "out-of-base range should be rejected");
      Assert (MC.Count_Status (Results, MC.Legality_Aggregate_Choice_Mismatch) = 1,
              "aggregate choice mismatch should be rejected");
      Assert (MC.Count_Status (Results, MC.Legality_Legal_Runtime_Check) = 1,
              "runtime membership check should remain legal when runtime check is allowed");
   end Rejects_Membership_Type_Static_And_Range_Errors;

   procedure Preserves_Evidence_And_Fingerprint_Blockers
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Model : MC.Choice_Model;
      Results : MC.Result_Model;
   begin
      Add_Check (Model, 1, MC.Choice_Case_Statement,
                 "token-only case", AST => False);
      Add_Check (Model, 2, MC.Choice_Case_Statement,
                 "case without type evidence", Type_Evidence => False,
                 Subject => MC.Discrete_Unknown);
      Add_Check (Model, 3, MC.Choice_Case_Statement,
                 "case without static evidence", Static_Evidence => False);
      Add_Check (Model, 4, MC.Choice_Case_Statement,
                 "stale source fingerprint", Expected_Source_FP => 999999);
      Add_Check (Model, 5, MC.Choice_Case_Statement,
                 "stale ast fingerprint", Expected_AST_FP => 999999);
      Add_Check (Model, 6, MC.Choice_Case_Statement,
                 "stale type fingerprint", Expected_Type_FP => 999999);
      Add_Check (Model, 7, MC.Choice_Case_Statement,
                 "stale static fingerprint", Expected_Static_FP => 999999);

      Results := MC.Build (Model);

      Assert (MC.Count_Status (Results, MC.Legality_Missing_AST_Coverage) = 1,
              "AST coverage blocker should be preserved");
      Assert (MC.Count_Status (Results, MC.Legality_Missing_Type_Evidence) = 1,
              "type evidence blocker should be preserved");
      Assert (MC.Count_Status (Results, MC.Legality_Choice_Not_Static) = 1,
              "static evidence blocker should be preserved");
      Assert (MC.Count_Status (Results, MC.Legality_Source_Fingerprint_Mismatch) = 1,
              "source fingerprint mismatch should be preserved");
      Assert (MC.Count_Status (Results, MC.Legality_AST_Fingerprint_Mismatch) = 1,
              "AST fingerprint mismatch should be preserved");
      Assert (MC.Count_Status (Results, MC.Legality_Type_Fingerprint_Mismatch) = 1,
              "type fingerprint mismatch should be preserved");
      Assert (MC.Count_Status (Results, MC.Legality_Static_Fingerprint_Mismatch) = 1,
              "static fingerprint mismatch should be preserved");
   end Preserves_Evidence_And_Fingerprint_Blockers;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Accepts_Source_Shaped_Membership_And_Case_Choices'Access,
         "accepts source-shaped membership and case choices");
      Register_Routine
        (T, Rejects_Case_Coverage_Overlap_And_Others_Errors'Access,
         "rejects case coverage, overlap, and others errors");
      Register_Routine
        (T, Rejects_Membership_Type_Static_And_Range_Errors'Access,
         "rejects membership type, staticness, and range errors");
      Register_Routine
        (T, Preserves_Evidence_And_Fingerprint_Blockers'Access,
         "preserves evidence and fingerprint blockers");
   end Register_Tests;

end Test_Ada_Membership_Case_Choice_Vertical_Slice_Legality_Pass1315;
