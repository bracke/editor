with Editor.External_Producers.Diagnostic_Line_Pipeline;

package body Editor.External_Producers.Diagnostic_Line_Parsing is

   function Parse_Compiler_Diagnostic_Severity
     (Token : String) return Compiler_Severity
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Parse_Compiler_Diagnostic_Severity;

   function Parse_Compiler_Diagnostic_Line
     (Line      : String;
      Tool_Name : String := "") return Parse_Result
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Parse_Compiler_Diagnostic_Line;

   function Parse_Compiler_Diagnostic_Lines
     (Lines     : Text_Line_Array;
      Tool_Name : String := "") return Batch_Parse_Result
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Parse_Compiler_Diagnostic_Lines;

   function Assert_Diagnostic_Line_Batch_Consistent
     (Batch : Batch_Parse_Result) return Boolean
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Assert_Diagnostic_Line_Batch_Consistent;

   function Normalize_Parsed_Compiler_Diagnostic
     (S        : Editor.State.State_Type;
      Producer : Producer_Source;
      Parsed   : Parse_Result) return Diagnostic_Record
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Normalize_Parsed_Compiler_Diagnostic;

   function Ingest_Compiler_Diagnostic_Lines
     (S        : in out Editor.State.State_Type;
      Producer : Producer_Source;
      Lines    : Text_Line_Array) return Ingestion_Result
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Ingest_Compiler_Diagnostic_Lines;

   function Diagnostic_Line_Ingestion_Result_Is_Consistent
     (Result : Ingestion_Result) return Boolean
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Diagnostic_Line_Ingestion_Result_Is_Consistent;

   procedure Assert_Diagnostic_Line_Ingestion_Result_Consistent
     (Result : Ingestion_Result)
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Assert_Diagnostic_Line_Ingestion_Result_Consistent;

   function Classify_Diagnostic_Line_Command_Outcome
     (Result : Ingestion_Result) return Command_Outcome
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Classify_Diagnostic_Line_Command_Outcome;

   function Build_Diagnostic_Line_Command_Feedback
     (Result : Ingestion_Result) return String
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Build_Diagnostic_Line_Command_Feedback;

   function Format_Diagnostic_Line_Ingestion_Result
     (Result : Ingestion_Result) return String
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Format_Diagnostic_Line_Ingestion_Result;

   function Empty_Diagnostic_Line_Command_Result return Command_Result
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Empty_Diagnostic_Line_Command_Result;

   function Ingest_Diagnostic_Lines_From_Command
     (S                : in out Editor.State.State_Type;
      Producer         : Producer_Source;
      Lines            : Text_Line_Array;
      Show_Diagnostics : Boolean := False) return Command_Result
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Ingest_Diagnostic_Lines_From_Command;

   function Ingest_Diagnostic_Lines_From_Command_With_Tool_Label
     (S                : in out Editor.State.State_Type;
      Producer         : Producer_Source;
      Lines            : Text_Line_Array;
      Tool_Label       : String;
      Show_Diagnostics : Boolean := False) return Command_Result
     renames Editor.External_Producers.Diagnostic_Line_Pipeline.Ingest_Diagnostic_Lines_From_Command_With_Tool_Label;

end Editor.External_Producers.Diagnostic_Line_Parsing;
