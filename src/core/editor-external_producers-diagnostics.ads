with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Editor.Feature_Diagnostics;
with Editor.Producer_Contracts;
with Editor.State;

package Editor.External_Producers.Diagnostics is

   type Producer_Kind is
     (No_External_Producer,
      Build_Diagnostics_Producer,
      Compiler_Diagnostics_Producer);

   type Producer_Source is record
      Kind          : Producer_Kind := No_External_Producer;
      Stable_Name   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Display_Label : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   type Diagnostic_Record is record
      Severity      : Editor.Feature_Diagnostics.Diagnostic_Severity :=
        Editor.Feature_Diagnostics.Diagnostic_Info;
      Message       : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Source_Label  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Target    : Boolean := False;
      Target_Buffer : Natural := Editor.Feature_Diagnostics.No_Buffer;
      Target_Line   : Natural := 0;
      Target_Column : Natural := 0;
      Has_Edit          : Boolean := False;
      Edit_Start_Line   : Natural := 0;
      Edit_Start_Column : Natural := 0;
      Edit_End_Line     : Natural := 0;
      Edit_End_Column   : Natural := 0;
      Replacement_Text  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Quick_Fix_Label   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Quick_Fix_Detail  : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   package Diagnostic_Record_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Diagnostic_Record);

   subtype Diagnostic_Record_Array is Diagnostic_Record_Vectors.Vector;

   type Compiler_Severity is
     (Compiler_Info,
      Compiler_Note,
      Compiler_Warning,
      Compiler_Error,
      Compiler_Fatal,
      Compiler_Unknown);

   type Compiler_Record is record
      Severity     : Compiler_Severity := Compiler_Unknown;
      Message      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      File_Label   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Has_Location : Boolean := False;
      Line         : Natural := 0;
      Column       : Natural := 0;
      Tool_Name    : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   package Compiler_Record_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Compiler_Record);

   subtype Compiler_Record_Array is Compiler_Record_Vectors.Vector;

   type Buffer_Target_Resolution is record
      Found  : Boolean := False;
      Buffer : Natural := Editor.Feature_Diagnostics.No_Buffer;
   end record;

   type Normalized_Batch is record
      Items                  : Diagnostic_Record_Array;
      Input_Count            : Natural := 0;
      Normalized_Count       : Natural := 0;
      Untargeted_Count       : Natural := 0;
      Empty_Message_Count    : Natural := 0;
      Invalid_Location_Count : Natural := 0;
   end record;

   type Producer_Batch_Result is record
      Accepted_Count      : Natural := 0;
      Accepted_Untargeted : Natural := 0;
      Rejected_Count      : Natural := 0;
      Evicted_Count       : Natural := 0;
      Projection_Changed  : Boolean := False;
   end record;

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
