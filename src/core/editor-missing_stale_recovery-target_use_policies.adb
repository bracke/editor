with Editor.Missing_Stale_Recovery.Target_Messages;

package body Editor.Missing_Stale_Recovery.Target_Use_Policies is

   function Target_State_Blocks_Use
     (State : Target_Availability_State;
      Use_Kind   : Target_Use_Kind) return Boolean
   is
   begin
      if State = Target_Available then
         return False;
      end if;

      case State is
         when Target_Command_Pending
            | Target_No_Result_Selected
            | Target_No_Diagnostic_Selected
            | Target_No_Build_Candidate_Selected
            | Target_Source_Less
            | Target_Outside_Project
            | Target_Missing
            | Target_Parent_Directory_Missing
            | Target_Unreadable
            | Target_Unwritable
            | Target_Stale
            | Target_Refresh_Required
            | Target_Reload_Required
            | Target_Candidate_Stale
            | Target_Preview_Stale
            | Target_Working_Directory_Missing
            | Target_Line_Out_Of_Range
            | Target_Column_Out_Of_Range =>
            return True;
         when Target_Available =>
            return False;
      end case;
   end Target_State_Blocks_Use;

   function Target_Use_May_Proceed
     (Result : Target_Validation_Result;
      Use_Kind    : Target_Use_Kind) return Boolean
   is
   begin
      if Target_State_Blocks_Use (Result.State, Use_Kind) then
         return False;
      end if;

      case Use_Kind is
         when Use_Apply_Replace_Target =>
            return Result.Surface = Replace_Preview_Surface;
         when Use_Run_Build_Target =>
            return Result.Surface = Build_Surface;
         when Use_Navigate_Target =>
            return Result.Surface in Project_Search_Surface
              | Outline_Surface
              | Diagnostics_Surface
              | Quick_Open_Surface
              | File_Tree_Surface;
         when Use_Save_Target
            | Use_Reload_Target
            | Use_Revert_Target
            | Use_Reveal_Target
            | Use_Open_Target =>
            return True;
      end case;
   end Target_Use_May_Proceed;

   function Target_Use_Blocking_Message
     (Result : Target_Validation_Result;
      Use_Kind    : Target_Use_Kind) return String
   is
   begin
      if Target_Use_May_Proceed (Result, Use_Kind) then
         return "Target validated for command execution.";
      end if;

      case Use_Kind is
         when Use_Save_Target =>
            if Result.State = Target_Parent_Directory_Missing then
               return "Parent directory is unavailable.";
            elsif Result.State = Target_Unwritable then
               return "File is not writable.";
            else
               return Target_Messages.Target_Outcome_Message (Result);
            end if;
         when Use_Reload_Target | Use_Revert_Target =>
            if Result.State = Target_Missing then
               return "Could not reload file.";
            elsif Result.State = Target_Unreadable then
               return "File is not readable.";
            else
               return Target_Messages.Target_Outcome_Message (Result);
            end if;
         when Use_Apply_Replace_Target =>
            return "Replace preview is stale; rerun search.";
         when Use_Run_Build_Target =>
            return Target_Messages.Target_Outcome_Message (Result);
         when Use_Navigate_Target | Use_Reveal_Target | Use_Open_Target =>
            return Target_Messages.Target_Outcome_Message (Result);
      end case;
   end Target_Use_Blocking_Message;

   function Target_Use_Failure_Requires_Recovery_Command
     (State : Target_Availability_State;
      Use_Kind   : Target_Use_Kind) return Boolean
   is
   begin
      if not Target_State_Blocks_Use (State, Use_Kind) then
         return False;
      end if;

      case State is
         when Target_No_Result_Selected
            | Target_No_Diagnostic_Selected
            | Target_No_Build_Candidate_Selected
            | Target_Source_Less
            | Target_Command_Pending
            | Target_Outside_Project =>
            return False;
         when others =>
            return True;
      end case;
   end Target_Use_Failure_Requires_Recovery_Command;

   function Target_Use_Requires_Execution_Validation
     (Use_Kind : Target_Use_Kind) return Boolean
   is
      pragma Unreferenced (Use_Kind);
   begin
      return True;
   end Target_Use_Requires_Execution_Validation;

   function Target_Use_May_Auto_Refresh
     (Use_Kind : Target_Use_Kind) return Boolean
   is
      pragma Unreferenced (Use_Kind);
   begin
      return False;
   end Target_Use_May_Auto_Refresh;

end Editor.Missing_Stale_Recovery.Target_Use_Policies;
