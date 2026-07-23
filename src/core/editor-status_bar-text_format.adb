with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands;
with Editor.Commands.Workflow_Messages;

package body Editor.Status_Bar.Text_Format is

   function Enabled
     (Config : Status_Bar_Config) return Boolean
   is
   begin
      return Config.Enabled;
   end Enabled;

   function Height_In_Rows
     (Config : Status_Bar_Config) return Natural
   is
   begin
      if Enabled (Config) then
         return 1;
      else
         return 0;
      end if;
   end Height_In_Rows;

   function Plural
     (Count       : Natural;
      Singular    : String;
      Plural_Text : String) return String
   is
   begin
      if Count = 1 then
         return Singular;
      else
         return Plural_Text;
      end if;
   end Plural;

   function Status_Truncate_Label
     (Text        : String;
      Max_Columns : Natural := 64) return String
   is
      Clean : String := Text;
   begin
      for I in Clean'Range loop
         if Clean (I) = ASCII.CR
           or else Clean (I) = ASCII.LF
           or else Clean (I) = ASCII.HT
         then
            Clean (I) := ' ';
         end if;
      end loop;

      if Max_Columns = 0 then
         return "";
      elsif Clean'Length <= Max_Columns then
         return Clean;
      elsif Max_Columns = 1 then
         return ".";
      elsif Max_Columns = 2 then
         return "..";
      elsif Max_Columns = 3 then
         return "...";
      else
         return Clean (Clean'First .. Clean'First + Max_Columns - 4) & "...";
      end if;
   end Status_Truncate_Label;

   function Segment_Text
     (Value : Unbounded_String) return String
   is
   begin
      return Status_Truncate_Label
        (Editor.Commands.Workflow_Messages.Normalize_Workflow_Message
           (To_String (Value)));
   end Segment_Text;

   function Status_Segment_Text
     (Value : Unbounded_String) return String
   is
      Raw_Text : constant String := Ada.Strings.Fixed.Trim
        (To_String (Value), Ada.Strings.Both);
      Text : constant String := Segment_Text (Value);

      function Diagnostics_Target_Status return String is
      begin
         if Text = "Diagnostics: target file missing"
           or else Text = "Diagnostics: Target file missing"
           or else Text = "Diagnostics: Target file missing."
           or else Text = "Diagnostics: target file missing or unavailable"
           or else Text = "Diagnostics: Target file missing or unavailable"
           or else Text = "Diagnostics: Target file missing or unavailable."
           or else Text = "Diagnostics: diagnostic target file is unavailable"
           or else Text = "Diagnostics: Diagnostic target file is unavailable"
           or else Text = "Diagnostics: Diagnostic target file is unavailable."
           or else Text = "Diagnostics: target no longer exists"
           or else Text = "Diagnostics: Target no longer exists"
           or else Text = "Diagnostics: Target no longer exists."
         then
            return "Diagnostics: Target no longer exists.";
         elsif Text = "Diagnostics: no source target"
           or else Text = "Diagnostics: No source target"
           or else Text = "Diagnostics: No source target."
           or else Text = "Diagnostics: selected diagnostic has no source target"
           or else Text = "Diagnostics: Selected diagnostic has no source target"
           or else Text = "Diagnostics: Selected diagnostic has no source target."
         then
            return "Diagnostics: Selected diagnostic has no source target.";
         elsif Text = "Diagnostics: diagnostic target line is unavailable"
           or else Text = "Diagnostics: Diagnostic target line is unavailable"
           or else Text = "Diagnostics: Diagnostic target line is unavailable."
           or else Text = "Diagnostics: target line unavailable"
           or else Text = "Diagnostics: Target line unavailable"
           or else Text = "Diagnostics: Target line unavailable."
           or else Text = "Diagnostics: target line is unavailable"
           or else Text = "Diagnostics: Target line unavailable"
           or else Text = "Diagnostics: Target line unavailable."
         then
            return "Diagnostics: Target line is unavailable.";
         else
            return "";
         end if;
      end Diagnostics_Target_Status;
   begin
      declare
         Diagnostics_Status : constant String := Diagnostics_Target_Status;
      begin
         if Diagnostics_Status'Length > 0 then
            return Diagnostics_Status;
         end if;
      end;

      if Text = "Search: stale"
        or else Text = "Search: replacement target changed; rerun search"
        or else Text = "Search: Replacement target changed; rerun search"
        or else Text = "Search: Replacement target changed; rerun search."
        or else Text = "Search: search result is stale; rerun search"
        or else Text = "Search: Search result is stale; rerun search"
        or else Text = "Search: Search result is stale; rerun search."
      then
         return "Search: Target is stale; refresh required.";
      elsif Raw_Text = "Search Results: no active buffer"
        or else Raw_Text = "Search Results: no active buffer."
        or else Text = "Search: no active buffer"
        or else Text = "Search: No active buffer"
        or else Text = "Search: No active buffer."
      then
         return "Search: No active buffer.";
      elsif Raw_Text = "Search Results: no selected result"
        or else Raw_Text = "Search Results: no selected result."
        or else Text = "Search: no file selected"
        or else Text = "Search: No file selected"
        or else Text = "Search: No file selected."
      then
         return "Search: No file selected.";
      elsif Text = "Search: search result target unavailable"
        or else Text = "Search: Search result target unavailable"
        or else Text = "Search: Search result target unavailable."
        or else Text = "Search: target no longer exists"
        or else Text = "Search: Target no longer exists"
        or else Text = "Search: Target no longer exists."
      then
         return "Search: Target no longer exists.";
      elsif Raw_Text = "Project Search unavailable: no project open"
        or else Raw_Text = "Project Search unavailable: no project open."
        or else Text = "Project Search: no project"
        or else Text = "Project Search: No project"
        or else Text = "Project Search: no project open"
        or else Text = "Project Search: No project open"
        or else Text = "Project Search: No project open."
        or else Text = "Search: no project"
        or else Text = "Search: No project"
        or else Text = "Search: no project open"
        or else Text = "Search: No project open"
        or else Text = "Search: No project open."
      then
         return "Search: No project open.";
      elsif Text = "Search: no query"
        or else Text = "Search: No search query"
        or else Text = "Search: No search query."
        or else Raw_Text = "Search Results: no query"
        or else Raw_Text = "Search Results: no query."
      then
         return "Search: No search query.";
      elsif Text = "Search: no matches"
        or else Text = "Search: No matches"
        or else Text = "Search: No matches."
        or else Text = "Search: no results"
        or else Text = "Search: No search results"
        or else Text = "Search: No search results."
        or else Raw_Text = "Search Results: no matches"
        or else Raw_Text = "Search Results: no matches."
        or else Raw_Text = "Project search completed: no matches"
        or else Raw_Text = "Project search completed: no matches."
      then
         return "Search: No search results.";
      elsif Text = "Replace: stale preview"
        or else Text = "Replace: replacement target changed; rerun search"
        or else Text = "Replace: Replacement target changed; rerun search"
        or else Text = "Replace: Replacement target changed; rerun search."
      then
         return "Replace: Target is stale; refresh required.";
      elsif Text = "Replace: no replacement preview"
        or else Text = "Replace: No replacement preview"
        or else Text = "Replace: No replacement preview."
        or else Raw_Text = "No replacement preview"
        or else Raw_Text = "No replacement preview."
      then
         return "Replace: No replacement preview.";
      elsif Text = "Replace: replacement target is unavailable"
        or else Text = "Replace: Replacement target is unavailable"
        or else Text = "Replace: Replacement target is unavailable."
        or else Text = "Replace: replacement target no longer exists"
        or else Text = "Replace: Replacement target no longer exists"
        or else Text = "Replace: Replacement target no longer exists."
      then
         return "Replace: Target no longer exists.";
      elsif Text = "Replace: replacement target is outside project"
        or else Text = "Replace: Replacement target is outside project"
        or else Text = "Replace: Replacement target is outside project."
      then
         return "Replace: Target is outside the current project.";
      elsif Text = "Replace: replacement target is read-only"
        or else Text = "Replace: Replacement target is read-only"
        or else Text = "Replace: Replacement target is read-only."
      then
         return "Replace: File is not writable.";
      elsif Text = "Replace: replacement target is not a regular file"
        or else Text = "Replace: Replacement target is not a regular file"
        or else Text = "Replace: Replacement target is not a regular file."
      then
         return "Replace: Target is not a file.";
      elsif Text = "Replace: replacement target path is invalid"
        or else Text = "Replace: Replacement target path is invalid"
        or else Text = "Replace: Replacement target path is invalid."
      then
         return "Replace: Invalid file path.";
      elsif Text = "Replace: replacement text must be single-line"
        or else Text = "Replace: Replacement text must be single-line"
        or else Text = "Replace: Replacement text must be single-line."
      then
         return "Replace: Replacement text must be single-line.";
      elsif Text = "Replace: could not open file for replacement"
        or else Text = "Replace: Could not open file for replacement"
        or else Text = "Replace: Could not open file for replacement."
      then
         return "Replace: Could not open file.";
      elsif Text = "Quick Open: no matches"
        or else Text = "Quick Open: No matches"
        or else Text = "Quick Open: No matches."
      then
         return "Quick Open: No matches.";
      elsif Raw_Text = "Quick Open unavailable: no project open"
        or else Raw_Text = "Quick Open unavailable: no project open."
        or else Text = "Quick Open: no project"
        or else Text = "Quick Open: No project"
        or else Text = "Quick Open: no project open"
        or else Text = "Quick Open: No project open"
        or else Text = "Quick Open: No project open."
      then
         return "Quick Open: No project open.";
      elsif Text = "Quick Open: no result selected"
        or else Text = "Quick Open: No result selected"
        or else Text = "Quick Open: No result selected."
        or else Text = "Quick Open: no file selected"
        or else Text = "Quick Open: No file selected"
        or else Text = "Quick Open: No file selected."
      then
         return "Quick Open: No file selected.";
      elsif Text = "Outline: stale" then
         return "Outline: Target is stale; refresh required.";
      elsif Raw_Text = "Outline unavailable: no active buffer"
        or else Raw_Text = "Outline unavailable: no active buffer."
        or else Text = "Outline: no active buffer"
        or else Text = "Outline: No active buffer"
        or else Text = "Outline: No active buffer."
      then
         return "Outline: No active buffer.";
      elsif Text = "Outline: no project"
        or else Text = "Outline: No project"
        or else Text = "Outline: no project open"
        or else Text = "Outline: No project open"
        or else Text = "Outline: No project open."
      then
         return "Outline: No project open.";
      elsif Text = "Outline: no item selected"
        or else Text = "Outline: No item selected"
        or else Text = "Outline: No item selected."
        or else Text = "Outline: no file selected"
        or else Text = "Outline: No file selected"
        or else Text = "Outline: No file selected."
      then
         return "Outline: No file selected.";
      elsif Text = "Outline: outline target unavailable"
        or else Text = "Outline: Outline target unavailable"
        or else Text = "Outline: Outline target unavailable."
        or else Text = "Outline: target no longer exists"
        or else Text = "Outline: Target no longer exists"
        or else Text = "Outline: Target no longer exists."
      then
         return "Outline: Target no longer exists.";
      elsif Text = "Outline: not refreshed"
        or else Text = "Outline: Not refreshed"
        or else Text = "Outline: Not refreshed."
        or else Raw_Text = "Outline not refreshed"
        or else Raw_Text = "Outline not refreshed."
      then
         return "Outline: Not refreshed.";
      elsif Text = "Diagnostics: stale targets" then
         return "Diagnostics: Target is stale; refresh required.";
      elsif Text = "Diagnostics: no project"
        or else Text = "Diagnostics: No project"
        or else Text = "Diagnostics: no project open"
        or else Text = "Diagnostics: No project open"
        or else Text = "Diagnostics: No project open."
      then
         return "Diagnostics: No project open.";
      elsif Text = "Diagnostics: no diagnostic selected"
        or else Text = "Diagnostics: No diagnostic selected"
        or else Text = "Diagnostics: No diagnostic selected."
        or else Text = "Diagnostics: no file selected"
        or else Text = "Diagnostics: No file selected"
        or else Text = "Diagnostics: No file selected."
      then
         return "Diagnostics: No file selected.";
      elsif Text = "Diagnostics: target file missing"
        or else Text = "Diagnostics: Target file missing"
        or else Text = "Diagnostics: Target file missing."
        or else Text = "Diagnostics: target file missing or unavailable"
        or else Text = "Diagnostics: Target file missing or unavailable"
        or else Text = "Diagnostics: Target file missing or unavailable."
        or else Text = "Diagnostics: diagnostic target file is unavailable"
        or else Text = "Diagnostics: Diagnostic target file is unavailable"
        or else Text = "Diagnostics: Diagnostic target file is unavailable."
      then
         return "Diagnostics: Target no longer exists.";
      elsif Text = "Diagnostics: no source target"
        or else Text = "Diagnostics: No source target"
        or else Text = "Diagnostics: No source target."
        or else Text = "Diagnostics: selected diagnostic has no source target"
        or else Text = "Diagnostics: Selected diagnostic has no source target"
        or else Text = "Diagnostics: Selected diagnostic has no source target."
      then
         return "Diagnostics: Selected diagnostic has no source target.";
      elsif (Text = Editor.Commands.Reason_Target_Stale
             and then (Raw_Text = "candidate must be refreshed"
                       or else Raw_Text = "candidate must be refreshed."))
        or else Text = "Build: candidate stale"
        or else Text = "Build: candidate must be refreshed"
        or else Text = "Build: Candidate must be refreshed"
        or else Text = "Build: Candidate must be refreshed."
      then
         return "Build: Target is stale; refresh required.";
      elsif Text = "No build candidate selected."
        or else Text = "Build: no build candidate selected"
        or else Text = "Build: No build candidate selected"
        or else Text = "Build: No build candidate selected."
      then
         return "Build: No build candidate selected.";
      elsif Text = "No build candidates."
        or else Text = "Build: no build candidates"
        or else Text = "Build: No build candidates"
        or else Text = "Build: No build candidates."
      then
         return "Build: No build candidates.";
      elsif Text = "Build consent required."
        or else Text = "Build: consent required"
        or else Text = "Build: Consent required"
        or else Text = "Build: Consent required."
      then
         return "Build: Consent required.";
      elsif Text = "Build consent is stale."
        or else Text = "Build: consent stale"
        or else Text = "Build: Consent stale"
        or else Text = "Build: Consent stale."
      then
         return "Build: Consent is stale.";
      elsif Text = "No build tool selected."
        or else Text = "Build: no build tool selected"
        or else Text = "Build: No build tool selected"
        or else Text = "Build: No build tool selected."
      then
         return "Build: No build tool selected.";
      elsif Text = "No build request ready."
        or else Text = "Build: no build request ready"
        or else Text = "Build: No build request ready"
        or else Text = "Build: No build request ready."
      then
         return "Build: No build request ready.";
      elsif Raw_Text = "Build unavailable: no project open"
        or else Raw_Text = "Build unavailable: no project open."
        or else Raw_Text = "Build unavailable: no project open or no build request ready"
        or else Raw_Text = "Build unavailable: no project open or no build request ready."
        or else Raw_Text = "Build run unavailable: no project working context selected"
        or else Raw_Text = "Build run unavailable: no project working context selected."
        or else Raw_Text = "Build working directory is required"
        or else Raw_Text = "Build working directory is required."
        or else Raw_Text = "No canonical project/workspace context"
        or else Raw_Text = "No canonical project/workspace context."
        or else Text = "Build: no project"
        or else Text = "Build: No project"
        or else Text = "Build: no project open"
        or else Text = "Build: No project open"
        or else Text = "Build: No project open."
      then
         return "Build: No project open.";
      elsif Text = "Target no longer exists."
        or else Text = "Build: target no longer exists"
        or else Text = "Build: Target no longer exists"
        or else Text = "Build: Target no longer exists."
      then
         return "Build: Target no longer exists.";
      elsif Text = "Target is outside the current project."
        or else Text = "Build: target is outside the current project"
        or else Text = "Build: Target is outside the current project"
        or else Text = "Build: Target is outside the current project."
      then
         return "Build: Target is outside the current project.";
      elsif Text = "No build output captured."
        or else Text = "Build: output unavailable"
        or else Text = "Build: Output unavailable"
        or else Text = "Build: Output unavailable."
        or else Text = "Build: no build output captured"
        or else Text = "Build: No build output captured"
        or else Text = "Build: No build output captured."
      then
         return "Build: No build output captured.";
      elsif Text = "No stdout captured."
        or else Text = "Build: no standard output captured"
        or else Text = "Build: No standard output captured"
        or else Text = "Build: No standard output captured."
        or else Text = "Build: no stdout captured"
        or else Text = "Build: No stdout captured"
        or else Text = "Build: No stdout captured."
      then
         return "Build: No stdout captured.";
      elsif Text = "No stderr captured."
        or else Text = "Build: no standard error captured"
        or else Text = "Build: No standard error captured"
        or else Text = "Build: No standard error captured."
        or else Text = "Build: no stderr captured"
        or else Text = "Build: No stderr captured"
        or else Text = "Build: No stderr captured."
      then
         return "Build: No stderr captured.";
      elsif Text = "Build execution is unavailable."
        or else Text = "Build: execution unavailable"
        or else Text = "Build: Execution unavailable"
        or else Text = "Build: Execution unavailable."
      then
         return "Build: Execution unavailable.";
      elsif Text = "File Tree: stale node" then
         return "File Tree: Target is stale; refresh required.";
      elsif Text = "File Tree: no node selected"
        or else Text = "File Tree: No node selected"
        or else Text = "File Tree: No node selected."
        or else Text = "File Tree: no file selected"
        or else Text = "File Tree: No file selected"
        or else Text = "File Tree: No file selected."
      then
         return "File Tree: No file selected.";
      elsif Text = "File Tree: target path is outside the project"
        or else Text = "File Tree: Target path is outside the project"
        or else Text = "File Tree: Target path is outside the project."
        or else Text = "File Tree: target is outside the current project"
        or else Text = "File Tree: Target is outside the current project"
        or else Text = "File Tree: Target is outside the current project."
      then
         return "File Tree: Target is outside the current project.";
      elsif Text = "File Tree: dirty buffer file cannot be deleted"
        or else Text = "File Tree: Dirty buffer file cannot be deleted"
        or else Text = "File Tree: Dirty buffer file cannot be deleted."
        or else Text = "File Tree: dirty buffer preserved"
        or else Text = "File Tree: Dirty buffer preserved"
        or else Text = "File Tree: Dirty buffer preserved."
      then
         return "File Tree: Dirty buffer preserved.";
      elsif Raw_Text = "File Tree unavailable: no project open"
        or else Raw_Text = "File Tree unavailable: no project open."
        or else Text = "File Tree: no project"
        or else Text = "File Tree: No project"
        or else Text = "File Tree: no project open"
        or else Text = "File Tree: No project open"
        or else Text = "File Tree: No project open."
      then
         return "File Tree: No project open.";
      elsif Text = "Workspace: no state"
        or else Text = "Workspace: No state"
        or else Text = "Workspace: No state."
      then
         return "Workspace: No workspace state.";
      elsif Text = "No workspace restored."
        or else Text = "Workspace: no workspace restored"
        or else Text = "Workspace: No workspace restored"
        or else Text = "Workspace: No workspace restored."
      then
         return "Workspace: No workspace restored.";
      elsif Raw_Text = "Workspace: Cannot restore workspace with unsaved changes"
        or else Raw_Text = "Workspace: Cannot restore workspace with unsaved changes."
        or else Text = "Workspace: unsaved changes require confirmation"
        or else Text = "Workspace: Unsaved changes require confirmation"
        or else Text = "Workspace: Unsaved changes require confirmation."
      then
         return "Workspace: Unsaved changes require confirmation.";
      elsif Text = "Workspace restored."
        or else Text = "Workspace: Restored"
        or else Text = "Workspace: Restored."
        or else Text = "Workspace: Workspace restored"
        or else Text = "Workspace: Workspace restored."
      then
         return "Workspace: Restored.";
      elsif Text = "Workspace restored with missing entries skipped."
        or else Text = "Workspace: restored with missing entries skipped"
        or else Text = "Workspace: Restored with missing entries skipped"
        or else Text = "Workspace: Restored with missing entries skipped."
      then
         return "Workspace: Restored with missing entries skipped.";
      elsif Text = "Recent Projects: no recent project"
        or else Text = "Recent Projects: No recent project"
        or else Text = "Recent Projects: No recent project."
      then
         return "Recent Projects: No recent project.";
      elsif Text = "No recent projects."
        or else Text = "Recent Projects: no recent projects"
        or else Text = "Recent Projects: No recent projects"
        or else Text = "Recent Projects: No recent projects."
      then
         return "Recent Projects: No recent projects.";
      elsif Text = "Recent Projects loaded with invalid entries ignored."
        or else Text = "Recent Projects: loaded with invalid entries ignored"
        or else Text = "Recent Projects: Loaded with invalid entries ignored"
        or else Text = "Recent Projects: Invalid entries ignored"
        or else Text = "Recent Projects: Invalid entries ignored."
      then
         return "Recent Projects: Invalid entries ignored.";
      elsif Text = "Ready with configuration warnings."
        or else Text = "Startup: ready with configuration warnings"
        or else Text = "Startup: Ready with configuration warnings"
        or else Text = "Startup: Ready with configuration warnings."
      then
         return "Startup: Ready with configuration warnings.";
      elsif Text = "Ready with workspace project unavailable."
        or else Text = "Startup: ready with workspace project unavailable"
        or else Text = "Startup: Ready with workspace project unavailable"
        or else Text = "Startup: Ready with workspace project unavailable."
      then
         return "Startup: Ready with workspace project unavailable.";
      elsif Text = "Settings file is invalid."
        or else Raw_Text = "Settings: Settings file has an invalid format"
        or else Raw_Text = "Settings: Settings file has an invalid format."
        or else Text = "Settings: settings file is invalid"
        or else Text = "Settings: Settings file is invalid"
        or else Text = "Settings: Settings file is invalid."
      then
         return "Settings: File is invalid.";
      elsif Text = "Settings loaded with invalid values reset to defaults."
        or else Raw_Text = "Settings loaded with invalid values reset to defaults"
        or else Raw_Text = "Settings loaded with invalid values reset to defaults."
        or else Text = "Settings: settings loaded with invalid values reset to defaults"
        or else Text = "Settings: Settings loaded with invalid values reset to defaults"
        or else Text = "Settings: Settings loaded with invalid values reset to defaults."
      then
         return "Settings: Invalid values reset to defaults.";
      elsif Text = "Invalid setting value."
        or else Raw_Text = "Settings: Setting value is invalid"
        or else Raw_Text = "Settings: Setting value is invalid."
        or else Text = "Settings: invalid setting value"
        or else Text = "Settings: Invalid setting value"
        or else Text = "Settings: Invalid setting value."
      then
         return "Settings: Invalid setting value.";
      elsif Text = "Settings: selected setting is not editable"
        or else Text = "Settings: Selected setting is not editable"
        or else Text = "Settings: Selected setting is not editable."
      then
         return "Settings: Selected setting is not editable.";
      elsif Text = "Default keybindings active."
        or else Raw_Text = "Keybindings: Keybindings file malformed; default keybindings active"
        or else Raw_Text = "Keybindings: Keybindings file malformed; default keybindings active."
        or else Text = "Keybindings: default keybindings active"
        or else Text = "Keybindings: Default keybindings active"
        or else Text = "Keybindings: Default keybindings active."
      then
         return "Keybindings: Default keybindings active.";
      elsif Text = "Keybindings loaded with rejected bindings."
        or else Raw_Text = "Keybindings: Keybindings loaded with ignored invalid entries"
        or else Raw_Text = "Keybindings: Keybindings loaded with ignored invalid entries."
        or else Text = "Keybindings: keybindings loaded with rejected bindings"
        or else Text = "Keybindings: Keybindings loaded with rejected bindings"
        or else Text = "Keybindings: Keybindings loaded with rejected bindings."
      then
         return "Keybindings: Rejected invalid bindings.";
      elsif Text = "Shortcut is already assigned."
        or else Raw_Text = "Keybindings: Keybinding conflict: shortcut already assigned"
        or else Raw_Text = "Keybindings: Keybinding conflict: shortcut already assigned."
        or else Text = "Keybindings: shortcut is already assigned"
        or else Text = "Keybindings: Shortcut is already assigned"
        or else Text = "Keybindings: Shortcut is already assigned."
      then
         return "Keybindings: Shortcut is already assigned.";
      elsif Text = "Selected command is not bindable."
        or else Raw_Text = "Keybindings: Command is not bindable"
        or else Raw_Text = "Keybindings: Command is not bindable."
        or else Text = "Keybindings: selected command is not bindable"
        or else Text = "Keybindings: Selected command is not bindable"
        or else Text = "Keybindings: Selected command is not bindable."
      then
         return "Keybindings: Selected command is not bindable.";
      elsif Text = "Reset all configuration requires confirmation."
        or else Ada.Strings.Fixed.Index
          (Raw_Text, "Configuration: Reset all configuration requested.") = Raw_Text'First
        or else Text = "Configuration: reset all configuration requires confirmation"
        or else Text = "Configuration: Reset all configuration requires confirmation"
        or else Text = "Configuration: Reset all configuration requires confirmation."
      then
         return "Configuration: Reset all requires confirmation.";
      elsif Text = "All configuration domains reset."
        or else Raw_Text = "All configuration domains reset after explicit confirmation"
        or else Raw_Text = "All configuration domains reset after explicit confirmation."
        or else Text = "Configuration: all configuration domains reset"
        or else Text = "Configuration: All configuration domains reset"
        or else Text = "Configuration: All configuration domains reset."
      then
         return "Configuration: All domains reset.";
      elsif Text = "No matching commands."
        or else Ada.Strings.Fixed.Index
          (Raw_Text, "Command Palette: No commands match") = Raw_Text'First
        or else Text = "Command Palette: no matching commands"
        or else Text = "Command Palette: No matching commands"
        or else Text = "Command Palette: No matching commands."
      then
         return "Command Palette: No matching commands.";
      elsif Text = "No matching available commands."
        or else Ada.Strings.Fixed.Index
          (Raw_Text, "Command Palette: No available commands match") = Raw_Text'First
        or else Text = "Command Palette: no matching available commands"
        or else Text = "Command Palette: No matching available commands"
        or else Text = "Command Palette: No matching available commands."
      then
         return "Command Palette: No matching available commands.";
      elsif Text = "No available commands."
        or else Text = "Command Palette: no available commands"
        or else Text = "Command Palette: No available commands"
        or else Text = "Command Palette: No available commands."
      then
         return "Command Palette: No available commands.";
      elsif Text = "No command selected."
        or else Text = "Command Palette: no command selected"
        or else Text = "Command Palette: No command selected"
        or else Text = "Command Palette: No command selected."
      then
         return "Command Palette: No command selected.";
      elsif Text = "Command Palette closed."
        or else Raw_Text = "Command Palette: Command Palette is closed"
        or else Raw_Text = "Command Palette: Command Palette is closed."
        or else Text = "Command Palette: command palette closed"
        or else Text = "Command Palette: Command Palette closed"
        or else Text = "Command Palette: Command Palette closed."
      then
         return "Command Palette: Closed.";
      elsif Raw_Text = "Clipboard: No selection"
        or else Raw_Text = "Clipboard: No selection."
        or else Raw_Text = "Clipboard: No selected text"
        or else Raw_Text = "Clipboard: No selected text."
        or else Text = "Clipboard: no selected text"
        or else Text = "Clipboard: No selected text"
        or else Text = "Clipboard: No selected text."
      then
         return "Clipboard: No selected text.";
      elsif Raw_Text = "Clipboard: No clipboard to clear"
        or else Raw_Text = "Clipboard: No clipboard to clear."
        or else Raw_Text = "Clipboard: Clipboard is empty"
        or else Raw_Text = "Clipboard: Clipboard is empty."
        or else Text = "Clipboard: empty"
        or else Text = "Clipboard: Empty"
        or else Text = "Clipboard: Empty."
      then
         return "Clipboard: Empty.";
      elsif Raw_Text = "Clipboard: Invalid selection"
        or else Raw_Text = "Clipboard: Invalid selection."
        or else Text = "Clipboard: invalid selection"
        or else Text = "Clipboard: Invalid selection"
        or else Text = "Clipboard: Invalid selection."
      then
         return "Clipboard: Invalid selection.";
      elsif Text = "Bookmarks: no bookmarks"
        or else Text = "Bookmarks: No bookmarks"
        or else Text = "Bookmarks: No bookmarks."
      then
         return "Bookmarks: No bookmarks.";
      elsif Text = "Bookmarks: bookmark target unavailable"
        or else Text = "Bookmarks: Bookmark target unavailable"
        or else Text = "Bookmarks: Bookmark target unavailable."
        or else Text = "Bookmarks: target no longer exists"
        or else Text = "Bookmarks: Target no longer exists"
        or else Text = "Bookmarks: Target no longer exists."
      then
         return "Bookmarks: Target no longer exists.";
      elsif Text = "Buffer List: no next buffer"
        or else Text = "Buffer List: No next buffer"
        or else Text = "Buffer List: No next buffer."
      then
         return "Buffer List: No next buffer.";
      elsif Text = "Buffer List: no previous buffer"
        or else Text = "Buffer List: No previous buffer"
        or else Text = "Buffer List: No previous buffer."
      then
         return "Buffer List: No previous buffer.";
      elsif Text = "Buffer List: no matching buffers"
        or else Text = "Buffer List: No matching buffers"
        or else Text = "Buffer List: No matching buffers."
        or else Text = "Buffer List: no matching open buffers"
        or else Text = "Buffer List: No matching open buffers"
        or else Text = "Buffer List: No matching open buffers."
      then
         return "Buffer List: No matching open buffers.";
      elsif Text = "Buffer List: no pending marked targets"
        or else Text = "Buffer List: No pending marked targets"
        or else Text = "Buffer List: No pending marked targets."
        or else Text = "Buffer List: no pending close targets"
        or else Text = "Buffer List: No pending close targets"
        or else Text = "Buffer List: No pending close targets."
      then
         return "Buffer List: No pending close targets.";
      elsif Text = "Buffer List: no dirty-prune preview targets"
        or else Text = "Buffer List: No dirty-prune preview targets"
        or else Text = "Buffer List: No dirty-prune preview targets."
      then
         return "Buffer List: No dirty-prune preview targets.";
      elsif Text = "Buffer List: no marked buffers"
        or else Text = "Buffer List: No marked buffers"
        or else Text = "Buffer List: No marked buffers."
      then
         return "Buffer List: No marked buffers.";
      elsif Text = "Buffer List: no removed dirty-prune apply targets"
        or else Text = "Buffer List: No removed dirty-prune apply targets"
        or else Text = "Buffer List: No removed dirty-prune apply targets."
      then
         return "Buffer List: No removed dirty-prune apply targets.";
      elsif Text = "Buffer List: no pruned pending close targets"
        or else Text = "Buffer List: No pruned pending close targets"
        or else Text = "Buffer List: No pruned pending close targets."
      then
         return "Buffer List: No pruned pending close targets.";
      elsif Text = "Buffer List: selected row is not a buffer"
        or else Text = "Buffer List: Selected row is not a buffer"
        or else Text = "Buffer List: Selected row is not a buffer."
      then
         return "Buffer List: Selected row is not a buffer.";
      else
         return Text;
      end if;
   end Status_Segment_Text;

   function Outcome_Class_From_Severity
     (Severity : Unbounded_String) return String
   is
      Text : constant String := To_String (Severity);
   begin
      if Text = "success" or else Text = "ok" then
         return "success";
      elsif Text = "unavailable" or else Text = "warn"
        or else Text = "warning"
      then
         return "unavailable";
      elsif Text = "failed" or else Text = "failure" or else Text = "error" then
         return "failed";
      elsif Text = "cancelled" or else Text = "canceled" then
         return "cancelled";
      elsif Text = "pending" then
         return "pending";
      else
         return "info";
      end if;
   end Outcome_Class_From_Severity;

   function Is_Priority_Feedback
     (Severity : Unbounded_String) return Boolean
   is
      Class_Text : constant String := Outcome_Class_From_Severity (Severity);
   begin
      return Class_Text = "failed"
        or else Class_Text = "unavailable";
   end Is_Priority_Feedback;

   function Field_Or_Fallback
     (Value    : Unbounded_String;
      Fallback : String) return String
   is
   begin
      if Length (Value) = 0 then
         return Fallback;
      else
         return Segment_Text (Value);
      end if;
   end Field_Or_Fallback;

   function Format_Left
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Name : constant String :=
        (if not Snapshot.Has_Active_Buffer
           or else To_String (Snapshot.Buffer_Kind_Label) = "No buffer"
           or else To_String (Snapshot.File_State_Label) = "Unavailable"
         then "No active buffer."
         elsif Length (Snapshot.File_Label) > 0
         then Segment_Text (Snapshot.File_Label)
         elsif Length (Snapshot.File_Name) = 0
         then "Untitled"
         else Segment_Text (Snapshot.File_Name));
      Kind_Text : constant String :=
        (if Length (Snapshot.Buffer_Kind_Label) = 0
         then ""
         else " | " & Segment_Text (Snapshot.Buffer_Kind_Label));
      State_Text : constant String :=
        (if Length (Snapshot.File_State_Label) = 0
         then ""
         else " | " & Status_Segment_Text (Snapshot.File_State_Label));
      Dirty_Text : constant String :=
        (if Snapshot.Is_Dirty then " *" else "");
      Dirty_Label_Text : constant String :=
        (if Length (Snapshot.Dirty_State_Label) = 0
         then ""
         else " | " & Status_Segment_Text (Snapshot.Dirty_State_Label));
   begin
      return Name & Dirty_Text & Kind_Text & State_Text & Dirty_Label_Text;
   end Format_Left;

   function Status_Message_Kind_For
     (Label : Unbounded_String) return Status_Message_Kind
   is
      Text : constant String := Status_Segment_Text (Label);
   begin
      if Text = "Search: Target is stale; refresh required."
        or else Text = "Build: Target is stale; refresh required."
        or else Text = "Diagnostics: Target is stale; refresh required."
        or else Text = "Replace: Target is stale; refresh required."
      then
         return Status_Message_Search_Target_Stale;
      elsif Text = "Search: No search query."
        or else Text = "Find: No search query."
      then
         return Status_Message_Find_No_Query;
      elsif Text = "Search: No search results."
        or else Text = "Find: No matches."
      then
         return Status_Message_Find_No_Matches;
      elsif Text = "Quick Open: No matches."
      then
         return Status_Message_Quick_Open_No_Matches;
      elsif Text = "Quick Open: No project open."
      then
         return Status_Message_Quick_Open_No_Project;
      elsif Text = "Outline: Not refreshed."
      then
         return Status_Message_Outline_Not_Refreshed;
      elsif Text = "Build: failed"
        or else Text = "Build: Build failed"
      then
         return Status_Message_Build_Failed;
      elsif Text = "Build: succeeded"
        or else Text = "Build: ready"
        or else Text = "Build: Ready"
        or else Text = "Build: Ready."
        or else Text = "Build: No build request ready."
        or else Text = "Build: Execution unavailable."
      then
         return Status_Message_Build_Ready;
      elsif Text = "File Tree: No project open."
      then
         return Status_Message_File_Tree_No_Project;
      elsif Text = "Workspace: No workspace state."
        or else Text = "Workspace: No workspace restored."
      then
         return Status_Message_Workspace_No_Restore;
      elsif Text = "Workspace: Restored."
        or else Text = "Workspace: Workspace restored."
      then
         return Status_Message_Workspace_Restored;
      elsif Text = "Workspace: Partial restore."
        or else Text = "Workspace: Restored with missing entries skipped."
      then
         return Status_Message_Workspace_Partial_Restore;
      elsif Text = "Workspace: Unsaved confirmation."
      then
         return Status_Message_Workspace_Unsaved_Confirmation;
      elsif Text = "Recent Projects: No recent project."
        or else Text = "Recent Projects: No recent projects."
      then
         return Status_Message_Recent_Projects_None;
      else
         return Status_Message_Other;
      end if;
   end Status_Message_Kind_For;

   function Status_Build_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
   is
   begin
      if Snapshot.Build_Status_Kind /= Status_Message_Other then
         return Snapshot.Build_Status_Kind;
      else
         return Status_Message_Kind_For (Snapshot.Build_Status_Label);
      end if;
   end Status_Build_Message_Kind;

   function Status_Diagnostics_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
   is
   begin
      if Snapshot.Diagnostics_Status_Kind /= Status_Message_Other then
         return Snapshot.Diagnostics_Status_Kind;
      else
         return Status_Message_Kind_For (Snapshot.Diagnostics_Status_Label);
      end if;
   end Status_Diagnostics_Message_Kind;

   function Status_Search_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
   is
   begin
      if Snapshot.Search_Status_Kind /= Status_Message_Other then
         return Snapshot.Search_Status_Kind;
      else
         return Status_Message_Kind_For (Snapshot.Search_Status_Label);
      end if;
   end Status_Search_Message_Kind;

   function Status_Quick_Open_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
   is
   begin
      if Snapshot.Quick_Open_Status_Kind /= Status_Message_Other then
         return Snapshot.Quick_Open_Status_Kind;
      else
         return Status_Message_Kind_For (Snapshot.Quick_Open_Status_Label);
      end if;
   end Status_Quick_Open_Message_Kind;

   function Status_File_Tree_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
   is
   begin
      if Snapshot.File_Tree_Status_Kind /= Status_Message_Other then
         return Snapshot.File_Tree_Status_Kind;
      else
         return Status_Message_Kind_For (Snapshot.File_Tree_Status_Label);
      end if;
   end Status_File_Tree_Message_Kind;

   function Status_Workspace_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
   is
   begin
      if Snapshot.Workspace_Status_Kind /= Status_Message_Other then
         return Snapshot.Workspace_Status_Kind;
      else
         return Status_Message_Kind_For (Snapshot.Workspace_Status_Label);
      end if;
   end Status_Workspace_Message_Kind;

   function Status_Outline_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
   is
   begin
      if Snapshot.Outline_Status_Kind /= Status_Message_Other then
         return Snapshot.Outline_Status_Kind;
      else
         return Status_Message_Kind_For (Snapshot.Outline_Status_Label);
      end if;
   end Status_Outline_Message_Kind;

   function Status_Recent_Projects_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
   is
   begin
      if Snapshot.Recent_Projects_Status_Kind /= Status_Message_Other then
         return Snapshot.Recent_Projects_Status_Kind;
      else
         return Status_Message_Kind_For (Snapshot.Recent_Projects_Status_Label);
      end if;
   end Status_Recent_Projects_Message_Kind;

end Editor.Status_Bar.Text_Format;
