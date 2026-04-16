with Ada.Containers; use Ada.Containers;
with Editor.Commands; use Editor.Commands;
with Ada.Text_IO; use Ada.Text_IO;
package body Editor.State.Caret_Rules is

function Transform_Carets
  (Carets : Cursors_Vector.Vector;
   Cmd    : Editor.Commands.Command;
   Len    : Natural)
   return Cursors_Vector.Vector
is
begin
   case Cmd.Kind is

      when Editor.Commands.Insert_Char =>
         declare
            Result : Cursors_Vector.Vector := Carets;
         begin
            for I in Result.First_Index .. Result.Last_Index loop
               if Result (I) >= Cmd.Pos then
                  Result.Replace_Element (I, Result (I) + 1);
               end if;
            end loop;
Put_Line ("RETURNING SIZE = " &
          Natural'Image (Natural (Result.Length)));
            return Result;
         end;

      when Editor.Commands.Delete_Char =>
         declare
            Result : Cursors_Vector.Vector := Carets;
         begin
            for I in Result.First_Index .. Result.Last_Index loop
               if Result (I) > Cmd.Pos then
                  Result.Replace_Element (I, Result (I) - 1);
               end if;
            end loop;

            return Result;
         end;

   end case;
end Transform_Carets;

end Editor.State.Caret_Rules;