with Editor.State;
with Editor.Commands;
with Editor.Cursors;    use Editor.Cursors;
with Editor.Navigation; use Editor.Navigation;
with Ada.Containers;    use Ada.Containers;

package body Editor.Executor.Structural is

   function Primary_Caret_Index
     (S : Editor.State.State_Type) return Cursors_Vector.Extended_Index is
   begin
      return S.Carets.First_Index;
   end Primary_Caret_Index;

   procedure Keep_Only_Primary_Caret
     (S : in out Editor.State.State_Type) is
      Primary : Caret_State := (others => <>);
   begin
      if S.Carets.Length > 0 then
         Primary := S.Carets (Primary_Caret_Index (S));
      end if;

      S.Carets.Clear;
      S.Carets.Append (Primary);
   end Keep_Only_Primary_Caret;

   procedure Add_Caret_At_Point
     (S : in out Editor.State.State_Type;
      X : Natural;
      Y : Natural)
   is
      Pos : constant Cursor_Index := Index_For_Point (S, X, Y);
   begin
      S.Carets.Append (Caret_State'(
         Pos => Pos,
         Anchor => Pos,
         Virtual_Column => 0,
         Anchor_Virtual_Column => 0
      ));
      Editor.State.Normalize_Carets (S);
   end Add_Caret_At_Point;

   procedure Execute
     (S   : in out Editor.State.State_Type;
      Cmd : Editor.Commands.Command) is
   begin
      case Cmd.Kind is
         when Editor.Commands.Add_Caret_At_Point =>
            Add_Caret_At_Point (S, Cmd.Click_X, Cmd.Click_Y);

         when Editor.Commands.Clear_Extra_Carets =>
            Keep_Only_Primary_Caret (S);

         when others =>
            null;
      end case;
   end Execute;

end Editor.Executor.Structural;