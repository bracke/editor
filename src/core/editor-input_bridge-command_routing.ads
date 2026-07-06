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

   function Handle_Active_Overlay
     (S                         : in out Editor.State.State_Type;
      Cmd                       : Editor.Commands.Command;
      Handle_Command_Palette    : not null access function
        (Cmd : Editor.Commands.Command) return Boolean;
      Handle_Quick_Open         : not null access function
        (Cmd : Editor.Commands.Command) return Boolean;
      Handle_Buffer_Switcher    : not null access function
        (Cmd : Editor.Commands.Command) return Boolean;
      Handle_Project_Search_Bar : not null access function
        (Cmd : Editor.Commands.Command) return Boolean;
      Handle_Goto_Line          : not null access function
        (Cmd : Editor.Commands.Command) return Boolean;
      Handle_Active_Find_Input  : not null access function
        (Cmd : Editor.Commands.Command) return Boolean;
      Handle_File_Target_Prompt : not null access function
        (Cmd : Editor.Commands.Command) return Boolean)
      return Boolean;

   function Handle_Focused_Panel_Input
     (S                           : in out Editor.State.State_Type;
      Cmd                         : Editor.Commands.Command;
      Handle_Search_Query_Input   : not null access function
        (Cmd : Editor.Commands.Command) return Boolean;
      Handle_Outline_Filter_Input : not null access function
        (Cmd : Editor.Commands.Command) return Boolean)
      return Boolean;

end Editor.Input_Bridge.Command_Routing;
