with Editor.Build_Candidate_Refresh;
with Editor.Build_Output_Details;
with Editor.Build_Result_Summary;
with Editor.Build_UI;
with Editor.Build_Working_Context;
with Editor.Command_Execution;
with Editor.State;

package Editor.Build_UI_Actions is

   --  Phase 526 UI operability facade.  These helpers model visible Build UI
   --  interactions while preserving the frozen architecture: refresh uses the
   --  canonical refresh path, selection/consent mutate only transient UI
   --  request state, and Run dispatches build.run through Executor.

   procedure Show_Build_UI (S : in out Editor.State.State_Type);
   procedure Hide_Build_UI (S : in out Editor.State.State_Type);
   procedure Focus_Build_UI (S : in out Editor.State.State_Type);
   procedure Toggle_Build_UI (S : in out Editor.State.State_Type);

   function Build_UI_Refresh_Candidates
     (S       : in out Editor.State.State_Type;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record)
      return Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result;

   procedure Build_UI_Select_Candidate
     (S            : in out Editor.State.State_Type;
      Candidate_Id : String);

   procedure Build_UI_Clear_Selected_Candidate
     (S : in out Editor.State.State_Type);

   procedure Build_UI_Acknowledge_Consent
     (S : in out Editor.State.State_Type);

   procedure Build_UI_Clear_Consent
     (S : in out Editor.State.State_Type);

   procedure Build_UI_Select_Next_Candidate
     (S : in out Editor.State.State_Type);

   procedure Build_UI_Select_Previous_Candidate
     (S : in out Editor.State.State_Type);

   procedure Build_UI_Set_Mode_Default
     (S : in out Editor.State.State_Type);

   procedure Build_UI_Set_Mode_Debug
     (S : in out Editor.State.State_Type);

   procedure Build_UI_Set_Mode_Release
     (S : in out Editor.State.State_Type);

   procedure Build_UI_Set_Mode_Validation
     (S : in out Editor.State.State_Type);

   procedure Build_UI_Toggle_Diagnostics_Ingestion
     (S : in out Editor.State.State_Type);

   procedure Build_UI_Cycle_Output_Limit
     (S : in out Editor.State.State_Type);

   procedure Build_UI_Toggle_Verbose_Output
     (S : in out Editor.State.State_Type);

   procedure Build_UI_Toggle_Keep_Going
     (S : in out Editor.State.State_Type);

   function Build_UI_Run_Build
     (S : in out Editor.State.State_Type)
      return Editor.Command_Execution.Command_Execution_Result;

   function Build_UI_Reveal_Diagnostics
     (S : in out Editor.State.State_Type)
      return Editor.Command_Execution.Command_Execution_Result;

   function Build_UI_Operability_Snapshot
     (S : Editor.State.State_Type) return Editor.Build_UI.Build_UI_Render_Snapshot;

   function Assert_Build_UI_Operable
     (S : Editor.State.State_Type) return Boolean;

   function Assert_Build_UI_Run_Routes_Through_Executor
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result) return Boolean;

   function Assert_Build_UI_Does_Not_Persist_Transient_State
     (S : Editor.State.State_Type) return Boolean;

   function Assert_Public_Build_UI_Operability_Coherent
     (S : Editor.State.State_Type) return Boolean;

   function Assert_Build_UI_Reveal_Diagnostics_Uses_Existing_Command
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result) return Boolean;

   function Assert_Public_Build_Result_Output_UI_Coherent
     (S : Editor.State.State_Type) return Boolean;

end Editor.Build_UI_Actions;
