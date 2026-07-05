with Ada.Characters.Latin_1;
with Ada.Strings.Fixed;
with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Syntax_Core;

package body Editor.Ada_Declaration_Parser.Metadata_Helpers is

   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Language_Model;

   function Has_Access_Subprogram_Metadata (Line : String) return Boolean is
      L : constant String := Lower (Line);
   begin
      return Ada.Strings.Fixed.Index (L, " access procedure") /= 0
        or else Ada.Strings.Fixed.Index (L, " access function") /= 0
        or else Ada.Strings.Fixed.Index (L, " access protected procedure") /= 0
        or else Ada.Strings.Fixed.Index (L, " access protected function") /= 0
        or else Starts_With_Word (Trim (L), "procedure")
        or else Starts_With_Word (Trim (L), "function")
        or else Starts_With_Word (Trim (L), "protected procedure")
        or else Starts_With_Word (Trim (L), "protected function");
   end Has_Access_Subprogram_Metadata;

   function Has_Entry_Family_Metadata (Line : String) return Boolean is
      Code       : constant String := Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Line));
      Entry_Pos  : Natural := Ada.Strings.Fixed.Index (Code, "entry");
      Open_Pos   : Natural := 0;
      Close_Pos  : Natural := 0;
      Nesting    : Natural := 0;
   begin
      --  Ada entry families have an index subtype/discrete subtype part
      --  before the parameter profile.  Retain only bounded shape metadata on
      --  the entry declaration; the family index choices are not declarations.
      if Entry_Pos = 0
        or else not Starts_With_Word (Trim (Code), "entry")
      then
         return False;
      end if;

      Open_Pos := Ada.Strings.Fixed.Index (Code, "(", Entry_Pos + 5);
      if Open_Pos = 0 then
         return False;
      end if;

      for I in Open_Pos .. Code'Last loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting = 1 then
               Close_Pos := I;
               exit;
            elsif Nesting > 0 then
               Nesting := Nesting - 1;
            end if;
         end if;
      end loop;

      if Close_Pos = 0 or else Close_Pos <= Open_Pos + 1 then
         return False;
      end if;

      declare
         Family_Index : constant String := Code (Open_Pos + 1 .. Close_Pos - 1);
         After_Group  : constant String :=
           (if Close_Pos < Code'Last then Code (Close_Pos + 1 .. Code'Last) else "");
      begin
         return Ada.Strings.Fixed.Index (Family_Index, ":") = 0
           and then (Ada.Strings.Fixed.Index (After_Group, "(") /= 0
                     or else Has_Token (Family_Index, "range")
                     or else Ada.Strings.Fixed.Index (Family_Index, "<>") /= 0);
      end;
   end Has_Entry_Family_Metadata;

   function Has_Class_Wide_Metadata (Line : String) return Boolean is
      Code : constant String := Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Line));
   begin
      return Ada.Strings.Fixed.Index (Code, "'class") /= 0
        or else Ada.Strings.Fixed.Index (Code, " class") /= 0;
   end Has_Class_Wide_Metadata;

   function Generic_Formal_Type_Family_From_Line
     (Line : String) return Generic_Formal_Type_Family
   is
      Code : constant String := Lower (Editor.Ada_Syntax_Core.Sanitize_Line (Line));
   begin
      if Has_Token (Code, "new") and then not Has_Token (Code, "access") then
         return Generic_Formal_Type_Derived;
      elsif Has_Token (Code, "array") then
         return Generic_Formal_Type_Array;
      elsif Has_Token (Code, "access")
        and then Has_Access_Subprogram_Metadata (Line)
      then
         return Generic_Formal_Type_Access_Subprogram;
      elsif Has_Token (Code, "access") then
         return Generic_Formal_Type_Access_Object;
      elsif Has_Token (Code, "interface") then
         return Generic_Formal_Type_Interface;
      elsif Has_Token (Code, "mod") then
         return Generic_Formal_Type_Modular_Integer;
      elsif Has_Token (Code, "digits")
        and then not Has_Token (Code, "delta")
      then
         return Generic_Formal_Type_Floating_Point;
      elsif Has_Token (Code, "delta")
        and then Has_Token (Code, "digits")
      then
         return Generic_Formal_Type_Decimal_Fixed_Point;
      elsif Has_Token (Code, "delta") then
         return Generic_Formal_Type_Ordinary_Fixed_Point;
      elsif Has_Token (Code, "range") then
         return Generic_Formal_Type_Signed_Integer;
      elsif Ada.Strings.Fixed.Index (Code, "(<>)") /= 0
        or else Ada.Strings.Fixed.Index (Code, "( <> )") /= 0
        or else Ada.Strings.Fixed.Index (Code, "(< >)") /= 0
      then
         return Generic_Formal_Type_Discrete;
      elsif Has_Token (Code, "private") then
         return Generic_Formal_Type_Private;
      else
         return Generic_Formal_Type_Unknown;
      end if;
   end Generic_Formal_Type_Family_From_Line;

   function First_Non_Blank_Column (Line : String) return Positive is
   begin
      for I in Line'Range loop
         if Line (I) /= ' ' and then Line (I) /= Ada.Characters.Latin_1.HT then
            return Positive (I - Line'First + 1);
         end if;
      end loop;
      return 1;
   end First_Non_Blank_Column;

end Editor.Ada_Declaration_Parser.Metadata_Helpers;
