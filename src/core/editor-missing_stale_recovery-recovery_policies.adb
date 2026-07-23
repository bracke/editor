with Editor.Missing_Stale_Recovery.Target_Messages;

package body Editor.Missing_Stale_Recovery.Recovery_Policies is

   function Make
     (Surface : Target_Surface;
      State   : Target_Availability_State;
      Path    : String := "";
      Line    : Natural := 0;
      Column  : Natural := 0) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Target_Messages.Make;

   function Workspace_Restore_Action_Fabricates_State
     (Action : Workspace_Restore_Action) return Boolean
   is
   begin
      return Action in Workspace_Reject_Fabricated_Project | Workspace_Reject_Fabricated_Buffer;
   end Workspace_Restore_Action_Fabricates_State;

   function Workspace_Restore_Action_Is_Safe
     (Action : Workspace_Restore_Action) return Boolean
   is
   begin
      case Action is
         when Workspace_Reopen_File
            | Workspace_Skip_Missing_File
            | Workspace_Restore_Active_File
            | Workspace_Fallback_To_First_Available_File
            | Workspace_Ignore_Missing_Expanded_Path
            | Workspace_Clamp_Caret_Target
            | Workspace_Ignore_Caret_Target =>
            return True;
         when Workspace_Reject_Fabricated_Project
            | Workspace_Reject_Fabricated_Buffer =>
            return False;
      end case;
   end Workspace_Restore_Action_Is_Safe;

   function Caret_Target_Policy
     (State : Target_Availability_State; Explicit_Clamp_Policy : Boolean)
      return String
   is
   begin
      if State = Target_Available then
         return "restore caret";
      elsif State in Target_Line_Out_Of_Range | Target_Column_Out_Of_Range
        and then Explicit_Clamp_Policy
      then
         return "clamp caret target";
      elsif State in Target_Line_Out_Of_Range | Target_Column_Out_Of_Range then
         return "ignore caret target";
      else
         return "ignore stale caret target";
      end if;
   end Caret_Target_Policy;

   function Recovery_Command_Name (Command : Recovery_Command_Kind) return String is
   begin
      case Command is
         when Recovery_Workspace_Load => return "workspace.load";
         when Recovery_Recent_Projects_Remove_Missing => return "recent-projects.remove-missing";
         when Recovery_File_Reload_From_Disk => return "file.reload-from-disk";
         when Recovery_File_Revert_Buffer => return "file.revert-buffer";
         when Recovery_File_Reveal_Active_In_Tree => return "file.reveal-active-in-tree";
         when Recovery_File_Tree_Refresh => return "file-tree.refresh";
         when Recovery_Quick_Open_Clear_Query => return "quick-open.clear-query";
         when Recovery_Project_Search_Run => return "project-search.run";
         when Recovery_Project_Search_Clear_Results => return "project-search.clear-results";
         when Recovery_Project_Search_Replace_Clear_Preview =>
            return "project-search.replace.clear-preview";
         when Recovery_Outline_Refresh => return "outline.refresh";
         when Recovery_Diagnostics_Clear => return "diagnostics.clear";
         when Recovery_Build_Refresh_Candidates => return "build.refresh-candidates";
      end case;
   end Recovery_Command_Name;

   function Recovery_Command_Is_Payload_Free
     (Command : Recovery_Command_Kind) return Boolean
   is
      pragma Unreferenced (Command);
   begin
      return True;
   end Recovery_Command_Is_Payload_Free;

   function Recovery_Command_Is_Explicit
     (Command : Recovery_Command_Kind) return Boolean
   is
      pragma Unreferenced (Command);
   begin
      return True;
   end Recovery_Command_Is_Explicit;

   function Recovery_Command_Replaces_Stale_Surface
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface) return Boolean
   is
   begin
      case Command is
         when Recovery_File_Tree_Refresh =>
            return Surface = File_Tree_Surface;
         when Recovery_Quick_Open_Clear_Query =>
            return Surface = Quick_Open_Surface;
         when Recovery_Project_Search_Run |
              Recovery_Project_Search_Clear_Results |
              Recovery_Project_Search_Replace_Clear_Preview =>
            return Surface = Project_Search_Surface
              or else Surface = Replace_Preview_Surface;
         when Recovery_Outline_Refresh =>
            return Surface = Outline_Surface;
         when Recovery_Diagnostics_Clear =>
            return Surface = Diagnostics_Surface;
         when Recovery_Build_Refresh_Candidates =>
            return Surface = Build_Surface;
         when Recovery_Workspace_Load |
              Recovery_Recent_Projects_Remove_Missing |
              Recovery_File_Reload_From_Disk |
              Recovery_File_Revert_Buffer |
              Recovery_File_Reveal_Active_In_Tree =>
            return Surface = Workspace_Surface
              or else Surface = Recent_Project_Surface
              or else Surface = Buffer_Surface;
     end case;
   end Recovery_Command_Replaces_Stale_Surface;

   function Surface_Cleared_On_Project_Transition
     (Surface : Target_Surface) return Boolean
   is
   begin
      return Surface in File_Tree_Surface
        | Quick_Open_Surface
        | Project_Search_Surface
        | Replace_Preview_Surface
        | Outline_Surface
        | Diagnostics_Surface
        | Build_Surface;
   end Surface_Cleared_On_Project_Transition;

   function Stale_State_After_Content_Change
     (Surface : Target_Surface) return Target_Availability_State
   is
   begin
      if Surface = Replace_Preview_Surface then
         return Target_Preview_Stale;
      elsif Surface = Build_Surface then
         return Target_Candidate_Stale;
      else
         return Target_Stale;
      end if;
   end Stale_State_After_Content_Change;

   function Navigation_Allowed
     (Result : Target_Validation_Result) return Boolean
   is
   begin
      return Result.State = Target_Available
        or else Result.State = Target_Stale
        or else Result.State = Target_Line_Out_Of_Range
        or else Result.State = Target_Column_Out_Of_Range;
   end Navigation_Allowed;

   function Replace_Apply_Allowed
     (Result : Target_Validation_Result) return Boolean
   is
   begin
      return Result.State = Target_Available or else Result.State = Target_Preview_Stale;
   end Replace_Apply_Allowed;

   function Build_Run_Allowed
     (Result : Target_Validation_Result) return Boolean
   is
   begin
      return Result.State = Target_Available or else Result.State = Target_Candidate_Stale;
   end Build_Run_Allowed;

   function Recovery_State_Is_Persistable
     (State : Target_Availability_State) return Boolean
   is
   begin
      return State in Target_Stale | Target_Line_Out_Of_Range | Target_Column_Out_Of_Range
        or else State = Target_Preview_Stale
        or else State = Target_Candidate_Stale;
   end Recovery_State_Is_Persistable;

   function Persistence_Field_Allowed
     (Surface : Target_Surface;
      State   : Target_Availability_State) return Boolean
   is
   begin
      return Surface /= Workspace_Surface or else Recovery_State_Is_Persistable (State);
   end Persistence_Field_Allowed;

   function Render_May_Probe_Targets return Boolean is
   begin
      return False;
   end Render_May_Probe_Targets;

   function Render_May_Repair_Targets return Boolean is
   begin
      return False;
   end Render_May_Repair_Targets;

   function Availability_May_Repair_Targets return Boolean is
   begin
      return False;
   end Availability_May_Repair_Targets;

   function Recovery_Command_May_Run_From_Render
     (Command : Recovery_Command_Kind) return Boolean
   is
      pragma Unreferenced (Command);
   begin
      return False;
   end Recovery_Command_May_Run_From_Render;

   function Recovery_Command_May_Run_From_Availability
     (Command : Recovery_Command_Kind) return Boolean
   is
      pragma Unreferenced (Command);
   begin
      return False;
   end Recovery_Command_May_Run_From_Availability;

   function Recovery_Command_May_Bypass_Dirty_Guards
     (Command : Recovery_Command_Kind) return Boolean
   is
      pragma Unreferenced (Command);
   begin
      return False;
   end Recovery_Command_May_Bypass_Dirty_Guards;

   function Command_Availability_When_No_Selection
     (Surface : Target_Surface) return Target_Validation_Result
   is
   begin
      case Surface is
         when Quick_Open_Surface | Project_Search_Surface | Replace_Preview_Surface =>
            return Make (Surface, Target_No_Result_Selected);
         when Diagnostics_Surface =>
            return Make (Surface, Target_No_Diagnostic_Selected);
         when Build_Surface =>
            return Make (Surface, Target_No_Build_Candidate_Selected);
         when others =>
            return Make (Surface, Target_Command_Pending);
      end case;
   end Command_Availability_When_No_Selection;

   function Recovery_Command_Routes_Through_Executor
     (Command : Recovery_Command_Kind) return Boolean
   is
      pragma Unreferenced (Command);
   begin
      return True;
   end Recovery_Command_Routes_Through_Executor;

end Editor.Missing_Stale_Recovery.Recovery_Policies;
