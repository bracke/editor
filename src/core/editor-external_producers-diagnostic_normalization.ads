with Editor.External_Producers.Diagnostics;
with Editor.Producer_Contracts;
with Editor.State;

package Editor.External_Producers.Diagnostic_Normalization is

   function Is_Diagnostic_Path_Absolute (Path : String) return Boolean;

   function Starts_With_Case_Insensitive
     (Text   : String;
      Prefix : String) return Boolean;

   function Diagnostic_Path_Has_Parent_Traversal (Path : String) return Boolean;

   function Diagnostic_Label_Project_Bounded
     (S          : Editor.State.State_Type;
      File_Label : String) return Boolean;

   function Resolve_Diagnostic_File_Target
     (S          : Editor.State.State_Type;
      File_Label : String) return Editor.External_Producers.Diagnostics.Buffer_Target_Resolution;

   function Build_Normalized_Diagnostic_Source_Label
     (Tool_Name  : String;
      File_Label : String) return String;

   function Normalize_Compiler_Diagnostic
     (S        : Editor.State.State_Type;
      Producer : Editor.External_Producers.Diagnostics.Producer_Source;
      Input    : Editor.External_Producers.Diagnostics.Compiler_Record)
      return Editor.External_Producers.Diagnostics.Diagnostic_Record;

   function Normalize_Compiler_Diagnostic_Batch
     (S        : Editor.State.State_Type;
      Producer : Editor.External_Producers.Diagnostics.Producer_Source;
      Inputs   : Editor.External_Producers.Diagnostics.Compiler_Record_Array)
      return Editor.External_Producers.Diagnostics.Normalized_Batch;

   function Ingest_Compiler_Diagnostic_Batch
     (S        : in out Editor.State.State_Type;
      Producer : Editor.External_Producers.Diagnostics.Producer_Source;
      Inputs   : Editor.External_Producers.Diagnostics.Compiler_Record_Array)
      return Editor.External_Producers.Diagnostics.Producer_Batch_Result;

   function Assert_Normalized_Batch_Consistent
     (Batch : Editor.External_Producers.Diagnostics.Normalized_Batch) return Boolean;

   function Compiler_Diagnostic_Normalization_Audit_Passes return Boolean;

   function Producer_Lifecycle_Audit_Passes return Boolean;

   function Normalize_External_Diagnostic_Record
     (Item : Editor.External_Producers.Diagnostics.Diagnostic_Record) return Editor.External_Producers.Diagnostics.Diagnostic_Record;

   procedure Add_Normalized_Record
     (S           : in out Editor.State.State_Type;
      Producer    : Editor.External_Producers.Diagnostics.Producer_Source;
      Item        : Editor.External_Producers.Diagnostics.Diagnostic_Record;
      Target_Kept : out Boolean);

   function Ingest_Diagnostic_Record
     (S        : in out Editor.State.State_Type;
      Producer : Editor.External_Producers.Diagnostics.Producer_Source;
      Item     : Editor.External_Producers.Diagnostics.Diagnostic_Record)
      return Editor.Producer_Contracts.Producer_Result;

   function Ingest_Diagnostic_Batch
     (S        : in out Editor.State.State_Type;
      Producer : Editor.External_Producers.Diagnostics.Producer_Source;
      Items    : Editor.External_Producers.Diagnostics.Diagnostic_Record_Array)
      return Editor.External_Producers.Diagnostics.Producer_Batch_Result;

   function External_Producer_Audit_Passes return Boolean;

end Editor.External_Producers.Diagnostic_Normalization;
