with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Phase579_Legacy_Projection_Tower_Removal_Pass1441 is

   --  Pass1441 implements the second legacy-cleanup project-scale item after
   --  the pass1440 inventory.  It removes the obsolete diagnostic
   --  command/palette/keybinding/workspace/render projection tower from the
   --  active tree and records a deterministic removal ledger so that future
   --  passes cannot reintroduce the same noncanonical projection surface.

   type Removed_Surface_Family is
     (Family_Command_Palette,
      Family_Keybinding_Hint,
      Family_Workspace_Projection,
      Family_Render_Projection,
      Family_Lifecycle_Recovery,
      Family_Recovery_Projection,
      Family_Recovery_Render_Projection,
      Family_Recovery_Render_Workspace,
      Family_Unknown);

   type Removal_Status is
     (Status_Not_Checked,
      Status_Removed_From_Active_Source,
      Status_Removed_From_Active_Test,
      Status_Removed_From_Source_And_Test,
      Status_Kept_As_Historical_Documentation,
      Status_Rejected_Active_Source_Remains,
      Status_Rejected_Active_Test_Remains,
      Status_Rejected_Core_Suite_Reference_Remains,
      Status_Rejected_Dangling_Dependent_Source,
      Status_Rejected_Noncanonical_Replacement,
      Status_Rejected_Reopened_Remaining_Gap,
      Status_Rejected_Fingerprint_Mismatch,
      Status_Indeterminate_Unowned_Surface);

   type Removal_Result_Class is
     (Class_Unknown,
      Class_Accepted,
      Class_Rejected,
      Class_Indeterminate);

   type Removal_Row is record
      Id : Natural := 0;
      Family : Removed_Surface_Family := Family_Unknown;
      Package_Name : Ada.Strings.Unbounded.Unbounded_String;
      Source_Path : Ada.Strings.Unbounded.Unbounded_String;
      Test_Path : Ada.Strings.Unbounded.Unbounded_String;
      Canonical_Owner : Ada.Strings.Unbounded.Unbounded_String;
      Replacement_Surface : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Family : Ada.Strings.Unbounded.Unbounded_String;

      Active_Source_Remains : Boolean := False;
      Active_Test_Remains : Boolean := False;
      Core_Suite_Reference_Remains : Boolean := False;
      Dangling_Dependent_Source : Boolean := False;
      Noncanonical_Replacement : Boolean := False;
      Reopens_Remaining_Gap : Boolean := False;
      Historical_Documentation_Only : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Test_Fingerprint : Natural := 0;
      Expected_Test_Fingerprint : Natural := 0;
      Removal_Fingerprint : Natural := 0;
      Expected_Removal_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Removal_Row);

   type Removal_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Removal_Entry is record
      Id : Natural := 0;
      Family : Removed_Surface_Family := Family_Unknown;
      Status : Removal_Status := Status_Not_Checked;
      Result_Class : Removal_Result_Class := Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Removal_Entry);

   type Removal_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Removed_Source_Count : Natural := 0;
      Removed_Test_Count : Natural := 0;
      Historical_Documentation_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Removal_Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Removal_Input; Row : Removal_Row);
   function Build (Input : Removal_Input) return Removal_Model;
   function Result_For (Model : Removal_Model; Id : Natural) return Removal_Entry;
   function Class_For_Status (Status : Removal_Status) return Removal_Result_Class;
   function Removal_Batch_Clean (Model : Removal_Model) return Boolean;

end Editor.Ada_Phase579_Legacy_Projection_Tower_Removal_Pass1441;
