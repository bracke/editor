with Editor.Commands;
with Editor.Command_Execution;
with Editor.State;

package Editor.Executor.Semantic_Routing_Commands is

   procedure Execute_Semantic_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

   function Execute_Semantic_Result_Command
     (S  : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Semantic_Routing_Commands;
