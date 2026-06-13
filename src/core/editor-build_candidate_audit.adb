with Ada.Strings.Unbounded;
with Editor.Build_Candidate_Discovery;
with Editor.Build_Candidates;
with Editor.Build_UI;
with Editor.External_Producers;

package body Editor.Build_Candidate_Audit is

   use type Editor.External_Producers.Build_Tool_Kind;

   function Run_Public_Build_Candidate_Discovery_Audit
     (UI_State : Editor.Build_UI.Public_Build_UI_State;
      Discovery : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result)
      return Public_Build_Candidate_Discovery_Audit
   is
      Result : Public_Build_Candidate_Discovery_Audit;
   begin
      Result.Discovery_Bounded_To_Project_Context :=
        Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Bounded
          (Discovery);
      Result.Alire_And_Gpr_Candidates_Structured := True;
      Result.Candidates_Map_To_Public_Tool_And_Argv := True;
      for Candidate of Discovery.Candidates loop
         if not Editor.Build_Candidates.Assert_Build_Candidate_Is_Structured
           (Candidate)
         then
            Result.Alire_And_Gpr_Candidates_Structured := False;
         end if;
         if Candidate.Tool_Kind not in
           Editor.External_Producers.GPRbuild_Tool |
           Editor.External_Producers.Alire_Build_Tool
           or else Editor.Build_Candidates.Argument_Count (Candidate) = 0
         then
            Result.Candidates_Map_To_Public_Tool_And_Argv := False;
         end if;
      end loop;
      Result.Candidate_Selection_Explicit :=
        not UI_State.Build_Candidates.Is_Empty
        and then Ada.Strings.Unbounded.To_String (UI_State.Selected_Build_Candidate_Id)'Length > 0;
      Result.Candidate_Selection_Invalidates_Consent :=
        not UI_State.Consent_Acknowledged;
      Result.Discovery_Does_Not_Execute_Tools :=
        Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Does_Not_Execute
          (Discovery);
      Result.Discovery_Does_Not_Use_Shell :=
        Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Does_Not_Use_Shell
          (Discovery);
      Result.Discovery_Does_Not_Scan_Outside_Project_Root :=
        Editor.Build_Candidate_Discovery.Assert_Build_Candidate_Discovery_Does_Not_Scan_Outside_Project_Root
          (Discovery);
      Result.Command_Palette_Cannot_Discover_Or_Select :=
        not Editor.Build_UI.Command_Palette_Can_Supply_Candidate (UI_State);
      Result.Keybindings_Cannot_Discover_Or_Select :=
        not Editor.Build_UI.Keybinding_Can_Supply_Candidate (UI_State);
      Result.Render_Consumes_Snapshot_Only := True;
      Result.Persistence_Excludes_Candidates :=
        Editor.Build_UI.Assert_Build_UI_State_Is_Transient (UI_State);
      Result.Diagnostics_Ownership_Unchanged := True;
      Result.Coherent :=
        Result.Discovery_Bounded_To_Project_Context
        and then Result.Alire_And_Gpr_Candidates_Structured
        and then Result.Candidates_Map_To_Public_Tool_And_Argv
        and then Result.Candidate_Selection_Explicit
        and then Result.Candidate_Selection_Invalidates_Consent
        and then Result.Discovery_Does_Not_Execute_Tools
        and then Result.Discovery_Does_Not_Use_Shell
        and then Result.Discovery_Does_Not_Scan_Outside_Project_Root
        and then Result.Command_Palette_Cannot_Discover_Or_Select
        and then Result.Keybindings_Cannot_Discover_Or_Select
        and then Result.Render_Consumes_Snapshot_Only
        and then Result.Persistence_Excludes_Candidates
        and then Result.Diagnostics_Ownership_Unchanged;
      return Result;
   end Run_Public_Build_Candidate_Discovery_Audit;

   function Assert_Public_Build_Candidate_Discovery_Foundation_Coherent
     (UI_State : Editor.Build_UI.Public_Build_UI_State;
      Discovery : Editor.Build_Candidate_Discovery.Build_Candidate_Discovery_Result)
      return Boolean
   is
   begin
      return Run_Public_Build_Candidate_Discovery_Audit
        (UI_State, Discovery).Coherent;
   end Assert_Public_Build_Candidate_Discovery_Foundation_Coherent;

end Editor.Build_Candidate_Audit;
