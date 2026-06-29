with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Phase579_Architecture_Cleanup_Pass1429 is

   --  Pass1429 is the project-scale architecture cleanup gate after the
   --  frozen RM remaining-gap closure.  It does not create another Ada RM
   --  semantic edge.  Instead it classifies editor architecture artifacts as
   --  canonical production surfaces, quarantined historical scaffolding,
   --  release documentation, or covered tests, and rejects alias, compatibility,
   --  render-parse, dirty-state, workspace/keybinding/render mutation, reopened
   --  gap, unowned API, and pass-churn leaks.

   type Architecture_Surface is
     (Surface_Semantic_Engine,
      Surface_Syntax_Parser,
      Surface_Project_Index,
      Surface_Diagnostic_Consumer,
      Surface_Command_Surface,
      Surface_Render_Surface,
      Surface_Workspace_Surface,
      Surface_Test_Harness,
      Surface_Release_Document,
      Surface_Historical_Pass_Scaffold,
      Surface_Unknown);

   type Cleanup_Status is
     (Status_Not_Checked,
      Status_Canonical_Production_Surface,
      Status_Quarantined_Historical_Scaffold,
      Status_Release_Documented,
      Status_Test_Harness_Covered,
      Status_Rejected_Command_Alias,
      Status_Rejected_Compatibility_Spelling,
      Status_Rejected_Render_Side_Parsing,
      Status_Rejected_Dirty_State_Mutation,
      Status_Rejected_Workspace_Keybinding_Render_Leak,
      Status_Rejected_Unowned_API_Surface,
      Status_Rejected_Obsolete_Scaffold_Export,
      Status_Rejected_Pass_Churn_Intent,
      Status_Rejected_Reopened_Remaining_Gap,
      Status_Rejected_Fingerprint_Mismatch,
      Status_Rejected_Duplicate_Surface,
      Status_Indeterminate_Missing_Cleanup_Evidence);

   type Cleanup_Result_Class is
     (Class_Unknown,
      Class_Accepted,
      Class_Quarantined,
      Class_Rejected,
      Class_Indeterminate);

   type Cleanup_Row is record
      Id : Natural := 0;
      Surface : Architecture_Surface := Surface_Unknown;
      Source_File : Ada.Strings.Unbounded.Unbounded_String;
      Package_Name : Ada.Strings.Unbounded.Unbounded_String;
      Canonical_Owner : Ada.Strings.Unbounded.Unbounded_String;
      Final_Intent : Ada.Strings.Unbounded.Unbounded_String;
      Quarantine_Reason : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Family : Ada.Strings.Unbounded.Unbounded_String;

      Is_Production_Surface : Boolean := True;
      Is_Historical_Pass_Scaffold : Boolean := False;
      Is_Test_Surface : Boolean := False;
      Is_Release_Document : Boolean := False;
      Quarantined : Boolean := False;
      Exported_To_Production : Boolean := False;
      Test_Coverage_Present : Boolean := True;
      Registered_In_Core_Suite : Boolean := True;
      Release_Doc_Present : Boolean := True;
      Canonical_Name : Boolean := True;
      Final_Intent_Comment_Present : Boolean := True;
      Public_API_Owned : Boolean := True;

      Has_Command_Alias : Boolean := False;
      Has_Compatibility_Spelling : Boolean := False;
      Performs_Render_Side_Parsing : Boolean := False;
      Mutates_Dirty_State_During_Analysis : Boolean := False;
      Mutates_Command_Palette_Keybindings_Workspace_Or_Render : Boolean := False;
      Reopens_Remaining_Gap : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      API_Fingerprint : Natural := 0;
      Expected_API_Fingerprint : Natural := 0;
      Cleanup_Fingerprint : Natural := 0;
      Expected_Cleanup_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Cleanup_Row);

   type Cleanup_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Cleanup_Entry is record
      Id : Natural := 0;
      Surface : Architecture_Surface := Surface_Unknown;
      Status : Cleanup_Status := Status_Not_Checked;
      Result_Class : Cleanup_Result_Class := Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Cleanup_Entry);

   type Cleanup_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Canonical_Count : Natural := 0;
      Quarantined_Count : Natural := 0;
      Documented_Count : Natural := 0;
      Test_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Required_Surface_Count : Natural := 0;
      Missing_Surface_Count : Natural := 0;
      Duplicate_Surface_Count : Natural := 0;
      Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Cleanup_Input; Row : Cleanup_Row);
   function Build (Input : Cleanup_Input) return Cleanup_Model;
   function Result_For (Model : Cleanup_Model; Id : Natural) return Cleanup_Entry;
   function Class_For_Status (Status : Cleanup_Status) return Cleanup_Result_Class;
   function Final_Cleanup_Achieved (Model : Cleanup_Model) return Boolean;

end Editor.Ada_Phase579_Architecture_Cleanup_Pass1429;
