with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.External_Producers.Diagnostic_Line_Parsing;
with Editor.External_Producers.Diagnostics;
with Editor.State;

package Editor.External_Producers.Diagnostic_Line_Pipeline is

   function Parse_Compiler_Diagnostic_Severity
     (Token : String)
      return Editor.External_Producers.Diagnostic_Line_Parsing.Compiler_Severity;

   function Parse_Compiler_Diagnostic_Line
     (Line      : String;
      Tool_Name : String := "")
      return Editor.External_Producers.Diagnostic_Line_Parsing.Parse_Result;

   function Parse_Compiler_Diagnostic_Lines
     (Lines     : Editor.External_Producers.Diagnostic_Line_Parsing.Text_Line_Array;
      Tool_Name : String := "")
      return Editor.External_Producers.Diagnostic_Line_Parsing.Batch_Parse_Result;

   function Assert_Diagnostic_Line_Batch_Consistent
     (Batch : Editor.External_Producers.Diagnostic_Line_Parsing.Batch_Parse_Result)
      return Boolean;

   function Normalize_Parsed_Compiler_Diagnostic
     (S        : Editor.State.State_Type;
      Producer : Editor.External_Producers.Diagnostics.Producer_Source;
      Parsed   : Editor.External_Producers.Diagnostic_Line_Parsing.Parse_Result)
      return Editor.External_Producers.Diagnostics.Diagnostic_Record;

   function Ingest_Compiler_Diagnostic_Lines
     (S        : in out Editor.State.State_Type;
      Producer : Editor.External_Producers.Diagnostics.Producer_Source;
      Lines    : Editor.External_Producers.Diagnostic_Line_Parsing.Text_Line_Array)
      return Editor.External_Producers.Diagnostic_Line_Parsing.Ingestion_Result;

   function Diagnostic_Line_Ingestion_Result_Is_Consistent
     (Result : Editor.External_Producers.Diagnostic_Line_Parsing.Ingestion_Result)
      return Boolean;

   procedure Assert_Diagnostic_Line_Ingestion_Result_Consistent
     (Result : Editor.External_Producers.Diagnostic_Line_Parsing.Ingestion_Result);

   function Classify_Diagnostic_Line_Command_Outcome
     (Result : Editor.External_Producers.Diagnostic_Line_Parsing.Ingestion_Result)
      return Editor.External_Producers.Diagnostic_Line_Parsing.Command_Outcome;

   function Build_Diagnostic_Line_Command_Feedback
     (Result : Editor.External_Producers.Diagnostic_Line_Parsing.Ingestion_Result)
      return String;

   function Format_Diagnostic_Line_Ingestion_Result
     (Result : Editor.External_Producers.Diagnostic_Line_Parsing.Ingestion_Result)
      return String;

   function Empty_Diagnostic_Line_Command_Result
     return Editor.External_Producers.Diagnostic_Line_Parsing.Command_Result;

   function Ingest_Diagnostic_Lines_From_Command
     (S                : in out Editor.State.State_Type;
      Producer         : Editor.External_Producers.Diagnostics.Producer_Source;
      Lines            : Editor.External_Producers.Diagnostic_Line_Parsing.Text_Line_Array;
      Show_Diagnostics : Boolean := False)
      return Editor.External_Producers.Diagnostic_Line_Parsing.Command_Result;

   function Ingest_Diagnostic_Lines_From_Command_With_Tool_Label
     (S                : in out Editor.State.State_Type;
      Producer         : Editor.External_Producers.Diagnostics.Producer_Source;
      Lines            : Editor.External_Producers.Diagnostic_Line_Parsing.Text_Line_Array;
      Tool_Label       : String;
      Show_Diagnostics : Boolean := False)
      return Editor.External_Producers.Diagnostic_Line_Parsing.Command_Result;

   function Diagnostic_Line_Parser_Audit_Passes return Boolean;

   function Diagnostic_Line_Command_Surface_Audit_Passes return Boolean;

   function Diagnostic_Line_Layering_Audit_Passes return Boolean;

   procedure Reset_Diagnostic_Line_Command_State_For_Project_Close
     (S : in out Editor.State.State_Type);

   procedure Reset_Diagnostic_Line_Command_State_For_Workspace_Close
     (S : in out Editor.State.State_Type);

end Editor.External_Producers.Diagnostic_Line_Pipeline;
