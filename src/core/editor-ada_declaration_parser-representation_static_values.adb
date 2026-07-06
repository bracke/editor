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

   function Natural_In_Integer_Range
     (Value    : Natural;
      Has_Low  : Boolean;
      Low      : Integer;
      Has_High : Boolean;
      High     : Integer) return Boolean
   is
      Int_Value : constant Integer := Integer (Value);
   begin
      if Has_Low and then Int_Value < Low then
         return False;
      elsif Has_High and then Int_Value > High then
         return False;
      else
         return True;
      end if;
   exception
      when Constraint_Error =>
         return False;
   end Natural_In_Integer_Range;

end Editor.Ada_Declaration_Parser.Representation_Static_Values;
