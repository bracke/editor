with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Editor.Dirty_Lines is

   procedure Split_Lines
     (Text  : String;
      Lines : in out Line_Vectors.Vector)
   is
      Current : Unbounded_String := Null_Unbounded_String;
   begin
      Lines.Clear;

      for Ch of Text loop
         if Ch = ASCII.LF then
            Lines.Append (Current);
            Current := Null_Unbounded_String;
         else
            Append (Current, Ch);
         end if;
      end loop;

      --  The editor row model exposes at least one logical line.  A final LF
      --  therefore creates a final empty logical row, matching Text_Buffer's
      --  visible-line behavior for editor rendering.
      Lines.Append (Current);
   end Split_Lines;

   procedure Clear
     (State : in out Dirty_Line_State)
   is
   begin
      State.Has_Saved_Baseline := False;
      State.Baseline_Lines.Clear;
      State.Kinds.Clear;
      State.Dirty_Count := 0;
   end Clear;

   procedure Set_Baseline_Text
     (State : in out Dirty_Line_State;
      Text  : String)
   is
   begin
      Split_Lines (Text, State.Baseline_Lines);
      State.Kinds.Clear;
      State.Dirty_Count := 0;
      State.Has_Saved_Baseline := True;
   end Set_Baseline_Text;

   function Has_Baseline
     (State : Dirty_Line_State) return Boolean
   is
   begin
      return State.Has_Saved_Baseline;
   end Has_Baseline;

   function Baseline_Line_Count
     (State : Dirty_Line_State) return Natural
   is
   begin
      return Natural (State.Baseline_Lines.Length);
   end Baseline_Line_Count;

   function Dirty_Line_Count
     (State : Dirty_Line_State) return Natural
   is
   begin
      return State.Dirty_Count;
   end Dirty_Line_Count;

   function Kind_For_Row
     (State : Dirty_Line_State;
      Row   : Natural) return Dirty_Line_Kind
   is
   begin
      if State.Kinds.Is_Empty then
         return Clean_Line;
      end if;

      if Row < State.Kinds.First_Index or else Row > State.Kinds.Last_Index then
         return Clean_Line;
      end if;

      return State.Kinds.Element (Row);
   end Kind_For_Row;

   function Is_Dirty_Row
     (State : Dirty_Line_State;
      Row   : Natural) return Boolean
   is
   begin
      return Kind_For_Row (State, Row) /= Clean_Line;
   end Is_Dirty_Row;

   procedure Recompute
     (State        : in out Dirty_Line_State;
      Current_Text : String)
   is
      Current_Lines : Line_Vectors.Vector;
      Current_Count : Natural;
      Base_Count    : Natural;
      Kind          : Dirty_Line_Kind := Clean_Line;
   begin
      if not State.Has_Saved_Baseline then
         Set_Baseline_Text (State, "");
      end if;

      Split_Lines (Current_Text, Current_Lines);
      Current_Count := Natural (Current_Lines.Length);
      Base_Count := Natural (State.Baseline_Lines.Length);

      State.Kinds.Clear;
      State.Dirty_Count := 0;

      if Current_Count = 0 then
         return;
      end if;

      for Row in 0 .. Current_Count - 1 loop
         if Row >= Base_Count then
            Kind := Added_Line;
         elsif Current_Lines.Element (Row) /= State.Baseline_Lines.Element (Row) then
            Kind := Modified_Line;
         else
            Kind := Clean_Line;
         end if;

         State.Kinds.Append (Kind);
         if Kind /= Clean_Line then
            State.Dirty_Count := State.Dirty_Count + 1;
         end if;
      end loop;
   end Recompute;

   procedure Clear_Dirty_State_To_Current
     (State        : in out Dirty_Line_State;
      Current_Text : String)
   is
   begin
      Set_Baseline_Text (State, Current_Text);
   end Clear_Dirty_State_To_Current;

end Editor.Dirty_Lines;
