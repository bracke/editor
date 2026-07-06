with Editor.Ada_Declaration_Parser.Lexical_Helpers;

package body Editor.Ada_Declaration_Parser.Representation_Static_Values is

   procedure Parse_Static_Natural
     (Text  : String;
      Valid : out Boolean;
      Value : out Natural)
   is
      T     : constant String :=
        Editor.Ada_Declaration_Parser.Lexical_Helpers.Trim (Text);
      Acc   : Natural := 0;
      Digit : Natural;
   begin
      Valid := T'Length > 0;
      Value := 0;
      if not Valid then
         return;
      end if;

      for C of T loop
         if C < '0' or else C > '9' then
            Valid := False;
            Value := 0;
            return;
         end if;

         Digit := Character'Pos (C) - Character'Pos ('0');
         if Acc > (Natural'Last - Digit) / 10 then
            Valid := False;
            Value := 0;
            return;
         end if;
         Acc := Acc * 10 + Digit;
      end loop;

      Value := Acc;
   end Parse_Static_Natural;

end Editor.Ada_Declaration_Parser.Representation_Static_Values;
