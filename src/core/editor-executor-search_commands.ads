with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Availability_Metadata;
with Editor.Commands.Payloads;
with Editor.State;

package Editor.Executor.Search_Commands is

   function Project_Search_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Command_Ids.Command_Id)
      return Editor.Commands.Availability_Metadata.Command_Availability;

   procedure Execute_Project_Search_Scope_Selected_Directory
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Payloads.Command);

end Editor.Executor.Search_Commands;
