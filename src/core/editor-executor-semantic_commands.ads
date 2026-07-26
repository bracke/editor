with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Availability_Metadata;
with Editor.Commands.Payloads;
with Editor.Command_Execution;
with Editor.Ada_Language_Service;
with Editor.State;

package Editor.Executor.Semantic_Commands is

   function Semantic_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability;

   function Service_Status_Image
     (Status : Editor.Ada_Language_Service.Service_Status) return String;

   function Execute_Semantic_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id;
      Cmd : Editor.Commands.Payloads.Command)
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Semantic_Commands;
