with Ada.Containers.Vectors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Feature_Diagnostics;

package Editor.External_Producers.Diagnostics_Types is

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

   subtype Compiler_Diagnostic_Severity is Compiler_Severity;

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

end Editor.External_Producers.Diagnostics_Types;
