with Editor.Build_UI;

package Editor.Build_Candidate_Selection_Audit is

   type Public_Build_Candidate_Selection_Audit is record
      Candidate_Selection_Explicit : Boolean := False;
      Candidate_Selection_Does_Not_Consent : Boolean := False;
      Candidate_Selection_Does_Not_Execute : Boolean := False;
      Candidate_Selection_Populates_Structured_Request : Boolean := False;
      Candidate_Preview_Is_Structured_Not_Shell : Boolean := False;
      Manual_Request_Path_Available : Boolean := False;
      Command_Palette_Cannot_Select : Boolean := False;
      Keybindings_Cannot_Select : Boolean := False;
      Render_Cannot_Select : Boolean := False;
      Persistence_Excluded : Boolean := False;
      Diagnostics_Ownership_Unchanged : Boolean := False;
      Coherent : Boolean := False;
   end record;

   function Run_Public_Build_Candidate_Selection_Audit
     (UI_State : Editor.Build_UI.Public_Build_UI_State)
      return Public_Build_Candidate_Selection_Audit;

   function Assert_Build_Candidate_Selection_Is_Explicit
     (UI_State : Editor.Build_UI.Public_Build_UI_State) return Boolean;

   function Assert_Build_Candidate_Selection_Does_Not_Consent
     (UI_State : Editor.Build_UI.Public_Build_UI_State) return Boolean;

   function Assert_Build_Candidate_Selection_Does_Not_Execute
     (UI_State : Editor.Build_UI.Public_Build_UI_State) return Boolean;

   function Assert_Build_Candidate_Selection_Persistence_Excluded
     (UI_State : Editor.Build_UI.Public_Build_UI_State) return Boolean;

   function Assert_Public_Build_Candidate_Selection_Foundation_Coherent
     (UI_State : Editor.Build_UI.Public_Build_UI_State) return Boolean;

end Editor.Build_Candidate_Selection_Audit;
