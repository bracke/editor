with Ada.Strings.Unbounded;
with Editor.Build_Candidates;
with Editor.Build_Working_Context;

package Editor.Build_Candidate_Discovery is

   type Build_Candidate_Discovery_Status is
     (Build_Candidate_Discovery_Complete,
      Build_Candidate_Discovery_No_Project_Context,
      Build_Candidate_Discovery_Rejected_Context,
      Build_Candidate_Discovery_No_Candidates);

   type Build_Candidate_Discovery_Result is record
      Status : Build_Candidate_Discovery_Status :=
        Build_Candidate_Discovery_No_Project_Context;
      Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Candidates : Editor.Build_Candidates.Build_Candidate_Vector :=
        Editor.Build_Candidates.Build_Candidate_Vectors.Empty_Vector;
      Checked_Project_Root : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Alire_Candidate_Count : Natural := 0;
      Gpr_Candidate_Count : Natural := 0;
      Directories_Visited : Natural := 0;
      Files_Inspected : Natural := 0;
      Skipped_Directory_Count : Natural := 0;
      Limit_Reached : Boolean := False;
   end record;

   function Discover_Build_Candidates
     (Context : Editor.Build_Working_Context.Build_Working_Context_Record)
      return Build_Candidate_Discovery_Result;

   function Discover_Alire_Build_Candidate
     (Project_Root : String) return Editor.Build_Candidates.Build_Candidate_Vector;

   function Discover_Gprbuild_Candidates
     (Project_Root : String) return Editor.Build_Candidates.Build_Candidate_Vector;

   function Discover_GPR_Project_Candidates_Bounded
     (Project_Root : String;
      Directories_Visited : out Natural;
      Files_Inspected : out Natural;
      Skipped_Directory_Count : out Natural;
      Limit_Reached : out Boolean)
      return Editor.Build_Candidates.Build_Candidate_Vector;

   function Ignore_Build_Discovery_Directory
     (Project_Relative_Directory : String;
      Simple_Name : String) return Boolean;

   function Build_Candidate_Discovery_Summary
     (Result : Build_Candidate_Discovery_Result) return String;

   function Assert_Build_Candidate_Discovery_Bounded
     (Result : Build_Candidate_Discovery_Result) return Boolean;

   function Assert_Build_Candidate_Discovery_Does_Not_Execute
     (Result : Build_Candidate_Discovery_Result) return Boolean;

   function Assert_Build_Candidate_Discovery_Does_Not_Use_Shell
     (Result : Build_Candidate_Discovery_Result) return Boolean;

   function Assert_Build_Candidate_Discovery_Does_Not_Scan_Outside_Project_Root
     (Result : Build_Candidate_Discovery_Result) return Boolean;

   function Assert_Build_Candidate_Discovery_Depth_Coherent
     (Result : Build_Candidate_Discovery_Result) return Boolean;

end Editor.Build_Candidate_Discovery;
