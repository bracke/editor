with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Text_Buffer;

with Editor.Buffers;
with Editor.Commands;
with Editor.Cursors;
with Editor.Executor;
with Editor.Executor.History;
with Editor.Render_Cache;
with Editor.State;

package body Editor.Executor.Semantic_Completion_Commands is

   use type Editor.State.Semantic_Popup_Kind;

   function Is_Semantic_Identifier_Character
     (Code : Wide_Wide_Character) return Boolean
   is
      Pos : constant Natural := Wide_Wide_Character'Pos (Code);
   begin
      return (Pos >= Character'Pos ('A') and then Pos <= Character'Pos ('Z'))
        or else (Pos >= Character'Pos ('a') and then Pos <= Character'Pos ('z'))
        or else (Pos >= Character'Pos ('0') and then Pos <= Character'Pos ('9'))
        or else Code = '_';
   end Is_Semantic_Identifier_Character;

   procedure Clear_Semantic_Popup (S : in out Editor.State.State_Type) is
   begin
      S.Semantic_Popup :=
        (Active => False,
         Kind => Editor.State.No_Semantic_Popup,
         Anchor_Row => 0,
         Anchor_Column => 0,
         Title => Null_Unbounded_String,
         Detail => Null_Unbounded_String,
         Item_Count => 0,
         Selected_Item => 0,
         Items => (others => (others => <>)));
   end Clear_Semantic_Popup;

   function Semantic_Completion_Popup_Is_Active
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return S.Semantic_Popup.Active
        and then S.Semantic_Popup.Kind = Editor.State.Semantic_Completion_Popup
        and then S.Semantic_Popup.Item_Count > 0
        and then S.Semantic_Popup.Selected_Item in 1 .. S.Semantic_Popup.Item_Count;
   end Semantic_Completion_Popup_Is_Active;

   procedure Execute_Semantic_Completion_Select
     (S    : in out Editor.State.State_Type;
      Next : Boolean)
   is
      Count : constant Natural := S.Semantic_Popup.Item_Count;
   begin
      if not Semantic_Completion_Popup_Is_Active (S) then
         return;
      end if;

      if Next then
         S.Semantic_Popup.Selected_Item :=
           (if S.Semantic_Popup.Selected_Item >= Count
            then 1
            else S.Semantic_Popup.Selected_Item + 1);
      else
         S.Semantic_Popup.Selected_Item :=
           (if S.Semantic_Popup.Selected_Item <= 1
            then Count
            else S.Semantic_Popup.Selected_Item - 1);
      end if;

      Editor.Render_Cache.Invalidate_All;
   end Execute_Semantic_Completion_Select;

   procedure Execute_Semantic_Completion_Accept
     (S : in out Editor.State.State_Type)
   is
      Label : Unbounded_String;
      Start_Pos : Natural;
      End_Pos   : Natural;
      Caret     : Natural;
      Len       : Natural;
      Cmd       : Editor.Commands.Command;
      Before    : Editor.State.State_Type;
      Before_Text : Unbounded_String;
   begin
      if not Semantic_Completion_Popup_Is_Active (S) then
         return;
      end if;

      Label :=
        S.Semantic_Popup.Items
          (Editor.State.Semantic_Completion_Item_Index
             (S.Semantic_Popup.Selected_Item)).Label;
      if Length (Label) = 0 then
         return;
      end if;

      Len := Text_Buffer.Length (S.Buffer);
      Caret := Natural'Min (Natural (Editor.Executor.Safe_Caret (S)), Len);
      Start_Pos := Caret;
      End_Pos := Caret;

      while Start_Pos > 0
        and then Is_Semantic_Identifier_Character
          (Text_Buffer.Code_Point_At (S.Buffer, Start_Pos - 1))
      loop
         Start_Pos := Start_Pos - 1;
      end loop;

      while End_Pos < Len
        and then Is_Semantic_Identifier_Character
          (Text_Buffer.Code_Point_At (S.Buffer, End_Pos))
      loop
         End_Pos := End_Pos + 1;
      end loop;

      Cmd.Kind := Editor.Commands.Apply_Replace_Batch;
      Editor.Executor.Append_Replace_Op
        (Cmd,
         Editor.Cursors.Cursor_Index (Start_Pos),
         End_Pos - Start_Pos,
         Label);

      Editor.Buffers.Ensure_Global_Registry (S);
      Before := S;
      Before_Text := To_Unbounded_String (Editor.State.Current_Text (S));
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Cmd);
      if Editor.State.Current_Text (S) /= To_String (Before_Text) then
         declare
            New_Pos : constant Editor.Cursors.Cursor_Index :=
              Editor.Cursors.Cursor_Index
                (Start_Pos
                 + Text_Buffer.UTF8_Code_Point_Count (To_String (Label)));
            C : Editor.Cursors.Caret_State := S.Carets (S.Carets.First_Index);
         begin
            C.Pos := New_Pos;
            C.Anchor := New_Pos;
            C.Virtual_Column := 0;
            C.Anchor_Virtual_Column := 0;
            S.Carets.Replace_Element (S.Carets.First_Index, C);
         end;
         Editor.State.Load_Text (Before, To_String (Before_Text));
         Editor.Executor.History.Log_Edit (Before, S, Cmd);
         Editor.Buffers.Sync_Global_Active_From_State (S);
      end if;

      Clear_Semantic_Popup (S);
      Editor.Executor.Report_Info (S, "Accepted completion " & To_String (Label) & ".");
      Editor.Render_Cache.Invalidate_All;
   end Execute_Semantic_Completion_Accept;

end Editor.Executor.Semantic_Completion_Commands;
