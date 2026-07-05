with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Performance_Boundedness_Validation is

   --  Project-scale performance and boundedness validation.  It does not
   --  reopen the finite Remaining_* remediation inventory; it records whether
   --  large-file, multi-buffer, cross-unit, cancellation, stale-result, and
   --  deterministic replay scenarios remain bounded and snapshot-owned.

   type Scenario_Kind is
     (Scenario_Large_File,
      Scenario_Multi_Buffer_Project,
      Scenario_Cross_Unit_Index,
      Scenario_Cancellation,
      Scenario_Stale_Result_Rejection,
      Scenario_Deterministic_Replay,
      Scenario_Budget_Exhaustion,
      Scenario_Unknown);

   type Boundedness_Status is
     (Status_Not_Checked,
      Status_Accepted,
      Status_Rejected_Unbounded_Work,
      Status_Rejected_Cancellation_Ignored,
      Status_Rejected_Stale_Result_Accepted,
      Status_Rejected_Nondeterministic_Replay,
      Status_Rejected_Index_Traversal_Unbounded,
      Status_Rejected_Duplicate_Scenario,
      Status_Rejected_Consumer_Disagreement,
      Status_Rejected_Reopened_Remaining_Gap,
      Status_Rejected_Stale_Evidence,
      Status_Indeterminate_Missing_Evidence);

   type Boundedness_Result_Class is
     (Class_Unknown,
      Class_Accepted,
      Class_Rejected,
      Class_Indeterminate);

   type Boundedness_Row is record
      Id : Natural := 0;
      Scenario : Scenario_Kind := Scenario_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;

      Evidence_Present : Boolean := True;
      Work_Budget : Natural := 0;
      Observed_Work : Natural := 0;
      Index_Traversal_Bound : Natural := 0;
      Observed_Index_Traversal : Natural := 0;

      Cancellation_Requested : Boolean := False;
      Cancellation_Acknowledged : Boolean := True;
      Snapshot_Fresh : Boolean := True;
      Stale_Result_Rejected : Boolean := True;
      Deterministic_Replay : Boolean := True;
      Consumer_Agreement : Boolean := True;
      Reopens_Remaining_Gap : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Snapshot_Fingerprint : Natural := 0;
      Expected_Snapshot_Fingerprint : Natural := 0;
      Schedule_Fingerprint : Natural := 0;
      Expected_Schedule_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Boundedness_Row);

   type Boundedness_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Boundedness_Entry is record
      Id : Natural := 0;
      Scenario : Scenario_Kind := Scenario_Unknown;
      Status : Boundedness_Status := Status_Not_Checked;
      Result_Class : Boundedness_Result_Class := Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Boundedness_Entry);

   type Boundedness_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Accepted_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Required_Scenario_Count : Natural := 0;
      Missing_Scenario_Count : Natural := 0;
      Duplicate_Scenario_Count : Natural := 0;
      Performance_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Boundedness_Input; Row : Boundedness_Row);
   function Build (Input : Boundedness_Input) return Boundedness_Model;
   function Result_For (Model : Boundedness_Model; Id : Natural) return Boundedness_Entry;
   function Class_For_Status (Status : Boundedness_Status) return Boundedness_Result_Class;
   function Performance_Boundedness_Complete (Model : Boundedness_Model) return Boolean;

end Editor.Ada_Performance_Boundedness_Validation;
