with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
package body Editor.Commands is

   use Position_Vectors;
   use Delete_Count_Vectors;
   use Text_Vectors;
   function "=" (L, R : Command) return Boolean is
   begin
      return L.Kind = R.Kind
        and then L.Pos = R.Pos
        and then L.Has_Position = R.Has_Position
        and then L.Ch = R.Ch
        and then L.Code = R.Code
        and then L.Shift = R.Shift
        and then L.Ctrl = R.Ctrl
        and then L.Alt = R.Alt
        and then L.Click_X = R.Click_X
        and then L.Click_Y = R.Click_Y
        and then L.Positions = R.Positions
        and then L.Delete_Counts = R.Delete_Counts
        and then L.Insert_Texts = R.Insert_Texts
        and then L.Text = R.Text
        and then L.Path = R.Path
        and then L.Query = R.Query
        and then L.Buffer_Id = R.Buffer_Id;
   end "=";




   function Available return Command_Availability
   is
   begin
      return (Status => Command_Available, Reason => Null_Unbounded_String);
   end Available;

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
      elsif Trimmed = "Search result is stale; run Project Search again."
        or else Trimmed = "Search result is stale; rerun search"
        or else Trimmed = "Search result is stale; rerun search."
        or else Trimmed = "Replacement target changed; rerun search"
        or else Trimmed = "Replacement target changed; rerun search."
        or else Trimmed = "Search results are stale"
        or else Trimmed = "Search results are stale."
        or else Trimmed = "Search results are stale; rerun search."
        or else Trimmed = "Replacement preview is stale"
        or else Trimmed = "Replacement preview is stale."
        or else Trimmed = "Selected replacement is stale"
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
         return "Target is stale; refresh required.";
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
         return "Target no longer exists.";
      elsif Trimmed = "Target line unavailable"
        or else Trimmed = "Target line unavailable."
        or else Trimmed = "Target line is unavailable"
        or else Trimmed = "Target line is unavailable."
        or else Trimmed = "Search target line is unavailable"
        or else Trimmed = "Search target line is unavailable."
        or else Trimmed = "Diagnostic target line is unavailable"
        or else Trimmed = "Diagnostic target line is unavailable."
        or else Trimmed = "Diagnostic target column is outside the line"
        or else Trimmed = "Diagnostic target column is outside the line."
      then
         return "Target line is unavailable.";
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
      then
         return "Workspace available.";
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

   function Unavailable
     (Reason : String) return Command_Availability
   is
   begin
      return
        (Status => Command_Unavailable,
         Reason => To_Unbounded_String (Normalize_Workflow_Message (Reason)));
   end Unavailable;

   function Is_Available
     (Availability : Command_Availability) return Boolean
   is
   begin
      return Availability.Status = Command_Available;
   end Is_Available;

   function Unavailable_Reason
     (Availability : Command_Availability) return String
   is
   begin
      return Normalize_Workflow_Message (To_String (Availability.Reason));
   end Unavailable_Reason;

   function Command_For_Id
     (Id    : Command_Id;
      Shift : Boolean := False) return Command
   is
      Cmd : Command;
   begin
      Cmd.Shift := Shift;

      case Id is
         when Command_Move_Left =>
            Cmd.Kind := Move_Left;
         when Command_Move_Right =>
            Cmd.Kind := Move_Right;
         when Command_Move_Up =>
            Cmd.Kind := Move_Up;
         when Command_Move_Down =>
            Cmd.Kind := Move_Down;
         when Command_Move_Line_Start =>
            Cmd.Kind := Move_Line_Start;
         when Command_Move_Line_End =>
            Cmd.Kind := Move_Line_End;
         when Command_Move_Document_Start =>
            Cmd.Kind := Move_Document_Start;
         when Command_Move_Document_End =>
            Cmd.Kind := Move_Document_End;
         when Command_Move_Word_Left =>
            Cmd.Kind := Move_Word_Left;
         when Command_Move_Word_Right =>
            Cmd.Kind := Move_Word_Right;
         when Command_Page_Up =>
            Cmd.Kind := Move_Page_Up;
         when Command_Page_Down =>
            Cmd.Kind := Move_Page_Down;
         when Command_Select_Left =>
            Cmd.Kind := Move_Left;
            Cmd.Shift := True;
         when Command_Select_Right =>
            Cmd.Kind := Move_Right;
            Cmd.Shift := True;
         when Command_Select_Up =>
            Cmd.Kind := Move_Up;
            Cmd.Shift := True;
         when Command_Select_Down =>
            Cmd.Kind := Move_Down;
            Cmd.Shift := True;
         when Command_Select_Word_Left =>
            Cmd.Kind := Select_Word_Left;
            Cmd.Shift := True;
         when Command_Select_Word_Right =>
            Cmd.Kind := Select_Word_Right;
            Cmd.Shift := True;
         when Command_Select_Word =>
            Cmd.Kind := Select_Word;
         when Command_Select_Line =>
            Cmd.Kind := Select_Line;
         when Command_Start_Rectangular_Selection =>
            Cmd.Kind := Start_Rectangle_At_Caret;
         when Command_Clear_Rectangular_Selection =>
            Cmd.Kind := Clear_Rectangle_Selection;
         when Command_Extend_Selection_Line_Up =>
            Cmd.Kind := Extend_Selection_Line_Up;
            Cmd.Shift := True;
         when Command_Extend_Selection_Line_Down =>
            Cmd.Kind := Extend_Selection_Line_Down;
            Cmd.Shift := True;
         when Command_Select_Line_Start =>
            Cmd.Kind := Select_Line_Start;
            Cmd.Shift := True;
         when Command_Select_Line_End =>
            Cmd.Kind := Select_Line_End;
            Cmd.Shift := True;
         when Command_Select_Document_Start =>
            Cmd.Kind := Select_Document_Start;
            Cmd.Shift := True;
         when Command_Select_Document_End =>
            Cmd.Kind := Select_Document_End;
            Cmd.Shift := True;
         when Command_Select_Page_Up =>
            Cmd.Kind := Select_Page_Up;
            Cmd.Shift := True;
         when Command_Select_Page_Down =>
            Cmd.Kind := Select_Page_Down;
            Cmd.Shift := True;
         when Command_Insert_Newline =>
            Cmd.Kind := Insert_Text_Input;
            Cmd.Ch := ASCII.LF;
            Cmd.Code := Wide_Wide_Character'Val (Character'Pos (ASCII.LF));
            Cmd.Text := To_Unbounded_String (String'(1 => ASCII.LF));
         when Command_Undo =>
            Cmd.Kind := Undo;
         when Command_Redo =>
            Cmd.Kind := Redo;
         when Command_Edit_History_Clear =>
            Cmd.Kind := Break_Group;
         when Command_Copy =>
            Cmd.Kind := Copy_Selection;
         when Command_Cut =>
            Cmd.Kind := Cut_Selection;
         when Command_Paste =>
            Cmd.Kind := Paste_Clipboard;
         when Command_Clipboard_Clear =>
            Cmd.Kind := Clear_Clipboard;
         when Command_Selection_Delete =>
            Cmd.Kind := Delete_Selection_Range;
         when Command_Line_Delete =>
            Cmd.Kind := Delete_Current_Line;
         when Command_Line_Duplicate =>
            Cmd.Kind := Duplicate_Current_Line;
         when Command_Line_Move_Up =>
            Cmd.Kind := Move_Current_Line_Up;
         when Command_Line_Move_Down =>
            Cmd.Kind := Move_Current_Line_Down;
         when Command_Indent_Increase =>
            Cmd.Kind := Indent_Current_Line;
         when Command_Indent_Decrease =>
            Cmd.Kind := Outdent_Current_Line;
         when Command_Comment_Line =>
            Cmd.Kind := Comment_Current_Line;
         when Command_Uncomment_Line =>
            Cmd.Kind := Uncomment_Current_Line;
         when Command_Toggle_Line_Comment =>
            Cmd.Kind := Toggle_Current_Line_Comment;
         when Command_Line_Join_Next =>
            Cmd.Kind := Join_Current_Line_With_Next;
         when Command_Line_Split_At_Caret =>
            Cmd.Kind := Split_Current_Line_At_Caret;
         when Command_Trim_Trailing_Whitespace =>
            Cmd.Kind := Trim_Trailing_Whitespace;
         when Command_Char_Delete_Previous =>
            Cmd.Kind := Delete_Previous_Character;
         when Command_Char_Delete_Next =>
            Cmd.Kind := Delete_Next_Character;
         when Command_Word_Delete_Previous =>
            Cmd.Kind := Delete_Previous_Word;
         when Command_Word_Delete_Next =>
            Cmd.Kind := Delete_Next_Word;
         when Command_Save_File =>
            Cmd.Kind := Save_File;
         when Command_Save_File_As =>
            Cmd.Kind := Save_File_As;
         when Command_Reload_Active_Buffer =>
            Cmd.Kind := Reload_Active_Buffer;
         when Command_Revert_Active_Buffer =>
            Cmd.Kind := Revert_Active_Buffer;
         when Command_File_Conflict_Keep_Buffer =>
            Cmd.Kind := File_Conflict_Keep_Buffer;
         when Command_File_Conflict_Reload_From_Disk =>
            Cmd.Kind := File_Conflict_Reload_From_Disk;
         when Command_File_Conflict_Overwrite_Disk =>
            Cmd.Kind := File_Conflict_Overwrite_Disk;
         when Command_File_Conflict_Cancel =>
            Cmd.Kind := File_Conflict_Cancel;
         when Command_Rename_Buffer_File =>
            Cmd.Kind := Rename_Buffer_File;
         when Command_Delete_Buffer_File =>
            Cmd.Kind := Delete_Buffer_File;
         when Command_Copy_Buffer_File =>
            Cmd.Kind := Copy_Buffer_File;
         when Command_Move_Buffer_File =>
            Cmd.Kind := Move_Buffer_File;
         when Command_Save_All =>
            Cmd.Kind := Save_All;
         when Command_Open_Quick_Open =>
            Cmd.Kind := Open_Quick_Open;
         when Command_Close_Quick_Open =>
            Cmd.Kind := Close_Quick_Open;
         when Command_Toggle_Quick_Open =>
            Cmd.Kind := Toggle_Quick_Open;
         when Command_Accept_Quick_Open =>
            Cmd.Kind := Accept_Quick_Open;
         when Command_Quick_Open_Next_Result =>
            Cmd.Kind := Quick_Open_Next_Result;
         when Command_Quick_Open_Previous_Result =>
            Cmd.Kind := Quick_Open_Previous_Result;
         when Command_Quick_Open_Query_Set =>
            Cmd.Kind := Quick_Open_Query_Set;
         when Command_Quick_Open_Query_Clear =>
            Cmd.Kind := Quick_Open_Query_Clear;
         when Command_Quick_Open_Kind_Next =>
            Cmd.Kind := Quick_Open_Kind_Next;
         when Command_Quick_Open_Kind_Previous =>
            Cmd.Kind := Quick_Open_Kind_Previous;
         when Command_Quick_Open_Kind_Clear =>
            Cmd.Kind := Quick_Open_Kind_Clear;
         when Command_Quick_Open_Scope_Set =>
            Cmd.Kind := Quick_Open_Scope_Set;
         when Command_Quick_Open_Scope_Clear =>
            Cmd.Kind := Quick_Open_Scope_Clear;
         when Command_Quick_Open_Scope_From_Selected =>
            Cmd.Kind := Quick_Open_Scope_From_Selected;
         when Command_Quick_Open_Scope_Parent =>
            Cmd.Kind := Quick_Open_Scope_Parent;
         when Command_Quick_Open_Reveal_Active =>
            Cmd.Kind := Quick_Open_Reveal_Active;
         when Command_Quick_Open_Scope_Active_Directory =>
            Cmd.Kind := Quick_Open_Scope_Active_Directory;
         when Command_Quick_Open_Create_From_Query =>
            Cmd.Kind := Quick_Open_Create_From_Query;
         when Command_Quick_Open_Create_With_Parents_From_Query =>
            Cmd.Kind := Quick_Open_Create_With_Parents_From_Query;
         when Command_Quick_Open_Priority_Toggle =>
            Cmd.Kind := Quick_Open_Priority_Toggle;
         when Command_Quick_Open_Priority_Clear =>
            Cmd.Kind := Quick_Open_Priority_Clear;
         when Command_Open_Buffer_Switcher =>
            Cmd.Kind := Open_Buffer_Switcher;
         when Command_Close_Buffer_Switcher =>
            Cmd.Kind := Close_Buffer_Switcher;
         when Command_Accept_Buffer_Switcher =>
            Cmd.Kind := Accept_Buffer_Switcher;
         when Command_Buffer_Switcher_Next_Result =>
            Cmd.Kind := Buffer_Switcher_Next_Result;
         when Command_Buffer_Switcher_Previous_Result =>
            Cmd.Kind := Buffer_Switcher_Previous_Result;
         when Command_Buffer_Switcher_Filter_Clear =>
            Cmd.Kind := Buffer_Switcher_Filter_Clear;
         when Command_Buffer_Switcher_Filter_Pinned =>
            Cmd.Kind := Buffer_Switcher_Filter_Pinned;
         when Command_Buffer_Switcher_Filter_Group =>
            Cmd.Kind := Buffer_Switcher_Filter_Group;
         when Command_Buffer_Switcher_Filter_Label =>
            Cmd.Kind := Buffer_Switcher_Filter_Label;
         when Command_Buffer_Switcher_Filter_Noted =>
            Cmd.Kind := Buffer_Switcher_Filter_Noted;
         when Command_Buffer_Switcher_Sort_Default =>
            Cmd.Kind := Buffer_Switcher_Sort_Default;
         when Command_Buffer_Switcher_Sort_Recent =>
            Cmd.Kind := Buffer_Switcher_Sort_Recent;
         when Command_Buffer_Switcher_Sort_Name =>
            Cmd.Kind := Buffer_Switcher_Sort_Name;
         when Command_Buffer_Switcher_Sort_Pinned =>
            Cmd.Kind := Buffer_Switcher_Sort_Pinned;
         when Command_Buffer_Switcher_Sort_Group =>
            Cmd.Kind := Buffer_Switcher_Sort_Group;
         when Command_Buffer_Switcher_Sort_Label =>
            Cmd.Kind := Buffer_Switcher_Sort_Label;
         when Command_Buffer_Switcher_Sort_Next =>
            Cmd.Kind := Buffer_Switcher_Sort_Next;
         when Command_Buffer_Switcher_Sort_Previous =>
            Cmd.Kind := Buffer_Switcher_Sort_Previous;
         when Command_Buffer_Switcher_Selected_Close =>
            Cmd.Kind := Buffer_Switcher_Selected_Close;
         when Command_Buffer_Switcher_Selected_Pin =>
            Cmd.Kind := Buffer_Switcher_Selected_Pin;
         when Command_Buffer_Switcher_Selected_Unpin =>
            Cmd.Kind := Buffer_Switcher_Selected_Unpin;
         when Command_Buffer_Switcher_Selected_Toggle_Pin =>
            Cmd.Kind := Buffer_Switcher_Selected_Toggle_Pin;
         when Command_Buffer_Switcher_Selected_Group_Assign =>
            Cmd.Kind := Buffer_Switcher_Selected_Group_Assign;
         when Command_Buffer_Switcher_Selected_Group_Clear =>
            Cmd.Kind := Buffer_Switcher_Selected_Group_Clear;
         when Command_Buffer_Switcher_Selected_Label_Set =>
            Cmd.Kind := Buffer_Switcher_Selected_Label_Set;
         when Command_Buffer_Switcher_Selected_Label_Clear =>
            Cmd.Kind := Buffer_Switcher_Selected_Label_Clear;
         when Command_Buffer_Switcher_Selected_Note_Set =>
            Cmd.Kind := Buffer_Switcher_Selected_Note_Set;
         when Command_Buffer_Switcher_Selected_Note_Clear =>
            Cmd.Kind := Buffer_Switcher_Selected_Note_Clear;
         when Command_Buffer_Switcher_Preview_Toggle =>
            Cmd.Kind := Buffer_Switcher_Preview_Toggle;
         when Command_Buffer_Switcher_Preview_Show =>
            Cmd.Kind := Buffer_Switcher_Preview_Show;
         when Command_Buffer_Switcher_Preview_Hide =>
            Cmd.Kind := Buffer_Switcher_Preview_Hide;
         when Command_Buffer_Switcher_Preview_Next_Line =>
            Cmd.Kind := Buffer_Switcher_Preview_Next_Line;
         when Command_Buffer_Switcher_Preview_Previous_Line =>
            Cmd.Kind := Buffer_Switcher_Preview_Previous_Line;
         when Command_Buffer_Switcher_Preview_Center_Cursor =>
            Cmd.Kind := Buffer_Switcher_Preview_Center_Cursor;
         when Command_Buffer_Switcher_Mark_Toggle =>
            Cmd.Kind := Buffer_Switcher_Mark_Toggle;
         when Command_Buffer_Switcher_Mark_Set =>
            Cmd.Kind := Buffer_Switcher_Mark_Set;
         when Command_Buffer_Switcher_Mark_Clear =>
            Cmd.Kind := Buffer_Switcher_Mark_Clear;
         when Command_Buffer_Switcher_Mark_Clear_All =>
            Cmd.Kind := Buffer_Switcher_Mark_Clear_All;
         when Command_Buffer_Switcher_Mark_Invert_Visible =>
            Cmd.Kind := Buffer_Switcher_Mark_Invert_Visible;
         when Command_Buffer_Switcher_Mark_Visible =>
            Cmd.Kind := Buffer_Switcher_Mark_Visible;
         when Command_Buffer_Switcher_Mark_Clear_Visible =>
            Cmd.Kind := Buffer_Switcher_Mark_Clear_Visible;
         when Command_Buffer_Switcher_Mark_Pinned =>
            Cmd.Kind := Buffer_Switcher_Mark_Pinned;
         when Command_Buffer_Switcher_Mark_Group =>
            Cmd.Kind := Buffer_Switcher_Mark_Group;
         when Command_Buffer_Switcher_Mark_Label =>
            Cmd.Kind := Buffer_Switcher_Mark_Label;
         when Command_Buffer_Switcher_Mark_Noted =>
            Cmd.Kind := Buffer_Switcher_Mark_Noted;
         when Command_Buffer_Switcher_Mark_Close_Marked =>
            Cmd.Kind := Buffer_Switcher_Mark_Close_Marked;
         when Command_Buffer_Switcher_Mark_Confirm =>
            Cmd.Kind := Buffer_Switcher_Mark_Confirm;
         when Command_Buffer_Switcher_Mark_Cancel =>
            Cmd.Kind := Buffer_Switcher_Mark_Cancel;
         when Command_Buffer_Switcher_Mark_Pin_Marked =>
            Cmd.Kind := Buffer_Switcher_Mark_Pin_Marked;
         when Command_Buffer_Switcher_Mark_Unpin_Marked =>
            Cmd.Kind := Buffer_Switcher_Mark_Unpin_Marked;
         when Command_Buffer_Switcher_Mark_Clear_Metadata =>
            Cmd.Kind := Buffer_Switcher_Mark_Clear_Metadata;
         when Command_Buffer_Switcher_Mark_Group_Assign =>
            Cmd.Kind := Buffer_Switcher_Mark_Group_Assign;
         when Command_Buffer_Switcher_Mark_Group_Clear =>
            Cmd.Kind := Buffer_Switcher_Mark_Group_Clear;
         when Command_Buffer_Switcher_Mark_Label_Set =>
            Cmd.Kind := Buffer_Switcher_Mark_Label_Set;
         when Command_Buffer_Switcher_Mark_Label_Clear =>
            Cmd.Kind := Buffer_Switcher_Mark_Label_Clear;
         when Command_Buffer_Switcher_Mark_Note_Set =>
            Cmd.Kind := Buffer_Switcher_Mark_Note_Set;
         when Command_Buffer_Switcher_Mark_Note_Clear =>
            Cmd.Kind := Buffer_Switcher_Mark_Note_Clear;
         when Command_Buffer_Switcher_Mark_Review_Toggle =>
            Cmd.Kind := Buffer_Switcher_Mark_Review_Toggle;
         when Command_Buffer_Switcher_Mark_Review_Show =>
            Cmd.Kind := Buffer_Switcher_Mark_Review_Show;
         when Command_Buffer_Switcher_Mark_Review_Hide =>
            Cmd.Kind := Buffer_Switcher_Mark_Review_Hide;
         when Command_Buffer_Switcher_Pending_Mark_Review_Toggle =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Review_Toggle;
         when Command_Buffer_Switcher_Pending_Mark_Review_Show =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Review_Show;
         when Command_Buffer_Switcher_Pending_Mark_Review_Hide =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Review_Hide;
         when Command_Buffer_Switcher_Pending_Mark_Next =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Next;
         when Command_Buffer_Switcher_Pending_Mark_Previous =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Previous;
         when Command_Buffer_Switcher_Pending_Mark_Summary =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Summary;
         when Command_Buffer_Switcher_Pending_Mark_Remove_Selected =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Remove_Selected;
         when Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Restore_Last_Pruned;
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Summary =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Pruned_Summary;
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Next =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Pruned_Next;
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Previous =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Pruned_Previous;
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle;
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Pruned_Review_Show;
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Pruned_Review_Hide;
         when Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Summary =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Summary;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Next =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Next;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Previous =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Previous;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Next;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale;
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary =>
            Cmd.Kind := Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary;
         when Command_Buffer_Switcher_Mark_Next =>
            Cmd.Kind := Buffer_Switcher_Mark_Next;
         when Command_Buffer_Switcher_Mark_Previous =>
            Cmd.Kind := Buffer_Switcher_Mark_Previous;
         when Command_Buffer_Switcher_Mark_Summary =>
            Cmd.Kind := Buffer_Switcher_Mark_Summary;
         when Command_Open_Project =>
            Cmd.Kind := Open_Project;
         when Command_Switch_Project =>
            Cmd.Kind := Switch_Project;
         when Command_Show_Recent_Projects =>
            Cmd.Kind := Show_Recent_Projects;
         when Command_Open_Selected_Recent_Project =>
            Cmd.Kind := Open_Selected_Recent_Project;
         when Command_Clear_Recent_Projects =>
            Cmd.Kind := Clear_Recent_Projects;
         when Command_Remove_Selected_Recent_Project =>
            Cmd.Kind := Remove_Selected_Recent_Project;
         when Command_Remove_Missing_Recent_Projects =>
            Cmd.Kind := Remove_Missing_Recent_Projects;
         when Command_Select_Next_Recent_Project =>
            Cmd.Kind := Select_Next_Recent_Project;
         when Command_Select_Previous_Recent_Project =>
            Cmd.Kind := Select_Previous_Recent_Project;
         when Command_Close_Project =>
            Cmd.Kind := Close_Project;
         when Command_Clear_Project =>
            Cmd.Kind := Clear_Project;
         when Command_Refresh_File_Tree =>
            Cmd.Kind := Refresh_File_Tree;
         when Command_Refresh_Project_Files =>
            Cmd.Kind := Refresh_Project_Files;
         when Command_Project_Files_Summary =>
            Cmd.Kind := Project_Files_Summary;
         when Command_Reveal_Active_File_In_Tree =>
            Cmd.Kind := Reveal_Active_File_In_Tree;
         when Command_Open_Command_Palette =>
            Cmd.Kind := Open_Command_Palette;
         when Command_Palette_Show_Command_Help =>
            Cmd.Kind := Palette_Show_Command_Help;
         when Command_New_Buffer =>
            Cmd.Kind := New_Buffer;
         when Command_Close_Active_Buffer
            | Command_Confirm_Close_Save
            | Command_Confirm_Close_Discard
            | Command_Cancel_Close =>
            Cmd.Kind := Close_Buffer;
         when Command_Reopen_Closed_Buffer =>
            Cmd.Kind := Reopen_Closed_Buffer;
         when Command_Close_Other_Buffers =>
            Cmd.Kind := Close_Other_Buffers;
         when Command_Close_All_Buffers =>
            Cmd.Kind := Close_All_Clean_Buffers;
         when Command_Close_All_Clean_Buffers =>
            Cmd.Kind := Close_All_Clean_Buffers;
         when Command_Pin_Buffer =>
            Cmd.Kind := Pin_Buffer;
         when Command_Unpin_Buffer =>
            Cmd.Kind := Unpin_Buffer;
         when Command_Toggle_Buffer_Pin =>
            Cmd.Kind := Toggle_Buffer_Pin;
         when Command_Set_Buffer_Label =>
            Cmd.Kind := Set_Buffer_Label;
         when Command_Clear_Buffer_Label =>
            Cmd.Kind := Clear_Buffer_Label;
         when Command_Edit_Buffer_Label =>
            Cmd.Kind := Edit_Buffer_Label;
         when Command_Show_Buffer_Label =>
            Cmd.Kind := Show_Buffer_Label;
         when Command_Set_Buffer_Note =>
            Cmd.Kind := Set_Buffer_Note;
         when Command_Clear_Buffer_Note =>
            Cmd.Kind := Clear_Buffer_Note;
         when Command_Edit_Buffer_Note =>
            Cmd.Kind := Edit_Buffer_Note;
         when Command_Show_Buffer_Note =>
            Cmd.Kind := Show_Buffer_Note;
         when Command_Assign_Buffer_Group =>
            Cmd.Kind := Assign_Buffer_Group;
         when Command_Clear_Buffer_Group =>
            Cmd.Kind := Clear_Buffer_Group;
         when Command_Switch_Buffer_Group =>
            Cmd.Kind := Switch_Buffer_Group;
         when Command_Next_Buffer_Group =>
            Cmd.Kind := Next_Buffer_Group;
         when Command_Previous_Buffer_Group =>
            Cmd.Kind := Previous_Buffer_Group;
         when Command_Show_All_Buffer_Groups =>
            Cmd.Kind := Show_All_Buffer_Groups;
         when Command_Cancel_Pending_Transition =>
            Cmd.Kind := Cancel_Pending_Transition;
         when Command_Retry_Pending_Transition =>
            Cmd.Kind := Retry_Pending_Transition;
         when Command_Discard_Pending_Transition =>
            Cmd.Kind := Discard_Pending_Transition;
         when Command_Next_Buffer =>
            Cmd.Kind := Next_Buffer;
         when Command_Previous_Buffer =>
            Cmd.Kind := Previous_Buffer;
         when Command_Previous_Recent_Buffer =>
            Cmd.Kind := Previous_Recent_Buffer;
         when Command_Next_Recent_Buffer =>
            Cmd.Kind := Next_Recent_Buffer;
         when Command_Switch_Buffer =>
            Cmd.Kind := Switch_Buffer;
         when Command_Toggle_Problems_Panel =>
            Cmd.Kind := Toggle_Problems_Panel;
         when Command_Next_Diagnostic =>
            Cmd.Kind := Next_Diagnostic;
         when Command_Previous_Diagnostic =>
            Cmd.Kind := Previous_Diagnostic;
         when Command_Toggle_Bookmark =>
            Cmd.Kind := Toggle_Bookmark;
         when Command_Next_Bookmark =>
            Cmd.Kind := Next_Bookmark;
         when Command_Previous_Bookmark =>
            Cmd.Kind := Previous_Bookmark;
         when Command_Clear_Bookmarks =>
            Cmd.Kind := Clear_Bookmarks;
         when Command_Clear_All_Bookmarks =>
            Cmd.Kind := Clear_All_Bookmarks;
         when Command_Bookmark_Toggle_Current_Location =>
            Cmd.Kind := Bookmark_Toggle_Current_Location;
         when Command_Bookmark_Clear_All =>
            Cmd.Kind := Bookmark_Clear_All;
         when Command_Bookmark_Next =>
            Cmd.Kind := Bookmark_Next;
         when Command_Bookmark_Previous =>
            Cmd.Kind := Bookmark_Previous;
         when Command_Bookmark_Goto_Next =>
            Cmd.Kind := Bookmark_Goto_Next;
         when Command_Bookmark_Goto_Previous =>
            Cmd.Kind := Bookmark_Goto_Previous;
         when Command_Bookmark_Open_Selected =>
            Cmd.Kind := Bookmark_Open_Selected;
         when Command_Bookmark_Reveal_Current =>
            Cmd.Kind := Bookmark_Reveal_Current;
         when Command_Bookmark_Remove_Selected =>
            Cmd.Kind := Bookmark_Remove_Selected;
         when Command_Bookmark_Show =>
            Cmd.Kind := Bookmark_Show;
         when Command_Bookmark_Hide =>
            Cmd.Kind := Bookmark_Hide;
         when Command_Bookmark_Toggle =>
            Cmd.Kind := Bookmark_Toggle;
         when Command_Cancel =>
            Cmd.Kind := Clear_Extra_Carets;
         when Command_Goto_Start =>
            Cmd.Kind := Move_Document_Start;
         when Command_Goto_End =>
            Cmd.Kind := Move_Document_End;
         when Command_Goto_Line =>
            Cmd.Kind := Open_Goto_Line;
         when Command_Goto_Line_Toggle =>
            Cmd.Kind := Toggle_Goto_Line;
         when Command_Goto_Line_Prefill_Current =>
            Cmd.Kind := Prefill_Goto_Line_Current;
         when Command_Goto_Line_Query_Set =>
            Cmd.Kind := Goto_Line_Query_Set;
         when Command_Goto_Line_Query_Clear =>
            Cmd.Kind := Goto_Line_Query_Clear;
         when Command_Navigation_Back =>
            Cmd.Kind := Navigation_Back;
         when Command_Navigation_Forward =>
            Cmd.Kind := Navigation_Forward;
         when Command_Navigation_History_Clear =>
            Cmd.Kind := Navigation_History_Clear;
         when Command_Close_Goto_Line =>
            Cmd.Kind := Close_Goto_Line;
         when Command_Accept_Goto_Line =>
            Cmd.Kind := Accept_Goto_Line;
         when Command_Find_Show =>
            Cmd.Kind := Active_Find_Show;
         when Command_Find_Hide =>
            Cmd.Kind := Active_Find_Hide;
         when Command_Find_Toggle =>
            Cmd.Kind := Active_Find_Toggle;
         when Command_Find_Query_Set =>
            Cmd.Kind := Active_Find_Query_Set;
         when Command_Find_Query_Clear =>
            Cmd.Kind := Active_Find_Query_Clear;
         when Command_Find_Case_Toggle =>
            Cmd.Kind := Active_Find_Case_Toggle;
         when Command_Find_Case_Clear =>
            Cmd.Kind := Active_Find_Case_Clear;
         when Command_Find_Whole_Word_Toggle =>
            Cmd.Kind := Active_Find_Whole_Word_Toggle;
         when Command_Find_Whole_Word_Clear =>
            Cmd.Kind := Active_Find_Whole_Word_Clear;
         when Command_Find_From_Selection =>
            Cmd.Kind := Active_Find_From_Selection;
         when Command_Find_From_Active_Word =>
            Cmd.Kind := Active_Find_From_Active_Word;
         when Command_Active_Find_Next =>
            Cmd.Kind := Active_Find_Next;
         when Command_Active_Find_Previous =>
            Cmd.Kind := Active_Find_Previous;
         when Command_Find_First =>
            Cmd.Kind := Active_Find_First;
         when Command_Find_Last =>
            Cmd.Kind := Active_Find_Last;
         when Command_Find_Reveal_Current =>
            Cmd.Kind := Active_Find_Reveal_Current;
         when Command_Replace_Show =>
            Cmd.Kind := Active_Replace_Show;
         when Command_Replace_Hide =>
            Cmd.Kind := Active_Replace_Hide;
         when Command_Replace_Toggle =>
            Cmd.Kind := Active_Replace_Toggle;
         when Command_Replace_Text_Set =>
            Cmd.Kind := Active_Replace_Text_Set;
         when Command_Replace_Text_Clear =>
            Cmd.Kind := Active_Replace_Text_Clear;
         when Command_Replace_Current =>
            Cmd.Kind := Active_Replace_Current;
         when Command_Replace_All =>
            Cmd.Kind := Active_Replace_All;
         when Command_Run_Project_Search =>
            Cmd.Kind := Run_Project_Search;
         when Command_Rerun_Project_Search =>
            Cmd.Kind := Rerun_Project_Search;
         when Command_Open_Project_Search_Bar =>
            Cmd.Kind := Open_Project_Search_Bar;
         when Command_Toggle_Project_Search_Bar =>
            Cmd.Kind := Toggle_Project_Search_Bar;
         when Command_Close_Project_Search_Bar =>
            Cmd.Kind := Close_Project_Search_Bar;
         when Command_Run_Project_Search_From_Bar =>
            Cmd.Kind := Run_Project_Search_From_Bar;
         when Command_Project_Search_From_Selection =>
            Cmd.Kind := Project_Search_From_Selection;
         when Command_Project_Search_From_Active_Word =>
            Cmd.Kind := Project_Search_From_Active_Word;
         when Command_Project_Search_Active_Directory =>
            Cmd.Kind := Project_Search_Active_Directory;
         when Command_Clear_Project_Search =>
            Cmd.Kind := Clear_Project_Search;
         when Command_Open_Selected_Project_Search_Result =>
            Cmd.Kind := Open_Selected_Project_Search_Result;
         when Command_Move_Project_Search_Selection_Up =>
            Cmd.Kind := Move_Project_Search_Selection_Up;
         when Command_Move_Project_Search_Selection_Down =>
            Cmd.Kind := Move_Project_Search_Selection_Down;
         when Command_Next_Project_Search_Result =>
            Cmd.Kind := Next_Project_Search_Result;
         when Command_Previous_Project_Search_Result =>
            Cmd.Kind := Previous_Project_Search_Result;
         when Command_First_Project_Search_Result =>
            Cmd.Kind := First_Project_Search_Result;
         when Command_Last_Project_Search_Result =>
            Cmd.Kind := Last_Project_Search_Result;
         when Command_Reveal_Active_Project_Search_Result =>
            Cmd.Kind := Reveal_Active_Project_Search_Result;
         when Command_Project_Search_Scope_Selected_Directory =>
            Cmd.Kind := Project_Search_Scope_Selected_Directory;
         when Command_Project_Search_Kind_Next =>
            Cmd.Kind := Project_Search_Kind_Next;
         when Command_Project_Search_Kind_Previous =>
            Cmd.Kind := Project_Search_Kind_Previous;
         when Command_Project_Search_Kind_Clear =>
            Cmd.Kind := Project_Search_Kind_Clear;
         when Command_Project_Search_Scope_Set =>
            Cmd.Kind := Project_Search_Scope_Set;
         when Command_Project_Search_Scope_Clear =>
            Cmd.Kind := Project_Search_Scope_Clear;
         when Command_Project_Search_Case_Toggle =>
            Cmd.Kind := Project_Search_Case_Toggle;
         when Command_Project_Search_Case_Clear =>
            Cmd.Kind := Project_Search_Case_Clear;
         when Command_Project_Search_Whole_Word_Toggle =>
            Cmd.Kind := Project_Search_Whole_Word_Toggle;
         when Command_Project_Search_Whole_Word_Clear =>
            Cmd.Kind := Project_Search_Whole_Word_Clear;
         when Command_Project_Search_Regex_Toggle =>
            Cmd.Kind := Project_Search_Regex_Toggle;
         when Command_Project_Search_Regex_Clear =>
            Cmd.Kind := Project_Search_Regex_Clear;
         when Command_Project_Search_Include_Filter_Set =>
            Cmd.Kind := Project_Search_Include_Filter_Set;
         when Command_Project_Search_Exclude_Filter_Set =>
            Cmd.Kind := Project_Search_Exclude_Filter_Set;
         when Command_Project_Search_Include_Filter_Clear =>
            Cmd.Kind := Project_Search_Include_Filter_Clear;
         when Command_Project_Search_Exclude_Filter_Clear =>
            Cmd.Kind := Project_Search_Exclude_Filter_Clear;
         when Command_Project_Search_Replace_Preview =>
            Cmd.Kind := Project_Search_Replace_Preview;
         when Command_Project_Search_Replace_Toggle_Selected =>
            Cmd.Kind := Project_Search_Replace_Toggle_Selected;
         when Command_Project_Search_Replace_Include_Selected =>
            Cmd.Kind := Project_Search_Replace_Include_Selected;
         when Command_Project_Search_Replace_Exclude_Selected =>
            Cmd.Kind := Project_Search_Replace_Exclude_Selected;
         when Command_Project_Search_Replace_Include_File =>
            Cmd.Kind := Project_Search_Replace_Include_File;
         when Command_Project_Search_Replace_Exclude_File =>
            Cmd.Kind := Project_Search_Replace_Exclude_File;
         when Command_Project_Search_Replace_Include_All =>
            Cmd.Kind := Project_Search_Replace_Include_All;
         when Command_Project_Search_Replace_Exclude_All =>
            Cmd.Kind := Project_Search_Replace_Exclude_All;
         when Command_Project_Search_Replace_Selected =>
            Cmd.Kind := Project_Search_Replace_Selected;
         when Command_Project_Search_Replace_All_Included =>
            Cmd.Kind := Project_Search_Replace_All_Included;
         when Command_Project_Search_Replace_Clear_Preview =>
            Cmd.Kind := Project_Search_Replace_Clear_Preview;
         when Command_Show_Search_Results_Panel =>
            Cmd.Kind := Show_Search_Results_Panel;
         when Command_Focus_Editor_Text =>
            Cmd.Kind := Focus_Editor_Text;
         when Command_Focus_Search_Results =>
            Cmd.Kind := Focus_Search_Results;
         when Command_Focus_Problems =>
            Cmd.Kind := Focus_Problems;
         when Command_Toggle_Bottom_Panel_Focus =>
            Cmd.Kind := Toggle_Bottom_Panel_Focus;
         when Command_Search_Results_Move_Up =>
            Cmd.Kind := Search_Results_Move_Up;
         when Command_Search_Results_Move_Down =>
            Cmd.Kind := Search_Results_Move_Down;
         when Command_Search_Results_Page_Up =>
            Cmd.Kind := Search_Results_Page_Up;
         when Command_Search_Results_Page_Down =>
            Cmd.Kind := Search_Results_Page_Down;
         when Command_Search_Results_Open_Selected =>
            Cmd.Kind := Search_Results_Open_Selected;
         when Command_Problems_Move_Up =>
            Cmd.Kind := Problems_Move_Up;
         when Command_Problems_Move_Down =>
            Cmd.Kind := Problems_Move_Down;
         when Command_Problems_Page_Up =>
            Cmd.Kind := Problems_Page_Up;
         when Command_Problems_Page_Down =>
            Cmd.Kind := Problems_Page_Down;
         when Command_Problems_Open_Selected =>
            Cmd.Kind := Problems_Open_Selected;
         when Command_Problems_Focus_Editor =>
            Cmd.Kind := Problems_Focus_Editor;
         when Command_Focus_File_Tree =>
            Cmd.Kind := Focus_File_Tree;
         when Command_File_Tree_Move_Up =>
            Cmd.Kind := File_Tree_Move_Up;
         when Command_File_Tree_Move_Down =>
            Cmd.Kind := File_Tree_Move_Down;
         when Command_File_Tree_Page_Up =>
            Cmd.Kind := File_Tree_Page_Up;
         when Command_File_Tree_Page_Down =>
            Cmd.Kind := File_Tree_Page_Down;
         when Command_File_Tree_Open_Selected =>
            Cmd.Kind := File_Tree_Open_Selected;
         when Command_File_Tree_Create_File =>
            Cmd.Kind := File_Tree_Create_File;
         when Command_File_Tree_Create_Directory =>
            Cmd.Kind := File_Tree_Create_Directory;
         when Command_File_Tree_Rename_Selected =>
            Cmd.Kind := File_Tree_Rename_Selected;
         when Command_File_Tree_Delete_Selected =>
            Cmd.Kind := File_Tree_Delete_Selected;
         when Command_File_Tree_Expand_Selected =>
            Cmd.Kind := File_Tree_Expand_Selected;
         when Command_File_Tree_Collapse_Selected =>
            Cmd.Kind := File_Tree_Collapse_Selected;
         when Command_File_Tree_Toggle_Selected =>
            Cmd.Kind := File_Tree_Toggle_Selected;
         when Command_File_Tree_Collapse_All =>
            Cmd.Kind := File_Tree_Collapse_All;
         when Command_File_Tree_Expand_To_Active_File =>
            Cmd.Kind := File_Tree_Expand_To_Active_File;
         when Command_Toggle_Theme =>
            Cmd.Kind := Toggle_Theme;
         when Command_Set_Theme_Light =>
            Cmd.Kind := Set_Theme_Light;
         when Command_Set_Theme_Dark =>
            Cmd.Kind := Set_Theme_Dark;
         when Command_Toggle_Minimap =>
            Cmd.Kind := Toggle_Minimap;
         when Command_Toggle_Scrollbars =>
            Cmd.Kind := Toggle_Scrollbars;
         when Command_Toggle_Line_Number_Mode =>
            Cmd.Kind := Toggle_Line_Number_Mode;
         when Command_Toggle_Cursor_Blink =>
            Cmd.Kind := Toggle_Cursor_Blink;
         when Command_Save_Settings =>
            Cmd.Kind := Save_Settings;
         when Command_Reload_Settings =>
            Cmd.Kind := Reload_Settings;
         when Command_Reset_Settings_To_Defaults =>
            Cmd.Kind := Reset_Settings_To_Defaults;
         when Command_Save_Keybindings =>
            Cmd.Kind := Save_Keybindings;
         when Command_Reload_Keybindings =>
            Cmd.Kind := Reload_Keybindings;
         when Command_Validate_Keybindings =>
            Cmd.Kind := Validate_Keybindings;
         when Command_Keybindings_Show =>
            Cmd.Kind := Keybindings_Show;
         when Command_Keybindings_Focus =>
            Cmd.Kind := Keybindings_Focus;
         when Command_Keybindings_Assign_Selected =>
            Cmd.Kind := Keybindings_Assign_Selected;
         when Command_Keybindings_Remove_Selected =>
            Cmd.Kind := Keybindings_Remove_Selected;
         when Command_Keybindings_Reset_To_Defaults =>
            Cmd.Kind := Keybindings_Reset_To_Defaults;
         when Command_Keybindings_Filter_Conflicts =>
            Cmd.Kind := Keybindings_Filter_Conflicts;
         when Command_Keybindings_Filter_Unbound =>
            Cmd.Kind := Keybindings_Filter_Unbound;
         when Command_Keybindings_Clear_Filter =>
            Cmd.Kind := Keybindings_Clear_Filter;
         when Command_Keybindings_Cancel_Capture =>
            Cmd.Kind := Keybindings_Cancel_Capture;
         when Command_Startup_Show_Summary =>
            Cmd.Kind := Startup_Show_Summary;
         when Command_Configuration_Recover_Show =>
            Cmd.Kind := Configuration_Recover_Show;
         when Command_Configuration_Audit =>
            Cmd.Kind := Configuration_Audit;
         when Command_Configuration_Reset_Settings =>
            Cmd.Kind := Configuration_Reset_Settings;
         when Command_Configuration_Reset_Keybindings =>
            Cmd.Kind := Configuration_Reset_Keybindings;
         when Command_Configuration_Reset_Workspace =>
            Cmd.Kind := Configuration_Reset_Workspace;
         when Command_Configuration_Reset_Recent_Projects =>
            Cmd.Kind := Configuration_Reset_Recent_Projects;
         when Command_Configuration_Reset_All =>
            Cmd.Kind := Configuration_Reset_All;
         when Command_Configuration_Reset_All_Confirm =>
            Cmd.Kind := Configuration_Reset_All_Confirm;
         when Command_Configuration_Reset_All_Cancel =>
            Cmd.Kind := Configuration_Reset_All_Cancel;
         when Command_Configuration_Save_Clean_Settings =>
            Cmd.Kind := Configuration_Save_Clean_Settings;
         when Command_Configuration_Save_Clean_Keybindings =>
            Cmd.Kind := Configuration_Save_Clean_Keybindings;
         when Command_Configuration_Save_Clean_Workspace =>
            Cmd.Kind := Configuration_Save_Clean_Workspace;
         when Command_Configuration_Save_Clean_Recent_Projects =>
            Cmd.Kind := Configuration_Save_Clean_Recent_Projects;
         when Command_Save_Workspace_State =>
            Cmd.Kind := Save_Workspace_State;
         when Command_Restore_Workspace_State =>
            Cmd.Kind := Restore_Workspace_State;
         when Command_Clear_Workspace_State =>
            Cmd.Kind := Clear_Workspace_State;
         when Command_Toggle_Feature_Panel =>
            Cmd.Kind := Toggle_Feature_Panel;
         when Command_Show_Feature_Panel =>
            Cmd.Kind := Show_Feature_Panel;
         when Command_Hide_Feature_Panel =>
            Cmd.Kind := Hide_Feature_Panel;
         when Command_Focus_Feature_Panel =>
            Cmd.Kind := Focus_Feature_Panel;
         when Command_Clear_Feature_Panel =>
            Cmd.Kind := Clear_Feature_Panel;
         when Command_Feature_Panel_Select_Next =>
            Cmd.Kind := Feature_Panel_Select_Next;
         when Command_Feature_Panel_Select_Previous =>
            Cmd.Kind := Feature_Panel_Select_Previous;
         when Command_Feature_Panel_Open_Selected =>
            Cmd.Kind := Feature_Panel_Open_Selected;
         when Command_Build_UI_Toggle =>
            Cmd.Kind := Build_UI_Toggle;
         when Command_Build_UI_Show =>
            Cmd.Kind := Build_UI_Show;
         when Command_Build_UI_Hide =>
            Cmd.Kind := Build_UI_Hide;
         when Command_Build_UI_Focus =>
            Cmd.Kind := Build_UI_Focus;
         when Command_Build_Select_Next_Candidate =>
            Cmd.Kind := Build_Select_Next_Candidate;
         when Command_Build_Select_Previous_Candidate =>
            Cmd.Kind := Build_Select_Previous_Candidate;
         when Command_Build_Clear_Selected_Candidate =>
            Cmd.Kind := Build_Clear_Selected_Candidate;
         when Command_Build_Set_Mode_Default =>
            Cmd.Kind := Build_Set_Mode_Default;
         when Command_Build_Set_Mode_Debug =>
            Cmd.Kind := Build_Set_Mode_Debug;
         when Command_Build_Set_Mode_Release =>
            Cmd.Kind := Build_Set_Mode_Release;
         when Command_Build_Set_Mode_Validation =>
            Cmd.Kind := Build_Set_Mode_Validation;
         when Command_Build_Toggle_Diagnostics_Ingestion =>
            Cmd.Kind := Build_Toggle_Diagnostics_Ingestion;
         when Command_Build_Cycle_Output_Limit =>
            Cmd.Kind := Build_Cycle_Output_Limit;
         when Command_Build_Toggle_Option_Verbose =>
            Cmd.Kind := Build_Toggle_Option_Verbose;
         when Command_Build_Toggle_Option_Keep_Going =>
            Cmd.Kind := Build_Toggle_Option_Keep_Going;
         when Command_Build_Acknowledge_Consent =>
            Cmd.Kind := Build_Acknowledge_Consent;
         when Command_Build_Clear_Consent =>
            Cmd.Kind := Build_Clear_Consent;
         when Command_Build_Cancel =>
            Cmd.Kind := Build_Cancel;
         when Command_Refresh_Outline =>
            Cmd.Kind := Refresh_Outline;
         when Command_Refresh_Outline_Project_Index =>
            Cmd.Kind := Refresh_Outline_Project_Index;
         when Command_Goto_Declaration =>
            Cmd.Kind := Goto_Declaration;
         when Command_Goto_Body =>
            Cmd.Kind := Goto_Body;
         when Command_Goto_Spec =>
            Cmd.Kind := Goto_Spec;
         when Command_Semantic_Refresh_Buffer =>
            Cmd.Kind := Semantic_Refresh_Buffer;
         when Command_Semantic_Refresh_Project_Index =>
            Cmd.Kind := Semantic_Refresh_Project_Index;
         when Command_Language_Index_Clear =>
            Cmd.Kind := Language_Index_Clear;
         when Command_Language_Index_Status =>
            Cmd.Kind := Language_Index_Status;
         when Command_Clear_Outline =>
            Cmd.Kind := Clear_Outline;
         when Command_Show_Outline =>
            Cmd.Kind := Show_Outline;
         when Command_Focus_Outline =>
            Cmd.Kind := Focus_Outline;
         when Command_Open_Selected_Outline_Item =>
            Cmd.Kind := Open_Selected_Outline_Item;
         when Command_Select_Current_Outline_Symbol =>
            Cmd.Kind := Select_Current_Outline_Symbol;
         when Command_Reveal_Current_Outline_Symbol =>
            Cmd.Kind := Reveal_Current_Outline_Symbol;
         when Command_Next_Outline_Symbol =>
            Cmd.Kind := Next_Outline_Symbol;
         when Command_Previous_Outline_Symbol =>
            Cmd.Kind := Previous_Outline_Symbol;
         when Command_Select_Next_Outline_Item =>
            Cmd.Kind := Select_Next_Outline_Item;
         when Command_Select_Previous_Outline_Item =>
            Cmd.Kind := Select_Previous_Outline_Item;
         when Command_Focus_Outline_Filter =>
            Cmd.Kind := Focus_Outline_Filter;
         when Command_Filter_Outline =>
            Cmd.Kind := Filter_Outline;
         when Command_Clear_Outline_Filter =>
            Cmd.Kind := Clear_Outline_Filter;
         when Command_Toggle_Outline_Filter =>
            Cmd.Kind := Toggle_Outline_Filter;
         when Command_Outline_Filter_History_Previous =>
            Cmd.Kind := Outline_Filter_History_Previous;
         when Command_Outline_Filter_History_Next =>
            Cmd.Kind := Outline_Filter_History_Next;
         when Command_Clear_Outline_Filter_History =>
            Cmd.Kind := Clear_Outline_Filter_History;
         when Command_Show_Messages =>
            Cmd.Kind := Show_Messages;
         when Command_Clear_Messages =>
            Cmd.Kind := Clear_Messages;
         when Command_Search_Results_Search_Active_Buffer =>
            Cmd.Kind := Search_Results_Search_Active_Buffer;
         when Command_Search_Results_Focus_Query =>
            Cmd.Kind := Search_Results_Focus_Query;
         when Command_Search_Results_Repeat_Active_Buffer =>
            Cmd.Kind := Search_Results_Repeat_Active_Buffer;
         when Command_Search_Results_Query_History_Previous =>
            Cmd.Kind := Search_Results_Query_History_Previous;
         when Command_Search_Results_Query_History_Next =>
            Cmd.Kind := Search_Results_Query_History_Next;
         when Command_Search_Results_Toggle_Case_Sensitive =>
            Cmd.Kind := Search_Results_Toggle_Case_Sensitive;
         when Command_Show_Search_Results_Feature =>
            Cmd.Kind := Show_Search_Results_Feature;
         when Command_Clear_Search_Results_Feature =>
            Cmd.Kind := Clear_Search_Results_Feature;
         when Command_Diagnostics_Show =>
            Cmd.Kind := Diagnostics_Show;
         when Command_Diagnostics_Clear =>
            Cmd.Kind := Diagnostics_Clear;
         when Command_Diagnostics_Toggle_Info =>
            Cmd.Kind := Diagnostics_Toggle_Info;
         when Command_Diagnostics_Toggle_Warnings =>
            Cmd.Kind := Diagnostics_Toggle_Warnings;
         when Command_Diagnostics_Toggle_Errors =>
            Cmd.Kind := Diagnostics_Toggle_Errors;
         when Command_Diagnostics_Show_All =>
            Cmd.Kind := Diagnostics_Show_All;
         when Command_Diagnostics_Clear_Filter =>
            Cmd.Kind := Diagnostics_Clear_Filter;
         when Command_Diagnostics_Filter_Errors =>
            Cmd.Kind := Diagnostics_Filter_Errors;
         when Command_Diagnostics_Filter_Warnings =>
            Cmd.Kind := Diagnostics_Filter_Warnings;
         when Command_Diagnostics_Filter_Info_Notes =>
            Cmd.Kind := Diagnostics_Filter_Info_Notes;
         when Command_Diagnostics_Filter_Source =>
            Cmd.Kind := Diagnostics_Filter_Source;
         when Command_Diagnostics_Filter_Build =>
            Cmd.Kind := Diagnostics_Filter_Build;
         when Command_Diagnostics_Clear_Build =>
            Cmd.Kind := Diagnostics_Clear_Build;
         when Command_Diagnostics_Open_Selected =>
            Cmd.Kind := Diagnostics_Open_Selected;
         when Command_Diagnostics_Select_Next =>
            Cmd.Kind := Diagnostics_Select_Next;
         when Command_Diagnostics_Select_Previous =>
            Cmd.Kind := Diagnostics_Select_Previous;
         when Command_Diagnostics_Clear_Selected =>
            Cmd.Kind := Diagnostics_Clear_Selected;
         when Command_Diagnostics_Copy_Selected_Text =>
            Cmd.Kind := Diagnostics_Copy_Selected_Text;
         when Command_Diagnostics_Clear_Info =>
            Cmd.Kind := Diagnostics_Clear_Info;
         when Command_Diagnostics_Clear_Warnings =>
            Cmd.Kind := Diagnostics_Clear_Warnings;
         when Command_Diagnostics_Clear_Errors =>
            Cmd.Kind := Diagnostics_Clear_Errors;
         when Command_Diagnostics_Toggle_Editor_Source =>
            Cmd.Kind := Diagnostics_Toggle_Editor_Source;
         when Command_Diagnostics_Toggle_File_Source =>
            Cmd.Kind := Diagnostics_Toggle_File_Source;
         when Command_Diagnostics_Toggle_Project_Source =>
            Cmd.Kind := Diagnostics_Toggle_Project_Source;
         when Command_Diagnostics_Toggle_External_Source =>
            Cmd.Kind := Diagnostics_Toggle_External_Source;
         when Command_Diagnostics_Toggle_Unknown_Source =>
            Cmd.Kind := Diagnostics_Toggle_Unknown_Source;
         when Command_Clear_Selected_Message =>
            Cmd.Kind := Clear_Selected_Message;
         when Command_Copy_Selected_Message_Text =>
            Cmd.Kind := Copy_Selected_Message_Text;
         when Command_Clear_Info_Messages =>
            Cmd.Kind := Clear_Info_Messages;
         when Command_Clear_Warning_Messages =>
            Cmd.Kind := Clear_Warning_Messages;
         when Command_Clear_Error_Messages =>
            Cmd.Kind := Clear_Error_Messages;
         when Command_Toggle_Message_Info =>
            Cmd.Kind := Toggle_Message_Info;
         when Command_Toggle_Message_Warnings =>
            Cmd.Kind := Toggle_Message_Warnings;
         when Command_Toggle_Message_Errors =>
            Cmd.Kind := Toggle_Message_Errors;
         when Command_Show_All_Messages =>
            Cmd.Kind := Show_All_Messages;
         when Command_Clear_Message_Filter =>
            Cmd.Kind := Clear_Message_Filter;
         when others =>
            Cmd.Kind := Break_Group;
      end case;

      return Cmd;
   end Command_For_Id;


   function Is_File_Lifecycle_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Save_File
            | Command_Save_File_As
            | Command_Close_Active_Buffer
            | Command_Confirm_Close_Save
            | Command_Confirm_Close_Discard
            | Command_Cancel_Close
            | Command_Reopen_Closed_Buffer
            | Command_Reload_Active_Buffer
            | Command_Revert_Active_Buffer
            | Command_File_Conflict_Keep_Buffer
            | Command_File_Conflict_Reload_From_Disk
            | Command_File_Conflict_Overwrite_Disk
            | Command_File_Conflict_Cancel
            | Command_Rename_Buffer_File
            | Command_Delete_Buffer_File
            | Command_Copy_Buffer_File
            | Command_Move_Buffer_File =>
            return True;
         when others =>
            return False;
      end case;
   end Is_File_Lifecycle_Command;

   type Command_Reference_Metadata is record
      Summary : Unbounded_String;
      Availability_Summary : Unbounded_String;
      Mutation_Summary : Unbounded_String;
      Filesystem_Effect_Summary : Unbounded_String;
      State_Preservation_Summary : Unbounded_String;
      Non_Goal_Summary : Unbounded_String;
      Family : Command_Family_Id;
      Effect_Classification : Command_Effect_Classification_Id;
   end record;

   Empty_Command_Reference_Metadata : constant Command_Reference_Metadata :=
     (Summary => To_Unbounded_String (""),
      Availability_Summary => To_Unbounded_String (""),
      Mutation_Summary => To_Unbounded_String (""),
      Filesystem_Effect_Summary => To_Unbounded_String (""),
      State_Preservation_Summary => To_Unbounded_String (""),
      Non_Goal_Summary => To_Unbounded_String (""),
      Family => No_Command_Family,
      Effect_Classification => No_Command_Effect);

   function Canonical_Command_Reference_Metadata
     (Id : Command_Id) return Command_Reference_Metadata
   is
   begin
      case Id is
         when Command_Save_File =>
            return
              (Summary => To_Unbounded_String ("Saves the active buffer to its current associated file path."),
               Availability_Summary => To_Unbounded_String ("Requires an active associated buffer that can be saved."),
               Mutation_Summary => To_Unbounded_String ("Updates the active buffer save baseline and dirty state only after a successful write."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Writes active buffer text to the current associated file path."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves open-buffer identity, text content, selection, clipboard, find state, and visible feature panels."),
               Non_Goal_Summary => To_Unbounded_String ("Does not choose a new target path or save every buffer."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Writes_Buffer_Text_To_Associated_File);
         when Command_Save_File_As =>
            return
              (Summary => To_Unbounded_String ("Saves the active buffer to an explicit target path and associates the buffer with that path after success."),
               Availability_Summary => To_Unbounded_String ("Requires an active buffer and an explicit non-empty target path."),
               Mutation_Summary => To_Unbounded_String ("Updates the active buffer association, save baseline, and dirty state only after a successful explicit-target write."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Writes active buffer text to an explicit target path."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves text and current editor UI state while changing association after successful write."),
               Non_Goal_Summary => To_Unbounded_String ("Does not rename or move the existing backing file, infer a target path, or prompt from hidden details."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Writes_Buffer_Text_To_Explicit_Target_And_Associates);
         when Command_Close_Active_Buffer =>
            return
              (Summary => To_Unbounded_String ("Closes the active buffer only when it is safe under the retained dirty-buffer policy."),
               Availability_Summary => To_Unbounded_String ("Requires an active buffer that may be closed under the dirty-buffer review policy."),
               Mutation_Summary => To_Unbounded_String ("Removes the active buffer from the open-buffer set and may create a safe reopen candidate."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Performs no filesystem operation."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves unrelated buffers and project/configuration domains; closes only the selected safe buffer."),
               Non_Goal_Summary => To_Unbounded_String ("Does not delete the associated file, force-close dirty buffers, or persist closed-buffer history."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Closes_Active_Buffer);
         when Command_Confirm_Close_Save
            | Command_Confirm_Close_Discard
            | Command_Cancel_Close =>
            return
              (Summary => To_Unbounded_String ("Resolves the dirty-buffer close review through an explicit user action."),
               Availability_Summary => To_Unbounded_String ("Requires an active dirty close prompt."),
               Mutation_Summary => To_Unbounded_String ("Save and discard confirmations recheck the selected buffer before closing; cancel clears only the prompt."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Save confirmation may write dirty file-backed buffers; discard and cancel write nothing."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves dirty text on cancel, stale targets, conflicts, and save failures."),
               Non_Goal_Summary => To_Unbounded_String ("Does not remember close requests, store dirty text, delete files, or show generated buffer names in commands or keybindings."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Closes_Active_Buffer);
         when Command_Reopen_Closed_Buffer =>
            return
              (Summary => To_Unbounded_String ("Reopens the latest safe closed-buffer file reference through canonical file-open behavior."),
               Availability_Summary => To_Unbounded_String ("Requires a safe transient reopen candidate for a recently closed file."),
               Mutation_Summary => To_Unbounded_String ("Uses the safe reopen candidate through normal open behavior and creates or activates the reopened buffer."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Reads the reopen candidate through canonical file-open behavior."),
               State_Preservation_Summary => To_Unbounded_String ("Uses normal open behavior and does not restore command-reference or operation-history state."),
               Non_Goal_Summary => To_Unbounded_String ("Does not restore unsaved closed-buffer memory, watch files, repair missing files, or remember reopen history."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Reopens_Safe_File_Reference);
         when Command_Reload_Active_Buffer =>
            return
              (Summary => To_Unbounded_String ("Reloads the active clean associated buffer from disk without discarding dirty text."),
               Availability_Summary => To_Unbounded_String ("Requires an active clean associated buffer; dirty buffers are blocked before disk reread."),
               Mutation_Summary => To_Unbounded_String ("Replaces active clean buffer text and saved baseline from the associated file after a successful read."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Reads the current associated file path."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves unrelated buffers and current UI state; blocked dirty reload preserves dirty text."),
               Non_Goal_Summary => To_Unbounded_String ("Does not discard dirty text; use revert for explicit discard."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Rereads_Associated_File);
         when Command_Revert_Active_Buffer =>
            return
              (Summary => To_Unbounded_String ("Explicitly discards unsaved changes in the active dirty associated buffer and rereads from disk."),
               Availability_Summary => To_Unbounded_String ("Requires an active dirty associated buffer and an explicit revert command invocation."),
               Mutation_Summary => To_Unbounded_String ("Replaces dirty active buffer text with disk contents and clears dirty state after a successful read."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Reads the current associated file path after explicit discard intent."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves unrelated buffers and current UI state while intentionally replacing dirty active text."),
               Non_Goal_Summary => To_Unbounded_String ("Does not autosave, create recovery snapshots, or affect unrelated buffers."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Discards_Unsaved_Changes_And_Rereads);
         when Command_File_Conflict_Keep_Buffer
            | Command_File_Conflict_Reload_From_Disk
            | Command_File_Conflict_Overwrite_Disk
            | Command_File_Conflict_Cancel =>
            return
              (Summary => To_Unbounded_String ("Resolves the active file-conflict prompt through an explicit user action."),
               Availability_Summary => To_Unbounded_String ("Requires an active file conflict prompt."),
               Mutation_Summary => To_Unbounded_String ("Changes files only after the current prompt is confirmed; cancel and keep write nothing."),
               Filesystem_Effect_Summary => To_Unbounded_String ("May read or write only for explicit reload/overwrite conflict actions."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves dirty buffer text on cancel, keep, stale prompt, and filesystem failure."),
               Non_Goal_Summary => To_Unbounded_String ("Does not store paths, generated buffer names, conflict details, or text in keybindings or Command Palette."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Rereads_Associated_File);
         when Command_Rename_Buffer_File =>
            return
              (Summary => To_Unbounded_String ("Renames the active clean associated backing file to an explicit target path and updates association after filesystem success."),
               Availability_Summary => To_Unbounded_String ("Requires an active clean associated buffer and a valid explicit target path that does not already exist."),
               Mutation_Summary => To_Unbounded_String ("Updates active buffer association only after filesystem rename success; preserves text, saved baseline, and dirty state."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Renames the current associated backing file to the explicit target path."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves active text, saved baseline, dirty state, open-buffer identity, and unrelated buffers."),
               Non_Goal_Summary => To_Unbounded_String ("Does not write buffer text, overwrite targets, rename dirty buffers, open the target separately, or rename project files."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Renames_Associated_File);
         when Command_Delete_Buffer_File =>
            return
              (Summary => To_Unbounded_String ("Deletes the active clean associated backing file, preserves text in memory, and clears association after filesystem success."),
               Availability_Summary => To_Unbounded_String ("Requires an active clean associated buffer; dirty associated files cannot be deleted by this command."),
               Mutation_Summary => To_Unbounded_String ("Clears active buffer association only after filesystem delete success; preserves text and leaves the buffer open under the no-associated-file policy."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Deletes the current associated backing file."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves active text and open-buffer identity; the no-associated-file policy marks retained text dirty."),
               Non_Goal_Summary => To_Unbounded_String ("Does not delete dirty buffers, close the buffer, move files to trash, or create recovery records."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Deletes_Associated_File);
         when Command_Copy_Buffer_File =>
            return
              (Summary => To_Unbounded_String ("Copies the active clean associated backing file to an explicit target path without changing association."),
               Availability_Summary => To_Unbounded_String ("Requires an active clean associated buffer and a valid explicit target path that does not already exist."),
               Mutation_Summary => To_Unbounded_String ("Does not mutate association; Preserves active buffer association, text, saved baseline, dirty state, and open-buffer collection on success."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Copies the current associated backing file to the explicit target path."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves active association, text, saved baseline, dirty state, open-buffer identity, and unrelated buffers."),
               Non_Goal_Summary => To_Unbounded_String ("Does not overwrite targets, copy dirty buffers, adopt the target, or open the copied file."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Copies_Associated_File);
         when Command_Move_Buffer_File =>
            return
              (Summary => To_Unbounded_String ("Moves the active clean associated backing file to an explicit target path and updates association after filesystem success."),
               Availability_Summary => To_Unbounded_String ("Requires an active clean associated buffer and a valid explicit target path that does not already exist."),
               Mutation_Summary => To_Unbounded_String ("Updates active buffer association only after filesystem move success; preserves text, saved baseline, and dirty state."),
               Filesystem_Effect_Summary => To_Unbounded_String ("Moves the current associated backing file to the explicit target path."),
               State_Preservation_Summary => To_Unbounded_String ("Preserves active text, saved baseline, dirty state, open-buffer identity, and unrelated buffers."),
               Non_Goal_Summary => To_Unbounded_String ("Does not write buffer text, overwrite targets, move dirty buffers, open the moved file separately, or copy-then-delete as a public command."),
               Family => File_Lifecycle_Family,
               Effect_Classification => Moves_Associated_File);
         when others =>
            return Empty_Command_Reference_Metadata;
      end case;
   end Canonical_Command_Reference_Metadata;

   function Reference_Summary
     (Id : Command_Id) return String
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return To_String (M.Summary);
   end Reference_Summary;

   function Reference_Availability_Summary
     (Id : Command_Id) return String
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return To_String (M.Availability_Summary);
   end Reference_Availability_Summary;

   function Reference_Mutation_Summary
     (Id : Command_Id) return String
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return To_String (M.Mutation_Summary);
   end Reference_Mutation_Summary;

   function Reference_Filesystem_Effect_Summary
     (Id : Command_Id) return String
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return To_String (M.Filesystem_Effect_Summary);
   end Reference_Filesystem_Effect_Summary;

   function Reference_State_Preservation_Summary
     (Id : Command_Id) return String
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return To_String (M.State_Preservation_Summary);
   end Reference_State_Preservation_Summary;

   function Reference_Non_Goal_Summary
     (Id : Command_Id) return String
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return To_String (M.Non_Goal_Summary);
   end Reference_Non_Goal_Summary;

   function Reference_Command_Family
     (Id : Command_Id) return Command_Family_Id
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return M.Family;
   end Reference_Command_Family;

   function Reference_Effect_Classification
     (Id : Command_Id) return Command_Effect_Classification_Id
   is
      M : constant Command_Reference_Metadata := Canonical_Command_Reference_Metadata (Id);
   begin
      return M.Effect_Classification;
   end Reference_Effect_Classification;


   type Minimal_Target_Prompt_Metadata is record
      Requires_Explicit_Target : Boolean := False;
      Target_Prompt_Capable    : Boolean := False;
      Target_Prompt_Label      : Unbounded_String := Null_Unbounded_String;
   end record;

   Empty_Target_Prompt_Metadata : constant Minimal_Target_Prompt_Metadata :=
     (Requires_Explicit_Target => False,
      Target_Prompt_Capable    => False,
      Target_Prompt_Label      => Null_Unbounded_String);

   --  Single static source for the retained Phase 473 minimal prompt metadata.
   --  Descriptors and public accessors both project this source; no product
   --  consumer owns a second prompted-command list or prompt-label table.
   function Canonical_Target_Prompt_Metadata
     (Id : Command_Id) return Minimal_Target_Prompt_Metadata
   is
      function Metadata (Label : String) return Minimal_Target_Prompt_Metadata is
      begin
         return
           (Requires_Explicit_Target => True,
            Target_Prompt_Capable    => True,
            Target_Prompt_Label      => To_Unbounded_String (Label));
      end Metadata;
   begin
      case Id is
         when Command_Save_File_As =>
            return Metadata ("Save As target");
         when Command_Rename_Buffer_File =>
            return Metadata ("Rename target");
         when Command_Copy_Buffer_File =>
            return Metadata ("Copy target");
         when Command_Move_Buffer_File =>
            return Metadata ("Move target");
         when others =>
            return Empty_Target_Prompt_Metadata;
      end case;
   end Canonical_Target_Prompt_Metadata;

   function Command_Requires_Explicit_Target
     (Id : Command_Id) return Boolean
   is
   begin
      return Canonical_Target_Prompt_Metadata (Id).Requires_Explicit_Target;
   end Command_Requires_Explicit_Target;

   function Command_Is_Target_Prompt_Capable
     (Id : Command_Id) return Boolean
   is
   begin
      return Canonical_Target_Prompt_Metadata (Id).Target_Prompt_Capable;
   end Command_Is_Target_Prompt_Capable;

   function Command_Target_Prompt_Label
     (Id : Command_Id) return String
   is
   begin
      return To_String (Canonical_Target_Prompt_Metadata (Id).Target_Prompt_Label);
   end Command_Target_Prompt_Label;

   function Command_Summary
     (Id : Command_Id) return String is (Reference_Summary (Id));

   function Command_Availability_Summary
     (Id : Command_Id) return String is (Reference_Availability_Summary (Id));

   function Command_Mutation_Summary
     (Id : Command_Id) return String is (Reference_Mutation_Summary (Id));

   function Command_Filesystem_Effect_Summary
     (Id : Command_Id) return String is (Reference_Filesystem_Effect_Summary (Id));

   function Command_State_Preservation_Summary
     (Id : Command_Id) return String is (Reference_State_Preservation_Summary (Id));

   function Command_Non_Goal_Summary
     (Id : Command_Id) return String is (Reference_Non_Goal_Summary (Id));

   function Command_Family
     (Id : Command_Id) return Command_Family_Id is (Reference_Command_Family (Id));

   function Command_Effect_Classification
     (Id : Command_Id) return Command_Effect_Classification_Id is
       (Reference_Effect_Classification (Id));

   function Command_Family_Label
     (Family : Command_Family_Id) return String
   is
   begin
      case Family is
         when File_Lifecycle_Family =>
            return "File Operations";
         when No_Command_Family =>
            return "";
      end case;
   end Command_Family_Label;

   function Command_Effect_Classification_Label
     (Effect : Command_Effect_Classification_Id) return String
   is
   begin
      case Effect is
         when Writes_Buffer_Text_To_Associated_File =>
            return "writes-buffer-text-to-associated-file";
         when Writes_Buffer_Text_To_Explicit_Target_And_Associates =>
            return "writes-buffer-text-to-explicit-target-and-associates";
         when Closes_Active_Buffer =>
            return "closes-active-buffer";
         when Reopens_Safe_File_Reference =>
            return "reopens-safe-file-reference";
         when Rereads_Associated_File =>
            return "rereads-associated-file";
         when Discards_Unsaved_Changes_And_Rereads =>
            return "discards-unsaved-changes-and-rereads";
         when Renames_Associated_File =>
            return "renames-associated-file";
         when Deletes_Associated_File =>
            return "deletes-associated-file";
         when Copies_Associated_File =>
            return "copies-associated-file";
         when Moves_Associated_File =>
            return "moves-associated-file";
         when No_Command_Effect =>
            return "";
      end case;
   end Command_Effect_Classification_Label;

   function Has_Command_Reference
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Save_File
            | Command_Save_File_As
            | Command_Close_Active_Buffer
            | Command_Reopen_Closed_Buffer
            | Command_Reload_Active_Buffer
            | Command_Revert_Active_Buffer
            | Command_Rename_Buffer_File
            | Command_Delete_Buffer_File
            | Command_Copy_Buffer_File
            | Command_Move_Buffer_File =>
            null;
         when others =>
            return False;
      end case;

      return Is_File_Lifecycle_Command (Id)
        and then Command_Family (Id) = File_Lifecycle_Family
        and then Command_Effect_Classification (Id) /= No_Command_Effect
        and then Command_Summary (Id)'Length > 0
        and then Command_Availability_Summary (Id)'Length > 0
        and then Command_Mutation_Summary (Id)'Length > 0
        and then Command_Filesystem_Effect_Summary (Id)'Length > 0
        and then Command_State_Preservation_Summary (Id)'Length > 0
        and then Command_Non_Goal_Summary (Id)'Length > 0;
   end Has_Command_Reference;

   function File_Lifecycle_Command_Reference_Coherent return Boolean
   is
      Covered : constant array (Positive range 1 .. 10) of Command_Id :=
        (Command_Save_File,
         Command_Save_File_As,
         Command_Close_Active_Buffer,
         Command_Reopen_Closed_Buffer,
         Command_Reload_Active_Buffer,
         Command_Revert_Active_Buffer,
         Command_Rename_Buffer_File,
         Command_Delete_Buffer_File,
         Command_Copy_Buffer_File,
         Command_Move_Buffer_File);
      Seen : array (Command_Effect_Classification_Id) of Boolean :=
        (others => False);
      D : Command_Descriptor;
   begin
      for Id of Covered loop
         D := Descriptor (Id);
         if D.Id /= Id
           or else D.Category /= File_Category
           or else D.Family /= File_Lifecycle_Family
           or else D.Effect_Classification /= Command_Effect_Classification (Id)
           or else not Has_Command_Reference (Id)
           or else To_String (D.Summary) /= Command_Summary (Id)
           or else To_String (D.Availability_Summary) /= Command_Availability_Summary (Id)
           or else To_String (D.Mutation_Summary) /= Command_Mutation_Summary (Id)
           or else To_String (D.Filesystem_Effect_Summary) /= Command_Filesystem_Effect_Summary (Id)
           or else To_String (D.State_Preservation_Summary) /= Command_State_Preservation_Summary (Id)
           or else To_String (D.Non_Goal_Summary) /= Command_Non_Goal_Summary (Id)
         then
            return False;
         end if;

         if Seen (D.Effect_Classification) then
            return False;
         end if;
         Seen (D.Effect_Classification) := True;
      end loop;

      return True;
   end File_Lifecycle_Command_Reference_Coherent;

   function File_Lifecycle_Target_Prompt_Metadata_Minimal return Boolean
   is
      Covered : constant array (Positive range 1 .. 10) of Command_Id :=
        (Command_Save_File,
         Command_Save_File_As,
         Command_Close_Active_Buffer,
         Command_Reopen_Closed_Buffer,
         Command_Reload_Active_Buffer,
         Command_Revert_Active_Buffer,
         Command_Rename_Buffer_File,
         Command_Delete_Buffer_File,
         Command_Copy_Buffer_File,
         Command_Move_Buffer_File);

      D : Command_Descriptor;
      M : Minimal_Target_Prompt_Metadata;
      Prompt_Capable_Count : Natural := 0;
   begin
      for Id of Covered loop
         D := Descriptor (Id);
         M := Canonical_Target_Prompt_Metadata (Id);

         if D.Requires_Explicit_Target /= M.Requires_Explicit_Target
           or else D.Target_Prompt_Capable /= M.Target_Prompt_Capable
           or else To_String (D.Target_Prompt_Label) /= To_String (M.Target_Prompt_Label)
           or else D.Requires_Explicit_Target /= Command_Requires_Explicit_Target (Id)
           or else D.Target_Prompt_Capable /= Command_Is_Target_Prompt_Capable (Id)
           or else To_String (D.Target_Prompt_Label) /= Command_Target_Prompt_Label (Id)
         then
            return False;
         end if;

         if M.Target_Prompt_Capable then
            Prompt_Capable_Count := Prompt_Capable_Count + 1;
            if not M.Requires_Explicit_Target
              or else To_String (M.Target_Prompt_Label)'Length = 0
            then
               return False;
            end if;
         elsif M.Requires_Explicit_Target
           or else To_String (M.Target_Prompt_Label)'Length /= 0
         then
            return False;
         end if;
      end loop;

      if Prompt_Capable_Count /= 4 then
         return False;
      end if;

      for Id in Command_Id loop
         M := Canonical_Target_Prompt_Metadata (Id);
         if (Command_Requires_Explicit_Target (Id) /= M.Requires_Explicit_Target)
           or else (Command_Is_Target_Prompt_Capable (Id) /= M.Target_Prompt_Capable)
           or else (Command_Target_Prompt_Label (Id) /= To_String (M.Target_Prompt_Label))
         then
            return False;
         end if;

         if M.Target_Prompt_Capable
           and then not Is_File_Lifecycle_Command (Id)
         then
            return False;
         end if;
      end loop;

      return True;
   end File_Lifecycle_Target_Prompt_Metadata_Minimal;

   function File_Lifecycle_Target_Prompt_Metadata_Canonical_And_Minimal
     return Boolean
   is
   begin
      return File_Lifecycle_Target_Prompt_Metadata_Minimal;
   end File_Lifecycle_Target_Prompt_Metadata_Canonical_And_Minimal;

   function File_Lifecycle_Target_Prompt_Metadata_Frozen return Boolean
   is
      type Expected_Metadata is record
         Id       : Command_Id;
         Name     : Unbounded_String;
         Required : Boolean;
         Capable  : Boolean;
         Label    : Unbounded_String;
      end record;

      Expected : constant array (Positive range 1 .. 14) of Expected_Metadata :=
        ((Command_Save_File, To_Unbounded_String ("file.save"), False, False, Null_Unbounded_String),
         (Command_Save_File_As, To_Unbounded_String ("file.save-as"), True, True, To_Unbounded_String ("Save As target")),
         (Command_Close_Active_Buffer, To_Unbounded_String ("file.close-buffer"), False, False, Null_Unbounded_String),
         (Command_Reopen_Closed_Buffer, To_Unbounded_String ("file.reopen-closed-buffer"), False, False, Null_Unbounded_String),
         (Command_Reload_Active_Buffer, To_Unbounded_String ("file.reload-buffer"), False, False, Null_Unbounded_String),
         (Command_Revert_Active_Buffer, To_Unbounded_String ("file.revert-buffer"), False, False, Null_Unbounded_String),
         (Command_File_Conflict_Keep_Buffer, To_Unbounded_String ("file-conflict.keep-buffer"), False, False, Null_Unbounded_String),
         (Command_File_Conflict_Reload_From_Disk, To_Unbounded_String ("file-conflict.reload-from-disk"), False, False, Null_Unbounded_String),
         (Command_File_Conflict_Overwrite_Disk, To_Unbounded_String ("file-conflict.overwrite-disk"), False, False, Null_Unbounded_String),
         (Command_File_Conflict_Cancel, To_Unbounded_String ("file-conflict.cancel"), False, False, Null_Unbounded_String),
         (Command_Rename_Buffer_File, To_Unbounded_String ("file.rename-buffer-file"), True, True, To_Unbounded_String ("Rename target")),
         (Command_Delete_Buffer_File, To_Unbounded_String ("file.delete-buffer-file"), False, False, Null_Unbounded_String),
         (Command_Copy_Buffer_File, To_Unbounded_String ("file.copy-buffer-file"), True, True, To_Unbounded_String ("Copy target")),
         (Command_Move_Buffer_File, To_Unbounded_String ("file.move-buffer-file"), True, True, To_Unbounded_String ("Move target")));

      Prompt_Capable_Count : Natural := 0;
      Required_Count       : Natural := 0;

      function Prompted_Name_Absent (Name : String) return Boolean
      is
         Found : Boolean := False;
         Id    : Command_Id := No_Command;
      begin
         Id := Command_Id_From_Stable_Name (Name, Found);
         return (not Found) and then Id = No_Command;
      end Prompted_Name_Absent;
   begin
      if not File_Lifecycle_Target_Prompt_Metadata_Canonical_And_Minimal then
         return False;
      end if;

      for E of Expected loop
         declare
            D : constant Command_Descriptor := Descriptor (E.Id);
         begin
            if D.Id /= E.Id
              or else Stable_Command_Name (E.Id) /= To_String (E.Name)
              or else D.Requires_Explicit_Target /= E.Required
              or else D.Target_Prompt_Capable /= E.Capable
              or else To_String (D.Target_Prompt_Label) /= To_String (E.Label)
              or else Command_Requires_Explicit_Target (E.Id) /= E.Required
              or else Command_Is_Target_Prompt_Capable (E.Id) /= E.Capable
              or else Command_Target_Prompt_Label (E.Id) /= To_String (E.Label)
            then
               return False;
            end if;

            if E.Required then
               Required_Count := Required_Count + 1;
            end if;
            if E.Capable then
               Prompt_Capable_Count := Prompt_Capable_Count + 1;
               if To_String (E.Label)'Length = 0 then
                  return False;
               end if;
            elsif To_String (E.Label)'Length /= 0 then
               return False;
            end if;
         end;
      end loop;

      if Required_Count /= 4 or else Prompt_Capable_Count /= 4 then
         return False;
      end if;

      for Id in Command_Id loop
         if Command_Is_Target_Prompt_Capable (Id)
           and then Id not in Command_Save_File_As
                        | Command_Rename_Buffer_File
                        | Command_Copy_Buffer_File
                        | Command_Move_Buffer_File
         then
            return False;
         end if;

         if Command_Requires_Explicit_Target (Id)
           and then not Command_Is_Target_Prompt_Capable (Id)
         then
            return False;
         end if;

         if (not Command_Is_Target_Prompt_Capable (Id))
           and then Command_Target_Prompt_Label (Id)'Length /= 0
         then
            return False;
         end if;
      end loop;

      return Prompted_Name_Absent ("file.save-as-prompt")
        and then Prompted_Name_Absent ("file.prompt-save-as")
        and then Prompted_Name_Absent ("file.rename-buffer-file-prompt")
        and then Prompted_Name_Absent ("file.copy-buffer-file-prompt")
        and then Prompted_Name_Absent ("file.move-buffer-file-prompt")
        and then Prompted_Name_Absent ("file.save-as-with-target-prompt")
        and then Prompted_Name_Absent ("file.rename-with-target-prompt")
        and then Prompted_Name_Absent ("file.copy-with-target-prompt")
        and then Prompted_Name_Absent ("file.move-with-target-prompt")
        and then Prompted_Name_Absent ("prompt.file.save-as")
        and then Prompted_Name_Absent ("prompt.file.rename-buffer-file")
        and then Prompted_Name_Absent ("prompt.file.copy-buffer-file")
        and then Prompted_Name_Absent ("prompt.file.move-buffer-file")
        and then Prompted_Name_Absent ("leg" & "acy.file-target-prompt");
   end File_Lifecycle_Target_Prompt_Metadata_Frozen;

   function Make_Command_Descriptor
     (Id             : Command_Id;
      Stable_Name    : String;
      Label          : String;
      Description    : String;
      Category       : Command_Category;
      Visible        : Boolean;
      Bindable       : Boolean;
      Destructive    : Boolean := False;
      Lifecycle      : Boolean := False;
      Configuration  : Boolean := False)
      return Command_Descriptor
   is
      pragma Unreferenced (Stable_Name);
      Prompt_Metadata : constant Minimal_Target_Prompt_Metadata :=
        Canonical_Target_Prompt_Metadata (Id);
   begin
      return
        (Id            => Id,
         Name          => To_Unbounded_String (Label),
         Description   => To_Unbounded_String (Description),
         Category      => Category,
         Visibility    => (if Visible then Palette_Command else Hidden_Command),
         Bindable      => Bindable,
         Destructive   => Destructive,
         Lifecycle     => Lifecycle,
         Configuration => Configuration,
         Summary       => To_Unbounded_String (Command_Summary (Id)),
         Availability_Summary => To_Unbounded_String (Command_Availability_Summary (Id)),
         Mutation_Summary => To_Unbounded_String (Command_Mutation_Summary (Id)),
         Filesystem_Effect_Summary => To_Unbounded_String (Command_Filesystem_Effect_Summary (Id)),
         State_Preservation_Summary => To_Unbounded_String (Command_State_Preservation_Summary (Id)),
         Non_Goal_Summary => To_Unbounded_String (Command_Non_Goal_Summary (Id)),
         Requires_Explicit_Target => Prompt_Metadata.Requires_Explicit_Target,
         Target_Prompt_Capable => Prompt_Metadata.Target_Prompt_Capable,
         Target_Prompt_Label => Prompt_Metadata.Target_Prompt_Label,
         Family        => Command_Family (Id),
         Effect_Classification => Command_Effect_Classification (Id));
   end Make_Command_Descriptor;

   function Make_Descriptor
     (Id          : Command_Id;
      Name        : String;
      Description : String;
      Category    : Command_Category;
      Visibility  : Command_Visibility) return Command_Descriptor
   is
      Effective_Description : constant String :=
        (if Id = No_Command then Description
         elsif Description'Length = 0 then "Execute " & Name & "."
         else Description);
   begin
      return Make_Command_Descriptor
        (Id            => Id,
         Stable_Name   => Stable_Command_Name (Id),
         Label         => Name,
         Description   => Effective_Description,
         Category      => Category,
         Visible       => Visibility = Palette_Command,
         Bindable      => Id /= No_Command
           and then not Is_Public_Build_Command (Id),
         Destructive   => Is_Destructive_Command (Id),
         Lifecycle     => Is_Lifecycle_Command (Id),
         Configuration => Is_Configuration_Command (Id));
   end Make_Descriptor;

   function Descriptor
     (Id : Command_Id) return Command_Descriptor
   is
   begin
      case Id is
         when No_Command =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "No Command",
               Description => "",
               Category    => Internal_Category,
               Visibility  => Hidden_Command);
         when Command_Move_Left =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Left",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Move_Right =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Right",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Move_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Up",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Move_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Down",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Move_Line_Start =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Line Start",
               Description => "Move to the start of the current line",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Move_Line_End =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Line End",
               Description => "Move to the end of the current line",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Move_Document_Start =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Document Start",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Move_Document_End =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Document End",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Move_Word_Left =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Word Left",
               Description => "Move the caret to the previous word boundary",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Move_Word_Right =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Word Right",
               Description => "Move the caret to the next word boundary",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Page_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Page Up",
               Description => "Move up by one viewport page",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Page_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Page Down",
               Description => "Move down by one viewport page",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Select_Left =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Left",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Right =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Right",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Up",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Down",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Word_Left =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Extend Selection Word Left",
               Description => "Selection: extend to the previous word boundary",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Select_Word_Right =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Extend Selection Word Right",
               Description => "Selection: extend to the next word boundary",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Select_Word =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Word",
               Description => "Selection: select the word or symbol run at the caret",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Select_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Line",
               Description => "Selection: select the current full line",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Start_Rectangular_Selection =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Start Rectangular Selection",
               Description => "Selection: start a grid-cell rectangular selection at the caret",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Rectangular_Selection =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Rectangular Selection",
               Description => "Selection: clear the active rectangular selection",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Extend_Selection_Line_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Extend Selection Line Up",
               Description => "Selection: extend upward by one full line",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Extend_Selection_Line_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Extend Selection Line Down",
               Description => "Selection: extend downward by one full line",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Select_Line_Start =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Line Start",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Line_End =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Line End",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Document_Start =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Document Start",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Document_End =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Document End",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Page_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Page Up",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Page_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Page Down",
               Description => "",
               Category    => Selection_Category,
               Visibility  => Hidden_Command);
         when Command_Insert_Newline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Insert Newline",
               Description => "",
               Category    => Edit_Category,
               Visibility  => Hidden_Command);
         when Command_Undo =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Undo",
               Description => "Undo the most recent text edit in the current buffer.",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Redo =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Redo",
               Description => "Redo the most recently undone text edit in the current buffer.",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Edit_History_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Edit History",
               Description => "Clear undo and redo history for the current buffer.",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Copy =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Copy",
               Description => "Copy the active selected text into the editor clipboard",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Cut =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cut",
               Description => "Cut the active selected text into the editor clipboard",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Paste =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Paste",
               Description => "Paste editor clipboard text into the active buffer",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Clipboard_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Clipboard",
               Description => "Clear the editor clipboard.",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Select_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select All",
               Description => "Select all text in the current buffer.",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Selection_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Selection",
               Description => "Clear the current text selection.",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Line_Delete =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Delete Line",
               Description => "Delete the current logical line in the active buffer",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Line_Duplicate =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Duplicate Line",
               Description => "Duplicate the current logical line below itself",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Line_Move_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Line Up",
               Description => "Move the current logical line one line upward",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Line_Move_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Line Down",
               Description => "Move the current logical line one line downward",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Indent_Increase =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Indent Line",
               Description => "Increase indentation of the current logical line",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Indent_Decrease =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Outdent Line",
               Description => "Decrease indentation of the current logical line",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Comment_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Comment Line",
               Description => "Insert the canonical line comment marker on the current logical line",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Uncomment_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Uncomment Line",
               Description => "Remove the canonical line comment marker from the current logical line",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Line_Comment =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Line Comment",
               Description => "Toggle the canonical line comment marker on the current logical line",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Line_Join_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Join Line With Next",
               Description => "Join the current logical line with the following logical line",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Line_Split_At_Caret =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Split Line At Caret",
               Description => "Split the current logical line at the caret",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Trim_Trailing_Whitespace =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Trim Trailing Whitespace",
               Description => "Remove trailing spaces and tabs from the active buffer",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Char_Delete_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Delete Previous Character",
               Description => "Delete the character before the caret",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Char_Delete_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Delete Next Character",
               Description => "Delete the character after the caret",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Word_Delete_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Delete Previous Word",
               Description => "Delete the word-like text before the caret",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Word_Delete_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Delete Next Word",
               Description => "Delete the word-like text after the caret",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Selection_Delete =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Delete Selection",
               Description => "Delete the active selected text from the active buffer",
               Category    => Edit_Category,
               Visibility  => Palette_Command);
         when Command_Save_File =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save File",
               Description => "Save the active buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Save_File_As =>
            --  Phase 469: target acquisition is canonical, so Save As is
            --  projected and bindable through the transient file-target prompt.
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Save File As",
               Description   => "Save the current buffer to an explicit path.",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_Reload_Active_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reload File",
               Description => "Reload the active clean file-backed buffer from disk; dirty buffers are blocked.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Revert_Active_Buffer =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Revert File",
               Description   => "Discard unsaved changes in the active file-backed buffer by rereading disk contents",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_File_Conflict_Keep_Buffer =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Keep Buffer Changes",
               Description   => "Dismiss the active file conflict without reading or writing",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => False,
               Lifecycle     => True,
               Configuration => False);
         when Command_File_Conflict_Reload_From_Disk =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Reload Conflict From Disk",
               Description   => "Replace the conflicted buffer from disk after explicit confirmation",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => True,
               Lifecycle     => True,
               Configuration => False);
         when Command_File_Conflict_Overwrite_Disk =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Overwrite Disk From Buffer",
               Description   => "Overwrite the conflicted backing file with current buffer text",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => True,
               Lifecycle     => True,
               Configuration => False);
         when Command_File_Conflict_Cancel =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Cancel File Conflict",
               Description   => "Cancel the active file conflict prompt and preserve buffer text",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => False,
               Lifecycle     => True,
               Configuration => False);
         when Command_Rename_Buffer_File =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Rename Buffer File",
               Description   => "Rename the active clean file-backed buffer's backing file to an explicit path",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_Delete_Buffer_File =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Delete Buffer File",
               Description   => "Delete the active clean file-backed buffer's backing file and keep the buffer open as unsaved text",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_Copy_Buffer_File =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Copy Buffer File",
               Description   => "Copy the active clean file-backed buffer's backing file to an explicit path without changing the active association",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_Move_Buffer_File =>
            return Make_Command_Descriptor
              (Id            => Id,
               Stable_Name   => Stable_Command_Name (Id),
               Label         => "Move Buffer File",
               Description   => "Move the active clean file-backed buffer's backing file to an explicit path and update the active association after success",
               Category      => File_Category,
               Visible       => True,
               Bindable      => True,
               Destructive   => Is_Destructive_Command (Id),
               Lifecycle     => Is_Lifecycle_Command (Id),
               Configuration => Is_Configuration_Command (Id));
         when Command_Open_Quick_Open =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Quick Open",
               Description => "Show project files and filter them by path.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Close_Quick_Open =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Quick Open",
               Description => "Hide the Quick Open panel.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Toggle_Quick_Open =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Quick Open",
               Description => "Show or hide the Quick Open panel.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Accept_Quick_Open =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Quick Open Result",
               Description => "Open or activate the selected Quick Open file.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Next_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Quick Open Result",
               Description => "Select the next visible Quick Open result.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Previous_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Quick Open Result",
               Description => "Select the previous visible Quick Open result.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Query_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Quick Open Query",
                  Description => "Replace the Quick Open query with literal text.",
                  Category    => Project_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Quick_Open_Query_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Quick Open Query",
               Description => "Clear the Quick Open query.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Kind_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Quick Open File Kind",
               Description => "Cycle Quick Open to the next file-kind filter.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Kind_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Quick Open File Kind",
               Description => "Cycle Quick Open to the previous file-kind filter.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Kind_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Quick Open File Kind",
               Description => "Clear the Quick Open file-kind filter.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Scope_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Quick Open Scope",
                  Description => "Set the Quick Open project-relative path scope.",
                  Category    => Project_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Quick_Open_Scope_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Quick Open Scope",
               Description => "Clear the Quick Open path scope.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Scope_From_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Scope Quick Open to Selected Directory",
               Description => "Scope Quick Open to the selected file directory.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Scope_Parent =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Quick Open Parent Scope",
               Description => "Move Quick Open scope to the parent directory.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Reveal_Active =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reveal Active File in Quick Open",
               Description => "Show Quick Open with the active project file selected.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Quick_Open_Scope_Active_Directory =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Scope Quick Open to Active Directory",
               Description => "Show Quick Open scoped to the active file directory.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Quick_Open_Create_From_Query =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Create File from Quick Open Query",
               Description => "Create an empty project file from the current Quick Open query.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Create_With_Parents_From_Query =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Create File with Parent Directories from Quick Open Query",
               Description => "Create missing parent directories and an empty project file from the current Quick Open query.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Quick_Open_Priority_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Quick Open Recent Priority",
               Description => "Toggle Quick Open between path ordering and recent-file priority ordering.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Quick_Open_Priority_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Quick Open Priority",
               Description => "Restore Quick Open to deterministic path ordering.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Open_Buffer_Switcher =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Open Buffer List",
               Description => "Inspect and switch among currently open buffers",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Close_Buffer_Switcher =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Open Buffer List",
               Description => "Hide the open-buffer list",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Accept_Buffer_Switcher =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Switch To Selected Buffer",
               Description => "Switch to the selected open buffer-list row",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Buffer_Switcher_Next_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Next Buffer List Row",
               Description => "Select the next open-buffer list row",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Buffer_Switcher_Previous_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Previous Buffer List Row",
               Description => "Select the previous open-buffer list row",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Buffer_Switcher_Filter_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Open Buffer List Filter",
               Description => "Clear the active open-buffer list filter.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Filter_Pinned =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Open Buffer List to Pinned Buffers",
               Description => "Show only pinned open buffers in the Open Buffer List.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Filter_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Open Buffer List by Group",
               Description => "Show only open buffers in the named session-local group.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Filter_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Open Buffer List by Label",
               Description => "Show only open buffers with the named session-local label.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Filter_Noted =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Open Buffer List to Noted Buffers",
               Description => "Show only open buffers that have session-local notes.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Default =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List Default",
               Description => "Use the default Open Buffer List order.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Recent =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List by Recent",
               Description => "Order Open Buffer List rows by recent activation.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Name =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List by Name",
               Description => "Order Open Buffer List rows by display name.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Pinned =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List Pinned First",
               Description => "Order pinned open buffers before unpinned buffers in the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List by Group",
               Description => "Order grouped open buffers by group name in the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Sort Open Buffer List by Label",
               Description => "Order labeled open buffers by label text in the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Open Buffer List Sort",
               Description => "Cycle to the next Open Buffer List sort mode.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Sort_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Open Buffer List Sort",
               Description => "Cycle to the previous Open Buffer List sort mode.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Close =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close Selected Buffer List Row",
               Description => "Close the selected open buffer from the buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Pin =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Pin Selected Open Buffer",
               Description => "Pin the selected open buffer from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Unpin =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Unpin Selected Open Buffer",
               Description => "Unpin the selected open buffer from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Toggle_Pin =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Selected Open Buffer Pin",
               Description => "Toggle pin state for the selected open buffer from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Group_Assign =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Assign Selected Open Buffer Group",
               Description => "Assign the selected open buffer to a session-local group from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Group_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Selected Open Buffer Group",
               Description => "Clear the selected open buffer group from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Label_Set =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Selected Open Buffer Label",
               Description => "Set the selected open buffer label from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Label_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Selected Open Buffer Label",
               Description => "Clear the selected open buffer label from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Note_Set =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Selected Open Buffer Note",
               Description => "Set the selected open buffer note from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Selected_Note_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Selected Open Buffer Note",
               Description => "Clear the selected open buffer note from the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Open Buffer List Preview",
               Description => "Show or hide the selected open-buffer preview in the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Open Buffer List Preview",
               Description => "Show a compact read-only preview for the selected open buffer.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Hide =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Open Buffer List Preview",
               Description => "Hide the selected open-buffer preview in the open-buffer list.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Next_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Buffer List Preview Next Line",
               Description => "Scroll the selected-buffer preview down by one line.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Previous_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Buffer List Preview Previous Line",
               Description => "Scroll the selected-buffer preview up by one line.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Preview_Center_Cursor =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Center Open Buffer List Preview on Cursor",
               Description => "Return the selected-buffer preview to that buffer's cursor line.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Buffer_Switcher_Mark_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Selected Buffer Mark", Description => "Mark or unmark the selected open buffer in the open-buffer list.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Set =>
            return Make_Descriptor (Id => Id, Name => "Mark Selected Open Buffer", Description => "Mark the selected open buffer in the open-buffer list.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Clear =>
            return Make_Descriptor (Id => Id, Name => "Unmark Selected Open Buffer", Description => "Clear the mark from the selected open buffer in the open-buffer list.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Clear_All =>
            return Make_Descriptor (Id => Id, Name => "Clear Open Buffer List Marks", Description => "Clear all temporary Open Buffer List marks.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Invert_Visible =>
            return Make_Descriptor (Id => Id, Name => "Invert Visible Open Buffer List Marks", Description => "Invert marks for the currently visible open-buffer rows.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Visible =>
            return Make_Descriptor (Id => Id, Name => "Mark Visible Open Buffers", Description => "Mark all currently visible open-buffer list rows.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Clear_Visible =>
            return Make_Descriptor (Id => Id, Name => "Clear Visible Buffer Marks", Description => "Clear marks from currently visible open-buffer list rows.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Pinned =>
            return Make_Descriptor (Id => Id, Name => "Mark Pinned Open Buffers", Description => "Mark all currently open pinned buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Group =>
            return Make_Descriptor (Id => Id, Name => "Mark Open Buffers by Group", Description => "Mark all currently open buffers in a session-local group.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Label =>
            return Make_Descriptor (Id => Id, Name => "Mark Open Buffers by Label", Description => "Mark all currently open buffers with a session-local label.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Noted =>
            return Make_Descriptor (Id => Id, Name => "Mark Noted Open Buffers", Description => "Mark all currently open buffers that have session-local notes.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Close_Marked =>
            return Make_Descriptor (Id => Id, Name => "Prepare Close Marked Open Buffers", Description => "Prepare confirmation for closing all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Confirm =>
            return Make_Descriptor (Id => Id, Name => "Confirm Marked Buffer Action", Description => "Confirm the pending marked buffer action.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Cancel =>
            return Make_Descriptor (Id => Id, Name => "Cancel Marked Buffer Action", Description => "Cancel the pending marked buffer action without mutation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Pin_Marked =>
            return Make_Descriptor (Id => Id, Name => "Pin Marked Open Buffers", Description => "Pin all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Unpin_Marked =>
            return Make_Descriptor (Id => Id, Name => "Unpin Marked Open Buffers", Description => "Unpin all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Clear_Metadata =>
            return Make_Descriptor (Id => Id, Name => "Clear Marked Buffer Details", Description => "Clear group, label, and note details from all marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Group_Assign =>
            return Make_Descriptor (Id => Id, Name => "Assign Group to Marked Open Buffers", Description => "Assign a group to all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Group_Clear =>
            return Make_Descriptor (Id => Id, Name => "Clear Group from Marked Open Buffers", Description => "Clear group names from all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Label_Set =>
            return Make_Descriptor (Id => Id, Name => "Set Label on Marked Open Buffers", Description => "Set a label on all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Label_Clear =>
            return Make_Descriptor (Id => Id, Name => "Clear Label from Marked Open Buffers", Description => "Clear labels from all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Note_Set =>
            return Make_Descriptor (Id => Id, Name => "Set Note on Marked Open Buffers", Description => "Set a note on all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Note_Clear =>
            return Make_Descriptor (Id => Id, Name => "Clear Note from Marked Open Buffers", Description => "Clear notes from all currently marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Review_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Marked Buffer Review", Description => "Show or hide a marked-only review view in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Review_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Marked Buffer Review", Description => "Show only currently marked open buffers in the open-buffer list.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Review_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Marked Buffer Review", Description => "Return the open-buffer list to its normal view.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Review_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Pending Marked Close Review", Description => "Show or hide the captured pending marked-close target review in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Review_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Pending Marked Close Review", Description => "Show captured pending marked-close targets in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Review_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Pending Marked Close Review", Description => "Hide pending marked-close target review without cancelling the pending action.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Pending Marked Close Target", Description => "Move open-buffer list selection to the next captured pending close target without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Pending Marked Close Target", Description => "Move open-buffer list selection to the previous captured pending close target without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Pending Marked Close", Description => "Report captured and still-open pending marked-close target counts.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Remove_Selected =>
            return Make_Descriptor (Id => Id, Name => "Remove Selected Pending Marked Close Target", Description => "Remove the selected buffer from the captured pending marked-close targets without changing marks.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned =>
            return Make_Descriptor (Id => Id, Name => "Restore Last Pruned Pending Marked Close Target", Description => "Restore the most recently pruned pending marked-close target without changing marks.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Pruned Pending Marked Close Targets", Description => "Report pruned pending marked-close target counts.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Pruned Pending Marked Close Target", Description => "Move open-buffer list selection to the next still-open pruned pending marked-close target without restoring it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Pruned Pending Marked Close Target", Description => "Move open-buffer list selection to the previous still-open pruned pending marked-close target without restoring it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Pruned Pending Marked Close Review", Description => "Show or hide pruned pending marked-close targets in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Pruned Pending Marked Close Review", Description => "Show still-open pruned pending marked-close targets in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Pruned Pending Marked Close Review", Description => "Hide pruned pending marked-close target review without restoring targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned =>
            return Make_Descriptor (Id => Id, Name => "Restore Selected Pruned Pending Marked Close Target", Description => "Restore the selected still-open pruned pending marked-close target without changing marks.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Dirty Pending Marked Close Targets", Description => "Report dirty still-open pending marked-close target counts.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Dirty Pending Marked Close Target", Description => "Move open-buffer list selection to the next dirty pending marked-close target without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Dirty Pending Marked Close Target", Description => "Move open-buffer list selection to the previous dirty pending marked-close target without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected =>
            return Make_Descriptor (Id => Id, Name => "Remove Selected Dirty Pending Marked Close Target", Description => "Remove the selected dirty pending marked-close target without closing, saving, discarding, or changing marks.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview =>
            return Make_Descriptor (Id => Id, Name => "Prepare Dirty Pending Marked Close Prune", Description => "Capture all currently dirty pending marked-close targets for explicit bulk pruning.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply =>
            return Make_Descriptor (Id => Id, Name => "Prepare Dirty Prune Apply Confirmation", Description => "Capture the current dirty-prune preview targets for explicit apply confirmation without pruning pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm =>
            return Make_Descriptor (Id => Id, Name => "Confirm Dirty Prune Apply", Description => "Confirm and prune captured dirty-prune apply targets that are still open, pending, and dirty.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel =>
            return Make_Descriptor (Id => Id, Name => "Cancel Dirty Prune Apply Confirmation", Description => "Clear the pending dirty-prune apply confirmation without mutating preview or pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Dirty Prune Apply Targets", Description => "Report captured and still-applicable dirty-prune apply confirmation targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Dirty Prune Apply Target", Description => "Move open-buffer list selection to the next captured dirty-prune apply target without activating or pruning it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Dirty Prune Apply Target", Description => "Move open-buffer list selection to the previous captured dirty-prune apply target without activating or pruning it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Dirty Prune Apply Review", Description => "Toggle review of captured dirty-prune apply targets in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Dirty Prune Apply Review", Description => "Show captured dirty-prune apply targets in the Open Buffer List without confirming them.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Dirty Prune Apply Review", Description => "Return the open-buffer list to its normal view without clearing dirty-prune apply confirmation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected =>
            return Make_Descriptor (Id => Id, Name => "Remove Selected Dirty Prune Apply Target", Description => "Remove the selected buffer from dirty-prune apply confirmation without mutating the preview or pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed =>
            return Make_Descriptor (Id => Id, Name => "Restore Last Removed Dirty Prune Apply Target", Description => "Restore the most recently removed buffer to dirty-prune apply confirmation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Removed Dirty Prune Apply Targets", Description => "Report targets removed from the current dirty-prune apply confirmation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Removed Dirty Prune Apply Target", Description => "Move open-buffer list selection to the next still-open target removed from dirty-prune apply confirmation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Removed Dirty Prune Apply Target", Description => "Move open-buffer list selection to the previous still-open target removed from dirty-prune apply confirmation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale =>
            return Make_Descriptor (Id => Id, Name => "Clear Stale Dirty Prune Apply Targets", Description => "Remove stale targets from dirty-prune apply confirmation without recording removals or pruning pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Stale_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Stale Dirty Prune Apply Targets", Description => "Report stale targets in the pending dirty-prune apply confirmation without mutating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel =>
            return Make_Descriptor (Id => Id, Name => "Cancel Dirty Pending Marked Close Prune", Description => "Clear the prepared dirty pending marked-close prune without mutation.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Dirty Pending Marked Close Prune", Description => "Report captured and still-applicable dirty pending marked-close prune targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Dirty Prune Preview Target", Description => "Move open-buffer list selection to the next captured dirty-prune preview target without activating or pruning it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Dirty Prune Preview Target", Description => "Move open-buffer list selection to the previous captured dirty-prune preview target without activating or pruning it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Dirty Prune Preview Review", Description => "Toggle review of captured dirty-prune preview targets in the Open Buffer List.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Dirty Prune Preview Review", Description => "Show captured dirty-prune preview targets in the Open Buffer List without applying them.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Dirty Prune Preview Review", Description => "Return the open-buffer list to its normal view without clearing the dirty-prune preview.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected =>
            return Make_Descriptor (Id => Id, Name => "Remove Selected Dirty Prune Preview Target", Description => "Remove the selected buffer from the prepared dirty-prune preview without pruning pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed =>
            return Make_Descriptor (Id => Id, Name => "Restore Last Removed Dirty Prune Preview Target", Description => "Restore the most recently removed buffer to the prepared dirty-prune preview without pruning pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Removed Dirty Prune Preview Targets", Description => "Report dirty-prune preview targets removed from the current prepared preview.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Removed Dirty Prune Preview Target", Description => "Move open-buffer list selection to the next still-open target removed from the dirty-prune preview without restoring or activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Removed Dirty Prune Preview Target", Description => "Move open-buffer list selection to the previous still-open target removed from the dirty-prune preview without restoring or activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale =>
            return Make_Descriptor (Id => Id, Name => "Clear Stale Dirty Prune Preview Targets", Description => "Remove stale targets from the prepared dirty-prune preview without pruning active pending close targets.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Stale Dirty Prune Preview Targets", Description => "Report stale targets in the prepared dirty-prune preview without mutating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Next =>
            return Make_Descriptor (Id => Id, Name => "Select Next Marked Open Buffer", Description => "Move the open-buffer list selection to the next marked candidate without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Previous =>
            return Make_Descriptor (Id => Id, Name => "Select Previous Marked Open Buffer", Description => "Move the open-buffer list selection to the previous marked candidate without activating it.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Buffer_Switcher_Mark_Summary =>
            return Make_Descriptor (Id => Id, Name => "Summarize Buffer Marks", Description => "Report the current count of marked open buffers.", Category => Navigation_Category, Visibility => Palette_Command);
         when Command_Open_Command_Palette =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Command Palette",
               Description => "Open the command palette overlay for command discovery and execution.",
               Category    => Overlay_Category,
               Visibility  => Hidden_Command);
         when Command_Palette_Show_Command_Help =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Command Help",
               Description => "Toggle display-only help for the selected command palette command without executing it.",
               Category    => Overlay_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Theme =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Theme",
               Description => "Switch between available editor themes.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Set_Theme_Light =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Theme Light",
               Description => "Use the light editor theme.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Set_Theme_Dark =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Theme Dark",
               Description => "Use the dark editor theme.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Cancel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel",
               Description => "",
               Category    => Overlay_Category,
               Visibility  => Hidden_Command);
         when Command_Open_File =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open File",
               Description => "Open a file",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Open_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Project",
               Description => "Open a folder as the current project",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Switch_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Switch Project",
               Description => "Switch explicitly to another project after any required dirty-buffer review.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Show_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Recent Projects",
               Description => "Show known project roots",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Open_Selected_Recent_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Recent Project",
               Description => "Open the selected recent project",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Clear_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Recent Projects",
               Description => "Forget the list of recent project roots",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Remove_Selected_Recent_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Remove Selected Recent Project",
               Description => "Forget the selected recent project",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Remove_Missing_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Remove Missing Recent Projects",
               Description => "Forget recent projects whose paths are unavailable",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Select_Next_Recent_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Next Recent Project",
               Description => "Move Recent Projects selection to the next entry",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Select_Previous_Recent_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Previous Recent Project",
               Description => "Move Recent Projects selection to the previous entry",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Close_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close Project",
               Description => "Close the current project and project-scoped UI state; does not delete project files.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Project =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Context",
               Description => "Clear the current project root and project-scoped UI state.",
               Category    => Project_Category,
               Visibility  => Hidden_Command);
         when Command_Refresh_File_Tree =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh File Tree",
               Description => "Refresh the project File Tree.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Refresh_Project_Files =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh Project Files",
               Description => "Refresh the project file list for Quick Open.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Project_Files_Summary =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Project Files Summary",
               Description => "Show the current project file count.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Reveal_Active_File_In_Tree =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reveal Active File in File Tree",
               Description => "Select the active file in the project File Tree without opening files.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_New_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "New Buffer",
               Description => "Create a new untitled buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Close_Active_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close Buffer",
               Description => "Close the active buffer; dirty buffers open a save/discard/cancel review.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Confirm_Close_Save =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Confirm Close: Save",
               Description => "Save dirty file-backed close candidates, then close only successfully saved buffers.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Confirm_Close_Discard =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Confirm Close: Discard",
               Description => "Explicitly discard dirty close candidates without deleting backing files.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Cancel_Close =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel Close",
               Description => "Cancel the active dirty-buffer close review without mutating buffers.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Reopen_Closed_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reopen Closed Buffer",
               Description => "Reopen the most recently closed clean file-backed buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Close_Other_Buffers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close Other Buffers",
               Description => "Close every non-active clean buffer and leave dirty buffers open.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Close_All_Buffers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close All Buffers",
               Description => "Close all buffers, requiring explicit confirmation when dirty buffers would be discarded.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Close_All_Clean_Buffers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close All Clean Buffers",
               Description => "Close clean buffers while leaving dirty buffers open.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Pin_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Pin Buffer",
               Description => "Mark the active buffer as pinned for this session.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Unpin_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Unpin Buffer",
               Description => "Clear the active buffer pinned marker.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Buffer_Pin =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Buffer Pin",
               Description => "Toggle the active buffer pinned state.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Set_Buffer_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Buffer Label",
               Description => "Set or replace the active buffer session-local label.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Buffer_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Buffer Label",
               Description => "Clear the active buffer session-local label.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Edit_Buffer_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Edit Buffer Label",
               Description => "Edit the active buffer session-local label.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Show_Buffer_Label =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Buffer Label",
               Description => "Show the active buffer session-local label.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Set_Buffer_Note =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Buffer Note",
               Description => "Set or replace the active buffer session-local note.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Buffer_Note =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Buffer Note",
               Description => "Clear the active buffer session-local note.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Edit_Buffer_Note =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Edit Buffer Note",
               Description => "Edit the active buffer session-local note.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Show_Buffer_Note =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Buffer Note",
               Description => "Show the active buffer session-local note.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Assign_Buffer_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Assign Buffer Group",
               Description => "Assign the active buffer to a session-local group.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Buffer_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Buffer Group",
               Description => "Remove the active buffer from its session-local group.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Switch_Buffer_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Switch Buffer Group",
               Description => "Switch the active buffer group filter by name.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Next_Buffer_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Buffer Group",
               Description => "Cycle to the next existing buffer group.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Buffer_Group =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Buffer Group",
               Description => "Cycle to the previous existing buffer group.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Show_All_Buffer_Groups =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show All Buffer Groups",
               Description => "Clear the active buffer group filter and show all open buffers.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Cancel_Pending_Transition =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel Pending Transition",
               Description => "Cancel the blocked operation without saving or discarding files.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Retry_Pending_Transition =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Retry Pending Transition",
               Description => "Retry the blocked operation after unsaved changes are resolved.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Discard_Pending_Transition =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Discard and Continue Pending Transition",
               Description => "Explicitly discard affected dirty buffers and continue the blocked project operation.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Next_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Buffer",
               Description => "Switch to the next open buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Buffer",
               Description => "Switch to the previous open buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Recent_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Recent Buffer",
               Description => "Switch to the most recently used non-active open buffer",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Next_Recent_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Recent Buffer",
               Description => "Move forward through recent-buffer traversal",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Switch_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Switch Buffer",
               Description => "",
               Category    => File_Category,
               Visibility  => Hidden_Command);
         when Command_Toggle_Minimap =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Minimap",
               Description => "Show or hide the minimap.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Scrollbars =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Scrollbars",
               Description => "Show or hide editor scrollbars.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Line_Numbers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Line Numbers",
               Description => "Show or hide gutter line numbers",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Line_Number_Mode =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Line Number Mode",
               Description => "Cycle the editor line-number display mode.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Set_Absolute_Line_Numbers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Absolute Line Numbers",
               Description => "Show absolute document line numbers",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Set_Relative_Line_Numbers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Relative Line Numbers",
               Description => "Show relative distances in the gutter",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Set_Hybrid_Line_Numbers =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hybrid Line Numbers",
               Description => "Show the current line as absolute and other lines as relative",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Current_Line_Highlight =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Current Line Highlight",
               Description => "Show or hide the current-line highlights",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Cursor_Blink =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Cursor Blink",
               Description => "Enable or disable cursor blinking.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Syntax_Colouring =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Syntax Colouring",
               Description => "Enable or disable syntax colouring",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Diagnostics =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Diagnostics",
               Description => "Show or hide diagnostic decorations",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Problems_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Problems",
               Description => "Show or hide the Problems panel",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Next_Diagnostic =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Diagnostic",
               Description => "Jump to the next diagnostic",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Diagnostic =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Diagnostic",
               Description => "Jump to the previous diagnostic",
               Category    => Diagnostics_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Bookmark =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Bookmark",
               Description => "Bookmarks: toggle a bookmark on the current row",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Next_Bookmark =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Bookmark",
               Description => "Bookmarks: jump to the next bookmark",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Bookmark =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Bookmark",
               Description => "Bookmarks: jump to the previous bookmark",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Bookmarks =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Buffer Bookmarks",
               Description => "Bookmarks: clear bookmarks in the active buffer",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Clear_All_Bookmarks =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear All Bookmarks",
               Description => "Bookmarks: clear bookmarks in all open buffers",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Toggle_Current_Location =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmark: Toggle Current Location",
               Description => "Toggle a session-local bookmark at the active editor location",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Clear_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Clear All",
               Description => "Clear all session-local bookmarks",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Next",
               Description => "Select the next bookmark row without opening a file",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Previous",
               Description => "Select the previous bookmark row without opening a file",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Goto_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Go To Next",
               Description => "Open the next bookmark after the active editor location",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Goto_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Go To Previous",
               Description => "Open the previous bookmark before the active editor location",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Open Selected",
               Description => "Open the selected bookmark through the existing file-open path",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Reveal_Current =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Reveal Current",
               Description => "Select the bookmark nearest to the active editor location",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Remove_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Remove Selected",
               Description => "Remove the selected session-local bookmark row",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Show",
               Description => "Show the session-local bookmark surface",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Bookmark_Hide =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Hide",
               Description => "Hide the session-local bookmark surface",
               Category    => Bookmarks_Category,
               Visibility  => Hidden_Command);
         when Command_Bookmark_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Bookmarks: Toggle",
               Description => "Toggle the session-local bookmark surface",
               Category    => Bookmarks_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Cursor_Style =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Cursor Style",
               Description => "Cycle cursor style",
               Category    => View_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Line",
               Description => "Show a line-number input for jumping in the active buffer",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Line_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Go to Line",
               Description => "Toggle the go-to-line input",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Line_Prefill_Current =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Current Line",
               Description => "Prefill the go-to-line input from the active caret line",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Line_Query_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Go to Line Query",
                  Description => "Replace the go-to-line input with the entered line number",
                  Category    => Navigation_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Goto_Line_Query_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Go to Line Query",
               Description => "Clear the go-to-line input",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Navigation_Back =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Navigation Back",
               Description => "Return to the previous editor navigation location",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Navigation_Forward =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Navigation Forward",
               Description => "Move to the next editor navigation location",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Navigation_History_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Navigation History",
               Description => "Clear the session navigation back and forward stacks",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Close_Goto_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Close Go to Line",
               Description => "Close the go-to-line input",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Accept_Goto_Line =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Accept Go to Line",
               Description => "Jump to the line entered in the go-to-line input",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Find_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find",
               Description => "Show a literal find prompt for the active buffer",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Hide =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Find",
               Description => "Hide Find and clear the current find text",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Find_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Find",
               Description => "Toggle the Find prompt for the current buffer.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Query_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Find Query",
                  Description => "Replace the Find text for the active buffer",
                  Category    => Search_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Find_Query_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Find Query",
               Description => "Clear the Find text for the active buffer",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Find_Case_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Find Case Sensitivity",
               Description => "Toggle Find between case-insensitive and case-sensitive matching",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Case_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Find Case Sensitivity",
               Description => "Reset Find to case-insensitive matching",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Whole_Word_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Find Whole Word",
               Description => "Toggle Find between substring and whole-word matching",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Whole_Word_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Find Whole Word",
               Description => "Reset Find to substring matching",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_From_Selection =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find from Selection",
               Description => "Use the active single-line selection as the Find text",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_From_Active_Word =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find from Active Word",
               Description => "Use the word under the primary caret as the Find text",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Active_Find_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find Next in Active Buffer",
               Description => "Move to the next literal match in the active buffer",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Active_Find_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find Previous in Active Buffer",
               Description => "Move to the previous literal match in the active buffer",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_First =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find First in Active Buffer",
               Description => "Move to the first literal match in the active buffer",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Last =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Find Last in Active Buffer",
               Description => "Move to the last literal match in the active buffer",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Find_Reveal_Current =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reveal Current Find Match",
               Description => "Select the Find match at or after the current caret without moving the caret",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Replace_Show =>
            return Make_Descriptor (Id => Id, Name => "Show Replace", Description => "Show the literal Replace field attached to Find", Category => Search_Category, Visibility => Palette_Command);
         when Command_Replace_Hide =>
            return Make_Descriptor (Id => Id, Name => "Hide Replace", Description => "Hide Replace and clear the replacement text", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Replace_Toggle =>
            return Make_Descriptor (Id => Id, Name => "Toggle Replace", Description => "Toggle the Replace field", Category => Search_Category, Visibility => Palette_Command);
         when Command_Replace_Text_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor (Id => Id, Name => "Set Replace Text", Description => "Set the literal replacement text", Category => Search_Category, Visibility => Hidden_Command);
            begin
               D.Bindable := False; return D;
            end;
         when Command_Replace_Text_Clear =>
            return Make_Descriptor (Id => Id, Name => "Clear Replace Text", Description => "Clear the literal replacement text", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Replace_Current =>
            return Make_Descriptor (Id => Id, Name => "Replace Current Find Match", Description => "Replace the selected Find match with literal replacement text", Category => Search_Category, Visibility => Palette_Command);
         when Command_Replace_All =>
            return Make_Descriptor (Id => Id, Name => "Replace All Find Matches", Description => "Replace every current Find match with literal replacement text", Category => Search_Category, Visibility => Palette_Command);
         when Command_Goto_Start =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Goto Start",
               Description => "Move to document start",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_End =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Goto End",
               Description => "Move to document end",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Run_Project_Search =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Search Project",
               Description => "Search known project files for the current query.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Rerun_Project_Search =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Rerun Project Search",
               Description => "Rerun the current Project Search query.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Open_Project_Search_Bar =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Project Search",
               Description => "Show Project Search.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Project_Search_Bar =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Search",
               Description => "Toggle Project Search.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Close_Project_Search_Bar =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Project Search",
               Description => "Hide Project Search without changing files.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Run_Project_Search_From_Bar =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Set Project Search Query",
               Description => "Set the Project Search query from the active input and run search.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_From_Selection =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Search Project for Selection",
               Description => "Search Project for the active single-line selection.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_From_Active_Word =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Search Project for Active Word",
               Description => "Search Project for the word under the primary caret.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_Active_Directory =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Search Active Directory",
               Description => "Search the active file directory for the active selection or word.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Project_Search =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Query",
               Description => "Clear the Project Search query and results.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Open_Selected_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Project Search Result",
               Description => "Open the selected project search result.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Move_Project_Search_Selection_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Project Search Selection Up",
               Description => "Move the Project Search selection up without opening a file.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Move_Project_Search_Selection_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Project Search Selection Down",
               Description => "Move the Project Search selection down without opening a file.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Next_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Project Search Result",
               Description => "Move to the next Project Search result without opening a file.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Project Search Result",
               Description => "Move to the previous Project Search result without opening a file.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_First_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "First Project Search Result",
               Description => "Select the first Project Search result without opening a file.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Last_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Last Project Search Result",
               Description => "Select the last Project Search result without opening a file.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Reveal_Active_Project_Search_Result =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reveal Active Project Search Result",
               Description => "Reveal the active buffer in Project Search results.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Project_Search_Scope_Selected_Directory =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Scope Project Search to Selected Directory",
               Description => "Scope Project Search to the selected result's directory.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Kind_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Project Search Kind Filter",
               Description => "Select the next Project Search file-kind filter.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Kind_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Project Search Kind Filter",
               Description => "Select the previous Project Search file-kind filter.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Kind_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Kind Filter",
               Description => "Clear the Project Search file-kind filter.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Scope_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Project Search Scope",
                  Description => "Set the Project Search path scope.",
                  Category    => Search_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Project_Search_Scope_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Scope",
               Description => "Clear the Project Search path scope.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Case_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Search Case Sensitivity",
               Description => "Toggle case-sensitive Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Case_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Case Sensitivity",
               Description => "Clear case-sensitive Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Whole_Word_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Search Whole Word",
               Description => "Toggle whole-word Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Whole_Word_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Whole Word",
               Description => "Clear whole-word Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Regex_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Search Regex",
               Description => "Toggle regex Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Regex_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Regex",
               Description => "Clear regex Project Search matching.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Include_Filter_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Project Search Include Filter",
                  Description => "Set the Project Search include path filter.",
                  Category    => Search_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Project_Search_Exclude_Filter_Set =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Set Project Search Exclude Filter",
                  Description => "Set the Project Search exclude path filter.",
                  Category    => Search_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Project_Search_Include_Filter_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Include Filter",
               Description => "Clear the Project Search include path filter.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Exclude_Filter_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Exclude Filter",
               Description => "Clear the Project Search exclude path filter.",
               Category    => Search_Category,
               Visibility  => Hidden_Command);
         when Command_Project_Search_Replace_Preview =>
            return Make_Descriptor (Id => Id, Name => "Preview Project Search Replacements", Description => "Preview replacements for current Project Search results.", Category => Search_Category, Visibility => Palette_Command);
         when Command_Project_Search_Replace_Toggle_Selected =>
            return Make_Descriptor (Id => Id, Name => "Toggle Selected Project Search Replacement", Description => "Include or exclude the selected replacement preview row", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Include_Selected =>
            return Make_Descriptor (Id => Id, Name => "Include Selected Project Search Replacement", Description => "Include the selected replacement preview row", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Exclude_Selected =>
            return Make_Descriptor (Id => Id, Name => "Exclude Selected Project Search Replacement", Description => "Exclude the selected replacement preview row", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Include_File =>
            return Make_Descriptor (Id => Id, Name => "Include File Project Search Replacements", Description => "Include all replacement preview rows for the selected file group", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Exclude_File =>
            return Make_Descriptor (Id => Id, Name => "Exclude File Project Search Replacements", Description => "Exclude all replacement preview rows for the selected file group", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Include_All =>
            return Make_Descriptor (Id => Id, Name => "Include All Project Search Replacements", Description => "Include all replacement preview rows", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Exclude_All =>
            return Make_Descriptor (Id => Id, Name => "Exclude All Project Search Replacements", Description => "Exclude all replacement preview rows", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Project_Search_Replace_Selected =>
            return Make_Descriptor (Id => Id, Name => "Replace Selected Project Search Match", Description => "Replace the selected Project Search match.", Category => Search_Category, Visibility => Palette_Command);
         when Command_Project_Search_Replace_All_Included =>
            return Make_Descriptor (Id => Id, Name => "Replace All Included Project Search Matches", Description => "Replace all included Project Search matches.", Category => Search_Category, Visibility => Palette_Command);
         when Command_Project_Search_Replace_Clear_Preview =>
            return Make_Descriptor (Id => Id, Name => "Clear Project Search Replacement Preview", Description => "Clear Project Search replacement preview without changing files.", Category => Search_Category, Visibility => Hidden_Command);
         when Command_Show_Search_Results_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Project Search Results",
               Description => "Show Project Search results.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Editor_Text =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Editor",
               Description => "Return keyboard focus to editor text",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Search_Results =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Project Search Results",
               Description => "Focus Project Search results.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Problems =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Problems",
               Description => "Move keyboard focus to the Problems panel",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Bottom_Panel_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Bottom Panel Focus",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Search_Results_Move_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Project Search Selection Up",
               Description => "Move the Project Search result selection up.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Move_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Project Search Selection Down",
               Description => "Move the Project Search result selection down.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Page_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Project Search Page Up",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Search_Results_Page_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Project Search Page Down",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Search_Results_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Search Result",
               Description => "Open the selected Search Result.",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Move_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Problem Selection Up",
               Description => "Move the focused Problems selection up",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Move_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Move Problem Selection Down",
               Description => "Move the focused Problems selection down",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Page_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Problems Page Up",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Problems_Page_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Problems Page Down",
               Description => "",
               Category    => Navigation_Category,
               Visibility  => Hidden_Command);
         when Command_Problems_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Problem",
               Description => "Open the currently selected Problems row",
               Category    => Selection_Category,
               Visibility  => Palette_Command);
         when Command_Problems_Focus_Editor =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Problems Focus Editor",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Focus_File_Tree =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus File Tree",
               Description => "Move keyboard focus to the project file tree",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Move_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "File Tree Move Up",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_File_Tree_Move_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "File Tree Move Down",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_File_Tree_Page_Up =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "File Tree Page Up",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_File_Tree_Page_Down =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "File Tree Page Down",
               Description => "",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_File_Tree_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected File",
               Description => "Open or toggle the selected File Tree row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Create_File =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Create File",
               Description => "Create an empty file under the active project from a selected directory name or project-relative path.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Create_Directory =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Create Directory",
               Description => "Create a directory under the active project from a selected directory name or project-relative path.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Rename_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Rename File or Directory",
               Description => "Rename the selected project file or directory from explicit input.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Delete_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Delete File or Directory",
               Description => "Delete the selected project file or directory after explicit confirmation text.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Expand_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Expand Selected File Tree Item",
               Description => "Expand the selected file tree directory",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Collapse_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Collapse Selected File Tree Item",
               Description => "Collapse the selected file tree directory",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Toggle_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Selected File Tree Item",
               Description => "Toggle the selected file tree directory",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Collapse_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Collapse All File Tree Directories",
               Description => "Collapse all directories in the File Tree view state only.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_File_Tree_Expand_To_Active_File =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Expand File Tree to Active File",
               Description => "Expand parent directories and select the active project file.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Save_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save All",
               Description => "Save all dirty file-backed buffers.",
               Category    => File_Category,
               Visibility  => Palette_Command);
         when Command_Save_Settings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Settings",
               Description => "Save global editor preferences.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Reload_Settings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reload Settings",
               Description => "Reload global editor preferences from disk.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Reset_Settings_To_Defaults =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Settings to Defaults",
               Description => "Reset global editor preferences to built-in defaults.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Save_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Keybindings",
               Description => "Save global keybinding overrides.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Reload_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reload Keybindings",
               Description => "Reload global keybinding overrides from disk.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Validate_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Validate Keybindings",
               Description => "Validate active keybindings against known commands and conflicts.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Keybindings",
               Description => "Show the keybinding management surface.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Keybindings",
               Description => "Focus the keybinding management surface.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Assign_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Assign Selected Keybinding",
               Description => "Start explicit shortcut capture for the selected bindable command.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Remove_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Remove Selected Keybinding",
               Description => "Remove the selected user keybinding or selected chord.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Reset_To_Defaults =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Keybindings to Defaults",
               Description => "Request explicit reset of user keybinding overrides to defaults.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Filter_Conflicts =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Keybinding Conflicts",
               Description => "Show keybindings with active/default conflicts.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Filter_Unbound =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Unbound Commands",
               Description => "Show bindable commands that currently have no active shortcut.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Clear_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Keybinding Filter",
               Description => "Clear the keybinding filter text.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Keybindings_Cancel_Capture =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel Keybinding Capture",
               Description => "Cancel pending keybinding capture or replacement confirmation.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Startup_Show_Summary =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Startup Summary",
               Description => "Show the startup and recovery summary without loading, saving, or repairing configuration.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Recover_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Configuration Recovery",
               Description => "Show bounded configuration recovery status for settings, keybindings, workspace, and recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Audit =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Review Configuration",
               Description => "Review configuration and recovery readiness without changing settings.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Settings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Settings Domain",
               Description => "Reset settings to safe defaults without touching keybindings, workspace, or recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Keybindings Domain",
               Description => "Reset keybindings to safe defaults without touching settings, workspace, or recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Workspace =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Workspace Domain",
               Description => "Clear structural workspace state without touching settings, keybindings, or recent projects.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset Recent Projects Domain",
               Description => "Clear recent projects without touching settings, keybindings, or workspace state.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reset All Configuration Domains",
               Description => "Request explicit confirmation before resetting settings, keybindings, workspace, and recent projects.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_All_Confirm =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Confirm Reset All Configuration Domains",
               Description => "Confirm the pending reset-all request; project files and dirty buffers are not changed.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Reset_All_Cancel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Cancel Reset All Configuration Domains",
               Description => "Cancel the pending reset-all confirmation without changing configuration domains.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Settings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Settings",
               Description => "Write supported settings fields only; does not write other configuration domains.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Keybindings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Keybindings",
               Description => "Write normalized valid keybindings only; does not write settings or workspace state.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Workspace =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Workspace",
               Description => "Write structural workspace fields only; does not write settings, keybindings, or recent projects.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Configuration_Save_Clean_Recent_Projects =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Clean Recent Projects",
               Description => "Write lightweight recent project entries only; does not write workspace or settings data.",
               Category    => Settings_Category,
               Visibility  => Palette_Command);
         when Command_Save_Workspace_State =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Save Workspace State",
               Description => "Save structural workspace/session state; does not save dirty file contents.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Restore_Workspace_State =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Restore Workspace",
               Description => "Restore saved workspace/session state without saving or restoring unsaved text.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Workspace_State =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Workspace State",
               Description => "Delete the saved structural workspace/session state for the current project; does not delete project files.",
               Category    => Workspace_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Feature Panel",
               Description => "Show or hide the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Show_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Feature Panel",
               Description => "Show the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Hide_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Feature Panel",
               Description => "Hide the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Feature Panel",
               Description => "Move focus to the feature panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Feature_Panel =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Feature Panel",
               Description => "Clear feature panel rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Feature_Panel_Select_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Feature Panel Select Next",
               Description => "Select the next feature panel row.",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Feature_Panel_Select_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Feature Panel Select Previous",
               Description => "Select the previous feature panel row.",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Feature_Panel_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Feature Panel Row",
               Description => "Open the selected feature panel row.",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Refresh_Outline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh Outline",
               Description => "Refresh Outline for the active buffer.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Refresh_Outline_Project_Index =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh Outline Project Index",
               Description => "Refresh the Ada language index from known project Ada source files for Outline navigation.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Declaration =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Declaration",
               Description => "Open the declaration target for the selected Outline symbol.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Body =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Body",
               Description => "Open the body target for the selected Outline symbol when available.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Goto_Spec =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Go to Spec",
               Description => "Open the spec target for the selected Outline symbol when available.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Semantic_Refresh_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh Semantic Colouring",
               Description => "Refresh Ada semantic colouring data for the active buffer.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Semantic_Refresh_Project_Index =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Refresh Semantic Project Index",
               Description => "Refresh known project Ada source files in the language index and update semantic colouring for the active buffer.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Language_Index_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Language Index",
               Description => "Clear the Ada language index without changing files or buffers.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Language_Index_Status =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Language Index Status",
               Description => "Show the Ada language index file count, symbol count, overflow state, and fingerprint.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Outline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Outline",
               Description => "Clear Outline rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Show_Outline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Outline",
               Description => "Show the Outline panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Outline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Outline",
               Description => "Move focus to the Outline panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Open_Selected_Outline_Item =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Outline Item",
               Description => "Open the selected Outline item.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Select_Current_Outline_Symbol =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Current Outline Symbol",
               Description => "Select the current outline symbol tracked from the active editor cursor.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Reveal_Current_Outline_Symbol =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Reveal Current Outline Symbol",
               Description => "Reveal and select the current outline symbol without moving the editor cursor.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Next_Outline_Symbol =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Outline Symbol",
               Description => "Move the editor caret to the next Outline symbol.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Previous_Outline_Symbol =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Outline Symbol",
               Description => "Move the editor caret to the previous Outline symbol.",
               Category    => Navigation_Category,
               Visibility  => Palette_Command);
         when Command_Select_Next_Outline_Item =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Next Outline Symbol",
               Description => "Move outline selection to the next selectable symbol row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Select_Previous_Outline_Item =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Previous Outline Symbol",
               Description => "Move outline selection to the previous selectable symbol row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Focus_Outline_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Outline Filter",
               Description => "Focus the Outline filter input.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Filter_Outline =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Filter Outline Symbols",
               Description => "Apply the Outline filter to the active buffer.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Outline_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Outline Filter",
               Description => "Clear the Outline filter and show all Outline items.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Outline_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Outline Filter",
               Description => "Toggle focus for the local outline filter input.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Outline_Filter_History_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Outline: Previous Filter",
               Description => "Replace the active outline filter with the previous session-local filter history entry.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Outline_Filter_History_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Outline: Next Filter",
               Description => "Replace the active outline filter with the next session-local filter history entry.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Outline_Filter_History =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Outline Filter History",
               Description => "Clear session-local outline filter history without changing accepted outline rows.",
               Category    => Panel_Category,
               Visibility  => Hidden_Command);
         when Command_Show_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Show Panel",
               Description => "Show the session-local Messages feature panel without diagnostics, LSP, search, persistence, or background collection.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear",
               Description => "Clear session-local Messages rows without mutating outline state.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Search_Active_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Search Active Buffer",
               Description => "Search the current active buffer snapshot with the current literal search query and replace Search Results rows.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Focus_Query =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Search Query",
               Description => "Focus the session-local Search Results query input without mutating editor text.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Repeat_Active_Buffer =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Repeat Active Buffer Search",
               Description => "Rerun the last literal Search Results query against the current active buffer.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Query_History_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Previous Search Query",
               Description => "Move the active Search Results query input to the previous session-local query.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Query_History_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Next Search Query",
               Description => "Move the active Search Results query input to the next session-local query.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Search_Results_Toggle_Case_Sensitive =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Search Case Sensitivity",
               Description => "Toggle literal Search Results case sensitivity without adding regex or fuzzy behavior.",
               Category    => Search_Category,
               Visibility  => Palette_Command);
         when Command_Show_Search_Results_Feature =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Project Search Results",
               Description => "Show Project Search Results without running a new search.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Search_Results_Feature =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Project Search Results",
               Description => "Clear Project Search Results without changing files, Outline, or Messages.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Diagnostics",
               Description => "Show the current Diagnostics panel without scanning, background collection, or changing editor text.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Diagnostics",
               Description => "Clear session-local Diagnostics rows without mutating Outline, Messages, or Search Results.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Info =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Info Diagnostics",
               Description => "Show or hide informational Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Warnings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Warning Diagnostics",
               Description => "Show or hide warning Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Errors =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Error Diagnostics",
               Description => "Show or hide error Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Show_All =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show All Diagnostics",
               Description => "Clear Diagnostics filtering and restore all severity and source visibility flags.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Diagnostics Filter",
               Description => "Clear Diagnostics filtering and restore all severity and source visibility flags.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Filter_Errors =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Error Diagnostics",
               Description => "Show only error Diagnostics rows without deleting rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Filter_Warnings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Warning Diagnostics",
               Description => "Show only warning Diagnostics rows without deleting rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Filter_Info_Notes =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Info and Note Diagnostics",
               Description => "Show only informational Diagnostics rows without deleting rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Filter_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Diagnostics from Selected Source",
               Description => "Show only Diagnostics rows from the selected diagnostic source.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Filter_Build =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Build Diagnostics",
               Description => "Show Diagnostics reported by the last build.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Build =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Build Diagnostics",
               Description => "Clear only build-produced Diagnostics rows without mutating Build result or output details.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Open_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Open Selected Diagnostic",
               Description => "Open the file location for the selected Diagnostic when available.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Select_Next =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Next Diagnostic",
               Description => "Move selection to the next visible Diagnostics row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Select_Previous =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Select Previous Diagnostic",
               Description => "Move selection to the previous visible Diagnostics row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Selected =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Selected Diagnostic",
               Description => "Clear the selected Diagnostic.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Copy_Selected_Text =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Copy Selected Diagnostic Text",
               Description => "Copy deterministic text for the selected Diagnostics row.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Info =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Info Diagnostics",
               Description => "Clear info Diagnostics rows while preserving filters and other severities.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Warnings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Warning Diagnostics",
               Description => "Clear warning Diagnostics rows while preserving filters and other severities.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Clear_Errors =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Clear Error Diagnostics",
               Description => "Clear error Diagnostics rows while preserving filters and other severities.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Editor_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Editor Diagnostics",
               Description => "Show or hide editor Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_File_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle File Diagnostics",
               Description => "Show or hide file Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Project_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Project Diagnostics",
               Description => "Show or hide project Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_External_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle External Diagnostics",
               Description => "Show or hide external Diagnostics rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Diagnostics_Toggle_Unknown_Source =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Unknown Diagnostics",
               Description => "Show or hide Diagnostics rows from unknown sources.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Selected_Message =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear Selected",
               Description => "Clear the selected session-local Messages row by stable Message_Id.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Copy_Selected_Message_Text =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Copy Selected Text",
               Description => "Copy deterministic selected Messages row text without exposing internal ids.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Info_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear Info",
               Description => "Clear informational Messages rows while preserving filters and warnings/errors.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Warning_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear Warnings",
               Description => "Clear warning Messages rows while preserving filters and info/errors.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Error_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear Errors",
               Description => "Clear error Messages rows while preserving filters and info/warnings.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Message_Info =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Toggle Info",
               Description => "Toggle visibility for informational Messages rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Message_Warnings =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Toggle Warnings",
               Description => "Toggle visibility for warning Messages rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Toggle_Message_Errors =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Toggle Errors",
               Description => "Toggle visibility for error Messages rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Show_All_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Show All Messages",
               Description => "Clear Messages filters and show all session-local Messages rows.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Clear_Message_Filter =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Messages: Clear Filter",
               Description => "Clear Messages filter text and restore all severities.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Dismiss_Latest_Message =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Dismiss Latest Message",
               Description => "Dismiss the most recent message.",
               Category    => Message_Category,
               Visibility  => Hidden_Command);
         when Command_Dismiss_All_Messages =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Dismiss All Messages",
               Description => "Dismiss all messages.",
               Category    => Message_Category,
               Visibility  => Palette_Command);
         when Command_Build_UI_Toggle =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Toggle Build Output",
               Description => "Show or hide the build output panel without refreshing candidates or running a build.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_UI_Show =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Show Build Output",
               Description => "Show the current build output without starting a new build.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_UI_Hide =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Hide Build Output",
               Description => "Hide the build output panel.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_UI_Focus =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Focus Build Output",
               Description => "Show and focus the build output panel without changing request, candidate, or confirmation state.",
               Category    => Panel_Category,
               Visibility  => Palette_Command);
         when Command_Build_Select_Next_Candidate =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Select Next Candidate",
               Description => "Select the next discovered build candidate without starting a build.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Select_Previous_Candidate =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Select Previous Candidate",
               Description => "Select the previous discovered build candidate without starting a build.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Clear_Selected_Candidate =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Clear Selected Candidate",
               Description => "Clear the selected build candidate and require confirmation before the next run.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Set_Mode_Default =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Set Mode Default",
               Description => "Set the build mode to the default profile.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Set_Mode_Debug =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Set Mode Debug",
               Description => "Set the selected GPRbuild candidate to the debug profile (-g).",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Set_Mode_Release =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Set Mode Release",
               Description => "Set the selected GPRbuild candidate to the release profile (-O2 -gnatp).",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Set_Mode_Validation =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Set Mode Validation",
               Description => "Set the selected GPRbuild candidate to the validation profile (-gnata -gnatwa).",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Toggle_Diagnostics_Ingestion =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Toggle Diagnostics Ingestion",
               Description => "Toggle whether build results update Diagnostics after the next run.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Cycle_Output_Limit =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Cycle Output Capture Limit",
               Description => "Cycle the build output capture limit.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Toggle_Option_Verbose =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Toggle Verbose Output",
               Description => "Toggle the fixed verbose-output request option where supported by the selected candidate.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Toggle_Option_Keep_Going =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Toggle Keep Going",
               Description => "Toggle the fixed keep-going request option where supported by the selected candidate.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Acknowledge_Consent =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Acknowledge Consent",
               Description => "Confirm the current build request before running it.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Clear_Consent =>
            return Make_Descriptor
              (Id          => Id,
               Name        => "Build: Clear Consent",
               Description => "Clear build confirmation without changing candidates or request options.",
               Category    => Project_Category,
               Visibility  => Palette_Command);
         when Command_Build_Cancel =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Cancel Build",
                  Description => "Request cancellation of the currently active build job.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Build_Run =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Run Build",
                  Description => "Run the currently selected build request after explicit confirmation.",
                  Category    => Project_Category,
                  Visibility  => Palette_Command);
            begin
               D.Bindable := False;
               return D;
            end;
         when Command_Build_Run_User_Opt_In_Test_Seam =>
            declare
               D : Command_Descriptor := Make_Descriptor
                 (Id          => Id,
                  Name        => "Build: Run User Opt-In Test Command",
                  Description => "Internal test-only command for structured user opt-in build command validation.",
                  Category    => Internal_Category,
                  Visibility  => Hidden_Command);
            begin
               D.Bindable := False;
               return D;
            end;
      end case;
   end Descriptor;

   function Label
     (Id : Command_Id) return String
   is
   begin
      return To_String (Descriptor (Id).Name);
   end Label;

   function Category
     (Id : Command_Id) return Command_Category
   is
   begin
      return Descriptor (Id).Category;
   end Category;

   function Category_Label
     (Category : Command_Category) return String
   is
   begin
      case Category is
         when File_Category =>
            return "File";
         when Project_Category =>
            return "Project";
         when Edit_Category =>
            return "Edit";
         when Selection_Category =>
            return "Selection";
         when Navigation_Category =>
            return "Navigation";
         when Search_Category =>
            return "Search";
         when Panel_Category =>
            return "Panels";
         when View_Category =>
            return "View";
         when Diagnostics_Category =>
            return "Diagnostics";
         when Bookmarks_Category =>
            return "Bookmarks";
         when Overlay_Category =>
            return "Overlays";
         when Message_Category =>
            return "Messages";
         when Theme_Category =>
            return "Theme";
         when Settings_Category =>
            return "Settings";
         when Workspace_Category =>
            return "Workspace";
         when Internal_Category =>
            return "Internal";
      end case;
   end Category_Label;

   function Discoverability_Category_Label
     (Id : Command_Id) return String
   is
      Stable : constant String := Stable_Command_Name (Id);
   begin
      if Ada.Strings.Fixed.Index (Stable, "build.") = Stable'First then
         return "Build";
      elsif Ada.Strings.Fixed.Index (Stable, "recent-projects.") = Stable'First then
         return "Recent Projects";
      elsif Ada.Strings.Fixed.Index (Stable, "file-tree.") = Stable'First then
         return "File Tree";
      elsif Ada.Strings.Fixed.Index (Stable, "outline.") = Stable'First then
         return "Outline";
      elsif Ada.Strings.Fixed.Index (Stable, "semantic.") = Stable'First
        or else Ada.Strings.Fixed.Index (Stable, "language.index.") = Stable'First
      then
         return "Language";
      elsif Ada.Strings.Fixed.Index (Stable, "buffer-switcher.") = Stable'First
        or else Stable = "switch-buffer"
      then
         return "Buffers";
      elsif Ada.Strings.Fixed.Index (Stable, "keybindings.") = Stable'First
        or else Ada.Strings.Fixed.Index (Stable, "keybinding.") = Stable'First
      then
         return "Keybindings";
      elsif Ada.Strings.Fixed.Index (Stable, "command-palette.") = Stable'First
        or else Stable = "open-command-palette"
      then
         return "Command Palette";
      else
         return Category_Label (Descriptor (Id).Category);
      end if;
   end Discoverability_Category_Label;

   function Classification_Label
     (Id : Command_Id) return String
   is
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Add (Text : String) is
      begin
         if Length (Result) > 0 then
            Result := Result & ", ";
         end if;
         Result := Result & Text;
      end Add;
   begin
      if Is_Destructive_Command (Id) then
         Add ("destructive");
      end if;
      if Is_Lifecycle_Command (Id) then
         Add ("lifecycle");
      end if;
      if Is_Configuration_Command (Id) then
         Add ("configuration");
      end if;
      if Is_Navigation_Command (Id) then
         Add ("navigation");
      end if;
      if Is_Search_Command (Id) then
         Add ("search");
      end if;
      if Is_Panel_Focus_Command (Id) then
         Add ("panel");
      end if;
      if Is_Text_Editing_Command (Id) then
         Add ("editing");
      end if;
      if Descriptor (Id).Visibility = Hidden_Command
        or else Descriptor (Id).Category = Internal_Category
      then
         Add ("internal");
      end if;
      if not Is_Bindable_Command (Id) then
         Add ("non-bindable");
      end if;
      if Length (Result) = 0 then
         Add ("command");
      end if;
      return To_String (Result);
   end Classification_Label;

   function Surface_Relevance_Label
     (Id : Command_Id) return String
   is
      Stable : constant String := Stable_Command_Name (Id);
   begin
      if Stable'Length = 0 then
         return "";
      elsif Ada.Strings.Fixed.Index (Stable, "file-tree.") = Stable'First then
         return "File Tree";
      elsif Ada.Strings.Fixed.Index (Stable, "diagnostics.") = Stable'First
        or else Ada.Strings.Fixed.Index (Stable, "problems.") = Stable'First
      then
         return "Diagnostics";
      elsif Ada.Strings.Fixed.Index (Stable, "build.") = Stable'First then
         return "Build";
      elsif Ada.Strings.Fixed.Index (Stable, "project-search.") = Stable'First
        or else Ada.Strings.Fixed.Index (Stable, "search-results.") = Stable'First
      then
         return "Project Search";
      elsif Ada.Strings.Fixed.Index (Stable, "outline.") = Stable'First then
         return "Outline";
      elsif Ada.Strings.Fixed.Index (Stable, "semantic.") = Stable'First
        or else Ada.Strings.Fixed.Index (Stable, "language.index.") = Stable'First
      then
         return "Language";
      elsif Ada.Strings.Fixed.Index (Stable, "quick-open.") = Stable'First then
         return "Quick Open";
      elsif Ada.Strings.Fixed.Index (Stable, "recent-projects.") = Stable'First then
         return "Recent Projects";
      elsif Ada.Strings.Fixed.Index (Stable, "buffer-switcher.") = Stable'First
        or else Stable = "switch-buffer"
      then
         return "Buffers";
      elsif Ada.Strings.Fixed.Index (Stable, "command-palette.") = Stable'First
        or else Stable = "open-command-palette"
      then
         return "Command Palette";
      elsif Ada.Strings.Fixed.Index (Stable, "keybindings.") = Stable'First
        or else Stable = "keybinding.validate"
      then
         return "Keybindings";
      else
         return "";
      end if;
   end Surface_Relevance_Label;

   function Guard_Label
     (Id : Command_Id) return String
   is
      Result : Unbounded_String := Null_Unbounded_String;

      procedure Add (Text : String) is
      begin
         if Length (Result) > 0 then
            Result := Result & ", ";
         end if;
         Result := Result & Text;
      end Add;
   begin
      if Is_Destructive_Command (Id) then
         Add ("confirmation and dirty-file protection retained");
      end if;
      if Is_Lifecycle_Command (Id) then
         Add ("project/file safety protection retained");
      end if;
      if Is_Configuration_Command (Id) then
         Add ("configuration safety check retained");
      end if;
      if not Is_Bindable_Command (Id) then
         Add ("not keybindable");
      end if;
      if Length (Result) = 0 then
         Add ("no special safety check");
      end if;
      return To_String (Result);
   end Guard_Label;

   function Has_Discoverability_Metadata
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
      Stable : constant String := Stable_Command_Name (Id);
      Title : constant String := To_String (D.Name);
      Description_Text : constant String := To_String (D.Description);
      Category_Text : constant String := Discoverability_Category_Label (Id);
      Class_Text : constant String := Classification_Label (Id);
   begin
      if not Is_Concrete_Command (Id) then
         return False;
      end if;

      if D.Id /= Id then
         return False;
      end if;

      if Stable'Length = 0
        or else Ada.Strings.Fixed.Trim (Stable, Ada.Strings.Both) /= Stable
      then
         return False;
      end if;

      if D.Visibility = Hidden_Command then
         --  Hidden/internal descriptors are allowed to be minimal, but they
         --  must never leak into the normal palette and must still retain a
         --  stable command identity for command/keybinding routing checks.
         return not Visible_In_Command_Palette (Id);
      end if;

      if Title'Length = 0
        or else Ada.Strings.Fixed.Trim (Title, Ada.Strings.Both) /= Title
        or else Description_Text'Length = 0
        or else Ada.Strings.Fixed.Trim (Description_Text, Ada.Strings.Both) /= Description_Text
        or else Category_Text'Length = 0
        or else Ada.Strings.Fixed.Trim (Category_Text, Ada.Strings.Both) /= Category_Text
        or else Class_Text'Length = 0
        or else Ada.Strings.Fixed.Trim (Class_Text, Ada.Strings.Both) /= Class_Text
      then
         return False;
      end if;

      if D.Category = Internal_Category then
         return False;
      end if;

      return True;
   end Has_Discoverability_Metadata;

   function Command_Discoverability_Coherent return Boolean
   is
   begin
      for Id in Command_Id loop
         if Is_Concrete_Command (Id) then
            if not Has_Discoverability_Metadata (Id) then
               return False;
            end if;

            if Is_Internal_Command (Id) and then Visible_In_Command_Palette (Id) then
               return False;
            end if;
         end if;
      end loop;

      return True;
   end Command_Discoverability_Coherent;

   function First_Command return Command_Id
   is
   begin
      return Command_Id'First;
   end First_Command;

   function Last_Command return Command_Id
   is
   begin
      return Command_Id'Last;
   end Last_Command;

   function Next_Command
     (Id    : Command_Id;
      Found : out Boolean) return Command_Id
   is
   begin
      if Id = Command_Id'Last then
         Found := False;
         return No_Command;
      end if;

      Found := True;
      return Command_Id'Succ (Id);
   end Next_Command;

   function First_Concrete_Command return Command_Id
   is
   begin
      return Command_Id'Succ (No_Command);
   end First_Concrete_Command;

   function Concrete_Command_Count return Natural
   is
   begin
      return Command_Count - 1;
   end Concrete_Command_Count;

   procedure For_Each_Command
     (Process : not null access procedure (Id : Command_Id))
   is
   begin
      for Id in Command_Id loop
         if Is_Concrete_Command (Id) then
            Process (Id);
         end if;
      end loop;
   end For_Each_Command;

   function Is_Valid_Command
     (Id : Command_Id) return Boolean
   is
      pragma Unreferenced (Id);
   begin
      return True;
   end Is_Valid_Command;

   function Trimmed
     (Text : String) return String
   is
   begin
      return Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both);
   end Trimmed;

   function Is_Placeholder_Label
     (Text : String) return Boolean
   is
      T : constant String := Trimmed (Text);
   begin
      return T = "TODO"
        or else T = "Command"
        or else T = "Unnamed";
   end Is_Placeholder_Label;

   function Has_Stable_User_Label
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
      L : constant String := To_String (D.Name);
   begin
      return Id /= No_Command
        and then D.Id = Id
        and then L'Length > 0
        and then Trimmed (L) = L
        and then not Is_Placeholder_Label (L);
   end Has_Stable_User_Label;

   function Requires_Context
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when No_Command
            | Command_Close_Goto_Line
            | Command_Accept_Goto_Line
            | Command_Goto_Line_Query_Set
            | Command_Goto_Line_Query_Clear
            | Command_Find_Hide
            | Command_Find_Query_Set
            | Command_Find_Query_Clear
            | Command_Replace_Hide
            | Command_Replace_Text_Set
            | Command_Replace_Text_Clear
            | Command_Replace_Current
            | Command_Replace_All
            | Command_Close_Buffer_Switcher
            | Command_Accept_Buffer_Switcher
            | Command_Buffer_Switcher_Next_Result
            | Command_Buffer_Switcher_Previous_Result
            | Command_Buffer_Switcher_Filter_Group
            | Command_Buffer_Switcher_Filter_Label
            | Command_Buffer_Switcher_Selected_Group_Assign
            | Command_Buffer_Switcher_Selected_Label_Set
            | Command_Buffer_Switcher_Selected_Note_Set
            | Command_Buffer_Switcher_Mark_Group
            | Command_Buffer_Switcher_Mark_Label
            | Command_Buffer_Switcher_Mark_Group_Assign
            | Command_Buffer_Switcher_Mark_Label_Set
            | Command_Buffer_Switcher_Mark_Note_Set
            | Command_Buffer_Switcher_Mark_Review_Toggle
            | Command_Buffer_Switcher_Mark_Review_Show
            | Command_Buffer_Switcher_Mark_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Review_Toggle
            | Command_Buffer_Switcher_Pending_Mark_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Next
            | Command_Buffer_Switcher_Pending_Mark_Previous
            | Command_Buffer_Switcher_Pending_Mark_Summary
            | Command_Buffer_Switcher_Pending_Mark_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Summary
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Next
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Previous
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Toggle
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Stale_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary
            | Command_Buffer_Switcher_Mark_Next
            | Command_Buffer_Switcher_Mark_Previous
            | Command_Buffer_Switcher_Mark_Summary
            | Command_Build_Run_User_Opt_In_Test_Seam
            | Command_Build_Cancel
            | Command_Open_File
            | Command_Open_Project
            | Command_Switch_Project
            | Command_Save_File_As
            | Command_Rename_Buffer_File
            | Command_Delete_Buffer_File
            | Command_Copy_Buffer_File
            | Command_Move_Buffer_File
            | Command_Switch_Buffer
            | Command_Run_Project_Search
            | Command_Toggle_Project_Search_Bar
            | Command_Open_Selected_Project_Search_Result
            | Command_Search_Results_Open_Selected
            | Command_Problems_Open_Selected
            | Command_File_Tree_Open_Selected
            | Command_File_Tree_Create_File
            | Command_File_Tree_Create_Directory
            | Command_File_Tree_Rename_Selected
            | Command_File_Tree_Delete_Selected
            | Command_File_Tree_Expand_Selected
            | Command_File_Tree_Collapse_Selected
            | Command_File_Tree_Toggle_Selected
            | Command_File_Tree_Collapse_All
            | Command_File_Tree_Expand_To_Active_File
            | Command_Toggle_Feature_Panel
            | Command_Show_Feature_Panel
            | Command_Hide_Feature_Panel
            | Command_Focus_Feature_Panel
            | Command_Clear_Feature_Panel
            | Command_Feature_Panel_Select_Next
            | Command_Feature_Panel_Select_Previous
            | Command_Feature_Panel_Open_Selected
            | Command_Refresh_Outline
            | Command_Refresh_Outline_Project_Index
            | Command_Goto_Declaration
            | Command_Goto_Body
            | Command_Goto_Spec
            | Command_Semantic_Refresh_Buffer
            | Command_Semantic_Refresh_Project_Index
            | Command_Language_Index_Clear
            | Command_Language_Index_Status
            | Command_Clear_Outline
            | Command_Show_Outline
            | Command_Focus_Outline
            | Command_Open_Selected_Outline_Item
            | Command_Select_Current_Outline_Symbol
            | Command_Reveal_Current_Outline_Symbol
            | Command_Next_Outline_Symbol
            | Command_Previous_Outline_Symbol
            | Command_Select_Next_Outline_Item
            | Command_Select_Previous_Outline_Item
            | Command_Focus_Outline_Filter
            | Command_Filter_Outline
            | Command_Clear_Outline_Filter
            | Command_Toggle_Outline_Filter
            | Command_Outline_Filter_History_Previous
            | Command_Outline_Filter_History_Next
            | Command_Clear_Outline_Filter_History
            | Command_Show_Messages
            | Command_Clear_Messages
            | Command_Search_Results_Search_Active_Buffer
            | Command_Search_Results_Focus_Query
            | Command_Search_Results_Repeat_Active_Buffer
            | Command_Search_Results_Query_History_Previous
            | Command_Search_Results_Query_History_Next
            | Command_Search_Results_Toggle_Case_Sensitive
            | Command_Show_Search_Results_Feature
            | Command_Clear_Search_Results_Feature
            | Command_Diagnostics_Show
            | Command_Diagnostics_Clear
            | Command_Diagnostics_Toggle_Info
            | Command_Diagnostics_Toggle_Warnings
            | Command_Diagnostics_Toggle_Errors
            | Command_Diagnostics_Show_All
            | Command_Diagnostics_Clear_Filter
            | Command_Diagnostics_Filter_Errors
            | Command_Diagnostics_Filter_Warnings
            | Command_Diagnostics_Filter_Info_Notes
            | Command_Diagnostics_Filter_Source
            | Command_Diagnostics_Filter_Build
            | Command_Diagnostics_Clear_Build
            | Command_Diagnostics_Open_Selected
            | Command_Diagnostics_Select_Next
            | Command_Diagnostics_Select_Previous
            | Command_Diagnostics_Clear_Selected
            | Command_Diagnostics_Copy_Selected_Text
            | Command_Diagnostics_Clear_Info
            | Command_Diagnostics_Clear_Warnings
            | Command_Diagnostics_Clear_Errors
            | Command_Diagnostics_Toggle_Editor_Source
            | Command_Diagnostics_Toggle_File_Source
            | Command_Diagnostics_Toggle_Project_Source
            | Command_Diagnostics_Toggle_External_Source
            | Command_Diagnostics_Toggle_Unknown_Source
            | Command_Clear_Selected_Message
            | Command_Copy_Selected_Message_Text
            | Command_Clear_Info_Messages
            | Command_Clear_Warning_Messages
            | Command_Clear_Error_Messages
            | Command_Toggle_Message_Info
            | Command_Toggle_Message_Warnings
            | Command_Toggle_Message_Errors
            | Command_Show_All_Messages
            | Command_Clear_Message_Filter =>
            return True;
         when others =>
            return False;
      end case;
   end Requires_Context;

   function Is_Concrete_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id /= No_Command;
   end Is_Concrete_Command;

   function Is_Public_Build_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id in Command_Build_Run
        | Command_Build_Cancel
        | Command_Build_Select_Next_Candidate
        | Command_Build_Select_Previous_Candidate
        | Command_Build_Clear_Selected_Candidate
        | Command_Build_Set_Mode_Default
        | Command_Build_Set_Mode_Debug
        | Command_Build_Set_Mode_Release
        | Command_Build_Set_Mode_Validation
        | Command_Build_Toggle_Diagnostics_Ingestion
        | Command_Build_Cycle_Output_Limit
        | Command_Build_Toggle_Option_Verbose
        | Command_Build_Toggle_Option_Keep_Going
        | Command_Build_Acknowledge_Consent
        | Command_Build_Clear_Consent;
   end Is_Public_Build_Command;

   function Is_Internal_Build_Test_Seam_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id = Command_Build_Run_User_Opt_In_Test_Seam;
   end Is_Internal_Build_Test_Seam_Command;

   function Is_Test_Only_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Is_Internal_Build_Test_Seam_Command (Id);
   end Is_Test_Only_Command;

   function Is_Destructive_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Clear_Workspace_State
            | Command_Clear_Recent_Projects
            | Command_Remove_Selected_Recent_Project
            | Command_Remove_Missing_Recent_Projects
            | Command_Reset_Settings_To_Defaults
            | Command_Keybindings_Reset_To_Defaults
            | Command_Close_Project
            | Command_Close_Active_Buffer
            | Command_Confirm_Close_Save
            | Command_Confirm_Close_Discard
            | Command_Revert_Active_Buffer
            | Command_Delete_Buffer_File
            | Command_File_Tree_Delete_Selected
            | Command_Close_Other_Buffers
            | Command_Close_All_Buffers
            | Command_Close_All_Clean_Buffers
            | Command_Clear_Project
            | Command_Clear_Bookmarks
            | Command_Clear_All_Bookmarks
            | Command_Bookmark_Clear_All
            | Command_Clear_Project_Search
            | Command_File_Conflict_Reload_From_Disk
            | Command_File_Conflict_Overwrite_Disk
            | Command_Buffer_Switcher_Selected_Close =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Destructive_Command;

   function Is_Lifecycle_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Open_Project
            | Command_Switch_Project
            | Command_Open_Selected_Recent_Project
            | Command_Close_Project
            | Command_Clear_Project
            | Command_Save_Workspace_State
            | Command_Restore_Workspace_State
            | Command_Clear_Workspace_State
            | Command_Close_Active_Buffer
            | Command_Confirm_Close_Save
            | Command_Confirm_Close_Discard
            | Command_Cancel_Close
            | Command_Reopen_Closed_Buffer
            | Command_Close_Other_Buffers
            | Command_Close_All_Buffers
            | Command_Close_All_Clean_Buffers
            | Command_Pin_Buffer
            | Command_Unpin_Buffer
            | Command_Toggle_Buffer_Pin
            | Command_Set_Buffer_Label
            | Command_Clear_Buffer_Label
            | Command_Edit_Buffer_Label
            | Command_Show_Buffer_Label
            | Command_Set_Buffer_Note
            | Command_Clear_Buffer_Note
            | Command_Edit_Buffer_Note
            | Command_Show_Buffer_Note
            | Command_Assign_Buffer_Group
            | Command_Clear_Buffer_Group
            | Command_Switch_Buffer_Group
            | Command_Next_Buffer_Group
            | Command_Previous_Buffer_Group
            | Command_Show_All_Buffer_Groups
            | Command_Reload_Active_Buffer
            | Command_Revert_Active_Buffer
            | Command_File_Conflict_Keep_Buffer
            | Command_File_Conflict_Reload_From_Disk
            | Command_File_Conflict_Overwrite_Disk
            | Command_File_Conflict_Cancel
            | Command_Rename_Buffer_File
            | Command_Delete_Buffer_File
            | Command_Copy_Buffer_File
            | Command_Move_Buffer_File
            | Command_File_Tree_Create_File
            | Command_File_Tree_Create_Directory
            | Command_File_Tree_Rename_Selected
            | Command_File_Tree_Delete_Selected
            | Command_New_Buffer
            | Command_Switch_Buffer
            | Command_Next_Buffer
            | Command_Previous_Buffer
            | Command_Previous_Recent_Buffer
            | Command_Next_Recent_Buffer
            | Command_Cancel_Pending_Transition
            | Command_Retry_Pending_Transition
            | Command_Discard_Pending_Transition
            | Command_Show_Recent_Projects
            | Command_Clear_Recent_Projects
            | Command_Remove_Selected_Recent_Project
            | Command_Remove_Missing_Recent_Projects
            | Command_Select_Next_Recent_Project
            | Command_Select_Previous_Recent_Project
            | Command_Buffer_Switcher_Selected_Close
            | Command_Buffer_Switcher_Selected_Pin
            | Command_Buffer_Switcher_Selected_Unpin
            | Command_Buffer_Switcher_Selected_Toggle_Pin
            | Command_Buffer_Switcher_Selected_Group_Assign
            | Command_Buffer_Switcher_Selected_Group_Clear
            | Command_Buffer_Switcher_Selected_Label_Set
            | Command_Buffer_Switcher_Selected_Label_Clear
            | Command_Buffer_Switcher_Selected_Note_Set
            | Command_Buffer_Switcher_Selected_Note_Clear
            | Command_Buffer_Switcher_Mark_Confirm
            | Command_Accept_Quick_Open
            | Command_Quick_Open_Create_From_Query
            | Command_Quick_Open_Create_With_Parents_From_Query =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Lifecycle_Command;

   function Is_Configuration_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Save_Settings
            | Command_Reload_Settings
            | Command_Reset_Settings_To_Defaults
            | Command_Save_Keybindings
            | Command_Reload_Keybindings
            | Command_Validate_Keybindings
            | Command_Keybindings_Show
            | Command_Keybindings_Focus
            | Command_Keybindings_Assign_Selected
            | Command_Keybindings_Remove_Selected
            | Command_Keybindings_Reset_To_Defaults
            | Command_Keybindings_Filter_Conflicts
            | Command_Keybindings_Filter_Unbound
            | Command_Keybindings_Clear_Filter
            | Command_Keybindings_Cancel_Capture
            | Command_Startup_Show_Summary
            | Command_Configuration_Recover_Show
            | Command_Configuration_Audit
            | Command_Configuration_Reset_Settings
            | Command_Configuration_Reset_Keybindings
            | Command_Configuration_Reset_Workspace
            | Command_Configuration_Reset_Recent_Projects
            | Command_Configuration_Reset_All
            | Command_Configuration_Reset_All_Confirm
            | Command_Configuration_Reset_All_Cancel
            | Command_Configuration_Save_Clean_Settings
            | Command_Configuration_Save_Clean_Keybindings
            | Command_Configuration_Save_Clean_Workspace
            | Command_Configuration_Save_Clean_Recent_Projects
            | Command_Toggle_Theme
            | Command_Set_Theme_Light
            | Command_Set_Theme_Dark
            | Command_Toggle_Minimap
            | Command_Toggle_Scrollbars
            | Command_Toggle_Line_Numbers
            | Command_Toggle_Line_Number_Mode
            | Command_Set_Absolute_Line_Numbers
            | Command_Set_Relative_Line_Numbers
            | Command_Set_Hybrid_Line_Numbers
            | Command_Toggle_Current_Line_Highlight
            | Command_Toggle_Cursor_Blink
            | Command_Toggle_Syntax_Colouring
            | Command_Toggle_Diagnostics
            | Command_Toggle_Cursor_Style =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Configuration_Command;

   function Is_File_Content_Save_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Save_File
            | Command_Save_File_As
            | Command_Save_All =>
            return True;
         when others =>
            return False;
      end case;
   end Is_File_Content_Save_Command;

   function Is_Workspace_Structural_Save_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id = Command_Save_Workspace_State;
   end Is_Workspace_Structural_Save_Command;

   function Is_Global_Settings_Save_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id = Command_Save_Settings;
   end Is_Global_Settings_Save_Command;

   function Is_Global_Keybindings_Save_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Id = Command_Save_Keybindings;
   end Is_Global_Keybindings_Save_Command;

   function Is_Navigation_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Move_Left
            | Command_Move_Right
            | Command_Move_Up
            | Command_Move_Down
            | Command_Move_Line_Start
            | Command_Move_Line_End
            | Command_Move_Document_Start
            | Command_Move_Document_End
            | Command_Move_Word_Left
            | Command_Move_Word_Right
            | Command_Page_Up
            | Command_Page_Down
            | Command_Goto_Start
            | Command_Goto_End
            | Command_Goto_Line
            | Command_Goto_Line_Toggle
            | Command_Goto_Line_Prefill_Current
            | Command_Goto_Line_Query_Set
            | Command_Goto_Line_Query_Clear
            | Command_Active_Find_Next
            | Command_Active_Find_Previous
            | Command_Find_First
            | Command_Find_Last
            | Command_Open_Buffer_Switcher
            | Command_Close_Buffer_Switcher
            | Command_Accept_Buffer_Switcher
            | Command_Buffer_Switcher_Next_Result
            | Command_Buffer_Switcher_Previous_Result
            | Command_Buffer_Switcher_Filter_Clear
            | Command_Buffer_Switcher_Filter_Pinned
            | Command_Buffer_Switcher_Filter_Group
            | Command_Buffer_Switcher_Filter_Label
            | Command_Buffer_Switcher_Filter_Noted
            | Command_Buffer_Switcher_Sort_Default
            | Command_Buffer_Switcher_Sort_Recent
            | Command_Buffer_Switcher_Sort_Name
            | Command_Buffer_Switcher_Sort_Pinned
            | Command_Buffer_Switcher_Sort_Group
            | Command_Buffer_Switcher_Sort_Label
            | Command_Buffer_Switcher_Sort_Next
            | Command_Buffer_Switcher_Sort_Previous
            | Command_Buffer_Switcher_Selected_Close
            | Command_Buffer_Switcher_Selected_Pin
            | Command_Buffer_Switcher_Selected_Unpin
            | Command_Buffer_Switcher_Selected_Toggle_Pin
            | Command_Buffer_Switcher_Selected_Group_Assign
            | Command_Buffer_Switcher_Selected_Group_Clear
            | Command_Buffer_Switcher_Selected_Label_Set
            | Command_Buffer_Switcher_Selected_Label_Clear
            | Command_Buffer_Switcher_Selected_Note_Set
            | Command_Buffer_Switcher_Selected_Note_Clear
            | Command_Buffer_Switcher_Preview_Toggle
            | Command_Buffer_Switcher_Preview_Show
            | Command_Buffer_Switcher_Preview_Hide
            | Command_Buffer_Switcher_Preview_Next_Line
            | Command_Buffer_Switcher_Preview_Previous_Line
            | Command_Buffer_Switcher_Preview_Center_Cursor
            | Command_Buffer_Switcher_Mark_Toggle
            | Command_Buffer_Switcher_Mark_Set
            | Command_Buffer_Switcher_Mark_Clear
            | Command_Buffer_Switcher_Mark_Clear_All
            | Command_Buffer_Switcher_Mark_Invert_Visible
            | Command_Buffer_Switcher_Mark_Visible
            | Command_Buffer_Switcher_Mark_Clear_Visible
            | Command_Buffer_Switcher_Mark_Pinned
            | Command_Buffer_Switcher_Mark_Group
            | Command_Buffer_Switcher_Mark_Label
            | Command_Buffer_Switcher_Mark_Noted
            | Command_Buffer_Switcher_Mark_Close_Marked
            | Command_Buffer_Switcher_Mark_Confirm
            | Command_Buffer_Switcher_Mark_Cancel
            | Command_Buffer_Switcher_Mark_Pin_Marked
            | Command_Buffer_Switcher_Mark_Unpin_Marked
            | Command_Buffer_Switcher_Mark_Clear_Metadata
            | Command_Buffer_Switcher_Mark_Group_Assign
            | Command_Buffer_Switcher_Mark_Group_Clear
            | Command_Buffer_Switcher_Mark_Label_Set
            | Command_Buffer_Switcher_Mark_Label_Clear
            | Command_Buffer_Switcher_Mark_Note_Set
            | Command_Buffer_Switcher_Mark_Note_Clear
            | Command_Buffer_Switcher_Mark_Review_Toggle
            | Command_Buffer_Switcher_Mark_Review_Show
            | Command_Buffer_Switcher_Mark_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Review_Toggle
            | Command_Buffer_Switcher_Pending_Mark_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Next
            | Command_Buffer_Switcher_Pending_Mark_Previous
            | Command_Buffer_Switcher_Pending_Mark_Summary
            | Command_Buffer_Switcher_Pending_Mark_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Summary
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Next
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Previous
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Toggle
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Stale_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale
            | Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary
            | Command_Buffer_Switcher_Mark_Next
            | Command_Buffer_Switcher_Mark_Previous
            | Command_Buffer_Switcher_Mark_Summary
            | Command_Navigation_Back
            | Command_Navigation_Forward
            | Command_Navigation_History_Clear
            | Command_Next_Buffer
            | Command_Previous_Buffer
            | Command_Previous_Recent_Buffer
            | Command_Next_Recent_Buffer
            | Command_Next_Diagnostic
            | Command_Previous_Diagnostic
            | Command_Next_Bookmark
            | Command_Previous_Bookmark
            | Command_Next_Project_Search_Result
            | Command_Previous_Project_Search_Result
            | Command_First_Project_Search_Result
            | Command_Last_Project_Search_Result
            | Command_Reveal_Active_Project_Search_Result =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Navigation_Command;

   function Is_Search_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Find_Show
            | Command_Find_Hide
            | Command_Find_Toggle
            | Command_Find_Query_Set
            | Command_Find_Query_Clear
            | Command_Find_Case_Toggle
            | Command_Find_Case_Clear
            | Command_Find_Whole_Word_Toggle
            | Command_Find_Whole_Word_Clear
            | Command_Find_From_Selection
            | Command_Find_From_Active_Word
            | Command_Active_Find_Next
            | Command_Active_Find_Previous
            | Command_Find_First
            | Command_Find_Last
            | Command_Find_Reveal_Current
            | Command_Replace_Show
            | Command_Replace_Hide
            | Command_Replace_Toggle
            | Command_Replace_Text_Set
            | Command_Replace_Text_Clear
            | Command_Replace_Current
            | Command_Replace_All
            | Command_Run_Project_Search
            | Command_Rerun_Project_Search
            | Command_Open_Project_Search_Bar
            | Command_Toggle_Project_Search_Bar
            | Command_Close_Project_Search_Bar
            | Command_Run_Project_Search_From_Bar
            | Command_Project_Search_From_Selection
            | Command_Project_Search_From_Active_Word
            | Command_Project_Search_Active_Directory
            | Command_Clear_Project_Search
            | Command_Open_Selected_Project_Search_Result
            | Command_Move_Project_Search_Selection_Up
            | Command_Move_Project_Search_Selection_Down
            | Command_Next_Project_Search_Result
            | Command_Previous_Project_Search_Result
            | Command_First_Project_Search_Result
            | Command_Last_Project_Search_Result
            | Command_Reveal_Active_Project_Search_Result
            | Command_Project_Search_Scope_Selected_Directory
            | Command_Project_Search_Kind_Next
            | Command_Project_Search_Kind_Previous
            | Command_Project_Search_Kind_Clear
            | Command_Project_Search_Scope_Set
            | Command_Project_Search_Scope_Clear
            | Command_Project_Search_Case_Toggle
            | Command_Project_Search_Case_Clear
            | Command_Project_Search_Whole_Word_Toggle
            | Command_Project_Search_Whole_Word_Clear
            | Command_Project_Search_Regex_Toggle
            | Command_Project_Search_Regex_Clear
            | Command_Project_Search_Include_Filter_Set
            | Command_Project_Search_Exclude_Filter_Set
            | Command_Project_Search_Include_Filter_Clear
            | Command_Project_Search_Exclude_Filter_Clear
            | Command_Project_Search_Replace_Preview
            | Command_Project_Search_Replace_Toggle_Selected
            | Command_Project_Search_Replace_Include_Selected
            | Command_Project_Search_Replace_Exclude_Selected
            | Command_Project_Search_Replace_Include_File
            | Command_Project_Search_Replace_Exclude_File
            | Command_Project_Search_Replace_Include_All
            | Command_Project_Search_Replace_Exclude_All
            | Command_Project_Search_Replace_Selected
            | Command_Project_Search_Replace_All_Included
            | Command_Project_Search_Replace_Clear_Preview
            | Command_Show_Search_Results_Panel
            | Command_Focus_Search_Results
            | Command_Search_Results_Move_Up
            | Command_Search_Results_Move_Down
            | Command_Search_Results_Page_Up
            | Command_Search_Results_Page_Down
            | Command_Search_Results_Open_Selected =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Search_Command;

   function Is_Panel_Focus_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Toggle_Problems_Panel
            | Command_Focus_Editor_Text
            | Command_Focus_Search_Results
            | Command_Focus_Problems
            | Command_Toggle_Bottom_Panel_Focus
            | Command_Search_Results_Move_Up
            | Command_Search_Results_Move_Down
            | Command_Search_Results_Page_Up
            | Command_Search_Results_Page_Down
            | Command_Search_Results_Open_Selected
            | Command_Problems_Move_Up
            | Command_Problems_Move_Down
            | Command_Problems_Page_Up
            | Command_Problems_Page_Down
            | Command_Problems_Open_Selected
            | Command_Problems_Focus_Editor
            | Command_Focus_File_Tree
            | Command_File_Tree_Move_Up
            | Command_File_Tree_Move_Down
            | Command_File_Tree_Page_Up
            | Command_File_Tree_Page_Down
            | Command_File_Tree_Open_Selected
            | Command_File_Tree_Create_File
            | Command_File_Tree_Create_Directory
            | Command_File_Tree_Rename_Selected
            | Command_File_Tree_Delete_Selected
            | Command_File_Tree_Expand_Selected
            | Command_File_Tree_Collapse_Selected
            | Command_File_Tree_Toggle_Selected
            | Command_File_Tree_Collapse_All
            | Command_File_Tree_Expand_To_Active_File
            | Command_Toggle_Feature_Panel
            | Command_Show_Feature_Panel
            | Command_Hide_Feature_Panel
            | Command_Focus_Feature_Panel
            | Command_Clear_Feature_Panel
            | Command_Feature_Panel_Select_Next
            | Command_Feature_Panel_Select_Previous
            | Command_Feature_Panel_Open_Selected
            | Command_Refresh_Outline
            | Command_Refresh_Outline_Project_Index
            | Command_Goto_Declaration
            | Command_Goto_Body
            | Command_Goto_Spec
            | Command_Semantic_Refresh_Buffer
            | Command_Semantic_Refresh_Project_Index
            | Command_Language_Index_Clear
            | Command_Language_Index_Status
            | Command_Clear_Outline
            | Command_Show_Outline
            | Command_Focus_Outline
            | Command_Open_Selected_Outline_Item
            | Command_Select_Current_Outline_Symbol
            | Command_Reveal_Current_Outline_Symbol
            | Command_Next_Outline_Symbol
            | Command_Previous_Outline_Symbol
            | Command_Select_Next_Outline_Item
            | Command_Select_Previous_Outline_Item
            | Command_Focus_Outline_Filter
            | Command_Filter_Outline
            | Command_Clear_Outline_Filter
            | Command_Toggle_Outline_Filter
            | Command_Outline_Filter_History_Previous
            | Command_Outline_Filter_History_Next
            | Command_Clear_Outline_Filter_History
            | Command_Show_Messages
            | Command_Clear_Messages
            | Command_Search_Results_Search_Active_Buffer
            | Command_Search_Results_Focus_Query
            | Command_Search_Results_Repeat_Active_Buffer
            | Command_Search_Results_Query_History_Previous
            | Command_Search_Results_Query_History_Next
            | Command_Search_Results_Toggle_Case_Sensitive
            | Command_Show_Search_Results_Feature
            | Command_Clear_Search_Results_Feature
            | Command_Diagnostics_Show
            | Command_Diagnostics_Clear
            | Command_Diagnostics_Toggle_Info
            | Command_Diagnostics_Toggle_Warnings
            | Command_Diagnostics_Toggle_Errors
            | Command_Diagnostics_Show_All
            | Command_Diagnostics_Clear_Filter
            | Command_Diagnostics_Filter_Errors
            | Command_Diagnostics_Filter_Warnings
            | Command_Diagnostics_Filter_Info_Notes
            | Command_Diagnostics_Filter_Source
            | Command_Diagnostics_Filter_Build
            | Command_Diagnostics_Clear_Build
            | Command_Diagnostics_Open_Selected
            | Command_Diagnostics_Select_Next
            | Command_Diagnostics_Select_Previous
            | Command_Diagnostics_Clear_Selected
            | Command_Diagnostics_Copy_Selected_Text
            | Command_Diagnostics_Clear_Info
            | Command_Diagnostics_Clear_Warnings
            | Command_Diagnostics_Clear_Errors
            | Command_Diagnostics_Toggle_Editor_Source
            | Command_Diagnostics_Toggle_File_Source
            | Command_Diagnostics_Toggle_Project_Source
            | Command_Diagnostics_Toggle_External_Source
            | Command_Diagnostics_Toggle_Unknown_Source
            | Command_Clear_Selected_Message
            | Command_Copy_Selected_Message_Text
            | Command_Clear_Info_Messages
            | Command_Clear_Warning_Messages
            | Command_Clear_Error_Messages
            | Command_Toggle_Message_Info
            | Command_Toggle_Message_Warnings
            | Command_Toggle_Message_Errors
            | Command_Show_All_Messages
            | Command_Clear_Message_Filter =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Panel_Focus_Command;

   function Is_Text_Editing_Command
     (Id : Command_Id) return Boolean
   is
   begin
      case Id is
         when Command_Insert_Newline
            | Command_Undo
            | Command_Redo
            | Command_Cut
            | Command_Paste
            | Command_Line_Delete
            | Command_Line_Duplicate
            | Command_Line_Move_Up
            | Command_Line_Move_Down
            | Command_Indent_Increase
            | Command_Indent_Decrease
            | Command_Comment_Line
            | Command_Uncomment_Line
            | Command_Toggle_Line_Comment
            | Command_Line_Join_Next
            | Command_Line_Split_At_Caret
            | Command_Trim_Trailing_Whitespace
            | Command_Char_Delete_Previous
            | Command_Char_Delete_Next
            | Command_Word_Delete_Previous
            | Command_Word_Delete_Next
            | Command_Selection_Delete
            | Command_Replace_Current
            | Command_Replace_All =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Text_Editing_Command;

   function Has_Descriptor
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
   begin
      return D.Id = Id;
   end Has_Descriptor;

   function Has_Availability_Handler
     (Id : Command_Id) return Boolean
   is
   begin
      return Is_Concrete_Command (Id);
   end Has_Availability_Handler;


   function Stable_Command_Name
     (Id : Command_Id) return String
   is
      Raw    : constant String := Command_Id'Image (Id);
      First  : Positive := Raw'First;
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      if Id = Command_Palette_Show_Command_Help then
         return "command-palette.show-command-help";
      elsif Id = Command_Open_Project then
         return "project.open";
      elsif Id = Command_Refresh_Outline then
         return "outline.refresh";
      elsif Id = Command_Refresh_Outline_Project_Index then
         return "outline.refresh-project-index";
      elsif Id = Command_Goto_Declaration then
         return "outline.goto-declaration";
      elsif Id = Command_Goto_Body then
         return "outline.goto-body";
      elsif Id = Command_Goto_Spec then
         return "outline.goto-spec";
      elsif Id = Command_Semantic_Refresh_Buffer then
         return "semantic.refresh-buffer";
      elsif Id = Command_Semantic_Refresh_Project_Index then
         return "semantic.refresh-project-index";
      elsif Id = Command_Language_Index_Clear then
         return "language.index.clear";
      elsif Id = Command_Language_Index_Status then
         return "language.index.status";
      elsif Id = Command_Clear_Outline then
         return "outline.clear";
      elsif Id = Command_Show_Outline then
         return "outline.show";
      elsif Id = Command_Focus_Outline then
         return "outline.focus";
      elsif Id = Command_Open_Selected_Outline_Item then
         return "outline.open-selected";
      elsif Id = Command_Build_Run then
         return "build.run";
      elsif Id = Command_Build_UI_Toggle then
         return "build.ui.toggle";
      elsif Id = Command_Build_UI_Show then
         return "build.ui.show";
      elsif Id = Command_Build_UI_Hide then
         return "build.ui.hide";
      elsif Id = Command_Build_UI_Focus then
         return "build.ui.focus";
      elsif Id = Command_Build_Select_Next_Candidate then
         return "build.select-next-candidate";
      elsif Id = Command_Build_Select_Previous_Candidate then
         return "build.select-previous-candidate";
      elsif Id = Command_Build_Clear_Selected_Candidate then
         return "build.clear-selected-candidate";
      elsif Id = Command_Build_Set_Mode_Default then
         return "build.set-mode-default";
      elsif Id = Command_Build_Set_Mode_Debug then
         return "build.set-mode-debug";
      elsif Id = Command_Build_Set_Mode_Release then
         return "build.set-mode-release";
      elsif Id = Command_Build_Set_Mode_Validation then
         return "build.set-mode-validation";
      elsif Id = Command_Build_Toggle_Diagnostics_Ingestion then
         return "build.toggle-diagnostics-ingestion";
      elsif Id = Command_Build_Cycle_Output_Limit then
         return "build.cycle-output-limit";
      elsif Id = Command_Build_Toggle_Option_Verbose then
         return "build.toggle-option-verbose";
      elsif Id = Command_Build_Toggle_Option_Keep_Going then
         return "build.toggle-option-keep-going";
      elsif Id = Command_Build_Acknowledge_Consent then
         return "build.acknowledge-consent";
      elsif Id = Command_Build_Clear_Consent then
         return "build.clear-consent";
      elsif Id = Command_Build_Cancel then
         return "build.cancel";
      elsif Id = Command_Build_Run_User_Opt_In_Test_Seam then
         return "build.run-user-opt-in-test-seam";
      elsif Id = Command_Startup_Show_Summary then
         return "startup.show-summary";
      elsif Id = Command_Configuration_Recover_Show then
         return "configuration.recover-show";
      elsif Id = Command_Configuration_Audit then
         return "configuration.audit";
      elsif Id = Command_Configuration_Reset_Settings then
         return "configuration.reset-settings";
      elsif Id = Command_Configuration_Reset_Keybindings then
         return "configuration.reset-keybindings";
      elsif Id = Command_Configuration_Reset_Workspace then
         return "configuration.reset-workspace";
      elsif Id = Command_Configuration_Reset_Recent_Projects then
         return "configuration.reset-recent-projects";
      elsif Id = Command_Configuration_Reset_All then
         return "configuration.reset-all";
      elsif Id = Command_Configuration_Reset_All_Confirm then
         return "configuration.reset-all.confirm";
      elsif Id = Command_Configuration_Reset_All_Cancel then
         return "configuration.reset-all.cancel";
      elsif Id = Command_Configuration_Save_Clean_Settings then
         return "configuration.save-clean-settings";
      elsif Id = Command_Configuration_Save_Clean_Keybindings then
         return "configuration.save-clean-keybindings";
      elsif Id = Command_Configuration_Save_Clean_Workspace then
         return "configuration.save-clean-workspace";
      elsif Id = Command_Configuration_Save_Clean_Recent_Projects then
         return "configuration.save-clean-recent-projects";
      elsif Id = Command_Save_Keybindings then
         return "keybindings.save";
      elsif Id = Command_Reload_Keybindings then
         return "keybindings.load";
      elsif Id = Command_Keybindings_Show then
         return "keybindings.show";
      elsif Id = Command_Keybindings_Focus then
         return "keybindings.focus";
      elsif Id = Command_Keybindings_Assign_Selected then
         return "keybindings.assign-selected";
      elsif Id = Command_Keybindings_Remove_Selected then
         return "keybindings.remove-selected";
      elsif Id = Command_Keybindings_Reset_To_Defaults then
         return "keybindings.reset-to-defaults";
      elsif Id = Command_Keybindings_Filter_Conflicts then
         return "keybindings.filter-conflicts";
      elsif Id = Command_Keybindings_Filter_Unbound then
         return "keybindings.filter-unbound";
      elsif Id = Command_Keybindings_Clear_Filter then
         return "keybindings.clear-filter";
      elsif Id = Command_Keybindings_Cancel_Capture then
         return "keybindings.cancel-capture";
      elsif Id = Command_Switch_Project then
         return "project.switch";
      elsif Id = Command_Show_Recent_Projects then
         return "recent-projects.show";
      elsif Id = Command_Open_Selected_Recent_Project then
         return "recent-projects.open-selected";
      elsif Id = Command_Clear_Recent_Projects then
         return "recent-projects.clear";
      elsif Id = Command_Remove_Selected_Recent_Project then
         return "recent-projects.remove-selected";
      elsif Id = Command_Remove_Missing_Recent_Projects then
         return "recent-projects.remove-missing";
      elsif Id = Command_Select_Next_Recent_Project then
         return "recent-projects.select-next";
      elsif Id = Command_Select_Previous_Recent_Project then
         return "recent-projects.select-previous";
      elsif Id = Command_Diagnostics_Filter_Errors then
         return "diagnostics.filter-errors";
      elsif Id = Command_Diagnostics_Filter_Warnings then
         return "diagnostics.filter-warnings";
      elsif Id = Command_Diagnostics_Filter_Info_Notes then
         return "diagnostics.filter-info-notes";
      elsif Id = Command_Diagnostics_Filter_Source then
         return "diagnostics.filter-source";
      elsif Id = Command_Diagnostics_Filter_Build then
         return "diagnostics.filter-producer-build";
      elsif Id = Command_Diagnostics_Clear_Build then
         return "diagnostics.clear-build";
      elsif Id = Command_Diagnostics_Open_Selected then
         return "diagnostics.open-selected";
      elsif Id = Command_Diagnostics_Select_Next then
         return "diagnostics.next";
      elsif Id = Command_Diagnostics_Select_Previous then
         return "diagnostics.previous";
      elsif Id = Command_Navigation_Back then
         return "navigation.back";
      elsif Id = Command_Navigation_Forward then
         return "navigation.forward";
      elsif Id = Command_Navigation_History_Clear then
         return "navigation.history.clear";
      elsif Id = Command_Undo then
         return "edit.undo";
      elsif Id = Command_Redo then
         return "edit.redo";
      elsif Id = Command_Edit_History_Clear then
         return "edit.history.clear";
      elsif Id = Command_Copy then
         return "edit.copy";
      elsif Id = Command_Cut then
         return "edit.cut";
      elsif Id = Command_Paste then
         return "edit.paste";
      elsif Id = Command_Clipboard_Clear then
         return "edit.clipboard.clear";
      elsif Id = Command_Select_Left then
         return "selection.extend-left";
      elsif Id = Command_Select_Right then
         return "selection.extend-right";
      elsif Id = Command_Select_Up then
         return "selection.extend-up";
      elsif Id = Command_Select_Down then
         return "selection.extend-down";
      elsif Id = Command_Select_Word_Left then
         return "selection.extend-word-left";
      elsif Id = Command_Select_Word_Right then
         return "selection.extend-word-right";
      elsif Id = Command_Select_Word then
         return "selection.select-word";
      elsif Id = Command_Select_Line then
         return "selection.select-line";
      elsif Id = Command_Select_Line_Start then
         return "selection.extend-line-start";
      elsif Id = Command_Select_Line_End then
         return "selection.extend-line-end";
      elsif Id = Command_Select_Document_Start then
         return "selection.extend-buffer-start";
      elsif Id = Command_Select_Document_End then
         return "selection.extend-buffer-end";
      elsif Id = Command_Select_All then
         return "selection.select-all";
      elsif Id = Command_Selection_Clear then
         return "selection.clear";
      elsif Id = Command_Selection_Delete then
         return "selection.delete";
      elsif Id = Command_Line_Delete then
         return "edit.line.delete";
      elsif Id = Command_Line_Duplicate then
         return "edit.line.duplicate";
      elsif Id = Command_Line_Move_Up then
         return "edit.line.move-up";
      elsif Id = Command_Line_Move_Down then
         return "edit.line.move-down";
      elsif Id = Command_Indent_Increase then
         return "edit.indent.increase";
      elsif Id = Command_Indent_Decrease then
         return "edit.indent.decrease";
      elsif Id = Command_Comment_Line then
         return "edit.comment.line";
      elsif Id = Command_Uncomment_Line then
         return "edit.uncomment.line";
      elsif Id = Command_Toggle_Line_Comment then
         return "edit.comment.toggle-line";
      elsif Id = Command_Line_Join_Next then
         return "edit.line.join-next";
      elsif Id = Command_Line_Split_At_Caret then
         return "edit.line.split-at-caret";
      elsif Id = Command_Trim_Trailing_Whitespace then
         return "edit.trim-trailing-whitespace";
      elsif Id = Command_Char_Delete_Previous then
         return "edit.char.delete-previous";
      elsif Id = Command_Char_Delete_Next then
         return "edit.char.delete-next";
      elsif Id = Command_Word_Delete_Previous then
         return "edit.word.delete-previous";
      elsif Id = Command_Word_Delete_Next then
         return "edit.word.delete-next";
      elsif Id = Command_Save_File then
         return "file.save";
      elsif Id = Command_Save_File_As then
         return "file.save-as";
      elsif Id = Command_Save_All then
         return "file.save-all";
      elsif Id = Command_Reload_Active_Buffer then
         return "file.reload-buffer";
      elsif Id = Command_Revert_Active_Buffer then
         return "file.revert-buffer";
      elsif Id = Command_File_Conflict_Keep_Buffer then
         return "file-conflict.keep-buffer";
      elsif Id = Command_File_Conflict_Reload_From_Disk then
         return "file-conflict.reload-from-disk";
      elsif Id = Command_File_Conflict_Overwrite_Disk then
         return "file-conflict.overwrite-disk";
      elsif Id = Command_File_Conflict_Cancel then
         return "file-conflict.cancel";
      elsif Id = Command_Rename_Buffer_File then
         return "file.rename-buffer-file";
      elsif Id = Command_Delete_Buffer_File then
         return "file.delete-buffer-file";
      elsif Id = Command_Copy_Buffer_File then
         return "file.copy-buffer-file";
      elsif Id = Command_Move_Buffer_File then
         return "file.move-buffer-file";
      elsif Id = Command_Goto_Line then
         return "navigation.goto-line.show";
      elsif Id = Command_Goto_Line_Toggle then
         return "navigation.goto-line.toggle";
      elsif Id = Command_Goto_Line_Prefill_Current then
         return "navigation.goto-line.prefill-current";
      elsif Id = Command_Goto_Line_Query_Set then
         return "navigation.goto-line.query.set";
      elsif Id = Command_Goto_Line_Query_Clear then
         return "navigation.goto-line.query.clear";
      elsif Id = Command_Close_Goto_Line then
         return "navigation.goto-line.hide";
      elsif Id = Command_Accept_Goto_Line then
         return "navigation.goto-line.accept";
      elsif Id = Command_Find_Show then
         return "edit.find.show";
      elsif Id = Command_Find_Hide then
         return "edit.find.hide";
      elsif Id = Command_Find_Toggle then
         return "edit.find.toggle";
      elsif Id = Command_Find_Query_Set then
         return "edit.find.query.set";
      elsif Id = Command_Find_Query_Clear then
         return "edit.find.query.clear";
      elsif Id = Command_Find_Case_Toggle then
         return "edit.find.case.toggle";
      elsif Id = Command_Find_Case_Clear then
         return "edit.find.case.clear";
      elsif Id = Command_Find_Whole_Word_Toggle then
         return "edit.find.whole-word.toggle";
      elsif Id = Command_Find_Whole_Word_Clear then
         return "edit.find.whole-word.clear";
      elsif Id = Command_Find_From_Selection then
         return "edit.find.from-selection";
      elsif Id = Command_Find_From_Active_Word then
         return "edit.find.from-active-word";
      elsif Id = Command_Active_Find_Next then
         return "edit.find.next";
      elsif Id = Command_Active_Find_Previous then
         return "edit.find.previous";
      elsif Id = Command_Find_First then
         return "edit.find.first";
      elsif Id = Command_Find_Last then
         return "edit.find.last";
      elsif Id = Command_Find_Reveal_Current then
         return "edit.find.reveal-current";
      elsif Id = Command_Replace_Show then
         return "edit.replace.show";
      elsif Id = Command_Replace_Hide then
         return "edit.replace.hide";
      elsif Id = Command_Replace_Toggle then
         return "edit.replace.toggle";
      elsif Id = Command_Replace_Text_Set then
         return "edit.replace.text.set";
      elsif Id = Command_Replace_Text_Clear then
         return "edit.replace.text.clear";
      elsif Id = Command_Replace_Current then
         return "edit.replace.current";
      elsif Id = Command_Replace_All then
         return "edit.replace.all";
      elsif Id = Command_Toggle_Bookmark then
         return "bookmarks.toggle";
      elsif Id = Command_Next_Bookmark then
         return "bookmarks.next";
      elsif Id = Command_Previous_Bookmark then
         return "bookmarks.previous";
      elsif Id = Command_Clear_Bookmarks then
         return "bookmarks.clear-buffer";
      elsif Id = Command_Clear_All_Bookmarks then
         return "bookmarks.clear-all";
      elsif Id = Command_Bookmark_Toggle_Current_Location then
         return "bookmark.toggle-current-location";
      elsif Id = Command_Bookmark_Clear_All then
         return "bookmark.clear-all";
      elsif Id = Command_Bookmark_Next then
         return "bookmark.next";
      elsif Id = Command_Bookmark_Previous then
         return "bookmark.previous";
      elsif Id = Command_Bookmark_Goto_Next then
         return "bookmark.goto-next";
      elsif Id = Command_Bookmark_Goto_Previous then
         return "bookmark.goto-previous";
      elsif Id = Command_Bookmark_Open_Selected then
         return "bookmark.open-selected";
      elsif Id = Command_Bookmark_Reveal_Current then
         return "bookmark.reveal-current";
      elsif Id = Command_Bookmark_Remove_Selected then
         return "bookmark.remove-selected";
      elsif Id = Command_Bookmark_Show then
         return "bookmark.show";
      elsif Id = Command_Bookmark_Hide then
         return "bookmark.hide";
      elsif Id = Command_Bookmark_Toggle then
         return "bookmark.toggle";
      elsif Id = Command_Open_Quick_Open then
         return "project.quick-open.show";
      elsif Id = Command_Close_Quick_Open then
         return "project.quick-open.hide";
      elsif Id = Command_Toggle_Quick_Open then
         return "project.quick-open.toggle";
      elsif Id = Command_Accept_Quick_Open then
         return "project.quick-open.open-selected";
      elsif Id = Command_Quick_Open_Next_Result then
         return "project.quick-open.next";
      elsif Id = Command_Quick_Open_Previous_Result then
         return "project.quick-open.previous";
      elsif Id = Command_Quick_Open_Query_Set then
         return "project.quick-open.query.set";
      elsif Id = Command_Quick_Open_Query_Clear then
         return "project.quick-open.query.clear";
      elsif Id = Command_Quick_Open_Kind_Next then
         return "project.quick-open.kind.next";
      elsif Id = Command_Quick_Open_Kind_Previous then
         return "project.quick-open.kind.previous";
      elsif Id = Command_Quick_Open_Kind_Clear then
         return "project.quick-open.kind.clear";
      elsif Id = Command_Quick_Open_Scope_Set then
         return "project.quick-open.scope.set";
      elsif Id = Command_Quick_Open_Scope_Clear then
         return "project.quick-open.scope.clear";
      elsif Id = Command_Quick_Open_Scope_From_Selected then
         return "project.quick-open.scope.from-selected";
      elsif Id = Command_Quick_Open_Scope_Parent then
         return "project.quick-open.scope.parent";
      elsif Id = Command_Quick_Open_Reveal_Active then
         return "project.quick-open.reveal-active";
      elsif Id = Command_Quick_Open_Scope_Active_Directory then
         return "project.quick-open.scope.active-directory";
      elsif Id = Command_Quick_Open_Create_From_Query then
         return "project.quick-open.create-from-query";
      elsif Id = Command_Quick_Open_Create_With_Parents_From_Query then
         return "project.quick-open.create-with-parents-from-query";
      elsif Id = Command_Quick_Open_Priority_Toggle then
         return "project.quick-open.priority.toggle";
      elsif Id = Command_Quick_Open_Priority_Clear then
         return "project.quick-open.priority.clear";
      elsif Id = Command_Run_Project_Search then
         return "project.search.run";
      elsif Id = Command_Open_Project_Search_Bar then
         return "project.search.show";
      elsif Id = Command_Toggle_Project_Search_Bar then
         return "project.search.toggle";
      elsif Id = Command_Close_Project_Search_Bar then
         return "project.search.hide";
      elsif Id = Command_Run_Project_Search_From_Bar then
         return "project.search.query.set";
      elsif Id = Command_Project_Search_From_Selection then
         return "project.search.from-selection";
      elsif Id = Command_Project_Search_From_Active_Word then
         return "project.search.from-active-word";
      elsif Id = Command_Project_Search_Active_Directory then
         return "project.search.active-directory";
      elsif Id = Command_Clear_Project_Search then
         return "project.search.query.clear";
      elsif Id = Command_Next_Project_Search_Result then
         return "project.search.next";
      elsif Id = Command_Previous_Project_Search_Result then
         return "project.search.previous";
      elsif Id = Command_First_Project_Search_Result then
         return "project.search.first";
      elsif Id = Command_Last_Project_Search_Result then
         return "project.search.last";
      elsif Id = Command_Reveal_Active_Project_Search_Result then
         return "project.search.reveal-active-result";
      elsif Id = Command_Project_Search_Scope_Selected_Directory then
         return "project.search.scope.selected-directory";
      elsif Id = Command_Open_Selected_Project_Search_Result then
         return "project.search.open-selected";
      elsif Id = Command_Project_Search_Kind_Next then
         return "project.search.kind.next";
      elsif Id = Command_Project_Search_Kind_Previous then
         return "project.search.kind.previous";
      elsif Id = Command_Project_Search_Kind_Clear then
         return "project.search.kind.clear";
      elsif Id = Command_Project_Search_Scope_Set then
         return "project.search.scope.set";
      elsif Id = Command_Project_Search_Scope_Clear then
         return "project.search.scope.clear";
      elsif Id = Command_Project_Search_Case_Toggle then
         return "project.search.case.toggle";
      elsif Id = Command_Project_Search_Case_Clear then
         return "project.search.case.clear";
      elsif Id = Command_Project_Search_Whole_Word_Toggle then
         return "project.search.whole-word.toggle";
      elsif Id = Command_Project_Search_Whole_Word_Clear then
         return "project.search.whole-word.clear";
      elsif Id = Command_Project_Search_Regex_Toggle then
         return "project.search.regex.toggle";
      elsif Id = Command_Project_Search_Regex_Clear then
         return "project.search.regex.clear";
      elsif Id = Command_Project_Search_Include_Filter_Set then
         return "project.search.include.set";
      elsif Id = Command_Project_Search_Exclude_Filter_Set then
         return "project.search.exclude.set";
      elsif Id = Command_Project_Search_Include_Filter_Clear then
         return "project.search.include.clear";
      elsif Id = Command_Project_Search_Exclude_Filter_Clear then
         return "project.search.exclude.clear";
      elsif Id = Command_Project_Search_Replace_Preview then
         return "project.search.replace.preview";
      elsif Id = Command_Project_Search_Replace_Toggle_Selected then
         return "project.search.replace.toggle-selected";
      elsif Id = Command_Project_Search_Replace_Include_Selected then
         return "project.search.replace.include-selected";
      elsif Id = Command_Project_Search_Replace_Exclude_Selected then
         return "project.search.replace.exclude-selected";
      elsif Id = Command_Project_Search_Replace_Include_File then
         return "project.search.replace.include-file";
      elsif Id = Command_Project_Search_Replace_Exclude_File then
         return "project.search.replace.exclude-file";
      elsif Id = Command_Project_Search_Replace_Include_All then
         return "project.search.replace.include-all";
      elsif Id = Command_Project_Search_Replace_Exclude_All then
         return "project.search.replace.exclude-all";
      elsif Id = Command_Project_Search_Replace_Selected then
         return "project.search.replace.selected";
      elsif Id = Command_Project_Search_Replace_All_Included then
         return "project.search.replace.all-included";
      elsif Id = Command_Project_Search_Replace_Clear_Preview then
         return "project.search.replace.clear-preview";
      elsif Id = Command_Refresh_File_Tree then
         return "file-tree.refresh";
      elsif Id = Command_Refresh_Project_Files then
         return "project.files.refresh";
      elsif Id = Command_Project_Files_Summary then
         return "project.files.summary";
      elsif Id = Command_Reveal_Active_File_In_Tree then
         return "file-tree.reveal-active-file";
      elsif Id = Command_Focus_File_Tree then
         return "file-tree.focus";
      elsif Id = Command_File_Tree_Move_Up then
         return "file-tree.move-up";
      elsif Id = Command_File_Tree_Move_Down then
         return "file-tree.move-down";
      elsif Id = Command_File_Tree_Page_Up then
         return "file-tree.page-up";
      elsif Id = Command_File_Tree_Page_Down then
         return "file-tree.page-down";
      elsif Id = Command_File_Tree_Open_Selected then
         return "file-tree.open-selected";
      elsif Id = Command_File_Tree_Create_File then
         return "file-tree.create-file";
      elsif Id = Command_File_Tree_Create_Directory then
         return "file-tree.create-directory";
      elsif Id = Command_File_Tree_Rename_Selected then
         return "file-tree.rename-selected";
      elsif Id = Command_File_Tree_Delete_Selected then
         return "file-tree.delete-selected";
      elsif Id = Command_File_Tree_Expand_Selected then
         return "file-tree.expand-selected";
      elsif Id = Command_File_Tree_Collapse_Selected then
         return "file-tree.collapse-selected";
      elsif Id = Command_File_Tree_Toggle_Selected then
         return "file-tree.toggle-selected";
      elsif Id = Command_File_Tree_Collapse_All then
         return "file-tree.collapse-all";
      elsif Id = Command_File_Tree_Expand_To_Active_File then
         return "file-tree.expand-to-active-file";
      elsif Id = Command_Open_Buffer_Switcher then
         return "buffers.switcher.open";
      elsif Id = Command_Close_Buffer_Switcher then
         return "buffers.switcher.close";
      elsif Id = Command_Accept_Buffer_Switcher then
         return "buffers.switcher.accept";
      elsif Id = Command_Buffer_Switcher_Next_Result then
         return "buffers.switcher.next";
      elsif Id = Command_Buffer_Switcher_Previous_Result then
         return "buffers.switcher.previous";
      elsif Id = Command_Buffer_Switcher_Filter_Clear then
         return "buffers.switcher.filter.clear";
      elsif Id = Command_Buffer_Switcher_Filter_Pinned then
         return "buffers.switcher.filter.pinned";
      elsif Id = Command_Buffer_Switcher_Filter_Group then
         return "buffers.switcher.filter.group";
      elsif Id = Command_Buffer_Switcher_Filter_Label then
         return "buffers.switcher.filter.label";
      elsif Id = Command_Buffer_Switcher_Filter_Noted then
         return "buffers.switcher.filter.noted";
      elsif Id = Command_Buffer_Switcher_Sort_Default then
         return "buffers.switcher.sort.default";
      elsif Id = Command_Buffer_Switcher_Sort_Recent then
         return "buffers.switcher.sort.recent";
      elsif Id = Command_Buffer_Switcher_Sort_Name then
         return "buffers.switcher.sort.name";
      elsif Id = Command_Buffer_Switcher_Sort_Pinned then
         return "buffers.switcher.sort.pinned";
      elsif Id = Command_Buffer_Switcher_Sort_Group then
         return "buffers.switcher.sort.group";
      elsif Id = Command_Buffer_Switcher_Sort_Label then
         return "buffers.switcher.sort.label";
      elsif Id = Command_Buffer_Switcher_Sort_Next then
         return "buffers.switcher.sort.next";
      elsif Id = Command_Buffer_Switcher_Sort_Previous then
         return "buffers.switcher.sort.previous";
      elsif Id = Command_Buffer_Switcher_Selected_Close then
         return "buffers.switcher.selected.close";
      elsif Id = Command_Buffer_Switcher_Selected_Pin then
         return "buffers.switcher.selected.pin";
      elsif Id = Command_Buffer_Switcher_Selected_Unpin then
         return "buffers.switcher.selected.unpin";
      elsif Id = Command_Buffer_Switcher_Selected_Toggle_Pin then
         return "buffers.switcher.selected.toggle-pin";
      elsif Id = Command_Buffer_Switcher_Selected_Group_Assign then
         return "buffers.switcher.selected.group.assign";
      elsif Id = Command_Buffer_Switcher_Selected_Group_Clear then
         return "buffers.switcher.selected.group.clear";
      elsif Id = Command_Buffer_Switcher_Selected_Label_Set then
         return "buffers.switcher.selected.label.set";
      elsif Id = Command_Buffer_Switcher_Selected_Label_Clear then
         return "buffers.switcher.selected.label.clear";
      elsif Id = Command_Buffer_Switcher_Selected_Note_Set then
         return "buffers.switcher.selected.note.set";
      elsif Id = Command_Buffer_Switcher_Selected_Note_Clear then
         return "buffers.switcher.selected.note.clear";
      elsif Id = Command_Buffer_Switcher_Preview_Toggle then
         return "buffers.switcher.preview.toggle";
      elsif Id = Command_Buffer_Switcher_Preview_Show then
         return "buffers.switcher.preview.show";
      elsif Id = Command_Buffer_Switcher_Preview_Hide then
         return "buffers.switcher.preview.hide";
      elsif Id = Command_Buffer_Switcher_Preview_Next_Line then
         return "buffers.switcher.preview.next-line";
      elsif Id = Command_Buffer_Switcher_Preview_Previous_Line then
         return "buffers.switcher.preview.previous-line";
      elsif Id = Command_Buffer_Switcher_Preview_Center_Cursor then
         return "buffers.switcher.preview.center-cursor";
      elsif Id = Command_Buffer_Switcher_Mark_Toggle then
         return "buffers.switcher.mark.toggle";
      elsif Id = Command_Buffer_Switcher_Mark_Set then
         return "buffers.switcher.mark.set";
      elsif Id = Command_Buffer_Switcher_Mark_Clear then
         return "buffers.switcher.mark.clear";
      elsif Id = Command_Buffer_Switcher_Mark_Clear_All then
         return "buffers.switcher.mark.clear-all";
      elsif Id = Command_Buffer_Switcher_Mark_Invert_Visible then
         return "buffers.switcher.mark.invert-visible";
      elsif Id = Command_Buffer_Switcher_Mark_Visible then
         return "buffers.switcher.mark.visible";
      elsif Id = Command_Buffer_Switcher_Mark_Clear_Visible then
         return "buffers.switcher.mark.clear-visible";
      elsif Id = Command_Buffer_Switcher_Mark_Pinned then
         return "buffers.switcher.mark.pinned";
      elsif Id = Command_Buffer_Switcher_Mark_Group then
         return "buffers.switcher.mark.group";
      elsif Id = Command_Buffer_Switcher_Mark_Label then
         return "buffers.switcher.mark.label";
      elsif Id = Command_Buffer_Switcher_Mark_Noted then
         return "buffers.switcher.mark.noted";
      elsif Id = Command_Buffer_Switcher_Mark_Close_Marked then
         return "buffers.switcher.mark.close-marked";
      elsif Id = Command_Buffer_Switcher_Mark_Confirm then
         return "buffers.switcher.mark.confirm";
      elsif Id = Command_Buffer_Switcher_Mark_Cancel then
         return "buffers.switcher.mark.cancel";
      elsif Id = Command_Buffer_Switcher_Mark_Pin_Marked then
         return "buffers.switcher.mark.pin-marked";
      elsif Id = Command_Buffer_Switcher_Mark_Unpin_Marked then
         return "buffers.switcher.mark.unpin-marked";
      elsif Id = Command_Buffer_Switcher_Mark_Clear_Metadata then
         return "buffers.switcher.mark.clear-metadata";
      elsif Id = Command_Buffer_Switcher_Mark_Group_Assign then
         return "buffers.switcher.mark.group.assign";
      elsif Id = Command_Buffer_Switcher_Mark_Group_Clear then
         return "buffers.switcher.mark.group.clear";
      elsif Id = Command_Buffer_Switcher_Mark_Label_Set then
         return "buffers.switcher.mark.label.set";
      elsif Id = Command_Buffer_Switcher_Mark_Label_Clear then
         return "buffers.switcher.mark.label.clear";
      elsif Id = Command_Buffer_Switcher_Mark_Note_Set then
         return "buffers.switcher.mark.note.set";
      elsif Id = Command_Buffer_Switcher_Mark_Note_Clear then
         return "buffers.switcher.mark.note.clear";
      elsif Id = Command_Buffer_Switcher_Mark_Review_Toggle then
         return "buffers.switcher.mark.review.toggle";
      elsif Id = Command_Buffer_Switcher_Mark_Review_Show then
         return "buffers.switcher.mark.review.show";
      elsif Id = Command_Buffer_Switcher_Mark_Review_Hide then
         return "buffers.switcher.mark.review.hide";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Review_Toggle then
         return "buffers.switcher.pending-mark.review.toggle";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Review_Show then
         return "buffers.switcher.pending-mark.review.show";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Review_Hide then
         return "buffers.switcher.pending-mark.review.hide";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Next then
         return "buffers.switcher.pending-mark.next";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Previous then
         return "buffers.switcher.pending-mark.previous";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Summary then
         return "buffers.switcher.pending-mark.summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Remove_Selected then
         return "buffers.switcher.pending-mark.remove-selected";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned then
         return "buffers.switcher.pending-mark.restore-last-pruned";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Pruned_Summary then
         return "buffers.switcher.pending-mark.pruned-summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Pruned_Next then
         return "buffers.switcher.pending-mark.pruned-next";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Pruned_Previous then
         return "buffers.switcher.pending-mark.pruned-previous";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Toggle then
         return "buffers.switcher.pending-mark.pruned-review.toggle";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show then
         return "buffers.switcher.pending-mark.pruned-review.show";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide then
         return "buffers.switcher.pending-mark.pruned-review.hide";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Restore_Selected_Pruned then
         return "buffers.switcher.pending-mark.restore-selected-pruned";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Summary then
         return "buffers.switcher.pending-mark.dirty-summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Next then
         return "buffers.switcher.pending-mark.dirty-next";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Previous then
         return "buffers.switcher.pending-mark.dirty-previous";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected then
         return "buffers.switcher.pending-mark.dirty-remove-selected";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview then
         return "buffers.switcher.pending-mark.dirty-prune.preview";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply then
         return "buffers.switcher.pending-mark.dirty-prune.apply";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm then
         return "buffers.switcher.pending-mark.dirty-prune.apply.confirm";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel then
         return "buffers.switcher.pending-mark.dirty-prune.apply.cancel";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Summary then
         return "buffers.switcher.pending-mark.dirty-prune.apply.summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next then
         return "buffers.switcher.pending-mark.dirty-prune.apply.next";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous then
         return "buffers.switcher.pending-mark.dirty-prune.apply.previous";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Toggle then
         return "buffers.switcher.pending-mark.dirty-prune.apply.review.toggle";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show then
         return "buffers.switcher.pending-mark.dirty-prune.apply.review.show";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide then
         return "buffers.switcher.pending-mark.dirty-prune.apply.review.hide";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected then
         return "buffers.switcher.pending-mark.dirty-prune.apply.remove-selected";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed then
         return "buffers.switcher.pending-mark.dirty-prune.apply.restore-last-removed";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Summary then
         return "buffers.switcher.pending-mark.dirty-prune.apply.removed-summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next then
         return "buffers.switcher.pending-mark.dirty-prune.apply.removed-next";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous then
         return "buffers.switcher.pending-mark.dirty-prune.apply.removed-previous";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale then
         return "buffers.switcher.pending-mark.dirty-prune.apply.clear-stale";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Stale_Summary then
         return "buffers.switcher.pending-mark.dirty-prune.apply.stale-summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel then
         return "buffers.switcher.pending-mark.dirty-prune.cancel";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Summary then
         return "buffers.switcher.pending-mark.dirty-prune.summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next then
         return "buffers.switcher.pending-mark.dirty-prune.next";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous then
         return "buffers.switcher.pending-mark.dirty-prune.previous";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Toggle then
         return "buffers.switcher.pending-mark.dirty-prune.review.toggle";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show then
         return "buffers.switcher.pending-mark.dirty-prune.review.show";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide then
         return "buffers.switcher.pending-mark.dirty-prune.review.hide";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected then
         return "buffers.switcher.pending-mark.dirty-prune.remove-selected";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed then
         return "buffers.switcher.pending-mark.dirty-prune.restore-last-removed";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Summary then
         return "buffers.switcher.pending-mark.dirty-prune.removed-summary";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next then
         return "buffers.switcher.pending-mark.dirty-prune.removed-next";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous then
         return "buffers.switcher.pending-mark.dirty-prune.removed-previous";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale then
         return "buffers.switcher.pending-mark.dirty-prune.clear-stale";
      elsif Id = Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Stale_Summary then
         return "buffers.switcher.pending-mark.dirty-prune.stale-summary";
      elsif Id = Command_Buffer_Switcher_Mark_Next then
         return "buffers.switcher.mark.next";
      elsif Id = Command_Buffer_Switcher_Mark_Previous then
         return "buffers.switcher.mark.previous";
      elsif Id = Command_Buffer_Switcher_Mark_Summary then
         return "buffers.switcher.mark.summary";
      elsif Id = Command_Previous_Recent_Buffer then
         return "buffers.recent.previous";
      elsif Id = Command_Next_Outline_Symbol then
         return "outline.next-symbol";
      elsif Id = Command_Previous_Outline_Symbol then
         return "outline.previous-symbol";
      elsif Id = Command_Reveal_Current_Outline_Symbol then
         return "outline.reveal-current-symbol";
      elsif Id = Command_Focus_Outline_Filter then
         return "outline.filter.focus";
      elsif Id = Command_Clear_Outline_Filter then
         return "outline.filter.clear";
      elsif Id = Command_Toggle_Outline_Filter then
         return "outline.filter.toggle";
      elsif Id = Command_Outline_Filter_History_Previous then
         return "outline.filter.history.previous";
      elsif Id = Command_Outline_Filter_History_Next then
         return "outline.filter.history.next";
      elsif Id = Command_Next_Recent_Buffer then
         return "buffers.recent.next";
      elsif Id = Command_Close_Other_Buffers then
         return "file.close-other-buffers";
      elsif Id = Command_Close_All_Buffers then
         return "file.close-all-buffers";
      elsif Id = Command_Close_All_Clean_Buffers then
         return "file.close-clean-buffers";
      elsif Id = Command_Confirm_Close_Save then
         return "buffer.confirm-close-save";
      elsif Id = Command_Confirm_Close_Discard then
         return "buffer.confirm-close-discard";
      elsif Id = Command_Cancel_Close then
         return "buffer.cancel-close";
      elsif Id = Command_Pin_Buffer then
         return "buffers.pin";
      elsif Id = Command_Unpin_Buffer then
         return "buffers.unpin";
      elsif Id = Command_Toggle_Buffer_Pin then
         return "buffers.toggle-pin";
      elsif Id = Command_Set_Buffer_Label then
         return "buffers.label.set";
      elsif Id = Command_Clear_Buffer_Label then
         return "buffers.label.clear";
      elsif Id = Command_Edit_Buffer_Label then
         return "buffers.label.edit";
      elsif Id = Command_Show_Buffer_Label then
         return "buffers.label.show";
      elsif Id = Command_Set_Buffer_Note then
         return "buffers.note.set";
      elsif Id = Command_Clear_Buffer_Note then
         return "buffers.note.clear";
      elsif Id = Command_Edit_Buffer_Note then
         return "buffers.note.edit";
      elsif Id = Command_Show_Buffer_Note then
         return "buffers.note.show";
      elsif Id = Command_Assign_Buffer_Group then
         return "buffers.group.assign";
      elsif Id = Command_Clear_Buffer_Group then
         return "buffers.group.clear";
      elsif Id = Command_Switch_Buffer_Group then
         return "buffers.group.switch";
      elsif Id = Command_Next_Buffer_Group then
         return "buffers.group.next";
      elsif Id = Command_Previous_Buffer_Group then
         return "buffers.group.previous";
      elsif Id = Command_Close_Active_Buffer then
         return "file.close-buffer";
      elsif Id = Command_Reopen_Closed_Buffer then
         return "file.reopen-closed-buffer";
      elsif Id = Command_Show_All_Buffer_Groups then
         return "buffers.group.show-all";
      elsif Id = Command_Discard_Pending_Transition then
         return "lifecycle.pending.discard";
      end if;

      if Raw'Length >= 8 and then Raw (Raw'First .. Raw'First + 7) = "COMMAND_" then
         First := Raw'First + 8;
      end if;

      for I in First .. Raw'Last loop
         if Raw (I) = '_' then
            Append (Result, "-");
         else
            Append (Result, Ada.Characters.Handling.To_Lower (Raw (I)));
         end if;
      end loop;
      return To_String (Result);
   end Stable_Command_Name;

   function Command_Id_From_Stable_Name
     (Name  : String;
      Found : out Boolean) return Command_Id
   is
      N : constant String := Ada.Characters.Handling.To_Lower
        (Ada.Strings.Fixed.Trim (Name, Ada.Strings.Both));
   begin
      --  Phase 579 product workflow names.  These are the daily-use command
      --  ids documented for the product surface.  Removed and spelling-only
      --  variants intentionally do not resolve here.
      if N = "command-palette.show-command-help"
      then
         Found := True;
         return Command_Palette_Show_Command_Help;
      elsif N = "project.open" or else N = "open-project" then
         Found := True;
         return Command_Open_Project;
      elsif N = "project.close" then
         Found := True;
         return Command_Close_Project;
      elsif N = "project.switch" then
         Found := True;
         return Command_Switch_Project;
      elsif N = "project.reopen-recent"
      then
         Found := True;
         return Command_Open_Selected_Recent_Project;
      elsif N = "file.open" then
         Found := True;
         return Command_Open_File;
      elsif N = "file.save" then
         Found := True;
         return Command_Save_File;
      elsif N = "file.save-as"
      then
         Found := True;
         return Command_Save_File_As;
      elsif N = "file.reload" then
         Found := True;
         return Command_Reload_Active_Buffer;
      elsif N = "file.revert" then
         Found := True;
         return Command_Revert_Active_Buffer;
      elsif N = "file-tree.refresh"
      then
         Found := True;
         return Command_Refresh_File_Tree;
      elsif N = "file-tree.open-selected"
      then
         Found := True;
         return Command_File_Tree_Open_Selected;
      elsif N = "file-tree.rename"
      then
         Found := True;
         return Command_File_Tree_Rename_Selected;
      elsif N = "file-tree.delete"
      then
         Found := True;
         return Command_File_Tree_Delete_Selected;
      elsif N = "file-tree.create-file"
      then
         Found := True;
         return Command_File_Tree_Create_File;
      elsif N = "file-tree.create-directory"
      then
         Found := True;
         return Command_File_Tree_Create_Directory;
      elsif N = "quick-open.show"
      then
         Found := True;
         return Command_Open_Quick_Open;
      elsif N = "quick-open.open-selected"
      then
         Found := True;
         return Command_Accept_Quick_Open;
      elsif N = "search.project" then
         Found := True;
         return Command_Run_Project_Search;
      elsif N = "search.open-selected"
      then
         Found := True;
         return Command_Open_Selected_Project_Search_Result;
      elsif N = "outline.refresh" then
         Found := True;
         return Command_Refresh_Outline;
      elsif N = "outline.refresh-project-index" then
         Found := True;
         return Command_Refresh_Outline_Project_Index;
      elsif N = "outline.goto-declaration" then
         Found := True;
         return Command_Goto_Declaration;
      elsif N = "outline.goto-body" then
         Found := True;
         return Command_Goto_Body;
      elsif N = "outline.goto-spec" then
         Found := True;
         return Command_Goto_Spec;
      elsif N = "semantic.refresh-buffer" then
         Found := True;
         return Command_Semantic_Refresh_Buffer;
      elsif N = "semantic.refresh-project-index" then
         Found := True;
         return Command_Semantic_Refresh_Project_Index;
      elsif N = "language.index.clear" then
         Found := True;
         return Command_Language_Index_Clear;
      elsif N = "language.index.status" then
         Found := True;
         return Command_Language_Index_Status;
      elsif N = "outline.show" then
         Found := True;
         return Command_Show_Outline;
      elsif N = "outline.focus" then
         Found := True;
         return Command_Focus_Outline;
      elsif N = "outline.clear" then
         Found := True;
         return Command_Clear_Outline;
      elsif N = "outline.open-selected"
      then
         Found := True;
         return Command_Open_Selected_Outline_Item;
      elsif N = "outline.select-next"
      then
         Found := True;
         return Command_Select_Next_Outline_Item;
      elsif N = "outline.select-previous"
      then
         Found := True;
         return Command_Select_Previous_Outline_Item;
      elsif N = "build.output.show" then
         Found := True;
         return Command_Build_UI_Show;
      elsif N = "build.output.toggle" then
         Found := True;
         return Command_Build_UI_Toggle;
      elsif N = "build.output.hide" then
         Found := True;
         return Command_Build_UI_Hide;
      elsif N = "build.output.focus" then
         Found := True;
         return Command_Build_UI_Focus;
      elsif N = "buffer.switch-next"
      then
         Found := True;
         return Command_Next_Buffer;
      elsif N = "buffer.switch-previous"
      then
         Found := True;
         return Command_Previous_Buffer;
      elsif N = "buffer.close" then
         Found := True;
         return Command_Close_Active_Buffer;
      elsif N = "buffer.close-all-clean"
      then
         Found := True;
         return Command_Close_All_Clean_Buffers;
      elsif N = "workspace.restore" then
         Found := True;
         return Command_Restore_Workspace_State;
      elsif N = "build.run" then
         Found := True;
         return Command_Build_Run;
      elsif N = "build.ui.toggle" then
         Found := True;
         return Command_Build_UI_Toggle;
      elsif N = "build.ui.show" then
         Found := True;
         return Command_Build_UI_Show;
      elsif N = "build.ui.hide" then
         Found := True;
         return Command_Build_UI_Hide;
      elsif N = "build.ui.focus" then
         Found := True;
         return Command_Build_UI_Focus;
      elsif N = "build.select-next-candidate" then
         Found := True;
         return Command_Build_Select_Next_Candidate;
      elsif N = "build.select-previous-candidate" then
         Found := True;
         return Command_Build_Select_Previous_Candidate;
      elsif N = "build.clear-selected-candidate" then
         Found := True;
         return Command_Build_Clear_Selected_Candidate;
      elsif N = "build.set-mode-default" then
         Found := True;
         return Command_Build_Set_Mode_Default;
      elsif N = "build.set-mode-debug" then
         Found := True;
         return Command_Build_Set_Mode_Debug;
      elsif N = "build.set-mode-release" then
         Found := True;
         return Command_Build_Set_Mode_Release;
      elsif N = "build.set-mode-validation" then
         Found := True;
         return Command_Build_Set_Mode_Validation;
      elsif N = "build.toggle-diagnostics-ingestion" then
         Found := True;
         return Command_Build_Toggle_Diagnostics_Ingestion;
      elsif N = "build.cycle-output-limit" then
         Found := True;
         return Command_Build_Cycle_Output_Limit;
      elsif N = "build.toggle-option-verbose" then
         Found := True;
         return Command_Build_Toggle_Option_Verbose;
      elsif N = "build.toggle-option-keep-going" then
         Found := True;
         return Command_Build_Toggle_Option_Keep_Going;
      elsif N = "build.acknowledge-consent" then
         Found := True;
         return Command_Build_Acknowledge_Consent;
      elsif N = "build.clear-consent" then
         Found := True;
         return Command_Build_Clear_Consent;
      elsif N = "build.cancel" then
         Found := True;
         return Command_Build_Cancel;
      elsif N = "build.run-user-opt-in-test-seam" then
         Found := True;
         return Command_Build_Run_User_Opt_In_Test_Seam;
      elsif N = "diagnostics.show" then
         Found := True;
         return Command_Diagnostics_Show;
      elsif N = "diagnostics.hide" then
         --  Phase 557 accepts the public Problems-style dot-form hide command name
         --  without adding diagnostic row/source/filter payloads.  Reuse the
         --  generic feature-panel hide route so persisted command identity and
         --  panel mutation boundaries remain unchanged.
         Found := True;
         return Command_Hide_Feature_Panel;
      elsif N = "diagnostics.focus" then
         --  Same no-payload command-name policy as diagnostics.hide: focusing the
         --  panel is a generic panel action, not a Diagnostics row action.
         Found := True;
         return Command_Focus_Feature_Panel;
      elsif N = "diagnostics.clear" then
         Found := True;
         return Command_Diagnostics_Clear;
      elsif N = "diagnostics.next" then
         Found := True;
         return Command_Diagnostics_Select_Next;
      elsif N = "diagnostics.previous" then
         Found := True;
         return Command_Diagnostics_Select_Previous;
      elsif N = "diagnostics.open-selected" then
         Found := True;
         return Command_Diagnostics_Open_Selected;
      elsif N = "diagnostics.filter-all" then
         Found := True;
         return Command_Diagnostics_Show_All;
      elsif N = "diagnostics.filter-clear" then
         Found := True;
         return Command_Diagnostics_Clear_Filter;
      elsif N = "diagnostics.filter-errors" then
         Found := True;
         return Command_Diagnostics_Filter_Errors;
      elsif N = "diagnostics.filter-warnings" then
         Found := True;
         return Command_Diagnostics_Filter_Warnings;
      elsif N = "diagnostics.filter-info-notes" then
         Found := True;
         return Command_Diagnostics_Filter_Info_Notes;
      elsif N = "diagnostics.filter-source" then
         Found := True;
         return Command_Diagnostics_Filter_Source;
      elsif N = "diagnostics.filter-producer-build" then
         Found := True;
         return Command_Diagnostics_Filter_Build;
      elsif N = "diagnostics.clear-build" then
         Found := True;
         return Command_Diagnostics_Clear_Build;
      elsif N = "navigation.goto-line.show" or else N = "navigation.goto-line" then
         Found := True;
         return Command_Goto_Line;
      elsif N = "navigation.goto-line.toggle" then
         Found := True;
         return Command_Goto_Line_Toggle;
      elsif N = "navigation.goto-line.prefill-current" then
         Found := True;
         return Command_Goto_Line_Prefill_Current;
      elsif N = "navigation.goto-line.query.set" then
         Found := True;
         return Command_Goto_Line_Query_Set;
      elsif N = "navigation.goto-line.query.clear" then
         Found := True;
         return Command_Goto_Line_Query_Clear;
      elsif N = "navigation.goto-line.hide" then
         Found := True;
         return Command_Close_Goto_Line;
      elsif N = "navigation.goto-line.accept" then
         Found := True;
         return Command_Accept_Goto_Line;
      elsif N = "cursor.word-left" then
         Found := True;
         return Command_Move_Word_Left;
      elsif N = "cursor.word-right" then
         Found := True;
         return Command_Move_Word_Right;
      elsif N = "selection.extend-left" then
         Found := True;
         return Command_Select_Left;
      elsif N = "selection.extend-right" then
         Found := True;
         return Command_Select_Right;
      elsif N = "selection.extend-up" then
         Found := True;
         return Command_Select_Up;
      elsif N = "selection.extend-down" then
         Found := True;
         return Command_Select_Down;
      elsif N = "selection.extend-word-left" then
         Found := True;
         return Command_Select_Word_Left;
      elsif N = "selection.extend-word-right" then
         Found := True;
         return Command_Select_Word_Right;
      elsif N = "selection.extend-line-start" then
         Found := True;
         return Command_Select_Line_Start;
      elsif N = "selection.extend-line-end" then
         Found := True;
         return Command_Select_Line_End;
      elsif N = "selection.extend-buffer-start" then
         Found := True;
         return Command_Select_Document_Start;
      elsif N = "selection.extend-buffer-end" then
         Found := True;
         return Command_Select_Document_End;
      elsif N = "selection.select-word" then
         Found := True;
         return Command_Select_Word;
      elsif N = "selection.select-line" then
         Found := True;
         return Command_Select_Line;
      elsif N = "selection.expand-to-line" then
         Found := True;
         return Command_Select_Line;
      elsif N = "edit.delete-word-backward" then
         Found := True;
         return Command_Word_Delete_Previous;
      elsif N = "edit.delete-word-forward" then
         Found := True;
         return Command_Word_Delete_Next;
      elsif N = "edit.duplicate-line" then
         Found := True;
         return Command_Line_Duplicate;
      elsif N = "edit.move-line-up" then
         Found := True;
         return Command_Line_Move_Up;
      elsif N = "edit.move-line-down" then
         Found := True;
         return Command_Line_Move_Down;
      elsif N = "edit.join-lines" then
         Found := True;
         return Command_Line_Join_Next;
      elsif N = "edit.split-line" then
         Found := True;
         return Command_Line_Split_At_Caret;
      elsif N = "edit.undo" then
         Found := True;
         return Command_Undo;
      elsif N = "edit.redo" then
         Found := True;
         return Command_Redo;
      elsif N = "edit.history.clear" then
         Found := True;
         return Command_Edit_History_Clear;
      elsif N = "edit.copy" then
         Found := True;
         return Command_Copy;
      elsif N = "edit.cut" then
         Found := True;
         return Command_Cut;
      elsif N = "edit.paste" then
         Found := True;
         return Command_Paste;
      elsif N = "edit.clipboard.clear" then
         Found := True;
         return Command_Clipboard_Clear;
      elsif N = "selection.select-all" or else N = "edit.select-all" then
         Found := True;
         return Command_Select_All;
      elsif N = "selection.clear" or else N = "edit.selection.clear" then
         Found := True;
         return Command_Selection_Clear;
      elsif N = "selection.delete" then
         Found := True;
         return Command_Selection_Delete;
      elsif N = "edit.line.delete" then
         Found := True;
         return Command_Line_Delete;
      elsif N = "edit.line.duplicate" then
         Found := True;
         return Command_Line_Duplicate;
      elsif N = "edit.line.move-up" then
         Found := True;
         return Command_Line_Move_Up;
      elsif N = "edit.line.move-down" then
         Found := True;
         return Command_Line_Move_Down;
      elsif N = "edit.indent.increase" then
         Found := True;
         return Command_Indent_Increase;
      elsif N = "edit.indent.decrease" then
         Found := True;
         return Command_Indent_Decrease;
      elsif N = "edit.comment.line" then
         Found := True;
         return Command_Comment_Line;
      elsif N = "edit.uncomment.line" then
         Found := True;
         return Command_Uncomment_Line;
      elsif N = "edit.comment.toggle-line" then
         Found := True;
         return Command_Toggle_Line_Comment;
      elsif N = "edit.line.join-next" then
         Found := True;
         return Command_Line_Join_Next;
      elsif N = "edit.line.split-at-caret" then
         Found := True;
         return Command_Line_Split_At_Caret;
      elsif N = "edit.trim-trailing-whitespace" then
         Found := True;
         return Command_Trim_Trailing_Whitespace;
      elsif N = "edit.char.delete-previous" then
         Found := True;
         return Command_Char_Delete_Previous;
      elsif N = "edit.char.delete-next" then
         Found := True;
         return Command_Char_Delete_Next;
      elsif N = "edit.word.delete-previous" then
         Found := True;
         return Command_Word_Delete_Previous;
      elsif N = "edit.word.delete-next" then
         Found := True;
         return Command_Word_Delete_Next;
      elsif N = "file.save-all" then
         Found := True;
         return Command_Save_All;
      elsif N = "file.reload-from-disk" or else N = "file.reload-buffer" then
         Found := True;
         return Command_Reload_Active_Buffer;
      elsif N = "file.revert-buffer" then
         Found := True;
         return Command_Revert_Active_Buffer;
      elsif N = "file-conflict.keep-buffer" then
         Found := True;
         return Command_File_Conflict_Keep_Buffer;
      elsif N = "file-conflict.reload-from-disk" then
         Found := True;
         return Command_File_Conflict_Reload_From_Disk;
      elsif N = "file-conflict.overwrite-disk" then
         Found := True;
         return Command_File_Conflict_Overwrite_Disk;
      elsif N = "file-conflict.cancel" then
         Found := True;
         return Command_File_Conflict_Cancel;
      elsif N = "file.rename-buffer-file" then
         Found := True;
         return Command_Rename_Buffer_File;
      elsif N = "file.delete-buffer-file" then
         Found := True;
         return Command_Delete_Buffer_File;
      elsif N = "file.copy-buffer-file" then
         Found := True;
         return Command_Copy_Buffer_File;
      elsif N = "file.move-buffer-file" then
         Found := True;
         return Command_Move_Buffer_File;
      elsif N = "file.close-buffer"
        or else N = "buffer.close-active"
      then
         Found := True;
         return Command_Close_Active_Buffer;
      elsif N = "file.close-all-buffers"
        or else N = "buffer.close-all"
      then
         Found := True;
         return Command_Close_All_Buffers;
      elsif N = "buffer.confirm-close-save" then
         Found := True;
         return Command_Confirm_Close_Save;
      elsif N = "buffer.confirm-close-discard" then
         Found := True;
         return Command_Confirm_Close_Discard;
      elsif N = "buffer.cancel-close" then
         Found := True;
         return Command_Cancel_Close;
      elsif N = "file.close-other-buffers"
        or else N = "buffer.close-other"
      then
         Found := True;
         return Command_Close_Other_Buffers;
      elsif N = "file.close-clean-buffers"
        or else N = "buffer.close-clean"
        or else N = "buffer-list.close-clean"
        or else N = "buffer.list.close-clean"
      then
         Found := True;
         return Command_Close_All_Clean_Buffers;
      elsif N = "file.reopen-closed-buffer" then
         Found := True;
         return Command_Reopen_Closed_Buffer;
      elsif N = "buffer.close-selected"
        or else N = "buffer-list.close-selected"
        or else N = "buffers.switcher.selected.close"
      then
         Found := True;
         return Command_Buffer_Switcher_Selected_Close;
      elsif N = "lifecycle.pending.discard" then
         Found := True;
         return Command_Discard_Pending_Transition;
      elsif N = "file.reveal-active-in-tree"
        or else N = "file-tree.reveal-active-file"
      then
         Found := True;
         return Command_Reveal_Active_File_In_Tree;
      elsif N = "file-tree.focus" then
         Found := True;
         return Command_Focus_File_Tree;
      elsif N = "file-tree.move-up" then
         Found := True;
         return Command_File_Tree_Move_Up;
      elsif N = "file-tree.move-down" then
         Found := True;
         return Command_File_Tree_Move_Down;
      elsif N = "file-tree.page-up" then
         Found := True;
         return Command_File_Tree_Page_Up;
      elsif N = "file-tree.page-down" then
         Found := True;
         return Command_File_Tree_Page_Down;
      elsif N = "file-tree.rename-selected" then
         Found := True;
         return Command_File_Tree_Rename_Selected;
      elsif N = "file-tree.delete-selected" then
         Found := True;
         return Command_File_Tree_Delete_Selected;
      elsif N = "file-tree.expand-selected" then
         Found := True;
         return Command_File_Tree_Expand_Selected;
      elsif N = "file-tree.collapse-selected" then
         Found := True;
         return Command_File_Tree_Collapse_Selected;
      elsif N = "file-tree.toggle-selected" then
         Found := True;
         return Command_File_Tree_Toggle_Selected;
      elsif N = "file-tree.collapse-all" then
         Found := True;
         return Command_File_Tree_Collapse_All;
      elsif N = "file-tree.expand-to-active-file" then
         Found := True;
         return Command_File_Tree_Expand_To_Active_File;
      elsif N = "buffer.list.show" or else N = "buffer.list.focus"
        or else N = "buffer-list.show" or else N = "buffer-list.focus"
        or else N = "buffer.list.toggle" or else N = "buffer-list.toggle"
        or else N = "buffers.switcher.open" then
         --  Phase 543 canonical open-buffer list names.  Preserve the
         --  historical buffers.switcher.* stable names while allowing the
         --  multi-buffer navigation command surface to use buffer.list.*.
         Found := True;
         return Command_Open_Buffer_Switcher;
      elsif N = "buffer.list.hide" or else N = "buffer-list.hide"
        or else N = "buffers.switcher.close" then
         Found := True;
         return Command_Close_Buffer_Switcher;
      elsif N = "buffer.switch-selected" or else N = "buffer-list.switch-selected"
        or else N = "buffers.switcher.accept" then
         Found := True;
         return Command_Accept_Buffer_Switcher;
      elsif N = "buffer.next" then
         Found := True;
         return Command_Next_Buffer;
      elsif N = "buffer.previous" then
         Found := True;
         return Command_Previous_Buffer;
      elsif N = "buffer-list.select-next"
        or else N = "buffer.list.select-next"
        or else N = "buffers.switcher.next"
      then
         Found := True;
         return Command_Buffer_Switcher_Next_Result;
      elsif N = "buffer-list.select-previous"
        or else N = "buffer.list.select-previous"
        or else N = "buffers.switcher.previous"
      then
         Found := True;
         return Command_Buffer_Switcher_Previous_Result;
      elsif N = "edit.find.show" then
         Found := True;
         return Command_Find_Show;
      elsif N = "edit.find.hide" then
         Found := True;
         return Command_Find_Hide;
      elsif N = "edit.find.toggle" then
         Found := True;
         return Command_Find_Toggle;
      elsif N = "edit.find.query.set" then
         Found := True;
         return Command_Find_Query_Set;
      elsif N = "edit.find.query.clear" then
         Found := True;
         return Command_Find_Query_Clear;
      elsif N = "edit.find.case.toggle" then
         Found := True;
         return Command_Find_Case_Toggle;
      elsif N = "edit.find.case.clear" then
         Found := True;
         return Command_Find_Case_Clear;
      elsif N = "edit.find.whole-word.toggle" then
         Found := True;
         return Command_Find_Whole_Word_Toggle;
      elsif N = "edit.find.whole-word.clear" then
         Found := True;
         return Command_Find_Whole_Word_Clear;
      elsif N = "edit.find.from-selection" then
         Found := True;
         return Command_Find_From_Selection;
      elsif N = "edit.find.from-active-word" then
         Found := True;
         return Command_Find_From_Active_Word;
      elsif N = "edit.find.next" then
         Found := True;
         return Command_Active_Find_Next;
      elsif N = "edit.find.previous" then
         Found := True;
         return Command_Active_Find_Previous;
      elsif N = "edit.find.first" then
         Found := True;
         return Command_Find_First;
      elsif N = "edit.find.last" then
         Found := True;
         return Command_Find_Last;
      elsif N = "edit.find.reveal-current" then
         Found := True;
         return Command_Find_Reveal_Current;
      elsif N = "edit.replace.show" then
         Found := True;
         return Command_Replace_Show;
      elsif N = "edit.replace.hide" then
         Found := True;
         return Command_Replace_Hide;
      elsif N = "edit.replace.toggle" then
         Found := True;
         return Command_Replace_Toggle;
      elsif N = "edit.replace.text.set" then
         Found := True;
         return Command_Replace_Text_Set;
      elsif N = "edit.replace.text.clear" then
         Found := True;
         return Command_Replace_Text_Clear;
      elsif N = "edit.replace.current" then
         Found := True;
         return Command_Replace_Current;
      elsif N = "edit.replace.all" then
         Found := True;
         return Command_Replace_All;
      elsif N = "project.search.regex.toggle" then
         Found := True;
         return Command_Project_Search_Regex_Toggle;
      elsif N = "project.search.regex.clear" then
         Found := True;
         return Command_Project_Search_Regex_Clear;
      elsif N = "project.search.include.set" then
         Found := True;
         return Command_Project_Search_Include_Filter_Set;
      elsif N = "project.search.exclude.set" then
         Found := True;
         return Command_Project_Search_Exclude_Filter_Set;
      elsif N = "project.search.run" then
         Found := True;
         return Command_Run_Project_Search;
      elsif N = "project.search.show" then
         Found := True;
         return Command_Open_Project_Search_Bar;
      elsif N = "project.search.toggle" then
         Found := True;
         return Command_Toggle_Project_Search_Bar;
      elsif N = "project.search.hide" then
         Found := True;
         return Command_Close_Project_Search_Bar;
      elsif N = "project.search.query.set" then
         Found := True;
         return Command_Run_Project_Search_From_Bar;
      elsif N = "project.search.from-selection" then
         Found := True;
         return Command_Project_Search_From_Selection;
      elsif N = "project.search.from-active-word" then
         Found := True;
         return Command_Project_Search_From_Active_Word;
      elsif N = "project.search.active-directory" then
         Found := True;
         return Command_Project_Search_Active_Directory;
      elsif N = "project.search.query.clear" then
         Found := True;
         return Command_Clear_Project_Search;
      elsif N = "project.search.open-selected" then
         Found := True;
         return Command_Open_Selected_Project_Search_Result;
      elsif N = "project.search.next" then
         Found := True;
         return Command_Next_Project_Search_Result;
      elsif N = "project.search.previous" then
         Found := True;
         return Command_Previous_Project_Search_Result;
      elsif N = "project.search.first" then
         Found := True;
         return Command_First_Project_Search_Result;
      elsif N = "project.search.last" then
         Found := True;
         return Command_Last_Project_Search_Result;
      elsif N = "project.search.reveal-active-result" then
         Found := True;
         return Command_Reveal_Active_Project_Search_Result;
      elsif N = "project.search.scope.selected-directory" then
         Found := True;
         return Command_Project_Search_Scope_Selected_Directory;
      elsif N = "project.search.kind.next" then
         Found := True;
         return Command_Project_Search_Kind_Next;
      elsif N = "project.search.kind.previous" then
         Found := True;
         return Command_Project_Search_Kind_Previous;
      elsif N = "project.search.kind.clear" then
         Found := True;
         return Command_Project_Search_Kind_Clear;
      elsif N = "project.search.scope.set" then
         Found := True;
         return Command_Project_Search_Scope_Set;
      elsif N = "project.search.scope.clear" then
         Found := True;
         return Command_Project_Search_Scope_Clear;
      elsif N = "project.search.case.toggle" then
         Found := True;
         return Command_Project_Search_Case_Toggle;
      elsif N = "project.search.case.clear" then
         Found := True;
         return Command_Project_Search_Case_Clear;
      elsif N = "project.search.whole-word.toggle" then
         Found := True;
         return Command_Project_Search_Whole_Word_Toggle;
      elsif N = "project.search.whole-word.clear" then
         Found := True;
         return Command_Project_Search_Whole_Word_Clear;
      elsif N = "project.search.include.clear" then
         Found := True;
         return Command_Project_Search_Include_Filter_Clear;
      elsif N = "project.search.exclude.clear" then
         Found := True;
         return Command_Project_Search_Exclude_Filter_Clear;
      elsif N = "project.search.replace.preview" then
         Found := True;
         return Command_Project_Search_Replace_Preview;
      elsif N = "project.search.replace.toggle-selected" then
         Found := True;
         return Command_Project_Search_Replace_Toggle_Selected;
      elsif N = "project.search.replace.include-selected" then
         Found := True;
         return Command_Project_Search_Replace_Include_Selected;
      elsif N = "project.search.replace.exclude-selected" then
         Found := True;
         return Command_Project_Search_Replace_Exclude_Selected;
      elsif N = "project.search.replace.include-file" then
         Found := True;
         return Command_Project_Search_Replace_Include_File;
      elsif N = "project.search.replace.exclude-file" then
         Found := True;
         return Command_Project_Search_Replace_Exclude_File;
      elsif N = "project.search.replace.include-all" then
         Found := True;
         return Command_Project_Search_Replace_Include_All;
      elsif N = "project.search.replace.exclude-all" then
         Found := True;
         return Command_Project_Search_Replace_Exclude_All;
      elsif N = "project.search.replace.selected" then
         Found := True;
         return Command_Project_Search_Replace_Selected;
      elsif N = "project.search.replace.all-included" then
         Found := True;
         return Command_Project_Search_Replace_All_Included;
      elsif N = "project.search.replace.clear-preview" then
         Found := True;
         return Command_Project_Search_Replace_Clear_Preview;
      elsif N = "outline.next-symbol" then
         Found := True;
         return Command_Next_Outline_Symbol;
      elsif N = "outline.previous-symbol" then
         Found := True;
         return Command_Previous_Outline_Symbol;
      elsif N = "outline.reveal-current-symbol" then
         Found := True;
         return Command_Reveal_Current_Outline_Symbol;
      elsif N = "outline.filter.focus" or else N = "focus-outline-filter" then
         Found := True;
         return Command_Focus_Outline_Filter;
      elsif N = "outline.filter.clear" or else N = "clear-outline-filter" then
         Found := True;
         return Command_Clear_Outline_Filter;
      elsif N = "outline.filter.toggle" or else N = "toggle-outline-filter" then
         Found := True;
         return Command_Toggle_Outline_Filter;
      elsif N = "outline.filter.history.previous"
        or else N = "outline-filter-history-previous"
      then
         Found := True;
         return Command_Outline_Filter_History_Previous;
      elsif N = "outline.filter.history.next"
        or else N = "outline-filter-history-next"
      then
         Found := True;
         return Command_Outline_Filter_History_Next;
      elsif N = "outline.filter.next-match" then
         Found := True;
         return Command_Select_Next_Outline_Item;
      elsif N = "outline.filter.previous-match" then
         Found := True;
         return Command_Select_Previous_Outline_Item;
      elsif N = "open-quick-open" or else N = "project.quick-open.show" then
         Found := True;
         return Command_Open_Quick_Open;
      elsif N = "close-quick-open" or else N = "project.quick-open.hide" then
         Found := True;
         return Command_Close_Quick_Open;
      elsif N = "toggle-quick-open" or else N = "project.quick-open.toggle" then
         Found := True;
         return Command_Toggle_Quick_Open;
      elsif N = "accept-quick-open" or else N = "project.quick-open.open-selected" then
         Found := True;
         return Command_Accept_Quick_Open;
      elsif N = "quick-open-next-result" or else N = "project.quick-open.next" then
         Found := True;
         return Command_Quick_Open_Next_Result;
      elsif N = "quick-open-previous-result" or else N = "project.quick-open.previous" then
         Found := True;
         return Command_Quick_Open_Previous_Result;
      elsif N = "quick-open-query-set" or else N = "project.quick-open.query.set" then
         Found := True;
         return Command_Quick_Open_Query_Set;
      elsif N = "quick-open-query-clear" or else N = "project.quick-open.query.clear" then
         Found := True;
         return Command_Quick_Open_Query_Clear;
      elsif N = "quick-open-kind-next" or else N = "project.quick-open.kind.next" then
         Found := True;
         return Command_Quick_Open_Kind_Next;
      elsif N = "quick-open-kind-previous" or else N = "project.quick-open.kind.previous" then
         Found := True;
         return Command_Quick_Open_Kind_Previous;
      elsif N = "quick-open-kind-clear" or else N = "project.quick-open.kind.clear" then
         Found := True;
         return Command_Quick_Open_Kind_Clear;
      elsif N = "quick-open-scope-set" or else N = "project.quick-open.scope.set" then
         Found := True;
         return Command_Quick_Open_Scope_Set;
      elsif N = "quick-open-scope-clear" or else N = "project.quick-open.scope.clear" then
         Found := True;
         return Command_Quick_Open_Scope_Clear;
      elsif N = "quick-open-scope-from-selected" or else N = "project.quick-open.scope.from-selected" then
         Found := True;
         return Command_Quick_Open_Scope_From_Selected;
      elsif N = "quick-open-scope-parent" or else N = "project.quick-open.scope.parent" then
         Found := True;
         return Command_Quick_Open_Scope_Parent;
      elsif N = "quick-open-reveal-active" or else N = "project.quick-open.reveal-active" then
         Found := True;
         return Command_Quick_Open_Reveal_Active;
      elsif N = "quick-open-scope-active-directory"
        or else N = "project.quick-open.scope.active-directory"
      then
         Found := True;
         return Command_Quick_Open_Scope_Active_Directory;
      elsif N = "quick-open-create-from-query"
        or else N = "project.quick-open.create-from-query"
      then
         Found := True;
         return Command_Quick_Open_Create_From_Query;
      elsif N = "quick-open-create-with-parents-from-query"
        or else N = "project.quick-open.create-with-parents-from-query"
      then
         Found := True;
         return Command_Quick_Open_Create_With_Parents_From_Query;
      elsif N = "quick-open-priority-toggle"
        or else N = "project.quick-open.priority.toggle"
      then
         Found := True;
         return Command_Quick_Open_Priority_Toggle;
      elsif N = "quick-open-priority-clear"
        or else N = "project.quick-open.priority.clear"
      then
         Found := True;
         return Command_Quick_Open_Priority_Clear;
      end if;

      for Id in Command_Id loop
         if Is_Bindable_Command (Id) and then Stable_Command_Name (Id) = N then
            Found := True;
            return Id;
         end if;
      end loop;
      Found := False;
      return No_Command;
   end Command_Id_From_Stable_Name;

   function Has_Stable_Name
     (Id : Command_Id) return Boolean
   is
      Name : constant String := Stable_Command_Name (Id);
   begin
      return Is_Bindable_Command (Id)
        and then Name'Length > 0
        and then Ada.Strings.Fixed.Index (Name, " ") = 0
        and then Ada.Strings.Fixed.Trim (Name, Ada.Strings.Both) = Name;
   end Has_Stable_Name;

   function Is_Bindable_Command
     (Id : Command_Id) return Boolean
   is
   begin
      return Is_Concrete_Command (Id)
        and then not Is_Test_Only_Command (Id)
        and then Descriptor (Id).Bindable;
   end Is_Bindable_Command;

   function Is_Internal_Command
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
   begin
      return D.Category = Internal_Category
        or else D.Visibility = Hidden_Command;
   end Is_Internal_Command;

   function Descriptor_Is_Complete
     (Id : Command_Id) return Boolean
   is
      D : constant Command_Descriptor := Descriptor (Id);
      L : constant String := To_String (D.Name);
      Desc : constant String := To_String (D.Description);
      Cat_Label : constant String := Category_Label (D.Category);
   begin
      if D.Id /= Id then
         return False;
      end if;

      if Id = No_Command then
         return D.Visibility = Hidden_Command
           and then D.Category = Internal_Category;
      end if;

      if not Has_Stable_User_Label (Id) then
         return False;
      end if;

      if Cat_Label'Length = 0 or else Trimmed (Cat_Label) /= Cat_Label then
         return False;
      end if;

      if Desc'Length = 0 or else Trimmed (Desc) /= Desc then
         return False;
      end if;

      if D.Visibility = Palette_Command then
         return D.Category /= Internal_Category;
      end if;

      return True;
   end Descriptor_Is_Complete;

   procedure Audit_Command
     (Id      : Command_Id;
      Failure : out Command_Audit_Failure;
      Found   : out Boolean)
   is
      D    : constant Command_Descriptor := Descriptor (Id);
      Desc : constant String := To_String (D.Description);
   begin
      Failure := (Kind => Missing_Descriptor, Command => Id);
      Found := False;

      if not Is_Concrete_Command (Id) then
         return;
      end if;

      if not Has_Descriptor (Id) then
         Failure := (Kind => Missing_Descriptor, Command => Id);
         Found := True;
         return;
      end if;

      if not Has_Stable_User_Label (Id) then
         Failure := (Kind => Missing_Label, Command => Id);
         Found := True;
         return;
      end if;

      if Desc'Length = 0
        or else Trimmed (Desc) /= Desc
      then
         Failure := (Kind => Missing_Description, Command => Id);
         Found := True;
         return;
      end if;

      if Category_Label (D.Category)'Length = 0 then
         Failure := (Kind => Missing_Category, Command => Id);
         Found := True;
         return;
      end if;

      if Is_Bindable_Command (Id) and then not Has_Stable_Name (Id) then
         Failure := (Kind => Missing_Stable_Name, Command => Id);
         Found := True;
         return;
      end if;

      if D.Bindable and then not Is_Concrete_Command (Id) then
         Failure := (Kind => Invalid_Bindability, Command => Id);
         Found := True;
         return;
      end if;

      if not Has_Availability_Handler (Id) then
         Failure := (Kind => Missing_Availability, Command => Id);
         Found := True;
         return;
      end if;

      if not Descriptor_Is_Complete (Id) then
         Failure := (Kind => Missing_Classification, Command => Id);
         Found := True;
      end if;
   end Audit_Command;

   function Audit_Command_Registry
      return Command_Audit_Failure_Vectors.Vector
   is
      Result  : Command_Audit_Failure_Vectors.Vector;
      Failure : Command_Audit_Failure;
      Found   : Boolean;
   begin
      for Id in Command_Id loop
         if Is_Concrete_Command (Id) then
            Audit_Command (Id, Failure, Found);
            if Found then
               Result.Append (Failure);
            end if;
         end if;
      end loop;

      return Result;
   end Audit_Command_Registry;

   function Command_Audit_Summary
     (Failures : Command_Audit_Failure_Vectors.Vector) return String
   is
      Text : Unbounded_String := Null_Unbounded_String;

      function Failure_Text
        (Kind : Command_Audit_Failure_Kind) return String
      is
      begin
         case Kind is
            when Missing_Descriptor =>
               return "missing descriptor";
            when Missing_Label =>
               return "missing label";
            when Missing_Description =>
               return "missing description";
            when Missing_Category =>
               return "missing category";
            when Missing_Stable_Name =>
               return "missing stable command name";
            when Duplicate_Stable_Name =>
               return "duplicate stable command name";
            when Missing_Availability =>
               return "missing availability handler";
            when Missing_Executor_Handling =>
               return "missing Executor handling";
            when Invalid_Bindability =>
               return "invalid bindability";
            when Invalid_Default_Keybinding =>
               return "invalid default keybinding";
            when Missing_Classification =>
               return "missing classification";
            when Ambiguous_Save_Command =>
               return "ambiguous save command classification";
            when Route_Bypasses_Executor =>
               return "route bypasses Executor";
            when Unexpected_Domain_Mutation =>
               return "unexpected side-effect domain mutation";
         end case;
      end Failure_Text;
   begin
      if Failures.Is_Empty then
         return "Command audit passed";
      end if;

      Append (Text, "Command audit failed:");
      for Failure of Failures loop
         Append (Text, ASCII.LF);
         Append (Text, "  ");
         Append (Text, Command_Id'Image (Failure.Command));
         Append (Text, ": ");
         Append (Text, Failure_Text (Failure.Kind));
      end loop;

      return To_String (Text);
   end Command_Audit_Summary;


   function Is_Visible_In_Palette
     (Id : Command_Id) return Boolean
   is
   begin
      return Descriptor (Id).Visibility = Palette_Command;
   end Is_Visible_In_Palette;

   function Visible_In_Command_Palette
     (Id : Command_Id) return Boolean
   is
   begin
      return Is_Visible_In_Palette (Id);
   end Visible_In_Command_Palette;

   function Palette_Command_Count return Natural
   is
      Count : Natural := 0;
   begin
      for I in 1 .. Command_Count loop
         if Visible_In_Command_Palette (Command_At (I)) then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Palette_Command_Count;

   function Palette_Command_At
     (Index : Positive) return Command_Id
   is
      Count : Natural := 0;
      Id    : Command_Id;
   begin
      pragma Assert
        (Index <= Palette_Command_Count,
         "Editor.Commands.Palette_Command_At index out of range");

      for I in 1 .. Command_Count loop
         Id := Command_At (I);
         if Visible_In_Command_Palette (Id) then
            Count := Count + 1;
            if Count = Index then
               return Id;
            end if;
         end if;
      end loop;

      return No_Command;
   end Palette_Command_At;

   function Command_Count return Natural
   is
   begin
      return Command_Id'Pos (Command_Id'Last) - Command_Id'Pos (Command_Id'First) + 1;
   end Command_Count;

   function Command_At
     (Index : Positive) return Command_Id
   is
   begin
      pragma Assert (Index <= Command_Count, "Editor.Commands.Command_At index out of range");
      return Command_Id'Val (Command_Id'Pos (Command_Id'First) + Index - 1);
   end Command_At;

   function Palette_Commands return Command_Descriptor_Vectors.Vector is
      Result : Command_Descriptor_Vectors.Vector;
      D      : Command_Descriptor;
   begin
      for I in 1 .. Command_Count loop
         D := Descriptor (Command_At (I));
         if D.Visibility = Palette_Command then
            Result.Append (D);
         end if;
      end loop;

      return Result;
   end Palette_Commands;

end Editor.Commands;
