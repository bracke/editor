package body Editor.Folding is

   procedure Clear (State : in out Folding_State) is
   begin
      State.Ranges.Clear;
   end Clear;

   procedure Add_Fold
     (State     : in out Folding_State;
      Start_Row : Natural;
      End_Row   : Natural)
   is
   begin
      if End_Row <= Start_Row then
         return;
      end if;

      if not State.Ranges.Is_Empty then
         for I in State.Ranges.First_Index .. State.Ranges.Last_Index loop
            if State.Ranges (I).Start_Row = Start_Row then
               State.Ranges.Replace_Element
                 (I,
                  (Start_Row => Start_Row,
                   End_Row   => Natural'Max (End_Row, State.Ranges (I).End_Row),
                   Collapsed => State.Ranges (I).Collapsed));
               return;
            end if;
         end loop;
      end if;

      State.Ranges.Append
        (Fold_Range'
          (Start_Row => Start_Row,
          End_Row   => End_Row,
          Collapsed => False));
   end Add_Fold;

   procedure Toggle_Fold_At_Row
     (State : in out Folding_State;
      Row   : Natural)
   is
      R : Fold_Range;
   begin
      if not State.Ranges.Is_Empty then
         for I in State.Ranges.First_Index .. State.Ranges.Last_Index loop
            if State.Ranges (I).Start_Row = Row then
               R := State.Ranges (I);
               R.Collapsed := not R.Collapsed;
               State.Ranges.Replace_Element (I, R);
               return;
            end if;
         end loop;
      end if;
   end Toggle_Fold_At_Row;

   function Has_Fold_Start
     (State : Folding_State;
      Row   : Natural) return Boolean
   is
   begin
      for R of State.Ranges loop
         if R.Start_Row = Row then
            return True;
         end if;
      end loop;
      return False;
   end Has_Fold_Start;

   function Is_Fold_Collapsed
     (State : Folding_State;
      Row   : Natural) return Boolean
   is
   begin
      for R of State.Ranges loop
         if R.Start_Row = Row then
            return R.Collapsed;
         end if;
      end loop;
      return False;
   end Is_Fold_Collapsed;

   function Fold_Start_For_Hidden_Row
     (State : Folding_State;
      Row   : Natural;
      Found : out Boolean) return Natural
   is
   begin
      for R of State.Ranges loop
         if R.Collapsed and then Row > R.Start_Row and then Row <= R.End_Row then
            Found := True;
            return R.Start_Row;
         end if;
      end loop;

      Found := False;
      return Row;
   end Fold_Start_For_Hidden_Row;

   function Is_Row_Hidden
     (State : Folding_State;
      Row   : Natural) return Boolean
   is
      Found : Boolean := False;
      Start : Natural := 0;
   begin
      Start := Fold_Start_For_Hidden_Row (State, Row, Found);
      return Found and then Start /= Row;
   end Is_Row_Hidden;

   procedure Expand_To_Reveal_Row
     (State : in out Folding_State;
      Row   : Natural)
   is
      R : Fold_Range;
   begin
      if State.Ranges.Is_Empty then
         return;
      end if;

      for I in State.Ranges.First_Index .. State.Ranges.Last_Index loop
         R := State.Ranges.Element (I);
         if R.Collapsed and then Row > R.Start_Row and then Row <= R.End_Row then
            R.Collapsed := False;
            State.Ranges.Replace_Element (I, R);
         end if;
      end loop;
   end Expand_To_Reveal_Row;

   function Visible_Row_To_Document_Row
     (State       : Folding_State;
      Visible_Row : Natural) return Natural
   is
      Visible : Natural := 0;
      Row     : Natural := 0;
   begin
      loop
         if not Is_Row_Hidden (State, Row) then
            if Visible = Visible_Row then
               return Row;
            end if;
            Visible := Visible + 1;
         end if;
         Row := Row + 1;
      end loop;
   end Visible_Row_To_Document_Row;

   function Document_Row_To_Visible_Row
     (State : Folding_State;
      Row   : Natural;
      Found : out Boolean) return Natural
   is
      Visible : Natural := 0;
   begin
      if Is_Row_Hidden (State, Row) then
         Found := False;
         return 0;
      end if;

      for R in 0 .. Row loop
         if not Is_Row_Hidden (State, R) then
            if R = Row then
               Found := True;
               return Visible;
            end if;
            Visible := Visible + 1;
         end if;
      end loop;

      Found := False;
      return 0;
   end Document_Row_To_Visible_Row;

   function Visible_Row_Count
     (State         : Folding_State;
      Document_Rows : Natural) return Natural
   is
      Count : Natural := 0;
   begin
      if Document_Rows = 0 then
         return 0;
      end if;

      for Row in 0 .. Document_Rows - 1 loop
         if not Is_Row_Hidden (State, Row) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Visible_Row_Count;

end Editor.Folding;
