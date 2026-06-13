with Editor.Build_Candidates;
with Editor.Build_UI;

package body Editor.Build_Candidate_Selection is

   procedure Select_Build_Candidate
     (State        : in out Editor.Build_UI.Public_Build_UI_State;
      Candidate_Id : String)
   is
   begin
      Editor.Build_UI.Select_Build_Candidate (State, Candidate_Id);
   end Select_Build_Candidate;

   procedure Clear_Selected_Build_Candidate
     (State : in out Editor.Build_UI.Public_Build_UI_State)
   is
   begin
      Editor.Build_UI.Clear_Selected_Build_Candidate (State);
   end Clear_Selected_Build_Candidate;

   procedure Apply_Build_Candidate_To_UI_State
     (State     : in out Editor.Build_UI.Public_Build_UI_State;
      Candidate : Editor.Build_Candidates.Build_Candidate_Record)
   is
   begin
      Editor.Build_UI.Apply_Build_Candidate_To_UI_State (State, Candidate);
   end Apply_Build_Candidate_To_UI_State;

   function Build_Candidate_Request_Preview
     (State : Editor.Build_UI.Public_Build_UI_State) return String
   is
   begin
      return Editor.Build_UI.Build_Candidate_Request_Preview (State);
   end Build_Candidate_Request_Preview;

   procedure Invalidate_Consent_On_Candidate_Selection
     (State : in out Editor.Build_UI.Public_Build_UI_State)
   is
   begin
      Editor.Build_UI.Clear_Consent (State);
   end Invalidate_Consent_On_Candidate_Selection;

end Editor.Build_Candidate_Selection;
