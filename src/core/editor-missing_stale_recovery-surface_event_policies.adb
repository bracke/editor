with Editor.Missing_Stale_Recovery.Recovery_Policies;
with Editor.Missing_Stale_Recovery.Target_Messages;

package body Editor.Missing_Stale_Recovery.Surface_Event_Policies is

   function Target_Outcome_Message
     (Result : Target_Validation_Result) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Target_Outcome_Message;

   function Recovery_Command_Is_Payload_Free
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_Is_Payload_Free;

   function Recovery_Command_Is_Explicit
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_Is_Explicit;

   function Recovery_Command_Replaces_Stale_Surface
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_Replaces_Stale_Surface;

   function Recovery_Command_Routes_Through_Executor
     (Command : Recovery_Command_Kind) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_Routes_Through_Executor;

   function Missing_Target_May_Create_Implicit_File
     (Surface : Target_Surface) return Boolean
   is
      pragma Unreferenced (Surface);
   begin
      return False;
   end Missing_Target_May_Create_Implicit_File;

   function Failed_Target_Use_Preserves_User_Text
     (Use_Kind   : Target_Use_Kind;
      State : Target_Availability_State) return Boolean
   is
   begin
      if State = Target_Available then
         return True;
      end if;

      case Use_Kind is
         when Use_Save_Target
            | Use_Reload_Target
            | Use_Revert_Target
            | Use_Open_Target =>
            return State in Target_Missing
              | Target_Parent_Directory_Missing
              | Target_Unreadable
              | Target_Unwritable
              | Target_Reload_Required
              | Target_Stale
              | Target_Outside_Project;
         when Use_Reveal_Target
            | Use_Navigate_Target
            | Use_Apply_Replace_Target
            | Use_Run_Build_Target =>
            return True;
      end case;
   end Failed_Target_Use_Preserves_User_Text;

   function Target_Use_Failure_May_Discard_User_Text
     (Use_Kind   : Target_Use_Kind;
      State : Target_Availability_State) return Boolean
   is
   begin
      return not Failed_Target_Use_Preserves_User_Text (Use_Kind, State);
   end Target_Use_Failure_May_Discard_User_Text;

   function Target_Validation_Failure_May_Mutate_State
     (Result : Target_Validation_Result) return Boolean
   is
   begin
      return Result.State = Target_Available;
   end Target_Validation_Failure_May_Mutate_State;

   function Target_Validation_Failure_Disposition
     (Result : Target_Validation_Result) return Validation_Failure_Disposition
   is
   begin
      if Result.State = Target_Available then
         return Failure_Preserves_Surface_State;
      elsif Result.State in Target_Stale
        | Target_Refresh_Required
        | Target_Reload_Required
        | Target_Candidate_Stale
        | Target_Preview_Stale
      then
         return Failure_Marks_Surface_Stale;
      else
         return Failure_Preserves_Surface_State;
      end if;
   end Target_Validation_Failure_Disposition;

   function Validation_Failure_Disposition_Label
     (Disposition : Validation_Failure_Disposition) return String
   is
   begin
      case Disposition is
         when Failure_Preserves_Surface_State =>
            return "preserve existing surface state";
         when Failure_Marks_Surface_Stale =>
            return "mark target stale and require explicit recovery";
         when Failure_Clears_Nothing =>
            return "clear no state automatically";
      end case;
   end Validation_Failure_Disposition_Label;

   function Recovery_Command_Failed_Attempt_Clears_Stale_State
     (Command : Recovery_Command_Kind) return Boolean
   is
      pragma Unreferenced (Command);
   begin
      return False;
   end Recovery_Command_Failed_Attempt_Clears_Stale_State;

   function Stale_Target_User_Action_Hint
     (Surface : Target_Surface) return String
   is
   begin
      case Surface is
         when Workspace_Surface =>
            return "load workspace explicitly";
         when Recent_Project_Surface =>
            return "remove unavailable recent project";
         when Buffer_Surface =>
            return "reload or save explicitly";
         when File_Tree_Surface =>
            return "refresh File Tree";
         when Quick_Open_Surface =>
            return "clear or requery Quick Open";
         when Project_Search_Surface =>
            return "rerun search";
         when Replace_Preview_Surface =>
            return "rerun search before replace";
         when Outline_Surface =>
            return "refresh Outline";
         when Diagnostics_Surface =>
            return "clear or regenerate Diagnostics";
         when Build_Surface =>
            return "refresh build candidates";
      end case;
   end Stale_Target_User_Action_Hint;

   function Project_Transition_Surface_Disposition
     (Surface : Target_Surface) return String
   is
   begin
      case Surface is
         when File_Tree_Surface =>
            return "clear File Tree snapshot";
         when Quick_Open_Surface =>
            return "clear Quick Open query and results";
         when Project_Search_Surface =>
            return "clear Project Search results";
         when Replace_Preview_Surface =>
            return "clear replace preview";
         when Outline_Surface =>
            return "clear Outline rows";
         when Diagnostics_Surface =>
            return "clear project diagnostics";
         when Build_Surface =>
            return "clear Build candidates, request, consent, result and output";
         when Workspace_Surface =>
            return "preserve workspace persistence domain";
         when Recent_Project_Surface =>
            return "preserve recent project references";
         when Buffer_Surface =>
            return "preserve guarded dirty buffers";
      end case;
   end Project_Transition_Surface_Disposition;

   function Event_Effect_On_Surface
     (Event   : Recovery_Event_Kind;
      Surface : Target_Surface) return Surface_Event_Effect
   is
   begin
      case Event is
         when Event_Buffer_Edited | Event_Buffer_Reloaded =>
            case Surface is
               when Project_Search_Surface | Outline_Surface | Diagnostics_Surface =>
                  return Surface_Marked_Stale;
               when Replace_Preview_Surface =>
                  return Surface_Marked_Stale;
               when others =>
                  return Surface_Unchanged;
            end case;
         when Event_Project_Switched | Event_Project_Closed =>
            case Surface is
               when File_Tree_Surface | Quick_Open_Surface | Project_Search_Surface |
                    Replace_Preview_Surface | Outline_Surface | Diagnostics_Surface |
                    Build_Surface =>
                  return Surface_Cleared;
               when Buffer_Surface | Workspace_Surface | Recent_Project_Surface =>
                  return Surface_Unchanged;
            end case;
         when Event_File_Tree_Refreshed =>
            return (if Surface = File_Tree_Surface then Surface_Replaced else Surface_Unchanged);
         when Event_Quick_Open_Requeried =>
            return (if Surface = Quick_Open_Surface then Surface_Replaced else Surface_Unchanged);
         when Event_Project_Search_Rerun =>
            if Surface = Project_Search_Surface then
               return Surface_Replaced;
            elsif Surface = Replace_Preview_Surface then
               return Surface_Cleared;
            else
               return Surface_Unchanged;
            end if;
         when Event_Replace_Preview_Cleared =>
            return (if Surface = Replace_Preview_Surface then Surface_Cleared else Surface_Unchanged);
         when Event_Outline_Refreshed =>
            return (if Surface = Outline_Surface then Surface_Replaced else Surface_Unchanged);
         when Event_Diagnostics_Cleared =>
            return (if Surface = Diagnostics_Surface then Surface_Cleared else Surface_Unchanged);
         when Event_Build_Candidates_Refreshed =>
            return (if Surface = Build_Surface then Surface_Replaced else Surface_Unchanged);
      end case;
   end Event_Effect_On_Surface;

   function Event_Effect_Label
     (Effect : Surface_Event_Effect) return String
   is
   begin
      case Effect is
         when Surface_Unchanged    => return "unchanged";
         when Surface_Marked_Stale => return "marked stale";
         when Surface_Cleared      => return "cleared";
         when Surface_Replaced     => return "replaced by explicit refresh";
         when Surface_Ignored      => return "ignored";
      end case;
   end Event_Effect_Label;

   function Event_State_After
     (Event   : Recovery_Event_Kind;
      Surface : Target_Surface) return Target_Availability_State
   is
      Effect : constant Surface_Event_Effect :=
        Event_Effect_On_Surface (Event, Surface);
   begin
      case Effect is
         when Surface_Marked_Stale =>
            case Surface is
               when Outline_Surface =>
                  return Target_Refresh_Required;
               when Replace_Preview_Surface =>
                  return Target_Preview_Stale;
               when Diagnostics_Surface | Project_Search_Surface =>
                  return Target_Stale;
               when others =>
                  return Target_Stale;
            end case;
         when Surface_Cleared | Surface_Replaced | Surface_Unchanged | Surface_Ignored =>
            return Target_Available;
      end case;
   end Event_State_After;

   function Event_May_Create_Files
     (Event : Recovery_Event_Kind) return Boolean
   is
      pragma Unreferenced (Event);
   begin
      return False;
   end Event_May_Create_Files;

   function Event_May_Bypass_Executor
     (Event : Recovery_Event_Kind) return Boolean
   is
      pragma Unreferenced (Event);
   begin
      return False;
   end Event_May_Bypass_Executor;

   function Surface_Event_Effect_Is_Transient
     (Effect : Surface_Event_Effect) return Boolean
   is
   begin
      return Effect /= Surface_Unchanged;
   end Surface_Event_Effect_Is_Transient;

   function Recovery_Command_For_Surface
     (Surface : Target_Surface) return Recovery_Command_Kind
   is
   begin
      case Surface is
         when Workspace_Surface =>
            return Recovery_Workspace_Load;
         when Recent_Project_Surface =>
            return Recovery_Recent_Projects_Remove_Missing;
         when Buffer_Surface =>
            return Recovery_File_Reload_From_Disk;
         when File_Tree_Surface =>
            return Recovery_File_Tree_Refresh;
         when Quick_Open_Surface =>
            return Recovery_Quick_Open_Clear_Query;
         when Project_Search_Surface =>
            return Recovery_Project_Search_Run;
         when Replace_Preview_Surface =>
            return Recovery_Project_Search_Replace_Clear_Preview;
         when Outline_Surface =>
            return Recovery_Outline_Refresh;
         when Diagnostics_Surface =>
            return Recovery_Diagnostics_Clear;
         when Build_Surface =>
            return Recovery_Build_Refresh_Candidates;
      end case;
   end Recovery_Command_For_Surface;

   function Recovery_Command_Can_Address_Result
     (Command : Recovery_Command_Kind;
      Result  : Target_Validation_Result) return Boolean
   is
   begin
      return Result.State /= Target_Available
        and then Recovery_Command_Is_Explicit (Command)
        and then Recovery_Command_Is_Payload_Free (Command)
        and then Recovery_Command_Routes_Through_Executor (Command)
        and then Recovery_Command_Replaces_Stale_Surface (Command, Result.Surface);
   end Recovery_Command_Can_Address_Result;

   function Recovery_Command_Hint_Message
     (Result : Target_Validation_Result) return String
   is
      Command : constant Recovery_Command_Kind := Recovery_Command_For_Surface (Result.Surface);
   begin
      if Result.State = Target_Available then
         return Target_Outcome_Message (Result);
      elsif Recovery_Command_Can_Address_Result (Command, Result) then
         return Target_Outcome_Message (Result)
           & " Recovery: " & Stale_Target_User_Action_Hint (Result.Surface) & ".";
      else
         return Target_Outcome_Message (Result);
      end if;
   end Recovery_Command_Hint_Message;

end Editor.Missing_Stale_Recovery.Surface_Event_Policies;
