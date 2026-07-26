with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Token_Cursor.Tokenization;
with Editor.Text_Helpers;

package body Editor.Ada_Token_Cursor.Grammar_Helpers is

   function Lower (S : String) return String
     renames Editor.Text_Helpers.Lower;

   function Match_Keyword
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Keyword  : String) return Boolean
   is
   begin
      if not Editor.Ada_Token_Cursor.Tokenization.At_End (Position)
        and then To_String (Editor.Ada_Token_Cursor.Tokenization.Current (Position).Lower) = Lower (Keyword)
        and then Editor.Ada_Token_Cursor.Tokenization.Current (Position).Kind = Editor.Ada_Token_Cursor.Token_Keyword
      then
         Editor.Ada_Token_Cursor.Tokenization.Advance (Position);
         return True;
      end if;
      return False;
   end Match_Keyword;

   function Match_Symbol
     (Position : in out Editor.Ada_Token_Cursor.Cursor;
      Symbol   : String) return Boolean
   is
   begin
      if not Editor.Ada_Token_Cursor.Tokenization.At_End (Position)
        and then To_String (Editor.Ada_Token_Cursor.Tokenization.Current (Position).Text) = Symbol
      then
         Editor.Ada_Token_Cursor.Tokenization.Advance (Position);
         return True;
      end if;
      return False;
   end Match_Symbol;

   procedure Add_Production
     (Result : in out Editor.Ada_Token_Cursor.Grammar_Result;
      Kind   : Editor.Ada_Token_Cursor.Production_Kind;
      Tok    : Editor.Ada_Token_Cursor.Token_Info;
      Label  : String)
   is
      Info : Editor.Ada_Token_Cursor.Production_Info;
   begin
      Info.Kind := Kind;
      Info.Line := Tok.Line;
      Info.Column := Tok.Column;
      Info.Label := To_Unbounded_String (Label);
      Result.Productions.Append (Info);
   end Add_Production;

end Editor.Ada_Token_Cursor.Grammar_Helpers;
