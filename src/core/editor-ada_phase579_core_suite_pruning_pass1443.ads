with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Phase579_Core_Suite_Pruning_Pass1443 is

   --  Pass1443 implements project-scale cleanup item 4: Core_Suite pruning.
   --  It keeps canonical production and meaningful regression tests registered,
   --  removes obsolete legacy-scaffold tests from the active suite, and records
   --  why any retained historical test remains useful.

   type Suite_Surface is
     (Surface_Canonical_Production,
      Surface_Regression_Evidence,
      Surface_Cleanup_Gate,
      Surface_Removed_Legacy,
      Surface_Quarantined_Legacy,
      Surface_Unknown);

   type Prune_Action is
     (Action_Keep_Registered,
      Action_Prune_From_Core_Suite,
      Action_Remove_Test_Files,
      Action_Keep_Unregistered_Evidence,
      Action_Unknown);

   type Prune_Status is
     (Status_Not_Checked,
      Status_Kept_Canonical_Test,
      Status_Kept_Regression_Test,
      Status_Kept_Cleanup_Gate_Test,
      Status_Pruned_Removed_Legacy_Test,
      Status_Pruned_Quarantined_Legacy_Test,
      Status_Removed_Legacy_Test_Files,
      Status_Kept_Unregistered_Evidence,
      Status_Rejected_Missing_Justification,
      Status_Rejected_Missing_Registered_Test,
      Status_Rejected_Stale_Legacy_Registration,
      Status_Rejected_Test_File_Dangling_Active,
      Status_Rejected_Removed_Test_File_Still_Present,
      Status_Rejected_Reopened_Remaining_Gap,
      Status_Rejected_Command_Alias,
      Status_Rejected_Fingerprint_Mismatch,
      Status_Indeterminate_Unknown_Surface,
      Status_Indeterminate_Unknown_Action);

   type Prune_Class is
     (Class_Unknown,
      Class_Accepted,
      Class_Rejected,
      Class_Indeterminate);

   type Prune_Row is record
      Id : Natural := 0;
      Surface : Suite_Surface := Surface_Unknown;
      Action : Prune_Action := Action_Unknown;
      Package_Name : Ada.Strings.Unbounded.Unbounded_String;
      Test_Package_Name : Ada.Strings.Unbounded.Unbounded_String;
      Justification : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Family : Ada.Strings.Unbounded.Unbounded_String;

      Suite_With_Present : Boolean := False;
      Suite_Add_Test_Present : Boolean := False;
      Test_Spec_Present : Boolean := False;
      Test_Body_Present : Boolean := False;
      Source_Package_Present : Boolean := False;
      Removed_Legacy_Surface : Boolean := False;
      Quarantined_Legacy_Surface : Boolean := False;
      Meaningful_Regression_Evidence : Boolean := False;
      Reopens_Remaining_Gap : Boolean := False;
      Adds_Command_Alias : Boolean := False;

      Suite_Fingerprint : Natural := 0;
      Expected_Suite_Fingerprint : Natural := 0;
      Test_Fingerprint : Natural := 0;
      Expected_Test_Fingerprint : Natural := 0;
      Inventory_Fingerprint : Natural := 0;
      Expected_Inventory_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Prune_Row);

   type Prune_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Prune_Entry is record
      Id : Natural := 0;
      Status : Prune_Status := Status_Not_Checked;
      Result_Class : Prune_Class := Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Prune_Entry);

   type Prune_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Kept_Registered_Count : Natural := 0;
      Pruned_From_Suite_Count : Natural := 0;
      Removed_Test_File_Count : Natural := 0;
      Unregistered_Evidence_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Suite_Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Prune_Input; Row : Prune_Row);
   function Build (Input : Prune_Input) return Prune_Model;
   function Result_For (Model : Prune_Model; Id : Natural) return Prune_Entry;
   function Class_For_Status (Status : Prune_Status) return Prune_Class;
   function Core_Suite_Pruned (Model : Prune_Model) return Boolean;
   function Ready_For_Documentation_Cleanup (Model : Prune_Model) return Boolean;

end Editor.Ada_Phase579_Core_Suite_Pruning_Pass1443;
