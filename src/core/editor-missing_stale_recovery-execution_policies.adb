with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Missing_Stale_Recovery.Target_Messages;

package body Editor.Missing_Stale_Recovery.Execution_Policies is

   function Make
     (Surface : Target_Surface;
      State   : Target_Availability_State;
      Path    : String := "";
      Line    : Natural := 0;
      Column  : Natural := 0) return Target_Validation_Result
     renames Editor.Missing_Stale_Recovery.Target_Messages.Make;

   function Trim (Text : String) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Trim;

   function Canonical (Path : String) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Canonical;

   function Surface_Label (Surface : Target_Surface) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Surface_Label;

   function Label (State : Target_Availability_State) return String
     renames Editor.Missing_Stale_Recovery.Target_Messages.Label;

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
      Message : constant String := Target_Messages.Target_Outcome_Message (Result);
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

end Editor.Missing_Stale_Recovery.Execution_Policies;
