with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Phase579_Release_Readiness_Validation_Pass1431 is

   --  Pass1431 is the project-scale release-readiness validation gate after
   --  the real Ada corpus validation pass.  It verifies that the final phase
   --  surface is coherent: packages, tests, READMEs, Core_Suite registration,
   --  finite remaining-gap closure, and release documentation must agree.

   type Readiness_Surface is
     (Surface_Source_Package,
      Surface_Test_Package,
      Surface_Readme,
      Surface_Core_Suite_Registration,
      Surface_Release_Documentation,
      Surface_Final_Remaining_Gap_Closure,
      Surface_Project_Index,
      Surface_Unknown);

   type Readiness_Status is
     (Status_Not_Checked,
      Status_Validated,
      Status_Rejected_Missing_Source,
      Status_Rejected_Missing_Test,
      Status_Rejected_Missing_Readme,
      Status_Rejected_Unregistered_Test,
      Status_Rejected_Orphan_Source,
      Status_Rejected_Duplicate_Registration,
      Status_Rejected_Reopened_Remaining_Gap,
      Status_Rejected_Stale_Readiness_Evidence,
      Status_Rejected_Release_Documentation_Drift,
      Status_Indeterminate_Missing_Evidence);

   type Readiness_Result_Class is
     (Class_Unknown,
      Class_Validated,
      Class_Rejected,
      Class_Indeterminate);

   type Readiness_Row is record
      Id : Natural := 0;
      Surface : Readiness_Surface := Surface_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;
      Expected_Package_Name : Ada.Strings.Unbounded.Unbounded_String;
      Expected_Test_Name : Ada.Strings.Unbounded.Unbounded_String;
      Expected_Readme_Name : Ada.Strings.Unbounded.Unbounded_String;

      Source_Present : Boolean := True;
      Test_Present : Boolean := True;
      Readme_Present : Boolean := True;
      Registered_In_Core_Suite : Boolean := True;
      Duplicate_Core_Suite_Registration : Boolean := False;
      Orphan_Source : Boolean := False;
      Reopened_Remaining_Gap : Boolean := False;
      Release_Documentation_Agreed : Boolean := True;
      Evidence_Present : Boolean := True;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Test_Fingerprint : Natural := 0;
      Expected_Test_Fingerprint : Natural := 0;
      Suite_Fingerprint : Natural := 0;
      Expected_Suite_Fingerprint : Natural := 0;
      Documentation_Fingerprint : Natural := 0;
      Expected_Documentation_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Readiness_Row);

   type Readiness_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Readiness_Entry is record
      Id : Natural := 0;
      Surface : Readiness_Surface := Surface_Unknown;
      Status : Readiness_Status := Status_Not_Checked;
      Result_Class : Readiness_Result_Class := Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Readiness_Entry);

   type Readiness_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Validated_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Readiness_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Readiness_Input; Row : Readiness_Row);
   function Build (Input : Readiness_Input) return Readiness_Model;
   function Result_For (Model : Readiness_Model; Id : Natural) return Readiness_Entry;
   function Class_For_Status (Status : Readiness_Status) return Readiness_Result_Class;
   function Release_Readiness_Achieved (Model : Readiness_Model) return Boolean;

end Editor.Ada_Phase579_Release_Readiness_Validation_Pass1431;
