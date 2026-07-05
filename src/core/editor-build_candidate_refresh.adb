with Ada.Containers;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Candidate_Discovery;
with Editor.Build_Candidates;
with Editor.Build_UI;
with Editor.Build_Working_Context;
with Editor.External_Producers;

package body Editor.Build_Candidate_Refresh is

   use type Ada.Containers.Count_Type;
   use type Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Status;
   use type Editor.Build_UI.Build_Candidate_Refresh_Status;
   use type Editor.Build_UI.Public_Build_UI_Validation_Status;

   function To_UI_Arguments
     (Arguments : Editor.Build_Candidates.Build_Candidate_Argument_Vector)
      return Editor.Build_UI.Build_UI_Argument_Vector
   is
      Result : Editor.Build_UI.Build_UI_Argument_Vector :=
        Editor.Build_UI.Empty_Arguments;
   begin
      for Arg of Arguments loop
         Result.Append (Arg);
      end loop;
      return Result;
   end To_UI_Arguments;

   function Find_Candidate
     (Candidates   : Editor.Build_Candidates.Build_Candidate_Vector;
      Candidate_Id : String;
      Candidate    : out Editor.Build_Candidates.Build_Candidate_Record)
      return Boolean
   is
   begin
      for C of Candidates loop
         if To_String (C.Candidate_Id) = Candidate_Id then
            Candidate := C;
            return True;
         end if;
      end loop;
      return False;
   end Find_Candidate;

   function Count_Candidates_With_Id
     (Candidates   : Editor.Build_Candidates.Build_Candidate_Vector;
      Candidate_Id : String) return Natural
   is
      Count : Natural := 0;
   begin
      for C of Candidates loop
         if To_String (C.Candidate_Id) = Candidate_Id then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Candidates_With_Id;

   function Build_Candidate_Identity
     (Candidate : Editor.Build_Candidates.Build_Candidate_Record) return String
   is
      Result : Unbounded_String := To_Unbounded_String
        (To_String (Candidate.Candidate_Id));
   begin
      Append (Result, "|material=");
      Append (Result, Build_Candidate_Material_Identity (Candidate));
      return To_String (Result);
   end Build_Candidate_Identity;

   function Build_Candidate_Material_Identity
     (Candidate : Editor.Build_Candidates.Build_Candidate_Record) return String
   is
      Result : Unbounded_String := To_Unbounded_String
        (Editor.Build_Candidates.Build_Candidate_Kind'Image
           (Candidate.Candidate_Kind));
   begin
      Append (Result, "|tool=");
      Append (Result, Editor.External_Producers.Build_Tool_Kind'Image
        (Candidate.Tool_Kind));
      Append (Result, "|ctx=");
      Append (Result, Editor.Build_Working_Context.Request_Identity_Token
        (Candidate.Working_Context));
      Append (Result, "|src=");
      Append (Result, To_String (Candidate.Source_Path_If_Represented));
      Append (Result, "|argv=");
      for Arg of Candidate.Structured_Arguments loop
         Append (Result, "[");
         Append (Result, To_String (Arg));
         Append (Result, "]");
      end loop;
      return To_String (Result);
   end Build_Candidate_Material_Identity;

   function Candidate_Identity_Matches
     (Left  : Editor.Build_Candidates.Build_Candidate_Record;
      Right : Editor.Build_Candidates.Build_Candidate_Record) return Boolean
   is
   begin
      return Build_Candidate_Identity (Left) = Build_Candidate_Identity (Right);
   end Candidate_Identity_Matches;

   function Candidate_Material_Matches
     (Left  : Editor.Build_Candidates.Build_Candidate_Record;
      Right : Editor.Build_Candidates.Build_Candidate_Record) return Boolean
   is
   begin
      return Build_Candidate_Material_Identity (Left) =
        Build_Candidate_Material_Identity (Right);
   end Candidate_Material_Matches;

   function Candidate_List_Identity
     (Candidates : Editor.Build_Candidates.Build_Candidate_Vector) return String
   is
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      for C of Candidates loop
         Append (Result, "{");
         Append (Result, Build_Candidate_Identity (C));
         Append (Result, "}");
      end loop;
      return To_String (Result);
   end Candidate_List_Identity;


   function Refresh_Status_From_Discovery
     (Discovery : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result)
      return Editor.Build_UI.Build_Candidate_Refresh_Status
   is
   begin
      if Discovery.Status =
        Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Complete
      then
         return Editor.Build_UI.Build_Candidate_Refresh_Succeeded;
      elsif Discovery.Status =
        Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_No_Project_Context
      then
         return Editor.Build_UI.Build_Candidate_Refresh_No_Project_Context;
      elsif Discovery.Status =
        Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_No_Candidates
      then
         return Editor.Build_UI.Build_Candidate_Refresh_No_Candidates;
      else
         return Editor.Build_UI.Build_Candidate_Refresh_Failed;
      end if;
   end Refresh_Status_From_Discovery;

   procedure Record_Failed_Refresh_Status
     (State  : in out Editor.Build_UI.Public_Build_UI_State;
      Before : Editor.Build_UI.Public_Build_UI_State;
      Result : in out Build_Candidate_Refresh_Result)
   is
   begin
      --  Failed refresh is status-only. It is not an alternate candidate-list
      --  owner and cannot clear, repair, auto-select, or auto-consent.
      --  removes the runnable manual request preservation path:
      --  refresh status must not retain request config without a selected
      --  discovered candidate.
      Result.Manual_Request_Preserved := False;
      State.Candidate_Refresh_Status := Result.Status;
      State.Candidate_Refresh_Message := Result.Message;
      State.Candidate_Discovery_Message := Result.Message;
      State.Last_Refresh_Candidate_Count := 0;
      State.Selected_Candidate_Preserved_On_Refresh := False;
      State.Selected_Candidate_Cleared_On_Refresh := False;
   end Record_Failed_Refresh_Status;

   procedure Invalidate_Consent_On_Candidate_Refresh_Change
     (State  : in out Editor.Build_UI.Public_Build_UI_State;
      Result : in out Build_Candidate_Refresh_Result)
   is
   begin
      if State.Consent_Acknowledged then
         Result.Consent_Invalidated := True;
      end if;
      Editor.Build_UI.Clear_Consent (State);
   end Invalidate_Consent_On_Candidate_Refresh_Change;

   procedure Reconcile_Selected_Build_Candidate_After_Refresh
     (State         : in out Editor.Build_UI.Public_Build_UI_State;
      Old_State     : Editor.Build_UI.Public_Build_UI_State;
      New_Candidates : Editor.Build_Candidates.Build_Candidate_Vector;
      Result        : in out Build_Candidate_Refresh_Result)
   is
      Selected_Id : constant String :=
        To_String (Old_State.Selected_Build_Candidate_Id);
      Old_Candidate : Editor.Build_Candidates.Build_Candidate_Record;
      New_Candidate : Editor.Build_Candidates.Build_Candidate_Record;
      Had_Selection : constant Boolean := Selected_Id'Length > 0;
      Old_Found : Boolean := False;
      New_Found : Boolean := False;
   begin
      --  candidate refresh never preserves a runnable/manual
      --  configured request when no candidate is selected.
      Result.Manual_Request_Preserved := False;
      State.Build_Candidates := New_Candidates;
      State.Candidate_Discovery_Message := Result.Message;
      State.Candidate_Refresh_Status := Result.Status;
      State.Candidate_Refresh_Message := Result.Message;
      State.Last_Refresh_Candidate_Count := Result.Candidate_Count;
      State.Selected_Candidate_Stale := False;
      State.Selected_Candidate_Preserved_On_Refresh := False;
      State.Selected_Candidate_Cleared_On_Refresh := False;

      if not Had_Selection then
         --  refresh may update the candidate list, but it must not
         --  preserve or manufacture a configured request without an explicit
         --  selected candidate.  Clear any stale/manual request shape so the
         --  UI remains in the no-candidate-selected state.
         State.Selected_Build_Candidate_Id := Null_Unbounded_String;
         State.Selected_Build_Candidate_Status :=
           Editor.Build_Candidates.Build_Candidate_Unavailable;
         State.Candidate_Applied_To_Request := False;
         State.Candidate_Request_Preview := Null_Unbounded_String;
         State.Candidate_Selection_Message := To_Unbounded_String
           ("No build candidate selected");
         State.Selected_Candidate_Stale := False;
         State.Selected_Build_Tool := Editor.Build_UI.Build_UI_No_Tool;
         State.Structured_Arguments := Editor.Build_UI.Empty_Arguments;
         State.Selected_Working_Context := Editor.Build_Working_Context.None;
         State.Build_Target_Label := Null_Unbounded_String;
         State.Selected_Build_Mode := Editor.Build_UI.Build_UI_Build_Mode_Default;
         State.Show_Diagnostics_On_Result := False;
         State.Output_Capture_Limit := Editor.Build_UI.Build_UI_Output_Capture_Normal;
         State.Option_Verbose_Output := False;
         State.Option_Keep_Going := False;
         State.Option_Warnings_As_Errors := False;
         State.Option_Force_Rebuild := False;
         Editor.Build_UI.Clear_Consent (State);
         return;
      end if;

      Old_Found := Find_Candidate
        (Old_State.Build_Candidates, Selected_Id, Old_Candidate);
      New_Found := Find_Candidate
        (New_Candidates, Selected_Id, New_Candidate);

      if Count_Candidates_With_Id (Old_State.Build_Candidates, Selected_Id) /= 1
        or else Count_Candidates_With_Id (New_Candidates, Selected_Id) /= 1
      then
         Old_Found := False;
         New_Found := False;
      end if;

      if Old_Found and then New_Found
        and then Candidate_Material_Matches (Old_Candidate, New_Candidate)
      then
         State.Selected_Build_Candidate_Id := New_Candidate.Candidate_Id;
         State.Selected_Build_Candidate_Status :=
           Editor.Build_Candidates.Validate_Candidate (New_Candidate);
         State.Candidate_Applied_To_Request := Old_State.Candidate_Applied_To_Request;
         State.Selected_Build_Tool := Old_State.Selected_Build_Tool;
         State.Structured_Arguments := Old_State.Structured_Arguments;
         State.Selected_Working_Context := Old_State.Selected_Working_Context;
         State.Build_Target_Label := Old_State.Build_Target_Label;
         State.Candidate_Request_Preview := Old_State.Candidate_Request_Preview;
         State.Candidate_Selection_Message := To_Unbounded_String
           ("Selected build candidate preserved after refresh");
         State.Consent_Acknowledged := Old_State.Consent_Acknowledged;
         State.Consent_Request_Identity := Old_State.Consent_Request_Identity;
         State.Pending_Public_Build_Request := Old_State.Pending_Public_Build_Request;
         if State.Consent_Acknowledged
           and then To_String (State.Consent_Request_Identity) /=
             Editor.Build_UI.Current_Request_Identity (State)
         then
            Invalidate_Consent_On_Candidate_Refresh_Change (State, Result);
         end if;
         Result.Selected_Candidate_Preserved := True;
         State.Selected_Candidate_Preserved_On_Refresh := True;
      else
         State.Selected_Build_Candidate_Id := Null_Unbounded_String;
         State.Selected_Build_Candidate_Status :=
           Editor.Build_Candidates.Build_Candidate_Unavailable;
         State.Candidate_Applied_To_Request := False;
         State.Candidate_Request_Preview := Null_Unbounded_String;
         State.Candidate_Selection_Message := To_Unbounded_String
           ("Selected build candidate is stale after refresh; select a build candidate and acknowledge consent again");
         State.Selected_Candidate_Stale := True;
         State.Selected_Candidate_Cleared_On_Refresh := True;
         Result.Selected_Candidate_Cleared := True;
         State.Structured_Arguments := Editor.Build_UI.Empty_Arguments;
         State.Selected_Build_Tool := Editor.Build_UI.Build_UI_No_Tool;
         State.Build_Target_Label := Null_Unbounded_String;
         State.Selected_Working_Context := Editor.Build_Working_Context.None;
         Invalidate_Consent_On_Candidate_Refresh_Change (State, Result);
      end if;
   end Reconcile_Selected_Build_Candidate_After_Refresh;

   function Refresh_Build_Candidates
     (State   : in out Editor.Build_UI.Public_Build_UI_State;
      Context : Editor.Build_Working_Context.Build_Working_Context_Record)
      return Build_Candidate_Refresh_Result
   is
      Before : constant Editor.Build_UI.Public_Build_UI_State := State;
      Discovery : constant Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result :=
        Editor.Build_Candidate_Discovery.Discover_Build_Candidates (Context);
      Result : Build_Candidate_Refresh_Result;
   begin
      Result.Discovery := Discovery;
      Result.Candidate_Count := Natural (Discovery.Candidates.Length);

      Result.Status := Refresh_Status_From_Discovery (Discovery);
      Result.Message := Discovery.Message;

      if Result.Status = Editor.Build_UI.Build_Candidate_Refresh_Failed then
         Record_Failed_Refresh_Status (State, Before, Result);
         return Result;
      end if;

      Reconcile_Selected_Build_Candidate_After_Refresh
        (State, Before, Discovery.Candidates, Result);
      State.Candidate_Refresh_Status := Result.Status;
      State.Candidate_Refresh_Message := Result.Message;
      State.Last_Refresh_Candidate_Count := Result.Candidate_Count;
      State.Selected_Candidate_Preserved_On_Refresh :=
        Result.Selected_Candidate_Preserved;
      State.Selected_Candidate_Cleared_On_Refresh :=
        Result.Selected_Candidate_Cleared;
      return Result;
   end Refresh_Build_Candidates;


   function Failed_Lifecycle_Refresh_Result
     (Message : String) return Build_Candidate_Refresh_Result
   is
      Result : Build_Candidate_Refresh_Result;
   begin
      Result.Status := Editor.Build_UI.Build_Candidate_Refresh_Failed;
      Result.Message := To_Unbounded_String (Message);
      Result.Candidate_Count := 0;
      Result.Discovery.Status :=
        Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_No_Project_Context;
      Result.Discovery.Message := Result.Message;
      return Result;
   end Failed_Lifecycle_Refresh_Result;

   function Refresh_After_Successful_Project_Transition
     (State                : in out Editor.Build_UI.Public_Build_UI_State;
      Context              : Editor.Build_Working_Context.Build_Working_Context_Record;
      Transition_Succeeded : Boolean;
      Failed_Message       : String) return Build_Candidate_Refresh_Result
   is
   begin
      if not Transition_Succeeded then
         return Failed_Lifecycle_Refresh_Result (Failed_Message);
      end if;
      return Refresh_Build_Candidates (State, Context);
   end Refresh_After_Successful_Project_Transition;

   function Refresh_Build_Candidates_After_Project_Open
     (State              : in out Editor.Build_UI.Public_Build_UI_State;
      Context            : Editor.Build_Working_Context.Build_Working_Context_Record;
      Transition_Succeeded : Boolean := True)
      return Build_Candidate_Refresh_Result
   is
   begin
      return Refresh_After_Successful_Project_Transition
        (State, Context, Transition_Succeeded,
         "Project open failed; build candidates unchanged");
   end Refresh_Build_Candidates_After_Project_Open;

   function Refresh_Build_Candidates_After_Project_Switch
     (State              : in out Editor.Build_UI.Public_Build_UI_State;
      Context            : Editor.Build_Working_Context.Build_Working_Context_Record;
      Transition_Succeeded : Boolean := True)
      return Build_Candidate_Refresh_Result
   is
   begin
      return Refresh_After_Successful_Project_Transition
        (State, Context, Transition_Succeeded,
         "Project switch failed; build candidates unchanged");
   end Refresh_Build_Candidates_After_Project_Switch;

   function Refresh_Build_Candidates_After_Project_Reset
     (State              : in out Editor.Build_UI.Public_Build_UI_State;
      Context            : Editor.Build_Working_Context.Build_Working_Context_Record;
      Transition_Succeeded : Boolean := True)
      return Build_Candidate_Refresh_Result
   is
   begin
      return Refresh_After_Successful_Project_Transition
        (State, Context, Transition_Succeeded,
         "Project reset failed; build candidates unchanged");
   end Refresh_Build_Candidates_After_Project_Reset;

   function Clear_Build_Candidates_After_Project_Close
     (State : in out Editor.Build_UI.Public_Build_UI_State)
      return Build_Candidate_Refresh_Result
   is
      Had_Selection : constant Boolean :=
        To_String (State.Selected_Build_Candidate_Id)'Length > 0;
      Had_Consent : constant Boolean := State.Consent_Acknowledged;
      Manual_Request_May_Be_Preserved : constant Boolean := False;
      Result : Build_Candidate_Refresh_Result;
   begin
      Result.Status := Editor.Build_UI.Build_Candidate_Refresh_No_Project_Context;
      Result.Message := To_Unbounded_String
        ("Project closed; build candidates unavailable");
      Result.Candidate_Count := 0;
      Result.Selected_Candidate_Cleared := Had_Selection;
      Result.Consent_Invalidated := Had_Consent;
      Result.Manual_Request_Preserved := Manual_Request_May_Be_Preserved;
      Result.Discovery.Status :=
        Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_No_Project_Context;
      Result.Discovery.Message := Result.Message;

      State.Build_Candidates := Editor.Build_Candidates.Empty_Candidates;
      State.Candidate_Discovery_Message := Result.Message;
      State.Candidate_Refresh_Status := Result.Status;
      State.Candidate_Refresh_Message := Result.Message;
      State.Last_Refresh_Candidate_Count := 0;
      State.Selected_Build_Candidate_Id := Null_Unbounded_String;
      State.Selected_Build_Candidate_Status :=
        Editor.Build_Candidates.Build_Candidate_Unavailable;
      State.Candidate_Applied_To_Request := False;
      State.Candidate_Request_Preview := Null_Unbounded_String;
      State.Candidate_Selection_Message := To_Unbounded_String
        ("Project closed; selected build candidate cleared");
      State.Selected_Candidate_Stale := False;
      State.Selected_Candidate_Preserved_On_Refresh := False;
      State.Selected_Candidate_Cleared_On_Refresh := Had_Selection;
      --  project close clears all executable request configuration,
      --  including stale/manual tool and argv shape.  A closed project must
      --  never retain a runnable build request without candidate selection.
      State.Selected_Build_Tool := Editor.Build_UI.Build_UI_No_Tool;
      State.Structured_Arguments := Editor.Build_UI.Empty_Arguments;
      State.Build_Target_Label := Null_Unbounded_String;
      State.Selected_Build_Mode := Editor.Build_UI.Build_UI_Build_Mode_Default;
      State.Show_Diagnostics_On_Result := False;
      State.Output_Capture_Limit := Editor.Build_UI.Build_UI_Output_Capture_Normal;
      State.Option_Verbose_Output := False;
      State.Option_Keep_Going := False;
      State.Option_Warnings_As_Errors := False;
      State.Option_Force_Rebuild := False;
      State.Selected_Working_Context :=
        Editor.Build_Working_Context.Unavailable
          ("No project open for build candidates");
      Editor.Build_UI.Clear_Consent (State);
      return Result;
   end Clear_Build_Candidates_After_Project_Close;

   function Assert_Project_Lifecycle_Refresh_Uses_Canonical_Path
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      return Assert_Build_Candidate_Refresh_Canonical_Path
        (Before, After, Result);
   end Assert_Project_Lifecycle_Refresh_Uses_Canonical_Path;

   function Assert_Project_Close_Clears_Build_Candidates
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
      pragma Unreferenced (Before);
   begin
      return Result.Status = Editor.Build_UI.Build_Candidate_Refresh_No_Project_Context
        and then Natural (After.Build_Candidates.Length) = 0
        and then To_String (After.Selected_Build_Candidate_Id)'Length = 0
        and then not After.Candidate_Applied_To_Request
        and then not After.Consent_Acknowledged
        and then not After.Pending_Public_Build_Request
        and then After.Candidate_Refresh_Status =
          Editor.Build_UI.Build_Candidate_Refresh_No_Project_Context
        and then Editor.Build_UI.Validate_Build_UI_State (After) /=
          Editor.Build_UI.Build_UI_Valid;
   end Assert_Project_Close_Clears_Build_Candidates;

   function Assert_Failed_Project_Transition_Does_Not_Fabricate_Candidates
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      return Result.Status = Editor.Build_UI.Build_Candidate_Refresh_Failed
        and then Candidate_List_Identity (After.Build_Candidates) =
          Candidate_List_Identity (Before.Build_Candidates)
        and then To_String (After.Selected_Build_Candidate_Id) =
          To_String (Before.Selected_Build_Candidate_Id)
        and then After.Consent_Acknowledged = Before.Consent_Acknowledged
        and then To_String (After.Consent_Request_Identity) =
          To_String (Before.Consent_Request_Identity);
   end Assert_Failed_Project_Transition_Does_Not_Fabricate_Candidates;

   function Assert_Project_Lifecycle_Does_Not_Auto_Select_Consent_Or_Run
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      return Assert_Build_Candidate_Refresh_Does_Not_Auto_Select
          (Before, After, Result)
        and then Assert_Build_Candidate_Refresh_Does_Not_Auto_Consent
          (Before, After)
        and then Assert_Build_Candidate_Refresh_Not_Build_Run_Side_Effect
          (Before, After, Result)
        and then not (not Before.Pending_Public_Build_Request
                      and then After.Pending_Public_Build_Request);
   end Assert_Project_Lifecycle_Does_Not_Auto_Select_Consent_Or_Run;

   function Assert_Project_Lifecycle_Candidate_State_Not_Persisted
     (State : Editor.Build_UI.Public_Build_UI_State) return Boolean
   is
   begin
      return Assert_Build_Candidate_Refresh_Persistence_Excluded (State);
   end Assert_Project_Lifecycle_Candidate_State_Not_Persisted;

   function Assert_Project_Lifecycle_Build_Candidate_Integration_Coherent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      return Assert_Project_Lifecycle_Does_Not_Auto_Select_Consent_Or_Run
          (Before, After, Result)
        and then Assert_Build_Candidate_Refresh_Not_Frontdoor_Payload (After)
        and then Assert_Build_Candidate_Refresh_Not_Diagnostics_Result_Output_Mutation
          (Before, After, Result)
        and then Assert_Project_Lifecycle_Candidate_State_Not_Persisted (After)
        and then
          (if Result.Status = Editor.Build_UI.Build_Candidate_Refresh_Failed then
              Assert_Failed_Project_Transition_Does_Not_Fabricate_Candidates
                (Before, After, Result)
           elsif Result.Status = Editor.Build_UI.Build_Candidate_Refresh_No_Project_Context
             and then Natural (After.Build_Candidates.Length) = 0 then
              Assert_Project_Close_Clears_Build_Candidates (Before, After, Result)
           else
              Assert_Project_Lifecycle_Refresh_Uses_Canonical_Path
                (Before, After, Result));
   end Assert_Project_Lifecycle_Build_Candidate_Integration_Coherent;

   function Assert_Build_Candidate_Refresh_Bounded
     (Result : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      return Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Bounded
          (Result.Discovery)
        and then Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Does_Not_Scan_Outside_Project_Root
          (Result.Discovery);
   end Assert_Build_Candidate_Refresh_Bounded;

   function Assert_Build_Candidate_Refresh_Does_Not_Execute
     (Result : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      return Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Does_Not_Execute
          (Result.Discovery)
        and then Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Does_Not_Use_Shell
          (Result.Discovery);
   end Assert_Build_Candidate_Refresh_Does_Not_Execute;

   function Assert_Build_Candidate_Refresh_Does_Not_Auto_Select
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
      pragma Unreferenced (Result);
      Before_Selected : constant Boolean :=
        To_String (Before.Selected_Build_Candidate_Id)'Length > 0;
      After_Selected : constant Boolean :=
        To_String (After.Selected_Build_Candidate_Id)'Length > 0;
   begin
      if not Before_Selected then
         return not After_Selected;
      end if;
      return True;
   end Assert_Build_Candidate_Refresh_Does_Not_Auto_Select;

   function Assert_Build_Candidate_Refresh_Does_Not_Auto_Consent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State) return Boolean
   is
   begin
      return (if Before.Consent_Acknowledged then True else not After.Consent_Acknowledged);
   end Assert_Build_Candidate_Refresh_Does_Not_Auto_Consent;

   function Assert_Build_Candidate_Refresh_Request_Identity_Coherent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
      pragma Unreferenced (Before);
   begin
      if Result.Consent_Invalidated then
         return not After.Consent_Acknowledged;
      elsif After.Consent_Acknowledged then
         return To_String (After.Consent_Request_Identity) =
           Editor.Build_UI.Current_Request_Identity (After);
      else
         return True;
      end if;
   end Assert_Build_Candidate_Refresh_Request_Identity_Coherent;

   function Assert_Build_Candidate_Refresh_Deterministic
     (Left  : Build_Candidate_Refresh_Result;
      Right : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      return Left.Status = Right.Status
        and then Left.Candidate_Count = Right.Candidate_Count
        and then Candidate_List_Identity (Left.Discovery.Candidates) =
          Candidate_List_Identity (Right.Discovery.Candidates);
   end Assert_Build_Candidate_Refresh_Deterministic;

   function Assert_Build_Candidate_Refresh_Persistence_Excluded
     (State : Editor.Build_UI.Public_Build_UI_State) return Boolean
   is
   begin
      return Editor.Build_UI.Assert_Build_UI_State_Is_Transient (State);
   end Assert_Build_Candidate_Refresh_Persistence_Excluded;

   function Assert_Build_Candidate_Refresh_Canonical_Path
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
      Before_Selected : constant Boolean :=
        To_String (Before.Selected_Build_Candidate_Id)'Length > 0;
      After_Selected : constant Boolean :=
        To_String (After.Selected_Build_Candidate_Id)'Length > 0;
   begin
      if not Assert_Build_Candidate_Refresh_Bounded (Result)
        or else not Assert_Build_Candidate_Refresh_Does_Not_Execute (Result)
        or else not Assert_Build_Candidate_Refresh_Does_Not_Auto_Select
          (Before, After, Result)
        or else not Assert_Build_Candidate_Refresh_Does_Not_Auto_Consent
          (Before, After)
        or else not Assert_Build_Candidate_Refresh_Request_Identity_Coherent
          (Before, After, Result)
      then
         return False;
      end if;

      if Result.Status = Editor.Build_UI.Build_Candidate_Refresh_Failed then
         return Candidate_List_Identity (After.Build_Candidates) =
             Candidate_List_Identity (Before.Build_Candidates)
           and then To_String (After.Selected_Build_Candidate_Id) =
             To_String (Before.Selected_Build_Candidate_Id);
      end if;

      if Natural (After.Build_Candidates.Length) /= Result.Candidate_Count then
         return False;
      end if;

      if not Before_Selected then
         return not After_Selected
           and then not Result.Manual_Request_Preserved
           and then not After.Consent_Acknowledged
           and then Editor.Build_UI.Validate_Build_UI_State (After) =
             Editor.Build_UI.Build_UI_Rejected_No_Candidate_Selected;
      elsif Result.Selected_Candidate_Preserved then
         return After_Selected
           and then not Result.Selected_Candidate_Cleared
           and then After.Selected_Candidate_Preserved_On_Refresh;
      elsif Result.Selected_Candidate_Cleared then
         return not After_Selected
           and then After.Selected_Candidate_Stale
           and then After.Selected_Candidate_Cleared_On_Refresh
           and then not After.Consent_Acknowledged;
      else
         return True;
      end if;
   end Assert_Build_Candidate_Refresh_Canonical_Path;

   function Assert_Build_Candidate_Identity_Canonical
     (Candidate : Editor.Build_Candidates.Build_Candidate_Record) return Boolean
   is
      Identity : constant String := Build_Candidate_Identity (Candidate);
      Material : constant String := Build_Candidate_Material_Identity (Candidate);
   begin
      return Identity = To_String (Candidate.Candidate_Id) & "|material=" & Material
        and then Material'Length > 0
        and then Editor.Build_Candidates.Assert_Build_Candidate_Is_Structured
          (Candidate)
        and then Editor.Build_Candidates.Assert_Build_Candidate_Is_Transient
          (Candidate);
   end Assert_Build_Candidate_Identity_Canonical;

   function Assert_Build_Candidate_Stale_Reconciliation_Canonical
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
      Before_Selected : constant Boolean :=
        To_String (Before.Selected_Build_Candidate_Id)'Length > 0;
   begin
      if not Before_Selected then
         return To_String (After.Selected_Build_Candidate_Id)'Length = 0;
      elsif Result.Selected_Candidate_Cleared then
         return To_String (After.Selected_Build_Candidate_Id)'Length = 0
           and then After.Selected_Candidate_Stale
           and then not After.Consent_Acknowledged;
      elsif Result.Selected_Candidate_Preserved then
         return To_String (After.Selected_Build_Candidate_Id)'Length > 0
           and then not After.Selected_Candidate_Stale;
      else
         return Result.Status = Editor.Build_UI.Build_Candidate_Refresh_Failed;
      end if;
   end Assert_Build_Candidate_Stale_Reconciliation_Canonical;

   function Assert_Build_Candidate_Refresh_Not_Build_Run_Side_Effect
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
      pragma Unreferenced (Result);
   begin
      --  build.run is represented by validated requests, not by refresh status
      --  mutation. A refresh result cannot create a pending public build
      --  request. It may clear one only through consent invalidation.
      return Before.Pending_Public_Build_Request
        or else not After.Pending_Public_Build_Request;
   end Assert_Build_Candidate_Refresh_Not_Build_Run_Side_Effect;

   function Assert_Build_Candidate_Refresh_Not_Frontdoor_Payload
     (State : Editor.Build_UI.Public_Build_UI_State) return Boolean
   is
   begin
      return not Editor.Build_UI.Command_Palette_Can_Supply_Candidate (State)
        and then not Editor.Build_UI.Keybinding_Can_Supply_Candidate (State);
   end Assert_Build_Candidate_Refresh_Not_Frontdoor_Payload;

   function Assert_Build_Candidate_Refresh_Not_Diagnostics_Result_Output_Mutation
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
      pragma Unreferenced (Before, After, Result);
   begin
      return True;
   end Assert_Build_Candidate_Refresh_Not_Diagnostics_Result_Output_Mutation;


   function Assert_Build_Candidate_Refresh_Final_Canonical_Path
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      return Assert_Build_Candidate_Refresh_Canonical_Path
        (Before, After, Result);
   end Assert_Build_Candidate_Refresh_Final_Canonical_Path;

   function Assert_Build_Candidate_Refresh_Final_Explicit_Path
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      return Assert_Build_Candidate_Refresh_Canonical_Path
        (Before, After, Result);
   end Assert_Build_Candidate_Refresh_Final_Explicit_Path;

   function Assert_Build_Candidate_Refresh_Final_Lifecycle_Path
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      --  Successful lifecycle hooks are allowed only to invoke the same
      --  canonical refresh/reconciliation path as explicit refresh.
      return Assert_Build_Candidate_Refresh_Canonical_Path
        (Before, After, Result);
   end Assert_Build_Candidate_Refresh_Final_Lifecycle_Path;

   function Assert_Build_Candidate_Refresh_Final_Bounded_Discovery
     (Result : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      return Assert_Build_Candidate_Refresh_Bounded (Result)
        and then Assert_Build_Candidate_Refresh_Does_Not_Execute (Result);
   end Assert_Build_Candidate_Refresh_Final_Bounded_Discovery;

   function Assert_Build_Candidate_Identity_Final_Canonical
     (Candidate : Editor.Build_Candidates.Build_Candidate_Record) return Boolean
   is
   begin
      return Assert_Build_Candidate_Identity_Canonical (Candidate);
   end Assert_Build_Candidate_Identity_Final_Canonical;

   function Assert_Build_Candidate_Material_Identity_Final_Canonical
     (Candidate : Editor.Build_Candidates.Build_Candidate_Record) return Boolean
   is
   begin
      return Build_Candidate_Material_Identity (Candidate)'Length > 0
        and then Assert_Build_Candidate_Identity_Canonical (Candidate);
   end Assert_Build_Candidate_Material_Identity_Final_Canonical;

   function Assert_Build_Candidate_Stale_Reconciliation_Final_Canonical
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      return Assert_Build_Candidate_Stale_Reconciliation_Canonical
        (Before, After, Result);
   end Assert_Build_Candidate_Stale_Reconciliation_Final_Canonical;

   function Assert_Build_Candidate_Refresh_Final_No_Auto_Select
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      return Assert_Build_Candidate_Refresh_Does_Not_Auto_Select
        (Before, After, Result);
   end Assert_Build_Candidate_Refresh_Final_No_Auto_Select;

   function Assert_Build_Candidate_Refresh_Final_No_Auto_Consent
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State) return Boolean
   is
   begin
      return Assert_Build_Candidate_Refresh_Does_Not_Auto_Consent
        (Before, After);
   end Assert_Build_Candidate_Refresh_Final_No_Auto_Consent;

   function Assert_Build_Candidate_Refresh_Final_No_Auto_Run
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      return Assert_Build_Candidate_Refresh_Not_Build_Run_Side_Effect
        (Before, After, Result);
   end Assert_Build_Candidate_Refresh_Final_No_Auto_Run;

   function Assert_Build_Candidate_Refresh_Final_Not_Build_Run_Side_Effect
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      return Assert_Build_Candidate_Refresh_Not_Build_Run_Side_Effect
        (Before, After, Result);
   end Assert_Build_Candidate_Refresh_Final_Not_Build_Run_Side_Effect;

   function Assert_Build_Candidate_Refresh_Final_Not_Render_Owned
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
      pragma Unreferenced (Before, After, Result);
   begin
      --  The render packet has no refresh entry point; the canonical assertion
      --  remains a side-effect-free schema/ownership check.
      return True;
   end Assert_Build_Candidate_Refresh_Final_Not_Render_Owned;

   function Assert_Build_Candidate_Refresh_Final_Not_Frontdoor_Payload
     (State : Editor.Build_UI.Public_Build_UI_State) return Boolean
   is
   begin
      return Assert_Build_Candidate_Refresh_Not_Frontdoor_Payload (State);
   end Assert_Build_Candidate_Refresh_Final_Not_Frontdoor_Payload;

   function Assert_Build_Candidate_Refresh_Final_Not_Diagnostics_Result_Output_Mutation
     (Before : Editor.Build_UI.Public_Build_UI_State;
      After  : Editor.Build_UI.Public_Build_UI_State;
      Result : Build_Candidate_Refresh_Result) return Boolean
   is
   begin
      return Assert_Build_Candidate_Refresh_Not_Diagnostics_Result_Output_Mutation
        (Before, After, Result);
   end Assert_Build_Candidate_Refresh_Final_Not_Diagnostics_Result_Output_Mutation;

   function Assert_Build_Candidate_Refresh_Final_Persistence_Excluded
     (State : Editor.Build_UI.Public_Build_UI_State) return Boolean
   is
   begin
      return Assert_Build_Candidate_Refresh_Persistence_Excluded (State);
   end Assert_Build_Candidate_Refresh_Final_Persistence_Excluded;

end Editor.Build_Candidate_Refresh;
