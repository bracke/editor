with Editor.Cursor;
with Editor.Keybinding_Management;
with Editor.Render_Cache;
with Editor.View;

package body Editor.Input_Bridge.Keybinding_Handlers is

   use type Editor.Keybindings.Key_Code;
   use type Editor.Keybinding_Management.Keybinding_Action_Status;
   use type Editor.Keybinding_Management.Keybinding_Capture_State;

   procedure Notify_Keybinding_Input is
   begin
      Editor.Render_Cache.Invalidate_All;
      Editor.Cursor.Notify_Input
        (Float (Editor.View.Current_Time_Seconds));
   end Notify_Keybinding_Input;

   procedure Report_Status
     (Status : Editor.Keybinding_Management.Keybinding_Action_Status;
      Report : not null access procedure (Message : String))
   is
   begin
      if Status = Editor.Keybinding_Management.Keybinding_Action_Ok then
         Report (Editor.Keybinding_Management.Latest_Message);
      else
         Report (Editor.Keybinding_Management.Action_Status_Label (Status));
      end if;
   end Report_Status;

   function Handle_Capture_Chord
     (Chord  : Editor.Keybindings.Key_Chord;
      Report : not null access procedure (Message : String)) return Boolean
   is
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
   begin
      if Editor.Keybinding_Management.Current_Capture_State =
        Editor.Keybinding_Management.Capture_Inactive
      then
         return False;
      end if;

      if Chord.Key = Editor.Keybindings.Key_Escape then
         Editor.Keybinding_Management.Cancel_Capture (Status);
      elsif Editor.Keybinding_Management.Has_Pending_Conflict
        and then Chord.Key = Editor.Keybindings.Key_Enter
      then
         Editor.Keybinding_Management.Confirm_Pending_Assignment (Status);
      elsif Editor.Keybinding_Management.Has_Pending_Conflict then
         --  A replacement conflict is an explicit confirmation state.
         --  While it is pending, only Enter confirms and Escape cancels;
         --  any other chord is consumed and must not assign a different
         --  binding or execute through the ordinary resolver.
         Status :=
           Editor.Keybinding_Management.Keybinding_Action_Confirmation_Pending;
      else
         Editor.Keybinding_Management.Assign_Selected
           (Chord, Confirm_Conflict => False, Status => Status);
      end if;

      Report_Status (Status, Report);
      Notify_Keybinding_Input;
      return True;
   end Handle_Capture_Chord;

   function Handle_Focused_Surface_Chord
     (Chord  : Editor.Keybindings.Key_Chord;
      Report : not null access procedure (Message : String)) return Boolean
   is
      Status : Editor.Keybinding_Management.Keybinding_Action_Status;
   begin
      if not Editor.Keybinding_Management.Is_Focused
        or else not Editor.Keybinding_Management.Is_Visible
        or else Chord.Modifiers.Ctrl
        or else Chord.Modifiers.Shift
        or else Chord.Modifiers.Alt
        or else Chord.Modifiers.Meta
      then
         return False;
      end if;

      case Chord.Key is
         when Editor.Keybindings.Key_Down =>
            Editor.Keybinding_Management.Select_Next_Row;
            Report (Editor.Keybinding_Management.Latest_Message);
         when Editor.Keybindings.Key_Up =>
            Editor.Keybinding_Management.Select_Previous_Row;
            Report (Editor.Keybinding_Management.Latest_Message);
         when Editor.Keybindings.Key_Enter =>
            if Editor.Keybinding_Management.Has_Pending_Reset then
               Editor.Keybinding_Management.Confirm_Reset_To_Defaults (Status);
            else
               Editor.Keybinding_Management.Begin_Assign_Selected (Status);
            end if;
            Report_Status (Status, Report);
         when Editor.Keybindings.Key_Escape =>
            if Editor.Keybinding_Management.Has_Pending_Reset then
               Editor.Keybinding_Management.Cancel_Reset_To_Defaults (Status);
               Report
                 (Editor.Keybinding_Management.Action_Status_Label (Status));
            else
               Editor.Keybinding_Management.Hide;
               Report ("Keybindings hidden.");
            end if;
         when others =>
            return False;
      end case;

      Notify_Keybinding_Input;
      return True;
   end Handle_Focused_Surface_Chord;

   function Handle_Keybinding_Chord
     (Chord  : Editor.Keybindings.Key_Chord;
      Report : not null access procedure (Message : String)) return Boolean
   is
   begin
      return Handle_Capture_Chord (Chord, Report)
        or else Handle_Focused_Surface_Chord (Chord, Report);
   end Handle_Keybinding_Chord;

end Editor.Input_Bridge.Keybinding_Handlers;
