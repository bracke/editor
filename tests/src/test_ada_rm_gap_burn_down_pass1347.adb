with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_RM_Gap_Burn_Down_Pass1347;

package body Test_Ada_RM_Gap_Burn_Down_Pass1347 is

   package Audit renames Editor.Ada_RM_Gap_Burn_Down_Pass1347;
   use type Audit.RM_Family;
   use type Audit.Implementing_Slice;
   use type Audit.Coverage_Level;
   use type Audit.Remediation_State;
   use type Audit.Semantic_Consumer;
   use type Audit.Precision_Classification;
   use type Audit.Burn_Down_Gap;
   use type Audit.Representation_Item_Kind;
   use type Audit.Representation_Context_Kind;
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
      return AUnit.Format ("Test_Ada_RM_Gap_Burn_Down_Pass1347");
   end Name;

   procedure Add_Row
     (Input : in out Audit.Burn_Down_Input;
      Id : Natural;
      Expected : Audit.Precision_Classification;
      Gap : Audit.Burn_Down_Gap := Audit.Gap_Representation_Freezing_Interfacing;
      Item : Audit.Representation_Item_Kind := Audit.Item_Record_Representation_Clause;
      Context : Audit.Representation_Context_Kind := Audit.Context_Type_Declaration;
      Owner : Audit.Implementing_Slice := Matrix.Slice_Representation_Aspect_Operational;
      Previous_State : Audit.Remediation_State := Remediation.State_Partial;
      Matrix_Before : Audit.Coverage_Level := Matrix.Coverage_Partial;
      Consumer : Audit.Semantic_Consumer := Consumers.Consumer_Diagnostics;
      Source_Shaped : Boolean := True;
      Remediation_Present : Boolean := True;
      Matrix_Present : Boolean := True;
      Package_Present : Boolean := True;
      New_Rule : Boolean := True;
      Coverage_Updated : Boolean := True;
      Corpus_Balanced : Boolean := True;
      Consumed : Boolean := True;
      Consumer_Reached : Boolean := True;
      Stable_Blocker : Boolean := True;
      Representation_Before_Freezing : Boolean := True;
      Aspect_Before_Freezing : Boolean := True;
      Target_Present : Boolean := True;
      Target_Kind_Compatible : Boolean := True;
      Private_Full_View_Freezing_Agrees : Boolean := True;
      Generic_Formal_Freezing : Boolean := False;
      Generic_Template_Freezing : Boolean := False;
      Component_Positions_Static : Boolean := True;
      First_Last_Bits_Valid : Boolean := True;
      Components_Nonoverlap : Boolean := True;
      Record_Size_Fits : Boolean := True;
      Component_Size_Fits : Boolean := True;
      Alignment_Compatible : Boolean := True;
      Storage_Order_Compatible : Boolean := True;
      Enum_Complete : Boolean := True;
      Enum_No_Extra : Boolean := True;
      Enum_No_Duplicate_Codes : Boolean := True;
      Enum_Static : Boolean := True;
      Enum_Nonnegative : Boolean := True;
      Enum_Monotonic : Boolean := True;
      Stream_Profile_Compatible : Boolean := True;
      Stream_View_Allowed : Boolean := True;
      No_Stream_External_Conflict : Boolean := True;
      Convention_Profile_Compatible : Boolean := True;
      C_Profile_Compatible : Boolean := True;
      Import_Export_Target_Compatible : Boolean := True;
      No_Import_Export_Conflict : Boolean := True;
      No_Duplicate_Interfacing : Boolean := True;
      External_Name_Legal : Boolean := True;
      Link_Name_Legal : Boolean := True;
      Access_Subprogram_Convention_Compatible : Boolean := True;
      Address_Storage_Compatible : Boolean := True;
      Aggregate_Consumes_Layout : Boolean := True;
      Assignment_Consumes_Representation : Boolean := True;
      Callable_Consumes_Convention : Boolean := True;
      Dispatch_Consumes_Convention : Boolean := True;
      Generic_Replay_Uses_Fresh_Representation : Boolean := True;
      Runtime_Address_Check : Boolean := False;
      Runtime_Stream_Check : Boolean := False;
      Runtime_Check_Preserved : Boolean := True;
      Private_View : Boolean := False;
      Limited_View : Boolean := False;
      Incomplete_View : Boolean := False;
      Generic_Formal_View : Boolean := False;
      Missing_Full_View : Boolean := False;
      Missing_Cross_Unit : Boolean := False;
      Consumer_Representation_Agrees : Boolean := True;
      Consumer_Freezing_Agrees : Boolean := True;
      Consumer_Interfacing_Agrees : Boolean := True;
      Consumer_Bridge_Agrees : Boolean := True;
      Evidence_Stale : Boolean := False;
      Expected_Burn_FP : Natural := 0;
      Expected_Source_FP : Natural := 0;
      Expected_AST_FP : Natural := 0;
      Expected_Type_FP : Natural := 0;
      Expected_Profile_FP : Natural := 0;
      Expected_Substitution_FP : Natural := 0;
      Expected_Representation_FP : Natural := 0;
      Expected_Freezing_FP : Natural := 0;
      Expected_Effect_FP : Natural := 0;
      Expected_Consumer_FP : Natural := 0) is
      Row : Audit.Burn_Down_Row;
      FP : constant Natural := 1_347_000 + Id * 100;
   begin
      Row.Id := Id;
      Row.Gap := Gap;
      Row.Family := Matrix.Family_Representation_Aspects_Freezing;
      Row.Owner := Owner;
      Row.Previous_State := Previous_State;
      Row.Target_State := Remediation.State_Covered;
      Row.Matrix_Level_Before := Matrix_Before;
      Row.Matrix_Level_After := Matrix.Coverage_Covered;
      Row.Consumer := Consumer;
      Row.Expected := Expected;
      Row.Item := Item;
      Row.Context := Context;
      Row.Name := To_Unbounded_String ("representation freezing interfacing burn-down row");
      Row.Implementing_Package :=
        To_Unbounded_String ("Editor.Ada_RM_Gap_Burn_Down_Pass1347");
      Row.Node := Editor.Ada_Syntax_Tree.Node_Id (1_347_000 + Id);
      Row.Source_Shaped_Evidence := Source_Shaped;
      Row.Remediation_Entry_Present := Remediation_Present;
      Row.Matrix_Coverage_Present := Matrix_Present;
      Row.Implementing_Package_Present := Package_Present;
      Row.New_Legality_Rule_Added := New_Rule;
      Row.Coverage_Entry_Updated_To_Covered := Coverage_Updated;
      Row.Balanced_Regression_Evidence := Corpus_Balanced;
      Row.Semantic_Result_Consumed := Consumed;
      Row.Consumer_Reached := Consumer_Reached;
      Row.Stable_Blocker_Family := Stable_Blocker;
      Row.Representation_Clause_Before_Freezing := Representation_Before_Freezing;
      Row.Aspect_Before_Freezing := Aspect_Before_Freezing;
      Row.Representation_Target_Present := Target_Present;
      Row.Representation_Target_Kind_Compatible := Target_Kind_Compatible;
      Row.Private_Full_View_Freezing_Agrees := Private_Full_View_Freezing_Agrees;
      Row.Generic_Formal_Freezing_Barrier := Generic_Formal_Freezing;
      Row.Generic_Template_Freezing_Barrier := Generic_Template_Freezing;
      Row.Record_Component_Positions_Static := Component_Positions_Static;
      Row.Component_First_Last_Bits_Valid := First_Last_Bits_Valid;
      Row.Record_Components_Nonoverlapping := Components_Nonoverlap;
      Row.Record_Size_Fits := Record_Size_Fits;
      Row.Component_Size_Fits := Component_Size_Fits;
      Row.Alignment_Compatible := Alignment_Compatible;
      Row.Storage_Order_Compatible := Storage_Order_Compatible;
      Row.Enum_Representation_Complete := Enum_Complete;
      Row.Enum_No_Extra_Literals := Enum_No_Extra;
      Row.Enum_No_Duplicate_Codes := Enum_No_Duplicate_Codes;
      Row.Enum_Values_Static := Enum_Static;
      Row.Enum_Values_Nonnegative := Enum_Nonnegative;
      Row.Enum_Order_Monotonic := Enum_Monotonic;
      Row.Stream_Profile_Compatible := Stream_Profile_Compatible;
      Row.Stream_View_Allowed := Stream_View_Allowed;
      Row.No_Stream_External_Representation_Conflict := No_Stream_External_Conflict;
      Row.Convention_Profile_Compatible := Convention_Profile_Compatible;
      Row.C_Profile_Compatible := C_Profile_Compatible;
      Row.Import_Export_Target_Compatible := Import_Export_Target_Compatible;
      Row.No_Import_Export_Conflict := No_Import_Export_Conflict;
      Row.No_Duplicate_Interfacing_Items := No_Duplicate_Interfacing;
      Row.External_Name_Legal := External_Name_Legal;
      Row.Link_Name_Legal := Link_Name_Legal;
      Row.Access_Subprogram_Convention_Compatible :=
        Access_Subprogram_Convention_Compatible;
      Row.Address_Storage_Compatible := Address_Storage_Compatible;
      Row.Aggregate_Consumes_Layout_Evidence := Aggregate_Consumes_Layout;
      Row.Assignment_Conversion_Consumes_Representation :=
        Assignment_Consumes_Representation;
      Row.Callable_Profile_Consumes_Convention := Callable_Consumes_Convention;
      Row.Dispatch_Consumes_Convention := Dispatch_Consumes_Convention;
      Row.Generic_Replay_Uses_Fresh_Representation :=
        Generic_Replay_Uses_Fresh_Representation;
      Row.Runtime_Address_Alignment_Check := Runtime_Address_Check;
      Row.Runtime_Stream_Tag_Check := Runtime_Stream_Check;
      Row.Runtime_Check_Evidence_Preserved := Runtime_Check_Preserved;
      Row.Private_View_Barrier := Private_View;
      Row.Limited_View_Barrier := Limited_View;
      Row.Incomplete_View_Barrier := Incomplete_View;
      Row.Generic_Formal_View_Barrier := Generic_Formal_View;
      Row.Missing_Full_View := Missing_Full_View;
      Row.Missing_Cross_Unit_Evidence := Missing_Cross_Unit;
      Row.Consumer_Representation_Model_Agrees := Consumer_Representation_Agrees;
      Row.Consumer_Freezing_Model_Agrees := Consumer_Freezing_Agrees;
      Row.Consumer_Interfacing_Model_Agrees := Consumer_Interfacing_Agrees;
      Row.Consumer_Diagnostic_Bridge_Agrees := Consumer_Bridge_Agrees;
      Row.Evidence_Stale := Evidence_Stale;
      Row.Burn_Down_Fingerprint := FP + 1;
      Row.Expected_Burn_Down_Fingerprint :=
        (if Expected_Burn_FP = 0 then Row.Burn_Down_Fingerprint else Expected_Burn_FP);
      Row.Source_Fingerprint := FP + 2;
      Row.Expected_Source_Fingerprint :=
        (if Expected_Source_FP = 0 then Row.Source_Fingerprint else Expected_Source_FP);
      Row.AST_Fingerprint := FP + 3;
      Row.Expected_AST_Fingerprint :=
        (if Expected_AST_FP = 0 then Row.AST_Fingerprint else Expected_AST_FP);
      Row.Type_Fingerprint := FP + 4;
      Row.Expected_Type_Fingerprint :=
        (if Expected_Type_FP = 0 then Row.Type_Fingerprint else Expected_Type_FP);
      Row.Profile_Fingerprint := FP + 5;
      Row.Expected_Profile_Fingerprint :=
        (if Expected_Profile_FP = 0 then Row.Profile_Fingerprint else Expected_Profile_FP);
      Row.Substitution_Fingerprint := FP + 6;
      Row.Expected_Substitution_Fingerprint :=
        (if Expected_Substitution_FP = 0 then Row.Substitution_Fingerprint else Expected_Substitution_FP);
      Row.Representation_Fingerprint := FP + 7;
      Row.Expected_Representation_Fingerprint :=
        (if Expected_Representation_FP = 0 then Row.Representation_Fingerprint else Expected_Representation_FP);
      Row.Freezing_Fingerprint := FP + 8;
      Row.Expected_Freezing_Fingerprint :=
        (if Expected_Freezing_FP = 0 then Row.Freezing_Fingerprint else Expected_Freezing_FP);
      Row.Effect_Fingerprint := FP + 9;
      Row.Expected_Effect_Fingerprint :=
        (if Expected_Effect_FP = 0 then Row.Effect_Fingerprint else Expected_Effect_FP);
      Row.Consumer_Fingerprint := FP + 10;
      Row.Expected_Consumer_Fingerprint :=
        (if Expected_Consumer_FP = 0 then Row.Consumer_Fingerprint else Expected_Consumer_FP);
      Audit.Add_Burn_Down_Row (Input, Row);
   end Add_Row;

   procedure Expect_Status
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Expected : Audit.Burn_Down_Status) is
   begin
      Assert
        (Audit.Result_For (Results, Id).Status = Expected,
         "unexpected burn-down status for row" & Natural'Image (Id));
   end Expect_Status;

   procedure Expect_Class
     (Results : Audit.Burn_Down_Model;
      Id : Natural;
      Expected : Audit.Precision_Classification) is
   begin
      Assert
        (Audit.Result_For (Results, Id).Classification = Expected,
         "unexpected precision class for row" & Natural'Image (Id));
   end Expect_Class;

   procedure Test_Representation_Freezing_Interfacing_Gap_Is_Burned_Down

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal,
               Owner => Matrix.Slice_Freezing_Representation,
               Item => Audit.Item_Record_Representation_Clause);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Owner => Matrix.Slice_Record_Layout_Representation,
               Item => Audit.Item_Record_Component_Clause,
               Components_Nonoverlap => False);
      Add_Row (Input, 3, Precision.Class_Legal_With_Runtime_Check,
               Owner => Matrix.Slice_Interfacing_Import_Export,
               Item => Audit.Item_Address,
               Runtime_Address_Check => True);
      Add_Row (Input, 4, Precision.Class_Indeterminate,
               Owner => Matrix.Slice_Representation_Aspect_Operational,
               Private_View => True);

      Results := Audit.Build (Input);

      Assert (Audit.RM_Gap_Burn_Down_Ready (Results),
              "representation/freezing/interfacing rows should be burn-down ready");
      Assert (Audit.Representation_Freezing_Interfacing_Gap_Closed (Results),
              "target representation/freezing/interfacing gap should be closed");
      Assert (Results.Audit_Fingerprint > 0, "audit fingerprint should be stable");
      Expect_Status (Results, 1, Audit.Status_Legal_Gap_Burned_Down);
      Expect_Status (Results, 2, Audit.Status_Illegal_Record_Component_Overlap);
      Expect_Status (Results, 3, Audit.Status_Runtime_Address_Alignment_Check_Preserved);
      Expect_Status (Results, 4, Audit.Status_Indeterminate_Private_View);
   end Test_Representation_Freezing_Interfacing_Gap_Is_Burned_Down;

   procedure Test_Freezing_Record_And_Enum_Rules_Are_Enforced

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Illegal,
               Representation_Before_Freezing => False,
               Owner => Matrix.Slice_Freezing_Representation);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Aspect_Before_Freezing => False,
               Item => Audit.Item_Aspect_Specification,
               Owner => Matrix.Slice_Representation_Aspect_Operational);
      Add_Row (Input, 3, Precision.Class_Illegal,
               Target_Present => False);
      Add_Row (Input, 4, Precision.Class_Illegal,
               Target_Kind_Compatible => False);
      Add_Row (Input, 5, Precision.Class_Illegal,
               Private_Full_View_Freezing_Agrees => False,
               Owner => Matrix.Slice_Freezing_Representation);
      Add_Row (Input, 6, Precision.Class_Illegal,
               Component_Positions_Static => False,
               Owner => Matrix.Slice_Record_Layout_Representation);
      Add_Row (Input, 7, Precision.Class_Illegal,
               First_Last_Bits_Valid => False,
               Owner => Matrix.Slice_Record_Layout_Representation);
      Add_Row (Input, 8, Precision.Class_Illegal,
               Components_Nonoverlap => False,
               Owner => Matrix.Slice_Record_Layout_Representation);
      Add_Row (Input, 9, Precision.Class_Illegal,
               Record_Size_Fits => False,
               Owner => Matrix.Slice_Record_Layout_Representation);
      Add_Row (Input, 10, Precision.Class_Illegal,
               Component_Size_Fits => False,
               Owner => Matrix.Slice_Record_Layout_Representation);
      Add_Row (Input, 11, Precision.Class_Illegal,
               Alignment_Compatible => False,
               Owner => Matrix.Slice_Record_Layout_Representation);
      Add_Row (Input, 12, Precision.Class_Illegal,
               Storage_Order_Compatible => False,
               Owner => Matrix.Slice_Record_Layout_Representation);
      Add_Row (Input, 13, Precision.Class_Illegal,
               Enum_Complete => False,
               Item => Audit.Item_Enumeration_Representation_Clause,
               Owner => Matrix.Slice_Enumeration_Representation);
      Add_Row (Input, 14, Precision.Class_Illegal,
               Enum_No_Extra => False,
               Item => Audit.Item_Enumeration_Representation_Clause,
               Owner => Matrix.Slice_Enumeration_Representation);
      Add_Row (Input, 15, Precision.Class_Illegal,
               Enum_No_Duplicate_Codes => False,
               Item => Audit.Item_Enumeration_Representation_Clause,
               Owner => Matrix.Slice_Enumeration_Representation);
      Add_Row (Input, 16, Precision.Class_Illegal,
               Enum_Static => False,
               Item => Audit.Item_Enumeration_Representation_Clause,
               Owner => Matrix.Slice_Enumeration_Representation);
      Add_Row (Input, 17, Precision.Class_Illegal,
               Enum_Nonnegative => False,
               Item => Audit.Item_Enumeration_Representation_Clause,
               Owner => Matrix.Slice_Enumeration_Representation);
      Add_Row (Input, 18, Precision.Class_Illegal,
               Enum_Monotonic => False,
               Item => Audit.Item_Enumeration_Representation_Clause,
               Owner => Matrix.Slice_Enumeration_Representation);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Illegal_Late_Representation_After_Freezing);
      Expect_Status (Results, 2, Audit.Status_Illegal_Late_Aspect_After_Freezing);
      Expect_Status (Results, 3, Audit.Status_Illegal_Missing_Representation_Target);
      Expect_Status (Results, 4, Audit.Status_Illegal_Wrong_Kind_Representation_Target);
      Expect_Status (Results, 5, Audit.Status_Illegal_Private_Full_View_Freezing_Disagreement);
      Expect_Status (Results, 6, Audit.Status_Illegal_Nonstatic_Component_Position);
      Expect_Status (Results, 7, Audit.Status_Illegal_Component_First_Last_Bit_Range);
      Expect_Status (Results, 8, Audit.Status_Illegal_Record_Component_Overlap);
      Expect_Status (Results, 9, Audit.Status_Illegal_Record_Size_Overflow);
      Expect_Status (Results, 10, Audit.Status_Illegal_Component_Size_Overflow);
      Expect_Status (Results, 11, Audit.Status_Illegal_Alignment_Conflict);
      Expect_Status (Results, 12, Audit.Status_Illegal_Storage_Order_Conflict);
      Expect_Status (Results, 13, Audit.Status_Illegal_Enum_Representation_Incomplete);
      Expect_Status (Results, 14, Audit.Status_Illegal_Enum_Extra_Literal);
      Expect_Status (Results, 15, Audit.Status_Illegal_Enum_Duplicate_Code);
      Expect_Status (Results, 16, Audit.Status_Illegal_Enum_Nonstatic_Value);
      Expect_Status (Results, 17, Audit.Status_Illegal_Enum_Negative_Value);
      Expect_Status (Results, 18, Audit.Status_Illegal_Enum_Nonmonotonic_Order);
      Assert (Results.Invalid_Count = 0, "layout and freezing rows should be valid");
   end Test_Freezing_Record_And_Enum_Rules_Are_Enforced;

   procedure Test_Operational_Import_Export_And_Convention_Rules_Are_Enforced

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Illegal,
               Stream_Profile_Compatible => False,
               Item => Audit.Item_Stream_Attribute,
               Owner => Matrix.Slice_Representation_Aspect_Operational);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Stream_View_Allowed => False,
               Item => Audit.Item_Stream_Attribute);
      Add_Row (Input, 3, Precision.Class_Illegal,
               No_Stream_External_Conflict => False,
               Item => Audit.Item_Stream_Attribute);
      Add_Row (Input, 4, Precision.Class_Illegal,
               Convention_Profile_Compatible => False,
               Item => Audit.Item_Convention,
               Owner => Matrix.Slice_Interfacing_Import_Export);
      Add_Row (Input, 5, Precision.Class_Illegal,
               C_Profile_Compatible => False,
               Item => Audit.Item_Convention,
               Owner => Matrix.Slice_Interfacing_Import_Export);
      Add_Row (Input, 6, Precision.Class_Illegal,
               Import_Export_Target_Compatible => False,
               Item => Audit.Item_Import,
               Owner => Matrix.Slice_Interfacing_Import_Export);
      Add_Row (Input, 7, Precision.Class_Illegal,
               No_Import_Export_Conflict => False,
               Item => Audit.Item_Export,
               Owner => Matrix.Slice_Interfacing_Import_Export);
      Add_Row (Input, 8, Precision.Class_Illegal,
               No_Duplicate_Interfacing => False,
               Item => Audit.Item_Export,
               Owner => Matrix.Slice_Interfacing_Import_Export);
      Add_Row (Input, 9, Precision.Class_Illegal,
               External_Name_Legal => False,
               Item => Audit.Item_External_Name,
               Owner => Matrix.Slice_Interfacing_Import_Export);
      Add_Row (Input, 10, Precision.Class_Illegal,
               Link_Name_Legal => False,
               Item => Audit.Item_Link_Name,
               Owner => Matrix.Slice_Interfacing_Import_Export);
      Add_Row (Input, 11, Precision.Class_Illegal,
               Access_Subprogram_Convention_Compatible => False,
               Item => Audit.Item_Convention,
               Context => Audit.Context_Access_Subprogram,
               Owner => Matrix.Slice_Access_Type_Access_Subprogram);
      Add_Row (Input, 12, Precision.Class_Illegal,
               Address_Storage_Compatible => False,
               Item => Audit.Item_Address,
               Owner => Matrix.Slice_Interfacing_Import_Export);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Illegal_Stream_Profile_Mismatch);
      Expect_Status (Results, 2, Audit.Status_Illegal_Stream_View_Barrier);
      Expect_Status (Results, 3, Audit.Status_Illegal_Stream_External_Representation_Conflict);
      Expect_Status (Results, 4, Audit.Status_Illegal_Convention_Profile_Mismatch);
      Expect_Status (Results, 5, Audit.Status_Illegal_C_Profile_Incompatible);
      Expect_Status (Results, 6, Audit.Status_Illegal_Import_Export_Target_Mismatch);
      Expect_Status (Results, 7, Audit.Status_Illegal_Import_Export_Conflict);
      Expect_Status (Results, 8, Audit.Status_Illegal_Duplicate_Interfacing_Item);
      Expect_Status (Results, 9, Audit.Status_Illegal_External_Name);
      Expect_Status (Results, 10, Audit.Status_Illegal_Link_Name);
      Expect_Status (Results, 11, Audit.Status_Illegal_Access_Subprogram_Convention_Mismatch);
      Expect_Status (Results, 12, Audit.Status_Illegal_Address_Storage_Conflict);
      Assert (Results.Invalid_Count = 0, "operational/interfacing rows should be valid");
   end Test_Operational_Import_Export_And_Convention_Rules_Are_Enforced;

   procedure Test_Cross_Slice_Runtime_And_Indeterminate_Cases_Are_Preserved

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Illegal,
               Gap => Audit.Gap_Cross_Slice_Representation_Use,
               Context => Audit.Context_Aggregate_Initialization,
               Aggregate_Consumes_Layout => False,
               Owner => Matrix.Slice_Aggregate);
      Add_Row (Input, 2, Precision.Class_Illegal,
               Gap => Audit.Gap_Cross_Slice_Representation_Use,
               Context => Audit.Context_Assignment_Conversion,
               Assignment_Consumes_Representation => False,
               Owner => Matrix.Slice_Assignment_Conversion);
      Add_Row (Input, 3, Precision.Class_Illegal,
               Gap => Audit.Gap_Cross_Slice_Representation_Use,
               Context => Audit.Context_Subprogram,
               Callable_Consumes_Convention => False,
               Owner => Matrix.Slice_Callable_Profile);
      Add_Row (Input, 4, Precision.Class_Illegal,
               Gap => Audit.Gap_Cross_Slice_Representation_Use,
               Context => Audit.Context_Dispatching_Call,
               Dispatch_Consumes_Convention => False,
               Owner => Matrix.Slice_Tagged_Dispatching);
      Add_Row (Input, 5, Precision.Class_Illegal,
               Gap => Audit.Gap_Cross_Slice_Representation_Use,
               Context => Audit.Context_Generic_Body_Replay,
               Generic_Replay_Uses_Fresh_Representation => False,
               Owner => Matrix.Slice_Generic_Body_Replay);
      Add_Row (Input, 6, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Address_Check => True,
               Owner => Matrix.Slice_Interfacing_Import_Export);
      Add_Row (Input, 7, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Stream_Check => True,
               Owner => Matrix.Slice_Representation_Aspect_Operational);
      Add_Row (Input, 8, Precision.Class_Legal_With_Runtime_Check,
               Runtime_Stream_Check => True,
               Runtime_Check_Preserved => False,
               Owner => Matrix.Slice_Representation_Aspect_Operational);
      Add_Row (Input, 9, Precision.Class_Indeterminate,
               Private_View => True);
      Add_Row (Input, 10, Precision.Class_Indeterminate,
               Limited_View => True);
      Add_Row (Input, 11, Precision.Class_Indeterminate,
               Incomplete_View => True);
      Add_Row (Input, 12, Precision.Class_Indeterminate,
               Generic_Formal_View => True);
      Add_Row (Input, 13, Precision.Class_Indeterminate,
               Generic_Template_Freezing => True);
      Add_Row (Input, 14, Precision.Class_Indeterminate,
               Missing_Full_View => True);
      Add_Row (Input, 15, Precision.Class_Indeterminate,
               Missing_Cross_Unit => True);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Illegal_Aggregate_Layout_Evidence_Not_Consumed);
      Expect_Status (Results, 2, Audit.Status_Illegal_Assignment_Representation_Barrier_Lost);
      Expect_Status (Results, 3, Audit.Status_Illegal_Callable_Convention_Disagreement);
      Expect_Status (Results, 4, Audit.Status_Illegal_Dispatch_Convention_Evidence_Lost);
      Expect_Status (Results, 5, Audit.Status_Illegal_Generic_Replay_Stale_Representation);
      Expect_Status (Results, 6, Audit.Status_Runtime_Address_Alignment_Check_Preserved);
      Expect_Status (Results, 7, Audit.Status_Runtime_Stream_Tag_Check_Preserved);
      Expect_Status (Results, 8, Audit.Status_Runtime_Check_Evidence_Lost);
      Expect_Status (Results, 9, Audit.Status_Indeterminate_Private_View);
      Expect_Status (Results, 10, Audit.Status_Indeterminate_Limited_View);
      Expect_Status (Results, 11, Audit.Status_Indeterminate_Incomplete_View);
      Expect_Status (Results, 12, Audit.Status_Indeterminate_Generic_Formal_View);
      Expect_Status (Results, 13, Audit.Status_Indeterminate_Generic_Template_Freezing_Barrier);
      Expect_Status (Results, 14, Audit.Status_Indeterminate_Missing_Full_View);
      Expect_Status (Results, 15, Audit.Status_Indeterminate_Missing_Cross_Unit_Evidence);
      Assert (Results.Invalid_Count = 1, "lost runtime-check evidence should invalidate one row");
   end Test_Cross_Slice_Runtime_And_Indeterminate_Cases_Are_Preserved;

   procedure Test_Remediation_Consumer_Fingerprint_And_Classification_Gates

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Audit.Burn_Down_Input;
      Results : Audit.Burn_Down_Model;
   begin
      Add_Row (Input, 1, Precision.Class_Legal,
               Remediation_Present => False);
      Add_Row (Input, 2, Precision.Class_Legal,
               Matrix_Present => False);
      Add_Row (Input, 3, Precision.Class_Legal,
               Package_Present => False);
      Add_Row (Input, 4, Precision.Class_Legal,
               New_Rule => False);
      Add_Row (Input, 5, Precision.Class_Legal,
               Coverage_Updated => False);
      Add_Row (Input, 6, Precision.Class_Legal,
               Corpus_Balanced => False);
      Add_Row (Input, 7, Precision.Class_Legal,
               Consumed => False);
      Add_Row (Input, 8, Precision.Class_Legal,
               Consumer_Reached => False);
      Add_Row (Input, 9, Precision.Class_Legal,
               Consumer_Representation_Agrees => False);
      Add_Row (Input, 10, Precision.Class_Legal,
               Consumer_Freezing_Agrees => False);
      Add_Row (Input, 11, Precision.Class_Legal,
               Consumer_Interfacing_Agrees => False);
      Add_Row (Input, 12, Precision.Class_Legal,
               Consumer_Bridge_Agrees => False);
      Add_Row (Input, 13, Precision.Class_Legal,
               Representation_Before_Freezing => False);
      Add_Row (Input, 14, Precision.Class_Legal,
               Evidence_Stale => True);
      Add_Row (Input, 15, Precision.Class_Legal,
               Source_Shaped => False);
      Add_Row (Input, 16, Precision.Class_Legal,
               Expected_Source_FP => 1);
      Add_Row (Input, 17, Precision.Class_Legal,
               Expected_AST_FP => 1);
      Add_Row (Input, 18, Precision.Class_Legal,
               Expected_Type_FP => 1);
      Add_Row (Input, 19, Precision.Class_Legal,
               Expected_Profile_FP => 1);
      Add_Row (Input, 20, Precision.Class_Legal,
               Expected_Substitution_FP => 1);
      Add_Row (Input, 21, Precision.Class_Legal,
               Expected_Representation_FP => 1);
      Add_Row (Input, 22, Precision.Class_Legal,
               Expected_Freezing_FP => 1);
      Add_Row (Input, 23, Precision.Class_Legal,
               Expected_Effect_FP => 1);
      Add_Row (Input, 24, Precision.Class_Legal,
               Expected_Consumer_FP => 1);

      Results := Audit.Build (Input);

      Expect_Status (Results, 1, Audit.Status_Missing_Remediation_Evidence);
      Expect_Status (Results, 2, Audit.Status_Missing_Matrix_Coverage);
      Expect_Status (Results, 3, Audit.Status_Missing_Implementing_Package);
      Expect_Status (Results, 4, Audit.Status_No_New_Legality_Rule);
      Expect_Status (Results, 5, Audit.Status_Coverage_Not_Updated_To_Covered);
      Expect_Status (Results, 6, Audit.Status_Regression_Corpus_Not_Balanced);
      Expect_Status (Results, 7, Audit.Status_Semantic_Result_Unconsumed);
      Expect_Status (Results, 8, Audit.Status_Consumer_Not_Reached);
      Expect_Status (Results, 9, Audit.Status_Consumer_Representation_Model_Disagreement);
      Expect_Status (Results, 10, Audit.Status_Consumer_Freezing_Model_Disagreement);
      Expect_Status (Results, 11, Audit.Status_Consumer_Interfacing_Model_Disagreement);
      Expect_Status (Results, 12, Audit.Status_Consumer_Diagnostic_Bridge_Disagreement);
      Expect_Status (Results, 13, Audit.Status_Unexpected_Classification);
      Expect_Status (Results, 14, Audit.Status_Stale_Burn_Down_Fingerprint);
      Expect_Status (Results, 15, Audit.Status_Source_Shaped_Evidence_Missing);
      Expect_Status (Results, 16, Audit.Status_Source_Fingerprint_Mismatch);
      Expect_Status (Results, 17, Audit.Status_AST_Fingerprint_Mismatch);
      Expect_Status (Results, 18, Audit.Status_Type_Fingerprint_Mismatch);
      Expect_Status (Results, 19, Audit.Status_Profile_Fingerprint_Mismatch);
      Expect_Status (Results, 20, Audit.Status_Substitution_Fingerprint_Mismatch);
      Expect_Status (Results, 21, Audit.Status_Representation_Fingerprint_Mismatch);
      Expect_Status (Results, 22, Audit.Status_Freezing_Fingerprint_Mismatch);
      Expect_Status (Results, 23, Audit.Status_Effect_Fingerprint_Mismatch);
      Expect_Status (Results, 24, Audit.Status_Consumer_Fingerprint_Mismatch);
      Expect_Class (Results, 13, Precision.Class_Illegal);
      Assert (Results.Invalid_Count = 24,
              "all remediation/fingerprint/classification gate rows should be invalid");
   end Test_Remediation_Consumer_Fingerprint_And_Classification_Gates;

   procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Representation_Freezing_Interfacing_Gap_Is_Burned_Down'Access,
         "representation freezing interfacing gap is burned down");
      Register_Routine
        (T, Test_Freezing_Record_And_Enum_Rules_Are_Enforced'Access,
         "freezing record and enum rules are enforced");
      Register_Routine
        (T, Test_Operational_Import_Export_And_Convention_Rules_Are_Enforced'Access,
         "operational import export and convention rules are enforced");
      Register_Routine
        (T, Test_Cross_Slice_Runtime_And_Indeterminate_Cases_Are_Preserved'Access,
         "cross-slice runtime and indeterminate cases are preserved");
      Register_Routine
        (T, Test_Remediation_Consumer_Fingerprint_And_Classification_Gates'Access,
         "remediation consumer fingerprint and classification gates");
   end Register_Tests;

end Test_Ada_RM_Gap_Burn_Down_Pass1347;
