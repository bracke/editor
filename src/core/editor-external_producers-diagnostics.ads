with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.External_Producers.Diagnostics_Types;
with Editor.Feature_Diagnostics;
with Editor.Producer_Contracts;
with Editor.State;

package Editor.External_Producers.Diagnostics is

   subtype Producer_Kind is
     Editor.External_Producers.Diagnostics_Types.Producer_Kind;
   No_External_Producer : constant Producer_Kind :=
     Editor.External_Producers.Diagnostics_Types.No_External_Producer;
   Build_Diagnostics_Producer : constant Producer_Kind :=
     Editor.External_Producers.Diagnostics_Types.Build_Diagnostics_Producer;
   Compiler_Diagnostics_Producer : constant Producer_Kind :=
     Editor.External_Producers.Diagnostics_Types.Compiler_Diagnostics_Producer;

   subtype Producer_Source is
     Editor.External_Producers.Diagnostics_Types.Producer_Source;
   subtype Diagnostic_Record is
     Editor.External_Producers.Diagnostics_Types.Diagnostic_Record;
   package Diagnostic_Record_Vectors renames
     Editor.External_Producers.Diagnostics_Types.Diagnostic_Record_Vectors;
   subtype Diagnostic_Record_Array is
     Editor.External_Producers.Diagnostics_Types.Diagnostic_Record_Array;
   subtype Compiler_Severity is
     Editor.External_Producers.Diagnostics_Types.Compiler_Severity;
   subtype Compiler_Diagnostic_Severity is
     Editor.External_Producers.Diagnostics_Types.Compiler_Diagnostic_Severity;
   Compiler_Info : constant Compiler_Severity :=
     Editor.External_Producers.Diagnostics_Types.Compiler_Info;
   Compiler_Note : constant Compiler_Severity :=
     Editor.External_Producers.Diagnostics_Types.Compiler_Note;
   Compiler_Warning : constant Compiler_Severity :=
     Editor.External_Producers.Diagnostics_Types.Compiler_Warning;
   Compiler_Error : constant Compiler_Severity :=
     Editor.External_Producers.Diagnostics_Types.Compiler_Error;
   Compiler_Fatal : constant Compiler_Severity :=
     Editor.External_Producers.Diagnostics_Types.Compiler_Fatal;
   Compiler_Unknown : constant Compiler_Severity :=
     Editor.External_Producers.Diagnostics_Types.Compiler_Unknown;
   subtype Compiler_Record is
     Editor.External_Producers.Diagnostics_Types.Compiler_Record;
   package Compiler_Record_Vectors renames
     Editor.External_Producers.Diagnostics_Types.Compiler_Record_Vectors;
   subtype Compiler_Record_Array is
     Editor.External_Producers.Diagnostics_Types.Compiler_Record_Array;
   subtype Buffer_Target_Resolution is
     Editor.External_Producers.Diagnostics_Types.Buffer_Target_Resolution;
   subtype Normalized_Batch is
     Editor.External_Producers.Diagnostics_Types.Normalized_Batch;
   subtype Producer_Batch_Result is
     Editor.External_Producers.Diagnostics_Types.Producer_Batch_Result;

   function Build_External_Producer_Source
     (Kind : Producer_Kind) return Producer_Source;

   function Build_Compiler_Diagnostics_Producer_Source
     return Producer_Source;

   function Producer_Kind_Is_Valid
     (Kind : Producer_Kind) return Boolean;

   function Producer_Source_Is_Valid
     (Producer : Producer_Source) return Boolean;

   function Stable_Name (Kind : Producer_Kind) return String;

   function Display_Label (Kind : Producer_Kind) return String;

   function Map_External_Producer_To_Diagnostic_Source
     (Producer : Producer_Source)
      return Editor.Feature_Diagnostics.Diagnostic_Source_Kind;

   function Map_Compiler_Severity_To_Diagnostic_Severity
     (Severity : Compiler_Severity)
      return Editor.Feature_Diagnostics.Diagnostic_Severity;

   function Resolve_Diagnostic_File_Target
     (S          : Editor.State.State_Type;
      File_Label : String) return Buffer_Target_Resolution;

   function Build_Normalized_Diagnostic_Source_Label
     (Tool_Name  : String;
      File_Label : String) return String;

   function Normalize_Diagnostic_Record
     (Item : Diagnostic_Record) return Diagnostic_Record;

   function Normalize_Compiler_Diagnostic
     (S        : Editor.State.State_Type;
      Producer : Producer_Source;
      Input    : Compiler_Record) return Diagnostic_Record;

   function Normalize_Compiler_Diagnostic_Batch
     (S        : Editor.State.State_Type;
      Producer : Producer_Source;
      Inputs   : Compiler_Record_Array) return Normalized_Batch;

   function Ingest_Diagnostic_Record
     (S        : in out Editor.State.State_Type;
      Producer : Producer_Source;
      Item     : Diagnostic_Record)
      return Editor.Producer_Contracts.Producer_Result;

   function Ingest_Diagnostic_Batch
     (S        : in out Editor.State.State_Type;
      Producer : Producer_Source;
      Items    : Diagnostic_Record_Array) return Producer_Batch_Result;

   function Ingest_Compiler_Diagnostic_Batch
     (S        : in out Editor.State.State_Type;
      Producer : Producer_Source;
      Inputs   : Compiler_Record_Array) return Producer_Batch_Result;

   function Assert_Normalized_Batch_Consistent
     (Batch : Normalized_Batch) return Boolean;

end Editor.External_Producers.Diagnostics;
