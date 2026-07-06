with Editor.Cursor;
with Editor.Focus_Management;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.Pending_Transition_Key_Handlers is

   use type Editor.Keybindings.Binding_Result;
   use type Editor.Keybindings.Key_Code;

   procedure Notify_Input is
   begin
      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Notify_Input;

   function Pending_Confirmation_Active
      (S : Editor.State.State_Type) return Boolean
   is
   begin
      return Editor.Focus_Management.Pending_Confirmation_Owns_Focus (S);
   end Pending_Confirmation_Active;

   function Handle_Pending_Transition_Key
     (S           : Editor.State.State_Type;
      Chord       : Editor.Keybindings.Key_Chord;
      Execute     : not null access procedure
        (Id : Editor.Commands.Command_Id; Shift : Boolean);
      Report_Info : not null access procedure (Text : String)) return Boolean
   is
      Id : Editor.Commands.Command_Id := Editor.Commands.No_Command;
   begin
      if not Pending_Confirmation_Active (S) then
         return False;
      end if;

      if Editor.Keybindings.Resolve (Chord, Id) /=
        Editor.Keybindings.Bound_Command
      then
         Id := Editor.Commands.No_Command;
      end if;

      case Chord.Key is
         when Editor.Keybindings.Key_Escape =>
            Execute (Editor.Commands.Command_Cancel_Pending_Transition, False);
         when Editor.Keybindings.Key_Enter =>
            Execute (Editor.Commands.Command_Retry_Pending_Transition, False);
         when others =>
            if Editor.Focus_Management.Command_Allowed_While_Pending (Id) then
               Execute (Id, Chord.Modifiers.Shift);
            else
               Report_Info ("Command unavailable while confirmation is pending");
               Editor.Render_Cache.Invalidate_All;
            end if;
      end case;

      Notify_Input;
      return True;
   end Handle_Pending_Transition_Key;

end Editor.Input_Bridge.Pending_Transition_Key_Handlers;
