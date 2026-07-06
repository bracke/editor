with Editor.Commands;
with Editor.State;

package Editor.Input_Bridge.File_Target_Handlers is

   function Handle_File_Target_Prompt
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

end Editor.Input_Bridge.File_Target_Handlers;
