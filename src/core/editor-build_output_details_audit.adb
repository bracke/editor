with Editor.Build_Output_Details;
with Editor.Build_Result_Summary;

package body Editor.Build_Output_Details_Audit is

   function Run_Build_Output_Details_Audit
     (State : Editor.State.State_Type) return Build_Output_Details_Audit_Result
   is
      Result : Build_Output_Details_Audit_Result;
   begin
      Result.Output_Details_Are_Transient :=
        Editor.Build_Output_Details.Assert_Build_Output_Details_Transient
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Are_Bounded :=
        Editor.Build_Output_Details.Assert_Build_Output_Details_Bounded
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Updated_By_Executor :=
        Editor.Build_Output_Details.Assert_Build_Output_Details_Updated_By_Executor
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Have_No_Process_Handle :=
        not Editor.Build_Output_Details.Has_Process_Handle_Field
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Have_No_Cancellation_Token :=
        not Editor.Build_Output_Details.Has_Cancellation_Token_Field
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Have_No_Rerun_Payload :=
        not Editor.Build_Output_Details.Has_Rerun_Request_Payload_Field
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Have_No_Public_Request :=
        not Editor.Build_Output_Details.Has_Public_Build_Request_Field
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Have_No_Consent :=
        not Editor.Build_Output_Details.Has_Consent_Field
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Have_No_Working_Context_Token :=
        not Editor.Build_Output_Details.Has_Working_Context_Token_Field
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Have_No_Diagnostics_Rows :=
        not Editor.Build_Output_Details.Has_Diagnostics_Rows_Field
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Have_No_Build_History :=
        not Editor.Build_Output_Details.Has_Build_History_Field
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Have_No_Output_File_Path :=
        not Editor.Build_Output_Details.Has_Output_File_Path_Field
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Persistence_Excluded :=
        Editor.Build_Output_Details.Assert_Build_Output_Details_Persistence_Excluded
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Replace_Only :=
        Editor.Build_Output_Details.Assert_Output_Details_Replaced_Not_Appended
          (Editor.Build_Output_Details.Empty_Output_Details,
           State.Latest_Build_Output_Details);
      Result.Output_Details_Stale_Fields_Cleared :=
        Editor.Build_Output_Details.Assert_Output_Details_Stale_Fields_Cleared
          (Editor.Build_Output_Details.Empty_Output_Details,
           State.Latest_Build_Output_Details);
      Result.Output_Details_Reliability_Coherent :=
        Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Reliability_Coherent
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Canonical_Shape :=
        Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Shape_Canonical
          (State.Latest_Build_Output_Details);
      Result.Output_Details_No_Output_Canonical :=
        Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_No_Output_Canonical
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Not_Output_Log :=
        Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Not_Output_Log
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Render_Cleanup :=
        Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Render_Cleanup
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Canonical_Coherent :=
        Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Canonical_Coherent
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Final_Ownership_Frozen :=
        Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Ownership_Frozen
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Final_Shape_Frozen :=
        Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Shape_Frozen
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Final_Mapping_Frozen :=
        Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Mapping_Frozen
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Final_No_Output_Frozen :=
        Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_No_Output_Frozen
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Final_No_History :=
        Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_No_History
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Final_Not_Rerun_State :=
        Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Not_Rerun_State
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Final_Not_Process_Control :=
        Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Not_Process_Control
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Final_Not_Output_Log :=
        Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Not_Output_Log
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Final_Not_Diagnostics_Owner :=
        Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Not_Diagnostics_Owner
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Final_Render_Boundary :=
        Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Render_Boundary
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Final_Persistence_Excluded :=
        Editor.Build_Output_Details.Assert_Latest_Build_Output_Details_Final_Persistence_Excluded
          (State.Latest_Build_Output_Details);
      Result.Output_Details_Final_Freeze_Coherent :=
        Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Final_Freeze_Coherent
          (State.Latest_Build_Output_Details);
      Result.Summary_Remains_Compact :=
        Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Not_Output_Log
          (State.Latest_Build_Result)
        and then Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Not_Rerun_State
          (State.Latest_Build_Result)
        and then Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Final_Not_Diagnostics_Owner
          (State.Latest_Build_Result);
      Result.Coherent :=
        Result.Output_Details_Are_Transient
        and then Result.Output_Details_Are_Bounded
        and then Result.Output_Details_Updated_By_Executor
        and then Result.Output_Details_Have_No_Process_Handle
        and then Result.Output_Details_Have_No_Cancellation_Token
        and then Result.Output_Details_Have_No_Rerun_Payload
        and then Result.Output_Details_Have_No_Public_Request
        and then Result.Output_Details_Have_No_Consent
        and then Result.Output_Details_Have_No_Working_Context_Token
        and then Result.Output_Details_Have_No_Diagnostics_Rows
        and then Result.Output_Details_Have_No_Build_History
        and then Result.Output_Details_Have_No_Output_File_Path
        and then Result.Output_Details_Persistence_Excluded
        and then Result.Output_Details_Replace_Only
        and then Result.Output_Details_Stale_Fields_Cleared
        and then Result.Output_Details_Reliability_Coherent
        and then Result.Output_Details_Canonical_Shape
        and then Result.Output_Details_No_Output_Canonical
        and then Result.Output_Details_Not_Output_Log
        and then Result.Output_Details_Render_Cleanup
        and then Result.Output_Details_Canonical_Coherent
        and then Result.Output_Details_Final_Ownership_Frozen
        and then Result.Output_Details_Final_Shape_Frozen
        and then Result.Output_Details_Final_Mapping_Frozen
        and then Result.Output_Details_Final_No_Output_Frozen
        and then Result.Output_Details_Final_No_History
        and then Result.Output_Details_Final_Not_Rerun_State
        and then Result.Output_Details_Final_Not_Process_Control
        and then Result.Output_Details_Final_Not_Output_Log
        and then Result.Output_Details_Final_Not_Diagnostics_Owner
        and then Result.Output_Details_Final_Render_Boundary
        and then Result.Output_Details_Final_Persistence_Excluded
        and then Result.Output_Details_Final_Freeze_Coherent
        and then Result.Summary_Remains_Compact;
      return Result;
   end Run_Build_Output_Details_Audit;

end Editor.Build_Output_Details_Audit;
