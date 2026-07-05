with Editor.Build_Command;
with Editor.Build_UI;
with Editor.Build_Working_Context;
with Editor.Build_Result_Summary;
with Editor.Build_Output_Details;
with Editor.Commands;
with Editor.External_Producers;

package body Editor.Build_Command_Audit is

   use type Editor.Build_Command.Build_Run_Readiness_Status;
   use type Editor.Commands.Command_Visibility;
   use type Editor.Build_Working_Context.Build_Working_Context_Validation_Status;

   function Run_Public_Build_Command_UX_Foundation_Audit
     (State : Editor.State.State_Type)
      return Public_Build_Command_UX_Foundation_Audit
   is
      Result : Public_Build_Command_UX_Foundation_Audit;
      Readiness : constant Editor.External_Producers.Public_Build_Command_Readiness_Audit_Result :=
        Editor.External_Producers.Run_Public_Build_Command_Readiness_Audit (State);
   begin
      Result.Build_Run_Descriptor_Stable :=
        Editor.Commands.Stable_Command_Name (Editor.Commands.Command_Build_Run) =
        "build.run"
        and then Editor.Commands.Descriptor (Editor.Commands.Command_Build_Run).Visibility =
          Editor.Commands.Palette_Command
        and then not Editor.Commands.Descriptor (Editor.Commands.Command_Build_Run).Bindable;
      Result.Build_Run_Routes_Through_Executor := Readiness.Routes_Through_Executor;
      Result.Build_Run_Requires_Explicit_Consent :=
        Readiness.Public_Consent_UX_Publicly_Ready
        and then not Readiness.Public_Consent_Publicly_Exposable;
      Result.Build_Run_Does_Not_Execute_When_Backend_Disabled :=
        Readiness.Public_Input_Does_Not_Enable_Public_Execution;
      Result.Build_UI_State_Is_Transient :=
        Editor.Build_UI.Assert_Build_UI_State_Is_Transient (State.Build_UI);
      Result.Build_UI_Has_No_Raw_Shell_Command_Field :=
        not Editor.Build_UI.Has_Raw_Shell_Command_Field (State.Build_UI);
      Result.Build_UI_Has_No_Remembered_Consent_Field :=
        not Editor.Build_UI.Has_Remembered_Consent_Field (State.Build_UI);
      Result.Persistence_Excludes_Build_UI_State :=
        Readiness.Public_Input_Does_Not_Create_Command_Descriptors;
      Result.Diagnostics_Ownership_Unchanged :=
        Readiness.Routes_Diagnostics_Through_Pipeline;
      Result.Working_Context_Is_Structured :=
        Editor.Build_Working_Context.Assert_Build_Working_Context_Is_Structured
          (State.Build_UI.Selected_Working_Context);
      Result.Working_Context_Is_Transient :=
        Editor.Build_Working_Context.Assert_Build_Working_Context_Is_Transient
          (State.Build_UI.Selected_Working_Context)
        and then Editor.Build_Working_Context.Assert_Build_Working_Context_Persistence_Excluded
          (State.Build_UI.Selected_Working_Context);
      Result.Working_Context_Requires_Valid_Source :=
        State.Build_UI.Selected_Working_Context.Source_Kind in
          Editor.Build_Working_Context.Working_Context_Source_None |
          Editor.Build_Working_Context.Working_Context_Source_Canonical_Project |
          Editor.Build_Working_Context.Working_Context_Source_Canonical_Workspace |
          Editor.Build_Working_Context.Working_Context_Source_Test_Fixture |
          Editor.Build_Working_Context.Working_Context_Source_Unavailable;
      Result.Working_Context_Rejects_Raw_Text :=
        Editor.Build_Working_Context.Validate_Build_Working_Context
          (Editor.Build_Working_Context.Unsafe_Context
             (Editor.Build_Working_Context.Build_Working_Context_Unavailable,
              "/tmp/build",
              Editor.Build_Working_Context.Working_Context_Source_Raw_Text,
              "/tmp/build")) =
        Editor.Build_Working_Context.Build_Working_Context_Rejected_Raw_Text;
      Result.Working_Context_Rejects_Shell_Derived :=
        Editor.Build_Working_Context.Validate_Build_Working_Context
          (Editor.Build_Working_Context.Unsafe_Context
             (Editor.Build_Working_Context.Build_Working_Context_Unavailable,
              "cd /tmp && alr build",
              Editor.Build_Working_Context.Working_Context_Source_Shell_Derived,
              "/tmp")) =
        Editor.Build_Working_Context.Build_Working_Context_Rejected_Shell_Derived;
      Result.Working_Context_Rejects_Implicit_Derived :=
        Editor.Build_Working_Context.Validate_Build_Working_Context
          (Editor.Build_Working_Context.Unsafe_Context
             (Editor.Build_Working_Context.Build_Working_Context_Current_Project_Root,
              "alire.toml",
              Editor.Build_Working_Context.Working_Context_Source_Implicit_Derived,
              "alire.toml")) =
        Editor.Build_Working_Context.Build_Working_Context_Rejected_Implicit_Derived;
      Result.Working_Context_Consent_Bound :=
        Editor.Build_UI.Current_Request_Identity (State.Build_UI)'Length > 0;
      Result.Command_Palette_Cannot_Supply_Working_Context :=
        not Readiness.Public_Command_Is_Invokable;
      Result.Keybindings_Cannot_Supply_Working_Context :=
        not Readiness.Has_Default_Public_Build_Keybinding;
      Result.Build_Run_Public_Command_Descriptor :=
        Editor.Build_Command.Assert_Build_Run_Descriptor_Stable;
      declare
         Availability : constant Editor.Commands.Command_Availability :=
           Editor.Build_Command.Build_Run_Availability (State);
      begin
         Result.Build_Run_Availability_Readiness_Derived :=
           (not Editor.Commands.Is_Available (Availability))
           and then Editor.Commands.Unavailable_Reason (Availability) =
             Editor.Build_Command.Build_Run_Unavailable_Reason
               (Editor.Build_Command.Build_Run_Readiness (State));
      end;
      Result.Build_Run_Invocation_Revalidated :=
        Editor.Build_Command.Validate_Build_Run_Invocation (State) =
        Editor.Build_Command.Build_Run_Readiness (State);
      Result.Build_Run_Backend_Disabled_Guard :=
        Editor.Build_Command.Validate_Build_Run_Invocation (State) /=
        Editor.Build_Command.Build_Run_Readiness_Ready;
      Result.Build_Run_Command_Palette_Boundary :=
        Editor.Build_Command.Assert_Build_Run_Command_Palette_Boundary (State);
      Result.Build_Run_Keybinding_Boundary :=
        Editor.Build_Command.Assert_Build_Run_Keybinding_Boundary;
      Result.Build_Run_Persistence_Excluded :=
        Editor.Build_Command.Assert_Build_Run_Persistence_Excluded (State);
      Result.Latest_Result_Summary_Is_Transient :=
        Editor.Build_Result_Summary.Assert_Summary_Is_Transient_Projection
          (State.Latest_Build_Result);
      Result.Latest_Result_Summary_Has_No_Process_Handle :=
        not Editor.Build_Result_Summary.Has_Process_Handle_Field
          (State.Latest_Build_Result);
      Result.Latest_Result_Summary_Has_No_Cancellation_Token :=
        not Editor.Build_Result_Summary.Has_Cancellation_Token_Field
          (State.Latest_Build_Result);
      Result.Latest_Result_Summary_Has_No_Rerun_Payload :=
        not Editor.Build_Result_Summary.Has_Rerun_Request_Payload_Field
          (State.Latest_Build_Result);
      Result.Latest_Result_Summary_Has_No_Diagnostics_Rows :=
        not Editor.Build_Result_Summary.Has_Diagnostics_Rows_Field
          (State.Latest_Build_Result);
      Result.Latest_Result_Summary_Has_No_Unbounded_Output :=
        not Editor.Build_Result_Summary.Has_Unbounded_Output_Field
          (State.Latest_Build_Result);
      Result.Latest_Result_Summary_Has_No_Build_History :=
        not Editor.Build_Result_Summary.Has_Build_History_Field
          (State.Latest_Build_Result);
      Result.Latest_Result_Summary_Owned_By_Executor :=
        Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Owned_By_Executor
          (State.Latest_Build_Result);
      Result.Latest_Result_Summary_Shape_Canonical :=
        Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Shape_Canonical
          (State.Latest_Build_Result);
      Result.Latest_Result_Summary_Replace_Only :=
        Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Replace_Only
          (State.Latest_Build_Result, State.Latest_Build_Result);
      Result.Latest_Result_Summary_Not_Rerun_State :=
        Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Not_Rerun_State
          (State.Latest_Build_Result);
      Result.Latest_Result_Summary_Not_Diagnostics_Owner :=
        Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Not_Diagnostics_Owner
          (State.Latest_Build_Result);
      Result.Latest_Result_Summary_Not_Output_Log :=
        Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Not_Output_Log
          (State.Latest_Build_Result);
      Result.Latest_Result_Summary_Render_Clean :=
        Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Render_Cleanup
          (State.Latest_Build_Result);
      Result.Latest_Result_Summary_Persistence_Excluded :=
        Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Persistence_Excluded
          (State.Latest_Build_Result);
      Result.Latest_Result_Surface_Canonical_Coherent :=
        Editor.Build_Result_Summary.Assert_Public_Build_Result_Surface_Canonical_Coherent
          (State.Latest_Build_Result);
      Result.Latest_Result_Surface_Final_Freeze_Coherent :=
        Editor.Build_Result_Summary.Assert_Public_Build_Result_Surface_Final_Freeze_Coherent
          (State.Latest_Build_Result);
      Result.Latest_Output_Details_Is_Transient :=
        Editor.Build_Output_Details.Assert_Build_Output_Details_Transient
          (State.Latest_Build_Output_Details);
      Result.Latest_Output_Details_Bounded :=
        Editor.Build_Output_Details.Assert_Build_Output_Details_Bounded
          (State.Latest_Build_Output_Details);
      Result.Latest_Output_Details_Has_No_Process_Handle :=
        not Editor.Build_Output_Details.Has_Process_Handle_Field
          (State.Latest_Build_Output_Details);
      Result.Latest_Output_Details_Has_No_Cancellation_Token :=
        not Editor.Build_Output_Details.Has_Cancellation_Token_Field
          (State.Latest_Build_Output_Details);
      Result.Latest_Output_Details_Has_No_Rerun_Payload :=
        not Editor.Build_Output_Details.Has_Rerun_Request_Payload_Field
          (State.Latest_Build_Output_Details);
      Result.Latest_Output_Details_Has_No_Diagnostics_Rows :=
        not Editor.Build_Output_Details.Has_Diagnostics_Rows_Field
          (State.Latest_Build_Output_Details);
      Result.Latest_Output_Details_Has_No_Build_History :=
        not Editor.Build_Output_Details.Has_Build_History_Field
          (State.Latest_Build_Output_Details);
      Result.Latest_Output_Details_Persistence_Excluded :=
        Editor.Build_Output_Details.Assert_Build_Output_Details_Persistence_Excluded
          (State.Latest_Build_Output_Details);
      Result.Latest_Output_Details_Foundation_Coherent :=
        Editor.Build_Output_Details.Assert_Public_Build_Output_Details_Foundation_Coherent
          (State.Latest_Build_Output_Details);
      Result.Side_Effect_Free :=
        Editor.Build_Command.Assert_Build_Run_Availability_Side_Effect_Free
          (State);
      Result.Coherent :=
        Result.Build_Run_Descriptor_Stable
        and then Result.Build_Run_Routes_Through_Executor
        and then Result.Build_Run_Requires_Explicit_Consent
        and then Result.Build_Run_Does_Not_Execute_When_Backend_Disabled
        and then Result.Build_UI_State_Is_Transient
        and then Result.Build_UI_Has_No_Raw_Shell_Command_Field
        and then Result.Build_UI_Has_No_Remembered_Consent_Field
        and then Result.Persistence_Excludes_Build_UI_State
        and then Result.Diagnostics_Ownership_Unchanged
        and then Result.Working_Context_Is_Structured
        and then Result.Working_Context_Is_Transient
        and then Result.Working_Context_Requires_Valid_Source
        and then Result.Working_Context_Rejects_Raw_Text
        and then Result.Working_Context_Rejects_Shell_Derived
        and then Result.Working_Context_Rejects_Implicit_Derived
        and then Result.Working_Context_Consent_Bound
        and then Result.Command_Palette_Cannot_Supply_Working_Context
        and then Result.Keybindings_Cannot_Supply_Working_Context
        and then Result.Build_Run_Public_Command_Descriptor
        and then Result.Build_Run_Availability_Readiness_Derived
        and then Result.Build_Run_Invocation_Revalidated
        and then Result.Build_Run_Backend_Disabled_Guard
        and then Result.Build_Run_Command_Palette_Boundary
        and then Result.Build_Run_Keybinding_Boundary
        and then Result.Build_Run_Persistence_Excluded
        and then Result.Latest_Result_Summary_Is_Transient
        and then Result.Latest_Result_Summary_Has_No_Process_Handle
        and then Result.Latest_Result_Summary_Has_No_Cancellation_Token
        and then Result.Latest_Result_Summary_Has_No_Rerun_Payload
        and then Result.Latest_Result_Summary_Has_No_Diagnostics_Rows
        and then Result.Latest_Result_Summary_Has_No_Unbounded_Output
        and then Result.Latest_Result_Summary_Has_No_Build_History
        and then Result.Latest_Result_Summary_Owned_By_Executor
        and then Result.Latest_Result_Summary_Shape_Canonical
        and then Result.Latest_Result_Summary_Replace_Only
        and then Result.Latest_Result_Summary_Not_Rerun_State
        and then Result.Latest_Result_Summary_Not_Diagnostics_Owner
        and then Result.Latest_Result_Summary_Not_Output_Log
        and then Result.Latest_Result_Summary_Render_Clean
        and then Result.Latest_Result_Summary_Persistence_Excluded
        and then Result.Latest_Result_Surface_Canonical_Coherent
        and then Result.Latest_Result_Surface_Final_Freeze_Coherent
        and then Result.Latest_Output_Details_Is_Transient
        and then Result.Latest_Output_Details_Bounded
        and then Result.Latest_Output_Details_Has_No_Process_Handle
        and then Result.Latest_Output_Details_Has_No_Cancellation_Token
        and then Result.Latest_Output_Details_Has_No_Rerun_Payload
        and then Result.Latest_Output_Details_Has_No_Diagnostics_Rows
        and then Result.Latest_Output_Details_Has_No_Build_History
        and then Result.Latest_Output_Details_Persistence_Excluded
        and then Result.Latest_Output_Details_Foundation_Coherent
        and then Result.Side_Effect_Free;
      return Result;
   end Run_Public_Build_Command_UX_Foundation_Audit;

end Editor.Build_Command_Audit;
