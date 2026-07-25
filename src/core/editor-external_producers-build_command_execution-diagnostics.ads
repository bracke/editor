with Editor.External_Producers.Build_Command_Execution;

package Editor.External_Producers.Build_Command_Execution.Diagnostics is

   procedure Append_Output_Text_Lines
     (Text  : String;
      Lines : in out Diagnostic_Text_Line_Array);

   function Extract_Diagnostic_Lines_From_Build_Result
     (Result : Build_Run_Result) return Diagnostic_Text_Line_Array;

   function Ingest_Build_Run_Diagnostics
     (S                : in out Editor.State.State_Type;
      Producer         : Editor.External_Producers.Diagnostics.Producer_Source;
      Result           : Build_Run_Result;
      Show_Diagnostics : Boolean := False) return Diagnostic_Line_Command_Result;


end Editor.External_Producers.Build_Command_Execution.Diagnostics;
