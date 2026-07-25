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

   function To_Root_Ingestion_Result
     (Result : Ingestion_Result)
      return Editor.External_Producers.Diagnostic_Line_Ingestion_Result
   is
   begin
      return
        (Parse_Input_Count =>
           Result.Parse_Input_Count,
         Parse_Accepted_Count =>
           Result.Parse_Accepted_Count,
         Parse_Ignored_Blank_Count =>
           Result.Parse_Ignored_Blank_Count,
         Parse_Ignored_Unrecognized_Count =>
           Result.Parse_Ignored_Unrecognized_Count,
         Parse_Rejected_Malformed_Count =>
           Result.Parse_Rejected_Malformed_Count,
         Normalized_Count =>
           Result.Normalized_Count,
         Parsed_Error_Count =>
           Result.Parsed_Error_Count,
         Parsed_Warning_Count =>
           Result.Parsed_Warning_Count,
         Parsed_Info_Count =>
           Result.Parsed_Info_Count,
         Parsed_Note_Count =>
           Result.Parsed_Note_Count,
         Parsed_Unknown_Count =>
           Result.Parsed_Unknown_Count,
         Ingestion_Result =>
           (Accepted_Count =>
              Result.Ingestion_Result.Accepted_Count,
            Accepted_Untargeted =>
              Result.Ingestion_Result.Accepted_Untargeted,
            Rejected_Count =>
              Result.Ingestion_Result.Rejected_Count,
            Evicted_Count =>
              Result.Ingestion_Result.Evicted_Count,
            Projection_Changed =>
              Result.Ingestion_Result.Projection_Changed));
   end To_Root_Ingestion_Result;

   function To_Root_Command_Result
     (Result : Command_Result)
      return Editor.External_Producers.Diagnostic_Line_Command_Result
   is
   begin
      return
        (Ingestion =>
           To_Root_Ingestion_Result (Result.Ingestion),
         Command_Message =>
           Result.Command_Message,
         Should_Show_Diagnostics =>
           Result.Should_Show_Diagnostics,
         Outcome =>
           Editor.External_Producers.Diagnostic_Line_Command_Outcome'Val
             (Command_Outcome'Pos (Result.Outcome)));
   end To_Root_Command_Result;

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
