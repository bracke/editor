with Text_Buffer;
with Ada.Containers; use Ada.Containers;
with Editor.State;
with Editor.Commands; use Editor.Commands;
with Editor.History; use Editor.History;
with Editor.Executor;
with Editor.Executor.Edits;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Cursors; use Editor.Cursors;
with Editor.UTF8;
with Editor.Dirty_Lines;
with Editor.Project_Search;
with Editor.Search;

package body Editor.Executor.History is

   Last_Was_Group_Break : Boolean := False;
   Last_Failed          : Boolean := False;
   Max_History_Entries  : constant Natural := 100;

   function Last_Operation_Failed return Boolean is
   begin
      return Last_Failed;
   end Last_Operation_Failed;

   procedure Clear_Operation_Status is
   begin
      Last_Failed := False;
   end Clear_Operation_Status;

   procedure Break_Group is
   begin
      Last_Was_Group_Break := True;
   end Break_Group;

   function Empty_Text return Unbounded_String is
   begin
      return Null_Unbounded_String;
   end Empty_Text;

   procedure Trim_To_Bound (Stack : in out Editor.History.History_Vector.Vector) is
   begin
      while Natural (Stack.Length) > Max_History_Entries loop
         Stack.Delete_First;
      end loop;
   end Trim_To_Bound;

   function Same_Text
     (Left  : Editor.State.State_Type;
      Right : Editor.State.State_Type) return Boolean
   is
   begin
      return Text_Buffer.UTF8_Text (Left.Buffer) =
        Text_Buffer.UTF8_Text (Right.Buffer);
   end Same_Text;

   function Snapshot_Text
     (S : Editor.State.State_Type) return Unbounded_String
   is
   begin
      return To_Unbounded_String (Text_Buffer.UTF8_Text (S.Buffer));
   end Snapshot_Text;

   procedure Mark_Current_File_Replace_Preview_Stale
     (S : in out Editor.State.State_Type)
   is
   begin
      if S.File_Info.Has_Path then
         Editor.Project_Search.Mark_Replace_Preview_Stale_For_Absolute_File
           (S.Project_Search, To_String (S.File_Info.Path));
      end if;
   end Mark_Current_File_Replace_Preview_Stale;

   procedure Recompute_Active_Find_After_Restore
     (S : in out Editor.State.State_Type)
   is
      Query      : constant String := To_String (S.Active_Find_Query);
      Options    : constant Editor.Search.Search_Options :=
        (Case_Sensitive => S.Active_Find_Case_Sensitive, Wrap => True);
      Candidates : Editor.Search.Search_Match_Vectors.Vector;
   begin
      S.Active_Find_Matches.Clear;
      S.Active_Find_Match := Editor.Search.No_Match;
      S.Active_Find_Stale := False;

      if Query'Length = 0 then
         S.Active_Find_Source_Buffer_Token := 0;
         return;
      end if;

      for Ch of Query loop
         if Ch = Character'Val (10) or else Ch = Character'Val (13) then
            S.Active_Find_Stale := True;
            S.Active_Find_Source_Buffer_Token := S.Active_Buffer_Token;
            return;
         end if;
      end loop;

      S.Active_Find_Source_Buffer_Token := S.Active_Buffer_Token;
      Editor.Search.Find_All (S.Buffer, Query, Options, Candidates);
      S.Active_Find_Matches := Candidates;

      if not S.Active_Find_Matches.Is_Empty then
         S.Active_Find_Match := S.Active_Find_Matches (S.Active_Find_Matches.First_Index);
      end if;
   end Recompute_Active_Find_After_Restore;

   procedure Restore_Buffer_Text
     (S    : in out Editor.State.State_Type;
      Text : Unbounded_String)
   is
      Old_Length : constant Natural :=
        Text_Buffer.UTF8_Code_Point_Count (Text_Buffer.UTF8_Text (S.Buffer));
      New_Length : constant Natural :=
        Text_Buffer.UTF8_Code_Point_Count (To_String (Text));
   begin
      Text_Buffer.Set_Text (S.Buffer, To_String (Text));

      --  Treat undo/redo as a canonical whole-buffer text mutation for
      --  dependent editor state: Find/Replace ranges are invalidated or
      --  recomputed through the ordinary post-edit path, diagnostics are
      --  cleared, render snapshots observe the new revision, and no
      --  Navigation History entry is recorded.
      Editor.State.Rebuild_After_Buffer_Change
        (S,
         (Start_Index => 0,
          Old_Length  => Old_Length,
          New_Length  => New_Length));
      Recompute_Active_Find_After_Restore (S);
   end Restore_Buffer_Text;

   function Entry_Owns_Current_Buffer
     (S : Editor.State.State_Type;
      E : History_Entry) return Boolean
   is
   begin
      return E.Owner_Buffer_Token = S.Active_Buffer_Token
        and then E.Owner_Lifecycle_Generation = S.Lifecycle_Generation;
   end Entry_Owns_Current_Buffer;

   procedure Append_Replace_Op
     (Cmd          : in out Editor.Commands.Command;
      Pos          : Cursor_Index;
      Delete_Count : Natural;
      Insert_Text  : Unbounded_String) is
   begin
      Cmd.Positions.Append (Pos);
      Cmd.Delete_Counts.Append (Delete_Count);
      Cmd.Insert_Texts.Append (Insert_Text);
   end Append_Replace_Op;

   function Extract_Text
     (Buffer : Text_Buffer.Buffer_Type;
      Pos    : Natural;
      Count  : Natural) return Unbounded_String
   is
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      if Count = 0 then
         return Result;
      end if;

      for I in 0 .. Count - 1 loop
         Append (Result, Editor.UTF8.Encode_UTF8
           (Text_Buffer.Code_Point_At (Buffer, Pos + I)));
      end loop;

      return Result;
   end Extract_Text;

   procedure Apply_Replace_Batch_Command
   (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command)
   is
      Work    : Editor.Commands.Command := Cmd;
      Overlap : Boolean := False;

      procedure Swap_Ops (A, B : Natural) is
         Pos_T : Cursor_Index;
         Del_T : Natural;
         Txt_T : Unbounded_String;
      begin
         Pos_T := Work.Positions.Element (A);
         Del_T := Work.Delete_Counts.Element (A);
         Txt_T := Work.Insert_Texts.Element (A);

         Work.Positions.Replace_Element
         (A, Work.Positions.Element (B));
         Work.Delete_Counts.Replace_Element
         (A, Work.Delete_Counts.Element (B));
         Work.Insert_Texts.Replace_Element
         (A, Work.Insert_Texts.Element (B));

         Work.Positions.Replace_Element (B, Pos_T);
         Work.Delete_Counts.Replace_Element (B, Del_T);
         Work.Insert_Texts.Replace_Element (B, Txt_T);
      end Swap_Ops;

      procedure Apply_One
      (Pos : Natural;
         Del : Natural;
         Ins : Unbounded_String)
      is
      begin
         if Del > 0 or else Length (Ins) > 0 then
            Text_Buffer.Replace_Range
              (S.Buffer,
               Pos,
               Pos + Del,
               To_String (Ins));
         end if;
      end Apply_One;

   begin
      pragma Assert
      (Cmd.Kind = Apply_Replace_Batch,
         "Apply_Replace_Batch_Command requires Apply_Replace_Batch");

      pragma Assert
      (Cmd.Positions.Length = Cmd.Delete_Counts.Length,
         "Replace batch positions/delete counts length mismatch");

      pragma Assert
      (Cmd.Positions.Length = Cmd.Insert_Texts.Length,
         "Replace batch positions/insert texts length mismatch");

      if Cmd.Positions.Length = 0 then
         return;
      end if;

      ------------------------------------------------------------------
      -- Normalize operation order: ascending original position.
      ------------------------------------------------------------------
      if Work.Positions.Length > 1 then
         for I in Work.Positions.First_Index .. Work.Positions.Last_Index loop
            for J in I + 1 .. Work.Positions.Last_Index loop
               if Natural (Work.Positions.Element (J)) <
                  Natural (Work.Positions.Element (I))
               then
                  Swap_Ops (I, J);
               end if;
            end loop;
         end loop;
      end if;

      ------------------------------------------------------------------
      -- Reject overlapping or duplicate-position replace operations.
      --
      -- For a clean batch model, each operation owns a distinct original
      -- span. Equal positions are also rejected here because multiple
      -- inserts at the same position have order-dependent semantics.
      ------------------------------------------------------------------
      if Work.Positions.Length > 1 then
         for I in Work.Positions.First_Index .. Work.Positions.Last_Index - 1 loop
            declare
               Pos_A : constant Natural :=
               Natural (Work.Positions.Element (I));

               Del_A : constant Natural :=
               Work.Delete_Counts.Element (I);

               Pos_B : constant Natural :=
               Natural (Work.Positions.Element (I + 1));

               End_A : constant Natural := Pos_A + Del_A;
            begin
               if Pos_A >= Pos_B or else End_A > Pos_B then
                  Overlap := True;
                  exit;
               end if;
            end;
         end loop;
      end if;

      pragma Assert
      (not Overlap,
         "Replace batch operations must be non-overlapping and unique");

      ------------------------------------------------------------------
      -- Safe path: sorted, non-overlapping batch.
      --
      -- Apply in reverse order so positions remain original-space
      -- positions for every operation.
      ------------------------------------------------------------------
      if not Overlap then
         declare
            First_Pos : constant Natural :=
              Natural (Work.Positions.Element (Work.Positions.First_Index));
            Last_I    : constant Natural := Work.Positions.Last_Index;
            Last_Pos  : constant Natural := Natural (Work.Positions.Element (Last_I));
            Last_Del  : constant Natural := Work.Delete_Counts.Element (Last_I);
            Old_Span  : constant Natural := Last_Pos + Last_Del - First_Pos;
            Step_Delta     : Integer := 0;
         begin
            for I in Work.Positions.First_Index .. Work.Positions.Last_Index loop
               Step_Delta := Step_Delta
                 + Integer
                     (Text_Buffer.UTF8_Code_Point_Count
                        (To_String (Work.Insert_Texts.Element (I))))
                 - Integer (Work.Delete_Counts.Element (I));
            end loop;

            for I in reverse Work.Positions.First_Index .. Work.Positions.Last_Index loop
               Apply_One
                 (Natural (Work.Positions.Element (I)),
                  Work.Delete_Counts.Element (I),
                  Work.Insert_Texts.Element (I));
            end loop;

            --  A replace batch is one logical edit.  Rebuild the dependent
            --  editor state once from the final buffer so diagnostics are
            --  cleared once, dirty state is set once, and active Find highlights
            --  are recomputed from the completed document rather than from
            --  each intermediate reverse-applied replacement.
            Editor.State.Rebuild_After_Buffer_Change
              (S,
               (Start_Index => First_Pos,
                Old_Length  => Old_Span,
                New_Length  => Natural (Integer (Old_Span) + Step_Delta)));
            Mark_Current_File_Replace_Preview_Stale (S);

            --  a successful text edit invalidates any active
            --  selection that was expressed in pre-edit coordinates.  Keep
            --  caret endpoints valid, but collapse selections so later
            --  Clipboard/Find consumers cannot extract stale ranges.
            for I in S.Carets.First_Index .. S.Carets.Last_Index loop
               declare
                  C : Caret_State := S.Carets (I);
               begin
                  C.Anchor := C.Pos;
                  C.Anchor_Virtual_Column := C.Virtual_Column;
                  S.Carets.Replace_Element (I, C);
               end;
            end loop;
            S.Rect_Select_Active := False;
         end;

      ------------------------------------------------------------------
      -- Release-build safety fallback.
      --
      -- If assertions are disabled and an invalid overlapping batch reaches
      -- here, apply in reverse order and rebuild once from the final buffer.
      ------------------------------------------------------------------
      else
         for I in reverse Cmd.Positions.First_Index .. Cmd.Positions.Last_Index loop
            Apply_One
            (Natural (Cmd.Positions.Element (I)),
               Cmd.Delete_Counts.Element (I),
               Cmd.Insert_Texts.Element (I));
         end loop;

         Editor.State.Rebuild_After_Buffer_Change (S);
         Mark_Current_File_Replace_Preview_Stale (S);
         for I in S.Carets.First_Index .. S.Carets.Last_Index loop
            declare
               C : Caret_State := S.Carets (I);
            begin
               C.Anchor := C.Pos;
               C.Anchor_Virtual_Column := C.Virtual_Column;
               S.Carets.Replace_Element (I, C);
            end;
         end loop;
         S.Rect_Select_Active := False;
      end if;
   end Apply_Replace_Batch_Command;
   procedure Restore_Edit_Context
     (S      : in out Editor.State.State_Type;
      Carets : Caret_Vectors.Vector;
      Preferred_Column : Natural;
      Rect_Select_Active : Boolean;
      Rect_Anchor_Row : Natural;
      Rect_Anchor_Col : Natural;
      Dirty : Boolean)
   is
   begin
      S.Carets := Carets;
      S.Preferred_Column := Preferred_Column;
      S.Rect_Select_Active := Rect_Select_Active;
      S.Rect_Anchor_Row := Rect_Anchor_Row;
      S.Rect_Anchor_Col := Rect_Anchor_Col;

      Editor.State.Normalize_Carets (S);

      if Editor.Dirty_Lines.Has_Baseline (S.Dirty_Lines) then
         --  dirty state is derived from the current saved baseline
         --  when one exists, not from the stale dirty flag captured when the
         --  undo entry was created. This keeps save-then-undo correct: saving
         --  updates the baseline while preserving transient undo history.
         Editor.State.Refresh_Dirty_Lines (S);
         Editor.State.Set_Dirty
           (S, Editor.Dirty_Lines.Dirty_Line_Count (S.Dirty_Lines) > 0);
      elsif Dirty then
         Editor.State.Set_Dirty (S, True);
         Editor.State.Refresh_Dirty_Lines (S);
      else
         Editor.State.Set_Dirty (S, False);
         Editor.State.Reset_Dirty_Line_Baseline (S);
      end if;
   end Restore_Edit_Context;

   function Build_Inverse_Replace_Command
     (Before  : Editor.State.State_Type;
      Forward : Editor.Commands.Command) return Editor.Commands.Command
   is
      Work    : Editor.Commands.Command := Forward;
      Inverse : Editor.Commands.Command;
      D       : Integer := 0;

      procedure Swap_Ops (A, B : Natural) is
         Pos_T : Cursor_Index;
         Del_T : Natural;
         Txt_T : Unbounded_String;
      begin
         Pos_T := Work.Positions.Element (A);
         Del_T := Work.Delete_Counts.Element (A);
         Txt_T := Work.Insert_Texts.Element (A);

         Work.Positions.Replace_Element (A, Work.Positions.Element (B));
         Work.Delete_Counts.Replace_Element (A, Work.Delete_Counts.Element (B));
         Work.Insert_Texts.Replace_Element (A, Work.Insert_Texts.Element (B));

         Work.Positions.Replace_Element (B, Pos_T);
         Work.Delete_Counts.Replace_Element (B, Del_T);
         Work.Insert_Texts.Replace_Element (B, Txt_T);
      end Swap_Ops;
   begin
      pragma Assert
        (Forward.Kind = Apply_Replace_Batch,
         "Build_Inverse_Replace_Command requires Apply_Replace_Batch");

      Inverse.Kind := Apply_Replace_Batch;

      if Work.Positions.Length > 1 then
         for I in Work.Positions.First_Index .. Work.Positions.Last_Index loop
            for J in I + 1 .. Work.Positions.Last_Index loop
               if Natural (Work.Positions.Element (J)) <
                  Natural (Work.Positions.Element (I))
               then
                  Swap_Ops (I, J);
               end if;
            end loop;
         end loop;
      end if;

      if Work.Positions.Length > 0 then
         for I in Work.Positions.First_Index .. Work.Positions.Last_Index loop
            declare
               Pos       : constant Natural :=
                 Natural (Work.Positions.Element (I));
               Del_Count : constant Natural := Work.Delete_Counts (I);
               Ins_Text  : constant Unbounded_String := Work.Insert_Texts (I);
               Undo_Pos  : constant Cursor_Index :=
                 Cursor_Index (Integer (Pos) + D);
               Deleted   : constant Unbounded_String :=
                 Extract_Text (Before.Buffer, Pos, Del_Count);
            begin
               Append_Replace_Op
                 (Inverse,
                  Undo_Pos,
                  Text_Buffer.UTF8_Code_Point_Count (To_String (Ins_Text)),
                  Deleted);

               D := D
                 + Integer (Text_Buffer.UTF8_Code_Point_Count (To_String (Ins_Text)))
                 - Integer (Del_Count);
            end;
         end loop;
      end if;

      return Inverse;
   end Build_Inverse_Replace_Command;

   function Is_Single_Char_Insert
     (Forward : Editor.Commands.Command) return Boolean
   is
      I : Natural;
   begin
      if Forward.Kind /= Apply_Replace_Batch then
         return False;
      end if;

      if Forward.Positions.Length /= 1 then
         return False;
      end if;

      I := Forward.Positions.First_Index;

      return Forward.Delete_Counts (I) = 0
        and then Text_Buffer.UTF8_Code_Point_Count (To_String (Forward.Insert_Texts (I))) = 1
        and then Element (Forward.Insert_Texts (I), 1) /= ASCII.LF;
   end Is_Single_Char_Insert;

   function Is_Typing_Groupable
     (Before  : Editor.State.State_Type;
      After_S : Editor.State.State_Type;
      Forward : Editor.Commands.Command) return Boolean
   is
   begin
      if not Is_Single_Char_Insert (Forward) then
         return False;
      end if;

      if Before.Carets.Length /= 1 or else After_S.Carets.Length /= 1 then
         return False;
      end if;

      if Before.Carets (Before.Carets.First_Index).Anchor /=
         Before.Carets (Before.Carets.First_Index).Pos
      then
         return False;
      end if;

      if After_S.Carets (After_S.Carets.First_Index).Anchor /=
         After_S.Carets (After_S.Carets.First_Index).Pos
      then
         return False;
      end if;

      return True;
   end Is_Typing_Groupable;

   function Can_Merge_Typing
     (Prev : Editor.History.History_Entry;
      Next : Editor.History.History_Entry) return Boolean
   is
      Prev_I : Natural;
      Next_I : Natural;

      Prev_Pos  : Cursor_Index;
      Next_Pos  : Cursor_Index;
      Prev_Text : Unbounded_String;
   begin
      if Prev.Group_Kind /= Typing_Group
        or else Next.Group_Kind /= Typing_Group
      then
         return False;
      end if;

      if Prev.Forward.Positions.Length /= 1
        or else Next.Forward.Positions.Length /= 1
      then
         return False;
      end if;

      Prev_I := Prev.Forward.Positions.First_Index;
      Next_I := Next.Forward.Positions.First_Index;

      Prev_Pos  := Prev.Forward.Positions (Prev_I);
      Next_Pos  := Next.Forward.Positions (Next_I);
      Prev_Text := Prev.Forward.Insert_Texts (Prev_I);

      return Natural (Next_Pos) =
        Natural (Prev_Pos) + Text_Buffer.UTF8_Code_Point_Count (To_String (Prev_Text));
   end Can_Merge_Typing;

   function Build_Typing_Inverse
     (Forward : Editor.Commands.Command) return Editor.Commands.Command
   is
      Inverse : Editor.Commands.Command;
      I       : constant Natural := Forward.Positions.First_Index;
   begin
      Inverse.Kind := Apply_Replace_Batch;

      Append_Replace_Op
        (Inverse,
         Forward.Positions (I),
         Text_Buffer.UTF8_Code_Point_Count (To_String (Forward.Insert_Texts (I))),
         Empty_Text);

      return Inverse;
   end Build_Typing_Inverse;

   function Merge_Typing
     (Prev : Editor.History.History_Entry;
      Next : Editor.History.History_Entry) return Editor.History.History_Entry
   is
      Result : Editor.History.History_Entry := Prev;

      Prev_I : constant Natural := Result.Forward.Positions.First_Index;
      Next_I : constant Natural := Next.Forward.Positions.First_Index;

      Merged_Text : Unbounded_String;
   begin
      Merged_Text :=
        Result.Forward.Insert_Texts (Prev_I) &
        Next.Forward.Insert_Texts (Next_I);

      Result.Forward.Insert_Texts.Replace_Element
        (Prev_I, Merged_Text);

      Result.Inverse := Build_Typing_Inverse (Result.Forward);

      Result.After_Carets := Next.After_Carets;
      Result.After_Preferred_Column := Next.After_Preferred_Column;
      Result.After_Rect_Select_Active := Next.After_Rect_Select_Active;
      Result.After_Rect_Anchor_Row := Next.After_Rect_Anchor_Row;
      Result.After_Rect_Anchor_Col := Next.After_Rect_Anchor_Col;

      Result.Group_Kind := Typing_Group;

      return Result;
   end Merge_Typing;

   procedure Log_Edit
     (Before  : Editor.State.State_Type;
      After_S : Editor.State.State_Type;
      Forward : Editor.Commands.Command)
   is
      E : Editor.History.History_Entry;
   begin
      --  A no-op command is not an edit history event and must not invalidate
      --  redo history after an undo.
      if Same_Text (Before, After_S) then
         return;
      end if;

      E.Forward := Forward;
      E.Before_Text := Snapshot_Text (Before);
      E.After_Text  := Snapshot_Text (After_S);

      E.Before_Carets := Before.Carets;
      E.After_Carets  := After_S.Carets;

      E.Before_Preferred_Column := Before.Preferred_Column;
      E.After_Preferred_Column  := After_S.Preferred_Column;

      E.Before_Rect_Select_Active := Before.Rect_Select_Active;
      E.After_Rect_Select_Active  := After_S.Rect_Select_Active;
      E.Before_Rect_Anchor_Row    := Before.Rect_Anchor_Row;
      E.Before_Rect_Anchor_Col    := Before.Rect_Anchor_Col;
      E.After_Rect_Anchor_Row     := After_S.Rect_Anchor_Row;
      E.After_Rect_Anchor_Col     := After_S.Rect_Anchor_Col;

      E.Before_Dirty := Before.File_Info.Dirty;
      E.After_Dirty  := After_S.File_Info.Dirty;
      E.Owner_Buffer_Token := Before.Active_Buffer_Token;
      E.Owner_Lifecycle_Generation := Before.Lifecycle_Generation;

      --  every successful concrete editing command is recorded
      --  as one predictable undo unit.  Older typing coalescing support is
      --  intentionally bypassed here so single insertions, newline insertion,
      --  paste, deletion, and selected replacement have direct undo/redo
      --  semantics.
      E.Group_Kind := No_Group;
      E.Inverse := Build_Inverse_Replace_Command (Before, Forward);

      Undo_Stack.Append (E);
      Trim_To_Bound (Undo_Stack);

      Last_Was_Group_Break := False;
      Redo_Stack.Clear;

   end Log_Edit;

   procedure Execute
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) is
   begin
      Last_Failed := False;

      case Cmd.Kind is
         when Editor.Commands.Undo =>
            if not Undo_Stack.Is_Empty then
               declare
                  Old_State : constant Editor.State.State_Type := S;
                  Old_Undo  : constant Editor.History.History_Vector.Vector := Undo_Stack;
                  Old_Redo  : constant Editor.History.History_Vector.Vector := Redo_Stack;
                  E         : constant History_Entry := Undo_Stack.Last_Element;
               begin
                  if not Entry_Owns_Current_Buffer (S, E) then
                     Last_Failed := True;
                     return;
                  end if;

                  Undo_Stack.Delete_Last;

                  Restore_Buffer_Text (S, E.Before_Text);

                  Restore_Edit_Context
                    (S,
                     E.Before_Carets,
                     E.Before_Preferred_Column,
                     E.Before_Rect_Select_Active,
                     E.Before_Rect_Anchor_Row,
                     E.Before_Rect_Anchor_Col,
                     E.Before_Dirty);

                  Last_Was_Group_Break := True;
                  Redo_Stack.Append (E);
                  Trim_To_Bound (Redo_Stack);
               exception
                  when others =>
                     S := Old_State;
                     Undo_Stack := Old_Undo;
                     Redo_Stack := Old_Redo;
                     Last_Failed := True;
               end;
            end if;

         when Editor.Commands.Redo =>
            if not Redo_Stack.Is_Empty then
               declare
                  Old_State : constant Editor.State.State_Type := S;
                  Old_Undo  : constant Editor.History.History_Vector.Vector := Undo_Stack;
                  Old_Redo  : constant Editor.History.History_Vector.Vector := Redo_Stack;
                  E         : constant History_Entry := Redo_Stack.Last_Element;
               begin
                  if not Entry_Owns_Current_Buffer (S, E) then
                     Last_Failed := True;
                     return;
                  end if;

                  Redo_Stack.Delete_Last;

                  Restore_Buffer_Text (S, E.After_Text);

                  Restore_Edit_Context
                    (S,
                     E.After_Carets,
                     E.After_Preferred_Column,
                     E.After_Rect_Select_Active,
                     E.After_Rect_Anchor_Row,
                     E.After_Rect_Anchor_Col,
                     E.After_Dirty);

                  Last_Was_Group_Break := True;
                  Undo_Stack.Append (E);
                  Trim_To_Bound (Undo_Stack);
               exception
                  when others =>
                     S := Old_State;
                     Undo_Stack := Old_Undo;
                     Redo_Stack := Old_Redo;
                     Last_Failed := True;
               end;
            end if;

         when Editor.Commands.Break_Group =>
            Last_Failed := False;

         when others =>
            null;
      end case;
   end Execute;

end Editor.Executor.History;
