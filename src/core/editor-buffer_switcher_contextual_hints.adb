with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffer_Switcher;
with Editor.Buffers;
with Editor.Commands;
with Editor.Executor;
with Editor.Keybindings;
with Editor.Settings;

package body Editor.Buffer_Switcher_Contextual_Hints is

   use type Editor.Buffer_Switcher.Switcher_Review_Mode;
   use type Editor.Buffers.Buffer_Id;
   use type Editor.Commands.Command_Id;

   type Command_Array is array (Positive range <>) of Editor.Commands.Command_Id;

   function Hint_Command_Available
     (S  : Editor.State.State_Type;
      Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      return Editor.Commands.Has_Descriptor (Id)
        and then Editor.Commands.Has_Availability_Handler (Id)
        and then (Editor.Commands.Is_Visible_In_Palette (Id)
                  or else Editor.Commands.Is_Bindable_Command (Id))
        and then Editor.Commands.Is_Available
          (Editor.Executor.Command_Availability (S, Id));
   end Hint_Command_Available;

   function Hint_Keybinding_Text
     (Id               : Editor.Commands.Command_Id;
      Show_Keybindings : Boolean) return String
   is
      Info : Editor.Keybindings.Command_Keybinding_Info;
   begin
      if not Show_Keybindings
        or else not Editor.Commands.Is_Bindable_Command (Id)
      then
         return "";
      end if;

      Info := Editor.Keybindings.Primary_Binding_For_Command (Id);
      if Info.Has_Binding then
         return To_String (Info.Display);
      end if;
      return "";
   end Hint_Keybinding_Text;

   procedure Add_Command
     (S                 : Editor.State.State_Type;
      Hints             : in out Switcher_Contextual_Hint_Vectors.Vector;
      Id                : Editor.Commands.Command_Id;
      Max_Hints         : Positive;
      Show_Keybindings  : Boolean;
      Allow_Unavailable : Boolean := False)
   is
      Availability : Editor.Commands.Command_Availability;
      Hint         : Switcher_Contextual_Hint;
   begin
      if Natural (Hints.Length) >= Max_Hints
        or else Id = Editor.Commands.No_Command
        or else not Editor.Commands.Has_Descriptor (Id)
        or else not Editor.Commands.Has_Availability_Handler (Id)
        or else (not Editor.Commands.Is_Visible_In_Palette (Id)
                 and then not Editor.Commands.Is_Bindable_Command (Id))
      then
         return;
      end if;

      for Existing of Hints loop
         if Existing.Command_Id = Id then
            return;
         end if;
      end loop;

      Availability := Editor.Executor.Command_Availability (S, Id);
      if not Editor.Commands.Is_Available (Availability) and then not Allow_Unavailable then
         return;
      end if;

      Hint.Command_Id := Id;
      Hint.Label := To_Unbounded_String (Editor.Commands.Label (Id));
      Hint.Keybinding_Text := To_Unbounded_String
        (Hint_Keybinding_Text (Id, Show_Keybindings));
      Hint.Is_Enabled := Editor.Commands.Is_Available (Availability);
      if not Hint.Is_Enabled then
         Hint.Disabled_Reason := To_Unbounded_String
           (Editor.Commands.Unavailable_Reason (Availability));
      end if;
      Hints.Append (Hint);
   end Add_Command;

   procedure Add_Commands
     (S                : Editor.State.State_Type;
      Hints            : in out Switcher_Contextual_Hint_Vectors.Vector;
      Ids              : Command_Array;
      Max_Hints        : Positive;
      Show_Keybindings : Boolean)
   is
   begin
      for Id of Ids loop
         Add_Command (S, Hints, Id, Max_Hints, Show_Keybindings);
      end loop;
   end Add_Commands;

   procedure Add_Review_Commands
     (S                : Editor.State.State_Type;
      Hints            : in out Switcher_Contextual_Hint_Vectors.Vector;
      Max_Hints        : Positive;
      Show_Keybindings : Boolean)
   is
      use Editor.Commands;
      Mode : constant Editor.Buffer_Switcher.Switcher_Review_Mode :=
        Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot
          (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI).Active_Review_Mode;
   begin
      case Mode is
         when Editor.Buffer_Switcher.No_Review =>
            null;
         when Editor.Buffer_Switcher.Marked_Review =>
            Add_Commands (S, Hints,
              (Command_Buffer_Switcher_Mark_Review_Hide,
               Command_Buffer_Switcher_Mark_Next,
               Command_Buffer_Switcher_Mark_Previous),
              Max_Hints, Show_Keybindings);
         when Editor.Buffer_Switcher.Pending_Marked_Close_Review =>
            Add_Commands (S, Hints,
              (Command_Buffer_Switcher_Pending_Mark_Review_Hide,
               Command_Buffer_Switcher_Pending_Mark_Next,
               Command_Buffer_Switcher_Pending_Mark_Previous),
              Max_Hints, Show_Keybindings);
         when Editor.Buffer_Switcher.Pruned_Pending_Close_Review =>
            Add_Commands (S, Hints,
              (Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Hide,
               Command_Buffer_Switcher_Pending_Mark_Pruned_Next,
               Command_Buffer_Switcher_Pending_Mark_Pruned_Previous),
              Max_Hints, Show_Keybindings);
         when Editor.Buffer_Switcher.Dirty_Pending_Close_Review =>
            Add_Commands (S, Hints,
              (Command_Buffer_Switcher_Pending_Mark_Dirty_Next,
               Command_Buffer_Switcher_Pending_Mark_Dirty_Previous),
              Max_Hints, Show_Keybindings);
         when Editor.Buffer_Switcher.Dirty_Prune_Preview_Review =>
            Add_Commands (S, Hints,
              (Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Hide,
               Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Next,
               Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Previous),
              Max_Hints, Show_Keybindings);
         when Editor.Buffer_Switcher.Removed_Dirty_Prune_Preview_Review =>
            Add_Commands (S, Hints,
              (Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Next,
               Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Removed_Previous),
              Max_Hints, Show_Keybindings);
         when Editor.Buffer_Switcher.Dirty_Prune_Apply_Review =>
            Add_Commands (S, Hints,
              (Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Hide,
               Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Next,
               Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Previous),
              Max_Hints, Show_Keybindings);
         when Editor.Buffer_Switcher.Removed_Dirty_Prune_Apply_Review =>
            Add_Commands (S, Hints,
              (Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Next,
               Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Removed_Previous),
              Max_Hints, Show_Keybindings);
      end case;
   end Add_Review_Commands;

   function Build_Switcher_Contextual_Hints
     (S         : Editor.State.State_Type;
      Max_Hints : Positive := Default_Max_Hints)
      return Switcher_Contextual_Hint_Vectors.Vector
   is
      use Editor.Commands;
      Snapshot : constant Editor.Buffer_Switcher.Switcher_Batch_State_Snapshot :=
        Editor.Buffer_Switcher.Build_Switcher_Batch_State_Snapshot
          (S.Buffer_Switcher, Editor.Buffers.Global_Registry_For_UI);
      Show_Keybindings : constant Boolean :=
        Editor.Settings.Command_Palette_Show_Keybindings (S.Settings);
      Hints : Switcher_Contextual_Hint_Vectors.Vector;
      Found : Boolean := False;
      Row   : constant Editor.Buffer_Switcher.Buffer_Switcher_Row :=
        Editor.Buffer_Switcher.Selected_Row (S.Buffer_Switcher, Found);
   begin
      if Snapshot.Has_Dirty_Prune_Apply_Confirmation then
         Add_Commands (S, Hints,
           (Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Confirm,
            Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Cancel,
            Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Review_Show),
           Max_Hints, Show_Keybindings);
         if Found and then Row.Is_Dirty_Prune_Apply_Target then
            Add_Command (S, Hints,
              Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Remove_Selected,
              Max_Hints, Show_Keybindings);
         end if;
         Add_Commands (S, Hints,
           (Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Restore_Last_Removed,
            Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply_Clear_Stale),
           Max_Hints, Show_Keybindings);
         Add_Review_Commands (S, Hints, Max_Hints, Show_Keybindings);
         return Hints;
      end if;

      if Snapshot.Has_Dirty_Prune_Preview then
         Add_Commands (S, Hints,
           (Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Apply,
            Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Cancel,
            Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Review_Show),
           Max_Hints, Show_Keybindings);
         if Found and then Row.Is_Dirty_Prune_Preview_Target then
            Add_Command (S, Hints,
              Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Remove_Selected,
              Max_Hints, Show_Keybindings);
         end if;
         Add_Commands (S, Hints,
           (Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Restore_Last_Removed,
            Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Clear_Stale),
           Max_Hints, Show_Keybindings);
         Add_Review_Commands (S, Hints, Max_Hints, Show_Keybindings);
         return Hints;
      end if;

      if Snapshot.Has_Pending_Marked_Close then
         Add_Commands (S, Hints,
           (Command_Buffer_Switcher_Mark_Confirm,
            Command_Buffer_Switcher_Mark_Cancel,
            Command_Buffer_Switcher_Pending_Mark_Review_Show),
           Max_Hints, Show_Keybindings);
         if Found and then Row.Is_Pending_Close_Target then
            Add_Command (S, Hints,
              Command_Buffer_Switcher_Pending_Mark_Remove_Selected,
              Max_Hints, Show_Keybindings);
         end if;
         if Snapshot.Dirty_Pending_Close_Count > 0 then
            Add_Command (S, Hints,
              Command_Buffer_Switcher_Pending_Mark_Dirty_Prune_Preview,
              Max_Hints, Show_Keybindings);
            if Found and then Row.Is_Pending_Close_Target and then Row.Is_Dirty then
               Add_Command (S, Hints,
                 Command_Buffer_Switcher_Pending_Mark_Dirty_Remove_Selected,
                 Max_Hints, Show_Keybindings);
            end if;
         end if;
         Add_Commands (S, Hints,
           (Command_Buffer_Switcher_Pending_Mark_Restore_Last_Pruned,
            Command_Buffer_Switcher_Pending_Mark_Pruned_Review_Show),
           Max_Hints, Show_Keybindings);
         Add_Review_Commands (S, Hints, Max_Hints, Show_Keybindings);
         return Hints;
      end if;

      Add_Review_Commands (S, Hints, Max_Hints, Show_Keybindings);

      if Snapshot.Marked_Count > 0 then
         Add_Commands (S, Hints,
           (Command_Buffer_Switcher_Mark_Close_Marked,
            Command_Buffer_Switcher_Mark_Review_Show,
            Command_Buffer_Switcher_Mark_Clear_All),
           Max_Hints, Show_Keybindings);
      end if;

      if Found and then Row.Id /= Editor.Buffers.No_Buffer then
         if Row.Is_Marked then
            Add_Command (S, Hints, Command_Buffer_Switcher_Mark_Clear,
              Max_Hints, Show_Keybindings);
         else
            Add_Command (S, Hints, Command_Buffer_Switcher_Mark_Set,
              Max_Hints, Show_Keybindings);
         end if;
      end if;

      Add_Commands (S, Hints,
        (Command_Accept_Buffer_Switcher,
         Command_Close_Buffer_Switcher,
         Command_Buffer_Switcher_Next_Result,
         Command_Buffer_Switcher_Previous_Result,
         Command_Buffer_Switcher_Filter_Clear,
         Command_Buffer_Switcher_Sort_Next),
        Max_Hints, Show_Keybindings);

      return Hints;
   end Build_Switcher_Contextual_Hints;

   function Format_Switcher_Contextual_Hints
     (Hints : Switcher_Contextual_Hint_Vectors.Vector) return String
   is
      Text : Unbounded_String := Null_Unbounded_String;
   begin
      for Hint of Hints loop
         if Length (Text) > 0 then
            Append (Text, " | ");
         end if;
         Append (Text, To_String (Hint.Label));
         if Length (Hint.Keybinding_Text) > 0 then
            Append (Text, " (");
            Append (Text, To_String (Hint.Keybinding_Text));
            Append (Text, ")");
         end if;
         if not Hint.Is_Enabled and then Length (Hint.Disabled_Reason) > 0 then
            Append (Text, " - ");
            Append (Text, To_String (Hint.Disabled_Reason));
         end if;
      end loop;
      return To_String (Text);
   end Format_Switcher_Contextual_Hints;

   function Contextual_Hint_Text
     (S         : Editor.State.State_Type;
      Max_Hints : Positive := Default_Max_Hints) return String
   is
   begin
      return Format_Switcher_Contextual_Hints
        (Build_Switcher_Contextual_Hints (S, Max_Hints));
   end Contextual_Hint_Text;

end Editor.Buffer_Switcher_Contextual_Hints;
