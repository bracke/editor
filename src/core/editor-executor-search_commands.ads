with Editor.Commands;
with Editor.State;

package Editor.Executor.Search_Commands is

   function Project_Search_Command_Availability
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id)
      return Editor.Commands.Command_Availability;

   procedure Execute_Project_Search_Scope_Selected_Directory
     (S : in out Editor.State.State_Type);

   procedure Execute_Project_Search_Kind
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command);

end Editor.Executor.Search_Commands;
