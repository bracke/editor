with Editor.Text_Helpers;

package body Editor.Ada_Declaration_Parser.Same_Line_Segment_Helpers is

   use Editor.Text_Helpers;

   function Strip_Override_Prefix (Segment : String) return String is
      S : constant String := Trim (Segment);
      L : constant String := Lower (S);
   begin
      if Starts_With (L, "not overriding ") then
         return Trim (S (S'First + 15 .. S'Last));
      elsif Starts_With (L, "overriding ") then
         return Trim (S (S'First + 11 .. S'Last));
      end if;

      return S;
   end Strip_Override_Prefix;

   function Strip_Callable_Prefix (Segment : String) return String is
      S : constant String := Strip_Override_Prefix (Segment);
      L : constant String := Lower (S);
   begin
      if Starts_With_Word (L, "with") then
         return Trim (S (S'First + 4 .. S'Last));
      end if;

      return S;
   end Strip_Callable_Prefix;

end Editor.Ada_Declaration_Parser.Same_Line_Segment_Helpers;
