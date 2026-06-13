with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Phase579_Canonical_API_Consolidation_Pass1442 is

   --  Pass1442 implements project-scale cleanup item 3: canonical API
   --  consolidation.  It records which Phase 579 semantic, diagnostic,
   --  project-index, release-gate, and cleanup surfaces are production APIs;
   --  which pass packages are regression evidence only; and which historical
   --  surfaces must not be reintroduced as production-facing entry points.

   type API_Family is
     (Family_Semantic_Core,
      Family_Parser_AST_Core,
      Family_Name_Resolution_Core,
      Family_Diagnostic_Surface,
      Family_Project_Index_Surface,
      Family_Editor_Consumer_Surface,
      Family_Release_Gate_Surface,
      Family_RM_Remediation_Evidence,
      Family_Regression_Evidence_Surface,
      Family_Legacy_Cleanup_Surface,
      Family_Removed_Legacy_Surface,
      Family_Unknown);

   type API_Role is
     (Role_Production_API,
      Role_Regression_Evidence,
      Role_Cleanup_Gate,
      Role_Removed_Legacy,
      Role_Quarantined_Legacy,
      Role_Unknown);

   type API_Status is
     (Status_Not_Checked,
      Status_Canonical_Production_API,
      Status_Canonical_Regression_Evidence,
      Status_Canonical_Cleanup_Gate,
      Status_Canonical_Removed_Legacy,
      Status_Canonical_Quarantined_Legacy,
      Status_Rejected_Missing_Owner,
      Status_Rejected_Production_Alias,
      Status_Rejected_Legacy_Production_Leak,
      Status_Rejected_Removed_Surface_Reference,
      Status_Rejected_Reopened_Remaining_Gap,
      Status_Rejected_Missing_Test_Coverage,
      Status_Rejected_Missing_Documentation,
      Status_Rejected_Fingerprint_Mismatch,
      Status_Indeterminate_Unknown_Role,
      Status_Indeterminate_Unknown_Family);

   type API_Result_Class is
     (Class_Unknown,
      Class_Accepted,
      Class_Rejected,
      Class_Indeterminate);

   type API_Row is record
      Id : Natural := 0;
      Family : API_Family := Family_Unknown;
      Role : API_Role := Role_Unknown;
      Package_Name : Ada.Strings.Unbounded.Unbounded_String;
      Source_Path : Ada.Strings.Unbounded.Unbounded_String;
      Canonical_Owner : Ada.Strings.Unbounded.Unbounded_String;
      Public_Surface : Ada.Strings.Unbounded.Unbounded_String;
      Documentation_Path : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Family : Ada.Strings.Unbounded.Unbounded_String;

      Production_Facing : Boolean := False;
      Regression_Only : Boolean := False;
      Cleanup_Only : Boolean := False;
      Removed_Legacy : Boolean := False;
      Quarantined_Legacy : Boolean := False;
      Has_Test_Coverage : Boolean := False;
      Has_Documentation : Boolean := False;
      Adds_Command_Alias : Boolean := False;
      Legacy_Production_Leak : Boolean := False;
      References_Removed_Surface : Boolean := False;
      Reopens_Remaining_Gap : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Test_Fingerprint : Natural := 0;
      Expected_Test_Fingerprint : Natural := 0;
      Documentation_Fingerprint : Natural := 0;
      Expected_Documentation_Fingerprint : Natural := 0;
      API_Fingerprint : Natural := 0;
      Expected_API_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => API_Row);

   type API_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type API_Entry is record
      Id : Natural := 0;
      Family : API_Family := Family_Unknown;
      Role : API_Role := Role_Unknown;
      Status : API_Status := Status_Not_Checked;
      Result_Class : API_Result_Class := Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => API_Entry);

   type API_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Production_API_Count : Natural := 0;
      Regression_Evidence_Count : Natural := 0;
      Cleanup_Gate_Count : Natural := 0;
      Removed_Legacy_Count : Natural := 0;
      Quarantined_Legacy_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      API_Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out API_Input; Row : API_Row);
   function Build (Input : API_Input) return API_Model;
   function Result_For (Model : API_Model; Id : Natural) return API_Entry;
   function Class_For_Status (Status : API_Status) return API_Result_Class;
   function Canonical_API_Consolidated (Model : API_Model) return Boolean;
   function Ready_For_Core_Suite_Pruning (Model : API_Model) return Boolean;

end Editor.Ada_Phase579_Canonical_API_Consolidation_Pass1442;
