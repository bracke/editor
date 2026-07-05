with Text_Buffer;
with Ada.Containers; use Ada.Containers;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Commands; use Editor.Commands;
with Editor.Cursors;  use Editor.Cursors;
with Editor.Executor.Edits; use Editor.Executor.Edits;
with Editor.Executor.History;
with Editor.State;
with Editor.Unicode;

package body Editor.Executor.Text_Delete_Commands is

   use type Editor.Executor_Edit_Status.Line_Edit_Status;
   use Cursors_Vector;

   function Safe_Caret
     (S : Editor.State.State_Type) return Cursor_Index is
   begin
      if S.Carets.Length = 0 then
         return 0;
      else
         return S.Carets.Element (S.Carets.First_Index).Pos;
      end if;
   end Safe_Caret;

   function Missing_Active_Buffer
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return not Editor.State.Has_Active_Buffer (S);
   end Missing_Active_Buffer;

   function Empty_Text return Unbounded_String is
   begin
      return Null_Unbounded_String;
   end Empty_Text;

   procedure Collapse_To_One_Caret
     (S   : in out Editor.State.State_Type;
      Pos : Cursor_Index) is
   begin
      S.Carets.Clear;
      S.Carets.Append (Caret_State'(
         Pos => Pos,
         Anchor => Pos,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));
   end Collapse_To_One_Caret;

   type Canonical_Word_Delete_Range is record
      Has_Range : Boolean := False;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
   end record;

   type Canonical_Word_Delete_Char_Class is (Word_Delete_Word, Word_Delete_Whitespace, Word_Delete_Other);

   function Is_Canonical_Word_Delete_Word_Character
     (Code : Editor.Unicode.Code_Point) return Boolean
   is
      V : constant Natural := Editor.Unicode.Code_Point'Pos (Code);
   begin
      if V > 255 then
         return False;
      end if;

      declare
         Ch : constant Character := Character'Val (V);
      begin
         return
           (Ch in 'a' .. 'z')
           or else (Ch in 'A' .. 'Z')
           or else (Ch in '0' .. '9')
           or else Ch = '_';
      end;
   end Is_Canonical_Word_Delete_Word_Character;

   function Is_Canonical_Word_Delete_Whitespace_Character
     (Code : Editor.Unicode.Code_Point) return Boolean
   is
      V : constant Natural := Editor.Unicode.Code_Point'Pos (Code);
   begin
      if V > 255 then
         return False;
      end if;

      declare
         Ch : constant Character := Character'Val (V);
      begin
         return Ch = ' ' or else Ch = ASCII.HT or else Ch = ASCII.LF or else Ch = ASCII.CR;
      end;
   end Is_Canonical_Word_Delete_Whitespace_Character;

   function Canonical_Word_Delete_Character_Class
     (S     : Editor.State.State_Type;
      Index : Natural) return Canonical_Word_Delete_Char_Class
   is
      Code : constant Editor.Unicode.Code_Point :=
        Text_Buffer.Code_Point_At (S.Buffer, Index);
   begin
      if Is_Canonical_Word_Delete_Word_Character (Code) then
         return Word_Delete_Word;
      elsif Is_Canonical_Word_Delete_Whitespace_Character (Code) then
         return Word_Delete_Whitespace;
      else
         return Word_Delete_Other;
      end if;
   end Canonical_Word_Delete_Character_Class;

   function Previous_Word_Delete_Range
     (S     : Editor.State.State_Type;
      Caret : Natural) return Canonical_Word_Delete_Range
   is
      Len    : constant Natural := Text_Buffer.Length (S.Buffer);
      I      : Natural := Natural'Min (Caret, Len);
      Result : Canonical_Word_Delete_Range;
      Target : Canonical_Word_Delete_Char_Class := Word_Delete_Other;
   begin
      if I = 0 or else Len = 0 then
         return Result;
      end if;

      if I = Len
        and then Canonical_Word_Delete_Character_Class (S, I - 1) =
          Word_Delete_Whitespace
      then
         while I > 0
           and then Canonical_Word_Delete_Character_Class (S, I - 1) =
             Word_Delete_Whitespace
         loop
            I := I - 1;
         end loop;
      end if;

      Result.End_Pos := I;

      if I = 0 then
         return Result;
      end if;

      if Canonical_Word_Delete_Character_Class (S, I - 1) = Word_Delete_Whitespace then
         while I > 0 and then Canonical_Word_Delete_Character_Class (S, I - 1) = Word_Delete_Whitespace loop
            I := I - 1;
         end loop;

         while I > 0 and then Canonical_Word_Delete_Character_Class (S, I - 1) = Word_Delete_Word loop
            I := I - 1;
         end loop;
      else
         Target := Canonical_Word_Delete_Character_Class (S, I - 1);
         while I > 0 and then Canonical_Word_Delete_Character_Class (S, I - 1) = Target loop
            I := I - 1;
         end loop;
      end if;

      if I < Result.End_Pos then
         Result.Has_Range := True;
         Result.Start_Pos := I;
      end if;

      return Result;
   end Previous_Word_Delete_Range;

   function Next_Word_Delete_Range
     (S     : Editor.State.State_Type;
      Caret : Natural) return Canonical_Word_Delete_Range
   is
      Len    : constant Natural := Text_Buffer.Length (S.Buffer);
      I      : Natural := Natural'Min (Caret, Len);
      Result : Canonical_Word_Delete_Range;
      Target : Canonical_Word_Delete_Char_Class := Word_Delete_Other;
   begin
      Result.Start_Pos := I;
      Result.End_Pos := I;

      if I >= Len or else Len = 0 then
         return Result;
      end if;

      if Canonical_Word_Delete_Character_Class (S, I) = Word_Delete_Whitespace then
         while I < Len and then Canonical_Word_Delete_Character_Class (S, I) = Word_Delete_Whitespace loop
            I := I + 1;
         end loop;

         while I < Len and then Canonical_Word_Delete_Character_Class (S, I) = Word_Delete_Word loop
            I := I + 1;
         end loop;
      else
         Target := Canonical_Word_Delete_Character_Class (S, I);
         while I < Len and then Canonical_Word_Delete_Character_Class (S, I) = Target loop
            I := I + 1;
         end loop;
      end if;

      if I > Result.Start_Pos then
         Result.Has_Range := True;
         Result.End_Pos := I;
      end if;

      return Result;
   end Next_Word_Delete_Range;

   function Valid_Canonical_Word_Delete_Range
     (S     : Editor.State.State_Type;
      Selection_Range : Canonical_Word_Delete_Range) return Boolean
   is
      Len : constant Natural := Text_Buffer.Length (S.Buffer);
   begin
      return Selection_Range.Has_Range
        and then Selection_Range.Start_Pos < Selection_Range.End_Pos
        and then Selection_Range.End_Pos <= Len;
   end Valid_Canonical_Word_Delete_Range;

   procedure Apply_Word_Delete_As_Undoable_Mutation
     (S           : in out Editor.State.State_Type;
      Selection_Range       : Canonical_Word_Delete_Range;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command)
   is
   begin
      Forward_Cmd.Kind := Apply_Replace_Batch;
      Append_Replace_Op
        (Forward_Cmd,
         Cursor_Index (Selection_Range.Start_Pos),
         Selection_Range.End_Pos - Selection_Range.Start_Pos,
         Empty_Text);
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      --  Both delete-previous and delete-next normalize to the deletion start.
      --  The command-level Undo/Redo capture, redo invalidation, dirty tracking,
      --  and Find/Replace invalidation remain owned by the canonical Executor
      --  edit pipeline around this mutation helper.
      Collapse_To_One_Caret (S, Cursor_Index (Selection_Range.Start_Pos));
      New_Caret := Safe_Caret (S);
   end Apply_Word_Delete_As_Undoable_Mutation;



   type Canonical_Character_Delete_Range is record
      Has_Range : Boolean := False;
      Start_Pos : Natural := 0;
      End_Pos   : Natural := 0;
   end record;

   --  reliability: a character delete range is exactly one
   --  canonical buffer text unit adjacent to the caret.  This deliberately
   --  uses Text_Buffer positions only; rendering, visual wrapping, glyph
   --  shaping, settings, syntax, Clipboard state, and Word/Line command
   --  helpers are outside the Character Delete boundary.
   function Previous_Character_Delete_Range
     (S     : Editor.State.State_Type;
      Caret : Natural) return Canonical_Character_Delete_Range
   is
      Len    : constant Natural := Text_Buffer.Length (S.Buffer);
      Pos    : constant Natural := Natural'Min (Caret, Len);
      Result : Canonical_Character_Delete_Range;
   begin
      if Pos = 0 or else Len = 0 then
         return Result;
      end if;

      Result.Has_Range := True;
      Result.Start_Pos := Pos - 1;
      Result.End_Pos := Pos;
      return Result;
   end Previous_Character_Delete_Range;

   function Next_Character_Delete_Range
     (S     : Editor.State.State_Type;
      Caret : Natural) return Canonical_Character_Delete_Range
   is
      Len    : constant Natural := Text_Buffer.Length (S.Buffer);
      Pos    : constant Natural := Natural'Min (Caret, Len);
      Result : Canonical_Character_Delete_Range;
   begin
      if Pos >= Len or else Len = 0 then
         return Result;
      end if;

      Result.Has_Range := True;
      Result.Start_Pos := Pos;
      Result.End_Pos := Pos + 1;
      return Result;
   end Next_Character_Delete_Range;

   function Valid_Canonical_Character_Delete_Range
     (S     : Editor.State.State_Type;
      Selection_Range : Canonical_Character_Delete_Range) return Boolean
   is
      Len : constant Natural := Text_Buffer.Length (S.Buffer);
   begin
      return Selection_Range.Has_Range
        and then Selection_Range.Start_Pos < Selection_Range.End_Pos
        and then Selection_Range.End_Pos <= Len;
   end Valid_Canonical_Character_Delete_Range;

   procedure Apply_Character_Delete_As_Undoable_Mutation
     (S           : in out Editor.State.State_Type;
      Selection_Range       : Canonical_Character_Delete_Range;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command)
   is
   begin
      Forward_Cmd.Kind := Apply_Replace_Batch;
      Append_Replace_Op
        (Forward_Cmd,
         Cursor_Index (Selection_Range.Start_Pos),
         Selection_Range.End_Pos - Selection_Range.Start_Pos,
         Empty_Text);
      Editor.Executor.History.Apply_Replace_Batch_Command (S, Forward_Cmd);

      Collapse_To_One_Caret (S, Cursor_Index (Selection_Range.Start_Pos));
      New_Caret := Safe_Caret (S);
   end Apply_Character_Delete_As_Undoable_Mutation;

   procedure Perform_Delete_Previous_Character
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Selection_Range : Canonical_Character_Delete_Range;
      Pos   : Natural := 0;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if Missing_Active_Buffer (S) then
         Status := No_Active_Buffer;
         New_Caret := Safe_Caret (S);
         return;
      elsif S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Pos := Natural (Safe_Caret (S));
      if Pos > Text_Buffer.Length (S.Buffer) + 1 then
         Status := Delete_Previous_Character_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Selection_Range := Previous_Character_Delete_Range (S, Pos);
      if not Selection_Range.Has_Range then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      elsif not Valid_Canonical_Character_Delete_Range (S, Selection_Range) then
         Status := Delete_Previous_Character_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Apply_Character_Delete_As_Undoable_Mutation
        (S, Selection_Range, New_Caret, Forward_Cmd);
      Status := Previous_Character_Deleted;
      Changed := True;
   exception
      when others =>
         Status := Delete_Previous_Character_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Delete_Previous_Character;

   procedure Perform_Delete_Next_Character
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Selection_Range : Canonical_Character_Delete_Range;
      Pos   : Natural := 0;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if Missing_Active_Buffer (S) then
         Status := No_Active_Buffer;
         New_Caret := Safe_Caret (S);
         return;
      elsif S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Pos := Natural (Safe_Caret (S));
      if Pos > Text_Buffer.Length (S.Buffer) then
         Status := Delete_Next_Character_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Selection_Range := Next_Character_Delete_Range (S, Pos);
      if not Selection_Range.Has_Range then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      elsif not Valid_Canonical_Character_Delete_Range (S, Selection_Range) then
         Status := Delete_Next_Character_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Apply_Character_Delete_As_Undoable_Mutation
        (S, Selection_Range, New_Caret, Forward_Cmd);
      Status := Next_Character_Deleted;
      Changed := True;
   exception
      when others =>
         Status := Delete_Next_Character_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Delete_Next_Character;

   procedure Perform_Delete_Previous_Word
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Selection_Range : Canonical_Word_Delete_Range;
      Pos   : Natural := 0;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if Missing_Active_Buffer (S) then
         Status := No_Active_Buffer;
         New_Caret := Safe_Caret (S);
         return;
      elsif S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Pos := Natural (Safe_Caret (S));
      if Pos > Text_Buffer.Length (S.Buffer) + 1 then
         Status := Delete_Previous_Word_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Selection_Range := Previous_Word_Delete_Range (S, Pos);
      if not Selection_Range.Has_Range then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      elsif not Valid_Canonical_Word_Delete_Range (S, Selection_Range) then
         Status := Delete_Previous_Word_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Apply_Word_Delete_As_Undoable_Mutation
        (S, Selection_Range, New_Caret, Forward_Cmd);
      Status := Previous_Word_Deleted;
      Changed := True;
   exception
      when others =>
         Status := Delete_Previous_Word_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Delete_Previous_Word;

   procedure Perform_Delete_Next_Word
     (S           : in out Editor.State.State_Type;
      New_Caret   : out Cursor_Index;
      Forward_Cmd : out Editor.Commands.Command;
      Changed     : out Boolean;
      Status      : out Line_Edit_Status)
   is
      Selection_Range : Canonical_Word_Delete_Range;
      Pos   : Natural := 0;
   begin
      Changed := False;
      Status := Line_Edit_None;
      Forward_Cmd.Kind := Apply_Replace_Batch;

      if Missing_Active_Buffer (S) then
         Status := No_Active_Buffer;
         New_Caret := Safe_Caret (S);
         return;
      elsif S.Carets.Length = 0 then
         Status := No_Caret_Location;
         New_Caret := 0;
         return;
      elsif Text_Buffer.Length (S.Buffer) = 0 then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Pos := Natural (Safe_Caret (S));
      if Pos > Text_Buffer.Length (S.Buffer) then
         Status := Delete_Next_Word_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Selection_Range := Next_Word_Delete_Range (S, Pos);
      if not Selection_Range.Has_Range then
         Status := Nothing_To_Delete;
         New_Caret := Safe_Caret (S);
         return;
      elsif not Valid_Canonical_Word_Delete_Range (S, Selection_Range) then
         Status := Delete_Next_Word_Failed;
         New_Caret := Safe_Caret (S);
         return;
      end if;

      Apply_Word_Delete_As_Undoable_Mutation
        (S, Selection_Range, New_Caret, Forward_Cmd);
      Status := Next_Word_Deleted;
      Changed := True;
   exception
      when others =>
         Status := Delete_Next_Word_Failed;
         New_Caret := Safe_Caret (S);
         Changed := False;
   end Perform_Delete_Next_Word;

end Editor.Executor.Text_Delete_Commands;
