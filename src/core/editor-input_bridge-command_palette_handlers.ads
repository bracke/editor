with Editor.Commands;
with Editor.State;

package Editor.Input_Bridge.Command_Palette_Handlers is

   function Handle_Command_Palette
     (S              : in out Editor.State.State_Type;
      Cmd            : Editor.Commands.Command;
      Execute        : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Report_Info    : not null access procedure (Message : String);
      Report_Warning : not null access procedure (Message : String))
      return Boolean;

end Editor.Input_Bridge.Command_Palette_Handlers;
