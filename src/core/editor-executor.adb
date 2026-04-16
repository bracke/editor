with Text_Buffer;
with Editor.State;
with Editor.Cursors; use Editor.Cursors;
with Editor.Commands; use Editor.Commands;
with Editor.Selection;
with Editor.History;
with Ada.Containers; use Ada.Containers;
with Editor.Invariants;

package body Editor.Executor is

   function Safe_Caret
     (S : Editor.State.State_Type)
      return Cursor_Index is
   begin
      if S.Carets.Length = 0 then
         return 0;
      else
         return S.Carets (S.Carets.First_Index);
      end if;
   end Safe_Caret;

   procedure Execute_No_Log
  (S   : in out Editor.State.State_Type;
   Cmd : Editor.Commands.Command) is

   Before : constant Editor.State.State_Type := S;

   Old_Len : constant Natural :=
     Natural (Text_Buffer.Length (S.Buffer));

   Old_Caret : constant Cursor_Index := Safe_Caret (S);
   New_Caret : Cursor_Index := Old_Caret;

   Had_Selection : constant Boolean := S.Selection.Active;
   Sel_Start     : constant Cursor_Index := S.Selection.Start_Pos;
   Sel_End       : constant Cursor_Index := S.Selection.End_Pos;

   L    : Cursor_Index := 0;
   H    : Cursor_Index := 0;
   Span : Natural := 0;

begin
   ----------------------------------------------------------------------
   -- Undo / Redo
   ----------------------------------------------------------------------
   case Cmd.Kind is
      when Undo =>
         if not Editor.History.Undo_Stack.Is_Empty then
            Editor.History.Redo_Stack.Append (S);
            S := Editor.History.Undo_Stack.Last_Element;
            Editor.History.Undo_Stack.Delete_Last;
         end if;
         return;

      when Redo =>
         if not Editor.History.Redo_Stack.Is_Empty then
            Editor.History.Undo_Stack.Append (S);
            S := Editor.History.Redo_Stack.Last_Element;
            Editor.History.Redo_Stack.Delete_Last;
         end if;
         return;

      when others =>
         null;
   end case;

   ----------------------------------------------------------------------
   -- Movement only
   -- Tests expect caret range 0 .. Len + 1
   ----------------------------------------------------------------------
   case Cmd.Kind is
      when Editor.Commands.Move_Left =>
         if Old_Caret > 0 then
            New_Caret := Old_Caret - 1;
         end if;

      when Editor.Commands.Move_Right =>
         if Old_Caret < Cursor_Index (Old_Len + 1) then
            New_Caret := Old_Caret + 1;
         end if;

      when others =>
         null;
   end case;

   ----------------------------------------------------------------------
   -- Edit operations
   ----------------------------------------------------------------------
   case Cmd.Kind is
      when Editor.Commands.Insert_Char =>
         if Had_Selection then
            L := Cursor_Index'Min (Sel_Start, Sel_End);
            H := Cursor_Index'Max (Sel_Start, Sel_End);
            Span := Natural (H - L);

            Text_Buffer.Delete_Range
              (S.Buffer,
               Natural (L),
               Span);

            Text_Buffer.Insert
              (S.Buffer,
               Natural (L),
               Cmd.Ch);

            New_Caret := L + 1;
         else
            Text_Buffer.Insert
              (S.Buffer,
               Natural (Old_Caret),
               Cmd.Ch);

            New_Caret := Old_Caret + 1;
         end if;

      when Editor.Commands.Delete_Char =>
         if Had_Selection then
            L := Cursor_Index'Min (Sel_Start, Sel_End);
            H := Cursor_Index'Max (Sel_Start, Sel_End);
            Span := Natural (H - L);

            Text_Buffer.Delete_Range
              (S.Buffer,
               Natural (L),
               Span);

            New_Caret := L;
         else
            -- Forward delete at caret position
            if Old_Caret < Cursor_Index (Old_Len) then
               Text_Buffer.Delete
                 (S.Buffer,
                  Natural (Old_Caret + 1));
            end if;

            New_Caret := Old_Caret;
         end if;

      when others =>
         null;
   end case;

   ----------------------------------------------------------------------
   -- Clamp caret to 0 .. current Length
   ----------------------------------------------------------------------
   declare
      Len2 : constant Natural := Natural (Text_Buffer.Length (S.Buffer));
   begin
      if New_Caret > Cursor_Index (Len2+1) then
         New_Caret := Cursor_Index (Len2+1);
      end if;
   end;

   S.Carets.Clear;
   S.Carets.Append (New_Caret);

   ----------------------------------------------------------------------
   -- Selection update
   ----------------------------------------------------------------------
   case Cmd.Kind is
      when Move_Left | Move_Right =>
         if Cmd.Shift then
            if not Had_Selection then
               S.Selection.Active := True;
               S.Selection.Start_Pos := Old_Caret;
            else
               S.Selection.Active := True;
               S.Selection.Start_Pos := Sel_Start;
            end if;

            S.Selection.End_Pos := New_Caret;
         else
            S.Selection.Active := False;
            S.Selection.Start_Pos := New_Caret;
            S.Selection.End_Pos := New_Caret;
         end if;

      when Insert_Char | Delete_Char =>
         S.Selection.Active := False;
         S.Selection.Start_Pos := New_Caret;
         S.Selection.End_Pos := New_Caret;

      when others =>
         null;
   end case;

   ----------------------------------------------------------------------
   -- History
   ----------------------------------------------------------------------
   Editor.History.Undo_Stack.Append (Before);
   Editor.History.Redo_Stack.Clear;

   Editor.Invariants.Check (S);
end Execute_No_Log;

end Editor.Executor;