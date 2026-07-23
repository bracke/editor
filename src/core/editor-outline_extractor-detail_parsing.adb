with Ada.Characters.Latin_1;
with Ada.Strings;
with Ada.Strings.Fixed;
with Editor.Outline_Extractor.Line_Analysis;

package body Editor.Outline_Extractor.Detail_Parsing is

   function Numeric_Suffix (Text : String; Start : Positive) return Natural
   is
      Value : Natural := 0;
      I     : Natural := Start;
   begin
      while I <= Text'Last
        and then Text (I) >= '0'
        and then Text (I) <= '9'
      loop
         Value := Value * 10 + Character'Pos (Text (I)) - Character'Pos ('0');
         I := I + 1;
      end loop;
      return Value;
   end Numeric_Suffix;

   function Detail_Start_Line (Detail : String) return Natural
   is
   begin
      if Editor.Outline_Extractor.Line_Analysis.Starts_With (Detail, "line ") then
         return Numeric_Suffix (Detail, Detail'First + 5);
      elsif Editor.Outline_Extractor.Line_Analysis.Starts_With (Detail, "lines ") then
         return Numeric_Suffix (Detail, Detail'First + 6);
      else
         return 0;
      end if;
   end Detail_Start_Line;

   function Detail_End_Line (Detail : String) return Natural
   is
      Start_Line : constant Natural := Detail_Start_Line (Detail);
      Dash       : Natural := 0;
   begin
      if not Editor.Outline_Extractor.Line_Analysis.Starts_With (Detail, "lines ") then
         return Start_Line;
      end if;

      for I in Detail'Range loop
         if Detail (I) = '-' then
            Dash := I;
            exit;
         end if;
      end loop;

      if Dash = 0 or else Dash >= Detail'Last then
         return Start_Line;
      end if;

      return Numeric_Suffix (Detail, Dash + 1);
   end Detail_End_Line;

   function End_Line_Detail
     (Start_Line : Natural;
      End_Line   : Natural;
      Form       : String) return String
   is
      Start_Text : constant String := Ada.Strings.Fixed.Trim
        (Natural'Image (Start_Line), Ada.Strings.Both);
      End_Text   : constant String := Ada.Strings.Fixed.Trim
        (Natural'Image (End_Line), Ada.Strings.Both);
      Prefix : constant String :=
        (if End_Line > Start_Line
         then "lines " & Start_Text & "-" & End_Text
         else "line " & Start_Text);
   begin
      if Form'Length = 0 then
         return Prefix;
      else
         return Prefix & " " & Form;
      end if;
   end End_Line_Detail;

   function Detail_Form (Detail : String) return String
   is
      I : Natural := Detail'First;
   begin
      if Editor.Outline_Extractor.Line_Analysis.Starts_With (Detail, "line ") then
         I := Detail'First + 5;
      elsif Editor.Outline_Extractor.Line_Analysis.Starts_With (Detail, "lines ") then
         I := Detail'First + 6;
      else
         return "";
      end if;

      while I <= Detail'Last
        and then ((Detail (I) >= '0' and then Detail (I) <= '9')
                  or else Detail (I) = '-')
      loop
         I := I + 1;
      end loop;

      while I <= Detail'Last
        and then (Detail (I) = ' ' or else Detail (I) = Ada.Characters.Latin_1.HT)
      loop
         I := I + 1;
      end loop;

      if I <= Detail'Last then
         return Detail (I .. Detail'Last);
      else
         return "";
      end if;
   end Detail_Form;

   function Primary_Detail_Form (Detail : String) return String
   is
      Form : constant String := Detail_Form (Detail);
   begin
      for I in Form'Range loop
         if Form (I) = ' ' or else Form (I) = Ada.Characters.Latin_1.HT then
            if I = Form'First then
               return "";
            else
               return Form (Form'First .. I - 1);
            end if;
         end if;
      end loop;

      return Form;
   end Primary_Detail_Form;

end Editor.Outline_Extractor.Detail_Parsing;
