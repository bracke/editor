with Editor.Command_Execution;
with Editor.Commands;
with Editor.Ada_Language_Service;
with Editor.State;

package Editor.Executor.Semantic_Commands is

   function Semantic_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   function Service_Status_Image
     (Status : Editor.Ada_Language_Service.Service_Status) return String;

   function Execute_Semantic_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Commands.Command_Id;
      Cmd : Editor.Commands.Command)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Semantic_Commands;
