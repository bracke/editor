with Ada.Strings.Unbounded;
with Editor.External_Producers.Diagnostic_Text_Lines;
with Editor.External_Producers.Diagnostics;
with Editor.State;

package Editor.External_Producers.Diagnostic_Line_Parsing is

   subtype Producer_Source is Editor.External_Producers.Diagnostics.Producer_Source;
   subtype Compiler_Severity is
     Editor.External_Producers.Diagnostics.Compiler_Severity;
   subtype Diagnostic_Record is
     Editor.External_Producers.Diagnostics.Diagnostic_Record;

   type Parse_Status is
     (Parse_Accepted,
      Parse_Ignored_Blank,
      Parse_Ignored_Unrecognized,
      Parse_Rejected_Malformed);

   type Parse_Reason is
     (No_Parse_Reason,
      Blank_Line,
      Unrecognized_Format,
      Missing_Line,
      Missing_Column,
      Nonnumeric_Line,
      Nonnumeric_Column,
      Zero_Line,
      Zero_Column,
      Missing_Severity,
      Missing_Message,
      Malformed_Location);

   type Parse_Result is record
      Status     : Parse_Status := Parse_Ignored_Unrecognized;
      Reason     : Parse_Reason := Unrecognized_Format;
      Has_Record : Boolean := False;
      Diagnostic_Record : Editor.External_Producers.Diagnostics.Compiler_Record;
   end record;

   package Text_Line_Vectors renames
     Editor.External_Producers.Diagnostic_Text_Lines.Vectors;

   subtype Text_Line_Array is
     Editor.External_Producers.Diagnostic_Text_Lines.Array_Type;

   type Batch_Parse_Result is record
      Input_Count                  : Natural := 0;
      Accepted_Count               : Natural := 0;
      Ignored_Blank_Count          : Natural := 0;
      Ignored_Unrecognized_Count   : Natural := 0;
      Rejected_Malformed_Count     : Natural := 0;
      Records                      : Editor.External_Producers.Diagnostics.Compiler_Record_Array;
      Error_Count                  : Natural := 0;
      Warning_Count                : Natural := 0;
      Info_Count                   : Natural := 0;
      Note_Count                   : Natural := 0;
      Unknown_Count                : Natural := 0;
   end record;

   type Ingestion_Result is record
      Parse_Input_Count                 : Natural := 0;
      Parse_Accepted_Count              : Natural := 0;
      Parse_Ignored_Blank_Count         : Natural := 0;
      Parse_Ignored_Unrecognized_Count  : Natural := 0;
      Parse_Rejected_Malformed_Count    : Natural := 0;
      Normalized_Count                  : Natural := 0;
      Parsed_Error_Count                : Natural := 0;
      Parsed_Warning_Count              : Natural := 0;
      Parsed_Info_Count                 : Natural := 0;
      Parsed_Note_Count                 : Natural := 0;
      Parsed_Unknown_Count              : Natural := 0;
      Ingestion_Result                  :
        Editor.External_Producers.Diagnostics.Producer_Batch_Result;
   end record;

   type Command_Outcome is
     (Diagnostic_Line_Command_Succeeded,
      Diagnostic_Line_Command_No_Input,
      Diagnostic_Line_Command_No_Diagnostics,
      Diagnostic_Line_Command_Malformed_Only);

   type Command_Result is record
      Ingestion       : Ingestion_Result;
      Command_Message : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Should_Show_Diagnostics : Boolean := False;
      Outcome         : Command_Outcome := Diagnostic_Line_Command_No_Input;
   end record;

   function Parse_Compiler_Diagnostic_Severity
     (Token : String) return Compiler_Severity;

   function Parse_Compiler_Diagnostic_Line
     (Line      : String;
      Tool_Name : String := "") return Parse_Result;

   function Parse_Compiler_Diagnostic_Lines
     (Lines     : Text_Line_Array;
      Tool_Name : String := "") return Batch_Parse_Result;

   function Assert_Diagnostic_Line_Batch_Consistent
     (Batch : Batch_Parse_Result) return Boolean;

   function Normalize_Parsed_Compiler_Diagnostic
     (S        : Editor.State.State_Type;
      Producer : Producer_Source;
      Parsed   : Parse_Result) return Diagnostic_Record;

   function Ingest_Compiler_Diagnostic_Lines
     (S        : in out Editor.State.State_Type;
      Producer : Producer_Source;
      Lines    : Text_Line_Array) return Ingestion_Result;

   function Diagnostic_Line_Ingestion_Result_Is_Consistent
     (Result : Ingestion_Result) return Boolean;

   procedure Assert_Diagnostic_Line_Ingestion_Result_Consistent
     (Result : Ingestion_Result);

   function Classify_Diagnostic_Line_Command_Outcome
     (Result : Ingestion_Result) return Command_Outcome;

   function Build_Diagnostic_Line_Command_Feedback
     (Result : Ingestion_Result) return String;

   function Format_Diagnostic_Line_Ingestion_Result
     (Result : Ingestion_Result) return String;

   function Empty_Diagnostic_Line_Command_Result return Command_Result;

   function Ingest_Diagnostic_Lines_From_Command
     (S                : in out Editor.State.State_Type;
      Producer         : Producer_Source;
      Lines            : Text_Line_Array;
      Show_Diagnostics : Boolean := False) return Command_Result;

   function Ingest_Diagnostic_Lines_From_Command_With_Tool_Label
     (S                : in out Editor.State.State_Type;
      Producer         : Producer_Source;
      Lines            : Text_Line_Array;
      Tool_Label       : String;
      Show_Diagnostics : Boolean := False) return Command_Result;

end Editor.External_Producers.Diagnostic_Line_Parsing;
