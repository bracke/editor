with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.Focus_Management;
with Editor.Guided_Prompts;
with Editor.UTF8;

package body Editor.Input_Bridge.Text_Entry_Routing is

   use type Editor.Buffers.Buffer_Id;

   function Is_Text_Entry_Workflow_Event
     (Cmd : Editor.Commands.Command) return Boolean
   is
   begin
      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input
            | Editor.Commands.Delete_Char
            | Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Previous_Character
            | Editor.Commands.Delete_Next_Character
            | Editor.Commands.Delete_Previous_Word
            | Editor.Commands.Delete_Next_Word
            | Editor.Commands.Delete_Selection_Range
            | Editor.Commands.Split_Current_Line_At_Caret =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Text_Entry_Workflow_Event;

   function Is_Text_Entry_Workflow_Command_Id
     (Id : Editor.Commands.Command_Id) return Boolean
   is
   begin
      case Id is
         when Editor.Commands.Command_Insert_Newline
            | Editor.Commands.Command_Selection_Delete
            | Editor.Commands.Command_Char_Delete_Previous
            | Editor.Commands.Command_Char_Delete_Next
            | Editor.Commands.Command_Word_Delete_Previous
            | Editor.Commands.Command_Word_Delete_Next
            | Editor.Commands.Command_Line_Split_At_Caret =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Text_Entry_Workflow_Command_Id;

   function Resolve_Text_Entry_Focus_Target
     (State : Editor.State.State_Type) return Text_Entry_Focus_Target
   is
   begin
      if Editor.Focus_Management.Pending_Confirmation_Owns_Focus (State) then
         return Text_Entry_No_Target;
      elsif Editor.Guided_Prompts.Is_Active (State.Guided_Prompt) then
         return Text_Entry_Guided_Prompt;
      elsif Editor.Focus_Management.Overlay_Input_Owns_Text (State) then
         return Text_Entry_Overlay_Input;
      elsif Editor.Focus_Management.Editor_Text_Can_Edit (State) then
         return Text_Entry_Editor_Buffer;
      else
         return Text_Entry_No_Target;
      end if;
   end Resolve_Text_Entry_Focus_Target;

   function Preview_Text_Entry_Route
     (State : Editor.State.State_Type;
      Cmd   : Editor.Commands.Command) return Text_Entry_Route_Result
   is
      Focus : constant Text_Entry_Focus_Target :=
        Resolve_Text_Entry_Focus_Target (State);
   begin
      if not Is_Text_Entry_Workflow_Event (Cmd) then
         return Unsupported_Text_Entry_Event;
      end if;

      if Focus = Text_Entry_Overlay_Input then
         return Routed_To_Overlay_Input;
      elsif Focus = Text_Entry_Guided_Prompt then
         return Routed_To_Guided_Prompt;
      elsif Focus /= Text_Entry_Editor_Buffer then
         return No_Editor_Text_Focus;
      elsif Editor.Buffers.Global_Active_Buffer = Editor.Buffers.No_Buffer
        and then not Editor.State.Has_Active_Buffer (State)
      then
         return No_Active_Buffer;
      elsif State.Carets.Is_Empty then
         return No_Caret_Location;
      end if;

      case Cmd.Kind is
         when Editor.Commands.Insert_Text_Input =>
            return Routed_To_Text_Insert;
         when Editor.Commands.Delete_Selection_Range =>
            return Routed_To_Selection_Delete;
         when Editor.Commands.Delete_Char
            | Editor.Commands.Delete_Previous_Character =>
            return Routed_To_Delete_Previous_Character;
         when Editor.Commands.Forward_Delete_Char
            | Editor.Commands.Delete_Next_Character =>
            return Routed_To_Delete_Next_Character;
         when Editor.Commands.Delete_Previous_Word =>
            return Routed_To_Delete_Previous_Word;
         when Editor.Commands.Delete_Next_Word =>
            return Routed_To_Delete_Next_Word;
         when Editor.Commands.Split_Current_Line_At_Caret =>
            return Routed_To_Line_Split;
         when others =>
            return Unsupported_Text_Entry_Event;
      end case;
   end Preview_Text_Entry_Route;

   function Canonical_Text_Entry_Command
     (State : Editor.State.State_Type;
      Cmd   : Editor.Commands.Command) return Editor.Commands.Command
   is
      Result : constant Text_Entry_Route_Result :=
        Preview_Text_Entry_Route (State, Cmd);
      Routed : Editor.Commands.Command := Cmd;
   begin
      case Result is
         when Routed_To_Text_Insert =>
            Routed.Kind := Editor.Commands.Insert_Text_Input;
            if not Routed.Has_Position
              and then not State.Carets.Is_Empty
            then
               Routed.Pos := State.Carets (State.Carets.First_Index).Pos;
               Routed.Has_Position := True;
            end if;
            if Cmd.Code /= Wide_Wide_Character'Val (0)
              and then
                (Length (Routed.Text) = 0
                 or else To_String (Routed.Text) = String'(1 => ASCII.NUL))
            then
               Routed.Text :=
                 To_Unbounded_String (Editor.UTF8.Encode_UTF8 (Cmd.Code));
            elsif Length (Routed.Text) = 0 then
               if Cmd.Ch /= ASCII.NUL then
                  Routed.Text := To_Unbounded_String (String'(1 => Cmd.Ch));
               else
                  Routed.Text := Null_Unbounded_String;
               end if;
            end if;
         when Routed_To_Selection_Delete =>
            Routed.Kind := Editor.Commands.Delete_Selection_Range;
         when Routed_To_Delete_Previous_Character =>
            Routed.Kind := Editor.Commands.Delete_Previous_Character;
         when Routed_To_Delete_Next_Character =>
            Routed.Kind := Editor.Commands.Delete_Next_Character;
         when Routed_To_Delete_Previous_Word =>
            Routed.Kind := Editor.Commands.Delete_Previous_Word;
         when Routed_To_Delete_Next_Word =>
            Routed.Kind := Editor.Commands.Delete_Next_Word;
         when Routed_To_Line_Split =>
            Routed.Kind := Editor.Commands.Split_Current_Line_At_Caret;
         when others =>
            null;
      end case;
      return Routed;
   end Canonical_Text_Entry_Command;

   function Preview_Text_Entry_Command_Id
     (State : Editor.State.State_Type;
      Cmd   : Editor.Commands.Command) return Editor.Commands.Command_Id
   is
   begin
      case Preview_Text_Entry_Route (State, Cmd) is
         when Routed_To_Selection_Delete =>
            return Editor.Commands.Command_Selection_Delete;
         when Routed_To_Delete_Previous_Character =>
            return Editor.Commands.Command_Char_Delete_Previous;
         when Routed_To_Delete_Next_Character =>
            return Editor.Commands.Command_Char_Delete_Next;
         when Routed_To_Delete_Previous_Word =>
            return Editor.Commands.Command_Word_Delete_Previous;
         when Routed_To_Delete_Next_Word =>
            return Editor.Commands.Command_Word_Delete_Next;
         when Routed_To_Line_Split =>
            return Editor.Commands.Command_Line_Split_At_Caret;
         when others =>
            return Editor.Commands.No_Command;
      end case;
   end Preview_Text_Entry_Command_Id;

end Editor.Input_Bridge.Text_Entry_Routing;
