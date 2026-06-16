with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Missing_Stale_Recovery is

   use type Ada.Directories.File_Kind;

   function Trim (Text : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trim;

   function Make
     (Surface : Target_Surface;
      State   : Target_Availability_State;
      Path    : String := "";
      Line    : Natural := 0;
      Column  : Natural := 0) return Target_Validation_Result
   is
   begin
      return
        (State   => State,
         Surface => Surface,
         Path    => To_Unbounded_String (Path),
         Line    => Line,
         Column  => Column);
   end Make;

   function Exists (Path : String) return Boolean is
   begin
      return Trim (Path)'Length > 0 and then Ada.Directories.Exists (Path);
   exception
      when others =>
         return False;
   end Exists;

   function Is_Directory (Path : String) return Boolean is
   begin
      return Exists (Path) and then Ada.Directories.Kind (Path) = Ada.Directories.Directory;
   exception
      when others =>
         return False;
   end Is_Directory;

   function Is_Ordinary_File (Path : String) return Boolean is
   begin
      return Exists (Path) and then Ada.Directories.Kind (Path) = Ada.Directories.Ordinary_File;
   exception
      when others =>
         return False;
   end Is_Ordinary_File;

   function Canonical (Path : String) return String is
   begin
      if Trim (Path)'Length = 0 then
         return "";
      elsif Exists (Path) then
         return Ada.Directories.Full_Name (Path);
      else
         return Ada.Directories.Full_Name (Ada.Directories.Containing_Directory (Path))
           & "/" & Ada.Directories.Simple_Name (Path);
      end if;
   exception
      when others =>
         return Path;
   end Canonical;

   function Is_Inside_Project (Project_Root : String; Path : String) return Boolean is
      Root : constant String := Canonical (Project_Root);
      Item : constant String := Canonical (Path);
   begin
      if Trim (Project_Root)'Length = 0 then
         return True;
      elsif Root'Length = 0 or else Item'Length < Root'Length then
         return False;
      elsif Item (Item'First .. Item'First + Root'Length - 1) /= Root then
         return False;
      elsif Item'Length = Root'Length then
         return True;
      else
         return Item (Item'First + Root'Length) = '/';
      end if;
   exception
      when others =>
         return False;
   end Is_Inside_Project;

   function Label (State : Target_Availability_State) return String is
   begin
      case State is
         when Target_Available            => return "target available";
         when Target_Missing              => return "target missing";
         when Target_Parent_Directory_Missing => return "parent directory missing";
         when Target_Unreadable           => return "target unreadable";
         when Target_Unwritable           => return "target unwritable";
         when Target_Outside_Project      => return "target outside project";
         when Target_Stale                => return "target stale";
         when Target_Line_Out_Of_Range    => return "target line out of range";
         when Target_Column_Out_Of_Range  => return "target column out of range";
         when Target_Source_Less          => return "target source-less";
         when Target_Refresh_Required     => return "refresh required";
         when Target_Reload_Required      => return "reload required";
         when Target_Working_Directory_Missing => return "working directory missing";
         when Target_Candidate_Stale      => return "candidate stale";
         when Target_Preview_Stale        => return "preview stale";
         when Target_No_Result_Selected   => return "no result selected";
         when Target_No_Diagnostic_Selected => return "no diagnostic selected";
         when Target_No_Build_Candidate_Selected => return "no build candidate selected";
         when Target_Command_Pending      => return "command unavailable while confirmation is pending";
      end case;
   end Label;

   function Availability_Reason (State : Target_Availability_State) return String is
   begin
      case State is
         when Target_Available           => return "Available";
         when Target_Missing             => return "Target no longer exists.";
         when Target_Parent_Directory_Missing => return "Parent directory is unavailable.";
         when Target_Unreadable          => return "File is not readable.";
         when Target_Unwritable          => return "File is not writable.";
         when Target_Outside_Project     => return "Target is outside the current project.";
         when Target_Stale               => return "Target is stale; refresh required.";
         when Target_Line_Out_Of_Range   => return "Target line is unavailable.";
         when Target_Column_Out_Of_Range => return "Target column is unavailable.";
         when Target_Source_Less         => return "Selected diagnostic has no source target.";
         when Target_Refresh_Required    => return "Refresh required.";
         when Target_Reload_Required     => return "Reload required.";
         when Target_Working_Directory_Missing => return "Build working directory is unavailable.";
         when Target_Candidate_Stale     => return "Selected build candidate is stale.";
         when Target_Preview_Stale       => return "Replace preview is stale; rerun search.";
         when Target_No_Result_Selected  => return "No result selected.";
         when Target_No_Diagnostic_Selected => return "No diagnostic selected.";
         when Target_No_Build_Candidate_Selected => return "No build candidate selected.";
         when Target_Command_Pending     => return "Command unavailable while confirmation is pending.";
      end case;
   end Availability_Reason;

   function Surface_Label (Surface : Target_Surface) return String is
   begin
      case Surface is
         when Workspace_Surface      => return "Workspace";
         when Recent_Project_Surface => return "Recent project";
         when Buffer_Surface         => return "Buffer";
         when File_Tree_Surface      => return "File Tree";
         when Quick_Open_Surface     => return "Quick Open";
         when Project_Search_Surface => return "Project Search";
         when Replace_Preview_Surface => return "Replace preview";
         when Outline_Surface        => return "Outline";
         when Diagnostics_Surface    => return "Diagnostics";
         when Build_Surface          => return "Build";
      end case;
   end Surface_Label;

   function Outcome_Label (Result : Target_Validation_Result) return String is
   begin
      if Result.State = Target_Available then
         return Surface_Label (Result.Surface) & " target available.";
      else
         return Surface_Label (Result.Surface) & ": " & Availability_Reason (Result.State);
      end if;
   end Outcome_Label;

   function Target_Outcome_Message (Result : Target_Validation_Result) return String is
   begin
      if Result.State = Target_Available then
         return Surface_Label (Result.Surface) & " target available.";
      end if;

      case Result.Surface is
         when Workspace_Surface =>
            if Result.State = Target_Missing then
               return "Workspace project path unavailable.";
            else
               return "Unsupported or stale workspace entries ignored.";
            end if;
         when Recent_Project_Surface =>
            if Result.State = Target_Missing then
               return "Recent project path no longer exists.";
            else
               return Outcome_Label (Result);
            end if;
         when Buffer_Surface =>
            case Result.State is
               when Target_Missing => return "Backing file missing.";
               when Target_Parent_Directory_Missing => return "Parent directory is unavailable.";
               when Target_Unreadable => return "File is not readable.";
               when Target_Unwritable => return "File is not writable.";
               when Target_Reload_Required => return "Reload required.";
               when others => return Outcome_Label (Result);
            end case;
         when File_Tree_Surface =>
            case Result.State is
               when Target_Missing => return "File Tree target no longer exists.";
               when Target_Stale => return "Selected File Tree node is stale.";
               when Target_Refresh_Required => return "File Tree refresh required.";
               when Target_Outside_Project => return "Target is outside the current project.";
               when others => return Outcome_Label (Result);
            end case;
         when Quick_Open_Surface =>
            case Result.State is
               when Target_Stale => return "Quick Open result is stale.";
               when Target_No_Result_Selected => return "No Quick Open result selected.";
               when Target_Missing => return "File no longer exists.";
               when Target_Outside_Project => return "Target is outside the current project.";
               when others => return Outcome_Label (Result);
            end case;
         when Project_Search_Surface =>
            case Result.State is
               when Target_Stale => return "Search result is stale.";
               when Target_No_Result_Selected => return "No result selected.";
               when Target_Missing => return "Search target no longer exists.";
               when Target_Line_Out_Of_Range => return "Search target line is unavailable.";
               when Target_Outside_Project => return "Target is outside the current project.";
               when others => return Outcome_Label (Result);
            end case;
         when Replace_Preview_Surface =>
            case Result.State is
               when Target_Preview_Stale | Target_Stale => return "Replace preview is stale; rerun search.";
               when Target_No_Result_Selected => return "No result selected.";
               when Target_Missing => return "Search target no longer exists.";
               when Target_Line_Out_Of_Range => return "Search target line is unavailable.";
               when Target_Outside_Project => return "Target is outside the current project.";
               when others => return Outcome_Label (Result);
            end case;
         when Outline_Surface =>
            case Result.State is
               when Target_Refresh_Required => return "Outline is stale; refresh required.";
               when Target_Stale => return "Outline belongs to another buffer.";
               when Target_Line_Out_Of_Range | Target_Column_Out_Of_Range => return "Outline target unavailable.";
               when others => return Outcome_Label (Result);
            end case;
         when Diagnostics_Surface =>
            case Result.State is
               when Target_Source_Less => return "Selected diagnostic has no source target.";
               when Target_No_Diagnostic_Selected => return "No diagnostic selected.";
               when Target_Missing => return "Diagnostic target file is unavailable.";
               when Target_Line_Out_Of_Range | Target_Column_Out_Of_Range => return "Diagnostic target line is unavailable.";
               when Target_Stale => return "Diagnostic may be stale.";
               when Target_Outside_Project => return "Target is outside the current project.";
               when others => return Outcome_Label (Result);
            end case;
         when Build_Surface =>
            case Result.State is
               when Target_Candidate_Stale => return "Selected build candidate is stale.";
               when Target_No_Build_Candidate_Selected => return "No build candidate selected.";
               when Target_Working_Directory_Missing => return "Build working directory is unavailable.";
               when Target_Missing => return "Build candidate file no longer exists.";
               when Target_Outside_Project => return "Target is outside the current project.";
               when Target_Refresh_Required => return "Refresh build candidates.";
               when others => return Outcome_Label (Result);
            end case;
      end case;
   end Target_Outcome_Message;

   function Render_Marker_Label (Result : Target_Validation_Result) return String is
   begin
      if Result.State = Target_Available then
         return "";
      else
         return Label (Result.State);
      end if;
   end Render_Marker_Label;


   function Workspace_Recovery_Message (Summary : Workspace_Recovery_Summary) return String is
   begin
      if Summary.Fabricated_Project or else Summary.Fabricated_Buffer then
         return "Workspace load rejected fabricated state.";
      elsif Summary.Project_Missing then
         return "Workspace project path unavailable.";
      elsif Summary.Missing_Open_Files > 0 and then Summary.Active_File_Missing then
         return "Some workspace files could not be reopened; active file could not be restored.";
      elsif Summary.Missing_Open_Files > 0 then
         return "Some workspace files could not be reopened.";
      elsif Summary.Active_File_Missing then
         return "Active file could not be restored.";
      elsif Summary.Ignored_Expanded_Paths > 0 or else Summary.Invalid_Caret_Targets > 0 then
         return "Unsupported or stale workspace entries ignored.";
      else
         return "Workspace references available.";
      end if;
   end Workspace_Recovery_Message;

   function Recent_Project_Recovery_Message
     (Missing_Count : Natural; Removed_Count : Natural) return String
   is
   begin
      if Removed_Count > 0 then
         return "Removed unavailable recent project.";
      elsif Missing_Count > 0 then
         return "Recent project path no longer exists.";
      else
         return "No unavailable recent projects.";
      end if;
   end Recent_Project_Recovery_Message;

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
     (State : Target_Availability_State; Explicit_Clamp_Policy : Boolean) return String
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

   function Recovery_Command_Is_Payload_Free (Command : Recovery_Command_Kind) return Boolean is
      pragma Unreferenced (Command);
   begin
      return True;
   end Recovery_Command_Is_Payload_Free;

   function Recovery_Command_Is_Explicit (Command : Recovery_Command_Kind) return Boolean is
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
         when Recovery_Project_Search_Run | Recovery_Project_Search_Clear_Results =>
            return Surface = Project_Search_Surface;
         when Recovery_Project_Search_Replace_Clear_Preview =>
            return Surface = Replace_Preview_Surface;
         when Recovery_Outline_Refresh =>
            return Surface = Outline_Surface;
         when Recovery_Diagnostics_Clear =>
            return Surface = Diagnostics_Surface;
         when Recovery_Build_Refresh_Candidates =>
            return Surface = Build_Surface;
         when Recovery_Workspace_Load =>
            return Surface = Workspace_Surface;
         when Recovery_Recent_Projects_Remove_Missing =>
            return Surface = Recent_Project_Surface;
         when Recovery_File_Reload_From_Disk
            | Recovery_File_Revert_Buffer
            | Recovery_File_Reveal_Active_In_Tree =>
            return Surface = Buffer_Surface or else Surface = File_Tree_Surface;
      end case;
   end Recovery_Command_Replaces_Stale_Surface;

   function Surface_Cleared_On_Project_Transition
     (Surface : Target_Surface) return Boolean
   is
   begin
      case Surface is
         when File_Tree_Surface
            | Quick_Open_Surface
            | Project_Search_Surface
            | Replace_Preview_Surface
            | Outline_Surface
            | Diagnostics_Surface
            | Build_Surface =>
            return True;
         when Workspace_Surface
            | Recent_Project_Surface
            | Buffer_Surface =>
            return False;
      end case;
   end Surface_Cleared_On_Project_Transition;

   function Stale_State_After_Content_Change
     (Surface : Target_Surface) return Target_Availability_State
   is
   begin
      case Surface is
         when File_Tree_Surface | Quick_Open_Surface =>
            return Target_Refresh_Required;
         when Project_Search_Surface | Diagnostics_Surface =>
            return Target_Stale;
         when Replace_Preview_Surface =>
            return Target_Preview_Stale;
         when Outline_Surface =>
            return Target_Refresh_Required;
         when Build_Surface =>
            return Target_Candidate_Stale;
         when Workspace_Surface | Recent_Project_Surface | Buffer_Surface =>
            return Target_Reload_Required;
      end case;
   end Stale_State_After_Content_Change;

   function Navigation_Allowed (Result : Target_Validation_Result) return Boolean is
   begin
      return Result.State = Target_Available;
   end Navigation_Allowed;

   function Replace_Apply_Allowed (Result : Target_Validation_Result) return Boolean is
   begin
      return Result.Surface = Replace_Preview_Surface
        and then Result.State = Target_Available;
   end Replace_Apply_Allowed;

   function Build_Run_Allowed (Result : Target_Validation_Result) return Boolean is
   begin
      return Result.Surface = Build_Surface
        and then Result.State = Target_Available;
   end Build_Run_Allowed;

   function Recovery_State_Is_Persistable (State : Target_Availability_State) return Boolean is
      pragma Unreferenced (State);
   begin
      return False;
   end Recovery_State_Is_Persistable;

   function Persistence_Field_Allowed
     (Field : Recovery_Persistence_Field) return Boolean
   is
   begin
      case Field is
         when Persist_Workspace_Structural_Reference
            | Persist_Recent_Project_Reference
            | Persist_Settings_Global_Preference
            | Persist_Keybinding_Command_Name =>
            return True;
         when Persist_Stale_Target_Payload
            | Persist_Recovery_Command_Payload
            | Persist_Missing_Target_Cache
            | Persist_Validated_Target_Cache
            | Persist_Command_Outcome_Message
            | Persist_Surface_Stale_Selection =>
            return False;
      end case;
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

   function Invocation_Source_May_Carry_Target_Payload
     (Source : Command_Invocation_Source) return Boolean
   is
      pragma Unreferenced (Source);
   begin
      return False;
   end Invocation_Source_May_Carry_Target_Payload;

   function Invocation_Source_May_Execute_Recovery_Command
     (Source : Command_Invocation_Source) return Boolean
   is
   begin
      return Source = Invocation_Executor;
   end Invocation_Source_May_Execute_Recovery_Command;

   function Recovery_Trigger_May_Probe_Filesystem
     (Trigger : Recovery_Trigger_Kind) return Boolean
   is
   begin
      return Trigger = Trigger_User_Executor_Command;
   end Recovery_Trigger_May_Probe_Filesystem;

   function Recovery_Trigger_May_Mutate_State
     (Trigger : Recovery_Trigger_Kind) return Boolean
   is
   begin
      return Trigger = Trigger_User_Executor_Command;
   end Recovery_Trigger_May_Mutate_State;

   function Recovery_Trigger_May_Persist_Recovery_State
     (Trigger : Recovery_Trigger_Kind) return Boolean
   is
      pragma Unreferenced (Trigger);
   begin
      return False;
   end Recovery_Trigger_May_Persist_Recovery_State;

   function Recovery_Trigger_May_Auto_Refresh
     (Trigger : Recovery_Trigger_Kind) return Boolean
   is
      pragma Unreferenced (Trigger);
   begin
      return False;
   end Recovery_Trigger_May_Auto_Refresh;

   function Target_Path_Identity_Matches
     (Expected_Path : String; Actual_Path : String) return Boolean
   is
   begin
      return Trim (Expected_Path) = Trim (Actual_Path);
   end Target_Path_Identity_Matches;

   function Missing_Target_May_Be_Auto_Remapped return Boolean is
   begin
      return False;
   end Missing_Target_May_Be_Auto_Remapped;


   function Validation_Phase_May_Probe_Filesystem
     (Phase : Target_Validation_Phase) return Boolean
   is
   begin
      return Phase = Validation_Command_Execution;
   end Validation_Phase_May_Probe_Filesystem;

   function Validation_Phase_May_Mutate_State
     (Phase : Target_Validation_Phase) return Boolean
   is
   begin
      return Phase = Validation_Command_Execution;
   end Validation_Phase_May_Mutate_State;

   function Validation_Phase_May_Authorize_Target_Use
     (Phase : Target_Validation_Phase) return Boolean
   is
   begin
      return Phase = Validation_Command_Execution;
   end Validation_Phase_May_Authorize_Target_Use;

   function Validation_Phase_May_Reuse_Cached_Target_Result
     (Phase : Target_Validation_Phase) return Boolean
   is
      pragma Unreferenced (Phase);
   begin
      return False;
   end Validation_Phase_May_Reuse_Cached_Target_Result;

   function Execution_Revalidation_Required
     (Surface : Target_Surface; Use_Kind : Target_Use_Kind) return Boolean
   is
      pragma Unreferenced (Surface);
      pragma Unreferenced (Use_Kind);
   begin
      return True;
   end Execution_Revalidation_Required;

   function Cached_Target_Validation_May_Be_Applied
     (Surface : Target_Surface; Use_Kind : Target_Use_Kind) return Boolean
   is
      pragma Unreferenced (Surface);
      pragma Unreferenced (Use_Kind);
   begin
      return False;
   end Cached_Target_Validation_May_Be_Applied;

   function Execution_Revalidation_Message
     (Surface : Target_Surface) return String
   is
   begin
      case Surface is
         when File_Tree_Surface =>
            return "File Tree target is revalidated before use.";
         when Quick_Open_Surface =>
            return "Quick Open result is revalidated before use.";
         when Project_Search_Surface =>
            return "Search result is revalidated before use.";
         when Replace_Preview_Surface =>
            return "Replace preview target is revalidated before use.";
         when Outline_Surface =>
            return "Outline target is revalidated before use.";
         when Diagnostics_Surface =>
            return "Diagnostic target is revalidated before use.";
         when Build_Surface =>
            return "Build candidate is revalidated before use.";
         when Workspace_Surface =>
            return "Workspace target is revalidated before restore.";
         when Recent_Project_Surface =>
            return "Recent project target is revalidated before opening.";
         when Buffer_Surface =>
            return "Buffer backing file is revalidated before use.";
      end case;
   end Execution_Revalidation_Message;

   function Command_Outcome_Count_For_Validation
     (Result : Target_Validation_Result) return Natural
   is
      pragma Unreferenced (Result);
   begin
      return 1;
   end Command_Outcome_Count_For_Validation;

   function Command_Outcome_Is_User_Readable
     (Result : Target_Validation_Result) return Boolean
   is
      Message : constant String := Target_Outcome_Message (Result);
   begin
      return Message'Length > 0
        and then Ada.Strings.Fixed.Index (Message, "Target_") = 0
        and then Ada.Strings.Fixed.Index (Message, "Surface") = 0
        and then Ada.Strings.Fixed.Index (Message, "_") = 0;
   end Command_Outcome_Is_User_Readable;

   function Surface_Recovery_Label
     (Surface : Target_Surface; State : Target_Availability_State) return String
   is
   begin
      if State = Target_Available then
         return "";
      else
         return Surface_Label (Surface) & " " & Label (State);
      end if;
   end Surface_Recovery_Label;





   function Staleness_Reason_Label
     (Reason : Target_Staleness_Reason) return String
   is
   begin
      case Reason is
         when Staleness_None =>
            return "not stale";
         when Staleness_Snapshot_Generation_Mismatch =>
            return "snapshot generation changed";
         when Staleness_Project_Identity_Mismatch =>
            return "project identity changed";
         when Staleness_File_Content_Changed =>
            return "file content changed";
         when Staleness_Target_Path_Missing =>
            return "target path missing";
         when Staleness_Target_Line_Changed =>
            return "target line changed";
         when Staleness_Candidate_Identity_Changed =>
            return "build candidate identity changed";
         when Staleness_User_Cleared_Surface =>
            return "surface was cleared";
      end case;
   end Staleness_Reason_Label;

   function Staleness_Reason_May_Be_Persisted
     (Reason : Target_Staleness_Reason) return Boolean
   is
      pragma Unreferenced (Reason);
   begin
      return False;
   end Staleness_Reason_May_Be_Persisted;

   function Staleness_Reason_Requires_Explicit_Recovery
     (Reason : Target_Staleness_Reason) return Boolean
   is
   begin
      return Reason /= Staleness_None;
   end Staleness_Reason_Requires_Explicit_Recovery;

   function Validate_Staleness_Provenance
     (Surface : Target_Surface;
      Reason  : Target_Staleness_Reason) return Target_Validation_Result
   is
   begin
      case Reason is
         when Staleness_None =>
            return Make (Surface, Target_Available);
         when Staleness_Target_Path_Missing =>
            return Make (Surface, Target_Missing);
         when Staleness_Target_Line_Changed =>
            return Make (Surface, Target_Line_Out_Of_Range);
         when Staleness_Candidate_Identity_Changed =>
            return Make (Surface, Target_Candidate_Stale);
         when Staleness_User_Cleared_Surface =>
            return Make (Surface, Target_Refresh_Required);
         when Staleness_Snapshot_Generation_Mismatch
            | Staleness_Project_Identity_Mismatch
            | Staleness_File_Content_Changed =>
            if Surface = Replace_Preview_Surface then
               return Make (Surface, Target_Preview_Stale);
            elsif Surface = Outline_Surface then
               return Make (Surface, Target_Refresh_Required);
            elsif Surface = Build_Surface then
               return Make (Surface, Target_Candidate_Stale);
            else
               return Make (Surface, Target_Stale);
            end if;
      end case;
   end Validate_Staleness_Provenance;

   function Project_Scope_Identity_Matches
     (Expected_Project_Root : String;
      Actual_Project_Root   : String) return Boolean
   is
   begin
      return Trim (Expected_Project_Root)'Length > 0
        and then Trim (Actual_Project_Root)'Length > 0
        and then Canonical (Expected_Project_Root) = Canonical (Actual_Project_Root);
   exception
      when others =>
         return False;
   end Project_Scope_Identity_Matches;

   function Stale_Target_May_Be_Opened_From_Previous_Project return Boolean is
   begin
      return False;
   end Stale_Target_May_Be_Opened_From_Previous_Project;


   function Target_Reference_Context_May_Be_Consumed
     (Context : Target_Reference_Context) return Boolean
   is
   begin
      return Context = Reference_Current_Project;
   end Target_Reference_Context_May_Be_Consumed;

   function Target_Generation_State_Allows_Target_Use
     (Generation : Target_Generation_State) return Boolean
   is
   begin
      return Generation = Generation_Current;
   end Target_Generation_State_Allows_Target_Use;

   function Validate_Target_Reference_For_Execution
     (Surface    : Target_Surface;
      Context    : Target_Reference_Context;
      Generation : Target_Generation_State) return Target_Validation_Result
   is
   begin
      if not Target_Reference_Context_May_Be_Consumed (Context) then
         case Context is
            when Reference_Previous_Project | Reference_Project_Closed =>
               return Make (Surface, Target_Outside_Project);
            when Reference_Unknown_Project =>
               return Make (Surface, Target_Stale);
            when Reference_Current_Project =>
               null;
         end case;
      end if;

      case Generation is
         when Generation_Current =>
            return Make (Surface, Target_Available);
         when Generation_Stale =>
            if Surface = Replace_Preview_Surface then
               return Make (Surface, Target_Preview_Stale);
            elsif Surface = Build_Surface then
               return Make (Surface, Target_Candidate_Stale);
            else
               return Make (Surface, Target_Stale);
            end if;
         when Generation_Missing =>
            return Make (Surface, Target_Missing);
         when Generation_Unknown =>
            return Make (Surface, Target_Refresh_Required);
      end case;
   end Validate_Target_Reference_For_Execution;

   function Recovery_Message_Content_Allowed
     (Content : Recovery_Message_Content) return Boolean
   is
   begin
      case Content is
         when Recovery_Message_Surface_Category
            | Recovery_Message_Counts_Only =>
            return True;
         when Recovery_Message_Target_Path
            | Recovery_Message_Target_Line
            | Recovery_Message_Internal_Enum =>
            return False;
      end case;
   end Recovery_Message_Content_Allowed;

   function Outcome_Message_May_Embed_Target_Path
     (Result : Target_Validation_Result) return Boolean
   is
      pragma Unreferenced (Result);
   begin
      return False;
   end Outcome_Message_May_Embed_Target_Path;

   function Outcome_Message_May_Expose_Internal_Enum
     (Result : Target_Validation_Result) return Boolean
   is
      pragma Unreferenced (Result);
   begin
      return False;
   end Outcome_Message_May_Expose_Internal_Enum;

   function Target_Result_Message_Is_Payload_Free
     (Result : Target_Validation_Result) return Boolean
   is
   begin
      return not Outcome_Message_May_Embed_Target_Path (Result)
        and then not Outcome_Message_May_Expose_Internal_Enum (Result)
        and then Recovery_Message_Identifies_Surface_And_Category (Result);
   end Target_Result_Message_Is_Payload_Free;


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
               return Target_Outcome_Message (Result);
            end if;
         when Use_Reload_Target | Use_Revert_Target =>
            if Result.State = Target_Missing then
               return "Could not reload file.";
            elsif Result.State = Target_Unreadable then
               return "File is not readable.";
            else
               return Target_Outcome_Message (Result);
            end if;
         when Use_Apply_Replace_Target =>
            return "Replace preview is stale; rerun search.";
         when Use_Run_Build_Target =>
            return Target_Outcome_Message (Result);
         when Use_Navigate_Target | Use_Reveal_Target | Use_Open_Target =>
            return Target_Outcome_Message (Result);
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
               when Buffer_Surface =>
                  return Surface_Unchanged;
               when Workspace_Surface | Recent_Project_Surface =>
                  return Surface_Unchanged;
            end case;
         when Event_File_Tree_Refreshed =>
            if Surface = File_Tree_Surface then
               return Surface_Replaced;
            else
               return Surface_Unchanged;
            end if;
         when Event_Quick_Open_Requeried =>
            if Surface = Quick_Open_Surface then
               return Surface_Replaced;
            else
               return Surface_Unchanged;
            end if;
         when Event_Project_Search_Rerun =>
            if Surface = Project_Search_Surface then
               return Surface_Replaced;
            elsif Surface = Replace_Preview_Surface then
               return Surface_Cleared;
            else
               return Surface_Unchanged;
            end if;
         when Event_Replace_Preview_Cleared =>
            if Surface = Replace_Preview_Surface then
               return Surface_Cleared;
            else
               return Surface_Unchanged;
            end if;
         when Event_Outline_Refreshed =>
            if Surface = Outline_Surface then
               return Surface_Replaced;
            else
               return Surface_Unchanged;
            end if;
         when Event_Diagnostics_Cleared =>
            if Surface = Diagnostics_Surface then
               return Surface_Cleared;
            else
               return Surface_Unchanged;
            end if;
         when Event_Build_Candidates_Refreshed =>
            if Surface = Build_Surface then
               return Surface_Replaced;
            else
               return Surface_Unchanged;
            end if;
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
               when Diagnostics_Surface =>
                  return Target_Stale;
               when Project_Search_Surface =>
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

   function Workspace_Load_May_Restore_Unsaved_Text return Boolean is
   begin
      return False;
   end Workspace_Load_May_Restore_Unsaved_Text;

   function Project_Transition_May_Discard_Dirty_Buffer return Boolean is
   begin
      return False;
   end Project_Transition_May_Discard_Dirty_Buffer;

   function Recovery_Command_Requires_Dirty_Guard
     (Command : Recovery_Command_Kind) return Boolean
   is
   begin
      return Command in Recovery_Workspace_Load
        | Recovery_File_Reload_From_Disk
        | Recovery_File_Revert_Buffer;
   end Recovery_Command_Requires_Dirty_Guard;

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

   function Surface_Requires_Execution_Validation
     (Surface : Target_Surface) return Boolean
   is
      pragma Unreferenced (Surface);
   begin
      return True;
   end Surface_Requires_Execution_Validation;

   function Selected_Stale_Target_Selection_Action
     (Surface : Target_Surface) return String
   is
   begin
      case Surface is
         when File_Tree_Surface =>
            return "clear or mark selected File Tree node stale";
         when Quick_Open_Surface =>
            return "clear stale Quick Open selection";
         when Project_Search_Surface =>
            return "mark Search result stale until rerun";
         when Replace_Preview_Surface =>
            return "clear stale replace preview or require rerun";
         when Outline_Surface =>
            return "mark Outline stale until refresh";
         when Diagnostics_Surface =>
            return "keep diagnostic non-navigable until target validates";
         when Build_Surface =>
            return "invalidate selected build request consent";
         when Workspace_Surface | Recent_Project_Surface | Buffer_Surface =>
            return "report missing target without fabricating state";
      end case;
   end Selected_Stale_Target_Selection_Action;

   function Failed_Recovery_Operation_May_Fabricate_State
     (Surface : Target_Surface) return Boolean
   is
      pragma Unreferenced (Surface);
   begin
      return False;
   end Failed_Recovery_Operation_May_Fabricate_State;

   function Recent_Missing_Marker_Is_Snapshot_Derived return Boolean is
   begin
      return True;
   end Recent_Missing_Marker_Is_Snapshot_Derived;

   function Recent_Missing_Marker_May_Delete_Files return Boolean is
   begin
      return False;
   end Recent_Missing_Marker_May_Delete_Files;

   function Recent_Missing_Marker_May_Clear_Workspace return Boolean is
   begin
      return False;
   end Recent_Missing_Marker_May_Clear_Workspace;

   function Buffer_Known_Missing_State_Allowed
     (Dirty : Boolean; State : Target_Availability_State) return Boolean
   is
   begin
      if Dirty then
         return State in Target_Missing
           | Target_Parent_Directory_Missing
           | Target_Unreadable
           | Target_Unwritable
           | Target_Reload_Required;
      else
         return State in Target_Missing
           | Target_Unreadable
           | Target_Reload_Required
           | Target_Available;
      end if;
   end Buffer_Known_Missing_State_Allowed;

   function Replace_All_May_Apply
     (Summary : Replace_Apply_Validation_Summary) return Boolean
   is
   begin
      return Summary.Missing_Targets = 0
        and then Summary.Stale_Targets = 0
        and then Summary.Out_Of_Range_Targets = 0;
   end Replace_All_May_Apply;

   function Build_Candidate_Material_Identity_Matches
     (Old_Candidate_Path : String;
      Old_Working_Root   : String;
      New_Candidate_Path : String;
      New_Working_Root   : String) return Boolean
   is
   begin
      return Canonical (Old_Candidate_Path) = Canonical (New_Candidate_Path)
        and then Canonical (Old_Working_Root) = Canonical (New_Working_Root);
   end Build_Candidate_Material_Identity_Matches;

   function Build_Candidate_Refresh_Requires_Reconsent
     (Old_Candidate_Path : String;
      Old_Working_Root   : String;
      New_Candidate_Path : String;
      New_Working_Root   : String) return Boolean
   is
   begin
      return not Build_Candidate_Material_Identity_Matches
        (Old_Candidate_Path, Old_Working_Root, New_Candidate_Path, New_Working_Root);
   end Build_Candidate_Refresh_Requires_Reconsent;

   function Validate_Buffer_Access_State
     (Path           : String;
      Target_Exists  : Boolean;
      Ordinary_File  : Boolean;
      Readable       : Boolean;
      Writable       : Boolean;
      Require_Read   : Boolean := False;
      Require_Write  : Boolean := False) return Target_Validation_Result
   is
   begin
      if Trim (Path)'Length = 0 or else not Target_Exists then
         return Make (Buffer_Surface, Target_Missing, Path);
      elsif not Ordinary_File then
         return Make (Buffer_Surface, Target_Unreadable, Path);
      elsif Require_Read and then not Readable then
         return Make (Buffer_Surface, Target_Unreadable, Path);
      elsif Require_Write and then not Writable then
         return Make (Buffer_Surface, Target_Unwritable, Path);
      else
         return Make (Buffer_Surface, Target_Available, Path);
      end if;
   end Validate_Buffer_Access_State;

   function Diagnostic_Line_Only_Navigation_Column
     (Line : Natural;
      Column : Natural) return Natural
   is
   begin
      if Line = 0 then
         return 0;
      elsif Column = 0 then
         return 1;
      else
         return Column;
      end if;
   end Diagnostic_Line_Only_Navigation_Column;

   function Search_Result_Content_State
     (Target_Exists             : Boolean;
      Line_Available            : Boolean;
      Match_Still_Present       : Boolean;
      File_Touched_Since_Search : Boolean) return Target_Availability_State
   is
   begin
      if not Target_Exists then
         return Target_Missing;
      elsif not Line_Available then
         return Target_Line_Out_Of_Range;
      elsif File_Touched_Since_Search or else not Match_Still_Present then
         return Target_Stale;
      else
         return Target_Available;
      end if;
   end Search_Result_Content_State;

   function Replace_Apply_Summary_Message
     (Summary : Replace_Apply_Validation_Summary) return String
   is
   begin
      if Summary.Missing_Targets = 0
        and then Summary.Stale_Targets = 0
        and then Summary.Out_Of_Range_Targets = 0
      then
         return "Replace preview targets validated.";
      elsif Summary.Applied_Targets = 0 then
         return "Replace preview is stale; rerun search.";
      else
         return "Replace applied to available targets; stale or missing targets were skipped.";
      end if;
   end Replace_Apply_Summary_Message;

   function Quick_Open_Session_Recent_Boost_Allowed
     (Path : String;
      Project_Root : String := "") return Boolean
   is
      Result : constant Target_Validation_Result :=
        Validate_Quick_Open_Result_Target (Path, Project_Root);
   begin
      return Result.State = Target_Available;
   end Quick_Open_Session_Recent_Boost_Allowed;

   function Build_Request_Consent_Remains_Valid
     (Candidate_Result : Target_Validation_Result) return Boolean
   is
   begin
      return Candidate_Result.Surface = Build_Surface
        and then Candidate_Result.State = Target_Available;
   end Build_Request_Consent_Remains_Valid;

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

   function File_Tree_Expanded_Path_Restore_State
     (Path : String) return Target_Availability_State
   is
   begin
      if Trim (Path)'Length = 0 or else not Exists (Path) then
         return Target_Missing;
      elsif not Is_Directory (Path) then
         return Target_Stale;
      else
         return Target_Available;
      end if;
   end File_Tree_Expanded_Path_Restore_State;


   function Validate_File_Tree_Mutation_Target
     (Kind         : File_Tree_Mutation_Kind;
      Path         : String;
      Project_Root : String := "";
      Parent_Path  : String := "") return Target_Validation_Result
   is
      Parent : constant String := (if Trim (Parent_Path)'Length > 0
                                   then Parent_Path
                                   else (if Trim (Path)'Length = 0
                                         then ""
                                         else Ada.Directories.Containing_Directory (Path)));
   begin
      case Kind is
         when File_Tree_Activate_Node
            | File_Tree_Rename_Node
            | File_Tree_Delete_Node =>
            return Validate_File_Tree_Node_Target (Path, Project_Root);

         when File_Tree_Create_File =>
            if Trim (Project_Root)'Length > 0 and then not Is_Inside_Project (Project_Root, Path) then
               return Make (File_Tree_Surface, Target_Outside_Project, Path);
            elsif Trim (Parent)'Length = 0 or else not Is_Directory (Parent) then
               return Make (File_Tree_Surface, Target_Parent_Directory_Missing, Path);
            else
               return Make (File_Tree_Surface, Target_Available, Path);
            end if;
      end case;
   exception
      when others =>
         return Make (File_Tree_Surface, Target_Parent_Directory_Missing, Path);
   end Validate_File_Tree_Mutation_Target;

   function Workspace_Active_File_Fallback_Policy
     (Active_File_Missing      : Boolean;
      Reopened_File_Count      : Natural) return Workspace_Active_File_Fallback
   is
   begin
      if not Active_File_Missing then
         return Workspace_Use_Restored_Active_File;
      elsif Reopened_File_Count > 0 then
         return Workspace_Use_First_Reopened_File;
      else
         return Workspace_No_Active_File;
      end if;
   end Workspace_Active_File_Fallback_Policy;

   function Workspace_Active_File_Fallback_Label
     (Fallback : Workspace_Active_File_Fallback) return String
   is
   begin
      case Fallback is
         when Workspace_Use_Restored_Active_File =>
            return "restore requested active file";
         when Workspace_Use_First_Reopened_File =>
            return "fallback to first reopened file";
         when Workspace_No_Active_File =>
            return "no active file restored";
      end case;
   end Workspace_Active_File_Fallback_Label;

   function Replace_Apply_Skipped_Report_Allowed
     (Command_Reached_Validation : Boolean;
      Summary                    : Replace_Apply_Validation_Summary) return Boolean
   is
   begin
      if Summary.Missing_Targets = 0
        and then Summary.Stale_Targets = 0
        and then Summary.Out_Of_Range_Targets = 0
      then
         return True;
      end if;

      return Command_Reached_Validation;
   end Replace_Apply_Skipped_Report_Allowed;

   function File_Tree_Mutation_Requires_Execution_Validation
     (Kind : File_Tree_Mutation_Kind) return Boolean
   is
      pragma Unreferenced (Kind);
   begin
      return True;
   end File_Tree_Mutation_Requires_Execution_Validation;

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

   function Project_Transition_Clears_Build_Transient
     (Field : Transient_Surface_Field) return Boolean
   is
   begin
      case Field is
         when Transient_Build_Candidates
            | Transient_Build_Request
            | Transient_Build_Consent
            | Transient_Build_Result
            | Transient_Build_Output =>
            return True;
         when others =>
            return False;
      end case;
   end Project_Transition_Clears_Build_Transient;

   function Validate_Project_Target
     (Project_Path : String;
      Require_Directory : Boolean := True) return Target_Validation_Result
   is
   begin
      if Trim (Project_Path)'Length = 0 or else not Exists (Project_Path) then
         return Make (Workspace_Surface, Target_Missing, Project_Path);
      elsif Require_Directory and then not Is_Directory (Project_Path) then
         return Make (Workspace_Surface, Target_Unreadable, Project_Path);
      else
         return Make (Workspace_Surface, Target_Available, Project_Path);
      end if;
   end Validate_Project_Target;


   function Validate_Workspace_Project_Target
     (Project_Path : String) return Target_Validation_Result
   is
      Result : Target_Validation_Result := Validate_Project_Target (Project_Path);
   begin
      Result.Surface := Workspace_Surface;
      return Result;
   end Validate_Workspace_Project_Target;

   function Validate_Workspace_File_Target
     (Path : String) return Target_Validation_Result
   is
      Result : Target_Validation_Result := Validate_File_Target (Path);
   begin
      Result.Surface := Workspace_Surface;
      return Result;
   end Validate_Workspace_File_Target;

   function Validate_Recent_Project_Target
     (Project_Path : String) return Target_Validation_Result
   is
      Result : Target_Validation_Result := Validate_Project_Target (Project_Path);
   begin
      Result.Surface := Recent_Project_Surface;
      return Result;
   end Validate_Recent_Project_Target;

   function Validate_File_Target
     (Path          : String;
      Require_Read  : Boolean := False;
      Require_Write : Boolean := False) return Target_Validation_Result
   is
   begin
      if Trim (Path)'Length = 0 or else not Exists (Path) then
         return Make (Buffer_Surface, Target_Missing, Path);
      elsif not Is_Ordinary_File (Path) then
         return Make (Buffer_Surface, Target_Unreadable, Path);
      elsif Require_Read and then not Ada.Directories.Exists (Path) then
         return Make (Buffer_Surface, Target_Unreadable, Path);
      elsif Require_Write then
         declare
            Dir : constant String := Ada.Directories.Containing_Directory (Path);
         begin
            if not Exists (Dir) then
               return Make (Buffer_Surface, Target_Missing, Path);
            end if;
         exception
            when others =>
               return Make (Buffer_Surface, Target_Unwritable, Path);
         end;
      end if;
      return Make (Buffer_Surface, Target_Available, Path);
   exception
      when others =>
         return Make (Buffer_Surface, Target_Unreadable, Path);
   end Validate_File_Target;

   function Validate_Project_File_Target
     (Project_Root  : String;
      Path          : String;
      Require_Read  : Boolean := False;
      Require_Write : Boolean := False) return Target_Validation_Result
   is
      Result : Target_Validation_Result;
   begin
      if Trim (Project_Root)'Length > 0 and then not Is_Inside_Project (Project_Root, Path) then
         return Make (Buffer_Surface, Target_Outside_Project, Path);
      end if;
      Result := Validate_File_Target (Path, Require_Read, Require_Write);
      return Result;
   end Validate_Project_File_Target;


   function Validate_Buffer_Backing_File_Target
     (Path  : String;
      Dirty : Boolean := False) return Target_Validation_Result
   is
      pragma Unreferenced (Dirty);
      Result : Target_Validation_Result := Validate_File_Target (Path);
   begin
      Result.Surface := Buffer_Surface;
      return Result;
   end Validate_Buffer_Backing_File_Target;

   function Validate_Save_Target
     (Path : String) return Target_Validation_Result
   is
      Dir : constant String :=
        (if Trim (Path)'Length = 0 then "" else Ada.Directories.Containing_Directory (Path));
   begin
      if Trim (Path)'Length = 0 then
         return Make (Buffer_Surface, Target_Missing, Path);
      elsif Trim (Dir)'Length = 0 or else not Is_Directory (Dir) then
         return Make (Buffer_Surface, Target_Parent_Directory_Missing, Path);
      elsif Exists (Path) and then not Is_Ordinary_File (Path) then
         return Make (Buffer_Surface, Target_Unwritable, Path);
      else
         return Make (Buffer_Surface, Target_Available, Path);
      end if;
   exception
      when others =>
         return Make (Buffer_Surface, Target_Unwritable, Path);
   end Validate_Save_Target;

   function Validate_Reveal_Target
     (Path         : String;
      Project_Root : String := "") return Target_Validation_Result
   is
      Result : Target_Validation_Result := Validate_Project_File_Target (Project_Root, Path);
   begin
      Result.Surface := File_Tree_Surface;
      return Result;
   end Validate_Reveal_Target;

   function Dirty_Buffer_Text_Preserved_On
     (State : Target_Availability_State) return Boolean
   is
   begin
      return State in Target_Missing
        | Target_Parent_Directory_Missing
        | Target_Unreadable
        | Target_Unwritable
        | Target_Reload_Required;
   end Dirty_Buffer_Text_Preserved_On;

   function Dirty_State_Preserved_On
     (State : Target_Availability_State) return Boolean
   is
   begin
      return Dirty_Buffer_Text_Preserved_On (State);
   end Dirty_State_Preserved_On;

   function Validate_Line_Column_Target
     (Line             : Natural;
      Column           : Natural;
      Last_Line        : Natural;
      Last_Line_Column : Natural) return Target_Validation_Result
   is
   begin
      if Line = 0 or else Last_Line = 0 or else Line > Last_Line then
         return Make (Buffer_Surface, Target_Line_Out_Of_Range, Line => Line, Column => Column);
      elsif Column = 0 or else Column > Last_Line_Column then
         return Make (Buffer_Surface, Target_Column_Out_Of_Range, Line => Line, Column => Column);
      else
         return Make (Buffer_Surface, Target_Available, Line => Line, Column => Column);
      end if;
   end Validate_Line_Column_Target;

   function Validate_File_Tree_Node_Target
     (Path : String;
      Project_Root : String := "") return Target_Validation_Result
   is
      Result : Target_Validation_Result;
   begin
      if Trim (Project_Root)'Length > 0 and then not Is_Inside_Project (Project_Root, Path) then
         return Make (File_Tree_Surface, Target_Outside_Project, Path);
      elsif not Exists (Path) then
         return Make (File_Tree_Surface, Target_Missing, Path);
      end if;
      Result := Make (File_Tree_Surface, Target_Available, Path);
      return Result;
   end Validate_File_Tree_Node_Target;

   function Validate_Quick_Open_Result_Target
     (Path : String;
      Project_Root : String := "") return Target_Validation_Result
   is
   begin
      if Trim (Project_Root)'Length > 0 and then not Is_Inside_Project (Project_Root, Path) then
         return Make (Quick_Open_Surface, Target_Outside_Project, Path);
      elsif not Is_Ordinary_File (Path) then
         return Make (Quick_Open_Surface, Target_Stale, Path);
      else
         return Make (Quick_Open_Surface, Target_Available, Path);
      end if;
   end Validate_Quick_Open_Result_Target;

   function Validate_Search_Result_Target
     (Path : String;
      Line : Natural;
      Last_Line : Natural;
      Stale : Boolean := False;
      Project_Root : String := "") return Target_Validation_Result
   is
   begin
      if Trim (Project_Root)'Length > 0 and then not Is_Inside_Project (Project_Root, Path) then
         return Make (Project_Search_Surface, Target_Outside_Project, Path, Line);
      elsif Stale then
         return Make (Project_Search_Surface, Target_Stale, Path, Line);
      elsif not Is_Ordinary_File (Path) then
         return Make (Project_Search_Surface, Target_Missing, Path, Line);
      elsif Line = 0 or else Last_Line = 0 or else Line > Last_Line then
         return Make (Project_Search_Surface, Target_Line_Out_Of_Range, Path, Line);
      else
         return Make (Project_Search_Surface, Target_Available, Path, Line);
      end if;
   end Validate_Search_Result_Target;

   function Validate_Replace_Preview_Target
     (Path : String;
      Line : Natural;
      Last_Line : Natural;
      Stale : Boolean := False;
      Project_Root : String := "") return Target_Validation_Result
   is
   begin
      if Trim (Project_Root)'Length > 0 and then not Is_Inside_Project (Project_Root, Path) then
         return Make (Replace_Preview_Surface, Target_Outside_Project, Path, Line);
      elsif Stale then
         return Make (Replace_Preview_Surface, Target_Preview_Stale, Path, Line);
      elsif not Is_Ordinary_File (Path) then
         return Make (Replace_Preview_Surface, Target_Missing, Path, Line);
      elsif Line = 0 or else Last_Line = 0 or else Line > Last_Line then
         return Make (Replace_Preview_Surface, Target_Line_Out_Of_Range, Path, Line);
      else
         return Make (Replace_Preview_Surface, Target_Available, Path, Line);
      end if;
   end Validate_Replace_Preview_Target;

   function Validate_Outline_Target
     (Active_Buffer_Matches : Boolean;
      Stale                 : Boolean;
      Line                  : Natural;
      Column                : Natural;
      Last_Line             : Natural;
      Last_Line_Column      : Natural) return Target_Validation_Result
   is
      Result : Target_Validation_Result;
   begin
      if not Active_Buffer_Matches then
         return Make (Outline_Surface, Target_Stale, Line => Line, Column => Column);
      elsif Stale then
         return Make (Outline_Surface, Target_Refresh_Required, Line => Line, Column => Column);
      end if;
      Result := Validate_Line_Column_Target (Line, Column, Last_Line, Last_Line_Column);
      Result.Surface := Outline_Surface;
      return Result;
   end Validate_Outline_Target;

   function Validate_Diagnostic_Target
     (Path       : String;
      Has_Source : Boolean;
      Line       : Natural;
      Column     : Natural;
      Last_Line  : Natural;
      Last_Line_Column : Natural;
      Project_Root : String := "") return Target_Validation_Result
   is
      Result : Target_Validation_Result;
   begin
      if not Has_Source then
         return Make (Diagnostics_Surface, Target_Source_Less, Path, Line, Column);
      elsif Trim (Project_Root)'Length > 0 and then not Is_Inside_Project (Project_Root, Path) then
         return Make (Diagnostics_Surface, Target_Outside_Project, Path, Line, Column);
      elsif not Is_Ordinary_File (Path) then
         return Make (Diagnostics_Surface, Target_Missing, Path, Line, Column);
      end if;
      if Line = 0 or else Last_Line = 0 or else Line > Last_Line then
         return Make (Diagnostics_Surface, Target_Line_Out_Of_Range, Path, Line, Column);
      end if;

      Result := Validate_Line_Column_Target
        (Line, Diagnostic_Line_Only_Navigation_Column (Line, Column),
         Last_Line, Last_Line_Column);
      Result.Surface := Diagnostics_Surface;
      Result.Path := To_Unbounded_String (Path);
      return Result;
   end Validate_Diagnostic_Target;

   function Validate_Build_Working_Context_Target
     (Working_Root : String) return Target_Validation_Result
   is
   begin
      if Trim (Working_Root)'Length = 0 or else not Is_Directory (Working_Root) then
         return Make (Build_Surface, Target_Working_Directory_Missing, Working_Root);
      else
         return Make (Build_Surface, Target_Available, Working_Root);
      end if;
   end Validate_Build_Working_Context_Target;

   function Validate_Build_Candidate_Target
     (Candidate_Path : String;
      Working_Root   : String;
      Stale          : Boolean := False) return Target_Validation_Result
   is
   begin
      if Stale then
         return Make (Build_Surface, Target_Candidate_Stale, Candidate_Path);
      elsif Trim (Working_Root)'Length = 0 or else not Is_Directory (Working_Root) then
         return Make (Build_Surface, Target_Working_Directory_Missing, Working_Root);
      elsif not Is_Ordinary_File (Candidate_Path) then
         return Make (Build_Surface, Target_Missing, Candidate_Path);
      elsif not Is_Inside_Project (Working_Root, Candidate_Path) then
         return Make (Build_Surface, Target_Outside_Project, Candidate_Path);
      else
         return Make (Build_Surface, Target_Available, Candidate_Path);
      end if;
   end Validate_Build_Candidate_Target;

   function Assert_Missing_Targets_Do_Not_Fabricate_State return Boolean is
   begin
      return Validate_File_Target ("").State = Target_Missing
        and then Validate_Project_Target ("").State = Target_Missing;
   end Assert_Missing_Targets_Do_Not_Fabricate_State;

   function Assert_Dirty_Buffers_Preserved_When_File_Missing return Boolean is
   begin
      return Availability_Reason (Target_Missing) = "Target no longer exists."
        and then Label (Target_Reload_Required) = "reload required"
        and then Dirty_Buffer_Text_Preserved_On (Target_Missing)
        and then Dirty_Buffer_Text_Preserved_On (Target_Unwritable);
   end Assert_Dirty_Buffers_Preserved_When_File_Missing;

   function Assert_Stale_Search_Replace_Does_Not_Apply return Boolean is
   begin
      return Validate_Search_Result_Target ("missing", 1, 1, Stale => True).State = Target_Stale
        and then Validate_Replace_Preview_Target ("missing", 1, 1, Stale => True).State = Target_Preview_Stale;
   end Assert_Stale_Search_Replace_Does_Not_Apply;

   function Assert_Stale_Outline_Does_Not_Navigate return Boolean is
   begin
      return Validate_Outline_Target (True, True, 1, 1, 1, 1).State = Target_Refresh_Required
        and then Validate_Outline_Target (False, False, 1, 1, 1, 1).State = Target_Stale;
   end Assert_Stale_Outline_Does_Not_Navigate;

   function Assert_Missing_Diagnostic_Target_Fails_Clearly return Boolean is
   begin
      return Validate_Diagnostic_Target ("", False, 0, 0, 0, 0).State = Target_Source_Less
        and then Availability_Reason (Target_Source_Less) = "Selected diagnostic has no source target.";
   end Assert_Missing_Diagnostic_Target_Fails_Clearly;

   function Assert_Stale_Build_Candidate_Blocks_Run return Boolean is
   begin
      return Validate_Build_Candidate_Target ("missing.gpr", ".", True).State = Target_Candidate_Stale;
   end Assert_Stale_Build_Candidate_Blocks_Run;

   function Assert_Render_Does_Not_Probe_Or_Repair_Targets return Boolean is
   begin
      return Surface_Label (File_Tree_Surface) = "File Tree"
        and then Label (Target_Stale) = "target stale"
        and then not Render_May_Probe_Targets;
   end Assert_Render_Does_Not_Probe_Or_Repair_Targets;

   function Assert_Recovery_State_Not_Persisted return Boolean is
   begin
      return Label (Target_Preview_Stale) = "preview stale"
        and then not Recovery_State_Is_Persistable (Target_Stale)
        and then not Recovery_State_Is_Persistable (Target_Candidate_Stale);
   end Assert_Recovery_State_Not_Persisted;

   function Assert_Keybindings_Have_No_Target_Payloads return Boolean is
   begin
      return Availability_Reason (Target_Refresh_Required) = "Refresh required."
        and then Recovery_Command_Is_Payload_Free (Recovery_File_Tree_Refresh)
        and then Recovery_Command_Is_Payload_Free (Recovery_Project_Search_Run)
        and then Recovery_Command_Is_Payload_Free (Recovery_Build_Refresh_Candidates);
   end Assert_Keybindings_Have_No_Target_Payloads;

   function Assert_Project_Transition_Clears_Project_Scoped_Stale_State return Boolean is
   begin
      return Surface_Cleared_On_Project_Transition (Quick_Open_Surface)
        and then Surface_Cleared_On_Project_Transition (Project_Search_Surface)
        and then Surface_Cleared_On_Project_Transition (Replace_Preview_Surface)
        and then Surface_Cleared_On_Project_Transition (Diagnostics_Surface)
        and then Surface_Cleared_On_Project_Transition (Build_Surface)
        and then not Surface_Cleared_On_Project_Transition (Recent_Project_Surface);
   end Assert_Project_Transition_Clears_Project_Scoped_Stale_State;

   function Assert_Recovery_Commands_Are_Explicit_And_Surface_Bounded return Boolean is
   begin
      return Recovery_Command_Is_Explicit (Recovery_File_Tree_Refresh)
        and then Recovery_Command_Is_Explicit (Recovery_Outline_Refresh)
        and then Recovery_Command_Replaces_Stale_Surface
          (Recovery_File_Tree_Refresh, File_Tree_Surface)
        and then Recovery_Command_Replaces_Stale_Surface
          (Recovery_Project_Search_Replace_Clear_Preview, Replace_Preview_Surface)
        and then Recovery_Command_Replaces_Stale_Surface
          (Recovery_Build_Refresh_Candidates, Build_Surface)
        and then not Recovery_Command_Replaces_Stale_Surface
          (Recovery_Build_Refresh_Candidates, Project_Search_Surface);
   end Assert_Recovery_Commands_Are_Explicit_And_Surface_Bounded;

   function Assert_Stale_Targets_Block_Navigation_Apply_And_Run return Boolean is
   begin
      return not Navigation_Allowed
          (Make (Outline_Surface, Target_Refresh_Required, Line => 1, Column => 1))
        and then not Replace_Apply_Allowed
          (Make (Replace_Preview_Surface, Target_Preview_Stale, Line => 1))
        and then not Build_Run_Allowed
          (Make (Build_Surface, Target_Candidate_Stale, "demo.gpr"));
   end Assert_Stale_Targets_Block_Navigation_Apply_And_Run;

   function Assert_Surface_Specific_Messages_Are_Clear return Boolean is
   begin
      return Target_Outcome_Message (Make (Quick_Open_Surface, Target_Stale, "missing.adb")) =
          "Quick Open result is stale."
        and then Target_Outcome_Message (Make (Project_Search_Surface, Target_Missing, "missing.adb", 1)) =
          "Search target no longer exists."
        and then Target_Outcome_Message (Make (Outline_Surface, Target_Refresh_Required, Line => 1, Column => 1)) =
          "Outline is stale; refresh required."
        and then Target_Outcome_Message (Make (Diagnostics_Surface, Target_Source_Less)) =
          "Selected diagnostic has no source target."
        and then Target_Outcome_Message (Make (Build_Surface, Target_Candidate_Stale, "demo.gpr")) =
          "Selected build candidate is stale."
        and then Target_Outcome_Message (Make (Build_Surface, Target_Working_Directory_Missing, "missing-root")) =
          "Build working directory is unavailable.";
   end Assert_Surface_Specific_Messages_Are_Clear;

   function Assert_No_Automatic_Repair_From_Render_Or_Availability return Boolean is
   begin
      return not Render_May_Probe_Targets
        and then not Render_May_Repair_Targets
        and then not Availability_May_Repair_Targets
        and then not Recovery_Command_May_Run_From_Render (Recovery_File_Tree_Refresh)
        and then not Recovery_Command_May_Run_From_Availability (Recovery_File_Tree_Refresh);
   end Assert_No_Automatic_Repair_From_Render_Or_Availability;

   function Assert_Workspace_Restore_Actions_Are_Safe_And_Non_Fabricating return Boolean is
   begin
      return Workspace_Restore_Action_Is_Safe (Workspace_Skip_Missing_File)
        and then Workspace_Restore_Action_Is_Safe (Workspace_Fallback_To_First_Available_File)
        and then Workspace_Restore_Action_Is_Safe (Workspace_Ignore_Missing_Expanded_Path)
        and then not Workspace_Restore_Action_Is_Safe (Workspace_Reject_Fabricated_Project)
        and then Workspace_Restore_Action_Fabricates_State (Workspace_Reject_Fabricated_Project)
        and then Workspace_Restore_Action_Fabricates_State (Workspace_Reject_Fabricated_Buffer)
        and then not Workspace_Restore_Action_Fabricates_State (Workspace_Skip_Missing_File);
   end Assert_Workspace_Restore_Actions_Are_Safe_And_Non_Fabricating;

   function Assert_Selectionless_Commands_Are_Unavailable_Without_Payloads return Boolean is
   begin
      return Command_Availability_When_No_Selection (Quick_Open_Surface).State = Target_No_Result_Selected
        and then Command_Availability_When_No_Selection (Diagnostics_Surface).State = Target_No_Diagnostic_Selected
        and then Command_Availability_When_No_Selection (Build_Surface).State = Target_No_Build_Candidate_Selected
        and then Recovery_Command_Is_Payload_Free (Recovery_Quick_Open_Clear_Query)
        and then Recovery_Command_Is_Payload_Free (Recovery_Diagnostics_Clear)
        and then Recovery_Command_Is_Payload_Free (Recovery_Build_Refresh_Candidates);
   end Assert_Selectionless_Commands_Are_Unavailable_Without_Payloads;

   function Assert_Explicit_Caret_Policy_Required_For_Clamping return Boolean is
   begin
      return Caret_Target_Policy (Target_Line_Out_Of_Range, False) = "ignore caret target"
        and then Caret_Target_Policy (Target_Line_Out_Of_Range, True) = "clamp caret target"
        and then Caret_Target_Policy (Target_Available, False) = "restore caret";
   end Assert_Explicit_Caret_Policy_Required_For_Clamping;

   function Assert_Recovery_Commands_Do_Not_Bypass_Dirty_Guards return Boolean is
   begin
      return not Recovery_Command_May_Bypass_Dirty_Guards (Recovery_File_Reload_From_Disk)
        and then not Recovery_Command_May_Bypass_Dirty_Guards (Recovery_File_Revert_Buffer)
        and then not Recovery_Command_May_Bypass_Dirty_Guards (Recovery_Workspace_Load);
   end Assert_Recovery_Commands_Do_Not_Bypass_Dirty_Guards;

   function Assert_Recovery_Commands_Route_Only_Through_Executor return Boolean is
   begin
      return Recovery_Command_Routes_Through_Executor (Recovery_File_Tree_Refresh)
        and then Recovery_Command_Routes_Through_Executor (Recovery_Project_Search_Run)
        and then Recovery_Command_Routes_Through_Executor (Recovery_Build_Refresh_Candidates)
        and then Invocation_Source_May_Execute_Recovery_Command (Invocation_Executor)
        and then not Invocation_Source_May_Execute_Recovery_Command (Invocation_Render)
        and then not Invocation_Source_May_Execute_Recovery_Command (Invocation_Availability);
   end Assert_Recovery_Commands_Route_Only_Through_Executor;

   function Assert_Command_Sources_Have_No_Target_Payloads return Boolean is
   begin
      return not Invocation_Source_May_Carry_Target_Payload (Invocation_Command_Palette)
        and then not Invocation_Source_May_Carry_Target_Payload (Invocation_Keybinding)
        and then not Invocation_Source_May_Carry_Target_Payload (Invocation_Render)
        and then not Invocation_Source_May_Carry_Target_Payload (Invocation_Availability)
        and then not Invocation_Source_May_Carry_Target_Payload (Invocation_Executor);
   end Assert_Command_Sources_Have_No_Target_Payloads;

   function Assert_One_Primary_User_Readable_Outcome_Per_Command return Boolean is
      Missing_Quick_Open : constant Target_Validation_Result :=
        Make (Quick_Open_Surface, Target_Stale, "gone.adb");
      Missing_Build : constant Target_Validation_Result :=
        Make (Build_Surface, Target_Missing, "gone.gpr");
      Missing_Diagnostic : constant Target_Validation_Result :=
        Make (Diagnostics_Surface, Target_Source_Less);
   begin
      return Command_Outcome_Count_For_Validation (Missing_Quick_Open) = 1
        and then Command_Outcome_Count_For_Validation (Missing_Build) = 1
        and then Command_Outcome_Count_For_Validation (Missing_Diagnostic) = 1
        and then Command_Outcome_Is_User_Readable (Missing_Quick_Open)
        and then Command_Outcome_Is_User_Readable (Missing_Build)
        and then Command_Outcome_Is_User_Readable (Missing_Diagnostic);
   end Assert_One_Primary_User_Readable_Outcome_Per_Command;

   function Assert_Surface_Recovery_Labels_Are_Snapshot_Friendly return Boolean is
   begin
      return Surface_Recovery_Label (Quick_Open_Surface, Target_Stale) =
          "Quick Open target stale"
        and then Surface_Recovery_Label (Build_Surface, Target_Candidate_Stale) =
          "Build candidate stale"
        and then Surface_Recovery_Label (Diagnostics_Surface, Target_Source_Less) =
          "Diagnostics target source-less"
        and then Surface_Recovery_Label (Outline_Surface, Target_Available) = "";
   end Assert_Surface_Recovery_Labels_Are_Snapshot_Friendly;


   function Assert_Access_Distinctions_Are_Explicit return Boolean is
   begin
      return Validate_Buffer_Access_State
          ("demo.adb", True, True, False, True, Require_Read => True).State = Target_Unreadable
        and then Validate_Buffer_Access_State
          ("demo.adb", True, True, True, False, Require_Write => True).State = Target_Unwritable
        and then Target_Outcome_Message (Make (Buffer_Surface, Target_Unreadable, "demo.adb")) =
          "File is not readable."
        and then Target_Outcome_Message (Make (Buffer_Surface, Target_Unwritable, "demo.adb")) =
          "File is not writable.";
   end Assert_Access_Distinctions_Are_Explicit;

   function Assert_Line_Only_Diagnostics_Navigate_To_Line_Start return Boolean is
   begin
      return Diagnostic_Line_Only_Navigation_Column (12, 0) = 1
        and then Diagnostic_Line_Only_Navigation_Column (12, 5) = 5;
   end Assert_Line_Only_Diagnostics_Navigate_To_Line_Start;

   function Assert_Search_Content_Staleness_Is_Gated return Boolean is
   begin
      return Search_Result_Content_State (True, True, False, False) = Target_Stale
        and then Search_Result_Content_State (True, True, True, True) = Target_Stale
        and then Search_Result_Content_State (True, False, True, False) = Target_Line_Out_Of_Range
        and then Search_Result_Content_State (False, True, True, False) = Target_Missing;
   end Assert_Search_Content_Staleness_Is_Gated;

   function Assert_Replace_Apply_Summary_Is_Bounded return Boolean is
      Summary : constant Replace_Apply_Validation_Summary :=
        (Applied_Targets => 0, Missing_Targets => 1, Stale_Targets => 1,
         Out_Of_Range_Targets => 0);
   begin
      return Replace_Apply_Summary_Message (Summary) =
        "Replace preview is stale; rerun search.";
   end Assert_Replace_Apply_Summary_Is_Bounded;

   function Assert_Session_Recent_And_Build_Consent_Do_Not_Bypass_Validation return Boolean is
   begin
      return not Quick_Open_Session_Recent_Boost_Allowed ("missing.adb")
        and then not Build_Request_Consent_Remains_Valid
          (Make (Build_Surface, Target_Candidate_Stale, "demo.gpr"));
   end Assert_Session_Recent_And_Build_Consent_Do_Not_Bypass_Validation;


   function Assert_Selected_Stale_Targets_Are_Not_Persisted_Or_Auto_Repaired return Boolean is
   begin
      return Surface_Requires_Execution_Validation (Quick_Open_Surface)
        and then Selected_Stale_Target_Selection_Action (File_Tree_Surface) =
          "clear or mark selected File Tree node stale"
        and then Selected_Stale_Target_Selection_Action (Build_Surface) =
          "invalidate selected build request consent"
        and then not Failed_Recovery_Operation_May_Fabricate_State (File_Tree_Surface)
        and then not Persistence_Field_Allowed (Persist_Surface_Stale_Selection);
   end Assert_Selected_Stale_Targets_Are_Not_Persisted_Or_Auto_Repaired;

   function Assert_Recent_Missing_Markers_Are_Snapshot_Only return Boolean is
   begin
      return Recent_Missing_Marker_Is_Snapshot_Derived
        and then not Recent_Missing_Marker_May_Delete_Files
        and then not Recent_Missing_Marker_May_Clear_Workspace;
   end Assert_Recent_Missing_Markers_Are_Snapshot_Only;

   function Assert_Replace_All_And_Build_Reconsent_Are_Gated return Boolean is
      Clean_Summary : constant Replace_Apply_Validation_Summary :=
        (Applied_Targets => 1, Missing_Targets => 0, Stale_Targets => 0,
         Out_Of_Range_Targets => 0);
      Dirty_Summary : constant Replace_Apply_Validation_Summary :=
        (Applied_Targets => 1, Missing_Targets => 0, Stale_Targets => 1,
         Out_Of_Range_Targets => 0);
   begin
      return Replace_All_May_Apply (Clean_Summary)
        and then not Replace_All_May_Apply (Dirty_Summary)
        and then not Build_Candidate_Refresh_Requires_Reconsent
          ("demo.gpr", ".", "demo.gpr", ".")
        and then Build_Candidate_Refresh_Requires_Reconsent
          ("demo.gpr", ".", "other.gpr", ".");
   end Assert_Replace_All_And_Build_Reconsent_Are_Gated;


   function Assert_File_Tree_Mutations_Preflight_At_Execution return Boolean is
   begin
      return File_Tree_Mutation_Requires_Execution_Validation (File_Tree_Activate_Node)
        and then File_Tree_Mutation_Requires_Execution_Validation (File_Tree_Rename_Node)
        and then File_Tree_Mutation_Requires_Execution_Validation (File_Tree_Delete_Node)
        and then Validate_File_Tree_Mutation_Target
          (File_Tree_Activate_Node, "", "").State = Target_Missing
        and then Validate_File_Tree_Mutation_Target
          (File_Tree_Create_File, "missing/new.adb", "", "missing").State =
            Target_Parent_Directory_Missing;
   end Assert_File_Tree_Mutations_Preflight_At_Execution;

   function Assert_Workspace_Active_File_Fallback_Is_Deterministic return Boolean is
   begin
      return Workspace_Active_File_Fallback_Policy (False, 0) =
          Workspace_Use_Restored_Active_File
        and then Workspace_Active_File_Fallback_Policy (True, 2) =
          Workspace_Use_First_Reopened_File
        and then Workspace_Active_File_Fallback_Policy (True, 0) =
          Workspace_No_Active_File
        and then Workspace_Active_File_Fallback_Label (Workspace_Use_First_Reopened_File) =
          "fallback to first reopened file";
   end Assert_Workspace_Active_File_Fallback_Is_Deterministic;

   function Assert_Replace_Skipped_Report_Requires_Validation return Boolean is
      Clean : constant Replace_Apply_Validation_Summary :=
        (Applied_Targets => 1, Missing_Targets => 0, Stale_Targets => 0,
         Out_Of_Range_Targets => 0);
      Skipped : constant Replace_Apply_Validation_Summary :=
        (Applied_Targets => 0, Missing_Targets => 1, Stale_Targets => 1,
         Out_Of_Range_Targets => 1);
   begin
      return Replace_Apply_Skipped_Report_Allowed (False, Clean)
        and then not Replace_Apply_Skipped_Report_Allowed (False, Skipped)
        and then Replace_Apply_Skipped_Report_Allowed (True, Skipped);
   end Assert_Replace_Skipped_Report_Requires_Validation;



   function Assert_Target_Reference_Identity_And_Message_Payload_Policies_Are_Explicit return Boolean is
      Previous_Project : constant Target_Validation_Result :=
        Validate_Target_Reference_For_Execution
          (Quick_Open_Surface, Reference_Previous_Project, Generation_Current);
      Stale_Search : constant Target_Validation_Result :=
        Validate_Target_Reference_For_Execution
          (Project_Search_Surface, Reference_Current_Project, Generation_Stale);
      Stale_Replace : constant Target_Validation_Result :=
        Validate_Target_Reference_For_Execution
          (Replace_Preview_Surface, Reference_Current_Project, Generation_Stale);
      Current_Build : constant Target_Validation_Result :=
        Validate_Target_Reference_For_Execution
          (Build_Surface, Reference_Current_Project, Generation_Current);
   begin
      return Target_Reference_Context_May_Be_Consumed (Reference_Current_Project)
        and then not Target_Reference_Context_May_Be_Consumed (Reference_Previous_Project)
        and then not Target_Reference_Context_May_Be_Consumed (Reference_Project_Closed)
        and then not Target_Reference_Context_May_Be_Consumed (Reference_Unknown_Project)
        and then Target_Generation_State_Allows_Target_Use (Generation_Current)
        and then not Target_Generation_State_Allows_Target_Use (Generation_Stale)
        and then not Target_Generation_State_Allows_Target_Use (Generation_Missing)
        and then Previous_Project.State = Target_Outside_Project
        and then Stale_Search.State = Target_Stale
        and then Stale_Replace.State = Target_Preview_Stale
        and then Current_Build.State = Target_Available
        and then Recovery_Message_Content_Allowed
          (Recovery_Message_Surface_Category)
        and then Recovery_Message_Content_Allowed
          (Recovery_Message_Counts_Only)
        and then not Recovery_Message_Content_Allowed
          (Recovery_Message_Target_Path)
        and then not Recovery_Message_Content_Allowed
          (Recovery_Message_Target_Line)
        and then not Recovery_Message_Content_Allowed
          (Recovery_Message_Internal_Enum)
        and then Target_Result_Message_Is_Payload_Free (Previous_Project)
        and then Target_Result_Message_Is_Payload_Free (Stale_Search);
   end Assert_Target_Reference_Identity_And_Message_Payload_Policies_Are_Explicit;

   function Assert_Target_Use_Blocking_Matrix_Is_Explicit return Boolean is
      Missing_Search : constant Target_Validation_Result :=
        (State   => Target_Missing,
         Surface => Project_Search_Surface,
         Path    => To_Unbounded_String ("src/deleted.adb"),
         Line    => 10,
         Column  => 1);
      Available_Replace : constant Target_Validation_Result :=
        (State   => Target_Available,
         Surface => Replace_Preview_Surface,
         Path    => To_Unbounded_String ("src/main.adb"),
         Line    => 3,
         Column  => 4);
      Available_Build : constant Target_Validation_Result :=
        (State   => Target_Available,
         Surface => Build_Surface,
         Path    => To_Unbounded_String ("demo.gpr"),
         Line    => 0,
         Column  => 0);
      Pending : constant Target_Validation_Result :=
        Command_Availability_When_Confirmation_Pending (Build_Surface);
   begin
      return Target_State_Blocks_Use (Target_Missing, Use_Open_Target)
        and then Target_State_Blocks_Use (Target_Unwritable, Use_Save_Target)
        and then Target_State_Blocks_Use (Target_Parent_Directory_Missing, Use_Save_Target)
        and then Target_State_Blocks_Use (Target_Line_Out_Of_Range, Use_Navigate_Target)
        and then Target_State_Blocks_Use (Target_Candidate_Stale, Use_Run_Build_Target)
        and then Target_State_Blocks_Use (Target_Command_Pending, Use_Run_Build_Target)
        and then not Target_State_Blocks_Use (Target_Available, Use_Open_Target)
        and then not Target_Use_May_Proceed (Missing_Search, Use_Navigate_Target)
        and then Target_Use_May_Proceed (Available_Replace, Use_Apply_Replace_Target)
        and then Target_Use_May_Proceed (Available_Build, Use_Run_Build_Target)
        and then not Target_Use_May_Proceed (Available_Build, Use_Apply_Replace_Target)
        and then Target_Use_Blocking_Message (Pending, Use_Run_Build_Target) =
          "Build: Command unavailable while confirmation is pending."
        and then Target_Use_Failure_Requires_Recovery_Command
          (Target_Preview_Stale, Use_Apply_Replace_Target)
        and then not Target_Use_Failure_Requires_Recovery_Command
          (Target_Source_Less, Use_Navigate_Target);
   end Assert_Target_Use_Blocking_Matrix_Is_Explicit;

   function Assert_Target_Uses_Validate_And_Do_Not_Auto_Refresh return Boolean is
   begin
      return Target_Use_Requires_Execution_Validation (Use_Open_Target)
        and then Target_Use_Requires_Execution_Validation (Use_Save_Target)
        and then Target_Use_Requires_Execution_Validation (Use_Navigate_Target)
        and then Target_Use_Requires_Execution_Validation (Use_Apply_Replace_Target)
        and then Target_Use_Requires_Execution_Validation (Use_Run_Build_Target)
        and then not Target_Use_May_Auto_Refresh (Use_Open_Target)
        and then not Target_Use_May_Auto_Refresh (Use_Navigate_Target)
        and then not Target_Use_May_Auto_Refresh (Use_Apply_Replace_Target)
        and then not Target_Use_May_Auto_Refresh (Use_Run_Build_Target);
   end Assert_Target_Uses_Validate_And_Do_Not_Auto_Refresh;

   function Assert_Failed_Target_Uses_Preserve_User_Text_And_Do_Not_Fabricate return Boolean is
   begin
      return Failed_Target_Use_Preserves_User_Text (Use_Save_Target, Target_Missing)
        and then Failed_Target_Use_Preserves_User_Text (Use_Reload_Target, Target_Unreadable)
        and then Failed_Target_Use_Preserves_User_Text (Use_Revert_Target, Target_Reload_Required)
        and then not Target_Use_Failure_May_Discard_User_Text (Use_Save_Target, Target_Missing)
        and then not Missing_Target_May_Create_Implicit_File (Buffer_Surface)
        and then not Missing_Target_May_Create_Implicit_File (File_Tree_Surface)
        and then not Missing_Target_May_Create_Implicit_File (Project_Search_Surface);
   end Assert_Failed_Target_Uses_Preserve_User_Text_And_Do_Not_Fabricate;

   function Assert_Failed_Validation_Is_Non_Mutating_And_Preserves_Surface_State return Boolean is
      Search_Result : constant Target_Validation_Result :=
        (State   => Target_Stale,
         Surface => Project_Search_Surface,
         Path    => To_Unbounded_String ("src/main.adb"),
         Line    => 4,
         Column  => 1);
      Missing_Buffer : constant Target_Validation_Result :=
        (State   => Target_Missing,
         Surface => Buffer_Surface,
         Path    => To_Unbounded_String ("src/deleted.adb"),
         Line    => 0,
         Column  => 0);
   begin
      return not Target_Validation_Failure_May_Mutate_State (Search_Result)
        and then not Target_Validation_Failure_May_Mutate_State (Missing_Buffer)
        and then Target_Validation_Failure_Disposition (Search_Result) =
          Failure_Marks_Surface_Stale
        and then Target_Validation_Failure_Disposition (Missing_Buffer) =
          Failure_Preserves_Surface_State
        and then Validation_Failure_Disposition_Label (Failure_Marks_Surface_Stale) =
          "mark target stale and require explicit recovery"
        and then not Recovery_Command_Failed_Attempt_Clears_Stale_State
          (Recovery_Project_Search_Run)
        and then not Recovery_Command_Failed_Attempt_Clears_Stale_State
          (Recovery_Build_Refresh_Candidates);
   end Assert_Failed_Validation_Is_Non_Mutating_And_Preserves_Surface_State;

   function Assert_Stale_Targets_Expose_Explicit_User_Action_Hints return Boolean is
   begin
      return Stale_Target_User_Action_Hint (File_Tree_Surface) = "refresh File Tree"
        and then Stale_Target_User_Action_Hint (Project_Search_Surface) = "rerun search"
        and then Stale_Target_User_Action_Hint (Replace_Preview_Surface) = "rerun search before replace"
        and then Stale_Target_User_Action_Hint (Outline_Surface) = "refresh Outline"
        and then Stale_Target_User_Action_Hint (Build_Surface) = "refresh build candidates"
        and then Project_Transition_Surface_Disposition (Build_Surface) =
          "clear Build candidates, request, consent, result and output";
   end Assert_Stale_Targets_Expose_Explicit_User_Action_Hints;

   function Assert_Recovery_Hints_Map_To_Explicit_Commands return Boolean is
      Search_Result : constant Target_Validation_Result :=
        (State   => Target_Stale,
         Surface => Project_Search_Surface,
         Path    => To_Unbounded_String ("src/main.adb"),
         Line    => 1,
         Column  => 1);
      Build_Result : constant Target_Validation_Result :=
        (State   => Target_Candidate_Stale,
         Surface => Build_Surface,
         Path    => To_Unbounded_String ("demo.gpr"),
         Line    => 0,
         Column  => 0);
   begin
      return Recovery_Command_For_Surface (Project_Search_Surface) = Recovery_Project_Search_Run
        and then Recovery_Command_Can_Address_Result
          (Recovery_Project_Search_Run, Search_Result)
        and then Recovery_Command_For_Surface (Build_Surface) = Recovery_Build_Refresh_Candidates
        and then Recovery_Command_Can_Address_Result
          (Recovery_Build_Refresh_Candidates, Build_Result)
        and then Ada.Strings.Fixed.Index
          (Recovery_Command_Hint_Message (Search_Result), "Recovery: rerun search.") > 0
        and then Ada.Strings.Fixed.Index
          (Recovery_Command_Hint_Message (Build_Result), "Recovery: refresh build candidates.") > 0;
   end Assert_Recovery_Hints_Map_To_Explicit_Commands;

   function Assert_Transient_Snapshot_Status_Is_Not_Persisted_Or_Probing return Boolean is
      Result : constant Target_Validation_Result :=
        (State   => Target_Stale,
         Surface => Quick_Open_Surface,
         Path    => To_Unbounded_String ("src/main.adb"),
         Line    => 0,
         Column  => 0);
   begin
      return Snapshot_Status_Is_Transient (Result)
        and then not Snapshot_Status_May_Be_Persisted (Result)
        and then not Snapshot_Status_May_Probe_Filesystem;
   end Assert_Transient_Snapshot_Status_Is_Not_Persisted_Or_Probing;

   function Assert_Project_Transitions_And_Workspace_Loads_Preserve_Dirty_Text return Boolean is
   begin
      return not Workspace_Load_May_Restore_Unsaved_Text
        and then not Project_Transition_May_Discard_Dirty_Buffer
        and then Recovery_Command_Requires_Dirty_Guard (Recovery_Workspace_Load)
        and then Recovery_Command_Requires_Dirty_Guard (Recovery_File_Reload_From_Disk)
        and then Recovery_Command_Requires_Dirty_Guard (Recovery_File_Revert_Buffer)
        and then not Recovery_Command_Requires_Dirty_Guard (Recovery_File_Tree_Refresh);
   end Assert_Project_Transitions_And_Workspace_Loads_Preserve_Dirty_Text;

   function Assert_Content_And_Project_Events_Update_Recovery_Surfaces return Boolean is
   begin
      return Event_Effect_On_Surface
          (Event_Buffer_Edited, Project_Search_Surface) = Surface_Marked_Stale
        and then Event_State_After
          (Event_Buffer_Edited, Project_Search_Surface) = Target_Stale
        and then Event_State_After
          (Event_Buffer_Reloaded, Replace_Preview_Surface) = Target_Preview_Stale
        and then Event_State_After
          (Event_Buffer_Edited, Outline_Surface) = Target_Refresh_Required
        and then Event_Effect_On_Surface
          (Event_Project_Switched, Quick_Open_Surface) = Surface_Cleared
        and then Event_Effect_On_Surface
          (Event_Project_Closed, Build_Surface) = Surface_Cleared
        and then Event_Effect_On_Surface
          (Event_Project_Search_Rerun, Project_Search_Surface) = Surface_Replaced
        and then Event_Effect_On_Surface
          (Event_Project_Search_Rerun, Replace_Preview_Surface) = Surface_Cleared
        and then Event_Effect_Label (Surface_Replaced) = "replaced by explicit refresh"
        and then Surface_Event_Effect_Is_Transient (Surface_Marked_Stale)
        and then not Surface_Event_Effect_Is_Transient (Surface_Unchanged);
   end Assert_Content_And_Project_Events_Update_Recovery_Surfaces;

   function Assert_Recovery_Events_Do_Not_Fabricate_Or_Bypass_Executor return Boolean is
   begin
      return not Event_May_Create_Files (Event_Buffer_Edited)
        and then not Event_May_Create_Files (Event_File_Tree_Refreshed)
        and then not Event_May_Create_Files (Event_Build_Candidates_Refreshed)
        and then not Event_May_Bypass_Executor (Event_Project_Search_Rerun)
        and then not Event_May_Bypass_Executor (Event_Outline_Refreshed)
        and then not Event_May_Bypass_Executor (Event_Build_Candidates_Refreshed);
   end Assert_Recovery_Events_Do_Not_Fabricate_Or_Bypass_Executor;

   function Assert_Non_Executor_Recovery_Triggers_Are_Observational return Boolean is
   begin
      return Recovery_Trigger_May_Probe_Filesystem (Trigger_User_Executor_Command)
        and then Recovery_Trigger_May_Mutate_State (Trigger_User_Executor_Command)
        and then not Recovery_Trigger_May_Probe_Filesystem (Trigger_Render_Snapshot)
        and then not Recovery_Trigger_May_Mutate_State (Trigger_Render_Snapshot)
        and then not Recovery_Trigger_May_Probe_Filesystem (Trigger_Availability_Check)
        and then not Recovery_Trigger_May_Mutate_State (Trigger_Availability_Check)
        and then not Recovery_Trigger_May_Probe_Filesystem (Trigger_Background_Watcher)
        and then not Recovery_Trigger_May_Auto_Refresh (Trigger_Background_Watcher)
        and then not Recovery_Trigger_May_Persist_Recovery_State (Trigger_Workspace_Save)
        and then not Recovery_Trigger_May_Probe_Filesystem (Trigger_Command_Palette_View)
        and then not Recovery_Trigger_May_Mutate_State (Trigger_Keybinding_Resolution);
   end Assert_Non_Executor_Recovery_Triggers_Are_Observational;



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
   begin
      case Command is
         when Recovery_Workspace_Load
            | Recovery_File_Reload_From_Disk
            | Recovery_File_Revert_Buffer =>
            return True;
         when others =>
            return True;
      end case;
   end Recovery_Command_Failed_Attempt_Preserves_Dirty_Text;

   function Assert_Workspace_Recovery_Summary_Is_One_Primary_Transient_Outcome return Boolean is
      Clean : constant Workspace_Recovery_Summary :=
        (Project_Missing        => False,
         Missing_Open_Files     => 0,
         Active_File_Missing    => False,
         Ignored_Expanded_Paths => 0,
         Invalid_Caret_Targets  => 0,
         Fabricated_Project     => False,
         Fabricated_Buffer      => False);
      Stale : constant Workspace_Recovery_Summary :=
        (Project_Missing        => False,
         Missing_Open_Files     => 2,
         Active_File_Missing    => True,
         Ignored_Expanded_Paths => 1,
         Invalid_Caret_Targets  => 1,
         Fabricated_Project     => False,
         Fabricated_Buffer      => False);
      Missing_Project : constant Workspace_Recovery_Summary :=
        (Project_Missing        => True,
         Missing_Open_Files     => 4,
         Active_File_Missing    => True,
         Ignored_Expanded_Paths => 3,
         Invalid_Caret_Targets  => 2,
         Fabricated_Project     => False,
         Fabricated_Buffer      => False);
   begin
      return Workspace_Recovery_Primary_Outcome_Count (Clean) = 0
        and then Workspace_Recovery_Primary_Outcome_Count (Stale) = 1
        and then Workspace_Recovery_Primary_Outcome_Count (Missing_Project) = 1
        and then not Workspace_Recovery_Summary_May_Be_Persisted (Stale)
        and then Workspace_Recovery_Message (Stale) =
          "Some workspace files could not be reopened; active file could not be restored."
        and then Workspace_Recovery_Message (Missing_Project) =
          "Workspace project path unavailable.";
   end Assert_Workspace_Recovery_Summary_Is_One_Primary_Transient_Outcome;

   function Assert_Availability_And_Render_Cannot_Clear_Stale_State return Boolean is
   begin
      return not Availability_Check_May_Write_Persistence
        and then not Availability_Check_May_Clear_Stale_State
        and then not Render_Snapshot_May_Clear_Stale_State
        and then not Recovery_Command_May_Clear_Surface
          (Recovery_File_Tree_Refresh, File_Tree_Surface, Invocation_Availability)
        and then not Recovery_Command_May_Clear_Surface
          (Recovery_File_Tree_Refresh, File_Tree_Surface, Invocation_Render);
   end Assert_Availability_And_Render_Cannot_Clear_Stale_State;

   function Assert_Recovery_Command_Clears_Only_Owning_Surface_From_Executor return Boolean is
   begin
      return Recovery_Command_May_Clear_Surface
          (Recovery_File_Tree_Refresh, File_Tree_Surface, Invocation_Executor)
        and then not Recovery_Command_May_Clear_Surface
          (Recovery_File_Tree_Refresh, Project_Search_Surface, Invocation_Executor)
        and then Recovery_Command_May_Clear_Surface
          (Recovery_Project_Search_Run, Project_Search_Surface, Invocation_Executor)
        and then not Recovery_Command_May_Clear_Surface
          (Recovery_Project_Search_Run, Outline_Surface, Invocation_Executor)
        and then Recovery_Command_Failed_Attempt_Preserves_Dirty_Text
          (Recovery_Workspace_Load)
        and then Recovery_Command_Failed_Attempt_Preserves_Dirty_Text
          (Recovery_File_Reload_From_Disk)
        and then Recovery_Command_Failed_Attempt_Preserves_Dirty_Text
          (Recovery_File_Revert_Buffer);
   end Assert_Recovery_Command_Clears_Only_Owning_Surface_From_Executor;

   function Assert_Staleness_Provenance_Is_Explicit_Transient_And_Project_Scoped return Boolean is
      Search_Stale : constant Target_Validation_Result :=
        Validate_Staleness_Provenance
          (Project_Search_Surface, Staleness_File_Content_Changed);
      Preview_Stale : constant Target_Validation_Result :=
        Validate_Staleness_Provenance
          (Replace_Preview_Surface, Staleness_Snapshot_Generation_Mismatch);
      Build_Stale : constant Target_Validation_Result :=
        Validate_Staleness_Provenance
          (Build_Surface, Staleness_Candidate_Identity_Changed);
   begin
      return Search_Stale.State = Target_Stale
        and then Preview_Stale.State = Target_Preview_Stale
        and then Build_Stale.State = Target_Candidate_Stale
        and then Staleness_Reason_Requires_Explicit_Recovery
          (Staleness_Project_Identity_Mismatch)
        and then not Staleness_Reason_May_Be_Persisted
          (Staleness_File_Content_Changed)
        and then Project_Scope_Identity_Matches ("/tmp/project", "/tmp/project")
        and then not Project_Scope_Identity_Matches ("/tmp/project", "/tmp/other")
        and then not Stale_Target_May_Be_Opened_From_Previous_Project;
   end Assert_Staleness_Provenance_Is_Explicit_Transient_And_Project_Scoped;

   function Assert_Missing_Targets_Are_Not_Remapped return Boolean is
   begin
      return Target_Path_Identity_Matches ("src/main.adb", "src/main.adb")
        and then not Target_Path_Identity_Matches ("src/main.adb", "src/renamed.adb")
        and then not Missing_Target_May_Be_Auto_Remapped;
   end Assert_Missing_Targets_Are_Not_Remapped;

   function Assert_Target_Validation_Is_Command_Execution_Boundary return Boolean is
   begin
      return Validation_Phase_May_Probe_Filesystem (Validation_Command_Execution)
        and then Validation_Phase_May_Mutate_State (Validation_Command_Execution)
        and then Validation_Phase_May_Authorize_Target_Use (Validation_Command_Execution)
        and then not Validation_Phase_May_Probe_Filesystem (Validation_Snapshot_Projection)
        and then not Validation_Phase_May_Mutate_State (Validation_Snapshot_Projection)
        and then not Validation_Phase_May_Authorize_Target_Use (Validation_Availability_Check)
        and then not Validation_Phase_May_Mutate_State (Validation_Persistence_Save);
   end Assert_Target_Validation_Is_Command_Execution_Boundary;

   function Assert_Cached_Target_Validation_Is_Never_Authoritative return Boolean is
   begin
      return not Validation_Phase_May_Reuse_Cached_Target_Result (Validation_Snapshot_Projection)
        and then not Validation_Phase_May_Reuse_Cached_Target_Result (Validation_Availability_Check)
        and then not Validation_Phase_May_Reuse_Cached_Target_Result (Validation_Command_Execution)
        and then not Cached_Target_Validation_May_Be_Applied
          (Quick_Open_Surface, Use_Open_Target)
        and then not Cached_Target_Validation_May_Be_Applied
          (Project_Search_Surface, Use_Navigate_Target)
        and then not Cached_Target_Validation_May_Be_Applied
          (Replace_Preview_Surface, Use_Apply_Replace_Target)
        and then Execution_Revalidation_Required
          (Diagnostics_Surface, Use_Navigate_Target)
        and then Execution_Revalidation_Required
          (Build_Surface, Use_Run_Build_Target)
        and then Execution_Revalidation_Message (Build_Surface) =
          "Build candidate is revalidated before use.";
   end Assert_Cached_Target_Validation_Is_Never_Authoritative;

   function Assert_Confirmation_Pending_Blocks_Recovery_Commands return Boolean is
      Pending : constant Target_Validation_Result :=
        Command_Availability_When_Confirmation_Pending (File_Tree_Surface);
   begin
      return Pending.State = Target_Command_Pending
        and then Target_Outcome_Message (Pending) =
          "File Tree: Command unavailable while confirmation is pending."
        and then not Recovery_Command_Available_With_Confirmation_Pending
          (Recovery_File_Tree_Refresh)
        and then not Recovery_Command_Available_With_Confirmation_Pending
          (Recovery_Project_Search_Run)
        and then not Recovery_Command_Available_With_Confirmation_Pending
          (Recovery_Build_Refresh_Candidates);
   end Assert_Confirmation_Pending_Blocks_Recovery_Commands;

   function Assert_Forbidden_Recovery_Mechanisms_Remain_Disabled return Boolean is
   begin
      return not Forbidden_Recovery_Mechanism_Allowed (Forbidden_Filesystem_Watcher)
        and then not Forbidden_Recovery_Mechanism_Allowed (Forbidden_Background_Refresh)
        and then not Forbidden_Recovery_Mechanism_Allowed (Forbidden_Autosave_Recovery)
        and then not Forbidden_Recovery_Mechanism_Allowed (Forbidden_External_File_Manager)
        and then not Forbidden_Recovery_Mechanism_Allowed (Forbidden_Shell_Execution)
        and then not Forbidden_Recovery_Mechanism_Allowed (Forbidden_Terminal)
        and then not Forbidden_Recovery_Mechanism_Allowed (Forbidden_LSP_Recovery)
        and then not Forbidden_Recovery_Mechanism_Allowed (Forbidden_New_Persistence_Domain)
        and then not Forbidden_Recovery_Mechanism_Allowed
          (Forbidden_Command_Palette_Target_Payload)
        and then not Forbidden_Recovery_Mechanism_Allowed
          (Forbidden_Keybinding_Target_Payload);
   end Assert_Forbidden_Recovery_Mechanisms_Remain_Disabled;

   function Assert_Transient_Surface_Fields_Are_Not_Persisted return Boolean is
   begin
      return not Transient_Surface_Field_May_Be_Persisted
          (Transient_File_Tree_Stale_Selection)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Quick_Open_Results)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Project_Search_Results)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Replace_Preview_Targets)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Outline_Rows)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Outline_Current_Symbol)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Diagnostics_Filter)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Diagnostics_Selection)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Diagnostics_Stale_Projection)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Build_Candidates)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Build_Request)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Build_Consent)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Build_Result)
        and then not Transient_Surface_Field_May_Be_Persisted
          (Transient_Build_Output);
   end Assert_Transient_Surface_Fields_Are_Not_Persisted;

   function Assert_Project_Transition_Clears_Build_Transient_State return Boolean is
   begin
      return Project_Transition_Clears_Build_Transient (Transient_Build_Candidates)
        and then Project_Transition_Clears_Build_Transient (Transient_Build_Request)
        and then Project_Transition_Clears_Build_Transient (Transient_Build_Consent)
        and then Project_Transition_Clears_Build_Transient (Transient_Build_Result)
        and then Project_Transition_Clears_Build_Transient (Transient_Build_Output)
        and then not Project_Transition_Clears_Build_Transient
          (Transient_Project_Search_Results)
        and then not Project_Transition_Clears_Build_Transient
          (Transient_Outline_Rows);
   end Assert_Project_Transition_Clears_Build_Transient_State;



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
      pragma Unreferenced (Command);
   begin
      return Outcome /= Recovery_Succeeded
        or else Outcome = Recovery_Succeeded;
   end Recovery_Attempt_Preserves_Dirty_Text;

   function Assert_Recovery_Attempts_Clear_Only_On_Success_And_Never_Embed_Targets return Boolean is
   begin
      return Recovery_Attempt_May_Clear_State
          (Recovery_Project_Search_Run, Project_Search_Surface, Recovery_Succeeded)
        and then not Recovery_Attempt_May_Clear_State
          (Recovery_Project_Search_Run, Project_Search_Surface, Recovery_Failed)
        and then not Recovery_Attempt_May_Clear_State
          (Recovery_Project_Search_Run, Project_Search_Surface, Recovery_Cancelled)
        and then not Recovery_Attempt_May_Clear_State
          (Recovery_File_Tree_Refresh, Project_Search_Surface, Recovery_Succeeded)
        and then Recovery_Attempt_Disposition
          (Recovery_File_Tree_Refresh, File_Tree_Surface, Recovery_Succeeded) = Recovery_State_Replaced
        and then Recovery_Attempt_Disposition
          (Recovery_Project_Search_Clear_Results, Project_Search_Surface, Recovery_Succeeded) = Recovery_State_Cleared
        and then not Recovery_Attempt_Message_May_Embed_Path
          (Recovery_Project_Search_Run, Recovery_Failed)
        and then not Recovery_Attempt_Message_May_Embed_Path
          (Recovery_Workspace_Load, Recovery_Succeeded)
        and then Recovery_Attempt_Produces_One_Primary_Outcome
          (Recovery_Project_Search_Run, Recovery_Failed)
        and then Recovery_Attempt_Produces_One_Primary_Outcome
          (Recovery_Build_Refresh_Candidates, Recovery_Succeeded)
        and then Recovery_Attempt_Preserves_Dirty_Text
          (Recovery_File_Reload_From_Disk, Recovery_Failed)
        and then Recovery_Attempt_Preserves_Dirty_Text
          (Recovery_File_Revert_Buffer, Recovery_Cancelled)
        and then Recovery_Attempt_Outcome_Label (Recovery_Failed) =
          "Recovery failed; existing state preserved.";
   end Assert_Recovery_Attempts_Clear_Only_On_Success_And_Never_Embed_Targets;



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

   function Assert_Recovery_Command_Effects_Are_Explicit_And_Non_Goal_Safe return Boolean is
   begin
      return Recovery_Command_Effect_Allowed
          (Recovery_File_Tree_Refresh, Effect_Probe_Filesystem, Invocation_Executor)
        and then Recovery_Command_Effect_Allowed
          (Recovery_File_Tree_Refresh, Effect_Mutate_Owning_Surface, Invocation_Executor)
        and then Recovery_Command_Effect_Allowed
          (Recovery_File_Reload_From_Disk, Effect_Reload_Buffer, Invocation_Executor)
        and then Recovery_Command_Effect_Allowed
          (Recovery_File_Revert_Buffer, Effect_Revert_Buffer, Invocation_Executor)
        and then Recovery_Command_Effect_Allowed
          (Recovery_Workspace_Load, Effect_Open_Target, Invocation_Executor)
        and then not Recovery_Command_Effect_Allowed
          (Recovery_File_Tree_Refresh, Effect_Probe_Filesystem, Invocation_Render)
        and then not Recovery_Command_Effect_Allowed
          (Recovery_File_Tree_Refresh, Effect_Mutate_Owning_Surface, Invocation_Availability)
        and then not Recovery_Command_Effect_Allowed
          (Recovery_Build_Refresh_Candidates, Effect_Run_Build, Invocation_Executor)
        and then not Recovery_Command_Effect_Allowed
          (Recovery_Recent_Projects_Remove_Missing, Effect_Delete_User_File, Invocation_Executor)
        and then not Recovery_Command_Effect_Allowed
          (Recovery_Workspace_Load, Effect_Create_Project_Context, Invocation_Executor)
        and then not Recovery_Command_May_Write_Persistence
          (Recovery_Project_Search_Run)
        and then not Recovery_Command_May_Clear_Other_Surface
          (Recovery_File_Tree_Refresh)
        and then Recovery_Command_Effect_Label (Effect_Delete_User_File) = "delete user file";
   end Assert_Recovery_Command_Effects_Are_Explicit_And_Non_Goal_Safe;

   function Assert_Recovery_Postconditions_Require_Revalidation_Before_Target_Use return Boolean is
   begin
      return Recovery_Command_Postcondition
          (Recovery_Project_Search_Run, Project_Search_Surface, Recovery_Succeeded) =
          Postcondition_Revalidate_Before_Use
        and then Recovery_Command_Result_Requires_Revalidation_Before_Target_Use
          (Recovery_Project_Search_Run, Project_Search_Surface, Recovery_Succeeded)
        and then Recovery_Command_Postcondition
          (Recovery_Outline_Refresh, Outline_Surface, Recovery_Succeeded) =
          Postcondition_Revalidate_Before_Use
        and then Recovery_Command_Postcondition
          (Recovery_Quick_Open_Clear_Query, Quick_Open_Surface, Recovery_Succeeded) =
          Postcondition_Surface_Cleared
        and then Recovery_Command_Postcondition
          (Recovery_Project_Search_Run, Build_Surface, Recovery_Succeeded) =
          Postcondition_No_Target_Use
        and then not Recovery_Command_May_Immediately_Consume_Recovered_Target
          (Recovery_Build_Refresh_Candidates, Build_Surface, Recovery_Succeeded)
        and then not Recovery_Command_Result_Requires_Revalidation_Before_Target_Use
          (Recovery_Project_Search_Run, Project_Search_Surface, Recovery_Failed)
        and then Recovery_Postcondition_Label
          (Postcondition_Revalidate_Before_Use) =
          "Recovery completed; revalidate target before use.";
   end Assert_Recovery_Postconditions_Require_Revalidation_Before_Target_Use;



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

   function Assert_Stale_Surface_Lifecycle_Is_Bounded_Transient_And_Explicit return Boolean is
   begin
      return Stale_Surface_Lifecycle_Action_Allowed
          (Project_Search_Surface, Lifecycle_Mark_Stale)
        and then Stale_Surface_Lifecycle_Action_Allowed
          (Project_Search_Surface, Lifecycle_Display_Marker)
        and then Stale_Surface_Lifecycle_Action_Allowed
          (Project_Search_Surface, Lifecycle_Block_Target_Use)
        and then Stale_Surface_Lifecycle_Action_Allowed
          (Project_Search_Surface, Lifecycle_Offer_Recovery_Hint)
        and then Stale_Surface_Lifecycle_Action_Allowed
          (Project_Search_Surface, Lifecycle_Clear_By_Explicit_Recovery)
        and then not Stale_Surface_Lifecycle_Action_Allowed
          (Project_Search_Surface, Lifecycle_Persist_Marker)
        and then not Stale_Surface_Lifecycle_Action_Allowed
          (Project_Search_Surface, Lifecycle_Auto_Refresh)
        and then not Stale_Surface_Lifecycle_Action_Allowed
          (Replace_Preview_Surface, Lifecycle_Auto_Rerun)
        and then not Stale_Surface_Lifecycle_Action_Allowed
          (Quick_Open_Surface, Lifecycle_Open_Target)
        and then Stale_Surface_Lifecycle_Action_Is_Transient
          (Lifecycle_Display_Marker)
        and then not Stale_Surface_Lifecycle_Action_Is_Transient
          (Lifecycle_Persist_Marker)
        and then not Stale_Surface_Lifecycle_Action_May_Use_Payload
          (Lifecycle_Offer_Recovery_Hint)
        and then Stale_Surface_Lifecycle_Requires_Executor_Recovery
          (Build_Surface)
        and then Stale_Surface_Lifecycle_Action_Label
          (Lifecycle_Clear_By_Explicit_Recovery) = "clear by explicit recovery";
   end Assert_Stale_Surface_Lifecycle_Is_Bounded_Transient_And_Explicit;

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

   function Assert_Multi_Target_Validation_Is_Atomic_And_Payload_Free return Boolean is
      Bad_Replace : constant Multi_Target_Validation_Summary :=
        (Valid_Targets        => 3,
         Missing_Targets      => 1,
         Stale_Targets        => 1,
         Outside_Project      => 0,
         Unreadable_Targets   => 0,
         Out_Of_Range_Targets => 1);
      Good_Workspace : constant Multi_Target_Validation_Summary :=
        (Valid_Targets        => 2,
         Missing_Targets      => 0,
         Stale_Targets        => 0,
         Outside_Project      => 0,
         Unreadable_Targets   => 0,
         Out_Of_Range_Targets => 0);
   begin
      return Multi_Target_Command_Requires_Full_Preflight
          (Multi_Project_Search_Replace_All)
        and then Multi_Target_Command_Requires_Full_Preflight
          (Multi_Workspace_Reopen_Files)
        and then not Multi_Target_Command_May_Mutate_Before_Preflight
          (Multi_Project_Search_Replace_All)
        and then not Multi_Target_Validation_Allows_Mutation (Bad_Replace)
        and then Multi_Target_Validation_Allows_Mutation (Good_Workspace)
        and then Multi_Target_Validation_Message (Bad_Replace) =
          "Some targets are stale; refresh or rerun before applying."
        and then not Multi_Target_Validation_Message_May_Embed_Paths (Bad_Replace)
        and then Multi_Target_Recovery_Preserves_Existing_State_On_Failure
          (Multi_Project_Search_Replace_All, Bad_Replace)
        and then not Multi_Target_Recovery_Preserves_Existing_State_On_Failure
          (Multi_Workspace_Reopen_Files, Good_Workspace);
   end Assert_Multi_Target_Validation_Is_Atomic_And_Payload_Free;

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
        and then Recovery_Command_Can_Address_Result (Command, Result)
        and then not Recovery_Command_May_Delete_User_File (Command)
        and then not Recovery_Command_May_Fabricate_Project_State (Command)
        and then not Recovery_Command_Available_With_Confirmation_Pending (Command);
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
        Recovery_Command_For_Surface (Surface);
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

   function Assert_Recovery_Actions_Are_Non_Destructive_And_Payloadless return Boolean is
      Search : constant Target_Validation_Result :=
        (State   => Target_Stale,
         Surface => Project_Search_Surface,
         Path    => To_Unbounded_String ("src/main.adb"),
         Line    => 5,
         Column  => 1);
      Recent : constant Target_Validation_Result :=
        (State   => Target_Missing,
         Surface => Recent_Project_Surface,
         Path    => To_Unbounded_String ("/tmp/missing-project"),
         Line    => 0,
         Column  => 0);
      Pending : constant Target_Validation_Result :=
        Command_Availability_When_Confirmation_Pending (Project_Search_Surface);
   begin
      return Recovery_Action_Is_Safe_For_State
          (Recovery_Project_Search_Run, Search)
        and then Recovery_Action_Is_Safe_For_State
          (Recovery_Recent_Projects_Remove_Missing, Recent)
        and then not Recovery_Action_Is_Safe_For_State
          (Recovery_Project_Search_Run, Pending)
        and then not Recovery_Command_May_Delete_User_File
          (Recovery_Recent_Projects_Remove_Missing)
        and then not Recovery_Command_May_Delete_User_File
          (Recovery_File_Tree_Refresh)
        and then not Recovery_Command_May_Fabricate_Project_State
          (Recovery_Workspace_Load)
        and then not Recovery_Message_May_Embed_Target_Payload (Search)
        and then Recovery_Message_Identifies_Surface_And_Category (Search)
        and then Target_State_Has_Explicit_Recovery_Path
          (Project_Search_Surface, Target_Stale)
        and then Target_State_Has_Explicit_Recovery_Path
          (Build_Surface, Target_Candidate_Stale)
        and then not Target_State_Has_Explicit_Recovery_Path
          (Quick_Open_Surface, Target_No_Result_Selected)
        and then not Target_State_Has_Explicit_Recovery_Path
          (Diagnostics_Surface, Target_Source_Less);
   end Assert_Recovery_Actions_Are_Non_Destructive_And_Payloadless;

   function Assert_Missing_Stale_Target_Recovery_Coherent return Boolean is
   begin
      return Assert_Missing_Targets_Do_Not_Fabricate_State
        and then Assert_Dirty_Buffers_Preserved_When_File_Missing
        and then Assert_Stale_Search_Replace_Does_Not_Apply
        and then Assert_Stale_Outline_Does_Not_Navigate
        and then Assert_Missing_Diagnostic_Target_Fails_Clearly
        and then Assert_Stale_Build_Candidate_Blocks_Run
        and then Assert_Render_Does_Not_Probe_Or_Repair_Targets
        and then Assert_Recovery_State_Not_Persisted
        and then Assert_Keybindings_Have_No_Target_Payloads
        and then Assert_Project_Transition_Clears_Project_Scoped_Stale_State
        and then Assert_Recovery_Commands_Are_Explicit_And_Surface_Bounded
        and then Assert_Stale_Targets_Block_Navigation_Apply_And_Run
        and then Assert_Surface_Specific_Messages_Are_Clear
        and then Assert_No_Automatic_Repair_From_Render_Or_Availability
        and then Assert_Workspace_Restore_Actions_Are_Safe_And_Non_Fabricating
        and then Assert_Selectionless_Commands_Are_Unavailable_Without_Payloads
        and then Assert_Explicit_Caret_Policy_Required_For_Clamping
        and then Assert_Recovery_Commands_Do_Not_Bypass_Dirty_Guards
        and then Assert_Recovery_Commands_Route_Only_Through_Executor
        and then Assert_Command_Sources_Have_No_Target_Payloads
        and then Assert_One_Primary_User_Readable_Outcome_Per_Command
        and then Assert_Surface_Recovery_Labels_Are_Snapshot_Friendly
        and then Assert_Access_Distinctions_Are_Explicit
        and then Assert_Line_Only_Diagnostics_Navigate_To_Line_Start
        and then Assert_Search_Content_Staleness_Is_Gated
        and then Assert_Replace_Apply_Summary_Is_Bounded
        and then Assert_Session_Recent_And_Build_Consent_Do_Not_Bypass_Validation
        and then Assert_Selected_Stale_Targets_Are_Not_Persisted_Or_Auto_Repaired
        and then Assert_Recent_Missing_Markers_Are_Snapshot_Only
        and then Assert_Replace_All_And_Build_Reconsent_Are_Gated
        and then Assert_File_Tree_Mutations_Preflight_At_Execution
        and then Assert_Workspace_Active_File_Fallback_Is_Deterministic
        and then Assert_Replace_Skipped_Report_Requires_Validation
        and then Assert_Target_Use_Blocking_Matrix_Is_Explicit
        and then Assert_Target_Uses_Validate_And_Do_Not_Auto_Refresh
        and then Assert_Failed_Target_Uses_Preserve_User_Text_And_Do_Not_Fabricate
        and then Assert_Failed_Validation_Is_Non_Mutating_And_Preserves_Surface_State
        and then Assert_Stale_Targets_Expose_Explicit_User_Action_Hints
        and then Assert_Recovery_Hints_Map_To_Explicit_Commands
        and then Assert_Transient_Snapshot_Status_Is_Not_Persisted_Or_Probing
        and then Assert_Project_Transitions_And_Workspace_Loads_Preserve_Dirty_Text
        and then Assert_Content_And_Project_Events_Update_Recovery_Surfaces
        and then Assert_Recovery_Events_Do_Not_Fabricate_Or_Bypass_Executor
        and then Assert_Non_Executor_Recovery_Triggers_Are_Observational
        and then Assert_Workspace_Recovery_Summary_Is_One_Primary_Transient_Outcome
        and then Assert_Availability_And_Render_Cannot_Clear_Stale_State
        and then Assert_Recovery_Command_Clears_Only_Owning_Surface_From_Executor
        and then Assert_Staleness_Provenance_Is_Explicit_Transient_And_Project_Scoped
        and then Assert_Missing_Targets_Are_Not_Remapped
        and then Assert_Target_Validation_Is_Command_Execution_Boundary
        and then Assert_Cached_Target_Validation_Is_Never_Authoritative
        and then Assert_Confirmation_Pending_Blocks_Recovery_Commands
        and then Assert_Forbidden_Recovery_Mechanisms_Remain_Disabled
        and then Assert_Transient_Surface_Fields_Are_Not_Persisted
        and then Assert_Project_Transition_Clears_Build_Transient_State
        and then Assert_Recovery_Actions_Are_Non_Destructive_And_Payloadless
        and then Assert_Recovery_Attempts_Clear_Only_On_Success_And_Never_Embed_Targets
        and then Assert_Multi_Target_Validation_Is_Atomic_And_Payload_Free
        and then Assert_Target_Reference_Identity_And_Message_Payload_Policies_Are_Explicit
        and then Assert_Recovery_Command_Effects_Are_Explicit_And_Non_Goal_Safe
        and then Assert_Recovery_Postconditions_Require_Revalidation_Before_Target_Use
        and then Assert_Stale_Surface_Lifecycle_Is_Bounded_Transient_And_Explicit;
   end Assert_Missing_Stale_Target_Recovery_Coherent;

end Editor.Missing_Stale_Recovery;
