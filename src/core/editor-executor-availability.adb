with Editor.Commands.Availability_Metadata;
with Editor.Executor.Command_Kind_Availability_Commands;
with Editor.Commands;
with Editor.State;

package body Editor.Executor.Availability is

   function Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability
   is
   begin
      return Editor.Executor.Command_Kind_Availability_Commands
        .Command_Availability (S, Id);
   end Command_Availability;

end Editor.Executor.Availability;
