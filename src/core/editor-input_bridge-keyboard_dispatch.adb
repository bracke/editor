with Editor.Commands;
with Editor.Commands.Payloads;
with Editor.Cursor;
with Editor.Executor.Clipboard;
with Editor.Executor.Find_Replace_Input_Commands;
with Editor.Input_Bridge.Buffer_Switcher_Key_Handlers;
with Editor.Input_Bridge.Build_UI_Key_Handlers;
with Editor.Input_Bridge.Feature_Panel_Key_Handlers;
with Editor.Input_Bridge.File_Target_Key_Handlers;
with Editor.Input_Bridge.File_Tree_Key_Handlers;
with Editor.Input_Bridge.Goto_Line_Key_Handlers;
with Editor.Input_Bridge.Key_Chord_Routing;
with Editor.Input_Bridge.Panel_Focus_Key_Handlers;
with Editor.Input_Bridge.Project_Search_Key_Handlers;
with Editor.Input_Bridge.Quick_Open_Key_Handlers;
with Editor.Instance;
with Editor.Keybindings;
with Editor.Overlay_Focus;
with Editor.View;

package body Editor.Input_Bridge.Keyboard_Dispatch is

   use type Editor.Commands.Command_Id;
   use type Editor.Keybindings.Binding_Result;

   procedure Handle_Key_Chord
     (Instance                   : in out Editor.Instance.Editor_Instance;
      Initialized                : Boolean;
      Chord                      : Editor.Keybindings.Key_Chord;
      Accept_Guided_Prompt_Enter : not null access procedure;
      Report_Info                : not null access procedure (Text : String);
      Handle_Command_Palette     : not null access function
        (Cmd : Editor.Commands.Payloads.Command) return Boolean;
      Execute_Command_Id         : not null access procedure
        (Id : Editor.Commands.Command_Id; Shift : Boolean))
   is
      Id  : Editor.Commands.Command_Id;
      Cmd : Editor.Commands.Payloads.Command;

      procedure Execute_Command_Id_Default
        (Command_Id : Editor.Commands.Command_Id)
      is
      begin
         Execute_Command_Id (Command_Id, False);
      end Execute_Command_Id_Default;

      procedure Execute_Instance_Command_Default
        (Command : Editor.Commands.Payloads.Command)
      is
      begin
         Editor.Instance.Execute (Instance, Command);
      end Execute_Instance_Command_Default;

      procedure Execute_Command_Id_With_Shift
        (Command_Id : Editor.Commands.Command_Id;
         Shift      : Boolean)
      is
      begin
         Execute_Command_Id (Command_Id, Shift);
      end Execute_Command_Id_With_Shift;

      procedure Execute_Active_Find_Previous_Default is
      begin
         Execute_Command_Id
           (Editor.Commands.Command_Active_Find_Previous, False);
      end Execute_Active_Find_Previous_Default;

      procedure Hide_Active_Find_Default is
      begin
         Cmd.Kind := Editor.Commands.Active_Find_Hide;
         Editor.Instance.Execute (Instance, Cmd);
      end Hide_Active_Find_Default;
   begin
      pragma Assert (Initialized,
         "Input_Bridge must be initialized before handling key chords");

      if Key_Chord_Routing.Handle_Pre_Bound_Chord
        (Instance.State,
         Chord,
         Accept_Guided_Prompt_Enter,
         Report_Info,
         Execute_Command_Id_With_Shift'Access,
         Execute_Command_Id_Default'Access,
         Execute_Active_Find_Previous_Default'Access,
         Hide_Active_Find_Default'Access)
      then
         return;
      end if;

      if Key_Chord_Routing.Handle_Focused_Surface_Pre_Bound_Chord
        (Instance.State, Chord, Execute_Command_Id_Default'Access)
      then
         return;
      end if;

      if Editor.Keybindings.Resolve (Chord, Id) = Editor.Keybindings.Bound_Command then
         Cmd := Editor.Commands.Payloads.Command_For_Id (Id, Chord.Modifiers.Shift);

         if Editor.Overlay_Focus.Is_Active
           (Instance.State.Overlay_Focus,
            Editor.Overlay_Focus.Command_Palette_Overlay)
         then
            if Handle_Command_Palette (Cmd) then
               Editor.Cursor.Notify_Input
                 (Float (Editor.View.Current_Time_Seconds));
            end if;
         elsif Editor.Input_Bridge.Quick_Open_Key_Handlers
           .Handle_Quick_Open_Key
             (Instance.State, Chord,
              Execute_Command_Id_Default'Access,
              Execute_Instance_Command_Default'Access)
         then
            null;
         elsif Editor.Input_Bridge.Buffer_Switcher_Key_Handlers
           .Handle_Buffer_Switcher_Key
             (Instance.State, Chord,
              Execute_Command_Id_Default'Access,
              Execute_Instance_Command_Default'Access)
         then
            null;
         elsif Editor.Input_Bridge.Project_Search_Key_Handlers
           .Handle_Project_Search_Bar_Key
             (Instance.State, Chord,
              Execute_Command_Id_Default'Access,
              Execute_Instance_Command_Default'Access)
         then
            null;
         elsif Editor.Input_Bridge.File_Target_Key_Handlers
           .Handle_File_Target_Key (Instance.State, Chord)
         then
            null;
         elsif Editor.Input_Bridge.Goto_Line_Key_Handlers
           .Handle_Goto_Line_Key
             (Instance.State, Chord,
              Execute_Command_Id_Default'Access,
              Execute_Instance_Command_Default'Access)
         then
            null;
         elsif Editor.Overlay_Focus.Is_Active
           (Instance.State.Overlay_Focus,
            Editor.Overlay_Focus.Active_Find_Prompt_Overlay)
           and then (Id = Editor.Commands.Command_Active_Find_Next
                     or else Id = Editor.Commands.Command_Active_Find_Previous
                     or else Id = Editor.Commands.Command_Find_First
                     or else Id = Editor.Commands.Command_Find_Last
                     or else Id = Editor.Commands.Command_Find_Reveal_Current
                     or else Id = Editor.Commands.Command_Find_From_Selection
                     or else Id = Editor.Commands.Command_Find_From_Active_Word
                     or else Id = Editor.Commands.Command_Find_Query_Clear
                     or else Id = Editor.Commands.Command_Find_Case_Toggle
                     or else Id = Editor.Commands.Command_Find_Case_Clear
                     or else Id = Editor.Commands.Command_Find_Whole_Word_Toggle
                     or else Id = Editor.Commands.Command_Find_Whole_Word_Clear
                     or else Id = Editor.Commands.Command_Replace_Show
                     or else Id = Editor.Commands.Command_Replace_Hide
                     or else Id = Editor.Commands.Command_Replace_Toggle
                     or else Id = Editor.Commands.Command_Replace_Text_Clear
                     or else Id = Editor.Commands.Command_Replace_Current
                     or else Id = Editor.Commands.Command_Replace_All)
         then
            Execute_Command_Id (Id, Chord.Modifiers.Shift);
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         elsif Instance.State.Active_Find_Prompt
           and then Editor.Overlay_Focus.Is_Active
             (Instance.State.Overlay_Focus,
              Editor.Overlay_Focus.Active_Find_Prompt_Overlay)
         then
            case Chord.Key is
               when Editor.Keybindings.Key_Enter =>
                  if Chord.Modifiers.Shift then
                     Execute_Command_Id
                       (Editor.Commands.Command_Active_Find_Previous, False);
                  else
                     Execute_Command_Id
                       (Editor.Commands.Command_Active_Find_Next, False);
                  end if;
               when Editor.Keybindings.Key_Escape =>
                  Execute_Command_Id (Editor.Commands.Command_Find_Hide, False);
               when Editor.Keybindings.Key_Tab =>
                  null;
               when Editor.Keybindings.Key_Backspace =>
                  Cmd.Kind := Editor.Commands.Active_Find_Input_Backspace;
                  Editor.Instance.Execute (Instance, Cmd);
               when Editor.Keybindings.Key_Delete =>
                  Cmd.Kind := Editor.Commands.Active_Find_Input_Delete_Forward;
                  Editor.Instance.Execute (Instance, Cmd);
               when Editor.Keybindings.Key_Left =>
                  Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Move_Cursor_Left
                    (Instance.State);
               when Editor.Keybindings.Key_Right =>
                  Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Move_Cursor_Right
                    (Instance.State);
               when Editor.Keybindings.Key_Home =>
                  Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Move_Cursor_Start
                    (Instance.State);
               when Editor.Keybindings.Key_End =>
                  Editor.Executor.Find_Replace_Input_Commands.Execute_Active_Find_Input_Move_Cursor_End
                    (Instance.State);
               when Editor.Keybindings.Key_V =>
                  if Chord.Modifiers.Ctrl then
                     Cmd.Kind := Editor.Commands.Active_Find_Input_Insert_Text;
                     Cmd.Text :=
                       Editor.Executor.Clipboard.Text_For_Local_Input;
                     Editor.Instance.Execute (Instance, Cmd);
                  end if;
               when others =>
                  null;
            end case;
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         elsif Editor.Input_Bridge.Feature_Panel_Key_Handlers
           .Handle_Feature_Panel_Key
             (Instance.State, Chord, Execute_Command_Id_Default'Access)
         then
            null;
         elsif Editor.Input_Bridge.File_Tree_Key_Handlers.Handle_File_Tree_Key
           (Instance.State, Chord, Execute_Command_Id_Default'Access)
         then
            null;
         elsif Editor.Input_Bridge.Build_UI_Key_Handlers.Handle_Build_UI_Key
           (Instance.State, Chord,
            Execute_Command_Id_Default'Access,
            Report_Info)
         then
            null;
         elsif Editor.Input_Bridge.Panel_Focus_Key_Handlers
           .Handle_Focused_Surface_Key
             (Instance.State, Chord, Execute_Command_Id_Default'Access)
         then
            null;
         else
            Execute_Command_Id (Id, Chord.Modifiers.Shift);
            Editor.Cursor.Notify_Input
              (Float (Editor.View.Current_Time_Seconds));
         end if;
      end if;
   end Handle_Key_Chord;

end Editor.Input_Bridge.Keyboard_Dispatch;
