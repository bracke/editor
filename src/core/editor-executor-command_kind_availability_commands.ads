with Editor.Commands.Availability_Metadata;
with Editor.Commands;
with Editor.State;

package Editor.Executor.Command_Kind_Availability_Commands is

   function Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability;

end Editor.Executor.Command_Kind_Availability_Commands;
