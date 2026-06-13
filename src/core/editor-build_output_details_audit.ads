with Editor.State;

package Editor.Build_Output_Details_Audit is

   type Build_Output_Details_Audit_Result is record
      Output_Details_Are_Transient : Boolean := False;
      Output_Details_Are_Bounded : Boolean := False;
      Output_Details_Updated_By_Executor : Boolean := False;
      Output_Details_Have_No_Process_Handle : Boolean := False;
      Output_Details_Have_No_Cancellation_Token : Boolean := False;
      Output_Details_Have_No_Rerun_Payload : Boolean := False;
      Output_Details_Have_No_Public_Request : Boolean := False;
      Output_Details_Have_No_Consent : Boolean := False;
      Output_Details_Have_No_Working_Context_Token : Boolean := False;
      Output_Details_Have_No_Diagnostics_Rows : Boolean := False;
      Output_Details_Have_No_Build_History : Boolean := False;
      Output_Details_Have_No_Output_File_Path : Boolean := False;
      Output_Details_Persistence_Excluded : Boolean := False;
      Output_Details_Replace_Only : Boolean := False;
      Output_Details_Stale_Fields_Cleared : Boolean := False;
      Output_Details_Reliability_Coherent : Boolean := False;
      Output_Details_Canonical_Shape : Boolean := False;
      Output_Details_No_Output_Canonical : Boolean := False;
      Output_Details_Not_Output_Log : Boolean := False;
      Output_Details_Render_Cleanup : Boolean := False;
      Output_Details_Canonical_Coherent : Boolean := False;
      Output_Details_Final_Ownership_Frozen : Boolean := False;
      Output_Details_Final_Shape_Frozen : Boolean := False;
      Output_Details_Final_Mapping_Frozen : Boolean := False;
      Output_Details_Final_No_Output_Frozen : Boolean := False;
      Output_Details_Final_No_History : Boolean := False;
      Output_Details_Final_Not_Rerun_State : Boolean := False;
      Output_Details_Final_Not_Process_Control : Boolean := False;
      Output_Details_Final_Not_Output_Log : Boolean := False;
      Output_Details_Final_Not_Diagnostics_Owner : Boolean := False;
      Output_Details_Final_Render_Boundary : Boolean := False;
      Output_Details_Final_Persistence_Excluded : Boolean := False;
      Output_Details_Final_Freeze_Coherent : Boolean := False;
      Summary_Remains_Compact : Boolean := False;
      Coherent : Boolean := False;
   end record;

   function Run_Build_Output_Details_Audit
     (State : Editor.State.State_Type) return Build_Output_Details_Audit_Result;

end Editor.Build_Output_Details_Audit;
