with Ada.Assertions;
with Text_Buffer;
with Editor.Cursors; use Editor.Cursors;
with Editor.State;
with Ada.Containers; use Ada.Containers;
package body Editor.Invariants is

   procedure Check (S : Editor.State.State_Type) is
      L : constant Cursor_Index := Cursor_Index (Text_Buffer.Length (S.Buffer));
      C : Cursor_Index := 0;
   begin
      pragma Assert (S.Carets.Length = 1, "Exactly one caret required in Stage 1");

      if S.Carets.Length > 0 then
         C := S.Carets (S.Carets.First_Index);
      end if;

      pragma Assert (C >= 0, "Caret must be non-negative");
      pragma Assert (C <= L + 1, "Caret must be <= Length + 1");

      pragma Assert (S.Selection.Start_Pos >= 0, "Selection start must be non-negative");
      pragma Assert (S.Selection.Start_Pos <= L + 1, "Selection start out of bounds");

      pragma Assert (S.Selection.End_Pos >= 0, "Selection end must be non-negative");
      pragma Assert (S.Selection.End_Pos <= L + 1, "Selection end out of bounds");

      if not S.Selection.Active then
         pragma Assert (S.Selection.Start_Pos = C,
                        "Inactive selection start must equal caret");
         pragma Assert (S.Selection.End_Pos = C,
                        "Inactive selection end must equal caret");
      end if;
   end Check;

end Editor.Invariants;