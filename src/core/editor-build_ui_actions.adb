with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Candidate_Refresh;
with Editor.Build_Command;
with Editor.Build_Output_Details;
with Editor.Build_Result_Summary;
with Editor.Build_UI;
with Editor.Build_Working_Context;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Focus_Management;
with Editor.State;

package body Editor.Build_UI_Actions is

   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Commands.Command_Id;

   procedure Show_Build_UI (S : in out Editor.State.State_Type) is
   begin
      Editor.Build_UI.Show (S.Build_UI);
   end Show_Build_UI;

   procedure Hide_Build_UI (S : in out Editor.State.State_Type) is
      Owner_Before : constant Editor.Focus_Management.Focus_Owner :=
        Editor.Focus_Management.Effective_Focus_Owner (S);
   begin
      Editor.Build_UI.Hide (S.Build_UI);
      S.Latest_Build_Result_Focused := False;
      S.Latest_Build_Output_Details.Build_Output_Details_Focused := False;

      if Owner_Before in Editor.Focus_Management.Focus_Build_UI
         | Editor.Focus_Management.Focus_Build_Result_Summary
         | Editor.Focus_Management.Focus_Build_Output_Details
      then
         Editor.Focus_Management.Restore_Focus_To_Editor (S);
      end if;
   end Hide_Build_UI;

   procedure Focus_Build_UI (S : in out Editor.State.State_Type) is
   begin
      Editor.Focus_Management.Set_Focus_Owner
        (S, Editor.Focus_Management.Focus_Build_UI);
   end Focus_Build_UI;

   procedure Toggle_Build_UI (S : in out Editor.State.State_Type) is
   begin
      if S.Build_UI.Build_UI_Visible then
         Hide_Build_UI (S);
      else
         Show_Build_UI (S);
      end if;
   end Toggle_Build_UI;

   function Build_UI_Refresh_Candidates
     (S       : in out Editor.State.State_Type;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record)
      return Editor.Build_Candidate_Refresh.Build_Candidate_Refresh_Result
   is
   begin
      return Editor.Build_Candidate_Refresh.Refresh_Build_Candidates
        (S.Build_UI, Context);
   end Build_UI_Refresh_Candidates;

   procedure Build_UI_Select_Candidate
     (S            : in out Editor.State.State_Type;
      Candidate_Id : String)
   is
   begin
      Editor.Build_UI.Select_Build_Candidate (S.Build_UI, Candidate_Id);
   end Build_UI_Select_Candidate;

   procedure Build_UI_Clear_Selected_Candidate
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Build_UI.Clear_Selected_Build_Candidate (S.Build_UI);
   end Build_UI_Clear_Selected_Candidate;

   procedure Build_UI_Acknowledge_Consent
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Build_UI.Acknowledge_Consent (S.Build_UI);
   end Build_UI_Acknowledge_Consent;

   procedure Build_UI_Clear_Consent
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Build_UI.Clear_Consent (S.Build_UI);
   end Build_UI_Clear_Consent;


   procedure Build_UI_Select_Next_Candidate
     (S : in out Editor.State.State_Type)
   is
      Count : constant Natural := Natural (S.Build_UI.Build_Candidates.Length);
      Selected : constant String := To_String (S.Build_UI.Selected_Build_Candidate_Id);
      Next_Index : Natural := 0;
      Found_Next : Boolean := False;
   begin
      if Count = 0 then
         return;
      end if;
      for I in S.Build_UI.Build_Candidates.First_Index ..
        S.Build_UI.Build_Candidates.Last_Index
      loop
         if To_String (S.Build_UI.Build_Candidates.Element (I).Candidate_Id) = Selected then
            if I = S.Build_UI.Build_Candidates.Last_Index then
               Next_Index := S.Build_UI.Build_Candidates.First_Index;
            else
               Next_Index := I + 1;
            end if;
            Found_Next := True;
         end if;
      end loop;
      if not Found_Next then
         Next_Index := S.Build_UI.Build_Candidates.First_Index;
      end if;
      Editor.Build_UI.Select_Build_Candidate
        (S.Build_UI,
         To_String (S.Build_UI.Build_Candidates.Element (Next_Index).Candidate_Id));
   end Build_UI_Select_Next_Candidate;

   procedure Build_UI_Select_Previous_Candidate
     (S : in out Editor.State.State_Type)
   is
      Count : constant Natural := Natural (S.Build_UI.Build_Candidates.Length);
      Selected : constant String := To_String (S.Build_UI.Selected_Build_Candidate_Id);
      Previous_Index : Natural := 0;
      Found_Previous : Boolean := False;
   begin
      if Count = 0 then
         return;
      end if;
      for I in S.Build_UI.Build_Candidates.First_Index ..
        S.Build_UI.Build_Candidates.Last_Index
      loop
         if To_String (S.Build_UI.Build_Candidates.Element (I).Candidate_Id) = Selected then
            if I = S.Build_UI.Build_Candidates.First_Index then
               Previous_Index := S.Build_UI.Build_Candidates.Last_Index;
            else
               Previous_Index := I - 1;
            end if;
            Found_Previous := True;
         end if;
      end loop;
      if not Found_Previous then
         Previous_Index := S.Build_UI.Build_Candidates.Last_Index;
      end if;
      Editor.Build_UI.Select_Build_Candidate
        (S.Build_UI,
         To_String (S.Build_UI.Build_Candidates.Element (Previous_Index).Candidate_Id));
   end Build_UI_Select_Previous_Candidate;

   procedure Build_UI_Set_Mode_Default
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Build_UI.Set_Build_Mode
        (S.Build_UI, Editor.Build_UI.Build_UI_Build_Mode_Default);
   end Build_UI_Set_Mode_Default;

   procedure Build_UI_Set_Mode_Debug
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Build_UI.Set_Build_Mode
        (S.Build_UI, Editor.Build_UI.Build_UI_Build_Mode_Debug);
   end Build_UI_Set_Mode_Debug;

   procedure Build_UI_Set_Mode_Release
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Build_UI.Set_Build_Mode
        (S.Build_UI, Editor.Build_UI.Build_UI_Build_Mode_Release);
   end Build_UI_Set_Mode_Release;

   procedure Build_UI_Set_Mode_Validation
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Build_UI.Set_Build_Mode
        (S.Build_UI, Editor.Build_UI.Build_UI_Build_Mode_Validation);
   end Build_UI_Set_Mode_Validation;

   procedure Build_UI_Toggle_Diagnostics_Ingestion
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Build_UI.Toggle_Diagnostics_Ingestion (S.Build_UI);
   end Build_UI_Toggle_Diagnostics_Ingestion;

   procedure Build_UI_Cycle_Output_Limit
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Build_UI.Cycle_Output_Capture_Limit (S.Build_UI);
   end Build_UI_Cycle_Output_Limit;

   procedure Build_UI_Toggle_Verbose_Output
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Build_UI.Toggle_Verbose_Output (S.Build_UI);
   end Build_UI_Toggle_Verbose_Output;

   procedure Build_UI_Toggle_Keep_Going
     (S : in out Editor.State.State_Type)
   is
   begin
      Editor.Build_UI.Toggle_Keep_Going (S.Build_UI);
   end Build_UI_Toggle_Keep_Going;

   function Build_UI_Run_Build
     (S : in out Editor.State.State_Type)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      return Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Build_Run);
   end Build_UI_Run_Build;

   function Build_UI_Reveal_Diagnostics
     (S : in out Editor.State.State_Type)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      return Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostics_Show);
   end Build_UI_Reveal_Diagnostics;

   function Build_UI_Operability_Snapshot
     (S : Editor.State.State_Type) return Editor.Build_UI.Build_UI_Render_Snapshot
   is
      Availability : constant Editor.Commands.Command_Availability :=
        Editor.Build_Command.Build_Run_Availability (S);
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot :=
        Editor.Build_UI.Build_Render_Snapshot
          (S.Build_UI, S.Latest_Build_Result, S.Latest_Build_Output_Details);
   begin
      Snapshot.Run_Available := Editor.Commands.Is_Available (Availability);
      if Snapshot.Run_Available then
         Snapshot.Run_Availability_Label := To_Unbounded_String ("Build request ready");
      else
         Snapshot.Run_Availability_Label := To_Unbounded_String
           (Editor.Commands.Unavailable_Reason (Availability));
      end if;
      Snapshot.Request_Preview.Availability_Label :=
        Snapshot.Run_Availability_Label;
      return Snapshot;
   end Build_UI_Operability_Snapshot;

   function Assert_Build_UI_Operable
     (S : Editor.State.State_Type) return Boolean
   is
      Snapshot : constant Editor.Build_UI.Build_UI_Render_Snapshot :=
        Build_UI_Operability_Snapshot (S);
   begin
      return Editor.Build_UI.Assert_Build_UI_Render_Snapshot_Is_Operable
          (Snapshot)
        and then Length (Snapshot.Run_Availability_Label) > 0;
   end Assert_Build_UI_Operable;

   function Assert_Build_UI_Run_Routes_Through_Executor
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result) return Boolean
   is
      pragma Unreferenced (Before);
   begin
      return Result.Command = Editor.Commands.Command_Build_Run
        and then (Result.Status = Editor.Command_Execution.Command_Executed
          or else Result.Status = Editor.Command_Execution.Command_Unavailable
          or else Result.Status = Editor.Command_Execution.Command_Failed)
        and then Editor.Build_UI.Assert_Build_UI_State_Is_Transient
          (After.Build_UI);
   end Assert_Build_UI_Run_Routes_Through_Executor;

   function Assert_Build_UI_Does_Not_Persist_Transient_State
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_UI.Assert_Build_UI_State_Is_Transient (S.Build_UI)
        and then Editor.Build_Result_Summary.Assert_Latest_Build_Result_Summary_Persistence_Excluded
          (S.Latest_Build_Result)
        and then Editor.Build_Output_Details.Assert_Build_Output_Details_Persistence_Excluded
          (S.Latest_Build_Output_Details);
   end Assert_Build_UI_Does_Not_Persist_Transient_State;

   function Assert_Public_Build_UI_Operability_Coherent
     (S : Editor.State.State_Type) return Boolean
   is
      Snapshot : constant Editor.Build_UI.Build_UI_Render_Snapshot :=
        Build_UI_Operability_Snapshot (S);
   begin
      return Assert_Build_UI_Operable (S)
        and then Assert_Build_UI_Does_Not_Persist_Transient_State (S)
        and then Snapshot.Visible
        and then Length (Snapshot.Request_Preview.Consent_Label) > 0
        and then Length (Snapshot.Request_Preview.Availability_Label) > 0;
   end Assert_Public_Build_UI_Operability_Coherent;

   function Assert_Build_UI_Reveal_Diagnostics_Uses_Existing_Command
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result) return Boolean
   is
   begin
      return Result.Command = Editor.Commands.Command_Diagnostics_Show
        and then (Result.Status = Editor.Command_Execution.Command_Executed
                  or else Result.Status = Editor.Command_Execution.Command_Unavailable
                  or else Result.Status = Editor.Command_Execution.Command_No_Op)
        and then To_String (Before.Latest_Build_Result.Primary_Message) =
          To_String (After.Latest_Build_Result.Primary_Message)
        and then To_String (Before.Latest_Build_Output_Details.Stdout_Excerpt) =
          To_String (After.Latest_Build_Output_Details.Stdout_Excerpt)
        and then To_String (Before.Latest_Build_Output_Details.Stderr_Excerpt) =
          To_String (After.Latest_Build_Output_Details.Stderr_Excerpt);
   end Assert_Build_UI_Reveal_Diagnostics_Uses_Existing_Command;

   function Assert_Public_Build_Result_Output_UI_Coherent
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_UI.Assert_Public_Build_Result_Output_UI_Coherent
        (S.Build_UI, S.Latest_Build_Result, S.Latest_Build_Output_Details)
        and then Assert_Build_UI_Does_Not_Persist_Transient_State (S);
   end Assert_Public_Build_Result_Output_UI_Coherent;

end Editor.Build_UI_Actions;
