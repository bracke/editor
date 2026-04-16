with Editor.Cursors;
with Text_Buffer;
with Ada.Containers; use Ada.Containers;

package body Editor.State is

   use Editor.Cursors;

   ------------------------------------------------------------------------
   -- Init (canonical state)
   ------------------------------------------------------------------------
   procedure Init (S : out State_Type) is
   begin
      Text_Buffer.Clear (S.Buffer);

      S.Carets.Clear;
      S.Carets.Append (0);

      S.Anchor := 0;

      pragma Assert (not S.Carets.Is_Empty);
      pragma Assert (S.Carets (S.Carets.First_Index) = 0);
   end Init;

   ------------------------------------------------------------------------
   -- Normalize_Carets
   ------------------------------------------------------------------------
 procedure Normalize_Carets (S : in out State_Type) is
   Result : Cursors_Vector.Vector;
   Len    : constant Natural :=
     Natural (Text_Buffer.Length (S.Buffer));
begin

   -- copy + clamp
   for C of S.Carets loop
      if C > Cursor_Index (Len) then
         Result.Append (Cursor_Index (Len));
      else
         Result.Append (C);
      end if;
   end loop;

   -- ensure at least one caret
   if Result.Length = 0 then
      Result.Append (0);
   end if;

   -- simple stable sort
   declare
      Tmp : Cursor_Index;
   begin
      for I in Result.First_Index .. Result.Last_Index loop
         for J in I + 1 .. Result.Last_Index loop
            if Result (J) < Result (I) then
               Tmp := Result (I);
               Result.Replace_Element (I, Result (J));
               Result.Replace_Element (J, Tmp);
            end if;
         end loop;
      end loop;
   end;

   S.Carets := Result;

end Normalize_Carets;

end Editor.State;