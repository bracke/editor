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
   function Subprogram_Name_Text (Code : String) return String is
      Clean : constant String := Strip_Terminator (Code);
      L     : constant String := Lower (Clean);
      Work  : Unbounded_String := To_Unbounded_String (Clean);
   begin
      if Starts_With_Word (L, "function") and then Clean'Length > 8 then
         Work := To_Unbounded_String (Trim (Clean (Clean'First + 8 .. Clean'Last)));
      elsif Starts_With_Word (L, "procedure") and then Clean'Length > 9 then
         Work := To_Unbounded_String (Trim (Clean (Clean'First + 9 .. Clean'Last)));
      end if;

      declare
         Tail : constant String := To_String (Work);
      begin
         if Contains (Tail, "(") then
            return Segment_Before (Tail, "(");
         elsif Contains (Lower (Tail), " return ") then
            return Segment_Before (Tail, " return ");
         elsif Contains (Lower (Tail), " is ") then
            return Segment_Before (Tail, " is ");
         elsif Contains (Tail, ";") then
            return Segment_Before (Tail, ";");
         else
            return Trim (Tail);
         end if;
      end;
   end Subprogram_Name_Text;
