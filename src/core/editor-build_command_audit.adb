with Editor.Commands.Availability_Metadata;
with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Command;
with Editor.Build_UI;
with Editor.Build_Working_Context;
with Editor.Build_Result_Summary;
with Editor.Build_Output_Details;
with Editor.Commands;
with Editor.Commands.Build_Terminal_Ids;
with Editor.Commands.Name_Metadata;
with Editor.External_Producers;
with Editor.External_Producers.Audits;
with Editor.External_Producers.Public_Build;
with Editor.State;


package body Editor.Build_Command_Audit is

   use type Editor.Build_Command.Build_Run_Readiness_Status;
   use type Editor.Commands.Descriptors.Command_Visibility;
   use type Editor.Commands.Descriptors.Command_Category;
   use type Editor.Build_Working_Context.Build_Working_Context_Validation_Status;

   function Build_Run_Availability_Is_Side_Effect_Free
     (State : Editor.State.State_Type) return Boolean
   is
      Copy              : Editor.State.State_Type := State;
      Before_Availability : constant Editor.Commands.Availability_Metadata.Command_Availability :=
        Editor.Build_Command.Build_Run_Availability (State);
      Before_Identity   : constant String :=
        Editor.Build_UI.Current_Request_Identity (State.Build_UI);
      After_Availability : Editor.Commands.Availability_Metadata.Command_Availability;
   begin
      After_Availability := Editor.Build_Command.Build_Run_Availability (Copy);
      return Editor.Commands.Availability_Metadata.Is_Available (Before_Availability) =
          Editor.Commands.Availability_Metadata.Is_Available (After_Availability)
        and then Editor.Commands.Availability_Metadata.Unavailable_Reason (Before_Availability) =
          Editor.Commands.Availability_Metadata.Unavailable_Reason (After_Availability)
        and then Editor.Build_UI.Current_Request_Identity (Copy.Build_UI) =
          Before_Identity;
   end Build_Run_Availability_Is_Side_Effect_Free;

   function Run_Public_Build_Command_UX_Foundation_Audit
     (State : Editor.State.State_Type)
      return Public_Build_Command_UX_Foundation_Audit
   is
      Result : Public_Build_Command_UX_Foundation_Audit;
      Readiness : constant
        Editor.External_Producers.Public_Build.Readiness_Audit_Result :=
          Editor.External_Producers.Public_Build
            .Run_Public_Build_Command_Readiness_Audit (State);
   begin
      Result.Build_Run_Descriptor_Stable :=
        Editor.Commands.Name_Metadata.Stable_Command_Name (Editor.Commands.Command_Build_Run) =
        "build.run"
        and then Editor.Commands.Descriptors.Descriptor (Editor.Commands.Command_Build_Run).Visibility =
          Editor.Commands.Descriptors.Palette_Command
        and then not Editor.Commands.Descriptors.Descriptor (Editor.Commands.Command_Build_Run).Bindable;
      Result.Build_Run_Routes_Through_Executor := Readiness.Routes_Through_Executor;
      Result.Build_Run_Requires_Explicit_Consent :=
        Readiness.Public_Consent_UX_Publicly_Ready
        and then Readiness.Public_Consent_Publicly_Exposable
        and then Readiness.Public_Input_Does_Not_Enable_Public_Execution;
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
        Readiness.Public_Command_Is_Invokable
        and then Readiness.Public_Input_Does_Not_Enable_Public_Execution;
      Result.Keybindings_Cannot_Supply_Working_Context :=
        not Readiness.Has_Default_Public_Build_Keybinding;
      Result.Build_Run_Public_Command_Descriptor :=
        Result.Build_Run_Descriptor_Stable;
      declare
         Availability : constant Editor.Commands.Availability_Metadata.Command_Availability :=
           Editor.Build_Command.Build_Run_Availability (State);
      begin
         Result.Build_Run_Availability_Readiness_Derived :=
           (not Editor.Commands.Availability_Metadata.Is_Available (Availability))
           and then Editor.Commands.Availability_Metadata.Unavailable_Reason (Availability) =
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
        Result.Command_Palette_Cannot_Supply_Working_Context;
      Result.Build_Run_Keybinding_Boundary :=
        Result.Keybindings_Cannot_Supply_Working_Context;
      Result.Build_Run_Persistence_Excluded :=
        Result.Persistence_Excludes_Build_UI_State;
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
        Build_Run_Availability_Is_Side_Effect_Free (State);
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

   function Assert_Build_Run_Descriptor_Stable return Boolean
   is
      State : Editor.State.State_Type;
   begin
      Editor.State.Initialize (State);
      return Run_Public_Build_Command_UX_Foundation_Audit (State).Build_Run_Descriptor_Stable;
   end Assert_Build_Run_Descriptor_Stable;

   function Assert_Build_Run_Routes_Through_Executor
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Run_Public_Build_Command_UX_Foundation_Audit (State).Build_Run_Routes_Through_Executor;
   end Assert_Build_Run_Routes_Through_Executor;

   function Assert_Build_Run_Availability_Side_Effect_Free
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Build_Run_Availability_Is_Side_Effect_Free (State);
   end Assert_Build_Run_Availability_Side_Effect_Free;

   function Assert_Build_Cancel_Command_Descriptor_Stable return Boolean
   is
      D : constant Editor.Commands.Descriptors.Command_Descriptor :=
        Editor.Commands.Descriptors.Descriptor (Editor.Commands.Command_Build_Cancel);
      Name : constant String := To_String (D.Name);
   begin
      return Editor.Commands.Name_Metadata.Stable_Command_Name
          (Editor.Commands.Command_Build_Cancel) = "build.cancel"
        and then Editor.Commands.Build_Terminal_Ids.Is_Public_Build_Command
          (Editor.Commands.Command_Build_Cancel)
        and then D.Visibility = Editor.Commands.Descriptors.Palette_Command
        and then D.Category = Editor.Commands.Descriptors.Project_Category
        and then not D.Bindable
        and then Name = "Cancel Build";
   end Assert_Build_Cancel_Command_Descriptor_Stable;

   function Assert_Build_Cancel_Requires_Active_Job
     (State : Editor.State.State_Type) return Boolean
   is
      Copy : Editor.State.State_Type := State;
      No_Job_Available : constant Boolean :=
        not Editor.Commands.Availability_Metadata.Is_Available (Editor.Build_Command.Build_Cancel_Availability (Copy));
   begin
      Editor.Build_Command.Begin_Public_Build_Job (Copy, "audit");
      return No_Job_Available
        and then Editor.Commands.Availability_Metadata.Is_Available (Editor.Build_Command.Build_Cancel_Availability (Copy));
   end Assert_Build_Cancel_Requires_Active_Job;

   function Assert_Build_Run_Command_Palette_Boundary
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Run_Public_Build_Command_UX_Foundation_Audit (State).Build_Run_Command_Palette_Boundary;
   end Assert_Build_Run_Command_Palette_Boundary;

   function Assert_Build_Run_Keybinding_Boundary return Boolean
   is
      State : Editor.State.State_Type;
   begin
      Editor.State.Initialize (State);
      return Run_Public_Build_Command_UX_Foundation_Audit (State).Build_Run_Keybinding_Boundary;
   end Assert_Build_Run_Keybinding_Boundary;

   function Assert_Build_Run_Persistence_Excluded
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Run_Public_Build_Command_UX_Foundation_Audit (State).Build_Run_Persistence_Excluded;
   end Assert_Build_Run_Persistence_Excluded;

   function Assert_Public_Build_Command_Registration_Coherent
     (State : Editor.State.State_Type) return Boolean
   is
   begin
      return Run_Public_Build_Command_UX_Foundation_Audit (State).Coherent;
   end Assert_Public_Build_Command_Registration_Coherent;

end Editor.Build_Command_Audit;
