with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Build_Working_Context;
with Editor.External_Producers;

package Editor.Build_Candidates is

   --  public build candidate discovery model. Candidates are
   --  transient, structured, read-only discovery output. They are not command
   --  descriptors, not consent, not persisted requests, and not execution
   --  handles.

   type Build_Candidate_Kind is
     (Build_Candidate_None,
      Build_Candidate_Alire_Project,
      Build_Candidate_Gpr_Project,
      Build_Candidate_Manual_Request);

   type Build_Candidate_Source is
     (Build_Candidate_Source_None,
      Build_Candidate_Source_Alire_Toml,
      Build_Candidate_Source_Gpr_File,
      Build_Candidate_Source_Manual_UI);

   type Build_Candidate_Validation_Status is
     (Build_Candidate_Valid,
      Build_Candidate_Unavailable,
      Build_Candidate_Rejected_Unstructured,
      Build_Candidate_Rejected_Unsafe_Source,
      Build_Candidate_Rejected_Shell_Text,
      Build_Candidate_Rejected_Persisted_State);

   subtype Build_Candidate_Argument_Vector is
     Editor.External_Producers.Process_Argument_Vector;

   type Build_Candidate_Record is record
      Candidate_Id : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Candidate_Kind : Build_Candidate_Kind := Build_Candidate_None;
      Display_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Tool_Kind : Editor.External_Producers.Build_Tool_Kind :=
        Editor.External_Producers.No_Build_Tool;
      Structured_Arguments : Build_Candidate_Argument_Vector :=
        Editor.External_Producers.Process_Argument_Vectors.Empty_Vector;
      Working_Context : Editor.Build_Working_Context.Build_Working_Context_Record :=
        Editor.Build_Working_Context.None;
      Source_Path_If_Represented : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Discovery_Source : Build_Candidate_Source := Build_Candidate_Source_None;
      Validation_Status : Build_Candidate_Validation_Status :=
        Build_Candidate_Unavailable;
      Validation_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   package Build_Candidate_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Build_Candidate_Record);

   subtype Build_Candidate_Vector is Build_Candidate_Vectors.Vector;

   function Empty_Candidates return Build_Candidate_Vector;

   function Argument_Count
     (Candidate : Build_Candidate_Record) return Natural;

   function Candidate_Id_For_Alire
     (Project_Root : String) return String;

   function Candidate_Id_For_Gpr
     (Project_Root : String;
      Project_Relative_Gpr_Path : String) return String;

   function Alire_Candidate
     (Project_Root : String) return Build_Candidate_Record;

   function Gprbuild_Candidate
     (Project_Root : String;
      Project_Relative_Gpr_Path : String) return Build_Candidate_Record;

   function Build_Candidate_Source_Kind_Label
     (Source : Build_Candidate_Source) return String;

   function Build_Candidate_Project_Relative_Label
     (Candidate : Build_Candidate_Record) return String;

   function Build_Candidate_Disabled_Reason
     (Candidate : Build_Candidate_Record) return String;

   function Manual_Request_Candidate return Build_Candidate_Record;

   function Validate_Candidate
     (Candidate : Build_Candidate_Record)
      return Build_Candidate_Validation_Status;

   procedure Sort_Build_Candidates
     (Candidates : in out Build_Candidate_Vector);

   procedure Append_Unique_Candidate
     (Candidates : in out Build_Candidate_Vector;
      Candidate  : Build_Candidate_Record);

   function Has_Raw_Shell_Command_Field
     (Candidate : Build_Candidate_Record) return Boolean;

   function Has_Remembered_Consent_Field
     (Candidate : Build_Candidate_Record) return Boolean;

   function Has_Process_State_Field
     (Candidate : Build_Candidate_Record) return Boolean;

   function Assert_Build_Candidate_Is_Structured
     (Candidate : Build_Candidate_Record) return Boolean;

   function Assert_Build_Candidate_Is_Transient
     (Candidate : Build_Candidate_Record) return Boolean;

   function Assert_Build_Candidate_Persistence_Excluded
     (Candidate : Build_Candidate_Record) return Boolean;

   function Assert_Build_Candidate_List_Is_Deterministic
     (Candidates : Build_Candidate_Vector) return Boolean;

end Editor.Build_Candidates;
