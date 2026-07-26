with Editor.Command_Ids; use Editor.Command_Ids;
with Editor.Commands.Payloads;
with Editor.State;

package Editor.Input_Bridge.Command_Palette_Handlers is

   function Handle_Command_Palette
     (S              : in out Editor.State.State_Type;
      Cmd            : Editor.Commands.Payloads.Command;
      Execute        : not null access procedure
        (Id : Editor.Command_Ids.Command_Id);
      Report_Info    : not null access procedure (Message : String);
      Report_Warning : not null access procedure (Message : String))
      return Boolean;

end Editor.Input_Bridge.Command_Palette_Handlers;
