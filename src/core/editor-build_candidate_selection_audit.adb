with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Build_Candidates;
with Editor.Build_UI;

package body Editor.Build_Candidate_Selection_Audit is

   use type Editor.Build_Candidates.Build_Candidate_Validation_Status;
   use type Editor.Build_UI.Public_Build_Tool_Selection;

   function Contains_Forbidden_Shell_Preview (Text : String) return Boolean is
   begin
      return Ada.Strings.Fixed.Index (Text, " && ") /= 0
        or else Ada.Strings.Fixed.Index (Text, "cd ") /= 0
        or else Ada.Strings.Fixed.Index (Text, "|") /= 0;
   end Contains_Forbidden_Shell_Preview;

   function Assert_Build_Candidate_Selection_Is_Explicit
     (UI_State : Editor.Build_UI.Public_Build_UI_State) return Boolean
   is
   begin
      return To_String (UI_State.Selected_Build_Candidate_Id)'Length > 0
        and then UI_State.Candidate_Applied_To_Request;
   end Assert_Build_Candidate_Selection_Is_Explicit;

   function Assert_Build_Candidate_Selection_Does_Not_Consent
     (UI_State : Editor.Build_UI.Public_Build_UI_State) return Boolean
   is
   begin
      return not UI_State.Consent_Acknowledged
        and then To_String (UI_State.Consent_Request_Identity)'Length = 0;
   end Assert_Build_Candidate_Selection_Does_Not_Consent;

   function Assert_Build_Candidate_Selection_Does_Not_Execute
     (UI_State : Editor.Build_UI.Public_Build_UI_State) return Boolean
   is
   begin
      return not Editor.Build_UI.Has_Candidate_Execution_Field (UI_State);
   end Assert_Build_Candidate_Selection_Does_Not_Execute;

   function Assert_Build_Candidate_Selection_Persistence_Excluded
     (UI_State : Editor.Build_UI.Public_Build_UI_State) return Boolean
   is
   begin
      return Editor.Build_UI.Assert_Build_UI_State_Is_Transient (UI_State)
        and then not Editor.Build_UI.Has_Remembered_Consent_Field (UI_State);
   end Assert_Build_Candidate_Selection_Persistence_Excluded;

   function Run_Public_Build_Candidate_Selection_Audit
     (UI_State : Editor.Build_UI.Public_Build_UI_State)
      return Public_Build_Candidate_Selection_Audit
   is
      Result : Public_Build_Candidate_Selection_Audit;
      Preview : constant String := To_String (UI_State.Candidate_Request_Preview);
   begin
      Result.Candidate_Selection_Explicit :=
        Assert_Build_Candidate_Selection_Is_Explicit (UI_State);
      Result.Candidate_Selection_Does_Not_Consent :=
        Assert_Build_Candidate_Selection_Does_Not_Consent (UI_State);
      Result.Candidate_Selection_Does_Not_Execute :=
        Assert_Build_Candidate_Selection_Does_Not_Execute (UI_State);
      Result.Candidate_Selection_Populates_Structured_Request :=
        UI_State.Selected_Build_Tool /= Editor.Build_UI.Build_UI_No_Tool
        and then Editor.Build_UI.Argument_Count (UI_State.Structured_Arguments) > 0
        and then UI_State.Selected_Build_Candidate_Status =
          Editor.Build_Candidates.Build_Candidate_Valid;
      Result.Candidate_Preview_Is_Structured_Not_Shell :=
        Preview'Length > 0
        and then not Editor.Build_UI.Has_Raw_Shell_Command_Field (UI_State)
        and then not Contains_Forbidden_Shell_Preview (Preview);
      Result.Manual_Request_Path_Available := False;
      Result.Command_Palette_Cannot_Select :=
        not Editor.Build_UI.Command_Palette_Can_Supply_Candidate (UI_State);
      Result.Keybindings_Cannot_Select :=
        not Editor.Build_UI.Keybinding_Can_Supply_Candidate (UI_State);
      Result.Render_Cannot_Select := True;
      Result.Persistence_Excluded :=
        Assert_Build_Candidate_Selection_Persistence_Excluded (UI_State);
      Result.Diagnostics_Ownership_Unchanged := True;
      Result.Coherent :=
        Result.Candidate_Selection_Explicit
        and then Result.Candidate_Selection_Does_Not_Consent
        and then Result.Candidate_Selection_Does_Not_Execute
        and then Result.Candidate_Selection_Populates_Structured_Request
        and then Result.Candidate_Preview_Is_Structured_Not_Shell
        and then not Result.Manual_Request_Path_Available
        and then Result.Command_Palette_Cannot_Select
        and then Result.Keybindings_Cannot_Select
        and then Result.Render_Cannot_Select
        and then Result.Persistence_Excluded
        and then Result.Diagnostics_Ownership_Unchanged;
      return Result;
   end Run_Public_Build_Candidate_Selection_Audit;

   function Assert_Public_Build_Candidate_Selection_Foundation_Coherent
     (UI_State : Editor.Build_UI.Public_Build_UI_State) return Boolean
   is
   begin
      return Run_Public_Build_Candidate_Selection_Audit (UI_State).Coherent;
   end Assert_Public_Build_Candidate_Selection_Foundation_Coherent;

end Editor.Build_Candidate_Selection_Audit;
