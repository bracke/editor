with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Availability_Metadata;
with Editor.State;

package Editor.Executor.Project_Lifecycle_Availability_Commands is

   function Project_Lifecycle_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability;

end Editor.Executor.Project_Lifecycle_Availability_Commands;
