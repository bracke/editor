with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Phase579_Real_Ada_Corpus_Validation_Pass1430 is

   --  Pass1430 is the project-scale real Ada corpus validation gate after
   --  architecture cleanup.  It does not reopen Remaining_* remediation.
   --  It records source-shaped Ada corpus scenarios, expected semantic
   --  verdicts, warning/runtime-check preservation, diagnostic precision,
   --  consumer agreement, and stale evidence rejection.

   type Corpus_Scenario_Family is
     (Family_Legal_Ada_2022_Unit,
      Family_Illegal_Ada_2022_Unit,
      Family_Runtime_Check_Preserved,
      Family_Warning_Only_Preserved,
      Family_Cross_Unit_Project,
      Family_Generic_Instance,
      Family_Tasking_Protected,
      Family_Representation_Freezing,
      Family_Incremental_Edit,
      Family_Unknown);

   type Expected_Corpus_Verdict is
     (Expect_Accepted,
      Expect_Rejected,
      Expect_Runtime_Check,
      Expect_Warning_Only,
      Expect_Indeterminate);

   type Corpus_Status is
     (Status_Not_Checked,
      Status_Accepted_Legal_Corpus,
      Status_Rejected_Illegal_Corpus,
      Status_Runtime_Check_Preserved,
      Status_Warning_Only_Preserved,
      Status_Cross_Unit_Consumer_Agreed,
      Status_Rejected_False_Positive,
      Status_Rejected_False_Negative,
      Status_Rejected_Missing_Diagnostic_Span,
      Status_Rejected_Duplicate_Diagnostic_Flood,
      Status_Rejected_Consumer_Disagreement,
      Status_Rejected_Stale_Corpus_Evidence,
      Status_Indeterminate_Missing_Corpus_Evidence);

   type Corpus_Result_Class is
     (Class_Unknown,
      Class_Validated,
      Class_Rejected,
      Class_Indeterminate);

   type Corpus_Row is record
      Id : Natural := 0;
      Family : Corpus_Scenario_Family := Family_Unknown;
      Scenario_Name : Ada.Strings.Unbounded.Unbounded_String;
      Source_Shape : Ada.Strings.Unbounded.Unbounded_String;
      RM_Anchor : Ada.Strings.Unbounded.Unbounded_String;
      Expected : Expected_Corpus_Verdict := Expect_Indeterminate;

      Actual_Accepted : Boolean := False;
      Actual_Rejected : Boolean := False;
      Runtime_Check_Preserved : Boolean := False;
      Warning_Only_Preserved : Boolean := False;
      Diagnostic_Span_Present : Boolean := True;
      Duplicate_Diagnostic_Flood : Boolean := False;
      Consumer_Agreed : Boolean := True;
      Project_Index_Agreed : Boolean := True;
      Snapshot_Owned : Boolean := True;
      Stale_Evidence_Rejected : Boolean := True;
      Reopened_Remaining_Gap : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      AST_Fingerprint : Natural := 0;
      Expected_AST_Fingerprint : Natural := 0;
      Semantic_Fingerprint : Natural := 0;
      Expected_Semantic_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Corpus_Row);

   type Corpus_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Corpus_Entry is record
      Id : Natural := 0;
      Family : Corpus_Scenario_Family := Family_Unknown;
      Status : Corpus_Status := Status_Not_Checked;
      Result_Class : Corpus_Result_Class := Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Corpus_Entry);

   type Corpus_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Legal_Accepted_Count : Natural := 0;
      Illegal_Rejected_Count : Natural := 0;
      Runtime_Check_Count : Natural := 0;
      Warning_Only_Count : Natural := 0;
      Cross_Unit_Agreed_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Corpus_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Corpus_Input; Row : Corpus_Row);
   function Build (Input : Corpus_Input) return Corpus_Model;
   function Result_For (Model : Corpus_Model; Id : Natural) return Corpus_Entry;
   function Class_For_Status (Status : Corpus_Status) return Corpus_Result_Class;
   function Corpus_Validation_Achieved (Model : Corpus_Model) return Boolean;

end Editor.Ada_Phase579_Real_Ada_Corpus_Validation_Pass1430;
