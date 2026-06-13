with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Phase579_Legacy_Cleanup_Closure_Pass1446 is

   --  Pass1446 closes the Phase 579 legacy-cleanup campaign.  It does not
   --  reopen semantic Remaining_* work; it verifies that the cleanup inventory,
   --  removal, API consolidation, Core_Suite pruning, documentation cleanup,
   --  and final dead-code sweep are all represented by fresh evidence.

   type Cleanup_Item is
     (Item_Inventory,
      Item_Removal,
      Item_API_Consolidation,
      Item_Core_Suite_Pruning,
      Item_Documentation_Cleanup,
      Item_Dead_Code_Sweep,
      Item_Closure);

   type Evidence_Status is
     (Status_Not_Checked,
      Status_Accepted,
      Status_Rejected_Missing_Test,
      Status_Rejected_Missing_Documentation,
      Status_Rejected_Unclassified_Legacy,
      Status_Rejected_Removed_Surface_Reference,
      Status_Rejected_Reopened_Remaining_Gap,
      Status_Rejected_Speculative_Cleanup,
      Status_Rejected_Fingerprint_Mismatch,
      Status_Indeterminate_Missing_Owner);

   type Evidence_Class is
     (Class_Unknown,
      Class_Accepted,
      Class_Rejected,
      Class_Indeterminate);

   type Closure_Row is record
      Id : Natural := 0;
      Item : Cleanup_Item := Item_Closure;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Canonical_Owner : Ada.Strings.Unbounded.Unbounded_String;
      Reason : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Family : Ada.Strings.Unbounded.Unbounded_String;

      Has_Source : Boolean := False;
      Has_Test : Boolean := False;
      Has_Readme : Boolean := False;
      Has_Release_Document : Boolean := False;
      Has_Core_Suite_Registration : Boolean := False;
      Inventory_Classified : Boolean := False;
      Removed_Surface_References_Absent : Boolean := False;
      Reopened_Remaining_Gap_Absent : Boolean := False;
      Speculative_Cleanup_Absent : Boolean := False;
      Production_Surface_Canonical : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Test_Fingerprint : Natural := 0;
      Expected_Test_Fingerprint : Natural := 0;
      Document_Fingerprint : Natural := 0;
      Expected_Document_Fingerprint : Natural := 0;
      Cleanup_Fingerprint : Natural := 0;
      Expected_Cleanup_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Closure_Row);

   type Closure_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Closure_Result is record
      Id : Natural := 0;
      Status : Evidence_Status := Status_Not_Checked;
      Result_Class : Evidence_Class := Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Result_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Closure_Result);

   type Closure_Model is record
      Results : Result_Vectors.Vector;
      Total_Rows : Natural := 0;
      Accepted_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Closure_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Closure_Input; Row : Closure_Row);
   function Build (Input : Closure_Input) return Closure_Model;
   function Result_For (Model : Closure_Model; Id : Natural) return Closure_Result;
   function Class_For_Status (Status : Evidence_Status) return Evidence_Class;
   function Legacy_Cleanup_Closed (Model : Closure_Model) return Boolean;
   function Ready_For_Next_Project_Phase (Model : Closure_Model) return Boolean;

end Editor.Ada_Phase579_Legacy_Cleanup_Closure_Pass1446;
