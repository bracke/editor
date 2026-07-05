with Editor.Cursor;
with Editor.View;

package body Editor.Input_Bridge.Semantic_Popup_Key_Handlers is

   use type Editor.Keybindings.Key_Code;
   use type Editor.State.Semantic_Popup_Kind;

   procedure Notify_Input is
   begin
      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Notify_Input;

   function Handle_Semantic_Popup_Key
     (S       : Editor.State.State_Type;
      Chord   : Editor.Keybindings.Key_Chord;
      Execute : not null access procedure
        (Id : Editor.Commands.Command_Id)) return Boolean
   is
   begin
      if not S.Semantic_Popup.Active then
         return False;
      end if;

      if Chord.Key = Editor.Keybindings.Key_Escape then
         Execute (Editor.Commands.Command_Semantic_Popup_Dismiss);
         Notify_Input;
         return True;
      end if;

      if S.Semantic_Popup.Kind /= Editor.State.Semantic_Completion_Popup then
         return False;
      end if;

      case Chord.Key is
         when Editor.Keybindings.Key_Enter =>
            Execute (Editor.Commands.Command_Semantic_Completion_Accept);
         when Editor.Keybindings.Key_Down =>
            Execute (Editor.Commands.Command_Semantic_Completion_Select_Next);
         when Editor.Keybindings.Key_Up =>
            Execute (Editor.Commands.Command_Semantic_Completion_Select_Previous);
         when Editor.Keybindings.Key_Tab =>
            if Chord.Modifiers.Shift then
               Execute (Editor.Commands.Command_Semantic_Completion_Select_Previous);
            else
               Execute (Editor.Commands.Command_Semantic_Completion_Select_Next);
            end if;
         when others =>
            return False;
      end case;

      Notify_Input;
      return True;
   end Handle_Semantic_Popup_Key;

end Editor.Input_Bridge.Semantic_Popup_Key_Handlers;
