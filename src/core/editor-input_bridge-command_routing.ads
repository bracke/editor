with Editor.Commands;
with Editor.State;

package Editor.Input_Bridge.Command_Routing is

   function Handle_Pending_Confirmation_Gate
     (S      : Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Report : not null access procedure (Message : String)) return Boolean;

   function Handle_Current_Focus_Gate
     (S      : Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Report : not null access procedure (Message : String)) return Boolean;

   function Handle_Command_Availability_Gate
     (S      : Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Report : not null access procedure (Message : String)) return Boolean;

   function Handle_Guided_Prompt_Start_Availability_Gate
     (S      : Editor.State.State_Type;
      Id     : Editor.Commands.Command_Id;
      Report : not null access procedure (Message : String)) return Boolean;

end Editor.Input_Bridge.Command_Routing;
