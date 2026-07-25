with Editor.External_Producers.Diagnostic_Normalization;
with Editor.External_Producers.Source_Metadata;

package body Editor.External_Producers.Diagnostics is

   function Build_External_Producer_Source
     (Kind : Producer_Kind) return Producer_Source
     renames Editor.External_Producers.Source_Metadata.Build_External_Producer_Source;

   function Build_Compiler_Diagnostics_Producer_Source
     return Producer_Source
     renames Editor.External_Producers.Source_Metadata.Build_Compiler_Diagnostics_Producer_Source;

   function Producer_Kind_Is_Valid
     (Kind : Producer_Kind) return Boolean
     renames Editor.External_Producers.Source_Metadata.Producer_Kind_Is_Valid;

   function Producer_Source_Is_Valid
     (Producer : Producer_Source) return Boolean
     renames Editor.External_Producers.Source_Metadata.Producer_Source_Is_Valid;

   function Stable_Name (Kind : Producer_Kind) return String
     renames Editor.External_Producers.Source_Metadata.Stable_Name;

   function Display_Label (Kind : Producer_Kind) return String
     renames Editor.External_Producers.Source_Metadata.Display_Label;

   function Map_External_Producer_To_Diagnostic_Source
     (Producer : Producer_Source)
      return Editor.Feature_Diagnostics.Diagnostic_Source_Kind
     renames Editor.External_Producers.Source_Metadata.Map_External_Producer_To_Diagnostic_Source;

   function Map_Compiler_Severity_To_Diagnostic_Severity
     (Severity : Compiler_Severity)
      return Editor.Feature_Diagnostics.Diagnostic_Severity
     renames Editor.External_Producers.Source_Metadata.Map_Compiler_Severity_To_Diagnostic_Severity;

   function Resolve_Diagnostic_File_Target
     (S          : Editor.State.State_Type;
      File_Label : String) return Buffer_Target_Resolution
     renames Editor.External_Producers.Diagnostic_Normalization.Resolve_Diagnostic_File_Target;

   function Build_Normalized_Diagnostic_Source_Label
     (Tool_Name  : String;
      File_Label : String) return String
     renames Editor.External_Producers.Diagnostic_Normalization.Build_Normalized_Diagnostic_Source_Label;

   function Normalize_Diagnostic_Record
     (Item : Diagnostic_Record) return Diagnostic_Record
     renames Editor.External_Producers.Diagnostic_Normalization.Normalize_External_Diagnostic_Record;

   function Normalize_Compiler_Diagnostic
     (S        : Editor.State.State_Type;
      Producer : Producer_Source;
      Input    : Compiler_Record) return Diagnostic_Record
     renames Editor.External_Producers.Diagnostic_Normalization.Normalize_Compiler_Diagnostic;

   function Normalize_Compiler_Diagnostic_Batch
     (S        : Editor.State.State_Type;
      Producer : Producer_Source;
      Inputs   : Compiler_Record_Array) return Normalized_Batch
     renames Editor.External_Producers.Diagnostic_Normalization.Normalize_Compiler_Diagnostic_Batch;

   function Ingest_Diagnostic_Record
     (S        : in out Editor.State.State_Type;
      Producer : Producer_Source;
      Item     : Diagnostic_Record)
      return Editor.Producer_Contracts.Producer_Result
     renames Editor.External_Producers.Diagnostic_Normalization.Ingest_Diagnostic_Record;

   function Ingest_Diagnostic_Batch
     (S        : in out Editor.State.State_Type;
      Producer : Producer_Source;
      Items    : Diagnostic_Record_Array) return Producer_Batch_Result
     renames Editor.External_Producers.Diagnostic_Normalization.Ingest_Diagnostic_Batch;

   function Ingest_Compiler_Diagnostic_Batch
     (S        : in out Editor.State.State_Type;
      Producer : Producer_Source;
      Inputs   : Compiler_Record_Array) return Producer_Batch_Result
     renames Editor.External_Producers.Diagnostic_Normalization.Ingest_Compiler_Diagnostic_Batch;

   function Assert_Normalized_Batch_Consistent
     (Batch : Normalized_Batch) return Boolean
     renames Editor.External_Producers.Diagnostic_Normalization.Assert_Normalized_Batch_Consistent;

end Editor.External_Producers.Diagnostics;
