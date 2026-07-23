with Ada.Characters.Handling;

package body Editor.Path_Helpers is

   function Is_Separator (Ch : Character) return Boolean is
   begin
      return Ch = '/' or else Ch = '\';
   end Is_Separator;

   function Strip_Trailing_Separators (Path : String) return String is
      Last : Integer := Path'Last;
   begin
      if Path'Length = 0 then
         return Path;
      end if;

      while Last > Path'First and then Is_Separator (Path (Last)) loop
         Last := Last - 1;
      end loop;

      return Path (Path'First .. Last);
   end Strip_Trailing_Separators;

   function Normalize_For_Compare
     (Path : String;
      Strip_Trailing : Boolean := False;
      Lowercase      : Boolean := False) return String
   is
      Source : constant String :=
        (if Strip_Trailing then Strip_Trailing_Separators (Path) else Path);
      Result : String (Source'Range);
   begin
      for I in Source'Range loop
         if Source (I) = '\' then
            Result (I) := '/';
         elsif Lowercase then
            Result (I) := Ada.Characters.Handling.To_Lower (Source (I));
         else
            Result (I) := Source (I);
         end if;
      end loop;
      return Result;
   end Normalize_For_Compare;

   function Path_Depth (Path : String) return Natural is
      Count : Natural := 0;
   begin
      for Ch of Path loop
         if Ch = '/' or else Ch = '\' then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Path_Depth;

end Editor.Path_Helpers;
