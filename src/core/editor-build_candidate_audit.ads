with Editor.Build_Candidate_Discovery;
with Editor.Build_UI;

package Editor.Build_Candidate_Audit is

   type Public_Build_Candidate_Discovery_Audit is record
      Discovery_Bounded_To_Project_Context : Boolean := False;
      Alire_And_Gpr_Candidates_Structured : Boolean := False;
      Candidates_Map_To_Public_Tool_And_Argv : Boolean := False;
      Candidate_Selection_Explicit : Boolean := False;
      Candidate_Selection_Invalidates_Consent : Boolean := False;
      Discovery_Does_Not_Execute_Tools : Boolean := False;
      Discovery_Does_Not_Use_Shell : Boolean := False;
      Discovery_Does_Not_Scan_Outside_Project_Root : Boolean := False;
      Command_Palette_Cannot_Discover_Or_Select : Boolean := False;
      Keybindings_Cannot_Discover_Or_Select : Boolean := False;
      Render_Consumes_Snapshot_Only : Boolean := False;
      Persistence_Excludes_Candidates : Boolean := False;
      Diagnostics_Ownership_Unchanged : Boolean := False;
      Coherent : Boolean := False;
   end record;

   function Run_Public_Build_Candidate_Discovery_Audit
     (UI_State : Editor.Build_UI.Public_Build_UI_State;
      Discovery : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result)
      return Public_Build_Candidate_Discovery_Audit;

   function Assert_Public_Build_Candidate_Discovery_Foundation_Coherent
     (UI_State : Editor.Build_UI.Public_Build_UI_State;
      Discovery : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result)
      return Boolean;

end Editor.Build_Candidate_Audit;
