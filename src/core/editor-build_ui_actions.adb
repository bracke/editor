with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Command_Projection;
with Editor.Build_Candidate_Refresh;
with Editor.Build_Command;
with Editor.Build_Output_Details;
with Editor.Build_Result_Summary;
with Editor.Build_UI;
with Editor.Build_Working_Context;
with Editor.Command_Execution;
with Editor.Commands;
with Editor.Executor;
with Editor.Feature_Diagnostics;
with Editor.Feature_Panel;
with Editor.Focus_Management;
with Editor.State;

package body Editor.Build_UI_Actions is

   use type Editor.Command_Execution.Command_Execution_Status;
   use type Editor.Ada_Diagnostic_Command_Projection.Diagnostic_Command_Kind;
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

   procedure Build_UI_Select_First_Candidate
     (S : in out Editor.State.State_Type)
   is
   begin
      if Natural (S.Build_UI.Build_Candidates.Length) = 0 then
         return;
      end if;

      Editor.Build_UI.Select_Build_Candidate
        (S.Build_UI,
         To_String
           (S.Build_UI.Build_Candidates.Element
              (S.Build_UI.Build_Candidates.First_Index).Candidate_Id));
   end Build_UI_Select_First_Candidate;

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

   function Build_UI_Open_Diagnostic_Source
     (S : in out Editor.State.State_Type)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      return Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostic_Open_Source);
   end Build_UI_Open_Diagnostic_Source;

   function Build_UI_Suppress_Diagnostic
     (S : in out Editor.State.State_Type)
      return Editor.Command_Execution.Command_Execution_Result
   is
   begin
      return Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostic_Suppress_Selected);
   end Build_UI_Suppress_Diagnostic;

   function Build_UI_Apply_Diagnostic_Quick_Fix
     (S            : in out Editor.State.State_Type;
      Action_Index : Natural := 0;
      Diagnostic_Index : Natural := 0)
      return Editor.Command_Execution.Command_Execution_Result
   is
      Selected_Diagnostic_Index : constant Natural :=
        Editor.Feature_Diagnostics.Map_Diagnostic_Row_To_Item
          (S.Feature_Diagnostics, S.Feature_Panel,
           Editor.Feature_Panel.Selected_Row (S.Feature_Panel),
           Editor.Feature_Panel.Projection_Generation (S.Feature_Panel));
      Effective_Diagnostic_Index : constant Natural :=
        (if Diagnostic_Index > 0 then Diagnostic_Index else Selected_Diagnostic_Index);
   begin
      if Action_Index > 0 then
         Editor.State.Start_Quick_Fix_Workflow
           (S, Effective_Diagnostic_Index, Action_Index);
      end if;
      return Editor.Executor.Execute_Command_With_Result
        (S, Editor.Commands.Command_Diagnostic_Apply_Quick_Fix);
   end Build_UI_Apply_Diagnostic_Quick_Fix;

   function Build_UI_Operability_Snapshot
     (S : Editor.State.State_Type) return Editor.Build_UI.Build_UI_Render_Snapshot
   is
      Availability : constant Editor.Commands.Command_Availability :=
        Editor.Build_Command.Build_Run_Availability (S);
      Snapshot : Editor.Build_UI.Build_UI_Render_Snapshot :=
        Editor.Build_UI.Build_Render_Snapshot
          (S.Build_UI, S.Latest_Build_Result, S.Latest_Build_Output_Details);
   begin
      Snapshot.Request_Valid := Snapshot.Run_Available;
      Snapshot.Run_Available := Editor.Commands.Is_Available (Availability);
      Snapshot.Run_Command_Available := Snapshot.Run_Available;
      if Snapshot.Request_Valid then
         Snapshot.Request_Status_Label := To_Unbounded_String ("Build request valid");
      else
         Snapshot.Request_Status_Label := To_Unbounded_String
           ("Build request invalid: "
            & To_String (Snapshot.Request_Preview.Availability_Label));
      end if;
      if Snapshot.Run_Available then
         Snapshot.Run_Availability_Label := To_Unbounded_String ("Build request ready");
         Snapshot.Run_Command_Status_Label :=
           To_Unbounded_String ("Run command available");
      else
         Snapshot.Run_Availability_Label := To_Unbounded_String
           (Editor.Commands.Unavailable_Reason (Availability));
         Snapshot.Run_Command_Status_Label := To_Unbounded_String
           ("Run command unavailable: "
            & Editor.Commands.Unavailable_Reason (Availability));
      end if;
      Snapshot.Request_Preview.Availability_Label :=
        Snapshot.Run_Availability_Label;

      declare
         procedure Append_Action_Row
           (Label           : String;
            Command         : Editor.Commands.Command_Id;
            Enabled         : Boolean;
            Disabled_Reason : String := "";
            Diagnostic_Index : Natural := 0;
            Quick_Fix_Action_Index : Natural := 0)
         is
         begin
            Snapshot.Actions.Append
              (Editor.Build_UI.Build_UI_Action_Row'
                 (Label => To_Unbounded_String (Label),
                  Command_Name => To_Unbounded_String
                    (Editor.Commands.Stable_Command_Name (Command)),
                  Enabled => Enabled,
                  Selected => False,
                  Diagnostic_Index => Diagnostic_Index,
                  Quick_Fix_Action_Index => Quick_Fix_Action_Index,
                  Disabled_Reason =>
                    (if Enabled then Null_Unbounded_String
                     else To_Unbounded_String (Disabled_Reason))));
         end Append_Action_Row;

         Open_Availability : constant Editor.Commands.Command_Availability :=
           Editor.Executor.Command_Availability
             (S, Editor.Commands.Command_Diagnostic_Open_Source);
         Suppress_Availability : constant Editor.Commands.Command_Availability :=
           Editor.Executor.Command_Availability
             (S, Editor.Commands.Command_Diagnostic_Suppress_Selected);
         Restore_Availability : constant Editor.Commands.Command_Availability :=
           Editor.Executor.Command_Availability
             (S, Editor.Commands.Command_Diagnostic_Restore_Last_Suppressed);
         Restore_Selected_Availability : constant Editor.Commands.Command_Availability :=
           Editor.Executor.Command_Availability
             (S, Editor.Commands.Command_Diagnostic_Restore_Selected_Suppressed);
         Clear_Suppressed_Availability : constant Editor.Commands.Command_Availability :=
           Editor.Executor.Command_Availability
             (S, Editor.Commands.Command_Diagnostic_Clear_Suppressed);
         Show_Suppressed_Availability : constant Editor.Commands.Command_Availability :=
           Editor.Executor.Command_Availability
             (S, Editor.Commands.Command_Diagnostic_Show_Suppressed);
         Quick_Fix_Availability : constant Editor.Commands.Command_Availability :=
           Editor.Executor.Command_Availability
             (S, Editor.Commands.Command_Diagnostic_Apply_Quick_Fix);
         Selected_Source : constant Natural :=
           Editor.Feature_Diagnostics.Map_Diagnostic_Row_To_Item
             (S.Feature_Diagnostics, S.Feature_Panel,
              Editor.Feature_Panel.Selected_Row (S.Feature_Panel),
              Editor.Feature_Panel.Projection_Generation (S.Feature_Panel));
         Selected_Has_Quick_Fix : constant Boolean :=
           Selected_Source /= 0
           and then Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Count
             (S.Feature_Diagnostics, Positive (Selected_Source)) > 0;
         Suppressed_Count : constant Natural :=
           Editor.Feature_Diagnostics.Suppressed_Diagnostic_Count
             (S.Feature_Diagnostics);
         Selected_Suppressed : constant Natural :=
           Editor.Feature_Diagnostics.Selected_Suppressed_Diagnostic
             (S.Feature_Diagnostics);
         Selected_Suppressed_Text : constant String :=
           (if Selected_Suppressed = 0 then ""
            else Editor.Feature_Diagnostics.Suppressed_Diagnostic_Text
              (S.Feature_Diagnostics, Positive (Selected_Suppressed)));

         function Quick_Fix_Action_Available
           (Action_Index : Natural) return Boolean
         is
         begin
            return Selected_Source > 0
              and then Editor.Commands.Is_Available
                (Editor.Executor.Diagnostic_Quick_Fix_Action_Availability
                   (S, Selected_Source, Action_Index));
         end Quick_Fix_Action_Available;

         function Quick_Fix_Action_Unavailable_Reason
           (Action_Index : Natural) return String
         is
            Availability : constant Editor.Commands.Command_Availability :=
              (if Selected_Source = 0
               then Editor.Commands.Unavailable ("No diagnostic selected")
               else Editor.Executor.Diagnostic_Quick_Fix_Action_Availability
                 (S, Selected_Source, Action_Index));
         begin
            if Selected_Source = 0 then
               return "No diagnostic selected";
            elsif not Selected_Has_Quick_Fix then
               return "Selected diagnostic has no quick fix";
            elsif not Editor.Commands.Is_Available (Availability) then
               return Editor.Commands.Unavailable_Reason (Availability);
            else
               return "";
            end if;
         end Quick_Fix_Action_Unavailable_Reason;
      begin
         Snapshot.Diagnostics_View.Open_Source_Available :=
           Editor.Commands.Is_Available (Open_Availability);
         Snapshot.Diagnostics_View.Open_Source_Unavailable_Reason :=
           (if Snapshot.Diagnostics_View.Open_Source_Available then
              Null_Unbounded_String
            else To_Unbounded_String
              (Editor.Commands.Unavailable_Reason (Open_Availability)));

         Snapshot.Diagnostics_View.Suppress_Available :=
           Editor.Commands.Is_Available (Suppress_Availability);
         Snapshot.Diagnostics_View.Suppress_Unavailable_Reason :=
           (if Snapshot.Diagnostics_View.Suppress_Available then
              Null_Unbounded_String
            else To_Unbounded_String
              (Editor.Commands.Unavailable_Reason (Suppress_Availability)));

         Snapshot.Diagnostics_View.Suppressed_Count_Label :=
           To_Unbounded_String
             ("Suppressed: "
              & Ada.Strings.Fixed.Trim
                  (Natural'Image (Suppressed_Count), Ada.Strings.Both));
         Snapshot.Diagnostics_View.Show_Suppressed_Available :=
           Editor.Commands.Is_Available (Show_Suppressed_Availability);
         Snapshot.Diagnostics_View.Show_Suppressed_Unavailable_Reason :=
           (if Snapshot.Diagnostics_View.Show_Suppressed_Available then
              Null_Unbounded_String
            else To_Unbounded_String
              (Editor.Commands.Unavailable_Reason (Show_Suppressed_Availability)));
         Snapshot.Diagnostics_View.Restore_Suppressed_Available :=
           Editor.Commands.Is_Available (Restore_Availability);
         Snapshot.Diagnostics_View.Restore_Suppressed_Unavailable_Reason :=
           (if Snapshot.Diagnostics_View.Restore_Suppressed_Available then
              Null_Unbounded_String
            else To_Unbounded_String
              (Editor.Commands.Unavailable_Reason (Restore_Availability)));

         Snapshot.Diagnostics_View.Quick_Fix_Available :=
           Selected_Has_Quick_Fix
           and then Editor.Commands.Is_Available (Quick_Fix_Availability);
         if Selected_Has_Quick_Fix then
            Snapshot.Diagnostics_View.Quick_Fix_Label :=
              To_Unbounded_String
                (Editor.Feature_Diagnostics.Item_Quick_Fix_Label_For_Display
                   (S.Feature_Diagnostics, Positive (Selected_Source)));
            Snapshot.Diagnostics_View.Quick_Fix_Detail :=
              To_Unbounded_String
                (Editor.Feature_Diagnostics.Item_Quick_Fix_Detail_For_Display
                   (S.Feature_Diagnostics, Positive (Selected_Source)));
         else
            Snapshot.Diagnostics_View.Quick_Fix_Label :=
              To_Unbounded_String ("Apply quick fix");
            Snapshot.Diagnostics_View.Quick_Fix_Detail :=
              (if Selected_Source = 0 then
                 To_Unbounded_String ("No diagnostic selected")
               else
                 To_Unbounded_String ("Selected diagnostic has no quick fix"));
         end if;
         Snapshot.Diagnostics_View.Quick_Fix_Unavailable_Reason :=
           (if Snapshot.Diagnostics_View.Quick_Fix_Available then
              Null_Unbounded_String
            elsif Selected_Source = 0 then
              To_Unbounded_String ("No diagnostic selected")
            elsif not Selected_Has_Quick_Fix then
              To_Unbounded_String ("Selected diagnostic has no quick fix")
            else To_Unbounded_String
              (Editor.Commands.Unavailable_Reason (Quick_Fix_Availability)));

         Snapshot.Diagnostics_View.Action_Summary_Label :=
           To_Unbounded_String
             ((if Snapshot.Diagnostics_View.Reveal_Available then
                  "Actions: reveal, open source, suppress, restore, clear, quick fix"
               else
                  "Actions unavailable until diagnostics are produced"));

         Append_Action_Row
           ("Reveal diagnostics",
            Editor.Commands.Command_Diagnostics_Show,
            Snapshot.Diagnostics_View.Reveal_Available,
            "No build diagnostics to reveal");
         Append_Action_Row
           ("Open diagnostic source",
            Editor.Commands.Command_Diagnostic_Open_Source,
            Snapshot.Diagnostics_View.Open_Source_Available,
            To_String (Snapshot.Diagnostics_View.Open_Source_Unavailable_Reason));
         Append_Action_Row
           ("Suppress diagnostic",
            Editor.Commands.Command_Diagnostic_Suppress_Selected,
            Snapshot.Diagnostics_View.Suppress_Available,
            To_String (Snapshot.Diagnostics_View.Suppress_Unavailable_Reason));
         Append_Action_Row
           ("Show suppressed diagnostics",
            Editor.Commands.Command_Diagnostic_Show_Suppressed,
            Snapshot.Diagnostics_View.Show_Suppressed_Available,
            To_String
              (Snapshot.Diagnostics_View.Show_Suppressed_Unavailable_Reason));
         Append_Action_Row
           ("Restore suppressed diagnostic",
            Editor.Commands.Command_Diagnostic_Restore_Last_Suppressed,
            Snapshot.Diagnostics_View.Restore_Suppressed_Available,
            To_String
              (Snapshot.Diagnostics_View.Restore_Suppressed_Unavailable_Reason));
         Append_Action_Row
           ((if Selected_Suppressed_Text'Length > 0 then
                "Restore selected suppressed: " & Selected_Suppressed_Text
             else
                "Restore selected suppressed diagnostic"),
            Editor.Commands.Command_Diagnostic_Restore_Selected_Suppressed,
            Editor.Commands.Is_Available (Restore_Selected_Availability),
            Editor.Commands.Unavailable_Reason (Restore_Selected_Availability));
         Append_Action_Row
           ("Clear suppressed diagnostics ("
            & Ada.Strings.Fixed.Trim
                (Natural'Image (Suppressed_Count), Ada.Strings.Both)
            & ")",
            Editor.Commands.Command_Diagnostic_Clear_Suppressed,
            Editor.Commands.Is_Available (Clear_Suppressed_Availability),
            Editor.Commands.Unavailable_Reason (Clear_Suppressed_Availability));
         if Selected_Source > 0
           and then Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Count
             (S.Feature_Diagnostics, Positive (Selected_Source)) > 1
         then
            for Action_Index in 1 ..
              Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Count
                (S.Feature_Diagnostics, Positive (Selected_Source))
            loop
               Append_Action_Row
                 (Editor.Feature_Diagnostics.Item_Quick_Fix_Action_Label_For_Display
                    (S.Feature_Diagnostics, Positive (Selected_Source), Action_Index),
                  Editor.Commands.Command_Diagnostic_Apply_Quick_Fix,
                  Quick_Fix_Action_Available (Action_Index),
                  Diagnostic_Index => Selected_Source,
                  Quick_Fix_Action_Index => Action_Index,
                  Disabled_Reason =>
                    Quick_Fix_Action_Unavailable_Reason (Action_Index));
            end loop;
         else
            Append_Action_Row
              (To_String (Snapshot.Diagnostics_View.Quick_Fix_Label),
               Editor.Commands.Command_Diagnostic_Apply_Quick_Fix,
               Quick_Fix_Action_Available
                 ((if Selected_Source > 0 then 1 else 0)),
               Diagnostic_Index => Selected_Source,
               Quick_Fix_Action_Index =>
                 (if Selected_Source > 0 then 1 else 0),
               Disabled_Reason =>
                 Quick_Fix_Action_Unavailable_Reason
                   ((if Selected_Source > 0 then 1 else 0)));
         end if;
         declare
            Selected : constant Natural :=
              Editor.Build_UI.Selected_Action_Row
                (S.Build_UI, Natural (Snapshot.Actions.Length));
         begin
            if Selected > 0 then
               for I in Snapshot.Actions.First_Index .. Snapshot.Actions.Last_Index loop
                  declare
                     Row : Editor.Build_UI.Build_UI_Action_Row :=
                       Snapshot.Actions.Element (I);
                  begin
                     Row.Selected := Natural (I) = Selected - 1;
                     Snapshot.Actions.Replace_Element (I, Row);
                  end;
               end loop;
            end if;
         end;
      end;
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

   function Assert_Build_UI_Diagnostic_Action_Is_UI_Routed
     (Before : Editor.State.State_Type;
      After  : Editor.State.State_Type;
      Result : Editor.Command_Execution.Command_Execution_Result) return Boolean
   is
   begin
      return (Result.Command = Editor.Commands.Command_Diagnostic_Open_Source
              or else Result.Command = Editor.Commands.Command_Diagnostic_Suppress_Selected
              or else Result.Command = Editor.Commands.Command_Diagnostic_Apply_Quick_Fix)
        and then (Result.Status = Editor.Command_Execution.Command_Executed
                  or else Result.Status = Editor.Command_Execution.Command_Unavailable
                  or else Result.Status = Editor.Command_Execution.Command_No_Op)
        and then To_String (Before.Latest_Build_Result.Primary_Message) =
          To_String (After.Latest_Build_Result.Primary_Message)
        and then To_String (Before.Latest_Build_Output_Details.Stdout_Excerpt) =
          To_String (After.Latest_Build_Output_Details.Stdout_Excerpt)
        and then To_String (Before.Latest_Build_Output_Details.Stderr_Excerpt) =
          To_String (After.Latest_Build_Output_Details.Stderr_Excerpt);
   end Assert_Build_UI_Diagnostic_Action_Is_UI_Routed;

   function Assert_Public_Build_Result_Output_UI_Coherent
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Build_UI.Assert_Public_Build_Result_Output_UI_Coherent
        (S.Build_UI, S.Latest_Build_Result, S.Latest_Build_Output_Details)
        and then Assert_Build_UI_Does_Not_Persist_Transient_State (S);
   end Assert_Public_Build_Result_Output_UI_Coherent;

end Editor.Build_UI_Actions;
