with Ada.Strings.Unbounded;
with Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies;
with Editor.Missing_Stale_Recovery.Recovery_Policies;
with Editor.Missing_Stale_Recovery.Surface_Event_Policies;
with Editor.Missing_Stale_Recovery.Target_Messages;

package body Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies is

   use Ada.Strings.Unbounded;

   function Surface_Label (Surface : Target_Surface) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Surface_Label;

   function Availability_Reason (State : Target_Availability_State) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Availability_Reason;

   function Target_Outcome_Message
     (Result : Target_Validation_Result) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Target_Outcome_Message;

   function Recovery_Command_Replaces_Stale_Surface
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_Replaces_Stale_Surface;

   function Recovery_Command_Is_Payload_Free
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_Is_Payload_Free;

   function Recovery_Command_Is_Explicit
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_Is_Explicit;

   function Recovery_Command_Routes_Through_Executor
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_Routes_Through_Executor;

   function Recovery_Attempt_Disposition
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Outcome : Recovery_Attempt_Outcome) return Recovery_State_Disposition
   is
   begin
      if Outcome /= Recovery_Succeeded then
         return Recovery_State_Unchanged;
      end if;

      if not Recovery_Command_Replaces_Stale_Surface (Command, Surface) then
         return Recovery_State_Unchanged;
      end if;

      case Command is
         when Recovery_File_Tree_Refresh |
              Recovery_Project_Search_Run |
              Recovery_Outline_Refresh |
              Recovery_Build_Refresh_Candidates |
              Recovery_Workspace_Load =>
            return Recovery_State_Replaced;
         when Recovery_Quick_Open_Clear_Query |
              Recovery_Project_Search_Clear_Results |
              Recovery_Project_Search_Replace_Clear_Preview |
              Recovery_Diagnostics_Clear |
              Recovery_Recent_Projects_Remove_Missing =>
            return Recovery_State_Cleared;
         when Recovery_File_Reload_From_Disk |
              Recovery_File_Revert_Buffer |
              Recovery_File_Reveal_Active_In_Tree =>
            return Recovery_State_Unchanged;
      end case;
   end Recovery_Attempt_Disposition;

   function Recovery_Attempt_Outcome_Label
     (Outcome : Recovery_Attempt_Outcome) return String
   is
   begin
      case Outcome is
         when Recovery_Not_Attempted => return "Recovery not attempted.";
         when Recovery_Succeeded     => return "Recovery completed.";
         when Recovery_Failed        => return "Recovery failed; existing state preserved.";
         when Recovery_Cancelled     => return "Recovery cancelled; existing state preserved.";
      end case;
   end Recovery_Attempt_Outcome_Label;

   function Recovery_Attempt_May_Clear_State
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Outcome : Recovery_Attempt_Outcome) return Boolean
   is
      Disposition : constant Recovery_State_Disposition :=
        Recovery_Attempt_Disposition (Command, Surface, Outcome);
   begin
      return Disposition = Recovery_State_Cleared
        or else Disposition = Recovery_State_Replaced;
   end Recovery_Attempt_May_Clear_State;

   function Recovery_Attempt_Message_May_Embed_Path
     (Command : Recovery_Command_Kind;
      Outcome : Recovery_Attempt_Outcome) return Boolean
   is
      pragma Unreferenced (Command, Outcome);
   begin
      return False;
   end Recovery_Attempt_Message_May_Embed_Path;

   function Recovery_Attempt_Produces_One_Primary_Outcome
     (Command : Recovery_Command_Kind;
      Outcome : Recovery_Attempt_Outcome) return Boolean
   is
      pragma Unreferenced (Command, Outcome);
   begin
      return True;
   end Recovery_Attempt_Produces_One_Primary_Outcome;

   function Recovery_Attempt_Preserves_Dirty_Text
     (Command : Recovery_Command_Kind;
      Outcome : Recovery_Attempt_Outcome) return Boolean
   is
      pragma Unreferenced (Command, Outcome);
   begin
      return True;
   end Recovery_Attempt_Preserves_Dirty_Text;

   function Recovery_Command_Effect_Allowed
     (Command : Recovery_Command_Kind;
      Effect  : Recovery_Command_Effect_Kind;
      Source  : Command_Invocation_Source := Invocation_Executor) return Boolean
   is
   begin
      if Source /= Invocation_Executor then
         return False;
      end if;

      case Effect is
         when Effect_Probe_Filesystem |
              Effect_Mutate_Owning_Surface =>
            return True;
         when Effect_Reload_Buffer =>
            return Command = Recovery_File_Reload_From_Disk;
         when Effect_Revert_Buffer =>
            return Command = Recovery_File_Revert_Buffer;
         when Effect_Open_Target =>
            return Command = Recovery_Workspace_Load;
         when Effect_Run_Build |
              Effect_Write_Persistence |
              Effect_Delete_User_File |
              Effect_Create_Project_Context |
              Effect_Clear_Other_Surface =>
            return False;
      end case;
   end Recovery_Command_Effect_Allowed;

   function Recovery_Command_May_Write_Persistence
     (Command : Recovery_Command_Kind) return Boolean
   is
      pragma Unreferenced (Command);
   begin
      return False;
   end Recovery_Command_May_Write_Persistence;

   function Recovery_Command_May_Open_Target
     (Command : Recovery_Command_Kind) return Boolean
   is
   begin
      return Recovery_Command_Effect_Allowed
        (Command, Effect_Open_Target, Invocation_Executor);
   end Recovery_Command_May_Open_Target;

   function Recovery_Command_May_Clear_Other_Surface
     (Command : Recovery_Command_Kind) return Boolean
   is
      pragma Unreferenced (Command);
   begin
      return False;
   end Recovery_Command_May_Clear_Other_Surface;

   function Recovery_Command_Effect_Label
     (Effect : Recovery_Command_Effect_Kind) return String
   is
   begin
      case Effect is
         when Effect_Probe_Filesystem =>
            return "probe filesystem";
         when Effect_Mutate_Owning_Surface =>
            return "update owning surface";
         when Effect_Write_Persistence =>
            return "write persistence";
         when Effect_Open_Target =>
            return "open validated target";
         when Effect_Reload_Buffer =>
            return "reload buffer";
         when Effect_Revert_Buffer =>
            return "revert buffer";
         when Effect_Run_Build =>
            return "run build";
         when Effect_Delete_User_File =>
            return "delete user file";
         when Effect_Create_Project_Context =>
            return "create project context";
         when Effect_Clear_Other_Surface =>
            return "clear unrelated surface";
      end case;
   end Recovery_Command_Effect_Label;

   function Recovery_Command_Postcondition
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Outcome : Recovery_Attempt_Outcome) return Recovery_Postcondition
   is
   begin
      if Outcome /= Recovery_Succeeded then
         return Postcondition_No_Target_Use;
      elsif not Recovery_Command_Replaces_Stale_Surface (Command, Surface) then
         return Postcondition_No_Target_Use;
      end if;

      case Command is
         when Recovery_Quick_Open_Clear_Query
            | Recovery_Project_Search_Clear_Results
            | Recovery_Project_Search_Replace_Clear_Preview
            | Recovery_Diagnostics_Clear
            | Recovery_Recent_Projects_Remove_Missing =>
            return Postcondition_Surface_Cleared;
         when Recovery_File_Tree_Refresh
            | Recovery_Project_Search_Run
            | Recovery_Outline_Refresh
            | Recovery_Build_Refresh_Candidates
            | Recovery_Workspace_Load
            | Recovery_File_Reload_From_Disk
            | Recovery_File_Revert_Buffer
            | Recovery_File_Reveal_Active_In_Tree =>
            return Postcondition_Revalidate_Before_Use;
      end case;
   end Recovery_Command_Postcondition;

   function Recovery_Postcondition_Label
     (Postcondition : Recovery_Postcondition) return String
   is
   begin
      case Postcondition is
         when Postcondition_Revalidate_Before_Use =>
            return "Recovery completed; revalidate target before use.";
         when Postcondition_Surface_Replaced =>
            return "Recovery replaced the owning surface.";
         when Postcondition_Surface_Cleared =>
            return "Recovery cleared the owning surface.";
         when Postcondition_No_Target_Use =>
            return "Recovery did not authorize target use.";
      end case;
   end Recovery_Postcondition_Label;

   function Recovery_Command_May_Immediately_Consume_Recovered_Target
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Outcome : Recovery_Attempt_Outcome) return Boolean
   is
      pragma Unreferenced (Command, Surface, Outcome);
   begin
      return False;
   end Recovery_Command_May_Immediately_Consume_Recovered_Target;

   function Recovery_Command_Result_Requires_Revalidation_Before_Target_Use
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Outcome : Recovery_Attempt_Outcome) return Boolean
   is
   begin
      return Recovery_Command_Postcondition (Command, Surface, Outcome) =
        Postcondition_Revalidate_Before_Use
        and then not Recovery_Command_May_Immediately_Consume_Recovered_Target
          (Command, Surface, Outcome);
   end Recovery_Command_Result_Requires_Revalidation_Before_Target_Use;

   function Stale_Surface_Lifecycle_Action_Allowed
     (Surface : Target_Surface;
      Action  : Stale_Surface_Lifecycle_Action) return Boolean
   is
      pragma Unreferenced (Surface);
   begin
      case Action is
         when Lifecycle_Mark_Stale |
              Lifecycle_Display_Marker |
              Lifecycle_Block_Target_Use |
              Lifecycle_Offer_Recovery_Hint |
              Lifecycle_Clear_By_Explicit_Recovery =>
            return True;
         when Lifecycle_Persist_Marker |
              Lifecycle_Auto_Refresh |
              Lifecycle_Auto_Rerun |
              Lifecycle_Open_Target =>
            return False;
      end case;
   end Stale_Surface_Lifecycle_Action_Allowed;

   function Stale_Surface_Lifecycle_Action_Label
     (Action : Stale_Surface_Lifecycle_Action) return String
   is
   begin
      case Action is
         when Lifecycle_Mark_Stale =>
            return "mark stale";
         when Lifecycle_Display_Marker =>
            return "display stale marker";
         when Lifecycle_Block_Target_Use =>
            return "block target use";
         when Lifecycle_Offer_Recovery_Hint =>
            return "offer recovery hint";
         when Lifecycle_Clear_By_Explicit_Recovery =>
            return "clear by explicit recovery";
         when Lifecycle_Persist_Marker =>
            return "persist stale marker";
         when Lifecycle_Auto_Refresh =>
            return "auto refresh";
         when Lifecycle_Auto_Rerun =>
            return "auto rerun";
         when Lifecycle_Open_Target =>
            return "open target";
      end case;
   end Stale_Surface_Lifecycle_Action_Label;

   function Stale_Surface_Lifecycle_Action_Is_Transient
     (Action : Stale_Surface_Lifecycle_Action) return Boolean
   is
   begin
      return Action /= Lifecycle_Persist_Marker;
   end Stale_Surface_Lifecycle_Action_Is_Transient;

   function Stale_Surface_Lifecycle_Action_May_Use_Payload
     (Action : Stale_Surface_Lifecycle_Action) return Boolean
   is
      pragma Unreferenced (Action);
   begin
      return False;
   end Stale_Surface_Lifecycle_Action_May_Use_Payload;

   function Stale_Surface_Lifecycle_Requires_Executor_Recovery
     (Surface : Target_Surface) return Boolean
   is
      pragma Unreferenced (Surface);
   begin
      return True;
   end Stale_Surface_Lifecycle_Requires_Executor_Recovery;

   function Multi_Target_Command_Requires_Full_Preflight
     (Command : Multi_Target_Command_Kind) return Boolean
   is
      pragma Unreferenced (Command);
   begin
      return True;
   end Multi_Target_Command_Requires_Full_Preflight;

   function Multi_Target_Command_May_Mutate_Before_Preflight
     (Command : Multi_Target_Command_Kind) return Boolean
   is
      pragma Unreferenced (Command);
   begin
      return False;
   end Multi_Target_Command_May_Mutate_Before_Preflight;

   function Multi_Target_Validation_Allows_Mutation
     (Summary : Multi_Target_Validation_Summary) return Boolean
   is
   begin
      return Summary.Missing_Targets = 0
        and then Summary.Stale_Targets = 0
        and then Summary.Outside_Project = 0
        and then Summary.Unreadable_Targets = 0
        and then Summary.Out_Of_Range_Targets = 0;
   end Multi_Target_Validation_Allows_Mutation;

   function Multi_Target_Validation_Message
     (Summary : Multi_Target_Validation_Summary) return String
   is
      Invalid : constant Natural :=
        Summary.Missing_Targets
        + Summary.Stale_Targets
        + Summary.Outside_Project
        + Summary.Unreadable_Targets
        + Summary.Out_Of_Range_Targets;
   begin
      if Invalid = 0 then
         return "All target references validated.";
      elsif Summary.Stale_Targets > 0 then
         return "Some targets are stale; refresh or rerun before applying.";
      elsif Summary.Missing_Targets > 0 then
         return "Some targets no longer exist; command not applied.";
      elsif Summary.Outside_Project > 0 then
         return "Some targets are outside the current project; command not applied.";
      elsif Summary.Unreadable_Targets > 0 then
         return "Some target files are not readable; command not applied.";
      else
         return "Some target lines are unavailable; command not applied.";
      end if;
   end Multi_Target_Validation_Message;

   function Multi_Target_Validation_Message_May_Embed_Paths
     (Summary : Multi_Target_Validation_Summary) return Boolean
   is
      pragma Unreferenced (Summary);
   begin
      return False;
   end Multi_Target_Validation_Message_May_Embed_Paths;

   function Multi_Target_Recovery_Preserves_Existing_State_On_Failure
     (Command : Multi_Target_Command_Kind;
      Summary : Multi_Target_Validation_Summary) return Boolean
   is
      pragma Unreferenced (Command);
   begin
      return not Multi_Target_Validation_Allows_Mutation (Summary);
   end Multi_Target_Recovery_Preserves_Existing_State_On_Failure;

   function Recovery_Command_May_Delete_User_File
     (Command : Recovery_Command_Kind) return Boolean
   is
      pragma Unreferenced (Command);
   begin
      return False;
   end Recovery_Command_May_Delete_User_File;

   function Recovery_Command_May_Fabricate_Project_State
     (Command : Recovery_Command_Kind) return Boolean
   is
      pragma Unreferenced (Command);
   begin
      return False;
   end Recovery_Command_May_Fabricate_Project_State;

   function Recovery_Message_May_Embed_Target_Payload
     (Result : Target_Validation_Result) return Boolean
   is
      pragma Unreferenced (Result);
   begin
      return False;
   end Recovery_Message_May_Embed_Target_Payload;

   function Recovery_Message_Identifies_Surface_And_Category
     (Result : Target_Validation_Result) return Boolean
   is
   begin
      return Surface_Label (Result.Surface)'Length > 0
        and then Availability_Reason (Result.State)'Length > 0
        and then Target_Outcome_Message (Result)'Length > 0
        and then not Recovery_Message_May_Embed_Target_Payload (Result);
   end Recovery_Message_Identifies_Surface_And_Category;

   function Recovery_Action_Is_Safe_For_State
     (Command : Recovery_Command_Kind;
      Result  : Target_Validation_Result) return Boolean
   is
   begin
      if Result.State = Target_Available then
         return True;
      elsif Result.State = Target_Command_Pending then
         return False;
      end if;

      return Recovery_Command_Is_Explicit (Command)
        and then Recovery_Command_Is_Payload_Free (Command)
        and then Recovery_Command_Routes_Through_Executor (Command)
        and then Editor.Missing_Stale_Recovery.Surface_Event_Policies
          .Recovery_Command_Can_Address_Result (Command, Result)
        and then not Recovery_Command_May_Delete_User_File (Command)
        and then not Recovery_Command_May_Fabricate_Project_State (Command)
        and then not Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies
          .Recovery_Command_Available_With_Confirmation_Pending (Command);
   end Recovery_Action_Is_Safe_For_State;

   function Target_State_Has_Explicit_Recovery_Path
     (Surface : Target_Surface;
      State   : Target_Availability_State) return Boolean
   is
      Result : constant Target_Validation_Result :=
        (State   => State,
         Surface => Surface,
         Path    => To_Unbounded_String (""),
         Line    => 0,
         Column  => 0);
      Command : constant Recovery_Command_Kind :=
        Editor.Missing_Stale_Recovery.Surface_Event_Policies
          .Recovery_Command_For_Surface (Surface);
   begin
      case State is
         when Target_Available | Target_No_Result_Selected |
              Target_No_Diagnostic_Selected | Target_No_Build_Candidate_Selected |
              Target_Command_Pending | Target_Outside_Project |
              Target_Source_Less =>
            return False;
         when others =>
            return Recovery_Action_Is_Safe_For_State (Command, Result);
      end case;
   end Target_State_Has_Explicit_Recovery_Path;

end Editor.Missing_Stale_Recovery.Recovery_Lifecycle_Policies;
