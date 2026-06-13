with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Phase579_Diagnostic_Quality_Validation_Pass1435 is

   --  Pass1435 is the project-scale diagnostic quality validation gate.  It
   --  does not add new diagnostic infrastructure and does not reopen the
   --  finite Remaining_* remediation inventory; it verifies that existing
   --  diagnostics are useful, stable, source-shaped, and consumer-consistent.

   type Diagnostic_Scenario_Kind is
     (Scenario_Error_Diagnostic,
      Scenario_Warning_Diagnostic,
      Scenario_Runtime_Check_Diagnostic,
      Scenario_Indeterminate_Diagnostic,
      Scenario_Duplicate_Flood,
      Scenario_Source_Span,
      Scenario_Severity,
      Scenario_Consumer_Agreement,
      Scenario_Unknown);

   type Diagnostic_Severity is
     (Severity_None,
      Severity_Info,
      Severity_Warning,
      Severity_Error);

   type Diagnostic_Status is
     (Status_Not_Checked,
      Status_Accepted,
      Status_Rejected_Missing_Source_Span,
      Status_Rejected_Unstable_Blocker_Family,
      Status_Rejected_Wrong_Severity,
      Status_Rejected_Duplicate_Flood,
      Status_Rejected_Misleading_Final_State,
      Status_Rejected_Consumer_Disagreement,
      Status_Rejected_Reopened_Remaining_Gap,
      Status_Rejected_Stale_Evidence,
      Status_Indeterminate_Missing_Evidence);

   type Diagnostic_Result_Class is
     (Class_Unknown,
      Class_Accepted,
      Class_Rejected,
      Class_Indeterminate);

   type Diagnostic_Row is record
      Id : Natural := 0;
      Scenario : Diagnostic_Scenario_Kind := Scenario_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;

      Evidence_Present : Boolean := True;
      Has_Source_Span : Boolean := True;
      Stable_Blocker_Family : Boolean := True;
      Actual_Severity : Diagnostic_Severity := Severity_None;
      Expected_Severity : Diagnostic_Severity := Severity_None;
      Duplicate_Count : Natural := 1;
      Duplicate_Limit : Natural := 1;
      Final_State_Matches_Result : Boolean := True;
      Consumer_Agreement : Boolean := True;
      Reopens_Remaining_Gap : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Diagnostic_Fingerprint : Natural := 0;
      Expected_Diagnostic_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
      Projection_Fingerprint : Natural := 0;
      Expected_Projection_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Diagnostic_Row);

   type Diagnostic_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Diagnostic_Entry is record
      Id : Natural := 0;
      Scenario : Diagnostic_Scenario_Kind := Scenario_Unknown;
      Status : Diagnostic_Status := Status_Not_Checked;
      Result_Class : Diagnostic_Result_Class := Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Diagnostic_Entry);

   type Diagnostic_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Accepted_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Quality_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Diagnostic_Input; Row : Diagnostic_Row);
   function Build (Input : Diagnostic_Input) return Diagnostic_Model;
   function Result_For (Model : Diagnostic_Model; Id : Natural) return Diagnostic_Entry;
   function Class_For_Status (Status : Diagnostic_Status) return Diagnostic_Result_Class;
   function Diagnostic_Quality_Complete (Model : Diagnostic_Model) return Boolean;

end Editor.Ada_Phase579_Diagnostic_Quality_Validation_Pass1435;
