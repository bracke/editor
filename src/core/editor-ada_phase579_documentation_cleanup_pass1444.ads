with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Phase579_Documentation_Cleanup_Pass1444 is

   --  Pass1444 implements project-scale cleanup item 5: documentation cleanup.
   --  It defines the canonical Phase 579 architecture map, separates release
   --  documentation from historical pass notes, and rejects stale or speculative
   --  documentation that reopens closed semantic work.

   type Document_Kind is
     (Kind_Canonical_Architecture_Map,
      Kind_Release_Gate,
      Kind_Validation_Report,
      Kind_Cleanup_Ledger,
      Kind_Historical_Pass_Note,
      Kind_Unknown);

   type Documentation_Action is
     (Action_Keep_Canonical,
      Action_Keep_Release_Evidence,
      Action_Archive_Historical_Note,
      Action_Reject_Stale_Note,
      Action_Unknown);

   type Documentation_Status is
     (Status_Not_Checked,
      Status_Canonical_Map_Accepted,
      Status_Release_Gate_Accepted,
      Status_Validation_Report_Accepted,
      Status_Cleanup_Ledger_Accepted,
      Status_Historical_Note_Archived,
      Status_Rejected_Missing_Canonical_Owner,
      Status_Rejected_Reopened_Remaining_Gap,
      Status_Rejected_Speculative_Semantic_Edge,
      Status_Rejected_Stale_Documentation,
      Status_Rejected_Missing_Architecture_Map,
      Status_Rejected_Contradicts_Core_Suite,
      Status_Rejected_Fingerprint_Mismatch,
      Status_Indeterminate_Unknown_Kind,
      Status_Indeterminate_Unknown_Action);

   type Documentation_Class is
     (Class_Unknown,
      Class_Accepted,
      Class_Rejected,
      Class_Indeterminate);

   type Documentation_Row is record
      Id : Natural := 0;
      Kind : Document_Kind := Kind_Unknown;
      Action : Documentation_Action := Action_Unknown;
      Path : Ada.Strings.Unbounded.Unbounded_String;
      Canonical_Owner : Ada.Strings.Unbounded.Unbounded_String;
      Summary : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Family : Ada.Strings.Unbounded.Unbounded_String;

      Document_Present : Boolean := False;
      Architecture_Map_Present : Boolean := False;
      References_Canonical_API : Boolean := False;
      References_Core_Suite_Prune : Boolean := False;
      Historical_Only : Boolean := False;
      Reopens_Remaining_Gap : Boolean := False;
      Adds_Speculative_Semantic_Edge : Boolean := False;
      Contradicts_Core_Suite : Boolean := False;
      Stale_Documentation : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Documentation_Fingerprint : Natural := 0;
      Expected_Documentation_Fingerprint : Natural := 0;
      Suite_Fingerprint : Natural := 0;
      Expected_Suite_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Documentation_Row);

   type Documentation_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Documentation_Entry is record
      Id : Natural := 0;
      Status : Documentation_Status := Status_Not_Checked;
      Result_Class : Documentation_Class := Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Documentation_Entry);

   type Documentation_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Canonical_Count : Natural := 0;
      Release_Evidence_Count : Natural := 0;
      Archived_Historical_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Documentation_Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Documentation_Input; Row : Documentation_Row);
   function Build (Input : Documentation_Input) return Documentation_Model;
   function Result_For (Model : Documentation_Model; Id : Natural)
                        return Documentation_Entry;
   function Class_For_Status (Status : Documentation_Status)
                              return Documentation_Class;
   function Documentation_Cleaned (Model : Documentation_Model) return Boolean;
   function Ready_For_Final_Dead_Code_Sweep (Model : Documentation_Model)
                                           return Boolean;

end Editor.Ada_Phase579_Documentation_Cleanup_Pass1444;
