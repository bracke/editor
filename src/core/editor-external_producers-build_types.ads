with Ada.Strings.Unbounded;
with Editor.External_Producers.Diagnostic_Line_Parsing;

package Editor.External_Producers.Build_Types is

   package Diagnostic_Text_Line_Vectors renames
     Editor.External_Producers.Diagnostic_Line_Parsing.Text_Line_Vectors;

   subtype Diagnostic_Text_Line_Array is
     Editor.External_Producers.Diagnostic_Line_Parsing.Text_Line_Array;

   subtype Diagnostic_Line_Command_Result is
     Editor.External_Producers.Diagnostic_Line_Parsing.Command_Result;

   type Build_Run_Result is record
      Status           : Editor.External_Producers.Build_Run_Status :=
        Editor.External_Producers.Build_Run_Not_Available;
      Output_Capture_Mode :
        Editor.External_Producers.Process_Output_Capture_Mode :=
          Editor.External_Producers.Process_Output_Capture_None;
      Exit_Code        : Integer := 0;
      Has_Exit_Code    : Boolean := False;
      Stdout_Text      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stderr_Text      : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Stdout_Truncated : Boolean := False;
      Stderr_Truncated : Boolean := False;
      Output_Partial   : Boolean := False;
      Diagnostic_Lines : Diagnostic_Text_Line_Array;
   end record;

   type Build_Command_Result is record
      Build_Result      : Build_Run_Result;
      Diagnostic_Result : Diagnostic_Line_Command_Result;
      Command_Message   : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

end Editor.External_Producers.Build_Types;
