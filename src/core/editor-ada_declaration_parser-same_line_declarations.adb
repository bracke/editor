with Ada.Strings.Fixed;
with Ada.Strings.Maps.Constants;
with Ada.Strings; use Ada.Strings;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Syntax_Core;

package body Editor.Ada_Declaration_Parser.Same_Line_Declarations is

   use Editor.Ada_Declaration_Parser.Lexical_Helpers;

   function Lower (S : String) return String is
   begin
      return Ada.Strings.Fixed.Translate
        (S, Ada.Strings.Maps.Constants.Lower_Case_Map);
   end Lower;

   function Has_Same_Line_Subtype_Group
     (Raw_Line   : String;
      Decl_Lower : String) return Boolean
   is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
   begin
      if not Starts_With_Word (Decl_Lower, "subtype")
        or else Code'Length <= 8
      then
         return False;
      end if;

      for I in Code'First .. Code'Last - 8 loop
         if Code (I) = ';'
           and then Starts_With_Word (Lower (Trim (Code (I + 1 .. Code'Last))), "subtype")
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Same_Line_Subtype_Group;

   function Has_Same_Line_Type_Group
     (Raw_Line   : String;
      Decl_Lower : String) return Boolean
   is
      Code    : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Nesting : Natural := 0;
   begin
      if not Starts_With_Word (Decl_Lower, "type")
        or else Code'Length <= 5
      then
         return False;
      end if;

      for I in Code'First .. Code'Last - 5 loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         elsif Code (I) = ';'
           and then Nesting = 0
           and then Starts_With_Word (Lower (Trim (Code (I + 1 .. Code'Last))), "type")
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Same_Line_Type_Group;

end Editor.Ada_Declaration_Parser.Same_Line_Declarations;
