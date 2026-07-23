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
   function End_Target_Text (Code : String) return String is
      Clean : constant String := Strip_Terminator (Code);
      L     : constant String := Lower (Clean);

      function Drop_Prefix (Prefix : String) return String is
      begin
         if Clean'Length <= Prefix'Length then
            return "";
         end if;
         return Trim (Clean (Clean'First + Prefix'Length .. Clean'Last));
      end Drop_Prefix;

      Tail : Unbounded_String := Null_Unbounded_String;
   begin
      if not Starts_With_Word (L, "end") then
         return "";
      elsif Starts_With_Word (L, "end if") then
         Tail := To_Unbounded_String (Drop_Prefix ("end if"));
      elsif Starts_With_Word (L, "end case") then
         Tail := To_Unbounded_String (Drop_Prefix ("end case"));
      elsif Starts_With_Word (L, "end loop") then
         Tail := To_Unbounded_String (Drop_Prefix ("end loop"));
      elsif Starts_With_Word (L, "end select") then
         Tail := To_Unbounded_String (Drop_Prefix ("end select"));
      elsif Starts_With_Word (L, "end record") then
         Tail := To_Unbounded_String (Drop_Prefix ("end record"));
      elsif Starts_With_Word (L, "end task") then
         Tail := To_Unbounded_String (Drop_Prefix ("end task"));
      elsif Starts_With_Word (L, "end protected") then
         Tail := To_Unbounded_String (Drop_Prefix ("end protected"));
      elsif Starts_With_Word (L, "end package") then
         Tail := To_Unbounded_String (Drop_Prefix ("end package"));
      elsif Starts_With_Word (L, "end procedure") then
         Tail := To_Unbounded_String (Drop_Prefix ("end procedure"));
      elsif Starts_With_Word (L, "end function") then
         Tail := To_Unbounded_String (Drop_Prefix ("end function"));
      else
         Tail := To_Unbounded_String (Drop_Prefix ("end"));
      end if;

      declare
         Work : constant String := Trim (To_String (Tail));
      begin
         if Work = "" then
            return "";
         elsif Contains (Work, ";") then
            return Segment_Before (Work, ";");
         else
            return Work;
         end if;
      end;
   end End_Target_Text;
