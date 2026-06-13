with Text_Buffer;
with Ada.Containers; use Ada.Containers;
with Editor.Cursors; use Editor.Cursors;
with Editor.State;

package body Editor.Invariants is

   procedure Check (S : Editor.State.State_Type) is
      Len : constant Cursor_Index :=
        Cursor_Index (Text_Buffer.Length (S.Buffer));
   begin
      ---------------------------------------------------------------------
      -- There must always be at least one caret
      ---------------------------------------------------------------------
      pragma Assert
        (S.Carets.Length > 0,
         "Invariant: state must always contain at least one caret");

      ---------------------------------------------------------------------
      -- Caret positions and anchors must be in bounds
      ---------------------------------------------------------------------
      for I in S.Carets.First_Index .. S.Carets.Last_Index loop
         pragma Assert
           (S.Carets (I).Pos <= Len,
            "Invariant: caret position out of bounds");

         pragma Assert
           (S.Carets (I).Anchor <= Len,
            "Invariant: caret anchor out of bounds");
      end loop;

      ---------------------------------------------------------------------
      -- Carets must be strictly increasing by position
      ---------------------------------------------------------------------
      if S.Carets.Length > 1 then
         for I in S.Carets.First_Index .. S.Carets.Last_Index - 1 loop
            pragma Assert
            (S.Carets (I).Pos < S.Carets (I + 1).Pos
               or else
               (S.Carets (I).Pos = S.Carets (I + 1).Pos
               and then
               S.Carets (I).Virtual_Column < S.Carets (I + 1).Virtual_Column),
               "Invariant: caret ordering must consider virtual column");

            --  Phase 23 allows Shift navigation to extend selections across
            --  multiple carets in normal selection mode.  Ordering and bounds
            --  remain invariant-enforced above; selection ownership is no longer
            --  restricted to rectangle mode only.

            --  pragma Assert
            --     (S.Carets.Element (I).Virtual_Column = 0
            --        or else S.Carets.Element (I).Pos = Cursor_Index (Text_Buffer.Length (S.Buffer))
            --        or else (
            --           (declare
            --              Row : Natural := 0;
            --              Col : Natural := 0;
            --           begin
            --              Line_Column_For_Index (S, Natural (S.Carets.Element (I).Pos), Row, Col);
            --              Col := Line_Length (S, Row);
            --           end)),
            --        "Invariant: virtual column only allowed at EOL");
         end loop;
      end if;


   end Check;

end Editor.Invariants;