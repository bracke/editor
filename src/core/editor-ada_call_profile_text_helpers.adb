package body Editor.Ada_Call_Profile_Text_Helpers is

   function Hash_Text (Text : String) return Natural is
      type Hash_Value is mod 2 ** 64;
      H : Hash_Value := 2166136261;
   begin
      for C of Text loop
         H := H * 16_777_619 + Hash_Value (Character'Pos (C) + 1);
      end loop;
      return Natural (H mod Hash_Value (Natural'Last));
   end Hash_Text;

   function Clean_Call_Name (Text : String) return String is
      T        : constant String := Trim (Text);
      Stop     : Natural := 0;
      First    : Natural := 0;
      Operator : Boolean := False;
   begin
      if T = "" then
         return "";
      end if;

      for I in T'Range loop
         if T (I) = '(' then
            Stop := I - 1;
            exit;
         end if;
      end loop;

      if Stop = 0 then
         Stop := T'Last;
      end if;

      while Stop >= T'First and then T (Stop) = ' ' loop
         Stop := Stop - 1;
         exit when Stop < T'First;
      end loop;

      if Stop < T'First then
         return "";
      end if;

      Operator := T (T'First) = '"';

      for I in reverse T'First .. Stop loop
         if Operator then
            if T (I) = '"' and then I /= Stop then
               First := I;
               exit;
            end if;
         elsif not Is_Name_Char (T (I)) then
            First := I + 1;
            exit;
         elsif I = T'First then
            First := T'First;
         end if;
      end loop;

      if First = 0 or else First > Stop then
         return "";
      end if;

      return Trim (T (First .. Stop));
   end Clean_Call_Name;

end Editor.Ada_Call_Profile_Text_Helpers;
