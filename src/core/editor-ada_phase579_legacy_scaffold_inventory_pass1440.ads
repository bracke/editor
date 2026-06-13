with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Phase579_Legacy_Scaffold_Inventory_Pass1440 is

   --  Pass1440 completes the first legacy-cleanup project-scale item after the
   --  destructive cleanup passes: it inventories remaining legacy scaffolding
   --  and classifies each surface as production, regression evidence,
   --  quarantined, or a concrete removal candidate.  This pass deliberately
   --  does not remove additional files; it creates the finite cleanup ledger
   --  required before subsequent destructive removal passes.

   type Scaffold_Family is
     (Family_Canonical_Semantic_Core,
      Family_Canonical_Diagnostic_Surface,
      Family_RM_Remediation_Evidence,
      Family_Project_Closure_Evidence,
      Family_Diagnostic_Recovery_Legacy,
      Family_Diagnostic_Command_Legacy,
      Family_Diagnostic_Render_Legacy,
      Family_Repair_Gated_Legacy,
      Family_Remediation_Worklist_Legacy,
      Family_Stabilized_Closure_Legacy,
      Family_Unknown);

   type Scaffold_Classification is
     (Classification_Production,
      Classification_Regression_Evidence,
      Classification_Quarantine,
      Classification_Remove,
      Classification_Unknown);

   type Inventory_Status is
     (Status_Not_Checked,
      Status_Classified_Production,
      Status_Classified_Regression_Evidence,
      Status_Classified_Quarantine,
      Status_Classified_Removal_Candidate,
      Status_Rejected_Unowned_Active_Legacy,
      Status_Rejected_Removed_Code_Reference,
      Status_Rejected_Production_Alias_Leak,
      Status_Rejected_Reopened_Remaining_Gap,
      Status_Rejected_Fingerprint_Mismatch,
      Status_Indeterminate_Missing_Owner,
      Status_Indeterminate_Unclassified_Surface);

   type Inventory_Result_Class is
     (Class_Unknown,
      Class_Accepted,
      Class_Rejected,
      Class_Indeterminate);

   type Inventory_Row is record
      Id : Natural := 0;
      Family : Scaffold_Family := Family_Unknown;
      Classification : Scaffold_Classification := Classification_Unknown;
      Package_Name : Ada.Strings.Unbounded.Unbounded_String;
      Surface_Path : Ada.Strings.Unbounded.Unbounded_String;
      Canonical_Owner : Ada.Strings.Unbounded.Unbounded_String;
      Cleanup_Action : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Family : Ada.Strings.Unbounded.Unbounded_String;

      Active_Source_Present : Boolean := True;
      Active_Test_Present : Boolean := False;
      Production_Facing : Boolean := False;
      Regression_Only : Boolean := False;
      Has_Core_Suite_Coverage : Boolean := False;
      References_Removed_Code : Boolean := False;
      Adds_Command_Alias : Boolean := False;
      Reopens_Remaining_Gap : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Test_Fingerprint : Natural := 0;
      Expected_Test_Fingerprint : Natural := 0;
      Inventory_Fingerprint : Natural := 0;
      Expected_Inventory_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Inventory_Row);

   type Inventory_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Inventory_Entry is record
      Id : Natural := 0;
      Family : Scaffold_Family := Family_Unknown;
      Classification : Scaffold_Classification := Classification_Unknown;
      Status : Inventory_Status := Status_Not_Checked;
      Result_Class : Inventory_Result_Class := Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Inventory_Entry);

   type Inventory_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Production_Count : Natural := 0;
      Regression_Evidence_Count : Natural := 0;
      Quarantine_Count : Natural := 0;
      Removal_Candidate_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Inventory_Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Inventory_Input; Row : Inventory_Row);
   function Build (Input : Inventory_Input) return Inventory_Model;
   function Result_For (Model : Inventory_Model; Id : Natural) return Inventory_Entry;
   function Class_For_Status (Status : Inventory_Status) return Inventory_Result_Class;
   function Inventory_Complete (Model : Inventory_Model) return Boolean;
   function Ready_For_Removal_Passes (Model : Inventory_Model) return Boolean;

end Editor.Ada_Phase579_Legacy_Scaffold_Inventory_Pass1440;
