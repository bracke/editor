with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.State;

package Editor.External_Producers.Diagnostic_Line_Pipeline is

   function Parse_Compiler_Diagnostic_Severity
     (Token : String) return Compiler_Diagnostic_Severity;

   function Parse_Compiler_Diagnostic_Line
     (Line      : String;
      Tool_Name : String := "") return Diagnostic_Line_Parse_Result;

   function Parse_Compiler_Diagnostic_Lines
     (Lines     : Diagnostic_Text_Line_Array;
      Tool_Name : String := "") return Diagnostic_Line_Batch_Parse_Result;

   function Assert_Diagnostic_Line_Batch_Consistent
     (Batch : Diagnostic_Line_Batch_Parse_Result) return Boolean;

   function Normalize_Parsed_Compiler_Diagnostic
     (S        : Editor.State.State_Type;
      Producer : External_Producer_Source;
      Parsed   : Diagnostic_Line_Parse_Result) return External_Diagnostic_Record;

   function Ingest_Compiler_Diagnostic_Lines
     (S        : in out Editor.State.State_Type;
      Producer : External_Producer_Source;
      Lines    : Diagnostic_Text_Line_Array) return Diagnostic_Line_Ingestion_Result;

   function Diagnostic_Line_Ingestion_Result_Is_Consistent
     (Result : Diagnostic_Line_Ingestion_Result) return Boolean;

   procedure Assert_Diagnostic_Line_Ingestion_Result_Consistent
     (Result : Diagnostic_Line_Ingestion_Result);

   function Classify_Diagnostic_Line_Command_Outcome
     (Result : Diagnostic_Line_Ingestion_Result)
      return Diagnostic_Line_Command_Outcome;

   function Build_Diagnostic_Line_Command_Feedback
     (Result : Diagnostic_Line_Ingestion_Result) return String;

   function Format_Diagnostic_Line_Ingestion_Result
     (Result : Diagnostic_Line_Ingestion_Result) return String;

   function Empty_Diagnostic_Line_Command_Result
     return Diagnostic_Line_Command_Result;

   function Ingest_Diagnostic_Lines_From_Command
     (S                : in out Editor.State.State_Type;
      Producer         : External_Producer_Source;
      Lines            : Diagnostic_Text_Line_Array;
      Show_Diagnostics : Boolean := False) return Diagnostic_Line_Command_Result;

   function Ingest_Diagnostic_Lines_From_Command_With_Tool_Label
     (S                : in out Editor.State.State_Type;
      Producer         : External_Producer_Source;
      Lines            : Diagnostic_Text_Line_Array;
      Tool_Label       : String;
      Show_Diagnostics : Boolean := False) return Diagnostic_Line_Command_Result;

   function Diagnostic_Line_Parser_Audit_Passes return Boolean;

   function Diagnostic_Line_Command_Surface_Audit_Passes return Boolean;

   function Diagnostic_Line_Layering_Audit_Passes return Boolean;

end Editor.External_Producers.Diagnostic_Line_Pipeline;
