with Editor.Missing_Stale_Recovery.Target_Messages;
with Editor.Missing_Stale_Recovery.Recovery_Policies;

package body Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies is

   function Make
     (Surface : Target_Surface;
      State   : Target_Availability_State;
      Path    : String := "";
      Line    : Natural := 0;
      Column  : Natural := 0) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Target_Messages.Make;

   function Recovery_Command_Replaces_Stale_Surface
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface) return Boolean
     renames Editor.Missing_Stale_Recovery.Recovery_Policies.Recovery_Command_Replaces_Stale_Surface;

   function Snapshot_Status_Is_Transient
     (Result : Target_Validation_Result) return Boolean
   is
   begin
      return Result.State /= Target_Available;
   end Snapshot_Status_Is_Transient;

   function Snapshot_Status_May_Be_Persisted
     (Result : Target_Validation_Result) return Boolean
   is
   begin
      return not Snapshot_Status_Is_Transient (Result);
   end Snapshot_Status_May_Be_Persisted;

   function Snapshot_Status_May_Probe_Filesystem return Boolean is
   begin
      return False;
   end Snapshot_Status_May_Probe_Filesystem;

   function Recovery_Command_No_Op_Message
     (Command : Recovery_Command_Kind) return String
   is
   begin
      case Command is
         when Recovery_Recent_Projects_Remove_Missing =>
            return "No unavailable recent projects.";
         when Recovery_Project_Search_Clear_Results =>
            return "No search results to clear.";
         when Recovery_Project_Search_Replace_Clear_Preview =>
            return "No replace preview to clear.";
         when Recovery_Diagnostics_Clear =>
            return "No diagnostics to clear.";
         when Recovery_Build_Refresh_Candidates =>
            return "No stale build candidates selected.";
         when Recovery_Quick_Open_Clear_Query =>
            return "No Quick Open query to clear.";
         when others =>
            return "No recovery action required.";
      end case;
   end Recovery_Command_No_Op_Message;

   function Command_Availability_When_Confirmation_Pending
     (Surface : Target_Surface) return Target_Validation_Result
   is
   begin
      return Make (Surface, Target_Command_Pending);
   end Command_Availability_When_Confirmation_Pending;

   function Recovery_Command_Available_With_Confirmation_Pending
     (Command : Recovery_Command_Kind) return Boolean
   is
      pragma Unreferenced (Command);
   begin
      return False;
   end Recovery_Command_Available_With_Confirmation_Pending;

   function Forbidden_Recovery_Mechanism_Allowed
     (Mechanism : Forbidden_Recovery_Mechanism) return Boolean
   is
      pragma Unreferenced (Mechanism);
   begin
      return False;
   end Forbidden_Recovery_Mechanism_Allowed;

   function Transient_Surface_Field_May_Be_Persisted
     (Field : Transient_Surface_Field) return Boolean
   is
      pragma Unreferenced (Field);
   begin
      return False;
   end Transient_Surface_Field_May_Be_Persisted;

   function Workspace_Recovery_Primary_Outcome_Count
     (Summary : Workspace_Recovery_Summary) return Natural is
   begin
      if Summary.Project_Missing
        or else Summary.Fabricated_Project
        or else Summary.Fabricated_Buffer
        or else Summary.Missing_Open_Files > 0
        or else Summary.Active_File_Missing
        or else Summary.Ignored_Expanded_Paths > 0
        or else Summary.Invalid_Caret_Targets > 0
      then
         return 1;
      else
         return 0;
      end if;
   end Workspace_Recovery_Primary_Outcome_Count;

   function Workspace_Recovery_Summary_May_Be_Persisted
     (Summary : Workspace_Recovery_Summary) return Boolean is
      pragma Unreferenced (Summary);
   begin
      return False;
   end Workspace_Recovery_Summary_May_Be_Persisted;

   function Availability_Check_May_Write_Persistence return Boolean is
   begin
      return False;
   end Availability_Check_May_Write_Persistence;

   function Availability_Check_May_Clear_Stale_State return Boolean is
   begin
      return False;
   end Availability_Check_May_Clear_Stale_State;

   function Render_Snapshot_May_Clear_Stale_State return Boolean is
   begin
      return False;
   end Render_Snapshot_May_Clear_Stale_State;

   function Recovery_Command_May_Clear_Surface
     (Command : Recovery_Command_Kind;
      Surface : Target_Surface;
      Source  : Command_Invocation_Source) return Boolean is
   begin
      return Source = Invocation_Executor
        and then Recovery_Command_Replaces_Stale_Surface (Command, Surface);
   end Recovery_Command_May_Clear_Surface;

   function Recovery_Command_Failed_Attempt_Preserves_Dirty_Text
     (Command : Recovery_Command_Kind) return Boolean is
      pragma Unreferenced (Command);
   begin
      return True;
   end Recovery_Command_Failed_Attempt_Preserves_Dirty_Text;

end Editor.Missing_Stale_Recovery.Configuration_Recovery_Policies;
