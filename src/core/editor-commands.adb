with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands.Availability_Metadata;
with Editor.Commands.Descriptor_Metadata;
with Editor.Commands.Name_Metadata;
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
      return Availability_Metadata.Available;
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
      elsif Trimmed = Editor.Commands.Reason_Project_Search_Result_Stale
        or else Trimmed = "Search result is stale; rerun search"
        or else Trimmed = Editor.Commands.Reason_Search_Result_Stale_Rerun
        or else Trimmed = "Replacement target changed; rerun search"
        or else Trimmed = "Replacement target changed; rerun search."
        or else Trimmed = "Search results are stale"
        or else Trimmed = "Search results are stale."
        or else Trimmed = "Search results are stale; rerun search."
        or else Trimmed = Editor.Commands.Reason_Replacement_Preview_Stale
        or else Trimmed = "Replacement preview is stale."
        or else Trimmed = Editor.Commands.Reason_Selected_Replacement_Stale
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
      return Availability_Metadata.Is_Available (Availability);
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
         when Command_Format_Buffer =>
            Cmd.Kind := Trim_Trailing_Whitespace;
         when Command_Format_Selected_Text =>
            Cmd.Kind := Trim_Trailing_Whitespace;
         when Command_Toggle_Format_On_Save =>
            Cmd.Kind := Toggle_Format_On_Save;
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
         when Command_Problems_Filter_All =>
            Cmd.Kind := Problems_Filter_All;
         when Command_Problems_Filter_Errors =>
            Cmd.Kind := Problems_Filter_Errors;
         when Command_Problems_Filter_Warnings =>
            Cmd.Kind := Problems_Filter_Warnings;
         when Command_Problems_Filter_Info =>
            Cmd.Kind := Problems_Filter_Info;
         when Command_Problems_Filter_Hints =>
            Cmd.Kind := Problems_Filter_Hints;
         when Command_Problems_Sort_By_Location =>
            Cmd.Kind := Problems_Sort_By_Location;
         when Command_Problems_Sort_By_Severity =>
            Cmd.Kind := Problems_Sort_By_Severity;
         when Command_Problems_Sort_By_Source =>
            Cmd.Kind := Problems_Sort_By_Source;
         when Command_Problems_Group_By_Severity =>
            Cmd.Kind := Problems_Group_By_Severity;
         when Command_Problems_Group_By_Source =>
            Cmd.Kind := Problems_Group_By_Source;
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
         when Command_Build_Result_Focus =>
            Cmd.Kind := Build_Result_Focus;
         when Command_Build_Output_Details_Focus =>
            Cmd.Kind := Build_Output_Details_Focus;
         when Command_Build_Output_Details_Select_Stdout =>
            Cmd.Kind := Build_Output_Details_Select_Stdout;
         when Command_Build_Output_Details_Select_Stderr =>
            Cmd.Kind := Build_Output_Details_Select_Stderr;
         when Command_Build_Output_Details_Select_Merged =>
            Cmd.Kind := Build_Output_Details_Select_Merged;
         when Command_Build_Refresh_Candidates =>
            Cmd.Kind := Build_Refresh_Candidates;
         when Command_Build_Select_First_Candidate =>
            Cmd.Kind := Build_Select_First_Candidate;
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
         when Command_Find_References =>
            Cmd.Kind := Find_References;
         when Command_Workspace_Symbols =>
            Cmd.Kind := Workspace_Symbols;
         when Command_Show_Hover =>
            Cmd.Kind := Show_Hover;
         when Command_Show_Completions =>
            Cmd.Kind := Show_Completions;
         when Command_Semantic_Completion_Select_Next =>
            Cmd.Kind := Semantic_Completion_Select_Next;
         when Command_Semantic_Completion_Select_Previous =>
            Cmd.Kind := Semantic_Completion_Select_Previous;
         when Command_Semantic_Completion_Accept =>
            Cmd.Kind := Semantic_Completion_Accept;
         when Command_Semantic_Popup_Dismiss =>
            Cmd.Kind := Semantic_Popup_Dismiss;
         when Command_Rename_Symbol_Preview =>
            Cmd.Kind := Rename_Symbol_Preview;
         when Command_Rename_Symbol_Apply =>
            Cmd.Kind := Rename_Symbol_Apply;
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
         when Command_Diagnostic_Open_Source =>
            Cmd.Kind := Diagnostic_Open_Source;
         when Command_Diagnostic_Suppress_Selected =>
            Cmd.Kind := Diagnostic_Suppress_Selected;
         when Command_Diagnostic_Show_Suppressed =>
            Cmd.Kind := Diagnostic_Show_Suppressed;
         when Command_Diagnostic_Restore_Last_Suppressed =>
            Cmd.Kind := Diagnostic_Restore_Last_Suppressed;
         when Command_Diagnostic_Restore_Selected_Suppressed =>
            Cmd.Kind := Diagnostic_Restore_Selected_Suppressed;
         when Command_Diagnostic_Clear_Suppressed =>
            Cmd.Kind := Diagnostic_Clear_Suppressed;
         when Command_Diagnostic_Apply_Quick_Fix =>
            Cmd.Kind := Diagnostic_Apply_Quick_Fix;
         when Command_Diagnostics_Execute_Selected_Action =>
            Cmd.Kind := Diagnostics_Execute_Selected_Action;
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
         when Command_Run_Project =>
            Cmd.Kind := Run_Project;
         when Command_Run_Tests =>
            Cmd.Kind := Run_Tests;
         when Command_Terminal_Toggle =>
            Cmd.Kind := Terminal_Toggle;
         when Command_Terminal_Show =>
            Cmd.Kind := Terminal_Show;
         when Command_Terminal_Hide =>
            Cmd.Kind := Terminal_Hide;
         when Command_Terminal_Focus =>
            Cmd.Kind := Terminal_Focus;
         when Command_Terminal_Clear =>
            Cmd.Kind := Terminal_Clear;
         when Command_Terminal_Clear_Output =>
            Cmd.Kind := Terminal_Clear_Output;
         when Command_Terminal_Select_Next_Task =>
            Cmd.Kind := Terminal_Select_Next_Task;
         when Command_Terminal_Select_Previous_Task =>
            Cmd.Kind := Terminal_Select_Previous_Task;
         when Command_Terminal_Run_Selected_Task =>
            Cmd.Kind := Terminal_Run_Selected_Task;
         when Command_Terminal_Rerun_Last_Task =>
            Cmd.Kind := Terminal_Rerun_Last_Task;
         when Command_Terminal_Cancel_Task =>
            Cmd.Kind := Terminal_Cancel_Task;
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

   --  Single static source for the retained minimal prompt metadata.
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
   begin
      return Descriptor_Metadata.Make_Command_Descriptor
        (Id            => Id,
         Stable_Name   => Stable_Name,
         Label         => Label,
         Description   => Description,
         Category      => Category,
         Visible       => Visible,
         Bindable      => Bindable,
         Destructive   => Destructive,
         Lifecycle     => Lifecycle,
         Configuration => Configuration);
   end Make_Command_Descriptor;

   function Descriptor
     (Id : Command_Id) return Command_Descriptor
   is
   begin
      return Descriptor_Metadata.Descriptor (Id);
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
            | Command_Find_References
            | Command_Workspace_Symbols
            | Command_Show_Hover
            | Command_Show_Completions
            | Command_Rename_Symbol_Preview
            | Command_Rename_Symbol_Apply
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
            | Command_Diagnostic_Open_Source
            | Command_Diagnostic_Suppress_Selected
            | Command_Diagnostic_Show_Suppressed
            | Command_Diagnostic_Restore_Last_Suppressed
            | Command_Diagnostic_Restore_Selected_Suppressed
            | Command_Diagnostic_Clear_Suppressed
            | Command_Diagnostic_Apply_Quick_Fix
            | Command_Diagnostics_Execute_Selected_Action
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
        | Command_Build_Result_Focus
        | Command_Build_Output_Details_Focus
        | Command_Build_Output_Details_Select_Stdout
        | Command_Build_Output_Details_Select_Stderr
        | Command_Build_Output_Details_Select_Merged
        | Command_Build_Refresh_Candidates
        | Command_Build_Select_First_Candidate
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
            | Command_Problems_Filter_All
            | Command_Problems_Filter_Errors
            | Command_Problems_Filter_Warnings
            | Command_Problems_Filter_Info
            | Command_Problems_Filter_Hints
            | Command_Problems_Sort_By_Location
            | Command_Problems_Sort_By_Severity
            | Command_Problems_Sort_By_Source
            | Command_Problems_Group_By_Severity
            | Command_Problems_Group_By_Source
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
            | Command_Find_References
            | Command_Workspace_Symbols
            | Command_Show_Hover
            | Command_Show_Completions
            | Command_Rename_Symbol_Preview
            | Command_Rename_Symbol_Apply
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
            | Command_Diagnostic_Open_Source
            | Command_Diagnostic_Suppress_Selected
            | Command_Diagnostic_Show_Suppressed
            | Command_Diagnostic_Restore_Last_Suppressed
            | Command_Diagnostic_Restore_Selected_Suppressed
            | Command_Diagnostic_Clear_Suppressed
            | Command_Diagnostic_Apply_Quick_Fix
            | Command_Diagnostics_Execute_Selected_Action
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
            | Command_Format_Buffer
            | Command_Format_Selected_Text
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
   begin
      return Name_Metadata.Stable_Command_Name (Id);
   end Stable_Command_Name;

   function Command_Id_From_Stable_Name
     (Name  : String;
      Found : out Boolean) return Command_Id
   is
   begin
      return Name_Metadata.Command_Id_From_Stable_Name (Name, Found);
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
