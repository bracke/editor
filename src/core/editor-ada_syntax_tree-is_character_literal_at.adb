with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Syntax_Core;
with Editor.Ada_Syntax_Tree.Builder;
with Editor.Ada_Syntax_Tree.Detail_Nodes;
with Editor.Ada_Syntax_Tree.Line_Classifier;
with Editor.Ada_Syntax_Tree.Statement_Details;
with Editor.Ada_Token_Cursor;
with Editor.Text_Helpers;

separate (Editor.Ada_Syntax_Tree)
   function Is_Character_Literal_At
     (Text : String; Pos : Natural; Last : Natural) return Boolean
   is
   begin
      return Pos + 2 <= Last
        and then Text (Pos) = Character'Val (39)
        and then Text (Pos + 2) = Character'Val (39);
   end Is_Character_Literal_At;
