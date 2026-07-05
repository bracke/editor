with Editor.Commands;
with Editor.State;

package Editor.Executor.Availability is

   function Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

end Editor.Executor.Availability;
