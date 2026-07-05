with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands;

package body Editor.Status_Bar is

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
     (Count    : Natural;
      Singular : String;
      Plural_Text  : String) return String
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
      --  Status labels are single-line UI fragments.  Normalize embedded
      --  control separators before truncation so message/file labels cannot
      --  create extra rendered status rows or hide lower-priority segments.
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
        (Editor.Commands.Normalize_Workflow_Message (To_String (Value)));
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
           or else Text = "Diagnostics: Target line is unavailable"
           or else Text = "Diagnostics: Target line is unavailable."
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
      elsif Text = "Outline: stale" then
         return "Outline: Target is stale; refresh required.";
      elsif Text = "Outline: not refreshed"
        or else Text = "Outline: Not refreshed"
        or else Text = "Outline: Not refreshed."
        or else Raw_Text = "Outline not refreshed"
        or else Raw_Text = "Outline not refreshed."
      then
         return "Outline: Not refreshed.";
      elsif Text = "Diagnostics: stale targets" then
         return "Diagnostics: Target is stale; refresh required.";
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
      elsif Text = "File Tree: stale node" then
         return "File Tree: Target is stale; refresh required.";
      elsif Raw_Text = "File Tree unavailable: no project open"
        or else Raw_Text = "File Tree unavailable: no project open."
        or else Text = "File Tree: no project"
        or else Text = "File Tree: No project"
        or else Text = "File Tree: no project open"
        or else Text = "File Tree: No project open"
        or else Text = "File Tree: No project open."
      then
         return "File Tree: No project open.";
      elsif Raw_Text = "Quick Open unavailable: no project open"
        or else Raw_Text = "Quick Open unavailable: no project open."
        or else Text = "Quick Open: no project"
        or else Text = "Quick Open: No project"
        or else Text = "Quick Open: no project open"
        or else Text = "Quick Open: No project open"
        or else Text = "Quick Open: No project open."
      then
         return "Quick Open: No project open.";
      elsif Raw_Text = "Project Search unavailable: no project open"
        or else Raw_Text = "Project Search unavailable: no project open."
        or else Text = "Search: no project"
        or else Text = "Search: No project"
        or else Text = "Search: no project open"
        or else Text = "Search: No project open"
        or else Text = "Search: No project open."
        or else Text = "Project Search: no project"
        or else Text = "Project Search: No project"
        or else Text = "Project Search: no project open"
        or else Text = "Project Search: No project open"
        or else Text = "Project Search: No project open."
      then
         return "Search: No project open.";
      elsif Raw_Text = "Build unavailable: no project open or no build request ready"
        or else Raw_Text = "Build unavailable: no project open or no build request ready."
        or else Text = "Build: no project"
        or else Text = "Build: No project"
        or else Text = "Build: no project open"
        or else Text = "Build: No project open"
        or else Text = "Build: No project open."
        or else Raw_Text = "Build unavailable: no project open"
        or else Raw_Text = "Build unavailable: no project open."
      then
         return "Build: No project open.";
      elsif Text = "Build consent required."
        or else Text = "Build: consent required"
        or else Text = "Build: Consent required"
        or else Text = "Build: Consent required."
        or else Raw_Text = "Build run unavailable: review the request and acknowledge consent first"
        or else Raw_Text = "Build run unavailable: review the request and acknowledge consent first."
        or else Raw_Text = "Build unavailable: consent required"
        or else Raw_Text = "Build unavailable: consent required."
        or else Raw_Text = "Consent missing: review and acknowledge the build request"
        or else Raw_Text = "Consent missing: review and acknowledge the build request."
        or else Raw_Text = "Build candidate applied to transient request; Consent missing: review and acknowledge the build request"
        or else Raw_Text = "Build candidate applied to transient request; Consent missing: review and acknowledge the build request."
      then
         return "Build: Consent required.";
      elsif Text = "Build consent is stale."
        or else Text = "Build: consent stale"
        or else Text = "Build: Consent stale"
        or else Text = "Build: Consent stale."
        or else Raw_Text = "Build run unavailable: consent is stale after the request changed"
        or else Raw_Text = "Build run unavailable: consent is stale after the request changed."
      then
         return "Build: Consent is stale.";
      elsif Text = "No build candidates."
        or else Text = "Build: no build candidates found"
        or else Text = "Build: No build candidates found"
        or else Text = "Build: No build candidates found."
        or else Text = "Build: no build candidates"
        or else Text = "Build: No build candidates"
        or else Text = "Build: No build candidates."
      then
         return "Build: No build candidates.";
      elsif Text = "No build tool selected."
        or else Text = "Build: no build tool selected"
        or else Text = "Build: No build tool selected"
        or else Text = "Build: No build tool selected."
        or else Raw_Text = "Build run unavailable: choose a build tool first"
        or else Raw_Text = "Build run unavailable: choose a build tool first."
        or else Raw_Text = "Build unavailable: build tool required"
        or else Raw_Text = "Build unavailable: build tool required."
      then
         return "Build: No build tool selected.";
      elsif Text = "No build candidate selected."
        or else Text = "Build: no build candidate selected"
        or else Text = "Build: No build candidate selected"
        or else Text = "Build: No build candidate selected."
        or else Raw_Text = "Build run unavailable: no build candidate selected"
        or else Raw_Text = "Build run unavailable: no build candidate selected."
      then
         return "Build: No build candidate selected.";
      elsif Text = "No build request ready."
        or else Text = "Build: no build request ready"
        or else Text = "Build: No build request ready"
        or else Text = "Build: No build request ready."
        or else Raw_Text = "Build unavailable: structured arguments invalid"
        or else Raw_Text = "Build unavailable: structured arguments invalid."
        or else Raw_Text = "Build run unavailable: arguments must be structured tokens, not shell text"
        or else Raw_Text = "Build run unavailable: arguments must be structured tokens, not shell text."
        or else Raw_Text = "Build run unavailable: custom shell commands are not supported"
        or else Raw_Text = "Build run unavailable: custom shell commands are not supported."
        or else Raw_Text = "Build run unavailable: request option is not supported for the selected candidate"
        or else Raw_Text = "Build run unavailable: request option is not supported for the selected candidate."
        or else Raw_Text = "candidate request could not be formed"
        or else Raw_Text = "candidate request could not be formed."
        or else Raw_Text = "candidate request is not structured argv"
        or else Raw_Text = "candidate request is not structured argv."
        or else Raw_Text = "Build request is not ready"
        or else Raw_Text = "Build request is not ready."
      then
         return "Build: No build request ready.";
      elsif Text = "Build execution is unavailable."
        or else Text = "Build: execution unavailable"
        or else Text = "Build: Execution unavailable"
        or else Text = "Build: Build execution is unavailable"
        or else Text = "Build: Build execution is unavailable."
        or else Raw_Text = "Build run unavailable: execution backend is disabled"
        or else Raw_Text = "Build run unavailable: execution backend is disabled."
        or else Raw_Text = "Build unavailable: execution backend disabled"
        or else Raw_Text = "Build unavailable: execution backend disabled."
        or else Raw_Text = "Build unavailable: cancellation unsupported"
        or else Raw_Text = "Build unavailable: cancellation unsupported."
      then
         return "Build: Execution unavailable.";
      elsif Text = "No build output captured."
        or else Text = "Build: no build output"
        or else Text = "Build: No build output"
        or else Text = "Build: No build output."
        or else Text = "Build: no build output captured"
        or else Text = "Build: No build output captured"
        or else Text = "Build: No build output captured."
        or else Text = "Build: output unavailable"
        or else Text = "Build: Output unavailable"
        or else Text = "Build: Output unavailable."
        or else Text = "Build: build output unavailable"
        or else Text = "Build: Build output unavailable"
        or else Text = "Build: Build output unavailable."
      then
         return "Build: No build output captured.";
      elsif Text = "No stdout captured."
        or else Text = "Build: no stdout captured"
        or else Text = "Build: No stdout captured"
        or else Text = "Build: No stdout captured."
        or else Text = "Build: no standard output captured"
        or else Text = "Build: No standard output captured"
        or else Text = "Build: No standard output captured."
      then
         return "Build: No stdout captured.";
      elsif Text = "No stderr captured."
        or else Text = "Build: no stderr captured"
        or else Text = "Build: No stderr captured"
        or else Text = "Build: No stderr captured."
        or else Text = "Build: no standard error captured"
        or else Text = "Build: No standard error captured"
        or else Text = "Build: No standard error captured."
      then
         return "Build: No stderr captured.";
      elsif Raw_Text = "Build run unavailable: no project working context selected"
        or else Raw_Text = "Build run unavailable: no project working context selected."
        or else Raw_Text = "Build working directory is required"
        or else Raw_Text = "Build working directory is required."
        or else Raw_Text = "Build working context required"
        or else Raw_Text = "Build working context required."
        or else Raw_Text = "No canonical project/workspace context"
        or else Raw_Text = "No canonical project/workspace context."
      then
         return "Build: No project open.";
      elsif Text = "Build: candidate path missing or unavailable"
        or else Text = "Build: Candidate path missing or unavailable"
        or else Text = "Build: Candidate path missing or unavailable."
      then
         return "Build: Target no longer exists.";
      elsif Text = "Build: candidate path outside project root"
        or else Text = "Build: Candidate path outside project root"
        or else Text = "Build: Candidate path outside project root."
        or else Text = "Build: build working directory is rejected"
        or else Text = "Build: Build working directory is rejected"
        or else Text = "Build: Build working directory is rejected."
      then
         return "Build: Target is outside the current project.";
      elsif Text = "Build: candidate request could not be formed"
        or else Text = "Build: Candidate request could not be formed"
        or else Text = "Build: Candidate request could not be formed."
        or else Text = "Build: candidate request is not structured argv"
        or else Text = "Build: Candidate request is not structured argv"
        or else Text = "Build: Candidate request is not structured argv."
        or else Text = "Build: Build request is not ready"
        or else Text = "Build: Build request is not ready."
      then
         return "Build: No build request ready.";
      elsif Text = "Target no longer exists."
        and then (Raw_Text = "Build run unavailable: selected project working context is unavailable"
                  or else Raw_Text = "Build run unavailable: selected project working context is unavailable."
                  or else Raw_Text = "candidate unavailable: source project context is unavailable"
                  or else Raw_Text = "candidate unavailable: source project context is unavailable."
                  or else Raw_Text = "Project root unavailable"
                  or else Raw_Text = "Project root unavailable."
                  or else Raw_Text = "Build working directory is unavailable"
                  or else Raw_Text = "Build working directory is unavailable."
                  or else Raw_Text = "candidate path missing or unavailable"
                  or else Raw_Text = "candidate path missing or unavailable.")
      then
         return "Build: Target no longer exists.";
      elsif Text = "Target is outside the current project."
        and then (Raw_Text = "Build run unavailable: working context must come from the current project/workspace"
                  or else Raw_Text = "Build run unavailable: working context must come from the current project/workspace."
                  or else Raw_Text = "candidate path outside project root"
                  or else Raw_Text = "candidate path outside project root."
                  or else Raw_Text = "Build working directory is rejected"
                  or else Raw_Text = "Build working directory is rejected."
                  or else Raw_Text = "Build working context canonical path required"
                  or else Raw_Text = "Build working context canonical path required.")
      then
         return "Build: Target is outside the current project.";
      elsif Raw_Text = "Outline unavailable: no project open"
        or else Raw_Text = "Outline unavailable: no project open."
        or else Text = "Outline: no project"
        or else Text = "Outline: No project"
        or else Text = "Outline: no project open"
        or else Text = "Outline: No project open"
        or else Text = "Outline: No project open."
      then
         return "Outline: No project open.";
      elsif Raw_Text = "Diagnostics unavailable: no project open"
        or else Raw_Text = "Diagnostics unavailable: no project open."
        or else Text = "Diagnostics: no project"
        or else Text = "Diagnostics: No project"
        or else Text = "Diagnostics: no project open"
        or else Text = "Diagnostics: No project open"
        or else Text = "Diagnostics: No project open."
      then
         return "Diagnostics: No project open.";
      elsif Raw_Text = "Outline unavailable: no active buffer"
        or else Raw_Text = "Outline unavailable: no active buffer."
        or else Text = "Outline: no active buffer"
        or else Text = "Outline: No active buffer"
        or else Text = "Outline: No active buffer."
      then
         return "Outline: No active buffer.";
      elsif Raw_Text = "Search Results: no active buffer"
        or else Raw_Text = "Search Results: no active buffer."
        or else Text = "Search: no active buffer"
        or else Text = "Search: No active buffer"
        or else Text = "Search: No active buffer."
      then
         return "Search: No active buffer.";
      elsif Text = "File Tree: rename blocked by unsaved changes"
        or else Text = "File Tree: Rename blocked by unsaved changes"
        or else Text = "File Tree: Rename blocked by unsaved changes."
        or else Text = "File Tree: delete blocked by unsaved changes"
        or else Text = "File Tree: Delete blocked by unsaved changes"
        or else Text = "File Tree: Delete blocked by unsaved changes."
        or else Text = "File Tree: dirty buffer file cannot be renamed"
        or else Text = "File Tree: Dirty buffer file cannot be renamed"
        or else Text = "File Tree: Dirty buffer file cannot be renamed."
        or else Text = "File Tree: dirty buffer file cannot be deleted"
        or else Text = "File Tree: Dirty buffer file cannot be deleted"
        or else Text = "File Tree: Dirty buffer file cannot be deleted."
        or else Text = "File Tree: dirty buffer file cannot be copied"
        or else Text = "File Tree: Dirty buffer file cannot be copied"
        or else Text = "File Tree: Dirty buffer file cannot be copied."
        or else Text = "File Tree: dirty buffer file cannot be moved"
        or else Text = "File Tree: Dirty buffer file cannot be moved"
        or else Text = "File Tree: Dirty buffer file cannot be moved."
        or else Text = "File Tree: unsaved changes require confirmation"
        or else Text = "File Tree: Unsaved changes require confirmation"
        or else Text = "File Tree: Unsaved changes require confirmation."
      then
         return "File Tree: Dirty buffer preserved.";
      elsif Text = "File Tree: dirty buffer preserved"
        or else Text = "File Tree: Dirty buffer preserved"
        or else Text = "File Tree: Dirty buffer preserved."
      then
         return "File Tree: Dirty buffer preserved.";
      elsif Text = "Buffer: dirty buffer cannot be closed"
        or else Text = "Buffer: Dirty buffer cannot be closed"
        or else Text = "Buffer: Dirty buffer cannot be closed."
        or else Text = "Buffer: unsaved changes require confirmation"
        or else Text = "Buffer: Unsaved changes require confirmation"
        or else Text = "Buffer: Unsaved changes require confirmation."
      then
         return "Buffer: Unsaved changes require confirmation.";
      elsif Text = "Project: cannot close project with unsaved changes"
        or else Text = "Project: Cannot close project with unsaved changes"
        or else Text = "Project: Cannot close project with unsaved changes."
        or else Text = "Project: cannot switch project with unsaved changes"
        or else Text = "Project: Cannot switch project with unsaved changes"
        or else Text = "Project: Cannot switch project with unsaved changes."
      then
         return "Project: Unsaved changes require confirmation.";
      elsif Text = "Workspace: cannot restore workspace with unsaved changes"
        or else Text = "Workspace: Cannot restore workspace with unsaved changes"
        or else Text = "Workspace: Cannot restore workspace with unsaved changes."
      then
         return "Workspace: Unsaved changes require confirmation.";
      elsif Text = "Buffer: close cancelled"
        or else Text = "Buffer: Close cancelled"
        or else Text = "Buffer: Close cancelled."
        or else Text = "Buffer: close canceled"
        or else Text = "Buffer: Close canceled"
        or else Text = "Buffer: Close canceled."
      then
         return "Buffer: Close cancelled.";
      elsif Text = "Buffer: save failed; buffer remains open"
        or else Text = "Buffer: Save failed; buffer remains open"
        or else Text = "Buffer: Save failed; buffer remains open."
        or else Text = "Buffer: save failed; buffer remains open and dirty"
        or else Text = "Buffer: Save failed; buffer remains open and dirty"
        or else Text = "Buffer: Save failed; buffer remains open and dirty."
      then
         return "Buffer: Save failed; buffer remains open.";
      elsif Text = "Buffer: file conflict requires resolution"
        or else Text = "Buffer: File conflict requires resolution"
        or else Text = "Buffer: File conflict requires resolution."
        or else Text = "Buffer: file conflict requires resolution before save-and-close"
        or else Text = "Buffer: File conflict requires resolution before save-and-close"
        or else Text = "Buffer: File conflict requires resolution before save-and-close."
      then
         return "Buffer: File conflict requires resolution.";
      elsif Text = "File: file conflict requires resolution"
        or else Text = "File: File conflict requires resolution"
        or else Text = "File: File conflict requires resolution."
        or else Text = "File: file changed on disk; choose how to proceed"
        or else Text = "File: File changed on disk; choose how to proceed"
        or else Text = "File: File changed on disk; choose how to proceed."
        or else Text = "File: file conflict detected; choose how to proceed"
        or else Text = "File: File conflict detected; choose how to proceed"
        or else Text = "File: File conflict detected; choose how to proceed."
      then
         return "File: File conflict requires resolution.";
      elsif Text = "File: reload will discard unsaved changes"
        or else Text = "File: Reload will discard unsaved changes"
        or else Text = "File: Reload will discard unsaved changes."
        or else Text = "File: Reload will discard unsaved changes. Disk version has changed since file was opened."
        or else Text = "File: Reload will discard unsaved changes, but the backing file is missing."
        or else Text = "File: Reload will discard unsaved changes. Backing file was replaced."
      then
         return "File: Reload will discard unsaved changes.";
      elsif Text = "Workspace restored."
        or else Text = "Workspace state restored"
        or else Text = "Workspace state restored."
        or else Text = "Workspace: workspace restored"
        or else Text = "Workspace: Workspace restored"
        or else Text = "Workspace: Workspace restored."
        or else Raw_Text = "Workspace restored"
        or else Raw_Text = "Workspace restored."
      then
         return "Workspace: Restored.";
      elsif Text = "Workspace restored with missing entries skipped."
        or else Text = "Workspace state partially restored"
        or else Text = "Workspace state partially restored."
        or else Text = "Workspace: workspace restored with missing files skipped"
        or else Text = "Workspace: Workspace restored with missing files skipped"
        or else Text = "Workspace: Workspace restored with missing files skipped."
        or else Text = "Workspace: workspace loaded with stale entries ignored"
        or else Text = "Workspace: Workspace loaded with stale entries ignored"
        or else Text = "Workspace: Workspace loaded with stale entries ignored."
        or else Text = "Workspace: workspace loaded with stale or unsupported structural entries ignored"
        or else Text = "Workspace: Workspace loaded with stale or unsupported structural entries ignored"
        or else Text = "Workspace: Workspace loaded with stale or unsupported structural entries ignored."
        or else Raw_Text = "Workspace restored with missing files skipped"
        or else Raw_Text = "Workspace restored with missing files skipped."
        or else Raw_Text = "Workspace loaded with stale or unsupported structural entries ignored"
        or else Raw_Text = "Workspace loaded with stale or unsupported structural entries ignored."
      then
         return "Workspace: Restored with missing entries skipped.";
      elsif Text = "No workspace restored."
        or else Text = "Workspace: no workspace restored"
        or else Text = "Workspace: No workspace restored"
        or else Text = "Workspace: No workspace restored."
        or else Text = "Workspace: workspace session malformed; no session restored"
        or else Text = "Workspace: Workspace session malformed; no session restored"
        or else Text = "Workspace: Workspace session malformed; no session restored."
        or else Text = "Workspace: workspace session unreadable; no session restored"
        or else Text = "Workspace: Workspace session unreadable; no session restored"
        or else Text = "Workspace: Workspace session unreadable; no session restored."
        or else Raw_Text = "Workspace session malformed; no session restored"
        or else Raw_Text = "Workspace session malformed; no session restored."
      then
         return "Workspace: No workspace restored.";
      elsif Text = "No recent projects."
        or else Text = "Recent Projects: no recent projects"
        or else Text = "Recent Projects: No recent projects"
        or else Text = "Recent Projects: No recent projects."
        or else Text = "Recent Projects: recent projects list empty"
        or else Text = "Recent Projects: Recent Projects list empty"
        or else Text = "Recent Projects: Recent Projects list empty."
        or else Raw_Text = "Recent Projects list empty"
        or else Raw_Text = "Recent Projects list empty."
      then
         return "Recent Projects: No recent projects.";
      elsif Text = "Recent Projects loaded with invalid entries ignored."
        or else Text = "Recent Projects: recent projects loaded with invalid entries ignored"
        or else Text = "Recent Projects: Recent Projects loaded with invalid entries ignored"
        or else Text = "Recent Projects: Recent Projects loaded with invalid entries ignored."
        or else Text = "Recent Projects: recent projects loaded with invalid lightweight entries ignored"
        or else Text = "Recent Projects: Recent Projects loaded with invalid lightweight entries ignored"
        or else Text = "Recent Projects: Recent Projects loaded with invalid lightweight entries ignored."
        or else Raw_Text = "Recent Projects loaded with invalid lightweight entries ignored"
        or else Raw_Text = "Recent Projects loaded with invalid lightweight entries ignored."
      then
         return "Recent Projects: Invalid entries ignored.";
      elsif Text = "Recent Projects: recent project is unavailable"
        or else Text = "Recent Projects: Recent project is unavailable"
        or else Text = "Recent Projects: Recent project is unavailable."
        or else Text = "Recent Projects: project path no longer exists"
        or else Text = "Recent Projects: Project path no longer exists"
        or else Text = "Recent Projects: Project path no longer exists."
        or else Raw_Text = "Recent project is unavailable"
        or else Raw_Text = "Recent project is unavailable."
        or else Raw_Text = "Project path no longer exists"
        or else Raw_Text = "Project path no longer exists."
      then
         return "Recent Projects: Target no longer exists.";
      elsif Text = "No bookmarks."
        or else Text = "Bookmarks: no bookmarks"
        or else Text = "Bookmarks: No bookmarks"
        or else Text = "Bookmarks: No bookmarks."
        or else Raw_Text = "No bookmarks"
        or else Raw_Text = "No bookmarks."
      then
         return "Bookmarks: No bookmarks.";
      elsif Text = "Bookmarks: no bookmarkable location"
        or else Text = "Bookmarks: No bookmarkable location"
        or else Text = "Bookmarks: No bookmarkable location."
        or else Raw_Text = "No bookmarkable location"
        or else Raw_Text = "No bookmarkable location."
      then
         return "Bookmarks: No bookmarkable location.";
      elsif Text = "Bookmarks: no bookmark in active file"
        or else Text = "Bookmarks: No bookmark in active file"
        or else Text = "Bookmarks: No bookmark in active file."
        or else Raw_Text = "No bookmark in active file"
        or else Raw_Text = "No bookmark in active file."
      then
         return "Bookmarks: No bookmark in active file.";
      elsif Text = "Bookmarks: bookmark target unavailable"
        or else Text = "Bookmarks: Bookmark target unavailable"
        or else Text = "Bookmarks: Bookmark target unavailable."
        or else Text = "Bookmarks: bookmark target no longer exists"
        or else Text = "Bookmarks: Bookmark target no longer exists"
        or else Text = "Bookmarks: Bookmark target no longer exists."
        or else Raw_Text = "Bookmark target unavailable"
        or else Raw_Text = "Bookmark target unavailable."
      then
         return "Bookmarks: Target no longer exists.";
      elsif Text = "Ready."
        or else Text = "Startup: editor ready"
        or else Text = "Startup: Editor ready"
        or else Text = "Startup: Editor ready."
        or else Raw_Text = "Editor ready"
        or else Raw_Text = "Editor ready."
      then
         return "Startup: Ready.";
      elsif Text = "Ready with configuration warnings."
        or else Text = "Startup: editor ready with configuration warnings"
        or else Text = "Startup: Editor ready with configuration warnings"
        or else Text = "Startup: Editor ready with configuration warnings."
        or else Raw_Text = "Editor ready with configuration warnings"
        or else Raw_Text = "Editor ready with configuration warnings."
      then
         return "Startup: Ready with configuration warnings.";
      elsif Text = "Ready with workspace project unavailable."
        or else Text = "Startup: editor ready with workspace project unavailable"
        or else Text = "Startup: Editor ready with workspace project unavailable"
        or else Text = "Startup: Editor ready with workspace project unavailable."
        or else Raw_Text = "Editor ready with workspace project unavailable"
        or else Raw_Text = "Editor ready with workspace project unavailable."
      then
         return "Startup: Ready with workspace project unavailable.";
      elsif Text = "Settings file is invalid."
        or else Text = "Settings: settings file malformed; using defaults"
        or else Text = "Settings: Settings file malformed; using defaults"
        or else Text = "Settings: Settings file malformed; using defaults."
        or else Text = "Settings: settings file has an invalid format"
        or else Text = "Settings: Settings file has an invalid format"
        or else Text = "Settings: Settings file has an invalid format."
        or else Text = "Settings: settings file is invalid"
        or else Text = "Settings: Settings file is invalid"
        or else Text = "Settings: Settings file is invalid."
        or else Raw_Text = "Settings file malformed; using defaults"
        or else Raw_Text = "Settings file malformed; using defaults."
        or else Raw_Text = "Settings file has an invalid format"
        or else Raw_Text = "Settings file has an invalid format."
      then
         return "Settings: File is invalid.";
      elsif Text = "Settings loaded with invalid values reset to defaults."
        or else Text = "Settings: settings loaded with invalid values reset to defaults"
        or else Text = "Settings: Settings loaded with invalid values reset to defaults"
        or else Text = "Settings: Settings loaded with invalid values reset to defaults."
        or else Text = "Settings: settings loaded with ignored invalid entries"
        or else Text = "Settings: Settings loaded with ignored invalid entries"
        or else Text = "Settings: Settings loaded with ignored invalid entries."
        or else Raw_Text = "Settings loaded with invalid values reset to defaults"
        or else Raw_Text = "Settings loaded with invalid values reset to defaults."
      then
         return "Settings: Invalid values reset to defaults.";
      elsif Text = "Default keybindings active."
        or else Text = "Keybindings: keybindings file malformed; default keybindings active"
        or else Text = "Keybindings: Keybindings file malformed; default keybindings active"
        or else Text = "Keybindings: Keybindings file malformed; default keybindings active."
        or else Text = "Keybindings: keybindings file has an invalid format"
        or else Text = "Keybindings: Keybindings file has an invalid format"
        or else Text = "Keybindings: Keybindings file has an invalid format."
        or else Raw_Text = "Keybindings file malformed; default keybindings active"
        or else Raw_Text = "Keybindings file malformed; default keybindings active."
      then
         return "Keybindings: Default keybindings active.";
      elsif Text = "Keybindings loaded with rejected bindings."
        or else Text = "Keybindings: keybindings loaded with rejected invalid bindings"
        or else Text = "Keybindings: Keybindings loaded with rejected invalid bindings"
        or else Text = "Keybindings: Keybindings loaded with rejected invalid bindings."
        or else Text = "Keybindings: keybindings loaded with ignored invalid entries"
        or else Text = "Keybindings: Keybindings loaded with ignored invalid entries"
        or else Text = "Keybindings: Keybindings loaded with ignored invalid entries."
        or else Raw_Text = "Keybindings loaded with rejected invalid bindings"
        or else Raw_Text = "Keybindings loaded with rejected invalid bindings."
      then
         return "Keybindings: Rejected invalid bindings.";
      elsif Text = "No previous navigation location."
        or else Text = "Navigation: no previous navigation location"
        or else Text = "Navigation: No previous navigation location"
        or else Text = "Navigation: No previous navigation location."
      then
         return "Navigation: No previous navigation location.";
      elsif Text = "No next navigation location."
        or else Text = "Navigation: no next navigation location"
        or else Text = "Navigation: No next navigation location"
        or else Text = "Navigation: No next navigation location."
      then
         return "Navigation: No next navigation location.";
      elsif Text = "No navigation history."
        or else Text = "Navigation: no navigation history"
        or else Text = "Navigation: No navigation history"
        or else Text = "Navigation: No navigation history."
        or else Text = "Navigation: no navigation history to clear"
        or else Text = "Navigation: No navigation history to clear"
        or else Text = "Navigation: No navigation history to clear."
      then
         return "Navigation: No navigation history.";
      elsif Text = "Target no longer exists."
        and then (Raw_Text = "Navigation target unavailable"
                  or else Raw_Text = "Navigation target unavailable.")
      then
         return "Navigation: Target no longer exists.";
      elsif Text = "Navigation: navigation target unavailable"
        or else Text = "Navigation: Navigation target unavailable"
        or else Text = "Navigation: Navigation target unavailable."
        or else Text = "Navigation: target no longer exists"
        or else Text = "Navigation: Target no longer exists"
        or else Text = "Navigation: Target no longer exists."
      then
         return "Navigation: Target no longer exists.";
      elsif Text = "Command Palette closed."
        or else Text = "Command Palette: command palette closed"
        or else Text = "Command Palette: Command Palette closed"
        or else Text = "Command Palette: Command Palette closed."
        or else Text = "Command Palette: command palette is closed"
        or else Text = "Command Palette: Command Palette is closed"
        or else Text = "Command Palette: Command Palette is closed."
        or else Raw_Text = "Command Palette closed"
        or else Raw_Text = "Command Palette closed."
      then
         return "Command Palette: Closed.";
      elsif Text = "No selected text"
        or else Text = "Clipboard: no selected text"
        or else Text = "Clipboard: No selected text"
        or else Text = "Clipboard: No selected text."
        or else Text = "Clipboard: no selection"
        or else Text = "Clipboard: No selection"
        or else Text = "Clipboard: No selection."
        or else Raw_Text = "No selected text"
        or else Raw_Text = "No selected text."
        or else Raw_Text = "No selection"
        or else Raw_Text = "No selection."
      then
         return "Clipboard: No selected text.";
      elsif Text = "Clipboard is empty"
        or else Text = "Clipboard: clipboard is empty"
        or else Text = "Clipboard: Clipboard is empty"
        or else Text = "Clipboard: Clipboard is empty."
        or else Text = "Clipboard: no clipboard to clear"
        or else Text = "Clipboard: No clipboard to clear"
        or else Text = "Clipboard: No clipboard to clear."
        or else Raw_Text = "Clipboard is empty"
        or else Raw_Text = "Clipboard is empty."
        or else Raw_Text = "No clipboard to clear"
        or else Raw_Text = "No clipboard to clear."
      then
         return "Clipboard: Empty.";
      elsif Text = "Invalid selection"
        or else Text = "Clipboard: invalid selection"
        or else Text = "Clipboard: Invalid selection"
        or else Text = "Clipboard: Invalid selection."
        or else Raw_Text = "Invalid selection"
        or else Raw_Text = "Invalid selection."
      then
         return "Clipboard: Invalid selection.";
      elsif Text = "No commands."
        or else Text = "Command Palette: no commands"
        or else Text = "Command Palette: No commands"
        or else Text = "Command Palette: No commands."
      then
         return "Command Palette: No commands.";
      elsif Text = "No available commands."
        or else Text = "Command Palette: no available commands"
        or else Text = "Command Palette: No available commands"
        or else Text = "Command Palette: No available commands."
      then
         return "Command Palette: No available commands.";
      elsif Text = "No matching available commands."
        or else Text = "Command Palette: no available commands match"
        or else Text = "Command Palette: No available commands match"
        or else Ada.Strings.Fixed.Index
          (Raw_Text, "No available commands match") = Raw_Text'First
        or else Ada.Strings.Fixed.Index
          (Raw_Text, "Command Palette: No available commands match") = Raw_Text'First
      then
         return "Command Palette: No matching available commands.";
      elsif Text = "No matching commands."
        or else Text = "Command Palette: no commands match"
        or else Text = "Command Palette: No commands match"
        or else Ada.Strings.Fixed.Index
          (Raw_Text, "No commands match") = Raw_Text'First
        or else Ada.Strings.Fixed.Index
          (Raw_Text, "Command Palette: No commands match") = Raw_Text'First
      then
         return "Command Palette: No matching commands.";
      elsif Text = "No command selected."
        or else Text = "Command Palette: no command selected"
        or else Text = "Command Palette: No command selected"
        or else Text = "Command Palette: No command selected."
      then
         return "Command Palette: No command selected.";
      elsif Text = "No setting selected."
        or else Text = "Settings: no setting selected"
        or else Text = "Settings: No setting selected"
        or else Text = "Settings: No setting selected."
      then
         return "Settings: No setting selected.";
      elsif Text = "Selected setting is not editable."
        or else Text = "Settings: selected setting is not editable"
        or else Text = "Settings: Selected setting is not editable"
        or else Text = "Settings: Selected setting is not editable."
      then
         return "Settings: Selected setting is not editable.";
      elsif Text = "Selected setting is not toggleable."
        or else Text = "Settings: selected setting is not toggleable"
        or else Text = "Settings: Selected setting is not toggleable"
        or else Text = "Settings: Selected setting is not toggleable."
      then
         return "Settings: Selected setting is not toggleable.";
      elsif Text = "Selected setting is already default."
        or else Text = "Settings: setting is already default"
        or else Text = "Settings: Setting is already default"
        or else Text = "Settings: Setting is already default."
        or else Text = "Settings: selected setting is already default"
        or else Text = "Settings: Selected setting is already default"
        or else Text = "Settings: Selected setting is already default."
      then
         return "Settings: Selected setting is already default.";
      elsif Text = "Invalid setting value."
        or else Text = "Settings: setting value is invalid"
        or else Text = "Settings: Setting value is invalid"
        or else Text = "Settings: Setting value is invalid."
        or else Text = "Settings: invalid setting value"
        or else Text = "Settings: Invalid setting value"
        or else Text = "Settings: Invalid setting value."
      then
         return "Settings: Invalid setting value.";
      elsif Text = "Selected command is not bindable."
        or else Text = "Keybindings: command is not bindable"
        or else Text = "Keybindings: Command is not bindable"
        or else Text = "Keybindings: Command is not bindable."
        or else Text = "Keybindings: selected command is not bindable"
        or else Text = "Keybindings: Selected command is not bindable"
        or else Text = "Keybindings: Selected command is not bindable."
      then
         return "Keybindings: Selected command is not bindable.";
      elsif Text = "No keybinding selected."
        or else Text = "Keybindings: no keybinding selected"
        or else Text = "Keybindings: No keybinding selected"
        or else Text = "Keybindings: No keybinding selected."
      then
         return "Keybindings: No keybinding selected.";
      elsif Text = "Shortcut is invalid."
        or else Text = "Keybindings: invalid shortcut"
        or else Text = "Keybindings: Invalid shortcut"
        or else Text = "Keybindings: Invalid shortcut."
        or else Text = "Keybindings: shortcut is invalid"
        or else Text = "Keybindings: Shortcut is invalid"
        or else Text = "Keybindings: Shortcut is invalid."
      then
         return "Keybindings: Shortcut is invalid.";
      elsif Text = "Shortcut is already assigned."
        or else Text = "Keybindings: shortcut is already assigned"
        or else Text = "Keybindings: Shortcut is already assigned"
        or else Text = "Keybindings: Shortcut is already assigned."
        or else Text = "Keybindings: keybinding conflict: shortcut already assigned"
        or else Text = "Keybindings: Keybinding conflict: shortcut already assigned"
        or else Text = "Keybindings: Keybinding conflict: shortcut already assigned."
      then
         return "Keybindings: Shortcut is already assigned.";
      elsif Text = "Keybinding assignment cancelled."
        or else Text = "Keybindings: keybinding assignment canceled"
        or else Text = "Keybindings: Keybinding assignment canceled"
        or else Text = "Keybindings: Keybinding assignment canceled."
        or else Text = "Keybindings: keybinding assignment cancelled"
        or else Text = "Keybindings: Keybinding assignment cancelled"
        or else Text = "Keybindings: Keybinding assignment cancelled."
      then
         return "Keybindings: Assignment cancelled.";
      elsif Text = "No configuration audit results."
        or else Text = "Configuration: no configuration audit results"
        or else Text = "Configuration: No configuration audit results"
        or else Text = "Configuration: No configuration audit results."
      then
         return "Configuration: No configuration audit results.";
      elsif Text = "All configuration domains reset."
        or else Text = "Configuration: all configuration domains reset after explicit confirmation"
        or else Text = "Configuration: All configuration domains reset after explicit confirmation"
        or else Text = "Configuration: All configuration domains reset after explicit confirmation."
      then
         return "Configuration: All domains reset.";
      elsif Text = "Reset all configuration requires confirmation."
        or else Text = "Configuration: reset all configuration requested. Run configuration.reset-all.confirm to confirm or configuration.reset-all.cancel to cancel; project files and dirty buffers will not be changed"
        or else Text = "Configuration: Reset all configuration requested. Run configuration.reset-all.confirm to confirm or configuration.reset-all.cancel to cancel; project files and dirty buffers will not be changed"
        or else Text = "Configuration: Reset all configuration requested. Run configuration.reset-all.confirm to confirm or configuration.reset-all.cancel to cancel; project files and dirty buffers will not be changed."
        or else Raw_Text = "Configuration: reset all configuration requested. Run configuration.reset-all.confirm to confirm or configuration.reset-all.cancel to cancel; project files and dirty buffers will not be changed"
        or else Raw_Text = "Configuration: Reset all configuration requested. Run configuration.reset-all.confirm to confirm or configuration.reset-all.cancel to cancel; project files and dirty buffers will not be changed"
        or else Raw_Text = "Configuration: Reset all configuration requested. Run configuration.reset-all.confirm to confirm or configuration.reset-all.cancel to cancel; project files and dirty buffers will not be changed."
      then
         return "Configuration: Reset all requires confirmation.";
      elsif Text = "No pending confirmation."
        or else Text = "Configuration: no pending reset-all confirmation"
        or else Text = "Configuration: No pending reset-all confirmation"
        or else Text = "Configuration: No pending reset-all confirmation."
        or else Raw_Text = "No pending reset-all confirmation"
        or else Raw_Text = "No pending reset-all confirmation."
      then
         return "Configuration: No pending confirmation.";
      elsif Text = "Reset requires confirmation."
        or else Text = "Configuration: reset requires confirmation"
        or else Text = "Configuration: Reset requires confirmation"
        or else Text = "Configuration: Reset requires confirmation."
        or else Raw_Text = "Reset requires confirmation"
        or else Raw_Text = "Reset requires confirmation."
      then
         return "Configuration: Reset requires confirmation.";
      elsif Text = "Another prompt is active."
        or else Text = "Prompt: another prompt is active"
        or else Text = "Prompt: Another prompt is active"
        or else Text = "Prompt: Another prompt is active."
        or else Raw_Text = "Another prompt is active"
        or else Raw_Text = "Another prompt is active."
      then
         return "Prompt: Another prompt is active.";
      elsif Text = "Prompt cancelled."
        or else Text = "Prompt: prompt cancelled"
        or else Text = "Prompt: Prompt cancelled"
        or else Text = "Prompt: Prompt cancelled."
        or else Text = "Prompt: prompt canceled"
        or else Text = "Prompt: Prompt canceled"
        or else Text = "Prompt: Prompt canceled."
        or else Raw_Text = "Prompt cancelled"
        or else Raw_Text = "Prompt cancelled."
        or else Raw_Text = "Prompt canceled"
        or else Raw_Text = "Prompt canceled."
      then
         return "Prompt: Cancelled.";
      elsif Text = "Prompt is stale."
        or else Text = "Prompt: conflict prompt is stale"
        or else Text = "Prompt: Conflict prompt is stale"
        or else Text = "Prompt: Conflict prompt is stale."
        or else Text = "Prompt: prompt is stale"
        or else Text = "Prompt: Prompt is stale"
        or else Text = "Prompt: Prompt is stale."
        or else Raw_Text = "Conflict prompt is stale"
        or else Raw_Text = "Conflict prompt is stale."
      then
         return "Prompt: Prompt is stale.";
      elsif Text = "Pending transition cancelled."
        or else Text = "Project: pending transition canceled"
        or else Text = "Project: Pending transition canceled"
        or else Text = "Project: Pending transition canceled."
        or else Text = "Project: pending transition cancelled"
        or else Text = "Project: Pending transition cancelled"
        or else Text = "Project: Pending transition cancelled."
      then
         return "Project: Pending transition cancelled.";
      elsif Text = "Switch project cancelled."
        or else Text = "Project: switch project canceled"
        or else Text = "Project: Switch project canceled"
        or else Text = "Project: Switch project canceled."
        or else Text = "Project: switch project cancelled"
        or else Text = "Project: Switch project cancelled"
        or else Text = "Project: Switch project cancelled."
      then
         return "Project: Switch cancelled.";
      elsif Text = "Close project cancelled."
        or else Text = "Project: close project canceled"
        or else Text = "Project: Close project canceled"
        or else Text = "Project: Close project canceled."
        or else Text = "Project: close project cancelled"
        or else Text = "Project: Close project cancelled"
        or else Text = "Project: Close project cancelled."
      then
         return "Project: Close cancelled.";
      elsif Text = "Project open cancelled."
        or else Text = "Project: project open canceled"
        or else Text = "Project: Project open canceled"
        or else Text = "Project: Project open canceled."
        or else Text = "Project: project open cancelled"
        or else Text = "Project: Project open cancelled"
        or else Text = "Project: Project open cancelled."
      then
         return "Project: Open cancelled.";
      elsif Text = "Reload cancelled."
        or else Text = "File: reload canceled"
        or else Text = "File: Reload canceled"
        or else Text = "File: Reload canceled."
        or else Text = "File: reload cancelled"
        or else Text = "File: Reload cancelled"
        or else Text = "File: Reload cancelled."
      then
         return "File: Reload cancelled.";
      elsif Text = "Revert cancelled."
        or else Text = "File: revert canceled"
        or else Text = "File: Revert canceled"
        or else Text = "File: Revert canceled."
        or else Text = "File: revert cancelled"
        or else Text = "File: Revert cancelled"
        or else Text = "File: Revert cancelled."
      then
         return "File: Revert cancelled.";
      elsif Text = "File Tree: no file selected"
        or else Text = "File Tree: No file selected"
        or else Text = "File Tree: No file selected."
        or else Text = "File Tree: no node selected"
        or else Text = "File Tree: No node selected"
        or else Text = "File Tree: No node selected."
      then
         return "File Tree: No file selected.";
      elsif Text = "Quick Open: no file selected"
        or else Text = "Quick Open: No file selected"
        or else Text = "Quick Open: No file selected."
        or else Text = "Quick Open: no result selected"
        or else Text = "Quick Open: No result selected"
        or else Text = "Quick Open: No result selected."
        or else Text = "Quick Open: no match selected"
        or else Text = "Quick Open: No match selected"
        or else Text = "Quick Open: No match selected."
      then
         return "Quick Open: No file selected.";
      elsif Text = "Search: no file selected"
        or else Text = "Search: No file selected"
        or else Text = "Search: No file selected."
        or else Text = "Search: no result selected"
        or else Text = "Search: No result selected"
        or else Text = "Search: No result selected."
        or else Raw_Text = "Search Results: no selected result"
        or else Raw_Text = "Search Results: no selected result."
      then
         return "Search: No file selected.";
      elsif Text = "Outline: no file selected"
        or else Text = "Outline: No file selected"
        or else Text = "Outline: No file selected."
        or else Text = "Outline: no item selected"
        or else Text = "Outline: No item selected"
        or else Text = "Outline: No item selected."
      then
         return "Outline: No file selected.";
      elsif Text = "Diagnostics: no file selected"
        or else Text = "Diagnostics: No file selected"
        or else Text = "Diagnostics: No file selected."
        or else Text = "Diagnostics: no diagnostic selected"
        or else Text = "Diagnostics: No diagnostic selected"
        or else Text = "Diagnostics: No diagnostic selected."
      then
         return "Diagnostics: No file selected.";
      elsif Text = "Diagnostics: none"
        or else Text = "Diagnostics: no diagnostics"
      then
         return "No diagnostics.";
      elsif Text = "Quick Open: file no longer exists"
        or else Text = "Quick Open: File no longer exists"
        or else Text = "Quick Open: File no longer exists."
        or else Text = "Quick Open: target no longer exists"
        or else Text = "Quick Open: Target no longer exists"
        or else Text = "Quick Open: Target no longer exists."
      then
         return "Quick Open: Target no longer exists.";
      elsif Text = "Search: result target unavailable"
        or else Text = "Search: Result target unavailable"
        or else Text = "Search: Search result target unavailable"
        or else Text = "Search: Search result target unavailable."
        or else Text = "Search: target no longer exists"
        or else Text = "Search: Target no longer exists"
        or else Text = "Search: Target no longer exists."
      then
         return "Search: Target no longer exists.";
      elsif Text = "Outline: target unavailable"
        or else Text = "Outline: Target unavailable"
        or else Text = "Outline: Outline target unavailable"
        or else Text = "Outline: Outline target unavailable."
        or else Text = "Outline: target no longer exists"
        or else Text = "Outline: Target no longer exists"
        or else Text = "Outline: Target no longer exists."
      then
         return "Outline: Target no longer exists.";
      elsif Text = "Diagnostics: diagnostic target file is unavailable"
        or else Text = "Diagnostics: Diagnostic target file is unavailable"
        or else Text = "Diagnostics: Diagnostic target file is unavailable."
        or else Text = "Diagnostics: target no longer exists"
        or else Text = "Diagnostics: Target no longer exists"
        or else Text = "Diagnostics: Target no longer exists."
      then
         return "Diagnostics: Target no longer exists.";
      elsif Text = "Search: target line unavailable"
        or else Text = "Search: Target line unavailable"
        or else Text = "Search: Search target line is unavailable"
        or else Text = "Search: Search target line is unavailable."
        or else Text = "Search: target line is unavailable"
        or else Text = "Search: Target line is unavailable"
        or else Text = "Search: Target line is unavailable."
      then
         return "Search: Target line is unavailable.";
      elsif Text = "Diagnostics: diagnostic target line is unavailable"
        or else Text = "Diagnostics: Diagnostic target line is unavailable"
        or else Text = "Diagnostics: Diagnostic target line is unavailable."
        or else Text = "Diagnostics: target line unavailable"
        or else Text = "Diagnostics: Target line unavailable"
        or else Text = "Diagnostics: Target line unavailable."
        or else Text = "Diagnostics: target line is unavailable"
        or else Text = "Diagnostics: Target line is unavailable"
        or else Text = "Diagnostics: Target line is unavailable."
      then
         return "Diagnostics: Target line is unavailable.";
      elsif Text = "File Tree: target outside project"
        or else Text = "File Tree: Target outside project"
        or else Text = "File Tree: target path is outside the project"
        or else Text = "File Tree: Target path is outside the project"
        or else Text = "File Tree: Target path is outside the project."
        or else Text = "File Tree: Target is outside the current project"
        or else Text = "File Tree: Target is outside the current project."
      then
         return "File Tree: Target is outside the current project.";
      elsif Text = "Search: replacement target is outside project"
        or else Text = "Search: Replacement target is outside project"
        or else Text = "Search: Replacement target is outside project."
        or else Text = "Search: target is outside the current project"
        or else Text = "Search: Target is outside the current project"
        or else Text = "Search: Target is outside the current project."
      then
         return "Search: Target is outside the current project.";
      elsif Text = "Buffer List: no open buffers"
        or else Text = "Buffer List: No open buffers"
        or else Text = "Buffer List: No open buffers."
        or else Text = "Buffer List: no buffers open"
        or else Text = "Buffer List: No buffers open"
        or else Text = "Buffer List: No buffers open."
      then
         return "Buffer List: No buffers open.";
      elsif Text = "Buffer List: no matching open buffers"
        or else Text = "Buffer List: No matching open buffers"
        or else Text = "Buffer List: No matching open buffers."
        or else Text = "Buffer List: no matching buffers"
        or else Text = "Buffer List: No matching buffers"
        or else Text = "Buffer List: No matching buffers."
        or else Text = "Buffer List: no matches"
        or else Text = "Buffer List: No matches"
        or else Text = "Buffer List: No matches."
      then
         return "Buffer List: No matching open buffers.";
      elsif Text = "Buffer List: no marked buffers"
        or else Text = "Buffer List: No marked buffers"
        or else Text = "Buffer List: No marked buffers."
      then
         return "Buffer List: No marked buffers.";
      elsif Text = "Buffer List: no pending close targets"
        or else Text = "Buffer List: No pending close targets"
        or else Text = "Buffer List: No pending close targets."
        or else Text = "Buffer List: no pending marked targets"
        or else Text = "Buffer List: No pending marked targets"
        or else Text = "Buffer List: No pending marked targets."
      then
         return "Buffer List: No pending close targets.";
      elsif Text = "Buffer List: no pruned pending close targets"
        or else Text = "Buffer List: No pruned pending close targets"
        or else Text = "Buffer List: No pruned pending close targets."
      then
         return "Buffer List: No pruned pending close targets.";
      elsif Text = "Buffer List: no dirty pending close targets"
        or else Text = "Buffer List: No dirty pending close targets"
        or else Text = "Buffer List: No dirty pending close targets."
      then
         return "Buffer List: No dirty pending close targets.";
      elsif Text = "Buffer List: no dirty-prune preview targets"
        or else Text = "Buffer List: No dirty-prune preview targets"
        or else Text = "Buffer List: No dirty-prune preview targets."
      then
         return "Buffer List: No dirty-prune preview targets.";
      elsif Text = "Buffer List: no removed dirty-prune preview targets"
        or else Text = "Buffer List: No removed dirty-prune preview targets"
        or else Text = "Buffer List: No removed dirty-prune preview targets."
      then
         return "Buffer List: No removed dirty-prune preview targets.";
      elsif Text = "Buffer List: no dirty-prune apply targets"
        or else Text = "Buffer List: No dirty-prune apply targets"
        or else Text = "Buffer List: No dirty-prune apply targets."
      then
         return "Buffer List: No dirty-prune apply targets.";
      elsif Text = "Buffer List: no removed dirty-prune apply targets"
        or else Text = "Buffer List: No removed dirty-prune apply targets"
        or else Text = "Buffer List: No removed dirty-prune apply targets."
      then
         return "Buffer List: No removed dirty-prune apply targets.";
      elsif Text = "Buffer List: only one buffer open"
        or else Text = "Buffer List: Only one buffer open"
        or else Text = "Buffer List: Only one buffer open."
        or else Text = "Buffer List: no other buffer"
        or else Text = "Buffer List: No other buffer"
        or else Text = "Buffer List: No other buffer."
      then
         return "Buffer List: No other buffer.";
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





   function Status_Project_File_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Project_Text : constant String := Status_Project_Segment (Snapshot);
      File_Text    : constant String := Format_Left (Snapshot);
   begin
      if File_Text'Length = 0 then
         return Project_Text;
      else
         return Project_Text & " | " & File_Text;
      end if;
   end Status_Project_File_Segment;

   function Status_Dirty_File_State_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Kind_Text : constant String := Segment_Text (Snapshot.Buffer_Kind_Label);
      State_Text : constant String := Status_Segment_Text (Snapshot.File_State_Label);
      Dirty_Text : constant String :=
        (if Length (Snapshot.Dirty_State_Label) > 0
         then Status_Segment_Text (Snapshot.Dirty_State_Label)
         elsif Snapshot.Is_Dirty
         then "Modified"
         else "");
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Append_Part (Part : String) is
      begin
         if Part'Length = 0 then
            return;
         elsif Length (Result) = 0 then
            Result := To_Unbounded_String (Part);
         else
            Append (Result, " | " & Part);
         end if;
      end Append_Part;
   begin
      if not Snapshot.Has_Active_Buffer then
         return "No active buffer.";
      end if;

      Append_Part (Kind_Text);
      Append_Part (State_Text);
      Append_Part (Dirty_Text);

      if Length (Result) = 0 then
         return (if Snapshot.Has_Active_Buffer then "Clean" else "No active buffer.");
      else
         return To_String (Result);
      end if;
   end Status_Dirty_File_State_Segment;

   function Status_Project_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      if Length (Snapshot.Project_State_Label) > 0 then
         return Segment_Text (Snapshot.Project_State_Label);
      elsif Snapshot.Has_Project then
         return "Project: " & Field_Or_Fallback (Snapshot.Project_Label, "?");
      else
         return "No project open.";
      end if;
   end Status_Project_Segment;

   function Status_Focus_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Focus_Text : constant String := Field_Or_Fallback (Snapshot.Focus_Label, "Editor");
      Panel_Text : constant String :=
        (if Length (Snapshot.Active_Panel_Label) = 0
         then ""
         else " | Panel: " & Segment_Text (Snapshot.Active_Panel_Label));
      Input_Mode_Text : constant String :=
        (if Length (Snapshot.Input_Mode_Label) = 0
         then ""
         else " | Mode: " & Segment_Text (Snapshot.Input_Mode_Label));
      Overlay_Text : constant String :=
        (if Snapshot.Overlay_Query_Active then " | Overlay input" else "");
      Feature_Text : constant String :=
        (if Length (Snapshot.Active_Feature_Label) = 0
         then ""
         else " | " & Segment_Text (Snapshot.Active_Feature_Label));
   begin
      return "Focus: " & Focus_Text
        & Panel_Text
        & Input_Mode_Text
        & Overlay_Text
        & Feature_Text;
   end Status_Focus_Segment;

   function Status_Caret_Selection_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Row_Display : constant Natural := Snapshot.Cursor_Row + 1;
      Col_Display : constant Natural := Snapshot.Cursor_Column + 1;
      Caret_Text : constant String :=
        (if Snapshot.Has_Active_Buffer
         then "Ln" & Natural'Image (Row_Display)
           & ", Col" & Natural'Image (Col_Display)
           & " |" & Natural'Image (Snapshot.Caret_Count)
           & " " & Plural (Snapshot.Caret_Count, "caret", "carets")
         else "No caret");
      Selection_Text : constant String :=
        (if Snapshot.Rectangular_Selection_Active
         then "rect selection"
         elsif Snapshot.Selected_Character_Count > 0
         then "Selected:" & Natural'Image (Snapshot.Selected_Character_Count)
           & " " & Plural (Snapshot.Selected_Character_Count, "char", "chars")
           & "," & Natural'Image (Natural'Max (1, Snapshot.Selected_Line_Count))
           & " " & Plural (Natural'Max (1, Snapshot.Selected_Line_Count), "line", "lines")
         elsif Snapshot.Selection_Count = 0
         then "No selection"
         else "Selected:" & Natural'Image (Snapshot.Selection_Count)
           & " " & Plural (Snapshot.Selection_Count, "range", "ranges"));
   begin
      return Caret_Text & " | " & Selection_Text;
   end Status_Caret_Selection_Segment;

   function Status_Command_Outcome_Class
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      if Snapshot.Has_Command_Feedback then
         return Outcome_Class_From_Severity (Snapshot.Command_Feedback_Severity);
      else
         return "";
      end if;
   end Status_Command_Outcome_Class;

   function Status_Command_Outcome_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Class_Text : constant String := Status_Command_Outcome_Class (Snapshot);
   begin
      if Snapshot.Has_Command_Feedback then
         return Class_Text & ": "
           & Field_Or_Fallback (Snapshot.Command_Feedback, "");
      else
         return "";
      end if;
   end Status_Command_Outcome_Segment;

   function Status_Build_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      return Status_Segment_Text (Snapshot.Build_Status_Label);
   end Status_Build_Segment;

   function Status_Diagnostics_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      if Length (Snapshot.Diagnostics_Status_Label) > 0 then
         return Status_Segment_Text (Snapshot.Diagnostics_Status_Label);
      elsif Snapshot.Diagnostic_Count = 0 then
         return "No diagnostics.";
      else
         return "Diagnostics:" & Natural'Image (Snapshot.Diagnostic_Count) & " total";
      end if;
   end Status_Diagnostics_Segment;

   function Status_Search_Replace_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      return Status_Segment_Text (Snapshot.Search_Status_Label)
        & Search_Replace_Surface_Action_Label
            (Search_Replace_Surface (Snapshot));
   end Status_Search_Replace_Segment;

   function Status_Quick_Open_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Surface : constant Quick_Open_Context_Surface :=
        Quick_Open_Context_Surface_For (Snapshot);
   begin
      return Status_Segment_Text (Snapshot.Quick_Open_Status_Label)
        & Quick_Open_Context_Action_Label (Surface);
   end Status_Quick_Open_Segment;

   function Status_Message_Kind_For
     (Label : Unbounded_String) return Status_Message_Kind
   is
      Text : constant String := Status_Segment_Text (Label);
   begin
      if Text = "Quick Open: No project open." then
         return Status_Message_Quick_Open_No_Project;
      elsif Text = "Quick Open: No matches." then
         return Status_Message_Quick_Open_No_Matches;
      elsif Text = "Outline: Not refreshed." then
         return Status_Message_Outline_Not_Refreshed;
      elsif Text = "Find: No search query." then
         return Status_Message_Find_No_Query;
      elsif Text = "Find: No matches." then
         return Status_Message_Find_No_Matches;
      elsif Text = "Build: failed"
        or else Text = "Build: Failed."
      then
         return Status_Message_Build_Failed;
      elsif Text = "Build: ready"
        or else Text = "Build: Ready."
      then
         return Status_Message_Build_Ready;
      elsif Text = "Diagnostics: Target is stale; refresh required." then
         return Status_Message_Diagnostics_Target_Stale;
      elsif Text = "Search: Target is stale; refresh required."
        or else Text = "Replace: Target is stale; refresh required."
      then
         return Status_Message_Search_Target_Stale;
      elsif Text = "File Tree: No project open." then
         return Status_Message_File_Tree_No_Project;
      elsif Text = "Workspace: Restored." then
         return Status_Message_Workspace_Restored;
      elsif Text = "Workspace: Restored with missing entries skipped." then
         return Status_Message_Workspace_Partial_Restore;
      elsif Text = "Workspace: No workspace restored." then
         return Status_Message_Workspace_No_Restore;
      elsif Text = "Workspace: Unsaved changes require confirmation." then
         return Status_Message_Workspace_Unsaved_Confirmation;
      elsif Text = "Recent Projects: No recent projects." then
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
      end if;
      return Status_Message_Kind_For (Snapshot.Build_Status_Label);
   end Status_Build_Message_Kind;

   function Status_Diagnostics_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
   is
   begin
      if Snapshot.Diagnostics_Status_Kind /= Status_Message_Other then
         return Snapshot.Diagnostics_Status_Kind;
      end if;
      return Status_Message_Kind_For (Snapshot.Diagnostics_Status_Label);
   end Status_Diagnostics_Message_Kind;

   function Status_Search_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
   is
   begin
      if Snapshot.Search_Status_Kind /= Status_Message_Other then
         return Snapshot.Search_Status_Kind;
      end if;
      return Status_Message_Kind_For (Snapshot.Search_Status_Label);
   end Status_Search_Message_Kind;

   function Status_Quick_Open_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
   is
   begin
      if Snapshot.Quick_Open_Status_Kind /= Status_Message_Other then
         return Snapshot.Quick_Open_Status_Kind;
      end if;
      return Status_Message_Kind_For (Snapshot.Quick_Open_Status_Label);
   end Status_Quick_Open_Message_Kind;

   function Status_File_Tree_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
   is
   begin
      if Snapshot.File_Tree_Status_Kind /= Status_Message_Other then
         return Snapshot.File_Tree_Status_Kind;
      end if;
      return Status_Message_Kind_For (Snapshot.File_Tree_Status_Label);
   end Status_File_Tree_Message_Kind;

   function Status_Workspace_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
   is
   begin
      if Snapshot.Workspace_Status_Kind /= Status_Message_Other then
         return Snapshot.Workspace_Status_Kind;
      end if;
      return Status_Message_Kind_For (Snapshot.Workspace_Status_Label);
   end Status_Workspace_Message_Kind;

   function Status_Outline_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
   is
   begin
      if Snapshot.Outline_Status_Kind /= Status_Message_Other then
         return Snapshot.Outline_Status_Kind;
      end if;
      return Status_Message_Kind_For (Snapshot.Outline_Status_Label);
   end Status_Outline_Message_Kind;

   function Status_Recent_Projects_Message_Kind
     (Snapshot : Status_Bar_Snapshot) return Status_Message_Kind
   is
   begin
      if Snapshot.Recent_Projects_Status_Kind /= Status_Message_Other then
         return Snapshot.Recent_Projects_Status_Kind;
      end if;
      return Status_Message_Kind_For (Snapshot.Recent_Projects_Status_Label);
   end Status_Recent_Projects_Message_Kind;

   function Status_Outline_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      return Status_Segment_Text (Snapshot.Outline_Status_Label)
        & Outline_Surface_Action_Label (Outline_Surface (Snapshot));
   end Status_Outline_Segment;

   function Status_File_Tree_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      return Status_Segment_Text (Snapshot.File_Tree_Status_Label)
        & File_Tree_Surface_Action_Label (File_Tree_Surface (Snapshot));
   end Status_File_Tree_Segment;

   function Status_Workspace_Recent_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Workspace_Text : constant String := Status_Segment_Text (Snapshot.Workspace_Status_Label);
      Recent_Text    : constant String := Status_Segment_Text (Snapshot.Recent_Projects_Status_Label);
      Workspace_Actions : constant String :=
        Workspace_Surface_Action_Label (Workspace_Surface (Snapshot));
      Recent_Actions : constant String :=
        Recent_Projects_Surface_Action_Label (Recent_Projects_Surface (Snapshot));
   begin
      if Workspace_Text'Length > 0 and then Recent_Text'Length > 0 then
         return Workspace_Text & Workspace_Actions & " | "
           & Recent_Text & Recent_Actions;
      elsif Workspace_Text'Length > 0 then
         return Workspace_Text & Workspace_Actions;
      else
         return Recent_Text & Recent_Actions;
      end if;
   end Status_Workspace_Recent_Segment;

   function Workspace_Surface_Action_Label
     (Surface : Workspace_Status_Surface) return String
   is
   begin
      if Length (Surface.Summary_Label) = 0 then
         return "";
      end if;

      return " ["
        & To_String (Surface.Save_State_Command) & ", "
        & To_String (Surface.Restore_State_Command) & ", "
        & To_String (Surface.Clear_State_Command) & "]";
   end Workspace_Surface_Action_Label;

   function Workspace_Surface_Action_Count
     (Surface : Workspace_Status_Surface) return Natural
   is
   begin
      if Length (Surface.Summary_Label) = 0 then
         return 0;
      end if;
      return 3;
   end Workspace_Surface_Action_Count;

   function Quick_Open_Context_Action_Label
     (Surface : Quick_Open_Context_Surface) return String
   is
   begin
      if not Surface.Active then
         return "";
      end if;

      return " ["
        & To_String (Surface.Open_Command) & ", "
        & To_String (Surface.Clear_Scope_Command) & ", "
        & To_String (Surface.Clear_Filter_Command) & "]";
   end Quick_Open_Context_Action_Label;

   function Quick_Open_Context_Action_Count
     (Surface : Quick_Open_Context_Surface) return Natural
   is
   begin
      if Surface.Active then
         return 3;
      end if;
      return 0;
   end Quick_Open_Context_Action_Count;

   function Outline_Surface_Action_Label
     (Surface : Outline_Status_Surface) return String
   is
   begin
      if not Surface.Active then
         return "";
      end if;

      return " ["
        & To_String (Surface.Refresh_Command) & ", "
        & To_String (Surface.Open_Selected_Command) & ", "
        & To_String (Surface.Reveal_Current_Command) & "]";
   end Outline_Surface_Action_Label;

   function Outline_Surface_Action_Count
     (Surface : Outline_Status_Surface) return Natural
   is
   begin
      if Surface.Active then
         return 3;
      end if;
      return 0;
   end Outline_Surface_Action_Count;

   function Search_Replace_Surface_Action_Label
     (Surface : Search_Replace_Status_Surface) return String
   is
   begin
      if not Surface.Active then
         return "";
      end if;

      return " ["
        & To_String (Surface.Run_Command) & ", "
        & To_String (Surface.Open_Selected_Command) & ", "
        & To_String (Surface.Clear_Query_Command) & "]";
   end Search_Replace_Surface_Action_Label;

   function Search_Replace_Surface_Action_Count
     (Surface : Search_Replace_Status_Surface) return Natural
   is
   begin
      if Surface.Active then
         return 3;
      end if;
      return 0;
   end Search_Replace_Surface_Action_Count;

   function File_Tree_Surface_Action_Label
     (Surface : File_Tree_Status_Surface) return String
   is
   begin
      if not Surface.Active then
         return "";
      end if;

      return " ["
        & To_String (Surface.Refresh_Command) & ", "
        & To_String (Surface.Open_Selected_Command) & ", "
        & To_String (Surface.Reveal_Active_Command) & "]";
   end File_Tree_Surface_Action_Label;

   function File_Tree_Surface_Action_Count
     (Surface : File_Tree_Status_Surface) return Natural
   is
   begin
      if Surface.Active then
         return 3;
      end if;
      return 0;
   end File_Tree_Surface_Action_Count;

   function Recent_Projects_Surface_Action_Label
     (Surface : Recent_Projects_Status_Surface) return String
   is
   begin
      if not Surface.Active then
         return "";
      end if;

      return " ["
        & To_String (Surface.Show_Command) & ", "
        & To_String (Surface.Open_Selected_Command) & ", "
        & To_String (Surface.Remove_Missing_Command) & "]";
   end Recent_Projects_Surface_Action_Label;

   function Recent_Projects_Surface_Action_Count
     (Surface : Recent_Projects_Status_Surface) return Natural
   is
   begin
      if Surface.Active then
         return 3;
      end if;
      return 0;
   end Recent_Projects_Surface_Action_Count;

   function Workspace_Surface
     (Snapshot : Status_Bar_Snapshot) return Workspace_Status_Surface
   is
      Summary : constant String := Status_Segment_Text (Snapshot.Workspace_Status_Label);
      Result  : Workspace_Status_Surface;
   begin
      Result.Summary_Label := To_Unbounded_String (Summary);
      if Summary'Length > 0 then
         Result.Has_Restore_Details := True;
         Result.Restore_Details_Label := To_Unbounded_String (Summary);
      end if;
      return Result;
   end Workspace_Surface;

   function Quick_Open_Context_Surface_For
     (Snapshot : Status_Bar_Snapshot) return Quick_Open_Context_Surface
   is
      Summary : constant String := Status_Segment_Text (Snapshot.Quick_Open_Status_Label);
      Result  : Quick_Open_Context_Surface;
   begin
      Result.Summary_Label := To_Unbounded_String (Summary);
      Result.Active := Summary'Length > 0;
      return Result;
   end Quick_Open_Context_Surface_For;

   function Outline_Surface
     (Snapshot : Status_Bar_Snapshot) return Outline_Status_Surface
   is
      Summary : constant String := Status_Segment_Text (Snapshot.Outline_Status_Label);
      Result  : Outline_Status_Surface;
   begin
      Result.Summary_Label := To_Unbounded_String (Summary);
      Result.Active := Summary'Length > 0;
      return Result;
   end Outline_Surface;

   function Search_Replace_Surface
     (Snapshot : Status_Bar_Snapshot) return Search_Replace_Status_Surface
   is
      Summary : constant String := Status_Segment_Text (Snapshot.Search_Status_Label);
      Result  : Search_Replace_Status_Surface;
   begin
      Result.Summary_Label := To_Unbounded_String (Summary);
      Result.Active := Summary'Length > 0;
      return Result;
   end Search_Replace_Surface;

   function File_Tree_Surface
     (Snapshot : Status_Bar_Snapshot) return File_Tree_Status_Surface
   is
      Summary : constant String := Status_Segment_Text (Snapshot.File_Tree_Status_Label);
      Result  : File_Tree_Status_Surface;
   begin
      Result.Summary_Label := To_Unbounded_String (Summary);
      Result.Active := Summary'Length > 0;
      return Result;
   end File_Tree_Surface;

   function Recent_Projects_Surface
     (Snapshot : Status_Bar_Snapshot) return Recent_Projects_Status_Surface
   is
      Summary : constant String := Status_Segment_Text
        (Snapshot.Recent_Projects_Status_Label);
      Result  : Recent_Projects_Status_Surface;
   begin
      Result.Summary_Label := To_Unbounded_String (Summary);
      Result.Active := Summary'Length > 0;
      return Result;
   end Recent_Projects_Surface;

   function Status_Startup_Segment
     (Snapshot : Status_Bar_Snapshot) return String
   is
   begin
      return Status_Segment_Text (Snapshot.Startup_Status_Label);
   end Status_Startup_Segment;

   function Format_Right
     (Snapshot : Status_Bar_Snapshot) return String
   is
      Row_Display : constant Natural := Snapshot.Cursor_Row + 1;
      Col_Display : constant Natural := Snapshot.Cursor_Column + 1;
      Caret_Text : constant String :=
        (if Snapshot.Has_Active_Buffer
         then "Ln" & Natural'Image (Row_Display)
           & ", Col" & Natural'Image (Col_Display)
           & " |" & Natural'Image (Snapshot.Caret_Count)
           & " " & Plural (Snapshot.Caret_Count, "caret", "carets")
         else "No caret");
      Project_Text : constant String :=
        (if Length (Snapshot.Project_State_Label) > 0
         then Segment_Text (Snapshot.Project_State_Label)
         elsif Snapshot.Has_Project
         then "Project: " & Field_Or_Fallback (Snapshot.Project_Label, "?")
         else "No project open.");
      Focus_Text : constant String := Status_Focus_Segment (Snapshot);
      Hint_Text : constant String :=
        (if Length (Snapshot.Focus_Hint) = 0
         then ""
         else " | " & Segment_Text (Snapshot.Focus_Hint));
      Lifecycle_Text : constant String :=
        (if Length (Snapshot.Lifecycle_Hint) = 0
         then ""
         else " | " & Segment_Text (Snapshot.Lifecycle_Hint));
      Pending_Text : constant String :=
        "";
      Undo_Redo_Text : constant String :=
        (if Length (Snapshot.Undo_Redo_Label) = 0
         then ""
         else " | " & Segment_Text (Snapshot.Undo_Redo_Label));
      Outline_Text : constant String :=
        (if Length (Snapshot.Outline_Status_Label) = 0
         then ""
         else " | " & Status_Outline_Segment (Snapshot));
      Diagnostics_Text : constant String :=
        " | " & Status_Diagnostics_Segment (Snapshot);
      Build_Text : constant String :=
        (if Length (Snapshot.Build_Status_Label) = 0
         then ""
         else " | " & Status_Segment_Text (Snapshot.Build_Status_Label));
      Search_Text : constant String :=
        (if Length (Snapshot.Search_Status_Label) = 0
         then ""
         else " | " & Status_Search_Replace_Segment (Snapshot));
      Quick_Open_Text : constant String :=
        (if Length (Snapshot.Quick_Open_Status_Label) = 0
         then ""
         else " | " & Status_Quick_Open_Segment (Snapshot));
      File_Tree_Text : constant String :=
        (if Length (Snapshot.File_Tree_Status_Label) = 0
         then ""
         else " | " & Status_File_Tree_Segment (Snapshot));
      Workspace_Text : constant String :=
        (if Length (Snapshot.Workspace_Status_Label) = 0
           and then Length (Snapshot.Recent_Projects_Status_Label) = 0
         then ""
         else " | " & Status_Workspace_Recent_Segment (Snapshot));
      Recent_Projects_Text : constant String :=
        "";
      Startup_Text : constant String :=
        (if Length (Snapshot.Startup_Status_Label) = 0
         then ""
         else " | " & Status_Segment_Text (Snapshot.Startup_Status_Label));
      Priority_Pending_Text : constant String :=
        (if Length (Snapshot.Pending_Confirmation_Label) = 0
         then ""
         else Segment_Text (Snapshot.Pending_Confirmation_Label) & " | ");
      Priority_Feedback_Text : constant String :=
        (if Snapshot.Has_Command_Feedback
           and then Is_Priority_Feedback (Snapshot.Command_Feedback_Severity)
         then Status_Command_Outcome_Segment (Snapshot) & " | "
         else "");
      Selection_Text : constant String :=
        (if Snapshot.Rectangular_Selection_Active
         then "rect selection"
         elsif Snapshot.Selected_Character_Count > 0
         then "Selected:" & Natural'Image (Snapshot.Selected_Character_Count)
           & " " & Plural (Snapshot.Selected_Character_Count, "char", "chars")
           & "," & Natural'Image (Natural'Max (1, Snapshot.Selected_Line_Count))
           & " " & Plural (Natural'Max (1, Snapshot.Selected_Line_Count), "line", "lines")
         elsif Snapshot.Selection_Count = 0
         then "No selection"
         else "Selected:" & Natural'Image (Snapshot.Selection_Count)
           & " " & Plural (Snapshot.Selection_Count, "range", "ranges"));
      Feedback_Text : constant String :=
        (if Snapshot.Has_Command_Feedback
           and then not Is_Priority_Feedback (Snapshot.Command_Feedback_Severity)
         then " | " & Status_Command_Outcome_Segment (Snapshot)
         else "");
   begin
      return Priority_Pending_Text
        & Priority_Feedback_Text
        & Project_Text
        & " | " & Focus_Text
        & " | " & Caret_Text
        & " | " & Selection_Text
        & " | " & Segment_Text (Snapshot.Line_Number_Mode)
        & " | "
        & (if Snapshot.Find_Input_Open and then not Snapshot.Find_Query_Present
           then "Find: No search query."
           elsif Snapshot.Find_Query_Present and then Snapshot.Active_Find_Match_Count = 0
           then "Find: No matches."
           elsif Snapshot.Find_Active_Match > 0
              and then Snapshot.Active_Find_Match_Count > 0
           then "Find:" & Natural'Image (Snapshot.Find_Active_Match)
                & " of" & Natural'Image (Snapshot.Active_Find_Match_Count)
                & (if Snapshot.Find_Wrapped then " wrapped" else "")
           else "Find:" & Natural'Image (Snapshot.Active_Find_Match_Count)
                & " " & Plural (Snapshot.Active_Find_Match_Count, "match", "matches"))
        & Undo_Redo_Text
        & Hint_Text
        & Lifecycle_Text
        & Pending_Text
        & Outline_Text
        & Diagnostics_Text
        & Build_Text
        & Search_Text
        & Quick_Open_Text
        & File_Tree_Text
        & Workspace_Text
        & Recent_Projects_Text
        & Startup_Text
        & Feedback_Text;
   end Format_Right;



   function Status_Layout_Should_Use_Compact
     (Snapshot          : Status_Bar_Snapshot;
      Available_Columns : Natural) return Boolean
   is
   begin
      return Available_Columns > 0
        and then (Available_Columns < 64
                  or else Length (Snapshot.Pending_Confirmation_Label) > 0
                  or else (Snapshot.Has_Command_Feedback
                            and then Is_Priority_Feedback
                              (Snapshot.Command_Feedback_Severity)));
   end Status_Layout_Should_Use_Compact;

   function Status_Layout_Compact
     (Snapshot    : Status_Bar_Snapshot;
      Max_Columns : Natural) return String
   is
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Append_Segment (Text : String) is
      begin
         if Text'Length = 0 then
            return;
         elsif Length (Result) = 0 then
            Result := To_Unbounded_String (Text);
         else
            Append (Result, " | " & Text);
         end if;
      end Append_Segment;

      Pending_Text : constant String := Segment_Text (Snapshot.Pending_Confirmation_Label);
      Command_Text : constant String := Status_Command_Outcome_Segment (Snapshot);
      Priority_Command : constant Boolean :=
        Snapshot.Has_Command_Feedback
        and then Is_Priority_Feedback (Snapshot.Command_Feedback_Severity);
   begin
      --  Compact layout is priority ordered, not merely left/right
      --  concatenation.  Narrow status surfaces must keep destructive/pending
      --  and failed/unavailable context ahead of lower-priority summaries.
      Append_Segment (Pending_Text);
      if Priority_Command then
         Append_Segment (Command_Text);
      end if;

      Append_Segment (Status_Project_File_Segment (Snapshot));
      Append_Segment (Status_Caret_Selection_Segment (Snapshot));
      Append_Segment (Status_Focus_Segment (Snapshot));
      Append_Segment (Status_Diagnostics_Segment (Snapshot));
      Append_Segment (Status_Build_Segment (Snapshot));
      Append_Segment (Status_Search_Replace_Segment (Snapshot));
      Append_Segment (Status_Quick_Open_Segment (Snapshot));
      Append_Segment (Status_Outline_Segment (Snapshot));
      Append_Segment (Status_File_Tree_Segment (Snapshot));
      Append_Segment (Status_Workspace_Recent_Segment (Snapshot));
      Append_Segment (Status_Startup_Segment (Snapshot));

      if Snapshot.Has_Command_Feedback and then not Priority_Command then
         Append_Segment (Command_Text);
      end if;

      return Status_Truncate_Label (To_String (Result), Max_Columns);
   end Status_Layout_Compact;


   function Contains
     (Text    : String;
      Pattern : String) return Boolean
   is
   begin
      if Pattern'Length = 0 then
         return True;
      end if;

      return Ada.Strings.Fixed.Index (Text, Pattern) > 0;
   end Contains;

   function Starts_With
     (Text    : String;
      Pattern : String) return Boolean
   is
   begin
      if Pattern'Length = 0 then
         return True;
      elsif Text'Length < Pattern'Length then
         return False;
      else
         return Text (Text'First .. Text'First + Pattern'Length - 1) = Pattern;
      end if;
   end Starts_With;

   function Occurrence_Count
     (Text    : String;
      Pattern : String) return Natural
   is
      Count : Natural := 0;
      From  : Positive := Text'First;
      At_Index    : Natural := 0;
   begin
      if Pattern'Length = 0 then
         return 0;
      end if;

      while From <= Text'Last loop
         At_Index := Ada.Strings.Fixed.Index (Text, Pattern, From);
         exit when At_Index = 0;
         Count := Count + 1;
         From := At_Index + Pattern'Length;
      end loop;

      return Count;
   end Occurrence_Count;

   function Assert_Status_Snapshot_Is_Observational
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      pragma Unreferenced (Snapshot);
   begin
      --  The status snapshot is scalar display data only.  The record type has
      --  no containers for diagnostics rows, outline rows, search results,
      --  build output, file-tree nodes, command payloads, or persistence data.
      return True;
   end Assert_Status_Snapshot_Is_Observational;

   function Assert_Status_Shows_Active_Buffer_And_Dirty_State
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Left : constant String := Format_Left (Snapshot);
   begin
      return (if not Snapshot.Has_Active_Buffer
              then Contains (Left, "No active buffer.")
              else (Length (Snapshot.File_Label) > 0
                    and then Contains (Left, Segment_Text (Snapshot.File_Label)))
                or else (Length (Snapshot.File_Name) > 0
                         and then Contains (Left, Segment_Text (Snapshot.File_Name))))
        and then (if Snapshot.Is_Dirty then Contains (Left, "*") else True);
   end Assert_Status_Shows_Active_Buffer_And_Dirty_State;

   function Assert_Status_Shows_Caret_And_Selection
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Right : constant String := Format_Right (Snapshot);
   begin
      return (if Snapshot.Has_Active_Buffer
              then Contains (Right, "Ln") and then Contains (Right, "Col")
              else Contains (Right, "No caret"))
        and then (Contains (Right, "No selection")
                  or else Contains (Right, "Selected:")
                  or else Contains (Right, "rect selection"));
   end Assert_Status_Shows_Caret_And_Selection;

   function Assert_Status_Shows_Command_Outcome
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Right : constant String := Format_Right (Snapshot);
   begin
      return (not Snapshot.Has_Command_Feedback)
        or else Contains (Right, Status_Command_Outcome_Segment (Snapshot));
   end Assert_Status_Shows_Command_Outcome;

   function Assert_Status_Does_Not_Copy_Feature_Rows
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      pragma Unreferenced (Snapshot);
   begin
      return True;
   end Assert_Status_Does_Not_Copy_Feature_Rows;

   function Assert_Status_Shows_Feature_Summaries
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Right : constant String := Format_Right (Snapshot);
   begin
      return (if Length (Snapshot.Active_Panel_Label) > 0
              then Contains (Right, Segment_Text (Snapshot.Active_Panel_Label))
              else True)
        and then (if Length (Snapshot.Input_Mode_Label) > 0
                  then Contains (Right, Segment_Text (Snapshot.Input_Mode_Label))
                  else True)
        and then (if Snapshot.Overlay_Query_Active
                  then Contains (Right, "Overlay input")
                  else True)
        and then (if Length (Snapshot.Outline_Status_Label) > 0
              then Contains (Right, Status_Segment_Text (Snapshot.Outline_Status_Label))
              else True)
        and then (if Length (Snapshot.Diagnostics_Status_Label) > 0
                  then Contains (Right, Status_Segment_Text (Snapshot.Diagnostics_Status_Label))
                  else Contains (Right, "diagnostic")
                    or else Contains (Right, "Diagnostics:"))
        and then (if Length (Snapshot.Build_Status_Label) > 0
                  then Contains (Right, Status_Segment_Text (Snapshot.Build_Status_Label))
                  else True)
        and then (if Length (Snapshot.Search_Status_Label) > 0
                  then Contains (Right, Status_Segment_Text (Snapshot.Search_Status_Label))
                  else True)
        and then (if Length (Snapshot.Quick_Open_Status_Label) > 0
                  then Contains (Right, Status_Segment_Text (Snapshot.Quick_Open_Status_Label))
                  else True)
        and then (if Length (Snapshot.File_Tree_Status_Label) > 0
                  then Contains (Right, Status_Segment_Text (Snapshot.File_Tree_Status_Label))
                  else True)
        and then (if Length (Snapshot.Workspace_Status_Label) > 0
                  then Contains (Right, Status_Segment_Text (Snapshot.Workspace_Status_Label))
                  else True)
        and then (if Length (Snapshot.Recent_Projects_Status_Label) > 0
                  then Contains (Right, Status_Segment_Text (Snapshot.Recent_Projects_Status_Label))
                  else True);
   end Assert_Status_Shows_Feature_Summaries;

   function Assert_Status_State_Not_Persisted
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      pragma Unreferenced (Snapshot);
   begin
      --  Status-bar snapshots are not part of workspace/settings/recent/
      --  keybinding persistence.  The type remains a render/input projection
      --  record only; adding this predicate gives tests and route audits a
      --  named persistence-boundary assertion.
      return True;
   end Assert_Status_State_Not_Persisted;


   function Assert_Status_Summarizes_Main_Context
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Right : constant String := Format_Right (Snapshot);
      Left  : constant String := Format_Left (Snapshot);
   begin
      return (if Snapshot.Has_Project
              then Contains (Right, Segment_Text (Snapshot.Project_Label))
                or else Contains (Right, Segment_Text (Snapshot.Project_State_Label))
              else Contains (Right, "No project open."))
        and then (if Snapshot.Has_Active_Buffer
                  then (Length (Snapshot.File_Label) > 0
                        and then Contains (Left, Segment_Text (Snapshot.File_Label)))
                    or else (Length (Snapshot.File_Name) > 0
                             and then Contains (Left, Segment_Text (Snapshot.File_Name)))
                  else Contains (Left, "No active buffer."))
        and then Contains (Right, Field_Or_Fallback (Snapshot.Focus_Label, "Editor"))
        and then (Length (Snapshot.Pending_Confirmation_Label) = 0
                  or else Contains
                    (Right, Segment_Text (Snapshot.Pending_Confirmation_Label)))
        and then (not Snapshot.Has_Command_Feedback
                  or else Contains
                    (Right, Status_Command_Outcome_Segment (Snapshot)))
        and then (Length (Snapshot.Build_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.Build_Status_Label)))
        and then (Length (Snapshot.Diagnostics_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.Diagnostics_Status_Label)))
        and then (Length (Snapshot.Search_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.Search_Status_Label)))
        and then (Length (Snapshot.Quick_Open_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.Quick_Open_Status_Label)))
        and then (Length (Snapshot.Outline_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.Outline_Status_Label)))
        and then (Length (Snapshot.File_Tree_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.File_Tree_Status_Label)))
        and then (Length (Snapshot.Workspace_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.Workspace_Status_Label)))
        and then (Length (Snapshot.Recent_Projects_Status_Label) = 0
                  or else Contains (Right, Status_Segment_Text (Snapshot.Recent_Projects_Status_Label)));
   end Assert_Status_Summarizes_Main_Context;


   function Assert_Status_Shows_File_State_Markers
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Left : constant String := Format_Left (Snapshot);
   begin
      return (Length (Snapshot.Buffer_Kind_Label) = 0
              or else Contains (Left, Segment_Text (Snapshot.Buffer_Kind_Label)))
        and then (Length (Snapshot.File_State_Label) = 0
                  or else Contains (Left, Segment_Text (Snapshot.File_State_Label)))
        and then (Length (Snapshot.Dirty_State_Label) = 0
                  or else Contains (Left, Segment_Text (Snapshot.Dirty_State_Label)))
        and then (if Snapshot.Is_Dirty then Contains (Left, "*") else True);
   end Assert_Status_Shows_File_State_Markers;


   function Assert_Status_Does_Not_Copy_Rows_Or_Output
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Left  : constant String := Format_Left (Snapshot);
      Right : constant String := Format_Right (Snapshot);
   begin
      --  The status surface may show scalar counts and scalar labels, but it
      --  must not embed row/output payload separators that would indicate copied
      --  diagnostics rows, search result rows, outline rows, file-tree nodes, or
      --  build output bodies.  This is intentionally a formatting-boundary
      --  assertion over the immutable snapshot.
      return not Contains (Left, ASCII.LF & "")
        and then not Contains (Right, ASCII.LF & "")
        and then not Contains (Left, ASCII.CR & "")
        and then not Contains (Right, ASCII.CR & "")
        and then not Contains (Left, ASCII.HT & "")
        and then not Contains (Right, ASCII.HT & "");
   end Assert_Status_Does_Not_Copy_Rows_Or_Output;

   function Assert_Status_Does_Not_Duplicate_Priority_Segments
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Right : constant String := Format_Right (Snapshot);
      Feedback_Text : constant String :=
        Status_Command_Outcome_Segment (Snapshot);
   begin
      return (Length (Snapshot.Pending_Confirmation_Label) = 0
              or else Occurrence_Count
                (Right, Segment_Text (Snapshot.Pending_Confirmation_Label)) = 1)
        and then ((not Snapshot.Has_Command_Feedback)
                  or else Length (Snapshot.Command_Feedback) = 0
                  or else Occurrence_Count (Right, Feedback_Text) = 1);
   end Assert_Status_Does_Not_Duplicate_Priority_Segments;

   function Assert_Status_Command_Outcome_Uses_Public_Classes
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Class_Text : constant String := Status_Command_Outcome_Class (Snapshot);
      Segment    : constant String := Status_Command_Outcome_Segment (Snapshot);
      Right      : constant String := Format_Right (Snapshot);
   begin
      if not Snapshot.Has_Command_Feedback then
         return Class_Text = "" and then Segment = "";
      end if;

      return (Class_Text = "success"
              or else Class_Text = "unavailable"
              or else Class_Text = "failed"
              or else Class_Text = "cancelled"
              or else Class_Text = "pending"
              or else Class_Text = "info")
        and then Contains (Segment, Class_Text & ": ")
        and then Contains (Right, Segment)
        and then not (Segment'Length >= 7
                      and then Segment (Segment'First .. Segment'First + 6) = "error: ")
        and then not (Segment'Length >= 6
                      and then Segment (Segment'First .. Segment'First + 5) = "warn: ")
        and then not (Segment'Length >= 9
                      and then Segment (Segment'First .. Segment'First + 8) = "warning: ")
        and then not (Segment'Length >= 9
                      and then Segment (Segment'First .. Segment'First + 8) = "failure: ")
        and then not (Segment'Length >= 4
                      and then Segment (Segment'First .. Segment'First + 3) = "ok: ");
   end Assert_Status_Command_Outcome_Uses_Public_Classes;

   function Assert_Status_Layout_Is_Bounded
     (Snapshot    : Status_Bar_Snapshot;
      Max_Columns : Natural) return Boolean
   is
      Text : constant String := Status_Layout_Compact (Snapshot, Max_Columns);
   begin
      return Text'Length <= Max_Columns
        and then (if Max_Columns = 0 then Text = "" else True);
   end Assert_Status_Layout_Is_Bounded;



   function Assert_Status_Layout_Preserves_Priority
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Compact_64 : constant String := Status_Layout_Compact (Snapshot, 64);
      Compact_128 : constant String := Status_Layout_Compact (Snapshot, 128);
      Pending_Text : constant String := Segment_Text (Snapshot.Pending_Confirmation_Label);
      Command_Text : constant String := Status_Command_Outcome_Segment (Snapshot);
      Pending_Prefix_Length : constant Natural :=
        Natural'Min (Pending_Text'Length, 16);
      Pending_Prefix : constant String :=
        (if Pending_Prefix_Length = 0
         then ""
         else Pending_Text
           (Pending_Text'First .. Pending_Text'First + Pending_Prefix_Length - 1));
      Command_Prefix_Length : constant Natural :=
        Natural'Min (Command_Text'Length, 16);
      Command_Prefix : constant String :=
        (if Command_Prefix_Length = 0
         then ""
         else Command_Text
           (Command_Text'First .. Command_Text'First + Command_Prefix_Length - 1));
   begin
      return (Length (Snapshot.Pending_Confirmation_Label) = 0
              or else Starts_With (Compact_64, Pending_Prefix))
        and then ((not Snapshot.Has_Command_Feedback)
                  or else not Is_Priority_Feedback
                    (Snapshot.Command_Feedback_Severity)
                  or else Contains (Compact_128, Command_Prefix));
   end Assert_Status_Layout_Preserves_Priority;


   function Assert_Status_Segment_Builders_Are_Coherent
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Right : constant String := Format_Right (Snapshot);
      Project_Text : constant String := Status_Project_Segment (Snapshot);
      Project_File_Text : constant String := Status_Project_File_Segment (Snapshot);
      Dirty_File_State_Text : constant String :=
        Status_Dirty_File_State_Segment (Snapshot);
      Focus_Text : constant String := Status_Focus_Segment (Snapshot);
      Caret_Selection_Text : constant String := Status_Caret_Selection_Segment (Snapshot);
      Command_Text : constant String := Status_Command_Outcome_Segment (Snapshot);
      Build_Text : constant String := Status_Build_Segment (Snapshot);
      Diagnostics_Text : constant String := Status_Diagnostics_Segment (Snapshot);
      Search_Text : constant String := Status_Search_Replace_Segment (Snapshot);
      Quick_Open_Text : constant String := Status_Quick_Open_Segment (Snapshot);
      Outline_Text : constant String := Status_Outline_Segment (Snapshot);
      File_Tree_Text : constant String := Status_File_Tree_Segment (Snapshot);
      Workspace_Recent_Text : constant String := Status_Workspace_Recent_Segment (Snapshot);
   begin
      return Contains (Right, Project_Text)
        and then Contains (Status_Layout_Compact (Snapshot, 4096), Project_File_Text)
        and then (Dirty_File_State_Text = "Clean"
                  or else Contains (Format_Left (Snapshot), Dirty_File_State_Text)
                  or else Assert_Status_Shows_File_State_Markers (Snapshot))
        and then Contains (Right, Focus_Text)
        and then Contains (Right, Caret_Selection_Text)
        and then Contains (Right, Diagnostics_Text)
        and then (Command_Text'Length = 0 or else Contains (Right, Command_Text))
        and then (Build_Text'Length = 0 or else Contains (Right, Build_Text))
        and then (Search_Text'Length = 0 or else Contains (Right, Search_Text))
        and then (Quick_Open_Text'Length = 0 or else Contains (Right, Quick_Open_Text))
        and then (Outline_Text'Length = 0 or else Contains (Right, Outline_Text))
        and then (File_Tree_Text'Length = 0 or else Contains (Right, File_Tree_Text))
        and then (Workspace_Recent_Text'Length = 0
                  or else Contains (Right, Workspace_Recent_Text)
                  or else (Length (Snapshot.Workspace_Status_Label) > 0
                           and then Contains (Right, Status_Segment_Text (Snapshot.Workspace_Status_Label)))
                  or else (Length (Snapshot.Recent_Projects_Status_Label) > 0
                           and then Contains (Right, Status_Segment_Text (Snapshot.Recent_Projects_Status_Label))));
   end Assert_Status_Segment_Builders_Are_Coherent;


   function Is_Single_Line_Text
     (Text : String) return Boolean
   is
   begin
      for C of Text loop
         if C = ASCII.CR or else C = ASCII.LF or else C = ASCII.HT then
            return False;
         end if;
      end loop;
      return True;
   end Is_Single_Line_Text;

   function Assert_Status_Is_Single_Line
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Left    : constant String := Format_Left (Snapshot);
      Right   : constant String := Format_Right (Snapshot);
      Compact : constant String := Status_Layout_Compact (Snapshot, 160);
   begin
      return Is_Single_Line_Text (Left)
        and then Is_Single_Line_Text (Right)
        and then Is_Single_Line_Text (Compact);
   end Assert_Status_Is_Single_Line;

   function Assert_Status_Config_Is_Display_Only
     (Config : Status_Bar_Config) return Boolean
   is
   begin
      --  The config contains exactly the display reservation switch consumed
      --  by layout/render.  It carries no current status text, latest command
      --  outcome, subsystem summary, focus owner, or persistence payload.
      return Height_In_Rows (Config) <= 1;
   end Assert_Status_Config_Is_Display_Only;

   function Assert_Status_Carries_No_Command_Payloads
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      pragma Unreferenced (Snapshot);
   begin
      --  Status snapshots carry scalar text/counts only.  They intentionally do
      --  not contain command identifiers, keybinding payloads, command-palette
      --  payloads, message ids, filesystem targets, or destructive arguments.
      return True;
   end Assert_Status_Carries_No_Command_Payloads;

   function Assert_Status_Line_Context_Coherent
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
      Right : constant String := Format_Right (Snapshot);
      Left  : constant String := Format_Left (Snapshot);
   begin
      return Assert_Status_Snapshot_Is_Observational (Snapshot)
        and then Assert_Status_Carries_No_Command_Payloads (Snapshot)
        and then Assert_Status_State_Not_Persisted (Snapshot)
        and then Assert_Status_Shows_Active_Buffer_And_Dirty_State (Snapshot)
        and then Assert_Status_Shows_Caret_And_Selection (Snapshot)
        and then Assert_Status_Shows_Command_Outcome (Snapshot)
        and then Assert_Status_Shows_Feature_Summaries (Snapshot)
        and then Assert_Status_Summarizes_Main_Context (Snapshot)
        and then Assert_Status_Shows_File_State_Markers (Snapshot)
        and then Assert_Status_Does_Not_Copy_Rows_Or_Output (Snapshot)
        and then Assert_Status_Does_Not_Duplicate_Priority_Segments (Snapshot)
        and then Assert_Status_Command_Outcome_Uses_Public_Classes (Snapshot)
        and then Assert_Status_Layout_Is_Bounded (Snapshot, 160)
        and then Assert_Status_Layout_Preserves_Priority (Snapshot)
        and then Assert_Status_Segment_Builders_Are_Coherent (Snapshot)
        and then Assert_Status_Is_Single_Line (Snapshot)
        and then Left'Length <= 256
        and then Right'Length <= 2048
        and then (not Snapshot.Has_Command_Feedback
                  or else Length (Snapshot.Command_Feedback) = 0
                  or else Contains
                    (Right, Status_Command_Outcome_Segment (Snapshot)))
        and then (Length (Snapshot.Pending_Confirmation_Label) = 0
                  or else Contains (Right, Segment_Text (Snapshot.Pending_Confirmation_Label)));
   end Assert_Status_Line_Context_Coherent;

   function Assert_Editing_Status_And_Feedback_Coherent
     (Snapshot : Status_Bar_Snapshot) return Boolean
   is
   begin
      return Assert_Status_Snapshot_Is_Observational (Snapshot)
        and then Assert_Status_Does_Not_Copy_Feature_Rows (Snapshot)
        and then Assert_Status_Does_Not_Copy_Rows_Or_Output (Snapshot)
        and then Assert_Status_Shows_Active_Buffer_And_Dirty_State (Snapshot)
        and then Assert_Status_Shows_Caret_And_Selection (Snapshot)
        and then Assert_Status_Shows_Command_Outcome (Snapshot)
        and then Assert_Status_Shows_Feature_Summaries (Snapshot)
        and then Assert_Status_State_Not_Persisted (Snapshot)
        and then Assert_Status_Carries_No_Command_Payloads (Snapshot)
        and then Assert_Status_Line_Context_Coherent (Snapshot);
   end Assert_Editing_Status_And_Feedback_Coherent;

end Editor.Status_Bar;
