with Editor.Commands;
with Editor.State;

package Editor.Executor.Command_Palette_Projection is

   procedure Command_Palette_Candidates
     (S      : Editor.State.State_Type;
      Result : out Editor.Commands.Command_Palette_Candidate_Vectors.Vector);

end Editor.Executor.Command_Palette_Projection;
