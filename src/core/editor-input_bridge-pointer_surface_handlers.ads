with Editor.Commands;
with Editor.State;

package Editor.Input_Bridge.Pointer_Surface_Handlers is

   function Handle_Minimap_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

   function Handle_Scrollbar_Pointer
     (S                       : in out Editor.State.State_Type;
      Cmd                     : Editor.Commands.Command;
      Max_Visible_Line_Length : Natural) return Boolean;

   function Handle_Gutter_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

   function Handle_Message_Overlay_Pointer
     (Cmd : Editor.Commands.Command) return Boolean;

   function Handle_Pending_Transition_Bar_Pointer
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Boolean;

   function Handle_Build_UI_Panel_Pointer
     (S           : in out Editor.State.State_Type;
      Cmd         : Editor.Commands.Command;
      Execute     : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Report_Info : not null access procedure (Message : String))
      return Boolean;

   function Handle_Tab_Bar_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

   function Handle_Status_Bar_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

   function Handle_Panel_Splitter_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

   function Handle_File_Tree_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

   function Handle_Search_Results_Panel_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

   function Handle_Feature_Panel_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean;

   function Handle_Problems_Panel_Pointer
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Boolean;

end Editor.Input_Bridge.Pointer_Surface_Handlers;
