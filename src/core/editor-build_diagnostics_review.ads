with Editor.Build_Output_Details;
with Editor.Build_Result_Summary;
with Editor.Command_Execution;
with Editor.External_Producers;
with Editor.State;

package Editor.Build_Diagnostics_Review is

   --  build diagnostics review/navigation foundation. This package
   --  exposes only declarative review helpers around Diagnostics-owned rows and
   --  existing Diagnostics commands. It does not execute builds, parse output
   --  from render, own Diagnostics rows, create build-local navigation routes,
   --  persist diagnostics, or store build history.

   type Build_Diagnostics_Review_Result is record
      Build_Rows_Are_Diagnostics_Owned        : Boolean := False;
      Review_Uses_Existing_Diagnostics        : Boolean := False;
      Navigation_Uses_Diagnostics_Routes      : Boolean := False;
      Summary_Stores_No_Diagnostics_Rows      : Boolean := False;
      Output_Details_Stores_No_Diagnostics_Rows : Boolean := False;
      Build_UI_Stores_No_Diagnostics_Rows     : Boolean := False;
      Render_Parses_No_Build_Output           : Boolean := False;
      Command_Frontdoors_Do_Not_Ingest        : Boolean := False;
      Persistence_Excluded                    : Boolean := False;
      Coherent                                : Boolean := False;
   end record;

   function Build_Diagnostic_Source_Label
     (Request : Editor.External_Producers.Build_Run_Request) return String;

   function Build_Diagnostics_Ingestion_Summary
     (Result : Editor.External_Producers.Diagnostic_Line_Command_Result)
      return String;

   function Assert_Build_Diagnostics_Are_Diagnostics_Owned
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Diagnostics_Review_Uses_Existing_Diagnostics
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Diagnostics_Navigation_Uses_Diagnostics_Routes
     return Boolean;

   function Assert_Build_Summary_Stores_No_Diagnostics_Rows
     (Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary)
      return Boolean;

   function Assert_Build_Output_Details_Stores_No_Diagnostics_Rows
     (Details : Editor.Build_Output_Details.Latest_Build_Output_Details)
      return Boolean;

   function Assert_Build_Diagnostics_Review_Persistence_Excluded
     (State : Editor.State.State_Type) return Boolean;


   function Assert_Build_Diagnostics_Source_Metadata_Reliable
     (Request : Editor.External_Producers.Build_Run_Request) return Boolean;

   function Assert_Build_Diagnostics_Zero_Output_Reliable
     (State  : Editor.State.State_Type;
      Result : Editor.External_Producers.Diagnostic_Line_Command_Result)
      return Boolean;

   function Assert_Build_Diagnostics_Malformed_Output_Reliable
     (State  : Editor.State.State_Type;
      Result : Editor.External_Producers.Diagnostic_Line_Command_Result)
      return Boolean;

   function Assert_Build_Diagnostics_Truncated_Or_Partial_Output_Reliable
     (State  : Editor.State.State_Type;
      Result : Editor.External_Producers.Diagnostic_Line_Command_Result)
      return Boolean;

   function Assert_Build_Diagnostics_Mixed_Source_Review_Reliable
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Diagnostics_Not_Build_Owned
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Diagnostics_Not_Render_Parsed return Boolean;

   function Assert_Build_Diagnostics_Persistence_Excluded
     (State : Editor.State.State_Type) return Boolean renames
      Assert_Build_Diagnostics_Review_Persistence_Excluded;

   function Run_Build_Diagnostics_Review
     (State : Editor.State.State_Type) return Build_Diagnostics_Review_Result;

   function Assert_Public_Build_Diagnostics_Review_Foundation_Coherent
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Public_Build_Diagnostics_Review_Reliability_Coherent
     (State : Editor.State.State_Type) return Boolean;

   --  canonical cleanup assertions. These helpers are declarative
   --  guards over the retained Diagnostics-owned model; they do not normalize,
   --  repair, ingest, navigate, persist, or mutate runtime state.
   function Assert_Build_Diagnostics_No_Build_Local_Table
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Diagnostics_No_Build_Local_Selection
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Diagnostics_No_Build_Specific_Navigation
     return Boolean;

   function Assert_Build_Diagnostics_Ingestion_Only_Diagnostics_API
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Public_Build_Diagnostics_Review_Canonical_Coherent
     (State : Editor.State.State_Type) return Boolean;

   --  final regression-freeze assertions.  These helpers close the
   --  build diagnostics review line by asserting that build-produced
   --  diagnostics remain Diagnostics-owned rows created only through the
   --  retained Diagnostics ingestion seam, reviewed/rendered/navigated only by
   --  Diagnostics, and never copied into Build summary/output/frontdoor/render/
   --  persistence state.
   function Assert_Build_Diagnostics_Final_Owned_By_Diagnostics
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Diagnostics_Final_Ingestion_Only_Row_Creation
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Diagnostics_Final_Source_Metadata_Boundary
     (Request : Editor.External_Producers.Build_Run_Request) return Boolean;

   function Assert_Build_Diagnostics_Final_Review_Boundary
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Diagnostics_Final_Navigation_Boundary return Boolean;

   function Assert_Build_Diagnostics_Final_No_Build_Local_Table
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Diagnostics_Final_No_Build_Local_Selection
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Diagnostics_Final_No_Build_Specific_Navigation
     return Boolean;

   function Assert_Build_Summary_Final_Stores_No_Diagnostics_Rows
     (Summary : Editor.Build_Result_Summary.Latest_Build_Result_Summary)
      return Boolean;

   function Assert_Build_Output_Details_Final_Stores_No_Diagnostics_Rows
     (Details : Editor.Build_Output_Details.Latest_Build_Output_Details)
      return Boolean;

   function Assert_Render_Final_Does_Not_Parse_Build_Diagnostics return Boolean;

   function Assert_Build_Diagnostics_Final_Persistence_Excluded
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Public_Build_Diagnostics_Review_Final_Freeze_Coherent
     (State : Editor.State.State_Type) return Boolean;

   --  practical Diagnostics navigation workflow assertions.  These
   --  predicates keep build diagnostics as ordinary Diagnostics rows while
   --  asserting that review, source labels, navigation, Build UI reveal,
   --  output details, render, command routes, and persistence stay on their
   --  retained owners.
   function Assert_Build_Diagnostics_Reviewable_In_Diagnostics_Surface
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Diagnostics_Navigate_Through_Diagnostics
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Diagnostics_Source_Labels_Practical
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Mixed_Build_And_Non_Build_Diagnostics_Share_Model
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Command_Frontdoors_Carry_No_Diagnostic_Payload
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_UI_Reveal_Diagnostics_Uses_Existing_Command
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result) return Boolean;

   function Assert_Output_Details_Do_Not_Navigate_Diagnostics
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Render_Does_Not_Copy_Build_Diagnostics
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Build_Diagnostics_Navigation_Persistence_Excluded
     (State : Editor.State.State_Type) return Boolean;

   function Assert_Public_Build_Diagnostics_Navigation_Workflow_Coherent
     (State : Editor.State.State_Type) return Boolean;

end Editor.Build_Diagnostics_Review;
