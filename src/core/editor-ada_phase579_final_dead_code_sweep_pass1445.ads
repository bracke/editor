with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Phase579_Final_Dead_Code_Sweep_Pass1445 is

   --  Pass1445 implements the final Phase 579 dead-code sweep.
   --  It removes orphaned off-suite legacy tests, records source units that are
   --  still retained only because active regression dependents use them, and
   --  rejects any active reference to already removed scaffolding.

   type Artifact_Kind is
     (Kind_Source_Package,
      Kind_Test_Package,
      Kind_Readme,
      Kind_Release_Document,
      Kind_Unknown);

   type Sweep_Action is
     (Action_Remove_Orphan,
      Action_Retain_Regression_Dependency,
      Action_Retain_Canonical,
      Action_Reject_Active_Removed_Reference,
      Action_Unknown);

   type Sweep_Status is
     (Status_Not_Checked,
      Status_Removed_Orphan,
      Status_Retained_Regression_Dependency,
      Status_Retained_Canonical,
      Status_Rejected_Still_In_Core_Suite,
      Status_Rejected_Active_Removed_Reference,
      Status_Rejected_Missing_Removal_Evidence,
      Status_Rejected_Unowned_Legacy_Source,
      Status_Rejected_Reopened_Remaining_Gap,
      Status_Rejected_Fingerprint_Mismatch,
      Status_Indeterminate_Unknown_Kind,
      Status_Indeterminate_Unknown_Action);

   type Sweep_Class is
     (Class_Unknown,
      Class_Accepted,
      Class_Rejected,
      Class_Indeterminate);

   type Sweep_Row is record
      Id : Natural := 0;
      Kind : Artifact_Kind := Kind_Unknown;
      Action : Sweep_Action := Action_Unknown;
      Path : Ada.Strings.Unbounded.Unbounded_String;
      Canonical_Owner : Ada.Strings.Unbounded.Unbounded_String;
      Reason : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Family : Ada.Strings.Unbounded.Unbounded_String;

      Artifact_Present_Before : Boolean := False;
      Artifact_Present_After : Boolean := False;
      Registered_In_Core_Suite : Boolean := False;
      Has_Active_Dependent : Boolean := False;
      Has_Removal_Evidence : Boolean := False;
      Canonical_Production_Surface : Boolean := False;
      Regression_Only : Boolean := False;
      References_Removed_Surface : Boolean := False;
      Reopens_Remaining_Gap : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Test_Fingerprint : Natural := 0;
      Expected_Test_Fingerprint : Natural := 0;
      Suite_Fingerprint : Natural := 0;
      Expected_Suite_Fingerprint : Natural := 0;
      Cleanup_Fingerprint : Natural := 0;
      Expected_Cleanup_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Sweep_Row);

   type Sweep_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Sweep_Result is record
      Id : Natural := 0;
      Status : Sweep_Status := Status_Not_Checked;
      Result_Class : Sweep_Class := Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Sweep_Result);

   type Sweep_Model is record
      Results : Result_Vectors.Vector;
      Total_Rows : Natural := 0;
      Removed_Count : Natural := 0;
      Retained_Regression_Count : Natural := 0;
      Retained_Canonical_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Sweep_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Sweep_Input; Row : Sweep_Row);
   function Build (Input : Sweep_Input) return Sweep_Model;
   function Result_For (Model : Sweep_Model; Id : Natural) return Sweep_Result;
   function Class_For_Status (Status : Sweep_Status) return Sweep_Class;
   function Dead_Code_Sweep_Complete (Model : Sweep_Model) return Boolean;
   function Ready_For_Phase_Handoff (Model : Sweep_Model) return Boolean;

end Editor.Ada_Phase579_Final_Dead_Code_Sweep_Pass1445;
