with Editor.Ada_Declaration_Parser.Lexical_Helpers;
with Editor.Ada_Declaration_Parser.Name_Profile_Helpers;
with Editor.Ada_Syntax_Core;

package body Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors is

   use Editor.Ada_Declaration_Parser.Lexical_Helpers;
   use Editor.Ada_Declaration_Parser.Name_Profile_Helpers;

   function Has_Code_Char (Line : String; C : Character) return Boolean is
      Code : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Line);
   begin
      for X of Code loop
         if X = C then
            return True;
         end if;
      end loop;
      return False;
   end Has_Code_Char;

   function Profile_Still_Open
     (Raw_Line      : String;
      Declared_Name : String) return Boolean
   is
      Code     : constant String := Editor.Ada_Syntax_Core.Sanitize_Line (Raw_Line);
      Name_Pos : constant Natural := Declaration_Name_Position (Raw_Line, Declared_Name);
      Open     : Natural := 0;
      Nesting  : Natural := 0;
   begin
      if Declared_Name'Length = 0 then
         return False;
      end if;

      if Name_Pos = 0 then
         return not Has_Code_Char (Raw_Line, ';')
           and then not Has_Token (Lower (Code), "is");
      end if;

      for I in Name_Pos + Declared_Name'Length .. Code'Last loop
         if Code (I) = '(' then
            Open := I;
            exit;
         elsif Code (I) = ';' or else Has_Token (Code (I .. Code'Last), "is") then
            return False;
         end if;
      end loop;

      if Open = 0 then
         return not Has_Code_Char (Raw_Line, ';')
           and then not Has_Token (Lower (Code), "is");
      end if;

      for I in Open + 1 .. Code'Last loop
         if Code (I) = '(' then
            Nesting := Nesting + 1;
         elsif Code (I) = ')' then
            if Nesting = 0 then
               return False;
            end if;
            Nesting := Nesting - 1;
         end if;
      end loop;

      return True;
   end Profile_Still_Open;

end Editor.Ada_Declaration_Parser.Profile_Parameter_Collectors;
