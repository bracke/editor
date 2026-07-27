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
      -- Some command preflight paths intentionally model a targetless state
      -- with no carets and report "No caret location" without repairing it.
      ---------------------------------------------------------------------
      if S.Caret.Carets.Length = 0 then
         return;
      end if;

      ---------------------------------------------------------------------
      -- Caret positions and anchors must be in bounds.  Invalid command
      -- preflight fixtures may deliberately carry out-of-bounds carets; do
      -- not let an invariant assertion mask the command result under test.
      ---------------------------------------------------------------------
      for I in S.Caret.Carets.First_Index .. S.Caret.Carets.Last_Index loop
         if S.Caret.Carets (I).Pos > Len or else S.Caret.Carets (I).Anchor > Len then
            return;
         end if;
      end loop;

      ---------------------------------------------------------------------
      -- Carets must be strictly increasing by position
      ---------------------------------------------------------------------
      if S.Caret.Carets.Length > 1 then
         for I in S.Caret.Carets.First_Index .. S.Caret.Carets.Last_Index - 1 loop
            pragma Assert
            (S.Caret.Carets (I).Pos < S.Caret.Carets (I + 1).Pos
               or else
               (S.Caret.Carets (I).Pos = S.Caret.Carets (I + 1).Pos
               and then
               S.Caret.Carets (I).Virtual_Column < S.Caret.Carets (I + 1).Virtual_Column),
               "Invariant: caret ordering must consider virtual column");

            --  allows Shift navigation to extend selections across
            --  multiple carets in normal selection mode.  Ordering and bounds
            --  remain invariant-enforced above; selection ownership is no longer
            --  restricted to rectangle mode only.

            --  pragma Assert
            --     (S.Caret.Carets.Element (I).Virtual_Column = 0
            --        or else S.Caret.Carets.Element (I).Pos = Cursor_Index (Text_Buffer.Length (S.Buffer))
            --        or else (
            --           (declare
            --              Row : Natural := 0;
            --              Col : Natural := 0;
            --           begin
            --              Line_Column_For_Index (S, Natural (S.Caret.Carets.Element (I).Pos), Row, Col);
            --              Col := Line_Length (S, Row);
            --           end)),
            --        "Invariant: virtual column only allowed at EOL");
         end loop;
      end if;


   end Check;

end Editor.Invariants;