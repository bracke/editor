with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Phase579_Real_Ada_Corpus_Validation_Pass1430;

package body Test_Ada_Phase579_Real_Ada_Corpus_Validation_Pass1430 is
   package Corpus renames Editor.Ada_Phase579_Real_Ada_Corpus_Validation_Pass1430;
   use type Corpus.Corpus_Scenario_Family;
   use type Corpus.Expected_Corpus_Verdict;
   use type Corpus.Corpus_Status;
   use type Corpus.Corpus_Result_Class;
   use type Corpus.Corpus_Row;
   use type Corpus.Corpus_Input;
   use type Corpus.Corpus_Entry;
   use type Corpus.Corpus_Model;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format
        ("Test_Ada_Phase579_Real_Ada_Corpus_Validation_Pass1430");
   end Name;

   function Base_Row
     (Id : Natural;
      Family : Corpus.Corpus_Scenario_Family;
      Expected : Corpus.Expected_Corpus_Verdict;
      Name : String;
      Shape : String) return Corpus.Corpus_Row is
      Row : Corpus.Corpus_Row;
   begin
      Row.Id := Id;
      Row.Family := Family;
      Row.Expected := Expected;
      Row.Scenario_Name := To_Unbounded_String (Name);
      Row.Source_Shape := To_Unbounded_String (Shape);
      Row.RM_Anchor := To_Unbounded_String ("Ada 2022 source-shaped corpus case");
      Row.Source_Fingerprint := Id * 100 + 1;
      Row.Expected_Source_Fingerprint := Row.Source_Fingerprint;
      Row.AST_Fingerprint := Id * 100 + 2;
      Row.Expected_AST_Fingerprint := Row.AST_Fingerprint;
      Row.Semantic_Fingerprint := Id * 100 + 3;
      Row.Expected_Semantic_Fingerprint := Row.Semantic_Fingerprint;
      Row.Consumer_Fingerprint := Id * 100 + 4;
      Row.Expected_Consumer_Fingerprint := Row.Consumer_Fingerprint;
      return Row;
   end Base_Row;

   procedure Expect_Status
     (Model : Corpus.Corpus_Model;
      Id : Natural;
      Status : Corpus.Corpus_Status;
      Result_Class : Corpus.Corpus_Result_Class) is
      Feed_Item : constant Corpus.Corpus_Entry := Corpus.Result_For (Model, Id);
   begin
      Assert (Feed_Item.Status = Status, "unexpected pass1430 corpus status");
      Assert (Feed_Item.Result_Class = Result_Class,
              "unexpected pass1430 corpus class");
      Assert (Corpus.Class_For_Status (Status) = Result_Class,
              "status-to-class mapping drifted");
   end Expect_Status;

   procedure Test_Corpus_Validation_Closure

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Corpus.Corpus_Input;
      Model : Corpus.Corpus_Model;
      Row : Corpus.Corpus_Row;
   begin
      Row := Base_Row
        (1, Corpus.Family_Legal_Ada_2022_Unit, Corpus.Expect_Accepted,
         "legal generic package body with predicate-preserving default",
         "generic type T is private; Default : T; package body G is X : T := Default; end;");
      Row.Actual_Accepted := True;
      Corpus.Add_Row (Input, Row);

      Row := Base_Row
        (2, Corpus.Family_Illegal_Ada_2022_Unit, Corpus.Expect_Rejected,
         "illegal private view record-extension aggregate",
         "X : Root'Class := Hidden_Extension'(Interface_Part with Bad => 1);");
      Row.Actual_Rejected := True;
      Corpus.Add_Row (Input, Row);

      Row := Base_Row
        (3, Corpus.Family_Runtime_Check_Preserved, Corpus.Expect_Runtime_Check,
         "array slice assignment with preserved length check",
         "S (I .. J) := Wide_Wide_String'(1 => Wide_Wide_Character'Val (16#10000#));");
      Row.Actual_Accepted := True;
      Row.Runtime_Check_Preserved := True;
      Corpus.Add_Row (Input, Row);

      Row := Base_Row
        (4, Corpus.Family_Warning_Only_Preserved, Corpus.Expect_Warning_Only,
         "unchecked conversion alignment warning is not a hard error",
         "function To_A is new Ada.Unchecked_Conversion (Address, Access_T);");
      Row.Actual_Accepted := True;
      Row.Warning_Only_Preserved := True;
      Corpus.Add_Row (Input, Row);

      Row := Base_Row
        (5, Corpus.Family_Cross_Unit_Project, Corpus.Expect_Accepted,
         "with/use selected-name closure agrees with project index",
         "with Parent.Child; use Parent; package body Client is X : Child.T; end;");
      Row.Actual_Accepted := True;
      Corpus.Add_Row (Input, Row);

      Model := Corpus.Build (Input);

      Assert (Corpus.Corpus_Validation_Achieved (Model),
              "pass1430 real Ada corpus validation should be closed");
      Assert (Model.Legal_Accepted_Count = 1, "legal corpus acceptance count");
      Assert (Model.Illegal_Rejected_Count = 1, "illegal corpus rejection count");
      Assert (Model.Runtime_Check_Count = 1, "runtime-check corpus count");
      Assert (Model.Warning_Only_Count = 1, "warning-only corpus count");
      Assert (Model.Cross_Unit_Agreed_Count = 1, "cross-unit corpus count");
      Assert (Model.Rejected_Count = 0, "no corpus validation rejections");

      Expect_Status
        (Model, 1, Corpus.Status_Accepted_Legal_Corpus, Corpus.Class_Validated);
      Expect_Status
        (Model, 2, Corpus.Status_Rejected_Illegal_Corpus, Corpus.Class_Validated);
      Expect_Status
        (Model, 3, Corpus.Status_Runtime_Check_Preserved, Corpus.Class_Validated);
      Expect_Status
        (Model, 4, Corpus.Status_Warning_Only_Preserved, Corpus.Class_Validated);
      Expect_Status
        (Model, 5, Corpus.Status_Cross_Unit_Consumer_Agreed,
         Corpus.Class_Validated);
   end Test_Corpus_Validation_Closure;

   procedure Test_False_Positive_And_False_Negative_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Corpus.Corpus_Input;
      Model : Corpus.Corpus_Model;
      Row : Corpus.Corpus_Row;
   begin
      Row := Base_Row
        (10, Corpus.Family_Legal_Ada_2022_Unit, Corpus.Expect_Accepted,
         "legal expression function rejected by model",
         "function F (X : Integer) return Integer is (X + 1);");
      Row.Actual_Rejected := True;
      Corpus.Add_Row (Input, Row);

      Row := Base_Row
        (11, Corpus.Family_Illegal_Ada_2022_Unit, Corpus.Expect_Rejected,
         "illegal dispatching abstract call accepted by model",
         "X : Root'Class := Abstract_Primitive (Y);");
      Row.Actual_Accepted := True;
      Corpus.Add_Row (Input, Row);

      Model := Corpus.Build (Input);

      Expect_Status
        (Model, 10, Corpus.Status_Rejected_False_Positive,
         Corpus.Class_Rejected);
      Expect_Status
        (Model, 11, Corpus.Status_Rejected_False_Negative,
         Corpus.Class_Rejected);
      Assert (Model.Rejected_Count = 2, "both corpus precision failures rejected");
   end Test_False_Positive_And_False_Negative_Rejections;

   procedure Test_Diagnostic_Consumer_And_Fingerprint_Rejections

     (T : in out AUnit.Test_Cases.Test_Case'Class) is

      pragma Unreferenced (T);
      Input : Corpus.Corpus_Input;
      Model : Corpus.Corpus_Model;
      Row : Corpus.Corpus_Row;
   begin
      Row := Base_Row
        (20, Corpus.Family_Illegal_Ada_2022_Unit, Corpus.Expect_Rejected,
         "illegal case expression without precise span",
         "X := (case K is when 1 => A);");
      Row.Actual_Rejected := True;
      Row.Diagnostic_Span_Present := False;
      Corpus.Add_Row (Input, Row);

      Row := Base_Row
        (21, Corpus.Family_Generic_Instance, Corpus.Expect_Accepted,
         "generic instance accepted but consumer disagrees",
         "package I is new G (T => Integer);");
      Row.Actual_Accepted := True;
      Row.Consumer_Agreed := False;
      Corpus.Add_Row (Input, Row);

      Row := Base_Row
        (22, Corpus.Family_Incremental_Edit, Corpus.Expect_Accepted,
         "incremental edit uses stale semantic fingerprint",
         "package body P is X : Integer := 1; end P;");
      Row.Actual_Accepted := True;
      Row.Semantic_Fingerprint := 1;
      Row.Expected_Semantic_Fingerprint := 2;
      Corpus.Add_Row (Input, Row);

      Row := Base_Row
        (23, Corpus.Family_Tasking_Protected, Corpus.Expect_Rejected,
         "protected entry diagnostic flood",
         "protected body P is entry E when Flag is begin requeue E; end; end P;");
      Row.Actual_Rejected := True;
      Row.Duplicate_Diagnostic_Flood := True;
      Corpus.Add_Row (Input, Row);

      Model := Corpus.Build (Input);

      Expect_Status
        (Model, 20, Corpus.Status_Rejected_Missing_Diagnostic_Span,
         Corpus.Class_Rejected);
      Expect_Status
        (Model, 21, Corpus.Status_Rejected_Consumer_Disagreement,
         Corpus.Class_Rejected);
      Expect_Status
        (Model, 22, Corpus.Status_Rejected_Stale_Corpus_Evidence,
         Corpus.Class_Rejected);
      Expect_Status
        (Model, 23, Corpus.Status_Rejected_Duplicate_Diagnostic_Flood,
         Corpus.Class_Rejected);
   end Test_Diagnostic_Consumer_And_Fingerprint_Rejections;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Corpus_Validation_Closure'Access,
         "real Ada corpus validation accepts/rejects source-shaped corpus");
      Register_Routine
        (T, Test_False_Positive_And_False_Negative_Rejections'Access,
         "real Ada corpus validation rejects false positives and negatives");
      Register_Routine
        (T, Test_Diagnostic_Consumer_And_Fingerprint_Rejections'Access,
         "real Ada corpus validation rejects span/consumer/stale failures");
   end Register_Tests;

end Test_Ada_Phase579_Real_Ada_Corpus_Validation_Pass1430;
