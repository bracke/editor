with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Phase579_Legacy_Code_Removal_Pass1439 is

   --  Pass1439 performs the third destructive legacy-code removal after the
   --  Phase 579 project-scale closure.  It removes the obsolete diagnostic
   --  recovery render final projection/lifecycle bundle, which is superseded by the final
   --  diagnostic quality and project-scale closure gates.  Like pass1437 and pass1438,
   --  this package models code that has actually been removed
   --  from the production/test source tree and rejects any remaining active
   --  reference to that removed scaffolds.

   type Legacy_Surface is
     (Surface_Source_Spec,
      Surface_Source_Body,
      Surface_AUnit_Spec,
      Surface_AUnit_Body,
      Surface_Core_Suite_Registration,
      Surface_Release_Document,
      Surface_Unknown);

   type Removal_Status is
     (Status_Not_Checked,
      Status_Removed_From_Source_Tree,
      Status_Removed_From_Test_Tree,
      Status_Removed_From_Core_Suite,
      Status_Documented_Removal,
      Status_Rejected_Active_Source_File,
      Status_Rejected_Active_Test_File,
      Status_Rejected_Core_Suite_Reference,
      Status_Rejected_Replacement_Not_Canonical,
      Status_Rejected_Reopened_Remaining_Gap,
      Status_Rejected_Fingerprint_Mismatch,
      Status_Indeterminate_Missing_Removal_Evidence);

   type Removal_Result_Class is
     (Class_Unknown,
      Class_Accepted,
      Class_Rejected,
      Class_Indeterminate);

   type Removal_Row is record
      Id : Natural := 0;
      Surface : Legacy_Surface := Surface_Unknown;
      Legacy_Path : Ada.Strings.Unbounded.Unbounded_String;
      Legacy_Package : Ada.Strings.Unbounded.Unbounded_String;
      Replacement_Owner : Ada.Strings.Unbounded.Unbounded_String;
      Removal_Reason : Ada.Strings.Unbounded.Unbounded_String;
      Blocker_Family : Ada.Strings.Unbounded.Unbounded_String;

      Source_File_Present : Boolean := False;
      Test_File_Present : Boolean := False;
      Core_Suite_Reference_Present : Boolean := False;
      Replacement_Is_Canonical : Boolean := True;
      Removal_Document_Present : Boolean := True;
      Reopens_Remaining_Gap : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Test_Fingerprint : Natural := 0;
      Expected_Test_Fingerprint : Natural := 0;
      Suite_Fingerprint : Natural := 0;
      Expected_Suite_Fingerprint : Natural := 0;
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
      Surface : Legacy_Surface := Surface_Unknown;
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
      Removed_Suite_Count : Natural := 0;
      Documented_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Removal_Audit_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Removal_Input; Row : Removal_Row);
   function Build (Input : Removal_Input) return Removal_Model;
   function Result_For (Model : Removal_Model; Id : Natural) return Removal_Entry;
   function Class_For_Status (Status : Removal_Status) return Removal_Result_Class;
   function Legacy_Code_Removal_Achieved (Model : Removal_Model) return Boolean;

end Editor.Ada_Phase579_Legacy_Code_Removal_Pass1439;
