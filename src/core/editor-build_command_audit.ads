with Editor.State;

package Editor.Build_Command_Audit is

   type Public_Build_Command_UX_Foundation_Audit is record
      Build_Run_Descriptor_Stable : Boolean := False;
      Build_Run_Routes_Through_Executor : Boolean := False;
      Build_Run_Requires_Explicit_Consent : Boolean := False;
      Build_Run_Does_Not_Execute_When_Backend_Disabled : Boolean := False;
      Build_UI_State_Is_Transient : Boolean := False;
      Build_UI_Has_No_Raw_Shell_Command_Field : Boolean := False;
      Build_UI_Has_No_Remembered_Consent_Field : Boolean := False;
      Persistence_Excludes_Build_UI_State : Boolean := False;
      Diagnostics_Ownership_Unchanged : Boolean := False;
      Working_Context_Is_Structured : Boolean := False;
      Working_Context_Is_Transient : Boolean := False;
      Working_Context_Requires_Valid_Source : Boolean := False;
      Working_Context_Rejects_Raw_Text : Boolean := False;
      Working_Context_Rejects_Shell_Derived : Boolean := False;
      Working_Context_Rejects_Implicit_Derived : Boolean := False;
      Working_Context_Consent_Bound : Boolean := False;
      Command_Palette_Cannot_Supply_Working_Context : Boolean := False;
      Keybindings_Cannot_Supply_Working_Context : Boolean := False;
      Build_Run_Public_Command_Descriptor : Boolean := False;
      Build_Run_Availability_Readiness_Derived : Boolean := False;
      Build_Run_Invocation_Revalidated : Boolean := False;
      Build_Run_Backend_Disabled_Guard : Boolean := False;
      Build_Run_Command_Palette_Boundary : Boolean := False;
      Build_Run_Keybinding_Boundary : Boolean := False;
      Build_Run_Persistence_Excluded : Boolean := False;
      Latest_Result_Summary_Is_Transient : Boolean := False;
      Latest_Result_Summary_Has_No_Process_Handle : Boolean := False;
      Latest_Result_Summary_Has_No_Cancellation_Token : Boolean := False;
      Latest_Result_Summary_Has_No_Rerun_Payload : Boolean := False;
      Latest_Result_Summary_Has_No_Diagnostics_Rows : Boolean := False;
      Latest_Result_Summary_Has_No_Unbounded_Output : Boolean := False;
      Latest_Result_Summary_Has_No_Build_History : Boolean := False;
      Latest_Result_Summary_Owned_By_Executor : Boolean := False;
      Latest_Result_Summary_Shape_Canonical : Boolean := False;
      Latest_Result_Summary_Replace_Only : Boolean := False;
      Latest_Result_Summary_Not_Rerun_State : Boolean := False;
      Latest_Result_Summary_Not_Diagnostics_Owner : Boolean := False;
      Latest_Result_Summary_Not_Output_Log : Boolean := False;
      Latest_Result_Summary_Render_Clean : Boolean := False;
      Latest_Result_Summary_Persistence_Excluded : Boolean := False;
      Latest_Result_Surface_Canonical_Coherent : Boolean := False;
      Latest_Result_Surface_Final_Freeze_Coherent : Boolean := False;
      Latest_Output_Details_Is_Transient : Boolean := False;
      Latest_Output_Details_Bounded : Boolean := False;
      Latest_Output_Details_Has_No_Process_Handle : Boolean := False;
      Latest_Output_Details_Has_No_Cancellation_Token : Boolean := False;
      Latest_Output_Details_Has_No_Rerun_Payload : Boolean := False;
      Latest_Output_Details_Has_No_Diagnostics_Rows : Boolean := False;
      Latest_Output_Details_Has_No_Build_History : Boolean := False;
      Latest_Output_Details_Persistence_Excluded : Boolean := False;
      Latest_Output_Details_Foundation_Coherent : Boolean := False;
      Side_Effect_Free : Boolean := False;
      Coherent : Boolean := False;
   end record;

   function Run_Public_Build_Command_UX_Foundation_Audit
     (State : Editor.State.State_Type)
      return Public_Build_Command_UX_Foundation_Audit;

end Editor.Build_Command_Audit;
