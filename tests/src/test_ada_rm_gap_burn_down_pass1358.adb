with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_RM_Gap_Burn_Down_Pass1358;

package body Test_Ada_RM_Gap_Burn_Down_Pass1358 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1358;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Predefined_Construct_Kind;
   use type Audit.Resolution_Context_Kind;
   use type Audit.Burn_Down_Status;
   use type Audit.Burn_Down_Row;
   use type Audit.Burn_Down_Input;
   use type Audit.Burn_Down_Entry;
   use type Audit.Burn_Down_Model;
   package Matrix renames Audit.Matrix;
   package Remediation renames Audit.Remediation;
   package Consumers renames Audit.Consumers;
   package Precision renames Audit.Precision;

   function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1358");
   end Name;

   function Base_Row
     (Id : Natural;
      Expected : Audit.Precision_Classification;
      Construct : Audit.Predefined_Construct_Kind :=
        Audit.Construct_Standard_Integer;
      Context : Audit.Resolution_Context_Kind := Audit.Context_Expected_Type;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics)
      return Audit.Burn_Down_Row is
      Row : Audit.Burn_Down_Row;
   begin
      Row.Id := Id;
      Row.Gap := Audit.Gap_Predefined_Environment_Literal_Resolution;
      Row.Family := Matrix.Family_Expressions_Expected_Type_Resolution;
      Row.Owner := Matrix.Slice_Numeric_Static_Expression;
      Row.Previous_State := Remediation.State_Partial;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix.Coverage_Partial;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Construct := Construct;
      Row.Context := Context;
      Row.Name := To_Unbounded_String
        ("pass1358 source-shaped predefined environment literal row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1358");
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Status : Audit.Burn_Down_Status;
      Expected : Audit.Precision_Classification) is
      Item : constant Audit.Burn_Down_Entry := Audit.Result_For (Results, Id);
   begin
      Assert (Item.Status = Status, "unexpected pass1358 status");
      Assert (Audit.Expected_For_Status (Item.Status) = Expected,
              "unexpected pass1358 classification");
   end Expect_Status;

   procedure Test_Balanced_Predefined_Gap_Closes

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (1, Precision.Class_Legal,
                       Audit.Construct_Standard_Integer,
                       Audit.Context_Standard_Environment);
      Audit.Add_Row (Input, Row);

      Row := Base_Row (2, Precision.Class_Illegal,
                       Audit.Construct_Character_Literal,
                       Audit.Context_Overload_Resolution);
      Row.Character_Enumeration_Literal_Ambiguous := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (3, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Construct_String_Literal,
                       Audit.Context_String_Array);
      Row.Runtime_String_Bounds_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (4, Precision.Class_Legal_With_Runtime_Check,
                       Audit.Construct_Integer_Literal,
                       Audit.Context_Subtype_Range_Predicate);
      Row.Runtime_Range_Check := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (5, Precision.Class_Indeterminate,
                       Audit.Construct_Enumeration_Literal,
                       Audit.Context_Expected_Type);
      Row.Missing_Literal_Evidence := True;
      Audit.Add_Row (Input, Row);

      Row := Base_Row (6, Precision.Class_Illegal,
                       Audit.Construct_Null_Literal,
                       Audit.Context_Expected_Type);
      Row.Null_Literal_Has_Access_Context := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Predefined_Environment_Literal_Resolution_Gap_Closed
                (Results),
              "balanced predefined environment literal gap closes");
      Assert (Results.Legal_Count = 1, "legal predefined row counted");
      Assert (Results.Illegal_Count = 2, "illegal predefined rows counted");
      Assert (Results.Runtime_Check_Count = 2,
              "runtime predefined rows counted");
      Assert (Results.Indeterminate_Count = 1,
              "indeterminate predefined row counted");
      Expect_Status (Results, 1, Audit.Status_Legal_Gap_Burned_Down,
                     Precision.Class_Legal);
      Expect_Status
        (Results, 2,
         Audit.Status_Illegal_Character_Enumeration_Literal_Ambiguity,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 3, Audit.Status_Runtime_String_Bounds_Check_Preserved,
         Precision.Class_Legal_With_Runtime_Check);
      Expect_Status
        (Results, 4, Audit.Status_Runtime_Range_Check_Preserved,
         Precision.Class_Legal_With_Runtime_Check);
      Expect_Status
        (Results, 5, Audit.Status_Indeterminate_Missing_Literal_Evidence,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 6, Audit.Status_Illegal_Null_Literal_No_Access_Context,
         Precision.Class_Illegal);
   end Test_Balanced_Predefined_Gap_Closes;

   procedure Test_Standard_Entity_And_Root_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (10, Precision.Class_Illegal,
                       Audit.Construct_Standard_Boolean,
                       Audit.Context_Standard_Environment);
      Row.Same_Standard_Entity := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (11, Precision.Class_Illegal,
                       Audit.Construct_Standard_Integer,
                       Audit.Context_Standard_Environment);
      Row.Standard_Entity_Present := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (12, Precision.Class_Illegal,
                       Audit.Construct_Predefined_Exception,
                       Audit.Context_Exception_Resolution);
      Row.Predefined_Exception_Identity_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (13, Precision.Class_Illegal,
                       Audit.Construct_Predefined_Attribute,
                       Audit.Context_Static_Expression);
      Row.Predefined_Attribute_Identity_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (14, Precision.Class_Illegal,
                       Audit.Construct_Predefined_Operator,
                       Audit.Context_Overload_Resolution);
      Row.Predefined_Operator_Identity_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (15, Precision.Class_Illegal,
                       Audit.Construct_Root_Integer,
                       Audit.Context_Static_Expression);
      Row.Root_Type_Identity_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (16, Precision.Class_Illegal,
                       Audit.Construct_Universal_Integer,
                       Audit.Context_Expected_Type);
      Row.Universal_Type_Conversion_Agrees := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status
        (Results, 10,
         Audit.Status_Illegal_Standard_Entity_Identity_Disagreement,
         Precision.Class_Illegal);
      Expect_Status (Results, 11,
                     Audit.Status_Illegal_Standard_Entity_Missing,
                     Precision.Class_Illegal);
      Expect_Status
        (Results, 12,
         Audit.Status_Illegal_Predefined_Exception_Identity_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 13,
         Audit.Status_Illegal_Predefined_Attribute_Identity_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 14,
         Audit.Status_Illegal_Predefined_Operator_Identity_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 15, Audit.Status_Illegal_Root_Type_Identity_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 16,
         Audit.Status_Illegal_Universal_Type_Conversion_Disagreement,
         Precision.Class_Illegal);
   end Test_Standard_Entity_And_Root_Blockers;

   procedure Test_Literal_Resolution_Blockers

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (20, Precision.Class_Illegal,
                       Audit.Construct_Integer_Literal,
                       Audit.Context_Overload_Resolution);
      Row.Integer_Literal_Resolution_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (21, Precision.Class_Illegal,
                       Audit.Construct_Real_Literal,
                       Audit.Context_Overload_Resolution);
      Row.Real_Literal_Resolution_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (22, Precision.Class_Illegal,
                       Audit.Construct_Integer_Literal,
                       Audit.Context_Static_Expression);
      Row.Static_Evaluation_Agrees_With_Overload := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (23, Precision.Class_Illegal,
                       Audit.Construct_String_Literal,
                       Audit.Context_String_Array);
      Row.String_Literal_Array_Compatible := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (24, Precision.Class_Illegal,
                       Audit.Construct_Wide_String_Type,
                       Audit.Context_String_Array);
      Row.Wide_String_Literal_Compatible := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (25, Precision.Class_Illegal,
                       Audit.Construct_Null_Literal,
                       Audit.Context_Expected_Type);
      Row.Null_Literal_Access_View_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (26, Precision.Class_Illegal,
                       Audit.Construct_Enumeration_Literal,
                       Audit.Context_Expected_Type);
      Row.Expected_Type_Context_Preserved := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status
        (Results, 20,
         Audit.Status_Illegal_Integer_Literal_Resolution_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 21,
         Audit.Status_Illegal_Real_Literal_Resolution_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 22,
         Audit.Status_Illegal_Static_Overload_Literal_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 23,
         Audit.Status_Illegal_String_Literal_Array_Incompatible,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 24,
         Audit.Status_Illegal_Wide_String_Literal_Incompatible,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 25,
         Audit.Status_Illegal_Null_Literal_Access_View_Disagreement,
         Precision.Class_Illegal);
      Expect_Status
        (Results, 26,
         Audit.Status_Illegal_Expected_Type_Literal_Context_Lost,
         Precision.Class_Illegal);
   end Test_Literal_Resolution_Blockers;

   procedure Test_Cross_Slice_Consumer_And_Audit_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (30, Precision.Class_Illegal,
                       Audit.Construct_String_Literal,
                       Audit.Context_Aggregate_Assignment);
      Row.Aggregate_Assignment_Literal_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (31, Precision.Class_Illegal,
                       Audit.Construct_Integer_Literal,
                       Audit.Context_Subtype_Range_Predicate);
      Row.Subtype_Range_Literal_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (32, Precision.Class_Illegal,
                       Audit.Construct_Standard_Boolean,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Diagnostics);
      Row.Consumer_Predefined_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (33, Precision.Class_Illegal,
                       Audit.Construct_String_Type,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Semantic_Colouring);
      Row.Consumer_Colouring_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (34, Precision.Class_Illegal,
                       Audit.Construct_Standard_Integer,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Outline_Model);
      Row.Consumer_Outline_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (35, Precision.Class_Illegal,
                       Audit.Construct_Predefined_Exception,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Semantic_Navigation);
      Row.Consumer_Navigation_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (36, Precision.Class_Illegal,
                       Audit.Construct_Universal_Real,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Hover_Details);
      Row.Consumer_Hover_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (37, Precision.Class_Illegal,
                       Audit.Construct_Predefined_Attribute,
                       Audit.Context_Consumer_Surface,
                       Consumers.Consumer_Build_Diagnostic_Bridge);
      Row.Consumer_Bridge_Agrees := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (38, Precision.Class_Illegal);
      Row.Source_Shaped_Evidence := False;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (39, Precision.Class_Illegal);
      Row.Semantic_Result_Consumed := False;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Assert (Audit.Result_For (Results, 30).Status =
              Audit.Status_Illegal_Aggregate_Assignment_Literal_Disagreement,
              "aggregate/assignment literal disagreement rejected");
      Assert (Audit.Result_For (Results, 31).Status =
              Audit.Status_Illegal_Subtype_Range_Literal_Disagreement,
              "subtype/range literal disagreement rejected");
      Assert (Audit.Result_For (Results, 32).Status =
              Audit.Status_Illegal_Diagnostics_Predefined_Disagreement,
              "diagnostic predefined disagreement rejected");
      Assert (Audit.Result_For (Results, 33).Status =
              Audit.Status_Illegal_Colouring_Predefined_Disagreement,
              "colouring predefined disagreement rejected");
      Assert (Audit.Result_For (Results, 34).Status =
              Audit.Status_Illegal_Outline_Predefined_Disagreement,
              "outline predefined disagreement rejected");
      Assert (Audit.Result_For (Results, 35).Status =
              Audit.Status_Illegal_Navigation_Predefined_Disagreement,
              "navigation predefined disagreement rejected");
      Assert (Audit.Result_For (Results, 36).Status =
              Audit.Status_Illegal_Hover_Predefined_Disagreement,
              "hover predefined disagreement rejected");
      Assert (Audit.Result_For (Results, 37).Status =
              Audit.Status_Illegal_Diagnostic_Bridge_Predefined_Disagreement,
              "bridge predefined disagreement rejected");
      Assert (Audit.Result_For (Results, 38).Status =
              Audit.Status_Source_Shaped_Evidence_Missing,
              "non-source-shaped predefined evidence rejected");
      Assert (Audit.Result_For (Results, 39).Status =
              Audit.Status_Semantic_Result_Unconsumed,
              "unconsumed predefined result rejected");
   end Test_Cross_Slice_Consumer_And_Audit_Gates;

   procedure Test_Indeterminate_And_Fingerprint_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
      Row : Audit.Burn_Down_Row;
   begin
      Row := Base_Row (40, Precision.Class_Indeterminate);
      Row.Missing_Predefined_Environment := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (41, Precision.Class_Indeterminate);
      Row.Missing_Expected_Type_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (42, Precision.Class_Indeterminate);
      Row.Missing_Cross_Unit_Evidence := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (43, Precision.Class_Indeterminate);
      Row.Private_View := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (44, Precision.Class_Illegal);
      Row.Evidence_Stale := True;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (45, Precision.Class_Illegal);
      Row.Predefined_Fingerprint := 1;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (46, Precision.Class_Illegal);
      Row.Literal_Fingerprint := 2;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (47, Precision.Class_Illegal);
      Row.Root_Type_Fingerprint := 3;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (48, Precision.Class_Illegal);
      Row.Expected_Type_Context_Fingerprint := 4;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (49, Precision.Class_Illegal);
      Row.Overload_Fingerprint := 5;
      Audit.Add_Row (Input, Row);
      Row := Base_Row (50, Precision.Class_Illegal);
      Row.Consumer_Fingerprint := 6;
      Audit.Add_Row (Input, Row);

      Results := Audit.Build (Input);

      Expect_Status
        (Results, 40,
         Audit.Status_Indeterminate_Missing_Predefined_Environment,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 41,
         Audit.Status_Indeterminate_Missing_Expected_Type_Evidence,
         Precision.Class_Indeterminate);
      Expect_Status
        (Results, 42,
         Audit.Status_Indeterminate_Missing_Cross_Unit_Evidence,
         Precision.Class_Indeterminate);
      Expect_Status (Results, 43, Audit.Status_Indeterminate_Private_View,
                     Precision.Class_Indeterminate);
      Assert (Audit.Result_For (Results, 44).Status =
              Audit.Status_Stale_Burn_Down_Fingerprint,
              "stale predefined evidence rejected");
      Assert (Audit.Result_For (Results, 45).Status =
              Audit.Status_Predefined_Fingerprint_Mismatch,
              "predefined fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 46).Status =
              Audit.Status_Literal_Fingerprint_Mismatch,
              "literal fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 47).Status =
              Audit.Status_Root_Type_Fingerprint_Mismatch,
              "root type fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 48).Status =
              Audit.Status_Expected_Type_Fingerprint_Mismatch,
              "expected-type fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 49).Status =
              Audit.Status_Overload_Fingerprint_Mismatch,
              "overload fingerprint mismatch rejected");
      Assert (Audit.Result_For (Results, 50).Status =
              Audit.Status_Consumer_Fingerprint_Mismatch,
              "consumer fingerprint mismatch rejected");
   end Test_Indeterminate_And_Fingerprint_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Balanced_Predefined_Gap_Closes'Access,
         "balanced predefined environment literal gap closure");
      Register_Routine
        (T, Test_Standard_Entity_And_Root_Blockers'Access,
         "standard entity and root blockers");
      Register_Routine
        (T, Test_Literal_Resolution_Blockers'Access,
         "literal resolution blockers");
      Register_Routine
        (T, Test_Cross_Slice_Consumer_And_Audit_Gates'Access,
         "cross-slice consumer and audit gates");
      Register_Routine
        (T, Test_Indeterminate_And_Fingerprint_Gates'Access,
         "indeterminate and predefined fingerprint gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1358;
