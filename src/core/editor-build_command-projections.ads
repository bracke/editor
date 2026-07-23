with Ada.Strings.Unbounded;
with Editor.Build_Output_Details;
with Editor.Build_Result_Summary;
with Editor.Build_UI;
with Editor.External_Producers;
with Editor.State;

package Editor.Build_Command.Projections is

   function Summary_Kind_For
     (Status : Editor.External_Producers.Build_Run_Status)
      return Editor.Build_Result_Summary.Build_Result_Summary_Kind;

   function Summary_Tool_For
     (Tool : Editor.External_Producers.Build_Tool_Kind)
      return Editor.Build_Result_Summary.Build_Result_Tool_Kind;

   function Compiler_Tool_Name
     (Tool : Editor.External_Producers.Build_Tool_Kind) return String;

   function Build_Run_Fingerprint
     (Result : Editor.External_Producers.Build_Run_Result) return Natural;

   procedure Feed_Language_Service_Compiler_Backend
     (State   : in out Editor.State.State_Type;
      Request : Editor.External_Producers.Build_Run_Request;
      Result  : Editor.External_Producers.Build_Run_Result);

   function Summary_Mode_For
     (Request : Editor.External_Producers.Build_Run_Request)
      return Editor.Build_Result_Summary.Build_Result_Request_Mode;

   function Summary_Diagnostics_For
     (Result : Editor.External_Producers.Diagnostic_Line_Command_Result;
      Allowed : Boolean)
      return Editor.Build_Result_Summary.Diagnostics_Ingestion_Summary_Status;

   function Runner_Status_Label
     (Status : Editor.External_Producers.Build_Run_Status) return String;

   function Output_Runner_Status_For
     (Status : Editor.External_Producers.Build_Run_Status)
      return Editor.Build_Output_Details.Build_Output_Runner_Status;

   function Output_Details_From_Result
     (Build : Editor.External_Producers.Build_Run_Result)
      return Editor.Build_Output_Details.Latest_Build_Output_Details;

   function Public_Build_Duration_Milliseconds
     (State : Editor.State.State_Type) return Natural;

   function Summary_From_Result
     (Request : Editor.External_Producers.Build_Run_Request;
      Result  : Editor.External_Producers.Build_Command_Result;
      Diagnostics_Allowed : Boolean;
      Duration_Milliseconds : Natural := 0;
      Has_Duration : Boolean := False)
      return Editor.Build_Result_Summary.Latest_Build_Result_Summary;

   function Selected_Candidate_Preflight_Status
     (State : Editor.State.State_Type) return Build_Run_Readiness_Status;

   function Map_UI_Status
     (Status : Editor.Build_UI.Public_Build_UI_Validation_Status)
      return Build_Run_Readiness_Status;

end Editor.Build_Command.Projections;
