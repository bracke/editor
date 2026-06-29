with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Phase579_End_To_End_Editor_Integration_Validation_Pass1432 is

   --  Pass1432 is the project-scale end-to-end editor integration validation
   --  gate.  It verifies that semantic analysis stays snapshot-owned while
   --  the ordinary editor workflow moves through project open, buffer editing,
   --  file-tree operations, search, outline, diagnostics, build, workspace
   --  restore, and project close/switch surfaces.

   type Integration_Surface is
     (Surface_Startup_Project_Open,
      Surface_Buffer_Edit_Save_Reload_Revert,
      Surface_File_Tree_Create_Rename_Delete,
      Surface_Project_Search,
      Surface_Outline_Projection,
      Surface_Semantic_Colouring,
      Surface_Diagnostics_Problems,
      Surface_Build_Panel,
      Surface_Workspace_Restore,
      Surface_Project_Close_Switch,
      Surface_Unknown);

   type Integration_Status is
     (Status_Not_Checked,
      Status_Validated,
      Status_Rejected_Rendering_Side_Parsing,
      Status_Rejected_Save_Reload_During_Analysis,
      Status_Rejected_Dirty_State_Mutation,
      Status_Rejected_Command_Surface_Mutation_Leak,
      Status_Rejected_Keybinding_Mutation_Leak,
      Status_Rejected_Workspace_Mutation_Leak,
      Status_Rejected_Render_Mutation_Leak,
      Status_Rejected_Stale_Snapshot_Accepted,
      Status_Rejected_Unbounded_Work,
      Status_Rejected_Consumer_Disagreement,
      Status_Rejected_Reopened_Remaining_Gap,
      Status_Rejected_Stale_Integration_Evidence,
      Status_Rejected_Duplicate_Surface,
      Status_Indeterminate_Missing_Evidence);

   type Integration_Result_Class is
     (Class_Unknown,
      Class_Validated,
      Class_Rejected,
      Class_Indeterminate);

   type Integration_Row is record
      Id : Natural := 0;
      Surface : Integration_Surface := Surface_Unknown;
      Scenario_Name : Ada.Strings.Unbounded.Unbounded_String;

      Evidence_Present : Boolean := True;
      Snapshot_Owned_Analysis : Boolean := True;
      Rendering_Side_Parsing : Boolean := False;
      Save_Reload_During_Analysis : Boolean := False;
      Dirty_State_Mutated : Boolean := False;
      Command_Surface_Mutated : Boolean := False;
      Keybinding_Mutated : Boolean := False;
      Workspace_Mutated_By_Analysis : Boolean := False;
      Render_Model_Mutated_By_Analysis : Boolean := False;
      Stale_Snapshot_Accepted : Boolean := False;
      Bounded_Work : Boolean := True;
      Consumers_Agree : Boolean := True;
      Reopened_Remaining_Gap : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Snapshot_Fingerprint : Natural := 0;
      Expected_Snapshot_Fingerprint : Natural := 0;
      Consumer_Fingerprint : Natural := 0;
      Expected_Consumer_Fingerprint : Natural := 0;
      Workflow_Fingerprint : Natural := 0;
      Expected_Workflow_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Integration_Row);

   type Integration_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Integration_Entry is record
      Id : Natural := 0;
      Surface : Integration_Surface := Surface_Unknown;
      Status : Integration_Status := Status_Not_Checked;
      Result_Class : Integration_Result_Class := Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Integration_Entry);

   type Integration_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Validated_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Required_Surface_Count : Natural := 0;
      Missing_Surface_Count : Natural := 0;
      Duplicate_Surface_Count : Natural := 0;
      Integration_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Integration_Input; Row : Integration_Row);
   function Build (Input : Integration_Input) return Integration_Model;
   function Result_For (Model : Integration_Model; Id : Natural) return Integration_Entry;
   function Class_For_Status (Status : Integration_Status) return Integration_Result_Class;
   function End_To_End_Integration_Achieved (Model : Integration_Model) return Boolean;

end Editor.Ada_Phase579_End_To_End_Editor_Integration_Validation_Pass1432;
