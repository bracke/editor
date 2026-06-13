with Editor.Build_Candidates;
with Editor.Build_UI;

package Editor.Build_Candidate_Selection is

   --  Phase 507 public build candidate selection UX foundation.  This package
   --  is only a named seam around transient Build_UI state mutation.  It does
   --  not discover candidates, execute candidates, acknowledge consent,
   --  persist selection, or create shell command text.

   procedure Select_Build_Candidate
     (State        : in out Editor.Build_UI.Public_Build_UI_State;
      Candidate_Id : String);

   procedure Clear_Selected_Build_Candidate
     (State : in out Editor.Build_UI.Public_Build_UI_State);

   procedure Apply_Build_Candidate_To_UI_State
     (State     : in out Editor.Build_UI.Public_Build_UI_State;
      Candidate : Editor.Build_Candidates.Build_Candidate_Record);

   function Build_Candidate_Request_Preview
     (State : Editor.Build_UI.Public_Build_UI_State) return String;

   procedure Invalidate_Consent_On_Candidate_Selection
     (State : in out Editor.Build_UI.Public_Build_UI_State);

end Editor.Build_Candidate_Selection;
