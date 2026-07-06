with Editor.Commands;
with Editor.State;

package Editor.Executor.Semantic_Routing_Commands is

   procedure Execute_Semantic_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

end Editor.Executor.Semantic_Routing_Commands;
