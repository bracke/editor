with Editor.Commands;
with Editor.Command_Execution;
with Editor.State;

package Editor.Executor.File_Tree_Commands is

   function File_Tree_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Execute_File_Tree_Result_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Command_Execution.Command_Execution_Result;

   procedure Execute_File_Tree_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

end Editor.Executor.File_Tree_Commands;
