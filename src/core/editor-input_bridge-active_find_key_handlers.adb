with Editor.Cursor;
with Editor.Overlay_Focus;
with Editor.View;

package body Editor.Input_Bridge.Active_Find_Key_Handlers is

   use type Editor.Keybindings.Key_Code;

   procedure Notify_Input is
   begin
      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Notify_Input;

   function Active_Find_Owns_Key
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return S.Active_Find_Prompt
        and then
          ((not Editor.Overlay_Focus.Has_Active_Overlay (S.Overlay_Focus))
           or else Editor.Overlay_Focus.Is_Active
             (S.Overlay_Focus,
              Editor.Overlay_Focus.Active_Find_Prompt_Overlay));
   end Active_Find_Owns_Key;

   function Handle_Active_Find_Key
     (S                : Editor.State.State_Type;
      Chord            : Editor.Keybindings.Key_Chord;
      Execute_Previous : not null access procedure;
      Hide             : not null access procedure) return Boolean
   is
   begin
      if not Active_Find_Owns_Key (S) then
         return False;
      end if;

      case Chord.Key is
         when Editor.Keybindings.Key_Enter =>
            if Chord.Modifiers.Shift then
               Execute_Previous.all;
               Notify_Input;
               return True;
            end if;
         when Editor.Keybindings.Key_Escape =>
            Hide.all;
            Notify_Input;
            return True;
         when others =>
            null;
      end case;

      return False;
   end Handle_Active_Find_Key;

end Editor.Input_Bridge.Active_Find_Key_Handlers;
