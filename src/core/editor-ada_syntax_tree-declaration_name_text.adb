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
   function Declaration_Name_Text (Code : String; Lead_Word : String := "") return String is
      Clean : constant String := Strip_Terminator (Code);
      L     : constant String := Lower (Clean);

      function Drop_First (Count : Natural) return String is
      begin
         if Count >= Clean'Length then
            return "";
         end if;
         return Trim (Clean (Clean'First + Count .. Clean'Last));
      end Drop_First;

      Tail : Unbounded_String := To_Unbounded_String (Clean);
   begin
      if Lead_Word /= "" and then Starts_With_Word (L, Lead_Word) then
         Tail := To_Unbounded_String (Drop_First (Lead_Word'Length));
      elsif Starts_With_Word (L, "task type") then
         Tail := To_Unbounded_String (Drop_First (9));
      elsif Starts_With_Word (L, "task body") then
         Tail := To_Unbounded_String (Drop_First (9));
      elsif Starts_With_Word (L, "task") then
         Tail := To_Unbounded_String (Drop_First (4));
      elsif Starts_With_Word (L, "protected type") then
         Tail := To_Unbounded_String (Drop_First (14));
      elsif Starts_With_Word (L, "protected body") then
         Tail := To_Unbounded_String (Drop_First (14));
      elsif Starts_With_Word (L, "protected") then
         Tail := To_Unbounded_String (Drop_First (9));
      elsif Starts_With_Word (L, "entry") then
         Tail := To_Unbounded_String (Drop_First (5));
      end if;

      declare
         Work : constant String := To_String (Tail);
      begin
         if Contains (Work, ":") then
            return Segment_Before (Work, ":");
         elsif Contains (Work, " is ") then
            return Segment_Before (Work, " is ");
         elsif Contains (Work, " renames ") then
            return Segment_Before (Work, " renames ");
         elsif Contains (Work, "(") then
            return Segment_Before (Work, "(");
         elsif Contains (Work, ";") then
            return Segment_Before (Work, ";");
         else
            return Trim (Work);
         end if;
      end;
   end Declaration_Name_Text;
