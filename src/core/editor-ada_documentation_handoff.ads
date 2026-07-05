with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Documentation_Handoff is

   --  Project-scale documentation and handoff gate.  It records the final
   --  status in a deterministic model: what is
   --  guaranteed by the in-tree semantic validation, what remains intentionally
   --  approximate until corpus feedback proves otherwise, and which future-work
   --  rule prevents speculative Remaining_* churn after the remaining-gap
   --  closure.

   type Handoff_Section is
     (Section_Final_Status,
      Section_Guarantees,
      Section_Intentional_Approximation,
      Section_Future_Work_Rule,
      Section_Operational_Handoff,
      Section_Unknown);

   type Handoff_Status is
     (Status_Not_Checked,
      Status_Accepted,
      Status_Rejected_Missing_Status,
      Status_Rejected_Missing_Guarantee,
      Status_Rejected_Missing_Approximation,
      Status_Rejected_Missing_Future_Work_Rule,
      Status_Rejected_Reopened_Remaining_Gap,
      Status_Rejected_Speculative_Edge,
      Status_Rejected_Missing_Acceptance_Standard,
      Status_Rejected_Stale_Documentation_Evidence,
      Status_Rejected_Duplicate_Section,
      Status_Indeterminate_Missing_Evidence);

   type Handoff_Result_Class is
     (Class_Unknown,
      Class_Accepted,
      Class_Rejected,
      Class_Indeterminate);

   type Handoff_Row is record
      Id : Natural := 0;
      Section : Handoff_Section := Section_Unknown;
      Title : Ada.Strings.Unbounded.Unbounded_String;
      Text : Ada.Strings.Unbounded.Unbounded_String;

      Evidence_Present : Boolean := True;
      Final_Status_Documented : Boolean := True;
      Guarantees_Documented : Boolean := True;
      Approximations_Documented : Boolean := True;
      Future_Work_Rule_Documented : Boolean := True;
      Acceptance_Standard_Documented : Boolean := True;
      Reopens_Remaining_Gap : Boolean := False;
      Speculative_Edge_Allowed : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Documentation_Fingerprint : Natural := 0;
      Expected_Documentation_Fingerprint : Natural := 0;
      Handoff_Fingerprint : Natural := 0;
      Expected_Handoff_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Handoff_Row);

   type Handoff_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Handoff_Entry is record
      Id : Natural := 0;
      Section : Handoff_Section := Section_Unknown;
      Status : Handoff_Status := Status_Not_Checked;
      Result_Class : Handoff_Result_Class := Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Handoff_Entry);

   type Handoff_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Accepted_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Required_Section_Count : Natural := 0;
      Missing_Section_Count : Natural := 0;
      Duplicate_Section_Count : Natural := 0;
      Handoff_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Handoff_Input; Row : Handoff_Row);
   function Build (Input : Handoff_Input) return Handoff_Model;
   function Result_For (Model : Handoff_Model; Id : Natural) return Handoff_Entry;
   function Class_For_Status (Status : Handoff_Status) return Handoff_Result_Class;
   function Documentation_Handoff_Complete (Model : Handoff_Model) return Boolean;

end Editor.Ada_Documentation_Handoff;
