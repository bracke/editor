with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Availability_Metadata;
with Editor.Command_Execution;
with Editor.State;

package Editor.Executor.Semantic_Language_Command_Surface is

   function Selected_Language_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability;

   function Execute_Selected_Language_Command
     (S  : in out Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id;
      Target_Name : String := "")
      return Editor.Command_Execution.Command_Execution_Result;

end Editor.Executor.Semantic_Language_Command_Surface;
