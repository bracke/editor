with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Editor.Ada_Phase579_Project_Scale_Closure_Pass1436 is

   --  Pass1436 is the Phase 579 project-scale closure gate.  It freezes the
   --  post-remediation validation campaign after the seven project-scale
   --  release items and rejects speculative continuation unless a real corpus
   --  failure, source-shaped regression, or concrete RM contradiction is
   --  attached as evidence.

   type Closure_Area is
     (Area_Release_Readiness,
      Area_End_To_End_Integration,
      Area_Real_Ada_Corpus,
      Area_Performance_Boundedness,
      Area_Diagnostic_Quality,
      Area_Architecture_Cleanup,
      Area_Documentation_Handoff,
      Area_Unknown);

   type Closure_Status is
     (Status_Not_Checked,
      Status_Accepted,
      Status_Rejected_Missing_Project_Item,
      Status_Rejected_Reopened_Remaining_Gap,
      Status_Rejected_Speculative_New_Work,
      Status_Rejected_Unregistered_Test,
      Status_Rejected_Missing_Documentation,
      Status_Rejected_Consumer_Disagreement,
      Status_Rejected_Stale_Evidence,
      Status_Indeterminate_Missing_Evidence);

   type Closure_Result_Class is
     (Class_Unknown,
      Class_Accepted,
      Class_Rejected,
      Class_Indeterminate);

   type Closure_Row is record
      Id : Natural := 0;
      Area : Closure_Area := Area_Unknown;
      Name : Ada.Strings.Unbounded.Unbounded_String;

      Evidence_Present : Boolean := True;
      Project_Item_Complete : Boolean := True;
      Test_Registered : Boolean := True;
      Documentation_Present : Boolean := True;
      Consumer_Agreement : Boolean := True;
      Reopens_Remaining_Gap : Boolean := False;
      Proposes_Speculative_Work : Boolean := False;
      Has_Real_Failing_Evidence : Boolean := False;

      Source_Fingerprint : Natural := 0;
      Expected_Source_Fingerprint : Natural := 0;
      Test_Fingerprint : Natural := 0;
      Expected_Test_Fingerprint : Natural := 0;
      Documentation_Fingerprint : Natural := 0;
      Expected_Documentation_Fingerprint : Natural := 0;
      Closure_Fingerprint : Natural := 0;
      Expected_Closure_Fingerprint : Natural := 0;
   end record;

   package Row_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Closure_Row);

   type Closure_Input is record
      Rows : Row_Vectors.Vector;
   end record;

   type Closure_Entry is record
      Id : Natural := 0;
      Area : Closure_Area := Area_Unknown;
      Status : Closure_Status := Status_Not_Checked;
      Result_Class : Closure_Result_Class := Class_Unknown;
      Result_Fingerprint : Natural := 0;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Natural, Element_Type => Closure_Entry);

   type Closure_Model is record
      Entries : Entry_Vectors.Vector;
      Total_Rows : Natural := 0;
      Accepted_Count : Natural := 0;
      Rejected_Count : Natural := 0;
      Indeterminate_Count : Natural := 0;
      Closure_Fingerprint : Natural := 0;
   end record;

   procedure Add_Row (Input : in out Closure_Input; Row : Closure_Row);
   function Build (Input : Closure_Input) return Closure_Model;
   function Result_For (Model : Closure_Model; Id : Natural) return Closure_Entry;
   function Class_For_Status (Status : Closure_Status) return Closure_Result_Class;
   function Phase579_Project_Scale_Closed (Model : Closure_Model) return Boolean;

end Editor.Ada_Phase579_Project_Scale_Closure_Pass1436;
