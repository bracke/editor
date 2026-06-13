with Ada.Containers; use Ada.Containers;
with Editor.Commands; use Editor.Commands;
with Editor.Cursors;  use Editor.Cursors;
with Text_Buffer;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.State.Caret_Rules is

   function Transform_Carets
     (Carets : Cursors_Vector.Vector;
      Cmd    : Editor.Commands.Command;
      Len    : Natural)
      return Cursors_Vector.Vector
   is
      pragma Unreferenced (Len);
   begin
      case Cmd.Kind is

         when Editor.Commands.Insert_Text_Input =>
            declare
               Result : Cursors_Vector.Vector := Carets;
               C      : Caret_State;
               Step_Delta  : constant Natural :=
                 Text_Buffer.UTF8_Code_Point_Count (To_String (Cmd.Text));
            begin
               for I in Result.First_Index .. Result.Last_Index loop
                  C := Result (I);

                  if C.Pos >= Cmd.Pos then
                     C.Pos := C.Pos + Cursor_Index (Step_Delta);
                  end if;

                  if C.Anchor >= Cmd.Pos then
                     C.Anchor := C.Anchor + Cursor_Index (Step_Delta);
                  end if;

                  Result.Replace_Element (I, C);
               end loop;

               return Result;
            end;

         when Editor.Commands.Delete_Char =>
            declare
               Result : Cursors_Vector.Vector := Carets;
               C      : Caret_State;
            begin
               for I in Result.First_Index .. Result.Last_Index loop
                  C := Result (I);

                  if C.Pos > Cmd.Pos then
                     C.Pos := C.Pos - 1;
                  end if;

                  if C.Anchor > Cmd.Pos then
                     C.Anchor := C.Anchor - 1;
                  end if;

                  Result.Replace_Element (I, C);
               end loop;

               return Result;
            end;

         when others =>
            return Carets;
      end case;
   end Transform_Carets;

end Editor.State.Caret_Rules;