with Editor.Command_Ids; use Editor.Command_Ids;
with Ada.Strings.Fixed;

package body Editor.Commands.Workflow_Messages is

   function Normalize_Workflow_Message
     (Text : String) return String
   is
      Trimmed : constant String := Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   begin
      if Trimmed = "No project open"
        or else Trimmed = "No project open."
        or else Trimmed = "No project"
        or else Trimmed = "No project."
        or else Trimmed = "No project open for build candidates"
        or else Trimmed = "No project open for build candidates."
        or else Trimmed = "Build unavailable: no project open"
        or else Trimmed = "Build unavailable: no project open."
        or else Trimmed = "Project Search - No project open"
        or else Trimmed = "Project Search - No project open."
        or else Trimmed = "File Tree unavailable: no project open"
        or else Trimmed = "File Tree unavailable: no project open."
        or else Trimmed = "Quick Open unavailable: no project open"
        or else Trimmed = "Quick Open unavailable: no project open."
        or else Trimmed = "Project Search unavailable: no project open"
        or else Trimmed = "Project Search unavailable: no project open."
        or else Trimmed = "Build unavailable: no project open or no build request ready"
        or else Trimmed = "Build unavailable: no project open or no build request ready."
      then
         return "No project open.";
      elsif Trimmed = "No active buffer"
        or else Trimmed = "No active buffer."
        or else Trimmed = "No active buffer available for saving"
        or else Trimmed = "No active buffer available for saving."
        or else Trimmed = "Outline unavailable: no active buffer"
        or else Trimmed = "Outline unavailable: no active buffer."
        or else Trimmed = "Search Results: no active buffer"
        or else Trimmed = "Search Results: no active buffer."
        or else Trimmed = "Bookmark unavailable: no active buffer"
        or else Trimmed = "Bookmark unavailable: no active buffer."
      then
         return "No active buffer.";
      elsif Trimmed = "No buffer selected"
        or else Trimmed = "No buffer selected."
      then
         return "No buffer selected.";
      elsif Trimmed = "No selection"
        or else Trimmed = "No selection."
        or else Trimmed = "No selected text"
        or else Trimmed = "No selected text."
      then
         return "No selected text";
      elsif Trimmed = "Clipboard is empty"
        or else Trimmed = "Clipboard is empty."
        or else Trimmed = "No clipboard to clear"
        or else Trimmed = "No clipboard to clear."
      then
         return "Clipboard is empty";
      elsif Trimmed = "Invalid selection"
        or else Trimmed = "Invalid selection."
      then
         return "Invalid selection";
      elsif Trimmed = "No open buffers"
        or else Trimmed = "No open buffers."
        or else Trimmed = "No buffers open"
        or else Trimmed = "No buffers open."
      then
         return "No buffers open.";
      elsif Trimmed = "No matching open buffers"
        or else Trimmed = "No matching open buffers."
        or else Trimmed = "No matching buffers"
        or else Trimmed = "No matching buffers."
      then
         return "No matching open buffers.";
      elsif Trimmed = "No matches"
        or else Trimmed = "No matches."
      then
         return "No matches";
      elsif Trimmed = "No marked buffers"
        or else Trimmed = "No marked buffers."
      then
         return "No marked buffers.";
      elsif Trimmed = "No pending close targets"
        or else Trimmed = "No pending close targets."
        or else Trimmed = "No pending marked targets"
        or else Trimmed = "No pending marked targets."
      then
         return "No pending close targets.";
      elsif Trimmed = "No pruned pending close targets"
        or else Trimmed = "No pruned pending close targets."
      then
         return "No pruned pending close targets.";
      elsif Trimmed = "No dirty pending close targets"
        or else Trimmed = "No dirty pending close targets."
      then
         return "No dirty pending close targets";
      elsif Trimmed = "No dirty-prune preview targets"
        or else Trimmed = "No dirty-prune preview targets."
      then
         return "No dirty-prune preview targets.";
      elsif Trimmed = "No removed dirty-prune preview targets"
        or else Trimmed = "No removed dirty-prune preview targets."
      then
         return "No removed dirty-prune preview targets";
      elsif Trimmed = "No dirty-prune apply targets"
        or else Trimmed = "No dirty-prune apply targets."
      then
         return "No dirty-prune apply targets.";
      elsif Trimmed = "No removed dirty-prune apply targets"
        or else Trimmed = "No removed dirty-prune apply targets."
      then
         return "No removed dirty-prune apply targets.";
      elsif Trimmed = "Only one buffer open"
        or else Trimmed = "Only one buffer open."
      then
         return "No other buffer.";
      elsif Trimmed = "No next buffer"
        or else Trimmed = "No next buffer."
      then
         return "No next buffer.";
      elsif Trimmed = "No previous buffer"
        or else Trimmed = "No previous buffer."
      then
         return "No previous buffer.";
      elsif Trimmed = "Selected row is not a buffer"
        or else Trimmed = "Selected row is not a buffer."
      then
         return "Selected row is not a buffer.";
      elsif Trimmed = "No File Tree node selected"
        or else Trimmed = "No File Tree node selected."
        or else Trimmed = "No file tree node selected"
        or else Trimmed = "No file tree node selected."
        or else Trimmed = "File Tree unavailable: no item selected"
        or else Trimmed = "File Tree unavailable: no item selected."
      then
         return "No file selected.";
      elsif Trimmed = "No diagnostic selected"
        or else Trimmed = "No diagnostic selected."
      then
         return "No diagnostic selected";
      elsif Trimmed = "No search result selected"
        or else Trimmed = "No search result selected."
      then
         return "No search result selected.";
      elsif Trimmed = "No outline item selected"
        or else Trimmed = "No outline item selected."
      then
         return "No outline item selected.";
      elsif Trimmed = "No outline items item selected"
        or else Trimmed = "No outline items item selected."
        or else Trimmed = "Outline unavailable: no item selected"
        or else Trimmed = "Outline unavailable: no item selected."
      then
         return "No file selected.";
      elsif Trimmed = "No file selected"
        or else Trimmed = "No file selected."
        or else Trimmed = "No Quick Open selection"
        or else Trimmed = "No Quick Open selection."
        or else Trimmed = "No Quick Open match selected"
        or else Trimmed = "No Quick Open match selected."
        or else Trimmed = "No Quick Open result selected"
        or else Trimmed = "No Quick Open result selected."
        or else Trimmed = "No result selected"
        or else Trimmed = "No result selected."
        or else Trimmed = "Search Results: no selected result"
        or else Trimmed = "Search Results: no selected result."
        or else Trimmed = "No item selected"
        or else Trimmed = "No item selected."
        or else Trimmed = "No replacement selected"
        or else Trimmed = "No replacement selected."
        or else Trimmed = "Quick Open unavailable: no item selected"
        or else Trimmed = "Quick Open unavailable: no item selected."
        or else Trimmed = "Project Search unavailable: no item selected"
        or else Trimmed = "Project Search unavailable: no item selected."
        or else Trimmed = "Diagnostics unavailable: no item selected"
        or else Trimmed = "Diagnostics unavailable: no item selected."
      then
         return "No file selected.";
      elsif Trimmed = "No project search query"
        or else Trimmed = "No project search query."
        or else Trimmed = "No search query"
        or else Trimmed = "No search query."
        or else Trimmed = "Search Results: no query"
        or else Trimmed = "Search Results: no query."
      then
         return "No search query.";
      elsif Trimmed = "No project search results"
        or else Trimmed = "No project search results."
      then
         return "No project search results";
      elsif Trimmed = "No project search"
        or else Trimmed = "No search results"
        or else Trimmed = "No search results."
        or else Trimmed = "No matches found"
        or else Trimmed = "No matches found."
        or else Trimmed = "Project search completed: no matches"
        or else Trimmed = "Project search completed: no matches."
        or else Trimmed = "Search Results: no matches"
        or else Trimmed = "Search Results: no matches."
      then
         return "No search results.";
      elsif Trimmed = "Project Search shown"
        or else Trimmed = "Project Search shown."
      then
         return "Project Search shown.";
      elsif Trimmed = "Project Search hidden"
        or else Trimmed = "Project Search hidden."
      then
         return "Project Search hidden.";
      elsif Trimmed = "Invalid Project Search scope"
        or else Trimmed = "Invalid Project Search scope."
        or else Trimmed = "Invalid Project Search include filter"
        or else Trimmed = "Invalid Project Search include filter."
        or else Trimmed = "Invalid Project Search exclude filter"
        or else Trimmed = "Invalid Project Search exclude filter."
      then
         return "Invalid Project Search filter.";
      elsif Trimmed = "No Project Search kind filter to clear"
        or else Trimmed = "No Project Search kind filter to clear."
        or else Trimmed = "No Project Search scope to clear"
        or else Trimmed = "No Project Search scope to clear."
        or else Trimmed = "No Project Search include filter to clear"
        or else Trimmed = "No Project Search include filter to clear."
      then
         return "No Project Search filter to clear.";
      elsif Trimmed = "No replacement preview"
        or else Trimmed = "No replacement preview."
      then
         return "No replacement preview.";
      elsif Trimmed = Reason_Project_Search_Result_Stale
        or else Trimmed = "Search result is stale; rerun search"
        or else Trimmed = Reason_Search_Result_Stale_Rerun
        or else Trimmed = "Replacement target changed; rerun search"
        or else Trimmed = "Replacement target changed; rerun search."
        or else Trimmed = "Search results are stale"
        or else Trimmed = "Search results are stale."
        or else Trimmed = "Search results are stale; rerun search."
        or else Trimmed = Reason_Replacement_Preview_Stale
        or else Trimmed = "Replacement preview is stale."
        or else Trimmed = Reason_Selected_Replacement_Stale
        or else Trimmed = "Selected replacement is stale."
        or else Trimmed = "Selected result is stale."
        or else Trimmed = "Quick Open result is stale."
        or else Trimmed = "Quick Open result is stale"
        or else Trimmed = "Outline is stale; refresh required."
        or else Trimmed = "Outline is stale; refresh required"
        or else Trimmed = "Outline may be stale; refresh Outline before navigating."
        or else Trimmed = "File Tree target is stale; refresh required."
        or else Trimmed = "File Tree target is stale; refresh required"
        or else Trimmed = "Some diagnostics may be stale."
        or else Trimmed = "Some diagnostics may be stale"
        or else Trimmed = "Selected build candidate is stale."
        or else Trimmed = "Selected build candidate is stale"
        or else Trimmed = "Selected build candidate is stale after refresh; select a build candidate and acknowledge consent again"
        or else Trimmed = "Build run unavailable: selected build candidate is stale"
        or else Trimmed = "Build run unavailable: selected build candidate is stale."
        or else Trimmed = "candidate must be refreshed"
        or else Trimmed = "candidate must be refreshed."
      then
         return Reason_Target_Stale;
      elsif Trimmed = "Selected buffer is no longer open"
        or else Trimmed = "Selected buffer is no longer open."
      then
         return "Selected buffer is no longer open";
      elsif Trimmed = "Selected file is no longer in project"
        or else Trimmed = "Selected file is no longer in project."
        or else Trimmed = "File no longer exists"
        or else Trimmed = "File no longer exists."
        or else Trimmed = "Target no longer exists"
        or else Trimmed = "Target no longer exists."
        or else Trimmed = "Search target no longer exists"
        or else Trimmed = "Search target no longer exists."
        or else Trimmed = "Search result target unavailable"
        or else Trimmed = "Search result target unavailable."
        or else Trimmed = "Outline target unavailable"
        or else Trimmed = "Outline target unavailable."
        or else Trimmed = "Diagnostic target file is unavailable"
        or else Trimmed = "Diagnostic target file is unavailable."
        or else Trimmed = "Target file missing"
        or else Trimmed = "Target file missing."
        or else Trimmed = "Target file missing or unavailable"
        or else Trimmed = "Target file missing or unavailable."
        or else Trimmed = "candidate path missing or unavailable"
        or else Trimmed = "candidate path missing or unavailable."
        or else Trimmed = "Replacement target is unavailable"
        or else Trimmed = "Replacement target is unavailable."
        or else Trimmed = "Replacement target no longer exists"
        or else Trimmed = "Replacement target no longer exists."
      then
         return Reason_Target_Missing;
      elsif Trimmed = "Target line unavailable"
        or else Trimmed = "Target line unavailable."
        or else Trimmed = "Target line is unavailable"
        or else Trimmed = "Target line is unavailable."
        or else Trimmed = "Search target line is unavailable"
        or else Trimmed = "Search target line is unavailable."
        or else Trimmed = "Diagnostic target line is unavailable"
        or else Trimmed = "Diagnostic target line is unavailable."
      then
         return Reason_Target_Line_Unavailable;
      elsif Trimmed = "Diagnostic target column is outside the line"
        or else Trimmed = "Diagnostic target column is outside the line."
      then
         return Reason_Diagnostic_Target_Column_Outside_Line;
      elsif Trimmed = "Target is outside the current project"
        or else Trimmed = "Target is outside the current project."
        or else Trimmed = "Target path is outside the project"
        or else Trimmed = "Target path is outside the project."
        or else Trimmed = "Target outside project"
        or else Trimmed = "Target outside project."
        or else Trimmed = "target outside project"
        or else Trimmed = "target outside project."
        or else Trimmed = "Active file is outside the current project"
        or else Trimmed = "Active file is outside the current project."
        or else Trimmed = "Replacement target is outside project"
        or else Trimmed = "Replacement target is outside project."
        or else Trimmed = "candidate path outside project root"
        or else Trimmed = "candidate path outside project root."
        or else Trimmed = "Build working directory is rejected"
        or else Trimmed = "Build working directory is rejected."
      then
         return "Target is outside the current project.";
      elsif Trimmed = "Backing file no longer exists"
        or else Trimmed = "Backing file no longer exists."
      then
         return "Backing file missing.";
      elsif Trimmed = "Backing file missing"
        or else Trimmed = "Backing file missing."
      then
         return "Backing file missing.";
      elsif Trimmed = "Save As required before saving this buffer"
        or else Trimmed = "Save As required before saving this buffer."
      then
         return "Buffer has no file path.";
      elsif Trimmed = "Parent directory is unavailable"
        or else Trimmed = "Parent directory is unavailable."
        or else Trimmed = "Parent directory unavailable"
        or else Trimmed = "Parent directory unavailable."
        or else Ada.Strings.Fixed.Index
          (Trimmed, "Parent directory does not exist:") = Trimmed'First
      then
         return "Parent directory is unavailable.";
      elsif Trimmed = "File is not readable"
        or else Trimmed = "File is not readable."
      then
         return "File is not readable.";
      elsif Trimmed = "File is not writable"
        or else Trimmed = "File is not writable."
        or else Trimmed = "Replacement target is read-only"
        or else Trimmed = "Replacement target is read-only."
      then
         return "File is not writable.";
      elsif Trimmed = "Replacement target is not a regular file"
        or else Trimmed = "Replacement target is not a regular file."
      then
         return "Target is not a file.";
      elsif Trimmed = "Replacement target path is invalid"
        or else Trimmed = "Replacement target path is invalid."
        or else Trimmed = "Invalid project file path"
        or else Trimmed = "Invalid project file path."
      then
         return "Invalid file path.";
      elsif Trimmed = "Replacement text must be single-line"
        or else Trimmed = "Replacement text must be single-line."
      then
         return "Replacement text must be single-line.";
      elsif Trimmed = "Could not open file for replacement"
        or else Trimmed = "Could not open file for replacement."
      then
         return "Could not open file.";
      elsif Trimmed = "Could not reload file"
        or else Trimmed = "Could not reload file."
        or else Trimmed = "Could not reload file; buffer unchanged"
        or else Trimmed = "Could not reload file; buffer unchanged."
        or else Trimmed = "Could not reload buffer"
        or else Trimmed = "Could not reload buffer."
      then
         return "Could not reload file.";
      elsif Trimmed = "Could not save file"
        or else Trimmed = "Could not save file."
        or else Trimmed = "Could not write file; buffer remains dirty"
        or else Trimmed = "Could not write file; buffer remains dirty."
      then
         return "Could not save file.";
      elsif Trimmed = "Rename blocked by unsaved changes"
        or else Trimmed = "Rename blocked by unsaved changes."
        or else Trimmed = "Delete blocked by unsaved changes"
        or else Trimmed = "Delete blocked by unsaved changes."
        or else Trimmed = "Dirty buffer file cannot be renamed"
        or else Trimmed = "Dirty buffer file cannot be renamed."
        or else Trimmed = "Dirty buffer file cannot be deleted"
        or else Trimmed = "Dirty buffer file cannot be deleted."
      then
         return "Dirty buffer preserved.";
      elsif Trimmed = "Unsaved changes require confirmation"
        or else Trimmed = "Unsaved changes require confirmation."
        or else Trimmed = "Dirty buffer cannot be closed"
        or else Trimmed = "Dirty buffer cannot be closed."
        or else Trimmed = "Cannot close project with unsaved changes"
        or else Trimmed = "Cannot close project with unsaved changes."
        or else Trimmed = "Cannot switch project with unsaved changes"
        or else Trimmed = "Cannot switch project with unsaved changes."
        or else Trimmed = "Cannot restore workspace with unsaved changes"
        or else Trimmed = "Cannot restore workspace with unsaved changes."
        or else Trimmed = "Save or resolve changes first"
        or else Trimmed = "Save or resolve changes first."
        or else Trimmed = "Project close blocked by unsaved changes"
        or else Trimmed = "Project close blocked by unsaved changes."
        or else Trimmed = "Project switch blocked by unsaved changes"
        or else Trimmed = "Project switch blocked by unsaved changes."
        or else Trimmed = "Workspace load blocked by unsaved changes"
        or else Trimmed = "Workspace load blocked by unsaved changes."
        or else Trimmed = "Dirty buffer file cannot be copied"
        or else Trimmed = "Dirty buffer file cannot be copied."
        or else Trimmed = "Dirty buffer file cannot be moved"
        or else Trimmed = "Dirty buffer file cannot be moved."
      then
         return "Unsaved changes require confirmation.";
      elsif Trimmed = "No unsaved changes"
        or else Trimmed = "No unsaved changes."
      then
         return "No unsaved changes.";
      elsif Trimmed = "File conflict requires resolution"
        or else Trimmed = "File conflict requires resolution."
        or else Trimmed = "File conflict requires resolution before save-and-close"
        or else Trimmed = "File conflict requires resolution before save-and-close."
        or else Trimmed = "File changed on disk; choose how to proceed"
        or else Trimmed = "File changed on disk; choose how to proceed."
        or else Trimmed = "File conflict detected; choose how to proceed"
        or else Trimmed = "File conflict detected; choose how to proceed."
      then
         return "File conflict requires resolution.";
      elsif Trimmed = "Reload will discard unsaved changes"
        or else Trimmed = "Reload will discard unsaved changes."
        or else Trimmed = "Reload will discard unsaved changes. Disk version has changed since file was opened."
        or else Trimmed = "Reload will discard unsaved changes, but the backing file is missing."
        or else Trimmed = "Reload will discard unsaved changes. Backing file was replaced."
      then
         return "Reload will discard unsaved changes.";
      elsif Trimmed = "Kept buffer changes; file remains conflicted"
        or else Trimmed = "Kept buffer changes; file remains conflicted."
      then
         return "Kept buffer changes; file remains conflicted.";
      elsif Trimmed = "File conflict cancelled"
        or else Trimmed = "File conflict cancelled."
        or else Trimmed = "File conflict canceled"
        or else Trimmed = "File conflict canceled."
      then
         return "File conflict cancelled.";
      elsif Trimmed = "No changes to overwrite"
        or else Trimmed = "No changes to overwrite."
      then
         return "No changes to overwrite.";
      elsif Trimmed = "No previous navigation location"
        or else Trimmed = "No previous navigation location."
      then
         return "No previous navigation location.";
      elsif Trimmed = "Navigation: no previous navigation location"
        or else Trimmed = "Navigation: No previous navigation location"
        or else Trimmed = "Navigation: No previous navigation location."
      then
         return "Navigation: No previous navigation location.";
      elsif Trimmed = "No next navigation location"
        or else Trimmed = "No next navigation location."
      then
         return "No next navigation location.";
      elsif Trimmed = "Navigation: no next navigation location"
        or else Trimmed = "Navigation: No next navigation location"
        or else Trimmed = "Navigation: No next navigation location."
      then
         return "Navigation: No next navigation location.";
      elsif Trimmed = "No navigation history"
        or else Trimmed = "No navigation history."
        or else Trimmed = "No navigation history to clear"
        or else Trimmed = "No navigation history to clear."
      then
         return "No navigation history.";
      elsif Trimmed = "Navigation: no navigation history"
        or else Trimmed = "Navigation: No navigation history"
        or else Trimmed = "Navigation: No navigation history."
        or else Trimmed = "Navigation: no navigation history to clear"
        or else Trimmed = "Navigation: No navigation history to clear"
        or else Trimmed = "Navigation: No navigation history to clear."
      then
         return "Navigation: No navigation history.";
      elsif Trimmed = "Navigation target unavailable"
        or else Trimmed = "Navigation target unavailable."
      then
         return "Target no longer exists.";
      elsif Trimmed = "Navigation: navigation target unavailable"
        or else Trimmed = "Navigation: Navigation target unavailable"
        or else Trimmed = "Navigation: Navigation target unavailable."
        or else Trimmed = "Navigation: target no longer exists"
        or else Trimmed = "Navigation: Target no longer exists"
        or else Trimmed = "Navigation: Target no longer exists."
      then
         return "Navigation: Target no longer exists.";
      elsif Trimmed = "No clean buffers"
        or else Trimmed = "No clean buffers."
      then
         return "No clean buffers.";
      elsif Trimmed = "No dirty file-backed buffers"
        or else Trimmed = "No dirty file-backed buffers."
      then
         return "No dirty file-backed buffers.";
      elsif Trimmed = "Close cancelled"
        or else Trimmed = "Close cancelled."
        or else Trimmed = "Close canceled"
        or else Trimmed = "Close canceled."
      then
         return "Close cancelled.";
      elsif Trimmed = "Save failed; buffer remains open"
        or else Trimmed = "Save failed; buffer remains open."
        or else Trimmed = "Save failed; buffer remains open and dirty"
        or else Trimmed = "Save failed; buffer remains open and dirty."
        or else Trimmed = "Save failed; project close cancelled"
        or else Trimmed = "Save failed; project close cancelled."
      then
         return "Save failed; buffer remains open.";
      elsif Trimmed = "Save As required before saving this buffer"
        or else Trimmed = "Save As required before saving this buffer."
      then
         return "Save As required before saving this buffer";
      elsif Trimmed = "Buffer has no file path"
        or else Trimmed = "Buffer has no file path."
      then
         return "Buffer has no file path.";
      elsif Trimmed = "Command unavailable while confirmation is pending"
        or else Trimmed = "Command unavailable while confirmation is pending."
      then
         return "Command unavailable while confirmation is pending.";
      elsif Trimmed = "Another prompt is active"
        or else Trimmed = "Another prompt is active."
      then
         return "Another prompt is active.";
      elsif Trimmed = "Prompt cancelled"
        or else Trimmed = "Prompt cancelled."
        or else Trimmed = "Prompt canceled"
        or else Trimmed = "Prompt canceled."
      then
         return "Prompt cancelled.";
      elsif Trimmed = "Conflict prompt is stale"
        or else Trimmed = "Conflict prompt is stale."
        or else Trimmed = "Prompt is stale"
        or else Trimmed = "Prompt is stale."
      then
         return "Prompt is stale.";
      elsif Trimmed = "No pending confirmation"
        or else Trimmed = "No pending confirmation."
        or else Trimmed = "No close confirmation pending"
        or else Trimmed = "No close confirmation pending."
        or else Trimmed = "No pending dirty-prune apply confirmation"
        or else Trimmed = "No pending dirty-prune apply confirmation."
        or else Trimmed = "No pending reset-all confirmation"
        or else Trimmed = "No pending reset-all confirmation."
      then
         return "No pending confirmation.";
      elsif Trimmed = "Reload/revert requires its own explicit confirmation"
        or else Trimmed = "Reload/revert requires its own explicit confirmation."
      then
         return "Reload or revert requires confirmation.";
      elsif Trimmed = "Reset requires confirmation"
        or else Trimmed = "Reset requires confirmation."
      then
         return "Reset requires confirmation.";
      elsif Trimmed = "Pending transition cancelled"
        or else Trimmed = "Pending transition cancelled."
        or else Trimmed = "Pending transition canceled"
        or else Trimmed = "Pending transition canceled."
      then
         return "Pending transition cancelled.";
      elsif Trimmed = "Switch project cancelled"
        or else Trimmed = "Switch project cancelled."
        or else Trimmed = "Switch project canceled"
        or else Trimmed = "Switch project canceled."
      then
         return "Switch project cancelled.";
      elsif Trimmed = "Close project cancelled"
        or else Trimmed = "Close project cancelled."
        or else Trimmed = "Close project canceled"
        or else Trimmed = "Close project canceled."
      then
         return "Close project cancelled.";
      elsif Trimmed = "Project open cancelled"
        or else Trimmed = "Project open cancelled."
        or else Trimmed = "Project open canceled"
        or else Trimmed = "Project open canceled."
      then
         return "Project open cancelled.";
      elsif Trimmed = "Reload cancelled"
        or else Trimmed = "Reload cancelled."
        or else Trimmed = "Reload canceled"
        or else Trimmed = "Reload canceled."
      then
         return "Reload cancelled.";
      elsif Trimmed = "Revert cancelled"
        or else Trimmed = "Revert cancelled."
        or else Trimmed = "Revert canceled"
        or else Trimmed = "Revert canceled."
      then
         return "Revert cancelled.";
      elsif Trimmed = "No build candidates found"
        or else Trimmed = "No build candidates found."
        or else Trimmed = "No build candidates"
        or else Trimmed = "No build candidates."
      then
         return "No build candidates.";
      elsif Trimmed = "No build tool selected"
        or else Trimmed = "No build tool selected."
        or else Trimmed = "Build run unavailable: choose a build tool first"
        or else Trimmed = "Build run unavailable: choose a build tool first."
        or else Trimmed = "Build unavailable: build tool required"
        or else Trimmed = "Build unavailable: build tool required."
      then
         return "No build tool selected.";
      elsif Trimmed = "No build candidate selected"
        or else Trimmed = "No build candidate selected."
        or else Trimmed = "No build candidate selected after working context change"
        or else Trimmed = "No build candidate selected after working context change."
        or else Trimmed = "No build candidate selected after manual argv edit"
        or else Trimmed = "No build candidate selected after manual argv edit."
        or else Trimmed = "Build run unavailable: no build candidate selected"
        or else Trimmed = "Build run unavailable: no build candidate selected."
      then
         return "No build candidate selected.";
      elsif Trimmed = "Build run unavailable: review the request and acknowledge consent first"
        or else Trimmed = "Build run unavailable: review the request and acknowledge consent first."
        or else Trimmed = "Build unavailable: consent required"
        or else Trimmed = "Build unavailable: consent required."
        or else Trimmed = "Consent required"
        or else Trimmed = "Consent required."
        or else Trimmed = "Consent missing: review and acknowledge the build request"
        or else Trimmed = "Consent missing: review and acknowledge the build request."
        or else Trimmed = "Build candidate applied to transient request; Consent missing: review and acknowledge the build request"
        or else Trimmed = "Build candidate applied to transient request; Consent missing: review and acknowledge the build request."
      then
         return "Build consent required.";
      elsif Trimmed = "Consent stale"
        or else Trimmed = "Consent stale."
        or else Trimmed = "Consent stale: review the changed build request"
        or else Trimmed = "Consent stale: review the changed build request."
        or else Trimmed = "Build run unavailable: consent is stale after the request changed"
        or else Trimmed = "Build run unavailable: consent is stale after the request changed."
      then
         return "Build consent is stale.";
      elsif Trimmed = "Build candidate file no longer exists"
        or else Trimmed = "Build candidate file no longer exists."
        or else Trimmed = "Build run unavailable: selected project working context is unavailable"
        or else Trimmed = "Build run unavailable: selected project working context is unavailable."
        or else Trimmed = "candidate unavailable: source project context is unavailable"
        or else Trimmed = "candidate unavailable: source project context is unavailable."
        or else Trimmed = "Project root unavailable"
        or else Trimmed = "Project root unavailable."
        or else Trimmed = "Build working directory is unavailable"
        or else Trimmed = "Build working directory is unavailable."
      then
         return "Target no longer exists.";
      elsif Trimmed = "Build run unavailable: working context must come from the current project/workspace"
        or else Trimmed = "Build run unavailable: working context must come from the current project/workspace."
        or else Trimmed = "Build working context canonical path required"
        or else Trimmed = "Build working context canonical path required."
      then
         return "Target is outside the current project.";
      elsif Trimmed = "Build run unavailable: no project working context selected"
        or else Trimmed = "Build run unavailable: no project working context selected."
        or else Trimmed = "Build working directory is required"
        or else Trimmed = "Build working directory is required."
        or else Trimmed = "Build working context required"
        or else Trimmed = "Build working context required."
        or else Trimmed = "No canonical project/workspace context"
        or else Trimmed = "No canonical project/workspace context."
      then
         return "No project open.";
      elsif Trimmed = "Build execution is unavailable"
        or else Trimmed = "Build execution is unavailable."
        or else Trimmed = "Build execution backend is disabled"
        or else Trimmed = "Build execution backend is disabled."
        or else Trimmed = "Build run unavailable: execution backend is disabled"
        or else Trimmed = "Build run unavailable: execution backend is disabled."
        or else Trimmed = "Build unavailable: execution backend disabled"
        or else Trimmed = "Build unavailable: execution backend disabled."
        or else Trimmed = "Build unavailable: cancellation unsupported"
        or else Trimmed = "Build unavailable: cancellation unsupported."
      then
         return "Build execution is unavailable.";
      elsif Trimmed = "No build request"
        or else Trimmed = "No build request."
        or else Trimmed = "No build request ready"
        or else Trimmed = "No build request ready."
        or else Trimmed = "Build request is invalid"
        or else Trimmed = "Build request is invalid."
        or else Trimmed = "Build request is not ready"
        or else Trimmed = "Build request is not ready."
        or else Trimmed = "candidate request could not be formed"
        or else Trimmed = "candidate request could not be formed."
        or else Trimmed = "candidate request is not structured argv"
        or else Trimmed = "candidate request is not structured argv."
        or else Trimmed = "Build request is not ready for consent"
        or else Trimmed = "Build request is not ready for consent."
        or else Trimmed = "Build unavailable: structured arguments invalid"
        or else Trimmed = "Build unavailable: structured arguments invalid."
        or else Trimmed = "Build run unavailable: arguments must be structured tokens, not shell text"
        or else Trimmed = "Build run unavailable: arguments must be structured tokens, not shell text."
        or else Trimmed = "Build run unavailable: custom shell commands are not supported"
        or else Trimmed = "Build run unavailable: custom shell commands are not supported."
        or else Trimmed = "Build run unavailable: request option is not supported for the selected candidate"
        or else Trimmed = "Build run unavailable: request option is not supported for the selected candidate."
      then
         return "No build request ready.";
      elsif Trimmed = "No build output captured"
        or else Trimmed = "No build output captured."
        or else Trimmed = "No build output"
        or else Trimmed = "No build output."
        or else Trimmed = "Build output unavailable"
        or else Trimmed = "Build output unavailable."
        or else Trimmed = "Output unavailable"
        or else Trimmed = "Output unavailable."
        or else Trimmed = "output unavailable"
        or else Trimmed = "output unavailable."
      then
         return "No build output captured.";
      elsif Trimmed = "No stdout captured"
        or else Trimmed = "No stdout captured."
        or else Trimmed = "No standard output captured"
        or else Trimmed = "No standard output captured."
      then
         return "No stdout captured.";
      elsif Trimmed = "No stderr captured"
        or else Trimmed = "No stderr captured."
        or else Trimmed = "No standard error captured"
        or else Trimmed = "No standard error captured."
      then
         return "No stderr captured.";
      elsif Trimmed = "Item could not be renamed"
        or else Trimmed = "Item could not be renamed."
      then
         return "File or directory could not be renamed.";
      elsif Trimmed = "File renamed"
        or else Trimmed = "File renamed."
      then
         return "File renamed.";
      elsif Trimmed = "Directory renamed"
        or else Trimmed = "Directory renamed."
      then
         return "Directory renamed.";
      elsif Trimmed = "File deleted"
        or else Trimmed = "File deleted."
      then
         return "File deleted.";
      elsif Trimmed = "Directory deleted"
        or else Trimmed = "Directory deleted."
      then
         return "Directory deleted.";
      elsif Trimmed = "Create file cancelled"
        or else Trimmed = "Create file cancelled."
      then
         return "Create file cancelled.";
      elsif Trimmed = "Create directory cancelled"
        or else Trimmed = "Create directory cancelled."
      then
         return "Create directory cancelled.";
      elsif Trimmed = "Rename cancelled"
        or else Trimmed = "Rename cancelled."
      then
         return "Rename cancelled.";
      elsif Trimmed = "Delete cancelled"
        or else Trimmed = "Delete cancelled."
      then
         return "Delete cancelled.";
      elsif Trimmed = "File created; refresh failed"
        or else Trimmed = "File created; refresh failed."
      then
         return "File created; refresh failed.";
      elsif Trimmed = "Directory created; refresh failed"
        or else Trimmed = "Directory created; refresh failed."
      then
         return "Directory created; refresh failed.";

      elsif Trimmed = "Workspace state restored"
        or else Trimmed = "Workspace state restored."
        or else Trimmed = "Workspace restored"
        or else Trimmed = "Workspace restored."
      then
         return "Workspace restored.";
      elsif Trimmed = "No workspace restored"
        or else Trimmed = "No workspace restored."
        or else Trimmed = "No workspace session restored"
        or else Trimmed = "No workspace session restored."
        or else Trimmed = "Workspace session malformed; no session restored"
        or else Trimmed = "Workspace session malformed; no session restored."
        or else Trimmed = "Workspace session unreadable; no session restored"
        or else Trimmed = "Workspace session unreadable; no session restored."
      then
         return "No workspace restored.";
      elsif Trimmed = "Workspace state is invalid"
        or else Trimmed = "Workspace state is invalid."
        or else Trimmed = "Workspace state version is unsupported"
        or else Trimmed = "Workspace state version is unsupported."
        or else Trimmed = "Load workspace state failed"
        or else Trimmed = "Load workspace state failed."
        or else Trimmed = "Workspace could not be restored"
        or else Trimmed = "Workspace could not be restored."
      then
         return "Workspace could not be restored.";
      elsif Trimmed = "Workspace state available"
        or else Trimmed = "Workspace state available."
        or else Trimmed = "Workspace available"
        or else Trimmed = "Workspace available."
        or else Trimmed = "Workspace available. Run Restore Workspace."
        or else Trimmed = "Workspace available. Run Restore Workspace State."
      then
         return "Workspace available. Run Restore Workspace.";
      elsif Trimmed = "Workspace state cleared"
        or else Trimmed = "Workspace state cleared."
        or else Trimmed = "Workspace cleared"
        or else Trimmed = "Workspace cleared."
      then
         return "Workspace cleared.";
      elsif Trimmed = "Clear workspace state failed"
        or else Trimmed = "Clear workspace state failed."
        or else Trimmed = "Workspace could not be cleared"
        or else Trimmed = "Workspace could not be cleared."
      then
         return "Workspace could not be cleared.";
      elsif Trimmed = "Workspace state partially restored"
        or else Trimmed = "Workspace state partially restored."
        or else Trimmed = "Workspace restored with missing files skipped"
        or else Trimmed = "Workspace restored with missing files skipped."
        or else Trimmed = "Workspace loaded with stale entries ignored"
        or else Trimmed = "Workspace loaded with stale entries ignored."
        or else Trimmed = "Workspace loaded with stale or unsupported structural entries ignored"
        or else Trimmed = "Workspace loaded with stale or unsupported structural entries ignored."
      then
         return "Workspace restored with missing entries skipped.";
      elsif Trimmed = "No recent projects"
        or else Trimmed = "No recent projects."
        or else Trimmed = "Recent Projects list empty"
        or else Trimmed = "Recent Projects list empty."
      then
         return "No recent projects.";
      elsif Trimmed = "Recent project is unavailable"
        or else Trimmed = "Recent project is unavailable."
        or else Trimmed = "Project path no longer exists"
        or else Trimmed = "Project path no longer exists."
        or else Trimmed = "Recent project path no longer exists"
        or else Trimmed = "Recent project path no longer exists."
      then
         return "Target no longer exists.";
      elsif Trimmed = "Recent Projects loaded with invalid entries ignored"
        or else Trimmed = "Recent Projects loaded with invalid entries ignored."
        or else Trimmed = "Recent Projects loaded with invalid lightweight entries ignored"
        or else Trimmed = "Recent Projects loaded with invalid lightweight entries ignored."
      then
         return "Recent Projects loaded with invalid entries ignored.";
      elsif Trimmed = "Editor ready"
        or else Trimmed = "Editor ready."
      then
         return "Ready.";
      elsif Trimmed = "Editor ready with configuration warnings"
        or else Trimmed = "Editor ready with configuration warnings."
      then
         return "Ready with configuration warnings.";
      elsif Trimmed = "Editor ready with workspace project unavailable"
        or else Trimmed = "Editor ready with workspace project unavailable."
      then
         return "Ready with workspace project unavailable.";
      elsif Trimmed = "Settings file malformed; using defaults"
        or else Trimmed = "Settings file malformed; using defaults."
        or else Trimmed = "Settings file has an invalid format"
        or else Trimmed = "Settings file has an invalid format."
        or else Trimmed = "Settings file is invalid"
        or else Trimmed = "Settings file is invalid."
      then
         return "Settings file is invalid.";
      elsif Trimmed = "Settings loaded with invalid values reset to defaults"
        or else Trimmed = "Settings loaded with invalid values reset to defaults."
        or else Trimmed = "Settings loaded with ignored invalid entries"
        or else Trimmed = "Settings loaded with ignored invalid entries."
      then
         return "Settings loaded with invalid values reset to defaults.";
      elsif Trimmed = "Settings file unavailable"
        or else Trimmed = "Settings file unavailable."
      then
         return "Settings file unavailable.";
      elsif Trimmed = "Settings reset to defaults"
        or else Trimmed = "Settings reset to defaults."
      then
         return "Settings reset to defaults.";
      elsif Trimmed = "No setting selected"
        or else Trimmed = "No setting selected."
      then
         return "No setting selected.";
      elsif Trimmed = "Selected setting is not editable"
        or else Trimmed = "Selected setting is not editable."
      then
         return "Selected setting is not editable.";
      elsif Trimmed = "Selected setting is not toggleable"
        or else Trimmed = "Selected setting is not toggleable."
      then
         return "Selected setting is not toggleable.";
      elsif Trimmed = "Selected setting is already default"
        or else Trimmed = "Selected setting is already default."
        or else Trimmed = "Setting is already default"
        or else Trimmed = "Setting is already default."
      then
         return "Selected setting is already default.";
      elsif Trimmed = "Invalid setting value"
        or else Trimmed = "Invalid setting value."
        or else Trimmed = "Setting value is invalid"
        or else Trimmed = "Setting value is invalid."
      then
         return "Invalid setting value.";
      elsif Trimmed = "Keybindings file malformed; default keybindings active"
        or else Trimmed = "Keybindings file malformed; default keybindings active."
        or else Trimmed = "Keybindings file has an invalid format"
        or else Trimmed = "Keybindings file has an invalid format."
      then
         return "Default keybindings active.";
      elsif Trimmed = "Keybindings loaded with rejected invalid bindings"
        or else Trimmed = "Keybindings loaded with rejected invalid bindings."
        or else Trimmed = "Keybindings loaded with ignored invalid entries"
        or else Trimmed = "Keybindings loaded with ignored invalid entries."
      then
         return "Keybindings loaded with rejected bindings.";
      elsif Trimmed = "Keybinding entry is malformed"
        or else Trimmed = "Keybinding entry is malformed."
        or else Trimmed = "Invalid shortcut"
        or else Trimmed = "Invalid shortcut."
        or else Trimmed = "Shortcut is invalid"
        or else Trimmed = "Shortcut is invalid."
      then
         return "Shortcut is invalid.";
      elsif Trimmed = "Shortcut is already assigned"
        or else Trimmed = "Shortcut is already assigned."
        or else Trimmed = "Keybinding conflict: shortcut already assigned"
        or else Trimmed = "Keybinding conflict: shortcut already assigned."
      then
         return "Shortcut is already assigned.";
      elsif Trimmed = "Command is not bindable"
        or else Trimmed = "Command is not bindable."
        or else Trimmed = "Selected command is not bindable"
        or else Trimmed = "Selected command is not bindable."
      then
         return "Selected command is not bindable.";
      elsif Trimmed = "No command selected"
        or else Trimmed = "No command selected."
      then
         return "No command selected.";
      elsif Trimmed = "No keybinding selected"
        or else Trimmed = "No keybinding selected."
      then
         return "No keybinding selected.";
      elsif Trimmed = "Keybinding assignment cancelled"
        or else Trimmed = "Keybinding assignment cancelled."
        or else Trimmed = "Keybinding assignment canceled"
        or else Trimmed = "Keybinding assignment canceled."
      then
         return "Keybinding assignment cancelled.";
      elsif Trimmed = "Keybindings reset to defaults"
        or else Trimmed = "Keybindings reset to defaults."
      then
         return "Keybindings reset to defaults.";
      elsif Trimmed = "No configuration audit results"
        or else Trimmed = "No configuration audit results."
      then
         return "No configuration audit results.";
      elsif Trimmed = "All configuration domains reset after explicit confirmation"
        or else Trimmed = "All configuration domains reset after explicit confirmation."
      then
         return "All configuration domains reset.";
      elsif Trimmed = "Reset all configuration requested. Run configuration.reset-all.confirm to confirm or configuration.reset-all.cancel to cancel; project files and dirty buffers will not be changed"
        or else Trimmed = "Reset all configuration requested. Run configuration.reset-all.confirm to confirm or configuration.reset-all.cancel to cancel; project files and dirty buffers will not be changed."
      then
         return "Reset all configuration requires confirmation.";
      elsif Trimmed = "Command Palette closed"
        or else Trimmed = "Command Palette closed."
        or else Trimmed = "Command Palette is closed"
        or else Trimmed = "Command Palette is closed."
      then
         return "Command Palette closed.";
      elsif Trimmed = "No commands"
        or else Trimmed = "No commands."
      then
         return "No commands.";
      elsif Trimmed = "No available commands"
        or else Trimmed = "No available commands."
      then
         return "No available commands.";
      elsif Ada.Strings.Fixed.Index
          (Trimmed, "No available commands match") = Trimmed'First
      then
         return "No matching available commands.";
      elsif Ada.Strings.Fixed.Index
          (Trimmed, "No commands match") = Trimmed'First
      then
         return "No matching commands.";
      elsif Trimmed = "No bookmarks"
        or else Trimmed = "No bookmarks."
      then
         return "No bookmarks.";
      elsif Trimmed = "No bookmarkable location"
        or else Trimmed = "No bookmarkable location."
      then
         return "No bookmarkable location.";
      elsif Trimmed = "No bookmark in active file"
        or else Trimmed = "No bookmark in active file."
      then
         return "No bookmark in active file.";
      elsif Trimmed = "Bookmark target unavailable"
        or else Trimmed = "Bookmark target unavailable."
        or else Trimmed = "Bookmark target no longer exists"
        or else Trimmed = "Bookmark target no longer exists."
      then
         return "Target no longer exists.";
      elsif Trimmed = "Outline shown"
        or else Trimmed = "Outline shown."
      then
         return "Outline shown.";
      elsif Trimmed = "Outline focused"
        or else Trimmed = "Outline focused."
      then
         return "Outline focused.";
      elsif Trimmed = "Build UI shown"
        or else Trimmed = "Build UI shown."
      then
         return "Build Output shown.";
      elsif Trimmed = "Build UI focused"
        or else Trimmed = "Build UI focused."
      then
         return "Build Output focused.";
      elsif Trimmed = "Build UI hidden"
        or else Trimmed = "Build UI hidden."
      then
         return "Build Output hidden.";
      elsif Trimmed = "Build UI toggled"
        or else Trimmed = "Build UI toggled."
      then
         return "Build Output toggled.";
      elsif Trimmed = "Build panel is closed; open Build before running build.run"
        or else Trimmed = "Build panel is closed; open Build before running build.run."
      then
         return "Build Output is closed; open Build Output before running build.run.";
      elsif Trimmed = "Diagnostics shown"
        or else Trimmed = "Diagnostics shown."
      then
         return "Diagnostics shown.";
      elsif Trimmed = "Diagnostics cleared"
        or else Trimmed = "Diagnostics cleared."
      then
         return "Diagnostics cleared.";
      elsif Trimmed = "Diagnostics updated"
        or else Trimmed = "Diagnostics updated."
      then
         return "Diagnostics updated.";
      elsif Trimmed = "No diagnostics produced"
        or else Trimmed = "No diagnostics produced."
        or else Trimmed = "No diagnostics to reveal yet"
        or else Trimmed = "No diagnostics to reveal yet."
      then
         return "No diagnostics.";
      elsif Trimmed = "No diagnostics"
        or else Trimmed = "No diagnostics."
        or else Trimmed = "Diagnostics: none"
      then
         return "No diagnostics.";
      elsif Trimmed = "No source target"
        or else Trimmed = "No source target."
        or else Trimmed = "Selected diagnostic has no source target"
        or else Trimmed = "Selected diagnostic has no source target."
      then
         return "Selected diagnostic has no source target.";
      else
         return Text;
      end if;
   end Normalize_Workflow_Message;

end Editor.Commands.Workflow_Messages;
