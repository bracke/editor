with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Token_Cursor.Tokenization;
with Editor.Text_Helpers;

package body Editor.Ada_Token_Cursor.Navigation_Helpers is

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   function Lookahead_Lower
     (Position : Editor.Ada_Token_Cursor.Cursor;
      Offset   : Natural) return String is
      Index : constant Natural := Position.Index + Offset;
   begin
      if Index < 1 or else Index > Natural (Position.Stream.Tokens.Length) then
         return "";
      end if;
      return To_String (Position.Stream.Tokens (Positive (Index)).Lower);
   end Lookahead_Lower;

   function Lookahead_Kind
     (Position : Editor.Ada_Token_Cursor.Cursor;
      Offset   : Natural) return Editor.Ada_Token_Cursor.Token_Kind is
      Index : constant Natural := Position.Index + Offset;
   begin
      if Index < 1 or else Index > Natural (Position.Stream.Tokens.Length) then
         return Editor.Ada_Token_Cursor.Token_End_Of_Input;
      end if;
      return Position.Stream.Tokens (Positive (Index)).Kind;
   end Lookahead_Kind;

   function Current_Lower
     (Position : Editor.Ada_Token_Cursor.Cursor) return String is
   begin
      return To_String (Editor.Ada_Token_Cursor.Tokenization.Current (Position).Lower);
   end Current_Lower;

   procedure Skip_Balanced_To_Semicolon
     (Position : in out Editor.Ada_Token_Cursor.Cursor) is
      Paren_Depth : Natural := 0;
   begin
      while not Editor.Ada_Token_Cursor.Tokenization.At_End (Position) loop
         declare
            T : constant String := To_String (Editor.Ada_Token_Cursor.Tokenization.Current (Position).Text);
         begin
            if T = "(" then
               Paren_Depth := Paren_Depth + 1;
            elsif T = ")" and then Paren_Depth > 0 then
               Paren_Depth := Paren_Depth - 1;
            elsif T = ";" and then Paren_Depth = 0 then
               Editor.Ada_Token_Cursor.Tokenization.Advance (Position);
               exit;
            end if;
         end;
         Editor.Ada_Token_Cursor.Tokenization.Advance (Position);
      end loop;
   end Skip_Balanced_To_Semicolon;

   procedure Advance_Through_Keyword
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Keyword  : String) is
   begin
      while not Editor.Ada_Token_Cursor.Tokenization.At_End (Position) loop
         declare
            L : constant String := Current_Lower (Position);
         begin
            Editor.Ada_Token_Cursor.Tokenization.Advance (Position);
            exit when L = Lower (Keyword);
         end;
      end loop;
   end Advance_Through_Keyword;

   function Has_Token_Before_Semicolon
     (Position : Editor.Ada_Token_Cursor.Cursor;
      Text     : String) return Boolean is
      Probe       : Editor.Ada_Token_Cursor.Cursor := Position;
      Paren_Depth : Natural := 0;
      Wanted      : constant String := Lower (Text);
   begin
      while not Editor.Ada_Token_Cursor.Tokenization.At_End (Probe) loop
         declare
            T : constant String := To_String (Editor.Ada_Token_Cursor.Tokenization.Current (Probe).Text);
            L : constant String := Current_Lower (Probe);
         begin
            if L = Wanted or else T = Text then
               return True;
            elsif T = "(" then
               Paren_Depth := Paren_Depth + 1;
            elsif T = ")" and then Paren_Depth > 0 then
               Paren_Depth := Paren_Depth - 1;
            elsif T = ";" and then Paren_Depth = 0 then
               return False;
            end if;
            Editor.Ada_Token_Cursor.Tokenization.Advance (Probe);
         end;
      end loop;
      return False;
   end Has_Token_Before_Semicolon;

   function Has_Token_Between
     (Stream : Editor.Ada_Token_Cursor.Token_Stream;
      First  : Natural;
      Last   : Natural;
      Text   : String) return Boolean is
      Wanted : constant String := Lower (Text);
   begin
      if First = 0 or else Last = 0 or else First > Last then
         return False;
      end if;

      for Index in First .. Natural'Min (Last, Editor.Ada_Token_Cursor.Tokenization.Length (Stream)) loop
         declare
            Tok : constant Editor.Ada_Token_Cursor.Token_Info :=
              Editor.Ada_Token_Cursor.Tokenization.Token_At (Stream, Index);
            Raw : constant String := To_String (Tok.Text);
         begin
            if Lower (Raw) = Wanted or else Raw = Text then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Has_Token_Between;

   procedure Skip_Balanced_To
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Stop_1   : String;
      Stop_2   : String := "";
      Stop_3   : String := "") is
      Paren_Depth : Natural := 0;
   begin
      while not Editor.Ada_Token_Cursor.Tokenization.At_End (Position) loop
         declare
            T : constant String := To_String (Editor.Ada_Token_Cursor.Tokenization.Current (Position).Text);
            L : constant String := Current_Lower (Position);
         begin
            exit when Paren_Depth = 0
              and then (T = Stop_1 or else L = Lower (Stop_1)
                        or else (Stop_2'Length > 0 and then (T = Stop_2 or else L = Lower (Stop_2)))
                        or else (Stop_3'Length > 0 and then (T = Stop_3 or else L = Lower (Stop_3))));
            if T = "(" then
               Paren_Depth := Paren_Depth + 1;
            elsif T = ")" and then Paren_Depth > 0 then
               Paren_Depth := Paren_Depth - 1;
            end if;
            Editor.Ada_Token_Cursor.Tokenization.Advance (Position);
         end;
      end loop;
   end Skip_Balanced_To;

end Editor.Ada_Token_Cursor.Navigation_Helpers;
