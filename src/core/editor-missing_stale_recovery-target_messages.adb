with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands.Workflow_Messages;
with Editor.Path_Helpers;
with Hostkit.Host;

package body Editor.Missing_Stale_Recovery.Target_Messages is

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
      use type Hostkit.Host.Kind;
      --  Compare in a host-appropriate form: separators folded to '/' (Canonical
      --  returns Full_Name, which is all backslashes on Windows, and the
      --  boundary test below is written for '/'), and case-folded on Windows,
      --  whose filesystem is case-insensitive. Without this every in-project
      --  file read as "outside the project" on Windows and the target
      --  validation returned Outside_Project instead of missing/stale/available.
      Fold : constant Boolean := Hostkit.Host.Current = Hostkit.Host.Windows;
      Root : constant String :=
        Editor.Path_Helpers.Normalize_For_Compare
          (Canonical (Project_Root), Strip_Trailing => True, Lowercase => Fold);
      Item : constant String :=
        Editor.Path_Helpers.Normalize_For_Compare
          (Canonical (Path), Strip_Trailing => True, Lowercase => Fold);
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
         when Target_Stale               => return Editor.Commands.Workflow_Messages.Reason_Target_Stale;
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
         when Workspace_Surface       => return "Workspace";
         when Recent_Project_Surface  => return "Recent project";
         when Buffer_Surface          => return "Buffer";
         when File_Tree_Surface       => return "File Tree";
         when Quick_Open_Surface      => return "Quick Open";
         when Project_Search_Surface  => return "Project Search";
         when Replace_Preview_Surface => return "Replace preview";
         when Outline_Surface         => return "Outline";
         when Diagnostics_Surface     => return "Diagnostics";
         when Build_Surface           => return "Build";
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

end Editor.Missing_Stale_Recovery.Target_Messages;
