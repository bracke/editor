with Editor.Input_Bridge.Build_UI_Pointer_Handlers;
with Editor.Input_Bridge.Gutter_Pointer_Handlers;
with Editor.Input_Bridge.Panel_Bars_Pointer_Handlers;
with Editor.Input_Bridge.Panel_Feature_Problems_Pointer_Handlers;
with Editor.Input_Bridge.Panel_Tree_Search_Pointer_Handlers;
with Editor.Input_Bridge.Pointer_Scroll_Handlers;

package body Editor.Input_Bridge.Pointer_Surface_Handlers is

   function Handle_Minimap_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Pointer_Scroll_Handlers.Handle_Minimap_Pointer (S, Cmd);
   end Handle_Minimap_Pointer;

   function Handle_Scrollbar_Pointer
     (S                       : in out Editor.State.State_Type;
      Cmd                     : Editor.Commands.Command;
      Max_Visible_Line_Length : Natural) return Boolean
   is
   begin
      return Pointer_Scroll_Handlers.Handle_Scrollbar_Pointer
        (S, Cmd, Max_Visible_Line_Length);
   end Handle_Scrollbar_Pointer;

   function Handle_Gutter_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Gutter_Pointer_Handlers.Handle_Gutter_Pointer (S, Cmd);
   end Handle_Gutter_Pointer;

   function Handle_Message_Overlay_Pointer
     (Cmd : Editor.Commands.Command) return Boolean
   is
      pragma Unreferenced (Cmd);
   begin
      --  Transient messages are passive feedback and must not capture pointer
      --  input or disturb focus.
      return False;
   end Handle_Message_Overlay_Pointer;

   function Handle_Pending_Transition_Bar_Pointer
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Boolean
   is
   begin
      return Panel_Bars_Pointer_Handlers.Handle_Pending_Transition_Bar_Pointer
        (S, Cmd, Execute);
   end Handle_Pending_Transition_Bar_Pointer;

   function Handle_Build_UI_Panel_Pointer
     (S           : in out Editor.State.State_Type;
      Cmd         : Editor.Commands.Command;
      Execute     : not null access procedure
        (Id : Editor.Commands.Command_Id);
      Report_Info : not null access procedure (Message : String))
      return Boolean
   is
   begin
      return Build_UI_Pointer_Handlers.Handle_Build_UI_Panel_Pointer
        (S, Cmd, Execute, Report_Info);
   end Handle_Build_UI_Panel_Pointer;

   function Handle_Tab_Bar_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Panel_Bars_Pointer_Handlers.Handle_Tab_Bar_Pointer (S, Cmd);
   end Handle_Tab_Bar_Pointer;

   function Handle_Status_Bar_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Panel_Bars_Pointer_Handlers.Handle_Status_Bar_Pointer (S, Cmd);
   end Handle_Status_Bar_Pointer;

   function Handle_Panel_Splitter_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Panel_Bars_Pointer_Handlers.Handle_Panel_Splitter_Pointer
        (S, Cmd);
   end Handle_Panel_Splitter_Pointer;

   function Handle_File_Tree_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Panel_Tree_Search_Pointer_Handlers.Handle_File_Tree_Pointer
        (S, Cmd);
   end Handle_File_Tree_Pointer;

   function Handle_Search_Results_Panel_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Panel_Tree_Search_Pointer_Handlers
        .Handle_Search_Results_Panel_Pointer (S, Cmd);
   end Handle_Search_Results_Panel_Pointer;

   function Handle_Feature_Panel_Pointer
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      return Panel_Feature_Problems_Pointer_Handlers
        .Handle_Feature_Panel_Pointer (S, Cmd);
   end Handle_Feature_Panel_Pointer;

   function Handle_Problems_Panel_Pointer
     (S       : in out Editor.State.State_Type;
      Cmd     : Editor.Commands.Command;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Boolean
   is
   begin
      return Panel_Feature_Problems_Pointer_Handlers
        .Handle_Problems_Panel_Pointer (S, Cmd, Execute);
   end Handle_Problems_Panel_Pointer;

end Editor.Input_Bridge.Pointer_Surface_Handlers;
