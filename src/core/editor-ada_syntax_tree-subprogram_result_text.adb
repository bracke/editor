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
   function Subprogram_Result_Text (Code : String) return String is
      Clean : constant String := Strip_Terminator (Code);
      L     : constant String := Lower (Clean);
      Tail  : Unbounded_String := Null_Unbounded_String;
   begin
      if not Starts_With_Word (L, "function") or else not Contains (L, " return ") then
         return "";
      end if;

      Tail := To_Unbounded_String (Segment_After (Clean, "return"));
      declare
         Work : constant String := To_String (Tail);
      begin
         if Contains (Lower (Work), " is ") then
            return Trim (Segment_Before (Work, " is "));
         elsif Contains (Work, " with ") then
            return Trim (Segment_Before (Work, " with "));
         elsif Contains (Work, ";") then
            return Trim (Segment_Before (Work, ";"));
         else
            return Trim (Work);
         end if;
      end;
   end Subprogram_Result_Text;
