with Editor.External_Producers;
with Editor.State;

package Editor.Build_Diagnostics is

   --  Phase 556 public build diagnostics ingestion and parsing seam. This
   --  package owns only the explicit build-output diagnostics ingestion policy,
   --  bounded handoff from completed build output, and coherence assertions for
   --  the retained GNAT/GPRbuild parser. It does not execute builds, stream
   --  output, render diagnostics, persist rows, inspect files, infer project
   --  metadata, or create a build-local diagnostics table.

   type Build_Diagnostics_Ingestion_Policy is
     (Build_Diagnostics_Ingestion_Disabled,
      Build_Diagnostics_Ingestion_On_Request,
      Build_Diagnostics_Ingestion_Always_For_Build_Run);

   Max_Build_Diagnostic_Input_Lines : constant Natural := 512;

   function Build_Diagnostics_Ingestion_Allowed
     (Policy                   : Build_Diagnostics_Ingestion_Policy;
      Request_Show_Diagnostics : Boolean) return Boolean;

   function Build_Diagnostics_Show_Diagnostics_Allowed
     (Policy                   : Build_Diagnostics_Ingestion_Policy;
      Request_Show_Diagnostics : Boolean) return Boolean;

   function Build_Diagnostic_Source_Metadata
     (Request : Editor.External_Producers.Build_Run_Request)
      return Editor.External_Producers.External_Producer_Source;

   function Build_Diagnostic_Source_Display_Label
     (Request : Editor.External_Producers.Build_Run_Request) return String;

   function Bounded_Build_Output_Diagnostic_Lines
     (Result : Editor.External_Producers.Build_Run_Result)
      return Editor.External_Producers.Diagnostic_Text_Line_Array;

   function Parse_Build_Output_Diagnostics
     (Request : Editor.External_Producers.Build_Run_Request;
      Result  : Editor.External_Producers.Build_Run_Result)
      return Editor.External_Producers.Diagnostic_Line_Batch_Parse_Result;

   function Ingest_Build_Diagnostics_Through_Diagnostics
     (S                        : in out Editor.State.State_Type;
      Request                  : Editor.External_Producers.Build_Run_Request;
      Result                   : Editor.External_Producers.Build_Run_Result;
      Policy                   : Build_Diagnostics_Ingestion_Policy;
      Request_Show_Diagnostics : Boolean := False)
      return Editor.External_Producers.Diagnostic_Line_Command_Result;

   function Assert_Build_Diagnostics_Output_Bounded return Boolean;
   function Assert_Build_Diagnostics_Uses_Diagnostics_API return Boolean;
   function Assert_Build_Diagnostics_Not_Persisted return Boolean;
   function Assert_Build_Diagnostics_Render_Not_Parsing return Boolean;

   function Assert_Build_Diagnostic_Source_Display_Labels_Bounded
     return Boolean;

   function Assert_Build_Diagnostics_Parse_Common_GNAT_Lines return Boolean;
   function Assert_Build_Diagnostics_Parse_Common_GPRBuild_Lines return Boolean;
   function Assert_Build_Diagnostics_Bounds_And_Summarizes_Output return Boolean;
   function Assert_Build_Diagnostics_Rejects_Malformed_And_Chatter return Boolean;
   function Assert_Build_Diagnostics_Parsing_Coherent return Boolean;

   function Assert_Public_Build_Diagnostics_Ingestion_Foundation_Coherent
     return Boolean;

end Editor.Build_Diagnostics;
