with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers; use type Ada.Containers.Count_Type;

with Text_Buffer;
with Editor.State;
with Editor.Commands;
with Editor.Cursors; use Editor.Cursors;
with Editor.Clipboard;
with Editor.History;
with Editor.Selection;
use type Editor.Selection.Selection_Validation_Status;

package body Editor.Executor.Clipboard is

   Current_Status : Clipboard_Execution_Status := Clipboard_No_Text;


   function Copy_Cut_Availability
     (S : Editor.State.State_Type)
      return Editor.Commands.Command_Availability
   is
      Selection_Range  : Editor.Selection.Active_Selection_Range;
      Status : constant Editor.Selection.Selection_Validation_Status :=
        Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
      pragma Unreferenced (Selection_Range);
   begin
      case Status is
         when Editor.Selection.Selection_No_Active_Buffer =>
            return Editor.Commands.Unavailable ("No active buffer.");
         when Editor.Selection.Selection_No_Caret
            | Editor.Selection.Selection_Empty =>
            return Editor.Commands.Unavailable ("No selected text");
         when Editor.Selection.Selection_Invalid =>
            return Editor.Commands.Unavailable ("Invalid selection");
         when Editor.Selection.Selection_Ok =>
            return Editor.Commands.Available;
      end case;
   end Copy_Cut_Availability;

   function Last_Status return Clipboard_Execution_Status is
   begin
      return Current_Status;
   end Last_Status;

   procedure Clear_Status is
   begin
      Current_Status := Clipboard_No_Text;
   end Clear_Status;

   function Text_For_Local_Input return Unbounded_String is
   begin
      --  Local input widgets may paste from the session-local editor
      --  clipboard, but they must not read or mutate clipboard storage
      --  directly.  This keeps all non-system clipboard consumers on the
      --  canonical Clipboard_Text / Clipboard_Has_Text path.
      if Editor.Clipboard.Has_Text then
         return Editor.Clipboard.Get_Text;
      end if;

      return Null_Unbounded_String;
   end Text_For_Local_Input;


   procedure Keep_Primary_Caret_Only
     (S : in out Editor.State.State_Type)
   is
      C : Caret_State;
   begin
      if S.Carets.Length = 0 then
         return;
      end if;

      C := S.Carets (S.Carets.First_Index);
      S.Carets.Clear;
      S.Carets.Append (C);
      S.Rect_Select_Active := False;
   end Keep_Primary_Caret_Only;

   procedure Execute_Copy
     (S : in out Editor.State.State_Type)
   is
      Selection_Range  : Editor.Selection.Active_Selection_Range;
      Status : constant Editor.Selection.Selection_Validation_Status :=
        Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
      Text   : Unbounded_String := Null_Unbounded_String;
      pragma Unreferenced (Selection_Range);
   begin
      case Status is
         when Editor.Selection.Selection_No_Active_Buffer =>
            Current_Status := Clipboard_No_Active_Buffer;
            return;
         when Editor.Selection.Selection_No_Caret | Editor.Selection.Selection_Empty =>
            Current_Status := Clipboard_No_Selected_Text;
            return;
         when Editor.Selection.Selection_Invalid =>
            Current_Status := Clipboard_Invalid_Selection;
            return;
         when Editor.Selection.Selection_Ok =>
            null;
      end case;

      Text := Editor.Selection.Extract_Selected_Text (S);
      if Length (Text) = 0 then
         Current_Status := Clipboard_No_Selected_Text;
      else
         Editor.Clipboard.Set_Text (Text);
         Current_Status := Clipboard_Copied;
      end if;
   exception
      when others =>
         Current_Status := Clipboard_Copy_Failed;
   end Execute_Copy;

   procedure Execute_Cut
     (S : in out Editor.State.State_Type)
   is
      Selection_Range  : Editor.Selection.Active_Selection_Range;
      Status : constant Editor.Selection.Selection_Validation_Status :=
        Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
      Text   : Unbounded_String := Null_Unbounded_String;
      Del    : Editor.Commands.Command;
      pragma Unreferenced (Selection_Range);
   begin
      case Status is
         when Editor.Selection.Selection_No_Active_Buffer =>
            Current_Status := Clipboard_No_Active_Buffer;
            return;
         when Editor.Selection.Selection_No_Caret | Editor.Selection.Selection_Empty =>
            Current_Status := Clipboard_No_Selected_Text;
            return;
         when Editor.Selection.Selection_Invalid =>
            Current_Status := Clipboard_Invalid_Selection;
            return;
         when Editor.Selection.Selection_Ok =>
            null;
      end case;

      Text := Editor.Selection.Extract_Selected_Text (S);
      if Length (Text) = 0 then
         Current_Status := Clipboard_No_Selected_Text;
         return;
      end if;

      --  Phase 374 atomic policy: only publish the clipboard after the
      --  canonical deletion path has successfully changed buffer text.  If
      --  the canonical edit path fails or reports no text change, restore the
      --  pre-command editor/history/clipboard state rather than leaving a
      --  partially collapsed selection or a disturbed redo stack behind.
      declare
         Before_State : constant Editor.State.State_Type := S;
         Before_Text  : constant String := Text_Buffer.UTF8_Text (S.Buffer);
         Before_Clip  : constant Unbounded_String := Editor.Clipboard.Get_Text;
         Before_Undo  : constant Editor.History.History_Vector.Vector :=
           Editor.History.Undo_Stack;
         Before_Redo  : constant Editor.History.History_Vector.Vector :=
           Editor.History.Redo_Stack;
      begin
         Keep_Primary_Caret_Only (S);
         Del.Kind := Editor.Commands.Delete_Char;
         Editor.Executor.Execute_No_Log (S, Del);

         if Text_Buffer.UTF8_Text (S.Buffer) /= Before_Text then
            Editor.Clipboard.Set_Text (Text);
            Current_Status := Clipboard_Cut;
         else
            S := Before_State;
            Editor.History.Undo_Stack := Before_Undo;
            Editor.History.Redo_Stack := Before_Redo;
            Editor.Clipboard.Set_Text (Before_Clip);
            Current_Status := Clipboard_Cut_Failed;
         end if;
      exception
         when others =>
            S := Before_State;
            Editor.History.Undo_Stack := Before_Undo;
            Editor.History.Redo_Stack := Before_Redo;
            Editor.Clipboard.Set_Text (Before_Clip);
            Current_Status := Clipboard_Cut_Failed;
      end;
   exception
      when others =>
         Current_Status := Clipboard_Cut_Failed;
   end Execute_Cut;

   procedure Execute_Paste
     (S : in out Editor.State.State_Type)
   is
      Text : constant Unbounded_String := Editor.Clipboard.Get_Text;
      P    : Editor.Commands.Command;
   begin
      if not Editor.State.Has_Active_Buffer (S) then
         Current_Status := Clipboard_No_Active_Buffer;
         return;
      elsif Length (Text) = 0 then
         Current_Status := Clipboard_No_Text;
         return;
      elsif S.Carets.Length = 0 then
         Current_Status := Clipboard_Paste_Failed;
         return;
      end if;

      declare
         Selection_Range  : Editor.Selection.Active_Selection_Range;
         Status : constant Editor.Selection.Selection_Validation_Status :=
           Editor.Selection.Validate_Active_Selection_Range (S, Selection_Range);
         pragma Unreferenced (Selection_Range);
      begin
         if Status = Editor.Selection.Selection_Invalid then
            Current_Status := Clipboard_Invalid_Selection;
            return;
         end if;
      end;

      --  Phase 374 keeps paste on the canonical text edit path, but avoids
      --  manufacturing an undo record for the degenerate replacement case
      --  where the selected text already equals the clipboard text.
      declare
         Selected : constant Unbounded_String := Editor.Selection.Extract_Selected_Text (S);
      begin
         if Length (Selected) > 0 and then Selected = Text then
            Current_Status := Clipboard_Pasted;
            return;
         end if;
      end;

      declare
         Before_State : constant Editor.State.State_Type := S;
         Before_Text  : constant String := Text_Buffer.UTF8_Text (S.Buffer);
         Before_Undo  : constant Editor.History.History_Vector.Vector :=
           Editor.History.Undo_Stack;
         Before_Redo  : constant Editor.History.History_Vector.Vector :=
           Editor.History.Redo_Stack;
      begin
         Keep_Primary_Caret_Only (S);
         P.Kind := Editor.Commands.Paste_Text;
         P.Text := Text;
         Editor.Executor.Execute_No_Log (S, P);

         if Text_Buffer.UTF8_Text (S.Buffer) /= Before_Text then
            Current_Status := Clipboard_Pasted;
         else
            S := Before_State;
            Editor.History.Undo_Stack := Before_Undo;
            Editor.History.Redo_Stack := Before_Redo;
            Current_Status := Clipboard_Paste_Failed;
         end if;
      exception
         when others =>
            S := Before_State;
            Editor.History.Undo_Stack := Before_Undo;
            Editor.History.Redo_Stack := Before_Redo;
            Current_Status := Clipboard_Paste_Failed;
      end;
   exception
      when others =>
         Current_Status := Clipboard_Paste_Failed;
   end Execute_Paste;

   procedure Execute_Clear is
   begin
      if Editor.Clipboard.Has_Text then
         Editor.Clipboard.Clear;
         Current_Status := Clipboard_Cleared;
      else
         Current_Status := Clipboard_Nothing_To_Clear;
      end if;
   end Execute_Clear;

   procedure Execute
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) is
   begin
      Clear_Status;

      case Cmd.Kind is
         when Editor.Commands.Copy_Selection =>
            Execute_Copy (S);
         when Editor.Commands.Cut_Selection =>
            Execute_Cut (S);
         when Editor.Commands.Paste_Clipboard =>
            Execute_Paste (S);
         when Editor.Commands.Clear_Clipboard =>
            Execute_Clear;
         when others =>
            null;
      end case;
   end Execute;

end Editor.Executor.Clipboard;
